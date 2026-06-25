#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
RUN_DIR="$REPO_ROOT/.github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace"
EVIDENCE_DIR="$RUN_DIR/evidence/aslr-off-full-lite-int10-create"

mkdir -p "$EVIDENCE_DIR"

set +e
NEMU_INTERPRETER_WIDE_IFETCH=0 \
make -C "$REPO_ROOT/Linux" ARCH=riscv64-nemu \
  NEMU_PYTHON_INT_CHECK_LOG_DIR="$EVIDENCE_DIR" \
  NEMU_PYTHON_INT_ROOTFS_OVERLAY="$EVIDENCE_DIR/rootfs-overlay.raw" \
  NEMU_PYTHON_INT_STAGE_MODE=full-lite \
  NEMU_PYTHON_INT_PROBE_MODE=int10-create \
  NEMU_PYTHON_INT_STAGE_PREWARM=0 \
  NEMU_PYTHON_INT_LOOPS=20 \
  NEMU_PYTHON_INT_DISABLE_ASLR=1 \
  NEMU_PYTHON_INT_CHECK_MAX_CYCLES=320000000000 \
  NEMU_PYTHON_INT_CHECK_TIMEOUT=9000 \
  NEMU_PYTHON_INT_BOOT_TIMEOUT=3600 \
  NEMU_PYTHON_INT_POWEROFF=0 \
  check-nemu-python-int-preflight >"$EVIDENCE_DIR/run.log" 2>&1
rc=$?
if [ -f "$EVIDENCE_DIR/console.log" ]; then
  python3 "$REPO_ROOT/Linux/tools/nemu-python-int-trace-correlate.py" \
    "$EVIDENCE_DIR/console.log" >"$EVIDENCE_DIR/trace-correlate.log" 2>&1
fi
set -e

printf '%s\n' "$rc" >"$EVIDENCE_DIR/run.rc"
exit "$rc"
