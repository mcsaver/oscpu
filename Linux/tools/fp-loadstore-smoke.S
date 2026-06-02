// Minimal RV64F/D smoke for the serialized FPR load/store bring-up path.
// It intentionally covers fflags/frm/fcsr plus FLD/FSD/FLW/FSW and lets the
// assembler emit compressed C.FLDSP/C.FSDSP in the stack case.

#ifndef FP_SMOKE_STACK
#define FP_SMOKE_STACK 0x87efc000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option rvc
  .align 2
_start:
  li sp, FP_SMOKE_STACK

  li t0, 0x12
  csrw fflags, t0
  csrr t1, fflags
  bne t0, t1, fail_fflags

  li t0, 0x2
  csrw frm, t0
  csrr t1, frm
  bne t0, t1, fail_frm

  li t0, 0xa5
  csrw fcsr, t0
  csrr t1, fcsr
  bne t0, t1, fail_fcsr

  la t0, fp_data
  fld ft0, 0(t0)
  fsd ft0, 8(t0)
  ld t1, 8(t0)
  ld t2, 0(t0)
  bne t1, t2, fail_fld

  flw ft1, 16(t0)
  fsw ft1, 20(t0)
  lwu t1, 20(t0)
  lwu t2, 16(t0)
  bne t1, t2, fail_flw

  addi sp, sp, -32
  sd t2, 0(sp)
  fld ft2, 0(sp)
  fsd ft2, 8(sp)
  ld t1, 8(sp)
  bne t1, t2, fail_cfldsp

  li a0, 0
  ebreak

fail_fflags:
  li a0, 1
  ebreak
fail_frm:
  li a0, 2
  ebreak
fail_fcsr:
  li a0, 3
  ebreak
fail_fld:
  li a0, 4
  ebreak
fail_flw:
  li a0, 5
  ebreak
fail_cfldsp:
  li a0, 6
  ebreak

  .align 3
fp_data:
  .dword 0x1122334455667788
  .dword 0
  .word 0x7fc12345
  .word 0
  .option pop
