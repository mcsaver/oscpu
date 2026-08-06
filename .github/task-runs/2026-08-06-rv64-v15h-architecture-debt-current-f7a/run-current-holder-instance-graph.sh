#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
EVIDENCE_DIR="$RUN_DIR/evidence/current-holder-instance-graph"
STATUS="$RUN_DIR/current-holder-instance-graph.status"
TOOL="$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py"
EXPECTED_DESIGN_ID="sha256:f7a6845564f2d697fca9eac8bf9424136508a62c7fcc7851ad56c688dc2053f9"
TEMP_DIR=""

source "$REPO_ROOT/scripts/task-run-status.sh"
task_run_status_init "$STATUS"
task_run_status_install_signal_traps

cleanup() {
  local cleanup_rc=0
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" &&
        "$TEMP_DIR" == "${TMPDIR:-/tmp}"/rv64-v15h-holder-graph.* ]]; then
    rm -rf -- "$TEMP_DIR" || cleanup_rc=$?
  fi
  return "$cleanup_rc"
}

finalize() {
  local command_rc=$?
  local cleanup_rc=0
  local final_rc
  trap - EXIT
  set +e
  cleanup
  cleanup_rc=$?
  task_run_status_finalize "$command_rc" "$cleanup_rc"
  final_rc=$?
  exit "$final_rc"
}
trap finalize EXIT

mkdir -p "$EVIDENCE_DIR"
cd "$REPO_ROOT"
task_run_status_stage "allocate-temp"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/rv64-v15h-holder-graph.XXXXXX")

task_run_status_stage "rtl-pre-hash"
find npc/rv64/vsrc -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
  -print0 | sort -z | xargs -0 sha256sum > "$TEMP_DIR/rtl.pre.sha256"

task_run_status_stage "yosys-elaboration"
python3 -B "$TOOL" \
  --elaborate \
  --timeout-seconds 180 \
  --json-out "$TEMP_DIR/holder-instance-graph.json" \
  --receipt-out "$TEMP_DIR/yosys-instance-graph-receipt.json" \
  --full-json-out "$TEMP_DIR/yosys-instance-graph.full.json.gz" \
  --script-out "$TEMP_DIR/yosys-instance-graph.ys" \
  --log-out "$TEMP_DIR/yosys-instance-graph.log" \
  > "$EVIDENCE_DIR/yosys-elaboration.stdout.log" 2>&1

task_run_status_stage "result-check"
[[ "$(jq -r '.status' "$TEMP_DIR/holder-instance-graph.json")" == "PASS" ]]
[[ "$(jq -r '.design_id' "$TEMP_DIR/holder-instance-graph.json")" == "$EXPECTED_DESIGN_ID" ]]
[[ "$(jq -r '.counts.holder_modules' "$TEMP_DIR/holder-instance-graph.json")" == "15" ]]
[[ "$(jq -r '.counts.holder_instances' "$TEMP_DIR/holder-instance-graph.json")" == "17" ]]

task_run_status_stage "rtl-post-hash"
find npc/rv64/vsrc -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
  -print0 | sort -z | xargs -0 sha256sum > "$TEMP_DIR/rtl.post.sha256"
cmp "$TEMP_DIR/rtl.pre.sha256" "$TEMP_DIR/rtl.post.sha256"

task_run_status_stage "publish-evidence"
for artifact in \
  holder-instance-graph.json \
  yosys-instance-graph-receipt.json \
  yosys-instance-graph.full.json.gz \
  yosys-instance-graph.ys \
  yosys-instance-graph.log
do
  mv -f -- "$TEMP_DIR/$artifact" "$EVIDENCE_DIR/$artifact"
done
sha256sum \
  "$EVIDENCE_DIR/holder-instance-graph.json" \
  "$EVIDENCE_DIR/yosys-instance-graph-receipt.json" \
  "$EVIDENCE_DIR/yosys-instance-graph.full.json.gz" \
  "$EVIDENCE_DIR/yosys-instance-graph.ys" \
  "$EVIDENCE_DIR/yosys-instance-graph.log" \
  > "$EVIDENCE_DIR/artifacts.sha256"

task_run_status_stage "cleanup"
cleanup
TEMP_DIR=""

task_run_status_stage "publish-status"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
trap - EXIT
printf '[V15H-HOLDER-INSTANCE-GRAPH][PASS] design_id=%s modules=15 instances=17\n' \
  "$EXPECTED_DESIGN_ID"
