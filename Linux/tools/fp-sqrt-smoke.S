// RV64F/D focused smoke: cover FSQRT.{S,D} finite, zero, inf, and NaN paths.
// This closes the square-root arithmetic frontier gate; full fflags remain open.

#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87ef4000
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
  // system-mode NEMU 按 mstatus.FS 判定 FP 指令可用性；裸机 smoke 需自行打开 FS。
  li t0, (3 << 13)
  csrs mstatus, t0

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
#if FP_SMOKE_NEMU_SYSCON_EXIT
  // NEMU system-mode smoke 用 syscon poweroff 作为 GOOD TRAP；NPC smoke 保留 ebreak。
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
