/*
 * RV64 architectural smoke for minstret retirement and absent Sdtrig.
 *
 * The program is deliberately freestanding and uses only RV64IMA+Zicsr.  It
 * verifies the architectural counter value at the first handler instruction,
 * before the handler itself can retire, so a faulting instruction cannot hide
 * behind handler accounting.
 */

  .equ CAUSE_INST_ACCESS,      1
  .equ CAUSE_ILLEGAL_INST,     2
  .equ CAUSE_BREAKPOINT,       3
  .equ CAUSE_LOAD_ACCESS,      5
  .equ CAUSE_ECALL_S,          9
  .equ CAUSE_ECALL_M,         11
  .equ IRQ_MACHINE_SOFTWARE,   3
  .equ SRET_TEST_MARKER,       0x5352
  .equ MSIP_TEST_MARKER,       0x4d53

  .equ INVALID_FETCH_ADDRESS, 0x40000000
  .equ INVALID_LOAD_ADDRESS,  0x40000000
  .equ CLINT_MSIP_ADDRESS,     0x02000000

  /* CSRRS t0, <csr>, x0 encodings for the unimplemented Trigger Module. */
  .equ READ_TSELECT,           0x7a0022f3
  .equ READ_TDATA1,            0x7a1022f3
  .equ READ_TDATA2,            0x7a2022f3
  .equ READ_TCONTROL,          0x7a5022f3
  /* CSRRW x0, tselect, t0. */
  .equ WRITE_TSELECT,          0x7a029073

  .macro CHECK_ZERO_RETIRE_TRAP encoding, cause, tval, error
    li s0, -1
    li s1, -1
    li s2, -1
    csrw minstret, zero
    .word \encoding
    li a0, \error
    bnez s0, fail
    li t0, \cause
    bne s1, t0, fail
    li t0, \tval
    bne s2, t0, fail
  .endm

  .section .text, "ax", @progbits
  .globl _start
  .type _start, @function
  .option push
  .option nopic
  .option norvc
  .align 2

_start:
  la t0, trap_handler
  csrw mtvec, t0
  csrw medeleg, zero
  csrw mideleg, zero
  csrw mcountinhibit, zero

  /* A normal straight-line group must retire inside one interpreter TB. */
  csrw minstret, zero
  addi t0, zero, 1
  addi t0, t0, 1
  addi t0, t0, 1
  csrr t1, minstret
  li a0, 1
  li t2, 3
  bne t1, t2, fail

  /* Explicit minstret writes win over the automatic same-instruction update. */
  li t0, 41
  csrw minstret, t0
  csrr t1, minstret
  li a0, 2
  li t2, 41
  bne t1, t2, fail

  /* ECALL and EBREAK synchronously trap and therefore do not retire. */
  CHECK_ZERO_RETIRE_TRAP 0x00000073, CAUSE_ECALL_M, 0, 3
  CHECK_ZERO_RETIRE_TRAP 0x00100073, CAUSE_BREAKPOINT, 0, 4

  /* A data-address exception follows the same non-retirement rule. */
  li t3, INVALID_LOAD_ADDRESS
  li s0, -1
  li s1, -1
  li s2, -1
  csrw minstret, zero
  ld t4, 0(t3)
  li a0, 5
  bnez s0, fail
  li t0, CAUSE_LOAD_ACCESS
  bne s1, t0, fail
  bne s2, t3, fail

  /* No Trigger Module is implemented: every former no-op CSR is illegal. */
  CHECK_ZERO_RETIRE_TRAP READ_TSELECT,  CAUSE_ILLEGAL_INST, READ_TSELECT,  6
  CHECK_ZERO_RETIRE_TRAP WRITE_TSELECT, CAUSE_ILLEGAL_INST, WRITE_TSELECT, 7
  CHECK_ZERO_RETIRE_TRAP READ_TDATA1,   CAUSE_ILLEGAL_INST, READ_TDATA1,   8
  CHECK_ZERO_RETIRE_TRAP READ_TDATA2,   CAUSE_ILLEGAL_INST, READ_TDATA2,   9
  CHECK_ZERO_RETIRE_TRAP READ_TCONTROL, CAUSE_ILLEGAL_INST, READ_TCONTROL, 10

  /* A legal MRET retires in its originating privilege mode. */
  csrr t0, mstatus
  li t1, 0x1800
  or t0, t0, t1
  csrw mstatus, t0
  la t0, mret_return
  csrw mepc, t0
  csrw minstret, zero
  mret
mret_return:
  csrr t0, minstret
  li a0, 11
  li t1, 1
  bne t0, t1, fail

  /* WFI is legal in M-mode and retires even when it returns immediately. */
  csrw minstret, zero
  wfi
  csrr t0, minstret
  li a0, 12
  li t1, 1
  bne t0, t1, fail

  /*
   * SRET must retire as well.  It enters S-mode at sret_ecall, whose ECALL
   * immediately traps without retiring.  The handler's first instruction
   * therefore observes exactly the one SRET retirement, then restores M-mode.
   */
  li s3, SRET_TEST_MARKER
  csrr t0, mstatus
  ori t0, t0, 0x100
  csrw mstatus, t0
  la t0, sret_ecall
  csrw sepc, t0
  csrw minstret, zero
  sret
sret_ecall:
  ecall
  j fail
sret_return:
  li a0, 13
  li t0, 1
  bne s0, t0, fail
  li t0, CAUSE_ECALL_S
  bne s1, t0, fail
  bnez s2, fail
  li s3, 0

  /*
   * MRET retires before redirecting to an invalid fetch address; the failed
   * fetch itself must not add another instret tick.  The handler redirects to
   * ifetch_return instead of advancing the invalid xEPC.
   */
  csrr t0, mstatus
  li t1, 0x1800
  or t0, t0, t1
  csrw mstatus, t0
  la s4, ifetch_return
  li t0, INVALID_FETCH_ADDRESS
  csrw mepc, t0
  csrw minstret, zero
  mret
ifetch_return:
  li a0, 14
  li t0, 1
  bne s0, t0, fail
  li t0, CAUSE_INST_ACCESS
  bne s1, t0, fail
  li t0, INVALID_FETCH_ADDRESS
  bne s2, t0, fail

  /*
   * Exercise an asynchronous interrupt at a deterministic instruction
   * boundary.  CLINT MSIP is made pending while global M-mode interrupts are
   * disabled.  The final csrs mstatus instruction retires, then the pending
   * interrupt must be taken before msip_return executes.
   *
   * trap_handler reads minstret in its first two instructions.  The first
   * value must contain only the interrupted-side instruction; the second must
   * additionally contain exactly the first handler instruction.  This checks
   * both sides of the asynchronous trap boundary without depending on host
   * timer scheduling.
   */
  csrci mstatus, 8
  li t0, 8
  csrc mie, t0
  li t1, CLINT_MSIP_ADDRESS
  li t2, 1
  sw t2, 0(t1)
  csrs mie, t0
  li s5, MSIP_TEST_MARKER
  li a0, 15
  csrw minstret, zero
  csrs mstatus, t0
msip_return:
  li t0, 1
  bne s0, t0, fail
  li t0, 2
  bne s7, t0, fail
  li t0, 1
  slli t0, t0, 63
  ori t0, t0, IRQ_MACHINE_SOFTWARE
  bne s1, t0, fail
  bnez s2, fail
  la t0, msip_return
  bne s6, t0, fail
  li s5, 0

pass:
  la t0, tohost
  li t1, 1
  sd t1, 0(t0)
  j pass

fail:
  la t0, tohost
  slli t1, a0, 1
  ori t1, t1, 1
  sd t1, 0(t0)
  j fail

trap_handler:
  /* This must stay first: it observes retirement before any handler code. */
  csrr s0, minstret
  /* The second sample proves that the first handler instruction retired. */
  csrr s7, minstret
  csrr s1, mcause
  csrr s2, mtval
  bltz s1, interrupt_trap
  li t0, CAUSE_INST_ACCESS
  beq s1, t0, ifetch_trap
  li t0, CAUSE_ECALL_S
  bne s1, t0, ordinary_trap
  li t0, SRET_TEST_MARKER
  bne s3, t0, ordinary_trap
  la t0, sret_return
  csrw mepc, t0
  csrr t0, mstatus
  li t1, 0x1800
  or t0, t0, t1
  csrw mstatus, t0
  mret

ordinary_trap:
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0
  mret

ifetch_trap:
  csrw mepc, s4
  mret

interrupt_trap:
  li t0, 1
  slli t0, t0, 63
  ori t0, t0, IRQ_MACHINE_SOFTWARE
  bne s1, t0, fail
  li t0, MSIP_TEST_MARKER
  bne s5, t0, fail
  csrr s6, mepc
  li t0, CLINT_MSIP_ADDRESS
  sw zero, 0(t0)
  mret

  .option pop
  .size _start, .-_start

  .section .tohost, "aw", @progbits
  .balign 8
  .globl tohost
tohost:
  .dword 0
