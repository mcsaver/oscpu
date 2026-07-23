# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rtl contract shell ownership
- `focus_scope`: non-history
- `token_estimate`: 2372 / 2400

## Profile Suggestions
- `agent-system` score=20 matched=contract, requested-profile, rtl command=`scripts/agent-e2e.sh --profile agent-system`
- `github-index` score=4 matched=contract, ownership, shell command=`scripts/agent-e2e.sh --profile github-index`
- `contracts` score=3 matched=contract command=`scripts/agent-e2e.sh --profile contracts`
- `nemu` score=3 matched=contract, ownership, shell command=`scripts/agent-e2e.sh --profile nemu`
- `verilator-tapeout` score=3 matched=contract, rtl command=`scripts/agent-e2e.sh --profile verilator-tapeout`

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

### .github/instructions/rtl-agent-task-contract.instructions.md#chunk-0003

- `kind`: instruction
- `lines`: 10-50
- `tokens`: 1355
- `heading`: 派发前硬门
- `summary`: 每个子任务必须具备以下字段；缺任一项不得派发： / 1. `engineering_domain`：固定为 `local-rv64-rtl`，正文说明是本地 Verilog/SystemVerilog 数字电路设计、验证或 PPA。 / 2. `task_kind`：`read-only-review | implementation | verification | ppa-analysis`。 / 3. `goal`：单一、可验证，不夹带父目标的全部历史。 / 4. `allowed_paths`：仓库相...

## 派发前硬门

每个子任务必须具备以下字段；缺任一项不得派发：

1. `engineering_domain`：固定为 `local-rv64-rtl`，正文说明是本地 Verilog/SystemVerilog 数字电路设计、验证或 PPA。
2. `task_kind`：`read-only-review | implementation | verification | ppa-analysis`。
3. `goal`：单一、可验证，不夹带父目标的全部历史。
4. `allowed_paths`：仓库相对路径白名单；禁止绝对路径、`..` 和工作区外路径。
5. `write_paths`：允许落盘的最小子集。`read-only-review` 必须为空；实现任务必须显式列出。
6. `allowed_commands`：每项固定为 `command/mode/purpose` 三元组；`mode` 只能是 `read-only` 或
   `write-within-scope`。任务只能选择 canonical command，`mode/purpose` 必须逐字匹配 canonical catalog，不能提交自由 purpose；中文用途标签也由 catalog 固定。详细意图只能放在 `goal/deliverables/success_criteria`，不会扩大命令权限。只读任务只接受 canonical 只读命令类，写型命令必须绑定非空 `write_paths`。未列出的命令不自动获得许可。
   默认使用 `workspace-files`；只有问题已经冻结、无需发现遗漏且只审查随附证据的限定材料复核，才允许
   `self-contained-no-tools` 使该数组为空。此时 `context.material_mode` 必须是
   `prompt-supplied-self-contained`，并由非空、单行的 `supplied_material` 承载全部可用事实。
7. `required_context`：完成该子任务真正需要的规则、spec、RTL/TB；以最小充分为准。原生 no-tools
   模式中的这些路径仅作 provenance，子 agent 不得自行读取。不得为了缩小权限而删掉已知必要的
   上下游、调用链或证据来源；边界暂时未知时，先给模块级只读范围，再由结果收窄。
8. `deliverables` 与 `success_criteria`：分别声明输出和客观验收条件。
9. 工程输入边界：输入只来自 `allowed_paths`；四个 non-workspace source flag 全部保持 `false`，其它资料另建研究节点。
10. 状态分流：当前节点未产出技术结论时只影响该节点；默认父目标保持 `active`。
11. 合同证据绑定：渲染提示必须同时给出 JSON 的仓库相对路径与该文件 SHA-256，并明确哈希只绑定该 JSON，不绑定设计 `contract.md` 或其它上下文。
12. WSL 调度：Windows/Codex 访问本 WSL 工作区时，工程 shell 为 single-flight；主 agent 可以把当前
    唯一 shell ownership 交给一个契约授权的子 agent，但该节点执行期间主 agent 与其它子 agent
    不得并发运行工程命令。只有无 shell 推理或自包含材料复核可以并行。
13. 硬件措辞剖面：`goal/deliverables/success_criteria/supplied_material` 直接使用 RV64 CPU 微架构、流水线、
    事务、时序、缓存一致性、验证或 PPA 术语；`render` 追加同一硬件语境前缀。反引号包裹的 RTL 标识符
    和 PMP、RISC-V 特权级、访问异常、内存保护、权限检查、store probe 等架构术语保持原样。本规则不做
    关键词拒绝或自动改写，也不改变工具、shell、路径、上下文或推理能力。
14. 本地作用域开场：渲染提示首屏固定声明工作对象为本地 RV64 Verilog/SystemVerilog 处理器，工程输入、
    动作和产物只覆盖合同授权的本地 RTL、spec、testbench、EDA 工具与生成证据，不使用非工作区来源。
    JSON 中的外部来源布尔字段继续逐项审计，但不把无关跨领域场景复制到 RTL 技术目标。
15. 多义术语限定：自然语言首次使用可能跨领域解释的词时，补齐对象、层级、作用域和工程目的；例如
    “testbench 接口异常激励”“流水取消信号”“checkpoint 状态恢复”“load replay 生命周期”与
    “compile-success RTL source mutation”。这是语义完整性要求，不是关键词黑名单或词法替换器。

使用 `.github/skills/prepare-rtl-task-contract/SKILL.md` 和其中脚本生成、校验、渲染 JSON 契约。存在 task-run 时，契约保存到
`.github/task-runs/<run-id>/subagent-contracts/`，并在 `dispatch-log.md` 记录路径与 SHA-256；没有 task-run 的短任务也必须把渲染后的同等字段完整放进提示。
契约工具的仓库信任锚固定为脚本所在工作区；`--repo-root` 只允许显式重复同一 realpath，不能重绑定到工作区外伪根。
`create` 自动把输出 JSON 的精确路径加入 `allowed_paths`；旧 JSON 不含自路径时仍可校验和渲染。
`render` 从实际 JSON 文件计算证据绑定，禁止手工填写无路径 SHA 或把它与设计合同哈希混用。

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
