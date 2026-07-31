#!/usr/bin/env bash
set -u -o pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
attempt_root="${run_root}/evidence/self-test-attempt-6"

if [[ -e "${attempt_root}" ]]; then
  printf 'refusing to overwrite %s\n' "${attempt_root}" >&2
  exit 2
fi

mkdir -p "${attempt_root}"
printf 'RUNNING\n' >"${attempt_root}/runner.status"
python3 npc/rv64/testbench/scripts/test_run_v11s_muldiv_producer_semantic.py -v \
  >"${attempt_root}/stdout.log" \
  2>"${attempt_root}/stderr.log"
rc=$?
printf '%d\n' "${rc}" >"${attempt_root}/runner.rc"
if [[ ${rc} -eq 0 ]]; then
  printf 'PASS rc=0\n' >"${attempt_root}/runner.status"
else
  printf 'FAIL rc=%d\n' "${rc}" >"${attempt_root}/runner.status"
fi
exit "${rc}"
