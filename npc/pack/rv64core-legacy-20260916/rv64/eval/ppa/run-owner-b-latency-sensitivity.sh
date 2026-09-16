#!/usr/bin/env bash

set -uo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "${script_dir}/../../../.." && pwd)
run_dir=

usage() {
  printf '%s\n' \
    "usage: $0 --run-dir .github/task-runs/<new-run-id>" >&2
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
    printf '%s\n' '[owner-b-latency] run directory escapes .github/task-runs' >&2
    exit 2
    ;;
esac
if [[ -e "${run_dir}" || -L "${run_dir}" ]]; then
  printf '%s\n' '[owner-b-latency] run directory already exists' >&2
  exit 2
fi

artifact_name=owner-b-latency-sensitivity
evidence_dir="${run_dir}/evidence/${artifact_name}"
logs_dir="${evidence_dir}/logs"
selection_dir="${evidence_dir}/selection-snapshot"
source_dir="${evidence_dir}/source-substitution"
status_path="${run_dir}/${artifact_name}.status"
command_status="${evidence_dir}/command-status.txt"
execution_status="${evidence_dir}/execution-status.txt"
result_path="${evidence_dir}/result.json"
manifest_before="${evidence_dir}/production-manifest-before.sha256"
manifest_after="${evidence_dir}/production-manifest-after.sha256"
simulator_manifest="${evidence_dir}/simulator-verFiles.dat"
simulator_identity="${evidence_dir}/simulator-identity.json"
cleanup_identity="${evidence_dir}/runtime-cleanup.json"

runtime_base="${repo_root}/.github/runtime-artifacts/owner-b-latency-sensitivity"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
mkdir -p -- "${evidence_dir}" "${logs_dir}" "${selection_dir}" \
  "${source_dir}" "${runtime_base}" "$(dirname -- "${lock_path}")" || exit 1
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[owner-b-latency] RV64 engineering lane is occupied' >&2
  exit 3
fi
runtime_dir=$(mktemp -d "${runtime_base}/run.XXXXXX") || exit 1
build_dir="${runtime_dir}/build"
build_log_full="${runtime_dir}/build-full.log"
l0_dir="${runtime_dir}/l0"
simulator="${build_dir}/NpcSimTop"
generated_base="${source_dir}/AxiDpiSlaveOwnerBDelayBase.sv"

owner_receipt="${repo_root}/.github/task-runs/2026-08-08-rv64-v15x-owner-timing-f72e-a1/evidence/owner-timing-workload-ab/result.json"
causal_receipt="${repo_root}/.github/task-runs/2026-08-08-rv64-v15x-owner-timing-causal-analysis-f72e-a1/evidence/owner-timing-causal-analysis/result.json"
selector="${repo_root}/npc/rv64/eval/ppa/evidence/optimization-slice-current.json"
selector_policy="${repo_root}/npc/rv64/design/arch/optimization-slice-selector-policy-v1.json"
selector_catalog="${repo_root}/npc/rv64/eval/ppa/optimization-slices-current.json"
selector_research="${repo_root}/.github/task-runs/2026-08-08-rv64-v15x-owner-timing-causal-analysis-f72e-a1/evidence/optimization-research-state-causal-analysis-f72e-v1.json"
original_slave="${repo_root}/npc/rv64/vsrc/sim/AxiDpiSlave.sv"
wrapper="${repo_root}/npc/rv64/eval/ppa/instrumentation/AxiDpiSlaveOwnerBDelayProbe.sv"
wrapper_tb="${repo_root}/npc/rv64/eval/ppa/instrumentation/tb_axi_dpi_owner_b_delay_probe.sv"
make_fragment="${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-b-latency-sensitivity.mk"
owner_make_fragment="${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing.mk"
owner_tool="${repo_root}/npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py"
causal_tool="${repo_root}/npc/rv64/eval/ppa/tools/owner_timing_causal_analysis.py"
selector_tool="${repo_root}/npc/rv64/eval/ppa/tools/optimization_slice_selector.py"
tool="${repo_root}/npc/rv64/eval/ppa/tools/owner_b_latency_sensitivity.py"
tool_test="${repo_root}/npc/rv64/eval/ppa/tests/test_owner_b_latency_sensitivity.py"
status_helper="${repo_root}/scripts/task-run-status.sh"
coremark_image=
dhrystone_image=

active_pid=
cleanup_rc=0
finalized=0
build_bytes_deleted=0

source "${status_helper}"
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
    printf '\n[owner-b-latency] ... bounded build-log middle omitted ...\n'
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
      printf '%s\n' "[owner-b-latency] refusing cleanup target: ${resolved}" >&2
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
    task_run_status_stage exit-trap
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}

trap 'forward_signal HUP 129' HUP
trap 'forward_signal INT 130' INT
trap 'forward_signal TERM 143' TERM
trap finalize_on_exit EXIT

run_l0() {
  local vvp_bin
  mkdir -p -- "${l0_dir}" || return 1
  vvp_bin="$(dirname -- "$(command -v iverilog)")/vvp"
  [[ -x "${vvp_bin}" ]] || vvp_bin=$(command -v vvp) || return 1
  iverilog -g2012 -Wall -DOOO_ASSERT \
    -I "${repo_root}/npc/rv64/vsrc" \
    -I "${repo_root}/npc/rv64/vsrc/include" \
    -s tb_axi_dpi_owner_b_delay_probe \
    -o "${l0_dir}/probe.vvp" "${wrapper_tb}" "${wrapper}" \
    >"${evidence_dir}/l0-compile.log" 2>&1 || return 1
  "${vvp_bin}" "${l0_dir}/probe.vvp" +owner_b_delay_cycles=0 \
    >"${evidence_dir}/l0-delay0.log" 2>&1 || return 1
  "${vvp_bin}" "${l0_dir}/probe.vvp" +owner_b_delay_cycles=2 \
    >"${evidence_dir}/l0-delay2.log" 2>&1 || return 1
  grep -Fq '[OWNER-B-LATENCY-WRAPPER][PASS] configured=0 observed=0 non_b_passthrough=1' \
    "${evidence_dir}/l0-delay0.log" || return 1
  grep -Fq '[OWNER-B-LATENCY-WRAPPER][PASS] configured=2 observed=2 non_b_passthrough=1' \
    "${evidence_dir}/l0-delay2.log" || return 1
  if "${vvp_bin}" "${l0_dir}/probe.vvp" \
      >"${evidence_dir}/l0-missing-plusarg.log" 2>&1; then
    return 1
  fi
  if "${vvp_bin}" "${l0_dir}/probe.vvp" +owner_b_delay_cycles=1 \
      >"${evidence_dir}/l0-invalid-delay.log" 2>&1; then
    return 1
  fi
  grep -Fq 'missing +owner_b_delay_cycles=<0|2>' \
    "${evidence_dir}/l0-missing-plusarg.log" || return 1
  grep -Fq 'unsupported delay_cycles=1' \
    "${evidence_dir}/l0-invalid-delay.log" || return 1
}

run_region() {
  local stage=$1
  local workload=$2
  local delay=$3
  local repetition=$4
  local image=$5
  local start_pc=$6
  local end_pc=$7
  local max_cycles=$8
  local timeout_seconds=$9
  local output=${10}
  local rc=0
  local assertion_markers=0
  task_run_status_stage "${stage}"
  setsid /usr/bin/env \
    NPC_REGION_START_PC="${start_pc}" \
    NPC_REGION_END_PC="${end_pc}" \
    /usr/bin/timeout --signal=TERM --kill-after=15s \
      "${timeout_seconds}s" "${simulator}" "${image}" \
      "+owner_b_delay_cycles=${delay}" \
      --batch --no-vga --max-cycles="${max_cycles}" >"${output}" 2>&1 &
  active_pid=$!
  wait "${active_pid}" || rc=$?
  active_pid=
  if [[ -f "${output}" ]]; then
    assertion_markers=$(grep -Eic \
      '%Error|Assertion failed|\[CHECK-FAIL\]|\[OWNER-B-LATENCY-[A-Z-]+\]\[FAIL\]' \
      "${output}" || true)
  fi
  if [[ "${rc}" -ne 0 || ! -f "${output}" ||
        $(stat -c '%s' "${output}") -gt 1048576 ||
        "${assertion_markers}" -ne 0 ]]; then
    return 1
  fi
  printf 'delay=%s workload=%s repetition=%s rc=0 assertion_markers=0\n' \
    "${delay}" "${workload}" "${repetition}" >>"${execution_status}"
}

preflight_rc=1
l0_rc=1
manifest_rc=1
source_rc=1
build_rc=1
simulator_identity_rc=1
execution_rc=1
postflight_rc=1
cleanup_capture_rc=1
receipt_rc=1
verify_rc=1

task_run_status_stage preflight-inputs
preflight_rc=0
for input in "${owner_receipt}" "${causal_receipt}" "${selector}" \
  "${selector_policy}" "${selector_catalog}" "${selector_research}" \
  "${original_slave}" "${wrapper}" "${wrapper_tb}" "${make_fragment}" \
  "${owner_make_fragment}" "${owner_tool}" "${causal_tool}" \
  "${selector_tool}" "${tool}" "${tool_test}" "${status_helper}"; do
  if [[ ! -f "${input}" || -L "${input}" ]]; then
    preflight_rc=1
  fi
done
for command_name in cmp find flock grep iverilog jq make python3 realpath \
  sed sha256sum sort stat timeout vvp xargs; do
  command -v "${command_name}" >/dev/null || preflight_rc=1
done

if [[ "${preflight_rc}" -eq 0 ]]; then
  python3 -B "${owner_tool}" verify --input "${owner_receipt}" \
    >"${evidence_dir}/owner-receipt-pre.log" 2>&1 || preflight_rc=$?
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  python3 -B "${causal_tool}" verify --input "${causal_receipt}" \
    >"${evidence_dir}/causal-receipt-pre.log" 2>&1 || preflight_rc=$?
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  python3 -B "${selector_tool}" verify --input "${selector}" \
    >"${evidence_dir}/selector-pre.log" 2>&1 || preflight_rc=$?
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  jq -e '.selected_slice.id == "measure.owner-b-latency-sensitivity"' \
    "${selector}" >/dev/null || preflight_rc=$?
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  cp -- "${selector}" "${selection_dir}/optimization-slice-current.json"
  cp -- "${selector_policy}" "${selection_dir}/selector-policy.json"
  cp -- "${selector_catalog}" "${selection_dir}/slice-catalog.json"
  cp -- "${selector_research}" "${selection_dir}/research-state.json"
  cmp -s "${selector}" "${selection_dir}/optimization-slice-current.json" || preflight_rc=1
  cmp -s "${selector_policy}" "${selection_dir}/selector-policy.json" || preflight_rc=1
  cmp -s "${selector_catalog}" "${selection_dir}/slice-catalog.json" || preflight_rc=1
  cmp -s "${selector_research}" "${selection_dir}/research-state.json" || preflight_rc=1
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  coremark_image=$(python3 -B "${owner_tool}" resolve-image \
    --baseline "${repo_root}/npc/rv64/eval/ppa/evidence/performance-baseline-current.json" \
    --contract "${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-contract-v1.json" \
    --profile "${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-validation-profile-v1.json" \
    --workload coremark) || preflight_rc=$?
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  dhrystone_image=$(python3 -B "${owner_tool}" resolve-image \
    --baseline "${repo_root}/npc/rv64/eval/ppa/evidence/performance-baseline-current.json" \
    --contract "${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-contract-v1.json" \
    --profile "${repo_root}/npc/rv64/eval/ppa/instrumentation/owner-timing-validation-profile-v1.json" \
    --workload dhrystone_10000) || preflight_rc=$?
fi

if [[ "${preflight_rc}" -eq 0 ]]; then
  task_run_status_stage l0-wrapper-contract
  python3 -B -m unittest -v \
    npc.rv64.eval.ppa.tests.test_owner_b_latency_sensitivity \
    >"${evidence_dir}/tool-unit-tests.log" 2>&1
  l0_rc=$?
  if [[ "${l0_rc}" -eq 0 ]]; then
    run_l0 || l0_rc=$?
  fi
fi

if [[ "${preflight_rc}" -eq 0 && "${l0_rc}" -eq 0 ]]; then
  production_identity >"${manifest_before}" || manifest_rc=$?
  if [[ -s "${manifest_before}" ]]; then
    manifest_rc=0
  fi
fi

if [[ "${manifest_rc}" -eq 0 ]]; then
  task_run_status_stage source-substitution
  sed '0,/^module AxiDpiSlave (/s//module AxiDpiSlaveOwnerBDelayBase (/' \
    "${original_slave}" >"${generated_base}" || source_rc=$?
  if [[ -s "${generated_base}" ]]; then
    python3 -B "${tool}" validate-source \
      --original "${original_slave}" --generated "${generated_base}" \
      >"${evidence_dir}/source-substitution.log" 2>&1
    source_rc=$?
  fi
fi

if [[ "${source_rc}" -eq 0 ]]; then
  task_run_status_stage diagnostic-simulator-build
  setsid /usr/bin/timeout --signal=TERM --kill-after=20s 900s \
    make -C "${repo_root}/npc/rv64" -f Makefile \
      -f eval/ppa/instrumentation/owner-timing.mk \
      -f eval/ppa/instrumentation/owner-b-latency-sensitivity.mk \
      CONFIG_NPC_OOO_STATS=y BUILD_DIR="${build_dir}" \
      OWNER_B_LATENCY_BASE="${generated_base}" \
      VERILATOR_BUILD_JOBS=1 >"${build_log_full}" 2>&1 &
  active_pid=$!
  build_rc=0
  wait "${active_pid}" || build_rc=$?
  active_pid=
  bounded_log "${build_log_full}" "${evidence_dir}/diagnostic-build.log" || build_rc=1
  if [[ "${build_rc}" -eq 0 && -x "${simulator}" &&
        -s "${build_dir}/obj_dir/VNpcSimTop__verFiles.dat" ]]; then
    cp -- "${build_dir}/obj_dir/VNpcSimTop__verFiles.dat" "${simulator_manifest}"
    build_bytes_deleted=$(du -sb "${runtime_dir}" | awk '{print $1}')
    python3 -B "${tool}" capture-simulator \
      --simulator "${simulator}" \
      --verilator-manifest "${simulator_manifest}" \
      --original-slave "${original_slave}" \
      --generated-base "${generated_base}" \
      --wrapper "${wrapper}" \
      --make-fragment "${make_fragment}" \
      --owner-make-fragment "${owner_make_fragment}" \
      --output "${simulator_identity}" \
      >"${evidence_dir}/simulator-identity.log" 2>&1
    simulator_identity_rc=$?
  fi
fi

if [[ "${simulator_identity_rc}" -eq 0 ]]; then
  : >"${execution_status}"
  execution_rc=0
  for delay in 0 2; do
    for repetition in 1 2 3; do
      run_region "coremark-delay${delay}-rep${repetition}" coremark \
        "${delay}" "${repetition}" "${coremark_image}" \
        0x00000000800017a8 0x00000000800017b0 \
        7000000 480 \
        "${logs_dir}/coremark-delay${delay}-rep${repetition}.log" || {
          execution_rc=$?
          break 2
        }
    done
    for repetition in 1 2 3; do
      run_region "dhrystone-delay${delay}-rep${repetition}" dhrystone_10000 \
        "${delay}" "${repetition}" "${dhrystone_image}" \
        0x0000000080000334 0x000000008000047c \
        14000000 780 \
        "${logs_dir}/dhrystone-delay${delay}-rep${repetition}.log" || {
          execution_rc=$?
          break 2
        }
    done
  done
fi

if [[ "${execution_rc}" -eq 0 ]]; then
  task_run_status_stage production-manifest-postflight
  production_identity >"${manifest_after}" || manifest_rc=$?
  if [[ "${manifest_rc}" -eq 0 ]] && ! cmp -s "${manifest_before}" "${manifest_after}"; then
    manifest_rc=1
  fi
fi

if [[ "${execution_rc}" -eq 0 && "${manifest_rc}" -eq 0 ]]; then
  task_run_status_stage evidence-postflight
  postflight_rc=0
  python3 -B "${owner_tool}" verify --input "${owner_receipt}" \
    >"${evidence_dir}/owner-receipt-post.log" 2>&1 || postflight_rc=$?
  if [[ "${postflight_rc}" -eq 0 ]]; then
    python3 -B "${causal_tool}" verify --input "${causal_receipt}" \
      >"${evidence_dir}/causal-receipt-post.log" 2>&1 || postflight_rc=$?
  fi
  if [[ "${postflight_rc}" -eq 0 ]]; then
    python3 -B "${selector_tool}" verify --input "${selector}" \
      >"${evidence_dir}/selector-post.log" 2>&1 || postflight_rc=$?
  fi
fi

task_run_status_stage runtime-cleanup
if [[ -e "${runtime_dir}" ]]; then
  cleanup_runtime || cleanup_rc=$?
fi
if [[ -e "${runtime_dir}" ]]; then
  cleanup_rc=1
fi
rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
if [[ "${cleanup_rc}" -eq 0 && "${build_bytes_deleted}" -gt 0 ]]; then
  python3 -B "${tool}" capture-cleanup \
    --runtime-dir "${runtime_dir}" --deleted-bytes "${build_bytes_deleted}" \
    --output "${cleanup_identity}" >"${evidence_dir}/runtime-cleanup.log" 2>&1
  cleanup_capture_rc=$?
fi

if [[ "${postflight_rc}" -eq 0 && "${cleanup_capture_rc}" -eq 0 ]]; then
  task_run_status_stage receipt-build
  python3 -B "${tool}" build \
    --owner-receipt "${owner_receipt}" \
    --causal-receipt "${causal_receipt}" \
    --selector "${selection_dir}/optimization-slice-current.json" \
    --selector-policy "${selection_dir}/selector-policy.json" \
    --selector-catalog "${selection_dir}/slice-catalog.json" \
    --selector-research "${selection_dir}/research-state.json" \
    --production-manifest "${manifest_before}" \
    --simulator-identity "${simulator_identity}" \
    --cleanup "${cleanup_identity}" \
    --execution-status "${execution_status}" \
    --execution-checker "${tool}" \
    --execution-runner "${repo_root}/npc/rv64/eval/ppa/run-owner-b-latency-sensitivity.sh" \
    --coremark-delay0-log "${logs_dir}/coremark-delay0-rep1.log" \
    --coremark-delay0-log "${logs_dir}/coremark-delay0-rep2.log" \
    --coremark-delay0-log "${logs_dir}/coremark-delay0-rep3.log" \
    --dhrystone-delay0-log "${logs_dir}/dhrystone-delay0-rep1.log" \
    --dhrystone-delay0-log "${logs_dir}/dhrystone-delay0-rep2.log" \
    --dhrystone-delay0-log "${logs_dir}/dhrystone-delay0-rep3.log" \
    --coremark-delay2-log "${logs_dir}/coremark-delay2-rep1.log" \
    --coremark-delay2-log "${logs_dir}/coremark-delay2-rep2.log" \
    --coremark-delay2-log "${logs_dir}/coremark-delay2-rep3.log" \
    --dhrystone-delay2-log "${logs_dir}/dhrystone-delay2-rep1.log" \
    --dhrystone-delay2-log "${logs_dir}/dhrystone-delay2-rep2.log" \
    --dhrystone-delay2-log "${logs_dir}/dhrystone-delay2-rep3.log" \
    --output "${result_path}" >"${evidence_dir}/receipt-build.log" 2>&1
  receipt_rc=$?
fi

if [[ "${receipt_rc}" -eq 0 ]]; then
  task_run_status_stage receipt-verify
  python3 -B "${tool}" verify --input "${result_path}" \
    >"${evidence_dir}/receipt-verify.log" 2>&1
  verify_rc=$?
fi

printf '%s\n' \
  "preflight_rc=${preflight_rc}" \
  "l0_rc=${l0_rc}" \
  "manifest_rc=${manifest_rc}" \
  "source_rc=${source_rc}" \
  "build_rc=${build_rc}" \
  "simulator_identity_rc=${simulator_identity_rc}" \
  "execution_rc=${execution_rc}" \
  "postflight_rc=${postflight_rc}" \
  "cleanup_rc=${cleanup_rc}" \
  "cleanup_capture_rc=${cleanup_capture_rc}" \
  "receipt_rc=${receipt_rc}" \
  "verify_rc=${verify_rc}" \
  "build_bytes_deleted=${build_bytes_deleted}" \
  >"${command_status}"

command_rc=1
if [[ "${preflight_rc}" -eq 0 && "${l0_rc}" -eq 0 &&
      "${manifest_rc}" -eq 0 && "${source_rc}" -eq 0 &&
      "${build_rc}" -eq 0 && "${simulator_identity_rc}" -eq 0 &&
      "${execution_rc}" -eq 0 && "${postflight_rc}" -eq 0 &&
      "${cleanup_rc}" -eq 0 && "${cleanup_capture_rc}" -eq 0 &&
      "${receipt_rc}" -eq 0 && "${verify_rc}" -eq 0 &&
      -s "${result_path}" ]]; then
  command_rc=0
  task_run_status_stage evidence-complete
  task_run_status_mark_evidence_complete
fi

finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
