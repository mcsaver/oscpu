#!/usr/bin/env bash
set -euo pipefail

run_root=".github/task-runs/2026-07-31-rv64-v11q-int-lane0-completion-resolve-packet-semantic"
status_path="${run_root}/final-static-gates.status"

write_status() {
  local gate_rc=$?
  printf '%s\n' "${gate_rc}" > "${status_path}"
}
trap write_status EXIT

printf '%s\n' '[V11Q-FINAL-STATIC] runner-unit begin'
make -C npc/rv64/testbench v11q-int-lane0-packet-self-test

printf '%s\n' '[V11Q-FINAL-STATIC] contract begin'
make -C npc/rv64 check-contract

printf '%s\n' '[V11Q-FINAL-STATIC] json begin'
python3 -m json.tool "${run_root}/attempt-ledger.json" >/dev/null
python3 -m json.tool "${run_root}/round-state.json" >/dev/null

printf '%s\n' '[V11Q-FINAL-STATIC] scoped-diff begin'
git diff --check -- \
  npc/rv64/Makefile \
  npc/rv64/design/arch/producer-holder-census.json \
  npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json \
  npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  npc/rv64/eval/ppa/tools/load_queue_producer_checker_replay.py \
  npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  npc/rv64/testbench/Makefile \
  npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  npc/rv64/testbench/scripts/run_v11q_int_lane0_packet_semantic.py \
  npc/rv64/testbench/scripts/test_run_v11q_int_lane0_packet_semantic.py

printf '%s\n' '[V11Q-FINAL-STATIC] production-rtl-binding begin'
git diff --quiet -- \
  npc/rv64/vsrc/execute/OooIntBackend.v \
  npc/rv64/vsrc/pipeline/PipeStageReg.v \
  npc/rv64/vsrc/include/define.v
sha256sum \
  npc/rv64/vsrc/execute/OooIntBackend.v \
  npc/rv64/vsrc/pipeline/PipeStageReg.v \
  npc/rv64/vsrc/include/define.v

printf '%s\n' '[V11Q-FINAL-STATIC][PASS]'
