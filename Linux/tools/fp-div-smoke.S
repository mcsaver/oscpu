// RV64F/D focused smoke: cover FDIV.{S,D} finite, zero, inf, and NaN paths.
// This closes the divide arithmetic frontier gate; FSQRT/full fflags remain open.

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

  li t0, 0x400b000000000000
  fmv.d.x ft0, t0
  li t0, 0x3ff8000000000000
  fmv.d.x ft1, t0
  fdiv.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x4002000000000000
  bne t1, t2, fail_div_d

  li t0, 0xc020000000000000
  fmv.d.x ft0, t0
  li t0, 0x4010000000000000
  fmv.d.x ft1, t0
  fdiv.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0xc000000000000000
  bne t1, t2, fail_sign_d

  li t0, 0x3ff0000000000000
  fmv.d.x ft0, t0
  li t0, 0x4010000000000000
  fmv.d.x ft1, t0
  fdiv.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x3fd0000000000000
  bne t1, t2, fail_frac_d

  li t0, 0x0000000000000000
  fmv.d.x ft1, t0
  fdiv.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x7ff0000000000000
  bne t1, t2, fail_divzero_d

  fmv.d.x ft0, t0
  fdiv.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x7ff8000000000000
  bne t1, t2, fail_zerozero_d

  li t0, 0x7ff0000000000000
  fmv.d.x ft0, t0
  fmv.d.x ft1, t0
  fdiv.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x7ff8000000000000
  bne t1, t2, fail_infinf_d

  li t0, 0x40580000
  fmv.w.x ft3, t0
  li t0, 0x3fc00000
  fmv.w.x ft4, t0
  fdiv.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0x0000000040100000
  bne t1, t2, fail_div_s

  li t0, 0x3f800000
  fmv.w.x ft6, t0
  fdiv.s ft7, ft5, ft6, rne
  fmv.x.w t1, ft7
  li t2, 0x0000000040100000
  bne t1, t2, fail_box_s

  li t0, 0xc1000000
  fmv.w.x ft3, t0
  li t0, 0x40800000
  fmv.w.x ft4, t0
  fdiv.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0xffffffffc0000000
  bne t1, t2, fail_sign_s

  li t0, 0x3f800000
  fmv.w.x ft3, t0
  li t0, 0x00000000
  fmv.w.x ft4, t0
  fdiv.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0x000000007f800000
  bne t1, t2, fail_divzero_s

  fmv.w.x ft3, t0
  fdiv.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0x000000007fc00000
  bne t1, t2, fail_zerozero_s

  li a0, 0
  j done

fail_div_d:
  li a0, 1
  j done
fail_sign_d:
  li a0, 2
  j done
fail_frac_d:
  li a0, 3
  j done
fail_divzero_d:
  li a0, 4
  j done
fail_zerozero_d:
  li a0, 5
  j done
fail_infinf_d:
  li a0, 6
  j done
fail_div_s:
  li a0, 7
  j done
fail_box_s:
  li a0, 8
  j done
fail_sign_s:
  li a0, 9
  j done
fail_divzero_s:
  li a0, 10
  j done
fail_zerozero_s:
  li a0, 11
  j done

  .align 2
done:
  ebreak

  .option pop
