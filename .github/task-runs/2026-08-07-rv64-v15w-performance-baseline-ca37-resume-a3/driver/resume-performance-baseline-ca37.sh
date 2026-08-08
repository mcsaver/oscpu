#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir=${repo_root}/.github/task-runs/2026-08-07-rv64-v15w-performance-baseline-ca37-resume-a3
source_run=${repo_root}/.github/task-runs/2026-08-07-rv64-v15w-performance-baseline-ca37-a5
source_evidence=${source_run}/evidence/performance-baseline-current
evidence_dir=${run_dir}/evidence/performance-baseline-current-resume-a3
logs_dir=${evidence_dir}/logs
inputs_dir=${evidence_dir}/inputs
status_path=${run_dir}/performance-baseline-current-resume-a3.status
command_status=${evidence_dir}/command-status.txt
manifest_path=${evidence_dir}/run-manifest.json
result_path=${evidence_dir}/result.json
build_log=${evidence_dir}/stats-off-build.log

arch_stable_result=${repo_root}/npc/rv64/eval/ppa/evidence/arch-stable-current.json
baseline_contract=${repo_root}/npc/rv64/design/arch/performance-baseline-contract-v3.json
measurement_contract=${repo_root}/npc/rv64/design/arch/performance-measurement-contract-v2.json
counter_schema=${repo_root}/npc/rv64/design/arch/performance-counter-schema-v4.json
boundary_amendment=${repo_root}/npc/rv64/design/arch/performance-boundary-qualification-amendment-v2.json
workload_matrix=${repo_root}/npc/rv64/design/arch/performance-workload-matrix-v1.json
policy=${repo_root}/npc/rv64/eval/ppa/policies/performance-baseline-f7-v1.json
tool=${repo_root}/npc/rv64/eval/ppa/tools/performance_baseline_current.py
arch_tool=${repo_root}/npc/rv64/eval/ppa/tools/arch_stable_freeze.py
stats_on_simulator=${repo_root}/.github/task-runs/2026-08-07-rv64-v15w-ca37-l01-refresh-a1/evidence/functional/frozen/NpcSimTop
coremark_image=${repo_root}/.github/task-runs/2026-08-07-rv64-v15w-ca37-l01-refresh-a1/evidence/functional/images/benchmarks/coremark.bin
dhrystone_image=${repo_root}/.github/task-runs/2026-08-07-rv64-v15w-ca37-l01-refresh-a1/evidence/functional/images/benchmarks/dhrystone.bin
config_path=${repo_root}/npc/rv64/.config

runtime_root=${repo_root}/.github/runtime-artifacts/rv64-performance-baseline-run
lock_path=${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock
build_dir=${runtime_root}/2026-08-07-rv64-v15w-performance-baseline-ca37-resume-a3/stats-off-build
stats_off_build_binary=${build_dir}/NpcSimTop
stats_off_simulator=${inputs_dir}/NpcSimTop-stats-off
build_owned=0
cleanup_rc=0
finalized=0

source ${repo_root}/scripts/task-run-status.sh
mkdir -p -- ${logs_dir} ${inputs_dir} $(dirname -- ${lock_path}) ${runtime_root}
exec 9>${lock_path}
if ! flock -n 9; then
  printf '%s\n' '[performance-baseline-resume] RV64 engineering lane is occupied' >&2
  exit 3
fi
task_run_status_init ${status_path}
task_run_status_install_signal_traps

cleanup_build() {
  local resolved_build expected_build
  if [[ ${build_owned} -ne 1 || ! -e ${build_dir} ]]; then
    return 0
  fi
  resolved_build=$(realpath -m -- ${build_dir}) || return 1
  expected_build=$(realpath -m -- ${runtime_root}/2026-08-07-rv64-v15w-performance-baseline-ca37-resume-a3/stats-off-build) || return 1
  if [[ ${resolved_build} != ${expected_build} || ${resolved_build} == ${runtime_root} ]]; then
    printf '%s\n' "[performance-baseline-resume] refusing unexpected cleanup target: ${resolved_build}" >&2
    return 2
  fi
  rm -r -- ${resolved_build}
}

finalize_on_exit() {
  local command_rc=$?
  if [[ ${build_owned} -eq 1 && -e ${build_dir} ]]; then
    cleanup_build || cleanup_rc=$?
  fi
  if [[ ${finalized} -eq 0 ]]; then
    task_run_status_stage exit-trap
    task_run_status_finalize ${command_rc} ${cleanup_rc} || true
  fi
}
trap finalize_on_exit EXIT

run_region() {
  local label=$1
  local simulator=$2
  local image=$3
  local start_pc=$4
  local stop_pc=$5
  local max_cycles=$6
  local timeout_seconds=$7
  local output=$8
  task_run_status_stage ${label}
  NPC_REGION_START_PC=${start_pc} NPC_REGION_END_PC=${stop_pc} \
    /usr/bin/timeout --signal=TERM --kill-after=10s ${timeout_seconds}s \
      ${simulator} ${image} --batch --no-vga --max-cycles=${max_cycles} \
      >${output} 2>&1
}

preflight_rc=1
source_rc=1
stats_off_build_rc=1
stats_off_rc=1
manifest_rc=1
precheck_rc=1
postflight_rc=1
bind_rc=1
build_rc=1
verify_rc=1
build_bytes=0

task_run_status_stage preflight-arch-stable
python3 -B ${arch_tool} verify ${arch_stable_result} --require-stable \
  >${evidence_dir}/arch-stable-pre.log 2>&1
preflight_rc=$?
if [[ ${preflight_rc} -eq 0 ]]; then
  task_run_status_stage preflight-exact-input-binding
  python3 -B ${tool} preflight \
    --output ${evidence_dir}/input-preflight.json \
    --arch-stable-result ${arch_stable_result} \
    --baseline-contract ${baseline_contract} \
    --measurement-contract ${measurement_contract} \
    --counter-schema ${counter_schema} \
    --boundary-qualification-amendment ${boundary_amendment} \
    --workload-matrix ${workload_matrix} \
    --policy ${policy} \
    --simulator ${stats_on_simulator} \
    --config ${config_path} \
    --coremark-image ${coremark_image} \
    --dhrystone-image ${dhrystone_image} \
    >${evidence_dir}/input-preflight.log 2>&1
  preflight_rc=$?
fi

if [[ ${preflight_rc} -eq 0 ]]; then
  task_run_status_stage bind-completed-stats-on-source
  if [[ $(tr -d '\r\n' <${source_run}/performance-baseline-current.status) == \
        'FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0' ]] &&
     grep -qx 'preflight_rc=0' ${source_evidence}/command-status.txt &&
     grep -qx 'stats_on_rc=0' ${source_evidence}/command-status.txt &&
     grep -qx 'stats_off_build_rc=2' ${source_evidence}/command-status.txt &&
     [[ -s ${source_evidence}/logs/coremark-stats-on-rep1.log ]] &&
     [[ -s ${source_evidence}/logs/coremark-stats-on-rep2.log ]] &&
     [[ -s ${source_evidence}/logs/coremark-stats-on-rep3.log ]] &&
     [[ -s ${source_evidence}/logs/dhrystone-stats-on-rep1.log ]] &&
     [[ -s ${source_evidence}/logs/dhrystone-stats-on-rep2.log ]] &&
     [[ -s ${source_evidence}/logs/dhrystone-stats-on-rep3.log ]]; then
    sha256sum \
      ${source_run}/performance-baseline-current.status \
      ${source_evidence}/command-status.txt \
      ${source_evidence}/logs/coremark-stats-on-rep1.log \
      ${source_evidence}/logs/coremark-stats-on-rep2.log \
      ${source_evidence}/logs/coremark-stats-on-rep3.log \
      ${source_evidence}/logs/dhrystone-stats-on-rep1.log \
      ${source_evidence}/logs/dhrystone-stats-on-rep2.log \
      ${source_evidence}/logs/dhrystone-stats-on-rep3.log \
      >${evidence_dir}/stats-on-source.sha256
    source_rc=$?
  fi
fi

if [[ ${source_rc} -eq 0 ]]; then
  task_run_status_stage stats-off-single-build
  mkdir -p -- ${build_dir}
  build_owned=1
  printf '%s\n' ${run_dir} >${build_dir}/.performance-baseline-owner
  printf '%s\n' 'VERILATOR_FLAGS += -Wno-PINCONNECTEMPTY' | \
    make -C ${repo_root}/npc/rv64 -f Makefile -f - \
    BUILD_DIR=${build_dir} CONFIG_NPC_OOO_STATS=n \
    VERILATOR_BUILD_JOBS=1 ${stats_off_build_binary} >${build_log} 2>&1
  stats_off_build_rc=$?
  if [[ ${stats_off_build_rc} -eq 0 && -x ${stats_off_build_binary} ]]; then
    build_bytes=$(du -sb ${build_dir} | awk '{print $1}')
    install -m 0755 ${stats_off_build_binary} ${stats_off_simulator}
    stats_off_build_rc=$?
  fi
fi

if [[ ${stats_off_build_rc} -eq 0 ]]; then
  stats_off_rc=0
  run_region coremark-stats-off ${stats_off_simulator} ${coremark_image} \
    0x00000000800017a8 0x00000000800017b0 6000000 300 \
    ${logs_dir}/coremark-stats-off.log || stats_off_rc=$?
  if [[ ${stats_off_rc} -eq 0 ]]; then
    run_region dhrystone-stats-off ${stats_off_simulator} ${dhrystone_image} \
      0x0000000080000334 0x000000008000047c 12000000 420 \
      ${logs_dir}/dhrystone-stats-off.log || stats_off_rc=$?
  fi
fi

if [[ ${stats_off_rc} -eq 0 ]]; then
  task_run_status_stage manifest
  python3 -B ${tool} manifest \
    --output ${manifest_path} \
    --arch-stable-result ${arch_stable_result} \
    --baseline-contract ${baseline_contract} \
    --measurement-contract ${measurement_contract} \
    --counter-schema ${counter_schema} \
    --boundary-qualification-amendment ${boundary_amendment} \
    --workload-matrix ${workload_matrix} \
    --policy ${policy} \
    --simulator ${stats_on_simulator} \
    --config ${config_path} \
    --coremark-image ${coremark_image} \
    --dhrystone-image ${dhrystone_image} \
    --coremark-log ${source_evidence}/logs/coremark-stats-on-rep1.log \
    --coremark-log ${source_evidence}/logs/coremark-stats-on-rep2.log \
    --coremark-log ${source_evidence}/logs/coremark-stats-on-rep3.log \
    --dhrystone-log ${source_evidence}/logs/dhrystone-stats-on-rep1.log \
    --dhrystone-log ${source_evidence}/logs/dhrystone-stats-on-rep2.log \
    --dhrystone-log ${source_evidence}/logs/dhrystone-stats-on-rep3.log \
    --stats-off-simulator ${stats_off_simulator} \
    --coremark-stats-off-log ${logs_dir}/coremark-stats-off.log \
    --dhrystone-stats-off-log ${logs_dir}/dhrystone-stats-off.log \
    >${evidence_dir}/manifest.log 2>&1
  manifest_rc=$?
fi

if [[ ${manifest_rc} -eq 0 ]]; then
  task_run_status_stage baseline-precheck
  python3 -B ${tool} precheck --manifest ${manifest_path} \
    --output ${evidence_dir}/precheck.json >${evidence_dir}/precheck.log 2>&1
  precheck_rc=$?
fi

if [[ ${precheck_rc} -eq 0 ]]; then
  task_run_status_stage postflight-arch-stable
  python3 -B ${arch_tool} verify ${arch_stable_result} --require-stable \
    >${evidence_dir}/arch-stable-post.log 2>&1
  postflight_rc=$?
fi

if [[ ${postflight_rc} -eq 0 ]]; then
  task_run_status_stage bind-postflight
  python3 -B ${tool} bind-postflight --manifest ${manifest_path} \
    --postflight-log ${evidence_dir}/arch-stable-post.log \
    --output ${manifest_path} >${evidence_dir}/bind-postflight.log 2>&1
  bind_rc=$?
fi

if [[ ${bind_rc} -eq 0 ]]; then
  task_run_status_stage baseline-build
  python3 -B ${tool} build --manifest ${manifest_path} \
    --output ${result_path} --require-baseline >${evidence_dir}/build.log 2>&1
  build_rc=$?
fi

task_run_status_stage cleanup-stats-off-build
if [[ ${build_owned} -eq 1 && -e ${build_dir} ]]; then
  cleanup_build || cleanup_rc=$?
fi
if [[ -e ${build_dir} ]]; then
  cleanup_rc=1
fi

if [[ ${build_rc} -eq 0 && ${cleanup_rc} -eq 0 ]]; then
  task_run_status_stage canonical-verify
  python3 -B ${tool} verify --input ${result_path} --require-baseline \
    >${evidence_dir}/verify.log 2>&1
  verify_rc=$?
fi

printf '%s\n' \
  "preflight_rc=${preflight_rc}" \
  "stats_on_source_rc=${source_rc}" \
  "stats_off_build_rc=${stats_off_build_rc}" \
  "stats_off_rc=${stats_off_rc}" \
  "manifest_rc=${manifest_rc}" \
  "precheck_rc=${precheck_rc}" \
  "postflight_rc=${postflight_rc}" \
  "bind_rc=${bind_rc}" \
  "build_rc=${build_rc}" \
  "verify_rc=${verify_rc}" \
  "cleanup_rc=${cleanup_rc}" \
  "stats_off_build_bytes_deleted=${build_bytes}" \
  >${command_status}

command_rc=1
if [[ ${preflight_rc} -eq 0 && ${source_rc} -eq 0 &&
      ${stats_off_build_rc} -eq 0 && ${stats_off_rc} -eq 0 &&
      ${manifest_rc} -eq 0 && ${precheck_rc} -eq 0 &&
      ${postflight_rc} -eq 0 && ${bind_rc} -eq 0 &&
      ${build_rc} -eq 0 && ${verify_rc} -eq 0 &&
      ${cleanup_rc} -eq 0 && -s ${result_path} ]]; then
  command_rc=0
fi

task_run_status_stage evidence-complete
if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize ${command_rc} ${cleanup_rc}
