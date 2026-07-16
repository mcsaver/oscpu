#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-15-rv64-t4s-final-200mhz
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$TASK_SLUG"
COMMON_SYNTH="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3p-lane1-simple-owner"
T3L_TASK="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3l-branch-target-split"
T4Q_TASK="$ROOT_DIR/.github/task-runs/2026-07-15-rv64-t4q-final-sta"
RUN_TAG=${STA_RUN_TAG:--final}
TARGET_EXPECT=${STA_EXPECT_TARGET:-met}
[[ $RUN_TAG =~ ^-[a-z0-9][a-z0-9-]*$ ]] || { printf 'invalid STA_RUN_TAG: %s\n' "$RUN_TAG" >&2; exit 64; }
[[ $TARGET_EXPECT == any || $TARGET_EXPECT == met || $TARGET_EXPECT == miss ]] || {
  printf 'STA_EXPECT_TARGET must be any, met, or miss; got %s\n' "$TARGET_EXPECT" >&2; exit 64;
}

GLOBAL_OUT="$TASK_DIR/evidence/opensta-fresh-t4s$RUN_TAG"
FREEZE_OUT="$TASK_DIR/evidence/opensta-freeze$RUN_TAG"
NETLIST="$TMP_DIR/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
PREVIOUS_NETLIST="$ROOT_DIR/tmp/2026-07-15-rv64-t4r-xbar-registered-r/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
CANONICAL_AUDIT="$TASK_DIR/evidence/synthesis/summary.json"
SYNTH_FREEZE="$TMP_DIR/synth-input-hash-cmp.txt"
SYNTH_EXIT="$TMP_DIR/synth-exit-status.txt"
AUDIT="$T4Q_TASK/audit-t4q-synthesis.py"
BINDING="$T4Q_TASK/check-t4q-synth-binding.py"
CHECKER="$T4Q_TASK/check-t4q-global-sta.py"
TARGET="$T4Q_TASK/check-t4q-target-200mhz.py"
FINALIZER="$T4Q_TASK/finalize-t4q-sta-attestation.py"
DERIVER="$T4Q_TASK/derive-t4q-setup-members.py"
HARDENING="$T4Q_TASK/test-t4q-evidence-hardening.py"
PROBE_TCL="$T4Q_TASK/opensta-t4q-setup-probe.tcl"
STA_TCL="$T4Q_TASK/opensta-t4q-current-5ns.tcl"
OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")

for output in "$GLOBAL_OUT" "$FREEZE_OUT"; do
  [[ ! -e $output ]] || { printf '[T4S-OPENSTA] refusing stale output: %s\n' "$output" >&2; exit 3; }
done
mkdir -p "$GLOBAL_OUT" "$FREEZE_OUT"

require_inputs() {
  local path
  for path in "$@"; do
    [[ -f $path && ! -L $path && -s $path ]] || {
      printf '[T4S-OPENSTA] invalid input: %s\n' "$path" >&2; exit 2;
    }
  done
}

require_inputs "$NETLIST" "$PREVIOUS_NETLIST" "$CANONICAL_AUDIT" "$SYNTH_FREEZE" "$SYNTH_EXIT" \
  "$AUDIT" "$BINDING" "$CHECKER" "$TARGET" "$FINALIZER" "$DERIVER" "$HARDENING" \
  "$PROBE_TCL" "$STA_TCL" "$OPENSTA" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}" \
  "$COMMON_SYNTH/audit-t3p-synthesis.py" "$T3L_TASK/check-t3l-global-sta.py"

python3 "$HARDENING" >"$FREEZE_OUT/hardening-mutations.log" 2>&1
printf 'mutations=PASS\n' >"$FREEZE_OUT/hardening-status.txt"

python3 "$AUDIT" "$TMP_DIR" --json-out "$GLOBAL_OUT/synth-audit.pre.json" \
  --expected-rtl-count 115 --expected-evidence-count 7 --expected-module-count 117 \
  --previous-netlist "$PREVIOUS_NETLIST" >"$GLOBAL_OUT/synth-audit.pre.log" 2>&1
cmp -s "$CANONICAL_AUDIT" "$GLOBAL_OUT/synth-audit.pre.json" || {
  printf '[T4S-OPENSTA] canonical/pre synthesis audit mismatch\n' >&2; exit 95;
}
python3 "$BINDING" --audit-summary "$CANONICAL_AUDIT" --netlist "$NETLIST" \
  --freeze-status "$SYNTH_FREEZE" --exit-status "$SYNTH_EXIT" \
  --json-out "$GLOBAL_OUT/synth-binding.pre.json" >"$GLOBAL_OUT/synth-binding.pre.log" 2>&1

T4Q_STA_NETLIST="$NETLIST" T4Q_STA_STD_LIB="$STD_LIB" T4Q_STA_MACRO_LIBS="$MACRO_LIBS" \
T4Q_STA_PERIOD_NS=5.0 T4Q_STA_SETUP_PROBE_OUT="$FREEZE_OUT/setup-probe.pre.txt" \
  "$OPENSTA" "$PROBE_TCL" >"$FREEZE_OUT/setup-probe.pre.log" 2>&1
python3 "$DERIVER" "$FREEZE_OUT/setup-probe.pre.txt" --netlist "$NETLIST" \
  --output "$FREEZE_OUT/setup-members.pre.json" >"$FREEZE_OUT/setup-members.pre.log" 2>&1
SETUP_MANIFEST="$FREEZE_OUT/setup-members.pre.json"

INPUTS=(
  "$NETLIST" "$TMP_DIR/sta-build/NpcTop-200MHz/NpcTop.netlist.v.sim"
  "$TMP_DIR/sta-build/NpcTop-200MHz/yosys.log" "$TMP_DIR/sta-build/NpcTop-200MHz/synth_check.txt"
  "$TMP_DIR/sta-build/NpcTop-200MHz/synth_stat.txt" "$TMP_DIR/sta-build/NpcTop-200MHz/abc.sdc"
  "$TMP_DIR/synth-console.log" "$SYNTH_EXIT" "$SYNTH_FREEZE"
  "$TMP_DIR/synth-provenance.pre.kv"
  "$TMP_DIR/synth-rtl-inputs.pre.sha256" "$TMP_DIR/synth-rtl-inputs.post.sha256"
  "$TMP_DIR/synth-vsrc-tree.pre.sha256" "$TMP_DIR/synth-vsrc-tree.post.sha256"
  "$TMP_DIR/synth-flow-inputs.pre.sha256" "$TMP_DIR/synth-flow-inputs.post.sha256"
  "$TMP_DIR/synth-liberty-inputs.pre.sha256" "$TMP_DIR/synth-liberty-inputs.post.sha256"
  "$TMP_DIR/synth-evidence-inputs.pre.sha256" "$TMP_DIR/synth-evidence-inputs.post.sha256"
  "$TMP_DIR/synth-tool-binaries.pre.sha256" "$TMP_DIR/synth-tool-binaries.post.sha256"
  "$TMP_DIR/synth-parameters.pre.kv" "$TMP_DIR/synth-parameters.post.kv"
  "$TMP_DIR/synth-tool-versions.pre.kv" "$TMP_DIR/synth-tool-versions.post.kv"
  "$CANONICAL_AUDIT" "$GLOBAL_OUT/synth-binding.pre.json"
  "$FREEZE_OUT/hardening-mutations.log" "$FREEZE_OUT/hardening-status.txt"
  "$FREEZE_OUT/setup-probe.pre.txt" "$SETUP_MANIFEST"
  "$AUDIT" "$BINDING" "$CHECKER" "$TARGET" "$FINALIZER" "$DERIVER" "$HARDENING"
  "$PROBE_TCL" "$STA_TCL" "$TASK_DIR/run-fresh-synthesis.sh" "$TASK_DIR/run-global-opensta.sh"
  "$COMMON_SYNTH/audit-t3p-synthesis.py" "$COMMON_SYNTH/run-fresh-synthesis.sh"
  "$T3L_TASK/opensta-t3l-current-5ns.tcl" "$T3L_TASK/check-t3l-global-sta.py"
  "$T3L_TASK/check-t3l-target-200mhz.py"
  "$PREVIOUS_NETLIST" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}" "$OPENSTA"
)
require_inputs "${INPUTS[@]}"

write_parameters() {
  local output=$1
  {
    printf 'period_ns=5.0\n'; printf 'top=NpcTop\n'; printf 'clock_port=clk\n'; printf 'clock_name=core_clock\n'
    printf 'target_expect=%s\n' "$TARGET_EXPECT"; printf 'netlist=%s\n' "$NETLIST"
    printf 'std_lib=%s\n' "$STD_LIB"; printf 'macro_libs=%s\n' "$MACRO_LIBS"
    printf 'opensta_binary=%s\n' "$OPENSTA"; printf 'setup_manifest_sha256=%s\n' "$(sha256sum "$SETUP_MANIFEST" | cut -d' ' -f1)"
  } >"$output"
}

sha256sum "${INPUTS[@]}" >"$FREEZE_OUT/opensta-inputs.pre.sha256"
write_parameters "$FREEZE_OUT/opensta-parameters.pre.kv"
printf 'opensta=%s\n' "$($OPENSTA -version)" >"$FREEZE_OUT/opensta-tool-version.pre.kv"
INPUT_MANIFEST_SHA=$(sha256sum "$FREEZE_OUT/opensta-inputs.pre.sha256" | cut -d' ' -f1)
PARAMETERS_SHA=$(sha256sum "$FREEZE_OUT/opensta-parameters.pre.kv" | cut -d' ' -f1)
NETLIST_SHA=$(sha256sum "$NETLIST" | cut -d' ' -f1)
STD_LIB_SHA=$(sha256sum "$STD_LIB" | cut -d' ' -f1)
OPENSTA_SHA=$(sha256sum "$OPENSTA" | cut -d' ' -f1)
AUDIT_SHA=$(sha256sum "$CANONICAL_AUDIT" | cut -d' ' -f1)
AUDIT_NETLIST_SHA=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["netlist_sha256"])' "$CANONICAL_AUDIT")
SYNTH_FREEZE_SHA=$(sha256sum "$SYNTH_FREEZE" | cut -d' ' -f1)
BINDING_SHA=$(sha256sum "$GLOBAL_OUT/synth-binding.pre.json" | cut -d' ' -f1)
SETUP_SHA=$(sha256sum "$SETUP_MANIFEST" | cut -d' ' -f1)

T4Q_STA_NETLIST="$NETLIST" T4Q_STA_OUT_DIR="$GLOBAL_OUT" T4Q_STA_STD_LIB="$STD_LIB" \
T4Q_STA_MACRO_LIBS="$MACRO_LIBS" T4Q_STA_PERIOD_NS=5.0 T4Q_STA_NETLIST_SHA256="$NETLIST_SHA" \
T4Q_STA_STD_LIB_SHA256="$STD_LIB_SHA" T4Q_STA_INPUT_MANIFEST_SHA256="$INPUT_MANIFEST_SHA" \
T4Q_STA_PARAMETERS_SHA256="$PARAMETERS_SHA" T4Q_STA_OPENSTA_BINARY="$OPENSTA" \
T4Q_STA_OPENSTA_BINARY_SHA256="$OPENSTA_SHA" T4Q_STA_SYNTH_AUDIT_SUMMARY="$CANONICAL_AUDIT" \
T4Q_STA_SYNTH_AUDIT_SUMMARY_SHA256="$AUDIT_SHA" T4Q_STA_SYNTH_AUDIT_NETLIST_SHA256="$AUDIT_NETLIST_SHA" \
T4Q_STA_SYNTH_FREEZE_STATUS_SHA256="$SYNTH_FREEZE_SHA" T4Q_STA_SYNTH_BINDING_SHA256="$BINDING_SHA" \
T4Q_STA_SETUP_MEMBERS_MANIFEST_SHA256="$SETUP_SHA" \
  "$OPENSTA" "$STA_TCL" >"$GLOBAL_OUT/opensta-console.log" 2>&1

python3 "$CHECKER" "$GLOBAL_OUT" --expected-netlist "$NETLIST" --expected-std-lib "$STD_LIB" \
  --expected-opensta-binary "$OPENSTA" --expected-input-manifest "$FREEZE_OUT/opensta-inputs.pre.sha256" \
  --expected-parameters "$FREEZE_OUT/opensta-parameters.pre.kv" --json-out "$GLOBAL_OUT/summary.json" \
  --setup-manifest "$SETUP_MANIFEST" --synth-audit "$CANONICAL_AUDIT" \
  --synth-freeze-status "$SYNTH_FREEZE" --synth-binding "$GLOBAL_OUT/synth-binding.pre.json" \
  >"$GLOBAL_OUT/checker.log" 2>&1

python3 "$AUDIT" "$TMP_DIR" --json-out "$GLOBAL_OUT/synth-audit.post.json" \
  --expected-rtl-count 115 --expected-evidence-count 7 --expected-module-count 117 \
  --previous-netlist "$PREVIOUS_NETLIST" >"$GLOBAL_OUT/synth-audit.post.log" 2>&1
cmp -s "$CANONICAL_AUDIT" "$GLOBAL_OUT/synth-audit.post.json" || exit 95
python3 "$BINDING" --audit-summary "$CANONICAL_AUDIT" --netlist "$NETLIST" \
  --freeze-status "$SYNTH_FREEZE" --exit-status "$SYNTH_EXIT" \
  --json-out "$GLOBAL_OUT/synth-binding.post.json" >"$GLOBAL_OUT/synth-binding.post.log" 2>&1
cmp -s "$GLOBAL_OUT/synth-binding.pre.json" "$GLOBAL_OUT/synth-binding.post.json" || exit 95
printf 'canonical_vs_pre_audit=PASS\ncanonical_vs_post_audit=PASS\npre_vs_post_binding=PASS\n' \
  >"$FREEZE_OUT/synth-binding-status.txt"

T4Q_STA_NETLIST="$NETLIST" T4Q_STA_STD_LIB="$STD_LIB" T4Q_STA_MACRO_LIBS="$MACRO_LIBS" \
T4Q_STA_PERIOD_NS=5.0 T4Q_STA_SETUP_PROBE_OUT="$FREEZE_OUT/setup-probe.post.txt" \
  "$OPENSTA" "$PROBE_TCL" >"$FREEZE_OUT/setup-probe.post.log" 2>&1
python3 "$DERIVER" "$FREEZE_OUT/setup-probe.post.txt" --netlist "$NETLIST" \
  --output "$FREEZE_OUT/setup-members.post.json" >"$FREEZE_OUT/setup-members.post.log" 2>&1
cmp -s "$FREEZE_OUT/setup-probe.pre.txt" "$FREEZE_OUT/setup-probe.post.txt" || exit 93
cmp -s "$FREEZE_OUT/setup-members.pre.json" "$FREEZE_OUT/setup-members.post.json" || exit 93
printf 'pre_vs_post_probe=PASS\npre_vs_post_manifest=PASS\n' >"$FREEZE_OUT/setup-probe-status.txt"

sha256sum "${INPUTS[@]}" >"$FREEZE_OUT/opensta-inputs.post.sha256"
write_parameters "$FREEZE_OUT/opensta-parameters.post.kv"
printf 'opensta=%s\n' "$($OPENSTA -version)" >"$FREEZE_OUT/opensta-tool-version.post.kv"
input_status=FAIL; parameter_status=FAIL; version_status=FAIL
cmp -s "$FREEZE_OUT/opensta-inputs.pre.sha256" "$FREEZE_OUT/opensta-inputs.post.sha256" && input_status=PASS
cmp -s "$FREEZE_OUT/opensta-parameters.pre.kv" "$FREEZE_OUT/opensta-parameters.post.kv" && parameter_status=PASS
cmp -s "$FREEZE_OUT/opensta-tool-version.pre.kv" "$FREEZE_OUT/opensta-tool-version.post.kv" && version_status=PASS
printf 'inputs=%s\nparameters=%s\ntool_version=%s\n' "$input_status" "$parameter_status" "$version_status" \
  >"$FREEZE_OUT/opensta-freeze-status.txt"
[[ $input_status == PASS && $parameter_status == PASS && $version_status == PASS ]] || exit 94

python3 "$FINALIZER" --summary "$GLOBAL_OUT/summary.json" \
  --synth-binding-status "$FREEZE_OUT/synth-binding-status.txt" \
  --opensta-freeze-status "$FREEZE_OUT/opensta-freeze-status.txt" \
  --setup-probe-status "$FREEZE_OUT/setup-probe-status.txt" \
  --hardening-status "$FREEZE_OUT/hardening-status.txt" \
  --json-out "$GLOBAL_OUT/final-attestation.json" >"$GLOBAL_OUT/final-attestation.log" 2>&1
if [[ $TARGET_EXPECT != any ]]; then
  python3 "$TARGET" "$GLOBAL_OUT/summary.json" --attestation "$GLOBAL_OUT/final-attestation.json" \
    --expect "$TARGET_EXPECT" >"$GLOBAL_OUT/target-200mhz.log" 2>&1
fi
printf '[T4S-OPENSTA] PASS tag=%s global=5ns target=%s\n' "$RUN_TAG" "$TARGET_EXPECT"
