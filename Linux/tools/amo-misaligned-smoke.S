// NEMU RV64A 精确异常 smoke：有效的非对齐 LR/SC/AMO 必须投递地址异常。
#ifndef AMO_MISALIGNED_STACK
#define AMO_MISALIGNED_STACK 0x87eef000
#endif

#ifndef SYSCON_RESET_MMIO
#define SYSCON_RESET_MMIO 0x100000
#endif

#ifndef SYSCON_POWEROFF_VALUE
#define SYSCON_POWEROFF_VALUE 0x5555
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2

_start:
  li sp, AMO_MISALIGNED_STACK
  la t0, trap_handler
  csrw mtvec, t0
  li s2, 0

  la t0, amo_data
  addi s1, t0, 1
  li s0, 4
  lr.w t2, (s1)

  la t0, amo_data
  addi s1, t0, 1
  li s0, 6
  li t3, 0x1234
  sc.w t4, t3, (s1)

  la t0, amo_data
  addi s1, t0, 1
  li s0, 6
  li t3, 1
  amoadd.w t4, t3, (s1)

  la t0, amo_data
  addi s1, t0, 4
  li s0, 4
  lr.d t2, (s1)

  la t0, amo_data
  addi s1, t0, 4
  li s0, 6
  li t3, 0x5678
  sc.d t4, t3, (s1)

  la t0, amo_data
  addi s1, t0, 4
  li s0, 6
  li t3, 1
  amoadd.d t4, t3, (s1)

  li t0, 6
  bne s2, t0, fail
  li t0, SYSCON_RESET_MMIO
  li t1, SYSCON_POWEROFF_VALUE
  sw t1, 0(t0)

pass_spin:
  j pass_spin

trap_handler:
  csrr t0, mcause
  bne t0, s0, fail
  csrr t0, mtval
  bne t0, s1, fail
  addi s2, s2, 1
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0
  mret

fail:
  li t0, 0x10000000
  li t1, 0x46
  sb t1, 0(t0)

fail_spin:
  j fail_spin

  .align 3
amo_data:
  .dword 0x1122334455667788
  .dword 0x99aabbccddeeff00

  .option pop
