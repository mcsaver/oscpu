#!/usr/bin/env bash
set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_root="$repo_root/.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a"

cd "$repo_root"
exec python3 -B npc/rv64/eval/ppa/tools/full_core_current_evidence.py \
  module \
  --output-dir "$task_root/evidence/l0-current-final" \
  --jobs 4 \
  >"$task_root/evidence/l0-current-final.driver.log" 2>&1
