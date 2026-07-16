#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-15-rv64-t4r-xbar-registered-r
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$TASK_SLUG"
OUT_DIR="$TASK_DIR/evidence/opensta-exact5ns-diagnostic"
T4Q_TASK="$ROOT_DIR/.github/task-runs/2026-07-15-rv64-t4q-final-sta"
NETLIST="$TMP_DIR/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
AUDIT="$TASK_DIR/evidence/synthesis/summary.json"
FREEZE="$TMP_DIR/synth-input-hash-cmp.txt"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIBS="$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"

[[ ! -e $OUT_DIR ]] || { printf '[T4R-STA] refusing stale output: %s\n' "$OUT_DIR" >&2; exit 3; }
for input in "$NETLIST" "$AUDIT" "$FREEZE" "$OPENSTA" "$STD_LIB" \
             "$T4Q_TASK/opensta-t4q-current-5ns.tcl"; do
  [[ -f $input && ! -L $input && -s $input ]] || { printf '[T4R-STA] invalid input: %s\n' "$input" >&2; exit 2; }
done
mkdir -p "$OUT_DIR"
printf 'period_ns=5.0\ntop=NpcTop\nclock_port=clk\nclock_name=core_clock\n' \
  >"$OUT_DIR/parameters.kv"
sha256sum "$NETLIST" "$AUDIT" "$FREEZE" "$OPENSTA" "$STD_LIB" \
  "$T4Q_TASK/opensta-t4q-current-5ns.tcl" >"$OUT_DIR/inputs.sha256"

NETLIST_SHA=$(sha256sum "$NETLIST" | cut -d' ' -f1)
AUDIT_SHA=$(sha256sum "$AUDIT" | cut -d' ' -f1)
AUDIT_NETLIST_SHA=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["netlist_sha256"])' "$AUDIT")
T4Q_STA_NETLIST="$NETLIST" T4Q_STA_OUT_DIR="$OUT_DIR" \
T4Q_STA_STD_LIB="$STD_LIB" T4Q_STA_MACRO_LIBS="$MACRO_LIBS" T4Q_STA_PERIOD_NS=5.0 \
T4Q_STA_NETLIST_SHA256="$NETLIST_SHA" \
T4Q_STA_STD_LIB_SHA256="$(sha256sum "$STD_LIB" | cut -d' ' -f1)" \
T4Q_STA_INPUT_MANIFEST_SHA256="$(sha256sum "$OUT_DIR/inputs.sha256" | cut -d' ' -f1)" \
T4Q_STA_PARAMETERS_SHA256="$(sha256sum "$OUT_DIR/parameters.kv" | cut -d' ' -f1)" \
T4Q_STA_OPENSTA_BINARY="$OPENSTA" \
T4Q_STA_OPENSTA_BINARY_SHA256="$(sha256sum "$OPENSTA" | cut -d' ' -f1)" \
T4Q_STA_SYNTH_AUDIT_SUMMARY="$AUDIT" T4Q_STA_SYNTH_AUDIT_SUMMARY_SHA256="$AUDIT_SHA" \
T4Q_STA_SYNTH_AUDIT_NETLIST_SHA256="$AUDIT_NETLIST_SHA" \
T4Q_STA_SYNTH_FREEZE_STATUS_SHA256="$(sha256sum "$FREEZE" | cut -d' ' -f1)" \
T4Q_STA_SYNTH_BINDING_SHA256="$AUDIT_SHA" T4Q_STA_SETUP_MEMBERS_MANIFEST_SHA256="$AUDIT_SHA" \
  "$OPENSTA" "$T4Q_TASK/opensta-t4q-current-5ns.tcl" >"$OUT_DIR/opensta-console.log" 2>&1

python3 - "$OUT_DIR/opensta-current-top40.rpt" "$OUT_DIR/summary.json" <<'PY'
import json, re, sys
from pathlib import Path
report = Path(sys.argv[1]).read_text()
wns = float(re.search(r"^wns max ([+-]?[0-9.]+)$", report, re.M).group(1))
tns = float(re.search(r"^tns max ([+-]?[0-9.]+)$", report, re.M).group(1))
blocks = report.count("Startpoint:")
violated = report.count("slack (VIOLATED)")
result = {
    "schema": "t4r-exact5ns-diagnostic-v1",
    "period_ns": 5.0,
    "path_count": blocks,
    "violated_path_count": violated,
    "wns_ns": wns,
    "tns_ns": tns,
    "target_200mhz_met": wns >= 0.0 and tns >= 0.0 and violated == 0,
}
Path(sys.argv[2]).write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
print(json.dumps(result, sort_keys=True))
PY

