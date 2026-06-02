// Focused FCSR/FRM/FFLAGS CSR smoke for the RV64GC/lp64d userland ladder.
// It checks software-visible CSR read/modify/write behavior only; FP arithmetic
// exception flag production is still a separate higher gate.

#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87efc000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option rvc
  .align 2
_start:
  li sp, FP_SMOKE_STACK

  csrwi fcsr, 0
  csrr t0, fcsr
  bnez t0, fail_clear

  li t1, 0x1f
  csrrw t0, fflags, t1
  bnez t0, fail_fflags_old0
  csrr t0, fflags
  li t2, 0x1f
  bne t0, t2, fail_fflags_write

  li t1, 0x05
  csrrc t0, fflags, t1
  li t2, 0x1f
  bne t0, t2, fail_fflags_clear_old
  csrr t0, fflags
  li t2, 0x1a
  bne t0, t2, fail_fflags_clear_new

  li t1, 0x01
  csrrs t0, fflags, t1
  li t2, 0x1a
  bne t0, t2, fail_fflags_set_old
  csrr t0, fflags
  li t2, 0x1b
  bne t0, t2, fail_fflags_set_new

  csrci fflags, 0x02
  csrr t0, fflags
  li t2, 0x19
  bne t0, t2, fail_fflags_imm_clear

  csrsi fflags, 0x02
  csrr t0, fflags
  li t2, 0x1b
  bne t0, t2, fail_fflags_imm_set

  csrwi frm, 0
  li t1, 3
  csrrw t0, frm, t1
  bnez t0, fail_frm_old0
  csrr t0, frm
  li t2, 3
  bne t0, t2, fail_frm_write

  csrwi frm, 4
  csrr t0, frm
  li t2, 4
  bne t0, t2, fail_frm_imm

  csrwi fcsr, 0
  li t1, 0x12
  csrw fflags, t1
  li t1, 3
  csrw frm, t1
  csrr t0, fcsr
  li t2, 0x72
  bne t0, t2, fail_fcsr_join

  li t1, 0x85
  csrrw t0, fcsr, t1
  li t2, 0x72
  bne t0, t2, fail_fcsr_swap_old
  csrr t0, fcsr
  li t2, 0x85
  bne t0, t2, fail_fcsr_swap_new
  csrr t0, fflags
  li t2, 0x05
  bne t0, t2, fail_fcsr_fflags
  csrr t0, frm
  li t2, 4
  bne t0, t2, fail_fcsr_frm

  li t1, 0x81
  csrrc t0, fcsr, t1
  li t2, 0x85
  bne t0, t2, fail_fcsr_clear_old
  csrr t0, fcsr
  li t2, 0x04
  bne t0, t2, fail_fcsr_clear_new

  li t1, 0x22
  csrrs t0, fcsr, t1
  li t2, 0x04
  bne t0, t2, fail_fcsr_set_old
  csrr t0, fcsr
  li t2, 0x26
  bne t0, t2, fail_fcsr_set_new

  csrr t0, fflags
  li t2, 0x06
  bne t0, t2, fail_final_fflags
  csrr t0, frm
  li t2, 1
  bne t0, t2, fail_final_frm

  csrwi fcsr, 0
  li a0, 0
  ebreak

fail_clear:
  li a0, 1
  ebreak
fail_fflags_old0:
  li a0, 2
  ebreak
fail_fflags_write:
  li a0, 3
  ebreak
fail_fflags_clear_old:
  li a0, 4
  ebreak
fail_fflags_clear_new:
  li a0, 5
  ebreak
fail_fflags_set_old:
  li a0, 6
  ebreak
fail_fflags_set_new:
  li a0, 7
  ebreak
fail_fflags_imm_clear:
  li a0, 8
  ebreak
fail_fflags_imm_set:
  li a0, 9
  ebreak
fail_frm_old0:
  li a0, 10
  ebreak
fail_frm_write:
  li a0, 11
  ebreak
fail_frm_imm:
  li a0, 12
  ebreak
fail_fcsr_join:
  li a0, 13
  ebreak
fail_fcsr_swap_old:
  li a0, 14
  ebreak
fail_fcsr_swap_new:
  li a0, 15
  ebreak
fail_fcsr_fflags:
  li a0, 16
  ebreak
fail_fcsr_frm:
  li a0, 17
  ebreak
fail_fcsr_clear_old:
  li a0, 18
  ebreak
fail_fcsr_clear_new:
  li a0, 19
  ebreak
fail_fcsr_set_old:
  li a0, 20
  ebreak
fail_fcsr_set_new:
  li a0, 21
  ebreak
fail_final_fflags:
  li a0, 22
  ebreak
fail_final_frm:
  li a0, 23
  ebreak

  .option pop
