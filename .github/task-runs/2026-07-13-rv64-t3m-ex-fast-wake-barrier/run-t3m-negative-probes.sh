#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
TB="$ROOT/npc/rv64/testbench"
VSRCDIR="$ROOT/npc/rv64/vsrc"
OUT="${1:-$ROOT/.github/task-runs/2026-07-13-rv64-t3m-ex-fast-wake-barrier/evidence/negative}"
mkdir -p "$OUT"

IVERILOG=${IVERILOG:-iverilog}
IVERILOG_DIR=$(dirname "$(command -v "$IVERILOG")")
VVP=${VVP:-$IVERILOG_DIR/vvp}
if [[ ! -x "$VVP" ]]; then
  VVP=$(command -v vvp)
fi

run_probe() {
  local name=$1
  local macro=$2
  local top=$3
  local marker=$4
  shift 4
  local log="$OUT/$name.log"
  local image="$OUT/$name.vvp"

  set +e
  "$IVERILOG" -g2012 -Wall -I"$VSRCDIR" -I"$VSRCDIR/include" \
    -I"$TB/common" -DOOO_ASSERT -D"$macro" -s "$top" -o "$image" "$@" \
    >"$log" 2>&1
  local compile_rc=$?
  if [[ $compile_rc -eq 0 ]]; then
    "$VVP" "$image" >>"$log" 2>&1
    local sim_rc=$?
  else
    local sim_rc=125
  fi
  set -e

  local error_count marker_count
  error_count=$(grep -c '^ERROR:' "$log" || true)
  marker_count=$(grep -cF "$marker" "$log" || true)
  printf 'compile_rc=%s\nsim_rc=%s\nerror_count=%s\nmarker_count=%s\n' \
    "$compile_rc" "$sim_rc" "$error_count" "$marker_count" \
    >"$OUT/$name.status"
  [[ $compile_rc -eq 0 ]]
  [[ $error_count -eq 1 ]]
  [[ $marker_count -eq 1 ]]
}

run_probe iq-int-sticky IQ_INT_WAKE_STICKY_NEGATIVE \
  tb_ooo_int_issue_queue '[IQ-INT-WAKE-STICKY-ONLY]' \
  "$TB/tests/tb_ooo_int_issue_queue.sv" \
  "$VSRCDIR/scheduling/OooIntIssueQueue.v"

run_probe prf-int-stored PRF_INT_READ_STORED_NEGATIVE \
  tb_ooo_phys_reg_file '[PRF-INT-READ-STORED-ONLY]' \
  "$TB/tests/tb_ooo_phys_reg_file.sv" \
  "$VSRCDIR/regread_bypass/OooPhysRegFile.v"

printf '[T3M-NEGATIVE] PASS probes=2\n' | tee "$OUT/summary.txt"
