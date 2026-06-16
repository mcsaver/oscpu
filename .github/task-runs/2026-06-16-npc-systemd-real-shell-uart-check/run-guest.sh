#!/usr/bin/env bash
set -o pipefail

cd /home/lyg/PA/ysyx-workbench

run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check
log_dir="$run_dir/evidence/npc-systemd-guest"
mkdir -p "$log_dir"

{
  echo "start: $(date -Is)"
  NPC_SYSTEMD_CHECK_LOG_DIR="$PWD/$log_dir" \
  NPC_SYSTEMD_PROMPT="root@ysyx-ubuntu2204:~#" \
  NPC_SYSTEMD_GUEST_COMMAND_MODE=uart \
  NPC_SYSTEMD_UART_WAIT="Ubuntu 22.04" \
  NPC_SYSTEMD_UART_CYCLE_GAP=10000 \
  NPC_SYSTEMD_CHECK_MAX_CYCLES=700000000 \
  NPC_SYSTEMD_HOST_TIMEOUT=2400 \
  NPC_SYSTEMD_PROGRESS=50000000 \
    make -C Linux ARCH=riscv64-npc check-npc-systemd-guest
  rc=$?
  echo "$rc" > "$run_dir/run.rc"
  echo "run.rc=$rc"
  echo "end: $(date -Is)"
  exit "$rc"
} 2>&1 | tee "$log_dir/run.log"
