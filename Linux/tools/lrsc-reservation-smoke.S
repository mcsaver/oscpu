// NEMU RV64A LR/SC reservation smoke：普通 store 覆盖 reservation 后 SC 必须失败。
#ifndef LRSC_RESERVATION_STACK
#define LRSC_RESERVATION_STACK 0x87eed000
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
  li sp, LRSC_RESERVATION_STACK

  la s0, word_data
  li t0, 0x11112222
  sw t0, 0(s0)
  lr.w t1, (s0)
  li t2, 0x33334444
  sc.w t3, t2, (s0)
  bnez t3, fail
  lw t4, 0(s0)
  li t5, 0x33334444
  bne t4, t5, fail

  li t0, 0x55667788
  sw t0, 0(s0)
  lr.w t1, (s0)
  li t0, 0x11223344
  sw t0, 0(s0)
  li t2, 0x99aabbcc
  sc.w t3, t2, (s0)
  li t4, 1
  bne t3, t4, fail
  lw t5, 0(s0)
  li t6, 0x11223344
  bne t5, t6, fail

  li t0, 0x66778899
  sw t0, 0(s0)
  lr.w t1, (s0)
  li t0, 0xaa
  sb t0, 1(s0)
  li t2, 0x12345678
  sc.w t3, t2, (s0)
  li t4, 1
  bne t3, t4, fail
  lw t5, 0(s0)
  li t6, 0x6677aa99
  bne t5, t6, fail

  la s1, dword_data
  li t0, 0x1122334455667788
  sd t0, 0(s1)
  lr.d t1, (s1)
  sw zero, 4(s1)
  li t2, 0x99aabbccddeeff00
  sc.d t3, t2, (s1)
  li t4, 1
  bne t3, t4, fail
  ld t5, 0(s1)
  li t6, 0x0000000055667788
  bne t5, t6, fail

pass:
  li t0, SYSCON_RESET_MMIO
  li t1, SYSCON_POWEROFF_VALUE
  sw t1, 0(t0)

pass_spin:
  j pass_spin

fail:
  li t0, 0x10000000
  li t1, 0x46
  sb t1, 0(t0)

fail_spin:
  j fail_spin

  .section .data, "aw", @progbits
  .balign 8
word_data:
  .word 0
  .word 0

  .balign 8
dword_data:
  .dword 0

  .option pop
