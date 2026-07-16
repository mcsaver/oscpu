#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane"
NETLIST="$ROOT_DIR/tmp/2026-07-14-rv64-t3v-predecode-mem-dataplane/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
OUT_DIR="$TASK_DIR/evidence/whatif-mask-dcache"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")
TCL="$TASK_DIR/opensta-whatif-mask-dcache.tcl"
SCRIPT="$TASK_DIR/run-whatif-mask-dcache.sh"
INPUTS=("$NETLIST" "$OPENSTA" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}" "$TCL" "$SCRIPT")

[[ ! -e $OUT_DIR ]] || {
  printf '[T3V-WHATIF-DCACHE] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 3
}
for input in "${INPUTS[@]}"; do
  [[ -f $input && ! -L $input && -s $input ]] || {
    printf '[T3V-WHATIF-DCACHE] invalid input: %s\n' "$input" >&2
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
printf '[T3V-WHATIF-DCACHE] PASS exploratory-only\n'
