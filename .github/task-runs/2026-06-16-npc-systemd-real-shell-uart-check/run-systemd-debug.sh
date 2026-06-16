#!/usr/bin/env bash
set -o pipefail

cd /home/lyg/PA/ysyx-workbench

run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check
log_dir="$run_dir/evidence/npc-systemd-debug"
mkdir -p "$log_dir"

{
  echo "start: $(date -Is)"
  env NPC_OOO_WINDOW=0 \
    NPC_GUEST_EXPECT="__NPC_CONSOLE_SHELL_READY__" \
    make -C Linux ARCH=riscv64-npc BOOT=ubuntu-rootfs \
      BOOTARGS_EXTRA="systemd.log_level=debug systemd.log_target=console systemd.show_status=1" \
      MAX_CYCLES=360000000 PROGRESS=50000000 LOG_DIR="$PWD/$log_dir" run
  rc=$?
  echo "$rc" > "$run_dir/systemd-debug.rc"
  echo "run.rc=$rc"
  echo "end: $(date -Is)"
  exit "$rc"
} 2>&1 | tee "$log_dir/run.log"
