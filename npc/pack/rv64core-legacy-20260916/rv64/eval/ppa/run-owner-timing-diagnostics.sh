#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir=""
tier=fast

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      [[ $# -ge 2 ]] || { printf '%s\n' 'missing --run-dir value' >&2; exit 2; }
      run_dir=$2
      shift 2
      ;;
    --tier)
      [[ $# -ge 2 ]] || { printf '%s\n' 'missing --tier value' >&2; exit 2; }
      tier=$2
      shift 2
      ;;
    *)
      printf '%s\n' "usage: $0 --run-dir .github/task-runs/<run-id> [--tier fast|link]" >&2
      exit 2
      ;;
  esac
done

if [[ -z "${run_dir}" ||
      ("${tier}" != "fast" && "${tier}" != "link") ]]; then
  printf '%s\n' "usage: $0 --run-dir .github/task-runs/<run-id> [--tier fast|link]" >&2
  exit 2
fi
if [[ "${run_dir}" != /* ]]; then
  run_dir="${repo_root}/${run_dir}"
fi
run_dir=$(realpath -m -- "${run_dir}") || exit 2
case "${run_dir}" in
  "${repo_root}/.github/task-runs/"*) ;;
  *)
    printf '%s\n' '[owner-timing-run] run directory escapes .github/task-runs' >&2
    exit 2
    ;;
esac

evidence_dir="${run_dir}/evidence/owner-timing-diagnostics"
status_path="${run_dir}/owner-timing-diagnostics.status"
command_status="${evidence_dir}/command-status.txt"
check_log="${evidence_dir}/check.log"
identity="${evidence_dir}/input-identity.sha256"
checker="${repo_root}/npc/rv64/eval/ppa/instrumentation/check-owner-timing.sh"
checker_pid=""

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p "${evidence_dir}" || exit 1
task_run_status_init "${status_path}" || exit 1

signal_finalize() {
  local signal_name=$1
  local signal_rc=$2
  if [[ -n "${checker_pid}" ]] && kill -0 "${checker_pid}" 2>/dev/null; then
    kill -s "${signal_name}" -- "-${checker_pid}" 2>/dev/null ||
      kill -s "${signal_name}" "${checker_pid}" 2>/dev/null || true
    wait "${checker_pid}" 2>/dev/null || true
  fi
  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  task_run_status_stage "signal-${signal_name}"
  task_run_status_finalize "${signal_rc}" 0 || true
  trap - HUP INT TERM
  exit "${signal_rc}"
}
trap 'signal_finalize HUP 129' HUP
trap 'signal_finalize INT 130' INT
trap 'signal_finalize TERM 143' TERM

task_run_status_stage "${tier}-validation"
check_rc=0
setsid "${checker}" --tier "${tier}" >"${check_log}" 2>&1 &
checker_pid=$!
wait "${checker_pid}" || check_rc=$?
checker_pid=""

marker_rc=0
grep -Fqx "[OWNER-TIMING-CHECK][PASS] tier=${tier} unit_cases=12 workload_cases=14 candidate_authorized=0 ppa=UNQUALIFIED" \
  "${check_log}" || marker_rc=1
grep -Fqx '[OWNER-TIMING-CLEANUP][PASS]' "${check_log}" || marker_rc=1
grep -Fqx '[OWNER-TIMING-IDENTITY][PASS] production-observation-inputs-stable=1' \
  "${check_log}" || marker_rc=1
if [[ "${tier}" == "link" ]]; then
  grep -Fqx '[OWNER-TIMING-STEP][PASS] step=full-dpi-link' \
    "${check_log}" || marker_rc=1
fi

sha256sum \
  "${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-contract-v1.json" \
  "${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-validation-profile-v1.json" \
  "${repo_root}/npc/rv64/eval/ppa/instrumentation/NpcOooOwnerTimingProbe.sv" \
  "${repo_root}/npc/rv64/eval/ppa/instrumentation/owner_timing_collector.cpp" \
  "${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing.mk" \
  "${repo_root}/npc/rv64/eval/ppa/instrumentation/check-owner-timing.sh" \
  "${repo_root}/npc/rv64/eval/ppa/run-owner-timing-diagnostics.sh" \
  >"${identity}"
identity_rc=$?

printf '%s\n' \
  "tier=${tier}" \
  "check_rc=${check_rc}" \
  "marker_rc=${marker_rc}" \
  "identity_rc=${identity_rc}" \
  >"${command_status}"

command_rc=1
if [[ "${check_rc}" -eq 0 && "${marker_rc}" -eq 0 &&
      "${identity_rc}" -eq 0 && -s "${identity}" ]]; then
  command_rc=0
  task_run_status_stage "evidence-complete"
  task_run_status_mark_evidence_complete
fi
task_run_status_finalize "${command_rc}" 0
