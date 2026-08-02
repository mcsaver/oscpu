#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1"
source_evidence="${run_dir}/evidence/p0-direct-rebind-1"
replay_dir="${run_dir}/evidence/p0-direct-rebind-checker-replay-1"
status_path="${run_dir}/p0-direct-rebind-checker-replay-1.status"
finalized=0
cleanup_rc=0

if [[ -e "${replay_dir}" || -e "${status_path}" ]]; then
  printf '%s\n' "[V14B-P0-REPLAY][FAIL] output already exists" >&2
  exit 2
fi
mkdir -p "${replay_dir}"

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

command_rc=0
task_run_status_stage "post-rtl-directed-check"
python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/architecture_hard_gates.py" \
  --repo-root "${repo_root}" \
  --evidence-manifest "${run_dir}/evidence/replay-1/current-directed-nine-gate-replay.json" \
  --output "${replay_dir}/source-post-result.json" \
  >"${replay_dir}/source-post-checker.log" 2>&1 || command_rc=$?

if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage "task-local-evidence-replay"
  python3 -B "${run_dir}/build-p0-direct-rebind-receipt.py" \
    --evidence-dir "${source_evidence}" \
    --output "${replay_dir}/rebind-receipt.json" \
    >"${replay_dir}/receipt.log" 2>&1 || command_rc=$?
fi

task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 &&
      -s "${replay_dir}/rebind-receipt.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
