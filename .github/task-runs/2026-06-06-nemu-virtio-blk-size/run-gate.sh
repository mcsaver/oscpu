#!/usr/bin/env bash
set -u

cd /home/lyg/PA/ysyx-workbench

run_dir=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-06-nemu-virtio-blk-size
gate_log=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-virtio-blk-size-gate

mkdir -p "$run_dir" "$gate_log"
rm -f "$run_dir/run.status"

timeout 2200s make -C Linux check-nemu-systemd-guest \
  NEMU_SYSTEMD_CHECK_LOG_DIR="$gate_log" \
  NEMU_SYSTEMD_CHECK_MAX_CYCLES=25000000000 \
  NEMU_SYSTEMD_CHECK_TIMEOUT=1900 \
  NEMU_SYSTEMD_RELOAD_TIMEOUT=60 \
  NEMU_SYSTEMD_SOAK_SECONDS=0 \
  NEMU_SYSTEMD_FS_STRESS_MIB=1 \
  NEMU_SYSTEMD_FS_TREE_FILES=8 \
  NEMU_SYSTEMD_PROCESS_LOOPS=2 \
  NEMU_SYSTEMD_UART_RX_STRESS_LINES=32 \
  NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=1 \
  NEMU_SYSTEMD_BLOCK_JOB_MIB=1 \
  NEMU_SYSTEMD_SYSCALL_PROBE=0 \
  > "$run_dir/run.out" 2>&1
status=$?
printf "%s\n" "$status" > "$run_dir/run.status"
exit "$status"
