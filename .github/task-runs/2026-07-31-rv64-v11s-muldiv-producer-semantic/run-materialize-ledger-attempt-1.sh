#!/usr/bin/env bash
set -u -o pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
attempt_root="${run_root}/evidence/materialize-ledger-attempt-1"
evidence_ledger="${run_root}/evidence/ledger-attempt-5/producer-holder-semantic-coverage.json"
live_ledger=npc/rv64/design/arch/producer-holder-semantic-coverage.json
expected_old_sha=587b4f1562de0c053597994991e2af695fd267e4466261ba1c7c29e6e281f097

if [[ -e "${attempt_root}" ]]; then
  printf 'refusing to overwrite %s\n' "${attempt_root}" >&2
  exit 2
fi

mkdir -p "${attempt_root}"
printf 'RUNNING\n' >"${attempt_root}/runner.status"

old_sha="$(sha256sum "${live_ledger}" | cut -d' ' -f1)"
printf '%s\n' "${old_sha}" >"${attempt_root}/live-before.sha256"
if [[ "${old_sha}" != "${expected_old_sha}" ]]; then
  printf 'FAIL rc=1 stage=precondition\n' >"${attempt_root}/runner.status"
  exit 1
fi

python3 npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  verify --input "${evidence_ledger}" \
  >"${attempt_root}/evidence-verify.stdout.log" \
  2>"${attempt_root}/evidence-verify.stderr.log"
evidence_rc=$?
printf '%d\n' "${evidence_rc}" >"${attempt_root}/evidence-verify.rc"
if [[ ${evidence_rc} -ne 0 ]]; then
  printf 'FAIL rc=%d stage=evidence-verify\n' "${evidence_rc}" \
    >"${attempt_root}/runner.status"
  exit "${evidence_rc}"
fi

python3 npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  build --output "${live_ledger}" \
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
  verify --input "${live_ledger}" \
  >"${attempt_root}/live-verify.stdout.log" \
  2>"${attempt_root}/live-verify.stderr.log"
live_rc=$?
printf '%d\n' "${live_rc}" >"${attempt_root}/live-verify.rc"
if [[ ${live_rc} -ne 0 ]]; then
  printf 'FAIL rc=%d stage=live-verify\n' "${live_rc}" \
    >"${attempt_root}/runner.status"
  exit "${live_rc}"
fi

cmp "${evidence_ledger}" "${live_ledger}" \
  >"${attempt_root}/cmp.stdout.log" \
  2>"${attempt_root}/cmp.stderr.log"
cmp_rc=$?
printf '%d\n' "${cmp_rc}" >"${attempt_root}/cmp.rc"
if [[ ${cmp_rc} -ne 0 ]]; then
  printf 'FAIL rc=%d stage=exact-match\n' "${cmp_rc}" \
    >"${attempt_root}/runner.status"
  exit "${cmp_rc}"
fi

sha256sum "${live_ledger}" >"${attempt_root}/live-after.sha256"
printf 'PASS rc=0\n' >"${attempt_root}/runner.status"
