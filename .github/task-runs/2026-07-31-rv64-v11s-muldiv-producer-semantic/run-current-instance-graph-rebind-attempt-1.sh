#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
attempt_root="${run_root}/evidence/current-instance-graph-rebind-attempt-1"
status_path="${attempt_root}/runner.status"

mkdir -p "${attempt_root}"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${attempt_root}/runner.rc"
  if [[ "${rc}" -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

for output in \
  holder-instance-graph.json \
  yosys-instance-graph-receipt.json \
  yosys-instance-graph.full.json.gz \
  yosys-instance-graph.ys \
  yosys-instance-graph.log; do
  if [[ -e "${attempt_root}/${output}" ]]; then
    printf 'refusing to overwrite %s\n' "${attempt_root}/${output}" >&2
    exit 73
  fi
done

printf 'RUNNING\n' >"${status_path}"
python3 npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  --elaborate \
  --json-out "${attempt_root}/holder-instance-graph.json" \
  --receipt-out "${attempt_root}/yosys-instance-graph-receipt.json" \
  --full-json-out "${attempt_root}/yosys-instance-graph.full.json.gz" \
  --script-out "${attempt_root}/yosys-instance-graph.ys" \
  --log-out "${attempt_root}/yosys-instance-graph.log" \
  >"${attempt_root}/stdout.log" \
  2>"${attempt_root}/stderr.log"
