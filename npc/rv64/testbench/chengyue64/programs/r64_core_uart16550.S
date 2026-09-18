// Linux 8250 register probing, FIFO/IRQ semantics through the real AXI UART.
// All reads and every retired register are checked against independent NEMU.
.option norvc
.section .text
.globl _start
.macro rd reg, value
  lbu t0, \reg(s1)
  li t1, \value
  bne t0, t1, fail
.endm
.macro wr reg, value
  li t0, \value
  sb t0, \reg(s1)
.endm
_start:
  li s1, 0x10000000
  rd 4, 0
  rd 6, 0xb0
  wr 7, 0x5a
  rd 7, 0x5a
  wr 7, 0xa5
  rd 7, 0xa5

  // Modem IRQ, status and read-to-clear deltas, including RI trailing edge.
  wr 1, 8
  wr 4, 0x1a
  rd 4, 0x1a
  rd 2, 0
  rd 6, 0x92
  rd 6, 0x90
  rd 2, 1
  wr 4, 0x1e
  rd 6, 0xd0
  wr 4, 0x1a
  rd 6, 0x94
  rd 6, 0x90
  wr 4, 0
  rd 6, 0xb2
  rd 6, 0xb0

  // Reading the neighboring IER/LCR bytes must not acknowledge THRE.
  wr 1, 2
  rd 1, 2
  rd 2, 2
  rd 2, 1
  wr 1, 2
  rd 2, 1
  wr 1, 0
  wr 1, 2
  rd 2, 2
  rd 2, 1

  // DLAB aliases leave IER and THR alone.
  wr 3, 0x80
  wr 0, 0x34
  wr 1, 0x12
  rd 0, 0x34
  rd 1, 0x12
  wr 3, 3
  rd 1, 2

  // Sixteen looped-back bytes, overflow, interrupt priority and trigger 14.
  wr 4, 0x10
  rd 6, 0x0b
  wr 1, 7
  wr 2, 0xc7
  li s2, 0
fill:
  sb s2, 0(s1)
  addi s2, s2, 1
  li t1, 16
  bne s2, t1, fill
  wr 0, 0xee
  rd 2, 0xc6
  rd 4, 0x10
  rd 2, 0xc6
  rd 5, 0xe3
  rd 5, 0x61
  rd 2, 0xc4
  rd 0, 0
  rd 0, 1
  rd 2, 0xc4
  rd 0, 2
  rd 2, 0xcc
  li s2, 3
drain:
  lbu t0, 0(s1)
  bne t0, s2, fail
  addi s2, s2, 1
  li t1, 16
  bne s2, t1, drain
  rd 5, 0x60
  rd 2, 0xc2
  rd 2, 0xc1
  rd 0, 0

  // FCR RX reset and disabling FIFO discard queued bytes.
  wr 0, 0x41
  wr 0, 0x42
  wr 2, 3
  rd 5, 0x60
  wr 0, 0x43
  wr 2, 0
  rd 5, 0x60
  wr 0, 0x44
  rd 0, 0x44
  wr 1, 0
  wr 4, 0
  li t0, 0x00100000
  li t1, 0x5555
  sw t1, 0(t0)
1: j 1b
fail:
  li t0, 0x00100000
  li t1, 0x7777
  sw t1, 0(t0)
  j 1b
