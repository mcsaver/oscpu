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
#include <cpu/cpu.h>
#include <cpu/ifetch.h>
#include <cpu/decode.h>
#include <memory/cache.h>
#include <ftrace.h>
#include <etrace.h>
#include <string.h>

/* 基础设施：寄存器/访存入口、字段提取和少量规范常量都放在文件开头。
 * 执行层只通过这些窄接口读写状态，后续扩指令不再到处散落位切片。 */
#define R(i) gpr(i)
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
#define FUNCT2(i) BITS(i, 26, 25)
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
#define OPC_OP_IMM_32 0x1b
#define OPC_AUIPC  0x17
#define OPC_STORE  0x23
#define OPC_STORE_FP 0x27
#define OPC_AMO    0x2f
#define OPC_OP     0x33
#define OPC_OP_32  0x3b
#define OPC_MADD   0x43
#define OPC_MSUB   0x47
#define OPC_NMSUB  0x4b
#define OPC_NMADD  0x4f
#define OPC_OP_FP  0x53
#define OPC_LUI    0x37
#define OPC_BRANCH 0x63
#define OPC_JALR   0x67
#define OPC_JAL    0x6f
#define OPC_SYSTEM 0x73

#define FFLAGS_NV 0x10u

#define OP_KEY(funct3, funct7) ((((funct7) & 0x7f) << 3) | ((funct3) & 0x7))
#define SHAMT5(value) ((value) & 0x1f)
#define SHAMT_XLEN(value) ((value) & (XLEN_BITS - 1))
#define BAD_DECODE() return false

#ifdef CONFIG_RISCV_EXT_A
static bool lr_reservation_valid = false;
static word_t lr_reservation_addr = 0;
#endif

#ifdef CONFIG_INTERPRETER_DECODE_CACHE
#define RV_DECODE_CACHE_ENTRIES 8192

typedef enum {
  RV_DC_NONE = 0,
  RV_DC_RVC,
  RV_DC_OP_IMM,
  RV_DC_OP_IMM_32,
  RV_DC_LOAD,
  RV_DC_LOAD_FP,
  RV_DC_STORE,
  RV_DC_STORE_FP,
  RV_DC_AMO,
  RV_DC_OP,
  RV_DC_OP_32,
  RV_DC_BRANCH,
  RV_DC_JALR,
  RV_DC_JAL,
  RV_DC_LUI,
  RV_DC_AUIPC,
} RvDecodeCacheKind;

typedef struct {
  vaddr_t pc;
  uint32_t inst_key;
  word_t imm;
  uint8_t kind;
  uint8_t rd;
  uint8_t rs1;
  uint8_t rs2;
  uint8_t funct3;
  uint8_t funct7;
} RvDecodeCacheEntry;

static RvDecodeCacheEntry rv_decode_cache[RV_DECODE_CACHE_ENTRIES];

static inline uint32_t rv_decode_cache_index(vaddr_t pc) {
  return (pc >> 1) & (RV_DECODE_CACHE_ENTRIES - 1);
}

static inline uint32_t rv_decode_cache_inst_key(uint32_t inst) {
#ifdef CONFIG_RISCV_EXT_C
  return (inst & 0x3u) == 0x3u ? inst : (inst & 0xffffu);
#else
  return inst;
#endif
}

static inline void rv_decode_cache_flush(void) {
  memset(rv_decode_cache, 0, sizeof(rv_decode_cache));
}
#else
#define rv_decode_cache_flush() ((void)0)
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

#ifdef CONFIG_RISCV_IRQ_DEBUG_LOG
static int csr_intr_log_budget = 128;
#define CSR_INTR_DEBUG_LOG(...) do { \
  if (csr_intr_log_budget > 0) { \
    csr_intr_log_budget--; \
    Log(__VA_ARGS__); \
  } \
} while (0)
#else
#define CSR_INTR_DEBUG_LOG(...) do {} while (0)
#endif

#ifdef CONFIG_RISCV_SYSCALL_DEBUG_LOG
static int syscall_debug_budget = CONFIG_RISCV_SYSCALL_DEBUG_BUDGET;
static bool syscall_return_pending = false;
static word_t syscall_return_nr = 0;
static vaddr_t syscall_return_epc = 0;
static int post_exec_pc_log_budget = 64;
static uint64_t post_exec_uinst_seen = 0;

static inline void syscall_debug_log_enter(vaddr_t pc) {
  if (cpu.priv != PRIV_U || syscall_debug_budget <= 0) return;
  syscall_debug_budget--;
  syscall_return_pending = true;
  syscall_return_nr = R(17);
  syscall_return_epc = pc;
  Log("[Strace] enter pc=" FMT_WORD " nr=%" PRIu64
      " a0=" FMT_WORD " a1=" FMT_WORD " a2=" FMT_WORD
      " a3=" FMT_WORD " a4=" FMT_WORD " a5=" FMT_WORD
      " sp=" FMT_WORD,
      pc, (uint64_t)R(17), R(10), R(11), R(12), R(13), R(14), R(15), R(2));
}

static inline void syscall_debug_log_return(vaddr_t target) {
  if (!syscall_return_pending || cpu.priv != PRIV_U) return;
  word_t nr = syscall_return_nr;
  vaddr_t epc = syscall_return_epc;
  syscall_return_pending = false;
  Log("[Strace] return pc=" FMT_WORD " nr=%" PRIu64
      " ret=" FMT_WORD " target=" FMT_WORD,
      epc, (uint64_t)nr, R(10), target);
  if (nr == 221 && target != epc + 4) {
    post_exec_uinst_seen = 0;
    Log("[Strace] execve switched image target=" FMT_WORD " sp=" FMT_WORD,
        target, R(2));
  }
}

static inline void syscall_debug_log_user_pc(vaddr_t pc, uint32_t inst) {
  if (post_exec_pc_log_budget <= 0 || cpu.priv != PRIV_U) return;
  post_exec_uinst_seen++;
  if (post_exec_uinst_seen <= 16 || post_exec_uinst_seen % 1000000 == 0) {
    post_exec_pc_log_budget--;
    Log("[Utrace] after-exec seen=%" PRIu64 " pc=" FMT_WORD
        " inst=0x%08x ra=" FMT_WORD " sp=" FMT_WORD,
        post_exec_uinst_seen, pc, inst, R(1), R(2));
  }
}
#else
#define syscall_debug_log_enter(pc) ((void)0)
#define syscall_debug_log_return(target) ((void)0)
#define syscall_debug_log_user_pc(pc, inst) ((void)0)
#endif

static inline word_t sext32(uint32_t value) {
  return (word_t)SEXT(value, 32);
}

static inline word_t rol_xlen(word_t value, word_t shamt) {
  shamt = SHAMT_XLEN(shamt);
  return shamt == 0 ? value : (word_t)((value << shamt) | (value >> (XLEN_BITS - shamt)));
}

static inline word_t ror_xlen(word_t value, word_t shamt) {
  shamt = SHAMT_XLEN(shamt);
  return shamt == 0 ? value : (word_t)((value >> shamt) | (value << (XLEN_BITS - shamt)));
}

static inline word_t clz_xlen(word_t value) {
  if (value == 0) return XLEN_BITS;
#ifdef CONFIG_ISA64
  return (word_t)__builtin_clzll(value);
#else
  return (word_t)__builtin_clz((uint32_t)value);
#endif
}

static inline word_t ctz_xlen(word_t value) {
  if (value == 0) return XLEN_BITS;
#ifdef CONFIG_ISA64
  return (word_t)__builtin_ctzll(value);
#else
  return (word_t)__builtin_ctz((uint32_t)value);
#endif
}

static inline word_t cpop_xlen(word_t value) {
#ifdef CONFIG_ISA64
  return (word_t)__builtin_popcountll(value);
#else
  return (word_t)__builtin_popcount((uint32_t)value);
#endif
}

static inline word_t sext_b_xlen(word_t value) {
  return SEXT(BITS(value, 7, 0), 8);
}

static inline word_t sext_h_xlen(word_t value) {
  return SEXT(BITS(value, 15, 0), 16);
}

static inline word_t orc_b_xlen(word_t value) {
  word_t r = 0;
  for (int i = 0; i < (int)(XLEN_BITS / 8); i++) {
    word_t b = (value >> (i * 8)) & 0xffu;
    if (b != 0) r |= (word_t)0xff << (i * 8);
  }
  return r;
}

static inline word_t rev8_xlen(word_t value) {
  word_t r = 0;
  for (int i = 0; i < (int)(XLEN_BITS / 8); i++) {
    r |= ((value >> (i * 8)) & 0xffu) << ((XLEN_BITS / 8 - 1 - i) * 8);
  }
  return r;
}

static inline word_t clmul_xlen(word_t src1, word_t src2) {
  word_t r = 0;
  for (int i = 0; i < (int)XLEN_BITS; i++) {
    if ((src2 >> i) & 1u) r ^= src1 << i;
  }
  return r;
}

static inline word_t clmulh_xlen(word_t src1, word_t src2) {
  word_t r = 0;
  for (int i = 1; i < (int)XLEN_BITS; i++) {
    if ((src2 >> i) & 1u) r ^= src1 >> (XLEN_BITS - i);
  }
  return r;
}

static inline word_t clmulr_xlen(word_t src1, word_t src2) {
  word_t r = 0;
  for (int i = 0; i < (int)XLEN_BITS; i++) {
    if ((src2 >> i) & 1u) r ^= src1 >> (XLEN_BITS - 1 - i);
  }
  return r;
}

/* CSR 执行基础设施集中在这里。SYSTEM 分发只决定“是哪类系统指令”，
 * CSR 的读改写语义、misa 配置回显和 mepc 对齐规则都不散到主 switch 里。 */
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

static inline word_t csr_sanitize_satp(word_t value) {
#ifdef CONFIG_ISA64
  word_t mode = value >> 60;
  return (mode == 0 || mode == 8) ? value : 0;
#else
  return value;
#endif
}

static inline bool csr_read(uint32_t csr, word_t *value) {
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
    case CSR_SIP:      *value = isa_riscv64_mip_value() & MIP_SUPERVISOR_MASK; return true;
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
       * Sv39 TLB 已按 root_ppn+ASID 标记，satp 切换本身不需要粗暴全刷；
       * 页表内容变化由后续 sfence.vma 精确失效，保留进程切换时的 ASID 热项。
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

/* RV64I 基础执行块：主干 ISA 按指令格式归类，直接 switch 到最终语义。
 * 这层是热路径，不使用表生成宏，读起来就是 RV64 编码到行为的最短映射。 */
static inline bool exec_rv64i_op_imm(uint32_t inst, int rd, word_t src1) {
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  uint32_t funct6 = BITS(inst, 31, 26);
  word_t imm = IMM_I(inst);
  uint32_t shamt = MUXDEF(CONFIG_ISA64, BITS(inst, 25, 20), BITS(inst, 24, 20));
  (void)funct7;
  (void)funct6;

  switch (funct3) {
    case 0x0: R(rd) = src1 + imm; return true;                                // addi
    case 0x2: R(rd) = (sword_t)src1 < (sword_t)imm ? 1 : 0; return true;       // slti
    case 0x3: R(rd) = src1 < (word_t)imm ? 1 : 0; return true;                 // sltiu
    case 0x4: R(rd) = src1 ^ imm; return true;                                 // xori
    case 0x6: R(rd) = src1 | imm; return true;                                  // ori
    case 0x7: R(rd) = src1 & imm; return true;                                  // andi
    case 0x1:
      if (MUXDEF(CONFIG_ISA64, funct6 == 0x00, funct7 == 0x00)) {
        R(rd) = src1 << shamt; return true;                                      // slli
      }
      break;
    case 0x5:
      if (MUXDEF(CONFIG_ISA64, funct6 == 0x00, funct7 == 0x00)) {
        R(rd) = src1 >> shamt; return true;                                      // srli
      }
      if (MUXDEF(CONFIG_ISA64, funct6 == 0x10, funct7 == 0x20)) {
        R(rd) = (sword_t)src1 >> shamt; return true;                             // srai
      }
      break;
  }

  return false;
}

static inline bool exec_rv64i_load(uint32_t funct3, int rd, word_t addr) {
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
    case 0x3:
      IFDEF(CONFIG_ISA64, {
        val = Mr(addr, 8);
        if (vaddr_has_fault()) return true;
        R(rd) = val; return true; // ld
      });
      return false;
    case 0x4:
      val = Mr(addr, 1);
      if (vaddr_has_fault()) return true;
      R(rd) = val; return true;           // lbu
    case 0x5:
      val = Mr(addr, 2);
      if (vaddr_has_fault()) return true;
      R(rd) = val; return true;           // lhu
    case 0x6:
      IFDEF(CONFIG_ISA64, {
        val = Mr(addr, 4);
        if (vaddr_has_fault()) return true;
        R(rd) = val; return true; // lwu
      });
      return false;
    default: return false;
  }
}

static inline bool exec_rv64i_store(uint32_t funct3, word_t addr, word_t data) {
  switch (funct3) {
    case 0x0: Mw(addr, 1, data); return true; // sb
    case 0x1: Mw(addr, 2, data); return true; // sh
    case 0x2: Mw(addr, 4, data); return true; // sw
    case 0x3:
      IFDEF(CONFIG_ISA64, Mw(addr, 8, data); return true); // sd
      return false;
    default: return false;
  }
}

static inline bool fp_state_enabled(void) {
  return (cpu.csr.mstatus & MSTATUS_FS_MASK) != 0;
}

static inline void fp_mark_dirty(void) {
  cpu.csr.mstatus = (cpu.csr.mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY;
}

static inline void fp_raise_invalid(void) {
  cpu.csr.fflags |= FFLAGS_NV;
  fp_mark_dirty();
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

static inline word_t fclass32(uint32_t value) {
  uint32_t sign = value >> 31;
  uint32_t exp = BITS(value, 30, 23);
  uint32_t frac = value & 0x7fffffu;
  if (exp == 0xffu) {
    if (frac == 0) return sign ? 0x001 : 0x080;
    return (frac & 0x400000u) ? 0x200 : 0x100;
  }
  if (exp == 0) {
    if (frac == 0) return sign ? 0x008 : 0x010;
    return sign ? 0x004 : 0x020;
  }
  return sign ? 0x002 : 0x040;
}

static inline bool f32_is_nan(uint32_t value) {
  return (value & 0x7fffffffu) > 0x7f800000u;
}

static inline bool f32_is_snan(uint32_t value) {
  uint32_t frac = value & 0x7fffffu;
  return (BITS(value, 30, 23) == 0xffu) && frac != 0 && (frac & 0x400000u) == 0;
}

static inline bool f64_is_nan(uint64_t value) {
  return (value & 0x7fffffffffffffffull) > 0x7ff0000000000000ull;
}

static inline bool f64_is_snan(uint64_t value) {
  uint64_t frac = value & 0x000fffffffffffffull;
  return (((value >> 52) & 0x7ffu) == 0x7ffu) && frac != 0 &&
         (frac & 0x0008000000000000ull) == 0;
}

static inline float f32_to_host(uint32_t value) {
  union {
    uint32_t u;
    float f;
  } v = { .u = value };
  return v.f;
}

static inline double f64_to_host(uint64_t value) {
  union {
    uint64_t u;
    double f;
  } v = { .u = value };
  return v.f;
}

static inline uint32_t f32_from_host(float value) {
  union {
    uint32_t u;
    float f;
  } v = { .f = value };
  return v.u;
}

static inline uint64_t f64_from_host(double value) {
  union {
    uint64_t u;
    double f;
  } v = { .f = value };
  return v.u;
}

static inline bool fp_rounding_mode_valid(uint32_t rm) {
  uint32_t resolved = rm == 0x7 ? cpu.csr.frm : rm;
  return resolved <= 0x4;
}

static inline bool exec_rvf_arith_s(uint32_t funct7, uint32_t rm, int rd,
                                    uint32_t a, uint32_t b) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float af = f32_to_host(a);
  float bf = f32_to_host(b);
  float result = 0.0f;
  switch (funct7) {
    case 0x00: result = af + bf; break;                         // fadd.s
    case 0x04: result = af - bf; break;                         // fsub.s
    case 0x08: result = af * bf; break;                         // fmul.s
    case 0x0c: result = af / bf; break;                         // fdiv.s
    default:
      return false;
  }
  F(rd) = 0xffffffff00000000ull | f32_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_arith_d(uint32_t funct7, uint32_t rm, int rd,
                                    uint64_t a, uint64_t b) {
  if (!fp_rounding_mode_valid(rm)) return false;
  double af = f64_to_host(a);
  double bf = f64_to_host(b);
  double result = 0.0;
  switch (funct7) {
    case 0x01: result = af + bf; break;                         // fadd.d
    case 0x05: result = af - bf; break;                         // fsub.d
    case 0x09: result = af * bf; break;                         // fmul.d
    case 0x0d: result = af / bf; break;                         // fdiv.d
    default:
      return false;
  }
  F(rd) = f64_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fused_madd_s(uint32_t opcode, uint32_t rm, int rd,
                                         uint32_t a, uint32_t b, uint32_t c) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float af = f32_to_host(a);
  float bf = f32_to_host(b);
  float cf = f32_to_host(c);
  float result = 0.0f;
  switch (opcode) {
    case OPC_MADD:  result = __builtin_fmaf( af, bf,  cf); break; // fmadd.s
    case OPC_MSUB:  result = __builtin_fmaf( af, bf, -cf); break; // fmsub.s
    case OPC_NMSUB: result = __builtin_fmaf(-af, bf,  cf); break; // fnmsub.s
    case OPC_NMADD: result = __builtin_fmaf(-af, bf, -cf); break; // fnmadd.s
    default:
      return false;
  }
  F(rd) = 0xffffffff00000000ull | f32_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fused_madd_d(uint32_t opcode, uint32_t rm, int rd,
                                         uint64_t a, uint64_t b, uint64_t c) {
  if (!fp_rounding_mode_valid(rm)) return false;
  double af = f64_to_host(a);
  double bf = f64_to_host(b);
  double cf = f64_to_host(c);
  double result = 0.0;
  switch (opcode) {
    case OPC_MADD:  result = __builtin_fma( af, bf,  cf); break;  // fmadd.d
    case OPC_MSUB:  result = __builtin_fma( af, bf, -cf); break;  // fmsub.d
    case OPC_NMSUB: result = __builtin_fma(-af, bf,  cf); break;  // fnmsub.d
    case OPC_NMADD: result = __builtin_fma(-af, bf, -cf); break;  // fnmadd.d
    default:
      return false;
  }
  F(rd) = f64_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fused_madd(uint32_t opcode, uint32_t inst, int rd,
                                       int rs1, int rs2) {
  if (!fp_state_enabled()) return false;
  uint32_t fmt = FUNCT2(inst);
#if defined(CONFIG_RISCV_EXT_F) || defined(CONFIG_RISCV_EXT_D)
  uint32_t rm = FUNCT3(inst);
  int rs3 = RS3(inst);
#endif
  switch (fmt) {
#ifdef CONFIG_RISCV_EXT_F
    case 0x0:
      return exec_rvf_fused_madd_s(opcode, rm, rd, (uint32_t)F(rs1),
                                   (uint32_t)F(rs2), (uint32_t)F(rs3));
#endif
#ifdef CONFIG_RISCV_EXT_D
    case 0x1:
      return exec_rvf_fused_madd_d(opcode, rm, rd, F(rs1), F(rs2), F(rs3));
#endif
    default:
      return false;
  }
}

static inline uint32_t fminmax32(uint32_t a, uint32_t b, bool is_max) {
  bool an = f32_is_nan(a);
  bool bn = f32_is_nan(b);
  if (f32_is_snan(a) || f32_is_snan(b)) fp_raise_invalid();
  if (an && bn) return 0x7fc00000u;
  if (an) return b;
  if (bn) return a;
  float af = f32_to_host(a);
  float bf = f32_to_host(b);
  if (af == bf && ((a ^ b) & 0x80000000u) != 0) {
    return is_max ? 0x00000000u : 0x80000000u;
  }
  if (is_max) return af < bf ? b : a;
  return af < bf ? a : b;
}

static inline uint64_t fminmax64(uint64_t a, uint64_t b, bool is_max) {
  bool an = f64_is_nan(a);
  bool bn = f64_is_nan(b);
  if (f64_is_snan(a) || f64_is_snan(b)) fp_raise_invalid();
  if (an && bn) return 0x7ff8000000000000ull;
  if (an) return b;
  if (bn) return a;
  double af = f64_to_host(a);
  double bf = f64_to_host(b);
  if (af == bf && ((a ^ b) & 0x8000000000000000ull) != 0) {
    return is_max ? 0x0000000000000000ull : 0x8000000000000000ull;
  }
  if (is_max) return af < bf ? b : a;
  return af < bf ? a : b;
}

static inline word_t fcvt_to_int(double value, uint32_t rs2) {
  if (value != value) {
    fp_raise_invalid();
    return rs2 == 0 || rs2 == 2 ? (word_t)0x7fffffffffffffffull : ~(word_t)0;
  }

  switch (rs2) {
    case 0:                                                     // w
      if (value < -2147483648.0) { fp_raise_invalid(); return (word_t)(int64_t)(int32_t)0x80000000u; }
      if (value > 2147483647.0) { fp_raise_invalid(); return 0x7fffffffu; }
      return (word_t)(int64_t)(int32_t)value;
    case 1:                                                     // wu
      if (value < 0.0) { fp_raise_invalid(); return 0; }
      if (value > 4294967295.0) { fp_raise_invalid(); return 0xffffffffu; }
      return (word_t)(uint32_t)value;
    case 2:                                                     // l
      if (value < -9223372036854775808.0) {
        fp_raise_invalid();
        return (word_t)0x8000000000000000ull;
      }
      if (value >= 9223372036854775808.0) {
        fp_raise_invalid();
        return (word_t)0x7fffffffffffffffull;
      }
      return (word_t)(int64_t)value;
    case 3:                                                     // lu
      if (value < 0.0) { fp_raise_invalid(); return 0; }
      if (value >= 18446744073709551616.0) {
        fp_raise_invalid();
        return ~(word_t)0;
      }
      return (word_t)(uint64_t)value;
    default:
      return 0;
  }
}

static inline bool exec_rvf_fcvt_int_s(uint32_t rm, int rd, int rs2,
                                       uint32_t value) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  R(rd) = fcvt_to_int((double)f32_to_host(value), rs2);
  return true;
}

static inline bool exec_rvf_fcvt_int_d(uint32_t rm, int rd, int rs2,
                                       uint64_t value) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  R(rd) = fcvt_to_int(f64_to_host(value), rs2);
  return true;
}

static inline bool exec_rvf_fcvt_from_int_s(uint32_t rm, int rd, int rs1,
                                            int rs2) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  float result = 0.0f;
  switch (rs2) {
    case 0: result = (float)(int32_t)R(rs1); break;             // fcvt.s.w
    case 1: result = (float)(uint32_t)R(rs1); break;            // fcvt.s.wu
    case 2: result = (float)(int64_t)R(rs1); break;             // fcvt.s.l
    case 3: result = (float)(uint64_t)R(rs1); break;            // fcvt.s.lu
  }
  F(rd) = 0xffffffff00000000ull | f32_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fcvt_from_int_d(uint32_t rm, int rd, int rs1,
                                            int rs2) {
  if (rs2 > 3 || !fp_rounding_mode_valid(rm)) return false;
  double result = 0.0;
  switch (rs2) {
    case 0: result = (double)(int32_t)R(rs1); break;            // fcvt.d.w
    case 1: result = (double)(uint32_t)R(rs1); break;           // fcvt.d.wu
    case 2: result = (double)(int64_t)R(rs1); break;            // fcvt.d.l
    case 3: result = (double)(uint64_t)R(rs1); break;           // fcvt.d.lu
  }
  F(rd) = f64_from_host(result);
  fp_mark_dirty();
  return true;
}

#if defined(CONFIG_RISCV_EXT_F) && defined(CONFIG_RISCV_EXT_D)
static inline bool exec_rvf_fcvt_s_d(uint32_t rm, int rd, uint64_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  float result = (float)f64_to_host(value);
  F(rd) = 0xffffffff00000000ull | f32_from_host(result);
  fp_mark_dirty();
  return true;
}

static inline bool exec_rvf_fcvt_d_s(uint32_t rm, int rd, uint32_t value) {
  if (!fp_rounding_mode_valid(rm)) return false;
  double result = (double)f32_to_host(value);
  F(rd) = f64_from_host(result);
  fp_mark_dirty();
  return true;
}
#endif

static inline bool exec_rvf_compare_s(uint32_t funct3, int rd, uint32_t a,
                                      uint32_t b) {
  bool nan = f32_is_nan(a) || f32_is_nan(b);
  switch (funct3) {
    case 0x0:                                                 // fle.s
      if (nan) { fp_raise_invalid(); R(rd) = 0; }
      else R(rd) = f32_to_host(a) <= f32_to_host(b);
      return true;
    case 0x1:                                                 // flt.s
      if (nan) { fp_raise_invalid(); R(rd) = 0; }
      else R(rd) = f32_to_host(a) < f32_to_host(b);
      return true;
    case 0x2:                                                 // feq.s
      if (f32_is_snan(a) || f32_is_snan(b)) fp_raise_invalid();
      R(rd) = nan ? 0 : (f32_to_host(a) == f32_to_host(b));
      return true;
    default:
      return false;
  }
}

static inline bool exec_rvf_compare_d(uint32_t funct3, int rd, uint64_t a,
                                      uint64_t b) {
  bool nan = f64_is_nan(a) || f64_is_nan(b);
  switch (funct3) {
    case 0x0:                                                 // fle.d
      if (nan) { fp_raise_invalid(); R(rd) = 0; }
      else R(rd) = f64_to_host(a) <= f64_to_host(b);
      return true;
    case 0x1:                                                 // flt.d
      if (nan) { fp_raise_invalid(); R(rd) = 0; }
      else R(rd) = f64_to_host(a) < f64_to_host(b);
      return true;
    case 0x2:                                                 // feq.d
      if (f64_is_snan(a) || f64_is_snan(b)) fp_raise_invalid();
      R(rd) = nan ? 0 : (f64_to_host(a) == f64_to_host(b));
      return true;
    default:
      return false;
  }
}

static inline word_t fclass64(uint64_t value) {
  uint64_t sign = value >> 63;
  uint64_t exp = (value >> 52) & 0x7ffu;
  uint64_t frac = value & 0x000fffffffffffffull;
  if (exp == 0x7ffu) {
    if (frac == 0) return sign ? 0x001 : 0x080;
    return (frac & 0x0008000000000000ull) ? 0x200 : 0x100;
  }
  if (exp == 0) {
    if (frac == 0) return sign ? 0x008 : 0x010;
    return sign ? 0x004 : 0x020;
  }
  return sign ? 0x002 : 0x040;
}

static inline bool exec_rvf_op(uint32_t inst, int rd, int rs1, int rs2) {
  if (!fp_state_enabled()) return false;
  uint32_t funct7 = FUNCT7(inst);
#if defined(CONFIG_RISCV_EXT_F) || defined(CONFIG_RISCV_EXT_D)
  uint32_t funct3 = FUNCT3(inst);
#endif

  switch (funct7) {
#ifdef CONFIG_RISCV_EXT_F
    case 0x00:                                                   // fadd.s
    case 0x04:                                                   // fsub.s
    case 0x08:                                                   // fmul.s
    case 0x0c:                                                   // fdiv.s
      return exec_rvf_arith_s(funct7, funct3, rd, (uint32_t)F(rs1), (uint32_t)F(rs2));
    case 0x10: {                                                 // fsgnj.s/fsgnjn.s/fsgnjx.s
      uint32_t a = (uint32_t)F(rs1);
      uint32_t b = (uint32_t)F(rs2);
      uint32_t sign = b & 0x80000000u;
      if (funct3 == 0x1) sign ^= 0x80000000u;
      else if (funct3 == 0x2) sign = (a ^ b) & 0x80000000u;
      else if (funct3 != 0x0) return false;
      F(rd) = 0xffffffff00000000ull | (a & 0x7fffffffu) | sign;
      fp_mark_dirty();
      return true;
    }
    case 0x14:                                                   // fmin.s/fmax.s
      if (funct3 > 0x1) return false;
      F(rd) = 0xffffffff00000000ull |
              fminmax32((uint32_t)F(rs1), (uint32_t)F(rs2), funct3 == 0x1);
      fp_mark_dirty();
      return true;
#if defined(CONFIG_RISCV_EXT_D)
    case 0x20:                                                   // fcvt.s.d
      return rs2 == 1 ? exec_rvf_fcvt_s_d(funct3, rd, F(rs1)) : false;
#endif
    case 0x50:                                                   // fle.s/flt.s/feq.s
      return exec_rvf_compare_s(funct3, rd, (uint32_t)F(rs1), (uint32_t)F(rs2));
    case 0x60:                                                   // fcvt.w/wu/l/lu.s
      return exec_rvf_fcvt_int_s(funct3, rd, rs2, (uint32_t)F(rs1));
    case 0x68:                                                   // fcvt.s.w/wu/l/lu
      return exec_rvf_fcvt_from_int_s(funct3, rd, rs1, rs2);
    case 0x70:
      if (rs2 == 0 && funct3 == 0x0) {                         // fmv.x.w
        R(rd) = (word_t)SEXT((uint32_t)F(rs1), 32);
        return true;
      }
      if (rs2 == 1 && funct3 == 0x1) {                         // fclass.s
        R(rd) = fclass32((uint32_t)F(rs1));
        return true;
      }
      return false;
    case 0x78:
      if (rs2 == 0 && funct3 == 0x0) {                         // fmv.w.x
        F(rd) = 0xffffffff00000000ull | (uint32_t)R(rs1);
        fp_mark_dirty();
        return true;
      }
      return false;
#endif
#ifdef CONFIG_RISCV_EXT_D
    case 0x01:                                                   // fadd.d
    case 0x05:                                                   // fsub.d
    case 0x09:                                                   // fmul.d
    case 0x0d:                                                   // fdiv.d
      return exec_rvf_arith_d(funct7, funct3, rd, F(rs1), F(rs2));
    case 0x11: {                                                 // fsgnj.d/fsgnjn.d/fsgnjx.d
      uint64_t a = F(rs1);
      uint64_t b = F(rs2);
      uint64_t sign = b & 0x8000000000000000ull;
      if (funct3 == 0x1) sign ^= 0x8000000000000000ull;
      else if (funct3 == 0x2) sign = (a ^ b) & 0x8000000000000000ull;
      else if (funct3 != 0x0) return false;
      F(rd) = (a & 0x7fffffffffffffffull) | sign;
      fp_mark_dirty();
      return true;
    }
    case 0x15:                                                   // fmin.d/fmax.d
      if (funct3 > 0x1) return false;
      F(rd) = fminmax64(F(rs1), F(rs2), funct3 == 0x1);
      fp_mark_dirty();
      return true;
#if defined(CONFIG_RISCV_EXT_F)
    case 0x21:                                                   // fcvt.d.s
      return rs2 == 0 ? exec_rvf_fcvt_d_s(funct3, rd, (uint32_t)F(rs1)) : false;
#endif
    case 0x51:                                                   // fle.d/flt.d/feq.d
      return exec_rvf_compare_d(funct3, rd, F(rs1), F(rs2));
    case 0x61:                                                   // fcvt.w/wu/l/lu.d
      return exec_rvf_fcvt_int_d(funct3, rd, rs2, F(rs1));
    case 0x69:                                                   // fcvt.d.w/wu/l/lu
      return exec_rvf_fcvt_from_int_d(funct3, rd, rs1, rs2);
    case 0x71:
      if (rs2 == 0 && funct3 == 0x0) {                         // fmv.x.d
        R(rd) = F(rs1);
        return true;
      }
      if (rs2 == 1 && funct3 == 0x1) {                         // fclass.d
        R(rd) = fclass64(F(rs1));
        return true;
      }
      return false;
    case 0x79:
      if (rs2 == 0 && funct3 == 0x0) {                         // fmv.d.x
        F(rd) = R(rs1);
        fp_mark_dirty();
        return true;
      }
      return false;
#endif
    default:
      return false;
  }
}

static inline bool exec_rv64i_branch(Decode *s, uint32_t funct3, word_t src1, word_t src2, word_t imm) {
  switch (funct3) {
    case 0x0: if (src1 == src2) s->dnpc = s->pc + imm; return true;                 // beq
    case 0x1: if (src1 != src2) s->dnpc = s->pc + imm; return true;                 // bne
    case 0x4: if ((sword_t)src1 < (sword_t)src2) s->dnpc = s->pc + imm; return true; // blt
    case 0x5: if ((sword_t)src1 >= (sword_t)src2) s->dnpc = s->pc + imm; return true;// bge
    case 0x6: if (src1 < src2) s->dnpc = s->pc + imm; return true;                  // bltu
    case 0x7: if (src1 >= src2) s->dnpc = s->pc + imm; return true;                 // bgeu
    default: return false;
  }
}

static inline bool exec_rv64i_op(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x0, 0x00): R(rd) = src1 + src2; return true;                             // add
    case OP_KEY(0x0, 0x20): R(rd) = src1 - src2; return true;                             // sub
    case OP_KEY(0x1, 0x00): R(rd) = src1 << SHAMT_XLEN(src2); return true;                // sll
    case OP_KEY(0x2, 0x00): R(rd) = (sword_t)src1 < (sword_t)src2 ? 1 : 0; return true;   // slt
    case OP_KEY(0x3, 0x00): R(rd) = src1 < src2 ? 1 : 0; return true;                     // sltu
    case OP_KEY(0x4, 0x00): R(rd) = src1 ^ src2; return true;                             // xor
    case OP_KEY(0x5, 0x00): R(rd) = src1 >> SHAMT_XLEN(src2); return true;                // srl
    case OP_KEY(0x5, 0x20): R(rd) = (sword_t)src1 >> SHAMT_XLEN(src2); return true;       // sra
    case OP_KEY(0x6, 0x00): R(rd) = src1 | src2; return true;                             // or
    case OP_KEY(0x7, 0x00): R(rd) = src1 & src2; return true;                             // and
    default: return false;
  }
}

static inline bool exec_rv64i_op_imm_32(uint32_t inst, int rd, word_t src1) {
  if (!ISDEF(CONFIG_ISA64)) return false;

  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  uint32_t shamt = BITS(inst, 24, 20);
  uint32_t src32 = src1;

  switch (funct3) {
    case 0x0: R(rd) = sext32(src32 + (uint32_t)IMM_I(inst)); return true; // addiw
    case 0x1:
#ifdef CONFIG_RISCV_EXT_B
      if (BITS(inst, 31, 26) == 0x02) { R(rd) = ((word_t)src32) << BITS(inst, 25, 20); return true; } // slli.uw
#endif
      if (funct7 == 0x00) { R(rd) = sext32(src32 << shamt); return true; } // slliw
      break;
    case 0x5:
      if (funct7 == 0x00) { R(rd) = sext32(src32 >> shamt); return true; } // srliw
      if (funct7 == 0x20) { R(rd) = sext32((uint32_t)((int32_t)src32 >> shamt)); return true; } // sraiw
      break;
  }

  return false;
}

static inline bool exec_rv64i_op_32(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  if (!ISDEF(CONFIG_ISA64)) return false;

  uint32_t a = src1;
  uint32_t b = src2;
  uint32_t shamt = b & 0x1f;

  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x0, 0x00): R(rd) = sext32(a + b); return true; // addw
    case OP_KEY(0x0, 0x20): R(rd) = sext32(a - b); return true; // subw
    case OP_KEY(0x1, 0x00): R(rd) = sext32(a << shamt); return true; // sllw
    case OP_KEY(0x5, 0x00): R(rd) = sext32(a >> shamt); return true; // srlw
    case OP_KEY(0x5, 0x20): R(rd) = sext32((uint32_t)((int32_t)a >> shamt)); return true; // sraw
    default: return false;
  }
}

static inline bool exec_system(Decode *s, uint32_t inst, uint32_t funct3, int rd, int rs1, int rs2) {
  if (funct3 != 0) return exec_csr(inst, funct3, rd, rs1);

  switch (inst) {
    case 0x00000073: // ecall
      syscall_debug_log_enter(s->pc);
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
      csr_sret(s);
      return true;
    case 0x30200073: // mret
      if (cpu.priv != PRIV_M) return false;
      csr_mret(s);
      return true;
    case 0x10500073: // wfi
      isa_riscv64_wfi();
      return true;
    default:
      if ((inst & 0xfe007fffu) == 0x12000073u) { // sfence.vma
        /*
         * Linux 进程切换常用 sfence.vma va,asid。按 rs1/rs2 精细失效后，
         * PTE_G 和其他 ASID 的 TLB 项不会被粗暴清空，保持 Ubuntu 热路径收益。
         */
        isa_riscv64_mmu_tlb_flush_selective(R(rs1), rs1 != 0, R(rs2), rs2 != 0);
        return true;
      }
      return false;
  }
}

static inline bool exec_misc_mem(uint32_t funct3) {
  switch (funct3) {
    case 0x0: // fence
      return true;
    case 0x1: // fence.i
      // fence.i 是自修改代码的架构同步点；硬件 cache 模型和解释器预译码缓存都在这里失效。
      IFDEF(CONFIG_CACHE, cache_flush_all());
      rv_decode_cache_flush();
      return true;
    default:
      return false;
  }
}

#ifdef CONFIG_RISCV_EXT_M
/* RVM 扩展：乘除相关编码集中在一个入口。关闭 Kconfig 后整组编码自然非法。 */
static inline bool exec_rvm_op(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  if (funct7 != 0x01) return false;

  switch (funct3) {
    case 0x0: { // mul
      R(rd) = (word_t)((unsigned __int128)src1 * (unsigned __int128)src2);
      return true;
    }
    case 0x1: { // mulh
      __int128 prod = (__int128)(sword_t)src1 * (__int128)(sword_t)src2;
      R(rd) = (word_t)(prod >> XLEN_BITS);
      return true;
    }
    case 0x2: { // mulhsu
      __int128 prod = (__int128)(sword_t)src1 * (__int128)(unsigned __int128)src2;
      R(rd) = (word_t)(prod >> XLEN_BITS);
      return true;
    }
    case 0x3: { // mulhu
      unsigned __int128 prod = (unsigned __int128)src1 * (unsigned __int128)src2;
      R(rd) = (word_t)(prod >> XLEN_BITS);
      return true;
    }
    case 0x4: // div
      if (src2 == 0) R(rd) = (word_t)-1;
      else if (src1 == WORD_SIGN_BIT && src2 == (word_t)-1) R(rd) = WORD_SIGN_BIT;
      else R(rd) = (sword_t)src1 / (sword_t)src2;
      return true;
    case 0x5: // divu
      R(rd) = (src2 == 0) ? (word_t)-1 : src1 / src2;
      return true;
    case 0x6: // rem
      if (src2 == 0) R(rd) = src1;
      else if (src1 == WORD_SIGN_BIT && src2 == (word_t)-1) R(rd) = 0;
      else R(rd) = (sword_t)src1 % (sword_t)src2;
      return true;
    case 0x7: // remu
      R(rd) = (src2 == 0) ? src1 : src1 % src2;
      return true;
    default:
      return false;
  }
}

static inline bool exec_rvm_op_32(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  if (!ISDEF(CONFIG_ISA64) || funct7 != 0x01) return false;

  uint32_t a = src1;
  uint32_t b = src2;
  int32_t sa = (int32_t)a;
  int32_t sb = (int32_t)b;

  switch (funct3) {
    case 0x0: R(rd) = sext32((uint32_t)((int64_t)sa * (int64_t)sb)); return true; // mulw
    case 0x4: // divw
      if (b == 0) R(rd) = (word_t)-1;
      else if (a == 0x80000000u && b == 0xffffffffu) R(rd) = sext32(0x80000000u);
      else R(rd) = sext32((uint32_t)(sa / sb));
      return true;
    case 0x5: // divuw
      R(rd) = (b == 0) ? (word_t)-1 : sext32(a / b);
      return true;
    case 0x6: // remw
      if (b == 0) R(rd) = sext32(a);
      else if (a == 0x80000000u && b == 0xffffffffu) R(rd) = 0;
      else R(rd) = sext32((uint32_t)(sa % sb));
      return true;
    case 0x7: // remuw
      R(rd) = (b == 0) ? sext32(a) : sext32(a % b);
      return true;
    default:
      return false;
  }
}
#endif

#ifdef CONFIG_RISCV_EXT_A
static inline word_t amo_sext_word(uint32_t value) {
  return MUXDEF(CONFIG_ISA64, (word_t)SEXT(value, 32), (word_t)value);
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

static inline word_t amo_compute_xlen(word_t old, word_t src, uint32_t funct5) {
  switch (funct5) {
    case 0x01: return src;                                      // amoswap.d
    case 0x00: return old + src;                                // amoadd.d
    case 0x04: return old ^ src;                                // amoxor.d
    case 0x0c: return old & src;                                // amoand.d
    case 0x08: return old | src;                                // amoor.d
    case 0x10: return (sword_t)old < (sword_t)src ? old : src;  // amomin.d
    case 0x14: return (sword_t)old > (sword_t)src ? old : src;  // amomax.d
    case 0x18: return old < src ? old : src;                    // amominu.d
    case 0x1c: return old > src ? old : src;                    // amomaxu.d
    default: return old;
  }
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

  if (funct3 == 0x3 && ISDEF(CONFIG_ISA64)) {
    if (funct5 == 0x02) {                                      // lr.d
      if ((addr & 0x7) != 0) return amo_raise_misaligned(addr, funct5);
      word_t old = Mr(addr, 8);
      if (vaddr_has_fault()) return true;
      lr_reservation_valid = true;
      lr_reservation_addr = addr;
      R(rd) = old;
      return true;
    }
    if (funct5 == 0x03) {                                      // sc.d
      if ((addr & 0x7) != 0) return amo_raise_misaligned(addr, funct5);
      bool ok = lr_reservation_valid && lr_reservation_addr == addr;
      if (ok) {
        Mw(addr, 8, R(rs2));
        if (vaddr_has_fault()) return true;
      }
      lr_reservation_valid = false;
      R(rd) = ok ? 0 : 1;
      return true;
    }
    if (!amo_funct5_valid(funct5)) return false;
    if ((addr & 0x7) != 0) return amo_raise_misaligned(addr, funct5);

    word_t old = Mr(addr, 8);
    if (vaddr_has_fault()) return true;
    word_t result = amo_compute_xlen(old, R(rs2), funct5);
    Mw(addr, 8, result);
    if (vaddr_has_fault()) return true;
    lr_reservation_valid = false;
    R(rd) = old;
    return true;
  }

  return false;
}
#endif

#ifdef CONFIG_RISCV_EXT_B
/* Zba/Zbb/Zbc/Zbs 扩展：所有 bitmanip 逻辑集中在这里。
 * 主译码只在 RV64I 没命中时进入本块，常见基础指令不为扩展表付额外层次。 */
static inline bool exec_zb_op_imm(uint32_t inst, int rd, word_t src1) {
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  uint32_t funct6 = BITS(inst, 31, 26);
  uint32_t imm = MUXDEF(CONFIG_ISA64, BITS(inst, 25, 20), BITS(inst, 24, 20));
  uint32_t imm5 = BITS(inst, 24, 20);

  if (funct3 == 0x1) {
    switch (funct6) {
      case 0x0a: R(rd) = src1 | ((word_t)1 << imm); return true;       // bseti
      case 0x12: R(rd) = src1 & ~((word_t)1 << imm); return true;      // bclri
      case 0x1a: R(rd) = src1 ^ ((word_t)1 << imm); return true;       // binvi
      default: break;
    }
    switch (funct7) {
      case 0x30:
        switch (imm5) {
          case 0x00: R(rd) = clz_xlen(src1); return true;        // clz
          case 0x01: R(rd) = ctz_xlen(src1); return true;        // ctz
          case 0x02: R(rd) = cpop_xlen(src1); return true;       // cpop
          case 0x04: R(rd) = sext_b_xlen(src1); return true;     // sext.b
          case 0x05: R(rd) = sext_h_xlen(src1); return true;     // sext.h
          default: return false;
        }
      default:
        return false;
    }
  }

  if (funct3 == 0x5) {
    switch (funct6) {
      case 0x18: R(rd) = ror_xlen(src1, imm); return true;       // rori
      case 0x12: R(rd) = (src1 >> imm) & 1u; return true;        // bexti
      default: break;
    }
    switch (funct7) {
      case 0x14:
        if (imm5 != 0x07) return false;
        R(rd) = orc_b_xlen(src1);                               // orc.b
        return true;
      case 0x34:
      case 0x35:
        if (imm5 != 0x18) return false;
        R(rd) = rev8_xlen(src1);                                // rev8
        return true;
      default:
        return false;
    }
  }

  return false;
}

static inline bool exec_zb_op(uint32_t funct3, uint32_t funct7, int rd, int rs2, word_t src1, word_t src2) {
  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x2, 0x10): R(rd) = (src1 << 1) + src2; return true; // sh1add
    case OP_KEY(0x4, 0x10): R(rd) = (src1 << 2) + src2; return true; // sh2add
    case OP_KEY(0x6, 0x10): R(rd) = (src1 << 3) + src2; return true; // sh3add
    case OP_KEY(0x7, 0x20): R(rd) = src1 & ~src2; return true;       // andn
    case OP_KEY(0x6, 0x20): R(rd) = src1 | ~src2; return true;       // orn
    case OP_KEY(0x4, 0x20): R(rd) = ~(src1 ^ src2); return true;     // xnor
    case OP_KEY(0x1, 0x30): R(rd) = rol_xlen(src1, src2); return true;  // rol
    case OP_KEY(0x5, 0x30): R(rd) = ror_xlen(src1, src2); return true;  // ror
    case OP_KEY(0x4, 0x05): R(rd) = ((sword_t)src1 < (sword_t)src2) ? src1 : src2; return true; // min
    case OP_KEY(0x5, 0x05): R(rd) = (src1 < src2) ? src1 : src2; return true;                   // minu
    case OP_KEY(0x6, 0x05): R(rd) = ((sword_t)src1 > (sword_t)src2) ? src1 : src2; return true; // max
    case OP_KEY(0x7, 0x05): R(rd) = (src1 > src2) ? src1 : src2; return true;                   // maxu
    case OP_KEY(0x1, 0x05): R(rd) = clmul_xlen(src1, src2); return true;  // clmul
    case OP_KEY(0x2, 0x05): R(rd) = clmulr_xlen(src1, src2); return true; // clmulr
    case OP_KEY(0x3, 0x05): R(rd) = clmulh_xlen(src1, src2); return true; // clmulh
    case OP_KEY(0x1, 0x14): R(rd) = src1 | ((word_t)1 << SHAMT_XLEN(src2)); return true;      // bset
    case OP_KEY(0x1, 0x24): R(rd) = src1 & ~((word_t)1 << SHAMT_XLEN(src2)); return true;     // bclr
    case OP_KEY(0x5, 0x24): R(rd) = (src1 >> SHAMT_XLEN(src2)) & 1u; return true;             // bext
    case OP_KEY(0x1, 0x34): R(rd) = src1 ^ ((word_t)1 << SHAMT_XLEN(src2)); return true;      // binv
    case OP_KEY(0x4, 0x04):
      if (rs2 != 0) return false;
      R(rd) = src1 & 0xffffu;                                      // zext.h
      return true;
    default:
      return false;
  }
}

static inline bool exec_zb_op_32(uint32_t funct3, uint32_t funct7, int rd, int rs2, word_t src1, word_t src2) {
  if (!ISDEF(CONFIG_ISA64)) return false;

  word_t src1_uw = (uint32_t)src1;
  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x0, 0x04): R(rd) = src1_uw + src2; return true;       // add.uw
    case OP_KEY(0x2, 0x10): R(rd) = (src1_uw << 1) + src2; return true; // sh1add.uw
    case OP_KEY(0x4, 0x10): R(rd) = (src1_uw << 2) + src2; return true; // sh2add.uw
    case OP_KEY(0x6, 0x10): R(rd) = (src1_uw << 3) + src2; return true; // sh3add.uw
    case OP_KEY(0x4, 0x04):
      if (rs2 != 0) return false;
      R(rd) = src1 & 0xffffu;                                           // zext.h
      return true;
    default:
      return false;
  }
}
#endif

#ifdef CONFIG_RISCV_EXT_C
/* RV64C 扩展：可变长取指只负责拿到 16/32 位原始指令，压缩语义全部收口在本块。 */
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

static inline bool exec_rv64c(Decode *s, uint16_t inst) {
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
          if (!exec_rv64i_load(0x2, C_RD(inst), R(C_RS1(inst)) + c_imm_lw_sw(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x3: // c.ld
          if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
          if (!exec_rv64i_load(0x3, C_RD(inst), R(C_RS1(inst)) + c_imm_ld_sd(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x6: // c.sw
          Mw(R(C_RS1(inst)) + c_imm_lw_sw(inst), 4, R(C_RS2(inst)));
          return true;
        case 0x5: // c.fsd
          if (!ISDEF(CONFIG_RISCV_EXT_D) ||
              !exec_rvf_store(0x3, R(C_RS1(inst)) + c_imm_ld_sd(inst), C_RS2(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x7: // c.sd
          if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
          Mw(R(C_RS1(inst)) + c_imm_ld_sd(inst), 8, R(C_RS2(inst)));
          return true;
        default:
          BAD_DECODE();
      }
    case 0x1:
      switch (funct3) {
        case 0x0: // c.addi / c.nop
          R(rd) = R(rd) + c_imm_6(inst);
          return true;
        case 0x1:
#ifdef CONFIG_ISA64
          if (rd == 0) BAD_DECODE();
          R(rd) = sext32((uint32_t)(R(rd) + c_imm_6(inst))); // c.addiw
#else
          R(1) = s->pc + 2;                                  // c.jal
          s->dnpc = s->pc + c_imm_j(inst);
          IFDEF(CONFIG_FTRACE, ftrace_log(1, s->pc, s->dnpc));
#endif
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
              if (!ISDEF(CONFIG_ISA64) && BITS(inst, 12, 12)) BAD_DECODE();
              R(rs1p) = R(rs1p) >> c_shamt(inst);
              return true;
            case 0x1: // c.srai
              if (!ISDEF(CONFIG_ISA64) && BITS(inst, 12, 12)) BAD_DECODE();
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
                  if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
                  R(rs1p) = sext32((uint32_t)R(rs1p) - (uint32_t)R(rs2p)); return true; // c.subw
                case 0x5:
                  if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
                  R(rs1p) = sext32((uint32_t)R(rs1p) + (uint32_t)R(rs2p)); return true; // c.addw
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
          if (!ISDEF(CONFIG_ISA64) && BITS(inst, 12, 12)) BAD_DECODE();
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
          if (!exec_rv64i_load(0x2, rd, R(2) + c_imm_lwsp(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x3: // c.ldsp
          if (!ISDEF(CONFIG_ISA64) || rd == 0) BAD_DECODE();
          if (!exec_rv64i_load(0x3, rd, R(2) + c_imm_ldsp(inst))) {
            BAD_DECODE();
          }
          return true;
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
        case 0x7: // c.sdsp
          if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
          Mw(R(2) + c_imm_sdsp(inst), 8, R(rs2));
          return true;
        default:
          BAD_DECODE();
      }
    default:
      BAD_DECODE();
  }
}
#endif

static inline void raise_illegal_inst(Decode *s, uint32_t inst) {
  s->dnpc = isa_raise_intr_with_tval(CAUSE_ILLEGAL_INST, s->pc, inst);
  R(0) = 0;
}

#ifdef CONFIG_INTERPRETER_DECODE_CACHE
static inline RvDecodeCacheKind rv_decode_cache_kind(uint32_t inst) {
#ifdef CONFIG_RISCV_EXT_C
  if ((inst & 0x3u) != 0x3u) return RV_DC_RVC;
#endif

  switch (OPCODE(inst)) {
    case OPC_OP_IMM: return RV_DC_OP_IMM;
    case OPC_OP_IMM_32: return RV_DC_OP_IMM_32;
    case OPC_LOAD: return RV_DC_LOAD;
    case OPC_LOAD_FP: return RV_DC_LOAD_FP;
    case OPC_STORE: return RV_DC_STORE;
    case OPC_STORE_FP: return RV_DC_STORE_FP;
    case OPC_AMO: return RV_DC_AMO;
    case OPC_OP: return RV_DC_OP;
    case OPC_OP_32: return RV_DC_OP_32;
    case OPC_BRANCH: return RV_DC_BRANCH;
    case OPC_JALR: return RV_DC_JALR;
    case OPC_JAL: return RV_DC_JAL;
    case OPC_LUI: return RV_DC_LUI;
    case OPC_AUIPC: return RV_DC_AUIPC;
    default: return RV_DC_NONE;
  }
}

static inline void rv_decode_cache_fill(const Decode *s) {
  uint32_t inst = s->isa.inst;
  RvDecodeCacheKind kind = rv_decode_cache_kind(inst);
  if (kind == RV_DC_NONE) return;

  RvDecodeCacheEntry next = {
    .pc = s->pc,
    .inst_key = rv_decode_cache_inst_key(inst),
    .imm = 0,
    .kind = kind,
    .rd = RD(inst),
    .rs1 = RS1(inst),
    .rs2 = RS2(inst),
    .funct3 = FUNCT3(inst),
    .funct7 = FUNCT7(inst),
  };

  switch (kind) {
    case RV_DC_LOAD:
    case RV_DC_LOAD_FP:
    case RV_DC_JALR:
      next.imm = IMM_I(inst);
      break;
    case RV_DC_STORE:
    case RV_DC_STORE_FP:
      next.imm = IMM_S(inst);
      break;
    case RV_DC_BRANCH:
      next.imm = IMM_B(inst);
      break;
    case RV_DC_JAL:
      next.imm = IMM_J(inst);
      break;
    case RV_DC_LUI:
    case RV_DC_AUIPC:
      next.imm = IMM_U(inst);
      break;
    default:
      break;
  }

  rv_decode_cache[rv_decode_cache_index(s->pc)] = next;
}

static inline bool rv_decode_cache_exec(Decode *s) {
  uint32_t inst_key = rv_decode_cache_inst_key(s->isa.inst);
  RvDecodeCacheEntry *entry = &rv_decode_cache[rv_decode_cache_index(s->pc)];
  if (entry->kind == RV_DC_NONE || entry->pc != s->pc || entry->inst_key != inst_key) {
    return false;
  }

  uint32_t inst = s->isa.inst;
  s->dnpc = s->snpc;

  switch ((RvDecodeCacheKind)entry->kind) {
    case RV_DC_RVC:
#ifdef CONFIG_RISCV_EXT_C
      if (!exec_rv64c(s, inst & 0xffffu)) goto invalid;
      break;
#else
      goto invalid;
#endif
    case RV_DC_OP_IMM: {
      word_t src1 = R(entry->rs1);
      if (!exec_rv64i_op_imm(inst, entry->rd, src1)) {
#ifdef CONFIG_RISCV_EXT_B
        if (!exec_zb_op_imm(inst, entry->rd, src1)) goto invalid;
#else
        goto invalid;
#endif
      }
      break;
    }
    case RV_DC_OP_IMM_32:
      if (!exec_rv64i_op_imm_32(inst, entry->rd, R(entry->rs1))) goto invalid;
      break;
    case RV_DC_LOAD:
      if (!exec_rv64i_load(entry->funct3, entry->rd, R(entry->rs1) + entry->imm)) goto invalid;
      break;
    case RV_DC_LOAD_FP:
      if (!exec_rvf_load(entry->funct3, entry->rd, R(entry->rs1) + entry->imm)) goto invalid;
      break;
    case RV_DC_STORE:
      if (!exec_rv64i_store(entry->funct3, R(entry->rs1) + entry->imm, R(entry->rs2))) goto invalid;
      break;
    case RV_DC_STORE_FP:
      if (!exec_rvf_store(entry->funct3, R(entry->rs1) + entry->imm, entry->rs2)) goto invalid;
      break;
    case RV_DC_AMO:
#ifdef CONFIG_RISCV_EXT_A
      if (!exec_rva_amo(inst, entry->rd, entry->rs1, entry->rs2)) goto invalid;
      break;
#else
      goto invalid;
#endif
    case RV_DC_OP: {
      word_t src1 = R(entry->rs1);
      word_t src2 = R(entry->rs2);
      if (exec_rv64i_op(entry->funct3, entry->funct7, entry->rd, src1, src2)) break;
#ifdef CONFIG_RISCV_EXT_M
      if (exec_rvm_op(entry->funct3, entry->funct7, entry->rd, src1, src2)) break;
#endif
#ifdef CONFIG_RISCV_EXT_B
      if (exec_zb_op(entry->funct3, entry->funct7, entry->rd, entry->rs2, src1, src2)) break;
#endif
      goto invalid;
    }
    case RV_DC_OP_32: {
      word_t src1 = R(entry->rs1);
      word_t src2 = R(entry->rs2);
#ifdef CONFIG_RISCV_EXT_B
      if (exec_zb_op_32(entry->funct3, entry->funct7, entry->rd, entry->rs2, src1, src2)) break;
#endif
      if (exec_rv64i_op_32(entry->funct3, entry->funct7, entry->rd, src1, src2)) break;
#ifdef CONFIG_RISCV_EXT_M
      if (exec_rvm_op_32(entry->funct3, entry->funct7, entry->rd, src1, src2)) break;
#endif
      goto invalid;
    }
    case RV_DC_BRANCH:
      if (!exec_rv64i_branch(s, entry->funct3, R(entry->rs1), R(entry->rs2), entry->imm)) goto invalid;
      break;
    case RV_DC_JALR: {
      if (entry->funct3 != 0x0) goto invalid;
      word_t target = (R(entry->rs1) + entry->imm) & ~(word_t)1;
      R(entry->rd) = s->pc + 4;
      s->dnpc = target;
      IFDEF(CONFIG_FTRACE, {
        if (entry->rd == 0 && entry->rs1 == 1) ftrace_log(-1, s->pc, target);
        else if (entry->rd == 1 || entry->rd == 5) ftrace_log(1, s->pc, target);
      })
      break;
    }
    case RV_DC_JAL:
      R(entry->rd) = s->pc + 4;
      s->dnpc = s->pc + entry->imm;
      IFDEF(CONFIG_FTRACE, if (entry->rd == 1 || entry->rd == 5) ftrace_log(1, s->pc, s->dnpc));
      break;
    case RV_DC_LUI:
      R(entry->rd) = entry->imm;
      break;
    case RV_DC_AUIPC:
      R(entry->rd) = s->pc + entry->imm;
      break;
    default:
      return false;
  }

  R(0) = 0;
  return true;

invalid:
  raise_illegal_inst(s, inst);
  return true;
}
#else
#define rv_decode_cache_fill(s) ((void)0)
#define rv_decode_cache_exec(s) false
#endif

static int decode_exec(Decode *s) {
  s->dnpc = s->snpc;
  uint32_t inst = s->isa.inst;

#ifdef CONFIG_RISCV_EXT_C
  if ((inst & 0x3) != 0x3) {
    if (!exec_rv64c(s, inst & 0xffffu)) goto invalid;
    R(0) = 0;
    return 0;
  }
#endif

  uint32_t opcode = OPCODE(inst);
  uint32_t funct3 = FUNCT3(inst);
  int rd = RD(inst);
  int rs1 = RS1(inst);
  int rs2 = RS2(inst);

  switch (opcode) {
    case OPC_OP_IMM: {
      word_t src1 = R(rs1);
      if (!exec_rv64i_op_imm(inst, rd, src1)) {
#ifdef CONFIG_RISCV_EXT_B
        if (!exec_zb_op_imm(inst, rd, src1)) goto invalid;
#else
        goto invalid;
#endif
      }
      break;
    }
    case OPC_OP_IMM_32: {
      word_t src1 = R(rs1);
      if (!exec_rv64i_op_imm_32(inst, rd, src1)) goto invalid;
      break;
    }
    case OPC_LOAD: {
      word_t addr = R(rs1) + IMM_I(inst);
      if (!exec_rv64i_load(funct3, rd, addr)) goto invalid;
      break;
    }
    case OPC_LOAD_FP: {
      word_t addr = R(rs1) + IMM_I(inst);
      if (!exec_rvf_load(funct3, rd, addr)) goto invalid;
      break;
    }
    case OPC_MISC_MEM:
      if (!exec_misc_mem(funct3)) goto invalid;
      break;
    case OPC_STORE: {
      word_t addr = R(rs1) + IMM_S(inst);
      if (!exec_rv64i_store(funct3, addr, R(rs2))) goto invalid;
      break;
    }
    case OPC_STORE_FP: {
      word_t addr = R(rs1) + IMM_S(inst);
      if (!exec_rvf_store(funct3, addr, rs2)) goto invalid;
      break;
    }
    case OPC_MADD:
    case OPC_MSUB:
    case OPC_NMSUB:
    case OPC_NMADD:
      if (!exec_rvf_fused_madd(opcode, inst, rd, rs1, rs2)) goto invalid;
      break;
    case OPC_OP_FP:
      if (!exec_rvf_op(inst, rd, rs1, rs2)) goto invalid;
      break;
    case OPC_AMO:
#ifdef CONFIG_RISCV_EXT_A
      if (!exec_rva_amo(inst, rd, rs1, rs2)) goto invalid;
      break;
#else
      goto invalid;
#endif
    case OPC_OP: {
      uint32_t funct7 = FUNCT7(inst);
      word_t src1 = R(rs1);
      word_t src2 = R(rs2);
      if (exec_rv64i_op(funct3, funct7, rd, src1, src2)) break;
#ifdef CONFIG_RISCV_EXT_M
      if (exec_rvm_op(funct3, funct7, rd, src1, src2)) break;
#endif
#ifdef CONFIG_RISCV_EXT_B
      if (exec_zb_op(funct3, funct7, rd, rs2, src1, src2)) break;
#endif
      goto invalid;
    }
    case OPC_OP_32: {
      uint32_t funct7 = FUNCT7(inst);
      word_t src1 = R(rs1);
      word_t src2 = R(rs2);
#ifdef CONFIG_RISCV_EXT_B
      if (exec_zb_op_32(funct3, funct7, rd, rs2, src1, src2)) break;
#endif
      if (exec_rv64i_op_32(funct3, funct7, rd, src1, src2)) break;
#ifdef CONFIG_RISCV_EXT_M
      if (exec_rvm_op_32(funct3, funct7, rd, src1, src2)) break;
#endif
      goto invalid;
    }
    case OPC_BRANCH:
      if (!exec_rv64i_branch(s, funct3, R(rs1), R(rs2), IMM_B(inst))) goto invalid;
      break;
    case OPC_JALR: {
      if (funct3 != 0x0) goto invalid;
      word_t target = (R(rs1) + IMM_I(inst)) & ~(word_t)1;
      R(rd) = s->pc + 4;
      s->dnpc = target;
      IFDEF(CONFIG_FTRACE, {
        if (rd == 0 && rs1 == 1) ftrace_log(-1, s->pc, target);
        else if (rd == 1 || rd == 5) ftrace_log(1, s->pc, target);
      })
      break;
    }
    case OPC_JAL:
      R(rd) = s->pc + 4;
      s->dnpc = s->pc + IMM_J(inst);
      IFDEF(CONFIG_FTRACE, if (rd == 1 || rd == 5) ftrace_log(1, s->pc, s->dnpc));
      break;
    case OPC_LUI:
      R(rd) = IMM_U(inst);
      break;
    case OPC_AUIPC:
      R(rd) = s->pc + IMM_U(inst);
      break;
    case OPC_SYSTEM:
      if (!exec_system(s, inst, funct3, rd, rs1, rs2)) goto invalid;
      break;
    default:
      goto invalid;
  }

  R(0) = 0;
  return 0;

invalid:
  raise_illegal_inst(s, inst);
  return 0;
}

static inline bool take_vaddr_fault(Decode *s) {
  word_t cause;
  vaddr_t tval;
  if (!vaddr_take_fault(&cause, &tval)) return false;
  s->dnpc = isa_raise_intr_with_tval(cause, s->pc, tval);
  R(0) = 0;
  return true;
}

int isa_exec_once(Decode *s) {
#ifdef CONFIG_RISCV_EXT_C
  uint32_t wide_inst = 0;
  int wide_len = 0;
  if (vaddr_ifetch_wide(s->snpc, &wide_inst, &wide_len)) {
    if (take_vaddr_fault(s)) {
      s->isa.inst = 0;
      return 0;
    }
    s->isa.inst = wide_inst;
    s->snpc += wide_len;
    syscall_debug_log_user_pc(s->pc, s->isa.inst);
    if (rv_decode_cache_exec(s)) {
      take_vaddr_fault(s);
      return 0;
    }
    int ret = decode_exec(s);
    rv_decode_cache_fill(s);
    take_vaddr_fault(s);
    return ret;
  }

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
  syscall_debug_log_user_pc(s->pc, s->isa.inst);
  if (rv_decode_cache_exec(s)) {
    take_vaddr_fault(s);
    return 0;
  }
  int ret = decode_exec(s);
  rv_decode_cache_fill(s);
  take_vaddr_fault(s);
  return ret;
}
