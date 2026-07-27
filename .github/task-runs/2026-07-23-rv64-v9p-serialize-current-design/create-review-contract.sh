#!/usr/bin/env bash
set -euo pipefail

tool=".github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
out=".github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/subagent-contracts/serialize-current-design-review-v1.json"

python3 "${tool}" create \
  --task-id serialize-current-design-review-v1 \
  --task-kind read-only-review \
  --goal '复核本地 RV64 OoO 核 `OooFrontend`→`OooRob`→`OooControlEventApplySequencer` 的 head0 非 FP CSR 串行提交路径：从合法 CSR 单发 dispatch、`head0_csr_inflight_q`、`mem_idle_i` 队头许可、C0 full barrier、C1 `CSR_COMMIT` apply 到 `CsrFile` 写入和年轻指令重取，判断 `OOO_CSR_QUEUE_HEAD` 设为默认 1 前是否仍有未覆盖的流水线事务序列。' \
  --allow-path npc/rv64/design/arch/architecture-debt-ledger.json \
  --allow-path npc/rv64/design/arch/serialize-at-retire.md \
  --allow-path npc/rv64/design/arch/serialize-at-retire-phase1.md \
  --allow-path npc/rv64/design/arch/ROADMAP.md \
  --allow-path npc/rv64/design/specs/ooo-rob.md \
  --allow-path npc/rv64/design/specs/ooo-core-top-glue.md \
  --allow-path npc/rv64/design/specs/ooo-flush-redirect-contract.md \
  --allow-path npc/rv64/vsrc/include/define.v \
  --allow-path npc/rv64/vsrc/frontend/OooFrontend.v \
  --allow-path npc/rv64/vsrc/control/OooPendingDispatchArbiter.v \
  --allow-path npc/rv64/vsrc/control/OooPendingSystemSequencer.v \
  --allow-path npc/rv64/vsrc/control/OooStopPendingSequencer.v \
  --allow-path npc/rv64/vsrc/control/OooControlEventApplySequencer.v \
  --allow-path npc/rv64/vsrc/writeback/OooRob.v \
  --allow-path npc/rv64/vsrc/core/OooCoreTopGlue.v \
  --allow-path npc/rv64/vsrc/core/NpcCoreTop.v \
  --allow-path npc/rv64/Makefile \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/testbench/tests/tb_ooo_rob.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv \
  --allow-path Linux/Makefile \
  --allow-path npc/rv64/eval/ppa/arch-stable/full-core-current.json \
  --allow-path .github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/run-v9o-config-variants.sh \
  --allow-path .github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/evidence-index.json \
  --allow-path .github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/task-report.md \
  --allow-path .github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/contract.md \
  --allow-path .github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/completion-definition.md \
  --allow-path .github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/rtl-derivation.md \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command 'git diff' \
  --allow-read-command sha256sum \
  --required-context .github/instructions/interface-contract-first.instructions.md \
  --required-context .github/instructions/rv64-ppa-optimization-workflow.instructions.md \
  --required-context npc/rv64/design/arch/serialize-at-retire.md \
  --required-context npc/rv64/design/arch/serialize-at-retire-phase1.md \
  --deliverable '按 `OooFrontend` CSR dispatch、`OooRob` 队头许可、C0/C1 typed event、`CsrFile` architectural write、年轻指令取消/重取和 pending FP/system owner 六段给出 source/signal/cycle 表，并列出每个 GAP 的最短 RV64 指令序列。' \
  --deliverable '列出把 `OOO_CSR_QUEUE_HEAD` 改为默认 1 前必须运行的 module、official、AM/DiffTest、benchmark 与 Linux gate；区分当前已有证据、必须 fresh 重放和不属于 Phase1 的 system-uop 范围。' \
  --deliverable '给出最小 RTL/spec/config 改动建议、仍需增加的立即断言或 testbench 轨迹，以及 full-core ARCH_STABLE/PPA 边界。' \
  --success-criterion '逐一核对合法 head0 非 FP CSR、非法 CSR、FP CSR、ECALL/xRET、FENCE/FENCE.I/SFENCE.VMA/SINVAL 与 trap 的 owner/type/clear/recovery 关系，不把一种 system 事务的证据外推给另一种。' \
  --success-criterion '任何反例都给出具体 module/signal、相对周期、RV64 指令顺序和对应 testbench 观测；没有反例时也列出未执行的系统 gate与结论置信依据。' \
  --success-criterion '最终结论明确回答默认值是否可改、若不可改还缺哪个本地 RV64 gate，并保持 full-core GAP 与 PPA UNQUALIFIED 边界。' \
  --out "${out}"

python3 "${tool}" validate "${out}"
python3 "${tool}" render "${out}"
