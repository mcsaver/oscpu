#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3l-branch-target-split"
OUT_DIR=${1:-"$TASK_DIR/evidence/negative-target-equiv"}
MUTATED_RTL="$OUT_DIR/OooFetchBranchTarget.mutated.v"
VVP="$OUT_DIR/tb-t3l-target-equiv-negative.vvp"
LOG="$OUT_DIR/sim.log"

mkdir -p "$OUT_DIR"
python3 - "$ROOT_DIR/npc/rv64/vsrc/frontend/OooFetchBranchTarget.v" "$MUTATED_RTL" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text()
old = "{{(`XLEN-13){1'b0}}, low_sum_w[12]} -\n      {{(`XLEN-13){1'b0}}, bimm_i[12]}"
new = "{{(`XLEN-13){1'b0}}, low_sum_w[12]} +\n      {{(`XLEN-13){1'b0}}, bimm_i[12]}"
if source.count(old) != 1:
    raise SystemExit("mutation setup did not find exactly one carry-sign formula")
Path(sys.argv[2]).write_text(source.replace(old, new, 1))
PY

set +e
iverilog -g2012 -Wall -DOOO_ASSERT \
  -I"$ROOT_DIR/npc/rv64/vsrc" \
  -I"$ROOT_DIR/npc/rv64/vsrc/include" \
  -s tb_t3l_target_equiv_negative \
  -o "$VVP" "$MUTATED_RTL" "$TASK_DIR/tb-t3l-target-equiv-negative.sv" \
  >"$OUT_DIR/compile.log" 2>&1
compile_rc=$?
if [[ $compile_rc -eq 0 ]]; then
  vvp "$VVP" >"$LOG" 2>&1
  sim_rc=$?
else
  sim_rc=127
  : >"$LOG"
fi
set -e

python3 "$TASK_DIR/check-t3l-negative-log.py" "$LOG" \
  --compile-rc "$compile_rc" --sim-rc "$sim_rc" | tee "$OUT_DIR/checker.log"
python3 "$TASK_DIR/check-t3l-negative-log.py" --selftest \
  | tee "$OUT_DIR/selftest.log"
{
  printf 'compile_rc=%s\n' "$compile_rc"
  printf 'sim_rc=%s\n' "$sim_rc"
  printf 'marker_count=%s\n' "$(grep -Fc '[FETCH-BRANCH-TARGET-EQUIV]' "$LOG")"
  printf 'premise_count=%s\n' "$(grep -Fc '[T3L-NEGATIVE-PREMISE]' "$LOG")"
  printf 'status=PASS\n'
} >"$OUT_DIR/status.txt"
printf '[T3L-NEGATIVE-PROBE] PASS output=%s\n' "$OUT_DIR"
