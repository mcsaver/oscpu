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

#ifndef __ETRACE_H__
#define __ETRACE_H__

#include <common.h>

#ifdef CONFIG_ETRACE

// RISC-V 的 mcause 最高位区分中断/异常，低位才是原因号；这里统一拆解，避免日志调用点重复位运算。
static inline bool etrace_is_intr(word_t cause) {
  return (cause >> (sizeof(word_t) * 8 - 1)) != 0;
}

static inline word_t etrace_cause_code(word_t cause) {
  word_t intr_bit = (word_t)1 << (sizeof(word_t) * 8 - 1);
  return cause & ~intr_bit;
}

static inline const char *etrace_cause_name(word_t cause) {
  word_t code = etrace_cause_code(cause);
  if (etrace_is_intr(cause)) {
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

static inline void etrace_log_raise(word_t cause, vaddr_t epc,
    word_t tval, vaddr_t target, word_t mstatus) {
  // 异常通常发生在长循环之后，不能被 TRACE_START/END 的普通日志窗口吞掉；
  // 只要 ETRACE 打开，就直接写入当前日志文件。
  extern FILE* log_fp;
  if (log_fp == NULL) return;
  fprintf(log_fp, "[Etrace] trap %s cause=%" PRIu64 " (%s) epc=" FMT_WORD
      " mtval=" FMT_WORD " target=" FMT_WORD " mstatus=" FMT_WORD "\n",
      etrace_is_intr(cause) ? "interrupt" : "exception",
      (uint64_t)etrace_cause_code(cause), etrace_cause_name(cause),
      epc, tval, target, mstatus);
  fflush(log_fp);
}

static inline void etrace_log_mret(vaddr_t pc, vaddr_t target,
    word_t mstatus) {
  // 返回点同样绕过普通 trace 窗口，保证 trap 进入/返回能在日志里成对出现。
  extern FILE* log_fp;
  if (log_fp == NULL) return;
  fprintf(log_fp, "[Etrace] mret pc=" FMT_WORD " target=" FMT_WORD
      " mstatus=" FMT_WORD "\n", pc, target, mstatus);
  fflush(log_fp);
}

#else

// 关闭 ETRACE 时让调用点退化为空操作，保持 trap 热路径没有额外运行时分支。
#define etrace_log_raise(cause, epc, tval, target, mstatus) ((void)0)
#define etrace_log_mret(pc, target, mstatus) ((void)0)

#endif

#endif
