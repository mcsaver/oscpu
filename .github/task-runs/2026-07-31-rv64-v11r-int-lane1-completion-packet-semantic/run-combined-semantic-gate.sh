#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic
status_path="${run_root}/combined-semantic-gate.status"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${status_path}"
}
trap finish EXIT

printf 'RUNNING\n' >"${status_path}"
make -C npc/rv64 check-producer-holder-semantic-coverage
