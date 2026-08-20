#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_id="2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
run_dir="${repo_root}/.github/task-runs/${run_id}"
evidence_root="${run_dir}/evidence/l0-build-contract-d3f3-v1"
module_dir="${evidence_root}/module"
log_path="${run_dir}/l0-build-contract-d3f3-v1.log"
status_path="${run_dir}/l0-build-contract-d3f3-v1.status"
tool="${repo_root}/npc/rv64/eval/ppa/tools/full_core_current_evidence.py"
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

[[ ! -e "${evidence_root}" && ! -L "${evidence_root}" ]]
mkdir -p -- "${evidence_root}"

task_run_status_stage "l0-module-current"
/usr/bin/python3 -B "${tool}" module \
  --output-dir "${module_dir}" --jobs 4 >"${log_path}" 2>&1

task_run_status_stage "evidence-contract"
grep -Eq '^\[FULL-CORE-MODULE-CURRENT\]\[PASS\] .* tests=114/114 retained_vvp=0$' \
  "${log_path}"
! grep -Fq '[FULL-CORE-MODULE-CURRENT][FAIL]' "${log_path}"
jq -e --arg design "${expected_design}" \
  '.schema == "npc-rv64-full-core-module-current-evidence-v1" and
   .status == "PASS" and .design_id == $design and
   .tests.required == 114 and .tests.passed == 114 and
   .inputs.unchanged == true and
   .inputs.pre.sha256 == .inputs.post.sha256 and
   .retention.compiled_images_retained == 0' \
  "${module_dir}/result.json" >/dev/null
cmp -s "${module_dir}/inputs.pre.json" "${module_dir}/inputs.post.json"
[[ -z "$(find "${evidence_root}" -type f -name '*.vvp' -print -quit)" ]]

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' \
  '[L0-BUILD-CONTRACT-D3F3-V1][PASS] tests=114/114 inputs=unchanged retained_vvp=0'
