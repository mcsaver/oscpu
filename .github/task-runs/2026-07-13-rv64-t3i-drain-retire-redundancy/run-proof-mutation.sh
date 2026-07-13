#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3i-drain-retire-redundancy"
SHADOW_BASE=/tmp/t3i-drain-proof-mutation
OUT_DIR="$TASK_DIR/evidence/proof-mutation"

mkdir -p "$OUT_DIR"

prepare_shadow() {
  local name=$1
  local shadow_root="$SHADOW_BASE/$name"
  mkdir -p "$shadow_root/npc/rv64/vsrc/writeback"
  mkdir -p "$shadow_root/npc/rv64/vsrc/execute"
  mkdir -p "$shadow_root/npc/rv64/vsrc/include"
  cp "$ROOT_DIR/npc/rv64/vsrc/writeback/OooRob.v" \
    "$shadow_root/npc/rv64/vsrc/writeback/OooRob.v"
  cp "$ROOT_DIR/npc/rv64/vsrc/execute/OooAluCoreSlice.v" \
    "$shadow_root/npc/rv64/vsrc/execute/OooAluCoreSlice.v"
  cp "$ROOT_DIR/npc/rv64/vsrc/include/define.v" \
    "$shadow_root/npc/rv64/vsrc/include/define.v"
  printf '%s\n' "$shadow_root"
}

run_expected_rejection() {
  local name=$1
  local shadow_root=$2
  local expected_reason=$3
  local log="$OUT_DIR/$name.log"
  local status="$OUT_DIR/$name.status.txt"
  local proof_rc reason_count

  set +e
  python3 "$TASK_DIR/prove-t3i-drain-theorem.py" "$shadow_root" \
    >"$log" 2>&1
  proof_rc=$?
  set -e
  reason_count=$(grep -F -c "$expected_reason" "$log" || true)
  {
    printf 'mutation=%s\n' "$name"
    printf 'proof_rc=%s\n' "$proof_rc"
    printf 'expected_reason=%s\n' "$expected_reason"
    printf 'expected_reason_count=%s\n' "$reason_count"
  } >"$status"
  if [[ $proof_rc -eq 0 || $reason_count -ne 1 ]]; then
    printf '[T3I-PROOF-MUTATION] FAIL: %s was not rejected exactly once\n' \
      "$name" >&2
    return 1
  fi
  printf '[T3I-PROOF-MUTATION] PASS: %s rejected rc=%s reason_count=1\n' \
    "$name" "$proof_rc"
}

removed_root=$(prepare_shadow removed-count-guard)
sed -i \
  "s/commit_ready_i && (count_q != {ROB_COUNT_W{1'b0}}) &&/commit_ready_i \&\&/" \
  "$removed_root/npc/rv64/vsrc/writeback/OooRob.v"
run_expected_rejection \
  removed-count-guard \
  "$removed_root" \
  'commit0 non-empty count guard must be exactly one top-level && conjunct'

or_bypass_root=$(prepare_shadow or-bypass)
sed -i \
  "s/!head0_csr_mem_hold_w;/!head0_csr_mem_hold_w || 1'b1;/" \
  "$or_bypass_root/npc/rv64/vsrc/writeback/OooRob.v"
run_expected_rejection \
  or-bypass \
  "$or_bypass_root" \
  'commit0_fire_w contains top-level logical OR'

{
  printf 'removed_count_guard=EXPECTED_FAIL\n'
  printf 'or_bypass=EXPECTED_FAIL\n'
} >"$OUT_DIR/status.txt"
