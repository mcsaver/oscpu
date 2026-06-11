// NEMU RV64 PMP smoke：S-mode 被 PMP 拒绝时必须产生 access fault。
#ifndef PMP_ACCESS_STACK
#define PMP_ACCESS_STACK 0x87eec000
#endif

#ifndef PMP_DENY_ADDR
#define PMP_DENY_ADDR 0x80010000
#endif

#ifndef SYSCON_RESET_MMIO
#define SYSCON_RESET_MMIO 0x100000
#endif

#ifndef SYSCON_POWEROFF_VALUE
#define SYSCON_POWEROFF_VALUE 0x5555
#endif

#define PMP_DENY_SIZE 0x1000
#define PMP_ALLOW_BASE 0x80000000
#define PMP_ALLOW_SIZE 0x20000
#define PMP_NAPOT_ADDR(base, size) (((base) >> 2) | (((size) - 1) >> 3))
#define PMP_CFG_NAPOT 0x18
#define PMP_CFG_RWX_NAPOT 0x1f
#define CAUSE_INST_ACCESS 1
#define CAUSE_LOAD_ACCESS 5
#define CAUSE_STORE_ACCESS 7

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2

_start:
  li sp, PMP_ACCESS_STACK
  la t0, trap_handler
  csrw mtvec, t0
  csrw medeleg, zero
  li s2, 1

  li t0, PMP_NAPOT_ADDR(PMP_DENY_ADDR, PMP_DENY_SIZE)
  csrw pmpaddr0, t0
  li t0, PMP_NAPOT_ADDR(PMP_ALLOW_BASE, PMP_ALLOW_SIZE)
  csrw pmpaddr1, t0
  li t0, (PMP_CFG_NAPOT | (PMP_CFG_RWX_NAPOT << 8))
  csrw pmpcfg0, t0
  fence.i

  li s0, CAUSE_LOAD_ACCESS
  li s1, PMP_DENY_ADDR
  la a0, smode_load_test
  j enter_smode

enter_smode:
  csrr t0, mstatus
  li t1, 0x1800
  not t1, t1
  and t0, t0, t1
  li t1, 0x800
  or t0, t0, t1
  csrw mstatus, t0
  csrw mepc, a0
  mret

smode_load_test:
  li t0, PMP_DENY_ADDR
  ld t1, 0(t0)
  j fail

smode_store_test:
  li t0, PMP_DENY_ADDR
  sd zero, 0(t0)
  j fail

trap_handler:
  csrr t0, mcause
  bne t0, s0, fail
  csrr t0, mtval
  bne t0, s1, fail

  li t0, 1
  beq s2, t0, next_store_fault
  li t0, 2
  beq s2, t0, next_ifetch_fault
  li t0, 3
  beq s2, t0, pass
  j fail

next_store_fault:
  li s2, 2
  li s0, CAUSE_STORE_ACCESS
  li s1, PMP_DENY_ADDR
  la a0, smode_store_test
  j enter_smode

next_ifetch_fault:
  li s2, 3
  li s0, CAUSE_INST_ACCESS
  li s1, PMP_DENY_ADDR
  li a0, PMP_DENY_ADDR
  j enter_smode

pass:
  li t0, SYSCON_RESET_MMIO
  li t1, SYSCON_POWEROFF_VALUE
  sw t1, 0(t0)

pass_spin:
  j pass_spin

fail:
  li t0, 0x10000000
  li t1, 0x46
  sb t1, 0(t0)

fail_spin:
  j fail_spin

  .option pop
