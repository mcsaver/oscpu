/* RV64 CSR 与 SYSTEM trap return 语义。 */

/* CSR 执行基础设施集中在这里。SYSTEM 分发只决定“是哪类系统指令”，
 * CSR 的读改写语义、misa 配置回显和 mepc 对齐规则都不散到主 switch 里。 */
#include <utils/profile.h>
#include <isa/riscv/pmp.h>
#include "../local-include/privileged.h"

static bool csr_last_sstatus_write_valid = false;
static bool csr_last_sstatus_write_changed = true;
static bool csr_last_sstatus_write_only_cleared_sie = false;
static word_t csr_last_sstatus_write_old = 0;
static word_t csr_last_sstatus_write_new = 0;
static word_t csr_last_sstatus_write_delta = 0;

bool isa_riscv64_last_sstatus_write_was_unchanged(void) {
  return csr_last_sstatus_write_valid && !csr_last_sstatus_write_changed;
}

bool isa_riscv64_last_sstatus_write_only_cleared_sie(void) {
  return csr_last_sstatus_write_valid && csr_last_sstatus_write_only_cleared_sie;
}

bool isa_riscv64_last_sstatus_write_delta(word_t *old_status,
    word_t *new_status, word_t *delta) {
  if (!csr_last_sstatus_write_valid) {
    return false;
  }
  if (old_status) *old_status = csr_last_sstatus_write_old;
  if (new_status) *new_status = csr_last_sstatus_write_new;
  if (delta) *delta = csr_last_sstatus_write_delta;
  return true;
}

static inline word_t csr_misa_value() {
  word_t misa = (word_t)2 << 62;
  // RV64 文件只描述 RV64I 基线；RV32E 由 riscv32 目录单独管理。
  misa |= (word_t)1 << ('I' - 'A');
#ifdef CONFIG_RISCV_EXT_M
  misa |= (word_t)1 << ('M' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_A
  misa |= (word_t)1 << ('A' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_F
  misa |= (word_t)1 << ('F' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_D
  misa |= (word_t)1 << ('D' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_B
  misa |= (word_t)1 << ('B' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_C
  misa |= (word_t)1 << ('C' - 'A');
#endif
  misa |= (word_t)1 << ('S' - 'A');
  misa |= (word_t)1 << ('U' - 'A');
  return misa;
}

static inline bool csr_is_counter(uint32_t csr) {
  switch (csr) {
    case CSR_CYCLE:
    case CSR_TIME:
    case CSR_INSTRET:
      return true;
    default:
      return false;
  }
}

static inline word_t csr_counter_bit(uint32_t csr) {
  switch (csr) {
    case CSR_CYCLE: return COUNTEREN_CY;
    case CSR_TIME: return COUNTEREN_TM;
    case CSR_INSTRET: return COUNTEREN_IR;
    default: return 0;
  }
}

static inline bool csr_counter_allowed(uint32_t csr) {
  if (!csr_is_counter(csr) || cpu.priv == PRIV_M) return true;
  word_t bit = csr_counter_bit(csr);
  if (cpu.priv == PRIV_S) return (cpu.csr.mcounteren & bit) != 0;
  return (cpu.csr.mcounteren & bit) != 0 && (cpu.csr.scounteren & bit) != 0;
}

static inline word_t csr_status_sd_bit(void) {
  // SD 汇总 FS 或 VS 任一为 Dirty(3)。VS 随 V 扩展 status 位一起暴露后, SD 也须兼顾 VS。
  return ((cpu.csr.mstatus & MSTATUS_FS_MASK) == MSTATUS_FS_DIRTY ||
          (cpu.csr.mstatus & MSTATUS_VS_MASK) == MSTATUS_VS_DIRTY)
           ? MSTATUS_SD : 0;
}

static inline word_t csr_mstatus_read_value(void) {
  return (cpu.csr.mstatus | MSTATUS_SXL_UXL | csr_status_sd_bit());
}

static inline word_t csr_sstatus_read_value(void) {
  return (csr_mstatus_read_value() & SSTATUS_MASK) | csr_status_sd_bit();
}

static inline word_t csr_sanitize_mstatus(word_t value) {
  word_t next = (value & MSTATUS_WRITABLE_MASK) | MSTATUS_SXL_UXL;
#ifndef CONFIG_RISCV_EXT_F
  next &= ~MSTATUS_FS_MASK;
#endif
  // MPP=2 是保留编码。NEMU 支持 U/S/M，非法 WARL 写统一折叠到最低特权 U。
  if ((next & MSTATUS_MPP_MASK) == ((word_t)2 << 11)) {
    next &= ~MSTATUS_MPP_MASK;
  }
  return next;
}

static inline word_t csr_supervisor_interrupt_mask(void) {
  return cpu.csr.mideleg & MIDELEG_WRITABLE_MASK;
}

static inline void csr_profile_sstatus_write_delta(word_t old_status,
    word_t new_status) {
  word_t delta = (old_status ^ new_status) & SSTATUS_MASK;
  // TB 边界判断消费真实写后 delta：只允许无变化或仅关 SIE 的窄安全子集继续。
  csr_last_sstatus_write_valid = true;
  csr_last_sstatus_write_changed = delta != 0;
  csr_last_sstatus_write_only_cleared_sie =
      delta == MSTATUS_SIE &&
      (old_status & MSTATUS_SIE) != 0 &&
      (new_status & MSTATUS_SIE) == 0;
  csr_last_sstatus_write_old = old_status;
  csr_last_sstatus_write_new = new_status;
  csr_last_sstatus_write_delta = delta;

  if (!nemu_profile_stop_detail_enabled()) return;

  nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_TOTAL, 1);
  if (delta == 0) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_UNCHANGED, 1);
    return;
  }

  nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_CHANGED, 1);
  if (delta & MSTATUS_SIE) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_SIE, 1);
  }
  if (delta & MSTATUS_SPIE) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_SPIE, 1);
  }
  if (delta & MSTATUS_SPP) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_SPP, 1);
  }
  if (delta & MSTATUS_FS_MASK) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_FS, 1);
  }
  if (delta & MSTATUS_SUM) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_SUM, 1);
  }
  if (delta & MSTATUS_MXR) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_MXR, 1);
  }
  if (delta & MSTATUS_UXL) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_SXL_UXL, 1);
  }

  word_t known = MSTATUS_SIE | MSTATUS_SPIE | MSTATUS_SPP |
                 MSTATUS_FS_MASK | MSTATUS_SUM | MSTATUS_MXR |
                 MSTATUS_UXL;
  if (delta & ~known) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_OTHER, 1);
  }
}

static inline word_t csr_sanitize_satp(word_t value) {
#ifdef CONFIG_ISA64
  word_t mode = value >> 60;
  // satp.MODE 是 WARL 字段，NEMU 支持 Bare(0)/Sv39(8)/Sv48(9)/Sv57(10)。写入不支持的 MODE 时，
  // 按 RISC-V 特权规范"整个 satp 写不生效"——保持旧值，而不是清成 Bare(0)。
  // 清 0 会丢掉正在生效的映射、让后续访存把 VA 当 PA 落到越界物理地址, 并破坏分页模式探测语义。
  if (mode != 0 && mode != 8 && mode != 9 && mode != 10) return cpu.csr.satp;
  return value;
#else
  return value;
#endif
}

static inline bool csr_pmpcfg_base(uint32_t csr, uint32_t *base) {
  if (csr == CSR_PMPCFG0) {
    *base = 0;
    return true;
  }
  if (csr == CSR_PMPCFG2) {
    *base = 8;
    return true;
  }
  return false;
}

static inline bool csr_is_implemented(uint32_t csr) {
  uint32_t pmpcfg_base = 0;
  if (csr_pmpcfg_base(csr, &pmpcfg_base)) return true;
  if (csr >= CSR_PMPADDR0 && csr <= CSR_PMPADDR15) return true;

  switch (csr) {
    case CSR_MVENDORID:
    case CSR_MARCHID:
    case CSR_MIMPID:
#ifdef CONFIG_RISCV_EXT_F
    case CSR_FFLAGS:
    case CSR_FRM:
    case CSR_FCSR:
#endif
    case CSR_SSTATUS:
    case CSR_SIE:
    case CSR_STVEC:
    case CSR_SCOUNTEREN:
    case CSR_SSCRATCH:
    case CSR_SEPC:
    case CSR_SCAUSE:
    case CSR_STVAL:
    case CSR_SIP:
    case CSR_SATP:
    case CSR_MSTATUS:
    case CSR_MEDELEG:
    case CSR_MIDELEG:
    case CSR_MIE:
    case CSR_MTVEC:
    case CSR_MCOUNTEREN:
    case CSR_MENVCFG:
    case CSR_MCOUNTINHIBIT:
    case CSR_MSCRATCH:
    case CSR_MEPC:
    case CSR_MCAUSE:
    case CSR_MTVAL:
    case CSR_MIP:
    case CSR_MCYCLE:
    case CSR_MINSTRET:
    case CSR_CYCLE:
    case CSR_TIME:
    case CSR_INSTRET:
    case CSR_MISA:
    case CSR_MHARTID:
    case CSR_TSELECT:
    case CSR_TDATA1:
    case CSR_TDATA2:
    case CSR_TCONTROL:
      return true;
    default:
      return false;
  }
}

static inline uint8_t csr_sanitize_pmpcfg(uint8_t cfg) {
  return riscv_pmp_sanitize_config(cfg);
}

static inline bool csr_pmpaddr_write_locked(uint32_t index) {
  if (cpu.csr.pmpcfg[index] & RISCV_PMP_LOCKED) return true;
  if (index + 1 < RISCV_PMP_ENTRY_COUNT &&
      (cpu.csr.pmpcfg[index + 1] & RISCV_PMP_LOCKED) &&
      riscv_pmp_address_matching(cpu.csr.pmpcfg[index + 1]) ==
          RISCV_PMP_TOR) {
    return true;
  }
  return false;
}

static inline void csr_update_pmp_active(void) {
  cpu.csr.pmp_active = false;
  for (uint32_t i = 0; i < RISCV_PMP_ENTRY_COUNT; i++) {
    if (riscv_pmp_address_matching(cpu.csr.pmpcfg[i]) != RISCV_PMP_OFF) {
      cpu.csr.pmp_active = true;
      return;
    }
  }
}

static inline word_t csr_read_pmpcfg(uint32_t base) {
  word_t value = 0;
  for (uint32_t i = 0; i < 8; i++) {
    value |= (word_t)cpu.csr.pmpcfg[base + i] << (i * 8);
  }
  return value;
}

static inline void csr_write_pmpcfg(uint32_t base, word_t value) {
  bool changed = false;
  for (uint32_t i = 0; i < 8; i++) {
    uint32_t index = base + i;
    if (cpu.csr.pmpcfg[index] & RISCV_PMP_LOCKED) continue;
    uint8_t next = csr_sanitize_pmpcfg((uint8_t)(value >> (i * 8)));
    if (cpu.csr.pmpcfg[index] != next) {
      cpu.csr.pmpcfg[index] = next;
      changed = true;
    }
  }
  if (changed) {
    csr_update_pmp_active();
    isa_riscv64_pmp_mark_dirty();
    isa_riscv64_mmu_tlb_flush();
  }
}

static inline void csr_write_pmpaddr(uint32_t index, word_t value) {
  if (csr_pmpaddr_write_locked(index)) return;
  word_t next = value & PMPADDR_MASK;
  if (cpu.csr.pmpaddr[index] != next) {
    cpu.csr.pmpaddr[index] = next;
    isa_riscv64_pmp_mark_dirty();
    isa_riscv64_mmu_tlb_flush();
  }
}

static inline bool csr_read(uint32_t csr, word_t *value) {
  uint32_t pmpcfg_base = 0;
  if (csr_pmpcfg_base(csr, &pmpcfg_base)) {
    *value = csr_read_pmpcfg(pmpcfg_base);
    return true;
  }
  if (csr >= CSR_PMPADDR0 && csr <= CSR_PMPADDR15) {
    *value = cpu.csr.pmpaddr[csr - CSR_PMPADDR0] & PMPADDR_MASK;
    return true;
  }

  switch (csr) {
    // 身份与计数器 CSR 对齐 NPC，避免 guest 在 difftest 下读到 reference illegal trap。
    case CSR_MVENDORID: *value = 0x79737978u; return true;
    case CSR_MARCHID:   *value = 26010035u; return true;
    case CSR_MIMPID:    *value = 0; return true;
#ifdef CONFIG_RISCV_EXT_F
    case CSR_FFLAGS:
      if (!fp_state_enabled()) return false;
      *value = cpu.csr.fflags;
      return true;
    case CSR_FRM:
      if (!fp_state_enabled()) return false;
      *value = cpu.csr.frm;
      return true;
    case CSR_FCSR:
      if (!fp_state_enabled()) return false;
      *value = ((word_t)cpu.csr.frm << 5) | cpu.csr.fflags;
      return true;
#endif
    case CSR_SSTATUS:  *value = csr_sstatus_read_value(); return true;
    case CSR_SIE:      *value = cpu.csr.mie & csr_supervisor_interrupt_mask(); return true;
    case CSR_STVEC:    *value = cpu.csr.stvec; return true;
    case CSR_SCOUNTEREN: *value = cpu.csr.scounteren; return true;
    case CSR_SSCRATCH: *value = cpu.csr.sscratch; return true;
    case CSR_SEPC:     *value = cpu.csr.sepc; return true;
    case CSR_SCAUSE:   *value = cpu.csr.scause; return true;
    case CSR_STVAL:    *value = cpu.csr.stval; return true;
    case CSR_SIP:      *value = isa_riscv64_mip_value() & csr_supervisor_interrupt_mask(); return true;
    case CSR_SATP:     *value = cpu.csr.satp; return true;
    case CSR_MSTATUS:  *value = csr_mstatus_read_value(); return true;
    case CSR_MEDELEG:  *value = cpu.csr.medeleg; return true;
    case CSR_MIDELEG:  *value = cpu.csr.mideleg; return true;
    case CSR_MIE:      *value = cpu.csr.mie; return true;
    case CSR_MTVEC:    *value = cpu.csr.mtvec; return true;
    case CSR_MCOUNTEREN: *value = cpu.csr.mcounteren; return true;
    case CSR_MENVCFG:  *value = cpu.csr.menvcfg; return true;
    case CSR_MCOUNTINHIBIT: *value = cpu.csr.mcountinhibit; return true;
    case CSR_MSCRATCH: *value = cpu.csr.mscratch; return true;
    case CSR_MEPC:     *value = cpu.csr.mepc; return true;
    case CSR_MCAUSE:   *value = cpu.csr.mcause; return true;
    case CSR_MTVAL:    *value = cpu.csr.mtval; return true;
    case CSR_MIP:      *value = isa_riscv64_mip_value(); return true;
    case CSR_MCYCLE:   *value = (word_t)cpu.csr.mcycle; return true;
    case CSR_MINSTRET: *value = (word_t)cpu.csr.minstret; return true;
    case CSR_CYCLE:    *value = (word_t)cpu.csr.mcycle; return true;
    // time 暴露平台 CLINT mtime，避免 guest 时间源和 mcycle 统计混在一起。
    case CSR_TIME:     *value = (word_t)isa_riscv64_mtime_value(); return true;
    case CSR_INSTRET:  *value = (word_t)cpu.csr.minstret; return true;
    case CSR_MISA:     *value = csr_misa_value(); return true;
    case CSR_MHARTID:  *value = 0; return true;
    // debug trigger 最小 no-op(对齐 NPC): tselect 读回 NO_TRIGGER(1)、tdata1/2/tcontrol 恒 0。
    case CSR_TSELECT:  *value = 1; return true;
    case CSR_TDATA1:
    case CSR_TDATA2:
    case CSR_TCONTROL: *value = 0; return true;
    default: return false;
  }
}

static inline bool csr_write(uint32_t csr, word_t value) {
  word_t mepc_mask = MUXDEF(CONFIG_RISCV_EXT_C, ~(word_t)0x1, ~(word_t)0x3);
  uint32_t pmpcfg_base = 0;
  if (csr_pmpcfg_base(csr, &pmpcfg_base)) {
    csr_write_pmpcfg(pmpcfg_base, value);
    return true;
  }
  if (csr >= CSR_PMPADDR0 && csr <= CSR_PMPADDR15) {
    csr_write_pmpaddr(csr - CSR_PMPADDR0, value);
    return true;
  }

  switch (csr) {
#ifdef CONFIG_RISCV_EXT_F
    case CSR_FFLAGS:
      if (!fp_state_enabled()) return false;
      cpu.csr.fflags = value & 0x1f;
      fp_mark_dirty();
      return true;
    case CSR_FRM:
      if (!fp_state_enabled()) return false;
      cpu.csr.frm = value & 0x7;
      fp_mark_dirty();
      return true;
    case CSR_FCSR:
      if (!fp_state_enabled()) return false;
      cpu.csr.fflags = value & 0x1f;
      cpu.csr.frm = (value >> 5) & 0x7;
      fp_mark_dirty();
      return true;
#endif
    case CSR_SSTATUS: {
      word_t writable_mask = SSTATUS_WRITABLE_MASK;
#ifndef CONFIG_RISCV_EXT_F
      writable_mask &= ~MSTATUS_FS_MASK;
#endif
      word_t old_status = cpu.csr.mstatus & SSTATUS_MASK;
      word_t new_status = (value & writable_mask) | MSTATUS_UXL;
      csr_profile_sstatus_write_delta(old_status, new_status);
      cpu.csr.mstatus = (cpu.csr.mstatus & ~SSTATUS_MASK) | new_status;
      return true;
    }
    case CSR_SIE: {
      word_t mask = csr_supervisor_interrupt_mask();
      cpu.csr.mie = (cpu.csr.mie & ~mask) | (value & mask);
      return true;
    }
    case CSR_STVEC:
      cpu.csr.stvec = riscv_tvec_warl_value(value);
      CSR_DEBUG_LOG("CSR write stvec=" FMT_WORD " raw=" FMT_WORD " pc=" FMT_WORD
          " priv=%u", cpu.csr.stvec, value, cpu.pc, cpu.priv);
      return true;
    case CSR_SCOUNTEREN: cpu.csr.scounteren = value & COUNTEREN_MASK; return true;
    case CSR_SSCRATCH: cpu.csr.sscratch = value; return true;
    case CSR_SEPC:     cpu.csr.sepc = value & mepc_mask; return true;
    case CSR_SCAUSE:   cpu.csr.scause = value; return true;
    case CSR_STVAL:    cpu.csr.stval = value; return true;
    case CSR_SIP: {
      word_t writable_mask =
          csr_supervisor_interrupt_mask() & SIP_WRITABLE_MASK;
      word_t old_mip = cpu.csr.mip;
      cpu.csr.mip = (cpu.csr.mip & ~writable_mask) |
                    (value & writable_mask);
      (void)old_mip;
      CSR_INTR_DEBUG_LOG("CSR write sip old_mip=" FMT_WORD " raw=" FMT_WORD
          " new_mip=" FMT_WORD " pc=" FMT_WORD " priv=%u",
          old_mip, value, cpu.csr.mip, cpu.pc, cpu.priv);
      return true;
    }
    case CSR_SATP:
      cpu.csr.satp = csr_sanitize_satp(value);
      /*
       * satp writes are not implicit fences. TLB entries are keyed by root_ppn,
       * ASID, privilege and status bits; guest software uses sfence.vma for
       * page-table ordering when it reuses an address space.
       */
      CSR_DEBUG_LOG("CSR write satp=" FMT_WORD " raw=" FMT_WORD " pc=" FMT_WORD
          " priv=%u", cpu.csr.satp, value, cpu.pc, cpu.priv);
      return true;
    // misa 是 WARL: NEMU 的扩展集固定不可变, 写按"忽略非法/所有位"处理(读回仍是 csr_misa_value)。
    // 关键是 csrw misa 本身是合法指令, 不能落到 default 当 illegal——否则 riscv-dv 等在 mtvec 设置前
    // 写 misa 的 boot code 会 trap 到 mtvec=0 而跑飞。(rv64dv 压测发现)
    case CSR_MISA:     return true;
    case CSR_MSTATUS:  cpu.csr.mstatus = csr_sanitize_mstatus(value); return true;
    case CSR_MEDELEG:  cpu.csr.medeleg = value & MEDELEG_WRITABLE_MASK; return true;
    case CSR_MIDELEG:  cpu.csr.mideleg = value & MIDELEG_WRITABLE_MASK; return true;
    case CSR_MIE:      isa_riscv64_write_mie(value); return true;
    case CSR_MTVEC:    cpu.csr.mtvec = riscv_tvec_warl_value(value); return true;
    case CSR_MCOUNTEREN: cpu.csr.mcounteren = value & COUNTEREN_MASK; return true;
    case CSR_MENVCFG:  cpu.csr.menvcfg = value & MENVCFG_WRITABLE_MASK; return true;
    case CSR_MCOUNTINHIBIT: cpu.csr.mcountinhibit = value & (MCOUNTINHIBIT_CY | MCOUNTINHIBIT_IR); return true;
    case CSR_MSCRATCH: cpu.csr.mscratch = value; return true;
    case CSR_MEPC:     cpu.csr.mepc = value & mepc_mask; return true;
    case CSR_MCAUSE:   cpu.csr.mcause = value; return true;
    case CSR_MTVAL:    cpu.csr.mtval = value; return true;
    case CSR_MIP: {
      word_t old_mip = cpu.csr.mip;
      isa_riscv64_write_mip(value);
      (void)old_mip;
      CSR_INTR_DEBUG_LOG("CSR write mip old_mip=" FMT_WORD " raw=" FMT_WORD
          " new_mip=" FMT_WORD " pc=" FMT_WORD " priv=%u",
          old_mip, value, cpu.csr.mip, cpu.pc, cpu.priv);
      return true;
    }
    case CSR_MCYCLE:   isa_riscv64_write_mcycle(value); return true;
    case CSR_MINSTRET: isa_riscv64_write_minstret(value); return true;
    // debug trigger 最小 no-op(对齐 NPC): 写忽略(WARL), 不 illegal。
    case CSR_TSELECT:
    case CSR_TDATA1:
    case CSR_TDATA2:
    case CSR_TCONTROL: return true;
    default: return false;
  }
}

static inline bool csr_write_masked(uint32_t csr, word_t value, word_t write_mask) {
  if (csr == CSR_SIP) {
    word_t writable_mask =
        write_mask & SIP_WRITABLE_MASK & csr_supervisor_interrupt_mask();
    word_t old_mip = cpu.csr.mip;
    cpu.csr.mip = (cpu.csr.mip & ~writable_mask) | (value & writable_mask);
    if ((old_mip | value | write_mask | cpu.csr.mip) & MIP_SEIP) {
      CSR_INTR_DEBUG_LOG("CSR write sip old_mip=" FMT_WORD " raw=" FMT_WORD
          " mask=" FMT_WORD " new_mip=" FMT_WORD " pc=" FMT_WORD " priv=%u",
          old_mip, value, write_mask, cpu.csr.mip, cpu.pc, cpu.priv);
    }
    return true;
  }

  if (csr == CSR_MIP) {
    word_t old_mip = cpu.csr.mip;
    word_t merged = (old_mip & ~write_mask) | (value & write_mask);
    isa_riscv64_write_mip(merged);
    if ((old_mip | value | write_mask | merged | cpu.csr.mip) & MIP_SEIP) {
      CSR_INTR_DEBUG_LOG("CSR write mip old_mip=" FMT_WORD " raw=" FMT_WORD
          " mask=" FMT_WORD " merged=" FMT_WORD " new_mip=" FMT_WORD
          " pc=" FMT_WORD " priv=%u",
          old_mip, value, write_mask, merged, cpu.csr.mip, cpu.pc, cpu.priv);
    }
    return true;
  }

  return csr_write(csr, value);
}

static inline uint8_t riscv_mstatus_previous_privilege(word_t status) {
  switch (status & MSTATUS_MPP_MASK) {
    case MSTATUS_MPP_S: return PRIV_S;
    case MSTATUS_MPP_M: return PRIV_M;
    default: return PRIV_U;
  }
}

static inline bool ebreak_should_raise_breakpoint_trap(void) {
#ifndef CONFIG_TARGET_AM
  // Linux/system 模式按官方 ISA 把 ebreak 当 breakpoint trap(ACT4/semihost 等依赖);
  // AM 系统测试统一用设备树 syscon 退出, 不依赖 ebreak 停机。
  return true;
#else
  return cpu.csr.mtvec != 0 || cpu.csr.stvec != 0;
#endif
}

static inline void csr_reset_sstatus_write_observer(void) {
  csr_last_sstatus_write_valid = false;
  csr_last_sstatus_write_changed = true;
  csr_last_sstatus_write_only_cleared_sie = false;
  csr_last_sstatus_write_old = 0;
  csr_last_sstatus_write_new = 0;
  csr_last_sstatus_write_delta = 0;
}

static inline bool riscv_csr_access_is_legal(
    const RiscvCsrInstruction *instruction) {
  const uint32_t address = instruction->address;

  if (!csr_is_implemented(address)) return false;
  if (cpu.priv < BITS(address, 9, 8)) return false;

  /* TVM makes every S-mode access to satp illegal, including a suppressed
   * read or write. M-mode is not constrained by TVM. */
  if (address == CSR_SATP && cpu.priv == PRIV_S &&
      (cpu.csr.mstatus & MSTATUS_TVM)) {
    return false;
  }
  if (!csr_counter_allowed(address)) return false;
  if (instruction->access.writes_csr &&
      riscv_csr_address_is_read_only(address)) {
    return false;
  }

#ifdef CONFIG_RISCV_EXT_F
  if ((address == CSR_FFLAGS || address == CSR_FRM || address == CSR_FCSR) &&
      !fp_state_enabled()) {
    return false;
  }
#endif
  return true;
}

static inline bool riscv_csr_capture_source(
    const RiscvCsrInstruction *instruction, word_t *source) {
  switch (instruction->source_kind) {
    case RISCV_CSR_SOURCE_REGISTER:
      *source = R(instruction->source_field);
      return true;
    case RISCV_CSR_SOURCE_IMMEDIATE:
      *source = instruction->source_field;
      return true;
    default:
      return false;
  }
}

static inline bool riscv_csr_calculate_write(
    const RiscvCsrInstruction *instruction, word_t source, word_t old_value,
    word_t *new_value, word_t *write_mask) {
  switch (instruction->access.operation) {
    case RISCV_CSR_OPERATION_WRITE:
      *new_value = source;
      *write_mask = ~(word_t)0;
      return true;
    case RISCV_CSR_OPERATION_SET_BITS:
      *new_value = old_value | source;
      *write_mask = source;
      return true;
    case RISCV_CSR_OPERATION_CLEAR_BITS:
      *new_value = old_value & ~source;
      *write_mask = source;
      return true;
    default:
      return false;
  }
}

/*
 * Zicsr architectural order:
 *   check access -> capture source/old value -> compute modification
 *   -> commit CSR -> commit rd.
 *
 * source_field is the encoded rs1/zimm field. Therefore rs1=x0 and zimm=0
 * suppress CSRRS/CSRRC writes even if x0 happens to contain a stale host-side
 * value, while rd=x0 suppresses only the CSRRW/CSRRWI CSR read.
 */
static inline bool riscv_execute_csr_instruction(
    const RiscvCsrInstruction *instruction) {
  word_t source = 0;
  word_t old_value = 0;
  word_t new_value = 0;
  word_t write_mask = 0;

  csr_reset_sstatus_write_observer();
  if (!riscv_csr_access_is_legal(instruction)) return false;

  if (!riscv_csr_capture_source(instruction, &source)) return false;
  if (instruction->access.reads_csr &&
      !csr_read(instruction->address, &old_value)) {
    return false;
  }
  if (!riscv_csr_calculate_write(
          instruction, source, old_value, &new_value, &write_mask)) {
    return false;
  }

  if (instruction->access.writes_csr &&
      !csr_write_masked(instruction->address, new_value, write_mask)) {
    return false;
  }
  if (instruction->destination_register != 0) {
    R(instruction->destination_register) = old_value;
  }
  return true;
}

/* MRET legality and the full xRET state transition deliberately live together. */
static inline bool riscv_execute_machine_return(Decode *state) {
  if (cpu.priv != PRIV_M) return false;

  const word_t previous_status = cpu.csr.mstatus;
  const uint8_t return_privilege =
      riscv_mstatus_previous_privilege(previous_status);
  word_t returned_status = previous_status;

  /* MIE <- MPIE; MPIE <- 1; MPP <- least-supported privilege (U). */
  if (previous_status & MSTATUS_MPIE) returned_status |= MSTATUS_MIE;
  else returned_status &= ~MSTATUS_MIE;
  returned_status |= MSTATUS_MPIE;
  returned_status &= ~MSTATUS_MPP_MASK;

  /* Leaving M-mode also clears MPRV. SXL/UXL are fixed WARL fields here. */
  if (return_privilege != PRIV_M) returned_status &= ~MSTATUS_MPRV;
  returned_status |= MSTATUS_SXL_UXL;

  cpu.csr.mstatus = returned_status;
  cpu.priv = return_privilege;
  state->dnpc = cpu.csr.mepc;
  etrace_log_mret(state->pc, state->dnpc, returned_status);
  return true;
}

/* SRET legality and the full xRET state transition deliberately live together. */
static inline bool riscv_execute_supervisor_return(Decode *state) {
  if (cpu.priv < PRIV_S) return false;
  if (cpu.priv == PRIV_S && (cpu.csr.mstatus & MSTATUS_TSR)) return false;

  const word_t previous_status = cpu.csr.mstatus;
  const uint8_t return_privilege =
      (previous_status & MSTATUS_SPP) ? PRIV_S : PRIV_U;
  word_t returned_status = previous_status;

  /* SIE <- SPIE; SPIE <- 1; SPP <- least-supported privilege (U). */
  if (previous_status & MSTATUS_SPIE) returned_status |= MSTATUS_SIE;
  else returned_status &= ~MSTATUS_SIE;
  returned_status |= MSTATUS_SPIE;
  returned_status &= ~MSTATUS_SPP;

  /* SRET always returns below M-mode and therefore clears MPRV. */
  returned_status &= ~MSTATUS_MPRV;
  returned_status |= MSTATUS_SXL_UXL;

  cpu.csr.mstatus = returned_status;
  cpu.priv = return_privilege;
  state->dnpc = cpu.csr.sepc;
  syscall_debug_log_return(state->dnpc);
  return true;
}
