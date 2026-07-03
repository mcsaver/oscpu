#ifndef __NPC_DEVICE_ADDRESS_H__
#define __NPC_DEVICE_ADDRESS_H__

#include <stdint.h>

// ============================================================================
// NPC (csrc) 侧设备地址图 —— 单一集中点 (single source)
//
// 与 AM (abstract-machine/am/include/device_address.h) 和
//    NEMU (nemu/include/device/device_address.h) 三方数值必须一致 —— difftest 前提。
// 由 Linux/scripts/check-device-address-map.sh 门禁校验;RTL 侧 vsrc/include/define.v
// 的设备段由 npc/rv64/scripts/gen-define-devices.py 从本文件回写生成。
//
// 分工:
//   - serial : 真 RTL UART @ 0x10000000 (Uart.v; 写 THR 触发 npc_uart_event → host 输出
//              + npc_difftest_skip_ref, 见 csrc/dpi.c)。csrc 不再单独建 serial 模型。
//   - clint/plic : 真 RTL (AxiLiteClint/AxiLitePlic), AM 不作功能数据读。
//   - rtc/kbd/vga/fb : 无 RTL 的简易 csrc 仿真设备, 集中在 DPI 窗口
//              [0x12000000, 0x14000000) (RTL AxiLiteXbar 的 LEGACY_MMIO slave→DPI→
//              csrc paddr.c→设备回调, 每次访问触发 skip_ref, 故 difftest 安全)。
// ============================================================================

#define NPC_UART_BASE     UINT64_C(0x10000000)  // 真 RTL UART (ns16550a)
#define NPC_SERIAL_PORT   NPC_UART_BASE
#define NPC_CLINT_BASE    UINT64_C(0x02000000)  // 真 RTL CLINT
#define NPC_PLIC_BASE     UINT64_C(0x0c000000)  // 真 RTL PLIC

// 简易 csrc 仿真设备 DPI 窗口 (须与 define.v NPC_AXI_LEGACY_MMIO_BASE/MASK 一致)
#define NPC_DEVICE_BASE   UINT64_C(0x12000000)  // 窗口基址
#define NPC_DEVICE_TOP    UINT64_C(0x14000000)  // 窗口上界 (32MB, 对应 mask 0xfe000000)
#define NPC_RTC_ADDR      (NPC_DEVICE_BASE + UINT64_C(0x00000048))
#define NPC_KBD_ADDR      (NPC_DEVICE_BASE + UINT64_C(0x00000060))
#define NPC_VGACTL_ADDR   (NPC_DEVICE_BASE + UINT64_C(0x00000100))
#define NPC_SYNC_ADDR     (NPC_VGACTL_ADDR + UINT64_C(0x4))
#define NPC_FB_ADDR       (NPC_DEVICE_BASE + UINT64_C(0x01000000))  // = 0x13000000

#endif
