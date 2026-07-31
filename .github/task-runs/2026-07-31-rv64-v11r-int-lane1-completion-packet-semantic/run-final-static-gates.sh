#!/usr/bin/env bash
set -euo pipefail

run_root=.github/task-runs/2026-07-31-rv64-v11r-int-lane1-completion-packet-semantic
status_path="${run_root}/final-static-gates.status"

finish() {
  rc=$?
  printf '%d\n' "${rc}" >"${status_path}"
}
trap finish EXIT

printf '%s\n' '[V11R-FINAL-STATIC] runner-unit begin'
make -C npc/rv64/testbench v11r-int-lane1-packet-self-test

printf '%s\n' '[V11R-FINAL-STATIC] repository-contract begin'
make -C npc/rv64 check-contract

printf '%s\n' '[V11R-FINAL-STATIC] reviewer-contract begin'
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  validate \
  "${run_root}/subagent-contracts/v11r-int-lane1-packet-final-review.json"

printf '%s\n' '[V11R-FINAL-STATIC] python-json begin'
python3 -m py_compile \
  npc/rv64/testbench/scripts/run_v11r_int_lane1_packet_semantic.py \
  npc/rv64/testbench/scripts/test_run_v11r_int_lane1_packet_semantic.py \
  npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  npc/rv64/eval/ppa/tools/load_queue_producer_checker_replay.py \
  npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py
python3 -m json.tool "${run_root}/attempt-ledger.json" >/dev/null
python3 -m json.tool "${run_root}/round-state.json" >/dev/null
python3 -m json.tool \
  "${run_root}/subagent-contracts/v11r-int-lane1-packet-final-review.json" \
  >/dev/null

printf '%s\n' '[V11R-FINAL-STATIC] scoped-diff begin'
git diff --check -- \
  npc/rv64/Makefile \
  npc/rv64/design/arch/producer-holder-census.json \
  npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json \
  npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  npc/rv64/eval/ppa/tools/load_queue_producer_checker_replay.py \
  npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  npc/rv64/testbench/Makefile \
  npc/rv64/testbench/tests/tb_ooo_int_backend.sv

printf '%s\n' '[V11R-FINAL-STATIC] production-rtl-binding begin'
git diff --quiet -- \
  npc/rv64/vsrc/execute/OooIntBackend.v \
  npc/rv64/vsrc/pipeline/PipeStageReg.v \
  npc/rv64/vsrc/include/define.v
sha256sum \
  npc/rv64/vsrc/execute/OooIntBackend.v \
  npc/rv64/vsrc/pipeline/PipeStageReg.v \
  npc/rv64/vsrc/include/define.v

printf '%s\n' '[V11R-FINAL-STATIC][PASS]'
