#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
status_path="${run_root}/brief-post-memory.status"
output_path="${run_root}/brief-post-memory.json"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${run_root}/brief-post-memory.rc"
  if [[ "${rc}" -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

if [[ -e "${output_path}" ]]; then
  printf 'refusing to overwrite %s\n' "${output_path}" >&2
  exit 73
fi

printf 'RUNNING\n' >"${status_path}"
python3 scripts/github_index_db.py brief \
  OooMulDivUnit producer lifecycle \
  --profile npc-dev \
  --focus-scope non-history \
  --max-tokens 2400 \
  --json \
  >"${output_path}" \
  2>"${run_root}/brief-post-memory.stderr.log"
