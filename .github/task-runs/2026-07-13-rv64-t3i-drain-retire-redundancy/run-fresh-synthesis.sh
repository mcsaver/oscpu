#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3i-drain-retire-redundancy"
TMP_DIR="$ROOT_DIR/tmp/2026-07-13-rv64-t3i-drain-retire-redundancy"
STA_ROOT="$TMP_DIR/sta-build"
FLOW_INPUTS=(
  "$ROOT_DIR/npc/rv64/.config"
  "$ROOT_DIR/npc/rv64/Makefile"
  "$ROOT_DIR/npc/rv64/vsrc/filelist.mk"
  "$ROOT_DIR/yosys-sta/scripts/yosys.tcl"
  "$ROOT_DIR/yosys-sta/scripts/default.sdc"
)

write_rtl_manifest() {
  local output=$1
  local rtl_line
  local -a rtl_files
  rtl_line=$(make -s -C "$ROOT_DIR/npc/rv64" print-synth-rtl)
  read -r -a rtl_files <<<"$rtl_line"
  [[ ${#rtl_files[@]} -gt 0 ]]
  sha256sum "${rtl_files[@]}" >"$output"
}

write_vsrc_manifest() {
  local output=$1
  find "$ROOT_DIR/npc/rv64/vsrc" -type f -print0 \
    | sort -z \
    | xargs -0 sha256sum >"$output"
}

write_flow_manifest() {
  local output=$1
  sha256sum "${FLOW_INPUTS[@]}" >"$output"
}

mkdir -p "$TASK_DIR/evidence/synthesis"
if [[ -e $STA_ROOT ]]; then
  printf '[T3I-SYNTH] refusing stale result root: %s\n' "$STA_ROOT" >&2
  exit 2
fi
mkdir -p "$TMP_DIR"

source "$ROOT_DIR/scripts/agent-env.sh"
export PATH="$ROOT_DIR/oss-cad-suite/bin:$PATH"

write_rtl_manifest "$TMP_DIR/synth-rtl-inputs.pre.sha256"
write_vsrc_manifest "$TMP_DIR/synth-vsrc-tree.pre.sha256"
write_flow_manifest "$TMP_DIR/synth-flow-inputs.pre.sha256"
{
  printf 'start=%s\n' "$(date --iso-8601=seconds)"
  printf 'head=%s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD)"
  printf 'yosys=%s\n' "$(yosys -V)"
  printf 'rtl_count=%s\n' "$(wc -l <"$TMP_DIR/synth-rtl-inputs.pre.sha256")"
  printf 'vsrc_count=%s\n' "$(wc -l <"$TMP_DIR/synth-vsrc-tree.pre.sha256")"
  printf 'flow_count=%s\n' "$(wc -l <"$TMP_DIR/synth-flow-inputs.pre.sha256")"
  printf 'rtl_manifest_sha256=%s\n' \
    "$(sha256sum "$TMP_DIR/synth-rtl-inputs.pre.sha256" | cut -d' ' -f1)"
  printf 'vsrc_manifest_sha256=%s\n' \
    "$(sha256sum "$TMP_DIR/synth-vsrc-tree.pre.sha256" | cut -d' ' -f1)"
  printf 'flow_manifest_sha256=%s\n' \
    "$(sha256sum "$TMP_DIR/synth-flow-inputs.pre.sha256" | cut -d' ' -f1)"
} >"$TMP_DIR/synth-provenance.pre.txt"

set +e
timeout --foreground 7200s nice -n 10 make -C "$ROOT_DIR/npc/rv64" syn \
  STA_RESULT_ROOT="$STA_ROOT" \
  STA_CLK_FREQ_MHZ=200 STA_PDK=icsprout55 \
  STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 STA_SYNTH_STOP_AFTER_COARSE=0 \
  STA_SYNTH_PUBLIC_AUTONAME=0 STA_SYNTH_DFF_AUTONAME=0 \
  STA_SYNTH_BLACKBOX_MODULES="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor" \
  STA_KEEP_HIERARCHY_MODULES="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue" \
  >"$TMP_DIR/synth-console.log" 2>&1
synth_rc=$?
set -e
printf '%s\n' "$synth_rc" >"$TMP_DIR/synth-exit-status.txt"

write_rtl_manifest "$TMP_DIR/synth-rtl-inputs.post.sha256"
write_vsrc_manifest "$TMP_DIR/synth-vsrc-tree.post.sha256"
write_flow_manifest "$TMP_DIR/synth-flow-inputs.post.sha256"

rtl_status=FAIL
vsrc_status=FAIL
flow_status=FAIL
cmp -s "$TMP_DIR/synth-rtl-inputs.pre.sha256" \
  "$TMP_DIR/synth-rtl-inputs.post.sha256" && rtl_status=PASS
cmp -s "$TMP_DIR/synth-vsrc-tree.pre.sha256" \
  "$TMP_DIR/synth-vsrc-tree.post.sha256" && vsrc_status=PASS
cmp -s "$TMP_DIR/synth-flow-inputs.pre.sha256" \
  "$TMP_DIR/synth-flow-inputs.post.sha256" && flow_status=PASS
{
  printf 'rtl_inputs=%s\n' "$rtl_status"
  printf 'vsrc_tree=%s\n' "$vsrc_status"
  printf 'flow_inputs=%s\n' "$flow_status"
} >"$TMP_DIR/synth-input-hash-cmp.txt"
cp "$TMP_DIR/synth-input-hash-cmp.txt" \
  "$TASK_DIR/evidence/synthesis/synth-input-hash-cmp.txt"
cp "$TMP_DIR/synth-exit-status.txt" \
  "$TASK_DIR/evidence/synthesis/synth-exit-status.txt"

if [[ $rtl_status != PASS || $vsrc_status != PASS || $flow_status != PASS ]]; then
  printf '[T3I-SYNTH] input freeze violated\n' >&2
  exit 94
fi
if [[ $synth_rc -ne 0 ]]; then
  printf '[T3I-SYNTH] synthesis failed rc=%s\n' "$synth_rc" >&2
  exit "$synth_rc"
fi
printf '[T3I-SYNTH] PASS inputs frozen result=%s\n' "$STA_ROOT/NpcTop-200MHz"
