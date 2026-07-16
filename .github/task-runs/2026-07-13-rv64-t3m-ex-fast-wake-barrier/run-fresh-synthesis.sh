#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-13-rv64-t3m-ex-fast-wake-barrier
TASK_DIR="$ROOT_DIR/.github/task-runs/$TASK_SLUG"
TMP_DIR="$ROOT_DIR/tmp/$TASK_SLUG"
STA_ROOT="$TMP_DIR/sta-build"
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
EVIDENCE_INPUTS=(
  "$TASK_DIR/run-fresh-synthesis.sh"
  "$TASK_DIR/audit-t3m-synthesis.py"
  "$TASK_DIR/opensta-t3m-exbarrier-focused.tcl"
  "$TASK_DIR/check-t3m-focused-sta.py"
  "$TASK_DIR/run-opensta-evidence.sh"
  "$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3l-branch-target-split/opensta-t3l-current-5ns.tcl"
  "$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3l-branch-target-split/check-t3l-global-sta.py"
  "$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3l-branch-target-split/check-t3l-target-200mhz.py"
)
LIBERTY_INPUTS=("$STD_LIB" "${MACRO_LIBS[@]}")
TOOL_BINARIES=(
  "$YOSYS_LAUNCHER"
  "$YOSYS_BINARY"
  "$ABC_LAUNCHER"
  "$ABC_BINARY"
  "$OSS_LOADER"
  "$OPENSTA_BINARY"
)

require_regular_inputs() {
  local path
  for path in "$@"; do
    if [[ ! -f $path || -L $path || ! -s $path ]]; then
      printf '[T3M-SYNTH] missing, empty, symlink, or non-regular input: %s\n' \
        "$path" >&2
      exit 90
    fi
  done
}

write_rtl_manifest() {
  local output=$1
  local rtl_line
  local -a rtl_files
  rtl_line=$(make -s -C "$ROOT_DIR/npc/rv64" print-synth-rtl)
  read -r -a rtl_files <<<"$rtl_line"
  [[ ${#rtl_files[@]} -eq 111 ]] || {
    printf '[T3M-SYNTH] expected 111 synthesis RTL inputs, got %s\n' \
      "${#rtl_files[@]}" >&2
    exit 91
  }
  require_regular_inputs "${rtl_files[@]}"
  sha256sum "${rtl_files[@]}" >"$output"
}

write_vsrc_manifest() {
  local output=$1
  find "$ROOT_DIR/npc/rv64/vsrc" -type f -print0 \
    | sort -z \
    | xargs -0 sha256sum >"$output"
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
  } >"$output"
}

write_tool_versions() {
  local output=$1
  local yosys_version
  local abc_version
  local opensta_version
  yosys_version=$($YOSYS_LAUNCHER -V)
  abc_version=$($ABC_LAUNCHER -c 'version; quit' 2>&1 \
    | awk '/^UC Berkeley, ABC / { print; found = 1 } END { exit !found }')
  opensta_version=$($OPENSTA_BINARY -version)
  [[ $yosys_version != *$'\n'* && $abc_version != *$'\n'* && \
     $opensta_version != *$'\n'* ]] || {
    printf '[T3M-SYNTH] tool version probe returned multiple lines\n' >&2
    exit 92
  }
  {
    printf 'yosys=%s\n' "$yosys_version"
    printf 'abc=%s\n' "$abc_version"
    printf 'opensta=%s\n' "$opensta_version"
  } >"$output"
}

manifest_count() {
  wc -l <"$1" | tr -d '[:space:]'
}

manifest_sha256() {
  sha256sum "$1" | cut -d' ' -f1
}

write_all_frozen_inputs() {
  local phase=$1
  write_rtl_manifest "$TMP_DIR/synth-rtl-inputs.$phase.sha256"
  write_vsrc_manifest "$TMP_DIR/synth-vsrc-tree.$phase.sha256"
  write_named_manifest "$TMP_DIR/synth-flow-inputs.$phase.sha256" \
    "${FLOW_INPUTS[@]}"
  write_named_manifest "$TMP_DIR/synth-liberty-inputs.$phase.sha256" \
    "${LIBERTY_INPUTS[@]}"
  write_named_manifest "$TMP_DIR/synth-evidence-inputs.$phase.sha256" \
    "${EVIDENCE_INPUTS[@]}"
  write_named_manifest "$TMP_DIR/synth-tool-binaries.$phase.sha256" \
    "${TOOL_BINARIES[@]}"
  write_parameters "$TMP_DIR/synth-parameters.$phase.kv"
  write_tool_versions "$TMP_DIR/synth-tool-versions.$phase.kv"
}

mkdir -p "$TASK_DIR/evidence/synthesis"
if [[ -e $STA_ROOT ]]; then
  printf '[T3M-SYNTH] refusing stale result root: %s\n' "$STA_ROOT" >&2
  exit 2
fi
mkdir -p "$TMP_DIR"

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
cmp -s "$TMP_DIR/synth-parameters.pre.kv" \
  "$TMP_DIR/synth-parameters.post.kv" && parameter_status=PASS
cmp -s "$TMP_DIR/synth-tool-versions.pre.kv" \
  "$TMP_DIR/synth-tool-versions.post.kv" && tool_version_status=PASS
{
  for index in "${!freeze_labels[@]}"; do
    printf '%s=%s\n' "${freeze_labels[$index]}" "${freeze_statuses[$index]}"
  done
  printf 'parameters=%s\n' "$parameter_status"
  printf 'tool_versions=%s\n' "$tool_version_status"
} >"$TMP_DIR/synth-input-hash-cmp.txt"
cp "$TMP_DIR/synth-input-hash-cmp.txt" \
  "$TASK_DIR/evidence/synthesis/synth-input-hash-cmp.txt"
cp "$TMP_DIR/synth-exit-status.txt" \
  "$TASK_DIR/evidence/synthesis/synth-exit-status.txt"

for status in "${freeze_statuses[@]}" "$parameter_status" "$tool_version_status"; do
  if [[ $status != PASS ]]; then
    printf '[T3M-SYNTH] input freeze violated\n' >&2
    exit 94
  fi
done
if [[ $synth_rc -ne 0 ]]; then
  printf '[T3M-SYNTH] synthesis failed rc=%s\n' "$synth_rc" >&2
  exit "$synth_rc"
fi
printf '[T3M-SYNTH] PASS inputs frozen result=%s\n' \
  "$STA_ROOT/NpcTop-200MHz"
