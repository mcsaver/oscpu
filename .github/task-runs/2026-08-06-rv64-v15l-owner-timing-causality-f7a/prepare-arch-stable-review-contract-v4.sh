#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_root=${repo_root}/.github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a
contract=${task_root}/subagent-contracts/v15l-arch-stable-independent-review-f7a-v4.json
rendered=${task_root}/subagent-contracts/v15l-arch-stable-independent-review-f7a-v4.rendered.txt
contract_hash=${task_root}/subagent-contracts/v15l-arch-stable-independent-review-f7a-v4.sha256
tool=${repo_root}/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py

cd -- "${repo_root}"
mkdir -p -- "${task_root}/subagent-contracts"
python3 -B "${tool}" create \
  --task-id v15l-arch-stable-independent-review-f7a-v4 \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 双发射 OoO 核的 ARCH_STABLE exact candidate v4：确认 design_id 对应的 146 个 production RTL、仿真配置、L0/L1/L2/L3、ProducerId holder 生命周期和系统事务证据保持不变，并确认 v3 到 v4 唯一输入变化是 RV64 PPA 优化规范文件的哈希重绑定；主动寻找证据假绿、RTL/仿真器/配置漂移、覆盖洞或越级 PPA 结论。' \
  --allow-path npc/rv64/vsrc \
  --allow-path npc/rv64/testbench \
  --allow-path npc/rv64/design/arch \
  --allow-path npc/rv64/design/specs \
  --allow-path npc/rv64/.config \
  --allow-path npc/rv64/include/config \
  --allow-path npc/rv64/include/generated \
  --allow-path npc/rv64/syn/macro-lib \
  --allow-path yosys-sta/pdk/icsprout55 \
  --allow-path npc/rv64/eval/ppa/tools \
  --allow-path npc/rv64/eval/ppa/tests \
  --allow-path npc/rv64/eval/ppa/schemas \
  --allow-path npc/rv64/eval/ppa/evidence \
  --allow-path .github/instructions/rv64-ppa-optimization-workflow.instructions.md \
  --allow-path .github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence \
  --allow-path .github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a/evidence \
  --allow-path .github/task-runs/2026-08-05-rv64-v15f-full-core-current-f7a6-a1/evidence \
  --allow-path .github/task-runs/2026-08-05-rv64-v15f-full-core-coremark-checker-replay-v2 \
  --allow-path .github/task-runs/2026-08-05-rv64-v15e-l2-mini-system-all-a11/mini-system \
  --allow-path .github/task-runs/2026-08-05-rv64-v15e-l3-lightweight-linux-all-a6/lightweight-linux \
  --allow-path .github/task-runs/2026-08-06-rv64-v15h-architecture-debt-current-f7a/evidence \
  --allow-path .github/task-runs/2026-08-05-rv64-v15g-v9p-terminal-root-cause-backfill/evidence \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command sha256sum \
  --required-context .github/instructions/rv64-ppa-optimization-workflow.instructions.md \
  --required-context npc/rv64/design/arch/rv64-architecture-ppa-contract.md \
  --required-context npc/rv64/.config \
  --required-context npc/rv64/eval/ppa/evidence/system-recertification-current.json \
  --required-context npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json \
  --required-context .github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence/arch-stable-candidate-f7a-v4/candidate.json \
  --required-context .github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence/arch-stable-candidate-f7a-v4/tool-versions.json \
  --required-context .github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence/arch-stable-candidate-f7a-v4/audit-without-review.json \
  --required-context .github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a/evidence/arch-stable-candidate-f7a-v3/candidate.json \
  --required-context npc/rv64/eval/ppa/evidence/arch-stable-independent-review-current.json \
  --deliverable '首行按 RV64 RTL 结论格式给出 exact candidate v4 的 PASS/GAP/inconclusive；随后列出已核对的本地证据文件与哈希、v3→v4 输入差异、反例、unknowns、替代假设、scope_extension_request、confidence_and_basis，并仅在确实无 blocker/unknown 时给出 exact approval marker。' \
  --success-criterion '独立确认 candidate v4 的 design_id、146 个 production RTL、live .config/generated headers/liberty/module specs、workspace-bound tool identity、9/9 architecture gates、L0 113/113、L1 official/AM/DiffTest、L2 all、L3 all、零 RTL assertion、holder 46/46 与历史缺陷证据均 exact-bound；v3→v4 的 97 项 workflow artifacts 中仅 .github/instructions/rv64-ppa-optimization-workflow.instructions.md 从 f1491047d807cb19c1bf66f0823e192b75a74f8727e97389f83850efd0e73764 变化为 c66ed74c0cd3dd23c7315a6ae5f1bd02e2fd56df00fc7826dcbf6804790f7682；Ubuntu 保持 optional NOT_RUN，PPA 保持 UNQUALIFIED 且 promotion_eligible=false。若且仅若不存在 blocker 与 unknown，报告中恰好一次输出 [ARCH-STABLE-INDEPENDENT-REVIEW][APPROVE] design_id=sha256:f7a6845564f2d697fca9eac8bf9424136508a62c7fcc7851ad56c688dc2053f9 candidate_sha256=08cb6b8ef87995428f6eb1306c78313984feff235bcf404fb49fbf51e1f39b74；否则不得输出该 marker，并明确 GAP。' \
  --out "${contract}"
python3 -B "${tool}" validate "${contract}"
python3 -B "${tool}" render "${contract}" >"${rendered}"
sha256sum "${contract}" >"${contract_hash}"
printf '[RTL-TASK-CONTRACT][PASS] contract=%s rendered=%s\n' \
  "${contract#${repo_root}/}" "${rendered#${repo_root}/}"
