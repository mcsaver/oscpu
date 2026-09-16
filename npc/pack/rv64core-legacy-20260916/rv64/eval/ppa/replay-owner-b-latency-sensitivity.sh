#!/usr/bin/env bash

set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir=

usage() {
  printf '%s\n' \
    "usage: $0 --run-dir .github/task-runs/<completed-owner-b-latency-run>" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      run_dir=$2
      shift 2
      ;;
    *) usage; exit 2 ;;
  esac
done

[[ -n "${run_dir}" ]] || { usage; exit 2; }
if [[ "${run_dir}" != /* ]]; then
  run_dir="${repo_root}/${run_dir}"
fi
run_dir=$(realpath -m -- "${run_dir}") || exit 2
case "${run_dir}" in
  "${repo_root}/.github/task-runs/"*) ;;
  *)
    printf '%s\n' '[owner-b-latency-replay] run directory escapes task-runs' >&2
    exit 2
    ;;
esac

evidence="${run_dir}/evidence/owner-b-latency-sensitivity"
execution_archive="${evidence}/checker-replay"
replay="${evidence}/checker-replay-v2"
logs="${evidence}/logs"
status_path="${replay}/checker-replay.status"
tool="${repo_root}/npc/rv64/eval/ppa/tools/owner_b_latency_sensitivity.py"
tests="${repo_root}/npc/rv64/eval/ppa/tests/test_owner_b_latency_sensitivity.py"
original_checker="${execution_archive}/original/owner_b_latency_sensitivity.py"
original_runner="${execution_archive}/original/run-owner-b-latency-sensitivity.sh"
owner_receipt="${repo_root}/.github/task-runs/2026-08-06-rv64-v15l-owner-timing-workload-ab-f7a-a2/evidence/owner-timing-workload-ab/result.json"
causal_receipt="${repo_root}/.github/task-runs/2026-08-06-rv64-v15m-owner-timing-hypothesis-f7a/evidence/owner-timing-causal-analysis/result.json"

mkdir -p -- "${replay}"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}" || exit 1
task_run_status_install_signal_traps
finalized=0

finish_on_exit() {
  local command_rc=$?
  local final_rc
  trap - EXIT
  set +e
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_finalize "${command_rc}" 0
    final_rc=$?
  else
    final_rc=${command_rc}
  fi
  exit "${final_rc}"
}
trap finish_on_exit EXIT

check_original_failure_binding() {
  local row

  grep -Fxq 'FAIL rc=1 stage=receipt-build evidence_complete=0 cleanup_rc=0' \
    "${run_dir}/owner-b-latency-sensitivity.status" || return
  for row in \
    'preflight_rc=0' 'l0_rc=0' 'manifest_rc=0' 'source_rc=0' \
    'build_rc=0' 'simulator_identity_rc=0' 'execution_rc=0' \
    'postflight_rc=0' 'cleanup_rc=0' 'cleanup_capture_rc=0' \
    'receipt_rc=2' 'verify_rc=1' 'build_bytes_deleted=231088914'; do
    grep -Fxq "${row}" "${evidence}/command-status.txt" || return
  done
  [[ -s "${original_checker}" && -s "${original_runner}" ]]
}

binding_rc=125
unit_tests_rc=125
build_rc=125
verify_rc=125
result_present_rc=125

task_run_status_stage original-failure-binding
if check_original_failure_binding; then
  binding_rc=0
else
  binding_rc=$?
fi

if [[ "${binding_rc}" -eq 0 ]]; then
  task_run_status_stage checker-negative-tests
  if python3 -B -m unittest -v \
    npc.rv64.eval.ppa.tests.test_owner_b_latency_sensitivity \
    >"${replay}/unit-tests.log" 2>&1; then
    unit_tests_rc=0
  else
    unit_tests_rc=$?
  fi
fi

if [[ "${unit_tests_rc}" -eq 0 ]]; then
  task_run_status_stage checker-replay-build
  if python3 -B "${tool}" build \
    --owner-receipt "${owner_receipt}" \
    --causal-receipt "${causal_receipt}" \
    --selector "${evidence}/selection-snapshot/optimization-slice-current.json" \
    --selector-policy "${evidence}/selection-snapshot/selector-policy.json" \
    --selector-catalog "${evidence}/selection-snapshot/slice-catalog.json" \
    --selector-research "${evidence}/selection-snapshot/research-state.json" \
    --production-manifest "${evidence}/production-manifest-before.sha256" \
    --simulator-identity "${evidence}/simulator-identity.json" \
    --cleanup "${evidence}/runtime-cleanup.json" \
    --execution-status "${evidence}/execution-status.txt" \
    --execution-checker "${original_checker}" \
    --execution-runner "${original_runner}" \
    --coremark-delay0-log "${logs}/coremark-delay0-rep1.log" \
    --coremark-delay0-log "${logs}/coremark-delay0-rep2.log" \
    --coremark-delay0-log "${logs}/coremark-delay0-rep3.log" \
    --dhrystone-delay0-log "${logs}/dhrystone-delay0-rep1.log" \
    --dhrystone-delay0-log "${logs}/dhrystone-delay0-rep2.log" \
    --dhrystone-delay0-log "${logs}/dhrystone-delay0-rep3.log" \
    --coremark-delay2-log "${logs}/coremark-delay2-rep1.log" \
    --coremark-delay2-log "${logs}/coremark-delay2-rep2.log" \
    --coremark-delay2-log "${logs}/coremark-delay2-rep3.log" \
    --dhrystone-delay2-log "${logs}/dhrystone-delay2-rep1.log" \
    --dhrystone-delay2-log "${logs}/dhrystone-delay2-rep2.log" \
    --dhrystone-delay2-log "${logs}/dhrystone-delay2-rep3.log" \
    --output "${replay}/result.json" >"${replay}/build.log" 2>&1; then
    build_rc=0
  else
    build_rc=$?
  fi
fi

if [[ "${build_rc}" -eq 0 ]]; then
  task_run_status_stage checker-replay-verify
  if python3 -B "${tool}" verify --input "${replay}/result.json" \
    >"${replay}/verify.log" 2>&1; then
    verify_rc=0
  else
    verify_rc=$?
  fi
fi

if [[ "${verify_rc}" -eq 0 ]]; then
  task_run_status_stage checker-replay-result
  if [[ -s "${replay}/result.json" ]]; then
    result_present_rc=0
  else
    result_present_rc=1
  fi
fi

printf '%s\n' \
  "binding_rc=${binding_rc}" \
  "unit_tests_rc=${unit_tests_rc}" \
  "build_rc=${build_rc}" \
  "verify_rc=${verify_rc}" \
  "result_present_rc=${result_present_rc}" \
  >"${replay}/command-status.txt"

command_rc=0
for stage_rc in \
  "${binding_rc}" "${unit_tests_rc}" "${build_rc}" \
  "${verify_rc}" "${result_present_rc}"; do
  if [[ "${stage_rc}" -ne 0 ]]; then
    command_rc=${stage_rc}
    break
  fi
done
if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_stage evidence-complete
  task_run_status_mark_evidence_complete
fi

set +e
task_run_status_finalize "${command_rc}" 0
final_rc=$?
finalized=1
trap - EXIT
exit "${final_rc}"
