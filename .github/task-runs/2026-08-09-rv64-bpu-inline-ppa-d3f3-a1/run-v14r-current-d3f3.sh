#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_dir="${repo_root}/.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
evidence_dir="${run_dir}/evidence/v14r-current-d3f3-v1"
status_path="${run_dir}/v14r-current-d3f3.status"
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

finalize_on_exit() {
  local command_rc=$?
  local final_rc
  trap - EXIT HUP INT TERM
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    set +e
    task_run_status_finalize "${command_rc}" 0
    final_rc=$?
    set -e
    if [[ "${command_rc}" -eq 0 ]]; then
      command_rc=${final_rc}
    fi
  fi
  exit "${command_rc}"
}
trap finalize_on_exit EXIT

task_run_status_stage "v14r-link-execution"
bash "${repo_root}/npc/rv64/testbench/scripts/check_v14r_memory_request_hold.sh" \
  --tier link \
  --evidence-dir "${evidence_dir}"

task_run_status_stage "evidence-contract"
grep -Fxq 'RESULT=PASS' "${evidence_dir}/result.txt"
grep -Fxq 'TIER=link' "${evidence_dir}/result.txt"
grep -Fxq 'MUTATION_TOTAL=6' "${evidence_dir}/result.txt"
grep -Fxq 'BUILD_RETAINED=0' "${evidence_dir}/result.txt"
grep -Fxq 'CLEANUP=PASS' "${evidence_dir}/result.txt"
[[ -z "$(find "${evidence_dir}" -type f -name '*.vvp' -print -quit)" ]]

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' "[V14R-CURRENT-D3F3][PASS] tier=link mutations=6 retained_vvp=0"
