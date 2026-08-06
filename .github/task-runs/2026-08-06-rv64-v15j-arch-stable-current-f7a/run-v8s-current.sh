#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_id=2026-08-06-rv64-v15j-arch-stable-current-f7a
asset_dir=${repo_root}/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration
adapter_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8s-dual-memory-core-current.patch
checker=${repo_root}/npc/rv64/eval/ppa/tools/v8s_dual_memory_core_current.py
checker_test=${repo_root}/npc/rv64/eval/ppa/tests/test_v8s_dual_memory_core_current.py
mutator=${repo_root}/npc/rv64/eval/ppa/tools/v8s_dual_memory_core_mutator_current.py
temporary_runner=$(mktemp /tmp/v8s-current-runner.XXXXXX.sh)

cleanup() {
  case "${temporary_runner}" in
    /tmp/v8s-current-runner.*.sh) rm -f -- "${temporary_runner}" ;;
  esac
}
trap cleanup EXIT

(
  cd -- "${asset_dir}"
  patch --silent -p0 -o "${temporary_runner}" < "${adapter_patch}"
)

env \
  V8S_ASSET_DIR="${asset_dir}" \
  V8S_CURRENT_ADAPTER_PATCH="${adapter_patch}" \
  V8S_CURRENT_CHECKER="${checker}" \
  V8S_CURRENT_CHECKER_TEST="${checker_test}" \
  V8S_CURRENT_MUTATOR="${mutator}" \
  V8S_SCOPED_REFRESH_MODE=1 \
  V8S_EVIDENCE_DIR="${repo_root}/.github/task-runs/${task_id}/evidence/f2-current" \
  V8S_ARCH_MANIFEST="${repo_root}/.github/task-runs/${task_id}/evidence/architecture-current.json" \
  bash "${temporary_runner}"
