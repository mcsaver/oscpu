#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
STATUS="$RUN_DIR/v14r-current.status"
RESULT_DIR="$RUN_DIR/evidence/v14r-current"
TEMP_DIR=""

source "$REPO_ROOT/scripts/task-run-status.sh"
task_run_status_init "$STATUS"
task_run_status_install_signal_traps

cleanup() {
  local cleanup_rc=0
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" &&
        "$TEMP_DIR" == "${TMPDIR:-/tmp}"/rv64-v15h-v14r.* ]]; then
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

[[ ! -e "$RESULT_DIR" ]] || {
  printf '[V15H-V14R][FAIL] result directory already exists: %s\n' "$RESULT_DIR" >&2
  exit 2
}
cd "$REPO_ROOT"
task_run_status_stage "rtl-pre-hash"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/rv64-v15h-v14r.XXXXXX")
find npc/rv64/vsrc -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
  -print0 | sort -z | xargs -0 sha256sum > "$TEMP_DIR/rtl.pre.sha256"

task_run_status_stage "v14r-link"
bash npc/rv64/testbench/scripts/check_v14r_memory_request_hold.sh \
  --tier link --evidence-dir "$RESULT_DIR" \
  > "$RUN_DIR/evidence/v14r-current.driver.log" 2>&1
grep -Fxq 'RESULT=PASS' "$RESULT_DIR/result.txt"
grep -Fxq 'TIER=link' "$RESULT_DIR/result.txt"
grep -Fxq 'MUTATION_TOTAL=6' "$RESULT_DIR/result.txt"
grep -Fxq 'BUILD_RETAINED=0' "$RESULT_DIR/result.txt"
grep -Fxq 'CLEANUP=PASS' "$RESULT_DIR/result.txt"

task_run_status_stage "rtl-post-hash"
find npc/rv64/vsrc -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
  -print0 | sort -z | xargs -0 sha256sum > "$TEMP_DIR/rtl.post.sha256"
cmp "$TEMP_DIR/rtl.pre.sha256" "$TEMP_DIR/rtl.post.sha256"

task_run_status_stage "cleanup"
cleanup
TEMP_DIR=""
task_run_status_stage "publish-status"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
trap - EXIT
printf '%s\n' '[V15H-V14R][PASS] tier=link mutations=6 build_retained=0'
