#ifndef ARCH_H__
#define ARCH_H__

#ifdef __riscv_e
#define NR_REGS 16
#else
#define NR_REGS 32
#endif

struct Context {
  // TODO: fix the order of these members to match trap.S
  uintptr_t gpr[NR_REGS], mcause, mstatus, mepc;
  void *pdir;//地址空间信息
};
//pdir的设计意图：
//trap进来->如果开了虚拟内存，把当前地址空间根保存到c->pdir
//切换上下文->用新context里的pdir切换satp

#ifdef __riscv_e
#define GPR1 gpr[15] // a5
#else
#define GPR1 gpr[17] // a7
#endif

#define GPR2 gpr[10] // a0，常用于“参数”语义
#define GPR3 gpr[11] // a1
#define GPR4 gpr[12] // a2
#define GPRx gpr[10]//  a0，常用于“返回值”语义

#endif
