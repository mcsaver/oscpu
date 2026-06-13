# Task Report: RV64 NPC systemd 1.4B late ecall probe

- **status**: partial
- **profile**: rv64-linux
- **task_slug**: rv64-npc-systemd-1400m-late-ecall
- **started_at**: 2026-06-12
- **updated_at**: 2026-06-12

## Summary

Ran the NPC RV64 Ubuntu 22.04 systemd hard gate to 1.4B cycles with late-start U-mode syscall tracing:

```sh
NPC_USER_TRACE_MIN_COMMIT=90000000
NPC_USER_PROGRESS_INTERVAL=20000000
NPC_USER_ECALL_TRACE=1
NPC_USER_ECALL_MIN_COMMIT=520000000
NPC_USER_ECALL_TRACE_LIMIT=768
NPC_SYSTEMD_CHECK_MAX_CYCLES=1400000000
```

The run did not reach the root prompt or guest completion marker, but it advanced beyond the prior 1.2B evidence into later systemd module/remount/udev work. No guest panic, Oops, bad trap, HIT BAD TRAP, or BUG signature was observed.

## Runtime Evidence

- Evidence directory: `Linux/env/logs/codex-npc-systemd-guest-late-ecall-1400m`
- `run.rc=2`, caused by the prompt gate failing after max-cycle abort.
- Stats: cycles=1400000000, commits=694241161, CPI=2.017, CLINT mtime=1400000000 with mtime-cycles match.
- Missing: real `root@ysyx-ubuntu2204:~#` prompt and `__NPC_SYSTEMD_CHECK_DONE__ rc=0`.
- The root prompt string only appears in harness wait configuration and waiting logs.
- Final abort PC: `0xffffffff80231694`, symbolized near kernel `elv_rb_del`; last commits are in the block I/O scheduler / mq-deadline path.

## Console Progress

Compared with the 1.2B run, this run continued through:

- `Starting Load Kernel Modules...`
- `Starting Remount Root and Kernel File Systems...`
- `Starting Coldplug All udev Devices...`
- `Mounted POSIX Message Queue File System.`
- `Finished Load Kernel Module configfs.`
- `modprobe@drm.service: Deactivated successfully.`

The system still did not reach a login/root shell prompt before the cycle budget expired.

## Late Ecall Trace

- First late U-mode ecall: commit=521319467, syscall=278.
- Last recorded ecall before trace quota exhaustion: commit=555280046, syscall=35.
- Trace count: 768 records.
- Top syscall IDs:
  - 29: 371
  - 79: 240
  - 63: 36
  - 278: 32
  - 57: 29
  - 56: 29

This confirms `NPC_USER_ECALL_MIN_COMMIT` works, but 520M is still early enough that the 768-record quota is consumed before the latest 650M+ systemd/remount/udev region.

## Next Step

Move the late ecall window further forward, for example:

```sh
NPC_USER_ECALL_MIN_COMMIT=620000000
NPC_USER_ECALL_TRACE_LIMIT=2048
NPC_SYSTEMD_CHECK_MAX_CYCLES=1600000000
```

That should capture remount/udev/getty-era syscalls rather than the 521M to 555M module/config probing region.
