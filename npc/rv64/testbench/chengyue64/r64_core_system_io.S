// Multi-image loading, real UART input, system EBREAK and precise poweroff.
// The host loads an eight-byte 0x1122334455667788 sentinel at 0x81000000.
.option norvc
.section .text
.globl _start
_start:
  la t0, trap_handler
  csrw mtvec, t0
  li s0, 0
  ebreak
  li t0, 1
  bne s0, t0, fail
  li t0, 0x81000000
  ld t1, 0(t0)
  li t2, 0x1122334455667788
  bne t1, t2, fail
  li s1, 0x10000000
  li t0, 63
  sb t0, 0(s1)
poll:
  lbu t0, 5(s1)
  andi t0, t0, 1
  beqz t0, poll
  lbu t0, 0(s1)
  li t1, 90
  bne t0, t1, fail
  li t0, 0x00100000
  li t1, 0x5555
  sw t1, 0(t0)
hang:
  j hang
fail:
  li t0, 0x00100000
  li t1, 0x13333
  sw t1, 0(t0)
  j hang
.balign 4
trap_handler:
  csrr t0, mcause
  li t1, 3
  bne t0, t1, fail
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0
  addi s0, s0, 1
  mret
