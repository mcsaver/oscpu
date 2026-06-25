# NEMU full Ubuntu cron timeout contract and WSL blocked verification

## Summary

- Scope: NEMU-only full Ubuntu 22.04.
- Slice: promote the existing `cron.service` execution smoke into an explicit full userland gate contract.
- Result: code/docs/e2e contract updated; host-side static checks passed; runtime/rootfs/e2e/full gate verification is blocked by the current WSL client issue.
- Superseded: the WSL client issue was later resolved by stopping the stale 2026-06-16 NPC task-run WSL clients, and `.github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-contract/` plus `.github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/` provide the current PASS evidence.

## Changes

- `Linux/scripts/check-nemu-systemd-guest.sh`
  - Added `NEMU_SYSTEMD_CRON_JOB_TIMEOUT`, default `180`.
  - Passes `NEMU_GUEST_CRON_JOB_TIMEOUT` into the guest check script.
  - Records `cron_job_timeout` in `perf.tsv`.
  - Emits `__NEMU_CHECK_FULL_CRON_JOB_TIMEOUT__`, `__NEMU_CHECK_FULL_CRON_JOB__`, `__NEMU_CHECK_FULL_CRON_EXEC_WAIT_SECONDS__`, and the existing `__NEMU_CHECK_FULL_CRON_EXEC_FILE__`.
  - Writes the cron probe as `/bin/sh -c 'printf ...'` to avoid depending on shell builtins in cron parsing.
  - Rechecks the probe file after the final sleep to avoid a timeout-boundary false failure.
- `Linux/Makefile`
  - Added `NEMU_SYSTEMD_CRON_JOB_TIMEOUT ?= 180`.
  - Passes the timeout to `check-nemu-systemd-guest.sh`.
- `Linux/scripts/ubuntu-rootfs-flavors.sh` and `Linux/scripts/check-ubuntu-rootfs.sh`
  - Full rootfs now requires `/etc/crontab`, `/etc/cron.d`, and `/etc/cron.daily` in addition to `/usr/sbin/cron`.
  - `check-ubuntu-rootfs-full` checks `cron` ownership for those paths.
- `scripts/e2e/modules/nemu.sh`
  - Added static contract strings for `NEMU_SYSTEMD_CRON_JOB_TIMEOUT`, `NEMU_GUEST_CRON_JOB_TIMEOUT`, cron markers, rootfs cron paths, and Makefile default.
  - Focused full gate passes `AGENT_E2E_NEMU_UBUNTU_CRON_JOB_TIMEOUT` to `NEMU_SYSTEMD_CRON_JOB_TIMEOUT`.
  - Focused marker grep now includes `FULL_CRON`.
  - Full gate hard marker list now requires `__NEMU_CHECK_FULL_CRON_JOB_TIMEOUT__` before accepting `full-userland-cron-exec`.
- Docs
  - `.github/e2e/README.md`, `.github/e2e/modules/nemu.md`, and `.github/instructions/agent-e2e-workflow.instructions.md` now describe the full cron daemon execution gate and boundary.

## Verification

- PASS: Git Bash shell syntax check:
  - `bash -n Linux/scripts/ubuntu-rootfs-flavors.sh Linux/scripts/check-ubuntu-rootfs.sh Linux/scripts/check-nemu-systemd-guest.sh scripts/e2e/modules/nemu.sh scripts/agent-e2e.sh`
- PASS: Windows Python compile:
  - `python -m py_compile scripts/dev_memory/maintenance.py scripts/dev_memory/cli.py scripts/dev_memory/core.py scripts/github_index_db.py`
- PASS: targeted `git diff --check` with Windows Git and one-shot `safe.directory`.
  - Only UNC/Windows Git LF-to-CRLF warnings were emitted.
- PASS: PowerShell text contract check for the new cron timeout, guest env, markers, rootfs paths, Makefile default, e2e env passthrough, and docs.
- BLOCKED: `python scripts/github_index_db.py archive-markdown ...` did not return under the current SQLite/WSL state. I stopped only this run's Python process. DB/archive sync must be retried after the environment is responsive.

## Blocked Runtime Verification

- `wsl.exe -l -v` returns and shows Ubuntu running.
- New Ubuntu clients currently hang:
  - `wsl.exe -d Ubuntu -- true`
  - `wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- true`
- I killed only the new probe clients created in this run.
- Historical NPC long-running WSL clients were left untouched:
  - `wsl.exe ... run-login-generators-enabled.sh` PIDs observed: `30680`, `32488`.

## Follow-up Required

Once new WSL clients can enter Ubuntu again, run:

```sh
bash -n Linux/scripts/ubuntu-rootfs-flavors.sh Linux/scripts/check-ubuntu-rootfs.sh Linux/scripts/check-nemu-systemd-guest.sh scripts/e2e/modules/nemu.sh scripts/agent-e2e.sh
python3 -m py_compile scripts/dev_memory/maintenance.py scripts/dev_memory/cli.py scripts/dev_memory/core.py scripts/github_index_db.py
git diff --check -- Linux/Makefile Linux/scripts/ubuntu-rootfs-flavors.sh Linux/scripts/check-ubuntu-rootfs.sh Linux/scripts/check-nemu-systemd-guest.sh scripts/e2e/modules/nemu.sh .github/e2e/README.md .github/e2e/modules/nemu.md .github/instructions/agent-e2e-workflow.instructions.md
make -C Linux ARCH=riscv64-nemu ubuntu-rootfs-flavors-check
make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-full
scripts/agent-e2e.sh --profile nemu-dev --task-slug 2026-06-22-nemu-full-cron-timeout-contract --stop-on-fail
AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate --task-slug 2026-06-22-nemu-full-cron-timeout-full-gate --stop-on-fail
python3 scripts/github_index_db.py archive-markdown .github/memory/project-status.md .github/memory/modules/nemu.md .github/memory/modules/agent-system.md .github/memory/known-issues.md .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-contract-wsl-blocked/task-report.md --backup-dir .github/db-backup --yes
python3 scripts/github_index_db.py doctor --fail-on-drift --show-nonblocking-drift
python3 scripts/github_index_db.py audit-db-first
python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence
```
