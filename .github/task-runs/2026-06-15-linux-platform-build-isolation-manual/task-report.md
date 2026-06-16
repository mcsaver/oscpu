# Task Report

## 基本信息

- `task_id`: 2026-06-15-linux-platform-build-isolation-manual
- `trace_id`: manual:2026-06-15-linux-platform-build-isolation
- `task_slug`: linux-platform-build-isolation-manual
- `profile`: manual + rv64-linux contract
- `status`: completed
- `owner`: rv64-linux + nemu + npc
- `started_at`: 2026-06-15 16:20:00 +0800
- `updated_at`: 2026-06-15 17:20:00 +0800

## 任务目标

- 将 Linux bring-up 的 NEMU/NPC 构建、镜像、日志和 DTB 输出按平台隔离，避免同时开发时共享 `.config`、OpenSBI build、rootfs overlay 或日志。
- 保留源码、下载缓存和工具链共享，形成类似 AM 平台无关构建的 `ARCH=riscv64-<platform>` 入口。

## 结果

- `ARCH=riscv64-nemu` 默认写入 `Linux/env/platforms/nemu/{build,images,logs}` 与 `Linux/build/riscv64-nemu`。
- `ARCH=riscv64-npc` 默认写入 `Linux/env/platforms/npc/{build,images,logs}` 与 `Linux/build/riscv64-npc`。
- Linux kernel 使用 out-of-tree `O=` 构建，源码树不再保留 `.config` 或 generated include。
- OpenSBI 构建脚本会先创建 `O=` 目录，修复 OpenSBI `readlink -f $(O)` 在父目录缺失时展开为空并写向 `/platform/...` 的问题。
- 文档、平台 YAML、direct helper、Linux tools Makefile、NEMU e2e 静态路径和 rv64-linux contract 已同步。

## 验证证据

- `bash -n Linux/scripts/build-linux.sh Linux/scripts/build-opensbi.sh Linux/scripts/check-nemu-systemd-guest.sh Linux/scripts/check-npc-systemd-guest.sh Linux/scripts/profile-nemu-ubuntu.sh Linux/scripts/run-qemu-ubuntu-initramfs.sh scripts/e2e/modules/nemu.sh scripts/e2e/modules/module_contracts.sh` PASS。
- `make -C Linux ARCH=riscv64-nemu paths` 与 `make -C Linux ARCH=riscv64-npc paths` PASS，输出平台根分别为 `Linux/env/platforms/nemu` 与 `Linux/env/platforms/npc`。
- `make -C Linux ARCH=riscv64-nemu rootfs-dtb` 与 `make -C Linux ARCH=riscv64-npc rootfs-dtb` PASS，DTB 输出分别为 `Linux/build/riscv64-nemu/npc-rv64-nemu-rootfs.dtb` 与 `Linux/build/riscv64-npc/npc-rv64-rootfs.dtb`。
- `make -C Linux ARCH=riscv64-nemu opensbi-rootfs` 与 `make -C Linux ARCH=riscv64-npc opensbi-rootfs` PASS，firmware 输出分别为 `Linux/env/platforms/nemu/build/opensbi/rootfs/.../fw_jump.bin` 与 `Linux/env/platforms/npc/build/opensbi/rootfs/.../fw_jump.bin`。
- `make -C Linux ARCH=riscv64-nemu JOBS=4 linux-image` 与 `make -C Linux ARCH=riscv64-npc JOBS=4 linux-image` PASS；首次运行均完成独立 `O=` kernel build，后续增量显示 nothing to be done。
- `make -C Linux ARCH=riscv64-nemu check-nemu-kernel-config` PASS，读取 `Linux/env/platforms/nemu/build/linux/.config`。
- Linux 源码树检查 PASS：`Linux/env/src/linux/.config`、`include/generated`、`include/config/auto.conf` 均不存在。
- `make -C Linux ARCH=riscv64-nemu -n run` 展开 firmware、rootfs、overlay 与 log 均位于 `Linux/env/platforms/nemu`。
- `scripts/agent-e2e.sh --validate-profile --profile contracts` 与 `--profile rv64-linux` PASS。
- 直接执行 `e2e_rv64_linux_contract` PASS，覆盖 `Linux/scripts/platform/nemu.mk` 与 `Linux/scripts/platform/npc.mk`。

## 已知边界

- 未跑完整 NEMU Ubuntu systemd/full guest gate，也未跑 NPC rootfs/systemd 长仿真；本轮验证目标是构建、路径和 contract。
- `scripts/agent-e2e.sh --profile contracts --task-slug linux-platform-build-isolation --stop-on-fail` 被既有 untracked agent/e2e source hygiene 拦在 `recall-discovery`，详见 `.github/task-runs/2026-06-15-linux-platform-build-isolation/`；该失败与本次 Linux 构建隔离无关。
- 全局 `git diff --check` 仍会被既有历史 task-run 文本格式问题刷屏；本轮改动范围需要用 scoped diff check 判定。
