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

#ifndef __ISA_RISCV64_H__
#define __ISA_RISCV64_H__

#include <common.h>

#define PRIV_U 0u
#define PRIV_S 1u
#define PRIV_M 3u

#define CSR_FFLAGS   0x001
#define CSR_FRM      0x002
#define CSR_FCSR     0x003
#define CSR_SSTATUS  0x100
#define CSR_SIE      0x104
#define CSR_STVEC    0x105
#define CSR_SCOUNTEREN 0x106
#define CSR_SSCRATCH 0x140
#define CSR_SEPC     0x141
#define CSR_SCAUSE   0x142
#define CSR_STVAL    0x143
#define CSR_SIP      0x144
#define CSR_SATP     0x180
#define CSR_MSTATUS  0x300
#define CSR_MISA     0x301
#define CSR_MEDELEG  0x302
#define CSR_MIDELEG  0x303
#define CSR_MIE      0x304
#define CSR_MTVEC    0x305
#define CSR_MCOUNTEREN 0x306
#define CSR_MCOUNTINHIBIT 0x320
#define CSR_MSCRATCH 0x340
#define CSR_MEPC     0x341
#define CSR_MCAUSE   0x342
#define CSR_MTVAL    0x343
#define CSR_MIP      0x344
#define CSR_MCYCLE   0xb00
#define CSR_MINSTRET 0xb02
#define CSR_MCYCLEH  0xb80
#define CSR_MINSTRETH 0xb82
#define CSR_CYCLE    0xc00
#define CSR_TIME     0xc01
#define CSR_INSTRET  0xc02
#define CSR_CYCLEH   0xc80
#define CSR_TIMEH    0xc81
#define CSR_INSTRETH 0xc82
#define CSR_MVENDORID 0xf11
#define CSR_MARCHID  0xf12
#define CSR_MIMPID   0xf13
#define CSR_MHARTID  0xf14

#define CAUSE_INST_MISALIGNED 0
#define CAUSE_INST_ACCESS     1
#define CAUSE_ILLEGAL_INST    2
#define CAUSE_BREAKPOINT      3
#define CAUSE_LOAD_MISALIGNED 4
#define CAUSE_LOAD_ACCESS     5
#define CAUSE_STORE_MISALIGNED 6
#define CAUSE_STORE_ACCESS    7
#define CAUSE_ECALL_U         8
#define CAUSE_ECALL_S         9
#define CAUSE_ECALL_M         11
#define CAUSE_INST_PAGE_FAULT 12
#define CAUSE_LOAD_PAGE_FAULT 13
#define CAUSE_STORE_PAGE_FAULT 15

#define MSTATUS_SIE        ((word_t)1 << 1)
#define MSTATUS_MIE        ((word_t)1 << 3)
#define MSTATUS_SPIE       ((word_t)1 << 5)
#define MSTATUS_MPIE       ((word_t)1 << 7)
#define MSTATUS_SPP        ((word_t)1 << 8)
#define MSTATUS_MPP_MASK   ((word_t)3 << 11)
#define MSTATUS_MPP_S      ((word_t)1 << 11)
#define MSTATUS_MPP_M      ((word_t)3 << 11)
#define MSTATUS_FS_MASK    ((word_t)3 << 13)
#define MSTATUS_FS_DIRTY   ((word_t)3 << 13)
#define MSTATUS_MPRV       ((word_t)1 << 17)
#define MSTATUS_SUM        ((word_t)1 << 18)
#define MSTATUS_MXR        ((word_t)1 << 19)
#define MSTATUS_SXL_UXL    MUXDEF(CONFIG_ISA64, ((word_t)0xa << 32), 0)
#define SSTATUS_MASK       (MSTATUS_SIE | MSTATUS_SPIE | MSTATUS_SPP | \
                            MSTATUS_FS_MASK | MSTATUS_SUM | MSTATUS_MXR | \
                            MSTATUS_SXL_UXL)
#define MSTATUS_WRITABLE_MASK \
    (MSTATUS_SIE | MSTATUS_MIE | MSTATUS_SPIE | MSTATUS_MPIE | \
     MSTATUS_SPP | MSTATUS_FS_MASK | MSTATUS_MPP_MASK | MSTATUS_MPRV | \
     MSTATUS_SUM | MSTATUS_MXR)

#define MIP_SSIP           ((word_t)1 << 1)
#define MIP_MSIP           ((word_t)1 << 3)
#define MIP_STIP           ((word_t)1 << 5)
#define MIP_MTIP           ((word_t)1 << 7)
#define MIP_SEIP           ((word_t)1 << 9)
#define MIP_MEIP           ((word_t)1 << 11)
#define MIP_SUPERVISOR_MASK (MIP_SSIP | MIP_STIP | MIP_SEIP)
#define MIP_MACHINE_MASK    (MIP_MSIP | MIP_MTIP | MIP_MEIP)
#define MIP_IRQ_MASK        (MIP_SUPERVISOR_MASK | MIP_MACHINE_MASK)
#define SIP_WRITABLE_MASK   MIP_SSIP

#define IRQ_CAUSE_SSI 1u
#define IRQ_CAUSE_MSI 3u
#define IRQ_CAUSE_STI 5u
#define IRQ_CAUSE_MTI 7u
#define IRQ_CAUSE_SEI 9u
#define IRQ_CAUSE_MEI 11u
#define MCAUSE_INTERRUPT ((word_t)1 << (sizeof(word_t) * 8 - 1))

#define COUNTEREN_CY 0x1u
#define COUNTEREN_TM 0x2u
#define COUNTEREN_IR 0x4u
#define COUNTEREN_MASK (COUNTEREN_CY | COUNTEREN_TM | COUNTEREN_IR)
#define MCOUNTINHIBIT_CY 0x00000001u
#define MCOUNTINHIBIT_IR 0x00000004u

//mtvec：trap入口地址，发生异常或中断后，CPU最终要跳到哪里执行，故障处理程序的起点
//mepc：异常发生时的程序计数器，记录出事的时候执行到那一条指令了，进入trap会把当前PC存放到这里，后面mret返回时再用它恢复现场
//mcause：trap原因码表，告诉你为何进入（ecall、非法指令、定时器中断、外部中断）
//mie：机器态中断使能寄存器，负责每种中断源允不允许进来
//mip：机器态中断待处理中断寄存器，表示：哪些中断已经来了，在排队等处理
//mscratch/mtval：trap 处理程序的临时寄存器和异常附加值，先补齐状态槽位，便于 SYSTEM 指令统一分发
//mcycle/mcountinhibit：对齐 NPC 已实现的最小性能计数器语义，供 CSR 指令和 difftest reference 共享。
typedef struct {
  word_t mtvec, mepc, mcause, mstatus, mie, mip, mscratch, mtval;
  word_t stvec, sepc, scause, sscratch, stval;
  word_t medeleg, mideleg, satp;
  word_t mcounteren, scounteren, mcountinhibit;
  uint64_t mcycle, minstret;
  uint8_t fflags, frm;
} riscv64_CSR_state;

typedef struct {
  word_t gpr[32];
  uint64_t fpr[32];
  vaddr_t pc;
  riscv64_CSR_state csr;
  uint8_t priv;
} riscv64_CPU_state;

// decode
typedef struct {
  uint32_t inst;
} riscv64_ISADecodeInfo;

#endif
