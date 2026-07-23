# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rv64 hardware professional prompt
- `focus_scope`: non-history
- `token_estimate`: 1922 / 2400

## Profile Suggestions
- `agent-system` score=16 matched=requested-profile command=`scripts/agent-e2e.sh --profile agent-system`
- `rv64-linux` score=7 matched=prompt, rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `hardware-flow` score=6 matched=hardware command=`scripts/agent-e2e.sh --profile hardware-flow`
- `nemu` score=3 matched=hardware, prompt, rv64 command=`scripts/agent-e2e.sh --profile nemu`
- `contracts` score=2 matched=hardware, rv64 command=`scripts/agent-e2e.sh --profile contracts`

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

### .github/instructions/rtl-agent-task-contract.instructions.md#chunk-0004

- `kind`: instruction
- `lines`: 45-67
- `tokens`: 818
- `heading`: 主 agent 派发流程
- `summary`: 1. 从当前图节点提取一个子目标，不把“持续优化完整 OoO/PPA”直接交给单个子 agent。 / 2. 创建契约并运行 `validate`；实现类任务还须把 `.github/instructions/rtl-generation-workflow.instructions.md` 放入 `required_context`。命令用 `--allow-read-command COMMAND` 或 `--allow-write-command COMMAND` 选择 catalog 项，不把完整 sh...

## 主 agent 派发流程

1. 从当前图节点提取一个子目标，不把“持续优化完整 OoO/PPA”直接交给单个子 agent。
2. 创建契约并运行 `validate`；实现类任务还须把 `.github/instructions/rtl-generation-workflow.instructions.md` 放入 `required_context`。命令用 `--allow-read-command COMMAND` 或 `--allow-write-command COMMAND` 选择 catalog 项，不把完整 shell 片段或自定义 purpose 塞入权限字段。需要独立发现遗漏、追调用链或核对源码时默认使用 `workspace-files`。只有问题已经冻结且结论明确限定为随附材料时，才使用 `--self-contained-no-tools`，并以一个或多个 `--supplied-material '<单行事实>'` 提供完整材料；不得同时声明任何命令或写路径。
3. 新派发固定走 `create → validate → render`；`create` 先执行 `rv64-hardware-professional` 措辞预检，
   再用 `render` 生成提示并原样派发，确认
   “合同 JSON 路径/合同 JSON SHA-256/只绑定该 JSON”三项齐全。主 agent 不另行改写边界，不用泛化动词替代
   可验证产物。JSON 未通过 validate、或提示手工漂移了权限/状态边界时，reviewer 输出只能记为
   `candidate-only`，不得进入下游硬证据。渲染提示只保留硬件任务语境、权限和证据边界，不附加平台处理、
   `review_pending` 或改变分类结果等协调层文字。
4. 派发后记录契约哈希。子 agent 若通过 `scope_extension_request` 请求扩大路径或命令，先返回主 agent，
   由主 agent决定是否创建新的 versioned 契约并重新 validate/render/绑定新 SHA；请求本身不自动授权，
   也不能在旧提示后口头追加权限。外部访问仍须拆成独立研究节点。
5. 接收结果时先审契约符合性，再审技术结论。越界结果不能作为下游硬依赖；需要时隔离为证据候选重新复核。
6. 文本反例不是验证证据。主 agent 必须把每个可操作反例映射到 spec/contract 修订，并至少落成
   定向 TB、compile-success mutation 或 fail-closed 静态审计之一；暂时无法落成时写入 task report
   的剩余风险，禁止只把 reviewer 的自然语言结论抄成 GREEN。
7. 仅当限定材料复核比源码探索更符合任务目标时，才生成原生 `prompt-supplied-self-contained`
   契约：JSON 精确声明 `allowed_commands=[]`、`write_paths=[]`，渲染提示声明
   `no tools / no shell / no file access / no network` 并内嵌全部 `supplied_material`。该模式只能称为
   “限定材料复核”，不得宣称完整独立仓库审查，也不得用于证明不存在未随附的实现或证据。不得用
   “实际执行比 JSON 上限更窄”的口头约束代替机器可校验权限。

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

### .github/skills/prepare-rtl-task-contract/agents/openai.yaml#chunk-0001

- `kind`: yaml
- `lines`: 1-7
- `tokens`: 87
- `heading`: openai.yaml
- `summary`: interface: / display_name: "Prepare RTL Task Contract" / short_description: "生成本地 RTL 契约与硬件专业措辞提示" / default_prompt: "Use $prepare-rtl-task-contract to prepare a precise local RV64 RTL contract and hardware-professional prompt before delegation." / policy:...

interface:
  display_name: "Prepare RTL Task Contract"
  short_description: "生成本地 RTL 契约与硬件专业措辞提示"
  default_prompt: "Use $prepare-rtl-task-contract to prepare a precise local RV64 RTL contract and hardware-professional prompt before delegation."

policy:
  allow_implicit_invocation: true
