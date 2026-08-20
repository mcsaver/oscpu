#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_id="2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
run_dir="${repo_root}/.github/task-runs/${run_id}"
evidence_dir="${run_dir}/evidence/memory-ordering-current-d3f3-v1"
manifest="${evidence_dir}/architecture-current.json"
gate_log="${evidence_dir}/memory-ordering.log"
ooo3_dir="${evidence_dir}/ooo3-current"
mutation_dir="${evidence_dir}/lq-mutations"
retained_f2="${repo_root}/.github/task-runs/2026-08-08-rv64-v15x-arch9-f72e-a1/evidence/f2-current"
status_path="${run_dir}/memory-ordering-current-d3f3-v1.status"
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

task_run_status_stage "ooo3-impacted-current"
V8V_SCOPED_REFRESH_MODE=1 \
V8V_ALLOW_RETAINED_F2=1 \
V8V_ARCH_MANIFEST="${manifest}" \
V8V_ARCH_LOG="${gate_log}" \
V8V_EVIDENCE_DIR="${ooo3_dir}" \
V8V_F2_EVIDENCE_DIR="${retained_f2}" \
V8V_MUTATION_OUTPUT_DIR="${mutation_dir}" \
V8V_RUN_ID="v8v-ooo3-d3f3-20260809-a1" \
bash "${repo_root}/.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/run-focused.sh"

task_run_status_stage "evidence-contract"
jq -e --arg design "${expected_design}" \
  '.schema == "npc-rv64-architecture-directed-suite-v2" and
   .design_id == $design and
   (.tests | keys) == ["memory_ordering"] and
   .tests.memory_ordering.status == "PASS" and
   .tests.memory_ordering.provenance.rtl_file_count == 147 and
   .tests.memory_ordering.provenance.rtl_sha256 == ($design | sub("^sha256:"; ""))' \
  "${manifest}" >/dev/null
jq -e --arg design "${expected_design}" \
  '.schema == "v8v-memory-ordering-evidence/v1" and
   .status == "PASS" and .design_id == $design and
   .metrics == {"passed": 11, "required": 11} and
   .mutations.required == 9 and .mutations.compile_success == 9 and
   .mutations.detected == 9 and .promotion_eligible == false and
   .ppa == "UNQUALIFIED"' \
  "${ooo3_dir}/result.json" >/dev/null
grep -Fq 'mode=1 f2=retained-live-revalidated metrics=11 mutations=9 OOO-3=GREEN' \
  "${ooo3_dir}/final.log"
cmp -s "${ooo3_dir}/sources.pre.sha256" "${ooo3_dir}/sources.post.sha256"
[[ -z "$(find "${evidence_dir}" -type f -name '*.vvp' -print -quit)" ]]

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' \
  '[MEMORY-ORDERING-CURRENT-D3F3-V1][PASS] OOO-3=1/1 metrics=11 mutations=9 f2=retained-live-revalidated retained_vvp=0'
