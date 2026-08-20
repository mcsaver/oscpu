#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_id="2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
run_dir="${repo_root}/.github/task-runs/${run_id}"
candidate_dir="${run_dir}/evidence/arch-stable-current-d3f3-v6"
candidate="${candidate_dir}/candidate.json"
preflight="${candidate_dir}/pre-review-audit.json"
log_path="${run_dir}/arch-stable-current-d3f3-v6.log"
status_path="${run_dir}/arch-stable-current-d3f3-v6.status"
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
[[ ! -e "${candidate_dir}" && ! -L "${candidate_dir}" ]]
exec > >(tee "${log_path}") 2>&1

task_run_status_stage "candidate-build"
python3 -B npc/rv64/eval/ppa/tools/arch_stable_current_candidate.py \
  --output-dir "${candidate_dir}" \
  --architecture-evidence \
    "${run_dir}/evidence/architecture-hybrid-rebind-d3f3-v1/architecture-current.json" \
  --architecture-result \
    "${run_dir}/evidence/architecture-hybrid-rebind-d3f3-v1/architecture-result.json" \
  --functional-aggregate \
    .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1/evidence/functional/functional-aggregate.json \
  --claim ARCH_STABLE

task_run_status_stage "pre-review-audit"
python3 -B npc/rv64/eval/ppa/tools/arch_stable_freeze.py audit \
  "${candidate}" --output "${preflight}"

jq -e --arg design "${expected_design}" '
  .design_id == $design and
  .architecture_freeze == "GAP" and
  .ppa == "UNQUALIFIED" and
  .promotion_eligible == false and
  (.blockers | length) == 1 and
  (.blockers[0] | startswith("independent_review.exact_binding:")) and
  ([.checks[] | select(.status != "PASS")] | length) == 1
' "${preflight}" >/dev/null

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' \
  '[ARCH-STABLE-CURRENT-D3F3-V6][PASS] prerequisites=GREEN review=PENDING ppa=UNQUALIFIED'
