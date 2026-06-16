# Task Report: RV64 NPC systemd 1.2B late ecall preparation

- **status**: partial
- **profile**: rv64-linux
- **task_slug**: rv64-npc-systemd-1200m-late-ecall
- **started_at**: 2026-06-12
- **updated_at**: 2026-06-12

## Summary

Continued the NPC RV64 Ubuntu 22.04 systemd hard gate from the current default rootfs/systemd path to 1.2B cycles. The run advanced beyond the prior 900M baseline into systemd slice/socket/module startup, but it still did not reach the root prompt or the guest-side completion marker.

To make the next long run more diagnostic, added `NPC_USER_ECALL_MIN_COMMIT` so U-mode syscall tracing can start late instead of spending the entire trace quota on early systemd startup scans.

## Runtime Evidence

- Evidence directory: `Linux/env/logs/codex-npc-systemd-guest-uecall-1200m`
- Result: max-cycle abort at 1.2B cycles, not a guest panic or bad trap.
- Stats: cycles=1200000000, commits=605646349, CPI=1.981, CLINT mtime=1200000000 and mtime-cycles matched.
- Console progress beyond banner: `/system/modprobe`, `/system/serial-getty`, user/session slice, journal and udev sockets, POSIX message queue mount, journal service, module load path.
- Missing: `root@ysyx-ubuntu2204:~#` prompt, UART RX release, and `__NPC_SYSTEMD_CHECK_DONE__ rc=0`.
- Bad signatures: panic/Oops/Bad trap/HIT BAD TRAP/BUG counts were all 0 in the checked logs.
- Final PC: `0xffffffff8011c60a`, symbolized as kernel `__kmem_cache_alloc_node`; nearby samples also touched `kmalloc_slab`, `__kmalloc`, `__memset`, `tcp_init`, and `do_seccomp`.

## Implementation

- `npc/rv64/csrc/cpu/cpu-exec.cpp`
  - Added `g_user_ecall_min_commit`.
  - Added env `NPC_USER_ECALL_MIN_COMMIT`, defaulting to `NPC_USER_TRACE_MIN_COMMIT`.
  - Included `ecall_min_commit=` in the user trace enable line.
  - Gated both commit-layer and trap-layer U-mode ecall logging by `NPC_USER_ECALL_MIN_COMMIT`.
- `scripts/e2e/modules/npc.sh`
  - Added static contract coverage for `NPC_USER_ECALL_MIN_COMMIT`.
- `.github/e2e/modules/npc.md`, `.github/memory/project-status.md`, `.github/memory/modules/npc.md`
  - Updated DB-backed memory and e2e notes with the 1.2B evidence and next-step boundary.

## Validation

- `bash -n Linux/scripts/check-npc-systemd-guest.sh scripts/e2e/modules/npc.sh`: PASS
- `make -C npc/rv64 -j2`: PASS
- `scripts/agent-e2e.sh --validate-profile --profile rv64-linux`: PASS
- manual `e2e_npc_rv64_systemd_guest_check_contract`: PASS
- `NPC_USER_ECALL_TRACE=1 NPC_USER_ECALL_TRACE_LIMIT=16 make -C Linux ARCH=riscv64-npc smoke-sret-user-sv39`: PASS, logs U-mode ecall at commit 94.
- `NPC_USER_ECALL_TRACE=1 NPC_USER_ECALL_MIN_COMMIT=1000 NPC_USER_ECALL_TRACE_LIMIT=16 make -C Linux ARCH=riscv64-npc smoke-sret-user-sv39`: PASS, suppresses the early U-mode ecall while still reaching GOOD TRAP.

## Boundary

This does not complete the NEMU-equivalent Ubuntu 22.04 gate. The current best next run should keep user progress around the previous 90M baseline and delay ecall trace, for example:

```sh
NPC_USER_TRACE_MIN_COMMIT=90000000
NPC_USER_PROGRESS_INTERVAL=20000000
NPC_USER_ECALL_MIN_COMMIT=520000000
NPC_USER_ECALL_TRACE=1
NPC_USER_ECALL_TRACE_LIMIT=512
```

That should capture the syscall behavior around the later serial-getty/module-load region instead of the early systemd scan.
