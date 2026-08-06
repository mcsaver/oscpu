#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_id=2026-08-06-rv64-v15j-di5-current-f7a
source_task_id=2026-08-06-rv64-v15j-arch-stable-current-f7a
asset_dir=${repo_root}/.github/task-runs/2026-07-20-rv64-v8u-dual-memory-sustained-issue
adapter_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8u-dual-memory-sustained-current.patch
temporary_runner=$(mktemp /tmp/v8u-current-runner.XXXXXX.sh)

cleanup() {
  case "${temporary_runner}" in
    /tmp/v8u-current-runner.*.sh) rm -f -- "${temporary_runner}" ;;
  esac
}
trap cleanup EXIT

(
  cd -- "${asset_dir}"
  patch --silent -p0 -o "${temporary_runner}" < "${adapter_patch}"
)

env \
  V8U_ASSET_DIR="${asset_dir}" \
  V8U_CURRENT_ADAPTER_PATCH="${adapter_patch}" \
  V8U_SCOPED_REFRESH_MODE=1 \
  V8U_F2_REPLAY_SOURCE_ROOT="${repo_root}/.github/task-runs/${source_task_id}/evidence" \
  V8U_EVIDENCE_DIR="${repo_root}/.github/task-runs/${task_id}/evidence/di5-current" \
  V8U_MUTATION_DIR="${repo_root}/.github/task-runs/${task_id}/evidence/di5-mutations" \
  V8U_ARCH_MANIFEST="${repo_root}/.github/task-runs/${task_id}/evidence/architecture-current.json" \
  V8U_ARCH_LOG="${repo_root}/.github/task-runs/${task_id}/evidence/dual-memory-issue.log" \
  bash "${temporary_runner}"
