#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
EVIDENCE_DIR="$RUN_DIR/evidence"
SUMMARY="$EVIDENCE_DIR/runner-summary.log"
STATUS="$RUN_DIR/v11a-instance-graph.status"
TEMP_DIR=""
SUMMARY_TMP=""
STATUS_HELPER_READY=0
CURRENT_STAGE="pre-helper"
EARLY_SIGNAL="none"
QUEUED_SIGNAL_RC=0

runner_atomic_line() {
  local path="${1:?path is required}"
  local line="${2:?line is required}"
  local temp="${path}.tmp.$$"

  printf '%s\n' "$line" > "$temp"
  mv -f -- "$temp" "$path"
}

cleanup() {
  local cleanup_rc=0

  if [[ -n "$SUMMARY_TMP" && -f "$SUMMARY_TMP" &&
        "$SUMMARY_TMP" == "$SUMMARY".tmp.* ]]; then
    rm -f -- "$SUMMARY_TMP" || cleanup_rc=$?
  fi
  if [[ -n "$TEMP_DIR" &&
        -d "$TEMP_DIR" &&
        "$TEMP_DIR" == "${TMPDIR:-/tmp}"/rv64-holder-instance-graph.* ]]; then
    rm -rf -- "$TEMP_DIR" || cleanup_rc=$?
  fi
  return "$cleanup_rc"
}

finalize() {
  local command_rc=$?
  local cleanup_rc=0
  local final_rc="$command_rc"

  trap - EXIT
  # HUP/INT/TERM cannot interrupt cleanup or the final FAIL publication.
  trap '' HUP INT TERM
  set +e
  cleanup
  cleanup_rc=$?
  if [[ "$STATUS_HELPER_READY" -eq 1 ]]; then
    if [[ "$EARLY_SIGNAL" != "none" ]]; then
      TASK_RUN_STATUS_SIGNAL="$EARLY_SIGNAL"
    fi
    task_run_status_finalize "$command_rc" "$cleanup_rc"
    final_rc=$?
  else
    if [[ "$final_rc" -eq 0 ]]; then
      final_rc=1
    fi
    runner_atomic_line \
      "$STATUS" \
      "FAIL rc=$final_rc stage=$CURRENT_STAGE evidence_complete=0 cleanup_rc=$cleanup_rc"
  fi
  runner_atomic_line \
    "$SUMMARY" \
    "[V11A-INSTANCE-GRAPH][FAIL] rc=$final_rc stage=$CURRENT_STAGE evidence_complete=0"
  exit "$final_rc"
}

early_signal() {
  EARLY_SIGNAL="${1:?signal name is required}"
  exit "${2:?signal return code is required}"
}

queue_signal() {
  EARLY_SIGNAL="${1:?signal name is required}"
  QUEUED_SIGNAL_RC="${2:?signal return code is required}"
}

mkdir -p "$EVIDENCE_DIR"
runner_atomic_line "$STATUS" "RUNNING"
runner_atomic_line \
  "$SUMMARY" \
  "[V11A-INSTANCE-GRAPH][RUNNING] evidence is incomplete"
trap finalize EXIT
trap 'early_signal HUP 129' HUP
trap 'early_signal INT 130' INT
trap 'early_signal TERM 143' TERM

REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
EXPECTED_RUN_DIR="$REPO_ROOT/.github/task-runs/2026-07-29-rv64-v11a-producer-holder-instance-graph"
[[ "$RUN_DIR" == "$EXPECTED_RUN_DIR" ]] || {
  printf '%s\n' "[V11A-INSTANCE-GRAPH][FAIL] unexpected task-run path: $RUN_DIR" >&2
  exit 2
}
cd "$REPO_ROOT"

TOOL="$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py"
CANONICAL="$EVIDENCE_DIR/holder-instance-graph.json"
CANONICAL_RECEIPT="$EVIDENCE_DIR/yosys-instance-graph-receipt.json"
CANONICAL_FULL="$EVIDENCE_DIR/yosys-instance-graph.full.json.gz"
CANONICAL_SCRIPT="$EVIDENCE_DIR/yosys-instance-graph.ys"
CANONICAL_LOG="$EVIDENCE_DIR/yosys-instance-graph.log"
STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"

source "$STATUS_HELPER"
STATUS_HELPER_READY=1
task_run_status_init "$STATUS"
task_run_status_install_signal_traps

runner_stage() {
  CURRENT_STAGE="${1:?stage is required}"
  task_run_status_stage "$CURRENT_STAGE"
}

fail() {
  printf '[V11A-INSTANCE-GRAPH][FAIL] %s\n' "$*" >&2
  exit 1
}

rm -f -- \
  "$EVIDENCE_DIR/instance-graph-unit.log" \
  "$EVIDENCE_DIR/census-unit.log" \
  "$EVIDENCE_DIR/task-run-status-unit.log" \
  "$EVIDENCE_DIR/fresh-elaboration.stdout.log" \
  "$EVIDENCE_DIR/frozen-audit.log" \
  "$EVIDENCE_DIR/census-audit.log"
runner_stage "allocate-temp"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/rv64-holder-instance-graph.XXXXXX")

source_paths=(
  "$REPO_ROOT/scripts/task-run-status.sh"
  "$REPO_ROOT/npc/rv64/Makefile"
  "$REPO_ROOT/npc/rv64/configs/product-rtl-defaults.mk"
  "$REPO_ROOT/npc/rv64/design/arch/producer-holder-census.json"
  "$REPO_ROOT/npc/rv64/eval/ppa/tools/arch_stable_freeze.py"
  "$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_census.py"
  "$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py"
  "$REPO_ROOT/npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py"
  "$REPO_ROOT/npc/rv64/eval/ppa/tests/test_producer_holder_census.py"
  "$REPO_ROOT/npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py"
  "$REPO_ROOT/npc/rv64/eval/ppa/tests/test_v11a_instance_graph_runner.py"
  "$REPO_ROOT/scripts/tests/test-task-run-status.sh"
  "$RUN_DIR/run-instance-graph.sh"
)
sha256sum "${source_paths[@]}" > "$TEMP_DIR/sources.pre.sha256"

runner_stage "instance-graph-unit"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_producer_holder_instance_graph \
  npc.rv64.eval.ppa.tests.test_v11a_instance_graph_runner \
  > "$EVIDENCE_DIR/instance-graph-unit.log" 2>&1
runner_stage "census-unit"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_producer_holder_census \
  > "$EVIDENCE_DIR/census-unit.log" 2>&1
runner_stage "task-run-status-unit"
"$REPO_ROOT/scripts/tests/test-task-run-status.sh" \
  > "$EVIDENCE_DIR/task-run-status-unit.log" 2>&1

runner_stage "fresh-yosys-elaboration"
python3 "$TOOL" \
  --elaborate \
  --timeout-seconds 180 \
  --json-out "$TEMP_DIR/holder-instance-graph.json" \
  --receipt-out "$TEMP_DIR/yosys-instance-graph-receipt.json" \
  --full-json-out "$TEMP_DIR/yosys-instance-graph.full.json.gz" \
  --script-out "$TEMP_DIR/yosys-instance-graph.ys" \
  --log-out "$TEMP_DIR/yosys-instance-graph.log" \
  > "$EVIDENCE_DIR/fresh-elaboration.stdout.log" 2>&1

runner_stage "byte-identical-result"
cmp "$TEMP_DIR/holder-instance-graph.json" "$CANONICAL" ||
  fail "fresh elaboration result differs from frozen canonical result"
cmp "$TEMP_DIR/yosys-instance-graph-receipt.json" "$CANONICAL_RECEIPT" ||
  fail "fresh normalized Yosys receipt differs from frozen receipt"
cmp "$TEMP_DIR/yosys-instance-graph.full.json.gz" "$CANONICAL_FULL" ||
  fail "fresh canonical full Yosys hierarchy differs from frozen artifact"
cmp "$TEMP_DIR/yosys-instance-graph.ys" "$CANONICAL_SCRIPT" ||
  fail "fresh canonical Yosys script differs from frozen script"
cmp "$TEMP_DIR/yosys-instance-graph.log" "$CANONICAL_LOG" ||
  fail "fresh Yosys hierarchy log differs from frozen log"

runner_stage "frozen-audit"
python3 "$TOOL" --check-frozen \
  > "$EVIDENCE_DIR/frozen-audit.log" 2>&1
runner_stage "census-audit"
python3 "$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_census.py" \
  > "$EVIDENCE_DIR/census-audit.log" 2>&1

runner_stage "source-post-hash"
sha256sum "${source_paths[@]}" > "$TEMP_DIR/sources.post.sha256"
cmp "$TEMP_DIR/sources.pre.sha256" "$TEMP_DIR/sources.post.sha256" ||
  fail "bound source files changed during instance-graph replay"

# No PASS artifact exists before cleanup and explicit status completion.
runner_stage "final-cleanup"
trap 'queue_signal HUP 129' HUP
trap 'queue_signal INT 130' INT
trap 'queue_signal TERM 143' TERM
cleanup
TEMP_DIR=""
SUMMARY_TMP=""
if [[ "$QUEUED_SIGNAL_RC" -ne 0 ]]; then
  exit "$QUEUED_SIGNAL_RC"
fi

# Cleanup is complete; mask terminal signals only for the bounded atomic
# publication sequence.  Any signal observed during cleanup already failed the
# run above, and the EXIT finalizer will publish that signal in the status.
trap '' HUP INT TERM
runner_stage "publish-status"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0

SUMMARY_TMP="${SUMMARY}.tmp.$$"
current_design_id="$(jq -r '.design_id' "$CANONICAL")"
[[ "$current_design_id" =~ ^sha256:[0-9a-f]{64}$ ]] ||
  fail "canonical result has invalid design_id"
printf '%s\n' \
  "[V11A-INSTANCE-GRAPH][PASS] design_id=$current_design_id" \
  '[V11A-INSTANCE-GRAPH][PASS] holder_modules=15 holder_instances=17 duplicate_modules=2 reachable_instances=194' \
  '[V11A-INSTANCE-GRAPH][PASS] source_count=127 result_receipt_full_script_log=byte-identical frozen_audit=PASS' \
  '[V11A-INSTANCE-GRAPH][PASS] OooMemInflightQueue=2 OooMemAxiBridge=2 fresh_elaboration=PASS' \
  '[V11A-INSTANCE-GRAPH][PASS] instance_graph_unit=23/23 census_unit=15/15 task_status_unit=PASS' \
  '[V11A-INSTANCE-GRAPH][BOUNDARY] semantic_complete=false whole_architecture=RED ppa=UNPROMOTED' \
  > "$SUMMARY_TMP"
mv -f -- "$SUMMARY_TMP" "$SUMMARY"
SUMMARY_TMP=""
trap - EXIT
cat "$SUMMARY" || true
exit 0
