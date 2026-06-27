// RV64F/D focused smoke: cover FMUL.{S,D} finite, zero, inf, and NaN paths.
// This is the next arithmetic frontier gate; FDIV/FSQRT and full fflags remain open.

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
  li t0, (3 << 13)
  csrs mstatus, t0

  li t0, 0x3ff8000000000000
  fmv.d.x ft0, t0
  li t0, 0x4002000000000000
  fmv.d.x ft1, t0
  fmul.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x400b000000000000
  bne t1, t2, fail_mul_d

  li t0, 0xc000000000000000
  fmv.d.x ft0, t0
  li t0, 0x4010000000000000
  fmv.d.x ft1, t0
  fmul.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0xc020000000000000
  bne t1, t2, fail_sign_d

  li t0, 0x0000000000000000
  fmv.d.x ft0, t0
  li t0, 0xc000000000000000
  fmv.d.x ft1, t0
  fmul.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x8000000000000000
  bne t1, t2, fail_zero_d

  li t0, 0x7ff0000000000000
  fmv.d.x ft0, t0
  li t0, 0xc000000000000000
  fmv.d.x ft1, t0
  fmul.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0xfff0000000000000
  bne t1, t2, fail_inf_d

  li t0, 0x0000000000000000
  fmv.d.x ft1, t0
  fmul.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x7ff8000000000000
  bne t1, t2, fail_nan_d

  li t0, 0x3fc00000
  fmv.w.x ft3, t0
  li t0, 0x40100000
  fmv.w.x ft4, t0
  fmul.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0x0000000040580000
  bne t1, t2, fail_mul_s

  li t0, 0x3f800000
  fmv.w.x ft6, t0
  fmul.s ft7, ft5, ft6, rne
  fmv.x.w t1, ft7
  li t2, 0x0000000040580000
  bne t1, t2, fail_box_s

  li t0, 0xc0000000
  fmv.w.x ft3, t0
  li t0, 0x40800000
  fmv.w.x ft4, t0
  fmul.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0xffffffffc1000000
  bne t1, t2, fail_sign_s

  li t0, 0x00000000
  fmv.w.x ft3, t0
  li t0, 0x7f800000
  fmv.w.x ft4, t0
  fmul.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0x000000007fc00000
  bne t1, t2, fail_nan_s

  li a0, 0
  j done

fail_mul_d:
  li a0, 1
  j done
fail_sign_d:
  li a0, 2
  j done
fail_zero_d:
  li a0, 3
  j done
fail_inf_d:
  li a0, 4
  j done
fail_nan_d:
  li a0, 5
  j done
fail_mul_s:
  li a0, 6
  j done
fail_box_s:
  li a0, 7
  j done
fail_sign_s:
  li a0, 8
  j done
fail_nan_s:
  li a0, 9
  j done

  .align 2
done:
  ebreak

  .option pop
