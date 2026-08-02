#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1"
source_evidence="${run_dir}/evidence/p0-replay-elimination-1"
replay_dir="${run_dir}/evidence/p0-replay-elimination-checker-replay-1"
status_path="${run_dir}/p0-replay-elimination-checker-replay-1.status"
finalized=0
cleanup_rc=0

if [[ -e "${replay_dir}" || -e "${status_path}" ]]; then
  printf '%s\n' "[V14C-P0-REPLAY-ELIMINATION-CHECKER][FAIL] output already exists" >&2
  exit 2
fi
mkdir -p "${replay_dir}"
exec > >(tee -a "${replay_dir}/driver.log") 2>&1

source "${repo_root}/scripts/task-run-status.sh"
source "${run_dir}/driver-lib.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps
run_logged() { v14c_run_logged "$@"; }

finalize_on_exit() {
  local command_rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

main() {
  run_logged "post-rtl-source-identity" \
    "${replay_dir}/source-post-checker.log" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/architecture_hard_gates.py" \
      --repo-root "${repo_root}" \
      --evidence-manifest "${repo_root}/.github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/replay-1/current-directed-nine-gate-replay.json" \
      --output "${replay_dir}/source-post-result.json" || return $?
  run_logged "corrected-warning-receipt" "${replay_dir}/receipt-driver.log" \
    python3 -B "${run_dir}/build-replay-elimination-receipt.py" \
      --evidence-dir "${source_evidence}" \
      --post-result "${replay_dir}/source-post-result.json" \
      --output "${replay_dir}/receipt.json" || return $?
  return 0
}

main
command_rc=$?
task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && \
      -s "${replay_dir}/receipt.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
