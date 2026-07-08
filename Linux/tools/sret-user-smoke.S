// Focused privilege smoke for SRET into U-mode.
// Linux user entry relies on sstatus.SPP=0 being honored by sret, and on the
// following U-mode trap recording SPP=0 instead of looking like a kernel fault.

#ifndef SRET_USER_STACK
#define SRET_USER_STACK 0x87ef7000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, SRET_USER_STACK

  la t0, m_handler
  csrw mtvec, t0
  la t0, s_handler
  csrw stvec, t0

  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x1f // NAPOT RWX for S/U focused smoke access.
  csrw pmpcfg0, t0

  li t0, (1 << 8)
  csrs medeleg, t0

  li t0, (1 << 11)
  csrs mstatus, t0
  la t0, s_entry
  csrw mepc, t0
  mret

m_handler:
  li a0, 10
  ebreak

s_entry:
  la t0, u_entry
  csrw sepc, t0
  li t0, 0x100
  csrc sstatus, t0
  sret

u_entry:
  ecall

s_handler:
  csrr t0, scause
  li t1, 8
  bne t0, t1, fail_scause
  csrr t0, sstatus
  andi t0, t0, 0x100
  bnez t0, fail_spp
  li a0, 0
  ebreak

fail_scause:
  li a0, 1
  ebreak

fail_spp:
  li a0, 2
  ebreak

  .option pop
