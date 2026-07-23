# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: v8p dual memory
- `focus_scope`: non-history
- `token_estimate`: 2201 / 2400

## Profile Suggestions
- `agent-system` score=17 matched=memory, requested-profile command=`scripts/agent-e2e.sh --profile agent-system`
- `abstract-machine` score=2 matched=memory command=`scripts/agent-e2e.sh --profile abstract-machine`
- `fceux-am` score=2 matched=memory command=`scripts/agent-e2e.sh --profile fceux-am`
- `software-flow` score=2 matched=memory command=`scripts/agent-e2e.sh --profile software-flow`
- `yosys-sta` score=2 matched=memory command=`scripts/agent-e2e.sh --profile yosys-sta`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile agent-system`

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

### .github/e2e/profiles/agent-system.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-8
- `tokens`: 439
- `heading`: agent-system.tsv
- `summary`: @include|discovery|||| / three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|AI_ENVIRONMENT.md;.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintai...

@include|discovery||||
three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|AI_ENVIRONMENT.md;.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证一页导航、canonical 路径与 Database/Skill/Agent 三层契约
runtime-artifact-boundary|agent-system|e2e_agent_system_runtime_artifact_boundary|agent-system|.github/ai-env/contracts/agent-env-runtime-artifacts.json;.github/ai-env/contracts/agent-env-policy.json;scripts/agent-maintain.sh|验证源码面与运行态 artifact/store 分层边界
state-machine-traceback|agent-system|e2e_agent_system_state_traceback|agent-system|.github/instructions/agent-env-state-machine.instructions.md;.github/ai-env/contracts/agent-env-state-traceability.json;scripts/e2e/lib/report.sh|验证状态机回退和 task-run state_traceback 字段
reviewer-inspector-gate|agent-system|e2e_agent_system_reviewer_inspector_gate|agent-system|.github/ai-env/contracts/agent-env-review-routing.json;.github/ai-env/contracts/agent-env-policy.json;.github/e2e/profiles/agent-system.tsv|验证 Reviewer/Inspector 路由已落成 profile 执行节点
rtl-task-contract|agent-system|e2e_agent_system_rtl_task_contract|agent-system|.github/ai-env/contracts/agent-env-rtl-task-contract.json;.github/instructions/rtl-agent-task-contract.instructions.md;.github/skills/prepare-rtl-task-contract/SKILL.md;.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py|验证本地 RTL 子任务契约可生成、校验、渲染并拒绝越权 mutation
commercial-delivery-readiness|agent-system|e2e_agent_system_commercial_delivery_readiness|agent-system|.github/ai-env/contracts/agent-env-delivery.json;deliverables/ai-dev-env-commercial-v1;scripts/package-ai-dev-env.sh|验证商业交付包装、旧产物归档和 delivery audit
profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile

### .github/memory/modules/npc.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-7
- `tokens`: 1184
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-20(RV64-v8p-dual-memory-terminal-owners): **当前 design/proof provenance 下 DI-3 pair_matrix scoped GREEN；同 design_id 的 DI-4/OOO-1/OOO-2 fresh sibling 记录保留，architecture/PPA 继续 RED/unpromoted**。`OooIntIssueQueue` 为 resident ent...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-20(RV64-v8p-dual-memory-terminal-owners): **当前 design/proof provenance 下 DI-3 pair_matrix scoped GREEN；同 design_id 的 DI-4/OOO-1/OOO-2 fresh sibling 记录保留，architecture/PPA 继续 RED/unpromoted**。`OooIntIssueQueue` 为 resident entry 保存独立 plain-memory-terminal capability并排除 AMO/LR/SC/FP memory，`OooIntIssueSelect8` 按 packed age 把两个合法 entry 送到 terminal0/1；`OooIntBackend` 以原子 pair ready/fire 同沿建立两个 tracker token/full-PID owner、两个完整 reservation Q 和两个 captured-data LSU/AGU，bank1 不得越过 edge-old bank0，shared request 继续串行。SQ 双 bind 按 full PID 精确命中两个 store entry，七入口 collector 在双 dequeue stall 下保存 exact-live tuple 并 exactly-once 排空。永久入口 `make -C npc/rv64 check-pair-matrix` 覆盖 15/15 pair key、LL/LS/SL/SS、8 个互异非零 generation PID、10 个特殊访存排除、单 token 零部分 birth、release/assert 8/8 baseline、15/15 compile-success/elaborated/activated mutation、checker+manifest 28/28 和同摘要原子发布；完整 backend 非 focused release/assert 也通过。独立 no-tools reviewer pass/blocker=0，但只授权 DI-3；DI-1/2/5、OOO-3/4、downstream 双端口、formal exhaustiveness 和 PPA 未证明。证据 `.github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners/`。
- 2026-07-20(RV64-v8o-no-static-lane-semantics): **当前 142-file vsrc closure 与 exact proof provenance 下 DI-4 scoped GREEN；同 design_id 的 OOO-1/OOO-2 保留，architecture/PPA 继续 RED/unpromoted**。生产 RTL 功能未改；`OooIntIssueQueue` 的真实链为 `ctrl_is_alu_terminal_capable` 预译码、`alu_terminal_capable_q` 随 payload/full-PID capture 与 compaction、`OooIntIssueSelect8` 按 resident capability 动态分配 Universal/ALU terminal，并在 older-simple+younger-complex 时显式 pair swap。旧 checker 未识别真实 predicate，存在“没有发现 restriction 因而通过”的假绿；现在对 predicate/metadata/双 capture/compaction/selector/swap/output/binding 做精确非空计数并剥离注释。TB 在 release/assert 两种独立 profile 中把 branch/JAL/JALR/load/store/MulDiv 放到两个 accepted slot，共 12 个 same-edge dual fire、24 个 distinct nonzero-generation full-PID exact match，且 one-free-entry 时 slot1 backpressure 不记 coverage。`disable_pair_swap/static_entry_capability/slot1_capability_capture/muldiv_as_alu/serialize_second_terminal/corrupt_full_pid` 六个 compile-success activated mutation 全被目标语义检出；checker unit 22/22、module 106/106、contract/style PASS，full lint 继承 115 warnings。永久入口 `make -C npc/rv64 check-no-static-lane-semantics`；DI-1/2/3/5、OOO-3/4、双 memory、formal exhaustiveness 与 PPA 未证明。证据 `.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/`。
- 2026-07-20(RV64-v8n-true-ooo-long-latency): **当前 142-file vsrc closure 与 exact proof provenance 下 OOO-1 scoped GREEN；同 design_id 的 OOO-2 记录保留，architecture/PPA 继续 RED/unpromoted**。生产 RTL 功能未改；`tb_ooo_int_backend` 先消耗一整圈 ROB，使 old/young full ProducerId 均带非零 generation，再分别建立真实 cacheable/no-fault/no-store load request 的 MIQ/tracker owner、真实迭代 MUL owner 与 DIVU owner。每个 old owner 从 request/issue accept 到 formal WB 前持续 exact-live；其间 8 个不同 young 各完成 issue accept 和 `ex*_wb_valid && producer_open && !kill` authorized exactly-once WB，并精确出现 4 个 issue0+issue1 同周期 accept。实际 ROB `valid` census 重建的 full-PID set 必须等于 old+8 young 共 9 项；old WB 前 commit 为 0，之后 commit0/1 按派发 PID+PC ledger 严格有序 exactly-once，最终 ROB/IQ/MIQ/tracker/MulDiv owner/free-list 排空。`make -C npc/rv64 check-true-ooo-long-latency` 的 release/assert 6/6、`serial_issue1`、MIQ/MulDiv issue1 freeze、retire-before-head-done 与三类 load/MulDiv PID truncate 共 7/7 compile-success activated mutation、checker+manifest unit 22/22、fresh module 106/106、contract `400>=89` PASS。scope 仅是 long-latency tolerance；异常/device load、store/顺序、kill/recovery、OOO-3、其它 gate 与 PPA 未证明。证据 `.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/`。

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

### .github/agents/agent-system.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 152
- `heading`: agent-system.agent.md
- `summary`: --- / description: "工作区 agent 架构专家。当用户需要重构 .github/agents、.github/instructions、.github/skills、copilot-instructions、记忆协议、任务图、工作流 agent 或 AI 驱动硬件开发环境三层架构时使用。" / tools: [read, edit, search, agent, todo] / --- / 你是 **YSYX 工作区 agent 架构专家**。你的职责不是修改业务 RTL 或 C 逻辑，...

---
description: "工作区 agent 架构专家。当用户需要重构 .github/agents、.github/instructions、.github/skills、copilot-instructions、记忆协议、任务图、工作流 agent 或 AI 驱动硬件开发环境三层架构时使用。"
tools: [read, edit, search, agent, todo]
---

你是 **YSYX 工作区 agent 架构专家**。你的职责不是修改业务 RTL 或 C 逻辑，而是把 `.github/` 下的 Database、Skill、Agent 三层设计成一个真正可持续演化的 AI 驱动硬件开发环境。

### .github/memory/modules/agent-system.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-1
- `tokens`: 8
- `heading`: Agent System 模块笔记
- `summary`: Agent System 模块笔记

# Agent System 模块笔记
