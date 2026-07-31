#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11s-muldiv-producer-semantic
attempt_root="${run_root}/final-static-gates-attempt-1"
status_path="${run_root}/final-static-gates-attempt-1.status"

if [[ -e "${attempt_root}" ]]; then
  printf 'refusing to overwrite %s\n' "${attempt_root}" >&2
  exit 2
fi

mkdir -p "${attempt_root}"
printf 'RUNNING\n' >"${status_path}"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${attempt_root}/runner.rc"
  if [[ ${rc} -eq 0 ]]; then
    printf 'PASS rc=0\n' >"${attempt_root}/runner.status"
    printf 'PASS rc=0\n' >"${status_path}"
  else
    printf 'FAIL rc=%d\n' "${rc}" >"${attempt_root}/runner.status"
    printf 'FAIL rc=%d\n' "${rc}" >"${status_path}"
  fi
}
trap finish EXIT

check_sha256() {
  expected=$1
  path=$2
  actual=$(sha256sum "${path}")
  actual=${actual%% *}
  if [[ "${actual}" != "${expected}" ]]; then
    printf 'sha256 mismatch path=%s expected=%s actual=%s\n' \
      "${path}" "${expected}" "${actual}" >&2
    return 1
  fi
  printf 'sha256 PASS %s %s\n' "${actual}" "${path}"
}

printf '%s\n' '[V11S-FINAL-STATIC] python syntax'
python3 -m py_compile \
  npc/rv64/testbench/scripts/run_v11s_muldiv_producer_semantic.py \
  npc/rv64/testbench/scripts/test_run_v11s_muldiv_producer_semantic.py \
  npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py \
  npc/rv64/eval/ppa/tools/load_queue_producer_checker_replay.py \
  npc/rv64/eval/ppa/tests/test_load_queue_producer_checker_replay.py \
  npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py

printf '%s\n' '[V11S-FINAL-STATIC] runner unit 10/10'
python3 npc/rv64/testbench/scripts/test_run_v11s_muldiv_producer_semantic.py -v

printf '%s\n' '[V11S-FINAL-STATIC] graph unit 19/19'
python3 npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py -v

printf '%s\n' '[V11S-FINAL-STATIC] replay unit 6/6'
python3 npc/rv64/eval/ppa/tests/test_load_queue_producer_checker_replay.py -v

printf '%s\n' '[V11S-FINAL-STATIC] semantic unit 85/85'
python3 npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py -v

printf '%s\n' '[V11S-FINAL-STATIC] reviewer contract'
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  validate \
  "${run_root}/subagent-contracts/v11s-muldiv-producer-final-review.json"

printf '%s\n' '[V11S-FINAL-STATIC] JSON documents'
python3 -m json.tool \
  "${run_root}/subagent-contracts/v11s-muldiv-producer-final-review.json" \
  >/dev/null
python3 -m json.tool \
  "${run_root}/evidence/focused-attempt-4/summary.json" \
  >/dev/null
python3 -m json.tool \
  "${run_root}/evidence/current-instance-graph-rebind-attempt-1/holder-instance-graph.json" \
  >/dev/null
python3 -m json.tool \
  "${run_root}/evidence/current-instance-graph-rebind-attempt-1/instance-graph-frozen-audit.json" \
  >/dev/null
python3 -m json.tool \
  "${run_root}/evidence/ledger-attempt-9/producer-holder-semantic-coverage.json" \
  >/dev/null
python3 -m json.tool \
  "${run_root}/evidence/v11h-checker-replay-after-graph-attempt-9-receipt.json" \
  >/dev/null
python3 -m json.tool \
  npc/rv64/design/arch/producer-holder-census.json \
  >/dev/null
python3 -m json.tool \
  npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json \
  >/dev/null
python3 -m json.tool \
  npc/rv64/design/arch/producer-holder-semantic-coverage.json \
  >/dev/null

printf '%s\n' '[V11S-FINAL-STATIC] immutable evidence bindings'
cmp -s \
  "${run_root}/evidence/focused-attempt-4/source-before.sha256" \
  "${run_root}/evidence/focused-attempt-4/source-after.sha256"
cmp -s \
  "${run_root}/evidence/ledger-attempt-9/producer-holder-semantic-coverage.json" \
  npc/rv64/design/arch/producer-holder-semantic-coverage.json
test "$(tr -d '\r\n' <"${run_root}/evidence/combined-semantic-gate-attempt-3/runner.rc")" = "0"
test "$(tr -d '\r\n' <"${run_root}/evidence/current-instance-graph-rebind-attempt-1/runner.rc")" = "0"
test "$(tr -d '\r\n' <"${run_root}/evidence/current-instance-graph-rebind-attempt-1/frozen-audit.rc")" = "0"

check_sha256 \
  2eb4984961fe34bdac751ae2dfb455de7c9256dd03bab4c31e25de0948a8e93b \
  "${run_root}/evidence/focused-attempt-4/summary.json"
check_sha256 \
  bc77764cc3367fdbf28c0babe90f12c56ef527c382d1ac8b44a49a9fdc7ef62d \
  "${run_root}/evidence/current-instance-graph-rebind-attempt-1/holder-instance-graph.json"
check_sha256 \
  dc638594e064d18b0d965291ef8f9e514bbab9442d9629347b32de160a2312af \
  "${run_root}/evidence/current-instance-graph-rebind-attempt-1/instance-graph-frozen-audit.json"
check_sha256 \
  80d50ba80916a4823479748cfa69dc4ecea1a4025abf50ff3414caa0a7205944 \
  "${run_root}/evidence/ledger-attempt-9/producer-holder-semantic-coverage.json"
check_sha256 \
  3a405dd3e95542676aafe1258eb4deda11267d88f968518c61cb474356070833 \
  "${run_root}/evidence/v11h-checker-replay-after-graph-attempt-9-receipt.json"

printf '%s\n' '[V11S-FINAL-STATIC] production and test source identity'
git diff --quiet -- \
  npc/rv64/vsrc/execute/OooIntBackend.v \
  npc/rv64/vsrc/execute/OooMulDivUnit.v \
  npc/rv64/vsrc/include/define.v
check_sha256 \
  49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a \
  npc/rv64/vsrc/execute/OooIntBackend.v
check_sha256 \
  c28ad0cf4a00644d906261cc05a6194cc78474afa9f70f8183a6bf996ba38eed \
  npc/rv64/vsrc/execute/OooMulDivUnit.v
check_sha256 \
  1ce15faee558f1814ad66303bb63c612fe5026475a198979662aa564c0682694 \
  npc/rv64/vsrc/include/define.v
check_sha256 \
  252c0df06384d2863c18265d843ad0434eafee163fd4b190ec59d1ed443090af \
  npc/rv64/testbench/tests/tb_ooo_int_backend.sv
check_sha256 \
  9c4b1d7b95caf7aac7228566a0f662dc772dab655ed7cd6da540a7d0d58e3d5a \
  npc/rv64/testbench/Makefile
check_sha256 \
  842d1c89f83b431a716a47a53fae0595eaf7bea9111157195396d5209af23c89 \
  npc/rv64/testbench/tests/tb_ooo_int_backend_v11s_muldiv_producer.svh
check_sha256 \
  74b7277b89e269945d44c08460dfce036a32ea7c18f0467b885077b69c39fd1f \
  npc/rv64/testbench/tests/tb_ooo_muldiv_unit.sv
check_sha256 \
  3ab6ffba4b4d31d8b89623e7ba09c936254bff45488004e6a98322c81e698160 \
  npc/rv64/testbench/scripts/run_v11s_muldiv_producer_semantic.py
check_sha256 \
  2766e5828105cbe238ace25d7c416eae2d48cc82599436eeda341952cb436685 \
  npc/rv64/testbench/scripts/test_run_v11s_muldiv_producer_semantic.py

printf '%s\n' '[V11S-FINAL-STATIC] scoped whitespace'
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

printf '%s\n' '[V11S-FINAL-STATIC][PASS]'
