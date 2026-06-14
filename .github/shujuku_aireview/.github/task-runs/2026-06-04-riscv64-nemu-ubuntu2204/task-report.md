# 2026-06-04 RISC-V64 NEMU Ubuntu 22.04 task report

## 结论

NEMU 的 RV64 Linux 路线已从 Ubuntu 22.04 initramfs gate 推进到完整 ext4 rootfs gate。`ARCH=riscv64-nemu BOOT=ubuntu-rootfs` 能通过 virtio-mmio block 暴露 `/dev/vda`，Linux 挂载 ext4 rootfs 后执行 rootfs 内 `/init`，官方 Ubuntu `/bin/sh -c` marker 返回 0，并进入 `/bin/sh` prompt。

后续入口语义已对齐到 NPC 用法：`make -C Linux ARCH=riscv64-nemu run` 默认就是完整 Ubuntu rootfs 路线，不再需要手动补 `BOOT=ubuntu-rootfs`、no-PMU OpenSBI build dir 或 `--block` 参数。默认 `MAX_CYCLES=0` 表示 NEMU 无限预算；历史 `MAX_CYCLES=8000000000` 只是自动 gate 为了在 shell 驻留后返回而使用的上限。

## 已闭合问题

- `riscv64` 日志路径不再落到 `src/isa/riscv32`。
- `ubuntu-shell` 打完 `uname -a` 后卡住的问题已定位并修复：根因是 PLIC 没有 level/in-service re-pend，导致 UART THRE 中断在 tty write 路径中丢失。
- NEMU `--block` 不再是占位参数；现在会 attach host ext4 image，并由 virtio-blk 后端处理 Linux block request。
- Rootfs DTB 中的 `virtio_mmio@10001000` 与 NEMU MMIO 设备、PLIC IRQ2 已对齐。

## 验收证据

- `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j4` PASS。
- `ubuntu-shell` clean gate：
  - `PRETTY_NAME="Ubuntu 22.04.5 LTS"`
  - `[ysyx-sh] /bin/sh -c marker`
  - `[ysyx-init] /bin/sh -c exit=0`
  - `/bin/sh` prompt
- `ubuntu-rootfs` gate：
  - `virtio_blk virtio0: [vda] 4194304 512-byte logical blocks (2.15 GB/2.00 GiB)`
  - `EXT4-fs (vda): mounted filesystem ... r/w`
  - `VFS: Mounted root (ext4 filesystem) on device 254:0`
  - `[ysyx-rootfs-sh] /bin/sh -c marker`
  - `[ysyx-rootfs] /bin/sh -c exit=0`
  - `/bin/sh` prompt
- 顶层入口对齐：
  - `make -C Linux ARCH=riscv64-nemu paths` 显示 `BOOT=ubuntu-rootfs`、`MAX_CYCLES=0`、`OPENSBI_PROFILE=nemu`、`OPENSBI_DISABLE_PMU=1`、`RUN_SIM=.../nemu/build/riscv64-nemu-interpreter`、`RUN_ROOTFS=...ubuntu-22.04-riscv64.ext4`。
  - `make -C Linux ARCH=riscv64-nemu check` PASS。
  - 短预算 smoke：`make -C Linux ARCH=riscv64-nemu MAX_CYCLES=10000000 LOG_DIR=$PWD/Linux/env/logs/linux-front/riscv64-nemu-default-entry-smoke run` 打印 OpenSBI v1.8、Linux 6.6 early boot，并确认加载 no-PMU OpenSBI、rootfs DTB 和 virtio block image。

## 后续建议

- 把 page fault/trap 预算日志改成显式调试开关，避免常规 Ubuntu run 的 console 被诊断日志穿插。
- 若要把 NEMU virtio-blk 作为长期 reference，可补 indirect descriptors、feature negotiation negative tests、multi-request pressure、read-only image、writeback/flush ordering 和 malformed descriptor 防御。
- 若要让 NEMU 更接近 QEMU 级通用机器，应先补 UART RX/TTY 交互 gate，再扩 virtio-blk 特性和长期 rootfs session 压力测试；当前 rootfs gate 不能替代这层结论。
- 若要对齐 NPC RTL rootfs，需要在 NPC 侧实现/验证同等 virtio-mmio block、IRQ2 PLIC gateway、UART THRE level interrupt re-pend，并复用本轮 NEMU 日志作为 golden bring-up 证据。
