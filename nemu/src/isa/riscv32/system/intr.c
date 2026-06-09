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

#include <isa.h>
#include <etrace.h>

#define CLINT_BASE 0x02000000u
#define CLINT_SIZE 0x00010000u
#define CLINT_MSIP_OFFSET      0x0000u
#define CLINT_MTIMECMP_LO      0x4000u
#define CLINT_MTIMECMP_HI      0x4004u
#define CLINT_MTIME_LO         0xbff8u
#define CLINT_MTIME_HI         0xbffcu
#define CLINT_TIMEBASE_HZ      10000000ull

static bool clint_msip = false;
static uint64_t clint_mtimecmp = ~0ull;
static uint64_t clint_mtime = 0;
static bool host_timer_irq_pending = false;
static bool mcycle_written_this_inst = false;
#ifdef CONFIG_RISCV_DEBUG_LOG
static int trap_log_budget = 64;
#endif

static inline word_t riscv_mepc_mask(void) {
  return MUXDEF(CONFIG_RISCV_EXT_C, ~(word_t)0x1, ~(word_t)0x3);
}

static inline word_t clint_pending_bits(void) {
  word_t pending = 0;
  if (clint_msip) pending |= MIP_MSIP;
  if (clint_mtime >= clint_mtimecmp || host_timer_irq_pending) pending |= MIP_MTIP;
  return pending;
}

// 供 CSR time 和 machine-info 复用同一份 CLINT 时间事实，避免 DTB/实现漂移。
uint64_t isa_riscv32_clint_timebase_hz(void) {
  return CLINT_TIMEBASE_HZ;
}

uint64_t isa_riscv32_mtime_value(void) {
  return clint_mtime;
}

const char *isa_riscv32_clint_time_source(void) {
  return "instruction";
}

static uint32_t clint_read_word(uint32_t offset) {
  switch (offset) {
    case CLINT_MSIP_OFFSET: return clint_msip ? 1u : 0u;
    case CLINT_MTIMECMP_LO: return (uint32_t)clint_mtimecmp;
    case CLINT_MTIMECMP_HI: return (uint32_t)(clint_mtimecmp >> 32);
    case CLINT_MTIME_LO:    return (uint32_t)clint_mtime;
    case CLINT_MTIME_HI:    return (uint32_t)(clint_mtime >> 32);
    default: return 0;
  }
}

static void clint_write_word(uint32_t offset, uint32_t value, uint32_t mask) {
  switch (offset) {
    case CLINT_MSIP_OFFSET:
      // msip 只有 bit0 是软件中断源；byte strobe 没碰到 bit0 时保持原值，和 NPC AXI-Lite CLINT 对齐。
      if (mask & 0x000000ffu) clint_msip = (value & 1u) != 0;
      break;
    case CLINT_MTIMECMP_LO: {
      uint32_t old = (uint32_t)clint_mtimecmp;
      uint32_t lo = (old & ~mask) | (value & mask);
      clint_mtimecmp = (clint_mtimecmp & 0xffffffff00000000ull) | lo;
      break;
    }
    case CLINT_MTIMECMP_HI: {
      uint32_t old = (uint32_t)(clint_mtimecmp >> 32);
      uint32_t hi = (old & ~mask) | (value & mask);
      clint_mtimecmp = ((uint64_t)hi << 32) | (uint32_t)clint_mtimecmp;
      break;
    }
    case CLINT_MTIME_LO: {
      uint32_t old = (uint32_t)clint_mtime;
      uint32_t lo = (old & ~mask) | (value & mask);
      clint_mtime = (clint_mtime & 0xffffffff00000000ull) | lo;
      break;
    }
    case CLINT_MTIME_HI: {
      uint32_t old = (uint32_t)(clint_mtime >> 32);
      uint32_t hi = (old & ~mask) | (value & mask);
      clint_mtime = ((uint64_t)hi << 32) | (uint32_t)clint_mtime;
      break;
    }
    default:
      break;
  }
}

bool isa_riscv32_clint_in_range(paddr_t addr) {
  return addr >= CLINT_BASE && addr < CLINT_BASE + CLINT_SIZE;
}

word_t isa_riscv32_clint_read(paddr_t addr, int len) {
  assert(len >= 1 && len <= 8);
  if (len == 8) {
    uint64_t value = (uint64_t)isa_riscv32_clint_read(addr, 4) |
                     ((uint64_t)isa_riscv32_clint_read(addr + 4, 4) << 32);
    return (word_t)value;
  }
  uint32_t offset = addr - CLINT_BASE;
  uint32_t shift = (offset & 0x3u) * 8u;
  uint32_t word = clint_read_word(offset & ~0x3u);
  uint32_t mask = len == 4 ? 0xffffffffu : ((1u << (len * 8)) - 1u);
  return (word >> shift) & mask;
}

void isa_riscv32_clint_write(paddr_t addr, int len, word_t data) {
  assert(len >= 1 && len <= 8);
  if (len == 8) {
    uint64_t value = data;
    isa_riscv32_clint_write(addr, 4, (uint32_t)data);
    isa_riscv32_clint_write(addr + 4, 4, (uint32_t)(value >> 32));
    return;
  }
  uint32_t offset = addr - CLINT_BASE;
  uint32_t shift = (offset & 0x3u) * 8u;
  uint32_t mask = len == 4 ? 0xffffffffu : ((1u << (len * 8)) - 1u);
  uint32_t word_mask = mask << shift;
  uint32_t word_value = ((uint32_t)data << shift) & word_mask;
  clint_write_word(offset & ~0x3u, word_value, word_mask);
}

void isa_riscv32_post_exec(void) {
  // NEMU 是指令级参考模型，这里用“每条已执行指令一跳”近似 NPC 的 mcycle/mtime 自然前进。
  if (!mcycle_written_this_inst && (cpu.csr.mcountinhibit & MCOUNTINHIBIT_CY) == 0) {
    cpu.csr.mcycle++;
  }
  if ((cpu.csr.mcountinhibit & MCOUNTINHIBIT_IR) == 0) {
    cpu.csr.minstret++;
  }
  mcycle_written_this_inst = false;
  clint_mtime++;
}

void isa_riscv32_reset(void) {
  clint_msip = false;
  clint_mtimecmp = ~0ull;
  clint_mtime = 0;
  host_timer_irq_pending = false;
  mcycle_written_this_inst = false;
  isa_riscv32_plic_reset();
}

word_t isa_riscv32_mip_value(void) {
  return (cpu.csr.mip & ~MIP_MACHINE_MASK) |
         clint_pending_bits() |
         isa_riscv32_plic_pending_bits();
}

bool isa_riscv32_intr_pending_fast(void) {
  word_t enabled = cpu.csr.mie & MIP_IRQ_MASK;
  if (enabled == 0) return false;

  word_t raw_pending = (cpu.csr.mip & MIP_SUPERVISOR_MASK) | clint_pending_bits();
  if (isa_riscv32_plic_maybe_pending()) {
    raw_pending |= MIP_MEIP | MIP_SEIP;
  }
  raw_pending &= enabled;
  if (raw_pending == 0) return false;

  bool s_global = (cpu.priv == PRIV_U) ||
                  (cpu.priv == PRIV_S && (cpu.csr.mstatus & MSTATUS_SIE));
  if (s_global && (raw_pending & MIP_SUPERVISOR_MASK) != 0) return true;

  bool m_global = (cpu.priv != PRIV_M) || (cpu.csr.mstatus & MSTATUS_MIE);
  return m_global && (raw_pending & MIP_MACHINE_MASK) != 0;
}

void isa_riscv32_write_mie(word_t value) {
  cpu.csr.mie = value & MIP_IRQ_MASK;
}

void isa_riscv32_write_mip(word_t value) {
  // M 级硬件 pending 位来自 CLINT/外部控制器；M-mode 可通过 mip 注入 S 级软件 pending。
  // sip 的 S-mode 视图只允许 SSIP 写入，不能伪造 STIP/SEIP。
  cpu.csr.mip = value & MIP_SUPERVISOR_MASK;
}

void isa_riscv32_write_mcycle_lo(word_t value) {
  cpu.csr.mcycle = (cpu.csr.mcycle & 0xffffffff00000000ull) | (uint32_t)value;
  mcycle_written_this_inst = true;
}

void isa_riscv32_write_mcycle_hi(word_t value) {
  cpu.csr.mcycle = ((uint64_t)(uint32_t)value << 32) | (uint32_t)cpu.csr.mcycle;
  mcycle_written_this_inst = true;
}

void isa_riscv32_raise_timer_intr(void) {
  host_timer_irq_pending = true;
}

static bool riscv_trap_is_intr(word_t cause) {
  return (cause >> (sizeof(word_t) * 8 - 1)) != 0;
}

static word_t riscv_trap_cause_code(word_t cause) {
  word_t intr_bit = (word_t)1 << (sizeof(word_t) * 8 - 1);
  return cause & ~intr_bit;
}

static const char *riscv_trap_cause_name(word_t cause) {
  word_t code = riscv_trap_cause_code(cause);
  if (riscv_trap_is_intr(cause)) {
    switch (code) {
      case 3:  return "machine software interrupt";
      case 1:  return "supervisor software interrupt";
      case 5:  return "supervisor timer interrupt";
      case 7:  return "machine timer interrupt";
      case 9:  return "supervisor external interrupt";
      case 11: return "machine external interrupt";
      default: return "unknown interrupt";
    }
  }

  switch (code) {
    case 0:  return "instruction address misaligned";
    case 1:  return "instruction access fault";
    case 2:  return "illegal instruction";
    case 3:  return "breakpoint";
    case 4:  return "load address misaligned";
    case 5:  return "load access fault";
    case 6:  return "store address misaligned";
    case 7:  return "store access fault";
    case 8:  return "environment call from U-mode";
    case 9:  return "environment call from S-mode";
    case 11: return "environment call from M-mode";
    case 12: return "instruction page fault";
    case 13: return "load page fault";
    case 15: return "store page fault";
    default: return "unknown exception";
  }
}

static bool should_log_trap(word_t cause, uint8_t from_priv) {
#ifndef CONFIG_RISCV_DEBUG_LOG
  (void)cause;
  (void)from_priv;
  return false;
#else
  if (trap_log_budget <= 0) return false;
  if (riscv_trap_is_intr(cause)) return false;

  word_t code = riscv_trap_cause_code(cause);
  switch (code) {
    case CAUSE_ECALL_U:
    case CAUSE_ECALL_S:
    case CAUSE_ECALL_M:
      return false;
    case CAUSE_BREAKPOINT:
    case CAUSE_ILLEGAL_INST:
      if (from_priv == PRIV_M) return false;
      break;
    default:
      break;
  }

  trap_log_budget--;
  return true;
#endif
}

static inline word_t encode_mpp(uint8_t priv) {
  switch (priv) {
    case PRIV_S: return MSTATUS_MPP_S;
    case PRIV_M: return MSTATUS_MPP_M;
    default: return 0;
  }
}

static inline bool trap_delegated_to_s(word_t cause) {
  if (cpu.priv == PRIV_M) return false;

  word_t code = riscv_trap_cause_code(cause);
  const word_t xlen = sizeof(word_t) * 8;
  if (riscv_trap_is_intr(cause)) {
    return code < xlen && ((cpu.csr.mideleg >> code) & 1u);
  }
  return code < xlen && ((cpu.csr.medeleg >> code) & 1u);
}

vaddr_t isa_raise_intr_with_tval(word_t NO, vaddr_t epc, word_t tval) {
  uint8_t from_priv = cpu.priv;
  bool to_s = trap_delegated_to_s(NO);
  word_t target;

  if (to_s) {
    cpu.csr.sepc = epc & riscv_mepc_mask();
    cpu.csr.scause = NO;
    cpu.csr.stval = tval;

    if (cpu.csr.mstatus & MSTATUS_SIE) cpu.csr.mstatus |= MSTATUS_SPIE;
    else cpu.csr.mstatus &= ~MSTATUS_SPIE;
    cpu.csr.mstatus &= ~MSTATUS_SIE;
    if (cpu.priv == PRIV_S) cpu.csr.mstatus |= MSTATUS_SPP;
    else cpu.csr.mstatus &= ~MSTATUS_SPP;
    cpu.csr.mstatus |= MSTATUS_SXL_UXL;
    cpu.priv = PRIV_S;
    target = cpu.csr.stvec & ~(word_t)0x3;
  } else {
    cpu.csr.mepc = epc & riscv_mepc_mask();
    cpu.csr.mcause = NO;
    cpu.csr.mtval = tval;

    if (cpu.csr.mstatus & MSTATUS_MIE) cpu.csr.mstatus |= MSTATUS_MPIE;
    else cpu.csr.mstatus &= ~MSTATUS_MPIE;
    cpu.csr.mstatus &= ~MSTATUS_MIE;
    cpu.csr.mstatus = (cpu.csr.mstatus & ~MSTATUS_MPP_MASK) | encode_mpp(cpu.priv);
    cpu.csr.mstatus |= MSTATUS_SXL_UXL;
    cpu.priv = PRIV_M;
    target = cpu.csr.mtvec & ~(word_t)0x3;
  }

  if (should_log_trap(NO, from_priv)) {
    // 常规 SBI ecall/timer interrupt 会极高频出现；这里只保留少量真正异常入口。
    const bool is_intr = riscv_trap_is_intr(NO);
    const char *type_color = is_intr ? ANSI_FG_YELLOW : ANSI_FG_RED;
    Log("RISC-V trap %s cause=%" PRIu64 " type=%s%s%s to=%c epc=" FMT_WORD
        " mtval=" FMT_WORD " target=" FMT_WORD,
        is_intr ? "interrupt" : "exception", (uint64_t)riscv_trap_cause_code(NO),
        type_color, riscv_trap_cause_name(NO), ANSI_NONE,
        to_s ? 'S' : 'M', epc & riscv_mepc_mask(), tval, target);
  }
  etrace_log_raise(NO, epc & riscv_mepc_mask(), tval, target, cpu.csr.mstatus);

  return target;
}

vaddr_t isa_raise_intr(word_t NO, vaddr_t epc) {
  return isa_raise_intr_with_tval(NO, epc, 0);
}

word_t isa_query_intr() {
  word_t enabled_pending = isa_riscv32_mip_value() & cpu.csr.mie & MIP_IRQ_MASK;
  word_t s_pending = enabled_pending & MIP_SUPERVISOR_MASK;
  bool s_global = (cpu.priv == PRIV_U) ||
                  (cpu.priv == PRIV_S && (cpu.csr.mstatus & MSTATUS_SIE));
  if (s_global && s_pending != 0) {
    if (s_pending & MIP_SEIP) return MCAUSE_INTERRUPT | IRQ_CAUSE_SEI;
    if (s_pending & MIP_SSIP) return MCAUSE_INTERRUPT | IRQ_CAUSE_SSI;
    if (s_pending & MIP_STIP) return MCAUSE_INTERRUPT | IRQ_CAUSE_STI;
  }

  word_t m_pending = enabled_pending & MIP_MACHINE_MASK;
  bool m_global = (cpu.priv != PRIV_M) || (cpu.csr.mstatus & MSTATUS_MIE);
  if (!m_global || m_pending == 0) return INTR_EMPTY;

  if (m_pending & MIP_MEIP) return MCAUSE_INTERRUPT | IRQ_CAUSE_MEI;
  if (m_pending & MIP_MSIP) return MCAUSE_INTERRUPT | IRQ_CAUSE_MSI;
  if (m_pending & MIP_MTIP) {
    host_timer_irq_pending = false;
    return MCAUSE_INTERRUPT | IRQ_CAUSE_MTI;
  }
  return INTR_EMPTY;
}
