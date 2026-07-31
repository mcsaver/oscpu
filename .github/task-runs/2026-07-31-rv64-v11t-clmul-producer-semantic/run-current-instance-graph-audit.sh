#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11t-clmul-producer-semantic
attempt_root="${run_root}/evidence/current-instance-graph-audit"
status_path="${attempt_root}/runner.status"

mkdir -p "${attempt_root}"
if [[ -e "${attempt_root}/instance-graph-frozen-audit.json" ]]; then
  printf 'refusing to overwrite current instance-graph audit\n' >&2
  exit 73
fi

printf 'RUNNING\n' >"${status_path}"
finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${attempt_root}/runner.rc"
  if [[ ${rc} -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

python3 -B npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  --check-frozen \
  --json-out "${attempt_root}/instance-graph-frozen-audit.json" \
  >"${attempt_root}/stdout.log" \
  2>"${attempt_root}/stderr.log"
