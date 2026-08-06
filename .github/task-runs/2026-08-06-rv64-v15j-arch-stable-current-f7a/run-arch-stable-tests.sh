#!/usr/bin/env bash
set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_root="$repo_root/.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a"
status_path="$task_root/arch-stable-tests.status"
log_path="$task_root/evidence/arch-stable-tests.log"

printf '%s\n' 'RUNNING suite=arch-stable-contract' >"$status_path"
cd "$repo_root/npc/rv64/eval/ppa/tests"
set +e
PYTHONPATH="$repo_root" python3 -B -m unittest \
  test_arch_stable_freeze \
  test_arch_stable_current_candidate \
  test_functional_archive_rehydrate -v \
  >"$log_path" 2>&1
rc=$?
set -e
if [[ "$rc" -eq 0 ]] && grep -Fq 'Ran 77 tests' "$log_path" \
    && grep -Fq 'OK' "$log_path"; then
  printf '%s\n' 'PASS suite=arch-stable-contract tests=77' >"$status_path"
else
  printf 'FAIL rc=%s suite=arch-stable-contract\n' "$rc" >"$status_path"
fi
exit "$rc"
