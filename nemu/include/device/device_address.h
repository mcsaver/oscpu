#ifndef __NEMU_DEVICE_ADDRESS_H__
#define __NEMU_DEVICE_ADDRESS_H__

#include <platform/generic-map.h>

// ============================================================================
// Generic IOMap 兼容命名层
//
// 数值真源位于 platform/generic-map.h；本文件只把现有 DEV_* consumer
// 映射到 generic profile 的手册名称。SOC_SIM 选择的是另一套完整平台，
// 其 UART/SPI/GPIO 等地址见 platform/ysyxsoc-map.h，不能在这里把 SPI
// 别名成 virtio-blk，也不能把 GPIO 别名成 virtio-rng。
//
// generic profile 的外部 ABI 对照:
//   AM  : abstract-machine/am/include/device_address.h
//   NPC : npc/rv64/csrc/include/device_address.h (经脚本回写 vsrc/include/define.v)
// 这些镜像必须数值一致,由 Linux/scripts/check-device-address-map.sh 校验。
// ============================================================================

#define DEV_SERIAL_MMIO        NEMU_GENERIC_UART_BASE
#define DEV_RTC_MMIO           NEMU_GENERIC_RTC_BASE
#define DEV_KBD_MMIO           NEMU_GENERIC_KEYBOARD_BASE
#define DEV_VGA_CTL_MMIO       NEMU_GENERIC_VGA_CONTROL_BASE
#define DEV_FB_ADDR            NEMU_GENERIC_FRAMEBUFFER_BASE
#define DEV_DISK_MMIO          NEMU_GENERIC_VIRTIO_BLK_BASE
#define DEV_AUDIO_CTL_MMIO     NEMU_GENERIC_AUDIO_CONTROL_BASE
#define DEV_SB_ADDR            NEMU_GENERIC_AUDIO_BUFFER_BASE

#define DEV_CLINT_MMIO         NEMU_GENERIC_CLINT_BASE
#define DEV_PLIC_MMIO          NEMU_GENERIC_PLIC_BASE
#define DEV_VIRTIO_RNG_MMIO    NEMU_GENERIC_VIRTIO_RNG_BASE
#define DEV_GOLDFISH_RTC_MMIO  NEMU_GENERIC_GOLDFISH_RTC_BASE
#define DEV_VIRTIO_NET_MMIO    NEMU_GENERIC_VIRTIO_NET_BASE
#define DEV_SYSCON_RESET_MMIO  NEMU_GENERIC_SYSCON_RESET_BASE

#endif
