#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "${script_dir}/../../../.." && pwd)
run_dir=""
owner_receipt=""

usage() {
  printf '%s\n' \
    "usage: $0 --run-dir .github/task-runs/<run-id> --owner-receipt <workspace-path>" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      run_dir=$2
      shift 2
      ;;
    --owner-receipt)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      owner_receipt=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[[ -n "${run_dir}" && -n "${owner_receipt}" ]] || { usage; exit 2; }
cd "${repo_root}"

if [[ "${run_dir}" != /* ]]; then
  run_dir="${repo_root}/${run_dir}"
fi
run_dir=$(realpath -m -- "${run_dir}") || exit 2
case "${run_dir}" in
  "${repo_root}/.github/task-runs/"*) ;;
  *)
    printf '%s\n' "[OWNER-TIMING-CAUSAL][ERROR] run-dir is outside task-runs" >&2
    exit 2
    ;;
esac
[[ ! -e "${run_dir}" && ! -L "${run_dir}" ]] || {
  printf '%s\n' "[OWNER-TIMING-CAUSAL][ERROR] run-dir already exists" >&2
  exit 2
}

if [[ "${owner_receipt}" != /* ]]; then
  owner_receipt="${repo_root}/${owner_receipt}"
fi
owner_receipt=$(realpath -e -- "${owner_receipt}") || exit 2
case "${owner_receipt}" in
  "${repo_root}/"*) ;;
  *)
    printf '%s\n' \
      "[OWNER-TIMING-CAUSAL][ERROR] owner receipt is outside workspace" >&2
    exit 2
    ;;
esac
owner_rel=${owner_receipt#"${repo_root}/"}

artifact_name=owner-timing-causal-analysis
evidence_dir="${run_dir}/evidence"
probe_dir="${evidence_dir}/causal-probe"
analysis_dir="${evidence_dir}/${artifact_name}"
status_path="${run_dir}/${artifact_name}.status"
command_status="${analysis_dir}/command-status.txt"
result_path="${analysis_dir}/result.json"
cleanup_path="${analysis_dir}/runtime-cleanup.json"
runtime_base="${repo_root}/.github/runtime-artifacts/${artifact_name}"

mkdir -p "${probe_dir}" "${analysis_dir}" "${runtime_base}"
runtime_dir=$(mktemp -d "${runtime_base}/run.XXXXXX") || exit 1
case "${runtime_dir}" in
  "${runtime_base}/run."*) ;;
  *)
    printf '%s\n' "[OWNER-TIMING-CAUSAL][ERROR] invalid runtime path" >&2
    exit 2
    ;;
esac

probe_log="${probe_dir}/logs/tb_ooo_owner_timing_causal_probe.log"
probe_rel=${probe_log#"${repo_root}/"}
result_rel=${result_path#"${repo_root}/"}
tool="${script_dir}/tools/owner_timing_causal_analysis.py"

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

l0_probe_rc=99
receipt_build_rc=99
receipt_verify_rc=99
checker_regression_rc=99
evidence_ready=0

finish_run() {
  local command_rc=$?
  local cleanup_rc=0
  local build_bytes_deleted=0
  local finalize_rc=0

  trap - EXIT
  set +e
  task_run_status_stage runtime-cleanup
  if [[ -e "${runtime_dir}" ]]; then
    build_bytes_deleted=$(du -sb -- "${runtime_dir}" 2>/dev/null |
      awk '{print $1}')
    build_bytes_deleted=${build_bytes_deleted:-0}
    rm -rf -- "${runtime_dir}"
    cleanup_rc=$?
  fi
  if [[ -e "${runtime_dir}" ]]; then
    cleanup_rc=1
  fi
  rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true

  printf '%s\n' \
    '{' \
    '  "runtime_retained": false,' \
    "  \"build_bytes_deleted\": ${build_bytes_deleted}," \
    "  \"cleanup_rc\": ${cleanup_rc}" \
    '}' >"${cleanup_path}"
  printf '%s\n' \
    "l0_probe_rc=${l0_probe_rc}" \
    "receipt_build_rc=${receipt_build_rc}" \
    "receipt_verify_rc=${receipt_verify_rc}" \
    "checker_regression_rc=${checker_regression_rc}" \
    "cleanup_rc=${cleanup_rc}" \
    "build_bytes_deleted=${build_bytes_deleted}" >"${command_status}"

  if [[ ${command_rc} -eq 0 && ${cleanup_rc} -eq 0 &&
        ${evidence_ready} -eq 1 && -s "${probe_log}" &&
        -s "${result_path}" && -s "${cleanup_path}" ]]; then
    task_run_status_stage evidence-complete
    task_run_status_mark_evidence_complete
  fi
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  finalize_rc=$?
  printf '%s\n' \
    "[OWNER-TIMING-CAUSAL][DONE] status=$(cat "${status_path}") result=${result_rel}"
  exit "${finalize_rc}"
}
trap finish_run EXIT

task_run_status_stage l0-causal-probe
set +e
make -s -C npc/rv64/testbench owner-timing-causal-probe-focused \
  "RESULT_DIR=${probe_dir}" "BUILD_DIR=${runtime_dir}/build" \
  >"${probe_dir}/driver.log" 2>&1
l0_probe_rc=$?
set -e
[[ ${l0_probe_rc} -eq 0 ]] || exit "${l0_probe_rc}"

task_run_status_stage receipt-build
set +e
python3 -B "${tool}" build \
  --owner-receipt "${owner_rel}" \
  --probe-log "${probe_rel}" \
  --output "${result_rel}" >"${analysis_dir}/build.log" 2>&1
receipt_build_rc=$?
set -e
[[ ${receipt_build_rc} -eq 0 ]] || exit "${receipt_build_rc}"

task_run_status_stage receipt-verify
set +e
python3 -B "${tool}" verify --input "${result_rel}" \
  >"${analysis_dir}/verify.log" 2>&1
receipt_verify_rc=$?
set -e
[[ ${receipt_verify_rc} -eq 0 ]] || exit "${receipt_verify_rc}"

task_run_status_stage checker-regression
set +e
NPC_OWNER_TIMING_RECEIPT="${owner_rel}" \
NPC_OWNER_TIMING_CAUSAL_PROBE_LOG="${probe_rel}" \
python3 -B -m unittest -q \
  npc.rv64.eval.ppa.tests.test_owner_timing_causal_analysis \
  >"${analysis_dir}/checker-regression.log" 2>&1
checker_regression_rc=$?
set -e
[[ ${checker_regression_rc} -eq 0 ]] || exit "${checker_regression_rc}"

evidence_ready=1
