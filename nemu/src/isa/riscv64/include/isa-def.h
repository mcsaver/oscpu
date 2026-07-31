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
// menvcfg(0x30a): S/U 环境配置。NEMU 已在 MMU walker 中实现 Svnapot 64KiB NAPOT；
// Svpbmt/Sstc/Svadu 仍未实现，相关环境配置位只保留 WARL 读写语义。寄存器本身必须
// 可读写(WARL)，否则 guest 的
// `csrc menvcfg, t` 会误触 illegal instruction。ACT4 svpbmt_disabled 测试正是靠清 PBMTE 走此路径。
#define CSR_MENVCFG  0x30a
#define MENVCFG_WRITABLE_MASK \
    (((word_t)1 << 0) | ((word_t)3 << 4) | ((word_t)1 << 6) | ((word_t)1 << 7) | \
     ((word_t)7 << 61))
#define CSR_PMPCFG0  0x3a0
#define CSR_PMPCFG1  0x3a1
#define CSR_PMPCFG2  0x3a2
#define CSR_PMPCFG3  0x3a3
#define CSR_PMPADDR0 0x3b0
#define CSR_PMPADDR15 0x3bf
#define CSR_MSCRATCH 0x340
#define CSR_MEPC     0x341
#define CSR_MCAUSE   0x342
#define CSR_MTVAL    0x343
#define CSR_MIP      0x344
#define CSR_MCYCLE   0xb00
#define CSR_MINSTRET 0xb02
#define CSR_MCYCLEH  0xb80  // RV32-only high-half CSR; RV64 译码必须视为保留地址
#define CSR_MINSTRETH 0xb82 // RV32-only high-half CSR; RV64 译码必须视为保留地址
#define CSR_CYCLE    0xc00
#define CSR_TIME     0xc01
#define CSR_INSTRET  0xc02
#define CSR_CYCLEH   0xc80  // RV32-only high-half CSR
#define CSR_TIMEH    0xc81  // RV32-only high-half CSR
#define CSR_INSTRETH 0xc82  // RV32-only high-half CSR
#define CSR_MVENDORID 0xf11
#define CSR_MARCHID  0xf12
#define CSR_MIMPID   0xf13
#define CSR_MHARTID  0xf14
// debug trigger(Sdtrig)最小 no-op 实现(对齐 NPC CsrFile): tselect 读回 NO_TRIGGER(1)、
// tdata1/tdata2/tcontrol 恒 0、写忽略、不 illegal —— 让 breakpoint 测试走 tselect 逃生门。
#define CSR_TSELECT  0x7a0
#define CSR_TDATA1   0x7a1
#define CSR_TDATA2   0x7a2
#define CSR_TCONTROL 0x7a5

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
// VS(vector context status, bits[10:9])。NEMU 未实现 V 扩展, 但 sail-rv64-max(max 含 V)参考模型
// 启动即把 VS 置 Dirty(3), 且 ACT 特权测试每次 trap 都把 sstatus 打包成签名字与金标准逐位比对;
// 只要 VS 读回值不一致, 第一条 trap 就失配。这里把 VS 作为可写保持的 WARL 字段暴露, 让 guest 写 VS
// 后能读回一致值, 与参考模型对齐(WARL 保留写入值即满足这些测试, 不需要真正实现 V)。
#define MSTATUS_VS_MASK    ((word_t)3 << 9)
#define MSTATUS_VS_DIRTY   ((word_t)3 << 9)
#define MSTATUS_MPRV       ((word_t)1 << 17)
#define MSTATUS_SUM        ((word_t)1 << 18)
#define MSTATUS_MXR        ((word_t)1 << 19)
#define MSTATUS_TVM        ((word_t)1 << 20)  // Trap Virtual Memory: S 态且置位时 satp/SFENCE.VMA 非法
#define MSTATUS_TW         ((word_t)1 << 21)  // Timeout Wait: priv<M 且置位时 WFI 非法
#define MSTATUS_TSR        ((word_t)1 << 22)  // Trap SRET: S 态且置位时 SRET 非法
#define MSTATUS_UXL        MUXDEF(CONFIG_ISA64, ((word_t)2 << 32), 0)
#define MSTATUS_SXL        MUXDEF(CONFIG_ISA64, ((word_t)2 << 34), 0)
#define MSTATUS_SXL_UXL    (MSTATUS_SXL | MSTATUS_UXL)
#define MSTATUS_SD         MUXDEF(CONFIG_ISA64, ((word_t)1 << 63), ((word_t)1 << 31))
#define SSTATUS_MASK       (MSTATUS_SIE | MSTATUS_SPIE | MSTATUS_SPP | \
                            MSTATUS_VS_MASK | \
                            MSTATUS_FS_MASK | MSTATUS_SUM | MSTATUS_MXR | \
                            MSTATUS_UXL)
#define SSTATUS_WRITABLE_MASK \
    (MSTATUS_SIE | MSTATUS_SPIE | MSTATUS_SPP | MSTATUS_VS_MASK | \
     MSTATUS_FS_MASK | MSTATUS_SUM | MSTATUS_MXR)
#define MSTATUS_WRITABLE_MASK \
    (MSTATUS_SIE | MSTATUS_MIE | MSTATUS_SPIE | MSTATUS_MPIE | \
     MSTATUS_SPP | MSTATUS_VS_MASK | MSTATUS_FS_MASK | MSTATUS_MPP_MASK | \
     MSTATUS_MPRV | MSTATUS_SUM | MSTATUS_MXR | MSTATUS_TVM | \
     MSTATUS_TW | MSTATUS_TSR)

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

// NEMU 实现的可委托同步异常与 S 级中断。M-mode ECALL(bit 11)不可委托；
// 保留/未实现的异常和中断位按 WARL 规则读回 0。
#define MEDELEG_WRITABLE_MASK \
    (((word_t)0x3ff) | ((word_t)1 << 12) | ((word_t)1 << 13) | ((word_t)1 << 15))
#define MIDELEG_WRITABLE_MASK MIP_SUPERVISOR_MASK

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

#define RISCV64_PMP_ENTRY_COUNT 16u
#define PMP_CFG_R 0x01u
#define PMP_CFG_W 0x02u
#define PMP_CFG_X 0x04u
#define PMP_CFG_A_MASK 0x18u
#define PMP_CFG_A_OFF 0x00u
#define PMP_CFG_A_TOR 0x08u
#define PMP_CFG_A_NA4 0x10u
#define PMP_CFG_A_NAPOT 0x18u
#define PMP_CFG_L 0x80u
#define PMPADDR_MASK ((word_t)((1ull << 54) - 1))

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
  word_t menvcfg;
  word_t mcounteren, scounteren, mcountinhibit;
  uint8_t pmpcfg[RISCV64_PMP_ENTRY_COUNT];
  word_t pmpaddr[RISCV64_PMP_ENTRY_COUNT];
  bool pmp_active;
  uint64_t mcycle, minstret;
  uint8_t fflags, frm;
} riscv64_CSR_state;

typedef struct {
  // pc 必须紧跟 gpr[32]：difftest 的 DIFFTEST_REG_SIZE=(GPR_NUM+1) words 假设 gpr+pc 连续。
  // 原布局 fpr[32] 夹在 gpr 与 pc 之间,使 regcpy 把 fpr[0] 当成 pc 同步,导致 DUT 读到的
  // ref.pc 恒为 fpr[0](init 时被写入 reset pc 后不变)→ difftest 首指令即 PC 不匹配。
  word_t gpr[32];
  vaddr_t pc;
  uint64_t fpr[32];
  riscv64_CSR_state csr;
  uint8_t priv;
} riscv64_CPU_state;

// decode
typedef struct {
  uint32_t inst;
} riscv64_ISADecodeInfo;

#endif
