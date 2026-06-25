/* RV64 CSR 与 SYSTEM trap return 语义。 */

/* CSR 执行基础设施集中在这里。SYSTEM 分发只决定“是哪类系统指令”，
 * CSR 的读改写语义、misa 配置回显和 mepc 对齐规则都不散到主 switch 里。 */
#include <utils/profile.h>

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
#ifdef CONFIG_MODE_SYSTEM
  misa |= (word_t)1 << ('S' - 'A');
  misa |= (word_t)1 << ('U' - 'A');
#endif
  return misa;
}

static inline bool csr_is_counter(uint32_t csr) {
  switch (csr) {
    case CSR_CYCLE:
    case CSR_TIME:
    case CSR_INSTRET:
    case CSR_CYCLEH:
    case CSR_TIMEH:
    case CSR_INSTRETH:
      return true;
    default:
      return false;
  }
}

static inline word_t csr_counter_bit(uint32_t csr) {
  switch (csr) {
    case CSR_CYCLE:
    case CSR_CYCLEH: return COUNTEREN_CY;
    case CSR_TIME:
    case CSR_TIMEH: return COUNTEREN_TM;
    case CSR_INSTRET:
    case CSR_INSTRETH: return COUNTEREN_IR;
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
  return (cpu.csr.mstatus & MSTATUS_FS_MASK) == MSTATUS_FS_DIRTY
           ? MSTATUS_SD : 0;
}

static inline word_t csr_mstatus_read_value(void) {
  return (cpu.csr.mstatus | MSTATUS_SXL_UXL | csr_status_sd_bit());
}

static inline word_t csr_sstatus_read_value(void) {
  return (csr_mstatus_read_value() & SSTATUS_MASK) | csr_status_sd_bit();
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
  if (delta & MSTATUS_SXL_UXL) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_SXL_UXL, 1);
  }

  word_t known = MSTATUS_SIE | MSTATUS_SPIE | MSTATUS_SPP |
                 MSTATUS_FS_MASK | MSTATUS_SUM | MSTATUS_MXR |
                 MSTATUS_SXL_UXL;
  if (delta & ~known) {
    nemu_profile_count(NEMU_PROFILE_CPU_CSR_SSTATUS_WRITE_DELTA_OTHER, 1);
  }
}

static inline word_t csr_sanitize_satp(word_t value) {
#ifdef CONFIG_ISA64
  word_t mode = value >> 60;
  return (mode == 0 || mode == 8) ? value : 0;
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

static inline uint8_t csr_sanitize_pmpcfg(uint8_t cfg) {
  cfg &= PMP_CFG_R | PMP_CFG_W | PMP_CFG_X | PMP_CFG_A_MASK | PMP_CFG_L;
  if ((cfg & PMP_CFG_W) && !(cfg & PMP_CFG_R)) {
    cfg &= ~PMP_CFG_W;
  }
  return cfg;
}

static inline bool csr_pmpaddr_write_locked(uint32_t index) {
  if (cpu.csr.pmpcfg[index] & PMP_CFG_L) return true;
  if (index + 1 < RISCV64_PMP_ENTRY_COUNT &&
      (cpu.csr.pmpcfg[index + 1] & PMP_CFG_L) &&
      ((cpu.csr.pmpcfg[index + 1] & PMP_CFG_A_MASK) == PMP_CFG_A_TOR)) {
    return true;
  }
  return false;
}

static inline void csr_update_pmp_active(void) {
  cpu.csr.pmp_active = false;
  for (uint32_t i = 0; i < RISCV64_PMP_ENTRY_COUNT; i++) {
    if ((cpu.csr.pmpcfg[i] & PMP_CFG_A_MASK) != PMP_CFG_A_OFF) {
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
    if (cpu.csr.pmpcfg[index] & PMP_CFG_L) continue;
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
    case CSR_FFLAGS:    *value = cpu.csr.fflags; return true;
    case CSR_FRM:       *value = cpu.csr.frm; return true;
    case CSR_FCSR:      *value = ((word_t)cpu.csr.frm << 5) | cpu.csr.fflags; return true;
    case CSR_SSTATUS:  *value = csr_sstatus_read_value(); return true;
    case CSR_SIE:      *value = cpu.csr.mie & MIP_SUPERVISOR_MASK; return true;
    case CSR_STVEC:    *value = cpu.csr.stvec; return true;
    case CSR_SCOUNTEREN: *value = cpu.csr.scounteren; return true;
    case CSR_SSCRATCH: *value = cpu.csr.sscratch; return true;
    case CSR_SEPC:     *value = cpu.csr.sepc; return true;
    case CSR_SCAUSE:   *value = cpu.csr.scause; return true;
    case CSR_STVAL:    *value = cpu.csr.stval; return true;
    case CSR_SIP:      *value = isa_riscv64_mip_value() & MIP_SUPERVISOR_MASK; return true;
    case CSR_SATP:     *value = cpu.csr.satp; return true;
    case CSR_MSTATUS:  *value = csr_mstatus_read_value(); return true;
    case CSR_MEDELEG:  *value = cpu.csr.medeleg; return true;
    case CSR_MIDELEG:  *value = cpu.csr.mideleg; return true;
    case CSR_MIE:      *value = cpu.csr.mie; return true;
    case CSR_MTVEC:    *value = cpu.csr.mtvec; return true;
    case CSR_MCOUNTEREN: *value = cpu.csr.mcounteren; return true;
    case CSR_MCOUNTINHIBIT: *value = cpu.csr.mcountinhibit; return true;
    case CSR_MSCRATCH: *value = cpu.csr.mscratch; return true;
    case CSR_MEPC:     *value = cpu.csr.mepc; return true;
    case CSR_MCAUSE:   *value = cpu.csr.mcause; return true;
    case CSR_MTVAL:    *value = cpu.csr.mtval; return true;
    case CSR_MIP:      *value = isa_riscv64_mip_value(); return true;
    case CSR_MCYCLE:   *value = (word_t)cpu.csr.mcycle; return true;
    case CSR_MCYCLEH:  *value = (word_t)(cpu.csr.mcycle >> 32); return true;
    case CSR_MINSTRET: *value = (word_t)cpu.csr.minstret; return true;
    case CSR_MINSTRETH:*value = (word_t)(cpu.csr.minstret >> 32); return true;
    case CSR_CYCLE:    *value = (word_t)cpu.csr.mcycle; return true;
    case CSR_CYCLEH:   *value = (word_t)(cpu.csr.mcycle >> 32); return true;
    // time/timeh 暴露平台 CLINT mtime，避免 guest 时间源和 mcycle 统计混在一起。
    case CSR_TIME:     *value = (word_t)isa_riscv64_mtime_value(); return true;
    case CSR_TIMEH:    *value = (word_t)(isa_riscv64_mtime_value() >> 32); return true;
    case CSR_INSTRET:  *value = (word_t)cpu.csr.minstret; return true;
    case CSR_INSTRETH: *value = (word_t)(cpu.csr.minstret >> 32); return true;
    case CSR_MISA:     *value = csr_misa_value(); return true;
    case CSR_MHARTID:  *value = 0; return true;
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
    case CSR_FFLAGS:   cpu.csr.fflags = value & 0x1f; return true;
    case CSR_FRM:      cpu.csr.frm = value & 0x7; return true;
    case CSR_FCSR:
      cpu.csr.fflags = value & 0x1f;
      cpu.csr.frm = (value >> 5) & 0x7;
      return true;
    case CSR_SSTATUS: {
      word_t old_status = cpu.csr.mstatus & SSTATUS_MASK;
      word_t new_status = (value & SSTATUS_MASK) | MSTATUS_SXL_UXL;
      csr_profile_sstatus_write_delta(old_status, new_status);
      cpu.csr.mstatus = (cpu.csr.mstatus & ~SSTATUS_MASK) | new_status;
      return true;
    }
    case CSR_SIE:
      cpu.csr.mie = (cpu.csr.mie & ~MIP_SUPERVISOR_MASK) |
                    (value & MIP_SUPERVISOR_MASK);
      return true;
    case CSR_STVEC:
      cpu.csr.stvec = value & ~(word_t)0x3;
      CSR_DEBUG_LOG("CSR write stvec=" FMT_WORD " raw=" FMT_WORD " pc=" FMT_WORD
          " priv=%u", cpu.csr.stvec, value, cpu.pc, cpu.priv);
      return true;
    case CSR_SCOUNTEREN: cpu.csr.scounteren = value & COUNTEREN_MASK; return true;
    case CSR_SSCRATCH: cpu.csr.sscratch = value; return true;
    case CSR_SEPC:     cpu.csr.sepc = value & mepc_mask; return true;
    case CSR_SCAUSE:   cpu.csr.scause = value; return true;
    case CSR_STVAL:    cpu.csr.stval = value; return true;
    case CSR_SIP: {
      word_t old_mip = cpu.csr.mip;
      cpu.csr.mip = (cpu.csr.mip & ~SIP_WRITABLE_MASK) |
                    (value & SIP_WRITABLE_MASK);
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
    case CSR_MSTATUS:  cpu.csr.mstatus = (value & MSTATUS_WRITABLE_MASK) | MSTATUS_SXL_UXL; return true;
    case CSR_MEDELEG:  cpu.csr.medeleg = value; return true;
    case CSR_MIDELEG:  cpu.csr.mideleg = value; return true;
    case CSR_MIE:      isa_riscv64_write_mie(value); return true;
    case CSR_MTVEC:    cpu.csr.mtvec = value & ~(word_t)0x3; return true;
    case CSR_MCOUNTEREN: cpu.csr.mcounteren = value & COUNTEREN_MASK; return true;
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
    case CSR_MCYCLE:   isa_riscv64_write_mcycle_lo(value); return true;
    case CSR_MCYCLEH:  isa_riscv64_write_mcycle_hi(value); return true;
    case CSR_MINSTRET: cpu.csr.minstret = (cpu.csr.minstret & 0xffffffff00000000ull) | (uint32_t)value; return true;
    case CSR_MINSTRETH: cpu.csr.minstret = ((uint64_t)(uint32_t)value << 32) | (uint32_t)cpu.csr.minstret; return true;
    default: return false;
  }
}

static inline bool csr_write_masked(uint32_t csr, word_t value, word_t write_mask) {
  if (csr == CSR_SIP) {
    word_t writable_mask = write_mask & SIP_WRITABLE_MASK;
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

static inline uint8_t csr_mpp_to_priv(word_t status) {
  switch (status & MSTATUS_MPP_MASK) {
    case MSTATUS_MPP_S: return PRIV_S;
    case MSTATUS_MPP_M: return PRIV_M;
    default: return PRIV_U;
  }
}

static inline word_t csr_encode_mpp(uint8_t priv) {
  switch (priv) {
    case PRIV_S: return MSTATUS_MPP_S;
    case PRIV_M: return MSTATUS_MPP_M;
    default: return 0;
  }
}

static inline bool ebreak_should_raise_breakpoint_trap(void) {
#if defined(CONFIG_MODE_SYSTEM) && !defined(CONFIG_TARGET_AM)
  // Linux/system 模式必须按官方 ISA 把 ebreak 当 breakpoint trap，不能被 PA 退出协议抢走。
  return true;
#else
  return cpu.csr.mtvec != 0 || cpu.csr.stvec != 0;
#endif
}

static inline void csr_mret(Decode *s) {
  uint8_t next_priv = csr_mpp_to_priv(cpu.csr.mstatus);
  word_t mstatus = cpu.csr.mstatus;
  if (mstatus & MSTATUS_MPIE) cpu.csr.mstatus |= MSTATUS_MIE;
  else cpu.csr.mstatus &= ~MSTATUS_MIE;
  cpu.csr.mstatus |= MSTATUS_MPIE;
  cpu.csr.mstatus &= ~MSTATUS_MPP_MASK;
  if (next_priv != PRIV_M) cpu.csr.mstatus &= ~MSTATUS_MPRV;
  cpu.csr.mstatus |= MSTATUS_SXL_UXL;
  cpu.priv = next_priv;
  s->dnpc = cpu.csr.mepc;
  etrace_log_mret(s->pc, s->dnpc, cpu.csr.mstatus);
}

static inline void csr_sret(Decode *s) {
  uint8_t next_priv = (cpu.csr.mstatus & MSTATUS_SPP) ? PRIV_S : PRIV_U;
  word_t mstatus = cpu.csr.mstatus;
  if (mstatus & MSTATUS_SPIE) cpu.csr.mstatus |= MSTATUS_SIE;
  else cpu.csr.mstatus &= ~MSTATUS_SIE;
  cpu.csr.mstatus |= MSTATUS_SPIE;
  cpu.csr.mstatus &= ~MSTATUS_SPP;
  if (next_priv != PRIV_M) cpu.csr.mstatus &= ~MSTATUS_MPRV;
  cpu.csr.mstatus |= MSTATUS_SXL_UXL;
  cpu.priv = next_priv;
  s->dnpc = cpu.csr.sepc;
  syscall_debug_log_return(s->dnpc);
}

static inline bool exec_csr(uint32_t inst, uint32_t funct3, int rd, int rs1) {
  uint32_t csr = BITS(inst, 31, 20);
  word_t old_val = 0;
  word_t new_val = 0;
  word_t write_mask = 0;
  bool need_write = false;

  csr_last_sstatus_write_valid = false;
  csr_last_sstatus_write_changed = true;
  csr_last_sstatus_write_only_cleared_sie = false;
  csr_last_sstatus_write_old = 0;
  csr_last_sstatus_write_new = 0;
  csr_last_sstatus_write_delta = 0;

  if (cpu.priv < BITS(csr, 9, 8)) return false;
  if (!csr_counter_allowed(csr)) return false;
  if (!csr_read(csr, &old_val)) return false;

  switch (funct3) {
    case 0x1:
      new_val = R(rs1); write_mask = ~(word_t)0; need_write = true; break;                 // csrrw
    case 0x2:
      write_mask = R(rs1); new_val = old_val | write_mask; need_write = (rs1 != 0); break;  // csrrs
    case 0x3:
      write_mask = R(rs1); new_val = old_val & ~write_mask; need_write = (rs1 != 0); break; // csrrc
    case 0x5:
      new_val = rs1; write_mask = ~(word_t)0; need_write = true; break;                    // csrrwi
    case 0x6:
      write_mask = (word_t)rs1; new_val = old_val | write_mask; need_write = (rs1 != 0); break;
    case 0x7:
      write_mask = (word_t)rs1; new_val = old_val & ~write_mask; need_write = (rs1 != 0); break;
    default: return false;
  }

  if (need_write && !csr_write_masked(csr, new_val, write_mask)) return false;
  R(rd) = old_val;
  return true;
}
