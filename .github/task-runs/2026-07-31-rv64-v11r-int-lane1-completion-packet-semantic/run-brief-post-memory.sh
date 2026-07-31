#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic
status_path="${run_root}/brief-post-memory.status"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${status_path}"
}
trap finish EXIT

python3 scripts/github_index_db.py brief \
  OooIntBackend integer ex1 packet lane1 \
  --profile npc-dev \
  --focus-scope non-history \
  --json >"${run_root}/brief-post-memory.json"
