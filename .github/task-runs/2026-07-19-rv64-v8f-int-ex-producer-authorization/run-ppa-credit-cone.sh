#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
RUN_ID=${1:-}
case "$RUN_ID" in
  run1|run2) ;;
  *) printf '[V8F-CREDIT-CONE][FAIL] expected run1 or run2\n' >&2; exit 64 ;;
esac

TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-19-rv64-v8f-int-ex-producer-authorization"
NETLIST="$ROOT_DIR/tmp/2026-07-19-rv64-v8f-int-ex-producer-authorization/evidence/ppa-current/fresh-synth-$RUN_ID/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
OUT_DIR="$TASK_DIR/evidence/ppa-current/fresh-synth-$RUN_ID/opensta-credit-cone-v4"
TCL="$TASK_DIR/opensta-v8f-credit-cone.tcl"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")
INT_PREFIX="u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend"
START_PIN="$INT_PREFIX/u_dispatch_backend/u_rob/_39164_/Q"
STRUCTURAL_START_PIN="$INT_PREFIX/u_dispatch_backend/u_rob/_39164_/CK"

[[ ! -e "$OUT_DIR" ]] || {
  printf '[V8F-CREDIT-CONE][FAIL] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 3
}
for input in "$NETLIST" "$TCL" "$OPENSTA" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}"; do
  [[ -f "$input" && ! -L "$input" && -s "$input" ]] || {
    printf '[V8F-CREDIT-CONE][FAIL] invalid input: %s\n' "$input" >&2
    exit 2
  }
done
mkdir -p "$OUT_DIR"
sha256sum "$NETLIST" "$TCL" "$OPENSTA" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}" \
  > "$OUT_DIR/inputs.sha256"

V8F_CONE_NETLIST="$NETLIST" \
V8F_CONE_OUT_DIR="$OUT_DIR" \
V8F_CONE_STD_LIB="$STD_LIB" \
V8F_CONE_MACRO_LIBS="$MACRO_LIBS" \
V8F_CONE_START_PIN="$START_PIN" \
V8F_CONE_STRUCTURAL_START_PIN="$STRUCTURAL_START_PIN" \
V8F_CONE_INT_PREFIX="$INT_PREFIX" \
  "$OPENSTA" "$TCL" > "$OUT_DIR/opensta-console.log" 2>&1
if grep -q '^Error:' "$OUT_DIR/opensta-console.log"; then
  printf '[V8F-CREDIT-CONE][FAIL] OpenSTA reported an error for %s\n' "$RUN_ID" >&2
  exit 4
fi

ready_labels=(mem_ready issue1_ready muldiv_ready clmul_ready fp_ready)
expected_ready=1
[[ "$RUN_ID" == run2 ]] && expected_ready=0
for label in "${ready_labels[@]}"; do
  count=$(sed -n "s/^${label}_structural_start_hits=//p" "$OUT_DIR/reachability.kv")
  [[ "$count" -eq "$expected_ready" ]] || {
    printf '[V8F-CREDIT-CONE][FAIL] %s %s paths=%s expected=%s\n' \
      "$RUN_ID" "$label" "$count" "$expected_ready" >&2
    exit 1
  }
done
authority_count=$(sed -n 's/^rob_wb0_authority_structural_start_hits=//p' \
  "$OUT_DIR/reachability.kv")
[[ "$authority_count" -eq 1 ]] || {
  printf '[V8F-CREDIT-CONE][FAIL] %s exact authority path missing\n' "$RUN_ID" >&2
  exit 1
}
printf 'run_id=%s\nsemantic_start_pin=%s\nstructural_start_pin=%s\nstructural_method=get_fanin_flat_startpoints_only_trace_arcs_all\nready_path_expected=%s\nready_targets=5\nready_targets_matched=5\nauthority_path_expected=1\nauthority_path_matched=1\nclaim_tier=diagnostic_rtl_proxy_partial_constraints\npromotion_eligible=false\n' \
  "$RUN_ID" "$START_PIN" "$STRUCTURAL_START_PIN" "$expected_ready" > "$OUT_DIR/summary.kv"
printf '[V8F-CREDIT-CONE] PASS run=%s ready_paths_each=%s authority_path=1\n' \
  "$RUN_ID" "$expected_ready"
