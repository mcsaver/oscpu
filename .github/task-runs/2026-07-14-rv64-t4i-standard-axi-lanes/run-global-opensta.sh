#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-14-rv64-t4i-standard-axi-lanes
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$TASK_SLUG"
STA_LABEL=T4I
STA_OUT_STEM=opensta-fresh-t4i
OPENSTA_SCRIPT_INPUT="$TASK_DIR/run-global-opensta.sh"
T3L_TASK="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3l-branch-target-split"
T4D_TASK="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t4d-plic-priority-warl"
COMMON_SYNTH_TASK="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3p-lane1-simple-owner"
STA_CHECKER="$TASK_DIR/check-t4i-global-sta.py"
TARGET_CHECKER="$TASK_DIR/check-t4i-target-200mhz.py"
BINDING_CHECKER="$TASK_DIR/check-t4i-synth-binding.py"
FINALIZER="$TASK_DIR/finalize-t4i-sta-attestation.py"
HARDENING_TEST="$TASK_DIR/test-t4i-evidence-hardening.py"
STA_TCL="$TASK_DIR/opensta-t4i-current-5ns.tcl"
SETUP_DERIVER="$TASK_DIR/derive-t4i-setup-members.py"
SETUP_MANIFEST="$TASK_DIR/t4i-setup-members.json"
BASE_SETUP="$T4D_TASK/evidence/opensta-fresh-t4d-checker-v2/opensta-current-check-setup.txt"
AUDIT_SCRIPT="$COMMON_SYNTH_TASK/audit-t3p-synthesis.py"
CANONICAL_SYNTH_AUDIT="$TASK_DIR/evidence/synthesis/summary.json"
PREVIOUS_NETLIST="$ROOT_DIR/tmp/2026-07-14-rv64-t4d-plic-priority-warl/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
NETLIST="$TMP_DIR/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
SYNTH_FREEZE_STATUS="$TMP_DIR/synth-input-hash-cmp.txt"
SYNTH_EXIT_STATUS="$TMP_DIR/synth-exit-status.txt"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")
RUN_TAG=${STA_RUN_TAG:--final}
TARGET_EXPECT=${STA_EXPECT_TARGET:-met}
if [[ ! $RUN_TAG =~ ^-[a-z0-9][a-z0-9-]*$ ]]; then
  printf 'invalid STA_RUN_TAG: %s\n' "$RUN_TAG" >&2
  exit 64
fi
if [[ $TARGET_EXPECT != any && $TARGET_EXPECT != met && $TARGET_EXPECT != miss ]]; then
  printf 'STA_EXPECT_TARGET must be any, met, or miss; got %s\n' \
    "$TARGET_EXPECT" >&2
  exit 64
fi

GLOBAL_OUT="$TASK_DIR/evidence/$STA_OUT_STEM$RUN_TAG"
FREEZE_OUT="$TASK_DIR/evidence/opensta-freeze$RUN_TAG"
for output in "$GLOBAL_OUT" "$FREEZE_OUT"; do
  [[ ! -e $output ]] || {
    printf '[%s-OPENSTA] refusing stale output: %s\n' \
      "$STA_LABEL" "$output" >&2
    exit 3
  }
done
mkdir -p "$GLOBAL_OUT" "$FREEZE_OUT"

python3 "$SETUP_DERIVER" "$BASE_SETUP" \
  --output "$FREEZE_OUT/t4i-setup-members.generated.json" \
  >"$FREEZE_OUT/setup-members-derivation.log" 2>&1
cmp -s "$SETUP_MANIFEST" "$FREEZE_OUT/t4i-setup-members.generated.json" || {
  printf '[%s-OPENSTA] canonical/regenerated setup manifest mismatch\n' \
    "$STA_LABEL" >&2
  exit 96
}
printf 'canonical_vs_regenerated=PASS\n' \
  >"$FREEZE_OUT/setup-members-derivation-status.txt"

python3 "$AUDIT_SCRIPT" "$TMP_DIR" \
  --json-out "$GLOBAL_OUT/synth-audit.pre.json" \
  --prefix T4I-SYNTH-AUDIT-STA-PRE \
  --expected-rtl-count 114 \
  --expected-evidence-count 7 \
  --expected-module-count 116 \
  --previous-netlist "$PREVIOUS_NETLIST" \
  >"$GLOBAL_OUT/synth-audit.pre.log" 2>&1
cmp -s "$CANONICAL_SYNTH_AUDIT" "$GLOBAL_OUT/synth-audit.pre.json" || {
  printf '[%s-OPENSTA] canonical/pre synthesis audit mismatch\n' "$STA_LABEL" >&2
  exit 95
}
python3 "$BINDING_CHECKER" \
  --audit-summary "$CANONICAL_SYNTH_AUDIT" \
  --netlist "$NETLIST" \
  --freeze-status "$SYNTH_FREEZE_STATUS" \
  --exit-status "$SYNTH_EXIT_STATUS" \
  --json-out "$GLOBAL_OUT/synth-binding.pre.json" \
  >"$GLOBAL_OUT/synth-binding.pre.log" 2>&1

SYNTH_AUDIT_SUMMARY_SHA256=$(sha256sum "$CANONICAL_SYNTH_AUDIT" | cut -d' ' -f1)
SYNTH_AUDIT_NETLIST_SHA256=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["netlist_sha256"])' "$CANONICAL_SYNTH_AUDIT")
SYNTH_FREEZE_STATUS_SHA256=$(sha256sum "$SYNTH_FREEZE_STATUS" | cut -d' ' -f1)
SYNTH_BINDING_SHA256=$(sha256sum "$GLOBAL_OUT/synth-binding.pre.json" | cut -d' ' -f1)
SETUP_MANIFEST_SHA256=$(sha256sum "$SETUP_MANIFEST" | cut -d' ' -f1)
INPUTS=(
  "$NETLIST"
  "$TMP_DIR/sta-build/NpcTop-200MHz/NpcTop.netlist.v.sim"
  "$TMP_DIR/sta-build/NpcTop-200MHz/yosys.log"
  "$TMP_DIR/sta-build/NpcTop-200MHz/synth_check.txt"
  "$TMP_DIR/sta-build/NpcTop-200MHz/synth_stat.txt"
  "$TMP_DIR/sta-build/NpcTop-200MHz/abc.sdc"
  "$TMP_DIR/synth-console.log"
  "$SYNTH_EXIT_STATUS"
  "$SYNTH_FREEZE_STATUS"
  "$TMP_DIR/synth-provenance.pre.kv"
  "$TMP_DIR/synth-rtl-inputs.pre.sha256"
  "$TMP_DIR/synth-rtl-inputs.post.sha256"
  "$TMP_DIR/synth-vsrc-tree.pre.sha256"
  "$TMP_DIR/synth-vsrc-tree.post.sha256"
  "$TMP_DIR/synth-flow-inputs.pre.sha256"
  "$TMP_DIR/synth-flow-inputs.post.sha256"
  "$TMP_DIR/synth-liberty-inputs.pre.sha256"
  "$TMP_DIR/synth-liberty-inputs.post.sha256"
  "$TMP_DIR/synth-evidence-inputs.pre.sha256"
  "$TMP_DIR/synth-evidence-inputs.post.sha256"
  "$TMP_DIR/synth-tool-binaries.pre.sha256"
  "$TMP_DIR/synth-tool-binaries.post.sha256"
  "$TMP_DIR/synth-parameters.pre.kv"
  "$TMP_DIR/synth-parameters.post.kv"
  "$TMP_DIR/synth-tool-versions.pre.kv"
  "$TMP_DIR/synth-tool-versions.post.kv"
  "$CANONICAL_SYNTH_AUDIT"
  "$GLOBAL_OUT/synth-audit.pre.json"
  "$GLOBAL_OUT/synth-audit.pre.log"
  "$GLOBAL_OUT/synth-binding.pre.json"
  "$GLOBAL_OUT/synth-binding.pre.log"
  "$AUDIT_SCRIPT"
  "$BINDING_CHECKER"
  "$FINALIZER"
  "$HARDENING_TEST"
  "$PREVIOUS_NETLIST"
  "$STD_LIB"
  "${MACRO_LIB_ARRAY[@]}"
  "$OPENSTA"
  "$STA_TCL"
  "$T3L_TASK/check-t3l-global-sta.py"
  "$STA_CHECKER"
  "$TARGET_CHECKER"
  "$SETUP_DERIVER"
  "$SETUP_MANIFEST"
  "$FREEZE_OUT/t4i-setup-members.generated.json"
  "$FREEZE_OUT/setup-members-derivation.log"
  "$FREEZE_OUT/setup-members-derivation-status.txt"
  "$BASE_SETUP"
  "$OPENSTA_SCRIPT_INPUT"
)

require_inputs() {
  local path
  for path in "$@"; do
    if [[ ! -f $path || -L $path || ! -s $path ]]; then
      printf '[%s-OPENSTA] missing, empty, symlink, or non-regular input: %s\n' \
        "$STA_LABEL" "$path" >&2
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
    printf 'target_expect=%s\n' "$TARGET_EXPECT"
    printf 'netlist=%s\n' "$NETLIST"
    printf 'std_lib=%s\n' "$STD_LIB"
    printf 'macro_libs=%s\n' "$MACRO_LIBS"
    printf 'opensta_binary=%s\n' "$OPENSTA"
    printf 'synth_audit_summary=%s\n' "$CANONICAL_SYNTH_AUDIT"
    printf 'synth_audit_summary_sha256=%s\n' "$SYNTH_AUDIT_SUMMARY_SHA256"
    printf 'synth_audit_netlist_sha256=%s\n' "$SYNTH_AUDIT_NETLIST_SHA256"
    printf 'synth_freeze_status_sha256=%s\n' "$SYNTH_FREEZE_STATUS_SHA256"
    printf 'synth_binding_sha256=%s\n' "$SYNTH_BINDING_SHA256"
    printf 'setup_members_manifest_sha256=%s\n' "$SETUP_MANIFEST_SHA256"
  } >"$output"
}

require_inputs "${INPUTS[@]}"
sha256sum "${INPUTS[@]}" >"$FREEZE_OUT/opensta-inputs.pre.sha256"
write_parameters "$FREEZE_OUT/opensta-parameters.pre.kv"
printf 'opensta=%s\n' "$($OPENSTA -version)" \
  >"$FREEZE_OUT/opensta-tool-version.pre.kv"
INPUT_MANIFEST_SHA256=$(sha256sum "$FREEZE_OUT/opensta-inputs.pre.sha256" | cut -d' ' -f1)
PARAMETERS_SHA256=$(sha256sum "$FREEZE_OUT/opensta-parameters.pre.kv" | cut -d' ' -f1)
OPENSTA_SHA256=$(sha256sum "$OPENSTA" | cut -d' ' -f1)
STD_LIB_SHA256=$(sha256sum "$STD_LIB" | cut -d' ' -f1)
NETLIST_SHA256=$(sha256sum "$NETLIST" | cut -d' ' -f1)

T4I_STA_NETLIST="$NETLIST" \
T4I_STA_OUT_DIR="$GLOBAL_OUT" \
T4I_STA_STD_LIB="$STD_LIB" \
T4I_STA_MACRO_LIBS="$MACRO_LIBS" \
T4I_STA_PERIOD_NS=5.0 \
T4I_STA_NETLIST_SHA256="$NETLIST_SHA256" \
T4I_STA_STD_LIB_SHA256="$STD_LIB_SHA256" \
T4I_STA_INPUT_MANIFEST_SHA256="$INPUT_MANIFEST_SHA256" \
T4I_STA_PARAMETERS_SHA256="$PARAMETERS_SHA256" \
T4I_STA_OPENSTA_BINARY="$OPENSTA" \
T4I_STA_OPENSTA_BINARY_SHA256="$OPENSTA_SHA256" \
T4I_STA_SYNTH_AUDIT_SUMMARY="$CANONICAL_SYNTH_AUDIT" \
T4I_STA_SYNTH_AUDIT_SUMMARY_SHA256="$SYNTH_AUDIT_SUMMARY_SHA256" \
T4I_STA_SYNTH_AUDIT_NETLIST_SHA256="$SYNTH_AUDIT_NETLIST_SHA256" \
T4I_STA_SYNTH_FREEZE_STATUS_SHA256="$SYNTH_FREEZE_STATUS_SHA256" \
T4I_STA_SYNTH_BINDING_SHA256="$SYNTH_BINDING_SHA256" \
  "$OPENSTA" "$STA_TCL" \
  >"$GLOBAL_OUT/opensta-console.log" 2>&1
python3 "$STA_CHECKER" "$GLOBAL_OUT" \
  --expected-netlist "$NETLIST" \
  --expected-std-lib "$STD_LIB" \
  --expected-opensta-binary "$OPENSTA" \
  --expected-input-manifest "$FREEZE_OUT/opensta-inputs.pre.sha256" \
  --expected-parameters "$FREEZE_OUT/opensta-parameters.pre.kv" \
  --json-out "$GLOBAL_OUT/summary.json" \
  >"$GLOBAL_OUT/checker.log" 2>&1
python3 "$AUDIT_SCRIPT" "$TMP_DIR" \
  --json-out "$GLOBAL_OUT/synth-audit.post.json" \
  --prefix T4I-SYNTH-AUDIT-STA-POST \
  --expected-rtl-count 114 \
  --expected-evidence-count 7 \
  --expected-module-count 116 \
  --previous-netlist "$PREVIOUS_NETLIST" \
  >"$GLOBAL_OUT/synth-audit.post.log" 2>&1
cmp -s "$CANONICAL_SYNTH_AUDIT" "$GLOBAL_OUT/synth-audit.post.json" || {
  printf '[%s-OPENSTA] canonical/post synthesis audit mismatch\n' "$STA_LABEL" >&2
  exit 95
}
python3 "$BINDING_CHECKER" \
  --audit-summary "$CANONICAL_SYNTH_AUDIT" \
  --netlist "$NETLIST" \
  --freeze-status "$SYNTH_FREEZE_STATUS" \
  --exit-status "$SYNTH_EXIT_STATUS" \
  --json-out "$GLOBAL_OUT/synth-binding.post.json" \
  >"$GLOBAL_OUT/synth-binding.post.log" 2>&1
cmp -s "$GLOBAL_OUT/synth-binding.pre.json" "$GLOBAL_OUT/synth-binding.post.json" || {
  printf '[%s-OPENSTA] pre/post synthesis binding mismatch\n' "$STA_LABEL" >&2
  exit 95
}
{
  printf 'canonical_vs_pre_audit=PASS\n'
  printf 'canonical_vs_post_audit=PASS\n'
  printf 'pre_vs_post_binding=PASS\n'
} >"$FREEZE_OUT/synth-binding-status.txt"

sha256sum "${INPUTS[@]}" >"$FREEZE_OUT/opensta-inputs.post.sha256"
write_parameters "$FREEZE_OUT/opensta-parameters.post.kv"
printf 'opensta=%s\n' "$($OPENSTA -version)" \
  >"$FREEZE_OUT/opensta-tool-version.post.kv"
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
  printf '[%s-OPENSTA] input freeze violated\n' "$STA_LABEL" >&2
  exit 94
fi
python3 "$FINALIZER" \
  --summary "$GLOBAL_OUT/summary.json" \
  --synth-binding-status "$FREEZE_OUT/synth-binding-status.txt" \
  --opensta-freeze-status "$FREEZE_OUT/opensta-freeze-status.txt" \
  --setup-derivation-status "$FREEZE_OUT/setup-members-derivation-status.txt" \
  --json-out "$GLOBAL_OUT/final-attestation.json" \
  >"$GLOBAL_OUT/final-attestation.log" 2>&1
if [[ $TARGET_EXPECT != any ]]; then
  python3 "$TARGET_CHECKER" \
    --attestation "$GLOBAL_OUT/final-attestation.json" \
    --expect "$TARGET_EXPECT" "$GLOBAL_OUT/summary.json" \
    >"$GLOBAL_OUT/target-200mhz.log" 2>&1
fi
printf '[%s-OPENSTA] PASS tag=%s global=5ns target=%s\n' \
  "$STA_LABEL" "$RUN_TAG" "$TARGET_EXPECT"
