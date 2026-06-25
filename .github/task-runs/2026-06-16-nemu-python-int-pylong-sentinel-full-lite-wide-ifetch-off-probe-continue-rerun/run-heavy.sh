#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
RUN_DIR="$REPO_ROOT/.github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun"
EVIDENCE_DIR="$RUN_DIR/evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun"

mkdir -p "$EVIDENCE_DIR"

set +e
NEMU_INTERPRETER_WIDE_IFETCH=0 \
make -C "$REPO_ROOT/Linux" ARCH=riscv64-nemu \
  NEMU_PYTHON_INT_CHECK_LOG_DIR="$EVIDENCE_DIR" \
  NEMU_PYTHON_INT_ROOTFS_OVERLAY="$EVIDENCE_DIR/rootfs-overlay.raw" \
  NEMU_PYTHON_INT_STAGE_MODE=full-lite \
  NEMU_PYTHON_INT_LOOPS=10 \
  NEMU_PYTHON_INT_CHECK_MAX_CYCLES=320000000000 \
  NEMU_PYTHON_INT_CHECK_TIMEOUT=9000 \
  NEMU_PYTHON_INT_BOOT_TIMEOUT=3600 \
  NEMU_PYTHON_INT_POWEROFF=0 \
  check-nemu-python-int-preflight >"$EVIDENCE_DIR/run.log" 2>&1
rc=$?
set -e

printf '%s\n' "$rc" >"$EVIDENCE_DIR/run.rc"
exit "$rc"
