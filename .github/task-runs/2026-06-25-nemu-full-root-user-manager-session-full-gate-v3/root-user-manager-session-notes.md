# NEMU full root user-manager/session-bus notes

## Slice

- Goal slice: advance NEMU Ubuntu 22.04 full system boot from logind-managed root ttyS0 session to root user manager and root session bus coverage.
- Task run: `.github/task-runs/2026-06-25-nemu-full-root-user-manager-session-full-gate-v3/`
- Profile: `nemu-dev-full-gate`

## Root Cause

- The NEMU serial autologin drop-in could start root login before `systemd-logind.service` was fully active.
- That race produced an empty or missing root session context, then `user@0.service` and `session-c1.scope` could time out.
- A timed-out first login also left a failed `session-*.scope`, which polluted the later `systemd --failed` gate even after the second autologin succeeded.

## Changes

- `Linux/scripts/build-ubuntu-rootfs.sh`
  - NEMU serial autologin now has `Wants=systemd-logind.service`.
  - NEMU serial autologin now waits after `systemd-logind.service systemd-user-sessions.service plymouth-quit-wait.service getty-pre.target rc-local.service`.
  - NPC early-login behavior remains on the previous early ordering.
- `Linux/scripts/check-ubuntu-rootfs.sh`
  - Full rootfs readiness verifies the NEMU serial-getty logind ordering.
- `Linux/scripts/check-nemu-systemd-guest.sh`
  - Resets only stale failed `session-*.scope` units before the `systemd-running` gate.
  - Adds `full-userland-logind-root-user-manager-session`, requiring root `/run/user/0`, `user@0.service`, root user bus, root `loginctl show-user`, and a root `systemctl --user` service cgroup under `user@0.service`.
- `scripts/e2e/modules/nemu.sh` and `.github/e2e/modules/nemu.md`
  - Static/source/focused contracts now require the new cleanup, rootfs ordering, and root user-manager/session-bus markers.

## Evidence

- `bash -n Linux/scripts/build-ubuntu-rootfs.sh Linux/scripts/check-ubuntu-rootfs.sh Linux/scripts/check-nemu-systemd-guest.sh scripts/e2e/modules/nemu.sh`: PASS
- `git diff --check`: PASS
- `make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-full`: PASS after rebuilding the full rootfs, including `OK NEMU serial-getty waits for logind before autologin`.
- Static contract: `.github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/` PASS.
- Full gate: `.github/task-runs/2026-06-25-nemu-full-root-user-manager-session-full-gate-v3/task-report.md` status `completed`, all 4 nodes PASS.
- Console markers:
  - line 470: `__NEMU_CHECK_SYSTEMD_STALE_FAILED_SESSION_SCOPES__:session-c1.scope`
  - line 471: `__NEMU_CHECK_SYSTEMD_STALE_FAILED_SESSION_RESET_RC__:0`
  - line 790: `__NEMU_CHECK_FULL_LOGIND_ROOT_USER_BUSCTL_HAS_SYSTEMD__:1`
  - line 797: `__NEMU_CHECK_FULL_LOGIND_ROOT_USER_SERVICE_CGROUP_OK__:1`
  - line 827: `__NEMU_CHECK_PASS__:full-userland-logind-root-user-manager-session`
  - line 13733: `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
  - line 13838: `HIT GOOD TRAP`
- Negative scan of the full console found no `__NEMU_CHECK_FAIL__`, BAD TRAP, panic, Oops, SIGILL, illegal instruction, unhandled signal, I/O error, or budget stop.
- Residual process scan found no real `riscv64-nemu`, `agent-e2e`, or `check-nemu-systemd` process.

## Boundaries

- This proves the root serial login now reaches a logind-backed root user manager and root session bus in the NEMU full Ubuntu gate.
- It does not claim GNOME/desktop session, display manager, Wayland/Xorg, DRM/GPU, input seat, external mirrors, long-duration performance signoff, SMP/PCI/snapshot, QEMU equivalence, or the whole Ubuntu 22.04 goal is complete.
