#ifndef MINI_LINUX_STACK
#define MINI_LINUX_STACK 0x87efe000
#endif

#ifndef MINI_LINUX_UART
#define MINI_LINUX_UART 0x10000000
#endif

#define FDT_MAGIC_LE 0xedfe0dd0

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, MINI_LINUX_STACK

  bnez a0, fail_hartid
  beqz a1, fail_dtb
  lwu t0, 0(a1)
  li t1, FDT_MAGIC_LE
  bne t0, t1, fail_dtb

  li t0, MINI_LINUX_UART
  li t1, 'S'
  sb t1, 0(t0)
  li t1, '\n'
  sb t1, 0(t0)

  li a0, 0
  ebreak

fail_hartid:
  li a0, 1
  ebreak

fail_dtb:
  li a0, 2
  ebreak
  .option pop
