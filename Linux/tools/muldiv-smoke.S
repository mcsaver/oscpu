// Focused RV64M smoke for the OoO integer MulDiv execution path.
// It covers high-half multiply, signed/unsigned division, corner cases, and *W sign extension.

#ifndef MULDIV_SMOKE_STACK
#define MULDIV_SMOKE_STACK 0x87ef0000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, MULDIV_SMOKE_STACK

  li t0, 7
  li t1, -3
  mul t2, t0, t1
  li t3, -21
  bne t2, t3, fail_mul
  addi t4, t2, 21
  bnez t4, fail_mul_raw

  li t0, -2
  li t1, 3
  mulh t2, t0, t1
  li t3, -1
  bne t2, t3, fail_mulh

  mulhsu t2, t0, t1
  bne t2, t3, fail_mulhsu

  li t0, 0x8000000000000000
  li t1, 2
  mulhu t2, t0, t1
  li t3, 1
  bne t2, t3, fail_mulhu

  li t0, -100
  li t1, 7
  div t2, t0, t1
  li t3, -14
  bne t2, t3, fail_div
  addi t4, t2, 14
  bnez t4, fail_div_raw

  rem t2, t0, t1
  li t3, -2
  bne t2, t3, fail_rem

  li t0, 100
  li t1, 7
  divu t2, t0, t1
  li t3, 14
  bne t2, t3, fail_divu

  remu t2, t0, t1
  li t3, 2
  bne t2, t3, fail_remu

  li t0, 0x123456789abcdef0
  li t1, 0
  div t2, t0, t1
  li t3, -1
  bne t2, t3, fail_div_zero

  rem t2, t0, t1
  bne t2, t0, fail_rem_zero

  li t0, 0x8000000000000000
  li t1, -1
  div t2, t0, t1
  bne t2, t0, fail_div_overflow

  rem t2, t0, t1
  bnez t2, fail_rem_overflow

  li t0, 0x0000000100000003
  li t1, 2
  mulw t2, t0, t1
  li t3, 6
  bne t2, t3, fail_mulw

  li t0, 0xffffffff80000000
  li t1, -1
  divw t2, t0, t1
  li t3, 0xffffffff80000000
  bne t2, t3, fail_divw_overflow

  remw t2, t0, t1
  bnez t2, fail_remw_overflow

  li t0, 0xffffffff
  li t1, 2
  divuw t2, t0, t1
  li t3, 0x7fffffff
  bne t2, t3, fail_divuw

  remuw t2, t0, t1
  li t3, 1
  bne t2, t3, fail_remuw

  li a0, 0
  ebreak

fail_mul:
  li a0, 1
  ebreak
fail_mul_raw:
  li a0, 2
  ebreak
fail_mulh:
  li a0, 3
  ebreak
fail_mulhsu:
  li a0, 4
  ebreak
fail_mulhu:
  li a0, 5
  ebreak
fail_div:
  li a0, 6
  ebreak
fail_div_raw:
  li a0, 7
  ebreak
fail_rem:
  li a0, 8
  ebreak
fail_divu:
  li a0, 9
  ebreak
fail_remu:
  li a0, 10
  ebreak
fail_div_zero:
  li a0, 11
  ebreak
fail_rem_zero:
  li a0, 12
  ebreak
fail_div_overflow:
  li a0, 13
  ebreak
fail_rem_overflow:
  li a0, 14
  ebreak
fail_mulw:
  li a0, 15
  ebreak
fail_divw_overflow:
  li a0, 16
  ebreak
fail_remw_overflow:
  li a0, 17
  ebreak
fail_divuw:
  li a0, 18
  ebreak
fail_remuw:
  li a0, 19
  ebreak

  .option pop
