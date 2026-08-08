#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
run_rel=.github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-ppa-a1
contract_rel=${run_rel}/subagent-contracts/v15u-csr-dispatch-permit-independent-review-v1.json

cd "${repo_root}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id v15u-csr-dispatch-permit-independent-review-v1 \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 pending CSR 串行化事务的 V15U 注册许可合同：Cdrain 只采样 eligibility，许可跨 ready stall 保持，cancel/clear/orphan/fire/death/reset 优先清除，且 Cresolve 只能由当前 holder 元数据、许可与反馈无关的 cancel 事实形成；同时核验该边界是否保持 exact ProducerId lease、memory owner terminal/collector 合同与断言，并审查 e34b 的定向 TB、负向版本、L0/L1、5ns mapped STA、L2 mini-system 与 L3 lightweight-Linux 证据。' \
  --allow-path npc/rv64/vsrc/control/OooPendingSystemSequencer.v \
  --allow-path npc/rv64/vsrc/control/OooControlPlane.v \
  --allow-path npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  --allow-path npc/rv64/vsrc/control/OooPendingSystemAdmissionCancelGate.v \
  --allow-path npc/rv64/vsrc/control/OooCsrAccessRequestMux.v \
  --allow-path npc/rv64/vsrc/control/OooStopPendingSequencer.v \
  --allow-path npc/rv64/design/specs/ooo-pending-system-sequencer.md \
  --allow-path npc/rv64/design/specs/ooo-serialize-memory-owner-terminal.md \
  --allow-path npc/rv64/testbench/tests/tb_ooo_pending_system_sequencer.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_pending_system_lease_probe.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_serialized_owner_exactly_once.sv \
  --allow-path npc/rv64/testbench/scripts/run_v15u_csr_dispatch_permit_mutation.sh \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path .github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-focused-mutation-a1 \
  --allow-path .github/task-runs/2026-08-07-rv64-v15u-csr-dispatch-permit-e34b-l01-a1 \
  --allow-path "${run_rel}/evidence" \
  --allow-path "${run_rel}/traceable-e34b-a1.status" \
  --allow-path "${run_rel}/driver/compare-102e-e34b-v1.py" \
  --allow-path .github/task-runs/2026-08-07-rv64-v15u-e34b-l2-mini-system-all-a1 \
  --allow-path .github/task-runs/2026-08-07-rv64-v15u-e34b-l3-lightweight-linux-all-a1 \
  --allow-path "${contract_rel}" \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command sha256sum \
  --allow-read-command 'git status' \
  --allow-read-command 'git diff' \
  --deliverable '给出独立 RV64 RTL/证据复核：列出任何具体 correctness 或 evidence blocker；若无 blocker，明确说明 e34b 可作为 engineering candidate 保留但 5ns/signoff 仍为 GAP。必须核对 permit 的 arm/hold/cancel/fire/lease 时序、同沿 cancel 优先级、feedback-free valid、collector 事件逐笔保留、断言未削弱、负向版本灵敏度、L0-L3 设计身份与终端事务、STA Top40 从 owner-terminal 转移到 CSR commit/cancel 的边界、未知项、回滚条件与下一条路径范围。' \
  --success-criterion '首行按“本地 RV64 RTL 对象或证据文件 → 周期或编译配置 → testbench/EDA 观测 → PASS/GAP 范围”组织；结论严格区分功能合同 PASS、engineering candidate 保留与 5ns/release/signoff GAP，引用真实文件名和 marker，不把路径计数当功能事件，不用去重掩盖终端事务，也不建议削弱断言。' \
  --out "${contract_rel}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  validate "${contract_rel}"
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
  render "${contract_rel}"
