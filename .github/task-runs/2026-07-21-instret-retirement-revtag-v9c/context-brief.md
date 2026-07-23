# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: instret retirement
- `focus_scope`: non-history
- `token_estimate`: 2156 / 2400

## Profile Suggestions
- `github-index` score=16 matched=requested-profile command=`scripts/agent-e2e.sh --profile github-index`

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
- `lines`: 2-6
- `tokens`: 1296
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-21(RV64-v9c-instret-retirement): **INSTRET-G1 在最终同设计上 CLOSED；production RTL 未改，full-core arch-stable/PPA 仍未晋级**。owner/source-of-truth 是 `OooCommitOutputMux` 最终可见 lane：`retire_count_o=popcount(commit_valid && !commit_excepti...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-21(RV64-v9c-instret-retirement): **INSTRET-G1 在最终同设计上 CLOSED；production RTL 未改，full-core arch-stable/PPA 仍未晋级**。owner/source-of-truth 是 `OooCommitOutputMux` 最终可见 lane：`retire_count_o=popcount(commit_valid && !commit_exception)`，随后唯一连接到`NpcCoreTop.CsrFile.instret_inc_i`；core-local 预 mux 计数不得进入 CSR。Sv39 full-core 程序给出精确event inventory：`exception_lanes=2 exception_zero_delta=2 mret=1 sret=6 sfence_vma=1 control_exact=8 control_total=8 csr_delta_checks=1052`，并由最终 `minstret` 聚合等式关闭尾拍。109/109 动态派生模块测试、3/3 focused 和 3 个 compile-success 当前源码 RTL 变异均通过预期判定；evidence builder/arch-stable validator 现场复算全部 RTL identity、source/log SHA、程序事件、模块membership 与变异源码。永久入口 `make -C npc/rv64 check-instret-retirement`，design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；`INSTRET-G1=CLOSED` 只覆盖 reset 退出、`mcountinhibit.IR=0`、无软件写 `minstret` 的当前合同，不外推 WFI、程序级 FENCE.I、inhibit 切换、软件写/overflow 或 full-core promotion。当前九项定向architecture GREEN，`ARCH_STABLE=GAP/blockers=45`、`ppa=UNQUALIFIED`、`promotion_eligible=false`。证据 `.github/task-runs/2026-07-21-rv64-v9c-instret-retirement/`。
- 2026-07-21(RV64-v9c-instret-retirement): **INSTRET-G1 在最终同设计上 CLOSED；production RTL 未改，full-core arch-stable/PPA 仍未晋级**。owner/source-of-truth 是 `OooCommitOutputMux` 最终可见 lane：`retire_count_o=popcount(commit_valid && !commit_exception)`，随后唯一连接到`NpcCoreTop.CsrFile.instret_inc_i`；core-local 预 mux 计数不得进入 CSR。Sv39 full-core 程序给出精确event inventory：`exception_lanes=2 exception_zero_delta=2 mret=1 sret=6 sfence_vma=1 control_exact=8 control_total=8 csr_delta_checks=1052`，并由最终 `minstret` 聚合等式关闭尾拍。109/109 动态派生模块测试、3/3 focused 和 3 个 compile-success 当前源码 RTL 变异均通过预期判定；evidence builder/arch-stable validator 现场复算全部 RTL identity、source/log SHA、程序事件、模块membership 与变异源码。永久入口 `make -C npc/rv64 check-instret-retirement`，design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；`INSTRET-G1=CLOSED` 只覆盖 reset 退出、`mcountinhibit.IR=0`、无软件写 `minstret` 的当前合同，不外推 WFI、程序级 FENCE.I、inhibit 切换、软件写/overflow 或 full-core promotion。当前九项定向architecture GREEN，`ARCH_STABLE=GAP/blockers=45`、`ppa=UNQUALIFIED`、`promotion_eligible=false`。证据 `.github/task-runs/2026-07-21-rv64-v9c-instret-retirement/`。
- 2026-07-21(RV64-v8z-di1-frontend-ii1): **final design/suite 绑定下 DI-1 scoped GREEN；DI-2/overall 仍 RED，PPA unqualified/unpromoted**。Bridge 层以 registered `S_CACHE_READ` H1 owner 完成 response+successor request 同拍 turnover，未 ready 时由 `S_RESP` skid 保持 payload；完整 `OooFrontend` 由 `fifo_count+outstanding_count<=depth` reserve 不变量、`OooFetchFlowControl` credit、`OooFetchPcOutstandingSequencer` replacement owner、`OooFetchPacketDecode` 与 registered FIFO sink 构成闭环。focused TB 的 request→response owner 和 enqueue→FIFO dequeue 两个独立 PC ledger 要求 successor PC=当前 owner+8；assert/release steady window 均为 `accepted=responses=enqueues=dequeues=64/max_ii=1`，`run_i=0` 在真实 outstanding response 上阻塞四拍且 payload/owner 稳定，恢复后 16 turnover，最终 `83=83=83=83` 并清零 outstanding/FIFO/ROB/IQ/ghost、free-list=32。`bridge_h1_ready_cut`、H1 state、semantic lookup、FlowControl outstanding/enqueue credit、Sequencer replacement、sink dequeue、successor PC 和 blocked-tail ghost 共 9/9 compile-success mutation 全部动态拒绝，6/6 regression PASS。永久入口 `make -C npc/rv64 check-frontend-ii1` 的 suite `v8z-di1-20260721T082600Z-1762933` 绑定 145-file design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；29-source pre/post identical、56-provenance exact-bound，七个同 design sibling 在原子发布前后逐项保持。本轮未改 production RTL；final no-tools reviewer 合同 SHA `c8aae57c868da65250a8abd59b8c9115fd9de4a87d5f019e303ec81b51dbc58f` 只在冻结材料内 PASS，不替代源码/哈希/波形独立重算。当前架构向量为 `DI-1/DI-3/DI-4/DI-5/OOO-1/OOO-2/OOO-3/OOO-4=GREEN`、`DI-2/overall=RED`；下一步是 DI-2 fetch→decode→rename→dispatch→issue→execute→retire width continuity，不得用 DI-1 外推全核 IPC 或正式 PPA。证据 `.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/`。

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

### npc/rv64/design/arch/ooo-core-architecture.md#chunk-0003

- `kind`: markdown
- `lines`: 38-56
- `tokens`: 375
- `heading`: 0.1 v0.3 现状校正摘要（2026-07-11）
- `summary`: - `OooRedirectArbiter` 已进入编译清单并在 `OooFrontend` 生产实例化，fetch redirect PC / 已按年龄律单源化；kill/reason/flush_backend 仍未成为全控制面的唯一来源。 / - pending branch/jump/memory 与 synthetic lane1-ret 相关模块已物理删除；域 B 当前只保留 / system/trap/IRQ/fault 类 pending+drain 主路径。 / - `DecodeStage...

### 0.1 v0.3 现状校正摘要（2026-07-11）

- `OooRedirectArbiter` 已进入编译清单并在 `OooFrontend` 生产实例化，fetch redirect PC
  已按年龄律单源化；kill/reason/flush_backend 仍未成为全控制面的唯一来源。
- pending branch/jump/memory 与 synthetic lane1-ret 相关模块已物理删除；域 B 当前只保留
  system/trap/IRQ/fault 类 pending+drain 主路径。
- `DecodeStage` 当前共 4 个实例（frontend 2、backend 2），int PRF 当前为 5R2W；旧
  “8实例/10R2W”是 07-03 以前的拓扑。
- commit 观察接口仍以分立信号为主，不能称为统一 `commit_event` 类型；2026-07-14
  T4J 已让 CsrFile 的 `minstret` 消费最终两 lane 的 ISA-retirement count，并过滤异常，
  `INSTRET-G1` 的程序级 exception/control delta 长回归仍按 ROADMAP 留证。
- `FDG-G1` 的 `arch_trap -> no backend dispatch`、`XRET-G1` current-mode legality 与
  `MEM-ISSUE-G1` 的 lane1 dequeue/request/MIQ owner 同源、IFU A-update write-drain 已于
  2026-07-12 关闭；IFU-FETCH-G2 的 second-page page-fault byte provenance 同日收窄关闭。
  当前优先继续关闭精确 IFU physical access/lane1 trap、faulting-portion tval、PTE-write PMP、
  MIQ ghost 与唯一 retirement source 等合同，再扩窗口或 memory MLP。

---
