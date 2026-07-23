# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: stored memory instret retirement
- `focus_scope`: non-history
- `token_estimate`: 2097 / 2400

## Profile Suggestions
- `github-index` score=18 matched=memory, requested-profile, stored command=`scripts/agent-e2e.sh --profile github-index`
- `abstract-machine` score=2 matched=memory command=`scripts/agent-e2e.sh --profile abstract-machine`
- `agent-system` score=2 matched=memory, stored command=`scripts/agent-e2e.sh --profile agent-system`
- `fceux-am` score=2 matched=memory command=`scripts/agent-e2e.sh --profile fceux-am`
- `software-flow` score=2 matched=memory command=`scripts/agent-e2e.sh --profile software-flow`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile github-index`

## Missing Paths
- `.github/agents/github-index.agent.md`
- `.github/memory/modules/github-index.md`

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

### .github/e2e/profiles/github-index.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 67
- `heading`: node_id|module|function|owner_agent|inputs|outputs
- `summary`: github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

# node_id|module|function|owner_agent|inputs|outputs
github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

### .github/memory/modules/agent-system.md#chunk-0002

- `kind`: memory-module
- `lines`: 2-7
- `tokens`: 1612
- `heading`: 当前状态
- `summary`: - 2026-07-21（V9C task-specific e2e DB-first focus ordering）：**task slug 的领域词必须先有当前non-history 独立 focus，不能由同一旧 task-run 自证**。反例 `.github/task-runs/2026-07-21-rv64-instret-retirement-closure-revtag-v9c/` 在五个 NPC 合同节点5/5 PASS 时仍因 `no independent primary focus...

## 当前状态

- 2026-07-21（V9C task-specific e2e DB-first focus ordering）：**task slug 的领域词必须先有当前non-history 独立 focus，不能由同一旧 task-run 自证**。反例 `.github/task-runs/2026-07-21-rv64-instret-retirement-closure-revtag-v9c/` 在五个 NPC 合同节点5/5 PASS 时仍因 `no independent primary focus match` 正确保持 blocked；根因是当时 INSTRET 稳定结论尚未通过 `update-stored` 进入 module memory，且多出的 `closure` 不存在于独立 focus。`project-status` 属于 core chunk，不能单独替代独立 focus。先用官方 `update-stored` 发布`.github/memory/modules/npc.md`，再把 slug 收敛到确实存在的 `rv64 instret retirement` 后，bounded brief 命中该 module chunk 并 complete；随后 `npc-dev` 5/5、`agent-system` 10/10、`github-index` 1/1 均完成原子 publication。稳定顺序是：业务证据闭合 → DB-owned module memory 发布 → 同领域词 task-specific e2e → strict guard。该规则保留 non-history fail-closed、历史隔离和全部节点验证强度，只消除收尾顺序歧义；blocked 反例保留审计但不计为完成证据。
- 2026-07-21（v8x 子 agent 合同与 shell ownership 实战纠偏）：**审查节点超时和合同顺序错误都必须显式降级，不能靠结果内容追认 PASS**。真实 `workspace-files/read-only` reviewer 在主 agent 交出唯一 WSL shell ownership 后完成合同哈希、focused marker 与两项 mutation witness 的部分检查，但未在限定窗口内返回 verdict；主 agent 中断该节点、收回 shell ownership，并在 dispatch log 登记 `review_interrupted`，其部分观察不授予 PASS。随后一次 no-tools follow-up 虽返回 pass，却因新版 JSON 尚未先走 canonical `create -> validate -> render`，结果只能保存为 `candidate-only`。正式 v2 合同改为真正的 `prompt-supplied-self-contained`，SHA `1b1d568b5ac9e2cec6bb7033ee7233ece6d7a6f2206927effcd39303e130678f`，无 tools/shell/files/write/external access，原样派发并允许 unknown、反例、scope extension 与 inconclusive，最终仅对冻结 V8X 证据判 pass/blockers=0。稳定规则：shell-holding 节点必须有明确归还或由主 agent 可审计中断回收；任何补派均先生成新版本合同，不口头扩权、不追认 candidate；限定材料 reviewer 不冒充完整仓库审查。准确本地 RV64 RTL 术语用于消歧，能力分档、反例强度与平台审查边界保持不变。
- 2026-07-21（v8w 本地 RV64 RTL 子 agent 实战）：**硬件专业措辞、最小真实权限与强反例复核在不削弱模型能力的前提下再次形成可审计闭环**。两轮独立 reviewer 均由 `prepare-rtl-task-contract` 的 canonical `create → validate → render` 生成 versioned `workspace-files`/read-only JSON；正文明确对象为本地 RV64 Verilog/SystemVerilog 处理器，把 `kill/drop/flush/recovery/mutation` 分别限定为流水线事务失效、bridge terminal、checkpoint 恢复和 compile-success RTL 验证变异，并保留 counterexample、UNKNOWN/GAP、scope-extension 与否决晋级的结论出口。合同显式冻结 allowed files/commands、零 write paths，排除网络、账号、凭据和外部服务；Windows→WSL 工程 shell ownership 在主 agent 与 reviewer 间单一交接并显式归还。v2 reviewer 的 late-old-drop/new-head 与纯选择性 A/D write drain 缺口已转成 directed TB、guard 反例和新增 mutation，v3 合同 SHA `082356f2bf7338a69d71b8da064421e1717764dbbe642add7c2d5d3033ebf3e5` 仍保留真实 backend+bridge 双 owner 联合轨迹为 verification GAP，父 goal 保持 active。该规则不采用关键词黑名单、语义隐写或自动改写，不承诺消除平台误分类，也不以绕过平台检查为目标；它只提高本地硬件任务的对象/层级/作用域/工程目的准确性，技术能力和审查强度保持不变。证据 `.github/task-runs/2026-07-21-rv64-v8w-speculation-recovery/`。
- 2026-07-21（RV64 硬件专业措辞 v10b 实战闭环）：**canonical RTL 子任务合同现以正向本地范围声明消歧，不靠关键词黑名单、隐匿、自动改写或能力缩减**。`rv64-hardware-professional` 首段固定声明工作对象为本地 RV64 Verilog/SystemVerilog 处理器，输入/操作/产物仅限合同授权的 RTL、规格、testbench、EDA 与证据；歧义术语必须显式补足对象、抽象层级、作用域和工程目的，例如 pipeline transaction `kill/flush`、checkpoint recovery、load replay、testbench fault stimulus、compile-success RTL mutation、datapath bypass 与 privilege-level transition。JSON policy/contract 已机器化 `domain_reference`、`positive_local_scope_preamble_required`、四维上下文与 `ambiguous_terms_require_hardware_context`；该层不扫描词表、不改 RTL 标识符，也不改变 tools、shell、filesystem、context、write_paths、反例搜索、推理或结论出口。旧 e2e 文本钩子错误地把 no-tools 等同于固定自然语言句式，已改为校验真实机器权限形状 `allowed_commands=[]`、`write_paths=[]` 与“不执行工程命令或仓库读取”；generator audit、25 项 self-test、20 项 CLI self-test 均 PASS。真实 v6 mutation-reconstruction reviewer 使用 versioned 合同 SHA `68e3ce55eb21c30b80b1de162be08bcf72260affee9dd7281d600ad2e84d1b46`，只消费冻结本地 RTL 材料且不执行工程命令/仓库读取，给出限域 PASS；`agent-system` run `.github/task-runs/2026-07-21-rv64-hardware-professional-task-contract-revtag-v10b/` 10/10 completed。v10 的生成 bytecode-cache 与 v10a 的陈旧文本钩子失败包均保留，证明规则通过真实 forward-test 纠偏，而非修改报告造绿。

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
