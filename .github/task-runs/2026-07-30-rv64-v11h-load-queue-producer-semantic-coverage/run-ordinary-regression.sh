#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
ATTEMPT="${V11H_ORDINARY_ATTEMPT:-1}"
[[ "$ATTEMPT" =~ ^[1-9][0-9]*$ ]]
EVIDENCE_DIR="$RUN_DIR/evidence/ordinary-regression-attempt-$ATTEMPT"
STATUS="$RUN_DIR/ordinary-regression-attempt-$ATTEMPT.status"
SUMMARY="$EVIDENCE_DIR/runner-summary.log"
CURRENT_STAGE="pre-init"
STATUS_HELPER_READY=0

atomic_line() {
  local path="${1:?path is required}"
  local value="${2:?value is required}"
  local temporary="${path}.tmp.$$"

  printf '%s\n' "$value" >"$temporary"
  mv -f -- "$temporary" "$path"
}

finalize() {
  local command_rc=$?
  local final_rc="$command_rc"

  trap - EXIT
  trap '' HUP INT TERM
  set +e
  if [[ "$STATUS_HELPER_READY" -eq 1 ]]; then
    task_run_status_finalize "$command_rc" 0
    final_rc=$?
  elif [[ "$final_rc" -eq 0 ]]; then
    final_rc=1
  fi
  if [[ "$final_rc" -ne 0 ]]; then
    atomic_line \
      "$SUMMARY" \
      "[V11H-LQ-ORDINARY-REGRESSION][FAIL] rc=$final_rc stage=$CURRENT_STAGE evidence_complete=0"
  fi
  exit "$final_rc"
}

[[ "$RUN_DIR" == \
  "$REPO_ROOT/.github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage" ]]
[[ ! -e "$EVIDENCE_DIR" ]]
mkdir -p "$EVIDENCE_DIR"
atomic_line "$STATUS" "RUNNING"
atomic_line \
  "$SUMMARY" \
  "[V11H-LQ-ORDINARY-REGRESSION][RUNNING] evidence is incomplete"
trap finalize EXIT

source "$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_READY=1
task_run_status_init "$STATUS"
task_run_status_install_signal_traps

runner_stage() {
  CURRENT_STAGE="${1:?stage is required}"
  task_run_status_stage "$CURRENT_STAGE"
}

SNAPSHOT_TOOL="$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
RESULT_DIR="$EVIDENCE_DIR/result"
BUILD_DIR="$EVIDENCE_DIR/build"
LOAD_LOG="$RESULT_DIR/logs/tb_ooo_load_queue.log"
PARENT_LOG="$RESULT_DIR/logs/tb_ooo_int_backend.log"

source_paths=(
  "scripts/task-run-status.sh"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/run-ordinary-regression.sh"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/load-queue-producer-attempt-4/summary.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/load-queue-producer-attempt-4.status"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/load-queue-producer-attempt-4-checker-replay/receipt.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/load-queue-producer-attempt-4-checker-replay.status"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/current-instance-graph-v2/holder-instance-graph.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/v11h-current-instance-graph-v2.status"
  "npc/rv64/vsrc/memory/OooLoadQueue.v"
  "npc/rv64/vsrc/execute/OooIntBackend.v"
  "npc/rv64/vsrc/include/define.v"
  "npc/rv64/vsrc/filelist.mk"
  "npc/rv64/testbench/Makefile"
  "npc/rv64/testbench/common/tb_common.svh"
  "npc/rv64/testbench/tests/tb_ooo_load_queue.sv"
  "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
)

cd "$REPO_ROOT"
runner_stage "source-pre-hash"
sha256sum "${source_paths[@]}" >"$EVIDENCE_DIR/sources.pre.sha256"
python3 "$SNAPSHOT_TOOL" \
  --snapshot-out "$EVIDENCE_DIR/rtl-source-binding.pre.json"
design_id=$(jq -r '.design_id' "$EVIDENCE_DIR/rtl-source-binding.pre.json")
[[ "$design_id" =~ ^sha256:[0-9a-f]{64}$ ]]

runner_stage "load-queue-and-parent-testbench"
make --no-print-directory \
  -C "$REPO_ROOT/npc/rv64/testbench" \
  "BUILD_DIR=$BUILD_DIR" \
  "RESULT_DIR=$RESULT_DIR" \
  "RTL_EVIDENCE_SHA=${design_id#sha256:}" \
  "$LOAD_LOG" \
  "$PARENT_LOG" \
  >"$EVIDENCE_DIR/make.log" 2>&1

runner_stage "result-markers"
grep -q '\[RESULT\] PASS' "$LOAD_LOG"
grep -q '\[PASS\] tb_ooo_load_queue' "$LOAD_LOG"
grep -q '\[RESULT\] PASS' "$PARENT_LOG"
grep -q '\[PASS\] tb_ooo_int_backend' "$PARENT_LOG"
grep -q -- '-DOOO_ASSERT' "$LOAD_LOG"
grep -q -- '-DOOO_ASSERT' "$PARENT_LOG"
if grep -Eq '\[V11H-LQ-(DUP-TERMINAL|PID-KNOWN)\]' \
  "$LOAD_LOG" "$PARENT_LOG"; then
  printf '%s\n' \
    "[V11H-LQ-ORDINARY-REGRESSION][FAIL] RTL assertion marker observed" \
    >&2
  exit 1
fi

runner_stage "source-post-hash"
sha256sum "${source_paths[@]}" >"$EVIDENCE_DIR/sources.post.sha256"
cmp "$EVIDENCE_DIR/sources.pre.sha256" \
  "$EVIDENCE_DIR/sources.post.sha256"
python3 "$SNAPSHOT_TOOL" \
  --snapshot-out "$EVIDENCE_DIR/rtl-source-binding.post.json"
cmp "$EVIDENCE_DIR/rtl-source-binding.pre.json" \
  "$EVIDENCE_DIR/rtl-source-binding.post.json"

runner_stage "publish-summary"
printf '%s\n' \
  "[V11H-LQ-ORDINARY-REGRESSION][PASS] attempt=$ATTEMPT design_id=$design_id" \
  "[V11H-LQ-ORDINARY-REGRESSION][PASS] tb_ooo_load_queue assertions=on GEN_W=4" \
  "[V11H-LQ-ORDINARY-REGRESSION][PASS] tb_ooo_int_backend assertions=on parent_integration=PASS" \
  "[V11H-LQ-ORDINARY-REGRESSION][PASS] rtl_assertion_markers=0 source_pre_post=identical" \
  "[V11H-LQ-ORDINARY-REGRESSION][BOUNDARY] focused module/parent regression only; no system or PPA promotion" \
  >"$SUMMARY"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
trap - EXIT
cat "$SUMMARY"
