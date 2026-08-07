#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a"
evidence_tag=${V15P_PERFORMANCE_TAG:-performance-ab}
if [[ ! "${evidence_tag}" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  printf '%s\n' "[v15p-performance-ab] invalid evidence tag: ${evidence_tag}" >&2
  exit 2
fi
evidence_dir="${run_dir}/evidence/${evidence_tag}"
logs_dir="${evidence_dir}/logs"
status_path="${run_dir}/${evidence_tag}.status"
command_status="${evidence_dir}/command-status.txt"
identity_path="${evidence_dir}/build-identity.json"
result_path="${evidence_dir}/result.json"
tool="${run_dir}/driver/v15p_performance_ab.py"

parent_adapter="${run_dir}/evidence/ppa/parent/OooLsuAxiLaneAdapter.v"
candidate_adapter="${repo_root}/npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
functional_dir=${V15P_FUNCTIONAL_DIR:-"${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-full-core-bfallthrough-a1/evidence/functional"}
coremark_image="${functional_dir}/images/benchmarks/coremark.bin"
dhrystone_image="${functional_dir}/images/benchmarks/dhrystone.bin"
config_path="${repo_root}/npc/rv64/.config"

runtime_base="${repo_root}/.github/runtime-artifacts/v15p-${evidence_tag}"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
runtime_dir=
active_pid=
cleanup_rc=0
finalized=0
build_bytes_deleted=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p -- "${evidence_dir}" "${logs_dir}" "${runtime_base}" \
  "$(dirname -- "${lock_path}")" || exit 1
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[v15p-performance-ab] RV64 engineering lane is occupied' >&2
  exit 3
fi
runtime_dir=$(mktemp -d "${runtime_base}/run.XXXXXX") || exit 1
task_run_status_init "${status_path}" || exit 1

cleanup_runtime() {
  local resolved
  if [[ -z "${runtime_dir}" || ! -e "${runtime_dir}" ]]; then
    return 0
  fi
  resolved=$(realpath -m -- "${runtime_dir}") || return 1
  case "${resolved}" in
    "${runtime_base}/run."*) ;;
    *)
      printf '%s\n' "[v15p-performance-ab] refusing cleanup target: ${resolved}" >&2
      return 2
      ;;
  esac
  rm -r -- "${resolved}"
}

forward_signal() {
  local signal_name=$1
  local signal_rc=$2
  if [[ -n "${active_pid}" ]] && kill -0 "${active_pid}" 2>/dev/null; then
    kill -s "${signal_name}" -- "-${active_pid}" 2>/dev/null ||
      kill -s "${signal_name}" "${active_pid}" 2>/dev/null || true
    wait "${active_pid}" 2>/dev/null || true
  fi
  active_pid=
  cleanup_runtime || cleanup_rc=$?
  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  task_run_status_stage "signal-${signal_name}"
  finalized=1
  task_run_status_finalize "${signal_rc}" "${cleanup_rc}" || true
  trap - HUP INT TERM EXIT
  exit "${signal_rc}"
}

finalize_on_exit() {
  local command_rc=$?
  if [[ -n "${runtime_dir}" && -e "${runtime_dir}" ]]; then
    cleanup_runtime || cleanup_rc=$?
  fi
  rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage exit-trap
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}

trap 'forward_signal HUP 129' HUP
trap 'forward_signal INT 130' INT
trap 'forward_signal TERM 143' TERM
trap finalize_on_exit EXIT

bounded_log() {
  local source_path=$1
  local destination_path=$2
  local size
  size=$(stat -c '%s' "${source_path}") || return 1
  if [[ "${size}" -le 131072 ]]; then
    cp -- "${source_path}" "${destination_path}"
  else
    {
      head -c 65536 "${source_path}"
      printf '\n[v15p-performance-ab] ... bounded build-log middle omitted ...\n'
      tail -c 65536 "${source_path}"
    } >"${destination_path}"
  fi
}

production_manifest() {
  find "${repo_root}/npc/rv64/vsrc" "${repo_root}/npc/rv64/csrc" \
    -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o \
      -name '*.svh' -o -name '*.cpp' -o -name '*.cc' -o -name '*.c' -o \
      -name '*.h' -o -name '*.hpp' -o -name '*.mk' \) -print0 |
    sort -z | xargs -0 sha256sum
  sha256sum "${config_path}" \
    "${repo_root}/npc/rv64/include/generated/autoconf.h" \
    "${repo_root}/npc/rv64/include/config/auto.conf" \
    "${coremark_image}" "${dhrystone_image}"
}

run_build() {
  local mode=$1
  local build_dir="${runtime_dir}/${mode}-build"
  local binary="${build_dir}/NpcSimTop"
  local full_log="${runtime_dir}/${mode}-build.full.log"
  local adapter_override=()
  if [[ "${mode}" == parent ]]; then
    adapter_override=("RTL_OOO_LSU_AXI_LANE_ADAPTER=${parent_adapter}")
  fi
  task_run_status_stage "verilator-build-${mode}"
  mkdir -p -- "${build_dir}"
  setsid /usr/bin/timeout --signal=TERM --kill-after=20s 1200s \
    make -C "${repo_root}/npc/rv64" \
      BUILD_DIR="${build_dir}" CONFIG_NPC_OOO_STATS=y \
      VERILATOR_BUILD_JOBS=2 "${adapter_override[@]}" "${binary}" \
      >"${full_log}" 2>&1 &
  active_pid=$!
  wait "${active_pid}"
  local rc=$?
  active_pid=
  bounded_log "${full_log}" "${evidence_dir}/${mode}-build.log" || rc=1
  if [[ "${rc}" -eq 0 && -x "${binary}" &&
        -s "${build_dir}/obj_dir/VNpcSimTop__verFiles.dat" ]]; then
    cp -- "${build_dir}/obj_dir/VNpcSimTop__verFiles.dat" \
      "${evidence_dir}/${mode}-verFiles.dat" || rc=1
  else
    rc=1
  fi
  return "${rc}"
}

run_region() {
  local stage=$1
  local simulator=$2
  local image=$3
  local start_pc=$4
  local end_pc=$5
  local max_cycles=$6
  local timeout_seconds=$7
  local output=$8
  local rc=0
  task_run_status_stage "${stage}"
  setsid /usr/bin/env NPC_REGION_START_PC="${start_pc}" \
    NPC_REGION_END_PC="${end_pc}" \
    /usr/bin/timeout --signal=TERM --kill-after=15s "${timeout_seconds}s" \
      "${simulator}" "${image}" --batch --no-vga \
      --max-cycles="${max_cycles}" >"${output}" 2>&1 &
  active_pid=$!
  wait "${active_pid}" || rc=$?
  active_pid=
  if [[ "${rc}" -ne 0 || ! -s "${output}" ||
        $(stat -c '%s' "${output}") -gt 1048576 ]]; then
    return 1
  fi
  if grep -Eiq '%Error|Assertion failed|\[CHECK-FAIL\]|\[RTL_ASSERTION\]|FATAL:' \
      "${output}"; then
    return 1
  fi
}

preflight_rc=1
manifest_rc=1
parent_build_rc=1
candidate_build_rc=1
identity_rc=1
execution_rc=1
result_rc=1
verify_rc=1

task_run_status_stage preflight
preflight_rc=0
for input in "${parent_adapter}" "${candidate_adapter}" "${coremark_image}" \
  "${dhrystone_image}" "${config_path}" "${tool}"; do
  [[ -f "${input}" && ! -L "${input}" ]] || preflight_rc=1
done
for command_name in flock find grep make python3 realpath setsid sha256sum \
  sort stat timeout xargs; do
  command -v "${command_name}" >/dev/null || preflight_rc=1
done
if [[ "${preflight_rc}" -eq 0 ]]; then
  [[ $(sha256sum "${parent_adapter}" | awk '{print $1}') == \
    3f59eb66967afca26700a520fedba6372a0ab7f96464048a5493642df55ab3b6 ]] || preflight_rc=1
  [[ $(sha256sum "${candidate_adapter}" | awk '{print $1}') == \
    6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22 ]] || preflight_rc=1
fi

if [[ "${preflight_rc}" -eq 0 ]]; then
  task_run_status_stage production-manifest-before
  production_manifest >"${evidence_dir}/production-manifest-before.sha256"
  manifest_rc=$?
fi
if [[ "${manifest_rc}" -eq 0 ]]; then
  run_build parent
  parent_build_rc=$?
fi
if [[ "${parent_build_rc}" -eq 0 ]]; then
  run_build candidate
  candidate_build_rc=$?
fi

if [[ "${candidate_build_rc}" -eq 0 ]]; then
  task_run_status_stage build-identity
  python3 -B "${tool}" identity \
    --parent-adapter "${parent_adapter}" \
    --candidate-adapter "${candidate_adapter}" \
    --parent-binary "${runtime_dir}/parent-build/NpcSimTop" \
    --candidate-binary "${runtime_dir}/candidate-build/NpcSimTop" \
    --parent-build-log "${evidence_dir}/parent-build.log" \
    --candidate-build-log "${evidence_dir}/candidate-build.log" \
    --parent-verfiles "${evidence_dir}/parent-verFiles.dat" \
    --candidate-verfiles "${evidence_dir}/candidate-verFiles.dat" \
    --config "${config_path}" --coremark-image "${coremark_image}" \
    --dhrystone-image "${dhrystone_image}" --output "${identity_path}" \
    >"${evidence_dir}/identity.log" 2>&1
  identity_rc=$?
fi

if [[ "${identity_rc}" -eq 0 ]]; then
  execution_rc=0
  sequence=(parent candidate candidate parent parent candidate)
  for workload in coremark dhrystone; do
    if [[ "${workload}" == coremark ]]; then
      image="${coremark_image}"
      start_pc=0x00000000800017a8
      end_pc=0x00000000800017b0
      max_cycles=6000000
      timeout_seconds=300
    else
      image="${dhrystone_image}"
      start_pc=0x0000000080000334
      end_pc=0x000000008000047c
      max_cycles=12000000
      timeout_seconds=420
    fi
    index=0
    for mode in "${sequence[@]}"; do
      index=$((index + 1))
      printf -v padded '%02d' "${index}"
      run_region "${workload}-${padded}-${mode}" \
        "${runtime_dir}/${mode}-build/NpcSimTop" "${image}" \
        "${start_pc}" "${end_pc}" "${max_cycles}" "${timeout_seconds}" \
        "${logs_dir}/${workload}-${padded}-${mode}.log" || {
          execution_rc=$?
          break 2
        }
      printf 'workload=%s sequence=%s mode=%s rc=0 assertion_markers=0\n' \
        "${workload}" "${padded}" "${mode}" >>"${evidence_dir}/execution-status.txt"
    done
  done
fi

if [[ "${execution_rc}" -eq 0 ]]; then
  task_run_status_stage result-build
  python3 -B "${tool}" result --identity "${identity_path}" \
    --logs-dir "${logs_dir}" --output "${result_path}" \
    >"${evidence_dir}/result.log" 2>&1
  result_rc=$?
fi
if [[ "${result_rc}" -eq 0 ]]; then
  task_run_status_stage result-verify
  python3 -B "${tool}" verify --input "${result_path}" \
    >"${evidence_dir}/verify.log" 2>&1
  verify_rc=$?
fi

if [[ "${verify_rc}" -eq 0 ]]; then
  task_run_status_stage production-manifest-after
  production_manifest >"${evidence_dir}/production-manifest-after.sha256" || manifest_rc=$?
  if [[ "${manifest_rc}" -eq 0 ]] && ! cmp -s \
      "${evidence_dir}/production-manifest-before.sha256" \
      "${evidence_dir}/production-manifest-after.sha256"; then
    manifest_rc=1
  fi
fi

task_run_status_stage runtime-cleanup
if [[ -e "${runtime_dir}" ]]; then
  build_bytes_deleted=$(du -sb "${runtime_dir}" | awk '{print $1}')
  cleanup_runtime || cleanup_rc=$?
fi
[[ ! -e "${runtime_dir}" ]] || cleanup_rc=1
rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true

command_rc=1
if [[ "${preflight_rc}" -eq 0 && "${manifest_rc}" -eq 0 &&
      "${parent_build_rc}" -eq 0 && "${candidate_build_rc}" -eq 0 &&
      "${identity_rc}" -eq 0 && "${execution_rc}" -eq 0 &&
      "${result_rc}" -eq 0 && "${verify_rc}" -eq 0 &&
      "${cleanup_rc}" -eq 0 && "${build_bytes_deleted}" -gt 0 ]]; then
  command_rc=0
fi
printf '%s\n' \
  "preflight_rc=${preflight_rc}" "manifest_rc=${manifest_rc}" \
  "parent_build_rc=${parent_build_rc}" "candidate_build_rc=${candidate_build_rc}" \
  "identity_rc=${identity_rc}" "execution_rc=${execution_rc}" \
  "result_rc=${result_rc}" "verify_rc=${verify_rc}" \
  "cleanup_rc=${cleanup_rc}" "runtime_bytes_deleted=${build_bytes_deleted}" \
  >"${command_status}"

task_run_status_stage evidence-complete
if [[ "${command_rc}" -eq 0 && -s "${result_path}" &&
      -s "${identity_path}" && ! -e "${runtime_dir}" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
