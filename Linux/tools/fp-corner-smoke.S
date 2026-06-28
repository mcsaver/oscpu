// FP#5/#6 验证: Inf/0 无 DZ(仍 Inf) + 有限/0 仍置 DZ + FCLASS.S 未 box→qNaN。
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
  // FP#5a: +Inf / +0 -> +Inf, 不置 DZ
  csrwi fflags, 0
  li t0, 0x7ff0000000000000
  fmv.d.x ft0, t0
  li t0, 0
  fmv.d.x ft1, t0
  fdiv.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  li t2, 0x7ff0000000000000
  bne t1, t2, fail_inf0_val
  csrr t1, fflags
  andi t1, t1, 0x8
  bnez t1, fail_inf0_dz
  // FP#5b: 1.0 / +0 -> +Inf, 必置 DZ(正确case不回退)
  csrwi fflags, 0
  li t0, 0x3ff0000000000000
  fmv.d.x ft0, t0
  fdiv.d ft2, ft0, ft1, rne
  fmv.x.d t3, ft2
  csrr t1, fflags
  andi t1, t1, 0x8
  beqz t1, fail_fin0_dz
  // FP#6: 未 box 单精度 fclass.s -> qNaN(0x200)
  li t0, 0x123456789abcdef0
  fmv.d.x ft0, t0
  fclass.s t1, ft0
  li t2, 0x200
  bne t1, t2, fail_fclass_box
  // FP#4: RDN 下 1.0+(-1.0)=-0; RNE 下 =+0
  li t0, 0x3ff0000000000000
  fmv.d.x ft0, t0
  li t0, 0xbff0000000000000
  fmv.d.x ft1, t0
  fadd.d ft2, ft0, ft1, rdn
  fmv.x.d t1, ft2
  li t2, 0x8000000000000000
  bne t1, t2, fail_rdn_cancel
  fadd.d ft2, ft0, ft1, rne
  fmv.x.d t1, ft2
  bnez t1, fail_rne_cancel
  // FP#3: max+max 上溢 RTZ->最大有限, RNE->+Inf
  li t0, 0x7fefffffffffffff
  fmv.d.x ft0, t0
  fadd.d ft2, ft0, ft0, rtz
  fmv.x.d t1, ft2
  li t2, 0x7fefffffffffffff
  bne t1, t2, fail_of_rtz
  fadd.d ft2, ft0, ft0, rne
  fmv.x.d t1, ft2
  li t2, 0x7ff0000000000000
  bne t1, t2, fail_of_rne
  li a0, 0
  j done
fail_inf0_val:   li a0, 1; ebreak
fail_inf0_dz:    li a0, 2; ebreak
fail_fin0_dz:    li a0, 3; ebreak
fail_fclass_box: li a0, 4; ebreak
fail_rdn_cancel:  li a0, 5; ebreak
fail_rne_cancel:  li a0, 6; ebreak
fail_of_rtz:      li a0, 7; ebreak
fail_of_rne:      li a0, 8; ebreak
  .align 2
done:
  ebreak
