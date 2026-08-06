#!/usr/bin/env bash
set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_root="$repo_root/.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a"
status_path="$task_root/semantic-tests.status"
log_path="$task_root/evidence/semantic-tests.log"

printf '%s\n' 'RUNNING suite=producer-holder-semantic-coverage' >"$status_path"
cd "$repo_root"
set +e
PYTHONPATH="$repo_root" python3 -B -m unittest \
  npc.rv64.eval.ppa.tests.test_producer_holder_semantic_coverage -v \
  >"$log_path" 2>&1
rc=$?
set -e
if [[ "$rc" -eq 0 ]] && grep -Fq 'OK' "$log_path"; then
  printf '%s\n' 'PASS suite=producer-holder-semantic-coverage' >"$status_path"
else
  printf 'FAIL rc=%s suite=producer-holder-semantic-coverage\n' "$rc" \
    >"$status_path"
fi
exit "$rc"
