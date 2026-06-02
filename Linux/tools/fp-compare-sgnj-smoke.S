// RV64F/D focused smoke: cover FSGNJ.{S,D} and FEQ/FLT/FLE.{S,D}.
// This is a userland frontier gate, not a claim of full FP arithmetic/fflags.

#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87ef8000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option rvc
  .align 2
_start:
  li sp, FP_SMOKE_STACK

  li t0, 0x3ff0000000000000
  fmv.d.x ft0, t0
  li t0, 0xc000000000000000
  fmv.d.x ft1, t0
  fsgnj.d ft2, ft0, ft1
  fmv.x.d t1, ft2
  li t2, 0xbff0000000000000
  bne t1, t2, fail_sgnj_d

  fsgnjn.d ft2, ft0, ft1
  fmv.x.d t1, ft2
  li t2, 0x3ff0000000000000
  bne t1, t2, fail_sgnjn_d

  fsgnjx.d ft2, ft0, ft1
  fmv.x.d t1, ft2
  li t2, 0xbff0000000000000
  bne t1, t2, fail_sgnjx_d

  feq.d t1, ft0, ft0
  li t2, 1
  bne t1, t2, fail_feq_d

  flt.d t1, ft1, ft0
  li t2, 1
  bne t1, t2, fail_flt_d

  fle.d t1, ft0, ft0
  li t2, 1
  bne t1, t2, fail_fle_d

  li t0, 0x8000000000000000
  fmv.d.x ft3, t0
  li t0, 0x0000000000000000
  fmv.d.x ft4, t0
  feq.d t1, ft3, ft4
  li t2, 1
  bne t1, t2, fail_zero_eq_d

  li t0, 0x7ff8000000000001
  fmv.d.x ft5, t0
  feq.d t1, ft5, ft5
  bnez t1, fail_nan_eq_d

  li t0, 0x3f800000
  fmv.w.x ft6, t0
  li t0, 0xbf800000
  fmv.w.x ft7, t0
  fsgnj.s ft8, ft6, ft7
  fmv.x.w t1, ft8
  li t2, 0xffffffffbf800000
  bne t1, t2, fail_sgnj_s

  flt.s t1, ft7, ft6
  li t2, 1
  bne t1, t2, fail_flt_s

  fle.s t1, ft6, ft6
  li t2, 1
  bne t1, t2, fail_fle_s

  li a0, 0
  j done

fail_sgnj_d:
  li a0, 1
  j done
fail_sgnjn_d:
  li a0, 2
  j done
fail_sgnjx_d:
  li a0, 3
  j done
fail_feq_d:
  li a0, 4
  j done
fail_flt_d:
  li a0, 5
  j done
fail_fle_d:
  li a0, 6
  j done
fail_zero_eq_d:
  li a0, 7
  j done
fail_nan_eq_d:
  li a0, 8
  j done
fail_sgnj_s:
  li a0, 9
  j done
fail_flt_s:
  li a0, 10
  j done
fail_fle_s:
  li a0, 11
  j done

  .align 2
done:
  ebreak

  .option pop
