#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
run_id="2026-08-09-rv64-bpu-inline-ppa-d3f3-a1"
run_dir="${repo_root}/.github/task-runs/${run_id}"
output="${run_dir}/evidence/layered-system-signoff-d3f3-build-contract-v2.json"
log_path="${run_dir}/layered-system-signoff-d3f3-build-contract-v2.log"
status_path="${run_dir}/layered-system-signoff-d3f3-build-contract-v2.status"
tool="${repo_root}/npc/rv64/eval/ppa/tools/layered_system_signoff.py"
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

[[ ! -e "${output}" && ! -L "${output}" ]]

task_run_status_stage "layered-compose"
python3 "${tool}" create \
  --l0-module-dir \
    .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1/evidence/module \
  --l1-dir \
    .github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1 \
  --l2-result-dir \
    .github/task-runs/2026-08-09-rv64-v16b-cancel-cycle-d3f3-l2-a2/mini-system \
  --l3-result-dir \
    .github/task-runs/2026-08-09-rv64-v16b-cancel-cycle-d3f3-l3-a1/lightweight-linux \
  --output "${output}" >"${log_path}" 2>&1

task_run_status_stage "evidence-contract"
grep -Eq '^\[RV64-LAYERED-SYSTEM-SIGNOFF\]\[PASS\].*L0=114/114 L1=177\+61\+ACT4-100 L2=all L3=all' \
  "${log_path}"
jq -e --arg design "${expected_design}" \
  '.status == "PASS" and .rtl_design_id == $design and
   .source_directories.l0_module ==
     ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1/evidence/module" and
   .source_directories.l1_full_core ==
     ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1" and
   .layers.L0_DIRECTED_RTL.tests == {"passed": 114, "required": 114} and
   .layers.L1_FULL_CORE_DIFFTEST.status == "PASS" and
   .layers.L2_MINI_SYSTEM.status == "PASS" and
   .layers.L3_LIGHTWEIGHT_LINUX.status == "PASS" and
   .optional_full_ubuntu.status == "NOT_RUN"' \
  "${output}" >/dev/null

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT HUP INT TERM
printf '%s\n' \
  '[LAYERED-REBIND-D3F3-V2][PASS] L0=114/114 L1=177+61+ACT4-100 L2=all L3=all Ubuntu=not-run'
