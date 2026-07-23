# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: true ooo long latency
- `focus_scope`: non-history
- `token_estimate`: 1867 / 2400

## Profile Suggestions
- `github-index` score=16 matched=requested-profile command=`scripts/agent-e2e.sh --profile github-index`
- `nemu` score=2 matched=long, true command=`scripts/agent-e2e.sh --profile nemu`
- `yosys-sta` score=2 matched=latency, ooo command=`scripts/agent-e2e.sh --profile yosys-sta`

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

### .github/memory/modules/npc.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-8
- `tokens`: 1382
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-20(RV64-v8n-true-ooo-long-latency): **当前 142-file vsrc closure 与 exact proof provenance 下 OOO-1 scoped GREEN；同 design_id 的 OOO-2 记录保留，architecture/PPA 继续 RED/unpromoted**。生产 RTL 功能未改；`tb_ooo_int_backend` 先消耗一整圈 ROB，使 old/yo...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-20(RV64-v8n-true-ooo-long-latency): **当前 142-file vsrc closure 与 exact proof provenance 下 OOO-1 scoped GREEN；同 design_id 的 OOO-2 记录保留，architecture/PPA 继续 RED/unpromoted**。生产 RTL 功能未改；`tb_ooo_int_backend` 先消耗一整圈 ROB，使 old/young full ProducerId 均带非零 generation，再分别建立真实 cacheable/no-fault/no-store load request 的 MIQ/tracker owner、真实迭代 MUL owner 与 DIVU owner。每个 old owner 从 request/issue accept 到 formal WB 前持续 exact-live；其间 8 个不同 young 各完成 issue accept 和 `ex*_wb_valid && producer_open && !kill` authorized exactly-once WB，并精确出现 4 个 issue0+issue1 同周期 accept。实际 ROB `valid` census 重建的 full-PID set 必须等于 old+8 young 共 9 项；old WB 前 commit 为 0，之后 commit0/1 按派发 PID+PC ledger 严格有序 exactly-once，最终 ROB/IQ/MIQ/tracker/MulDiv owner/free-list 排空。`make -C npc/rv64 check-true-ooo-long-latency` 的 release/assert 6/6、`serial_issue1`、MIQ/MulDiv issue1 freeze、retire-before-head-done 与三类 load/MulDiv PID truncate 共 7/7 compile-success activated mutation、checker+manifest unit 22/22、fresh module 106/106、contract `400>=89` PASS。scope 仅是 long-latency tolerance；异常/device load、store/顺序、kill/recovery、OOO-3、其它 gate 与 PPA 未证明。证据 `.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/`。
- 2026-07-20(RV64-v8n-directed-evidence-workflow): OOO-1 evidence builder 只发布精确命令、定量 marker、源码 pre/post hash、proof/harness exact provenance 与完整 vsrc design_id 均一致的记录。新增共享 `directed_evidence_manifest.py` 以临时文件 parse 后 atomic replace，只保留同 schema/design 的 sibling；单测固定 OOO-2 preservation、stale design drop 和 pre-replace fault 保持旧文件 byte-identical/parseable，OOO-2 builder 也复用同 helper。首轮 no-tools contract review 的 B1-B9 已全部机械闭合，revision 与独立 implementation review 均 strict pass；两者 JSON 只允许 prompt-supplied local RV64 RTL facts，`allowed_commands=[]`、`write_paths=[]`、network/accounts/credentials/external_services=false。合同 JSON SHA 与 design/proof digest 分离，避免协作审计哈希被误作 RTL 证据。
- 2026-07-20(RV64-v8m-selective-scheduling): **当前 design/proof provenance 绑定下 OOO-2 selective scheduling scoped GREEN；architecture inventory 仍 OVERALL RED，PPA unpromoted**。本轮未改生产 RTL；根因是旧 `architecture_hard_gates.py` 只看到 `mem_issue_res_valid_q` 对 issue0 的局部停发，未沿生产数据流验证 Universal owner 下 issue1 仍可选择、接收并 fire 独立 ALU。checker 现绑定 Backend owner、Dispatch/IQ 转发、selector owner-to-first-ALU steering、IQ issue1 valid 独立性及 Backend issue1 ready/fire 独立性，并要求精确命令、11 文件哈希与日志 manifest。真实 dispatch load 在 `mem_req_ready=0` 下建立并保持 reservation；older independent ALU 以及“older dependent + same-resource memory”之后的 younger independent ALU 均由 issue1 前进，PC 与完整 ProducerId 精确命中，且无 flush/ROB kill/recovery，`global_freeze_cycles=0`。release/assert focused 4/4、5 个 actual-source compile-success semantic mutation 5/5、checker unit 18/18、fresh module 106/106、contract `400>=89` PASS；full lint 仍为继承 rc=2/115 warnings。独立 no-tools reviewer verdict=pass/blocker=0；残余包括非穷尽 formal、未对任意 older-valid 与每个 valid/ready/fire 子条件逐一 mutation，以及其余架构门全红。永久入口 `make -C npc/rv64 check-selective-scheduling`；证据 `.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/`，不得据此宣称全核 OoO 或 PPA 晋级。
- 2026-07-20(RV64-v8m-workflow-e2e): v8m 已进入 DB-first retained memory、snapshot、evidence index 与 strict guard。`brief selective scheduling Universal reservation issue1 --profile npc-dev --focus-scope non-history` 从当前 NPC memory 命中本条工程事实；`npc-dev`、canonical `no-tools-rtl-subagent-contract` 的 `agent-system`、`db-first-stored-memory-audit` 的 `github-index` 均 completed，strict guard 也据当前工作树推导并接受三项证据。首个混合 `rtl-no-tools-subagent-contract-selective-scheduling` agent-system run 虽 10/10 节点 PASS，因规则层无独立 primary 而正确 blocked，失败包保留，不能被节点绿覆盖。手工 v8m task-run 已登记 152 个 evidence assets。稳定规则：RTL 子 agent 任务写成“本地 RV64 RTL/验证/证据复核”，明确仓库路径、只读/写边界、无网络/凭据/部署/外部目标；冻结材料足够时使用 JSON 固化的 self-contained no-tools 契约。该措辞用于精确界定正常工程范围，不是规避平台审查。

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
