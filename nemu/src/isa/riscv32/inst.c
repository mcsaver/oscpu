/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "local-include/reg.h"
#include "local-include/instruction.h"
#include <cpu/cpu.h>
#include <cpu/ifetch.h>
#include <cpu/decode.h>
#include <isa/riscv/pmp.h>
#include <memory/cache.h>
#include <memory/vaddr.h>
#include <ftrace.h>
#include <etrace.h>

/* 基础设施：寄存器/访存入口、字段提取和少量规范常量都放在文件开头。
 * 执行层只通过这些窄接口读写状态，后续扩指令不再到处散落位切片。 */
#define R(i) MUXDEF(CONFIG_RVE, gpr(i), cpu.gpr[(i)])
#define F(i) (cpu.fpr[(i)])
#define Mr vaddr_read
#define Mw vaddr_write

#define XLEN_BITS ((uint32_t)(sizeof(word_t) * 8))
#define WORD_SIGN_BIT ((word_t)1 << (XLEN_BITS - 1))

#define OPCODE(i) BITS(i, 6, 0)
#define RD(i)     BITS(i, 11, 7)
#define FUNCT3(i) BITS(i, 14, 12)
#define RS1(i)    BITS(i, 19, 15)
#define RS2(i)    BITS(i, 24, 20)
#define FUNCT7(i) BITS(i, 31, 25)

#define IMM_I(i) SEXT(BITS(i, 31, 20), 12)
#define IMM_U(i) (SEXT(BITS(i, 31, 12), 20) << 12)
#define IMM_S(i) ((SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7))
#define IMM_B(i) SEXT((BITS(i, 31, 31) << 12 | BITS(i, 7, 7) << 11 | \
                       BITS(i, 30, 25) << 5  | BITS(i, 11, 8) << 1), 13)
#define IMM_J(i) SEXT((BITS(i, 31, 31) << 20 | BITS(i, 19, 12) << 12 | \
                       BITS(i, 20, 20) << 11 | BITS(i, 30, 21) << 1), 21)

#define OPC_LOAD   0x03
#define OPC_LOAD_FP 0x07
#define OPC_MISC_MEM 0x0f
#define OPC_OP_IMM 0x13
#define OPC_AUIPC  0x17
#define OPC_STORE  0x23
#define OPC_STORE_FP 0x27
#define OPC_AMO    0x2f
#define OPC_OP     0x33
#define OPC_LUI    0x37
#define OPC_BRANCH 0x63
#define OPC_JALR   0x67
#define OPC_JAL    0x6f
#define OPC_SYSTEM 0x73

#define OP_KEY(funct3, funct7) \
  ((uint32_t)((((uint32_t)(funct7) & 0x7fu) << 3) | \
              ((uint32_t)(funct3) & 0x7u)))
#define SHAMT5(value) ((value) & 0x1f)
#define SHAMT_XLEN(value) ((value) & (XLEN_BITS - 1))
#define BAD_DECODE() return false

#ifdef CONFIG_RISCV_EXT_A
static bool lr_reservation_valid = false;
static word_t lr_reservation_addr = 0;
static int lr_reservation_len = 0;

static inline bool lr_sc_range_overlap(paddr_t lhs_start, int lhs_len,
    paddr_t rhs_start, int rhs_len) {
  paddr_t lhs_end = lhs_start + (paddr_t)lhs_len;
  paddr_t rhs_end = rhs_start + (paddr_t)rhs_len;
  return lhs_start < rhs_end && rhs_start < lhs_end;
}

void isa_riscv32_lr_sc_invalidate(paddr_t paddr, int len) {
  if (!lr_reservation_valid) return;
  if (lr_sc_range_overlap((paddr_t)lr_reservation_addr, lr_reservation_len, paddr, len)) {
    lr_reservation_valid = false;
  }
}
#else
void isa_riscv32_lr_sc_invalidate(paddr_t paddr, int len) {
  (void)paddr;
  (void)len;
}
#endif

#ifdef CONFIG_RISCV_DEBUG_LOG
static int csr_boot_log_budget = 8;
#define CSR_DEBUG_LOG(...) do { \
  if (csr_boot_log_budget > 0) { \
    csr_boot_log_budget--; \
    Log(__VA_ARGS__); \
  } \
} while (0)
#else
#define CSR_DEBUG_LOG(...) do {} while (0)
#endif

/* CSR 执行基础设施集中在这里。SYSTEM 分发只决定“是哪类系统指令”，
 * CSR 的读改写语义、misa 配置回显和 mepc 对齐规则都不散到主 switch 里。 */
static inline word_t csr_misa_value() {
  word_t misa = (word_t)1 << 30;
#ifdef CONFIG_RVE
  misa |= (word_t)1 << ('E' - 'A');
#else
  misa |= (word_t)1 << ('I' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_M
  misa |= (word_t)1 << ('M' - 'A');
#endif
#ifdef CONFIG_RISCV_EXT_A
  misa |= (word_t)1 << ('A' - 'A');
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

static inline word_t csr_sanitize_satp(word_t value) {
  return value;
}

/* RV32 packs four 8-bit PMP configurations into each pmpcfg CSR. */
static inline bool csr_pmpcfg_base(uint32_t csr, uint32_t *base) {
  if (csr < CSR_PMPCFG0 || csr > CSR_PMPCFG3) return false;
  *base = (csr - CSR_PMPCFG0) * 4;
  return true;
}

static inline bool csr_pmpaddr_write_locked(uint32_t index) {
  if ((cpu.csr.pmpcfg[index] & RISCV_PMP_LOCKED) != 0) return true;
  return index + 1 < RISCV_PMP_ENTRY_COUNT &&
         (cpu.csr.pmpcfg[index + 1] & RISCV_PMP_LOCKED) != 0 &&
         riscv_pmp_address_matching(cpu.csr.pmpcfg[index + 1]) ==
             RISCV_PMP_TOR;
}

static inline void csr_update_pmp_active(void) {
  cpu.csr.pmp_active = false;
  for (uint32_t index = 0; index < RISCV_PMP_ENTRY_COUNT; index++) {
    if (riscv_pmp_address_matching(cpu.csr.pmpcfg[index]) !=
        RISCV_PMP_OFF) {
      cpu.csr.pmp_active = true;
      return;
    }
  }
}

static inline word_t csr_read_pmpcfg(uint32_t base) {
  word_t value = 0;
  for (uint32_t byte = 0; byte < 4; byte++) {
    value |= (word_t)cpu.csr.pmpcfg[base + byte] << (byte * 8);
  }
  return value;
}

static inline void csr_write_pmpcfg(uint32_t base, word_t value) {
  bool changed = false;
  for (uint32_t byte = 0; byte < 4; byte++) {
    uint32_t index = base + byte;
    if ((cpu.csr.pmpcfg[index] & RISCV_PMP_LOCKED) != 0) continue;
    uint8_t next = riscv_pmp_sanitize_config(
        (uint8_t)(value >> (byte * 8)));
    if (cpu.csr.pmpcfg[index] != next) {
      cpu.csr.pmpcfg[index] = next;
      changed = true;
    }
  }
  if (changed) {
    csr_update_pmp_active();
    isa_riscv32_mmu_tlb_flush();
  }
}

static inline void csr_write_pmpaddr(uint32_t index, word_t value) {
  if (csr_pmpaddr_write_locked(index)) return;
  word_t next = value & PMPADDR_MASK;
  if (cpu.csr.pmpaddr[index] != next) {
    cpu.csr.pmpaddr[index] = next;
    isa_riscv32_mmu_tlb_flush();
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
    case CSR_SSTATUS:  *value = (cpu.csr.mstatus | MSTATUS_SXL_UXL) & SSTATUS_MASK; return true;
    case CSR_SIE:      *value = cpu.csr.mie & MIP_SUPERVISOR_MASK; return true;
    case CSR_STVEC:    *value = cpu.csr.stvec; return true;
    case CSR_SCOUNTEREN: *value = cpu.csr.scounteren; return true;
    case CSR_SSCRATCH: *value = cpu.csr.sscratch; return true;
    case CSR_SEPC:     *value = cpu.csr.sepc; return true;
    case CSR_SCAUSE:   *value = cpu.csr.scause; return true;
    case CSR_STVAL:    *value = cpu.csr.stval; return true;
    case CSR_SIP:      *value = isa_riscv32_mip_value() & MIP_SUPERVISOR_MASK; return true;
    case CSR_SATP:     *value = cpu.csr.satp; return true;
    case CSR_MSTATUS:  *value = cpu.csr.mstatus; return true;
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
    case CSR_MIP:      *value = isa_riscv32_mip_value(); return true;
    case CSR_MCYCLE:   *value = (word_t)cpu.csr.mcycle; return true;
    case CSR_MCYCLEH:  *value = (word_t)(cpu.csr.mcycle >> 32); return true;
    case CSR_MINSTRET: *value = (word_t)cpu.csr.minstret; return true;
    case CSR_MINSTRETH:*value = (word_t)(cpu.csr.minstret >> 32); return true;
    case CSR_CYCLE:    *value = (word_t)cpu.csr.mcycle; return true;
    case CSR_CYCLEH:   *value = (word_t)(cpu.csr.mcycle >> 32); return true;
    // time/timeh 暴露平台 CLINT mtime，避免 guest 时间源和 mcycle 统计混在一起。
    case CSR_TIME:     *value = (word_t)isa_riscv32_mtime_value(); return true;
    case CSR_TIMEH:    *value = (word_t)(isa_riscv32_mtime_value() >> 32); return true;
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
    case CSR_SSTATUS:
      cpu.csr.mstatus = (cpu.csr.mstatus & ~SSTATUS_MASK) |
                        (value & SSTATUS_MASK) | MSTATUS_SXL_UXL;
      return true;
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
    case CSR_SIP:
      cpu.csr.mip = (cpu.csr.mip & ~SIP_WRITABLE_MASK) |
                    (value & SIP_WRITABLE_MASK);
      return true;
    case CSR_SATP:
      cpu.csr.satp = csr_sanitize_satp(value);
      CSR_DEBUG_LOG("CSR write satp=" FMT_WORD " raw=" FMT_WORD " pc=" FMT_WORD
          " priv=%u", cpu.csr.satp, value, cpu.pc, cpu.priv);
      return true;
    case CSR_MSTATUS:  cpu.csr.mstatus = (value & MSTATUS_WRITABLE_MASK) | MSTATUS_SXL_UXL; return true;
    case CSR_MEDELEG:  cpu.csr.medeleg = value; return true;
    case CSR_MIDELEG:  cpu.csr.mideleg = value; return true;
    case CSR_MIE:      isa_riscv32_write_mie(value); return true;
    case CSR_MTVEC:    cpu.csr.mtvec = value & ~(word_t)0x3; return true;
    case CSR_MCOUNTEREN: cpu.csr.mcounteren = value & COUNTEREN_MASK; return true;
    case CSR_MCOUNTINHIBIT: cpu.csr.mcountinhibit = value & (MCOUNTINHIBIT_CY | MCOUNTINHIBIT_IR); return true;
    case CSR_MSCRATCH: cpu.csr.mscratch = value; return true;
    case CSR_MEPC:     cpu.csr.mepc = value & mepc_mask; return true;
    case CSR_MCAUSE:   cpu.csr.mcause = value; return true;
    case CSR_MTVAL:    cpu.csr.mtval = value; return true;
    case CSR_MIP:      isa_riscv32_write_mip(value); return true;
    case CSR_MCYCLE:   isa_riscv32_write_mcycle_lo(value); return true;
    case CSR_MCYCLEH:  isa_riscv32_write_mcycle_hi(value); return true;
    case CSR_MINSTRET: cpu.csr.minstret = (cpu.csr.minstret & 0xffffffff00000000ull) | (uint32_t)value; return true;
    case CSR_MINSTRETH: cpu.csr.minstret = ((uint64_t)(uint32_t)value << 32) | (uint32_t)cpu.csr.minstret; return true;
    default: return false;
  }
}

static inline bool csr_write_masked(uint32_t csr, word_t value, word_t write_mask) {
  if (csr == CSR_SIP) {
    word_t writable_mask = write_mask & SIP_WRITABLE_MASK;
    cpu.csr.mip = (cpu.csr.mip & ~writable_mask) | (value & writable_mask);
    return true;
  }

  if (csr == CSR_MIP) {
    word_t merged = (cpu.csr.mip & ~write_mask) | (value & write_mask);
    isa_riscv32_write_mip(merged);
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
#ifndef CONFIG_TARGET_AM
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
}

static inline bool exec_csr(uint32_t inst, uint32_t funct3, int rd, int rs1) {
  uint32_t csr = BITS(inst, 31, 20);
  word_t old_val = 0;
  word_t new_val = 0;
  word_t write_mask = 0;
  bool need_write = false;

  if (cpu.priv < BITS(csr, 9, 8)) return false;
  /* TVM makes satp inaccessible to S-mode; M-mode remains unrestricted. */
  if (csr == CSR_SATP && cpu.priv == PRIV_S &&
      (cpu.csr.mstatus & MSTATUS_TVM) != 0) return false;
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

/* 压缩指令适配器仍复用旧的基础整数加载入口。 */
static inline bool legacy_exec_rv32i_load(
    uint32_t funct3, int rd, word_t addr) {
  word_t val = 0;
  switch (funct3) {
    case 0x0:
      val = Mr(addr, 1);
      if (vaddr_has_fault()) return true;
      R(rd) = SEXT(val, 8); return true;  // lb
    case 0x1:
      val = Mr(addr, 2);
      if (vaddr_has_fault()) return true;
      R(rd) = SEXT(val, 16); return true; // lh
    case 0x2:
      val = Mr(addr, 4);
      if (vaddr_has_fault()) return true;
      R(rd) = SEXT(val, 32); return true; // lw
    case 0x4:
      val = Mr(addr, 1);
      if (vaddr_has_fault()) return true;
      R(rd) = val; return true;           // lbu
    case 0x5:
      val = Mr(addr, 2);
      if (vaddr_has_fault()) return true;
      R(rd) = val; return true;           // lhu
    default: return false;
  }
}

static inline bool fp_state_enabled(void) {
  return (cpu.csr.mstatus & MSTATUS_FS_MASK) != 0;
}

static inline void fp_mark_dirty(void) {
  cpu.csr.mstatus = (cpu.csr.mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY;
}

static inline bool exec_rvf_load(uint32_t funct3, int rd, word_t addr) {
  if (!fp_state_enabled()) return false;
  switch (funct3) {
#ifdef CONFIG_RISCV_EXT_F
    case 0x2: { // flw
      word_t val = Mr(addr, 4);
      if (vaddr_has_fault()) return true;
      F(rd) = 0xffffffff00000000ull | (uint32_t)val;
      fp_mark_dirty();
      return true;
    }
#endif
#ifdef CONFIG_RISCV_EXT_D
    case 0x3: { // fld
      word_t val = Mr(addr, 8);
      if (vaddr_has_fault()) return true;
      F(rd) = val;
      fp_mark_dirty();
      return true;
    }
#endif
    default:
      return false;
  }
}

static inline bool exec_rvf_store(uint32_t funct3, word_t addr, int rs2) {
  if (!fp_state_enabled()) return false;
  switch (funct3) {
#ifdef CONFIG_RISCV_EXT_F
    case 0x2: // fsw
      Mw(addr, 4, (uint32_t)F(rs2));
      return true;
#endif
#ifdef CONFIG_RISCV_EXT_D
    case 0x3: // fsd
      Mw(addr, 8, F(rs2));
      return true;
#endif
    default:
      return false;
  }
}

static inline bool exec_system(Decode *s, uint32_t inst, uint32_t funct3, int rd, int rs1) {
  if (funct3 != 0) return exec_csr(inst, funct3, rd, rs1);

  switch (inst) {
    case 0x00000073: // ecall
      s->dnpc = isa_raise_intr(
          cpu.priv == PRIV_M ? CAUSE_ECALL_M :
          cpu.priv == PRIV_S ? CAUSE_ECALL_S : CAUSE_ECALL_U,
          s->pc);
      return true;
    case 0x00100073: // ebreak
      if (ebreak_should_raise_breakpoint_trap()) {
        s->dnpc = isa_raise_intr(CAUSE_BREAKPOINT, s->pc);
      } else {
        NEMUTRAP(s->pc, R(10));
      }
      return true;
    case 0x10200073: // sret
      if (cpu.priv < PRIV_S) return false;
      if (cpu.priv == PRIV_S && (cpu.csr.mstatus & MSTATUS_TSR)) return false;
      csr_sret(s);
      return true;
    case 0x30200073: // mret
      if (cpu.priv != PRIV_M) return false;
      csr_mret(s);
      return true;
    case 0x10500073: // wfi
      if (cpu.priv != PRIV_M && (cpu.csr.mstatus & MSTATUS_TW)) return false;
      return true;
    default:
      if ((inst & 0xfe007fffu) == 0x12000073u) { // sfence.vma
        if (cpu.priv < PRIV_S) return false;
        if (cpu.priv == PRIV_S && (cpu.csr.mstatus & MSTATUS_TVM)) return false;
        uint32_t fence_vaddr_register = RS1(inst);
        uint32_t fence_asid_register = RS2(inst);
        isa_riscv32_mmu_tlb_flush_selective(
            R(fence_vaddr_register), fence_vaddr_register != 0,
            R(fence_asid_register), fence_asid_register != 0);
        return true;
      }
      return false;
  }
}

#ifdef CONFIG_RISCV_EXT_A
static inline word_t amo_sext_word(uint32_t value) {
  return (word_t)value;
}

static inline bool amo_funct5_valid(uint32_t funct5) {
  switch (funct5) {
    case 0x00: case 0x01: case 0x04: case 0x08: case 0x0c:
    case 0x10: case 0x14: case 0x18: case 0x1c:
      return true;
    default:
      return false;
  }
}

static inline uint32_t amo_compute_w(uint32_t old, uint32_t src, uint32_t funct5) {
  switch (funct5) {
    case 0x01: return src;                                      // amoswap.w
    case 0x00: return old + src;                                // amoadd.w
    case 0x04: return old ^ src;                                // amoxor.w
    case 0x0c: return old & src;                                // amoand.w
    case 0x08: return old | src;                                // amoor.w
    case 0x10: return (int32_t)old < (int32_t)src ? old : src;  // amomin.w
    case 0x14: return (int32_t)old > (int32_t)src ? old : src;  // amomax.w
    case 0x18: return old < src ? old : src;                    // amominu.w
    case 0x1c: return old > src ? old : src;                    // amomaxu.w
    default: return old;
  }
}

static inline bool amo_raise_misaligned(word_t addr, uint32_t funct5) {
  // AMO/LR/SC 编码有效但地址不对齐时应投递地址异常，不能退化成 illegal instruction。
  vaddr_set_fault(funct5 == 0x02 ? CAUSE_LOAD_MISALIGNED : CAUSE_STORE_MISALIGNED, addr);
  return true;
}

static inline bool exec_rva_amo(uint32_t inst, int rd, int rs1, int rs2) {
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct5 = BITS(inst, 31, 27);
  word_t addr = R(rs1);

  if (funct3 == 0x2) {
    if (funct5 == 0x02) {                                      // lr.w
      if ((addr & 0x3) != 0) return amo_raise_misaligned(addr, funct5);
      uint32_t old = Mr(addr, 4);
      if (vaddr_has_fault()) return true;
      lr_reservation_valid = true;
      lr_reservation_addr = addr;
      lr_reservation_len = 4;
      R(rd) = amo_sext_word(old);
      return true;
    }
    if (funct5 == 0x03) {                                      // sc.w
      if ((addr & 0x3) != 0) return amo_raise_misaligned(addr, funct5);
      bool ok = lr_reservation_valid && lr_reservation_addr == addr;
      if (ok) {
        Mw(addr, 4, (uint32_t)R(rs2));
        if (vaddr_has_fault()) return true;
      }
      lr_reservation_valid = false;
      R(rd) = ok ? 0 : 1;
      return true;
    }
    if (!amo_funct5_valid(funct5)) return false;
    if ((addr & 0x3) != 0) return amo_raise_misaligned(addr, funct5);

    uint32_t old = Mr(addr, 4);
    if (vaddr_has_fault()) return true;
    uint32_t result = amo_compute_w(old, (uint32_t)R(rs2), funct5);
    Mw(addr, 4, result);
    if (vaddr_has_fault()) return true;
    lr_reservation_valid = false;
    R(rd) = amo_sext_word(old);
    return true;
  }

  return false;
}
#endif

#ifdef CONFIG_RISCV_EXT_C
/* RV32C 扩展：可变长取指只负责拿到 16/32 位原始指令，压缩语义全部收口在本块。 */
#define C_FUNCT3(i) BITS(i, 15, 13)
#define C_RD(i)     (8 + BITS(i, 4, 2))
#define C_RS1(i)    (8 + BITS(i, 9, 7))
#define C_RS2(i)    (8 + BITS(i, 4, 2))

static inline word_t c_imm_addi4spn(uint16_t inst) {
  return (BITS(inst, 10, 7) << 6) |
         (BITS(inst, 12, 11) << 4) |
         (BITS(inst, 5, 5) << 3) |
         (BITS(inst, 6, 6) << 2);
}

static inline word_t c_imm_lw_sw(uint16_t inst) {
  return (BITS(inst, 5, 5) << 6) |
         (BITS(inst, 12, 10) << 3) |
         (BITS(inst, 6, 6) << 2);
}

static inline word_t c_imm_ld_sd(uint16_t inst) {
  return (BITS(inst, 6, 5) << 6) |
         (BITS(inst, 12, 10) << 3);
}

static inline word_t c_imm_6(uint16_t inst) {
  return SEXT((BITS(inst, 12, 12) << 5) | BITS(inst, 6, 2), 6);
}

static inline word_t c_imm_j(uint16_t inst) {
  uint32_t imm = (BITS(inst, 12, 12) << 11) |
                 (BITS(inst, 11, 11) << 4) |
                 (BITS(inst, 10, 9) << 8) |
                 (BITS(inst, 8, 8) << 10) |
                 (BITS(inst, 7, 7) << 6) |
                 (BITS(inst, 6, 6) << 7) |
                 (BITS(inst, 5, 3) << 1) |
                 (BITS(inst, 2, 2) << 5);
  return SEXT(imm, 12);
}

static inline word_t c_imm_addi16sp(uint16_t inst) {
  uint32_t imm = (BITS(inst, 12, 12) << 9) |
                 (BITS(inst, 6, 6) << 4) |
                 (BITS(inst, 5, 5) << 6) |
                 (BITS(inst, 4, 3) << 7) |
                 (BITS(inst, 2, 2) << 5);
  return SEXT(imm, 10);
}

static inline word_t c_imm_b(uint16_t inst) {
  uint32_t imm = (BITS(inst, 12, 12) << 8) |
                 (BITS(inst, 11, 10) << 3) |
                 (BITS(inst, 6, 5) << 6) |
                 (BITS(inst, 4, 3) << 1) |
                 (BITS(inst, 2, 2) << 5);
  return SEXT(imm, 9);
}

static inline word_t c_imm_lwsp(uint16_t inst) {
  return (BITS(inst, 12, 12) << 5) |
         (BITS(inst, 6, 4) << 2) |
         (BITS(inst, 3, 2) << 6);
}

static inline word_t c_imm_ldsp(uint16_t inst) {
  return (BITS(inst, 12, 12) << 5) |
         (BITS(inst, 6, 5) << 3) |
         (BITS(inst, 4, 2) << 6);
}

static inline word_t c_imm_swsp(uint16_t inst) {
  return (BITS(inst, 8, 7) << 6) |
         (BITS(inst, 12, 9) << 2);
}

static inline word_t c_imm_sdsp(uint16_t inst) {
  return (BITS(inst, 9, 7) << 6) |
         (BITS(inst, 12, 10) << 3);
}

static inline word_t c_shamt(uint16_t inst) {
  return (BITS(inst, 12, 12) << 5) | BITS(inst, 6, 2);
}

static inline bool exec_rv32c(Decode *s, uint16_t inst) {
  uint32_t funct3 = C_FUNCT3(inst);
  uint32_t rd = BITS(inst, 11, 7);
  uint32_t rs2 = BITS(inst, 6, 2);

  switch (BITS(inst, 1, 0)) {
    case 0x0:
      switch (funct3) {
        case 0x0: { // c.addi4spn
          word_t imm = c_imm_addi4spn(inst);
          if (imm == 0) BAD_DECODE();
          R(C_RD(inst)) = R(2) + imm;
          return true;
        }
        case 0x1: // c.fld
          if (!ISDEF(CONFIG_RISCV_EXT_D) ||
              !exec_rvf_load(0x3, C_RD(inst), R(C_RS1(inst)) + c_imm_ld_sd(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x2: // c.lw
          if (!legacy_exec_rv32i_load(
                  0x2, C_RD(inst), R(C_RS1(inst)) + c_imm_lw_sw(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x3:
          BAD_DECODE();
        case 0x6: // c.sw
          Mw(R(C_RS1(inst)) + c_imm_lw_sw(inst), 4, R(C_RS2(inst)));
          return true;
        case 0x5: // c.fsd
          if (!ISDEF(CONFIG_RISCV_EXT_D) ||
              !exec_rvf_store(0x3, R(C_RS1(inst)) + c_imm_ld_sd(inst), C_RS2(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x7:
          BAD_DECODE();
        default:
          BAD_DECODE();
      }
    case 0x1:
      switch (funct3) {
        case 0x0: // c.addi / c.nop
          R(rd) = R(rd) + c_imm_6(inst);
          return true;
        case 0x1:
          R(1) = s->pc + 2;                                  // c.jal
          s->dnpc = s->pc + c_imm_j(inst);
          IFDEF(CONFIG_FTRACE, ftrace_log(1, s->pc, s->dnpc));
          return true;
        case 0x2: // c.li
          if (rd != 0) R(rd) = c_imm_6(inst);
          return true;
        case 0x3:
          if (rd == 2) { // c.addi16sp
            word_t imm = c_imm_addi16sp(inst);
            if (imm == 0) BAD_DECODE();
            R(2) = R(2) + imm;
          } else { // c.lui
            word_t imm = c_imm_6(inst);
            if (rd == 0 || imm == 0) BAD_DECODE();
            R(rd) = imm << 12;
          }
          return true;
        case 0x4: {
          uint32_t rs1p = C_RS1(inst);
          uint32_t rs2p = C_RS2(inst);
          switch (BITS(inst, 11, 10)) {
            case 0x0: // c.srli
              if (BITS(inst, 12, 12)) BAD_DECODE();
              R(rs1p) = R(rs1p) >> c_shamt(inst);
              return true;
            case 0x1: // c.srai
              if (BITS(inst, 12, 12)) BAD_DECODE();
              R(rs1p) = (sword_t)R(rs1p) >> c_shamt(inst);
              return true;
            case 0x2: // c.andi
              R(rs1p) = R(rs1p) & c_imm_6(inst);
              return true;
            case 0x3:
              switch ((BITS(inst, 12, 12) << 2) | BITS(inst, 6, 5)) {
                case 0x0: R(rs1p) = R(rs1p) - R(rs2p); return true; // c.sub
                case 0x1: R(rs1p) = R(rs1p) ^ R(rs2p); return true; // c.xor
                case 0x2: R(rs1p) = R(rs1p) | R(rs2p); return true; // c.or
                case 0x3: R(rs1p) = R(rs1p) & R(rs2p); return true; // c.and
                case 0x4:
                case 0x5:
                  BAD_DECODE();
                default: BAD_DECODE();
              }
            default:
              BAD_DECODE();
          }
        }
        case 0x5: // c.j
          s->dnpc = s->pc + c_imm_j(inst);
          return true;
        case 0x6: // c.beqz
          if (R(C_RS1(inst)) == 0) s->dnpc = s->pc + c_imm_b(inst);
          return true;
        case 0x7: // c.bnez
          if (R(C_RS1(inst)) != 0) s->dnpc = s->pc + c_imm_b(inst);
          return true;
        default:
          BAD_DECODE();
      }
    case 0x2:
      switch (funct3) {
        case 0x0: // c.slli
          if (BITS(inst, 12, 12)) BAD_DECODE();
          R(rd) = R(rd) << c_shamt(inst);
          return true;
        case 0x1: // c.fldsp
          if (rd == 0 || !ISDEF(CONFIG_RISCV_EXT_D) ||
              !exec_rvf_load(0x3, rd, R(2) + c_imm_ldsp(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x2: // c.lwsp
          if (rd == 0) BAD_DECODE();
          if (!legacy_exec_rv32i_load(0x2, rd, R(2) + c_imm_lwsp(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x3:
          BAD_DECODE();
        case 0x4:
          if (BITS(inst, 12, 12) == 0) {
            if (rs2 == 0) { // c.jr
              if (rd == 0) BAD_DECODE();
              s->dnpc = R(rd) & ~(word_t)1;
              IFDEF(CONFIG_FTRACE, if (rd == 1) ftrace_log(-1, s->pc, s->dnpc));
            } else if (rd != 0) { // c.mv
              R(rd) = R(rs2);
            }
          } else {
            if (rs2 == 0) {
              if (rd == 0) {
                if (ebreak_should_raise_breakpoint_trap()) {
                  s->dnpc = isa_raise_intr(CAUSE_BREAKPOINT, s->pc);
                } else {
                  NEMUTRAP(s->pc, R(10)); // c.ebreak
                }
              } else { // c.jalr
                word_t target = R(rd) & ~(word_t)1;
                R(1) = s->pc + 2;
                s->dnpc = target;
                IFDEF(CONFIG_FTRACE, ftrace_log(1, s->pc, target));
              }
            } else if (rd != 0) { // c.add
              R(rd) = R(rd) + R(rs2);
            }
          }
          return true;
        case 0x6: // c.swsp
          Mw(R(2) + c_imm_swsp(inst), 4, R(rs2));
          return true;
        case 0x5: // c.fsdsp
          if (!ISDEF(CONFIG_RISCV_EXT_D) ||
              !exec_rvf_store(0x3, R(2) + c_imm_sdsp(inst), rs2)) {
            BAD_DECODE();
          }
          return true;
        case 0x7:
          BAD_DECODE();
        default:
          BAD_DECODE();
      }
    default:
      BAD_DECODE();
  }
}
#endif

/*
 * 这些函数是尚未迁移扩展的唯一兼容边界。统一执行器按具名 adapter
 * 调用它们，旧 helper 不再承担顶层 opcode 分发。
 */
static inline bool legacy_execute_compressed_adapter(
    Decode *state, const Rv32DecodedInstruction *instruction) {
#ifdef CONFIG_RISCV_EXT_C
  return exec_rv32c(state, (uint16_t)instruction->encoding);
#else
  (void)state;
  (void)instruction;
  return false;
#endif
}

static inline bool legacy_execute_floating_load_adapter(
    const Rv32DecodedInstruction *instruction) {
  const word_t address = R(instruction->rs1) + instruction->immediate;
  return exec_rvf_load(
      FUNCT3(instruction->encoding), instruction->rd, address);
}

static inline bool legacy_execute_floating_store_adapter(
    const Rv32DecodedInstruction *instruction) {
  const word_t address = R(instruction->rs1) + instruction->immediate;
  return exec_rvf_store(
      FUNCT3(instruction->encoding), address, instruction->rs2);
}

static inline bool legacy_execute_atomic_adapter(
    const Rv32DecodedInstruction *instruction) {
#ifdef CONFIG_RISCV_EXT_A
  return exec_rva_amo(
      instruction->encoding, instruction->rd,
      instruction->rs1, instruction->rs2);
#else
  (void)instruction;
  return false;
#endif
}

static inline bool legacy_execute_system_adapter(
    Decode *state, const Rv32DecodedInstruction *instruction) {
  return exec_system(
      state, instruction->encoding, FUNCT3(instruction->encoding),
      instruction->rd, instruction->rs1);
}

#include "inst/decode.c"
#include "inst/muldiv.c"
#include "inst/bitmanip.c"
#include "inst/execute.c"

static int decode_exec(Decode *s) {
  Rv32DecodedInstruction instruction;
  rv32_decode_instruction(s->isa.inst, &instruction);
  if (!rv32_execute_decoded_instruction(s, &instruction)) {
    s->dnpc = isa_raise_intr_with_tval(
        CAUSE_ILLEGAL_INST, s->pc, s->isa.inst);
  }

  /* 旧适配器完全迁移前，这里仍作为兼容性断言边界。 */
  R(0) = 0;
  return 0;
}

static inline bool take_vaddr_fault(Decode *s) {
  if (likely(!vaddr_has_fault())) return false;
  word_t cause;
  vaddr_t tval;
  if (!vaddr_take_fault(&cause, &tval)) return false;
  s->dnpc = isa_raise_intr_with_tval(cause, s->pc, tval);
  R(0) = 0;
  return true;
}

int isa_exec_once(Decode *s) {
#ifdef CONFIG_RISCV_EXT_C
  uint32_t inst = inst_fetch(&s->snpc, 2);
  if (take_vaddr_fault(s)) {
    s->isa.inst = 0;
    return 0;
  }
  if ((inst & 0x3) == 0x3) {
    inst |= inst_fetch(&s->snpc, 2) << 16;
    if (take_vaddr_fault(s)) {
      s->isa.inst = 0;
      return 0;
    }
  }
  s->isa.inst = inst;
#else
  s->isa.inst = inst_fetch(&s->snpc, 4);
  if (take_vaddr_fault(s)) return 0;
#endif
  int ret = decode_exec(s);
  take_vaddr_fault(s);
  return ret;
}
