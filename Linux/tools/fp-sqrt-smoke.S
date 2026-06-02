// RV64F/D focused smoke: cover FSQRT.{S,D} finite, zero, inf, and NaN paths.
// This closes the square-root arithmetic frontier gate; full fflags remain open.

#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87ef4000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option rvc
  .align 2
_start:
  li sp, FP_SMOKE_STACK

  li t0, 0x4010000000000000
  fmv.d.x ft0, t0
  fsqrt.d ft1, ft0, rne
  fmv.x.d t1, ft1
  li t2, 0x4000000000000000
  bne t1, t2, fail_sqrt4_d

  li t0, 0x4002000000000000
  fmv.d.x ft0, t0
  fsqrt.d ft1, ft0, rne
  fmv.x.d t1, ft1
  li t2, 0x3ff8000000000000
  bne t1, t2, fail_sqrt225_d

  li t0, 0x3fd0000000000000
  fmv.d.x ft0, t0
  fsqrt.d ft1, ft0, rne
  fmv.x.d t1, ft1
  li t2, 0x3fe0000000000000
  bne t1, t2, fail_sqrt025_d

  li t0, 0x8000000000000000
  fmv.d.x ft0, t0
  fsqrt.d ft1, ft0, rne
  fmv.x.d t1, ft1
  li t2, 0x8000000000000000
  bne t1, t2, fail_negzero_d

  li t0, 0x7ff0000000000000
  fmv.d.x ft0, t0
  fsqrt.d ft1, ft0, rne
  fmv.x.d t1, ft1
  li t2, 0x7ff0000000000000
  bne t1, t2, fail_inf_d

  li t0, 0xbff0000000000000
  fmv.d.x ft0, t0
  fsqrt.d ft1, ft0, rne
  fmv.x.d t1, ft1
  li t2, 0x7ff8000000000000
  bne t1, t2, fail_neg_d

  li t0, 0x41100000
  fmv.w.x ft2, t0
  fsqrt.s ft3, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0x0000000040400000
  bne t1, t2, fail_sqrt9_s

  li t0, 0x40100000
  fmv.w.x ft2, t0
  fsqrt.s ft3, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0x000000003fc00000
  bne t1, t2, fail_sqrt225_s

  li t0, 0x3f800000
  fmv.w.x ft2, t0
  fsqrt.s ft3, ft2, rne
  fsqrt.s ft4, ft3, rne
  fmv.x.w t1, ft4
  li t2, 0x000000003f800000
  bne t1, t2, fail_box_s

  li t0, 0x80000000
  fmv.w.x ft2, t0
  fsqrt.s ft3, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0xffffffff80000000
  bne t1, t2, fail_negzero_s

  li t0, 0x7f800000
  fmv.w.x ft2, t0
  fsqrt.s ft3, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0x000000007f800000
  bne t1, t2, fail_inf_s

  li t0, 0xbf800000
  fmv.w.x ft2, t0
  fsqrt.s ft3, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0x000000007fc00000
  bne t1, t2, fail_neg_s

  li a0, 0
  j done

fail_sqrt4_d:
  li a0, 1
  j done
fail_sqrt225_d:
  li a0, 2
  j done
fail_sqrt025_d:
  li a0, 3
  j done
fail_negzero_d:
  li a0, 4
  j done
fail_inf_d:
  li a0, 5
  j done
fail_neg_d:
  li a0, 6
  j done
fail_sqrt9_s:
  li a0, 7
  j done
fail_sqrt225_s:
  li a0, 8
  j done
fail_box_s:
  li a0, 9
  j done
fail_negzero_s:
  li a0, 10
  j done
fail_inf_s:
  li a0, 11
  j done
fail_neg_s:
  li a0, 12
  j done

  .align 2
done:
  ebreak

  .option pop
