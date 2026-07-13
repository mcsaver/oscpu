#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-13-rv64-t3k-csr-probe-isolation
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
T3J_NETLIST="$ROOT_DIR/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
T3K_NETLIST="$ROOT_DIR/tmp/$TASK_SLUG/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")
RUN_TAG=${T3K_STA_RUN_TAG:-}
TARGET_EXPECT=${T3K_STA_EXPECT_TARGET:-miss}
if [[ -n $RUN_TAG && ! $RUN_TAG =~ ^-[a-z0-9][a-z0-9-]*$ ]]; then
  printf 'invalid T3K_STA_RUN_TAG: %s\n' "$RUN_TAG" >&2
  exit 64
fi
if [[ $TARGET_EXPECT != met && $TARGET_EXPECT != miss ]]; then
  printf 'T3K_STA_EXPECT_TARGET must be met or miss, got: %s\n' \
    "$TARGET_EXPECT" >&2
  exit 64
fi

OLD_OUT="$TASK_DIR/evidence/opensta-focused-old-t3j$RUN_TAG"
FRESH_OUT="$TASK_DIR/evidence/opensta-focused-fresh-t3k$RUN_TAG"
GLOBAL_OUT="$TASK_DIR/evidence/opensta-fresh-t3k$RUN_TAG"
STRUCTURE_OUT="$TASK_DIR/evidence/netlist-structure$RUN_TAG"
FREEZE_OUT="$TASK_DIR/evidence/opensta-freeze$RUN_TAG"
INPUTS=(
  "$T3J_NETLIST"
  "$T3K_NETLIST"
  "$STD_LIB"
  "${MACRO_LIB_ARRAY[@]}"
  "$OPENSTA"
  "$TASK_DIR/opensta-t3k-current-5ns.tcl"
  "$TASK_DIR/opensta-t3k-csr-focused.tcl"
  "$TASK_DIR/check-t3k-global-sta.py"
  "$TASK_DIR/check-t3k-focused-sta.py"
  "$TASK_DIR/check-t3k-target-200mhz.py"
  "$TASK_DIR/check-t3k-netlist-structure.py"
  "$TASK_DIR/run-opensta-evidence.sh"
)

require_inputs() {
  local path
  for path in "$@"; do
    if [[ ! -f $path || -L $path || ! -s $path ]]; then
      printf '[T3K-OPENSTA] missing, empty, symlink, or non-regular input: %s\n' \
        "$path" >&2
      exit 2
    fi
  done
}

write_parameters() {
  local output=$1
  {
    printf 'period_ns=5.0\n'
    printf 'top=NpcTop\n'
    printf 'clock_port=clk\n'
    printf 'clock_name=core_clock\n'
    printf 'old_expect=old\n'
    printf 'fresh_expect=fresh\n'
    printf 'target_expect=%s\n' "$TARGET_EXPECT"
    printf 'old_netlist=%s\n' "$T3J_NETLIST"
    printf 'fresh_netlist=%s\n' "$T3K_NETLIST"
    printf 'std_lib=%s\n' "$STD_LIB"
    printf 'macro_libs=%s\n' "$MACRO_LIBS"
    printf 'opensta_binary=%s\n' "$OPENSTA"
  } >"$output"
}

write_versions() {
  local output=$1
  printf 'opensta=%s\n' "$($OPENSTA -version)" >"$output"
}

require_inputs "${INPUTS[@]}"
for output in "$OLD_OUT" "$FRESH_OUT" "$GLOBAL_OUT" "$STRUCTURE_OUT" "$FREEZE_OUT"; do
  if [[ -e $output ]]; then
    printf '[T3K-OPENSTA] refusing stale output: %s\n' "$output" >&2
    exit 3
  fi
done
mkdir -p "$OLD_OUT" "$FRESH_OUT" "$GLOBAL_OUT" "$STRUCTURE_OUT" "$FREEZE_OUT"
sha256sum "${INPUTS[@]}" >"$FREEZE_OUT/opensta-inputs.pre.sha256"
write_parameters "$FREEZE_OUT/opensta-parameters.pre.kv"
write_versions "$FREEZE_OUT/opensta-tool-version.pre.kv"
INPUT_MANIFEST_SHA256=$(sha256sum "$FREEZE_OUT/opensta-inputs.pre.sha256" | cut -d' ' -f1)
PARAMETERS_SHA256=$(sha256sum "$FREEZE_OUT/opensta-parameters.pre.kv" | cut -d' ' -f1)
OPENSTA_SHA256=$(sha256sum "$OPENSTA" | cut -d' ' -f1)
STD_LIB_SHA256=$(sha256sum "$STD_LIB" | cut -d' ' -f1)
T3J_SHA256=$(sha256sum "$T3J_NETLIST" | cut -d' ' -f1)
T3K_SHA256=$(sha256sum "$T3K_NETLIST" | cut -d' ' -f1)

set +e
python3 "$TASK_DIR/check-t3k-netlist-structure.py" --expect fresh \
  --std-lib "$STD_LIB" "$T3J_NETLIST" \
  >"$STRUCTURE_OUT/old-t3j-expected-fresh-red.log" 2>&1
structure_red_rc=$?
set -e
printf 'expected_fresh_on_old_rc=%s\n' "$structure_red_rc" \
  >"$STRUCTURE_OUT/old-t3j-expected-fresh-red-status.txt"
if [[ $structure_red_rc -ne 1 ]]; then
  printf '[T3K-OPENSTA] old T3J did not reject fresh structure contract\n' >&2
  exit 4
fi
python3 "$TASK_DIR/check-t3k-netlist-structure.py" --expect old \
  --std-lib "$STD_LIB" "$T3J_NETLIST" \
  >"$STRUCTURE_OUT/old-t3j.log" 2>&1
python3 "$TASK_DIR/check-t3k-netlist-structure.py" --expect fresh \
  --std-lib "$STD_LIB" "$T3K_NETLIST" \
  >"$STRUCTURE_OUT/fresh-t3k.log" 2>&1

T3K_STA_NETLIST="$T3J_NETLIST" \
T3K_STA_OUT_DIR="$OLD_OUT" \
T3K_STA_STD_LIB="$STD_LIB" \
T3K_STA_MACRO_LIBS="$MACRO_LIBS" \
T3K_STA_PERIOD_NS=5.0 \
T3K_STA_EXPECT_PROBE=old \
T3K_STA_NETLIST_SHA256="$T3J_SHA256" \
T3K_STA_INPUT_MANIFEST_SHA256="$INPUT_MANIFEST_SHA256" \
T3K_STA_PARAMETERS_SHA256="$PARAMETERS_SHA256" \
  "$OPENSTA" "$TASK_DIR/opensta-t3k-csr-focused.tcl" \
  >"$OLD_OUT/opensta-console.log" 2>&1
python3 "$TASK_DIR/check-t3k-focused-sta.py" --expect old \
  --expected-netlist "$T3J_NETLIST" \
  --expected-input-manifest "$FREEZE_OUT/opensta-inputs.pre.sha256" \
  --expected-parameters "$FREEZE_OUT/opensta-parameters.pre.kv" \
  "$OLD_OUT" >"$OLD_OUT/checker.log" 2>&1

T3K_STA_NETLIST="$T3K_NETLIST" \
T3K_STA_OUT_DIR="$FRESH_OUT" \
T3K_STA_STD_LIB="$STD_LIB" \
T3K_STA_MACRO_LIBS="$MACRO_LIBS" \
T3K_STA_PERIOD_NS=5.0 \
T3K_STA_EXPECT_PROBE=fresh \
T3K_STA_NETLIST_SHA256="$T3K_SHA256" \
T3K_STA_INPUT_MANIFEST_SHA256="$INPUT_MANIFEST_SHA256" \
T3K_STA_PARAMETERS_SHA256="$PARAMETERS_SHA256" \
  "$OPENSTA" "$TASK_DIR/opensta-t3k-csr-focused.tcl" \
  >"$FRESH_OUT/opensta-console.log" 2>&1
python3 "$TASK_DIR/check-t3k-focused-sta.py" --expect fresh \
  --expected-netlist "$T3K_NETLIST" \
  --expected-input-manifest "$FREEZE_OUT/opensta-inputs.pre.sha256" \
  --expected-parameters "$FREEZE_OUT/opensta-parameters.pre.kv" \
  "$FRESH_OUT" >"$FRESH_OUT/checker.log" 2>&1

T3K_STA_NETLIST="$T3K_NETLIST" \
T3K_STA_OUT_DIR="$GLOBAL_OUT" \
T3K_STA_STD_LIB="$STD_LIB" \
T3K_STA_MACRO_LIBS="$MACRO_LIBS" \
T3K_STA_PERIOD_NS=5.0 \
T3K_STA_NETLIST_SHA256="$T3K_SHA256" \
T3K_STA_STD_LIB_SHA256="$STD_LIB_SHA256" \
T3K_STA_INPUT_MANIFEST_SHA256="$INPUT_MANIFEST_SHA256" \
T3K_STA_PARAMETERS_SHA256="$PARAMETERS_SHA256" \
T3K_STA_OPENSTA_BINARY="$OPENSTA" \
T3K_STA_OPENSTA_BINARY_SHA256="$OPENSTA_SHA256" \
  "$OPENSTA" "$TASK_DIR/opensta-t3k-current-5ns.tcl" \
  >"$GLOBAL_OUT/opensta-console.log" 2>&1
python3 "$TASK_DIR/check-t3k-global-sta.py" "$GLOBAL_OUT" \
  --expected-netlist "$T3K_NETLIST" \
  --expected-std-lib "$STD_LIB" \
  --expected-opensta-binary "$OPENSTA" \
  --expected-input-manifest "$FREEZE_OUT/opensta-inputs.pre.sha256" \
  --expected-parameters "$FREEZE_OUT/opensta-parameters.pre.kv" \
  --json-out "$GLOBAL_OUT/summary.json" \
  >"$GLOBAL_OUT/checker.log" 2>&1
python3 "$TASK_DIR/check-t3k-target-200mhz.py" \
  --expect "$TARGET_EXPECT" "$GLOBAL_OUT/summary.json" \
  >"$GLOBAL_OUT/target-200mhz.log" 2>&1

sha256sum "${INPUTS[@]}" >"$FREEZE_OUT/opensta-inputs.post.sha256"
write_parameters "$FREEZE_OUT/opensta-parameters.post.kv"
write_versions "$FREEZE_OUT/opensta-tool-version.post.kv"
input_status=FAIL
parameter_status=FAIL
version_status=FAIL
cmp -s "$FREEZE_OUT/opensta-inputs.pre.sha256" \
  "$FREEZE_OUT/opensta-inputs.post.sha256" && input_status=PASS
cmp -s "$FREEZE_OUT/opensta-parameters.pre.kv" \
  "$FREEZE_OUT/opensta-parameters.post.kv" && parameter_status=PASS
cmp -s "$FREEZE_OUT/opensta-tool-version.pre.kv" \
  "$FREEZE_OUT/opensta-tool-version.post.kv" && version_status=PASS
{
  printf 'inputs=%s\n' "$input_status"
  printf 'parameters=%s\n' "$parameter_status"
  printf 'tool_version=%s\n' "$version_status"
} >"$FREEZE_OUT/opensta-freeze-status.txt"
if [[ $input_status != PASS || $parameter_status != PASS || $version_status != PASS ]]; then
  printf '[T3K-OPENSTA] input freeze violated\n' >&2
  exit 94
fi

printf '[T3K-OPENSTA] PASS tag=%s old=T3J fresh=T3K global=5ns target=%s\n' \
  "${RUN_TAG:-<default>}" "$TARGET_EXPECT"
