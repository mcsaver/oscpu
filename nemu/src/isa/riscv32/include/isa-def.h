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

#ifndef __ISA_RISCV_H__
#define __ISA_RISCV_H__

#include <common.h>

//mtvec：trap入口地址，发生异常或中断后，CPU最终要跳到哪里执行，故障处理程序的起点
//mepc：异常发生时的程序计数器，记录出事的时候执行到那一条指令了，进入trap会把当前PC存放到这里，后面mret返回时再用它恢复现场
//mcause：trap原因码表，告诉你为何进入（ecall、非法指令、定时器中断、外部中断）
//mie：机器态中断使能寄存器，负责每种中断源允不允许进来
//mip：机器态中断待处理中断寄存器，表示：哪些中断已经来了，在排队等处理
//mscratch/mtval：trap 处理程序的临时寄存器和异常附加值，先补齐状态槽位，便于 SYSTEM 指令统一分发
typedef struct {
  word_t mtvec, mepc, mcause, mstatus, mie, mip, mscratch, mtval;
} riscv32_CSR_state;

typedef struct {
  word_t gpr[MUXDEF(CONFIG_RVE, 16, 32)];
  vaddr_t pc;
  riscv32_CSR_state csr;
} riscv32_CPU_state;

#ifdef CONFIG_RV64
typedef struct {
  word_t gpr[MUXDEF(CONFIG_RVE, 16, 32)];
  vaddr_t pc;
} riscv64_CPU_state;
#endif

// decode
typedef struct {
  uint32_t inst;
} MUXDEF(CONFIG_RV64, riscv64_ISADecodeInfo, riscv32_ISADecodeInfo);

#define isa_mmu_check(vaddr, len, type) (MMU_DIRECT)

#endif
