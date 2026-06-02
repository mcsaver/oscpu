// Focused RV64 OoO RAW hazard smoke for an ALU result consumed by a branch.
// It mirrors the Linux calibrate_delay local-array clear loop that sits just
// before the stack canary slot.

#ifndef BRANCH_RAW_STACK
#define BRANCH_RAW_STACK 0x87ef8000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option rvc
  .align 2
_start:
  li sp, BRANCH_RAW_STACK
  li t6, 4096
  li t1, 0x1122334455667788

outer:
  addi sp, sp, -64
  sd t1, 40(sp)
  mv s5, sp
  li s2, 0
  li s10, 5

clear_loop:
  sd zero, 0(s5)
  addiw s2, s2, 1
  addi s5, s5, 8
  bne s2, s10, clear_loop

  ld t0, 40(sp)
  bne t0, t1, fail_sentinel
  addi sp, sp, 64
  addi t6, t6, -1
  bnez t6, outer

  li a0, 0
  ebreak

fail_sentinel:
  li a0, 1
  ebreak

  .option pop
