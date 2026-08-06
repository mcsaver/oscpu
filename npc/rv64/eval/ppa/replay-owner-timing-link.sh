#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
source_run=""
run_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-run)
      [[ $# -ge 2 ]] || exit 2
      source_run=$2
      shift 2
      ;;
    --run-dir)
      [[ $# -ge 2 ]] || exit 2
      run_dir=$2
      shift 2
      ;;
    *)
      printf '%s\n' "usage: $0 --source-run .github/task-runs/<link-run> --run-dir .github/task-runs/<replay-run>" >&2
      exit 2
      ;;
  esac
done

resolve_task_run() {
  local value=$1
  local resolved
  if [[ "${value}" != /* ]]; then
    value="${repo_root}/${value}"
  fi
  resolved=$(realpath -m -- "${value}") || return
  case "${resolved}" in
    "${repo_root}/.github/task-runs/"*) printf '%s\n' "${resolved}" ;;
    *) return 2 ;;
  esac
}

source_run=$(resolve_task_run "${source_run}") || exit 2
run_dir=$(resolve_task_run "${run_dir}") || exit 2
if [[ "${source_run}" == "${run_dir}" ]]; then
  printf '%s\n' '[owner-timing-replay] source and replay task-runs must differ' >&2
  exit 2
fi

source_status="${source_run}/owner-timing-diagnostics.status"
source_command="${source_run}/evidence/owner-timing-diagnostics/command-status.txt"
source_log="${source_run}/evidence/owner-timing-diagnostics/check.log"
source_identity="${source_run}/evidence/owner-timing-diagnostics/input-identity.sha256"
fast_runner="${repo_root}/npc/rv64/eval/ppa/run-owner-timing-diagnostics.sh"
evidence_dir="${run_dir}/evidence/owner-timing-link-replay"
status_path="${run_dir}/owner-timing-link-replay.status"
receipt="${evidence_dir}/replay.txt"
command_status="${evidence_dir}/command-status.txt"

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p "${evidence_dir}" || exit 1
task_run_status_init "${status_path}" || exit 1

signal_finalize() {
  local signal_name=$1
  local signal_rc=$2
  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  task_run_status_stage "signal-${signal_name}"
  task_run_status_finalize "${signal_rc}" 0 || true
  trap - HUP INT TERM
  exit "${signal_rc}"
}
trap 'signal_finalize HUP 129' HUP
trap 'signal_finalize INT 130' INT
trap 'signal_finalize TERM 143' TERM

task_run_status_stage current-fast
fast_rc=0
"${fast_runner}" --run-dir "${run_dir}" --tier fast || fast_rc=$?

verify_rc=0
task_run_status_stage frozen-link-verify
[[ "$(sed -n '1p' "${source_status}" 2>/dev/null)" == "PASS" ]] || verify_rc=1
grep -Fqx 'tier=link' "${source_command}" 2>/dev/null || verify_rc=1
grep -Fqx 'check_rc=0' "${source_command}" 2>/dev/null || verify_rc=1
grep -Fqx 'marker_rc=0' "${source_command}" 2>/dev/null || verify_rc=1
grep -Fqx 'identity_rc=0' "${source_command}" 2>/dev/null || verify_rc=1
grep -Fqx '[OWNER-TIMING-STEP][PASS] step=full-dpi-link' \
  "${source_log}" 2>/dev/null || verify_rc=1
grep -Fqx '[OWNER-TIMING-CLEANUP][PASS]' "${source_log}" 2>/dev/null || verify_rc=1

current_log="${run_dir}/evidence/owner-timing-diagnostics/check.log"
current_status="${run_dir}/owner-timing-diagnostics.status"
[[ "$(sed -n '1p' "${current_status}" 2>/dev/null)" == "PASS" ]] || verify_rc=1

source_manifest=$(grep -F '[OWNER-TIMING-PRODUCTION-MANIFEST]' \
  "${source_log}" 2>/dev/null || true)
current_manifest=$(grep -F '[OWNER-TIMING-PRODUCTION-MANIFEST]' \
  "${current_log}" 2>/dev/null || true)
[[ -n "${source_manifest}" && "${source_manifest}" == "${current_manifest}" ]] || verify_rc=1

source_tools=$(grep -F '[OWNER-TIMING-TOOL]' "${source_log}" 2>/dev/null || true)
current_tools=$(grep -F '[OWNER-TIMING-TOOL]' "${current_log}" 2>/dev/null || true)
[[ -n "${source_tools}" && "${source_tools}" == "${current_tools}" ]] || verify_rc=1

link_inputs=(
  npc/rv64/eval/ppa/instrumentation/owner-timing-contract-v1.json
  npc/rv64/eval/ppa/instrumentation/NpcOooOwnerTimingProbe.sv
  npc/rv64/eval/ppa/instrumentation/owner_timing_collector.cpp
  npc/rv64/eval/ppa/instrumentation/owner-timing.mk
)
link_identity=""
for relative in "${link_inputs[@]}"; do
  absolute="${repo_root}/${relative}"
  source_sha=$(awk -v path="${absolute}" '$2 == path {print $1}' \
    "${source_identity}" 2>/dev/null)
  current_sha=$(sha256sum "${absolute}" 2>/dev/null | cut -d ' ' -f 1)
  if [[ ! "${source_sha}" =~ ^[0-9a-f]{64}$ ||
        "${source_sha}" != "${current_sha}" ]]; then
    verify_rc=1
  fi
  link_identity+="${current_sha}  ${relative}"$'\n'
done

simulator_line=$(awk '$2 == "diagnostic-simulator" && $1 ~ /^[0-9a-f]{64}$/ {print}' \
  "${source_log}" 2>/dev/null)
[[ "$(printf '%s\n' "${simulator_line}" | grep -c .)" -eq 1 ]] || verify_rc=1

printf '%s\n' \
  'schema=npc-rv64-owner-timing-link-replay-v1' \
  "source_run=${source_run#${repo_root}/}" \
  "source_status=PASS" \
  "source_simulator=${simulator_line%% *}" \
  "source_log_sha256=$(sha256sum "${source_log}" | cut -d ' ' -f 1)" \
  "source_identity_sha256=$(sha256sum "${source_identity}" | cut -d ' ' -f 1)" \
  "current_fast_status=$(sed -n '1p' "${current_status}")" \
  "current_fast_log_sha256=$(sha256sum "${current_log}" | cut -d ' ' -f 1)" \
  "replay_script_sha256=$(sha256sum "$0" | cut -d ' ' -f 1)" \
  "production_manifest=${current_manifest}" \
  "tool_identity=$(printf '%s' "${current_tools}" | sha256sum | cut -d ' ' -f 1)" \
  "link_inputs_begin" \
  "${link_identity%$'\n'}" \
  "link_inputs_end" \
  'candidate_authorized=0' \
  'promotion_eligible=0' \
  'ppa=UNQUALIFIED' \
  >"${receipt}"
receipt_rc=$?

printf '%s\n' \
  "fast_rc=${fast_rc}" \
  "verify_rc=${verify_rc}" \
  "receipt_rc=${receipt_rc}" \
  >"${command_status}"

command_rc=1
if [[ "${fast_rc}" -eq 0 && "${verify_rc}" -eq 0 &&
      "${receipt_rc}" -eq 0 && -s "${receipt}" ]]; then
  command_rc=0
  task_run_status_stage evidence-complete
  task_run_status_mark_evidence_complete
fi
task_run_status_finalize "${command_rc}" 0
