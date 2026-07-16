#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3w-retire-static-cache-owner"
TMP_DIR="$ROOT_DIR/tmp/2026-07-14-rv64-t3w-retire-static-cache-owner"
OUT_TAG=${T3W_AUDIT_OUT_TAG:-netlist-directed-audit-v1}
OUT_DIR="$TASK_DIR/evidence/$OUT_TAG"
NETLIST="$TMP_DIR/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
SYNTH_CHECK="$TMP_DIR/sta-build/NpcTop-200MHz/synth_check.txt"
SYNTH_STATUS="$TMP_DIR/synth-exit-status.txt"
SYNTH_FREEZE="$TMP_DIR/synth-input-hash-cmp.txt"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")
PY_AUDIT="$TASK_DIR/audit-t3w-fresh-netlist.py"
TCL_AUDIT="$TASK_DIR/opensta-t3w-fresh-netlist-audit.tcl"
RUNNER="$TASK_DIR/run-t3w-fresh-netlist-audit.sh"
INPUTS=(
  "$NETLIST" "$SYNTH_CHECK" "$SYNTH_STATUS" "$SYNTH_FREEZE"
  "$OPENSTA" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}"
  "$PY_AUDIT" "$TCL_AUDIT" "$RUNNER"
)

[[ ! -e $OUT_DIR ]] || {
  printf '[T3W-FRESH-NETLIST-AUDIT] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 3
}
for input in "${INPUTS[@]}"; do
  [[ -f $input && ! -L $input && -s $input ]] || {
    printf '[T3W-FRESH-NETLIST-AUDIT] missing, empty, symlink, or non-regular input: %s\n' \
      "$input" >&2
    exit 2
  }
done

# Do not accept an early/partially-written Yosys result.  The common synthesis
# runner creates these only after make returns and all frozen inputs compare.
[[ $(tr -d '[:space:]' <"$SYNTH_STATUS") == 0 ]]
[[ $(grep -c '=PASS$' "$SYNTH_FREEZE") -eq 8 ]]
! grep -q '=FAIL$' "$SYNTH_FREEZE"
grep -q '^Found and reported 0 problems\.$' "$SYNTH_CHECK"
[[ $(stat -c %s "$NETLIST") -gt 1000000 ]]

mkdir -p "$OUT_DIR"
sha256sum "${INPUTS[@]}" >"$OUT_DIR/inputs.pre.sha256"

python3 "$PY_AUDIT" \
  --netlist "$NETLIST" \
  --std-lib "$STD_LIB" \
  --json-out "$OUT_DIR/structural-audit.json" \
  --object-manifest-out "$OUT_DIR/structural-objects.txt" \
  >"$OUT_DIR/structural-console.log" 2>&1

T3W_AUDIT_NETLIST="$NETLIST" \
T3W_AUDIT_OUT_DIR="$OUT_DIR" \
T3W_AUDIT_STD_LIB="$STD_LIB" \
T3W_AUDIT_MACRO_LIBS="$MACRO_LIBS" \
T3W_AUDIT_STRUCTURAL_MANIFEST="$OUT_DIR/structural-objects.txt" \
  "$OPENSTA" "$TCL_AUDIT" >"$OUT_DIR/opensta-console.log" 2>&1

sha256sum "${INPUTS[@]}" >"$OUT_DIR/inputs.post.sha256"
cmp -s "$OUT_DIR/inputs.pre.sha256" "$OUT_DIR/inputs.post.sha256"
printf 'inputs_pre_post=PASS\n' >"$OUT_DIR/input-freeze.txt"

grep -q '^  "status": "PASS"' "$OUT_DIR/structural-audit.json"
grep -q '^\[T3W-FRESH-NETLIST-STRUCTURAL\] PASS$' \
  "$OUT_DIR/structural-console.log"
grep -q '^\[T3W-FRESH-NETLIST-OPENSTA\] PASS$' \
  "$OUT_DIR/opensta-console.log"

# A wrong standard-cell family can silently manufacture hundreds of unknown
# black boxes.  Treat every such diagnostic as a hard failure.
if grep -Eiq \
  'Creating black box|unknown (module|cell)|not found in the timing library|link[^[:alnum:]]+error|black[- ]box.*(missing|unknown)' \
  "$OUT_DIR/opensta-console.log"; then
  printf '[T3W-FRESH-NETLIST-AUDIT] unknown/black-box diagnostic detected\n' >&2
  exit 90
fi

required_reports=(
  fifo-headq-to-shadow-d-required.rpt
  fifo-shadowq-to-production-required.rpt
  ifu-lookupq-to-fast-pmp0-required.rpt
  ifu-lookupq-to-fast-pmp1-required.rpt
  dcache-to-rob-state-required.rpt
)
for report in "${required_reports[@]}"; do
  [[ -s $OUT_DIR/$report ]]
  [[ $(grep -c '^Startpoint:' "$OUT_DIR/$report") -ge 1 ]]
  grep -Eq 'slack \((MET|VIOLATED)\)' "$OUT_DIR/$report"
done

forbidden_reports=(
  fifo-headq-to-production-forbidden.rpt
  ifu-pcq-to-fast-pmp0-forbidden.rpt
  ifu-pcq-to-fast-pmp1-forbidden.rpt
  rob-wb-to-commit-forbidden.rpt
  dcache-to-commit-forbidden.rpt
)
for report in "${forbidden_reports[@]}"; do
  [[ -e $OUT_DIR/$report ]]
  [[ $(grep -c '^Startpoint:' "$OUT_DIR/$report" || true) -eq 0 ]]
done

# Non-vacuity markers tie the required path to the intended physical blocks.
grep -q '/u_fetch_packet_fifo/' "$OUT_DIR/fifo-headq-to-shadow-d-required.rpt"
grep -q '/u_fetch_packet_fifo/' "$OUT_DIR/fifo-shadowq-to-production-required.rpt"
grep -q '/u_req_exec_pmp_checker/' "$OUT_DIR/ifu-lookupq-to-fast-pmp0-required.rpt"
grep -q '/u_req_exec1_pmp_checker/' "$OUT_DIR/ifu-lookupq-to-fast-pmp1-required.rpt"
grep -q '/u_ooo_mem_bridge/u_dcache/u_sram' \
  "$OUT_DIR/dcache-to-rob-state-required.rpt"
grep -Eq '/u_rob/.*wb[01]_data_i_' \
  "$OUT_DIR/dcache-to-rob-state-required.rpt"
grep -q '^Endpoint: .*/u_rob/' "$OUT_DIR/dcache-to-rob-state-required.rpt"

{
  for report in "${required_reports[@]}"; do
    printf '%s=%s\n' "$report" "$(grep -c '^Startpoint:' "$OUT_DIR/$report")"
  done
  for report in "${forbidden_reports[@]}"; do
    printf '%s=%s\n' "$report" "$(grep -c '^Startpoint:' "$OUT_DIR/$report" || true)"
  done
} >"$OUT_DIR/path-counts.txt"

netlist_sha=$(sha256sum "$NETLIST" | cut -d' ' -f1)
{
  printf 'status=PASS\n'
  printf 'fresh_netlist=%s\n' "$NETLIST"
  printf 'fresh_netlist_sha256=%s\n' "$netlist_sha"
  printf 'clock_period_ns=5.000\n'
  printf 'timing_exceptions_added=0\n'
  printf 'structural_graph=PASS\n'
  printf 'directed_opensta=PASS\n'
  printf 'input_freeze=PASS\n'
  printf 'unknown_blackboxes=0\n'
  printf 'required_reports=%s\n' "${#required_reports[@]}"
  printf 'forbidden_reports=%s\n' "${#forbidden_reports[@]}"
} >"$OUT_DIR/summary.txt"

sha256sum \
  "$OUT_DIR/structural-audit.json" \
  "$OUT_DIR/structural-objects.txt" \
  "$OUT_DIR/opensta-object-counts.txt" \
  "$OUT_DIR/path-counts.txt" \
  "$OUT_DIR/summary.txt" \
  >"$OUT_DIR/output-assets.sha256"

printf '[T3W-FRESH-NETLIST-AUDIT] PASS netlist_sha256=%s evidence=%s\n' \
  "$netlist_sha" "$OUT_DIR"
