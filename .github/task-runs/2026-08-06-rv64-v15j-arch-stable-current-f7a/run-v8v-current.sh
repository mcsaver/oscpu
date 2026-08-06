#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_id=2026-08-06-rv64-v15j-arch-stable-current-f7a
asset_dir=${repo_root}/.github/task-runs/2026-07-21-rv64-v8v-memory-ordering
adapter_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8v-memory-ordering-current.patch
current_f2_mutator=${repo_root}/npc/rv64/eval/ppa/tools/v8s_dual_memory_core_mutator_current.py
temporary_runner=$(mktemp /tmp/v8v-current-runner.XXXXXX.sh)

cleanup() {
  case "${temporary_runner}" in
    /tmp/v8v-current-runner.*.sh) rm -f -- "${temporary_runner}" ;;
  esac
}
trap cleanup EXIT

(
  cd -- "${asset_dir}"
  patch --silent -p0 -o "${temporary_runner}" < "${adapter_patch}"
)

env \
  V8V_ASSET_DIR="${asset_dir}" \
  V8V_CURRENT_ADAPTER_PATCH="${adapter_patch}" \
  V8V_CURRENT_F2_MUTATOR="${current_f2_mutator}" \
  V8V_SCOPED_REFRESH_MODE=1 \
  V8V_EVIDENCE_DIR="${repo_root}/.github/task-runs/${task_id}/evidence/ooo3-current" \
  V8V_MUTATION_OUTPUT_DIR="${repo_root}/.github/task-runs/${task_id}/evidence/lq-mutations" \
  V8V_ARCH_MANIFEST="${repo_root}/.github/task-runs/${task_id}/evidence/architecture-current.json" \
  V8V_ARCH_LOG="${repo_root}/.github/task-runs/${task_id}/evidence/memory-ordering.log" \
  V8V_F2_EVIDENCE_DIR="${repo_root}/.github/task-runs/${task_id}/evidence/f2-current" \
  bash "${temporary_runner}"
