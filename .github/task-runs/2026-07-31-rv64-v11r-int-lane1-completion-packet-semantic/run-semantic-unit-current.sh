#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic
status_path="${run_root}/semantic-unit-current.status"

finish() {
  rc=$?
  if [[ ${rc} -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

printf 'RUNNING\n' >"${status_path}"
python3 -m unittest -q \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py
