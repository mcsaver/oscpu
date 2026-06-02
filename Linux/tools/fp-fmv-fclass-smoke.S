// Focused RV64F/D smoke for the Ubuntu userland FP frontier.
// It covers FMV.{W,D}.X, FMV.X.{W,D}, and FCLASS.{S,D}; integer compares
// immediately after FP->GPR moves verify the serialized GPR recovery path.

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

  li t0, 0x0123456789abcdef
  fmv.d.x ft0, t0
  fmv.x.d t1, ft0
  bne t0, t1, fail_fmvd

  li t0, 0x80012345
  fmv.w.x ft1, t0
  fmv.x.w t1, ft1
  li t2, 0xffffffff80012345
  bne t1, t2, fail_fmvw

  li t0, 0x7ff0000000000000
  fmv.d.x ft2, t0
  fclass.d t1, ft2
  li t2, 0x080
  bne t1, t2, fail_fclass_d_pinf

  li t0, 0x8000000000000000
  fmv.d.x ft2, t0
  fclass.d t1, ft2
  li t2, 0x008
  bne t1, t2, fail_fclass_d_nzero

  li t0, 0x0010000000000000
  fmv.d.x ft2, t0
  fclass.d t1, ft2
  li t2, 0x040
  bne t1, t2, fail_fclass_d_pnorm

  li t0, 0x0000000000000001
  fmv.d.x ft2, t0
  fclass.d t1, ft2
  li t2, 0x020
  bne t1, t2, fail_fclass_d_psub

  li t0, 0x7ff8000000000001
  fmv.d.x ft2, t0
  fclass.d t1, ft2
  li t2, 0x200
  bne t1, t2, fail_fclass_d_qnan

  li t0, 0x7ff0000000000001
  fmv.d.x ft2, t0
  fclass.d t1, ft2
  li t2, 0x100
  bne t1, t2, fail_fclass_d_snan

  li t0, 0x7f800000
  fmv.w.x ft3, t0
  fclass.s t1, ft3
  li t2, 0x080
  bne t1, t2, fail_fclass_s_pinf

  li t0, 0x80000000
  fmv.w.x ft3, t0
  fclass.s t1, ft3
  li t2, 0x008
  bne t1, t2, fail_fclass_s_nzero

  li t0, 0x00800000
  fmv.w.x ft3, t0
  fclass.s t1, ft3
  li t2, 0x040
  bne t1, t2, fail_fclass_s_pnorm

  li t0, 0x00000001
  fmv.w.x ft3, t0
  fclass.s t1, ft3
  li t2, 0x020
  bne t1, t2, fail_fclass_s_psub

  li t0, 0x7fc00001
  fmv.w.x ft3, t0
  fclass.s t1, ft3
  li t2, 0x200
  bne t1, t2, fail_fclass_s_qnan

  li t0, 0x7f800001
  fmv.w.x ft3, t0
  fclass.s t1, ft3
  li t2, 0x100
  bne t1, t2, fail_fclass_s_snan

  li a0, 0
  ebreak

fail_fmvd:
  li a0, 1
  ebreak
fail_fmvw:
  li a0, 2
  ebreak
fail_fclass_d_pinf:
  li a0, 3
  ebreak
fail_fclass_d_nzero:
  li a0, 4
  ebreak
fail_fclass_d_pnorm:
  li a0, 5
  ebreak
fail_fclass_d_psub:
  li a0, 6
  ebreak
fail_fclass_d_qnan:
  li a0, 7
  ebreak
fail_fclass_d_snan:
  li a0, 8
  ebreak
fail_fclass_s_pinf:
  li a0, 9
  ebreak
fail_fclass_s_nzero:
  li a0, 10
  ebreak
fail_fclass_s_pnorm:
  li a0, 11
  ebreak
fail_fclass_s_psub:
  li a0, 12
  ebreak
fail_fclass_s_qnan:
  li a0, 13
  ebreak
fail_fclass_s_snan:
  li a0, 14
  ebreak

  .option pop
