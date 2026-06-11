// NEMU virtio-mmio net control virtqueue smoke.
// Exercises CTRL_RX, CTRL_RX_EXTRA, CTRL_VLAN, GUEST_ANNOUNCE, MAC_TABLE_SET and MAC_ADDR_SET OK completion plus unsupported ERR completion.

#ifndef VIRTIO_NET_STACK
#define VIRTIO_NET_STACK 0x87ee8000
#endif

#ifndef VIRTIO_NET_DESC_ADDR
#define VIRTIO_NET_DESC_ADDR 0x80018000
#endif
#ifndef VIRTIO_NET_AVAIL_ADDR
#define VIRTIO_NET_AVAIL_ADDR 0x80019000
#endif
#ifndef VIRTIO_NET_USED_ADDR
#define VIRTIO_NET_USED_ADDR 0x8001a000
#endif
#ifndef VIRTIO_NET_CTRL_HDR_ADDR
#define VIRTIO_NET_CTRL_HDR_ADDR 0x8001b000
#endif
#ifndef VIRTIO_NET_CTRL_ACK_ADDR
#define VIRTIO_NET_CTRL_ACK_ADDR 0x8001b010
#endif
#ifndef VIRTIO_NET_CTRL_MAC_UNI_ADDR
#define VIRTIO_NET_CTRL_MAC_UNI_ADDR 0x8001b020
#endif
#ifndef VIRTIO_NET_CTRL_MAC_MULTI_ADDR
#define VIRTIO_NET_CTRL_MAC_MULTI_ADDR 0x8001b040
#endif
#ifndef VIRTIO_NET_CTRL_MAC_ADDR_ADDR
#define VIRTIO_NET_CTRL_MAC_ADDR_ADDR 0x8001b060
#endif
#ifndef VIRTIO_NET_CTRL_VLAN_ADDR
#define VIRTIO_NET_CTRL_VLAN_ADDR 0x8001b070
#endif

#ifndef SYSCON_RESET_MMIO
#define SYSCON_RESET_MMIO 0x100000
#endif
#ifndef SYSCON_POWEROFF_VALUE
#define SYSCON_POWEROFF_VALUE 0x5555
#endif

#define VIRTIO_NET_BASE          0x10004000
#define UART_BASE                0x10000000
#define VIRTIO_MAGIC             0x74726976
#define VIRTIO_MMIO_VERSION      2
#define VIRTIO_DEVICE_ID_NET     1
#define VIRTIO_STATUS_ACK        1
#define VIRTIO_STATUS_DRIVER     2
#define VIRTIO_STATUS_DRIVER_OK  4
#define VIRTIO_STATUS_FEATURES_OK 8
#define VIRTQ_DESC_F_NEXT        1
#define VIRTQ_DESC_F_WRITE       2
#define VIRTIO_NET_F_CTRL_VQ_MASK 0x00020000
#define VIRTIO_NET_F_CTRL_RX_MASK 0x00040000
#define VIRTIO_NET_F_CTRL_VLAN_MASK 0x00080000
#define VIRTIO_NET_F_CTRL_RX_EXTRA_MASK 0x00100000
#define VIRTIO_NET_F_GUEST_ANNOUNCE_MASK 0x00200000
#define VIRTIO_NET_F_CTRL_MAC_ADDR_MASK 0x00800000
#define VIRTIO_NET_CTRL_QUEUE    2
#define VIRTIO_NET_CTRL_QUEUE_SIZE 8
#define VIRTIO_NET_CTRL_ACK_OK   0
#define VIRTIO_NET_CTRL_ACK_ERR  1
#define VIRTIO_NET_CTRL_RX_CLASS 0
#define VIRTIO_NET_CTRL_RX_PROMISC 0
#define VIRTIO_NET_CTRL_RX_ALLUNI 2
#define VIRTIO_NET_CTRL_MAC_CLASS 1
#define VIRTIO_NET_CTRL_MAC_TABLE_SET 0
#define VIRTIO_NET_CTRL_MAC_ADDR_SET 1
#define VIRTIO_NET_CTRL_VLAN_CLASS 2
#define VIRTIO_NET_CTRL_VLAN_ADD 0
#define VIRTIO_NET_CTRL_VLAN_DEL 1
#define VIRTIO_NET_CTRL_VLAN_TEST_ID 42
#define VIRTIO_NET_CTRL_ANNOUNCE_CLASS 3
#define VIRTIO_NET_CTRL_ANNOUNCE_ACK 0

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
  li sp, VIRTIO_NET_STACK
  la t0, unexpected_trap
  csrw mtvec, t0
  csrw stvec, t0
  csrw mie, zero
  li t0, 0x8
  csrc mstatus, t0
  li s0, VIRTIO_NET_BASE

  lwu t0, REG_MAGIC_VALUE(s0)
  li t1, VIRTIO_MAGIC
  bne t0, t1, fail_magic
  lwu t0, REG_VERSION(s0)
  li t1, VIRTIO_MMIO_VERSION
  bne t0, t1, fail_version
  lwu t0, REG_DEVICE_ID(s0)
  li t1, VIRTIO_DEVICE_ID_NET
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

  sw zero, REG_DEVICE_FEATURES_SEL(s0)
  lwu t1, REG_DEVICE_FEATURES(s0)
  li t2, VIRTIO_NET_F_CTRL_VQ_MASK
  li t3, VIRTIO_NET_F_CTRL_RX_MASK
  or t2, t2, t3
  li t3, VIRTIO_NET_F_CTRL_VLAN_MASK
  or t2, t2, t3
  li t3, VIRTIO_NET_F_CTRL_RX_EXTRA_MASK
  or t2, t2, t3
  li t3, VIRTIO_NET_F_GUEST_ANNOUNCE_MASK
  or t2, t2, t3
  li t3, VIRTIO_NET_F_CTRL_MAC_ADDR_MASK
  or t2, t2, t3
  and t1, t1, t2
  bne t1, t2, fail_features
  sw zero, REG_DRIVER_FEATURES_SEL(s0)
  sw t2, REG_DRIVER_FEATURES(s0)

  li t0, VIRTIO_STATUS_ACK | VIRTIO_STATUS_DRIVER | VIRTIO_STATUS_FEATURES_OK
  sw t0, REG_STATUS(s0)
  lwu t1, REG_STATUS(s0)
  andi t1, t1, VIRTIO_STATUS_FEATURES_OK
  beqz t1, fail_features_ok

  call clear_queue_area
  li t0, VIRTIO_NET_CTRL_QUEUE
  sw t0, REG_QUEUE_SEL(s0)
  lwu t0, REG_QUEUE_NUM_MAX(s0)
  li t1, VIRTIO_NET_CTRL_QUEUE_SIZE
  bltu t0, t1, fail_queue_max
  sw t1, REG_QUEUE_NUM(s0)

  li t0, VIRTIO_NET_DESC_ADDR
  sw t0, REG_QUEUE_DESC_LOW(s0)
  sw zero, REG_QUEUE_DESC_HIGH(s0)
  li t0, VIRTIO_NET_AVAIL_ADDR
  sw t0, REG_QUEUE_DRIVER_LOW(s0)
  sw zero, REG_QUEUE_DRIVER_HIGH(s0)
  li t0, VIRTIO_NET_USED_ADDR
  sw t0, REG_QUEUE_DEVICE_LOW(s0)
  sw zero, REG_QUEUE_DEVICE_HIGH(s0)
  li t0, 1
  sw t0, REG_QUEUE_READY(s0)

  li t0, VIRTIO_STATUS_ACK | VIRTIO_STATUS_DRIVER | VIRTIO_STATUS_FEATURES_OK | VIRTIO_STATUS_DRIVER_OK
  sw t0, REG_STATUS(s0)

  call setup_ctrl_rx_promisc_cmd
  li t2, VIRTIO_NET_AVAIL_ADDR
  li t0, 1
  sh t0, 2(t2)
  li t0, VIRTIO_NET_CTRL_QUEUE
  sw t0, REG_QUEUE_NOTIFY(s0)

  li t2, VIRTIO_NET_USED_ADDR
  lhu t0, 2(t2)
  li t1, 1
  bne t0, t1, fail_used_idx
  lwu t0, 4(t2)
  bnez t0, fail_used_id
  lwu t0, 8(t2)
  li t1, 1
  bne t0, t1, fail_used_len
  li t2, VIRTIO_NET_CTRL_ACK_ADDR
  lbu t0, 0(t2)
  li t1, VIRTIO_NET_CTRL_ACK_OK
  bne t0, t1, fail_ack
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  beqz t0, fail_irq
  li t0, 1
  sw t0, REG_INTERRUPT_ACK(s0)
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  bnez t0, fail_irq_ack

  call setup_mac_table_cmd
  li t2, VIRTIO_NET_AVAIL_ADDR
  li t0, 0
  sh t0, 6(t2)
  li t0, 2
  sh t0, 2(t2)
  li t0, VIRTIO_NET_CTRL_QUEUE
  sw t0, REG_QUEUE_NOTIFY(s0)

  li t2, VIRTIO_NET_USED_ADDR
  lhu t0, 2(t2)
  li t1, 2
  bne t0, t1, fail_used_idx
  lwu t0, 12(t2)
  bnez t0, fail_used_id
  lwu t0, 16(t2)
  li t1, 1
  bne t0, t1, fail_used_len
  li t2, VIRTIO_NET_CTRL_ACK_ADDR
  lbu t0, 0(t2)
  li t1, VIRTIO_NET_CTRL_ACK_OK
  bne t0, t1, fail_ack
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  beqz t0, fail_irq
  li t0, 1
  sw t0, REG_INTERRUPT_ACK(s0)
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  bnez t0, fail_irq_ack

  call setup_mac_addr_cmd
  li t2, VIRTIO_NET_AVAIL_ADDR
  li t0, 0
  sh t0, 8(t2)
  li t0, 3
  sh t0, 2(t2)
  li t0, VIRTIO_NET_CTRL_QUEUE
  sw t0, REG_QUEUE_NOTIFY(s0)

  li t2, VIRTIO_NET_USED_ADDR
  lhu t0, 2(t2)
  li t1, 3
  bne t0, t1, fail_used_idx
  lwu t0, 20(t2)
  bnez t0, fail_used_id
  lwu t0, 24(t2)
  li t1, 1
  bne t0, t1, fail_used_len
  li t2, VIRTIO_NET_CTRL_ACK_ADDR
  lbu t0, 0(t2)
  li t1, VIRTIO_NET_CTRL_ACK_OK
  bne t0, t1, fail_ack
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  beqz t0, fail_irq
  li t0, 1
  sw t0, REG_INTERRUPT_ACK(s0)
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  bnez t0, fail_irq_ack

  call setup_ctrl_rx_alluni_cmd
  li t2, VIRTIO_NET_AVAIL_ADDR
  li t0, 0
  sh t0, 10(t2)
  li t0, 4
  sh t0, 2(t2)
  li t0, VIRTIO_NET_CTRL_QUEUE
  sw t0, REG_QUEUE_NOTIFY(s0)

  li t2, VIRTIO_NET_USED_ADDR
  lhu t0, 2(t2)
  li t1, 4
  bne t0, t1, fail_used_idx
  lwu t0, 28(t2)
  bnez t0, fail_used_id
  lwu t0, 32(t2)
  li t1, 1
  bne t0, t1, fail_used_len
  li t2, VIRTIO_NET_CTRL_ACK_ADDR
  lbu t0, 0(t2)
  li t1, VIRTIO_NET_CTRL_ACK_OK
  bne t0, t1, fail_ack
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  beqz t0, fail_irq
  li t0, 1
  sw t0, REG_INTERRUPT_ACK(s0)
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  bnez t0, fail_irq_ack

  call setup_vlan_add_cmd
  li t2, VIRTIO_NET_AVAIL_ADDR
  li t0, 0
  sh t0, 12(t2)
  li t0, 5
  sh t0, 2(t2)
  li t0, VIRTIO_NET_CTRL_QUEUE
  sw t0, REG_QUEUE_NOTIFY(s0)

  li t2, VIRTIO_NET_USED_ADDR
  lhu t0, 2(t2)
  li t1, 5
  bne t0, t1, fail_used_idx
  lwu t0, 36(t2)
  bnez t0, fail_used_id
  lwu t0, 40(t2)
  li t1, 1
  bne t0, t1, fail_used_len
  li t2, VIRTIO_NET_CTRL_ACK_ADDR
  lbu t0, 0(t2)
  li t1, VIRTIO_NET_CTRL_ACK_OK
  bne t0, t1, fail_ack
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  beqz t0, fail_irq
  li t0, 1
  sw t0, REG_INTERRUPT_ACK(s0)
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  bnez t0, fail_irq_ack

  call setup_vlan_del_cmd
  li t2, VIRTIO_NET_AVAIL_ADDR
  li t0, 0
  sh t0, 14(t2)
  li t0, 6
  sh t0, 2(t2)
  li t0, VIRTIO_NET_CTRL_QUEUE
  sw t0, REG_QUEUE_NOTIFY(s0)

  li t2, VIRTIO_NET_USED_ADDR
  lhu t0, 2(t2)
  li t1, 6
  bne t0, t1, fail_used_idx
  lwu t0, 44(t2)
  bnez t0, fail_used_id
  lwu t0, 48(t2)
  li t1, 1
  bne t0, t1, fail_used_len
  li t2, VIRTIO_NET_CTRL_ACK_ADDR
  lbu t0, 0(t2)
  li t1, VIRTIO_NET_CTRL_ACK_OK
  bne t0, t1, fail_ack
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  beqz t0, fail_irq
  li t0, 1
  sw t0, REG_INTERRUPT_ACK(s0)
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  bnez t0, fail_irq_ack

  call setup_announce_ack_cmd
  li t2, VIRTIO_NET_AVAIL_ADDR
  li t0, 0
  sh t0, 16(t2)
  li t0, 7
  sh t0, 2(t2)
  li t0, VIRTIO_NET_CTRL_QUEUE
  sw t0, REG_QUEUE_NOTIFY(s0)

  li t2, VIRTIO_NET_USED_ADDR
  lhu t0, 2(t2)
  li t1, 7
  bne t0, t1, fail_used_idx
  lwu t0, 52(t2)
  bnez t0, fail_used_id
  lwu t0, 56(t2)
  li t1, 1
  bne t0, t1, fail_used_len
  li t2, VIRTIO_NET_CTRL_ACK_ADDR
  lbu t0, 0(t2)
  li t1, VIRTIO_NET_CTRL_ACK_OK
  bne t0, t1, fail_ack
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  beqz t0, fail_irq
  li t0, 1
  sw t0, REG_INTERRUPT_ACK(s0)
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  bnez t0, fail_irq_ack

  call setup_unsupported_ctrl_cmd
  li t2, VIRTIO_NET_AVAIL_ADDR
  li t0, 0
  sh t0, 18(t2)
  li t0, 8
  sh t0, 2(t2)
  li t0, VIRTIO_NET_CTRL_QUEUE
  sw t0, REG_QUEUE_NOTIFY(s0)

  li t2, VIRTIO_NET_USED_ADDR
  lhu t0, 2(t2)
  li t1, 8
  bne t0, t1, fail_used_idx
  lwu t0, 60(t2)
  bnez t0, fail_used_id
  lwu t0, 64(t2)
  li t1, 1
  bne t0, t1, fail_used_len
  li t2, VIRTIO_NET_CTRL_ACK_ADDR
  lbu t0, 0(t2)
  li t1, VIRTIO_NET_CTRL_ACK_ERR
  bne t0, t1, fail_ack
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  beqz t0, fail_irq
  li t0, 1
  sw t0, REG_INTERRUPT_ACK(s0)
  lwu t0, REG_INTERRUPT_STATUS(s0)
  andi t0, t0, 1
  bnez t0, fail_irq_ack

  j pass

clear_queue_area:
  li t0, VIRTIO_NET_DESC_ADDR
  li t1, VIRTIO_NET_CTRL_VLAN_ADDR + 16
clear_loop:
  sd zero, 0(t0)
  addi t0, t0, 8
  bltu t0, t1, clear_loop
  ret

setup_mac_addr_cmd:
  li t0, VIRTIO_NET_DESC_ADDR
  li t1, VIRTIO_NET_CTRL_HDR_ADDR
  sd t1, 0(t0)
  li t1, 2
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 16
  li t1, VIRTIO_NET_CTRL_MAC_ADDR_ADDR
  sd t1, 0(t0)
  li t1, 6
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 2
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 32
  li t1, VIRTIO_NET_CTRL_ACK_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_NET_CTRL_HDR_ADDR
  li t1, VIRTIO_NET_CTRL_MAC_CLASS
  sb t1, 0(t0)
  li t1, VIRTIO_NET_CTRL_MAC_ADDR_SET
  sb t1, 1(t0)

  li t0, VIRTIO_NET_CTRL_MAC_ADDR_ADDR
  li t1, 0x02
  sb t1, 0(t0)
  sb zero, 1(t0)
  li t1, 0x5e
  sb t1, 2(t0)
  sb zero, 3(t0)
  li t1, 0x53
  sb t1, 4(t0)
  li t1, 0x02
  sb t1, 5(t0)

  li t0, VIRTIO_NET_CTRL_ACK_ADDR
  li t1, 0xff
  sb t1, 0(t0)

  li t0, VIRTIO_NET_AVAIL_ADDR + 4
  sh zero, 0(t0)
  ret

setup_mac_table_cmd:
  li t0, VIRTIO_NET_DESC_ADDR
  li t1, VIRTIO_NET_CTRL_HDR_ADDR
  sd t1, 0(t0)
  li t1, 2
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 16
  li t1, VIRTIO_NET_CTRL_MAC_UNI_ADDR
  sd t1, 0(t0)
  li t1, 10
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 2
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 32
  li t1, VIRTIO_NET_CTRL_MAC_MULTI_ADDR
  sd t1, 0(t0)
  li t1, 10
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 3
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 48
  li t1, VIRTIO_NET_CTRL_ACK_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_NET_CTRL_HDR_ADDR
  li t1, VIRTIO_NET_CTRL_MAC_CLASS
  sb t1, 0(t0)
  li t1, VIRTIO_NET_CTRL_MAC_TABLE_SET
  sb t1, 1(t0)

  li t0, VIRTIO_NET_CTRL_MAC_UNI_ADDR
  li t1, 1
  sw t1, 0(t0)
  li t1, 0x52
  sb t1, 4(t0)
  li t1, 0x54
  sb t1, 5(t0)
  sb zero, 6(t0)
  li t1, 0x12
  sb t1, 7(t0)
  li t1, 0x34
  sb t1, 8(t0)
  li t1, 0x56
  sb t1, 9(t0)

  li t0, VIRTIO_NET_CTRL_MAC_MULTI_ADDR
  li t1, 1
  sw t1, 0(t0)
  li t1, 0x01
  sb t1, 4(t0)
  sb zero, 5(t0)
  li t1, 0x5e
  sb t1, 6(t0)
  sb zero, 7(t0)
  sb zero, 8(t0)
  li t1, 0x01
  sb t1, 9(t0)

  li t0, VIRTIO_NET_CTRL_ACK_ADDR
  li t1, 0xff
  sb t1, 0(t0)

  li t0, VIRTIO_NET_AVAIL_ADDR + 4
  sh zero, 0(t0)
  ret

setup_vlan_add_cmd:
  li t0, VIRTIO_NET_DESC_ADDR
  li t1, VIRTIO_NET_CTRL_HDR_ADDR
  sd t1, 0(t0)
  li t1, 2
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 16
  li t1, VIRTIO_NET_CTRL_VLAN_ADDR
  sd t1, 0(t0)
  li t1, 2
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 2
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 32
  li t1, VIRTIO_NET_CTRL_ACK_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_NET_CTRL_HDR_ADDR
  li t1, VIRTIO_NET_CTRL_VLAN_CLASS
  sb t1, 0(t0)
  li t1, VIRTIO_NET_CTRL_VLAN_ADD
  sb t1, 1(t0)

  li t0, VIRTIO_NET_CTRL_VLAN_ADDR
  li t1, VIRTIO_NET_CTRL_VLAN_TEST_ID
  sh t1, 0(t0)

  li t0, VIRTIO_NET_CTRL_ACK_ADDR
  li t1, 0xff
  sb t1, 0(t0)

  li t0, VIRTIO_NET_AVAIL_ADDR + 4
  sh zero, 0(t0)
  ret

setup_vlan_del_cmd:
  li t0, VIRTIO_NET_DESC_ADDR
  li t1, VIRTIO_NET_CTRL_HDR_ADDR
  sd t1, 0(t0)
  li t1, 2
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 16
  li t1, VIRTIO_NET_CTRL_VLAN_ADDR
  sd t1, 0(t0)
  li t1, 2
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 2
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 32
  li t1, VIRTIO_NET_CTRL_ACK_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_NET_CTRL_HDR_ADDR
  li t1, VIRTIO_NET_CTRL_VLAN_CLASS
  sb t1, 0(t0)
  li t1, VIRTIO_NET_CTRL_VLAN_DEL
  sb t1, 1(t0)

  li t0, VIRTIO_NET_CTRL_VLAN_ADDR
  li t1, VIRTIO_NET_CTRL_VLAN_TEST_ID
  sh t1, 0(t0)

  li t0, VIRTIO_NET_CTRL_ACK_ADDR
  li t1, 0xff
  sb t1, 0(t0)

  li t0, VIRTIO_NET_AVAIL_ADDR + 4
  sh zero, 0(t0)
  ret

setup_announce_ack_cmd:
  li t0, VIRTIO_NET_DESC_ADDR
  li t1, VIRTIO_NET_CTRL_HDR_ADDR
  sd t1, 0(t0)
  li t1, 2
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 16
  li t1, VIRTIO_NET_CTRL_ACK_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_NET_CTRL_HDR_ADDR
  li t1, VIRTIO_NET_CTRL_ANNOUNCE_CLASS
  sb t1, 0(t0)
  li t1, VIRTIO_NET_CTRL_ANNOUNCE_ACK
  sb t1, 1(t0)
  li t0, VIRTIO_NET_CTRL_ACK_ADDR
  li t1, 0xff
  sb t1, 0(t0)

  li t0, VIRTIO_NET_AVAIL_ADDR + 4
  sh zero, 0(t0)
  ret

setup_unsupported_ctrl_cmd:
  li t0, VIRTIO_NET_DESC_ADDR
  li t1, VIRTIO_NET_CTRL_HDR_ADDR
  sd t1, 0(t0)
  li t1, 2
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 16
  li t1, VIRTIO_NET_CTRL_ACK_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_NET_CTRL_HDR_ADDR
  li t1, 0xffff
  sh t1, 0(t0)
  li t0, VIRTIO_NET_CTRL_ACK_ADDR
  li t1, 0xff
  sb t1, 0(t0)

  li t0, VIRTIO_NET_AVAIL_ADDR + 4
  sh zero, 0(t0)
  ret

setup_ctrl_rx_alluni_cmd:
  li t0, VIRTIO_NET_DESC_ADDR
  li t1, VIRTIO_NET_CTRL_HDR_ADDR
  sd t1, 0(t0)
  li t1, 3
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 16
  li t1, VIRTIO_NET_CTRL_ACK_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_NET_CTRL_HDR_ADDR
  li t1, VIRTIO_NET_CTRL_RX_CLASS
  sb t1, 0(t0)
  li t1, VIRTIO_NET_CTRL_RX_ALLUNI
  sb t1, 1(t0)
  li t1, 1
  sb t1, 2(t0)
  li t0, VIRTIO_NET_CTRL_ACK_ADDR
  li t1, 0xff
  sb t1, 0(t0)

  li t0, VIRTIO_NET_AVAIL_ADDR + 4
  sh zero, 0(t0)
  ret

setup_ctrl_rx_promisc_cmd:
  li t0, VIRTIO_NET_DESC_ADDR
  li t1, VIRTIO_NET_CTRL_HDR_ADDR
  sd t1, 0(t0)
  li t1, 3
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_NEXT
  sh t1, 12(t0)
  li t1, 1
  sh t1, 14(t0)

  li t0, VIRTIO_NET_DESC_ADDR + 16
  li t1, VIRTIO_NET_CTRL_ACK_ADDR
  sd t1, 0(t0)
  li t1, 1
  sw t1, 8(t0)
  li t1, VIRTQ_DESC_F_WRITE
  sh t1, 12(t0)
  sh zero, 14(t0)

  li t0, VIRTIO_NET_CTRL_HDR_ADDR
  li t1, VIRTIO_NET_CTRL_RX_CLASS
  sb t1, 0(t0)
  li t1, VIRTIO_NET_CTRL_RX_PROMISC
  sb t1, 1(t0)
  li t1, 1
  sb t1, 2(t0)
  li t0, VIRTIO_NET_CTRL_ACK_ADDR
  li t1, 0xff
  sb t1, 0(t0)

  li t0, VIRTIO_NET_AVAIL_ADDR + 4
  sh zero, 0(t0)
  ret

pass:
  li t0, SYSCON_RESET_MMIO
  li t1, SYSCON_POWEROFF_VALUE
  sw t1, 0(t0)
pass_spin:
  j pass_spin

unexpected_trap:
  j fail_spin

fail_magic:
fail_version:
fail_device:
fail_features:
fail_features_ok:
fail_queue_max:
fail_used_idx:
fail_used_id:
fail_used_len:
fail_ack:
fail_irq:
fail_irq_ack:
fail_spin:
  j fail_spin

  .option pop
