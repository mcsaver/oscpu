#!/usr/bin/env bash
set -o pipefail

cd /home/lyg/PA/ysyx-workbench

run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check
log_dir="$run_dir/evidence/npc-systemd-autocheck-after-hook"
mkdir -p "$log_dir"

{
  echo "start: $(date -Is)"
  NPC_SYSTEMD_CHECK_LOG_DIR="$PWD/$log_dir" \
  NPC_SYSTEMD_PROMPT="root@ysyx-ubuntu2204:~#" \
  NPC_SYSTEMD_GUEST_COMMAND_MODE=autocheck \
  NPC_SYSTEMD_CHECK_MAX_CYCLES=500000000 \
  NPC_SYSTEMD_HOST_TIMEOUT=1800 \
  NPC_SYSTEMD_PROGRESS=50000000 \
    make -C Linux ARCH=riscv64-npc check-npc-systemd-guest
  rc=$?
  echo "$rc" > "$run_dir/autocheck-after-hook.rc"
  echo "run.rc=$rc"
  echo "end: $(date -Is)"
  exit "$rc"
} 2>&1 | tee "$log_dir/run.log"
