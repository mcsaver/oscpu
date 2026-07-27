#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
testbench_dir="${repo_root}/npc/rv64/testbench"
result_dir="${task_run_dir}/module-flag-on"
status_path="${task_run_dir}/module-flag-on.status"
design_sha="9ac1ae14b18635cf25ea80efa7ce4cd85a07bdd6f0e525755658dc8dcd26207a"
ivflags="-g2012 -Wall -I${repo_root}/npc/rv64/vsrc -I${repo_root}/npc/rv64/vsrc/include -I${testbench_dir}/common -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1"

mkdir -p "${result_dir}"
printf '%s\n' "RUNNING" > "${status_path}"
finish() {
  local rc=$?
  if [[ "${rc}" -eq 0 ]]; then
    printf '%s\n' "PASS" > "${status_path}"
  else
    printf 'FAIL rc=%s\n' "${rc}" > "${status_path}"
  fi
  exit "${rc}"
}
trap finish EXIT

make -B -C "${testbench_dir}" \
  "BUILD_DIR=build-v9p-module-on" \
  "RESULT_DIR=${result_dir}" \
  "IVFLAGS=${ivflags}" \
  "RTL_EVIDENCE_SHA=${design_sha}" \
  summary

grep -F -- "- failed: 0" "${result_dir}/summary.txt"
grep -F -- "[RTL-DESIGN-ID] sha256:${design_sha}" \
  "${result_dir}/logs/tb_ooo_core_top_glue.log"
