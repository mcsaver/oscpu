#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
source_run=""
run_dir=""
replay_mode=same-design

usage() {
  printf '%s\n' \
    "usage: $0 --source-run .github/task-runs/<failed-run> --run-dir .github/task-runs/<replay-run> [--mode same-design|current-design]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-run)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      source_run=$2
      shift 2
      ;;
    --run-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      run_dir=$2
      shift 2
      ;;
    --mode)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      replay_mode=$2
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[[ -n "${source_run}" && -n "${run_dir}" ]] || { usage; exit 2; }
case "${replay_mode}" in
  same-design|current-design) ;;
  *) usage; exit 2 ;;
esac
for variable_name in source_run run_dir; do
  value=${!variable_name}
  if [[ "${value}" != /* ]]; then
    value="${repo_root}/${value}"
  fi
  value=$(realpath -m -- "${value}") || exit 2
  case "${value}" in
    "${repo_root}/.github/task-runs/"*) ;;
    *)
      printf '%s\n' "[owner-timing-replay] ${variable_name} escapes task-runs" >&2
      exit 2
      ;;
  esac
  printf -v "${variable_name}" '%s' "${value}"
done

source_evidence="${source_run}/evidence/owner-timing-invalid-probe"
source_status="${source_run}/owner-timing-invalid-probe.status"
source_result="${source_evidence}/result.json"
source_manifest="${source_evidence}/production-manifest-before.sha256"
source_simulator="${source_evidence}/simulator-identity.json"
source_cleanup="${source_evidence}/runtime-cleanup.json"
source_log="${source_evidence}/logs/coremark-owner-timing-rep1.log"

evidence_dir="${run_dir}/evidence/owner-timing-invalid-probe-replay"
status_path="${run_dir}/owner-timing-invalid-probe-replay.status"
result_path="${evidence_dir}/result.json"
command_status="${evidence_dir}/command-status.txt"
tool="${repo_root}/npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py"
baseline="${repo_root}/npc/rv64/eval/ppa/evidence/performance-baseline-current.json"
contract="${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-contract-v1.json"
profile="${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-validation-profile-v1.json"

mkdir -p "${evidence_dir}" || exit 1
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}" || exit 1

finalized=0
cleanup_rc=0

finish_on_exit() {
  local command_rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}

finish_on_signal() {
  local signal_name=$1
  local signal_rc=$2
  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  task_run_status_stage "signal-${signal_name}"
  finalized=1
  task_run_status_finalize "${signal_rc}" "${cleanup_rc}" || true
  trap - HUP INT TERM EXIT
  exit "${signal_rc}"
}

trap 'finish_on_signal HUP 129' HUP
trap 'finish_on_signal INT 130' INT
trap 'finish_on_signal TERM 143' TERM
trap finish_on_exit EXIT

input_rc=0
build_rc=1
verify_rc=1
byte_identity_rc=1
byte_identity_applicable=0

task_run_status_stage "source-input-check"
required_paths=(
  "${source_status}"
  "${source_manifest}"
  "${source_simulator}"
  "${source_cleanup}"
  "${source_log}"
)
if [[ "${replay_mode}" == same-design ]]; then
  required_paths+=("${source_result}")
  byte_identity_applicable=1
fi
for path in "${required_paths[@]}"; do
  if [[ ! -f "${path}" ]]; then
    input_rc=1
  fi
done
if [[ "${input_rc}" -eq 0 ]]; then
  expected_stage=receipt-verify
  if [[ "${replay_mode}" == current-design ]]; then
    expected_stage=receipt-build
  fi
  if ! grep -Fq "FAIL rc=1 stage=${expected_stage}" "${source_status}"; then
    input_rc=1
  fi
fi

if [[ "${input_rc}" -eq 0 ]]; then
  task_run_status_stage "checker-replay-build"
  current_design_args=()
  if [[ "${replay_mode}" == current-design ]]; then
    current_design_args+=(--current-design-diagnostic)
  fi
  python3 -B "${tool}" build-invalid-probe \
    --baseline "${baseline}" \
    --contract "${contract}" \
    --profile "${profile}" \
    --production-manifest "${source_manifest}" \
    --simulator-identity "${source_simulator}" \
    --cleanup "${source_cleanup}" \
    --workload coremark \
    --log "${source_log}" \
    "${current_design_args[@]}" \
    --output "${result_path}" >"${evidence_dir}/replay-build.log" 2>&1
  build_rc=$?
fi

if [[ "${build_rc}" -eq 0 ]]; then
  task_run_status_stage "checker-replay-verify"
  python3 -B "${tool}" verify-invalid-probe --input "${result_path}" \
    >"${evidence_dir}/replay-verify.log" 2>&1
  verify_rc=$?
fi

if [[ "${verify_rc}" -eq 0 ]]; then
  if [[ "${replay_mode}" == same-design ]]; then
    task_run_status_stage "source-result-byte-identity"
    cmp -s "${source_result}" "${result_path}"
    byte_identity_rc=$?
  else
    byte_identity_rc=0
  fi
fi

printf '%s\n' \
  "replay_mode=${replay_mode}" \
  "input_rc=${input_rc}" \
  "build_rc=${build_rc}" \
  "verify_rc=${verify_rc}" \
  "source_result_byte_identity_rc=${byte_identity_rc}" \
  "source_result_byte_identity_applicable=${byte_identity_applicable}" \
  "dut_rerun=0" \
  "production_rtl_modified=0" \
  >"${command_status}"

command_rc=1
if [[ "${input_rc}" -eq 0 && "${build_rc}" -eq 0 &&
      "${verify_rc}" -eq 0 && "${byte_identity_rc}" -eq 0 &&
      -s "${result_path}" ]]; then
  command_rc=0
  task_run_status_stage "evidence-complete"
  task_run_status_mark_evidence_complete
fi

finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
