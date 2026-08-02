#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-01-rv64-v13l-performance-counter-schema-v1"
evidence_dir="${run_dir}/evidence/compile"
build_dir="${repo_root}/npc/rv64/build-v13l-counter-check"
status_path="${run_dir}/full-build.status"
log_path="${evidence_dir}/full-build.log"
result_path="${evidence_dir}/full-build-result.json"
finalized=0
cleanup_rc=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p "${evidence_dir}"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_build() {
  local resolved_build
  resolved_build=$(realpath -m -- "${build_dir}") || return 1
  if [[ "${resolved_build}" != "/home/lyg/PA/ysyx-workbench/npc/rv64/build-v13l-counter-check" ]]; then
    printf '%s\n' "[v13l-build] refusing unexpected cleanup target: ${resolved_build}" >&2
    return 2
  fi
  rm -rf -- "${resolved_build}"
}

finalize_on_exit() {
  local command_rc=$?
  if [[ -d "${build_dir}" ]]; then
    cleanup_build || cleanup_rc=$?
  fi
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

task_run_status_stage "verilator-full-build"
mkdir -p "${build_dir}"
make -C "${repo_root}/npc/rv64" \
  BUILD_DIR="${build_dir}" \
  VERILATOR_BUILD_JOBS=1 \
  "${build_dir}/NpcSimTop" >"${log_path}" 2>&1
build_rc=$?

binary_path="${build_dir}/NpcSimTop"
binary_sha256=""
binary_bytes=0
build_bytes=0
if [[ "${build_rc}" -eq 0 && -x "${binary_path}" ]]; then
  binary_sha256=$(sha256sum "${binary_path}" | awk '{print $1}')
  binary_bytes=$(stat -c '%s' "${binary_path}")
  build_bytes=$(du -sb "${build_dir}" | awk '{print $1}')
else
  build_rc=1
fi

rtl_sha256=$(sha256sum "${repo_root}/npc/rv64/vsrc/sim/NpcSimTop.sv" | awk '{print $1}')
host_sha256=$(sha256sum "${repo_root}/npc/rv64/csrc/cpu/cpu-exec.cpp" | awk '{print $1}')
log_sha256=$(sha256sum "${log_path}" | awk '{print $1}')
log_bytes=$(stat -c '%s' "${log_path}")

task_run_status_stage "cleanup-build-products"
cleanup_build || cleanup_rc=$?
if [[ -e "${build_dir}" ]]; then
  cleanup_rc=1
fi

status_word=FAIL
if [[ "${build_rc}" -eq 0 && "${cleanup_rc}" -eq 0 ]]; then
  status_word=PASS
fi
printf '{\n' >"${result_path}"
printf '  "schema": "npc-rv64-v13l-full-build-result-v1",\n' >>"${result_path}"
printf '  "status": "%s",\n' "${status_word}" >>"${result_path}"
printf '  "command_rc": %s,\n' "${build_rc}" >>"${result_path}"
printf '  "cleanup_rc": %s,\n' "${cleanup_rc}" >>"${result_path}"
printf '  "build_products_retained": false,\n' >>"${result_path}"
printf '  "build_bytes_deleted": %s,\n' "${build_bytes}" >>"${result_path}"
printf '  "binary_sha256": "%s",\n' "${binary_sha256}" >>"${result_path}"
printf '  "binary_bytes_before_cleanup": %s,\n' "${binary_bytes}" >>"${result_path}"
printf '  "npc_sim_top_sha256": "%s",\n' "${rtl_sha256}" >>"${result_path}"
printf '  "cpu_exec_sha256": "%s",\n' "${host_sha256}" >>"${result_path}"
printf '  "compile_log_sha256": "%s",\n' "${log_sha256}" >>"${result_path}"
printf '  "compile_log_bytes": %s\n' "${log_bytes}" >>"${result_path}"
printf '}\n' >>"${result_path}"

task_run_status_stage "evidence-complete"
if [[ "${status_word}" == PASS ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${build_rc}" "${cleanup_rc}"
