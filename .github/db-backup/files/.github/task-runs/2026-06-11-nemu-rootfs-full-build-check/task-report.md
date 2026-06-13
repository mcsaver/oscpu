# Task Report

## 基本信息

- `task_id`: 2026-06-11-nemu-rootfs-full-build-check
- `task_slug`: nemu-rootfs-full-build-check
- `graph_template`: rv64-ubuntu-rootfs-loop
- `profile`: manual-rootfs-full-build-check
- `status`: completed
- `owner`: nemu + rv64-linux

## 任务目标

- 将 `full` Ubuntu 22.04 rootfs 从 dry-run 入口推进到实物 ext4/cpio 生成与 rootfs readiness 检查证据。
- 保持 gate 分层：本任务只证明 full rootfs 实物存在并通过静态 debugfs 检查，不证明 full guest 已在 NEMU 中启动或长跑通过。

## 关键证据

- `evidence/full-rootfs-build.log`: `make -C Linux ARCH=riscv64-nemu ubuntu-rootfs-full-image` 下载并解包 full flavor 相关包，生成 `ubuntu-22.04-riscv64-full.ext4` 和 `ubuntu-22.04-riscv64-full-rootfs.cpio`；首次检查阶段暴露 `ping` 实物路径假设错误。
- `evidence/full-rootfs-check.log`: 修正 manifest 后，`make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-full` PASS，检查到 systemd、udev、dbus、lsb_release、curl、wget、`/bin/ping`、ssh、htop、less、strace、apt-get、sudo、man、sshd、cron、rsyslogd 和 timezone database。
- `evidence/full-rootfs-artifacts.stat`: full ext4 为 8589934592 bytes，full cpio 为 263651840 bytes；默认 `ubuntu-22.04-riscv64.ext4` 仍为 2147483648 bytes，说明 full 构建没有覆盖默认 minimized/systemd 镜像。

## 收尾结论

- full rootfs 实物已生成并通过 `check-ubuntu-rootfs-full`。
- 本轮根因修复：Ubuntu jammy/riscv64 `iputils-ping` 在当前 rootfs 中提供 `/bin/ping`，不是 `/usr/bin/ping`；`ubuntu-rootfs-flavors.sh` 已改为检查 `/bin/ping`，`nemu-ubuntu` slice contract 已追踪该路径。
- 剩余边界：尚未运行 `check-nemu-systemd-guest-full`，因此不能声明 full rootfs 已在 NEMU guest 中完整启动或长期稳定。
