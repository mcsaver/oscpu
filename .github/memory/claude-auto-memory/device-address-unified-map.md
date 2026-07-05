---
name: device-address-unified-map
description: AM/NEMU/NPC 三侧设备地址统一到单一真源 device_address.h 的设计与验证
metadata: 
  node_type: memory
  type: project
  originSessionId: d675f1f5-fc9f-44fc-9203-dd00fff6473f
---

设备地址已从"Kconfig(NEMU) + 硬编码 nemu.h/npc.h(AM) + utils.h/define.v(NPC)分散、易漂移"重构为**每侧一个 `device_address.h` 单一集中点、三方数值一致**(2026-07-01)。

**统一 SoC 图(RV64 默认)**: serial `0x10000000`(NPC 真 RTL UART,AM `putch` 只写命中 THR@0)/ clint `0x02000000` / plic `0x0c000000` / rtc `0x12000048` / kbd `0x12000060` / vgactl `0x12000100` / fb `0x13000000` / disk `0x10001000`。简易仿真设备(rtc/kbd/vga/fb)集中在 **NPC 的 0x12000000 DPI 窗口**(= `define.v` `NPC_AXI_LEGACY_MMIO_BASE`;旧 legacy 0xa0000000 已移除)。

**文件**: `abstract-machine/am/include/device_address.h`(全 ISA 共用,nemu.h/npc.h 接入)、`nemu/include/device/device_address.h`(经 `device/map.h` 统一 include,设备 .c/monitor.c 用 `DEV_*`)、`npc/rv64/csrc/include/device_address.h`(utils.h 接入)、`npc/rv64/vsrc/include/define.v`。**RV32 封存**旧 0xa0000000:`-DDEVICE_MAP_LEGACY`(AM rv32 .mk)/ `CONFIG_DEVICE_MAP_LEGACY`(nemu Kconfig，riscv32-am_defconfig=y)。riscv32-ysyxsoc 走独立 SoC 路径不动。

**一致性门禁**: `Linux/scripts/check-device-address-map.sh`(三侧相等 + define.v 窗口==NPC_DEVICE_BASE)。改设备地址后必跑。

**验证**: riscv64-npc cpu-tests difftest 13 项 PASS;CoreMark `--no-diff` PASS(CRC 0xfcaf / 8 Marks)。

**关键坑(勿重蹈)**: ① timer 用 csrc 简易 RTC(经 DPI/skip_ref),**不要**改读 RTL CLINT mtime(值不确定 + 历史 `__ARCH_RISCV64_NPC` 已因此回退,见 known-issues [99])。② CoreMark 在 **difftest 开启**下读 rtc 会 out-of-bound——NEMU 参考不初始化设备 + OoO MMIO **load** 使 `skip_ref` 被更早提交指令消费(store 无此竞态);预先存在,CoreMark 按 `--no-diff` 跑分。③ MODE_SYSTEM 必须保留(门控 `src/memory` 编译 + 特权,非设备图)。相关 [[rv64core-audit-baseline]]。
