#!/usr/bin/env bash

# Canonical local RV64 full-core functional runner.  It never discovers or
# rewrites an existing task-run.  Optional current publication starts only
# after the execution result has reached an explicit, verified PASS state.

set -uo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"
task_run_root="${repo_root}/.github/task-runs"
module_tool="${repo_root}/npc/rv64/eval/ppa/tools/full_core_current_evidence.py"
functional_tool="${repo_root}/npc/rv64/eval/ppa/tools/full_core_functional_evidence.py"
policy_path="${repo_root}/npc/rv64/design/arch/full-core-functional-run-policy-v1.json"
python_bin="$(realpath -e -- /usr/bin/python3)" || exit 2
run_dir_arg=""
jobs=2
publish_current=0
finalized=0

usage() {
  local stream=${1:-2}
  printf '%s\n' \
    "usage: $0 --run-dir .github/task-runs/<new-run-id> [--jobs 1..8] [--publish-current]" \
    >&"${stream}"
}

unique_stage_pass() {
  local log_path=${1:?log path is required}
  local pass_pattern=${2:?PASS pattern is required}
  local fail_pattern=${3:?FAIL pattern is required}
  local pass_count
  local fail_count

  pass_count="$(grep -Ec "${pass_pattern}" "${log_path}" || :)"
  fail_count="$(grep -Ec "${fail_pattern}" "${log_path}" || :)"
  [[ "${pass_count}" == "1" && "${fail_count}" == "0" ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      run_dir_arg=$2
      shift 2
      ;;
    --jobs)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      jobs=$2
      shift 2
      ;;
    --publish-current)
      publish_current=1
      shift
      ;;
    -h|--help)
      usage 1
      exit 0
      ;;
    *)
      printf '%s\n' "[FULL-CORE-CURRENT][FAIL] unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ ! "${jobs}" =~ ^[1-8]$ ]]; then
  printf '%s\n' "[FULL-CORE-CURRENT][FAIL] --jobs must be in [1, 8]" >&2
  exit 2
fi
if [[ ! "${run_dir_arg}" =~ ^\.github/task-runs/[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  printf '%s\n' \
    "[FULL-CORE-CURRENT][FAIL] --run-dir must name one new task-run directory" >&2
  exit 2
fi

task_run_root="$(realpath -e -- "${task_run_root}")" || exit 2
run_dir="${task_run_root}/${run_dir_arg##*/}"
if [[ -e "${run_dir}" || -L "${run_dir}" ]]; then
  printf '%s\n' \
    "[FULL-CORE-CURRENT][FAIL] run directory already exists: ${run_dir_arg}" >&2
  exit 2
fi
for required in "${module_tool}" "${functional_tool}" "${policy_path}"; do
  if [[ -L "${required}" || ! -f "${required}" ]]; then
    printf '%s\n' "[FULL-CORE-CURRENT][FAIL] required input is unsafe: ${required}" >&2
    exit 2
  fi
done

mkdir -- "${run_dir}" || exit 1
evidence_dir="${run_dir}/evidence"
module_dir="${evidence_dir}/module"
functional_dir="${evidence_dir}/functional"
status_path="${run_dir}/full-core-current.status"
publication_status_path="${run_dir}/full-core-publication.status"
summary_path="${run_dir}/driver-summary.tsv"
mkdir -- "${evidence_dir}" || exit 1

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}" || exit 1
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

policy_sha256="$(sha256sum -- "${policy_path}" | awk '{print $1}')" || exit 1
{
  printf '%s\t%s\n' \
    schema npc-rv64-full-core-current-driver-v2 \
    state RUNNING \
    run_dir "${run_dir_arg}" \
    jobs "${jobs}" \
    publish_current "${publish_current}" \
    policy npc/rv64/design/arch/full-core-functional-run-policy-v1.json \
    policy_sha256 "${policy_sha256}"
} >"${summary_path}"

module_rc=1
module_marker_rc=1
functional_rc=1
functional_marker_rc=1
verify_rc=1
verify_marker_rc=1
execution_finalize_rc=1
publication_rc=-1
publication_finalize_rc=-1

task_run_status_stage "module-current"
"${python_bin}" -B "${module_tool}" module \
  --output-dir "${module_dir}" --jobs "${jobs}" \
  >"${run_dir}/module-driver.log" 2>&1
module_rc=$?
if [[ "${module_rc}" -eq 0 ]] && unique_stage_pass \
     "${run_dir}/module-driver.log" \
     '^\[FULL-CORE-MODULE-CURRENT\]\[PASS\] ' \
     '^\[FULL-CORE-MODULE-CURRENT\]\[FAIL\] '; then
  module_marker_rc=0
else
  module_rc=1
fi

if [[ "${module_rc}" -eq 0 && -s "${module_dir}/result.json" ]]; then
  task_run_status_stage "functional-current"
  functional_args=(
    -B "${functional_tool}"
    --module-result "${module_dir}/result.json"
    --output-dir "${functional_dir}"
    --jobs "${jobs}"
  )
  "${python_bin}" "${functional_args[@]}" \
    >"${run_dir}/functional-driver.log" 2>&1
  functional_rc=$?
  if [[ "${functional_rc}" -eq 0 ]] && unique_stage_pass \
       "${run_dir}/functional-driver.log" \
       '^\[FULL-CORE-FUNCTIONAL-CURRENT\]\[PASS\] ' \
       '^\[FULL-CORE-FUNCTIONAL-CURRENT\]\[FAIL\] '; then
    functional_marker_rc=0
  else
    functional_rc=1
  fi
fi

if [[ "${functional_rc}" -eq 0 && -s "${functional_dir}/run-result.json" ]]; then
  task_run_status_stage "functional-result-verify"
  verify_args=(
    -B "${functional_tool}"
    --verify-result "${functional_dir}/run-result.json"
    --require-current-design
  )
  "${python_bin}" "${verify_args[@]}" >"${run_dir}/verify.log" 2>&1
  verify_rc=$?
  if [[ "${verify_rc}" -eq 0 ]] && unique_stage_pass \
       "${run_dir}/verify.log" \
       '^\[FULL-CORE-FUNCTIONAL-VERIFY\]\[PASS\] ' \
       '^\[FULL-CORE-FUNCTIONAL-VERIFY\]\[FAIL\] '; then
    verify_marker_rc=0
  else
    verify_rc=1
  fi
fi

printf '%s\t%s\n' \
  module_rc "${module_rc}" \
  module_marker_rc "${module_marker_rc}" \
  functional_rc "${functional_rc}" \
  functional_marker_rc "${functional_marker_rc}" \
  verify_rc "${verify_rc}" \
  verify_marker_rc "${verify_marker_rc}" \
  >>"${summary_path}"

command_rc=1
if [[ "${module_rc}" -eq 0 && "${functional_rc}" -eq 0 &&
      "${verify_rc}" -eq 0 ]]; then
  command_rc=0
fi

task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_mark_evidence_complete
  printf '%s\n' $'execution_state\tPASS' >>"${summary_path}"
else
  printf '%s\n' $'execution_state\tFAIL' >>"${summary_path}"
fi
task_run_status_finalize "${command_rc}" 0
execution_finalize_rc=$?
finalized=1
printf '%s\t%s\n' execution_finalize_rc "${execution_finalize_rc}" \
  >>"${summary_path}"

if [[ "${command_rc}" -ne 0 || "${execution_finalize_rc}" -ne 0 ]]; then
  exit "${execution_finalize_rc}"
fi

if [[ "${publish_current}" -eq 0 ]]; then
  printf '%s\n' $'publication_state\tNOT_REQUESTED' >>"${summary_path}"
  exit 0
fi

# Publication has a separate fail-closed lifecycle.  At this point the
# immutable execution result and full-core-current.status are already PASS.
task_run_status_init "${publication_status_path}" || exit 1
finalized=0
task_run_status_stage "publish-current"
"${python_bin}" -B "${functional_tool}" \
  --publish-result "${functional_dir}/run-result.json" \
  >"${run_dir}/publication.log" 2>&1
publication_rc=$?
if [[ "${publication_rc}" -eq 0 ]] && ! unique_stage_pass \
     "${run_dir}/publication.log" \
     '^\[FULL-CORE-FUNCTIONAL-PUBLISH\]\[PASS\] ' \
     '^\[FULL-CORE-FUNCTIONAL-PUBLISH\]\[FAIL\] '; then
  publication_rc=1
fi
printf '%s\t%s\n' publication_rc "${publication_rc}" >>"${summary_path}"

task_run_status_stage "publication-evidence-complete"
if [[ "${publication_rc}" -eq 0 ]]; then
  task_run_status_mark_evidence_complete
  printf '%s\n' $'publication_state\tPASS' >>"${summary_path}"
else
  printf '%s\n' $'publication_state\tFAIL' >>"${summary_path}"
fi
task_run_status_finalize "${publication_rc}" 0
publication_finalize_rc=$?
finalized=1
printf '%s\t%s\n' publication_finalize_rc "${publication_finalize_rc}" \
  >>"${summary_path}"
exit "${publication_finalize_rc}"
