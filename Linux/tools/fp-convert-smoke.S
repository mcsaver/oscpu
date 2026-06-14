// RV64D focused smoke：只覆盖 Ubuntu lp64d 前沿里的 FCVT.D.* 与
// FCVT.*.D，不把它误记成完整 FP 算术或 fflags 支持。

#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87efa000
#endif

#ifndef FP_SMOKE_NEMU_SYSCON_EXIT
#define FP_SMOKE_NEMU_SYSCON_EXIT 0
#endif

#ifndef SYSCON_RESET_MMIO
#define SYSCON_RESET_MMIO 0x00100000
#endif

#ifndef SYSCON_POWEROFF_VALUE
#define SYSCON_POWEROFF_VALUE 0x5555
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

  li t0, 1
  fcvt.d.w ft0, t0
  fmv.x.d t1, ft0
  li t2, 0x3ff0000000000000
  bne t1, t2, fail_d_w_pos

  li t0, -2
  fcvt.d.w ft1, t0
  fmv.x.d t1, ft1
  li t2, 0xc000000000000000
  bne t1, t2, fail_d_w_neg

  li t0, 0x80000000
  fcvt.d.wu ft2, t0
  fmv.x.d t1, ft2
  li t2, 0x41e0000000000000
  bne t1, t2, fail_d_wu

  li t0, 0x100000000
  fcvt.d.l ft3, t0
  fmv.x.d t1, ft3
  li t2, 0x41f0000000000000
  bne t1, t2, fail_d_l

  li t0, 0x4045000000000000
  fmv.d.x ft4, t0
  fcvt.w.d t1, ft4, rtz
  li t2, 42
  bne t1, t2, fail_w_d_pos

  li t0, 0xc031000000000000
  fmv.d.x ft5, t0
  fcvt.w.d t1, ft5, rtz
  li t2, -17
  bne t1, t2, fail_w_d_neg

  li t0, 0x3ff8000000000000
  fmv.d.x ft6, t0
  fcvt.w.d t1, ft6, rtz
  li t2, 1
  bne t1, t2, fail_w_d_rtz

  li t0, 0x41f0000000000000
  fmv.d.x ft7, t0
  fcvt.l.d t1, ft7, rtz
  li t2, 0x100000000
  bne t1, t2, fail_l_d

  li t0, 0x41e0000000000000
  fmv.d.x ft8, t0
  fcvt.wu.d t1, ft8, rtz
  li t2, 0x80000000
  bne t1, t2, fail_wu_d

  li a0, 0
  j done

fail_d_w_pos:
  li a0, 1
  j done
fail_d_w_neg:
  li a0, 2
  j done
fail_d_wu:
  li a0, 3
  j done
fail_d_l:
  li a0, 4
  j done
fail_w_d_pos:
  li a0, 5
  j done
fail_w_d_neg:
  li a0, 6
  j done
fail_w_d_rtz:
  li a0, 7
  j done
fail_l_d:
  li a0, 8
  j done
fail_wu_d:
  li a0, 9
  j done

  .align 2
done:
#if FP_SMOKE_NEMU_SYSCON_EXIT
  beqz a0, nemu_pass
  li t0, 0x10000000
  li t1, 0x46
  sb t1, 0(t0)
nemu_fail_spin:
  j nemu_fail_spin
nemu_pass:
  li t0, SYSCON_RESET_MMIO
  li t1, SYSCON_POWEROFF_VALUE
  sw t1, 0(t0)
nemu_pass_spin:
  j nemu_pass_spin
#else
  ebreak
#endif

  .option pop
