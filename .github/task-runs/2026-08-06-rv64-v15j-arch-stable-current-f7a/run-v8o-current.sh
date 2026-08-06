#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_id=2026-08-06-rv64-v15j-arch-stable-current-f7a
asset_dir=${repo_root}/.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics
adapter_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8o-no-static-lane-current.patch
temporary_runner=$(mktemp /tmp/v8o-current-runner.XXXXXX.sh)

cleanup() {
  case "${temporary_runner}" in
    /tmp/v8o-current-runner.*.sh) rm -f -- "${temporary_runner}" ;;
  esac
}
trap cleanup EXIT

(
  cd -- "${asset_dir}"
  patch --silent -p0 -o "${temporary_runner}" < "${adapter_patch}"
)

env \
  V8O_ASSET_DIR="${asset_dir}" \
  V8O_CURRENT_ADAPTER_PATCH="${adapter_patch}" \
  V8O_TASK_RUN_ID="${task_id}" \
  V8O_EVIDENCE_DIR="${repo_root}/.github/task-runs/${task_id}/evidence/di4-current" \
  V8O_ARCH_MANIFEST="${repo_root}/.github/task-runs/${task_id}/evidence/architecture-current.json" \
  V8O_ARCH_LOG="${repo_root}/.github/task-runs/${task_id}/evidence/no-static-lane-semantics.log" \
  bash "${temporary_runner}"
