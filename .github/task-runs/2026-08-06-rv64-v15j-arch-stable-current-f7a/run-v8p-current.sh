#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_id=2026-08-06-rv64-v15j-arch-stable-current-f7a
asset_dir=${repo_root}/.github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners
adapter_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8p-pair-matrix-current.patch
temporary_runner=$(mktemp /tmp/v8p-current-runner.XXXXXX.sh)

cleanup() {
  case "${temporary_runner}" in
    /tmp/v8p-current-runner.*.sh) rm -f -- "${temporary_runner}" ;;
  esac
}
trap cleanup EXIT

(
  cd -- "${asset_dir}"
  patch --silent -p0 -o "${temporary_runner}" < "${adapter_patch}"
)

env \
  V8P_ASSET_DIR="${asset_dir}" \
  V8P_CURRENT_ADAPTER_PATCH="${adapter_patch}" \
  V8P_TASK_RUN_ID="${task_id}" \
  V8P_EVIDENCE_DIR="${repo_root}/.github/task-runs/${task_id}/evidence/di3-current" \
  V8P_ARCH_MANIFEST="${repo_root}/.github/task-runs/${task_id}/evidence/architecture-current.json" \
  V8P_ARCH_LOG="${repo_root}/.github/task-runs/${task_id}/evidence/pair-matrix.log" \
  bash "${temporary_runner}"
