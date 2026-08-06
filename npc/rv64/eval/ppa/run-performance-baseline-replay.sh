#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
manifest=""
output_dir=""
status_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest) manifest=$2; shift 2 ;;
    --output-dir) output_dir=$2; shift 2 ;;
    --status) status_path=$2; shift 2 ;;
    *)
      printf '%s\n' \
        "usage: $0 --manifest A2_FROZEN_MANIFEST --output-dir PATH --status PATH" >&2
      exit 2
      ;;
  esac
done

[[ -n "${manifest}" && -n "${output_dir}" && -n "${status_path}" ]] || exit 2
for variable_name in manifest output_dir status_path; do
  case "${variable_name}" in
    manifest) value=${manifest} ;;
    output_dir) value=${output_dir} ;;
    status_path) value=${status_path} ;;
  esac
  if [[ "${value}" != /* ]]; then
    value="${repo_root}/${value}"
  fi
  resolved=$(realpath -m -- "${value}") || exit 2
  case "${resolved}" in
    "${repo_root}/.github/task-runs/"*) ;;
    *)
      printf '%s\n' \
        "[performance-baseline-replay] path escapes .github/task-runs: ${resolved}" >&2
      exit 2
      ;;
  esac
  case "${variable_name}" in
    manifest) manifest=${resolved} ;;
    output_dir) output_dir=${resolved} ;;
    status_path) status_path=${resolved} ;;
  esac
done

tool="${repo_root}/npc/rv64/eval/ppa/tools/performance_baseline_current.py"
arch_tool="${repo_root}/npc/rv64/eval/ppa/tools/arch_stable_freeze.py"
arch_stable="${repo_root}/npc/rv64/eval/ppa/evidence/arch-stable-current.json"
baseline_contract="${repo_root}/npc/rv64/design/arch/performance-baseline-contract-v2.json"
amendment="${repo_root}/npc/rv64/design/arch/performance-boundary-qualification-amendment-v1.json"
precheck_manifest="${output_dir}/precheck-manifest.json"
final_manifest="${output_dir}/final-manifest.json"
precheck_result="${output_dir}/precheck.json"
postflight_log="${output_dir}/arch-stable-postflight.log"
result="${output_dir}/result.json"
source "${repo_root}/scripts/task-run-status.sh"
mkdir -p "${output_dir}"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

manifest_rc=1
precheck_rc=1
postflight_rc=1
bind_rc=1
build_rc=1
verify_rc=1

task_run_status_stage "replay-manifest"
python3 -B "${tool}" replay-manifest \
  --source-manifest "${manifest}" \
  --baseline-contract "${baseline_contract}" \
  --boundary-qualification-amendment "${amendment}" \
  --output "${precheck_manifest}" >"${output_dir}/manifest.log" 2>&1
manifest_rc=$?

if [[ "${manifest_rc}" -eq 0 ]]; then
  task_run_status_stage "checker-precheck"
  python3 -B "${tool}" precheck \
    --manifest "${precheck_manifest}" \
    --output "${precheck_result}" >"${output_dir}/precheck.log" 2>&1
  precheck_rc=$?
fi

if [[ "${precheck_rc}" -eq 0 ]]; then
  task_run_status_stage "postflight-arch-stable"
  python3 -B "${arch_tool}" verify "${arch_stable}" \
    --require-stable >"${postflight_log}" 2>&1
  postflight_rc=$?
fi

if [[ "${postflight_rc}" -eq 0 ]]; then
  task_run_status_stage "bind-postflight"
  python3 -B "${tool}" bind-postflight \
    --manifest "${precheck_manifest}" \
    --postflight-log "${postflight_log}" \
    --output "${final_manifest}" >"${output_dir}/bind-postflight.log" 2>&1
  bind_rc=$?
fi

if [[ "${bind_rc}" -eq 0 ]]; then
  task_run_status_stage "checker-replay-build"
  python3 -B "${tool}" build \
    --manifest "${final_manifest}" \
    --output "${result}" \
    --require-baseline >"${output_dir}/build.log" 2>&1
  build_rc=$?
fi

if [[ "${build_rc}" -eq 0 ]]; then
  task_run_status_stage "checker-replay-verify"
  python3 -B "${tool}" verify \
    --input "${result}" \
    --require-baseline >"${output_dir}/verify.log" 2>&1
  verify_rc=$?
fi

printf '%s\n' \
  "manifest_rc=${manifest_rc}" \
  "precheck_rc=${precheck_rc}" \
  "postflight_rc=${postflight_rc}" \
  "bind_rc=${bind_rc}" \
  "build_rc=${build_rc}" \
  "verify_rc=${verify_rc}" \
  >"${output_dir}/command-status.txt"

command_rc=1
if [[ "${manifest_rc}" -eq 0 && "${precheck_rc}" -eq 0 &&
      "${postflight_rc}" -eq 0 && "${bind_rc}" -eq 0 &&
      "${build_rc}" -eq 0 && "${verify_rc}" -eq 0 &&
      -s "${result}" ]]; then
  command_rc=0
  task_run_status_stage "evidence-complete"
  task_run_status_mark_evidence_complete
fi
task_run_status_finalize "${command_rc}" 0
