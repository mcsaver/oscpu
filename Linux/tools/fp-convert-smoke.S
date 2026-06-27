// RV64F/D focused smoke：覆盖 FCVT.{S,D}.{W,WU,L,LU}、
// FCVT.{W,WU,L,LU}.{S,D} 与 FCVT.S.D/FCVT.D.S。
// 该 gate 验证 RV64GC 转换指令覆盖；完整 fflags 仍由后续 CSR gate 补强。

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
  // RV64 的 FCVT.W/WU.* 都把 32-bit 结果 sign-extend 到 XLEN。
  li t2, 0xffffffff80000000
  bne t1, t2, fail_wu_d

  li t0, 1
  fcvt.s.w ft0, t0
  fmv.x.w t1, ft0
  li t2, 0x3f800000
  bne t1, t2, fail_s_w_pos

  li t0, -2
  fcvt.s.w ft1, t0
  fmv.x.w t1, ft1
  li t2, 0xffffffffc0000000
  bne t1, t2, fail_s_w_neg

  li t0, 0x80000000
  fcvt.s.wu ft2, t0
  fmv.x.w t1, ft2
  li t2, 0x4f000000
  bne t1, t2, fail_s_wu

  li t0, 0x100000000
  fcvt.s.l ft3, t0
  fmv.x.w t1, ft3
  li t2, 0x4f800000
  bne t1, t2, fail_s_l

  li t0, 0x42280000
  fmv.w.x ft4, t0
  fcvt.w.s t1, ft4, rtz
  li t2, 42
  bne t1, t2, fail_w_s_pos

  li t0, 0xc1880000
  fmv.w.x ft5, t0
  fcvt.w.s t1, ft5, rtz
  li t2, -17
  bne t1, t2, fail_w_s_neg

  li t0, 0x3fc00000
  fmv.w.x ft6, t0
  fcvt.w.s t1, ft6, rtz
  li t2, 1
  bne t1, t2, fail_w_s_rtz

  li t0, 0x4f000000
  fmv.w.x ft7, t0
  fcvt.wu.s t1, ft7, rtz
  // RV64 的 FCVT.W/WU.* 都把 32-bit 结果 sign-extend 到 XLEN。
  li t2, 0xffffffff80000000
  bne t1, t2, fail_wu_s

  li t0, 0x3fc00000
  fmv.w.x ft0, t0
  fcvt.d.s ft1, ft0
  fmv.x.d t1, ft1
  li t2, 0x3ff8000000000000
  bne t1, t2, fail_d_s

  li t0, 0xc004000000000000
  fmv.d.x ft2, t0
  fcvt.s.d ft3, ft2
  fmv.x.w t1, ft3
  li t2, 0xffffffffc0200000
  bne t1, t2, fail_s_d

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
fail_s_w_pos:
  li a0, 10
  j done
fail_s_w_neg:
  li a0, 11
  j done
fail_s_wu:
  li a0, 12
  j done
fail_s_l:
  li a0, 13
  j done
fail_w_s_pos:
  li a0, 14
  j done
fail_w_s_neg:
  li a0, 15
  j done
fail_w_s_rtz:
  li a0, 16
  j done
fail_wu_s:
  li a0, 17
  j done
fail_d_s:
  li a0, 18
  j done
fail_s_d:
  li a0, 19
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
