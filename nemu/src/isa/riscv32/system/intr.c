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

#define MSTATUS_MIE  (1u << 3)//当前是否允许机器态中断
#define MSTATUS_MPIE (1u << 7)//进入trap前，原来的MIE值备份
#define MSTATUS_MPP_MASK (3u << 11)
#define MSTATUS_MPP_M    (3u << 11)

#define MCOUNTINHIBIT_CY 0x00000001u

#define MIP_MSIP 0x00000008u
#define MIP_MTIP 0x00000080u
#define MIP_MEIP 0x00000800u
#define MIP_IRQ_MASK (MIP_MSIP | MIP_MTIP | MIP_MEIP)

#define IRQ_CAUSE_MSI 3u
#define IRQ_CAUSE_MTI 7u
#define IRQ_CAUSE_MEI 11u
#define MCAUSE_INTERRUPT ((word_t)1 << (sizeof(word_t) * 8 - 1))

#define CLINT_BASE 0x02000000u
#define CLINT_SIZE 0x00010000u
#define CLINT_MSIP_OFFSET      0x0000u
#define CLINT_MTIMECMP_LO      0x4000u
#define CLINT_MTIMECMP_HI      0x4004u
#define CLINT_MTIME_LO         0xbff8u
#define CLINT_MTIME_HI         0xbffcu

static bool clint_msip = false;
static uint64_t clint_mtimecmp = ~0ull;
static uint64_t clint_mtime = 0;
static bool host_timer_irq_pending = false;
static bool mcycle_written_this_inst = false;

static inline word_t riscv_mepc_mask(void) {
  return MUXDEF(CONFIG_RISCV_EXT_C, ~0x1u, ~0x3u);
}

static inline word_t clint_pending_bits(void) {
  word_t pending = 0;
  if (clint_msip) pending |= MIP_MSIP;
  if (clint_mtime >= clint_mtimecmp || host_timer_irq_pending) pending |= MIP_MTIP;
  return pending;
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
  assert(len >= 1 && len <= 4);
  uint32_t offset = addr - CLINT_BASE;
  uint32_t shift = (offset & 0x3u) * 8u;
  uint32_t word = clint_read_word(offset & ~0x3u);
  uint32_t mask = len == 4 ? 0xffffffffu : ((1u << (len * 8)) - 1u);
  return (word >> shift) & mask;
}

void isa_riscv32_clint_write(paddr_t addr, int len, word_t data) {
  assert(len >= 1 && len <= 4);
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
  mcycle_written_this_inst = false;
  clint_mtime++;
}

void isa_riscv32_reset(void) {
  clint_msip = false;
  clint_mtimecmp = ~0ull;
  clint_mtime = 0;
  host_timer_irq_pending = false;
  mcycle_written_this_inst = false;
}

word_t isa_riscv32_mip_value(void) {
  return (cpu.csr.mip & ~MIP_IRQ_MASK) | clint_pending_bits();
}

void isa_riscv32_write_mie(word_t value) {
  cpu.csr.mie = value & MIP_IRQ_MASK;
}

void isa_riscv32_write_mip(word_t value) {
  // 标准硬件 pending 位来自 CLINT/外部控制器，软件写 mip 不能伪造或清除这些源。
  cpu.csr.mip = value & ~MIP_IRQ_MASK;
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
      case 7:  return "machine timer interrupt";
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
    default: return "unknown exception";
  }
}

vaddr_t isa_raise_intr_with_tval(word_t NO, vaddr_t epc, word_t tval) {

  cpu.csr.mepc = epc & riscv_mepc_mask();
  cpu.csr.mcause = NO;
  cpu.csr.mtval = tval;

  //如果跟MIE=1，就把MPIE置1
  //如果MIE=0，就把MPIE清0
  //用于记录是否打开了是否允许机器态中断
  if (cpu.csr.mstatus & MSTATUS_MIE)
  {
    cpu.csr.mstatus |= MSTATUS_MPIE;
  }
  else  {
    cpu.csr.mstatus &= ~MSTATUS_MPIE;// &= ~..代表的是按位清零某些位
  }

  //进入trap后先关中断
  cpu.csr.mstatus &= ~MSTATUS_MIE;
  // 当前只建模 M-mode，进入 trap 时仍显式记录 MPP=M，保证后续 mret 能按规范恢复栈位。
  cpu.csr.mstatus = (cpu.csr.mstatus & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_M;

  // ETRACE 在 trap 入口统一记录 cause/epc/目标入口，便于直接观察 CTE 往返链路。
  word_t target = cpu.csr.mtvec & ~0x3u;
  const bool is_intr = riscv_trap_is_intr(NO);
  const char *type_color = is_intr ? ANSI_FG_YELLOW : ANSI_FG_RED;
  // 用 Log 在终端高亮输出 trap 类型；非法指令等同步异常不会再退化成 NEMU_ABORT。
  Log("RISC-V trap %s cause=%" PRIu64 " type=%s%s%s epc=" FMT_WORD
      " mtval=" FMT_WORD " target=" FMT_WORD,
      is_intr ? "interrupt" : "exception", (uint64_t)riscv_trap_cause_code(NO),
      type_color, riscv_trap_cause_name(NO), ANSI_NONE,
      cpu.csr.mepc, cpu.csr.mtval, target);
  etrace_log_raise(NO, cpu.csr.mepc, cpu.csr.mtval, target, cpu.csr.mstatus);

  return target;
}

vaddr_t isa_raise_intr(word_t NO, vaddr_t epc) {
  return isa_raise_intr_with_tval(NO, epc, 0);
}

word_t isa_query_intr() {
  word_t pending = isa_riscv32_mip_value() & cpu.csr.mie & MIP_IRQ_MASK;
  if ((cpu.csr.mstatus & MSTATUS_MIE) == 0 || pending == 0) {
    return INTR_EMPTY;
  }

  // M-mode 固定优先级对齐 NPC：外部中断 > 软件中断 > 定时器中断。
  if (pending & MIP_MEIP) return MCAUSE_INTERRUPT | IRQ_CAUSE_MEI;
  if (pending & MIP_MSIP) return MCAUSE_INTERRUPT | IRQ_CAUSE_MSI;
  if (pending & MIP_MTIP) {
    host_timer_irq_pending = false;
    return MCAUSE_INTERRUPT | IRQ_CAUSE_MTI;
  }
  return INTR_EMPTY;
}
