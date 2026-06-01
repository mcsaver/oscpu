// RV64F/D focused smoke: cover FMIN/FMAX.{S,D} finite, zero, and NaN paths.
// This remains a focused userland gate and does not claim full fflags support.

#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87ef6000
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

  fmin.d ft2, ft0, ft1
  fmv.x.d t1, ft2
  li t2, 0xc000000000000000
  bne t1, t2, fail_min_d

  fmax.d ft2, ft0, ft1
  fmv.x.d t1, ft2
  li t2, 0x3ff0000000000000
  bne t1, t2, fail_max_d

  li t0, 0x8000000000000000
  fmv.d.x ft3, t0
  li t0, 0x0000000000000000
  fmv.d.x ft4, t0

  fmin.d ft2, ft3, ft4
  fmv.x.d t1, ft2
  li t2, 0x8000000000000000
  bne t1, t2, fail_min_zero_d

  fmax.d ft2, ft3, ft4
  fmv.x.d t1, ft2
  li t2, 0x0000000000000000
  bne t1, t2, fail_max_zero_d

  li t0, 0x7ff8000000000001
  fmv.d.x ft5, t0
  fmin.d ft2, ft5, ft0
  fmv.x.d t1, ft2
  li t2, 0x3ff0000000000000
  bne t1, t2, fail_min_nan_d

  fmax.d ft2, ft5, ft5
  fmv.x.d t1, ft2
  li t2, 0x7ff8000000000000
  bne t1, t2, fail_max_nan_d

  li t0, 0x3f800000
  fmv.w.x ft6, t0
  li t0, 0xc0000000
  fmv.w.x ft7, t0

  fmin.s ft8, ft6, ft7
  fmv.x.w t1, ft8
  li t2, 0xffffffffc0000000
  bne t1, t2, fail_min_s

  fmax.s ft8, ft6, ft7
  fmv.x.w t1, ft8
  li t2, 0x000000003f800000
  bne t1, t2, fail_max_s

  li t0, 0x7fc00001
  fmv.w.x ft9, t0
  fmin.s ft8, ft9, ft6
  fmv.x.w t1, ft8
  li t2, 0x000000003f800000
  bne t1, t2, fail_min_nan_s

  fmax.s ft8, ft9, ft9
  fmv.x.w t1, ft8
  li t2, 0x000000007fc00000
  bne t1, t2, fail_max_nan_s

  li a0, 0
  j done

fail_min_d:
  li a0, 1
  j done
fail_max_d:
  li a0, 2
  j done
fail_min_zero_d:
  li a0, 3
  j done
fail_max_zero_d:
  li a0, 4
  j done
fail_min_nan_d:
  li a0, 5
  j done
fail_max_nan_d:
  li a0, 6
  j done
fail_min_s:
  li a0, 7
  j done
fail_max_s:
  li a0, 8
  j done
fail_min_nan_s:
  li a0, 9
  j done
fail_max_nan_s:
  li a0, 10
  j done

  .align 2
done:
  ebreak

  .option pop
