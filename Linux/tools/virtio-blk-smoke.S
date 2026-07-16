// Focused virtio-mmio block smoke for Ubuntu rootfs bring-up.
// Reads sector 2 from the attached ext4 image and checks the superblock magic.

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

#define VIRTIO_BASE              0x10001000
#define VIRTIO_MAGIC             0x74726976
#define VIRTIO_MMIO_VERSION      2
#define VIRTIO_DEVICE_ID_BLOCK   2
#define VIRTIO_STATUS_ACK        1
#define VIRTIO_STATUS_DRIVER     2
#define VIRTIO_STATUS_DRIVER_OK  4
#define VIRTIO_STATUS_FEATURES_OK 8
#define VIRTQ_DESC_F_NEXT        1
#define VIRTQ_DESC_F_WRITE       2
#define VIRTIO_BLK_T_IN          0
#define EXT4_SUPER_SECTOR        2
#define EXT4_MAGIC               0xef53

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

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, VIRTIO_BLK_STACK
  li s0, VIRTIO_BASE

  lwu t0, REG_MAGIC_VALUE(s0)
  li t1, VIRTIO_MAGIC
  bne t0, t1, fail_magic
  lwu t0, REG_VERSION(s0)
  li t1, VIRTIO_MMIO_VERSION
  bne t0, t1, fail_version
  lwu t0, REG_DEVICE_ID(s0)
  li t1, VIRTIO_DEVICE_ID_BLOCK
  bne t0, t1, fail_device

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
  sw zero, REG_DRIVER_FEATURES_SEL(s0)
  sw zero, REG_DRIVER_FEATURES(s0)

  li t0, VIRTIO_STATUS_ACK | VIRTIO_STATUS_DRIVER | VIRTIO_STATUS_FEATURES_OK
  sw t0, REG_STATUS(s0)
  lwu t1, REG_STATUS(s0)
  andi t1, t1, VIRTIO_STATUS_FEATURES_OK
  beqz t1, fail_features_ok

  li t0, VIRTIO_DESC_ADDR
  li t1, VIRTIO_STATUS_ADDR + 8
clear_loop:
  sd zero, 0(t0)
  addi t0, t0, 8
  bltu t0, t1, clear_loop

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
  li t1, 2
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
  li t1, EXT4_SUPER_SECTOR
  sd t1, 8(t0)

  li t0, VIRTIO_STATUS_ADDR
  li t1, 0xff
  sb t1, 0(t0)

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

  li t0, VIRTIO_AVAIL_ADDR
  sh zero, 0(t0)
  sh zero, 2(t0)
  sh zero, 4(t0)
  fence rw, rw
  li t1, 1
  sh t1, 2(t0)
  fence rw, rw

  // Deliberately make representative fields from each device-written region
  // resident in DCache before the notify.  A virtio backend that updates PMEM
  // without completing the DMA/cache-coherence contract must not be allowed
  // to pass this smoke through cold misses after the device has written them.
  li t2, VIRTIO_STATUS_ADDR
  lbu t4, 0(t2)
  li t2, VIRTIO_USED_ADDR
  lhu t4, 2(t2)
  li t2, VIRTIO_DATA_ADDR
  lhu t4, 0x38(t2)
  fence rw, rw

  sw zero, REG_QUEUE_NOTIFY(s0)
  fence rw, rw

  li t3, 10000
poll_status:
  li t0, VIRTIO_STATUS_ADDR
  lbu t1, 0(t0)
  beqz t1, check_result
  addi t3, t3, -1
  bnez t3, poll_status
  j fail_timeout

check_result:
  li t0, VIRTIO_DATA_ADDR
  lhu t1, 0x38(t0)
  li t2, EXT4_MAGIC
  bne t1, t2, fail_ext4

  li t0, VIRTIO_USED_ADDR
  lhu t1, 2(t0)
  li t2, 1
  bne t1, t2, fail_used_idx
  lwu t1, 4(t0)
  bnez t1, fail_used_id
  lwu t1, 8(t0)
  li t2, 513
  bne t1, t2, fail_used_len

  lwu t1, REG_INTERRUPT_STATUS(s0)
  andi t1, t1, 1
  beqz t1, fail_irq
  li t1, 1
  sw t1, REG_INTERRUPT_ACK(s0)
  lwu t1, REG_INTERRUPT_STATUS(s0)
  andi t1, t1, 1
  bnez t1, fail_irq_ack

  li a0, 0
  ebreak

fail_magic:
  li a0, 1
  ebreak
fail_version:
  li a0, 2
  ebreak
fail_device:
  li a0, 3
  ebreak
fail_features:
  li a0, 4
  ebreak
fail_features_ok:
  li a0, 5
  ebreak
fail_queue_max:
  li a0, 6
  ebreak
fail_timeout:
  li a0, 7
  ebreak
fail_ext4:
  li a0, 8
  ebreak
fail_used_idx:
  li a0, 9
  ebreak
fail_used_id:
  li a0, 10
  ebreak
fail_used_len:
  li a0, 11
  ebreak
fail_irq:
  li a0, 12
  ebreak
fail_irq_ack:
  li a0, 13
  ebreak

  .option pop
