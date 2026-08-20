#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_id="2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
run_dir="${repo_root}/.github/task-runs/${run_id}"
prior_dir="${run_dir}/evidence/historical-current-d3f3-v1"
evidence_rel=".github/task-runs/${run_id}/evidence/historical-current-d3f3-v3"
evidence_dir="${repo_root}/${evidence_rel}"
status_path="${run_dir}/historical-current-d3f3-v3.status"
module_result="${repo_root}/.github/task-runs/2026-08-09-rv64-v16b-cancel-cycle-d3f3-l1-a1/evidence/module/result.json"
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

[[ ! -e "${evidence_dir}" && ! -L "${evidence_dir}" ]]
mkdir -p -- "${evidence_dir}"

task_run_status_stage "reuse-completed-qh-system"
jq -e --arg design "${expected_design}" \
  '.status == "PASS" and .design_id == $design and
   .counts.positive_profiles == 2 and
   .counts.compile_success_mutations == 3 and
   .cleanup.status == "PASS" and
   .cleanup.retained_temporary_artifacts == 0' \
  "${prior_dir}/qh/summary.json" >/dev/null
jq -e --arg design "${expected_design}" \
  '.status == "PASS" and .design_id == $design and
   .counts.baseline_profiles == 3 and
   .counts.compile_success_mutations == 15 and
   .cleanup.status == "PASS" and
   .cleanup.retained_temporary_artifacts == 0' \
  "${prior_dir}/system/summary.json" >/dev/null
[[ -z "$(find "${prior_dir}/qh" "${prior_dir}/system" -type f -name '*.vvp' -print -quit)" ]]

task_run_status_stage "historical-exit-current"
python3 "${repo_root}/npc/rv64/testbench/scripts/run_historical_exit_current.py" \
  --result-dir "${evidence_dir}/exit"

task_run_status_stage "v9r-current"
bash "${repo_root}/npc/rv64/eval/ppa/run-v9r-sq-retry-current.sh" \
  --result-dir "${evidence_rel}/v9r"

task_run_status_stage "v15p-adapter-mutation"
bash "${repo_root}/npc/rv64/testbench/scripts/run_v15p_adapter_final_b_fallthrough_mutation.sh" \
  "${evidence_dir}/adapter-mutation"

task_run_status_stage "evidence-contract"
jq -e --arg design "${expected_design}" \
  '.status == "PASS" and .design_id == $design and
   .rtl_file_count == 147 and
   .counts.baseline_profiles_pass == 2 and
   .counts.compile_success_mutations == 7 and
   .counts.dynamically_rejected_mutations == 7' \
  "${evidence_dir}/exit/summary.json" >/dev/null
jq -e --arg design "${expected_design}" \
  '.status == "PASS" and .design_id == $design and
   .baseline.status == "PASS" and
   (.compile_success_rtl_variants | length) == 3 and
   .cleanup.compiled_images_retained == 0' \
  "${evidence_dir}/v9r/summary.json" >/dev/null
grep -Fxq 'RESULT=PASS' "${evidence_dir}/adapter-mutation/result.txt"
grep -Fxq 'COMPILE_SUCCESS=1' "${evidence_dir}/adapter-mutation/result.txt"
grep -Fxq 'MUTATION_DETECTED=1' "${evidence_dir}/adapter-mutation/result.txt"

jq -e --arg design "${expected_design}" \
  '.schema == "npc-rv64-full-core-module-current-evidence-v1" and
   .status == "PASS" and .design_id == $design and
   .inputs.unchanged == true and
   .tests.passed == 114 and .tests.required == 114 and
   (.tests.logs.tb_ooo_lsu_axi_lane_adapter.path | type) == "string"' \
  "${module_result}" >/dev/null
adapter_log_rel="$(jq -r '.tests.logs.tb_ooo_lsu_axi_lane_adapter.path' "${module_result}")"
grep -Fq '[PASS] tb_ooo_lsu_axi_lane_adapter' "${repo_root}/${adapter_log_rel}"
grep -Fq "${expected_design}" "${repo_root}/${adapter_log_rel}"
grep -Fq '[RESULT] PASS' "${repo_root}/${adapter_log_rel}"
[[ -z "$(find "${evidence_dir}" -type f -name '*.vvp' -print -quit)" ]]

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' \
  '[HISTORICAL-CURRENT-D3F3-V3][PASS] reused-qh-system=1 exit=2+7 v9r=2+3 adapter=114+1 retained_vvp=0'
