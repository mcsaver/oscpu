# Task Report

## 基本信息

- `task_id`: 2026-06-11-nemu-full-e2scrub-mask
- `task_slug`: nemu-full-e2scrub-mask
- `graph_template`: regression-debug-loop + modular-agent-e2e
- `profile`: nemu-ubuntu-full-gate
- `graph_mode`: dynamic
- `status`: completed
- `owner`: nemu + linux-device + agent-system
- `started_at`: 2026-06-11 03:46:40 +0800
- `updated_at`: 2026-06-11 04:08:36 +0800

## 任务目标

- `source_request`: 通过新 `nemu-ubuntu-full-gate` profile 真实运行 full Ubuntu 22.04 rootfs focused gate。
- `goal`: 定位并修复 full profile 首次真实运行失败，让 profile 能承载 `check-nemu-systemd-guest-full` 的 PASS 证据。
- `scope`: NEMU full rootfs 的 systemd boot-blocking service 修复；不声明 QEMU 等价、SMP/PCI/TAP/NAT/snapshot、桌面 Ubuntu 或长期 soak。

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
| `run-full-profile-initial` | `agent-system` | `nemu` | `FAIL` | `AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate` | full focused node failed with guest rc=1 | `.github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run/` |
| `localize-systemd-blocker` | `nemu` | `linux-device` | `PASS` | initial console/log | `e2scrub_reap.service` kept systemd in `starting`; `multi-user.target` inactive | `.github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run/nemu-ubuntu-full-focused/console.log` |
| `fix-rootfs-production` | `nemu` | `linux-device` | `PASS` | rootfs build scripts and readiness check | full rootfs masks `e2scrub_reap.service` and `e2scrub_all.timer` while keeping e2fsprogs tools | `Linux/scripts/build-ubuntu-rootfs.sh`, `Linux/scripts/build-ubuntu-systemd-overlay.sh`, `Linux/scripts/check-ubuntu-rootfs.sh` |
| `rebuild-full-rootfs` | `nemu` | `linux-device` | `PASS` | `make -C Linux ARCH=riscv64-nemu ubuntu-rootfs-full-image` | full ext4 rebuilt and readiness passed | `evidence/full-rootfs-rebuild.log` |
| `rerun-full-profile` | `agent-system` | `nemu` | `PASS` | `AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate` | full focused gate PASS through profile | `.github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/` |

## 根因

full rootfs 包含 `e2scrub_reap.service`，该 unit 由 `multi-user.target.wants` 启动，用于清理 ext4 在线 metadata check snapshot。它不是 NEMU Ubuntu bring-up 的必要用户态能力，但在慢速 NEMU guest 中会长时间运行，导致 `systemctl is-system-running` 保持 `starting`，`multi-user.target` 仍为 `inactive`。首次 profile 失败的 console 证据包含 `e2scrub_reap.service start running`、`__NEMU_CHECK_FAIL__:systemd-running`、`__NEMU_CHECK_FAIL__:systemd-jobs`、`__NEMU_CHECK_FAIL__:systemd-target-multi-user.target`。

## 修复

- `build-ubuntu-rootfs.sh` 和 `build-ubuntu-systemd-overlay.sh` 在 rootfs 生产阶段把 `e2scrub_reap.service` 与 `e2scrub_all.timer` mask 到 `/dev/null`。
- `check-ubuntu-rootfs.sh` 新增 `rootfs_symlink_points_to()`，严格检查这两个 mask 存在；保留 `/sbin/e2scrub_all` 工具入口检查。
- `scripts/e2e/modules/nemu.sh` 和 `.github/e2e/modules/nemu.md` 追踪 mask hook 和 readiness marker，避免只在十几分钟 full focused gate 中才暴露回归。

## 验证

- `bash -n Linux/scripts/build-ubuntu-rootfs.sh Linux/scripts/build-ubuntu-systemd-overlay.sh Linux/scripts/check-ubuntu-rootfs.sh scripts/e2e/modules/nemu.sh scripts/agent-e2e.sh` PASS。
- `make -C Linux ARCH=riscv64-nemu ubuntu-rootfs-full-image` PASS；`full-rootfs-rebuild.log` 含 `OK boot-blocking e2scrub reap masked`、`OK periodic e2scrub timer masked` 和 `rootfs readiness check passed`。
- `AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate --task-slug nemu-ubuntu-full-gate-real-run-after-e2scrub-mask` PASS。
- 最终 full console 含 `__NEMU_CHECK_SYSTEMD_STATE__:running`、`__NEMU_CHECK_PASS__:systemd-running`、`__NEMU_CHECK_PASS__:systemd-jobs`、`__NEMU_CHECK_PASS__:systemd-target-multi-user.target`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 和 `HIT GOOD TRAP`。
- 负向检索最终 console/NEMU log 中 `__NEMU_CHECK_FAIL__`、`Module is unknown`、`unhandled signal`、`illegal instruction`、`sigill` 无命中。

## 收尾结论

- `final_result`: full rootfs focused gate 已通过 `nemu-ubuntu-full-gate` profile 真实 PASS。
- `evidence_summary`: 初始失败证据、rootfs rebuild/check、最终 profile PASS 证据均已落盘。
- `notes`: 该修复只禁用 boot-blocking 维护 unit；不删除 e2fsprogs 工具本体，也不把 full focused gate 越界声明为完整 VM/QEMU 等价或长期稳定性签核。
