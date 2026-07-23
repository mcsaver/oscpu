#!/usr/bin/env bash
set -euo pipefail

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id v8v-lq-topology-review \
  --task-kind read-only-review \
  --goal '仅依据随附的 RV64 OoO 访存流水事实，复核 OOO-3 下一刀的真实 load queue 拓扑，判断候选 A（从 per-bank MIQ 提取 load owner）与候选 B（共享 retire-resident LQ 加 MIQ transport）的协议完整性、PPA 代价和最小可验证实现边界，并给出明确推荐或 inconclusive。' \
  --allow-path npc/rv64/design/arch/rv64-architecture-ppa-contract.md \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/vsrc/memory/OooMemInflightQueue.v \
  --allow-path npc/rv64/vsrc/memory/OooStoreQueue.v \
  --allow-path npc/rv64/vsrc/writeback/OooRob.v \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/contract.md \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/rtl-derivation.md \
  --self-contained-no-tools \
  --supplied-material 'OOO-3 requires a younger non-alias load to bypass an older store, alias forward/wait/replay, physical-byte disambiguation, zero stale reads or recovery ghosts, and a store physical write only after exact ROB-head completion eligibility with exactly one B terminal and precise B-error retirement.' \
  --supplied-material 'The current canonical source has two independent memory banks and per-bank four-entry all-kind MIQs; DI-5 demonstrates 64 consecutive dual-bank ordinary cached-load issues at IPC 2.0 with complete ProducerId ownership.' \
  --supplied-material 'The current OooStoreQueue is four entries, allocates in program order, uses final-PA byte CAM allow/forward/replay, retains a fired store through B, launches only when SQ head full ProducerId equals the open ROB head, and releases only after the B terminal and ROB commit.' \
  --supplied-material 'The current OooRob exposes the full head ProducerId and a head-launch-open signal only while the exact head is valid, incomplete and outside reset/flush/recovery; a store probe success does not mark the ROB done, while B success/error supplies the formal completion.' \
  --supplied-material 'The architecture source checker intentionally requires a real module OooLoadQueue with at least four entries; adding an uninstantiated or observational shadow module is prohibited.' \
  --supplied-material 'A new LQ must preserve two-bank throughput, full ProducerId generation safety, fired-transaction drain, selective cancellation, precise load faults and absence of ready/valid combinational cycles.' \
  --supplied-material 'Candidate A transfers load ownership out of each all-kind MIQ into a dedicated LQ while leaving non-load transport entries in MIQ; candidate B keeps MIQ transport ownership and adds a shared at-least-four-entry LQ retained until ROB commit that actively qualifies physical-query, completion and recovery.' \
  --supplied-material 'The selected topology must identify unique state ownership, exact allocate/query/complete/release events, same-cycle dual-port algebra, flush priorities, required assertions, mutation points and any remaining unknowns; it must not infer facts outside these materials.' \
  --deliverable '给出候选 A/B 的 PASS、GAP 或 inconclusive 裁决，推荐最小真实 LQ 拓扑，列出逐拍状态生命周期、接口握手、同拍双端口代数、恢复优先级、反例、必要断言、定向变异、PPA 风险、替代假设、unknowns、scope_extension_request 与 confidence_and_basis。' \
  --success-criterion '推荐方案必须能解释为何它是行为路径上的真实 load queue、为何不会与 MIQ/SQ 形成双真源、如何保持双 bank 吞吐与完整 ProducerId，并明确任何尚不足以写 RTL 的合同空格；信息不足时允许 inconclusive。' \
  --out .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-lq-topology-review.json

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate \
  .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-lq-topology-review.json

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render \
  .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-lq-topology-review.json
