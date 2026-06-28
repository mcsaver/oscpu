// FP#1 验证 smoke: 动态舍入(fdiv.d 无 rm=dyn)是否随 fcsr.frm 变化。
// 1.0/10.0: RNE→0x3fb999999999999a, RTZ→0x3fb9999999999999。
// 修复前(frm 未路由)RTZ 被当 RNE→fail_rtz(a0=2);修复后 a0=0 GOOD TRAP。
#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87efa000
#endif
  .section .text, "ax", @progbits
  .globl _start
  .align 2
_start:
  li sp, FP_SMOKE_STACK
  li t0, (3 << 13)
  csrs mstatus, t0
  li t0, 0x3ff0000000000000
  fmv.d.x ft0, t0          // 1.0
  li t0, 0x4024000000000000
  fmv.d.x ft1, t0          // 10.0
  csrwi frm, 0
  fence
  fdiv.d ft2, ft0, ft1     // dyn rounding (rm=111) -> RNE
  fmv.x.d t1, ft2
  li t2, 0x3fb999999999999a
  bne t1, t2, fail_rne
  csrwi frm, 1
  fence
  fdiv.d ft2, ft0, ft1     // dyn rounding -> must be RTZ now
  fmv.x.d t1, ft2
  li t2, 0x3fb9999999999999
  bne t1, t2, fail_rtz
  csrwi frm, 0
  li a0, 0
  j done
fail_rne:
  li a0, 1
  j done
fail_rtz:
  li a0, 2
  j done
  .align 2
done:
  ebreak
