# RV64 Systemd Banner Smoke

- date: 2026-06-12
- scope: NPC rv64core Ubuntu rootfs boot after systemd handoff
- result: PASS

## What Changed

- The existing `e2e_npc_rv64_linux_rootfs_mount_smoke` gate now requires real systemd PID1 progress beyond kernel handoff:
  - `systemd ... running in system mode`
  - `Ubuntu 22.04`
  - `Hostname set to <ysyx-ubuntu2204>`
  - `Initializing machine ID from random generator`
- The default budget for that gate is raised from 220,000,000 to 280,000,000 cycles.

## Evidence

- Runtime log directory: `Linux/env/logs/codex-npc-rootfs-prompt-probe-260m/`
- Command shape:
  - `NPC_UART_RX_FILE=/tmp/ysyx-npc-probe/prompt.cmd`
  - `NPC_UART_RX_WAIT=root@ysyx-ubuntu2204:~#`
  - `NPC_GUEST_EXPECT=__NPC_SYSTEMD_CHECK_DONE__ rc=0`
  - `MAX_CYCLES=260000000`
- Observed console markers:
  - `Run /lib/systemd/systemd as init process`
  - `systemd 249.11-0ubuntu3.21 running in system mode`
  - `Welcome to Ubuntu 22.04.5 LTS`
  - `Hostname set to <ysyx-ubuntu2204>`
  - `Initializing machine ID from random generator`
- Assertion replay:
  - `bash -n scripts/e2e/modules/npc.sh`
  - upgraded rootfs/systemd banner greps PASS on `Linux/env/logs/codex-npc-rootfs-prompt-probe-260m/console.log`

## Limits

- The prompt wait did not release UART input in this run; `root@ysyx-ubuntu2204:~#` was not reached within 260,000,000 cycles.
- This proves systemd PID1 and Ubuntu banner execution on NPC, not full login shell or the NEMU full guest script gate.
