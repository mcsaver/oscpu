# NEMU RV64 Ubuntu systemd/login bring-up

## Summary

- 目标：让 `make -C Linux ARCH=riscv64-nemu run` 启动完整 Ubuntu 22.04 rootfs/systemd，并以 Linux/官方 RISC-V 语义优先于旧 PA/AM `ebreak` 退出约定。
- 结果：已在 NEMU performance 配置下到达 Ubuntu 22.04.5 login prompt。
- 关键证据：`Linux/env/logs/linux-front/riscv64-nemu-rootfs-csr-mask-fix-performance-5b.out` 出现 `Reached target Login Prompts`、`Started Serial Getty on ttyS0`、`Started Serial Getty on hvc0`、`Ubuntu 22.04.5 LTS ysyx-ubuntu2204 ttyS0` 和 `ysyx-ubuntu2204 login:`。

## Root Cause

- 原卡点不是 UART，也不是 rng-seed/systemd 缺失；rng-seed 后 `/lib/systemd/systemd` 已启动。
- debug heartbeat 显示 PC 长时间处于 Linux external interrupt path，`mip=0x220` 包含 `STIP|SEIP`。
- 同时 PLIC 统计显示 `irq2 claim=complete` 且 `level=0 pending=0 in_service=0`，说明 `SEIP` 已不是 PLIC 硬件线真实 pending。
- 根因是 NEMU CSR RMW 写回语义错误：`mip` 读值会 OR 上 PLIC 硬件 `SEIP`，旧 `CSRRS/CSRRC` 路径把 readback 的硬件 pending 整体写进 `cpu.csr.mip` 软件 shadow，造成假 SEIP 风暴。

## Changes

- `nemu/src/isa/riscv64/inst.c` / `nemu/src/isa/riscv32/inst.c`
  - 新增 mask-aware CSR 写路径，`CSR_MIP/CSR_SIP` 只更新指令真实写掩码覆盖的软件 pending 位。
  - `CSR_SIP` 的 S-mode 视图只允许写 `SSIP`；`STIP/SEIP` 继续由 M-mode/SBI 与 CLINT/PLIC 提供。
- `nemu/src/isa/riscv64/system/intr.c` / `nemu/src/isa/riscv32/system/intr.c`
  - `mip` 写入只保留 S 级软件 pending 位，机器级硬件 pending 位仍来自 CLINT/PLIC。
- `Linux/platform/npc-rv64.yml`、`nemu/configs/riscv64-linux_{,debug_}defconfig`
  - rootfs/systemd 路线内存提升到 512MiB，并保证 DTB `/memory` 与 NEMU `CONFIG_MSIZE=0x20000000` 一致。
- `nemu/src/device/disk.c`
  - virtio-blk 遵守 `VRING_AVAIL_F_NO_INTERRUPT`；本轮实测 Linux 当前队列 `avail_flags=0x0000`，所以该项是规范兼容修正，主要性能/推进收益来自 CSR pending 根因修复。

## Validation

- Build:
  - `make -C nemu ... riscv64-linux_debug_defconfig && make -C nemu ... -j4` PASS。
  - `make -C nemu ... riscv64-linux_defconfig && make -C nemu ... -j4` PASS。
  - `make -C Linux ARCH=riscv64-nemu rootfs-dtb opensbi-rootfs` PASS。
- Checks:
  - `make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-systemd` PASS。
  - `bash -n Linux/scripts/build-linux.sh Linux/scripts/build-ubuntu-rootfs.sh Linux/scripts/build-ubuntu-systemd-overlay.sh Linux/scripts/check-ubuntu-rootfs.sh` PASS。
  - `python3 -m py_compile Linux/platform/gen_dts.py` PASS。
  - `git diff --check` PASS。
- Runtime:
  - `riscv64-nemu-rootfs-csr-mask-fix-debug-500m.out`: progress `mip=0`，systemd 越过原 `Slice Units` 卡点。
  - `riscv64-nemu-rootfs-csr-mask-fix-performance-2b.out`: 到 udev/getty 设备发现。
  - `riscv64-nemu-rootfs-csr-mask-fix-performance-5b.out`: 到 `Login Prompts` 和 `ysyx-ubuntu2204 login:`。

## Remaining Boundaries

- 当前 NEMU 是可启动 Ubuntu/systemd 的最小 Linux bring-up 机器，不是 QEMU 等价完整虚拟机。
- 后续 gate：长期交互 session、UART RX 自动化输入、virtio-blk 压力/错误路径、更多设备模型与长期 rootfs 压测。
