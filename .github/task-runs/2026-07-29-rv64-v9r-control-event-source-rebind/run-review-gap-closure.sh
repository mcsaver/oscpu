#!/usr/bin/env bash
set -euo pipefail

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$run_dir" rev-parse --show-toplevel)
evidence_dir="$run_dir/evidence"
log_dir="$evidence_dir/debt-rebind-logs"
v10c_dir="$repo_root/.github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay"
v9o_dir="$repo_root/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
serialize_dir="$repo_root/.github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure"
mkdir -p "$log_dir"

run_logged() {
  local name=$1
  shift
  local log="$log_dir/$name.log"
  local rc

  set +e
  "$@" 2>&1 | tee "$log"
  rc=${PIPESTATUS[0]}
  set -e
  printf '%s\n' "$rc" > "$log_dir/$name.rc"
  if [[ "$rc" -ne 0 ]]; then
    printf '[V9R-REVIEW-GAP-CLOSURE][FAIL] step=%s rc=%s\n' \
      "$name" "$rc" >&2
    return "$rc"
  fi
  printf '[V9R-REVIEW-GAP-CLOSURE][PASS] step=%s\n' "$name"
}

run_logged v10c-review-gap-to-currentness-a20 \
  env \
    V10C_ATTEMPT=20 \
    V10C_START_STAGE=control-event-gap-boundary \
    V10C_EVIDENCE_DIR_OVERRIDE="$evidence_dir/v10c-replay-review-gap-closure-a20" \
    V10C_DRIVER_LOG_OVERRIDE="$log_dir/v10c-review-gap-a20-driver.log" \
    V10C_REPLAY_STATUS_PATH_OVERRIDE="$evidence_dir/v10c-review-gap-a20.status" \
    V10C_TASK_STATUS_PATH_OVERRIDE="$evidence_dir/v10c-review-gap-a20-task.status" \
    bash "$v10c_dir/run-current-design-evidence-replay.sh"

run_logged v9o-index-final-verify \
  python3 "$v9o_dir/build-evidence-index.py" --verify

run_logged serialize-g1-final-verify \
  python3 "$serialize_dir/verify_serialize_g1_closure.py"

run_logged arch-stable-currentness-tests \
  env PYTHONDONTWRITEBYTECODE=1 \
    python3 -m unittest npc.rv64.eval.ppa.tests.test_arch_stable_freeze

run_logged historical-defect-backfill-tests \
  env PYTHONDONTWRITEBYTECODE=1 \
    python3 -m unittest npc.rv64.eval.ppa.tests.test_historical_defect_backfill

run_logged task-local-workflow-tests \
  env PYTHONDONTWRITEBYTECODE=1 \
    python3 -m unittest discover \
      -s "$run_dir" \
      -p 'test_*.py'

run_logged postflight \
  python3 "$run_dir/finalize-postflight.py"
