# Task Report

## 基本信息

- `task_id`: 2026-06-15-npc-ubuntu-current-direct
- `trace_id`: manual:npc-ubuntu-current-direct
- `task_slug`: npc-ubuntu-current-direct
- `profile`: rv64-linux direct NPC slice
- `status`: pass
- `updated_at`: 2026-06-15 18:00 +0800

## 任务目标

- 推进 NPC 的完整 Ubuntu 22.04 路线，刷新 mtime 修正和 Linux/NPC 产物隔离后的当前 gate 状态。
- 不越级声明完整 root prompt；本轮目标限定为 rootfs readiness 与 NPC 340M rootfs mount + systemd banner smoke。

## 执行摘要

- `scripts/agent-e2e.sh --validate-profile --profile rv64-linux` PASS。
- 真实 `rv64-linux` profile dispatch 被 `recall-discovery` 的 untracked persistent agent/e2e source hygiene 拦截，证据在 `../2026-06-15-2026-06-15-npc-ubuntu-current-gate-baseline/`；该阻塞不是 NPC 仿真失败。
- 直接 NPC rootfs smoke 首轮复现当前 rootfs 退化：kernel 能挂载 `/dev/vda`，但 `/lib/systemd/systemd` 缺失导致 `Requested init /lib/systemd/systemd failed (error -2)`。
- 修复 `Linux/Makefile` 的 rootfs 路线契约：`BOOT=ubuntu-rootfs` run 依赖 rootfs systemd readiness；默认 `$(UBUNTU_ROOTFS_IMAGE)` 生成时启用 `UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1` 和 `UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1`，避免再次生成可挂载但不可 systemd 启动的 Ubuntu Base 镜像。
- 重建 systemd-minimal rootfs 后，`check-ubuntu-rootfs-systemd` PASS。
- 复跑 NPC 340M smoke PASS：ttyS0、virtio-blk、EXT4/VFS root、systemd PID1、Ubuntu 22.04.5 和 hostname marker 全部出现，`run.rc=0`，无 panic/Oops/Bad trap/HIT BAD TRAP。

## 关键证据

- `evidence/rebuild-systemd-rootfs/rebuild.log`: systemd overlay apt/dpkg-deb 解包 47 个包，rootfs readiness check passed。
- `evidence/rebuild-systemd-rootfs/rebuild.rc`: `0`
- `rootfs-smoke-script.start.stdout.log`: pre-fix 直接 smoke 证明旧 rootfs 缺 `/lib/systemd/systemd` 并触发 `error -2` kernel panic。
- `evidence/npc-rv64-linux-rootfs-mount-smoke-script/run.log`: run 前执行 rootfs readiness check，然后启动 NPC。
- `evidence/npc-rv64-linux-rootfs-mount-smoke-script/console.log`: 包含 Linux/rootfs/systemd/Ubuntu markers。
- `evidence/npc-rv64-linux-rootfs-mount-smoke-script/run.rc`: `0`

## 分层结论

- 已恢复 NPC 的 Ubuntu rootfs mount + systemd banner 分层 gate。
- 已补上 Makefile 防线，防止完整 rootfs 路线误用非 systemd Ubuntu Base 镜像。
- 尚未完成完整 Ubuntu 22.04 hard gate：本轮没有跑到真实 `root@ysyx-ubuntu2204:~#`，也没有出现 `__NPC_SYSTEMD_CHECK_DONE__ rc=0`。

## 下一步

- 在当前 rootfs readiness 已闭合的基础上，重新运行 `check-npc-systemd-guest` 的 1B/3B 长仿真，重点观察 systemd banner 后的 getty/root prompt、Create System Users、udev 与 guest-side injected check。
