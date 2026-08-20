#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_dir="${repo_root}/.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
candidate_dir="${run_dir}/evidence/arch-stable-current-d3f3-v11"
candidate="${candidate_dir}/candidate.json"
contract="${run_dir}/subagent-contracts/arch-stable-d3f3-v11-independent-review-v1.json"
report="${run_dir}/subagent-contracts/arch-stable-d3f3-v11-independent-review-v1.result.md"
review="${candidate_dir}/independent-review.json"
final_audit="${candidate_dir}/final-audit.json"
log_path="${run_dir}/arch-stable-finalize-d3f3-v11.log"
status_path="${run_dir}/arch-stable-finalize-d3f3-v11.status"
expected_design="sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af"
expected_candidate_sha="8322170c192f133f2e93f55e69635c13ce6eb84398e74825cbe37769f4a29e2b"
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
export PATH="/home/lyg/tools/OpenSTA/build:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${repo_root}/oss-cad-suite/bin"
[[ ! -e "${review}" && ! -L "${review}" ]]
[[ ! -e "${final_audit}" && ! -L "${final_audit}" ]]
exec > >(tee "${log_path}") 2>&1

task_run_status_stage "independent-review-receipt"
python3 -B npc/rv64/eval/ppa/tools/arch_stable_freeze.py review-receipt \
  "${candidate}" \
  --contract "${contract}" \
  --report "${report}" \
  --reviewer-task /root/arch_stable_v11_reviewer \
  --output "${review}"

jq -e --arg design "${expected_design}" --arg candidate_sha "${expected_candidate_sha}" '
  .decision == "APPROVE_ARCH_STABLE" and
  .design_id == $design and
  .candidate.sha256 == $candidate_sha and
  (.open_blockers | length) == 0 and
  (.unknowns | length) == 0
' "${review}" >/dev/null

task_run_status_stage "final-arch-stable-audit"
python3 -B npc/rv64/eval/ppa/tools/arch_stable_freeze.py audit \
  "${candidate}" \
  --review "${review}" \
  --output "${final_audit}" \
  --require-stable

jq -e --arg design "${expected_design}" '
  .design_id == $design and
  .architecture_freeze == "ARCH_STABLE" and
  .ppa == "UNQUALIFIED" and
  .promotion_eligible == false and
  (.blockers | length) == 0 and
  ([.checks[] | select(.status != "PASS")] | length) == 0
' "${final_audit}" >/dev/null

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' \
  '[ARCH-STABLE-FINAL-D3F3-V11][PASS] architecture=ARCH_STABLE ppa=UNQUALIFIED promotion=false'
