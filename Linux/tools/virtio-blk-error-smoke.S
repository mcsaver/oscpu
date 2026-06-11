// NEMU virtio-mmio block error-path smoke.
// Exercises collectable bad requests plus uncollectable descriptor chains.

#ifndef VIRTIO_BLK_STACK
#define VIRTIO_BLK_STACK 0x87ef2000
#endif

#ifndef VIRTIO_DESC_ADDR
#define VIRTIO_DESC_ADDR 0x80010000
#endif
#ifndef VIRTIO_AVAIL_ADDR
#define VIRTIO_AVAIL_ADDR 0x80011000
#endif
#ifndef VIRTIO_USED_ADDR
#define VIRTIO_USED_ADDR 0x80012000
#endif
#ifndef VIRTIO_REQ_ADDR
#define VIRTIO_REQ_ADDR 0x80013000
#endif
#ifndef VIRTIO_DATA_ADDR
#define VIRTIO_DATA_ADDR 0x80014000
#endif
#ifndef VIRTIO_STATUS_ADDR
#define VIRTIO_STATUS_ADDR 0x80015000
#endif
#ifndef VIRTIO_INDIRECT_ADDR
#define VIRTIO_INDIRECT_ADDR 0x80016000
#endif

#ifndef SYSCON_RESET_MMIO
#define SYSCON_RESET_MMIO 0x100000
#endif
#ifndef SYSCON_POWEROFF_VALUE
#define SYSCON_POWEROFF_VALUE 0x5555
#endif

#define VIRTIO_BASE              0x10001000
#define UART_BASE                0x10000000
#define VIRTIO_MAGIC             0x74726976
#define VIRTIO_MMIO_VERSION      2
#define VIRTIO_DEVICE_ID_BLOCK   2
#define VIRTIO_STATUS_ACK        1
#define VIRTIO_STATUS_DRIVER     2
#define VIRTIO_STATUS_DRIVER_OK  4
#define VIRTIO_STATUS_FEATURES_OK 8
#define VIRTQ_DESC_F_NEXT        1
#define VIRTQ_DESC_F_WRITE       2
#define VIRTQ_DESC_F_INDIRECT    4
#define VIRTIO_RING_F_INDIRECT_DESC_MASK 0x10000000
#define VIRTIO_BLK_T_IN          0
#define VIRTIO_BLK_S_OK          0
#define VIRTIO_BLK_S_IOERR       1
#define VIRTIO_BLK_S_UNSUPP      2
#define VIRTIO_BLK_T_UNSUPPORTED 0x7fffffff
#define VIRTIO_INVALID_DATA_ADDR 0xfffffffffffff000

#define REG_MAGIC_VALUE          0x000
#define REG_VERSION              0x004
#define REG_DEVICE_ID            0x008
#define REG_DEVICE_FEATURES      0x010
#define REG_DEVICE_FEATURES_SEL  0x014
#define REG_DRIVER_FEATURES      0x020
#define REG_DRIVER_FEATURES_SEL  0x024
#define REG_QUEUE_SEL            0x030
#define REG_QUEUE_NUM_MAX        0x034
#define REG_QUEUE_NUM            0x038
#define REG_QUEUE_READY          0x044
#define REG_QUEUE_NOTIFY         0x050
#define REG_INTERRUPT_STATUS     0x060
#define REG_INTERRUPT_ACK        0x064
#define REG_STATUS               0x070
#define REG_QUEUE_DESC_LOW       0x080
#define REG_QUEUE_DESC_HIGH      0x084
#define REG_QUEUE_DRIVER_LOW     0x090
#define REG_QUEUE_DRIVER_HIGH    0x094
#define REG_QUEUE_DEVICE_LOW     0x0a0
#define REG_QUEUE_DEVICE_HIGH    0x0a4
#define REG_CONFIG               0x100

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, VIRTIO_BLK_STACK
  la t0, unexpected_trap
  csrw mtvec, t0
  csrw stvec, t0
  csrw mie, zero
  li t0, 0x8
  csrc mstatus, t0
  li s0, VIRTIO_BASE
  li s1, 0                  // expected used.idx
  li s2, 0                  // disk capacity in 512B sectors
  li s3, 0                  // next avail.idx

  lwu t0, REG_MAGIC_VALUE(s0)
  li t1, VIRTIO_MAGIC
  bne t0, t1, fail_magic
  lwu t0, REG_VERSION(s0)
  li t1, VIRTIO_MMIO_VERSION
  bne t0, t1, fail_version
  lwu t0, REG_DEVICE_ID(s0)
  li t1, VIRTIO_DEVICE_ID_BLOCK
  bne t0, t1, fail_device

  lwu t0, REG_CONFIG(s0)
  lwu t1, REG_CONFIG + 4(s0)
  slli t1, t1, 32
  or s2, t0, t1
  beqz s2, fail_capacity

  sw zero, REG_STATUS(s0)
  li t0, VIRTIO_STATUS_ACK | VIRTIO_STATUS_DRIVER
  sw t0, REG_STATUS(s0)

  li t0, 1
  sw t0, REG_DEVICE_FEATURES_SEL(s0)
  lwu t1, REG_DEVICE_FEATURES(s0)
  andi t1, t1, 1
  beqz t1, fail_features

  sw t0, REG_DRIVER_FEATURES_SEL(s0)
  sw t0, REG_DRIVER_FEATURES(s0)

  sw zero, REG_DEVICE_FEATURES_SEL(s0)
  lwu t1, REG_DEVICE_FEATURES(s0)
  li t2, VIRTIO_RING_F_INDIRECT_DESC_MASK
  and t1, t1, t2
  beqz t1, fail_features
  sw zero, REG_DRIVER_FEATURES_SEL(s0)
  sw t2, REG_DRIVER_FEATURES(s0)

  li t0, VIRTIO_STATUS_ACK | VIRTIO_STATUS_DRIVER | VIRTIO_STATUS_FEATURES_OK
  sw t0, REG_STATUS(s0)
  lwu t1, REG_STATUS(s0)
  andi t1, t1, VIRTIO_STATUS_FEATURES_OK
  beqz t1, fail_features_ok

  li t0, VIRTIO_DESC_ADDR
  li t1, VIRTIO_STATUS_ADDR + 8
clear_initial_loop:
  sd zero, 0(t0)
  addi t0, t0, 8
  bltu t0, t1, clear_initial_loop

  sw zero, REG_QUEUE_SEL(s0)
  lwu t0, REG_QUEUE_NUM_MAX(s0)
  li t1, 8
  bltu t0, t1, fail_queue_max
  sw t1, REG_QUEUE_NUM(s0)

  li t0, VIRTIO_DESC_ADDR
  sw t0, REG_QUEUE_DESC_LOW(s0)
  sw zero, REG_QUEUE_DESC_HIGH(s0)
  li t0, VIRTIO_AVAIL_ADDR
  sw t0, REG_QUEUE_DRIVER_LOW(s0)
  sw zero, REG_QUEUE_DRIVER_HIGH(s0)
  li t0, VIRTIO_USED_ADDR
  sw t0, REG_QUEUE_DEVICE_LOW(s0)
  sw zero, REG_QUEUE_DEVICE_HIGH(s0)

  li t0, 1
  sw t0, REG_QUEUE_READY(s0)
  li t0, VIRTIO_STATUS_ACK | VIRTIO_STATUS_DRIVER | VIRTIO_STATUS_FEATURES_OK | VIRTIO_STATUS_DRIVER_OK
  sw t0, REG_STATUS(s0)

  call setup_bad_read_direction
  li a0, VIRTIO_BLK_S_IOERR
  call submit_expect_status

  call setup_bad_dma_range
  li a0, VIRTIO_BLK_S_IOERR
  call submit_expect_status

  call setup_beyond_capacity
  li a0, VIRTIO_BLK_S_IOERR
  call submit_expect_status

  call setup_unsupported_request
  li a0, VIRTIO_BLK_S_UNSUPP
  call submit_expect_status

  call setup_cycle_chain
  call submit_expect_malformed_completion

  call setup_nested_indirect
  call submit_expect_malformed_completion

  j pass

clear_request_area:
  li t0, VIRTIO_DESC_ADDR
  li t1, VIRTIO_DESC_ADDR + 64
clear_desc_loop:
  sd zero, 0(t0)
  addi t0, t0, 8
  bltu t0, t1, clear_desc_loop

  li t0, VIRTIO_REQ_ADDR
  li t1, VIRTIO_REQ_ADDR + 24
clear_req_loop:
  sd zero, 0(t0)
  addi t0, t0, 8
  bltu t0, t1, clear_req_loop

  li t0, VIRTIO_DATA_ADDR
  li t1, VIRTIO_DATA_ADDR + 64
clear_data_loop:
  sd zero, 0(t0)
  addi t0, t0, 8
  bltu t0, t1, clear_data_loop

  li t0, VIRTIO_STATUS_ADDR
  li t1, 0xff
  sb t1, 0(t0)

  li t0, VIRTIO_INDIRECT_ADDR
  li t1, VIRTIO_INDIRECT_ADDR + 64
clear_indirect_loop:
  sd zero, 0(t0)
  addi t0, t0, 8
  bltu t0, t1, clear_indirect_loop
  ret

setup_common_read_request:
  li t0, VIRTIO_DESC_ADDR
  li t1, VIRTIO_REQ_ADDR
  sd t1, 0(t0)
  li t1, 16
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_DESC_ADDR + 32
  li t1, VIRTIO_STATUS_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_REQ_ADDR
  li t1, VIRTIO_BLK_T_IN
  sw t1, 0(t0)
  sw zero, 4(t0)
  sd zero, 8(t0)
  ret

setup_bad_read_direction:
  addi sp, sp, -16
  sd ra, 8(sp)
  call clear_request_area
  call setup_common_read_request
  li t0, VIRTIO_DESC_ADDR + 16
  li t1, VIRTIO_DATA_ADDR
  sd t1, 0(t0)
  li t1, 512
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT          // malformed: IN data buffer must be writable
  sh t1, 12(t0)
  li t1, 2
  sh t1, 14(t0)
  ld ra, 8(sp)
  addi sp, sp, 16
  ret

setup_bad_dma_range:
  addi sp, sp, -16
  sd ra, 8(sp)
  call clear_request_area
  call setup_common_read_request
  li t0, VIRTIO_DESC_ADDR + 16
  li t1, VIRTIO_INVALID_DATA_ADDR   // malformed: collectable descriptor, invalid guest DMA range
  sd t1, 0(t0)
  li t1, 512
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT | VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  li t1, 2
  sh t1, 14(t0)
  ld ra, 8(sp)
  addi sp, sp, 16
  ret

setup_beyond_capacity:
  addi sp, sp, -16
  sd ra, 8(sp)
  call clear_request_area
  call setup_common_read_request
  li t0, VIRTIO_DESC_ADDR + 16
  li t1, VIRTIO_DATA_ADDR
  sd t1, 0(t0)
  li t1, 512
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT | VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  li t1, 2
  sh t1, 14(t0)
  li t0, VIRTIO_REQ_ADDR
  sd s2, 8(t0)                     // one sector past the last valid sector
  ld ra, 8(sp)
  addi sp, sp, 16
  ret

setup_unsupported_request:
  addi sp, sp, -16
  sd ra, 8(sp)
  call clear_request_area
  li t0, VIRTIO_DESC_ADDR
  li t1, VIRTIO_REQ_ADDR
  sd t1, 0(t0)
  li t1, 16
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_DESC_ADDR + 16
  li t1, VIRTIO_STATUS_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_REQ_ADDR
  li t1, VIRTIO_BLK_T_UNSUPPORTED
  sw t1, 0(t0)
  sw zero, 4(t0)
  sd zero, 8(t0)
  ld ra, 8(sp)
  addi sp, sp, 16
  ret

setup_cycle_chain:
  addi sp, sp, -16
  sd ra, 8(sp)
  call clear_request_area
  li t0, VIRTIO_DESC_ADDR
  li t1, VIRTIO_REQ_ADDR
  sd t1, 0(t0)
  li t1, 16
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_DESC_ADDR + 16
  li t1, VIRTIO_DATA_ADDR
  sd t1, 0(t0)
  li t1, 512
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT | VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)                  // malformed: desc1.next loops back to desc0

  li t0, VIRTIO_REQ_ADDR
  li t1, VIRTIO_BLK_T_IN
  sw t1, 0(t0)
  sw zero, 4(t0)
  sd zero, 8(t0)
  ld ra, 8(sp)
  addi sp, sp, 16
  ret

setup_nested_indirect:
  addi sp, sp, -16
  sd ra, 8(sp)
  call clear_request_area
  li t0, VIRTIO_DESC_ADDR
  li t1, VIRTIO_INDIRECT_ADDR
  sd t1, 0(t0)
  li t1, 16
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_INDIRECT
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_INDIRECT_ADDR
  li t1, VIRTIO_REQ_ADDR
  sd t1, 0(t0)
  li t1, 16
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_INDIRECT     // malformed: indirect table cannot nest indirect descriptors
  sh t1, 12(t0)
  sh zero, 14(t0)
  ld ra, 8(sp)
  addi sp, sp, 16
  ret

submit_expect_status:
  mv s4, a0
  li t0, VIRTIO_AVAIL_ADDR
  sh zero, 0(t0)
  andi t1, s3, 7
  slli t1, t1, 1
  addi t1, t1, 4
  add t1, t0, t1
  sh zero, 0(t1)
  addi s3, s3, 1
  sh s3, 2(t0)
  fence rw, rw
  sw zero, REG_QUEUE_NOTIFY(s0)
  fence rw, rw

  li t3, 2000000
poll_status:
  li t0, VIRTIO_STATUS_ADDR
  lbu t1, 0(t0)
  li t2, 0xff
  bne t1, t2, check_status
  addi t3, t3, -1
  bnez t3, poll_status
  j fail_timeout

check_status:
  bne t1, s4, fail_status

  li t0, VIRTIO_USED_ADDR
  lhu t1, 2(t0)
  bne t1, s3, fail_used_idx
  addi t2, s3, -1
  andi t2, t2, 7
  slli t2, t2, 3
  add t0, t0, t2
  lwu t1, 4(t0)
  bnez t1, fail_used_id
  lwu t1, 8(t0)
  li t2, 1
  bne t1, t2, fail_used_len

  lwu t1, REG_INTERRUPT_STATUS(s0)
  andi t1, t1, 1
  beqz t1, fail_irq
  li t1, 1
  sw t1, REG_INTERRUPT_ACK(s0)
  lwu t1, REG_INTERRUPT_STATUS(s0)
  andi t1, t1, 1
  bnez t1, fail_irq_ack
  ret

submit_expect_malformed_completion:
  li t0, VIRTIO_AVAIL_ADDR
  sh zero, 0(t0)
  andi t1, s3, 7
  slli t1, t1, 1
  addi t1, t1, 4
  add t1, t0, t1
  sh zero, 0(t1)
  addi s3, s3, 1
  sh s3, 2(t0)
  fence rw, rw
  sw zero, REG_QUEUE_NOTIFY(s0)
  fence rw, rw

  li t3, 2000000
poll_malformed_used:
  li t0, VIRTIO_USED_ADDR
  lhu t1, 2(t0)
  beq t1, s3, check_malformed_completion
  addi t3, t3, -1
  bnez t3, poll_malformed_used
  j fail_timeout

check_malformed_completion:
  li t0, VIRTIO_STATUS_ADDR
  lbu t1, 0(t0)
  li t2, 0xff
  bne t1, t2, fail_status_touched

  li t0, VIRTIO_USED_ADDR
  addi t2, s3, -1
  andi t2, t2, 7
  slli t2, t2, 3
  add t0, t0, t2
  lwu t1, 4(t0)
  bnez t1, fail_used_id
  lwu t1, 8(t0)
  bnez t1, fail_used_len

  lwu t1, REG_INTERRUPT_STATUS(s0)
  andi t1, t1, 1
  beqz t1, fail_irq
  li t1, 1
  sw t1, REG_INTERRUPT_ACK(s0)
  lwu t1, REG_INTERRUPT_STATUS(s0)
  andi t1, t1, 1
  bnez t1, fail_irq_ack
  ret

fail_magic:
  li a0, 1
  j fail
fail_version:
  li a0, 2
  j fail
fail_device:
  li a0, 3
  j fail
fail_capacity:
  li a0, 4
  j fail
fail_features:
  li a0, 5
  j fail
fail_features_ok:
  li a0, 6
  j fail
fail_queue_max:
  li a0, 7
  j fail
fail_timeout:
  li a0, 8
  j fail
fail_status:
  li a0, 9
  j fail
fail_used_idx:
  li a0, 10
  j fail
fail_used_id:
  li a0, 11
  j fail
fail_used_len:
  li a0, 12
  j fail
fail_irq:
  li a0, 13
  j fail
fail_irq_ack:
  li a0, 14
  j fail
fail_status_touched:
  li a0, 15
  j fail

unexpected_trap:
  csrr t0, mcause
  srli t1, t0, 63
  bnez t1, unexpected_interrupt
  li a0, 16
  j fail

unexpected_interrupt:
  csrw mie, zero
  li t0, 0x8
  csrc mstatus, t0
  mret

pass:
  li t0, SYSCON_RESET_MMIO
  li t1, SYSCON_POWEROFF_VALUE
  sw t1, 0(t0)

pass_spin:
  j pass_spin

fail:
  li t0, UART_BASE
  li t1, 0x46
  sb t1, 0(t0)
  srli t2, a0, 4
  andi t2, t2, 0xf
  li t3, 10
  bltu t2, t3, fail_high_digit
  addi t2, t2, 55
  j fail_emit_high

fail_high_digit:
  addi t2, t2, 48

fail_emit_high:
  sb t2, 0(t0)
  andi t2, a0, 0xf
  li t3, 10
  bltu t2, t3, fail_low_digit
  addi t2, t2, 55
  j fail_emit_low

fail_low_digit:
  addi t2, t2, 48

fail_emit_low:
  sb t2, 0(t0)

fail_spin:
  j fail_spin

  .option pop
