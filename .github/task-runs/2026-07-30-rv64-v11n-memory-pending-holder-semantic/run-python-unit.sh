#!/usr/bin/env bash
set -uo pipefail

run_root=".github/task-runs/2026-07-30-rv64-v11n-memory-pending-holder-semantic"
evidence_dir="${run_root}/evidence/python-unit-current"
status_path="${run_root}/python-unit.status"

mkdir -p "${evidence_dir}"
printf 'RUNNING stage=runner-unit\n' > "${status_path}"
python3 \
  npc/rv64/testbench/scripts/test_run_v11n_memory_pending_holder_semantic.py \
  -q > "${evidence_dir}/runner-unit.log" 2>&1
runner_rc=$?

if [[ ${runner_rc} -ne 0 ]]; then
  printf 'FAIL stage=runner-unit rc=%d\n' "${runner_rc}" > "${status_path}"
  exit "${runner_rc}"
fi

printf 'RUNNING stage=semantic-unit\n' > "${status_path}"
python3 \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  -q > "${evidence_dir}/semantic-unit.log" 2>&1
semantic_rc=$?

if [[ ${semantic_rc} -ne 0 ]]; then
  printf 'FAIL stage=semantic-unit rc=%d\n' "${semantic_rc}" > "${status_path}"
  exit "${semantic_rc}"
fi

printf 'PASS runner=6 semantic=58 rc=0\n' > "${status_path}"
