# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: dual memory architecture checkpoint
- `focus_scope`: non-history
- `token_estimate`: 1707 / 2400

## Profile Suggestions
- `npc-dev` score=8 matched=requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `yosys-sta` score=3 matched=architecture, memory command=`scripts/agent-e2e.sh --profile yosys-sta`
- `abstract-machine` score=2 matched=memory command=`scripts/agent-e2e.sh --profile abstract-machine`
- `contracts` score=2 matched=architecture, memory command=`scripts/agent-e2e.sh --profile contracts`
- `fceux-am` score=2 matched=memory command=`scripts/agent-e2e.sh --profile fceux-am`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile npc-dev`

## Missing Paths
- `.github/e2e/modules/npc-dev.md`
- `.github/agents/npc-dev.agent.md`
- `.github/memory/modules/npc-dev.md`

## Chunks

### .github/AGENTS.md#chunk-0001

- `kind`: agent-rule
- `lines`: 1-15
- `tokens`: 328
- `heading`: AGENTS.md — YSYX 工作区 Agent 通用工作流规范
- `summary`: > 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent / > （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等） / > 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。 / > / > 与本文件协作的入口文件分两类： / > 根...

# AGENTS.md — YSYX 工作区 Agent 通用工作流规范

> 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent
> （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等）
> 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。
>
> 与本文件协作的入口文件分两类：
> 根目录 `AGENTS.md` / 其他兼容入口文件是兼容 shim，保留最小可执行契约并回链本文件；
> `.github/copilot-instructions.md` 不是薄指针，而是 GitHub Copilot 专属工程级补充规则。
> 多份文件出现重叠时，以本文件作为跨 agent 通用基线；Copilot 的额外构建、调试与记录细则再叠加读取 `copilot-instructions.md`。
>
> 当前阶段的目标是“工程规则自动发现与会话恢复”，不是“插件式 UI 扩展”。因此本仓库优先补齐兼容 shim，不主动引入 `.codex-plugin/` 或 `.agents/plugins/marketplace.json`。

---

### .github/e2e/profiles/npc-dev.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-5
- `tokens`: 148
- `heading`: npc-dev.tsv
- `summary`: @include|software-flow|||| / npc-sim-contract|npc|e2e_npc_sim_contract|npc|npc/sim + backend manifests|NPC 开发环境入口只检查 NPC 仿真后端合同 / npc-single-contract|npc|e2e_npc_single_contract|npc|npc/single Makefile/Kconfig/vsrc/csrc|NPC single 后端合约入口存在 / npc-soc-contrac...

@include|software-flow||||
npc-sim-contract|npc|e2e_npc_sim_contract|npc|npc/sim + backend manifests|NPC 开发环境入口只检查 NPC 仿真后端合同
npc-single-contract|npc|e2e_npc_single_contract|npc|npc/single Makefile/Kconfig/vsrc/csrc|NPC single 后端合约入口存在
npc-soc-contract|npc|e2e_npc_soc_contract|npc|npc/soc + ysyxSoC CPU ABI|NPC SoC 后端合约入口存在
npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|NPC RV64 Linux 入口合约存在但不跑 NEMU Ubuntu gate

### .github/memory/modules/npc.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-7
- `tokens`: 1141
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-20(RV64-v8s-dual-memory-core-integration): **canonical `NpcCoreTop` 的 F2 双 ordinary-memory integration 在 closure `2334b38fd33e69d95e7ee2dbe40264a3dfb2fec61a00c0388b4edd233e11d2e2` 上获得严格限域的 `architecture_checkpoint`；DI-5/OOO...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-20(RV64-v8s-dual-memory-core-integration): **canonical `NpcCoreTop` 的 F2 双 ordinary-memory integration 在 closure `2334b38fd33e69d95e7ee2dbe40264a3dfb2fec61a00c0388b4edd233e11d2e2` 上获得严格限域的 `architecture_checkpoint`；DI-5/OOO-3/overall/PPA 继续 RED/unqualified，promotion=false**。`ENABLE_DUAL_MEM` 在 Backend→Decode→Slice→Execute→Glue reusable chain 默认 0，只有 canonical core 逐层 exact enable；topology 为 `dual_wrapper=1/legacy_bridge=0/core_glue=1`。`OooIntBackend` 现有两份 reservation/MIQ、独立 bridge face 与 ROB completion-open query，以 captured `addr[3]` 分 bank、同 bank 用 edge-old ROB distance 选较老者；两个 response 共享唯一两槽 WB allocator、双 SQ fill/terminal 分配与 10-ingress/32-token terminal collector，AMO/LR/SC/SQ singleton 仍由 bank0 承载且 launch/release edge 不得 ordinary look-through。`make -C npc/rv64 check-dual-memory-core-integration` 的 release/assert/legacy、full-top lint、17/17 source、13/13 checker negative、11/11 semantic mutation 和 fresh F1 handoff 全 PASS，最终 run `v8s-f2-20260720T080613Z-1010841`。reviewer 反例已新增真实 ROB head=15/raw 15→0 same-bank age 与 EX0/EX1 占满 WB0/WB1 时双 response hold/resume exactly-once 场景；v2 复审仅授权 checkpoint。F3 必须继续实现 final-PA SQ byte query/forward/replay，F4 才能讨论 sustained IPC/system/equal-capacity physical banking 与同源 synthesis/STA/power/Pareto。证据 `.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/`。
- 2026-07-20(RV64-v8r-dual-memory-bridge-wrapper): **未接入 canonical core 的 F1 leaf 在 frozen closure `05743bcd448bae5da16110a5a0a8644e74de87fde8bf6047b324c904eb1cfc18` 上获得 `dual_bridge_cache_hit_leaf_verified`；DI-5/OOO-3/overall/PPA 继续 RED/unpromoted**。`OooDualMemBridgeWrapper` 例化两份 `OooMemAxiBridge` 与 F0 `OooDualMemAxiArbiter`，保持 lane0/lane1 request ready 和 response 独立，并把每 lane 已授权的 cache-hit store maintenance 交叉送往 peer D-cache；`OooDataWordCache` 对 peer maintenance 做 mask normalize、exact-word same-cycle hit block、逐 entry clear-wins，不让 peer 成为 SRAM port owner，非法 mask 唯一 fatal。MMU flush 仍要求双 bridge idle；wrapper 尚未由 `NpcCoreTop` 实例化。`make -C npc/rv64 check-dual-memory-bridge-wrapper` 固化 6 个 release/assert profile、2 个 assertion-negative、10/10 semantic mutation、F0 checker/target 兼容、style/contract、closure 与 architecture expected-RED，最终 run `v8r-f1-20260720T052716Z-935556`。为关闭真实假绿，producer-holder census 已补第二 memory reservation 的 producer/token（direct=16/token_q=13），`swap_peer_addr` mutation 用互异的 unused self payload 建立非对称反例。下一步 F2 必须在 canonical core 中建立第二 MIQ/final-PA SQ query/completion 与 end-to-end 双 lane 所有权；本条不授权 IPC/PPA 结论。证据 `.github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/`。
- 2026-07-20(RV64-v8q-dual-memory-axi-fabric): **canonical design id `sha256:79e445cd976f7a2ace1da6288866b2442846677520052a95eea7c14504ab2cca` 下，未实例化的 `OooDualMemAxiArbiter` 获得 scoped `dual_axi_miss_fabric_leaf_verified`；same-digest DI-3/DI-4/OOO-1/OOO-2 fresh GREEN，DI-5/OOO-3/overall/PPA 继续 RED/unpromoted**。五态 registered-owner FSM 将 read 锁至 R terminal、write 以独立 `aw_seen_q/w_seen_q` 锁至 B terminal，non-owner request READY/response VALID 为零，response READY 仅来自 exact owner，`rr_q` 只在 terminal 更新；全系统同步 reset 组合静默并清所有 transport 状态，逐态 reset 后 orphan R/B 不可见，非法 read+write IDLE 全局 fail-closed。`make -C npc/rv64 check-dual-memory-fabric-foundation` 固化 release/assert/assert-negative、AR/R/AW/W/B stall/skew/fairness/reset matrix、12/12 compile-success semantic mutation、10/10 去注释 fail-closed checker、Verilator/style 与完整 closure pre/post；最终 run `v8q-f0-20260720T030925Z-849762`。canonical core 尚无该实例，F1 仍需双 bridge/cache-hit wrapper 与 peer maintenance，后续还需双 MIQ/final-PA SQ query/completion 和 IPC/PPA 证据。证据 `.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/`。

### .github/copilot-instructions.md#chunk-0001

- `kind`: instruction
- `lines`: 1-2
- `tokens`: 11
- `heading`: YSYX 工作区 — 全局指导规范
- `summary`: YSYX 工作区 — 全局指导规范

# YSYX 工作区 — 全局指导规范

### .github/memory/project-status.md#chunk-0001

- `kind`: memory
- `lines`: 1-3
- `tokens`: 38
- `heading`: YSYX 项目状态总览
- `summary`: > 本文件由 agent 自动维护，记录项目当前进度。每次完成重要任务后更新。

# YSYX 项目状态总览

> 本文件由 agent 自动维护，记录项目当前进度。每次完成重要任务后更新。

### .github/memory/known-issues.md#chunk-0001

- `kind`: memory
- `lines`: 1-4
- `tokens`: 35
- `heading`: 已知问题与调试历史
- `summary`: > 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

### .github/e2e/README.md#chunk-0001

- `kind`: markdown
- `lines`: 1-2
- `tokens`: 6
- `heading`: Agent E2E Profiles
- `summary`: Agent E2E Profiles

# Agent E2E Profiles
