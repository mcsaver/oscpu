#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
graph_root="${run_root}/evidence/current-instance-graph-rebind-attempt-1"
status_path="${graph_root}/frozen-audit.status"
audit_path="${graph_root}/instance-graph-frozen-audit.json"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${graph_root}/frozen-audit.rc"
  if [[ "${rc}" -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

if [[ -e "${audit_path}" ]]; then
  printf 'refusing to overwrite %s\n' "${audit_path}" >&2
  exit 73
fi

printf 'RUNNING\n' >"${status_path}"
python3 npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  --check-frozen \
  --json-out "${audit_path}" \
  >"${graph_root}/frozen-audit.stdout.log" \
  2>"${graph_root}/frozen-audit.stderr.log"
