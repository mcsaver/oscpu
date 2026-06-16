# Dispatch Log

## 2026-06-15 17:25 +0800

- `rv64-linux` profile validation PASS.
- Full profile dispatch blocked at `recall-discovery` because persistent agent/e2e source files are untracked. The generated report is retained in `../2026-06-15-2026-06-15-npc-ubuntu-current-gate-baseline/`.

## 2026-06-15 17:31 +0800

- Direct NPC rootfs smoke started after profile block.
- Initial wrapper attempts exposed a relative `LOG_DIR` issue in the manual command; the stray artifacts were discarded.

## 2026-06-15 17:37 +0800

- Direct smoke reached Linux root mount but panicked at PID1: `/lib/systemd/systemd` missing from the current ext4 image.
- `debugfs` confirmed `/lib/systemd/systemd` was absent in `Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64.ext4`.

## 2026-06-15 17:41 +0800

- Rebuilt systemd-minimal rootfs with `UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1` and `UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1`.
- Rebuild completed with `rebuild.rc=0`; readiness check passed.

## 2026-06-15 17:45 +0800

- Reran NPC 340M rootfs mount + systemd banner smoke.
- Smoke completed with `run.rc=0` and all marker assertions passing.
