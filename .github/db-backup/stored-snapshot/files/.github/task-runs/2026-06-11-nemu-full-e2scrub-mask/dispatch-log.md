# Dispatch Log

| time | node_id | status | owner | module | action | evidence | next |
| ---- | ------- | ------ | ----- | ------ | ------ | -------- | ---- |
| 2026-06-11 03:29:26 +0800 | `run-full-profile-initial` | FAIL | agent-system | nemu | Ran `nemu-ubuntu-full-gate` with `AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1`; full focused node failed with exit 2. | `.github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run/` | Inspect guest console fail markers. |
| 2026-06-11 03:46:40 +0800 | `localize-systemd-blocker` | PASS | nemu | linux-device | Found systemd stuck in `starting` because `e2scrub_reap.service` kept `multi-user.target` waiting. | `.github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run/nemu-ubuntu-full-focused/console.log` | Mask NEMU-unsuitable maintenance unit in rootfs production. |
| 2026-06-11 03:51:35 +0800 | `fix-rootfs-production` | PASS | nemu | linux-device | Added rootfs production masks and readiness checks for `e2scrub_reap.service` and `e2scrub_all.timer`. | `Linux/scripts/build-ubuntu-rootfs.sh`, `Linux/scripts/build-ubuntu-systemd-overlay.sh`, `Linux/scripts/check-ubuntu-rootfs.sh` | Rebuild full rootfs. |
| 2026-06-11 03:54:20 +0800 | `rebuild-full-rootfs` | PASS | nemu | linux-device | Rebuilt full rootfs and checked mask readiness. | `evidence/full-rootfs-rebuild.log`, `evidence/full-rootfs-check-after-mask.log` | Rerun full E2E profile. |
| 2026-06-11 04:08:36 +0800 | `rerun-full-profile` | PASS | agent-system | nemu | Reran `nemu-ubuntu-full-gate` with full gate enabled; all nodes PASS. | `.github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/` | Update memory and stage focused evidence. |
