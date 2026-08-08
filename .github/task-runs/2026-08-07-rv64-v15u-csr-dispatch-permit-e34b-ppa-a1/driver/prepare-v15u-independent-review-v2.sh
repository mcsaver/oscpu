#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
candidate_run=.github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1
baseline_run=.github/task-runs/2026-08-07-rv64-v15t-dbranch-head-facts-102e-ppa-a1
contract_rel=${candidate_run}/subagent-contracts/v15u-csr-dispatch-permit-independent-review-v2.json

cd "${repo_root}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id v15u-csr-dispatch-permit-independent-review-v2 \
  --task-kind read-only-review \
  --goal '以干净的版本化合同补充复核本地 RV64 V15U：直接核对 OooIntBackend、OooMemOwnerTerminalCollector 与 OooMemOwnerTracker 未因 CSR dispatch permit 改变 accepted-transfer、12 ingress、duplicate fail-loud 或 holder phase 权威；确认 owner-terminal 规范公式已与 RTL 的 pending_exit 项同步；并从 102e/e34b 各自的 mapped summary、Top40、synthesis sources 与 production manifest 推导候选路径迁移及设计身份边界。不得搜索任何未列出的 task-run 根目录。' \
  --allow-path npc/rv64/vsrc/control/OooPendingSystemSequencer.v \
  --allow-path npc/rv64/vsrc/control/OooControlPlane.v \
  --allow-path npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v \
  --allow-path npc/rv64/vsrc/memory/OooMemOwnerTracker.v \
  --allow-path npc/rv64/design/specs/ooo-pending-system-sequencer.md \
  --allow-path npc/rv64/design/specs/ooo-serialize-memory-owner-terminal.md \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_terminal_collector.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_pending_system_sequencer.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_serialized_owner_exactly_once.sv \
  --allow-path .github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-focused-mutation-a1/evidence \
  --allow-path .github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-l01-a1/driver-summary.tsv \
  --allow-path .github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-l01-a1/full-core-current.status \
  --allow-path .github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-l01-a1/module-driver.log \
  --allow-path .github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-l01-a1/functional-driver.log \
  --allow-path "${baseline_run}/evidence/traceable-102e-a1/summary.json" \
  --allow-path "${baseline_run}/evidence/traceable-102e-a1/opensta-top40.rpt" \
  --allow-path "${baseline_run}/evidence/traceable-102e-a1/synthesis-sources.sha256" \
  --allow-path "${baseline_run}/evidence/traceable-102e-a1/production-manifest-before.sha256" \
  --allow-path "${baseline_run}/evidence/traceable-102e-a1/production-manifest-after.sha256" \
  --allow-path "${candidate_run}/evidence/traceable-e34b-a1/summary.json" \
  --allow-path "${candidate_run}/evidence/traceable-e34b-a1/opensta-top40.rpt" \
  --allow-path "${candidate_run}/evidence/traceable-e34b-a1/synthesis-sources.sha256" \
  --allow-path "${candidate_run}/evidence/traceable-e34b-a1/production-manifest-before.sha256" \
  --allow-path "${candidate_run}/evidence/traceable-e34b-a1/production-manifest-after.sha256" \
  --allow-path "${candidate_run}/evidence/ppa-delta-and-path-cluster-v1.json" \
  --allow-path "${candidate_run}/driver/compare-102e-e34b-v1.py" \
  --allow-path "${contract_rel}" \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command sha256sum \
  --allow-read-command 'git status' \
  --allow-read-command 'git diff' \
  --deliverable '给出 V15U v2 独立补充复核：逐项说明 collector/tracker 的 production accepted-transfer、duplicate/phase fail-loud 与事件计数合同是否保持；确认 pending_exit 规范同步；验证 102e/e34b 各自 source/production manifest 前后一致及 Top40 路径迁移。若无 correctness blocker，批准 e34b engineering candidate；仍明确 live-permit 动态覆盖、production ControlPlane 负向版本、driver-summary 状态卫生、5ns/release/signoff 等 GAP。' \
  --success-criterion '首行采用本地 RV64 module/signal→周期/配置→TB/EDA 观测→PASS/GAP；只读取逐项列出的路径，不把 task-run 目录作为 rg/git 搜索根；区分 collector 功能事件计数与 STA 路径计数；不弱化断言，不扩大到 Ubuntu、绝对功耗或 timing signoff。' \
  --out "${contract_rel}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  validate "${contract_rel}"
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  render "${contract_rel}"
