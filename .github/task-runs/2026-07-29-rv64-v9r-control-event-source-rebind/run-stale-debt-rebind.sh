#!/usr/bin/env bash
set -euo pipefail

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$run_dir" rev-parse --show-toplevel)
npc_home="$repo_root/npc/rv64"
evidence_dir="$run_dir/evidence"
log_dir="$evidence_dir/debt-rebind-logs"
v10c_dir="$repo_root/.github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay"
v9o_dir="$repo_root/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
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
    printf '[V9R-DEBT-REBIND][FAIL] step=%s rc=%s\n' \
      "$name" "$rc" >&2
    return "$rc"
  fi
  printf '[V9R-DEBT-REBIND][PASS] step=%s\n' "$name"
}

run_logged fdg-arch-trap \
  make -C "$npc_home" check-fdg-arch-trap
run_logged xret-current-mode \
  make -C "$npc_home" check-xret-current-mode
run_logged memory-issue-lifecycle \
  make -C "$npc_home" check-memory-issue-lifecycle
run_logged ifu-axi-flush-drain \
  make -C "$npc_home" check-ifu-axi-flush-drain
run_logged ifu-fetch-provenance \
  make -C "$npc_home" check-ifu-fetch-provenance
run_logged ifu-access \
  make -C "$npc_home" check-ifu-access
run_logged ifu-tval \
  make -C "$npc_home" check-ifu-tval
run_logged ptw-pmp \
  make -C "$npc_home" check-ptw-pmp
run_logged instret-retirement \
  make -C "$npc_home" check-instret-retirement
run_logged fence-ordering \
  make -C "$npc_home" check-fence-ordering
run_logged holder-lifecycle-current \
  make -C "$npc_home" check-global-producer-no-live-reuse

run_logged v10c-architecture-to-currentness \
  env \
    V10C_ATTEMPT=17 \
    V10C_START_STAGE=control-event-architecture \
    V10C_EVIDENCE_DIR_OVERRIDE="$evidence_dir/v10c-replay-final" \
    V10C_DRIVER_LOG_OVERRIDE="$log_dir/v10c-final-driver.log" \
    V10C_REPLAY_STATUS_PATH_OVERRIDE="$evidence_dir/v10c-final.status" \
    V10C_TASK_STATUS_PATH_OVERRIDE="$evidence_dir/v10c-final-task.status" \
    bash "$v10c_dir/run-current-design-evidence-replay.sh"

run_logged arch-stable-currentness-tests \
  env PYTHONDONTWRITEBYTECODE=1 \
    python3 -m unittest npc.rv64.eval.ppa.tests.test_arch_stable_freeze
run_logged task-local-workflow-tests \
  env PYTHONDONTWRITEBYTECODE=1 \
    python3 -m unittest discover \
      -s "$run_dir" \
      -p 'test_*.py'
run_logged v9o-index-final-verify \
  python3 "$v9o_dir/build-evidence-index.py" --verify

run_logged postflight \
  python3 "$run_dir/finalize-postflight.py"
