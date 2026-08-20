#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_id="2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
run_dir="${repo_root}/.github/task-runs/${run_id}"
evidence_dir="${run_dir}/evidence/architecture-hybrid-rebind-d3f3-v1"
manifest="${evidence_dir}/architecture-current.json"
result="${evidence_dir}/architecture-result.json"
negative="${evidence_dir}/negative-summary.json"
receipt="${evidence_dir}/receipt.json"
build_log="${run_dir}/architecture-hybrid-rebind-d3f3-v1-build.log"
verify_log="${run_dir}/architecture-hybrid-rebind-d3f3-v1-verify.log"
status_path="${run_dir}/architecture-hybrid-rebind-d3f3-v1.status"
tool="${repo_root}/npc/rv64/eval/ppa/tools/architecture_current_delta_rebind.py"
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

task_run_status_stage "hybrid-build"
python3 "${tool}" build \
  --repo-root "${repo_root}" \
  --source-manifest \
    .github/task-runs/2026-08-08-rv64-v15x-arch9-f72e-a1/evidence/architecture-current-f72e-v2.json \
  --baseline-rtl-manifest \
    .github/task-runs/2026-08-08-rv64-v15x-trap-c0-dispatch-closure-f72e-l1-a1/evidence/module/inputs.pre.json \
  --current-rtl-manifest \
    .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1/evidence/module/inputs.pre.json \
  --current-record-manifest \
    .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/memory-ordering-current-d3f3-v7/architecture-current.json \
  --layered-receipt \
    .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/layered-system-signoff-d3f3-build-contract-v3.json \
  --census npc/rv64/design/arch/producer-holder-census.json \
  --output-manifest "${manifest}" \
  --result "${result}" \
  --negative-summary "${negative}" \
  --receipt "${receipt}" >"${build_log}" 2>&1

task_run_status_stage "hybrid-verify"
python3 "${tool}" verify --repo-root "${repo_root}" \
  --receipt "${receipt}" >"${verify_log}" 2>&1

task_run_status_stage "evidence-contract"
grep -Eq '^\[ARCH-CURRENT-DELTA-REBIND\]\[PASS\].*fresh=1 projected=8 gates=9/9 negative=4/4$' \
  "${build_log}"
grep -Eq '^\[ARCH-CURRENT-DELTA-REBIND-VERIFY\]\[PASS\].*fresh=1 projected=8 gates=9/9 negative=4/4$' \
  "${verify_log}"
jq -e --arg design "${expected_design}" \
  '.schema == "npc-rv64-architecture-current-delta-rebind-v2" and
   .status == "PASS" and .current_design_id == $design and
   .record_classification.fresh_current == ["memory_ordering"] and
   .record_classification.fresh_count == 1 and
   .record_classification.projected_count == 8 and
   .record_classification.required_count == 9 and
   (.rtl_delta.directed_source_closure_impact | keys) == ["memory_ordering"] and
   .rtl_delta.transitive_delta_coverage[
     "npc/rv64/vsrc/control/OooSerializedMemTerminalPermit.v"].dynamic ==
     "FOCUSED_PASS" and
   .architecture_directed_gates ==
     {"passed": 9, "required": 9, "status": "GREEN"} and
   .directed_simulation_reexecuted == true and
   .arch_stable == false and .ppa == "UNQUALIFIED"' \
  "${receipt}" >/dev/null
jq -e --arg design "${expected_design}" \
  '.overall_status == "GREEN" and .rtl_source_set.design_id == $design' \
  "${result}" >/dev/null
jq -e '.status == "PASS" and .detected == 4 and .required == 4' \
  "${negative}" >/dev/null

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' \
  '[ARCHITECTURE-HYBRID-REBIND-D3F3-V1][PASS] fresh=1 projected=8 gates=9/9 negative=4/4'
