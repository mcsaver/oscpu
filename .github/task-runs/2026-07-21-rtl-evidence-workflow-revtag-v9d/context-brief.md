# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rtl evidence workflow
- `focus_scope`: non-history
- `token_estimate`: 1950 / 2400

## Profile Suggestions
- `agent-system` score=20 matched=evidence, requested-profile, rtl, workflow command=`scripts/agent-e2e.sh --profile agent-system`
- `yosys-sta` score=3 matched=evidence, rtl, workflow command=`scripts/agent-e2e.sh --profile yosys-sta`
- `verilator-tapeout` score=2 matched=rtl, workflow command=`scripts/agent-e2e.sh --profile verilator-tapeout`
- `contracts` score=1 matched=workflow command=`scripts/agent-e2e.sh --profile contracts`
- `github-index` score=1 matched=evidence command=`scripts/agent-e2e.sh --profile github-index`

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

### .github/memory/modules/software-flow.md#chunk-0005

- `kind`: memory-module
- `lines`: 21-25
- `tokens`: 933
- `heading`: 当前状态
- `summary`: - 2026-06-09：通过 `nemu-ubuntu` 已 include `software-flow` 的链路，当前 interpreter TB max-inst 配置切片先执行 `software-flow-contract`，再执行 NEMU static/slice gate。验证：`scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-tb-max-inst-config-e2e` PASS，`.github/task-run...

- 2026-06-09：通过 `nemu-ubuntu` 已 include `software-flow` 的链路，当前 interpreter TB max-inst 配置切片先执行 `software-flow-contract`，再执行 NEMU static/slice gate。验证：`scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-tb-max-inst-config-e2e` PASS，`.github/task-runs/2026-06-09-nemu-tb-max-inst-config-e2e/nodes.tsv` 与 `task-report.md` 均显示 `software-flow-contract` PASS，后续 `nemu-ubuntu-static`/`nemu-ubuntu-slice-contract` 也 PASS。意义：NEMU C/Kconfig/Make/Shell 侧性能配置工作现在被软开流程前置消费，不再是单独跑过 `software-flow` 后靠主观记忆应用。
- 2026-06-09：`software-flow` 已被 `nemu-ubuntu` profile 显式 include，真正进入 NEMU C 侧/Ubuntu 切片生产链路。此前它能单独 PASS，但 NEMU 切片只是“按原则应叠加”；现在 `.github/e2e/profiles/nemu-ubuntu.tsv` 通过 `@include|software-flow` 把 `software-flow-contract` 放在 `nemu-ubuntu-static` 与 `nemu-ubuntu-slice-contract` 之前，`nemu-ubuntu-gate` 也继承该前置节点。验证：`scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu` 显示 8 nodes 且包含 `software-flow-contract`；`scripts/agent-e2e.sh --validate-all-profiles` PASS；`.github/task-runs/2026-06-09-nemu-ubuntu-software-flow-include-e2e/` PASS，task-report 节点表、dispatch-log 和 `evidence/software-flow-contract.log` 均证明该节点被真实执行。边界：这是把软件流程纳入 NEMU Ubuntu 生产守门，不替代 NEMU static/slice gate、真实 guest gate、DiffTest、target gate 或完整软件回归矩阵。
- 2026-06-09：新增 `software-flow` 作为 L1 软件开发流程 agent，用于覆盖需求/契约、设计、实现、单测/契约测试、集成 smoke、回归/e2e、审阅和记录的完整软件开发闭环。职责边界是软件模块、脚本、工具链、NEMU/AM/am-kernels/Linux guest check、host side C/C++/Python/Shell/Make/Kconfig；一旦任务进入 RTL/Chisel/SoC/STA/PPA 或 target/difftest 依赖，必须把产物交给 `hardware-flow` 或对应硬件模块 agent。验证：`software-flow` profile PASS，证据 `.github/task-runs/2026-06-09-software-flow-agent-e2e/`；`contracts` profile 中 `software-flow-contract` PASS，证据 `.github/task-runs/2026-06-09-software-flow-contracts-e2e/`；`quick` profile 无 hard fail，`nemu-add-smoke` 因当前 NEMU 配置边界 SKIP。
- 2026-06-09：根据用户指出“之前只是环境校验，没有作为主开发流程使用”，已把 `software-flow` 从可发现 agent 升级为生产组合流程。新增稳定口径 `hardware-aware-software-loop`：NEMU、Linux tools、guest check、host C++ harness、QMP/GDB、virtio/device model 等任务既是软件开发，又承载硬件/系统语义；必须先由 `software-flow` 做需求/契约、设计、实现、软件 focused test 和记录，再叠加 `nemu-ubuntu`、`hardware-flow`、`rv64-linux`、`difftest` 或 target gate 证明系统语义。e2e `software-flow-contract` 已升级为检查 software-flow、hardware-flow、nemu、coordinator、蓝图与 agent-e2e workflow 的组合钩子，避免退回“只验证存在”。验证：`scripts/agent-e2e.sh --validate-all-profiles` PASS；`scripts/agent-e2e.sh --profile software-flow --task-slug software-flow-integrated-e2e` PASS，日志含 `PASS hardware-flow consumes software-flow for software artifacts` 与 `PASS nemu agent requires software-flow for C-side model work`；`scripts/agent-e2e.sh --profile contracts --task-slug software-flow-integrated-contracts-e2e` PASS。

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
