#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_id="2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
run_dir="${repo_root}/.github/task-runs/${run_id}"
candidate_dir="${run_dir}/evidence/arch-stable-current-d3f3-v9"
candidate="${candidate_dir}/candidate.json"
preflight="${candidate_dir}/pre-review-audit.json"
log_path="${run_dir}/arch-stable-current-d3f3-v9.log"
status_path="${run_dir}/arch-stable-current-d3f3-v9.status"
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
export PATH="/home/lyg/tools/OpenSTA/build:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${repo_root}/oss-cad-suite/bin"
[[ ! -e "${candidate_dir}" && ! -L "${candidate_dir}" ]]
exec > >(tee "${log_path}") 2>&1

task_run_status_stage "layered-current"
python3 -B npc/rv64/eval/ppa/tools/layered_system_signoff.py create \
  --l0-module-dir \
    .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1/evidence/module \
  --l1-dir \
    .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1 \
  --l2-result-dir \
    .github/task-runs/2026-08-09-rv64-v16b-cancel-cycle-d3f3-l2-a2/mini-system \
  --l3-result-dir \
    .github/task-runs/2026-08-09-rv64-v16b-cancel-cycle-d3f3-l3-a1/lightweight-linux \
  --output npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json

task_run_status_stage "system-current"
python3 -B npc/rv64/eval/ppa/tools/system_recertification_current.py capture \
  --output npc/rv64/eval/ppa/evidence/system-recertification-current.json

task_run_status_stage "architecture-debt-delta-current"
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py build \
  --output npc/rv64/eval/ppa/evidence/architecture-debt-delta-rebind-current.json

task_run_status_stage "global-producer-holder-current"
python3 -B npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py capture \
  --v14g-result "${run_dir}/evidence/v14g-current-d3f3-a1" \
  --yosys-json \
    "${run_dir}/evidence/current-holder-instance-graph/yosys-instance-graph.full.json.gz" \
  --yosys-receipt \
    "${run_dir}/evidence/current-holder-instance-graph/yosys-instance-graph-receipt.json" \
  --output npc/rv64/eval/ppa/evidence/global-producer-no-live-reuse-current.json

task_run_status_stage "producer-holder-semantic-current"
python3 -B npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py build \
  --output npc/rv64/design/arch/producer-holder-semantic-coverage.json

task_run_status_stage "architecture-debt-current"
python3 -B npc/rv64/eval/ppa/tools/architecture_debt_current.py refresh \
  --output npc/rv64/eval/ppa/evidence/architecture-debt-current.json

task_run_status_stage "historical-defect-current"
python3 -B npc/rv64/eval/ppa/tools/historical_defect_current.py refresh \
  --output npc/rv64/eval/ppa/evidence/historical-defect-current.json

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
  '[ARCH-STABLE-CURRENT-D3F3-V9][PASS] prerequisites=GREEN review=PENDING ppa=UNQUALIFIED'
