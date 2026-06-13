# Task Report: RV64 NPC systemd 2.0B late ecall probe

- **status**: partial
- **profile**: rv64-linux
- **task_slug**: rv64-npc-systemd-2000m-late-ecall
- **started_at**: 2026-06-12
- **updated_at**: 2026-06-12

## Summary

Ran the NPC RV64 Ubuntu 22.04 systemd hard gate to 2.0B cycles with a later U-mode syscall trace window:

```sh
NPC_USER_TRACE_MIN_COMMIT=90000000
NPC_USER_PROGRESS_INTERVAL=20000000
NPC_USER_PROGRESS_LIMIT=256
NPC_USER_ECALL_TRACE=1
NPC_USER_ECALL_MIN_COMMIT=700000000
NPC_USER_ECALL_TRACE_LIMIT=4096
NPC_SYSTEMD_CHECK_MAX_CYCLES=2000000000
NPC_SYSTEMD_HOST_TIMEOUT=12000
```

The full Ubuntu/NEMU-equivalent gate remains incomplete: the real `root@ysyx-ubuntu2204:~#` prompt did not appear and `__NPC_SYSTEMD_CHECK_DONE__ rc=0` was not printed. The run nevertheless advanced past the 1.6B evidence into later systemd work, including create-users, random-seed completion, journal service start, and `/dev/ttyS0` start-job timing.

No guest panic, Oops, bad trap, HIT BAD TRAP, or BUG signature was observed.

## Runtime Evidence

- Wrapper evidence directory: `Linux/env/logs/codex-npc-systemd-guest-late-ecall-2000m`
- Inner script log directory for this run: `Linux/env/logs/linux-front/riscv64-npc-systemd-guest-check`
- `run.rc=1`, because the hard gate did not reach the root prompt; the inner NPC run itself ended with rc=0.
- Stats: cycles=2000000000, commits=953336113, CPI=2.098, CLINT mtime=2000000000 with mtime-cycles match.
- Simulation frequency: 201240 inst/s.
- Missing: real `root@ysyx-ubuntu2204:~#` prompt and `__NPC_SYSTEMD_CHECK_DONE__ rc=0`.
- Prompt string count is 3, all from harness configuration/waiting text.
- Final PC: `0xffffffff80119d48`, symbolized with `Linux/env/src/linux/vmlinux` as `___slab_alloc`.

## Harness Fix

This run was launched by calling `Linux/scripts/check-npc-systemd-guest.sh` directly while setting `NPC_SYSTEMD_CHECK_LOG_DIR`. The script only honored `LOG_DIR`, so its inner log directory fell back to the default even though the wrapper captured stdout in the intended directory.

Fixed after the run:

```sh
LOG_DIR=${LOG_DIR:-${NPC_SYSTEMD_CHECK_LOG_DIR:-...}}
```

The e2e contract now also checks that `NPC_SYSTEMD_CHECK_LOG_DIR` is present in the script.

## Console Progress

Compared with the 1.6B run, this run continued through:

- `Finished Remount Root and Kernel File Systems.`
- `Starting Load/Save Random Seed...`
- `Starting Create System Users...`
- `Finished Apply Kernel Variables.`
- `Finished Load/Save Random Seed.`
- `Started Journal Service.`
- `Starting Flush Journal to Persistent Storage...`
- start-job timing for `/dev/ttyS0`, `udev Devices`, and `Create System Users`.

The system still did not reach a login/root shell prompt before the cycle budget expired.

## Late Ecall Trace

- First late U-mode ecall: `trap_hit=1`, commit=700029763, syscall=79.
- Last recorded ecall before trace quota exhaustion: `trap_hit=4096`, commit=790151661, syscall=57.
- Trace count: 4096 records.
- Top syscall IDs:
  - 56: 872
  - 79: 745
  - 57: 560
  - 134: 488
  - 222: 267
  - 63: 170
  - 29: 113
  - 167: 102
  - 226: 86
  - 78: 79

The 700M window captures a later phase than the 620M window, but it still fills before the final 953336113-commit max-cycle stop.

## Interpretation

The final stop is a cycle-budget stop in slab allocation/spinlock work, not a known trap or panic. The console indicates systemd is waiting on udev, `/dev/ttyS0`, create-users, and journal flushing work. The trace suggests userspace is still doing dense open/stat/close/mmap-style activity before the prompt.

## Next Step

Run a longer prompt gate after the log-dir alias fix:

```sh
LOG_DIR=Linux/env/logs/codex-npc-systemd-guest-late-ecall-2400m
NPC_SYSTEMD_CHECK_MAX_CYCLES=2400000000
NPC_USER_ECALL_MIN_COMMIT=820000000
NPC_USER_ECALL_TRACE_LIMIT=8192
```

That should cover the 790M+ commit region where this run exhausted the ecall quota, especially `/dev/ttyS0`, udev, create-users, and journal persistence before the root prompt.
