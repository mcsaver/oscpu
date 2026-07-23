# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: active rules root shims
- `focus_scope`: non-history
- `token_estimate`: 2124 / 2400

## Profile Suggestions
- `github-index` score=19 matched=active, requested-profile, root, rules command=`scripts/agent-e2e.sh --profile github-index`
- `agent-system` score=4 matched=active, root, rules, shims command=`scripts/agent-e2e.sh --profile agent-system`
- `linux-device` score=2 matched=root command=`scripts/agent-e2e.sh --profile linux-device`
- `nemu` score=2 matched=active, root command=`scripts/agent-e2e.sh --profile nemu`
- `rv64-linux` score=2 matched=root command=`scripts/agent-e2e.sh --profile rv64-linux`

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
- `tokens`: 1639
- `heading`: 当前状态
- `summary`: - 2026-07-20（startup recall 新鲜度闭环）：**`brief` 的 “live-first” 是 live 索引快照，不等于每次直接读文件；修改 active skill/instruction/profile 后若不刷新，旧 chunk 仍可能形成结构合法但内容过时的 task-run**。v8k 收尾 reviewer 实际抓到首份 completed agent-system run 仍召回旧 no-tools skill，故该 run 不再作为最终新鲜度证据。现在 `agen...

## 当前状态

- 2026-07-20（startup recall 新鲜度闭环）：**`brief` 的 “live-first” 是 live 索引快照，不等于每次直接读文件；修改 active skill/instruction/profile 后若不刷新，旧 chunk 仍可能形成结构合法但内容过时的 task-run**。v8k 收尾 reviewer 实际抓到首份 completed agent-system run 仍召回旧 no-tools skill，故该 run 不再作为最终新鲜度证据。现在 `agent-e2e.sh` 在 context brief/resolve 前强制 `rebuild`，失败会令 recall 与整轮非零；刷新日志进入 `evidence/context-live-index-refresh.log`。实现以 `os.walk(topdown=True)` 在目录层剪枝 DB-first `.github/{memory,task-runs}`、历史 `.github/{archive,shujuku_aireview}`、backup/cache/tmp/runtime/raw-evidence 与显式 exclude；反例 monkeypatch 保证被剪枝文件连 `index_one_file` 都不能触达。后续 DB audit 又抓到旧 rebuild 会把“未扫描的排除区”误标 missing，现已把 missing 更新收窄到 scope 内且未被排除的旧行，并用真实 SQLite 反例固定。初版全 `.github` 扫描因 72,717 个 task-run 文件产生分钟级等待而被精确终止，最终 active-only rebuild 为 130 files/16.69s；一次包含 memory 的修复性 rebuild 为 174 files/16.98s，随后 DB-first audit PASS。`2026-07-20-no-tools-rtl-subagent-contract-3` 为 agent-system 10/10 completed，brief 明确命中新 `prompt-supplied-self-contained`；`2026-07-20-active-rules-root-shims` 因根 shim 已增长到 853 tokens 而旧 smoke 预算 800 正确 blocked，预算改为 1200 后 `...-2` 的 github-index contract completed，剪枝/load/DB-first/publication 均 PASS。稳定规则：手工 brief 在修改普通规则后用 targeted `refresh`；正式 profile 自动 active-only rebuild；retained memory 先 `update-stored`；任何旧索引、超时中断或 blocked run 都不能被后续节点 PASS 覆盖。该机制提高本地 RTL 协作证据新鲜度，不规避或削弱平台审查，也不构成 RTL/PPA 结论。
- 2026-07-20（v8k 原生最小权限纠偏）：**自包含只读 reviewer 的实际权限现在与 JSON 契约精确一致，不再用口头 no-tools 覆盖 JSON 中虚列的 `rg`**。canonical `context_policy` 新增 `prompt-supplied-self-contained`，仅允许 `read-only-review`，机器强制 `allowed_commands=[]`、`write_paths=[]`、四项外部访问全 false、非空且逐项单行的 `supplied_material`；来源路径仅作 provenance，子 agent 不得自行读取。`workspace-files` 仍要求非空 canonical command，旧版只有 `required_files` 的 context 保持 validate/render 兼容。generator audit PASS、in-memory self-test 20/20、CLI self-test 18/18，反例覆盖夹带命令、缺材料、多行提示结构、实现任务滥用与 workspace 空命令。真实 `fork_turns=none` reviewer 在 tools/shell/filesystem/network/write 全 false 下 verdict=pass，并明确未自行读 JSON、复算 SHA 或重放测试，故其文本结论不冒充验证。首次 agent-system forward run 因显式 `py_compile` 留下 untracked `.pyc` 正确 blocked；删除该精确可再生产物后，第二次 10 个执行节点虽全 PASS，startup brief 仍因新事实尚未进入 retained memory 而整体 blocked，两个失败包均保留。本规则用于准确描述本地 RV64 Verilog/SystemVerilog 最小权限和隔离 `review_pending`，不以改变、规避或削弱平台审查为目标，也不承诺零误判；父目标继续 active。
- 2026-07-19（v8i 第三次真实复用）：**bounded reviewer 合同必须把反例持续转成生产门控，而不能把“安全措辞”误解成减少审查**。合同 reviewer 在 no-tools/no-shell/no-file/network/write、只读冻结摘要边界下给出两个真实 blocker：result→formal 跨周期重复完成窗口与不可背压第九结果无槽；父 agent 保持 active，并把它们转成 pending capability、精确信用、directed TB 和 compile-success mutation。独立 implementation reviewer 同样 verdict=pass/blocker=0，但三个 blind spot 逐项归档；其中 FIFO 同槽 replacement 和 stale-generation raw transport 已继续转成 assertion/directed，未完成的 fixed-priority formal liveness 明确保留 residual RED。v8f 回归还发现旧 test force 只改 raw idx且 Icarus 快照 RHS 的证据漂移，修复为逐矩阵点重建 full PID/query boundary，证明 reviewer 结果必须由跨版本回归复核。稳定措辞仍是“本地 RV64 Verilog/SystemVerilog 数字电路设计与验证、指定路径、最小权限、无外部访问、独立反例复核”；目的在准确范围与可审计性，不规避平台检查、不保证零误判，也不把 reviewer pass 当 RTL/PPA promotion。
- 2026-07-19（v8h 第二次真实复用）：**reviewer `pass` 必须和其证据视野一起归档，不能被后续召回压缩成无条件通过**。本轮 contract review 的两个 gap 分别转成五源 full-PID claim mutation 与 ROB pair tail/tail+1 结构证明；实现 review 使用另一个 SHA 绑定 JSON，实际边界收紧为 no-tools/no-shell/no-file/network/write，只消费冻结摘要。结果虽为 pass，`dispatch-log.md` 和结构化 JSON 仍强制记录“未独立复核完整 actual cone、持续背压/wrap/death-edge 无形式证明、stale raw drain 的 QoS/source-hold 风险”；父 agent 在 review 期间保持 active，单节点状态不传播成长期目标停止。稳定规则：合同 SHA 只绑定对应 JSON；actual runtime 权限可以更窄；文本反例必须转成 spec/TB/mutation/audit，未转化项进入 residual RED。该工作流提高可审计性和领域消歧，不规避平台检查、不保证零误判，也不替代 RTL/PPA hard gate。

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
