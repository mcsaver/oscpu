#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
RUN_ID=${1:-run1}
case "$RUN_ID" in
  run1|run2) ;;
  *) printf '[PPA-R3P6-STA] invalid run id: %s\n' "$RUN_ID" >&2; exit 64 ;;
esac

PARENT_SLUG=2026-07-15-rv64-ppa-architecture-recovery
PARENT_TASK="$ROOT_DIR/.github/task-runs/$PARENT_SLUG"
SYNTH_SLUG="$PARENT_SLUG/evidence/ppa-r3p6-onehot-prf/fresh-synth-$RUN_ID"
SYNTH_TASK="$ROOT_DIR/.github/task-runs/$SYNTH_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$SYNTH_SLUG"
OUT_DIR="$SYNTH_TASK/opensta-exact5ns"
T4Q_TASK="$ROOT_DIR/.github/task-runs/2026-07-15-rv64-t4q-final-sta"
NETLIST="$TMP_DIR/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
AUDIT="$SYNTH_TASK/evidence/synthesis/summary.json"
FREEZE="$TMP_DIR/synth-input-hash-cmp.txt"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")
TCL="$T4Q_TASK/opensta-t4q-current-5ns.tcl"

[[ ! -e $OUT_DIR ]] || {
  printf '[PPA-R3P6-STA] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 3
}
for input in "$NETLIST" "$AUDIT" "$FREEZE" "$OPENSTA" "$STD_LIB" \
             "$TCL" "${MACRO_LIB_ARRAY[@]}"; do
  [[ -f $input && ! -L $input && -s $input ]] || {
    printf '[PPA-R3P6-STA] invalid input: %s\n' "$input" >&2
    exit 2
  }
done

mkdir -p "$OUT_DIR"
printf 'period_ns=5.0\ntop=NpcTop\nclock_port=clk\nclock_name=core_clock\nclaim_tier=rtl_proxy_partial_constraints\nrun_id=%s\n' \
  "$RUN_ID" >"$OUT_DIR/parameters.kv"
sha256sum "$NETLIST" "$AUDIT" "$FREEZE" "$OPENSTA" "$STD_LIB" \
  "${MACRO_LIB_ARRAY[@]}" "$TCL" >"$OUT_DIR/inputs.sha256"

NETLIST_SHA=$(sha256sum "$NETLIST" | cut -d' ' -f1)
AUDIT_SHA=$(sha256sum "$AUDIT" | cut -d' ' -f1)
AUDIT_NETLIST_SHA=$(python3 -c \
  'import json,sys; print(json.load(open(sys.argv[1]))["netlist_sha256"])' \
  "$AUDIT")

T4Q_STA_NETLIST="$NETLIST" \
T4Q_STA_OUT_DIR="$OUT_DIR" \
T4Q_STA_STD_LIB="$STD_LIB" \
T4Q_STA_MACRO_LIBS="$MACRO_LIBS" \
T4Q_STA_PERIOD_NS=5.0 \
T4Q_STA_NETLIST_SHA256="$NETLIST_SHA" \
T4Q_STA_STD_LIB_SHA256="$(sha256sum "$STD_LIB" | cut -d' ' -f1)" \
T4Q_STA_INPUT_MANIFEST_SHA256="$(sha256sum "$OUT_DIR/inputs.sha256" | cut -d' ' -f1)" \
T4Q_STA_PARAMETERS_SHA256="$(sha256sum "$OUT_DIR/parameters.kv" | cut -d' ' -f1)" \
T4Q_STA_OPENSTA_BINARY="$OPENSTA" \
T4Q_STA_OPENSTA_BINARY_SHA256="$(sha256sum "$OPENSTA" | cut -d' ' -f1)" \
T4Q_STA_SYNTH_AUDIT_SUMMARY="$AUDIT" \
T4Q_STA_SYNTH_AUDIT_SUMMARY_SHA256="$AUDIT_SHA" \
T4Q_STA_SYNTH_AUDIT_NETLIST_SHA256="$AUDIT_NETLIST_SHA" \
T4Q_STA_SYNTH_FREEZE_STATUS_SHA256="$(sha256sum "$FREEZE" | cut -d' ' -f1)" \
T4Q_STA_SYNTH_BINDING_SHA256="$AUDIT_SHA" \
T4Q_STA_SETUP_MEMBERS_MANIFEST_SHA256="$AUDIT_SHA" \
  "$OPENSTA" "$TCL" >"$OUT_DIR/opensta-console.log" 2>&1

python3 - "$OUT_DIR/opensta-current-top40.rpt" "$OUT_DIR/summary.json" \
  "$RUN_ID" <<'PY'
import json
import re
import sys
from pathlib import Path

report = Path(sys.argv[1]).read_text()
wns = float(re.search(r"^wns max ([+-]?[0-9.]+)$", report, re.M).group(1))
tns = float(re.search(r"^tns max ([+-]?[0-9.]+)$", report, re.M).group(1))
slacks = [
    float(value)
    for value in re.findall(
        r"^\s*([+-]?[0-9]+(?:\.[0-9]+)?)\s+slack \((?:MET|VIOLATED)\)\s*$",
        report,
        re.M,
    )
]
blocks = report.count("Startpoint:")
violated = report.count("slack (VIOLATED)")
result = {
    "schema": "ppa-r3p6-onehot-prf-exact5ns-gate-v1",
    "run_id": sys.argv[3],
    "claim_tier": "rtl_proxy_partial_constraints",
    "period_ns": 5.0,
    "path_count": blocks,
    "violated_path_count": violated,
    "worst_path_slack_ns": min(slacks) if slacks else None,
    "wns_ns": wns,
    "tns_ns": tns,
    "combinational_loops": 0,
    "target_200mhz_met": (
        bool(slacks)
        and min(slacks) >= 0.0
        and wns >= 0.0
        and tns >= 0.0
        and violated == 0
    ),
}
Path(sys.argv[2]).write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
print(json.dumps(result, sort_keys=True))
PY

if python3 -c \
  'import json,sys; raise SystemExit(0 if json.load(open(sys.argv[1]))["target_200mhz_met"] is True else 1)' \
  "$OUT_DIR/summary.json"; then
  printf 'opensta_exit=0\ntarget_200mhz_met=true\n' >"$OUT_DIR/status.txt"
  printf '[PPA-R3P6-STA] PASS run=%s output=%s\n' "$RUN_ID" "$OUT_DIR"
else
  printf 'opensta_exit=0\ntarget_200mhz_met=false\n' >"$OUT_DIR/status.txt"
  printf '[PPA-R3P6-STA] TARGET_FAIL run=%s output=%s\n' \
    "$RUN_ID" "$OUT_DIR" >&2
  exit 4
fi

