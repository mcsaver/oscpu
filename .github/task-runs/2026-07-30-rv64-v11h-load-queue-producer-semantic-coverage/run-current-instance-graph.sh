#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REVISION="${V11H_INSTANCE_GRAPH_REVISION:-2}"
case "$REVISION" in
  1)
    EVIDENCE_DIR="$RUN_DIR/evidence/current-instance-graph"
    STATUS="$RUN_DIR/v11h-current-instance-graph.status"
    ;;
  2)
    EVIDENCE_DIR="$RUN_DIR/evidence/current-instance-graph-v2"
    STATUS="$RUN_DIR/v11h-current-instance-graph-v2.status"
    ;;
  *)
    printf '[V11H-CURRENT-INSTANCE-GRAPH][FAIL] unsupported revision=%s\n' \
      "$REVISION" >&2
    exit 2
    ;;
esac
SUMMARY="$EVIDENCE_DIR/runner-summary.log"
TEMP_DIR=""
SUMMARY_TMP=""
STATUS_HELPER_READY=0
CURRENT_STAGE="pre-helper"

runner_atomic_line() {
  local path="${1:?path is required}"
  local line="${2:?line is required}"
  local temp="${path}.tmp.$$"

  printf '%s\n' "$line" >"$temp"
  mv -f -- "$temp" "$path"
}

cleanup() {
  if [[ -n "$SUMMARY_TMP" && -f "$SUMMARY_TMP" &&
        "$SUMMARY_TMP" == "$SUMMARY".tmp.* ]]; then
    rm -f -- "$SUMMARY_TMP"
  fi
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" &&
        "$TEMP_DIR" == "${TMPDIR:-/tmp}"/rv64-v11h-instance-graph.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}

finalize() {
  local command_rc=$?
  local cleanup_rc=0
  local final_rc="$command_rc"

  trap - EXIT
  trap '' HUP INT TERM
  set +e
  cleanup
  cleanup_rc=$?
  if [[ "$STATUS_HELPER_READY" -eq 1 ]]; then
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
    "[V11H-CURRENT-INSTANCE-GRAPH][FAIL] rc=$final_rc stage=$CURRENT_STAGE evidence_complete=0"
  exit "$final_rc"
}

mkdir -p "$EVIDENCE_DIR"
runner_atomic_line "$STATUS" "RUNNING"
runner_atomic_line \
  "$SUMMARY" \
  "[V11H-CURRENT-INSTANCE-GRAPH][RUNNING] evidence is incomplete"
trap finalize EXIT

REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
EXPECTED_RUN_DIR="$REPO_ROOT/.github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage"
[[ "$RUN_DIR" == "$EXPECTED_RUN_DIR" ]]
cd "$REPO_ROOT"

TOOL="$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py"
CENSUS_TOOL="$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_census.py"
CANONICAL="$EVIDENCE_DIR/holder-instance-graph.json"
CANONICAL_RECEIPT="$EVIDENCE_DIR/yosys-instance-graph-receipt.json"
CANONICAL_FULL="$EVIDENCE_DIR/yosys-instance-graph.full.json.gz"
CANONICAL_SCRIPT="$EVIDENCE_DIR/yosys-instance-graph.ys"
CANONICAL_LOG="$EVIDENCE_DIR/yosys-instance-graph.log"
STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"

for artifact in \
  "$CANONICAL" \
  "$CANONICAL_RECEIPT" \
  "$CANONICAL_FULL" \
  "$CANONICAL_SCRIPT" \
  "$CANONICAL_LOG"; do
  [[ -f "$artifact" ]]
done

source "$STATUS_HELPER"
STATUS_HELPER_READY=1
task_run_status_init "$STATUS"
task_run_status_install_signal_traps

runner_stage() {
  CURRENT_STAGE="${1:?stage is required}"
  task_run_status_stage "$CURRENT_STAGE"
}

fail() {
  printf '[V11H-CURRENT-INSTANCE-GRAPH][FAIL] %s\n' "$*" >&2
  exit 1
}

runner_stage "allocate-temp"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/rv64-v11h-instance-graph.XXXXXX")

source_paths=(
  "$REPO_ROOT/scripts/task-run-status.sh"
  "$REPO_ROOT/npc/rv64/Makefile"
  "$REPO_ROOT/npc/rv64/configs/product-rtl-defaults.mk"
  "$REPO_ROOT/npc/rv64/design/arch/producer-holder-census.json"
  "$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_census.py"
  "$REPO_ROOT/npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py"
  "$REPO_ROOT/npc/rv64/eval/ppa/tests/test_producer_holder_census.py"
  "$REPO_ROOT/npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py"
  "$RUN_DIR/run-current-instance-graph.sh"
)

runner_stage "source-pre-hash"
sha256sum "${source_paths[@]}" >"$EVIDENCE_DIR/sources.pre.sha256"

runner_stage "instance-graph-unit"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_producer_holder_instance_graph \
  >"$EVIDENCE_DIR/instance-graph-unit.log" 2>&1

runner_stage "census-unit"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_producer_holder_census \
  >"$EVIDENCE_DIR/census-unit.log" 2>&1

runner_stage "fresh-yosys-elaboration"
python3 "$TOOL" \
  --elaborate \
  --timeout-seconds 180 \
  --json-out "$TEMP_DIR/holder-instance-graph.json" \
  --receipt-out "$TEMP_DIR/yosys-instance-graph-receipt.json" \
  --full-json-out "$TEMP_DIR/yosys-instance-graph.full.json.gz" \
  --script-out "$TEMP_DIR/yosys-instance-graph.ys" \
  --log-out "$TEMP_DIR/yosys-instance-graph.log" \
  >"$EVIDENCE_DIR/fresh-elaboration.stdout.log" 2>&1

runner_stage "byte-identical-result"
cmp "$TEMP_DIR/holder-instance-graph.json" "$CANONICAL" ||
  fail "fresh result differs from the V11H canonical result"
cmp "$TEMP_DIR/yosys-instance-graph-receipt.json" "$CANONICAL_RECEIPT" ||
  fail "fresh receipt differs from the V11H canonical receipt"
cmp "$TEMP_DIR/yosys-instance-graph.full.json.gz" "$CANONICAL_FULL" ||
  fail "fresh full hierarchy differs from the V11H canonical hierarchy"
cmp "$TEMP_DIR/yosys-instance-graph.ys" "$CANONICAL_SCRIPT" ||
  fail "fresh Yosys script differs from the V11H canonical script"
cmp "$TEMP_DIR/yosys-instance-graph.log" "$CANONICAL_LOG" ||
  fail "fresh Yosys log differs from the V11H canonical log"

runner_stage "frozen-audit"
python3 "$TOOL" --check-frozen \
  >"$EVIDENCE_DIR/frozen-audit.log" 2>&1

runner_stage "census-audit"
python3 "$CENSUS_TOOL" \
  --json-out "$EVIDENCE_DIR/producer-holder-census-audit.json" \
  >"$EVIDENCE_DIR/census-audit.log" 2>&1

runner_stage "source-post-hash"
sha256sum "${source_paths[@]}" >"$EVIDENCE_DIR/sources.post.sha256"
cmp "$EVIDENCE_DIR/sources.pre.sha256" \
  "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "bound source files changed during V11H instance-graph replay"

current_design_id=$(jq -r '.design_id' "$CANONICAL")
[[ "$current_design_id" =~ ^sha256:[0-9a-f]{64}$ ]]
runner_stage "final-cleanup"
cleanup
TEMP_DIR=""
trap '' HUP INT TERM

SUMMARY_TMP="${SUMMARY}.tmp.$$"
printf '%s\n' \
  "[V11H-CURRENT-INSTANCE-GRAPH][PASS] design_id=$current_design_id" \
  "[V11H-CURRENT-INSTANCE-GRAPH][PASS] holder_modules=15 holder_instances=17 duplicate_modules=2 reachable_instances=194" \
  "[V11H-CURRENT-INSTANCE-GRAPH][PASS] fresh_elaboration=byte-identical frozen_audit=PASS census_audit=PASS" \
  "[V11H-CURRENT-INSTANCE-GRAPH][BOUNDARY] instance multiplicity only; semantic ledger and architecture remain separate" \
  >"$SUMMARY_TMP"
mv -f -- "$SUMMARY_TMP" "$SUMMARY"
SUMMARY_TMP=""
task_run_status_mark_evidence_complete
runner_stage "publish-status"
task_run_status_finalize 0 0
trap - EXIT
cat "$SUMMARY"
