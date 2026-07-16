#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3w-retire-static-cache-owner"
TMP_DIR="$ROOT_DIR/tmp/2026-07-14-rv64-t3w-retire-static-cache-owner/rob-wb-collision-negative"
EVIDENCE_DIR="$TASK_DIR/evidence/rob-wb-collision-negative-v1"
RTL="$ROOT_DIR/npc/rv64/vsrc/writeback/OooRob.v"
TB="$ROOT_DIR/npc/rv64/testbench/tests/tb_ooo_rob.sv"

rm -rf "$TMP_DIR" "$EVIDENCE_DIR"
mkdir -p "$TMP_DIR/build" "$EVIDENCE_DIR"

sha256sum "$RTL" "$TB" >"$EVIDENCE_DIR/inputs.pre.sha256"

make -C "$ROOT_DIR/npc/rv64/testbench" \
  TESTS=tb_ooo_rob \
  BUILD_DIR="$TMP_DIR/build" \
  RESULT_DIR="$TMP_DIR/positive" \
  run >"$EVIDENCE_DIR/positive-build.log" 2>&1

iverilog_bin=$(command -v iverilog)
vvp_bin="$(dirname "$iverilog_bin")/vvp"
[[ -x $vvp_bin ]] || vvp_bin=$(command -v vvp)

set +e
"$vvp_bin" "$TMP_DIR/build/tb_ooo_rob.vvp" \
  +T3W_ROB_WB_COLLISION_NEGATIVE \
  >"$EVIDENCE_DIR/negative.log" 2>&1
negative_rc=$?
set -e

sha256sum "$RTL" "$TB" >"$EVIDENCE_DIR/inputs.post.sha256"
cmp -s "$EVIDENCE_DIR/inputs.pre.sha256" "$EVIDENCE_DIR/inputs.post.sha256"
grep -Fq '[T3W-ROB-WB-OWNER-COLLISION]' "$EVIDENCE_DIR/negative.log"
[[ $negative_rc -ne 0 ]]

{
  printf 'positive=PASS\n'
  printf 'negative_rc=%d\n' "$negative_rc"
  printf 'assertion_hits=%s\n' \
    "$(grep -Fc '[T3W-ROB-WB-OWNER-COLLISION]' "$EVIDENCE_DIR/negative.log")"
  printf 'inputs_pre_post=IDENTICAL\n'
  printf 'runner=PASS\n'
} | tee "$EVIDENCE_DIR/summary.txt"
