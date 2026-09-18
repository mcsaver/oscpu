// Reuse the existing sector/vring/hot-cache workload and add the missing
// hardware observation: IRQ2 must traverse PLIC, trap entry and claim/complete.
.option norvc
.section .text
.globl _start
_start:
  la t0, block_irq_handler
  csrw mtvec, t0
  li t0, 0x80028000
  csrw mscratch, t0
  li s2, 0
  li t0, 0x0c000008
  li t1, 1
  sw t1, 0(t0)
  li t0, 0x0c002000
  li t1, 4
  sw t1, 0(t0)
  li t0, 0x0c200000
  sw zero, 0(t0)
  li t0, 0x800
  csrw mie, t0
  csrsi mstatus, 8
  j block_irq_body

block_irq_handler:
  csrrw sp, mscratch, sp
  sd t0, 0(sp)
  sd t1, 8(sp)
  sd t2, 16(sp)
  csrr t0, mcause
  li t1, 0x800000000000000b
  bne t0, t1, block_irq_fail
  li t0, 0x0c200004
  lwu t1, 0(t0)
  li t2, 2
  bne t1, t2, block_irq_fail
  addi s2, s2, 1
  // The included driver checks/ACKs the device's pending bit. Mask MEIE
  // until then, while still completing this claimed interrupt at the PLIC.
  csrw mie, zero
  sw t1, 0(t0)
  ld t0, 0(sp)
  ld t1, 8(sp)
  ld t2, 16(sp)
  csrrw sp, mscratch, sp
  mret

block_irq_fail:
  li a0, 100
  ebreak
block_irq_exit:
  bnez a0, block_irq_done
  li t0, 1
  bne s2, t0, block_irq_fail
block_irq_done:
  ebreak

#define _start block_irq_body
#define ebreak j block_irq_exit
#include "../../../../Linux/tools/virtio-blk-smoke.S"
#undef ebreak
#undef _start
