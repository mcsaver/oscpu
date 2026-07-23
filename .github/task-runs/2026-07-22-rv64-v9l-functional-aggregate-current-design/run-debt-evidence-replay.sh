#!/usr/bin/env bash
set -euo pipefail

# Local RV64 Verilog/SystemVerilog architecture-evidence replay only.  Each
# target rebuilds its directed tests and compile-success RTL verification
# variants against the current complete synthesizable RTL source set.

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
EVIDENCE_DIR="$RUN_DIR/debt-evidence-replay"

fail() {
  printf '[V9L-DEBT-REPLAY][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR/debt-evidence-replay") rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe replay output path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR"

run_target() {
  local target=$1
  local log="$EVIDENCE_DIR/$target.log"
  printf '[V9L-DEBT-REPLAY][START] %s\n' "$target"
  if ! make -C "$NPC_HOME" "$target" > "$log" 2>&1; then
    tail -n 120 "$log" >&2 || true
    fail "$target"
  fi
  printf '[V9L-DEBT-REPLAY][PASS] %s\n' "$target"
}

run_target check-instret-retirement
run_target check-fdg-arch-trap
run_target check-xret-current-mode
run_target check-memory-issue-lifecycle
run_target check-ifu-axi-flush-drain
run_target check-ifu-fetch-provenance
run_target check-ifu-access
run_target check-ifu-tval
run_target check-ptw-pmp

printf '%s\n' \
  '[V9L-DEBT-REPLAY][PASS] targets=9 local_rv64_current_design_evidence=9'
