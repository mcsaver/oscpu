# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: rv64 di1 frontend ii1 pc ledger
- `focus_scope`: non-history
- `token_estimate`: 1960 / 2400

## Profile Suggestions
- `npc-dev` score=12 matched=pc, requested-profile, rv64 command=`scripts/agent-e2e.sh --profile npc-dev`
- `rv64-linux` score=8 matched=pc, rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `npc` score=7 matched=pc, rv64 command=`scripts/agent-e2e.sh --profile npc`
- `yosys-sta` score=5 matched=frontend, pc, rv64 command=`scripts/agent-e2e.sh --profile yosys-sta`
- `nemu` score=4 matched=di1, ledger, pc, rv64 command=`scripts/agent-e2e.sh --profile nemu`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile npc-dev`

## Missing Paths
- `.github/e2e/modules/npc-dev.md`
- `.github/agents/npc-dev.agent.md`
- `.github/memory/modules/npc-dev.md`

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

### .github/e2e/profiles/npc-dev.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-5
- `tokens`: 148
- `heading`: npc-dev.tsv
- `summary`: @include|software-flow|||| / npc-sim-contract|npc|e2e_npc_sim_contract|npc|npc/sim + backend manifests|NPC 开发环境入口只检查 NPC 仿真后端合同 / npc-single-contract|npc|e2e_npc_single_contract|npc|npc/single Makefile/Kconfig/vsrc/csrc|NPC single 后端合约入口存在 / npc-soc-contrac...

@include|software-flow||||
npc-sim-contract|npc|e2e_npc_sim_contract|npc|npc/sim + backend manifests|NPC 开发环境入口只检查 NPC 仿真后端合同
npc-single-contract|npc|e2e_npc_single_contract|npc|npc/single Makefile/Kconfig/vsrc/csrc|NPC single 后端合约入口存在
npc-soc-contract|npc|e2e_npc_soc_contract|npc|npc/soc + ysyxSoC CPU ABI|NPC SoC 后端合约入口存在
npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|NPC RV64 Linux 入口合约存在但不跑 NEMU Ubuntu gate

### .github/memory/modules/npc.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-7
- `tokens`: 1394
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-21(RV64-v8z-di1-frontend-ii1): **final design/suite 绑定下 DI-1 scoped GREEN；DI-2/overall 仍 RED，PPA unqualified/unpromoted**。Bridge 层以 registered `S_CACHE_READ` H1 owner 完成 response+successor request 同拍 turnover，未 ready 时由 `S_...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-21(RV64-v8z-di1-frontend-ii1): **final design/suite 绑定下 DI-1 scoped GREEN；DI-2/overall 仍 RED，PPA unqualified/unpromoted**。Bridge 层以 registered `S_CACHE_READ` H1 owner 完成 response+successor request 同拍 turnover，未 ready 时由 `S_RESP` skid 保持 payload；完整 `OooFrontend` 由 `fifo_count+outstanding_count<=depth` reserve 不变量、`OooFetchFlowControl` credit、`OooFetchPcOutstandingSequencer` replacement owner、`OooFetchPacketDecode` 与 registered FIFO sink 构成闭环。focused TB 的 request→response owner 和 enqueue→FIFO dequeue 两个独立 PC ledger 要求 successor PC=当前 owner+8；assert/release steady window 均为 `accepted=responses=enqueues=dequeues=64/max_ii=1`，`run_i=0` 在真实 outstanding response 上阻塞四拍且 payload/owner 稳定，恢复后 16 turnover，最终 `83=83=83=83` 并清零 outstanding/FIFO/ROB/IQ/ghost、free-list=32。`bridge_h1_ready_cut`、H1 state、semantic lookup、FlowControl outstanding/enqueue credit、Sequencer replacement、sink dequeue、successor PC 和 blocked-tail ghost 共 9/9 compile-success mutation 全部动态拒绝，6/6 regression PASS。永久入口 `make -C npc/rv64 check-frontend-ii1` 的 suite `v8z-di1-20260721T082600Z-1762933` 绑定 145-file design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；29-source pre/post identical、56-provenance exact-bound，七个同 design sibling 在原子发布前后逐项保持。本轮未改 production RTL；final no-tools reviewer 合同 SHA `c8aae57c868da65250a8abd59b8c9115fd9de4a87d5f019e303ec81b51dbc58f` 只在冻结材料内 PASS，不替代源码/哈希/波形独立重算。当前架构向量为 `DI-1/DI-3/DI-4/DI-5/OOO-1/OOO-2/OOO-3/OOO-4=GREEN`、`DI-2/overall=RED`；下一步是 DI-2 fetch→decode→rename→dispatch→issue→execute→retire width continuity，不得用 DI-1 外推全核 IPC 或正式 PPA。证据 `.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/`。
- 2026-07-21(RV64-v8y-ooo4-speculation-recovery): **final design/suite 绑定下 OOO-4 scoped GREEN；DI-1/DI-2/overall 仍 RED，PPA unqualified/unpromoted**。`tb_ooo_int_backend` 在同一 focused 二进制覆盖 linear `D0/A1/B2` 与 ROB wrap `D14/A15/B0`：A/B 同时驻留且独立就绪，edge-old A 是唯一分支解析 owner，B 的 issue/resolve/complete/retire 均为 0；full-ProducerId ledger 要求 D/A 各 complete/retire exactly once、B 为 0，恢复后 B 从 ROB/IQ/global holder census 清除且 D/A exact-open。该二进制同时运行 V8D 8192-vector EX strictly-younger removal 与 V8X 真实 backend MIQ + dual-memory bridge 轨迹，已握手 AXI A 精确 drain/drop/pop/terminal，station B 在 pre-AXI 精确终结，`ar=1/drop=2/pop=2/terminal=2/wb=0/commit=0/fill=0/quiet=6`。永久入口 `make -C npc/rv64 check-speculation-recovery` 的最终 design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`、suite `v8y-ooo4-20260721T072758Z-1732951` 通过 focused 2/2、七项 OOO-4 metric、9/9 compile-success dynamic mutation、6/6 regressions；27-source pre/post identical、52-provenance exact-bound。canonical runner 在 live design 上先重建 OOO-3，再原子发布 OOO-4；mutable dispatch log 只属于 task-run/DB audit，不进入 architecture proof，避免后置审查记录污染冻结摘要。最终 no-tools reviewer 合同 SHA `53fefcc58f5072b34aee9eb836326592fad8db54b5d1bad8901f2541d7fdee85` 判 PASS，但不等价于仓库级独立重算。本轮未改 production RTL；F2 runner 只补 direct-Icarus testbench include 根路径。证据 `.github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/`。
- 2026-07-21(RV64-v8x-backend-bridge-recovery): **V8W 指出的真实 backend+bridge active/station 双 owner 联合动态 coverage gap 已关闭；production RTL 未改，OOO-4/overall 仍 RED，PPA unqualified/unpromoted**。`tb_ooo_int_backend_v8x_bridge.svh` 只在 focused 宏下把 `OooIntBackend` 的两 bank request/response、active/tracker/station expected、owner residency、drop、SQ query 与真实 `OooDualMemBridgeWrapper` 全端口直连，TB 仅建模共享 AXI slave。定向轨迹建立同 bank MIQ `[A,B]`、bridge0 `active=A/station=B`，older branch mispredict 单拍且 wrapper `flush_i=0`；唯一 AR 属于 A。迟到 R(A) 同一采样边产生 drop(A)+exact MIQ pop(A)+collector lane2(A)，不产生 response/WB/commit/cache fill；下一周期 station B 晋升，active/tracker/station/residency/head 均为 B，并由 persistent killed authority 在 pre-AXI 精确 drop/pop/terminal，不发 translate/AR。不可变 `{kind,token,epoch,fault_tval}` ledger 强制 A 后 B、各恰一次，最终全状态排空加 6-cycle quiet guard。focused marker 为 `ar=1 drop=2 pop=2 terminal=2 wb=0 commit=0 fill=0 lane1=0 quiet=6 PASS`；两项 compile-success RTL mutation 2/2 目标拒绝、相邻回归 5/5、contract/census PASS。永久入口 `make -C npc/rv64 check-backend-bridge-recovery`；证据 `.github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/`。

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
