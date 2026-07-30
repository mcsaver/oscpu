# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: schema aware rtl evidence publication receipt closure
- `focus_scope`: non-history
- `token_estimate`: 2356 / 2400

## Profile Suggestions
- `agent-system` score=22 matched=closure, evidence, publication, requested-profile, rtl, schema command=`scripts/agent-e2e.sh --profile agent-system`
- `github-index` score=3 matched=closure, evidence, publication command=`scripts/agent-e2e.sh --profile github-index`
- `nemu` score=3 matched=aware, evidence, schema command=`scripts/agent-e2e.sh --profile nemu`
- `yosys-sta` score=3 matched=closure, evidence, rtl command=`scripts/agent-e2e.sh --profile yosys-sta`
- `software-flow` score=2 matched=aware, evidence command=`scripts/agent-e2e.sh --profile software-flow`

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
- `lines`: 1-9
- `tokens`: 527
- `heading`: agent-system.tsv
- `summary`: @include|discovery|||| / three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|AI_ENVIRONMENT.md;.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintai...

@include|discovery||||
three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|AI_ENVIRONMENT.md;.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证一页导航、canonical 路径与 Database/Skill/Agent 三层契约
runtime-artifact-boundary|agent-system|e2e_agent_system_runtime_artifact_boundary|agent-system|.github/ai-env/contracts/agent-env-runtime-artifacts.json;.github/ai-env/contracts/agent-env-policy.json;scripts/agent-maintain.sh|验证源码面与运行态 artifact/store 分层边界
state-machine-traceback|agent-system|e2e_agent_system_state_traceback|agent-system|.github/instructions/agent-env-state-machine.instructions.md;.github/ai-env/contracts/agent-env-state-traceability.json;scripts/e2e/lib/report.sh|验证状态机回退和 task-run state_traceback 字段
reviewer-inspector-gate|agent-system|e2e_agent_system_reviewer_inspector_gate|agent-system|.github/ai-env/contracts/agent-env-review-routing.json;.github/ai-env/contracts/agent-env-policy.json;.github/e2e/profiles/agent-system.tsv|验证 Reviewer/Inspector 路由已落成 profile 执行节点
rtl-task-contract|agent-system|e2e_agent_system_rtl_task_contract|agent-system|.github/ai-env/contracts/agent-env-rtl-task-contract.json;.github/instructions/rtl-agent-task-contract.instructions.md;.github/skills/prepare-rtl-task-contract/SKILL.md;.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py|验证本地 RTL 子任务契约可生成、校验、渲染并检出合同外路径 mutation
task-run-status-fail-closed|agent-system|e2e_agent_system_task_run_status_fail_closed|agent-system|scripts/task-run-status.sh;scripts/tests/test-task-run-status.sh;scripts/agent-maintain.sh;AGENTS.md;.github/AGENTS.md;AI_ENVIRONMENT.md|验证长时间 RV64 runner 只有证据完成位才能授权 PASS，并检出 early-exit、cleanup failure 与 HUP
commercial-delivery-readiness|agent-system|e2e_agent_system_commercial_delivery_readiness|agent-system|.github/ai-env/contracts/agent-env-delivery.json;deliverables/ai-dev-env-commercial-v1;scripts/package-ai-dev-env.sh|验证商业交付包装、旧产物归档和 delivery audit
profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile

### .github/agentic-hardware-blueprint.md#chunk-0014

- `kind`: markdown
- `lines`: 140-157
- `tokens`: 461
- `heading`: Schema-aware RTL Evidence Publication and Receipt Closure
- `summary`: - RV64 architecture debt publisher 必须先校验 evidence 的 schema-specific identity，再刷新通用 SHA-256。 / candidate、review contract、review report 等混合 tuple 由一个 canonical verifier 导出精确的 / kind/path/order/fixed hash；missing、extra、remapped、reordered 或 hash-drifted member...

### Schema-aware RTL Evidence Publication and Receipt Closure

- RV64 architecture debt publisher 必须先校验 evidence 的 schema-specific identity，再刷新通用 SHA-256。
  candidate、review contract、review report 等混合 tuple 由一个 canonical verifier 导出精确的
  kind/path/order/fixed hash；missing、extra、remapped、reordered 或 hash-drifted member 都要在
  ledger 写回前 fail closed。
- raw simulator log、current-design JSON 与 independent-review Markdown 是不同 evidence kind：
  raw log 可以只做 hash；JSON 必须核验 design-id、status 与对应 CPU semantic check；Markdown 只有在
  exact tuple verifier 通过后才能免于通用 JSON 解析。不得用“所有非 JSON 都例外”替代字段级分派。
- postflight 不能只从上游 summary JSON 合成 PASS。开始校验时先撤销旧 PASS，再消费每个定向 testbench
  或 Python suite 的 `.log`、`.rc`、唯一测试数和 terminal marker；出现非零返回码、`FAILED`、
  `Traceback`、计数漂移或 marker 缺失时保持 GAP。
- 独立 reviewer 合同应包含 production RTL、实际 Makefile/filelist、所有参与 oracle 的 TB 源码和
  receipt。缺少任何决定结论的 testbench source 时只交付 GAP；修复后使用新的 versioned contract
  复核，并保留旧 reviewer 的反例报告。
- 中断 attempt 使用独立 status/log/output 路径保留，后续 attempt 不覆盖。Windows→WSL 工程命令
  继续 single-flight；只有确认无残留工程进程并完成 shell ownership 交接后才开始下一次 replay。

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-18
- `tokens`: 972
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
9. 交付前必须显式执行“实现者 / 审查者”双角色复核：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；分歧未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。
11. 派发本地 RV64 RTL 子 agent 前读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 明确 RTL/spec/TB/evidence 输入、输出路径、结构化 `command/mode/purpose`、最小上下文、产物和成功条件；只读任务只消费合同列出的本地工程材料并使用不落盘命令，其它资料另建研究节点。
12. 本地 RV64 RTL 子 agent 使用 `fork_turns="none"`，初始提示只采用已校验的合同 `render` 输出；所需设计事实写入合同路径或随附材料，不继承父任务完整对话历史。该上下文隔离不降低模型、源码探索、实现、验证或 PPA 能力。

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

### .github/memory/modules/agent-system.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-2
- `tokens`: 8
- `heading`: Agent System 模块笔记
- `summary`: Agent System 模块笔记

# Agent System 模块笔记
