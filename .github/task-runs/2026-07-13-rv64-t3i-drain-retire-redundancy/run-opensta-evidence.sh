#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3i-drain-retire-redundancy"
T3H_NETLIST="$ROOT_DIR/tmp/2026-07-13-rv64-t3h-fp-sticky-barrier/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
T3I_NETLIST="$ROOT_DIR/tmp/2026-07-13-rv64-t3i-drain-retire-redundancy/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
FLOW_OPENSTA_TCL="$ROOT_DIR/yosys-sta/scripts/opensta-fullcore.tcl"
MACRO_LIBS="$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib:$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
OLD_OUT="$TASK_DIR/evidence/opensta-focused-old-t3h"
FRESH_OUT="$TASK_DIR/evidence/opensta-focused-fresh"
GLOBAL_OUT="$TASK_DIR/evidence/opensta-fresh"

for path in "$OPENSTA" "$STD_LIB" "$FLOW_OPENSTA_TCL" "$T3H_NETLIST" "$T3I_NETLIST"; do
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
  printf 'OpenSTA standard liberty does not match the synthesis H7CL flow: configured=%s flow=%s\n' \
    "$STD_LIB" "$FLOW_STD_LIB" >&2
  exit 2
fi
T3H_NETLIST_SHA256=$(sha256sum "$T3H_NETLIST" | cut -d' ' -f1)
T3I_NETLIST_SHA256=$(sha256sum "$T3I_NETLIST" | cut -d' ' -f1)
for out_dir in "$OLD_OUT" "$FRESH_OUT" "$GLOBAL_OUT"; do
  if [[ -e $out_dir ]]; then
    printf 'refusing stale OpenSTA output directory: %s\n' "$out_dir" >&2
    exit 3
  fi
done
for out_dir in "$OLD_OUT" "$FRESH_OUT" "$GLOBAL_OUT"; do
  mkdir -p "$out_dir"
done

set +e
python3 "$TASK_DIR/check-t3i-netlist-structure.py" --expect absent "$T3H_NETLIST" \
  >"$TASK_DIR/evidence/netlist-structure-old-expected-fail.log" 2>&1
red_rc=$?
set -e
printf 'expected_absent_on_old_rc=%s\n' "$red_rc" \
  >"$TASK_DIR/evidence/netlist-structure-old-red-status.txt"
if [[ $red_rc -ne 1 ]]; then
  printf 'old T3H netlist did not fail the T3I absent-port contract\n' >&2
  exit 4
fi
python3 "$TASK_DIR/check-t3i-netlist-structure.py" --expect present "$T3H_NETLIST" \
  >"$TASK_DIR/evidence/netlist-structure-old-present.log" 2>&1
python3 "$TASK_DIR/check-t3i-netlist-structure.py" --expect absent "$T3I_NETLIST" \
  >"$TASK_DIR/evidence/netlist-structure-fresh.log" 2>&1

T3I_STA_NETLIST="$T3H_NETLIST" \
T3I_STA_OUT_DIR="$OLD_OUT" \
T3I_STA_STD_LIB="$STD_LIB" \
T3I_STA_MACRO_LIBS="$MACRO_LIBS" \
T3I_STA_PERIOD_NS=5.0 \
T3I_STA_EXPECT_RETIRED_PORTS=present \
T3I_STA_NETLIST_SHA256="$T3H_NETLIST_SHA256" \
  "$OPENSTA" "$TASK_DIR/opensta-t3i-drain-focused.tcl" \
  >"$OLD_OUT/opensta-console.log" 2>&1
python3 "$TASK_DIR/check-t3i-opensta-focused.py" --expect present \
  --expected-netlist "$T3H_NETLIST" "$OLD_OUT" \
  >"$OLD_OUT/checker.log" 2>&1

T3I_STA_NETLIST="$T3I_NETLIST" \
T3I_STA_OUT_DIR="$FRESH_OUT" \
T3I_STA_STD_LIB="$STD_LIB" \
T3I_STA_MACRO_LIBS="$MACRO_LIBS" \
T3I_STA_PERIOD_NS=5.0 \
T3I_STA_EXPECT_RETIRED_PORTS=absent \
T3I_STA_NETLIST_SHA256="$T3I_NETLIST_SHA256" \
  "$OPENSTA" "$TASK_DIR/opensta-t3i-drain-focused.tcl" \
  >"$FRESH_OUT/opensta-console.log" 2>&1
python3 "$TASK_DIR/check-t3i-opensta-focused.py" --expect absent \
  --expected-netlist "$T3I_NETLIST" "$FRESH_OUT" \
  >"$FRESH_OUT/checker.log" 2>&1

T3I_STA_NETLIST="$T3I_NETLIST" \
T3I_STA_OUT_DIR="$GLOBAL_OUT" \
T3I_STA_STD_LIB="$STD_LIB" \
T3I_STA_MACRO_LIBS="$MACRO_LIBS" \
T3I_STA_PERIOD_NS=5.0 \
T3I_STA_NETLIST_SHA256="$T3I_NETLIST_SHA256" \
  "$OPENSTA" "$TASK_DIR/opensta-t3i-current-5ns.tcl" \
  >"$GLOBAL_OUT/opensta-console.log" 2>&1
python3 "$TASK_DIR/check-t3i-global-sta.py" "$GLOBAL_OUT" \
  --expected-netlist "$T3I_NETLIST" \
  --json-out "$GLOBAL_OUT/summary.json" \
  >"$GLOBAL_OUT/checker.log" 2>&1

printf '[T3I-OPENSTA] PASS old-focused fresh-focused fresh-global\n'
