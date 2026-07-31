#!/usr/bin/env bash
set -euo pipefail

repo_root="/home/lyg/PA/ysyx-workbench"
run_root="${repo_root}/.github/task-runs/2026-07-31-workspace-artifact-cleanup-a1"
status_path="${run_root}/cleanup.status"
result_path="${run_root}/evidence/execution-result.json"
executor="${run_root}/cleanup_first_phase.py"
status_helper="${repo_root}/scripts/task-run-status.sh"
child_pid=""

if [[ "$#" -ne 1 || ! "$1" =~ ^[0-9a-f]{64}$ ]]; then
  printf '%s\n' "usage: execute_cleanup.sh <frozen-plan-sha256>" >&2
  exit 2
fi
plan_digest="$1"

cd "${repo_root}"
source "${status_helper}"

forward_signal() {
  local signal_name="${1:?signal name is required}"
  local signal_rc="${2:?signal return code is required}"

  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  if [[ -n "${child_pid}" ]] && kill -0 "${child_pid}" 2>/dev/null; then
    kill -s "${signal_name}" "${child_pid}" 2>/dev/null || true
    wait "${child_pid}" 2>/dev/null || true
  fi
  exit "${signal_rc}"
}

finish() {
  local command_rc=$?
  local final_rc

  trap - EXIT HUP INT TERM
  set +e
  if [[ "${command_rc}" -eq 0 ]] &&
     python3 -c \
       'import json,sys; r=json.load(open(sys.argv[1])); sys.exit(0 if r.get("status") == "PASS" and r.get("plan_sha256") == sys.argv[2] else 1)' \
       "${result_path}" "${plan_digest}"; then
    task_run_status_stage "evidence-verified"
    task_run_status_mark_evidence_complete
  fi
  task_run_status_finalize "${command_rc}" 0
  final_rc=$?
  exit "${final_rc}"
}

task_run_status_init "${status_path}"
task_run_status_stage "artifact-quarantine-purge"
trap finish EXIT
trap 'forward_signal HUP 129' HUP
trap 'forward_signal INT 130' INT
trap 'forward_signal TERM 143' TERM

export RV64_CLEANUP_WRAPPER_ACTIVE=1
python3 "${executor}" --execute --plan-sha256 "$1" &
child_pid=$!
set +e
wait "${child_pid}"
command_rc=$?
set -e
child_pid=""
exit "${command_rc}"
