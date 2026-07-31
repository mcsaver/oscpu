#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
status_path="${run_root}/npc-dev-e2e.status"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${run_root}/npc-dev-e2e.rc"
  if [[ "${rc}" -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

printf 'RUNNING\n' >"${status_path}"
scripts/agent-e2e.sh \
  --profile npc-dev \
  --task-slug OooMulDivUnit-producer-lifecycle-revtag-v11s \
  --stop-on-fail \
  >"${run_root}/npc-dev-e2e.stdout.log" \
  2>"${run_root}/npc-dev-e2e.stderr.log"
