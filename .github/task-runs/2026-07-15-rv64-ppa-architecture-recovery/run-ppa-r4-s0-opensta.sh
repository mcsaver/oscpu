#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-15-rv64-ppa-architecture-recovery
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
RUN_ID=${1:-run1}
TARGET_EXPECT=${R4_S0_STA_EXPECT_TARGET:-met}
case "$RUN_ID" in
  run1|run2) ;;
  *) printf '[PPA-R4-S0-STA-V2] invalid run id: %s\n' "$RUN_ID" >&2; exit 64 ;;
esac
case "$TARGET_EXPECT" in
  any|met|miss) ;;
  *) printf '[PPA-R4-S0-STA-V2] invalid target expectation: %s\n' "$TARGET_EXPECT" >&2; exit 64 ;;
esac

SYNTH_SLUG="$TASK_SLUG/evidence/r4-s0-correctness-checkpoint/fresh-synth-$RUN_ID"
SYNTH_TASK="$ROOT_DIR/.github/task-runs/$SYNTH_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$SYNTH_SLUG"
# `opensta-exact5ns` 是旧 fail-open preview；v2 永不读取、覆盖或提升它。
LEGACY_PREVIEW="$SYNTH_TASK/opensta-exact5ns"
OUT_DIR="$SYNTH_TASK/opensta-exact5ns-v2"
NETLIST="$TMP_DIR/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
SYNTH_AUDIT="$SYNTH_TASK/evidence/synthesis/summary.json"
SYNTH_FREEZE="$TMP_DIR/synth-input-hash-cmp.txt"
SYNTH_EXIT="$TMP_DIR/synth-exit-status.txt"

BINDING="$TASK_DIR/check-r4-s0-synth-binding.py"
DERIVER="$TASK_DIR/derive-r4-s0-setup-members.py"
CHECKER="$TASK_DIR/check-r4-s0-opensta.py"
HARDENING="$TASK_DIR/test-r4-s0-opensta-hardening.py"
PROBE_TCL="$TASK_DIR/opensta-r4-s0-setup-probe.tcl"
STA_TCL="$TASK_DIR/opensta-r4-s0-exact5ns.tcl"
POLICY="$TASK_DIR/r4-s0-opensta-hardening.md"
RUNNER="$TASK_DIR/run-ppa-r4-s0-opensta.sh"

OPENSTA=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
MACRO_LIB_ARRAY=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
MACRO_LIBS=$(IFS=:; printf '%s' "${MACRO_LIB_ARRAY[*]}")

[[ ! -e $OUT_DIR ]] || {
  printf '[PPA-R4-S0-STA-V2] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 3
}
require_inputs() {
  local path
  for path in "$@"; do
    [[ -f $path && ! -L $path && -s $path ]] || {
      printf '[PPA-R4-S0-STA-V2] invalid input: %s\n' "$path" >&2
      exit 2
    }
  done
}
require_inputs "$NETLIST" "$SYNTH_AUDIT" "$SYNTH_FREEZE" "$SYNTH_EXIT" \
  "$BINDING" "$DERIVER" "$CHECKER" "$HARDENING" "$PROBE_TCL" "$STA_TCL" \
  "$POLICY" "$RUNNER" "$OPENSTA" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}"

mkdir -p "$OUT_DIR"
{
  printf 'legacy_path=%s\n' "$LEGACY_PREVIEW"
  printf 'legacy_present=%s\n' "$([[ -e $LEGACY_PREVIEW ]] && printf true || printf false)"
  printf 'legacy_disposition=INVALID_FAIL_OPEN_PREVIEW\n'
  printf 'legacy_reason=fake_binding_hash_and_hardcoded_loop_count\n'
  printf 'v2_output=%s\n' "$OUT_DIR"
} >"$OUT_DIR/legacy-preview-disposition.kv"

if python3 "$HARDENING" >"$OUT_DIR/hardening-mutations.log" 2>&1; then
  printf 'mutations=PASS\n' >"$OUT_DIR/hardening-status.txt"
else
  printf 'mutations=FAIL\n' >"$OUT_DIR/hardening-status.txt"
  printf '[PPA-R4-S0-STA-V2] hardening negative selftest failed\n' >&2
  exit 90
fi

python3 "$BINDING" \
  --audit-summary "$SYNTH_AUDIT" \
  --netlist "$NETLIST" \
  --freeze-status "$SYNTH_FREEZE" \
  --exit-status "$SYNTH_EXIT" \
  --json-out "$OUT_DIR/synth-binding.pre.json" \
  >"$OUT_DIR/synth-binding.pre.log" 2>&1

run_setup_probe() {
  local tag=$1
  local probe="$OUT_DIR/setup-probe.$tag.txt"
  local console="$OUT_DIR/setup-probe.$tag.log"
  local exit_file="$OUT_DIR/setup-probe.$tag.exit-status.txt"
  local manifest="$OUT_DIR/setup-members.$tag.json"
  local derive_log="$OUT_DIR/setup-members.$tag.log"
  local status
  set +e
  R4_S0_STA_NETLIST="$NETLIST" \
  R4_S0_STA_STD_LIB="$STD_LIB" \
  R4_S0_STA_MACRO_LIBS="$MACRO_LIBS" \
  R4_S0_STA_PERIOD_NS=5.0 \
  R4_S0_STA_SETUP_PROBE_OUT="$probe" \
    "$OPENSTA" "$PROBE_TCL" >"$console" 2>&1
  status=$?
  set -e
  printf '%s\n' "$status" >"$exit_file"
  [[ $status -eq 0 ]] || {
    printf '[PPA-R4-S0-STA-V2] %s setup probe failed: exit=%s\n' "$tag" "$status" >&2
    exit 91
  }
  require_inputs "$probe" "$console" "$exit_file"
  python3 "$DERIVER" "$probe" --netlist "$NETLIST" --output "$manifest" \
    >"$derive_log" 2>&1
}

run_setup_probe pre
sha256sum "${MACRO_LIB_ARRAY[@]}" >"$OUT_DIR/macro-liberties.sha256"

INPUTS=(
  "$NETLIST" "$SYNTH_AUDIT" "$SYNTH_FREEZE" "$SYNTH_EXIT"
  "$OPENSTA" "$STD_LIB" "${MACRO_LIB_ARRAY[@]}"
  "$OUT_DIR/macro-liberties.sha256"
  "$OUT_DIR/synth-binding.pre.json"
  "$OUT_DIR/setup-probe.pre.txt" "$OUT_DIR/setup-probe.pre.log"
  "$OUT_DIR/setup-probe.pre.exit-status.txt" "$OUT_DIR/setup-members.pre.json"
  "$OUT_DIR/hardening-mutations.log" "$OUT_DIR/hardening-status.txt"
  "$RUNNER" "$BINDING" "$DERIVER" "$CHECKER" "$HARDENING"
  "$PROBE_TCL" "$STA_TCL" "$POLICY"
)
require_inputs "${INPUTS[@]}"

write_parameters() {
  local output=$1
  {
    printf 'period_ns=5.0\n'
    printf 'top=NpcTop\n'
    printf 'clock_port=clk\n'
    printf 'clock_name=core_clock\n'
    printf 'run_id=%s\n' "$RUN_ID"
    printf 'target_expect=%s\n' "$TARGET_EXPECT"
    printf 'claim_tier=rtl_proxy_partial_constraints\n'
    printf 'netlist=%s\n' "$NETLIST"
    printf 'std_lib=%s\n' "$STD_LIB"
    printf 'macro_libs=%s\n' "$MACRO_LIBS"
    printf 'opensta_binary=%s\n' "$OPENSTA"
    printf 'setup_manifest_sha256=%s\n' \
      "$(sha256sum "$OUT_DIR/setup-members.pre.json" | cut -d' ' -f1)"
    printf 'synth_binding_sha256=%s\n' \
      "$(sha256sum "$OUT_DIR/synth-binding.pre.json" | cut -d' ' -f1)"
  } >"$output"
}

sha256sum "${INPUTS[@]}" >"$OUT_DIR/opensta-inputs.pre.sha256"
write_parameters "$OUT_DIR/opensta-parameters.pre.kv"
printf 'opensta=%s\n' "$($OPENSTA -version 2>&1)" \
  >"$OUT_DIR/opensta-tool-version.pre.kv"
require_inputs "$OUT_DIR/opensta-inputs.pre.sha256" "$OUT_DIR/opensta-parameters.pre.kv" \
  "$OUT_DIR/opensta-tool-version.pre.kv"

NETLIST_SHA=$(sha256sum "$NETLIST" | cut -d' ' -f1)
STD_LIB_SHA=$(sha256sum "$STD_LIB" | cut -d' ' -f1)
MACRO_MANIFEST_SHA=$(sha256sum "$OUT_DIR/macro-liberties.sha256" | cut -d' ' -f1)
INPUT_MANIFEST_SHA=$(sha256sum "$OUT_DIR/opensta-inputs.pre.sha256" | cut -d' ' -f1)
PARAMETERS_SHA=$(sha256sum "$OUT_DIR/opensta-parameters.pre.kv" | cut -d' ' -f1)
OPENSTA_SHA=$(sha256sum "$OPENSTA" | cut -d' ' -f1)
AUDIT_SHA=$(sha256sum "$SYNTH_AUDIT" | cut -d' ' -f1)
AUDIT_NETLIST_SHA=$(python3 -c \
  'import json,sys; print(json.load(open(sys.argv[1]))["netlist_sha256"])' \
  "$SYNTH_AUDIT")
SYNTH_FREEZE_SHA=$(sha256sum "$SYNTH_FREEZE" | cut -d' ' -f1)
SYNTH_EXIT_SHA=$(sha256sum "$SYNTH_EXIT" | cut -d' ' -f1)
BINDING_SHA=$(sha256sum "$OUT_DIR/synth-binding.pre.json" | cut -d' ' -f1)
SETUP_SHA=$(sha256sum "$OUT_DIR/setup-members.pre.json" | cut -d' ' -f1)

set +e
R4_S0_STA_NETLIST="$NETLIST" \
R4_S0_STA_OUT_DIR="$OUT_DIR" \
R4_S0_STA_STD_LIB="$STD_LIB" \
R4_S0_STA_MACRO_LIBS="$MACRO_LIBS" \
R4_S0_STA_PERIOD_NS=5.0 \
R4_S0_STA_RUN_ID="$RUN_ID" \
R4_S0_STA_NETLIST_SHA256="$NETLIST_SHA" \
R4_S0_STA_STD_LIB_SHA256="$STD_LIB_SHA" \
R4_S0_STA_MACRO_MANIFEST_SHA256="$MACRO_MANIFEST_SHA" \
R4_S0_STA_INPUT_MANIFEST_SHA256="$INPUT_MANIFEST_SHA" \
R4_S0_STA_PARAMETERS_SHA256="$PARAMETERS_SHA" \
R4_S0_STA_OPENSTA_BINARY="$OPENSTA" \
R4_S0_STA_OPENSTA_BINARY_SHA256="$OPENSTA_SHA" \
R4_S0_STA_SYNTH_AUDIT_SUMMARY="$SYNTH_AUDIT" \
R4_S0_STA_SYNTH_AUDIT_SUMMARY_SHA256="$AUDIT_SHA" \
R4_S0_STA_SYNTH_AUDIT_NETLIST_SHA256="$AUDIT_NETLIST_SHA" \
R4_S0_STA_SYNTH_FREEZE_STATUS_SHA256="$SYNTH_FREEZE_SHA" \
R4_S0_STA_SYNTH_EXIT_STATUS_SHA256="$SYNTH_EXIT_SHA" \
R4_S0_STA_SYNTH_BINDING_SHA256="$BINDING_SHA" \
R4_S0_STA_SETUP_MEMBERS_MANIFEST_SHA256="$SETUP_SHA" \
  "$OPENSTA" "$STA_TCL" >"$OUT_DIR/opensta-console.log" 2>&1
OPENSTA_STATUS=$?
set -e
printf '%s\n' "$OPENSTA_STATUS" >"$OUT_DIR/opensta-exit-status.txt"
[[ $OPENSTA_STATUS -eq 0 ]] || {
  printf '[PPA-R4-S0-STA-V2] main OpenSTA failed: exit=%s\n' "$OPENSTA_STATUS" >&2
  exit 92
}

python3 "$BINDING" \
  --audit-summary "$SYNTH_AUDIT" \
  --netlist "$NETLIST" \
  --freeze-status "$SYNTH_FREEZE" \
  --exit-status "$SYNTH_EXIT" \
  --json-out "$OUT_DIR/synth-binding.post.json" \
  >"$OUT_DIR/synth-binding.post.log" 2>&1
run_setup_probe post

sha256sum "${INPUTS[@]}" >"$OUT_DIR/opensta-inputs.post.sha256"
write_parameters "$OUT_DIR/opensta-parameters.post.kv"
printf 'opensta=%s\n' "$($OPENSTA -version 2>&1)" \
  >"$OUT_DIR/opensta-tool-version.post.kv"

python3 "$CHECKER" "$OUT_DIR" \
  --run-id "$RUN_ID" \
  --expected-target "$TARGET_EXPECT" \
  --expected-netlist "$NETLIST" \
  --expected-std-lib "$STD_LIB" \
  --expected-macro-manifest "$OUT_DIR/macro-liberties.sha256" \
  --expected-opensta-binary "$OPENSTA" \
  --expected-input-manifest-pre "$OUT_DIR/opensta-inputs.pre.sha256" \
  --expected-input-manifest-post "$OUT_DIR/opensta-inputs.post.sha256" \
  --expected-parameters-pre "$OUT_DIR/opensta-parameters.pre.kv" \
  --expected-parameters-post "$OUT_DIR/opensta-parameters.post.kv" \
  --expected-tool-version-pre "$OUT_DIR/opensta-tool-version.pre.kv" \
  --expected-tool-version-post "$OUT_DIR/opensta-tool-version.post.kv" \
  --synth-audit "$SYNTH_AUDIT" \
  --synth-freeze-status "$SYNTH_FREEZE" \
  --synth-exit-status "$SYNTH_EXIT" \
  --synth-binding-pre "$OUT_DIR/synth-binding.pre.json" \
  --synth-binding-post "$OUT_DIR/synth-binding.post.json" \
  --setup-probe-pre "$OUT_DIR/setup-probe.pre.txt" \
  --setup-probe-post "$OUT_DIR/setup-probe.post.txt" \
  --setup-manifest-pre "$OUT_DIR/setup-members.pre.json" \
  --setup-manifest-post "$OUT_DIR/setup-members.post.json" \
  --setup-probe-console-pre "$OUT_DIR/setup-probe.pre.log" \
  --setup-probe-console-post "$OUT_DIR/setup-probe.post.log" \
  --setup-probe-exit-pre "$OUT_DIR/setup-probe.pre.exit-status.txt" \
  --setup-probe-exit-post "$OUT_DIR/setup-probe.post.exit-status.txt" \
  --opensta-exit-status "$OUT_DIR/opensta-exit-status.txt" \
  --hardening-status "$OUT_DIR/hardening-status.txt" \
  --json-out "$OUT_DIR/summary.json" \
  >"$OUT_DIR/checker.log" 2>&1

read -r TARGET_MET RESERVE_MET < <(python3 - "$OUT_DIR/summary.json" <<'PY'
import json
import sys

summary = json.load(open(sys.argv[1]))
print(str(summary["target_200mhz_met"]).lower(), str(summary["reserve_met"]).lower())
PY
)
{
  printf 'schema=ppa-r4-s0-opensta-status-v2\n'
  printf 'checker_exit=0\n'
  printf 'opensta_exit=0\n'
  printf 'target_200mhz_met=%s\n' "$TARGET_MET"
  printf 'reserve_threshold_ns=0.10\n'
  printf 'reserve_met=%s\n' "$RESERVE_MET"
} >"$OUT_DIR/status.txt"

case "$TARGET_EXPECT:$TARGET_MET" in
  any:*) ;;
  met:true) ;;
  miss:false) ;;
  *)
    printf '[PPA-R4-S0-STA-V2] target expectation mismatch: expected=%s actual=%s\n' \
      "$TARGET_EXPECT" "$TARGET_MET" >&2
    exit 4
    ;;
esac
printf '[PPA-R4-S0-STA-V2] PASS run=%s target_200mhz_met=%s reserve_met=%s output=%s\n' \
  "$RUN_ID" "$TARGET_MET" "$RESERVE_MET" "$OUT_DIR"
