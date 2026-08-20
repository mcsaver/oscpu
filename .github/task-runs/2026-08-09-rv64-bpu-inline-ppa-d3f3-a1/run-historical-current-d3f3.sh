#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_id="2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
run_dir="${repo_root}/.github/task-runs/${run_id}"
evidence_rel=".github/task-runs/${run_id}/evidence/historical-current-d3f3-v1"
evidence_dir="${repo_root}/${evidence_rel}"
status_path="${run_dir}/historical-current-d3f3.status"
module_result_rel=".github/task-runs/2026-08-09-rv64-v16b-cancel-cycle-d3f3-l1-a1/evidence/module/result.json"
module_result="${repo_root}/${module_result_rel}"
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

task_run_status_stage "queue-head-current"
python3 "${repo_root}/npc/rv64/testbench/scripts/run_v12c_serialize_qh_current.py" \
  --repo-root "${repo_root}" \
  --output-dir "${evidence_dir}/qh"

task_run_status_stage "serialized-system-current"
python3 "${repo_root}/npc/rv64/testbench/scripts/run_v12c_serialize_system_current.py" \
  --repo-root "${repo_root}" \
  --output-dir "${evidence_dir}/system"

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
for summary in qh system exit v9r; do
  jq -e --arg design "${expected_design}" \
    '.status == "PASS" and .design_id == $design' \
    "${evidence_dir}/${summary}/summary.json" >/dev/null
done
jq -e '.rtl_file_count == 147 and
       .counts.baseline_profiles_pass == 2 and
       .counts.compile_success_mutations == 7' \
  "${evidence_dir}/exit/summary.json" >/dev/null
jq -e '.counts.positive_profiles == 2 and
       .counts.compile_success_mutations == 3' \
  "${evidence_dir}/qh/summary.json" >/dev/null
jq -e '.counts.baseline_profiles == 3 and
       .counts.compile_success_mutations == 15' \
  "${evidence_dir}/system/summary.json" >/dev/null
jq -e '.baseline.status == "PASS" and
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
adapter_log="${repo_root}/${adapter_log_rel}"
grep -Fq '[PASS] tb_ooo_lsu_axi_lane_adapter' "${adapter_log}"
grep -Fq "${expected_design}" "${adapter_log}"
grep -Fq '[RESULT] PASS' "${adapter_log}"

module_sha="$(sha256sum -- "${module_result}" | awk '{print $1}')"
module_size="$(stat -c '%s' -- "${module_result}")"
adapter_log_sha="$(sha256sum -- "${adapter_log}" | awk '{print $1}')"
adapter_log_size="$(stat -c '%s' -- "${adapter_log}")"
mutation_result_rel="${evidence_rel}/adapter-mutation/result.txt"
mutation_result="${repo_root}/${mutation_result_rel}"
mutation_result_sha="$(sha256sum -- "${mutation_result}" | awk '{print $1}')"
mutation_result_size="$(stat -c '%s' -- "${mutation_result}")"
jq -n \
  --arg design_id "${expected_design}" \
  --arg module_path "${module_result_rel}" \
  --arg module_sha256 "${module_sha}" \
  --argjson module_size "${module_size}" \
  --arg adapter_log_path "${adapter_log_rel}" \
  --arg adapter_log_sha256 "${adapter_log_sha}" \
  --argjson adapter_log_size "${adapter_log_size}" \
  --arg mutation_path "${mutation_result_rel}" \
  --arg mutation_sha256 "${mutation_result_sha}" \
  --argjson mutation_size "${mutation_result_size}" \
  '{
    schema: "npc-rv64-v15p-adapter-current-projection-v1",
    status: "PASS",
    design_id: $design_id,
    module: {
      path: $module_path,
      sha256: $module_sha256,
      size_bytes: $module_size,
      tests: {passed: 114, required: 114}
    },
    adapter_log: {
      path: $adapter_log_path,
      sha256: $adapter_log_sha256,
      size_bytes: $adapter_log_size
    },
    compile_success_mutation: {
      path: $mutation_path,
      sha256: $mutation_sha256,
      size_bytes: $mutation_size,
      result: "REJECTED"
    },
    historical_review: {
      state: "IMMUTABLE_PREDECESSOR_ONLY",
      current_design_claim: false
    },
    promotion: "UNPROMOTED"
  }' >"${evidence_dir}/adapter-current-summary.json"

[[ -z "$(find "${evidence_dir}" -type f -name '*.vvp' -print -quit)" ]]

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' \
  '[HISTORICAL-CURRENT-D3F3][PASS] qh=2+3 system=3+15 exit=2+7 v9r=2+3 adapter=114+1 retained_vvp=0'
