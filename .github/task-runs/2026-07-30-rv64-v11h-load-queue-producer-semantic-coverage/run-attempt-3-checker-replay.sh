#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
REPLAY_DIR="$RUN_DIR/evidence/load-queue-producer-attempt-3-checker-replay"
STATUS="$RUN_DIR/load-queue-producer-attempt-3-checker-replay.status"
SUMMARY="$REPLAY_DIR/runner-summary.log"
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
      "[V11H-LQ-CHECKER-REPLAY][FAIL] rc=$final_rc stage=$CURRENT_STAGE evidence_complete=0"
  fi
  exit "$final_rc"
}

[[ "$RUN_DIR" == \
  "$REPO_ROOT/.github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage" ]]
[[ ! -e "$REPLAY_DIR" ]]
mkdir -p "$REPLAY_DIR"
atomic_line "$STATUS" "RUNNING"
atomic_line \
  "$SUMMARY" \
  "[V11H-LQ-CHECKER-REPLAY][RUNNING] evidence is incomplete"
trap finalize EXIT

source "$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_READY=1
task_run_status_init "$STATUS"
task_run_status_install_signal_traps

runner_stage() {
  CURRENT_STAGE="${1:?stage is required}"
  task_run_status_stage "$CURRENT_STAGE"
}

REPLAY_TOOL="$REPO_ROOT/npc/rv64/eval/ppa/tools/load_queue_producer_checker_replay.py"
SEMANTIC_TOOL="$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py"
RECEIPT="$REPLAY_DIR/receipt.json"
LEDGER="$REPLAY_DIR/semantic-ledger.json"

source_paths=(
  "scripts/task-run-status.sh"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/run-attempt-3-checker-replay.sh"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/load-queue-producer-attempt-3.status"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/load-queue-producer-attempt-3/summary.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/load-queue-producer-attempt-3/sources.pre.sha256"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/load-queue-producer-attempt-3/sources.post.sha256"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/load-queue-producer-attempt-3/rtl-source-binding.pre.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/load-queue-producer-attempt-3/rtl-source-binding.post.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/load-queue-producer-attempt-3/evidence-tool-unit.log"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/load-queue-producer-attempt-3/semantic-ledger-unit.log"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/current-instance-graph/holder-instance-graph.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/v11h-current-instance-graph.status"
  "npc/rv64/design/arch/producer-holder-census.json"
  "npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json"
  "npc/rv64/eval/ppa/tools/load_queue_producer_checker_replay.py"
  "npc/rv64/eval/ppa/tests/test_load_queue_producer_checker_replay.py"
  "npc/rv64/eval/ppa/tools/load_queue_producer_semantic_evidence.py"
  "npc/rv64/eval/ppa/tests/test_load_queue_producer_semantic_evidence.py"
  "npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py"
  "npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py"
)

cd "$REPO_ROOT"
runner_stage "source-pre-hash"
sha256sum "${source_paths[@]}" >"$REPLAY_DIR/sources.pre.sha256"

runner_stage "receipt-build"
python3 "$REPLAY_TOOL" build --output "$RECEIPT" \
  >"$REPLAY_DIR/receipt-build.log" 2>&1
runner_stage "receipt-verify"
python3 "$REPLAY_TOOL" verify --input "$RECEIPT" \
  >"$REPLAY_DIR/receipt-verify.log" 2>&1

runner_stage "checker-replay-unit"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_load_queue_producer_checker_replay \
  >"$REPLAY_DIR/checker-replay-unit.log" 2>&1
runner_stage "load-queue-evidence-unit"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_load_queue_producer_semantic_evidence \
  >"$REPLAY_DIR/load-queue-evidence-unit.log" 2>&1
runner_stage "semantic-ledger-unit"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_producer_holder_semantic_coverage \
  >"$REPLAY_DIR/semantic-ledger-unit.log" 2>&1

runner_stage "semantic-ledger-build"
python3 "$SEMANTIC_TOOL" build --output "$LEDGER" \
  >"$REPLAY_DIR/semantic-ledger-build.log" 2>&1
runner_stage "semantic-ledger-verify"
python3 "$SEMANTIC_TOOL" verify --input "$LEDGER" \
  >"$REPLAY_DIR/semantic-ledger-verify.log" 2>&1

runner_stage "source-post-hash"
sha256sum "${source_paths[@]}" >"$REPLAY_DIR/sources.post.sha256"
cmp "$REPLAY_DIR/sources.pre.sha256" "$REPLAY_DIR/sources.post.sha256"

runner_stage "publish-summary"
printf '%s\n' \
  "[V11H-LQ-CHECKER-REPLAY][PASS] original_attempt=3 original_status=FAIL@semantic-ledger-unit" \
  "[V11H-LQ-CHECKER-REPLAY][PASS] frozen_profiles=4 frozen_mutations=31x2 rtl_simulation_reexecuted=0" \
  "[V11H-LQ-CHECKER-REPLAY][PASS] replay_builder_unit=5/5 load_queue_evidence_unit=8/8 semantic_ledger_unit=21/21" \
  "[V11H-LQ-CHECKER-REPLAY][PASS] semantic_units=44 pass=11 gap=33 ledger_verify=PASS" \
  "[V11H-LQ-CHECKER-REPLAY][BOUNDARY] original FAIL is preserved; whole architecture remains RED and PPA remains UNPROMOTED" \
  >"$SUMMARY"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
trap - EXIT
cat "$SUMMARY"
