# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rtl contract response
- `focus_scope`: non-history
- `token_estimate`: 3933 / 4000

## Profile Suggestions
- `agent-system` score=20 matched=contract, requested-profile, rtl command=`scripts/agent-e2e.sh --profile agent-system`
- `contracts` score=3 matched=contract command=`scripts/agent-e2e.sh --profile contracts`
- `nemu` score=3 matched=contract, response command=`scripts/agent-e2e.sh --profile nemu`
- `verilator-tapeout` score=3 matched=contract, rtl command=`scripts/agent-e2e.sh --profile verilator-tapeout`
- `yosys-sta` score=3 matched=contract, rtl command=`scripts/agent-e2e.sh --profile yosys-sta`

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
- `lines`: 30-108
- `tokens`: 1658
- `heading`: 工作流
- `summary`: 1. 只给子任务所需的最小充分上下文；不附带整轮历史或无关日志，也不删掉已知必要的上下游、调用链 / 或证据来源。范围尚未收敛时，从模块级只读输入集合开始。 / 2. 用脚本创建契约。只读复核使用 `read-only-review`，落盘实现使用 `implementation`，验证与 PPA 分别使用 `verification`、`ppa-analysis`。 / 3. 校验并渲染；新派发必须走 canonical `create → validate → render`，把渲染结果原样放进子 age...

## 工作流

1. 只给子任务所需的最小充分上下文；不附带整轮历史或无关日志，也不删掉已知必要的上下游、调用链
   或证据来源。范围尚未收敛时，从模块级只读输入集合开始。
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

3. 校验并渲染；新派发必须走 canonical `create → validate → render`，把渲染结果原样放进子 agent
提示，不要另写一份可能漂移的边界说明。历史 JSON 只保留 validate/render 兼容，不作为新模板。
创建本地 RV64 RTL 子 agent 时使用 `fork_turns="none"`，使通过校验的渲染结果成为完整初始提示；
全部必要设计事实放入 `allowed_paths`、`required_context` 或 `supplied_material`，不要继承父任务完整
对话历史。该上下文隔离不改变模型、推理、源码探索、shell、实现、验证或 PPA 能力。
`create` 会把输出 JSON 自身的仓库相对路径加入 `allowed_paths`；`render` 会从实际文件自动写出
该 JSON 的路径与 SHA-256，并明确该哈希只绑定 JSON，不绑定设计 spec、`contract.md`、RTL 或测试。
不要手工补一条无文件名的 SHA，也不要让子 agent 猜测它绑定哪个合同。
JSON 未通过 validate、或派发文本手工改写了渲染后的工程范围/状态边界时，该轮结果只能登记为
`candidate-only`，不得成为下游硬证据。`scope_extension_request` 必须生成新的 versioned JSON，
重新 validate/render 并绑定新 SHA；不能在旧提示后口头追加范围。

自然语言字段必须使用硬件专业语义。例如用“独立反例复核”“定向变异被测试检出”“取消更年轻流水事务”
和“生产者完成资格”，不把协调层状态或改变平台处理结果写成 RTL 子任务目标。反引号包裹的真实 RTL
标识符不参与措辞替换，`kill_valid_i`、PMP、RISC-V 特权级、访问异常、内存保护、权限检查和
store probe 等合法架构术语必须保留。

子 agent 最终回复第一行使用
`RV64 RTL 结论｜对象=<module/signal/本地证据路径>｜周期/配置=<cycle/config>｜TB/EDA 观测=<结果>｜范围=<PASS/GAP/inconclusive>`。
若本地 JSON 证据校验出现意外接受或拒绝，直接写明 CPU 证据对象、具体 schema 字段、工作区相对路径、
定向单测和返回码。该顺序不得删除反例、未知项、替代假设、原始日志 marker、真实文件名或
`scope_extension_request`。

用户可见进度、子 agent 的 `goal/deliverables/success_criteria/supplied_material` 与终审摘要应优先写成
可直接对应 RTL 的字段级事实：

- `ARPROT[2]` 的 instruction 属性如何参与 `AxiXbar` default-slave 选择；
- `ARVALID && !ARREADY` 周期内 `ARADDR/ARSIZE/ARPROT` 如何由已锁存 transaction owner 保持；
- `PmpChecker` 对当前 instruction halfword 的 2B EXEC 检查，以及 PMEM 尾界 2B 读取的边界 oracle；
- 编译成功的负向 RTL 变体由哪个定向 testbench 标记或断言检出；
- lane0/lane1 instruction page/access fault 的 PC、cause、tval owner 如何经过 capture、pending 与 drain。

真实文件名、module/signal 名、testbench 名、日志 marker 和 JSON schema 字段保持原样；这些标识符可以
包含历史命名。字段级叙述只提高可判别性，不删减源码探索、实现工具、负向 RTL 变体、断言、覆盖矩阵
或任何成功条件。

首次出现多义术语时，明确 module/signal/transaction、pipeline/privilege/memory level、path/cycle/config
范围，并补齐对象、层级、作用域和工程目的。例如写“testbench 在 `OooLoadQueue` response 接口第 N 拍施加异常激励”，或
“编译成功的负向 RTL 变体删除 final-PA query 的 exact-ProducerId 条件，并由指定 directed oracle
检出”。不要用缩写、代称、拆分描述或模糊动词隐藏真实工程动作；这条规则不扫描或拒绝单个词。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate <contract.json>
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render <contract.json>
```

工程命令不是自由文本。`--allow-read-command` 与 `--allow-write-command` 只接收 canonical `COMMAND`；
生成器从 JSON catalog 填入固定的 `mode/purpose` 枚举和中文标签，任务不能自定义 purpose。详细意图写在
`goal/deliverables/success_criteria`，不会增加命令变体。只读任务只允许 canonical 只读命令类，写型命令必须同时声明最小 `write_paths`。工具的 repo realpath 固定为本 skill 所在工作区，
`--repo-root` 不能改绑到其它目录。

需要发现遗漏、核对源码或追踪调用链的 reviewer 默认使用 `workspace-files`。只有问题已经冻结、无需
发现未随附事实且结论明确限定为给定证据时，才使用原生 no-tools 模式；不要给 JSON 虚列 `rg` 或
`sed` 再在提示中口头收紧。每个 `--supplied-material` 是一条单行工程事实，渲染后就是子 agent
可见的全部材料；来源路径仅保留为 provenance。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id <task-id> \

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-22
- `tokens`: 1288
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`；AI 环境入口见 `AI_ENVIRONMENT.md`；非平凡任务优先用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile> --focus-scope non-history` 生成 bounded 上下文包。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境整理、e2e、自检或降低不确定性，先读取 `AI_ENVIRONMENT.md`、`.github/instructions/agent-env-layer-contract.instructions.md`、`.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，再用 `scripts/agent-e2e.sh --list-profiles` 选 profile 并生成 task-run 证据包。
7. Windows 侧访问本 WSL 工作区时，PowerShell 只作为 `wsl.exe` 启动器，工程命令统一交给 Ubuntu：`wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'`；若 agent/CLI 已在 WSL/Linux 原生 shell 内运行，则直接使用原生命令，不再套 `wsl.exe`。Windows/Codex→WSL 工程命令默认 single-flight：主 agent 可以把当前唯一 shell ownership 交给一个契约授权的子 agent，但该节点执行期间其它 agent 不得并发运行工程命令；无 shell 推理或自包含材料复核仍可并行。复杂控制流、管道和 Bash 变量放入仓库脚本，避免被 PowerShell 预先解释。
8. 历史 task-run/evidence 回查使用 `python3 scripts/github_index_db.py runs --profile <profile>` 和 `python3 scripts/github_index_db.py evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志。
9. 交付前必须显式切换“实现者人格”和“审查者人格”：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；冲突未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。
11. 派发本地 RV64 RTL 子 agent 前读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 明确 RTL/spec/TB/evidence 输入、输出路径、结构化 `command/mode/purpose`、最小上下文、产物和成功条件；只读任务只消费合同列出的本地工程材料并使用不落盘命令，其它资料另建研究节点。
12. 本地 RV64 RTL 子 agent 使用 `fork_turns="none"`，初始提示只采用已校验的合同 `render` 输出；所需设计事实写入合同路径或随附材料，不继承父任务完整对话历史。该上下文隔离不降低模型、源码探索、实现、验证或 PPA 能力。
13. 主/子 agent 的任务描述、用户进度和终审摘要使用 `rv64-hardware-professional` 措辞：首句明确本地 RV64 module/signal/transaction、仿真/综合/STA 动作与证据产物；协调状态单独记录，不反复混入 RTL 技术正文。子 agent 最终回复按“RTL 对象或本地证据文件 → 周期或编译配置 → testbench/EDA 观测 → PASS/GAP 范围”组织，并保留反例、未知项、日志 marker 和真实文件名。长期 goal 只引用该措辞剖面，不复制场景清单。该规则不得减少工具、上下文、源码探索、负向 RTL 版本、断言、覆盖或 PPA 能力。
14. 合同 `render` 保持精简，只承载 RV64 RTL/证据对象、周期/配置、TB/EDA 观测、合同绑定和工程动作；派发管线、父任务历史与协调状态留在 JSON/dispatch log。Python/JSON 证据工具复核也以具体 CPU 债务项、RTL 证据路径、字段、定向单测和返回码作主语，不用泛化软件保证叙述替代硬件事实。

请直接打开 [`.github/AGENTS.md`](./.github/AGENTS.md)。

### .github/copilot-instructions.md#chunk-0001

- `kind`: instruction
- `lines`: 1-2
- `tokens`: 11
- `heading`: YSYX 工作区 — 全局指导规范
- `summary`: YSYX 工作区 — 全局指导规范

# YSYX 工作区 — 全局指导规范

### .github/memory/project-status.md#chunk-0001

- `kind`: memory
- `lines`: 1-2
- `tokens`: 8
- `heading`: YSYX 项目状态总览
- `summary`: YSYX 项目状态总览

# YSYX 项目状态总览

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
- `lines`: 1-2
- `tokens`: 8
- `heading`: Agent System 模块笔记
- `summary`: Agent System 模块笔记

# Agent System 模块笔记
