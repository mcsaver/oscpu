// RV64F/D focused smoke: cover FMADD/FMSUB/FNMSUB/FNMADD.{S,D}.

#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87ef3000
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
  li t0, 0x4010000000000000
  fmv.d.x ft1, t0
  li t0, 0x4000000000000000
  fmv.d.x ft2, t0

  fmadd.d ft3, ft0, ft1, ft2, rne
  fmv.x.d t1, ft3
  li t2, 0x4020000000000000
  bne t1, t2, fail_fmadd_d

  fmsub.d ft3, ft0, ft1, ft2, rne
  fmv.x.d t1, ft3
  li t2, 0x4010000000000000
  bne t1, t2, fail_fmsub_d

  fnmsub.d ft3, ft0, ft1, ft2, rne
  fmv.x.d t1, ft3
  li t2, 0xc010000000000000
  bne t1, t2, fail_fnmsub_d

  fnmadd.d ft3, ft0, ft1, ft2, rne
  fmv.x.d t1, ft3
  li t2, 0xc020000000000000
  bne t1, t2, fail_fnmadd_d

  li t0, 0x0000000000000000
  fmv.d.x ft0, t0
  li t0, 0x7ff0000000000000
  fmv.d.x ft1, t0
  li t0, 0x3ff0000000000000
  fmv.d.x ft2, t0
  fmadd.d ft3, ft0, ft1, ft2, rne
  fmv.x.d t1, ft3
  li t2, 0x7ff8000000000000
  bne t1, t2, fail_nan_d

  li t0, 0x3fc00000
  fmv.w.x ft0, t0
  li t0, 0x40800000
  fmv.w.x ft1, t0
  li t0, 0x40000000
  fmv.w.x ft2, t0

  fmadd.s ft3, ft0, ft1, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0x0000000041000000
  bne t1, t2, fail_fmadd_s

  fmsub.s ft3, ft0, ft1, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0x0000000040800000
  bne t1, t2, fail_fmsub_s

  fnmsub.s ft3, ft0, ft1, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0xffffffffc0800000
  bne t1, t2, fail_fnmsub_s

  fnmadd.s ft3, ft0, ft1, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0xffffffffc1000000
  bne t1, t2, fail_fnmadd_s

  li t0, 0x00000000
  fmv.w.x ft0, t0
  li t0, 0x7f800000
  fmv.w.x ft1, t0
  li t0, 0x3f800000
  fmv.w.x ft2, t0
  fmadd.s ft3, ft0, ft1, ft2, rne
  fmv.x.w t1, ft3
  li t2, 0x000000007fc00000
  bne t1, t2, fail_nan_s

  li a0, 0
  j done

fail_fmadd_d:
  li a0, 1
  j done
fail_fmsub_d:
  li a0, 2
  j done
fail_fnmsub_d:
  li a0, 3
  j done
fail_fnmadd_d:
  li a0, 4
  j done
fail_nan_d:
  li a0, 5
  j done
fail_fmadd_s:
  li a0, 6
  j done
fail_fmsub_s:
  li a0, 7
  j done
fail_fnmsub_s:
  li a0, 8
  j done
fail_fnmadd_s:
  li a0, 9
  j done
fail_nan_s:
  li a0, 10
  j done

  .align 2
done:
  ebreak

  .option pop
