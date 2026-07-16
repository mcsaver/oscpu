#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane"
NETLIST="$ROOT_DIR/tmp/2026-07-14-rv64-t3v-predecode-mem-dataplane/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
OUT_DIR="$TASK_DIR/evidence/whatif-mask-planned-cuts-v4"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")
TCL="$TASK_DIR/opensta-whatif-mask-planned-cuts-v4.tcl"
SCRIPT="$TASK_DIR/run-whatif-mask-planned-cuts-v4.sh"
REPORT="$OUT_DIR/top40-mask-planned-cuts-v4.rpt"
COUNTS="$OUT_DIR/masked-object-count.txt"
INPUTS=("$NETLIST" "$OPENSTA" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}" "$TCL" "$SCRIPT")

[[ ! -e $OUT_DIR ]] || {
  printf '[T3V-WHATIF-PLANNED-CUTS-V4] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 3
}
for input in "${INPUTS[@]}"; do
  [[ -f $input && ! -L $input && -s $input ]] || {
    printf '[T3V-WHATIF-PLANNED-CUTS-V4] invalid input: %s\n' "$input" >&2
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
[[ -s $REPORT && -s $COUNTS ]]

awk '
  /^Startpoint:/ {
    startpoint=$0
    sub(/^Startpoint:[[:space:]]*/, "", startpoint)
  }
  /^Endpoint:/ {
    endpoint=$0
    sub(/^Endpoint:[[:space:]]*/, "", endpoint)
    print startpoint "\t" endpoint
  }
' "$REPORT" >"$OUT_DIR/startpoint-endpoint.tsv"
grep -E '^(tns|wns) max ' "$REPORT" >"$OUT_DIR/metrics.txt"
{
  printf 'reported_paths=%s\n' "$(grep -c '^Startpoint:' "$REPORT")"
  printf 'iq_marker_lines=%s\n' "$(grep -c '/u_issue_queue/' "$REPORT" || true)"
  printf 'prf_marker_lines=%s\n' "$(grep -c '/u_phys_reg_file/' "$REPORT" || true)"
  printf 'alu0_marker_lines=%s\n' "$(grep -c '/u_alu0/' "$REPORT" || true)"
  printf 'ex0_marker_lines=%s\n' "$(grep -c '/u_ex0_stage/' "$REPORT" || true)"
} >"$OUT_DIR/path-marker-count.txt"

if grep -q '^Startpoint: .*u_ooo_mem_bridge/u_dcache/' "$REPORT"; then
  printf '[T3V-WHATIF-PLANNED-CUTS-V4] ineffective D-cache Q mask\n' >&2
  exit 91
fi
if grep -q '^Startpoint: .*u_ooo_mem_bridge/u_dcache/u_sram$' "$REPORT"; then
  printf '[T3V-WHATIF-PLANNED-CUTS-V4] ineffective D-cache SRAM response mask\n' >&2
  exit 92
fi
if grep -q '^Endpoint: .*u_ooo_mem_bridge/u_dcache/u_sram$' "$REPORT"; then
  printf '[T3V-WHATIF-PLANNED-CUTS-V4] ineffective D-cache SRAM endpoint mask\n' >&2
  exit 93
fi
if grep -q '/u_fetch_head_pair_gate/.*/u_fp_decode/' "$REPORT"; then
  printf '[T3V-WHATIF-PLANNED-CUTS-V4] ineffective head FP-decode mask\n' >&2
  exit 94
fi
if grep -Eq '/u_(commit_output_mux|csr_access_request_mux|csr_trap_request_mux|pending_dispatch_arbiter|control_flush_sequencer|pending_system_sequencer|pending_trap_exit_sequencer|trap_exit_event_mux|trap_exit_output_sequencer)/' "$REPORT"; then
  printf '[T3V-WHATIF-PLANNED-CUTS-V4] ineffective commit/CSR/trap tail mask\n' >&2
  exit 95
fi
if grep -q '^Endpoint: u_core/u_csr_file/' "$REPORT"; then
  printf '[T3V-WHATIF-PLANNED-CUTS-V4] ineffective CSR endpoint mask\n' >&2
  exit 96
fi

printf '[T3V-WHATIF-PLANNED-CUTS-V4] PASS exploratory-only\n'
