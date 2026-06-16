# Task Report: RV64 NPC systemd 1.6B late ecall probe

- **status**: partial
- **profile**: rv64-linux
- **task_slug**: rv64-npc-systemd-1600m-late-ecall
- **started_at**: 2026-06-12
- **updated_at**: 2026-06-12

## Summary

Ran the NPC RV64 Ubuntu 22.04 systemd hard gate to 1.6B cycles with a later U-mode syscall trace window:

```sh
NPC_USER_TRACE_MIN_COMMIT=90000000
NPC_USER_PROGRESS_INTERVAL=20000000
NPC_USER_PROGRESS_LIMIT=256
NPC_USER_ECALL_TRACE=1
NPC_USER_ECALL_MIN_COMMIT=620000000
NPC_USER_ECALL_TRACE_LIMIT=2048
NPC_SYSTEMD_CHECK_MAX_CYCLES=1600000000
NPC_SYSTEMD_HOST_TIMEOUT=9000
```

The run still did not reach the real `root@ysyx-ubuntu2204:~#` prompt or `__NPC_SYSTEMD_CHECK_DONE__ rc=0`, so the full Ubuntu/NEMU-equivalent gate remains incomplete. It did continue beyond the 1.4B evidence through later module completion, rootfs remount, and kernel-variable application startup. No guest panic, Oops, bad trap, HIT BAD TRAP, or BUG signature was observed.

## Runtime Evidence

- Evidence directory: `Linux/env/logs/codex-npc-systemd-guest-late-ecall-1600m`
- `run.rc=2`, caused by the prompt gate failing after max-cycle abort.
- Stats: cycles=1600000000, commits=784942063, CPI=2.038, CLINT mtime=1600000000 with mtime-cycles match.
- Simulation frequency: 213763 inst/s.
- Missing: real `root@ysyx-ubuntu2204:~#` prompt and `__NPC_SYSTEMD_CHECK_DONE__ rc=0`.
- The root prompt string only appears in UART wait configuration and waiting logs.
- Final abort PC: `0xffffffff800f13a2`, symbolized with `Linux/env/src/linux/vmlinux` as kernel `unmap_page_range`.

## Console Progress

Compared with the 1.4B run, this run continued through:

- `Finished Load Kernel Module drm.`
- `Finished Load Kernel Module fuse.`
- `Finished Load Kernel Modules.`
- `EXT4-fs (vda): re-mounted ... r/w.`
- `Starting Apply Kernel Variables...`

The system still did not reach a login/root shell prompt before the cycle budget expired.

## Late Ecall Trace

- First late U-mode ecall: `trap_hit=1`, commit=620127547, syscall=57.
- Last recorded ecall before trace quota exhaustion: `trap_hit=2048`, commit=682976162, syscall=57.
- Trace count: 2048 records.
- Top syscall IDs:
  - 56: 338
  - 79: 247
  - 57: 219
  - 63: 210
  - 167: 188
  - 222: 159
  - 226: 84
  - 29: 80
  - 261: 71

This confirms the later `NPC_USER_ECALL_MIN_COMMIT=620000000` window works and captures a different systemd/userland phase than the 520M window. The trace still fills by 682976162 commits, before the final 784942063-commit max-cycle stop.

## Interpretation

The latest stop is a cycle-budget stop in kernel page unmap work, not a known bad trap or panic. The console and syscall evidence point to continued systemd initialization after module loading and rootfs remount. The next useful window should move past the 683M commit trace exhaustion point instead of repeating the same syscall region.

## Next Step

Run a longer prompt gate and shift the ecall window forward:

```sh
NPC_SYSTEMD_CHECK_MAX_CYCLES=2000000000
NPC_USER_ECALL_MIN_COMMIT=700000000
NPC_USER_ECALL_TRACE_LIMIT=4096
```

This should cover the 683M+ commit region and either reach the root prompt or identify the next concrete userspace/kernel phase before getty/login.
