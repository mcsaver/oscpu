# Task Report: rv64-systemd-guest-check-contract-manual

- status: PASS
- profile: rv64-linux
- task_slug: rv64-systemd-guest-check-contract-manual
- date: 2026-06-12

## Summary

NPC RV64 Ubuntu rootfs bring-up now has a NEMU-style hard gate entry for the next milestone: `make check-npc-systemd-guest`.

The new gate waits for the serial root prompt `root@ysyx-ubuntu2204:~#`, releases `NPC_UART_RX_FILE` only after that prompt is visible, injects a guest-side check script, and waits for `NPC_GUEST_EXPECT="__NPC_SYSTEMD_CHECK_DONE__ rc=0"`.

This is a contract/entrypoint step, not a claim that NPC already reaches the full Ubuntu shell. The latest long run evidence still reaches real systemd PID1 and the Ubuntu 22.04 banner, but not the root prompt.

## Changes

- Added `Linux/scripts/check-npc-systemd-guest.sh`.
- Added `Linux/Makefile` target `check-npc-systemd-guest` and internal `__check-npc-systemd-guest`.
- Added `e2e_npc_rv64_systemd_guest_check_contract` to `scripts/e2e/modules/npc.sh`.
- Added `npc-rv64-systemd-guest-check-contract` to `.github/e2e/profiles/rv64-linux.tsv`.

## Guest Checks

The injected guest script checks:

- `uname -m` is `riscv64`.
- `/etc/os-release` reports Ubuntu 22.04.
- the shell is running as root.
- `/bin/sh` and `/bin/bash` exist.
- `systemctl is-system-running` reports `running`, `degraded`, `starting`, or `initializing`.
- the final marker is `__NPC_SYSTEMD_CHECK_DONE__ rc=0`.

## Validation

- `bash -n Linux/scripts/check-npc-systemd-guest.sh scripts/e2e/modules/npc.sh`: PASS.
- `scripts/agent-e2e.sh --validate-profile --profile rv64-linux`: PASS, expanded to 10 nodes.
- Manual contract function `e2e_npc_rv64_systemd_guest_check_contract`: PASS.
- Makefile prompt expansion checked as `NPC_SYSTEMD_PROMPT = root@ysyx-ubuntu2204:~#`.

## Evidence

- `evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log`

## Boundary

The full `make check-npc-systemd-guest` runtime gate is expected to remain failing until NPC naturally reaches `root@ysyx-ubuntu2204:~#`. That failure is now intentional and useful: it is the next hard line to drive the RTL and platform work against.
