// Independent UART RX -> PLIC -> machine interrupt path with full DiffTest.
.option norvc
.section .text
.globl _start
_start:
  la t0, handler
  csrw mtvec, t0
  li s0, 0
  li s1, 0x10000000
  li s2, 0x0c200004
  li t0, 0x0c000004
  li t1, 1
  sw t1, 0(t0)
  li t0, 0x0c002000
  li t1, 2
  sw t1, 0(t0)
  li t0, 0x0c200000
  sw zero, 0(t0)
  li t0, 1
  sb t0, 1(s1)
  li t0, 0x800
  csrw mie, t0
  csrsi mstatus, 8
  li t0, 63
  sb t0, 0(s1)
wait_rx:
  wfi
  beqz s0, wait_rx
  li t0, 1
  bne s0, t0, fail
  li t0, 0x00100000
  li t1, 0x5555
  sw t1, 0(t0)
hang:
  j hang
.balign 4
handler:
  csrr t0, mcause
  li t1, 0x800000000000000b
  bne t0, t1, fail
  lw t0, 0(s2)
  li t1, 1
  bne t0, t1, fail
  lbu t0, 2(s1)
  li t1, 4
  bne t0, t1, fail
  lbu t0, 0(s1)
  li t1, 90
  bne t0, t1, fail
  lbu t0, 5(s1)
  li t1, 0x60
  bne t0, t1, fail
  li t0, 1
  sw t0, 0(s2)
  addi s0, s0, 1
  mret
fail:
  li t0, 0x00100000
  li t1, 0x3333
  sw t1, 0(t0)
  j hang
