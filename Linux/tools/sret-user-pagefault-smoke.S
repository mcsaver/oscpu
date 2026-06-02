// Focused Sv39 smoke for U-mode instruction page faults after SRET.
// A missing user mapping must trap to S-mode with sstatus.SPP=0; otherwise
// Linux treats the user fault as a kernel execute-from-user fault and panics.

#ifndef SRET_USER_PF_STACK
#define SRET_USER_PF_STACK 0x87ef6000
#endif
#ifndef SRET_USER_PF_ROOT
#define SRET_USER_PF_ROOT 0x80004000
#endif
#ifndef SRET_USER_PF_VA
#define SRET_USER_PF_VA 0x0000000040000000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, SRET_USER_PF_STACK

  la t0, m_handler
  csrw mtvec, t0
  la t0, s_handler
  csrw stvec, t0

  li t0, (1 << 12)
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
  li t0, SRET_USER_PF_ROOT
  li t1, ((0x80000000 >> 12) << 10) | 0xcf
  sd t1, 16(t0)

  li t0, (8 << 60)
  li t1, SRET_USER_PF_ROOT
  srli t1, t1, 12
  or t0, t0, t1
  csrw satp, t0
  sfence.vma

  li t0, SRET_USER_PF_VA
  csrw sepc, t0
  li t0, 0x100
  csrc sstatus, t0
  sret

s_handler:
  csrr t0, scause
  li t1, 12
  bne t0, t1, fail_scause
  csrr t0, stval
  li t1, SRET_USER_PF_VA
  bne t0, t1, fail_stval
  csrr t0, sstatus
  andi t0, t0, 0x100
  bnez t0, fail_spp
  li a0, 0
  ebreak

fail_scause:
  li a0, 1
  ebreak

fail_stval:
  li a0, 2
  ebreak

fail_spp:
  li a0, 3
  ebreak

  .option pop
