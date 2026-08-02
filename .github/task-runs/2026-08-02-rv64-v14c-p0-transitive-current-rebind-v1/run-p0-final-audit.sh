#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1"
evidence_dir="${run_dir}/evidence/p0-final-1"
status_path="${run_dir}/p0-final-1.status"
finalized=0
cleanup_rc=0

if [[ -e "${evidence_dir}" || -e "${status_path}" ]]; then
  printf '%s\n' "[V14C-P0-FINAL][FAIL] output already exists" >&2
  exit 2
fi
mkdir -p "${evidence_dir}"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

finalize_on_exit() {
  local command_rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

task_run_status_stage "p0-final-current-dynamic-audit"
python3 -B "${run_dir}/build-p0-final-receipt.py" \
  --output "${evidence_dir}/receipt.json" \
  >"${evidence_dir}/driver.log" 2>&1
command_rc=$?
if [[ "${command_rc}" -ne 0 ]]; then
  tail -n 80 "${evidence_dir}/driver.log" >&2 || true
fi
task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && \
      -s "${evidence_dir}/receipt.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
