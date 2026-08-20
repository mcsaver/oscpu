#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_dir="${repo_root}/.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
source_run="${repo_root}/.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-act4-a2/evidence/act4"
tool="${repo_root}/npc/rv64/eval/ppa/tools/act4_current.py"
projection="${run_dir}/evidence/act4-current-checker-rebind-d3f3-v1.json"
canonical="${repo_root}/npc/rv64/eval/ppa/evidence/act4-current.json"
log_path="${run_dir}/act4-checker-rebind-d3f3-v1.log"
status_path="${run_dir}/act4-checker-rebind-d3f3-v1.status"
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

cd "${repo_root}"
[[ ! -e "${projection}" && ! -L "${projection}" ]]
exec > >(tee "${log_path}") 2>&1

task_run_status_stage "recompute-retained-act4"
python3 -B "${tool}" build \
  --run-dir "${source_run}/raw" \
  --input-before "${source_run}/inputs.before.json" \
  --input-after "${source_run}/inputs.after.json" \
  --cleanup "${source_run}/runtime-cleanup.json" \
  --execution-manifest "${source_run}/elf-manifest.txt" \
  --output "${projection}"

task_run_status_stage "publish-current"
python3 -B "${tool}" publish \
  --receipt "${projection}" \
  --output "${canonical}"

task_run_status_stage "verify-current"
python3 -B "${tool}" verify --receipt "${canonical}"
jq -e --arg design "${expected_design}" '
  .status == "PASS" and
  .design_id == $design and
  .counts.required == 100 and
  .counts.passed == 100 and
  .counts.failed == 0 and
  .counts.rtl_assertion_failures == 0
' "${canonical}" >/dev/null

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' \
  '[ACT4-CHECKER-REBIND-D3F3-V1][PASS] cases=100 guest_rerun=0 assertions=0'
