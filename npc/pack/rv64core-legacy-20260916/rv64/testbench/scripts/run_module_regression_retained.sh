#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testbench_dir="$(cd "${script_dir}/.." && pwd)"
workspace_dir="$(cd "${testbench_dir}/../../.." && pwd)"
status_helper="${workspace_dir}/scripts/task-run-status.sh"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 RESULT_DIR [EXPECTED_TOTAL]" >&2
  exit 2
fi

result_dir="$(realpath -m "$1")"
expected_total="${2:-113}"
if [[ ! "${expected_total}" =~ ^[1-9][0-9]*$ ]]; then
  echo "invalid expected total: ${expected_total}" >&2
  exit 2
fi

mkdir -p -- "${result_dir}"
work_dir="${result_dir}/.work.$$"
build_dir="${work_dir}/build"
status_path="${result_dir}/runner.status"
mkdir -p -- "${build_dir}"

# shellcheck source=../../../../scripts/task-run-status.sh
source "${status_helper}"
task_run_status_init "${status_path}"
task_run_status_stage "module-regression"

finish_run() {
  local command_rc=$?
  local cleanup_rc=0
  local final_rc

  trap - EXIT HUP INT TERM
  case "${work_dir}" in
    "${result_dir}"/.work.*)
      if [[ -e "${work_dir}" ]]; then
        rm -r -- "${work_dir}" || cleanup_rc=$?
      fi
      ;;
    *)
      cleanup_rc=97
      ;;
  esac

  set +e
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  final_rc=$?
  exit "${final_rc}"
}
trap finish_run EXIT
task_run_status_install_signal_traps

make -C "${testbench_dir}" run \
  "RESULT_DIR=${result_dir}" \
  "BUILD_DIR=${build_dir}"
make_rc=$?
if [[ ${make_rc} -ne 0 ]]; then
  exit "${make_rc}"
fi

task_run_status_stage "evidence-verify"
summary_path="${result_dir}/summary.txt"
if [[ ! -f "${summary_path}" ]]; then
  echo "missing module regression summary: ${summary_path}" >&2
  exit 1
fi

total="$(awk '/^- total:/{print $3}' "${summary_path}")"
passed="$(awk '/^- passed:/{print $3}' "${summary_path}")"
failed="$(awk '/^- failed:/{print $3}' "${summary_path}")"
log_count="$(find "${result_dir}/logs" -maxdepth 1 -type f -name '*.log' | wc -l)"
if [[ "${total}" != "${expected_total}" ||
      "${passed}" != "${expected_total}" ||
      "${failed}" != 0 ||
      "${log_count}" != "${expected_total}" ]]; then
  printf '%s\n' \
    "module regression evidence mismatch" \
    "total=${total} passed=${passed} failed=${failed} logs=${log_count}" >&2
  exit 1
fi

printf '%s\n' \
  'RESULT=PASS' \
  "TOTAL=${total}" \
  "PASSED=${passed}" \
  "FAILED=${failed}" \
  "LOG_COUNT=${log_count}" \
  'BUILD_RETAINED=0' \
  "SUMMARY=${summary_path}" >"${result_dir}/result.txt"

task_run_status_stage "evidence-complete"
task_run_status_mark_evidence_complete
exit 0
