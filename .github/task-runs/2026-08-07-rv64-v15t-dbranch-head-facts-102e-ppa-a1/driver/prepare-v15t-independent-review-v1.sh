#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
run_rel=".github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1"
contract_rel="${run_rel}/subagent-contracts/v15t-dbranch-head-facts-independent-review-v1.json"

cd "${repo_root}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id v15t-dbranch-head-facts-independent-review-v1 \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 OooFrontendDispatchGate 的 dbranch_dual_go 入口合同：移除 post-mux dispatch0/1_unsupported_raw_i 后，head classifier、fetch fault、system/exit/control 与 backend ready/valid 事实是否仍完整；同时核验 102e 的定向 TB、compile-success mutation、L0/L1 与同配置 5ns mapped PPA 证据能否支持保留 engineering candidate。' \
  --allow-path npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v \
  --allow-path npc/rv64/vsrc/frontend/OooFrontend.v \
  --allow-path npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v \
  --allow-path npc/rv64/vsrc/frontend/OooFrontendBackendDispatchMux.v \
  --allow-path npc/rv64/vsrc/decode/OooAluDecodeBackend.v \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/testbench/tests/tb_ooo_frontend_dispatch_gate.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_ifu_lane1_fault_owner.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_fp_legality_dispatch_path.sv \
  --allow-path npc/rv64/testbench/scripts/run_v15t_dbranch_head_facts_mutation.sh \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path .github/task-runs/2026-08-07-rv64-v15t-e7da-named-timing-path-a1/evidence \
  --allow-path .github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-l1-a1 \
  --allow-path "${run_rel}/evidence" \
  --allow-path "${run_rel}/driver/compare-e7da-102e-top40-v1.py" \
  --allow-path "${contract_rel}" \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command sha256sum \
  --allow-read-command 'git status' \
  --allow-read-command 'git diff' \
  --deliverable '给出独立 RTL 复核：列出任何具体 correctness/evidence blocker；若无 blocker，明确说明候选可保留但 5ns 仍 GAP；核对 L0 原始 FAIL 与 replay PASS 的处置、mutation 灵敏度、Top40 结构变化、未知项、替代解释、回滚条件与下一路径范围。' \
  --success-criterion '首行按“RV64 RTL 对象→周期/配置→TB/EDA 观测→PASS/GAP 范围”组织；结论必须区分功能合同 PASS、engineering candidate 保留与 5ns/signoff GAP，并提供实际文件名和 marker，不弱化断言或用路径去重掩盖事件。' \
  --out "${contract_rel}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate "${contract_rel}"
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render "${contract_rel}"
