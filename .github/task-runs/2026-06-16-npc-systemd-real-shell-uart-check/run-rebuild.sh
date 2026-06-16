#!/usr/bin/env bash
set -o pipefail

cd /home/lyg/PA/ysyx-workbench

run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check
log_dir="$run_dir/evidence/rebuild"
mkdir -p "$log_dir"

{
  echo "start: $(date -Is)"
  make -C Linux ARCH=riscv64-npc ubuntu-rootfs-systemd-image check-ubuntu-rootfs-systemd rootfs-dtb opensbi-rootfs
  rc=$?
  echo "$rc" > "$run_dir/rebuild.rc"
  echo "run.rc=$rc"
  echo "end: $(date -Is)"
  exit "$rc"
} 2>&1 | tee "$log_dir/rebuild.log"
