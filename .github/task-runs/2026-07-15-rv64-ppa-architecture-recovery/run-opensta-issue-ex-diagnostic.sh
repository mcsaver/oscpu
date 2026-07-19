#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
OUT_DIR="$TASK_DIR/evidence/ppa-r3p2-early-wake/issue-ex-timing-diagnostic"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
TCL="$TASK_DIR/opensta-issue-ex-diagnostic.tcl"
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIBS="$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
PREFIX="u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue"

BASE_NETLIST="$ROOT_DIR/tmp/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r2p5-icache/fresh-synth-run1/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
CURRENT_NETLIST="$ROOT_DIR/tmp/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r3p2-early-wake/fresh-synth-run1/sta-build/NpcTop-200MHz/NpcTop.netlist.v"

[[ ! -e $OUT_DIR ]] || {
  printf '[ISSUE-EX-DIAG] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 3
}
mkdir -p "$OUT_DIR"

run_one() {
  local design=$1
  local netlist=$2
  local start_cell=$3
  local report="$OUT_DIR/$design.rpt"
  local console="$OUT_DIR/$design.console.log"

  DIAG_STA_NETLIST="$netlist" \
  DIAG_STA_OUT="$report" \
  DIAG_STA_STD_LIB="$STD_LIB" \
  DIAG_STA_MACRO_LIBS="$MACRO_LIBS" \
  DIAG_STA_START_PIN="$PREFIX/$start_cell/Q" \
    "$OPENSTA" "$TCL" >"$console" 2>&1
  if grep -q '^Error:' "$console" || [[ ! -s $report ]]; then
    printf '[ISSUE-EX-DIAG] OpenSTA failed closed for %s\n' "$design" >&2
    exit 4
  fi
}

run_one r2p5 "$BASE_NETLIST" _56714_
run_one r3p2 "$CURRENT_NETLIST" _57803_
sha256sum "$BASE_NETLIST" "$CURRENT_NETLIST" "$STD_LIB" "$TCL" \
  >"$OUT_DIR/inputs.sha256"
printf '[ISSUE-EX-DIAG] PASS output=%s\n' "$OUT_DIR"
