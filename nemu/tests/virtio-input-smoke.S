/*
 * NEMU virtio-input 裸机协议回归。
 *
 * 该程序直接驱动 modern virtio-mmio，检查配置查询、双 split virtqueue、
 * statusq 完成、eventq 的 Linux input_event wire layout，以及 PLIC IRQ7。
 * 宿主测试 shim 会依次注入 A 按下、SDL 自动重复、A 抬起；设备应过滤
 * 自动重复，并为两次有效转换各产生 EV_KEY + EV_SYN。
 */

  .equ VIRTIO_INPUT_BASE,       0x10006000
  .equ PLIC_PRIORITY_7,         0x0c00001c
  .equ PLIC_PENDING,            0x0c001000
  .equ PLIC_ENABLE_M,           0x0c002000
  .equ PLIC_THRESHOLD_M,        0x0c200000
  .equ PLIC_CLAIM_M,            0x0c200004

  .equ VIRTIO_MAGIC,            0x000
  .equ VIRTIO_VERSION,          0x004
  .equ VIRTIO_DEVICE_ID,        0x008
  .equ VIRTIO_VENDOR_ID,        0x00c
  .equ VIRTIO_DEVICE_FEATURES,  0x010
  .equ VIRTIO_DEVICE_FEAT_SEL,  0x014
  .equ VIRTIO_DRIVER_FEATURES,  0x020
  .equ VIRTIO_DRIVER_FEAT_SEL,  0x024
  .equ VIRTIO_QUEUE_SEL,        0x030
  .equ VIRTIO_QUEUE_NUM_MAX,    0x034
  .equ VIRTIO_QUEUE_NUM,        0x038
  .equ VIRTIO_QUEUE_READY,      0x044
  .equ VIRTIO_QUEUE_NOTIFY,     0x050
  .equ VIRTIO_INTERRUPT_STATUS, 0x060
  .equ VIRTIO_INTERRUPT_ACK,    0x064
  .equ VIRTIO_STATUS,           0x070
  .equ VIRTIO_QUEUE_DESC_LOW,   0x080
  .equ VIRTIO_QUEUE_DESC_HIGH,  0x084
  .equ VIRTIO_QUEUE_AVAIL_LOW,  0x090
  .equ VIRTIO_QUEUE_AVAIL_HIGH, 0x094
  .equ VIRTIO_QUEUE_USED_LOW,   0x0a0
  .equ VIRTIO_QUEUE_USED_HIGH,  0x0a4
  .equ VIRTIO_CONFIG,           0x100

  .equ EVENT_DESC,              0x80008000
  .equ EVENT_AVAIL,             0x80009000
  .equ EVENT_USED,              0x8000a000
  .equ EVENT_BUFFER,            0x8000b000
  .equ STATUS_DESC,             0x80010000
  .equ STATUS_AVAIL,            0x80011000
  .equ STATUS_USED,             0x80012000
  .equ STATUS_BUFFER,           0x80013000

  .equ VIRTQ_DESC_F_WRITE,      2
  .equ KEY_A,                   30

  .macro CHECK_EQ reg, expected, error
    li t6, \expected
    li a0, \error
    bne \reg, t6, fail
  .endm

  .macro CHECK_MASK reg, mask, expected, error
    li t6, \mask
    and t6, \reg, t6
    li a0, \error
    li t5, \expected
    bne t6, t5, fail
  .endm

  .macro SET_QUEUE_ADDR offset_low, offset_high, address
    li t0, \address
    sw t0, \offset_low(s0)
    sw zero, \offset_high(s0)
  .endm

  .macro INIT_DESC base, index, address, length, flags
    li t0, \address
    sd t0, (\index * 16)(\base)
    li t0, \length
    sw t0, (\index * 16 + 8)(\base)
    li t0, \flags
    sh t0, (\index * 16 + 12)(\base)
    sh zero, (\index * 16 + 14)(\base)
  .endm

  .section .text, "ax", @progbits
  .globl _start
  .type _start, @function
  .option push
  .option nopic
  .option norvc
  .align 2

_start:
  la t0, unexpected_trap
  csrw mtvec, t0
  li s0, VIRTIO_INPUT_BASE
  li s1, PLIC_PENDING
  li s2, EVENT_DESC
  li s3, EVENT_AVAIL
  li s4, EVENT_USED
  li s5, STATUS_DESC
  li s6, STATUS_AVAIL
  li s7, STATUS_USED

  /* 从干净 transport 开始，并核对标准 virtio-mmio 身份。 */
  sw zero, VIRTIO_STATUS(s0)
  lw t0, VIRTIO_MAGIC(s0)
  CHECK_EQ t0, 0x74726976, 1
  lw t0, VIRTIO_VERSION(s0)
  CHECK_EQ t0, 2, 2
  lw t0, VIRTIO_DEVICE_ID(s0)
  CHECK_EQ t0, 18, 3
  lw t0, VIRTIO_VENDOR_ID(s0)
  CHECK_EQ t0, 0x58535959, 4

  /* 只暴露 VERSION_1；不得虚报 INDIRECT_DESC / EVENT_IDX。 */
  sw zero, VIRTIO_DEVICE_FEAT_SEL(s0)
  lw t0, VIRTIO_DEVICE_FEATURES(s0)
  CHECK_EQ t0, 0, 5
  li t0, 1
  sw t0, VIRTIO_DEVICE_FEAT_SEL(s0)
  lw t0, VIRTIO_DEVICE_FEATURES(s0)
  CHECK_EQ t0, 1, 6

  /* Linux virtio_input_config：name、ids、EV_KEY bitmap、EV_REP。 */
  li t0, 1
  sb t0, VIRTIO_CONFIG(s0)
  sb zero, (VIRTIO_CONFIG + 1)(s0)
  lbu t0, (VIRTIO_CONFIG + 2)(s0)
  li a0, 7
  beqz t0, fail
  lw t0, (VIRTIO_CONFIG + 8)(s0)
  CHECK_EQ t0, 0x554d454e, 8

  li t0, 3
  sb t0, VIRTIO_CONFIG(s0)
  lbu t0, (VIRTIO_CONFIG + 2)(s0)
  CHECK_EQ t0, 8, 9
  lhu t0, (VIRTIO_CONFIG + 8)(s0)
  CHECK_EQ t0, 6, 10
  lhu t0, (VIRTIO_CONFIG + 10)(s0)
  CHECK_EQ t0, 0x5958, 11

  li t0, 0x11
  sb t0, VIRTIO_CONFIG(s0)
  li t0, 1
  sb t0, (VIRTIO_CONFIG + 1)(s0)
  lbu t0, (VIRTIO_CONFIG + 2)(s0)
  CHECK_EQ t0, 55, 12
  /* KEY_A=30 对应 payload[3] bit6；F12=88 对应 payload[11] bit0。 */
  lbu t0, (VIRTIO_CONFIG + 8 + 3)(s0)
  CHECK_MASK t0, 0x40, 0x40, 13
  lbu t0, (VIRTIO_CONFIG + 8 + 11)(s0)
  CHECK_MASK t0, 0x01, 0x01, 14

  li t0, 0x14
  sb t0, (VIRTIO_CONFIG + 1)(s0)
  lbu t0, (VIRTIO_CONFIG + 2)(s0)
  CHECK_EQ t0, 1, 15
  lbu t0, (VIRTIO_CONFIG + 8)(s0)
  CHECK_EQ t0, 0, 16

  /* 两条队列均为 64 项上限；不存在第三条队列。 */
  sw zero, VIRTIO_QUEUE_SEL(s0)
  lw t0, VIRTIO_QUEUE_NUM_MAX(s0)
  CHECK_EQ t0, 64, 17
  li t0, 1
  sw t0, VIRTIO_QUEUE_SEL(s0)
  lw t0, VIRTIO_QUEUE_NUM_MAX(s0)
  CHECK_EQ t0, 64, 18
  li t0, 2
  sw t0, VIRTIO_QUEUE_SEL(s0)
  lw t0, VIRTIO_QUEUE_NUM_MAX(s0)
  CHECK_EQ t0, 0, 19

  /* 标准累计状态推进与 VERSION_1 协商。 */
  li t0, 1
  sw t0, VIRTIO_STATUS(s0)
  li t0, 3
  sw t0, VIRTIO_STATUS(s0)
  li t0, 1
  sw t0, VIRTIO_DRIVER_FEAT_SEL(s0)
  sw t0, VIRTIO_DRIVER_FEATURES(s0)
  sw zero, VIRTIO_DRIVER_FEAT_SEL(s0)
  sw zero, VIRTIO_DRIVER_FEATURES(s0)
  li t0, 0x0b
  sw t0, VIRTIO_STATUS(s0)
  lw t0, VIRTIO_STATUS(s0)
  CHECK_EQ t0, 0x0b, 20

  /* eventq：先验证非法 QueueNum/layout 会被拒绝，再安装有效 ring。 */
  sw zero, VIRTIO_QUEUE_SEL(s0)
  li t0, 3
  sw t0, VIRTIO_QUEUE_NUM(s0)
  li t0, 8
  sw t0, VIRTIO_QUEUE_NUM(s0)
  SET_QUEUE_ADDR VIRTIO_QUEUE_DESC_LOW, VIRTIO_QUEUE_DESC_HIGH, 0x40000000
  SET_QUEUE_ADDR VIRTIO_QUEUE_AVAIL_LOW, VIRTIO_QUEUE_AVAIL_HIGH, EVENT_AVAIL
  SET_QUEUE_ADDR VIRTIO_QUEUE_USED_LOW, VIRTIO_QUEUE_USED_HIGH, EVENT_USED
  li t0, 1
  sw t0, VIRTIO_QUEUE_READY(s0)
  lw t0, VIRTIO_QUEUE_READY(s0)
  CHECK_EQ t0, 0, 22

  SET_QUEUE_ADDR VIRTIO_QUEUE_DESC_LOW, VIRTIO_QUEUE_DESC_HIGH, EVENT_DESC
  sh zero, 0(s3)
  sh zero, 2(s3)
  sh zero, 0(s4)
  sh zero, 2(s4)
  li t0, 1
  sw t0, VIRTIO_QUEUE_READY(s0)
  lw t0, VIRTIO_QUEUE_READY(s0)
  CHECK_EQ t0, 1, 23

  /*
   * 五个 event buffer 中 descriptor 2 故意缺少 WRITE：设备必须以 len=0
   * 完成它，并把尚未投递的 KEY_A release 继续写入 descriptor 3。
   */
  INIT_DESC s2, 0, (EVENT_BUFFER + 0), 8, VIRTQ_DESC_F_WRITE
  INIT_DESC s2, 1, (EVENT_BUFFER + 8), 8, VIRTQ_DESC_F_WRITE
  INIT_DESC s2, 2, (EVENT_BUFFER + 16), 8, 0
  INIT_DESC s2, 3, (EVENT_BUFFER + 24), 8, VIRTQ_DESC_F_WRITE
  INIT_DESC s2, 4, (EVENT_BUFFER + 32), 8, VIRTQ_DESC_F_WRITE
  li t0, EVENT_BUFFER
  sd zero, 0(t0)
  sd zero, 8(t0)
  sd zero, 16(t0)
  sd zero, 24(t0)
  sd zero, 32(t0)
  sh zero, 4(s3)
  li t0, 1
  sh t0, 6(s3)
  li t0, 2
  sh t0, 8(s3)
  li t0, 3
  sh t0, 10(s3)
  li t0, 4
  sh t0, 12(s3)
  li t0, 5
  sh t0, 2(s3)

  /* statusq：一个有效 readable buffer，随后一个非法 writable buffer。 */
  li t0, 1
  sw t0, VIRTIO_QUEUE_SEL(s0)
  li t0, 8
  sw t0, VIRTIO_QUEUE_NUM(s0)
  SET_QUEUE_ADDR VIRTIO_QUEUE_DESC_LOW, VIRTIO_QUEUE_DESC_HIGH, STATUS_DESC
  SET_QUEUE_ADDR VIRTIO_QUEUE_AVAIL_LOW, VIRTIO_QUEUE_AVAIL_HIGH, STATUS_AVAIL
  SET_QUEUE_ADDR VIRTIO_QUEUE_USED_LOW, VIRTIO_QUEUE_USED_HIGH, STATUS_USED
  sh zero, 0(s6)
  sh zero, 2(s6)
  sh zero, 0(s7)
  sh zero, 2(s7)
  li t0, 1
  sw t0, VIRTIO_QUEUE_READY(s0)
  lw t0, VIRTIO_QUEUE_READY(s0)
  CHECK_EQ t0, 1, 24

  INIT_DESC s5, 0, STATUS_BUFFER, 8, 0
  INIT_DESC s5, 1, (STATUS_BUFFER + 8), 8, VIRTQ_DESC_F_WRITE
  li t0, STATUS_BUFFER
  li t1, 0x0000000100000011
  sd t1, 0(t0)
  sd zero, 8(t0)
  sh zero, 4(s6)
  li t0, 1
  sh t0, 6(s6)
  li t0, 2
  sh t0, 2(s6)

  /* PLIC M context 接收 IRQ7。 */
  li t0, PLIC_PRIORITY_7
  li t1, 1
  sw t1, 0(t0)
  li t0, PLIC_ENABLE_M
  li t1, 0x80
  sw t1, 0(t0)
  li t0, PLIC_THRESHOLD_M
  sw zero, 0(t0)

  /* DRIVER_OK 后通知 statusq；notify 路径同步完成两个 descriptor。 */
  li t0, 0x0f
  sw t0, VIRTIO_STATUS(s0)
  lw t0, VIRTIO_STATUS(s0)
  CHECK_EQ t0, 0x0f, 25
  li t0, 1
  sw t0, VIRTIO_QUEUE_NOTIFY(s0)
  lhu t0, 2(s7)
  CHECK_EQ t0, 2, 26
  lw t0, 4(s7)
  CHECK_EQ t0, 0, 27
  lw t0, 8(s7)
  CHECK_EQ t0, 0, 28
  lw t0, 12(s7)
  CHECK_EQ t0, 1, 29
  lw t0, 16(s7)
  CHECK_EQ t0, 0, 30
  lw t0, VIRTIO_INTERRUPT_STATUS(s0)
  CHECK_MASK t0, 1, 1, 31
  lw t0, 0(s1)
  CHECK_MASK t0, 0x80, 0x80, 32
  li t0, PLIC_CLAIM_M
  lw t1, 0(t0)
  CHECK_EQ t1, 7, 33
  li t1, 1
  sw t1, VIRTIO_INTERRUPT_ACK(s0)
  lw t1, VIRTIO_INTERRUPT_STATUS(s0)
  CHECK_EQ t1, 0, 34
  li t1, 7
  sw t1, 0(t0)
  lw t1, 0(s1)
  CHECK_MASK t1, 0x80, 0, 35

  /* eventq 已发布五个 buffer；等待测试 shim 注入 SDL 事件。 */
  sw zero, VIRTIO_QUEUE_NOTIFY(s0)
wait_for_input:
  lhu t0, 2(s4)
  li t1, 5
  bne t0, t1, wait_for_input

  /* used ring 精确反映：press 两个事件、一个坏 buffer、release 两个事件。 */
  lw t0, 4(s4)
  CHECK_EQ t0, 0, 36
  lw t0, 8(s4)
  CHECK_EQ t0, 8, 37
  lw t0, 12(s4)
  CHECK_EQ t0, 1, 38
  lw t0, 16(s4)
  CHECK_EQ t0, 8, 39
  lw t0, 20(s4)
  CHECK_EQ t0, 2, 40
  lw t0, 24(s4)
  CHECK_EQ t0, 0, 41
  lw t0, 28(s4)
  CHECK_EQ t0, 3, 42
  lw t0, 32(s4)
  CHECK_EQ t0, 8, 43
  lw t0, 36(s4)
  CHECK_EQ t0, 4, 44
  lw t0, 40(s4)
  CHECK_EQ t0, 8, 45

  li t0, EVENT_BUFFER
  ld t1, 0(t0)
  CHECK_EQ t1, 0x00000001001e0001, 46
  ld t1, 8(t0)
  CHECK_EQ t1, 0, 47
  ld t1, 16(t0)
  CHECK_EQ t1, 0, 48
  ld t1, 24(t0)
  CHECK_EQ t1, 0x00000000001e0001, 49
  ld t1, 32(t0)
  CHECK_EQ t1, 0, 50

  /* eventq 完成再次拉高 IRQ7；ACK + claim completion 后彻底撤销。 */
  lw t0, VIRTIO_INTERRUPT_STATUS(s0)
  CHECK_MASK t0, 1, 1, 51
  lw t0, 0(s1)
  CHECK_MASK t0, 0x80, 0x80, 52
  li t0, PLIC_CLAIM_M
  lw t1, 0(t0)
  CHECK_EQ t1, 7, 53
  li t1, 1
  sw t1, VIRTIO_INTERRUPT_ACK(s0)
  li t1, 7
  sw t1, 0(t0)
  lw t1, 0(s1)
  CHECK_MASK t1, 0x80, 0, 54

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

unexpected_trap:
  csrr a0, mepc
  li t0, 0x80000000
  sub a0, a0, t0
  j fail

  .option pop
  .size _start, .-_start

  .section .tohost, "aw", @progbits
  .balign 8
  .globl tohost
tohost:
  .dword 0
