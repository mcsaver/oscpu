# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: self contained no tools rtl review
- `focus_scope`: non-history
- `token_estimate`: 2113 / 2400

## Profile Suggestions
- `agent-system` score=22 matched=no, requested-profile, review, rtl command=`scripts/agent-e2e.sh --profile agent-system`
- `github-index` score=3 matched=no, review command=`scripts/agent-e2e.sh --profile github-index`
- `nemu` score=3 matched=no, self, tools command=`scripts/agent-e2e.sh --profile nemu`
- `yosys-sta` score=3 matched=no, rtl, tools command=`scripts/agent-e2e.sh --profile yosys-sta`
- `contracts` score=2 matched=no, tools command=`scripts/agent-e2e.sh --profile contracts`

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

### .github/skills/prepare-rtl-task-contract/SKILL.md#chunk-0003

- `kind`: skill
- `lines`: 11-72
- `tokens`: 1096
- `heading`: 工作流
- `summary`: 1. 只给子任务所需的最小上下文；不得把整轮历史、账号信息或无关日志一并传入。 / 2. 用脚本创建契约。只读复核使用 `read-only-review`，落盘实现使用 `implementation`，验证与 PPA 分别使用 `verification`、`ppa-analysis`。 / 3. 校验并渲染；把渲染结果原样放进子 agent 提示，不要另写一份可能漂移的边界说明。 / `create` 会把输出 JSON 自身的仓库相对路径加入 `allowed_paths`；`render` 会从实际...

## 工作流

1. 只给子任务所需的最小上下文；不得把整轮历史、账号信息或无关日志一并传入。
2. 用脚本创建契约。只读复核使用 `read-only-review`，落盘实现使用 `implementation`，验证与 PPA 分别使用 `verification`、`ppa-analysis`。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id <task-id> \
  --task-kind read-only-review \
  --goal '<可验证目标>' \
  --allow-path npc/rv64/vsrc/<path> \
  --allow-read-command rg \
  --allow-read-command sed \
  --required-context npc/rv64/design/specs/<spec>.md \
  --deliverable '<输出内容>' \
  --success-criterion '<客观成功条件>' \
  --out .github/task-runs/<run-id>/subagent-contracts/<task-id>.json
```

3. 校验并渲染；把渲染结果原样放进子 agent 提示，不要另写一份可能漂移的边界说明。
`create` 会把输出 JSON 自身的仓库相对路径加入 `allowed_paths`；`render` 会从实际文件自动写出
该 JSON 的路径与 SHA-256，并明确该哈希只绑定 JSON，不绑定设计 spec、`contract.md`、RTL 或测试。
不要手工补一条无文件名的 SHA，也不要让子 agent 猜测它绑定哪个合同。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate <contract.json>
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render <contract.json>
```

命令权限不是自由文本。`--allow-read-command` 与 `--allow-write-command` 只接收 canonical `COMMAND`；
生成器从 JSON catalog 填入固定的 `mode/purpose` 枚举和中文标签，任务不能自定义 purpose。详细意图写在
`goal/deliverables/success_criteria`，不会扩大命令权限。只读任务只允许 canonical 只读命令类，写型命令必须同时声明最小 `write_paths`。工具的 repo realpath 固定为本 skill 所在工作区，
`--repo-root` 不能改绑到其它目录。

冻结、自包含材料已足够的只读 reviewer 使用原生 no-tools 模式；不要给 JSON 虚列 `rg` 或 `sed`
再在提示中口头收紧。每个 `--supplied-material` 是一条单行工程事实，渲染后就是子 agent 可见的全部
材料；来源路径仅保留为 provenance。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id <task-id> \
  --task-kind read-only-review \
  --goal '<只依据随附事实完成的可验证复核>' \
  --allow-path npc/rv64/design/specs/<spec>.md \
  --self-contained-no-tools \
  --supplied-material '<单行事实 1>' \
  --supplied-material '<单行事实 2>' \
  --deliverable '<结构化复核结论>' \
  --success-criterion '<明确 PASS/GAP 及反例>' \
  --out .github/task-runs/<run-id>/subagent-contracts/<task-id>.json
```

该模式的校验结果必须精确为 `context.material_mode=prompt-supplied-self-contained`、
`allowed_commands=[]`、`write_paths=[]`，并拒绝非只读任务、缺失材料、任何命令、任何写路径或多行材料。

4. 在 `dispatch-log.md` 逐字记录渲染结果中的 JSON 路径和 SHA-256。子 agent 返回后，对照契约检查越界读取、未授权写入、外部访问和缺失产物；需扩展范围时生成新版本契约，不在原提示后模糊追加权限。
5. 若平台暂不展示或不处理某个合法 RTL 子任务，只把该子任务记为 `review_pending`，保留原始请求、契约哈希、时间和平台提示；不得通过改变 RTL 语义来重试，也不得据此关闭长期父目标。
6. 将 reviewer 的每个可操作反例登记到 `dispatch-log.md`，并转成 spec 修订加定向 TB、
   compile-success mutation 或 fail-closed 静态审计；文本反例本身不能作为 GREEN 证据。若冻结摘要
   已充分，派发原生 `self-contained-no-tools` 契约，使 `no tools / no shell / no file access / no network`
   直接成为 JSON 与渲染提示一致的执行边界。

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
