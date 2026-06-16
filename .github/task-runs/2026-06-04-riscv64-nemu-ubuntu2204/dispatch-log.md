# 2026-06-04 RISC-V64 NEMU Ubuntu 22.04 dispatch log

## 目标

- 让 `ARCH=riscv64-nemu` 不再停留在轻量 probe/initramfs 阶段，而是能启动 Ubuntu 22.04 官方用户态，并继续推进到完整 ext4 rootfs。
- 将用户指出的 `src/isa/riscv32/...` 日志路径拆成独立 `src/isa/riscv64` ISA 目录。
- 对 “打印完 `/etc/os-release` / `uname -a` 后长时间不动” 做 root cause 定位，而不是绕过症状。

## 调用链与根因

- NEMU 旧结构：
  - `src/isa/filelist.mk` 把 `GUEST_ISA=riscv64` 映射到 `src/isa/riscv32`，所以 RV64 Linux 日志仍显示 `src/isa/riscv32/...`。
  - `--block/--disk` 在 `monitor.c` 中只保存路径并打印占位日志，设备层没有 virtio-blk 后端。
- Ubuntu shell 卡点：
  - `ubuntu-shell` 已能进入 `/init`，打印 Ubuntu 22.04 os-release 和 `uname -a`。
  - syscall 诊断显示 `/bin/uname` 已发出 `write(1, ..., 85)`，但预算耗尽时仍在内核 `write` 路径，没有返回父 shell。
  - 用户态 PC 采样没有出现，说明并非 `/bin/uname` 用户态死循环。
  - 根因收敛到 UART/PLIC：16550 THRE 是电平型中断，NEMU PLIC 原先只保存 `pending`，claim 清 pending 后没有保存 line level 和 in-service 状态；Linux 8250 driver complete 后如果 THRE 线仍高，需要重新 pending，否则 tty write 可能等不到下一次 TX-empty 唤醒。
- rootfs 缺口：
  - DTB 已描述 `virtio_mmio@10001000`，但 NEMU 未实现设备。
  - Linux rootfs 需要 `/dev/vda` 可读写，至少要实现 modern virtio-mmio block 的单队列 read/write/flush 和 used-buffer IRQ。

## 修改记录

- `Linux/Makefile`
  - 对齐 NPC 用法：`ARCH=riscv64-nemu` 默认仍走 `BOOT=ubuntu-rootfs`，并自动选择 NEMU sim、rootfs DTB、ext4 block image。
  - 新增 `OPENSBI_PROFILE`，NEMU 默认使用 `opensbi-nemu-*` build dir，避免与 NPC 普通 OpenSBI 产物混用。
  - NEMU 默认 `OPENSBI_DISABLE_PMU=1`，把此前手写的 no-PMU 参数收进入口契约。
  - NEMU 默认 `MAX_CYCLES=0`，保留无限预算启动语义；需要可返回 gate 时显式传上限。
- `nemu/src/isa/filelist.mk`
  - 移除 `riscv64 -> riscv32` 的源目录映射，`ISA_SRC_DIR := $(GUEST_ISA)`。
- `nemu/src/isa/riscv64/`
  - 从当前 RV64-capable `riscv32` ISA 源复制出独立目录，后续 RV64 Linux 日志显示 `src/isa/riscv64/...`。
- `nemu/src/isa/riscv32/inst.c`、`nemu/src/isa/riscv64/inst.c`
  - load/FP load 发生 page fault 后不再写 rd/FPR。
  - AMO/LR/SC 发生 page fault 后不再更新 rd/reservation/内存。
- `nemu/src/memory/vaddr.c`、`nemu/include/memory/vaddr.h`
  - 新增 `vaddr_has_fault()`。
  - 跨页 store 先翻译所有字节地址，任一 fault 时整条 store 不产生部分写入。
- `nemu/src/isa/{riscv32,riscv64}/system/plic.c`
  - PLIC source 数扩到 32。
  - 增加 `plic_level` 和 `plic_in_service`。
  - claim 清 pending 并置 in-service。
  - complete 清 in-service；若 source level 仍高则重新置 pending。
- `nemu/src/monitor/monitor.c`
  - `--block/--disk` 调用 `disk_set_image()` 传入设备层，不再只是占位说明。
- `nemu/src/device/disk.c`
  - 新增最小 virtio-mmio block 后端。
  - 支持 modern virtio-mmio v2、device id 2、`VIRTIO_F_VERSION_1`、单队列、512B sector capacity。
  - 支持 `VIRTIO_BLK_T_IN/OUT/FLUSH/GET_ID`，写 used ring 并通过 PLIC IRQ2 通知。
- `nemu/configs/riscv64-linux_defconfig`
  - 打开 `CONFIG_HAS_DISK=y`。
  - 设置 `CONFIG_DISK_CTL_MMIO=0x10001000`。

## 验证记录

- 构建：
  - `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j4` PASS。
- Ubuntu shell initramfs clean gate：
  - 命令：`make -C Linux ARCH=riscv64-nemu BOOT=ubuntu-shell OPENSBI_DISABLE_PMU=1 OPENSBI_UBUNTU_SHELL_BUILD_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/build/opensbi-npc-ubuntu-shell-nopmu LOG_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-ubuntu-shell-plic-level-clean-6b MAX_CYCLES=6000000000 run`
  - 证据日志：`Linux/env/logs/linux-front/riscv64-nemu-ubuntu-shell-plic-level-clean-6b/console.log`
  - 关键输出：`PRETTY_NAME="Ubuntu 22.04.5 LTS"`、`Linux (none) ... riscv64 GNU/Linux`、`[ysyx-sh] /bin/sh -c marker`、`[ysyx-init] /bin/sh -c exit=0`、`#` prompt。
- Ubuntu rootfs virtio gate：
  - 命令：`make -C Linux ARCH=riscv64-nemu BOOT=ubuntu-rootfs OPENSBI_DISABLE_PMU=1 OPENSBI_ROOTFS_BUILD_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/build/opensbi-npc-rootfs-nopmu LOG_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-ubuntu-rootfs-virtio-8b MAX_CYCLES=8000000000 run`
  - 证据日志：`Linux/env/logs/linux-front/riscv64-nemu-ubuntu-rootfs-virtio-8b/console.log`
  - 关键输出：`virtio_blk virtio0: [vda] 4194304 512-byte logical blocks`、`EXT4-fs (vda): mounted`、`VFS: Mounted root (ext4 filesystem) on device 254:0`、`[ysyx-rootfs] Ubuntu 22.04 rootfs reached`、`[ysyx-rootfs-sh] /bin/sh -c marker`、`[ysyx-rootfs] /bin/sh -c exit=0`、`#` prompt。
- 顶层默认入口 smoke：
  - `make -C Linux ARCH=riscv64-nemu paths` 确认默认 `BOOT=ubuntu-rootfs`、`MAX_CYCLES=0`、`OPENSBI_PROFILE=nemu`、`OPENSBI_DISABLE_PMU=1`、`RUN_SIM=/home/lyg/PA/ysyx-workbench/nemu/build/riscv64-nemu-interpreter`、`RUN_FW=/home/lyg/PA/ysyx-workbench/Linux/env/build/opensbi-nemu-rootfs/platform/generic/firmware/fw_jump.bin`、`RUN_ROOTFS=/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64.ext4`。
  - `make -C Linux ARCH=riscv64-nemu prepare` PASS，并构建 `opensbi-nemu-rootfs` no-PMU firmware。
  - `make -C Linux ARCH=riscv64-nemu check` PASS。
  - `make -C Linux ARCH=riscv64-nemu MAX_CYCLES=10000000 LOG_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-default-entry-smoke run` PASS，日志显示 OpenSBI v1.8、Linux 6.6 early boot、`Block image requested`、`virtio-blk: image=...ubuntu-22.04-riscv64.ext4`。

## 边界

- NEMU virtio-blk 是 rootfs bring-up 的最小功能模型，不覆盖完整 virtio feature set、多队列、discard/write-zeroes/config change、barrier ordering 或 DMA/cache coherency 压力。
- PLIC 仍是单 hart/最小 source 模型；本轮只补了 level/in-service/IRQ2 足够支撑 UART 与 virtio。
- 默认 `make ARCH=riscv64-nemu run` 是“启动完整 rootfs 路线”，不是 QEMU 级完整交互虚拟机；UART RX/TTY 输入、完整 virtio 特性和长期多设备压力仍未闭合。
- 当前日志中 page fault/trap 诊断仍会按既有 budget 打印，属于调试可见性，不代表 guest panic。
