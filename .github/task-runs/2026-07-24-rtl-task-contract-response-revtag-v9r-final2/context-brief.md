# Agent Brief

- `recall_status`: failed
- `profile`: agent-system

WARN context brief generation failed; profile dispatch is not green.

## Diagnostic

```text
# Agent Brief

- `ok`: false
- `recall_status`: failed
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rtl contract response final2
- `focus_scope`: non-history
- `token_estimate`: 3714 / 4000
- `error`: no independent primary focus match outside required/core/profile/optional paths: rtl contract response final2

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

### .github/e2e/modules/agent-system.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-8
- `tokens`: 1439
- `heading`: agent-system E2E Contract
- `summary`: - **范围**: `AI_ENVIRONMENT.md` 一页导航、`.github/AGENTS.md`、入口 shim、canonical contracts、agents、instructions、memory、task-runs、e2e profile、review routing、branch-health dashboard、observability/run-manifest、runtime artifact/source boundary、commercial delivery packag...

# agent-system E2E Contract

- **范围**: `AI_ENVIRONMENT.md` 一页导航、`.github/AGENTS.md`、入口 shim、canonical contracts、agents、instructions、memory、task-runs、e2e profile、review routing、branch-health dashboard、observability/run-manifest、runtime artifact/source boundary、commercial delivery package、state traceback、Reviewer/Inspector gate、非交互软环境入口。
- **上游**: 用户目标、已有 memory、蓝图。
- **下游**: 所有模块 profile 与跨模块图。
- **L0 gate**: `e2e_agent_system_discovery` 检查规则入口、e2e 目录、task-run 模板、memory、delivery contract、商业交付文档、`scripts/package-ai-dev-env.sh`、`scripts/agent-env.sh` 与 runner source hook、半初始化 `YSYX_AGENT_ENV_SOURCED` 继承自修复钩子、外层工具控制符命令卫生文档钩子（例如 `rg -e` 替代正则中的 `|`）、Codex/WSL single-flight 文档钩子（不要并发启动多个 `wsl.exe` 做工程命令；`Wsl/Service/E_UNEXPECTED` 先按宿主 WSL 健康问题处理；工程命令回到 `scripts/agent-run.sh` 入口）、收尾 `scripts/agent-e2e.sh --guard --guard-mode strict` 证据守门（按触碰路径推荐 profile，要求本轮 task-run evidence 晚于触发文件，且包含 completed report、带 `recall_status=complete` 的 `context-brief.md`、`profile-resolve.md`、`evidence-index.md`；context brief 失败必须使 runner 非零，缺证据或 DB 召回产物时阻断 strict 模式）、NEMU/NPC 场景隔离运行时边界（`nemu-dev*` 只能展开到 `nemu`/`software-flow`，`npc-dev` 只能展开到 `npc`/`software-flow`，旧 `nemu-ubuntu*` 集成 profile 保留跨模块节点），以及可配置 active scenario runtime isolation（默认 `warn`，NEMU-only/NPC-only dispatch 发现对侧活跃进程只告警并继续；超过 `AGENT_E2E_SCENARIO_RUNTIME_STALE_SECONDS` 默认 86400s 的对侧 stale 进程会失败；`strict` 拒绝所有对侧冲突；`off` 跳过）、持久 agent/e2e/review-routing/branch-health/observability/state-traceability/runtime-artifacts/delivery 源文件是否已被 Git 跟踪，以及 `report.sh` 的 context brief、run manifest、state_traceback、task-run 文本 artifact sanitizer、runtime evidence index-only 和 Markdown DB 归档 hook 是否定义、调用并限制在当前 run dir。
- **启动/终结 fail-closed gate**: runner 在生成 `context-brief.md` 前先 `rebuild` live 索引，通过目录级剪枝排除 DB-first 的 `.github/{memory,task-runs}/**` 与历史 `.github/{archive,shujuku_aireview}/**`，只刷新 active rules/profile/root shims，并保留 `evidence/context-live-index-refresh.log`；scoped rebuild 的 missing 更新只覆盖实际扫描且未排除的旧行，排除区状态必须保持。刷新失败会阻止旧规则 chunk 形成 complete recall，同时避免为 active-rule 刷新重复扫描海量历史证据。`context-brief.md` 与 `profile-resolve.md` 必须是原子落盘的普通文件；前者绑定硬预算内 canonical+profile+独立 focus chunks，并要求逐 chunk 完整 metadata/非空正文；后者绑定连续编号、唯一 ID 的非空 Nodes 闭包。completed 只允许全节点 PASS，run/report/manifest/index/dispatch 身份与时间一致，resolve/manifest/report/dispatch/`nodes.tsv` 绑定节点全元组；validator 同时递归解析当前 live profile include closure，逐节点复核 `node/source/module/owner/function/status/inputs/outputs`，拒绝多产物一致改写。dispatch 保持 canonical 全局事件顺序与 11 字段 payload；节点首要 evidence 必须是 canonical `evidence/<node_id>.log`，辅助指针也必须属于 actual indexed ordinary asset。strict guard 拒绝 diagnostic/header 注入、header-only/空壳截断、profile/count mismatch、未来时间、未知 deletion baseline、symlink run/evidence/artifact；`evidence-index.md` 的路径/尺寸/SHA 与 actual ordinary evidence 逐项重算。recall、resolve、report render、sanitizer、index、marker、staged sync、publish 任一失败都传播为非零/blocked。completed 先精确同步 staged Markdown，再生成七 artifact marker 与严格 EOF 的 `completion-publication.md`，最后由 `publish-task-run` 在单 SQLite 事务内复核并提交；普通 archive/promote/migrate/backup/rehydrate 不得创建或撤销 completion publication。失败撤销本次 live marker/publication 并重渲染 blocked，既有已提交 publication 不会被通用同步误删；strict guard 同时复核 marker、publication 与 DB/live 精确集合。
- **Bounded recall/publication route lock**: CLI/API 与 runner 的 brief 默认硬预算统一为 2400 tokens，显式 `E2E_CONTEXT_BRIEF_MAX_TOKENS` 覆盖仍须传入 recall CLI 并保留 fail-closed；runner 将 task slug 拆为至多 8 个非泛化语义词、只用 `--profile` 绑定 profile，并固定 `focus_scope=non-history`，使旧 task-run/report/evidence 不能为同 slug 重跑提供独立 primary focus，纯生命周期 slug 必须失败；通用 brief 默认 `all` 以保留显式历史召回。普通 backup 和 snapshot-stored 对 task-run publication 的 direct/default 路由都必须过滤，audit 不得出现 publication backup violation。

### .github/agents/agent-system.agent.md#chunk-0001

```
