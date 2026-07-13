#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-13-rv64-t3j-fetch-read-window
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
T3I_NETLIST="$ROOT_DIR/tmp/2026-07-13-rv64-t3i-drain-retire-redundancy/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
T3J_NETLIST="$ROOT_DIR/tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
FLOW_OPENSTA_TCL="$ROOT_DIR/yosys-sta/scripts/opensta-fullcore.tcl"
MACRO_LIBS="$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
RUN_TAG=${T3J_STA_RUN_TAG:-}
if [[ -n $RUN_TAG && ! $RUN_TAG =~ ^-[a-z0-9][a-z0-9-]*$ ]]; then
  printf 'invalid T3J_STA_RUN_TAG (expected empty or -[a-z0-9][a-z0-9-]*): %s\n' \
    "$RUN_TAG" >&2
  exit 64
fi
OLD_OUT="$TASK_DIR/evidence/opensta-focused-old-t3i$RUN_TAG"
FRESH_OUT="$TASK_DIR/evidence/opensta-focused-fresh-t3j$RUN_TAG"
GLOBAL_OUT="$TASK_DIR/evidence/opensta-fresh-t3j$RUN_TAG"
if [[ -n $RUN_TAG ]]; then
  STRUCTURE_OUT="$TASK_DIR/evidence/netlist-structure$RUN_TAG"
  STRUCTURE_RED_LOG="$STRUCTURE_OUT/old-t3i-expected-fresh-fail.log"
  STRUCTURE_RED_STATUS="$STRUCTURE_OUT/old-t3i-red-status.txt"
  STRUCTURE_OLD_LOG="$STRUCTURE_OUT/old-t3i.log"
  STRUCTURE_FRESH_LOG="$STRUCTURE_OUT/fresh-t3j.log"
else
  STRUCTURE_OUT=
  STRUCTURE_RED_LOG="$TASK_DIR/evidence/netlist-structure-old-t3i-expected-fresh-fail-final.log"
  STRUCTURE_RED_STATUS="$TASK_DIR/evidence/netlist-structure-old-t3i-red-status-final.txt"
  STRUCTURE_OLD_LOG="$TASK_DIR/evidence/netlist-structure-old-t3i-final.log"
  STRUCTURE_FRESH_LOG="$TASK_DIR/evidence/netlist-structure-fresh-t3j.log"
fi

for path in "$OPENSTA" "$STD_LIB" "$FLOW_OPENSTA_TCL" "$T3I_NETLIST" "$T3J_NETLIST"; do
  [[ -f $path ]] || { printf 'missing OpenSTA input: %s\n' "$path" >&2; exit 2; }
done
IFS=: read -r -a macro_lib_array <<<"$MACRO_LIBS"
for path in "${macro_lib_array[@]}"; do
  [[ -f $path ]] || { printf 'missing OpenSTA macro liberty: %s\n' "$path" >&2; exit 2; }
done
FLOW_STD_LIB=$(awk '$1 == "read_liberty" { print $2; exit }' "$FLOW_OPENSTA_TCL")
if [[ $STD_LIB != *'/ics55_LLSC_H7CL/'* || \
      $(basename "$STD_LIB") != ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib || \
      $(readlink -f "$STD_LIB") != $(readlink -f "$FLOW_STD_LIB") ]]; then
  printf 'OpenSTA standard liberty does not match synthesis H7CL flow: configured=%s flow=%s\n' \
    "$STD_LIB" "$FLOW_STD_LIB" >&2
  exit 2
fi
T3I_NETLIST_SHA256=$(sha256sum "$T3I_NETLIST" | cut -d' ' -f1)
T3J_NETLIST_SHA256=$(sha256sum "$T3J_NETLIST" | cut -d' ' -f1)
output_dirs=("$OLD_OUT" "$FRESH_OUT" "$GLOBAL_OUT")
if [[ -n $STRUCTURE_OUT ]]; then
  output_dirs+=("$STRUCTURE_OUT")
fi
for out_dir in "${output_dirs[@]}"; do
  if [[ -e $out_dir ]]; then
    printf 'refusing stale OpenSTA output directory: %s\n' "$out_dir" >&2
    exit 3
  fi
done
for out_dir in "${output_dirs[@]}"; do
  mkdir -p "$out_dir"
done

set +e
python3 "$TASK_DIR/check-t3j-netlist-structure.py" --expect fresh "$T3I_NETLIST" \
  >"$STRUCTURE_RED_LOG" 2>&1
red_rc=$?
set -e
printf 'expected_fresh_on_old_rc=%s\n' "$red_rc" \
  >"$STRUCTURE_RED_STATUS"
if [[ $red_rc -ne 1 ]]; then
  printf 'old T3I netlist did not fail the T3J fresh read-window contract\n' >&2
  exit 4
fi
python3 "$TASK_DIR/check-t3j-netlist-structure.py" --expect old "$T3I_NETLIST" \
  >"$STRUCTURE_OLD_LOG" 2>&1
python3 "$TASK_DIR/check-t3j-netlist-structure.py" --expect fresh "$T3J_NETLIST" \
  >"$STRUCTURE_FRESH_LOG" 2>&1

T3J_STA_NETLIST="$T3I_NETLIST" \
T3J_STA_OUT_DIR="$OLD_OUT" \
T3J_STA_STD_LIB="$STD_LIB" \
T3J_STA_MACRO_LIBS="$MACRO_LIBS" \
T3J_STA_PERIOD_NS=5.0 \
T3J_STA_EXPECT_READ_WINDOW=old \
T3J_STA_NETLIST_SHA256="$T3I_NETLIST_SHA256" \
  "$OPENSTA" "$TASK_DIR/opensta-t3j-fetch-focused.tcl" \
  >"$OLD_OUT/opensta-console.log" 2>&1
python3 "$TASK_DIR/check-t3j-opensta-focused.py" --expect old \
  --expected-netlist "$T3I_NETLIST" "$OLD_OUT" \
  >"$OLD_OUT/checker.log" 2>&1

T3J_STA_NETLIST="$T3J_NETLIST" \
T3J_STA_OUT_DIR="$FRESH_OUT" \
T3J_STA_STD_LIB="$STD_LIB" \
T3J_STA_MACRO_LIBS="$MACRO_LIBS" \
T3J_STA_PERIOD_NS=5.0 \
T3J_STA_EXPECT_READ_WINDOW=fresh \
T3J_STA_NETLIST_SHA256="$T3J_NETLIST_SHA256" \
  "$OPENSTA" "$TASK_DIR/opensta-t3j-fetch-focused.tcl" \
  >"$FRESH_OUT/opensta-console.log" 2>&1
python3 "$TASK_DIR/check-t3j-opensta-focused.py" --expect fresh \
  --expected-netlist "$T3J_NETLIST" "$FRESH_OUT" \
  >"$FRESH_OUT/checker.log" 2>&1

T3J_STA_NETLIST="$T3J_NETLIST" \
T3J_STA_OUT_DIR="$GLOBAL_OUT" \
T3J_STA_STD_LIB="$STD_LIB" \
T3J_STA_MACRO_LIBS="$MACRO_LIBS" \
T3J_STA_PERIOD_NS=5.0 \
T3J_STA_NETLIST_SHA256="$T3J_NETLIST_SHA256" \
  "$OPENSTA" "$TASK_DIR/opensta-t3j-current-5ns.tcl" \
  >"$GLOBAL_OUT/opensta-console.log" 2>&1
python3 "$TASK_DIR/check-t3j-global-sta.py" "$GLOBAL_OUT" \
  --expected-netlist "$T3J_NETLIST" \
  --json-out "$GLOBAL_OUT/summary.json" \
  >"$GLOBAL_OUT/checker.log" 2>&1

set +e
python3 "$TASK_DIR/check-t3j-target-200mhz.py" \
  --expect miss "$GLOBAL_OUT/summary.json" \
  >"$GLOBAL_OUT/target-200mhz.log" 2>&1
target_rc=$?
set -e
printf 'expect=miss\nrc=%s\n' "$target_rc" \
  >"$GLOBAL_OUT/target-200mhz-status.txt"
if [[ $target_rc -ne 1 ]]; then
  printf 'T3J target checker did not produce the expected RED rc=1\n' >&2
  exit 5
fi

printf '[T3J-OPENSTA] PASS tag=%s old-T3I focused, fresh-T3J focused, fresh-T3J global; target=expected-RED\n' \
  "${RUN_TAG:-<default>}"
