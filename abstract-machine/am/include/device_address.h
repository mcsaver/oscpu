#ifndef __AM_DEVICE_ADDRESS_H__
#define __AM_DEVICE_ADDRESS_H__

// ============================================================================
// AM 侧设备地址图 —— 全 ISA 共用的单一集中点 (single source, all ISAs)
//
//   默认                       : Linux/SoC 设备图,与 NEMU / NPC 三方一致,
//                                这是 difftest 能成立的前提。全部 ISA 共用此图。
//   -DDEVICE_MAP_LEGACY        : 切回封存的旧 AM 图 (0xa0000000 家族),
//                                仅历史 RV32 / x86 需要旧口径时显式开启。
//
// 对应真源:
//   NEMU : nemu/include/device/device_address.h
//   NPC  : npc/rv64/csrc/include/device_address.h  (经脚本回写 vsrc/include/define.v)
// 三份必须数值一致,由 Linux/scripts/check-device-address-map.sh 门禁校验。
//
// difftest 说明: NPC 对任何经 DPI/csrc 的 MMIO 访问都会 skip_ref(见
// npc/rv64/csrc/memory/paddr.c),所以 rtc/kbd/vga 用简易 csrc 模型即可,值不必与
// NEMU 逐拍一致。serial 走 RTL UART(只写),clint/plic 走 RTL(中断,AM 不作数据读)。
// ============================================================================

#if defined(DEVICE_MAP_LEGACY)
// ---- 封存: 旧 AM 设备图 (opt-in) ----
#  define DEV_SERIAL_BASE   0xa00003f8UL
#  define DEV_CLINT_BASE    0x02000000UL
#  define DEV_PLIC_BASE     0x0c000000UL
#  define DEV_RTC_BASE      0xa0000048UL
#  define DEV_KBD_BASE      0xa0000060UL
#  define DEV_VGACTL_BASE   0xa0000100UL
#  define DEV_FB_BASE       0xa1000000UL
#  define DEV_DISK_BASE     0xa0000300UL
#  define DEV_AUDIO_BASE    0xa0000200UL
#  define DEV_AUDIO_SBUF    0xa1200000UL
#else
// ---- 默认: Linux / SoC 设备图 (全 ISA 共用) ----
//   真设备 (NPC 有 RTL, NEMU 有对应模型):
#  define DEV_SERIAL_BASE   0x10000000UL  // ns16550a, THR@offset0 (RTL UART, AM 只写安全)
#  define DEV_CLINT_BASE    0x02000000UL  // RTL CLINT (中断/mtimecmp, AM 不作功能读)
#  define DEV_PLIC_BASE     0x0c000000UL  // RTL PLIC  (外部中断)
#  define DEV_DISK_BASE     0x10001000UL  // virtio-blk (Linux; AM 侧 present=false)
//   设备树真设备 (NEMU 已实现, AM 的 TRM/timer 直接架构其上, 与 Linux 走同一套设备):
#  define DEV_GOLDFISH_RTC_BASE 0x10003000UL // goldfish-rtc: AM timer 的时间源(纳秒), 设备树 goldfish_rtc
#  define DEV_SYSCON_BASE       0x00100000UL // reset_syscon(SiFive Test Finisher): AM halt→poweroff/exit
//   简易仿真设备: 无 RTL/无 Linux 对等, 集中在一个 DPI 窗口 (0x12000000, NPC 经 LEGACY_MMIO
//   slave→DPI→csrc→skip_ref; NEMU 用简易模型)。地址不必"像 Linux", 仿真专用。
#  define DEV_RTC_BASE      0x12000048UL  // csrc 简易 RTC (两个 32bit)
#  define DEV_KBD_BASE      0x12000060UL  // csrc 简易键盘 (keydown|keycode)
#  define DEV_AUDIO_BASE    0x12000200UL  // csrc 简易音频控制 (present=false 占位)
#  define DEV_VGACTL_BASE   0x12000100UL  // csrc 简易 VGA 控制 (w<<16|h, sync@+4)
#  define DEV_FB_BASE       0x13000000UL  // csrc framebuffer (窗口 +0x1000000)
#  define DEV_AUDIO_SBUF    0x13200000UL  // csrc 音频流缓冲 (窗口 +0x1200000)
#endif

#endif
