#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_dir="${repo_root}/.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
result_dir="${run_dir}/evidence/v14g-current-d3f3-a1"
status_path="${run_dir}/v14g-current-d3f3.status"
expected_design="sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af"
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

task_run_status_stage "v14g-owner-fence-execution"
python3 "${repo_root}/npc/rv64/testbench/scripts/run_v14g_global_producer_owner_fence.py" \
  --result-dir "${result_dir}" \
  --timeout-seconds 1800

task_run_status_stage "evidence-contract"
[[ "$(<"${result_dir}/status")" == "PASS" ]]
jq -e \
  --arg design "${expected_design}" \
  '.result == "PASS" and
   .design_id_pre == $design and .design_id_post == $design and
   .baseline_profiles_pass == 4 and .baseline_profiles_total == 4 and
   .compile_success_mutations_rejected == 22 and
   .compile_success_mutations_total == 22 and
   .intermediate_products_retained == 0 and
   (.profiles | length) == 26' \
  "${result_dir}/summary.json" >/dev/null
[[ -z "$(find "${result_dir}" -type f -name '*.vvp' -print -quit)" ]]

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' "[V14G-CURRENT-D3F3][PASS] baselines=4/4 mutations=22/22 retained_vvp=0"
