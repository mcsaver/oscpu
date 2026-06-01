// RV64F/D focused smoke: cover FADD/FSUB.{S,D} finite, zero, inf, and NaN.
// This is an arithmetic frontier gate; full fflags/dynamic rounding remains open.

#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87ef5000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option rvc
  .align 2
_start:
  li sp, FP_SMOKE_STACK

  li t0, 0x3ff8000000000000
  fmv.d.x ft0, t0
  li t0, 0x4002000000000000
  fmv.d.x ft1, t0
  fadd.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x400e000000000000
  bne t1, t2, fail_add_d

  li t0, 0x4016000000000000
  fmv.d.x ft0, t0
  li t0, 0x4002000000000000
  fmv.d.x ft1, t0
  fsub.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x400a000000000000
  bne t1, t2, fail_sub_d

  li t0, 0x3ff0000000000000
  fmv.d.x ft0, t0
  li t0, 0xbff0000000000000
  fmv.d.x ft1, t0
  fadd.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  bnez t1, fail_cancel_d

  li t0, 0x7ff0000000000000
  fmv.d.x ft0, t0
  li t0, 0x3ff0000000000000
  fmv.d.x ft1, t0
  fadd.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x7ff0000000000000
  bne t1, t2, fail_inf_d

  li t0, 0xfff0000000000000
  fmv.d.x ft1, t0
  fadd.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x7ff8000000000000
  bne t1, t2, fail_nan_d

  li t0, 0x3fc00000
  fmv.w.x ft3, t0
  li t0, 0x40100000
  fmv.w.x ft4, t0
  fadd.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0x0000000040700000
  bne t1, t2, fail_add_s

  li t0, 0x40b00000
  fmv.w.x ft3, t0
  li t0, 0x40100000
  fmv.w.x ft4, t0
  fsub.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0x0000000040500000
  bne t1, t2, fail_sub_s

  li t0, 0x7f800000
  fmv.w.x ft3, t0
  li t0, 0xff800000
  fmv.w.x ft4, t0
  fadd.s ft5, ft3, ft4, rne
  fmv.x.w t1, ft5
  li t2, 0x000000007fc00000
  bne t1, t2, fail_nan_s

  li a0, 0
  j done

fail_add_d:
  li a0, 1
  j done
fail_sub_d:
  li a0, 2
  j done
fail_cancel_d:
  li a0, 3
  j done
fail_inf_d:
  li a0, 4
  j done
fail_nan_d:
  li a0, 5
  j done
fail_add_s:
  li a0, 6
  j done
fail_sub_s:
  li a0, 7
  j done
fail_nan_s:
  li a0, 8
  j done

  .align 2
done:
  ebreak

  .option pop
