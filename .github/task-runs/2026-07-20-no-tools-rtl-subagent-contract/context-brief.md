# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: no tools rtl subagent contract
- `focus_scope`: non-history
- `token_estimate`: 2317 / 2400

## Profile Suggestions
- `agent-system` score=21 matched=contract, no, requested-profile, rtl command=`scripts/agent-e2e.sh --profile agent-system`
- `contracts` score=5 matched=contract, no, tools command=`scripts/agent-e2e.sh --profile contracts`
- `yosys-sta` score=5 matched=contract, no, rtl, tools command=`scripts/agent-e2e.sh --profile yosys-sta`
- `github-index` score=4 matched=contract, no command=`scripts/agent-e2e.sh --profile github-index`
- `display-vga` score=3 matched=contract, no command=`scripts/agent-e2e.sh --profile display-vga`

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
- `lines`: 11-51
- `tokens`: 809
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

4. 在 `dispatch-log.md` 逐字记录渲染结果中的 JSON 路径和 SHA-256。子 agent 返回后，对照契约检查越界读取、未授权写入、外部访问和缺失产物；需扩展范围时生成新版本契约，不在原提示后模糊追加权限。
5. 若平台暂不展示或不处理某个合法 RTL 子任务，只把该子任务记为 `review_pending`，保留原始请求、契约哈希、时间和平台提示；不得通过改变 RTL 语义来重试，也不得据此关闭长期父目标。
6. 将 reviewer 的每个可操作反例登记到 `dispatch-log.md`，并转成 spec 修订加定向 TB、
   compile-success mutation 或 fail-closed 静态审计；文本反例本身不能作为 GREEN 证据。若冻结摘要
   已充分，实际派发进一步使用 `no tools / no shell / no file access / no network`，并记录这是比
   JSON 授权上限更窄的运行边界。

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-18
- `tokens`: 643
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`；非平凡任务优先用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile>` 生成 bounded 上下文包。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境 e2e、自检或降低不确定性，读取 `.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，先用 `scripts/agent-e2e.sh --list-profiles` 选 profile，再生成 task-run 证据包。
7. Windows 侧访问本 WSL 工作区时，PowerShell 只作为 `wsl.exe` 启动器，工程命令统一交给 Ubuntu：`wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'`；若 agent/CLI 已在 WSL/Linux 原生 shell 内运行，则直接使用原生命令，不再套 `wsl.exe`。
8. 历史 task-run/evidence 回查使用 `python3 scripts/github_index_db.py runs --profile <profile>` 和 `python3 scripts/github_index_db.py evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志。
9. 交付前必须显式切换“实现者人格”和“审查者人格”：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；冲突未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。

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

### .github/memory/modules/agent-system.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-1
- `tokens`: 8
- `heading`: Agent System 模块笔记
- `summary`: Agent System 模块笔记

# Agent System 模块笔记
