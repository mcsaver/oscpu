#!/usr/bin/env bash
set -u

repo_root="/home/lyg/PA/ysyx-workbench"
run_dir="$repo_root/.github/task-runs/2026-06-16-nemu-python-int-systemctl-lite-wide-ifetch-off-heavy"
evidence_dir="$run_dir/evidence"
log_dir="$evidence_dir/python-int-systemctl-lite-wide-ifetch-off"

mkdir -p "$log_dir"

{
  echo "[run] start $(date -Is)"
  echo "[run] repo_root=$repo_root"
  echo "[run] log_dir=$log_dir"
  echo "[run] note=wide-ifetch-off systemctl-lite PyLong/int A/B; concurrent NPC run may affect host wall time only"
  cd "$repo_root" || exit 2
  env \
    NEMU_INTERPRETER_WIDE_IFETCH=0 \
    NEMU_PYTHON_INT_CHECK_LOG_DIR="$log_dir" \
    NEMU_PYTHON_INT_ROOTFS_OVERLAY="$log_dir/rootfs-overlay.raw" \
    NEMU_PYTHON_INT_STAGE_MODE=systemctl-lite \
    NEMU_PYTHON_INT_LOOPS=10 \
    NEMU_PYTHON_INT_STAGE_TIMEOUT=300 \
    NEMU_PYTHON_INT_CHECK_MAX_CYCLES=240000000000 \
    NEMU_PYTHON_INT_CHECK_TIMEOUT=7200 \
    NEMU_PYTHON_INT_BOOT_TIMEOUT=2400 \
    NEMU_PYTHON_INT_POWEROFF=0 \
    make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight
  rc=$?
  echo "$rc" > "$evidence_dir/run.rc"
  echo "[run] rc=$rc"
  echo "[run] end $(date -Is)"
  exit "$rc"
} > "$evidence_dir/run.log" 2>&1
