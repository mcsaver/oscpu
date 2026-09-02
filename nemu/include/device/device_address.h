#ifndef __NEMU_DEVICE_ADDRESS_H__
#define __NEMU_DEVICE_ADDRESS_H__

#include <generated/autoconf.h>

// ============================================================================
// NEMU 侧设备地址图 —— 单一集中点 (single source)
//
//   默认                  : Linux/SoC 设备图,全 ISA 共用。与 AM / NPC 三方一致,
//                           这是 difftest 能成立的前提。
//   CONFIG_DEVICE_MAP_LEGACY=y : 切回封存的旧图 (0xa0000000 家族)。
//
// 对应真源:
//   AM  : abstract-machine/am/include/device_address.h
//   NPC : npc/rv64/csrc/include/device_address.h (经脚本回写 vsrc/include/define.v)
// 三份必须数值一致,由 Linux/scripts/check-device-address-map.sh 门禁校验。
// ============================================================================

#ifdef CONFIG_DEVICE_MAP_LEGACY
// ---- 封存旧图 (opt-in) ----
#  define DEV_SERIAL_MMIO    0xa00003f8
#  define DEV_RTC_MMIO       0xa0000048
#  define DEV_KBD_MMIO       0xa0000060
#  define DEV_VGA_CTL_MMIO   0xa0000100
#  define DEV_FB_ADDR        0xa1000000
#  define DEV_DISK_MMIO      0xa0000300
#  define DEV_AUDIO_CTL_MMIO 0xa0000200
#  define DEV_SB_ADDR        0xa1200000
#else
// ---- 默认 Linux/SoC 图 (全 ISA 共用) ----
//   真设备:
#  define DEV_SERIAL_MMIO    0x10000000   // ns16550a (NPC 侧真 RTL UART)
#  define DEV_DISK_MMIO      0x10001000   // virtio-blk (Linux; AM 侧 present=false)
//   简易仿真设备: 集中在 0x12000000 DPI 窗口 (NPC 经 LEGACY_MMIO slave→DPI→csrc→skip_ref)
#  define DEV_RTC_MMIO       0x12000048   // 简易 RTC (AM timer, 两个 32bit)
#  define DEV_KBD_MMIO       0x12000060   // 简易键盘
#  define DEV_VGA_CTL_MMIO   0x12000100   // 简易 VGA 控制
#  define DEV_AUDIO_CTL_MMIO 0x12000200   // 简易音频控制
#  define DEV_FB_ADDR        0x13000000   // framebuffer (窗口 +0x1000000)
#  define DEV_SB_ADDR        0x13200000   // 音频流缓冲 (窗口 +0x1200000)
#endif

// ---- Linux 平台设备 (RV64 system；reset_syscon 已是 NEMU/NPC 共有设备；
// virtio_rng/net、goldfish_rtc 仍为 NEMU 独有) ----
#define DEV_CLINT_MMIO         0x02000000
#define DEV_PLIC_MMIO          0x0c000000
#define DEV_VIRTIO_RNG_MMIO    0x10002000
#define DEV_GOLDFISH_RTC_MMIO  0x10003000
#define DEV_VIRTIO_NET_MMIO    0x10004000
#define DEV_SYSCON_RESET_MMIO  0x00100000

#endif
