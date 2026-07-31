#!/usr/bin/env bash
set -u -o pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
attempt_root="${run_root}/evidence/focused-attempt-4"

if [[ -e "${attempt_root}" ]]; then
  printf 'refusing to overwrite %s\n' "${attempt_root}" >&2
  exit 2
fi

python3 npc/rv64/testbench/scripts/run_v11s_muldiv_producer_semantic.py \
  --result-dir "${attempt_root}"
