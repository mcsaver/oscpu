#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane"
NETLIST="$ROOT_DIR/tmp/2026-07-14-rv64-t3v-predecode-mem-dataplane/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
OUT_DIR="$TASK_DIR/evidence/whatif-mask-planned-cuts-v4-iq-probe"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")
BASE_TCL="$TASK_DIR/opensta-whatif-mask-planned-cuts-v4.tcl"
TCL="$TASK_DIR/opensta-whatif-mask-planned-cuts-v4-iq-probe.tcl"
SCRIPT="$TASK_DIR/run-whatif-mask-planned-cuts-v4-iq-probe.sh"
TOP40="$OUT_DIR/top40-mask-planned-cuts-v4.rpt"
REPORT="$OUT_DIR/iq-prf-alu0-ex0.rpt"
COUNTS="$OUT_DIR/iq-probe-object-count.txt"
INPUTS=("$NETLIST" "$OPENSTA" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}" "$BASE_TCL" "$TCL" "$SCRIPT")

[[ ! -e $OUT_DIR ]] || {
  printf '[T3V-WHATIF-PLANNED-CUTS-V4-IQ] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 3
}
for input in "${INPUTS[@]}"; do
  [[ -f $input && ! -L $input && -s $input ]] || {
    printf '[T3V-WHATIF-PLANNED-CUTS-V4-IQ] invalid input: %s\n' "$input" >&2
    exit 2
  }
done
mkdir -p "$OUT_DIR"
sha256sum "${INPUTS[@]}" >"$OUT_DIR/inputs.pre.sha256"

T3V_WHATIF_NETLIST="$NETLIST" \
T3V_WHATIF_OUT_DIR="$OUT_DIR" \
T3V_WHATIF_STD_LIB="$STD_LIB" \
T3V_WHATIF_MACRO_LIBS="$MACRO_LIBS" \
  "$OPENSTA" "$TCL" >"$OUT_DIR/console.log" 2>&1

sha256sum "${INPUTS[@]}" >"$OUT_DIR/inputs.post.sha256"
cmp -s "$OUT_DIR/inputs.pre.sha256" "$OUT_DIR/inputs.post.sha256"
[[ -s $TOP40 && -s $REPORT && -s $COUNTS ]]
grep -q '/u_issue_queue/' "$REPORT"
grep -q '/u_phys_reg_file/' "$REPORT"
grep -q '/u_alu0/' "$REPORT"
grep -q '/u_ex0_stage/' "$REPORT"

{
  printf 'reported_paths=%s\n' "$(grep -c '^Startpoint:' "$REPORT")"
  printf 'iq_marker_lines=%s\n' "$(grep -c '/u_issue_queue/' "$REPORT")"
  printf 'prf_marker_lines=%s\n' "$(grep -c '/u_phys_reg_file/' "$REPORT")"
  printf 'alu0_marker_lines=%s\n' "$(grep -c '/u_alu0/' "$REPORT")"
  printf 'ex0_marker_lines=%s\n' "$(grep -c '/u_ex0_stage/' "$REPORT")"
  grep -E '^[[:space:]]*-?[0-9]+\.[0-9]+[[:space:]]+slack( \(VIOLATED\))?$' "$REPORT" |
    sed -E 's/^[[:space:]]*//'
} >"$OUT_DIR/iq-probe-summary.txt"

printf '[T3V-WHATIF-PLANNED-CUTS-V4-IQ] PASS directed structural path\n'
