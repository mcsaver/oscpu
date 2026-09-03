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
#include <errno.h>
#include <stdlib.h>
#include <string.h>

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
#define RS3(i)    BITS(i, 31, 27)
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
#define OPC_MADD   0x43
#define OPC_MSUB   0x47
#define OPC_NMSUB  0x4b
#define OPC_NMADD  0x4f
#define OPC_OP_FP  0x53
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

static inline bool fp_state_enabled(void) {
#ifdef CONFIG_RISCV_EXT_F
  return (cpu.csr.mstatus & MSTATUS_FS_MASK) != 0;
#else
  return false;
#endif
}

static inline void fp_mark_dirty(void) {
  cpu.csr.mstatus =
      (cpu.csr.mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY;
}

static inline word_t csr_status_sd_bit(void) {
  return (cpu.csr.mstatus & MSTATUS_FS_MASK) == MSTATUS_FS_DIRTY
             ? MSTATUS_SD
             : 0;
}

static inline word_t csr_mstatus_read_value(void) {
  return cpu.csr.mstatus | MSTATUS_SXL_UXL | csr_status_sd_bit();
}

static inline word_t csr_sstatus_read_value(void) {
  return (csr_mstatus_read_value() & SSTATUS_MASK) | csr_status_sd_bit();
}

static inline word_t csr_sanitize_mstatus(word_t value) {
  word_t next = (value & MSTATUS_WRITABLE_MASK) | MSTATUS_SXL_UXL;
#ifndef CONFIG_RISCV_EXT_F
  next &= ~MSTATUS_FS_MASK;
#endif
  /* MPP=2 is reserved; WARL-coerce it to the least supported privilege U. */
  if ((next & MSTATUS_MPP_MASK) == ((word_t)2 << 11)) {
    next &= ~MSTATUS_MPP_MASK;
  }
  return next;
}

static inline word_t csr_supervisor_interrupt_mask(void) {
  return cpu.csr.mideleg & MIDELEG_WRITABLE_MASK;
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
    case CSR_MCOUNTINHIBIT:
    case CSR_MSCRATCH:
    case CSR_MEPC:
    case CSR_MCAUSE:
    case CSR_MTVAL:
    case CSR_MIP:
    case CSR_MCYCLE:
    case CSR_MCYCLEH:
    case CSR_MINSTRET:
    case CSR_MINSTRETH:
    case CSR_CYCLE:
    case CSR_TIME:
    case CSR_INSTRET:
    case CSR_CYCLEH:
    case CSR_TIMEH:
    case CSR_INSTRETH:
    case CSR_MISA:
    case CSR_MHARTID:
      return true;
    default:
      return false;
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
    case CSR_SIP:      *value = isa_riscv32_mip_value() & csr_supervisor_interrupt_mask(); return true;
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
      cpu.csr.mstatus = (cpu.csr.mstatus & ~SSTATUS_MASK) |
                        (value & writable_mask) | MSTATUS_SXL_UXL;
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
          SIP_WRITABLE_MASK & csr_supervisor_interrupt_mask();
      cpu.csr.mip = (cpu.csr.mip & ~writable_mask) |
                    (value & writable_mask);
      return true;
    }
    case CSR_SATP:
      cpu.csr.satp = csr_sanitize_satp(value);
      CSR_DEBUG_LOG("CSR write satp=" FMT_WORD " raw=" FMT_WORD " pc=" FMT_WORD
          " priv=%u", cpu.csr.satp, value, cpu.pc, cpu.priv);
      return true;
    /* misa is fixed WARL state: writes are legal and intentionally ignored. */
    case CSR_MISA:     return true;
    case CSR_MSTATUS:  cpu.csr.mstatus = csr_sanitize_mstatus(value); return true;
    case CSR_MEDELEG:  cpu.csr.medeleg = value & MEDELEG_WRITABLE_MASK; return true;
    case CSR_MIDELEG:  cpu.csr.mideleg = value & MIDELEG_WRITABLE_MASK; return true;
    case CSR_MIE:      isa_riscv32_write_mie(value); return true;
    case CSR_MTVEC:    cpu.csr.mtvec = riscv_tvec_warl_value(value); return true;
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
    word_t writable_mask =
        write_mask & SIP_WRITABLE_MASK & csr_supervisor_interrupt_mask();
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

static inline bool riscv32_csr_access_is_legal(
    const RiscvCsrInstruction *instruction) {
  const uint32_t address = instruction->address;

  /* Every gate is checked before reading a CSR or capturing a source value. */
  if (!csr_is_implemented(address)) return false;
  if (cpu.priv < BITS(address, 9, 8)) return false;
  if (address == CSR_SATP && cpu.priv == PRIV_S &&
      (cpu.csr.mstatus & MSTATUS_TVM) != 0) return false;
  if (!csr_counter_allowed(address)) return false;
  if (instruction->access.writes_csr &&
      riscv_csr_address_is_read_only(address)) return false;
#ifdef CONFIG_RISCV_EXT_F
  if ((address == CSR_FFLAGS || address == CSR_FRM ||
       address == CSR_FCSR) && !fp_state_enabled()) return false;
#endif
  return true;
}

static inline bool riscv32_csr_capture_source(
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

static inline bool riscv32_csr_calculate_write(
    const RiscvCsrInstruction *instruction, word_t source,
    word_t old_value, word_t *new_value, word_t *write_mask) {
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

/* Check -> capture -> calculate -> CSR commit -> rd commit. */
static inline bool riscv32_execute_csr_instruction(
    const RiscvCsrInstruction *instruction) {
  word_t source = 0;
  word_t old_value = 0;
  word_t new_value = 0;
  word_t write_mask = 0;

  if (!riscv32_csr_access_is_legal(instruction)) return false;
  if (!riscv32_csr_capture_source(instruction, &source)) return false;
  if (instruction->access.reads_csr &&
      !csr_read(instruction->address, &old_value)) return false;
  if (!riscv32_csr_calculate_write(
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

static inline bool riscv32_execute_machine_return(Decode *state) {
  if (!riscv_machine_return_is_legal(cpu.priv)) return false;
  const RiscvXretTransition transition =
      riscv_machine_return_transition(cpu.csr.mstatus);
  cpu.csr.mstatus = transition.status;
  cpu.priv = transition.privilege;
  state->dnpc = cpu.csr.mepc;
  etrace_log_mret(state->pc, state->dnpc, transition.status);
  return true;
}

static inline bool riscv32_execute_supervisor_return(Decode *state) {
  if (!riscv_supervisor_return_is_legal(
          cpu.priv, cpu.csr.mstatus)) return false;
  const RiscvXretTransition transition =
      riscv_supervisor_return_transition(cpu.csr.mstatus);
  cpu.csr.mstatus = transition.status;
  cpu.priv = transition.privilege;
  state->dnpc = cpu.csr.sepc;
  return true;
}

static inline bool riscv32_execute_breakpoint(Decode *state) {
  const bool trap_vector_configured =
      cpu.csr.mtvec != 0 || cpu.csr.stvec != 0;
  if (riscv_eei_ebreak_requests_halt(trap_vector_configured)) {
    NEMUTRAP(state->pc, R(10));
  } else {
    state->dnpc = isa_raise_intr(CAUSE_BREAKPOINT, state->pc);
  }
  return true;
}

static inline bool riscv32_execute_system(
    Decode *state, const RiscvSystemInstruction *instruction) {
  switch (instruction->operation) {
    case RISCV_SYSTEM_OPERATION_ECALL:
      state->dnpc = isa_raise_intr(
          riscv_environment_call_cause(cpu.priv), state->pc);
      return true;
    case RISCV_SYSTEM_OPERATION_EBREAK:
      return riscv32_execute_breakpoint(state);
    case RISCV_SYSTEM_OPERATION_SRET:
      return riscv32_execute_supervisor_return(state);
    case RISCV_SYSTEM_OPERATION_MRET:
      return riscv32_execute_machine_return(state);
    case RISCV_SYSTEM_OPERATION_WFI:
      if (!riscv_wait_for_interrupt_is_legal(
              cpu.priv, cpu.csr.mstatus)) return false;
      isa_riscv32_wfi();
      return true;
    case RISCV_SYSTEM_OPERATION_SFENCE_VMA: {
      if (!riscv_sfence_vma_is_legal(
              cpu.priv, cpu.csr.mstatus)) return false;
      const uint8_t rs1 = instruction->source_register_1;
      const uint8_t rs2 = instruction->source_register_2;
      isa_riscv32_mmu_tlb_flush_selective(
          R(rs1), rs1 != 0, R(rs2), rs2 != 0);
      return true;
    }
    case RISCV_SYSTEM_OPERATION_CSRRW:
    case RISCV_SYSTEM_OPERATION_CSRRS:
    case RISCV_SYSTEM_OPERATION_CSRRC:
    case RISCV_SYSTEM_OPERATION_CSRRWI:
    case RISCV_SYSTEM_OPERATION_CSRRSI:
    case RISCV_SYSTEM_OPERATION_CSRRCI:
      return riscv32_execute_csr_instruction(&instruction->csr);
    default:
      return false;
  }
}

#include "inst/decode.c"
#include "inst/muldiv.c"
#include "inst/bitmanip.c"
#include "inst/amo.c"
#include "inst/fp.c"
#include "inst/compressed.c"
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
