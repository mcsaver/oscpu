#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir=""
mode=full
probe_workload=coremark
arch_stable_input=npc/rv64/eval/ppa/evidence/arch-stable-current.json

usage() {
  printf '%s\n' \
    "usage: $0 --run-dir .github/task-runs/<run-id> [--arch-stable PATH] [--mode full|candidate-full|invalid-probe] [--workload coremark|dhrystone_10000]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      run_dir=$2
      shift 2
      ;;
    --mode)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      mode=$2
      shift 2
      ;;
    --arch-stable)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      arch_stable_input=$2
      shift 2
      ;;
    --workload)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      probe_workload=$2
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

case "${mode}" in
  full|candidate-full|invalid-probe) ;;
  *) usage; exit 2 ;;
esac
case "${probe_workload}" in
  coremark|dhrystone_10000) ;;
  *) usage; exit 2 ;;
esac

[[ -n "${run_dir}" ]] || { usage; exit 2; }
if [[ "${run_dir}" != /* ]]; then
  run_dir="${repo_root}/${run_dir}"
fi
run_dir=$(realpath -m -- "${run_dir}") || exit 2
case "${run_dir}" in
  "${repo_root}/.github/task-runs/"*) ;;
  *)
    printf '%s\n' '[owner-timing-workload] run directory escapes .github/task-runs' >&2
    exit 2
    ;;
esac
if [[ -e "${run_dir}" || -L "${run_dir}" ]]; then
  printf '%s\n' '[owner-timing-workload] run directory already exists' >&2
  exit 2
fi
if [[ "${arch_stable_input}" != /* ]]; then
  arch_stable_input="${repo_root}/${arch_stable_input}"
fi
arch_stable=$(realpath -m -- "${arch_stable_input}") || exit 2
case "${arch_stable}" in
  "${repo_root}/"*) ;;
  *)
    printf '%s\n' '[owner-timing-workload] ARCH_STABLE receipt escapes workspace' >&2
    exit 2
    ;;
esac
[[ -f "${arch_stable}" ]] || {
  printf '%s\n' '[owner-timing-workload] ARCH_STABLE receipt is missing' >&2
  exit 2
}

artifact_name=owner-timing-workload-ab
arch_stable_required=1
if [[ "${mode}" == candidate-full ]]; then
  artifact_name=owner-timing-current-candidate-ab
  arch_stable_required=0
elif [[ "${mode}" == invalid-probe ]]; then
  artifact_name=owner-timing-invalid-probe
  arch_stable_required=0
fi
evidence_dir="${run_dir}/evidence/${artifact_name}"
logs_dir="${evidence_dir}/logs"
status_path="${run_dir}/${artifact_name}.status"
command_status="${evidence_dir}/command-status.txt"
result_path="${evidence_dir}/result.json"
manifest_before="${evidence_dir}/production-manifest-before.sha256"
manifest_after="${evidence_dir}/production-manifest-after.sha256"
simulator_identity="${evidence_dir}/simulator-identity.json"
cleanup_identity="${evidence_dir}/runtime-cleanup.json"

runtime_base="${repo_root}/.github/runtime-artifacts/owner-timing-workload-ab"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
mkdir -p "${evidence_dir}" "${logs_dir}" "${runtime_base}" \
  "$(dirname -- "${lock_path}")" || exit 1
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[owner-timing-workload] RV64 engineering lane is occupied' >&2
  exit 3
fi
runtime_dir=$(mktemp -d "${runtime_base}/run.XXXXXX") || exit 1
build_dir="${runtime_dir}/build"
build_log_full="${runtime_dir}/build-full.log"
diagnostic_simulator="${build_dir}/NpcSimTop"

baseline="${repo_root}/npc/rv64/eval/ppa/evidence/performance-baseline-current.json"
contract="${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-contract-v1.json"
profile="${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-validation-profile-v1.json"
make_fragment="${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing.mk"
checker="${repo_root}/npc/rv64/eval/ppa/instrumentation/check-owner-timing.sh"
tool="${repo_root}/npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py"
arch_tool="${repo_root}/npc/rv64/eval/ppa/tools/arch_stable_freeze.py"
baseline_tool="${repo_root}/npc/rv64/eval/ppa/tools/performance_baseline_current.py"
coremark_image=""
dhrystone_image=""

active_pid=""
cleanup_rc=0
finalized=0
build_bytes_deleted=0

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}" || exit 1

production_identity() {
  find "${repo_root}/npc/rv64/vsrc" -type f \
    \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o \
       -name '*.svh' -o -name '*.mk' \) -print0 |
    sort -z | xargs -0 sha256sum
  sha256sum "${repo_root}/npc/rv64/include/generated/autoconf.h" \
            "${repo_root}/npc/rv64/include/config/auto.conf"
}

bounded_log() {
  local source_path=$1
  local destination_path=$2
  local size
  size=$(stat -c '%s' "${source_path}") || return 1
  if [[ "${size}" -le 65536 ]]; then
    cp -- "${source_path}" "${destination_path}"
    return $?
  fi
  {
    head -c 32768 "${source_path}"
    printf '\n[owner-timing-workload] ... bounded build-log middle omitted ...\n'
    tail -c 32768 "${source_path}"
  } >"${destination_path}"
}

cleanup_runtime() {
  local resolved
  if [[ ! -e "${runtime_dir}" ]]; then
    return 0
  fi
  resolved=$(realpath -m -- "${runtime_dir}") || return 1
  case "${resolved}" in
    "${runtime_base}/run."*) ;;
    *)
      printf '%s\n' "[owner-timing-workload] refusing cleanup target: ${resolved}" >&2
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
  active_pid=""
  cleanup_runtime || cleanup_rc=$?
  rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  task_run_status_stage "signal-${signal_name}"
  finalized=1
  task_run_status_finalize "${signal_rc}" "${cleanup_rc}" || true
  trap - HUP INT TERM EXIT
  exit "${signal_rc}"
}

finalize_on_exit() {
  local command_rc=$?
  if [[ -e "${runtime_dir}" ]]; then
    cleanup_runtime || cleanup_rc=$?
  fi
  rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}

trap 'forward_signal HUP 129' HUP
trap 'forward_signal INT 130' INT
trap 'forward_signal TERM 143' TERM
trap finalize_on_exit EXIT

run_region() {
  local stage=$1
  local image=$2
  local start_pc=$3
  local end_pc=$4
  local max_cycles=$5
  local timeout_seconds=$6
  local output=$7
  local rc=0
  task_run_status_stage "${stage}"
  setsid /usr/bin/env \
    NPC_REGION_START_PC="${start_pc}" \
    NPC_REGION_END_PC="${end_pc}" \
    /usr/bin/timeout --signal=TERM --kill-after=15s \
      "${timeout_seconds}s" "${diagnostic_simulator}" "${image}" \
      --batch --no-vga --max-cycles="${max_cycles}" >"${output}" 2>&1 &
  active_pid=$!
  wait "${active_pid}" || rc=$?
  active_pid=""
  if [[ -f "${output}" && $(stat -c '%s' "${output}") -gt 1048576 ]]; then
    printf '%s\n' "[owner-timing-workload] log exceeds 1 MiB: ${output}" >&2
    return 1
  fi
  return "${rc}"
}

preflight_rc=1
fast_rc=1
build_rc=1
simulator_identity_rc=1
coremark_rc=1
dhrystone_rc=1
manifest_rc=1
postflight_rc=1
cleanup_capture_rc=1
receipt_rc=1
verify_rc=1

preflight_rc=0
if [[ "${arch_stable_required}" -eq 1 ]]; then
  task_run_status_stage "preflight-arch-stable"
  python3 -B "${arch_tool}" verify "${arch_stable}" --require-stable \
    >"${evidence_dir}/arch-stable-pre.log" 2>&1
  preflight_rc=$?
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  task_run_status_stage "preflight-reference-baseline"
  python3 -B "${baseline_tool}" verify --input "${baseline}" --require-baseline \
    >"${evidence_dir}/performance-baseline-pre.log" 2>&1
  preflight_rc=$?
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  task_run_status_stage "preflight-workload-images"
  coremark_image=$(python3 -B "${tool}" resolve-image \
    --baseline "${baseline}" --contract "${contract}" --profile "${profile}" \
    --workload coremark) || preflight_rc=$?
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  dhrystone_image=$(python3 -B "${tool}" resolve-image \
    --baseline "${baseline}" --contract "${contract}" --profile "${profile}" \
    --workload dhrystone_10000) || preflight_rc=$?
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  if [[ ! -f "${coremark_image}" || ! -f "${dhrystone_image}" ||
        ! -f "${contract}" || ! -f "${profile}" || ! -f "${tool}" ]]; then
    preflight_rc=1
  else
    sha256sum "${coremark_image}" "${dhrystone_image}" \
      >"${evidence_dir}/workload-images.sha256" || preflight_rc=$?
  fi
fi

if [[ "${preflight_rc}" -eq 0 ]]; then
  task_run_status_stage "owner-timing-fast"
  setsid "${checker}" --tier fast >"${evidence_dir}/owner-timing-fast.log" 2>&1 &
  active_pid=$!
  fast_rc=0
  wait "${active_pid}" || fast_rc=$?
  active_pid=""
  if [[ $(grep -Ec \
      '^\[OWNER-TIMING-CHECK\]\[PASS\] tier=fast unit_cases=[1-9][0-9]* workload_cases=[1-9][0-9]* candidate_authorized=0 ppa=UNQUALIFIED$' \
      "${evidence_dir}/owner-timing-fast.log") -ne 1 ]]; then
    fast_rc=1
  fi
fi

if [[ "${preflight_rc}" -eq 0 && "${fast_rc}" -eq 0 ]]; then
  production_identity >"${manifest_before}" || manifest_rc=$?
  if [[ -s "${manifest_before}" ]]; then
    manifest_rc=0
  fi
fi

if [[ "${manifest_rc}" -eq 0 ]]; then
  task_run_status_stage "diagnostic-simulator-build"
  setsid /usr/bin/timeout --signal=TERM --kill-after=20s 900s \
    make -C "${repo_root}/npc/rv64" -f Makefile \
      -f eval/ppa/instrumentation/owner-timing.mk \
      CONFIG_NPC_OOO_STATS=y BUILD_DIR="${build_dir}" \
      VERILATOR_BUILD_JOBS=1 >"${build_log_full}" 2>&1 &
  active_pid=$!
  build_rc=0
  wait "${active_pid}" || build_rc=$?
  active_pid=""
  bounded_log "${build_log_full}" "${evidence_dir}/diagnostic-build.log" || build_rc=1
  if [[ "${build_rc}" -eq 0 && -x "${diagnostic_simulator}" ]]; then
    build_bytes_deleted=$(du -sb "${build_dir}" | awk '{print $1}')
    python3 -B "${tool}" capture-simulator \
      --simulator "${diagnostic_simulator}" \
      --make-fragment "${make_fragment}" \
      --output "${simulator_identity}" \
      >"${evidence_dir}/simulator-identity.log" 2>&1
    simulator_identity_rc=$?
  fi
fi

if [[ "${simulator_identity_rc}" -eq 0 ]]; then
  coremark_rc=0
  if [[ "${mode}" != invalid-probe || "${probe_workload}" == coremark ]]; then
    coremark_repetitions=3
    if [[ "${mode}" == invalid-probe ]]; then
      coremark_repetitions=1
    fi
    for repetition in $(seq 1 "${coremark_repetitions}"); do
      run_region "coremark-owner-timing-rep${repetition}" \
        "${coremark_image}" \
        0x00000000800017a8 0x00000000800017b0 \
        6000000 420 \
        "${logs_dir}/coremark-owner-timing-rep${repetition}.log" || {
          coremark_rc=$?
          break
        }
    done
  fi
fi

if [[ "${coremark_rc}" -eq 0 ]]; then
  dhrystone_rc=0
  if [[ "${mode}" != invalid-probe || "${probe_workload}" == dhrystone_10000 ]]; then
    dhrystone_repetitions=3
    if [[ "${mode}" == invalid-probe ]]; then
      dhrystone_repetitions=1
    fi
    for repetition in $(seq 1 "${dhrystone_repetitions}"); do
      run_region "dhrystone-owner-timing-rep${repetition}" \
        "${dhrystone_image}" \
        0x0000000080000334 0x000000008000047c \
        12000000 660 \
        "${logs_dir}/dhrystone-owner-timing-rep${repetition}.log" || {
          dhrystone_rc=$?
          break
        }
    done
  fi
fi

if [[ "${dhrystone_rc}" -eq 0 ]]; then
  task_run_status_stage "production-manifest-postflight"
  production_identity >"${manifest_after}" || manifest_rc=$?
  if [[ "${manifest_rc}" -eq 0 ]] && ! cmp -s "${manifest_before}" "${manifest_after}"; then
    manifest_rc=1
  fi
fi

if [[ "${dhrystone_rc}" -eq 0 && "${manifest_rc}" -eq 0 ]]; then
  postflight_rc=0
  if [[ "${arch_stable_required}" -eq 1 ]]; then
    task_run_status_stage "postflight-arch-stable"
    python3 -B "${arch_tool}" verify "${arch_stable}" --require-stable \
      >"${evidence_dir}/arch-stable-post.log" 2>&1
    postflight_rc=$?
  fi
  if [[ "${postflight_rc}" -eq 0 ]]; then
    task_run_status_stage "postflight-reference-baseline"
    python3 -B "${baseline_tool}" verify --input "${baseline}" --require-baseline \
      >"${evidence_dir}/performance-baseline-post.log" 2>&1
    postflight_rc=$?
  fi
fi

task_run_status_stage "runtime-cleanup"
if [[ -e "${runtime_dir}" ]]; then
  cleanup_runtime || cleanup_rc=$?
fi
if [[ -e "${runtime_dir}" ]]; then
  cleanup_rc=1
fi
rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
if [[ "${cleanup_rc}" -eq 0 ]]; then
  python3 -B "${tool}" capture-cleanup \
    --runtime-dir "${runtime_dir}" --output "${cleanup_identity}" \
    >"${evidence_dir}/runtime-cleanup.log" 2>&1
  cleanup_capture_rc=$?
fi

if [[ "${postflight_rc}" -eq 0 && "${cleanup_capture_rc}" -eq 0 ]]; then
  task_run_status_stage "receipt-build"
  if [[ "${mode}" == full ]]; then
    python3 -B "${tool}" build \
      --baseline "${baseline}" \
      --arch-stable "${arch_stable}" \
      --contract "${contract}" \
      --profile "${profile}" \
      --production-manifest "${manifest_before}" \
      --simulator-identity "${simulator_identity}" \
      --cleanup "${cleanup_identity}" \
      --coremark-log "${logs_dir}/coremark-owner-timing-rep1.log" \
      --coremark-log "${logs_dir}/coremark-owner-timing-rep2.log" \
      --coremark-log "${logs_dir}/coremark-owner-timing-rep3.log" \
      --dhrystone-log "${logs_dir}/dhrystone-owner-timing-rep1.log" \
      --dhrystone-log "${logs_dir}/dhrystone-owner-timing-rep2.log" \
      --dhrystone-log "${logs_dir}/dhrystone-owner-timing-rep3.log" \
      --output "${result_path}" >"${evidence_dir}/receipt-build.log" 2>&1
  elif [[ "${mode}" == candidate-full ]]; then
    python3 -B "${tool}" build-current-candidate \
      --baseline "${baseline}" \
      --contract "${contract}" \
      --profile "${profile}" \
      --production-manifest "${manifest_before}" \
      --simulator-identity "${simulator_identity}" \
      --cleanup "${cleanup_identity}" \
      --coremark-log "${logs_dir}/coremark-owner-timing-rep1.log" \
      --coremark-log "${logs_dir}/coremark-owner-timing-rep2.log" \
      --coremark-log "${logs_dir}/coremark-owner-timing-rep3.log" \
      --dhrystone-log "${logs_dir}/dhrystone-owner-timing-rep1.log" \
      --dhrystone-log "${logs_dir}/dhrystone-owner-timing-rep2.log" \
      --dhrystone-log "${logs_dir}/dhrystone-owner-timing-rep3.log" \
      --output "${result_path}" >"${evidence_dir}/receipt-build.log" 2>&1
  else
    probe_log="${logs_dir}/${probe_workload%%_10000}-owner-timing-rep1.log"
    python3 -B "${tool}" build-invalid-probe \
      --baseline "${baseline}" \
      --contract "${contract}" \
      --profile "${profile}" \
      --production-manifest "${manifest_before}" \
      --simulator-identity "${simulator_identity}" \
      --cleanup "${cleanup_identity}" \
      --workload "${probe_workload}" \
      --log "${probe_log}" \
      --current-design-diagnostic \
      --output "${result_path}" >"${evidence_dir}/receipt-build.log" 2>&1
  fi
  receipt_rc=$?
fi

if [[ "${receipt_rc}" -eq 0 ]]; then
  task_run_status_stage "receipt-verify"
  verify_command=verify
  if [[ "${mode}" == candidate-full ]]; then
    verify_command=verify-current-candidate
  elif [[ "${mode}" == invalid-probe ]]; then
    verify_command=verify-invalid-probe
  fi
  python3 -B "${tool}" "${verify_command}" --input "${result_path}" \
      >"${evidence_dir}/receipt-verify.log" 2>&1
  verify_rc=$?
fi

candidate_gate_rc=0
if [[ "${mode}" == candidate-full && "${verify_rc}" -eq 0 ]]; then
  task_run_status_stage "candidate-performance-gate"
  jq -e '.performance_gate == "PASS"' "${result_path}" >/dev/null 2>&1
  candidate_gate_rc=$?
fi

printf '%s\n' \
  "mode=${mode}" \
  "probe_workload=${probe_workload}" \
  "arch_stable_required=${arch_stable_required}" \
  "preflight_rc=${preflight_rc}" \
  "fast_rc=${fast_rc}" \
  "build_rc=${build_rc}" \
  "simulator_identity_rc=${simulator_identity_rc}" \
  "coremark_rc=${coremark_rc}" \
  "dhrystone_rc=${dhrystone_rc}" \
  "manifest_rc=${manifest_rc}" \
  "postflight_rc=${postflight_rc}" \
  "cleanup_rc=${cleanup_rc}" \
  "cleanup_capture_rc=${cleanup_capture_rc}" \
  "receipt_rc=${receipt_rc}" \
  "verify_rc=${verify_rc}" \
  "candidate_gate_rc=${candidate_gate_rc}" \
  "build_bytes_deleted=${build_bytes_deleted}" \
  >"${command_status}"

command_rc=1
if [[ "${preflight_rc}" -eq 0 && "${fast_rc}" -eq 0 &&
      "${build_rc}" -eq 0 && "${simulator_identity_rc}" -eq 0 &&
      "${coremark_rc}" -eq 0 && "${dhrystone_rc}" -eq 0 &&
      "${manifest_rc}" -eq 0 && "${postflight_rc}" -eq 0 &&
      "${cleanup_rc}" -eq 0 && "${cleanup_capture_rc}" -eq 0 &&
      "${receipt_rc}" -eq 0 && "${verify_rc}" -eq 0 &&
      "${candidate_gate_rc}" -eq 0 &&
      -s "${result_path}" ]]; then
  command_rc=0
  task_run_status_stage "evidence-complete"
  task_run_status_mark_evidence_complete
fi

finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
