#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir=""

if [[ "${1:-}" == "--run-dir" && -n "${2:-}" && -z "${3:-}" ]]; then
  run_dir=$2
else
  printf '%s\n' "usage: $0 --run-dir .github/task-runs/<run-id>" >&2
  exit 2
fi

if [[ "${run_dir}" != /* ]]; then
  run_dir="${repo_root}/${run_dir}"
fi
run_dir=$(realpath -m -- "${run_dir}") || exit 2
case "${run_dir}" in
  "${repo_root}/.github/task-runs/"*) ;;
  *)
    printf '%s\n' "[cpi-census] run directory escapes .github/task-runs" >&2
    exit 2
    ;;
esac

evidence_dir="${run_dir}/evidence/cpi-bottleneck-census"
status_path="${run_dir}/cpi-bottleneck-census.status"
command_status="${evidence_dir}/command-status.txt"
test_log="${evidence_dir}/checker-regression.log"
build_log="${evidence_dir}/build.log"
verify_log="${evidence_dir}/verify.log"
result="${evidence_dir}/census.json"
baseline="${repo_root}/npc/rv64/eval/ppa/evidence/performance-baseline-current.json"
tool="${repo_root}/npc/rv64/eval/ppa/tools/performance_bottleneck_census.py"

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p "${evidence_dir}"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

test_rc=1
build_rc=1
verify_rc=1

task_run_status_stage "checker-regression"
python3 -B -m unittest -q \
  npc.rv64.eval.ppa.tests.test_performance_bottleneck_census \
  >"${test_log}" 2>&1
test_rc=$?

if [[ "${test_rc}" -eq 0 ]]; then
  task_run_status_stage "census-build"
  python3 -B "${tool}" build \
    --baseline "${baseline}" \
    --output "${result}" >"${build_log}" 2>&1
  build_rc=$?
fi

if [[ "${build_rc}" -eq 0 ]]; then
  task_run_status_stage "census-verify"
  python3 -B "${tool}" verify \
    --input "${result}" >"${verify_log}" 2>&1
  verify_rc=$?
fi

printf '%s\n' \
  "test_rc=${test_rc}" \
  "build_rc=${build_rc}" \
  "verify_rc=${verify_rc}" \
  >"${command_status}"

command_rc=1
if [[ "${test_rc}" -eq 0 && "${build_rc}" -eq 0 &&
      "${verify_rc}" -eq 0 && -s "${result}" ]]; then
  command_rc=0
  task_run_status_stage "evidence-complete"
  task_run_status_mark_evidence_complete
fi
task_run_status_finalize "${command_rc}" 0
