#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-15-rv64-ppa-architecture-recovery
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
RUN_ID=${1:-run1}
case "$RUN_ID" in
  run1|run2) ;;
  *) printf '[PPA-R4-P0-SYNTH] invalid run id: %s\n' "$RUN_ID" >&2; exit 64 ;;
esac

# P0-A 是首测点；只有 A 不足时才用同一冻结协议切换到 P0-B/P0-AB。
CANDIDATE_DIR=${R4_P0_CANDIDATE_DIR:-r4-p0a-wb-valid}
CANDIDATE_ID=${R4_P0_CANDIDATE_ID:-r4-p0a-distributed-wb-valid}
case "$CANDIDATE_DIR:$CANDIDATE_ID" in
  r4-p0a-wb-valid:r4-p0a-distributed-wb-valid|\
  r4-p0b-balanced-tag:r4-p0b-balanced-tag|\
  r4-p0-timing-recovery:r4-p0-ab-balanced-tag-distributed-wb-valid) ;;
  *)
    printf '[PPA-R4-P0-SYNTH] unsupported candidate binding: dir=%s id=%s\n' \
      "$CANDIDATE_DIR" "$CANDIDATE_ID" >&2
    exit 64
    ;;
esac

SYNTH_SLUG="$TASK_SLUG/evidence/$CANDIDATE_DIR/fresh-synth-$RUN_ID"
SYNTH_TASK="$ROOT_DIR/.github/task-runs/$SYNTH_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$SYNTH_SLUG"
STA_ROOT="$TMP_DIR/sta-build"
CANONICAL_AUDIT="$SYNTH_TASK/evidence/synthesis/summary.json"
CANDIDATE_BINDING="$SYNTH_TASK/evidence/synthesis/candidate-binding.kv"
CANDIDATE_STATUS="$SYNTH_TASK/evidence/synthesis/status.txt"
CONTRACT="$TASK_DIR/r4-p0-timing-recovery-contract.md"
OPENSTA_RUNNER="$TASK_DIR/run-ppa-r4-p0-opensta.sh"
AUDIT_SCRIPT="$ROOT_DIR/.github/task-runs/2026-07-15-rv64-t4q-final-sta/audit-t4q-synthesis.py"
BASE_AUDIT="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3p-lane1-simple-owner/audit-t3p-synthesis.py"
PREVIOUS_NETLIST="$ROOT_DIR/tmp/$TASK_SLUG/evidence/r4-s0-correctness-checkpoint/fresh-synth-run1/sta-build/NpcTop-200MHz/NpcTop.netlist.v"
PREVIOUS_AUDIT="$TASK_DIR/evidence/r4-s0-correctness-checkpoint/fresh-synth-run1/evidence/synthesis/summary.json"

EXPECTED_RTL_COUNT=117
EXPECTED_VSRC_COUNT=140
EXPECTED_MODULE_COUNT=119
YOSYS_LAUNCHER="$ROOT_DIR/oss-cad-suite/bin/yosys"
YOSYS_BINARY="$ROOT_DIR/oss-cad-suite/libexec/yosys"
ABC_LAUNCHER="$ROOT_DIR/oss-cad-suite/bin/yosys-abc"
ABC_BINARY="$ROOT_DIR/oss-cad-suite/libexec/yosys-abc"
OSS_LOADER="$ROOT_DIR/oss-cad-suite/lib/ld-linux-x86-64.so.2"
OPENSTA_BINARY=/home/lyg/tools/OpenSTA/build/sta
STD_LIB="$ROOT_DIR/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor"
KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"
MACRO_LIBS=(
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "$ROOT_DIR/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
FLOW_INPUTS=(
  "$ROOT_DIR/Makefile"
  "$ROOT_DIR/npc/rv64/Makefile"
  "$ROOT_DIR/yosys-sta/Makefile"
  "$ROOT_DIR/npc/rv64/.config"
  "$ROOT_DIR/npc/rv64/include/config/auto.conf"
  "$ROOT_DIR/npc/rv64/include/config/auto.conf.cmd"
  "$ROOT_DIR/npc/rv64/scripts/config.mk"
  "$ROOT_DIR/npc/rv64/vsrc/filelist.mk"
  "$ROOT_DIR/scripts/agent-env.sh"
  "$ROOT_DIR/yosys-sta/scripts/yosys.tcl"
  "$ROOT_DIR/yosys-sta/scripts/common.tcl"
  "$ROOT_DIR/yosys-sta/scripts/pdk/icsprout55.tcl"
  "$ROOT_DIR/yosys-sta/scripts/default.sdc"
  "$ROOT_DIR/yosys-sta/scripts/opensta-fullcore.tcl"
)
PROTOCOL_INPUTS=(
  "$TASK_DIR/check-r4-s0-synth-binding.py"
  "$TASK_DIR/derive-r4-s0-setup-members.py"
  "$TASK_DIR/check-r4-s0-opensta.py"
  "$TASK_DIR/test-r4-s0-opensta-hardening.py"
  "$TASK_DIR/opensta-r4-s0-setup-probe.tcl"
  "$TASK_DIR/opensta-r4-s0-exact5ns.tcl"
  "$TASK_DIR/r4-s0-opensta-hardening.md"
)
LIBERTY_INPUTS=("$STD_LIB" "${MACRO_LIBS[@]}")
TOOL_BINARIES=(
  "$YOSYS_LAUNCHER" "$YOSYS_BINARY" "$ABC_LAUNCHER" "$ABC_BINARY"
  "$OSS_LOADER" "$OPENSTA_BINARY"
)

require_regular_inputs() {
  local path
  for path in "$@"; do
    [[ -f $path && ! -L $path && -s $path ]] || {
      printf '[PPA-R4-P0-SYNTH] invalid input: %s\n' "$path" >&2
      exit 90
    }
  done
}

if [[ -e $TMP_DIR || -e $CANONICAL_AUDIT || -e $CANDIDATE_BINDING ]]; then
  printf '[PPA-R4-P0-SYNTH] refusing stale output: %s\n' "$SYNTH_TASK" >&2
  exit 2
fi
require_regular_inputs "$CONTRACT" "$OPENSTA_RUNNER" "$AUDIT_SCRIPT" "$BASE_AUDIT" \
  "$PREVIOUS_NETLIST" "$PREVIOUS_AUDIT" "${FLOW_INPUTS[@]}" \
  "${PROTOCOL_INPUTS[@]}" "${LIBERTY_INPUTS[@]}" "${TOOL_BINARIES[@]}"
mkdir -p "$SYNTH_TASK/evidence/synthesis" "$TMP_DIR"
export TMPDIR="$TMP_DIR/tool-tmp"
mkdir -p "$TMPDIR"

{
  printf 'schema=ppa-r4-p0-candidate-binding-v1\n'
  printf 'candidate_id=%s\n' "$CANDIDATE_ID"
  printf 'candidate_dir=%s\n' "$CANDIDATE_DIR"
  printf 'candidate_role=timing_recovery_only_not_architecture_seed\n'
  printf 'run_id=%s\n' "$RUN_ID"
  printf 'parent_checkpoint=r4-s0-posttranslate-memory-semantics\n'
  printf 'parent_synth_audit=%s\n' "$PREVIOUS_AUDIT"
  printf 'parent_synth_audit_sha256=%s\n' "$(sha256sum "$PREVIOUS_AUDIT" | cut -d' ' -f1)"
  printf 'parent_netlist=%s\n' "$PREVIOUS_NETLIST"
  printf 'parent_netlist_sha256=%s\n' "$(sha256sum "$PREVIOUS_NETLIST" | cut -d' ' -f1)"
  printf 'contract=%s\n' "$CONTRACT"
  printf 'contract_sha256=%s\n' "$(sha256sum "$CONTRACT" | cut -d' ' -f1)"
} >"$CANDIDATE_BINDING"

EVIDENCE_INPUTS=(
  "$TASK_DIR/run-ppa-r4-p0-synthesis.sh" "$AUDIT_SCRIPT" "$BASE_AUDIT"
  "$OPENSTA_RUNNER" "$CONTRACT" "$CANDIDATE_BINDING"
  "${PROTOCOL_INPUTS[@]}"
)

write_rtl_manifest() {
  local output=$1 rtl_line
  local -a rtl_files
  rtl_line=$(make -s -C "$ROOT_DIR/npc/rv64" print-synth-rtl)
  read -r -a rtl_files <<<"$rtl_line"
  [[ ${#rtl_files[@]} -eq $EXPECTED_RTL_COUNT ]] || {
    printf '[PPA-R4-P0-SYNTH] expected %s RTL inputs, got %s\n' \
      "$EXPECTED_RTL_COUNT" "${#rtl_files[@]}" >&2
    exit 91
  }
  require_regular_inputs "${rtl_files[@]}"
  sha256sum "${rtl_files[@]}" >"$output"
}

write_vsrc_manifest() {
  local output=$1 count
  find "$ROOT_DIR/npc/rv64/vsrc" -type f -print0 | sort -z | xargs -0 sha256sum >"$output"
  count=$(wc -l <"$output" | tr -d '[:space:]')
  [[ $count -eq $EXPECTED_VSRC_COUNT ]] || {
    printf '[PPA-R4-P0-SYNTH] expected %s vsrc files, got %s\n' \
      "$EXPECTED_VSRC_COUNT" "$count" >&2
    exit 91
  }
}

write_named_manifest() {
  local output=$1
  shift
  require_regular_inputs "$@"
  sha256sum "$@" >"$output"
}

write_parameters() {
  local output=$1
  {
    printf 'synth_design=NpcTop\n'
    printf 'synth_pdk=icsprout55\n'
    printf 'synth_clk_port=clk\n'
    printf 'synth_clk_freq_mhz=200\n'
    printf 'synth_sdc=%s\n' "$ROOT_DIR/yosys-sta/scripts/default.sdc"
    printf 'synth_result_root=%s\n' "$STA_ROOT"
    printf 'synth_verilog_include_dirs=%s %s\n' \
      "$ROOT_DIR/npc/rv64/vsrc" "$ROOT_DIR/npc/rv64/vsrc/include"
    printf 'synth_verilog_defines=\n'
    printf 'synth_flatten=0\n'
    printf 'synth_share=0\n'
    printf 'synth_stop_after_coarse=0\n'
    printf 'synth_public_autoname=0\n'
    printf 'synth_dff_autoname=0\n'
    printf 'synth_blackbox_modules=%s\n' "$BLACKBOX_MODULES"
    printf 'synth_keep_hierarchy_modules=%s\n' "$KEEP_HIERARCHY_MODULES"
    printf 'synth_extra_lib_files=%s\n' "${MACRO_LIBS[*]}"
    printf 'opensta_period_ns=5.0\n'
    printf 'opensta_top=NpcTop\n'
    printf 'opensta_clock_port=clk\n'
    printf 'opensta_clock_name=core_clock\n'
    printf 'opensta_std_lib=%s\n' "$STD_LIB"
    printf 'opensta_macro_libs=%s\n' "$(IFS=:; printf '%s' "${MACRO_LIBS[*]}")"
    printf 'opensta_binary=%s\n' "$OPENSTA_BINARY"
    printf 'freeze_dynamic_libraries=NOT_INCLUDED\n'
    printf 'freeze_tool_support_tree=NOT_INCLUDED\n'
    printf 'candidate_id=%s\n' "$CANDIDATE_ID"
    printf 'candidate_dir=%s\n' "$CANDIDATE_DIR"
  } >"$output"
}

write_tool_versions() {
  local output=$1 yosys_version abc_version opensta_version
  yosys_version=$($YOSYS_LAUNCHER -V)
  abc_version=$($ABC_LAUNCHER -c 'version; quit' 2>&1 \
    | awk '/^UC Berkeley, ABC / { print; found = 1 } END { exit !found }')
  opensta_version=$($OPENSTA_BINARY -version)
  [[ $yosys_version != *$'\n'* && $abc_version != *$'\n'* && \
     $opensta_version != *$'\n'* ]] || exit 92
  {
    printf 'yosys=%s\n' "$yosys_version"
    printf 'abc=%s\n' "$abc_version"
    printf 'opensta=%s\n' "$opensta_version"
  } >"$output"
}

manifest_count() { wc -l <"$1" | tr -d '[:space:]'; }
manifest_sha256() { sha256sum "$1" | cut -d' ' -f1; }

write_all_frozen_inputs() {
  local phase=$1
  write_rtl_manifest "$TMP_DIR/synth-rtl-inputs.$phase.sha256"
  write_vsrc_manifest "$TMP_DIR/synth-vsrc-tree.$phase.sha256"
  write_named_manifest "$TMP_DIR/synth-flow-inputs.$phase.sha256" "${FLOW_INPUTS[@]}"
  write_named_manifest "$TMP_DIR/synth-liberty-inputs.$phase.sha256" "${LIBERTY_INPUTS[@]}"
  write_named_manifest "$TMP_DIR/synth-evidence-inputs.$phase.sha256" "${EVIDENCE_INPUTS[@]}"
  write_named_manifest "$TMP_DIR/synth-tool-binaries.$phase.sha256" "${TOOL_BINARIES[@]}"
  write_parameters "$TMP_DIR/synth-parameters.$phase.kv"
  write_tool_versions "$TMP_DIR/synth-tool-versions.$phase.kv"
}

source "$ROOT_DIR/scripts/agent-env.sh"
export PATH="$ROOT_DIR/oss-cad-suite/bin:$PATH"
write_all_frozen_inputs pre
{
  printf 'start=%s\n' "$(date --iso-8601=seconds)"
  printf 'head=%s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD)"
  printf 'rtl_count=%s\n' "$(manifest_count "$TMP_DIR/synth-rtl-inputs.pre.sha256")"
  printf 'vsrc_count=%s\n' "$(manifest_count "$TMP_DIR/synth-vsrc-tree.pre.sha256")"
  printf 'flow_count=%s\n' "$(manifest_count "$TMP_DIR/synth-flow-inputs.pre.sha256")"
  printf 'liberty_count=%s\n' "$(manifest_count "$TMP_DIR/synth-liberty-inputs.pre.sha256")"
  printf 'evidence_count=%s\n' "$(manifest_count "$TMP_DIR/synth-evidence-inputs.pre.sha256")"
  printf 'tool_binary_count=%s\n' "$(manifest_count "$TMP_DIR/synth-tool-binaries.pre.sha256")"
  printf 'rtl_manifest_sha256=%s\n' "$(manifest_sha256 "$TMP_DIR/synth-rtl-inputs.pre.sha256")"
  printf 'vsrc_manifest_sha256=%s\n' "$(manifest_sha256 "$TMP_DIR/synth-vsrc-tree.pre.sha256")"
  printf 'flow_manifest_sha256=%s\n' "$(manifest_sha256 "$TMP_DIR/synth-flow-inputs.pre.sha256")"
  printf 'liberty_manifest_sha256=%s\n' "$(manifest_sha256 "$TMP_DIR/synth-liberty-inputs.pre.sha256")"
  printf 'evidence_manifest_sha256=%s\n' "$(manifest_sha256 "$TMP_DIR/synth-evidence-inputs.pre.sha256")"
  printf 'tool_binary_manifest_sha256=%s\n' "$(manifest_sha256 "$TMP_DIR/synth-tool-binaries.pre.sha256")"
  printf 'parameters_sha256=%s\n' "$(manifest_sha256 "$TMP_DIR/synth-parameters.pre.kv")"
  printf 'tool_versions_sha256=%s\n' "$(manifest_sha256 "$TMP_DIR/synth-tool-versions.pre.kv")"
} >"$TMP_DIR/synth-provenance.pre.kv"

set +e
timeout --foreground 7200s nice -n 10 make -C "$ROOT_DIR/npc/rv64" syn \
  STA_RESULT_ROOT="$STA_ROOT" \
  STA_DESIGN=NpcTop STA_PDK=icsprout55 \
  STA_CLK_PORT_NAME=clk STA_CLK_FREQ_MHZ=200 \
  STA_SDC_FILE="$ROOT_DIR/yosys-sta/scripts/default.sdc" \
  STA_VERILOG_INCLUDE_DIRS="$ROOT_DIR/npc/rv64/vsrc $ROOT_DIR/npc/rv64/vsrc/include" \
  STA_VERILOG_DEFINES= \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="$BLACKBOX_MODULES" \
  STA_KEEP_HIERARCHY_MODULES="$KEEP_HIERARCHY_MODULES" \
  STA_EXTRA_LIB_FILES="${MACRO_LIBS[*]}" \
  >"$TMP_DIR/synth-console.log" 2>&1
synth_rc=$?
set -e
printf '%s\n' "$synth_rc" >"$TMP_DIR/synth-exit-status.txt"

write_all_frozen_inputs post
freeze_names=(rtl-inputs vsrc-tree flow-inputs liberty-inputs evidence-inputs tool-binaries)
freeze_labels=(rtl_inputs vsrc_tree flow_inputs liberty_inputs evidence_inputs tool_binaries)
freeze_statuses=()
for index in "${!freeze_names[@]}"; do
  status=FAIL
  cmp -s "$TMP_DIR/synth-${freeze_names[$index]}.pre.sha256" \
    "$TMP_DIR/synth-${freeze_names[$index]}.post.sha256" && status=PASS
  freeze_statuses+=("$status")
done
parameter_status=FAIL
tool_version_status=FAIL
cmp -s "$TMP_DIR/synth-parameters.pre.kv" "$TMP_DIR/synth-parameters.post.kv" \
  && parameter_status=PASS
cmp -s "$TMP_DIR/synth-tool-versions.pre.kv" "$TMP_DIR/synth-tool-versions.post.kv" \
  && tool_version_status=PASS
{
  for index in "${!freeze_labels[@]}"; do
    printf '%s=%s\n' "${freeze_labels[$index]}" "${freeze_statuses[$index]}"
  done
  printf 'parameters=%s\n' "$parameter_status"
  printf 'tool_versions=%s\n' "$tool_version_status"
} >"$TMP_DIR/synth-input-hash-cmp.txt"
cp "$TMP_DIR/synth-input-hash-cmp.txt" "$SYNTH_TASK/evidence/synthesis/"
cp "$TMP_DIR/synth-exit-status.txt" "$SYNTH_TASK/evidence/synthesis/"

for status in "${freeze_statuses[@]}" "$parameter_status" "$tool_version_status"; do
  [[ $status == PASS ]] || {
    printf '[PPA-R4-P0-SYNTH] input freeze violated\n' >&2
    exit 94
  }
done
[[ $synth_rc -eq 0 ]] || {
  printf '[PPA-R4-P0-SYNTH] synthesis failed rc=%s\n' "$synth_rc" >&2
  exit "$synth_rc"
}

python3 "$AUDIT_SCRIPT" "$TMP_DIR" \
  --prefix "PPA-R4-P0-${RUN_ID^^}-SYNTH-AUDIT" \
  --json-out "$CANONICAL_AUDIT" \
  --expected-rtl-count "$EXPECTED_RTL_COUNT" \
  --expected-evidence-count "${#EVIDENCE_INPUTS[@]}" \
  --expected-module-count "$EXPECTED_MODULE_COUNT" \
  --previous-netlist "$PREVIOUS_NETLIST" \
  >"$SYNTH_TASK/evidence/synthesis/audit.log" 2>&1

python3 - "$CANONICAL_AUDIT" "$EXPECTED_VSRC_COUNT" "$EXPECTED_MODULE_COUNT" <<'PY'
import json
import sys

summary = json.load(open(sys.argv[1]))
expected_vsrc = int(sys.argv[2])
expected_modules = int(sys.argv[3])
if summary.get("vsrc_count") != expected_vsrc:
    raise SystemExit(f"vsrc_count={summary.get('vsrc_count')!r}, expected {expected_vsrc}")
if summary.get("module_count") != expected_modules:
    raise SystemExit(f"module_count={summary.get('module_count')!r}, expected {expected_modules}")
PY

{
  printf 'schema=ppa-r4-p0-synthesis-status-v1\n'
  printf 'candidate_id=%s\n' "$CANDIDATE_ID"
  printf 'candidate_dir=%s\n' "$CANDIDATE_DIR"
  printf 'candidate_role=timing_recovery_only_not_architecture_seed\n'
  printf 'run_id=%s\n' "$RUN_ID"
  printf 'synthesis=PASS\n'
  printf 'audit=PASS\n'
  printf 'module_count=%s\n' "$EXPECTED_MODULE_COUNT"
  printf 'vsrc_count=%s\n' "$EXPECTED_VSRC_COUNT"
  printf 'parent_netlist_binding=PASS\n'
} >"$CANDIDATE_STATUS"

printf '[PPA-R4-P0-SYNTH] PASS candidate=%s run=%s audit=%s\n' \
  "$CANDIDATE_ID" "$RUN_ID" "$CANONICAL_AUDIT"
