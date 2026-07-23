#!/usr/bin/env bash
set -euo pipefail

CONTRACT=.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-ooo3-final-review.json

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id v8v-ooo3-final-review \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 双发射 OoO 核的共享 retire-resident OooLoadQueue 实现与 OOO-3 memory-ordering 证据，优先寻找行为路径假绿、owner 双真源、full ProducerId 代际混淆、final-PA 元数据漂移、response/retire 越权、recovery ghost、双端口冲突、DI-5 吞吐退化以及 checker 或 evidence binding 漏洞；按 PASS、GAP 或 inconclusive 给出审查结论。' \
  --allow-path npc/rv64/design/arch/rv64-architecture-ppa-contract.md \
  --allow-path npc/rv64/design/arch/producer-holder-census.json \
  --allow-path npc/rv64/design/specs/ooo-load-queue.md \
  --allow-path npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  --allow-path npc/rv64/vsrc/filelist.mk \
  --allow-path npc/rv64/vsrc/memory/OooLoadQueue.v \
  --allow-path npc/rv64/vsrc/memory/OooStoreQueue.v \
  --allow-path npc/rv64/vsrc/memory/OooMemInflightQueue.v \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v \
  --allow-path npc/rv64/vsrc/writeback/OooRob.v \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/testbench/tests/tb_ooo_load_queue.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_store_queue.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_dual_memory_sustained_issue.sv \
  --allow-path npc/rv64/eval/ppa/tools/architecture_hard_gates.py \
  --allow-path npc/rv64/eval/ppa/tools/memory_ordering_evidence.py \
  --allow-path npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py \
  --allow-path npc/rv64/eval/ppa/evidence/architecture-current.json \
  --allow-path npc/rv64/eval/ppa/evidence/memory-ordering.log \
  --allow-path .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/mutate-v8s-dual-memory-core.py \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/contract.md \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/rtl-derivation.md \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/run-focused.sh \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/run-lq-mutations.py \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/mutation-results.json \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/evidence/final-run \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command 'git diff' \
  --allow-read-command sha256sum \
  --required-context npc/rv64/design/arch/rv64-architecture-ppa-contract.md \
  --required-context npc/rv64/design/specs/ooo-load-queue.md \
  --required-context .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/contract.md \
  --required-context .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/rtl-derivation.md \
  --deliverable '给出实现者主张的独立裁决；逐项检查 allocate/issue/launch/query/disposition/response/formal-completion/terminal/retire-release 生命周期、MIQ/LQ/SQ/ROB 单一真源边界、同拍双端口与 wrap recovery、8 个 mutation 的反例质量、11 项 OOO-3 指标的代码与日志绑定、DI-5 64-cycle 双 bank 证据及新增 CAM/state 的 PPA 风险。发现项按严重度、精确文件/行与可触发反例报告，不限制发现数量；证据不足则明确 unknowns、scope_extension_request 与 confidence_and_basis。' \
  --success-criterion '只有当普通 load response 必须经过 exact full ProducerId 与稳定 final-PA disposition、launched killed load 仅由 exact terminal drain、LQ 仅在 completed exact ROB retirement release、双 bank 吞吐证据与源码 digest 同版、checker 无明显静态或日志假绿路径时才可给出 PASS；否则给出 GAP 或 inconclusive，且不得把 OOO-3 局部闭合外推为全核架构或正式 PPA GREEN。' \
  --out "$CONTRACT"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate \
  "$CONTRACT"
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render \
  "$CONTRACT"
sha256sum "$CONTRACT"
