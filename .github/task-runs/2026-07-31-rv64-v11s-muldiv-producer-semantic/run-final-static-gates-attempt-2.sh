#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
status_path="${run_root}/final-static-gates-attempt-2.status"

printf 'RUNNING\n' >"${status_path}"

finish() {
  rc=$?
  if [[ ${rc} -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

check_sha256() {
  expected=$1
  path=$2
  actual=$(sha256sum "${path}")
  actual=${actual%% *}
  [[ "${actual}" == "${expected}" ]]
  printf 'sha256 PASS %s %s\n' "${actual}" "${path}"
}

printf '%s\n' '[V11S-FINAL-STATIC-A2] final JSON'
python3 -m json.tool "${run_root}/attempt-ledger.json" >/dev/null
python3 -m json.tool "${run_root}/round-state.json" >/dev/null
python3 -m json.tool "${run_root}/verification-receipt.json" >/dev/null
python3 -m json.tool \
  "${run_root}/subagent-contracts/v11s-muldiv-producer-final-review.json" \
  >/dev/null

printf '%s\n' '[V11S-FINAL-STATIC-A2] stored documents'
for doc in \
  contract.md \
  implementation-result.md \
  test-disposition.md \
  final-review-result.md \
  completion-definition.md \
  task-report.md \
  dispatch-log.md \
  evidence-map.md
do
  python3 scripts/github_index_db.py load \
    --source stored \
    --path "${run_root}/${doc}" \
    >/dev/null
done

printf '%s\n' '[V11S-FINAL-STATIC-A2] terminal gate receipts'
grep -qx 'PASS rc=0' "${run_root}/final-static-gates-attempt-1.status"
grep -qx 'PASS rc=0' "${run_root}/task-doc-publish-attempt-2.status"
grep -qx 'PASS rc=0' "${run_root}/db-audits-attempt-2.status"
grep -qx 'PASS rc=0' "${run_root}/index-evidence.status"
grep -qx 'PASS rc=0' "${run_root}/scoped-strict-guard-attempt-1.status"
grep -qx 'PASS rc=0' "${run_root}/npc-dev-e2e.status"

printf '%s\n' '[V11S-FINAL-STATIC-A2] canonical bindings'
cmp -s \
  "${run_root}/evidence/ledger-attempt-9/producer-holder-semantic-coverage.json" \
  npc/rv64/design/arch/producer-holder-semantic-coverage.json
git diff --quiet -- \
  npc/rv64/vsrc/execute/OooIntBackend.v \
  npc/rv64/vsrc/execute/OooMulDivUnit.v \
  npc/rv64/vsrc/include/define.v
check_sha256 \
  2eb4984961fe34bdac751ae2dfb455de7c9256dd03bab4c31e25de0948a8e93b \
  "${run_root}/evidence/focused-attempt-4/summary.json"
check_sha256 \
  80d50ba80916a4823479748cfa69dc4ecea1a4025abf50ff3414caa0a7205944 \
  npc/rv64/design/arch/producer-holder-semantic-coverage.json
check_sha256 \
  49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a \
  npc/rv64/vsrc/execute/OooIntBackend.v
check_sha256 \
  c28ad0cf4a00644d906261cc05a6194cc78474afa9f70f8183a6bf996ba38eed \
  npc/rv64/vsrc/execute/OooMulDivUnit.v

printf '%s\n' '[V11S-FINAL-STATIC-A2] scoped whitespace'
git diff --check -- \
  npc/rv64/Makefile \
  npc/rv64/design/arch/producer-holder-census.json \
  npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json \
  npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py \
  npc/rv64/eval/ppa/tools/load_queue_producer_checker_replay.py \
  npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  npc/rv64/testbench/Makefile \
  npc/rv64/testbench/tests/tb_ooo_int_backend.sv

printf '%s\n' '[V11S-FINAL-STATIC-A2][PASS]'
