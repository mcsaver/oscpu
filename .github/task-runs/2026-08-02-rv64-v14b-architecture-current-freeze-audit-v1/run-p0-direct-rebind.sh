#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1"
evidence_dir="${run_dir}/evidence/p0-direct-rebind-1"
status_path="${run_dir}/p0-direct-rebind-1.status"
driver_log="${evidence_dir}/driver.log"
mem_dir="${evidence_dir}/mem"
ptw_dir="${evidence_dir}/ptw"
module_dir="${evidence_dir}/module-aggregate"
mem_runner="${repo_root}/.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/run-memory-lifecycle-variants.py"
ptw_runner="${repo_root}/.github/task-runs/2026-07-22-rv64-v9k-ptw-pmp-current-design/run-ptw-pmp-variants.py"
mem_temp_dir=
ptw_temp_dir=
finalized=0
cleanup_rc=0

if [[ -e "${evidence_dir}" || -e "${status_path}" ]]; then
  printf '%s\n' "[V14B-P0-DIRECT-REBIND][FAIL] output already exists" >&2
  exit 2
fi
mkdir -p "${evidence_dir}"
exec > >(tee -a "${driver_log}") 2>&1

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_one() {
  local target=$1
  local prefix=$2
  local resolved
  [[ -n "${target}" && -e "${target}" ]] || return 0
  resolved=$(realpath -m -- "${target}") || return 1
  if [[ "${resolved}" != /tmp/${prefix}.* ]]; then
    printf '%s\n' "refusing unexpected RTL compile cleanup target: ${resolved}" >&2
    return 2
  fi
  rm -rf -- "${resolved}"
}

cleanup_all() {
  cleanup_one "${mem_temp_dir}" rv64-memory-lifecycle-v9f || cleanup_rc=$?
  cleanup_one "${ptw_temp_dir}" rv64-ptw-pmp-v9k || cleanup_rc=$?
}

finalize_on_exit() {
  local command_rc=$?
  cleanup_all
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

run_step() {
  local stage=$1
  shift
  task_run_status_stage "${stage}"
  "$@"
}

main() {
  mem_temp_dir=$(mktemp -d /tmp/rv64-memory-lifecycle-v9f.XXXXXXXX) || return $?
  ptw_temp_dir=$(mktemp -d /tmp/rv64-ptw-pmp-v9k.XXXXXXXX) || return $?
  mkdir -p \
    "${mem_dir}/focused/mem-issue" \
    "${mem_dir}/focused/miq-flush" \
    "${mem_dir}/mutations" \
    "${ptw_dir}/focused" \
    "${ptw_dir}/mutations" \
    "${module_dir}"

  run_step "mem-issue-focused" \
    make -B -C "${repo_root}/npc/rv64/testbench" \
      TESTS=tb_ooo_int_backend \
      "RESULT_DIR=${mem_dir}/focused/mem-issue" \
      "BUILD_DIR=${mem_temp_dir}/mem-build" \
      TB_IVFLAGS_tb_ooo_int_backend=-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED \
      run || return $?

  run_step "miq-flush-focused" \
    make -B -C "${repo_root}/npc/rv64/testbench" \
      TESTS=tb_ooo_mem_inflight_queue \
      "RESULT_DIR=${mem_dir}/focused/miq-flush" \
      "BUILD_DIR=${mem_temp_dir}/miq-build" \
      run || return $?

  run_step "ptw-pmp-focused" \
    make -B -C "${repo_root}/npc/rv64/testbench" \
      TESTS="tb_ooo_fetch_axi_bridge tb_ooo_mem_axi_bridge" \
      "RESULT_DIR=${ptw_dir}/focused" \
      "BUILD_DIR=${ptw_temp_dir}/focused-build" \
      run || return $?

  run_step "shared-module-aggregate" \
    make -B -C "${repo_root}/npc/rv64/testbench" \
      "RESULT_DIR=${module_dir}" \
      "BUILD_DIR=${mem_temp_dir}/module-build" \
      run || return $?

  run_step "normalize-mem-issue-log" \
    python3 -B "${mem_runner}" --root "${repo_root}" \
      --normalize-log-dir "${mem_dir}/focused/mem-issue/logs" \
      --transient-dir "${mem_temp_dir}" || return $?
  run_step "normalize-miq-log" \
    python3 -B "${mem_runner}" --root "${repo_root}" \
      --normalize-log-dir "${mem_dir}/focused/miq-flush/logs" \
      --transient-dir "${mem_temp_dir}" || return $?
  run_step "normalize-module-logs" \
    python3 -B "${mem_runner}" --root "${repo_root}" \
      --normalize-log-dir "${module_dir}/logs" \
      --transient-dir "${mem_temp_dir}" || return $?
  run_step "normalize-ptw-logs" \
    python3 -B "${ptw_runner}" --root "${repo_root}" \
      --normalize-log-dir "${ptw_dir}/focused/logs" \
      --transient-dir "${ptw_temp_dir}" || return $?

  run_step "mem-issue-compile-success-variants" \
    python3 -B "${mem_runner}" --root "${repo_root}" \
      --output "${mem_dir}/mutations/summary.json" || return $?
  run_step "ptw-pmp-compile-success-variants" \
    python3 -B "${ptw_runner}" --root "${repo_root}" \
      --output "${ptw_dir}/mutations/summary.json" || return $?

  run_step "mem-issue-evidence" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/memory_issue_lifecycle_evidence.py" \
      --root "${repo_root}" \
      --mem-log "${mem_dir}/focused/mem-issue/logs/tb_ooo_int_backend.log" \
      --miq-log "${mem_dir}/focused/miq-flush/logs/tb_ooo_mem_inflight_queue.log" \
      --module-summary "${module_dir}/summary.txt" \
      --mutation-summary "${mem_dir}/mutations/summary.json" \
      --output "${evidence_dir}/memory-issue-lifecycle-current.json" \
      --raw-log "${evidence_dir}/memory-issue-lifecycle.log" || return $?

  run_step "ptw-pmp-evidence" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/ptw_pmp_evidence.py" \
      --root "${repo_root}" \
      --ifu-log "${ptw_dir}/focused/logs/tb_ooo_fetch_axi_bridge.log" \
      --lsu-log "${ptw_dir}/focused/logs/tb_ooo_mem_axi_bridge.log" \
      --module-summary "${module_dir}/summary.txt" \
      --variant-summary "${ptw_dir}/mutations/summary.json" \
      --output "${evidence_dir}/ptw-pmp-current.json" \
      --raw-log "${evidence_dir}/ptw-pmp.log" || return $?

  run_step "evidence-tool-unit-tests" \
    python3 -B -m unittest \
      npc.rv64.eval.ppa.tests.test_memory_issue_lifecycle_evidence \
      npc.rv64.eval.ppa.tests.test_ptw_pmp_evidence -v || return $?

  run_step "post-rtl-directed-check" \
    python3 -B "${repo_root}/npc/rv64/eval/ppa/tools/architecture_hard_gates.py" \
      --repo-root "${repo_root}" \
      --evidence-manifest "${run_dir}/evidence/replay-1/current-directed-nine-gate-replay.json" \
      --output "${evidence_dir}/source-post-result.json" || return $?

  run_step "receipt" \
    python3 -B "${run_dir}/build-p0-direct-rebind-receipt.py" \
      --evidence-dir "${evidence_dir}" \
      --output "${evidence_dir}/rebind-receipt.json" || return $?
  return 0
}

main
command_rc=$?
task_run_status_stage "cleanup-rtl-build-products"
cleanup_all
if [[ -e "${mem_temp_dir}" || -e "${ptw_temp_dir}" ]]; then
  cleanup_rc=1
fi

task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 &&
      -s "${evidence_dir}/rebind-receipt.json" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
