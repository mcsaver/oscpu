// Focused RAS privilege-boundary smoke.
// A user-mode call leaves a user return address on the RAS, then ECALL traps
// to S-mode.  The S handler executes a normal ret with ra pointing to an
// S-mode label; direct RAS must not redirect that ret to the stale user target.

#ifndef RAS_TRAP_STACK
#define RAS_TRAP_STACK 0x87ef5000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, RAS_TRAP_STACK

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
  jal ra, u_ecall
u_stale_return:
  li a0, 1
  ebreak

u_ecall:
  ecall
  li a0, 2
  ebreak

s_handler:
  la ra, s_ret_ok
  ret

s_ret_ok:
  li a0, 0
  ebreak

  .option pop
