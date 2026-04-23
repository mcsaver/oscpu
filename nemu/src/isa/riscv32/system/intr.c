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

  cpu.csr.mepc = epc & ~0x3u;
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
  word_t target = cpu.csr.mtvec;
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
  return INTR_EMPTY;
}
