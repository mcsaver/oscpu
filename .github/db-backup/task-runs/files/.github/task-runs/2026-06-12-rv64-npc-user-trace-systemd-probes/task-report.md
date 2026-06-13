# Task Report: rv64-npc-user-trace-systemd-probes

- status: PASS
- profile: rv64-linux
- task_slug: rv64-npc-user-trace-systemd-probes
- date: 2026-06-12

## Summary

Continued NPC RV64 Ubuntu 22.04 systemd bring-up by adding default-off observability for the banner-to-prompt gap. The simulator can now sample dynamic userland execution and user ECALL candidates without enabling heavy global itrace.

This does not complete the full Ubuntu gate yet. It gives a much sharper next-debug surface after systemd starts.

## Changes

- `npc/rv64/csrc/cpu/cpu-exec.cpp`: added `NPC_USER_PROGRESS_INTERVAL`, `NPC_USER_PROGRESS_LIMIT`, `NPC_USER_ECALL_TRACE`, `NPC_USER_ECALL_TRACE_LIMIT`, and `NPC_USER_TRACE_MIN_COMMIT`.
- `Linux/scripts/check-npc-systemd-guest.sh`: added `NPC_SYSTEMD_PROGRESS` and passes it through as `PROGRESS` for the NPC run.
- `Linux/Makefile`: forwards `NPC_SYSTEMD_PROGRESS` into the guest-check script.
- `scripts/e2e/modules/npc.sh`: extends the systemd guest-check contract to assert the progress/user-trace controls exist.

## Probe Evidence

- Short negative smoke with `NPC_SYSTEMD_PROGRESS=500` confirmed the script prints the progress interval, the run command receives `--progress=500`, and the simulator logs `user_trace enabled`.
- 220M relaxed probe captured first dynamic userland progress at commit `89427905`, `pc=0x0000003f8efbc620`, matching ld-linux-style execution; no user ECALL sample was seen in that budget.
- 260M late probe reached `systemd 249.11-0ubuntu3.21`, `Welcome to Ubuntu 22.04.5 LTS`, and `Hostname set to <ysyx-ubuntu2204>`, then captured 64 systemd/libc userland samples from commit `120001804`. The run stopped only because `MAX_CYCLES=260000000`, with final PC in kernel `bio_add_page`.
- Rechecking the earlier 700M evidence showed the final PC in kernel `tty_save_termios` return code, also a max-cycle boundary rather than a panic or bad trap.

## Validation

- `make -C npc/rv64 -j2`: PASS
- `bash -n Linux/scripts/check-npc-systemd-guest.sh scripts/e2e/modules/npc.sh`: PASS
- `scripts/agent-e2e.sh --validate-profile --profile rv64-linux`: PASS
- Manual `e2e_npc_rv64_systemd_guest_check_contract`: PASS

## Boundary

The hard completion gate is still `make check-npc-systemd-guest`, requiring `root@ysyx-ubuntu2204:~#`, guest script injection, and `__NPC_SYSTEMD_CHECK_DONE__ rc=0`. Current evidence proves real Ubuntu systemd userland progress and absence of immediate critical traps, not full Ubuntu completion.
