#!/usr/bin/env bash
set -u -o pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
attempt_root="${run_root}/evidence/ledger-attempt-1"
ledger_path="${attempt_root}/producer-holder-semantic-coverage.json"

if [[ -e "${attempt_root}" ]]; then
  printf 'refusing to overwrite %s\n' "${attempt_root}" >&2
  exit 2
fi

mkdir -p "${attempt_root}"
printf 'RUNNING\n' >"${attempt_root}/runner.status"

python3 -m unittest -v \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  >"${attempt_root}/unit.stdout.log" \
  2>"${attempt_root}/unit.stderr.log"
unit_rc=$?
printf '%d\n' "${unit_rc}" >"${attempt_root}/unit.rc"
if [[ ${unit_rc} -ne 0 ]]; then
  printf 'FAIL rc=%d stage=unit\n' "${unit_rc}" \
    >"${attempt_root}/runner.status"
  exit "${unit_rc}"
fi

python3 npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  build --output "${ledger_path}" \
  >"${attempt_root}/build.stdout.log" \
  2>"${attempt_root}/build.stderr.log"
build_rc=$?
printf '%d\n' "${build_rc}" >"${attempt_root}/build.rc"
if [[ ${build_rc} -ne 0 ]]; then
  printf 'FAIL rc=%d stage=build\n' "${build_rc}" \
    >"${attempt_root}/runner.status"
  exit "${build_rc}"
fi

python3 npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  verify --input "${ledger_path}" \
  >"${attempt_root}/verify.stdout.log" \
  2>"${attempt_root}/verify.stderr.log"
verify_rc=$?
printf '%d\n' "${verify_rc}" >"${attempt_root}/verify.rc"
if [[ ${verify_rc} -ne 0 ]]; then
  printf 'FAIL rc=%d stage=verify\n' "${verify_rc}" \
    >"${attempt_root}/runner.status"
  exit "${verify_rc}"
fi

printf 'PASS rc=0\n' >"${attempt_root}/runner.status"
