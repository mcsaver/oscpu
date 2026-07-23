# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: rv64 memory issue lifecycle
- `focus_scope`: non-history
- `token_estimate`: 1864 / 2400

## Profile Suggestions
- `npc-dev` score=9 matched=requested-profile, rv64 command=`scripts/agent-e2e.sh --profile npc-dev`
- `rv64-linux` score=6 matched=rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `yosys-sta` score=5 matched=issue, memory, rv64 command=`scripts/agent-e2e.sh --profile yosys-sta`
- `nemu` score=3 matched=lifecycle, memory, rv64 command=`scripts/agent-e2e.sh --profile nemu`
- `abstract-machine` score=2 matched=memory command=`scripts/agent-e2e.sh --profile abstract-machine`

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
- `lines`: 2-6
- `tokens`: 1298
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-22(RV64-v9f-memory-issue-lifecycle): **MEM-ISSUE-G1 与 MIQ-FLUSH-G1 在当前 design_id 上 CLOSED；production RTL 未改，full-core arch-stable/PPA 未晋级**。单端口 owner chain 为 iq pair capture → mem_issue_res/mem_issue1_res → selected request...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-22(RV64-v9f-memory-issue-lifecycle): **MEM-ISSUE-G1 与 MIQ-FLUSH-G1 在当前 design_id 上 CLOSED；production RTL 未改，full-core arch-stable/PPA 未晋级**。单端口 owner chain 为 iq pair capture → mem_issue_res/mem_issue1_res → selected request fire → MIQ exact owner；terminal0 edge-old 优先，本地异常不产生 bridge request/MIQ birth，terminal1 只在自身 grant 与选中端口 ready 构成的 fire 上消费。MIQ flush next-state 是 filter_DRAIN(Q_old - exact fired head)；pop_fire 要求 pop_valid、head_valid、exact owner match，owner mismatch 由 assertion 定义为非法输入，无独立 pop_ready；DRAIN 只声明 transport-irrevocable/nokill，不声明已退休。focused 覆盖竞争 owner、两拍 backpressure、15 字段正常身份、5 字段竞争身份、t+1..t+3 quiet window、valid/no-pop head 和 wrapped FIFO；MEM 8/8 + MIQ 3/3 compile-success RTL 验证变异全部动态拒绝，模块 109/109。canonical make -C npc/rv64 check-memory-issue-lifecycle；result a7d87c174882a1acdf7fefd9df3199cefbf2b758d359418595c11fd6d3d334c8，raw 71131cf79e86c99b1d82d982bc08eda5f5ecbe9cb8853a582c69ded9ac218983，design sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc。九项架构 gate GREEN，但 ARCH_STABLE=GAP/blockers=41、PPA=UNQUALIFIED、promotion_eligible=false；不外推 dual-port、任意长 stall/exactly-once、完整系统或正式 PPA。
- 2026-07-21(RV64-v9e-xret-current-design): **XRET-G1 在当前 design_id 上 CLOSED；production RTL 未改，full-core arch-stable/PPA 未晋级**。legality owner 为 `OooFetchHeadClassifyGate`：MRET 仅 M mode 合法，SRET 在 U mode 非法、S mode+TSR 非法、M mode 不受 TSR 阻断；不在 `CsrFile` 重复解码。head0/lane1 exception-versus-system capture 分别由 `OooPendingDispatchArbiter` 与 `OooPendingLane1CaptureGate` 掌握，精确 metadata 经 `OooPendingTrapExitSequencer/OooCsrTrapRequestMux` 进入 CSR。focused marker 为 `cases=7 legal=3 illegal=4 raw_preserved=7 legal_system=3 illegal_arch_trap=4`；四个 full-core marker 分别证明 legal MRET/SRET 各 1 次 request/commit/return，以及 illegal MRET/SRET 各 1 次 precise exception、0 return request、0 faulting commit、cause=2、PC/tval/mepc/mtval exact，lane1 case 另有 `older_lane0=1`。八个 current-source compile-success RTL verification variants 覆盖 mode/TSR legality、false-closed positive control、head0/lane1 routing、PC/tval，另有 2/2 zero-observer sensitivity 配置；全部动态拒绝且 source unchanged。模块 109/109、XRET 单测 10/10、永久入口 `make -C npc/rv64 check-xret-current-mode` 双跑 result/raw/variant/module/focused/program SHA 全相同；result `26f29205929a75a9b824f1ab2b3ac938bb453b8e027f041a0f1e02b364d257a1`，design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。九项 directed architecture GREEN；full-core `ARCH_STABLE=GAP/blockers=44`、`ppa=UNQUALIFIED`、`promotion_eligible=false`，且尚无同设计 full functional aggregate/完整 freeze inputs。
- 2026-07-21(RV64-v9d-fdg-current-design-rebind): **FDG-G1 在当前 design_id 上 CLOSED；production RTL 未改，full-core arch-stable/PPA 未晋级**。分类/admission/final sink 为 `OooFetchHeadClassifyGate/OooFetchHeadPairGate → OooFrontendDispatchGate → OooFrontendBackendDispatchMux → OooCoreTopGlue`；`NpcCoreTop.v` 不是该谓词 owner。precise-trap owner 独立经 `OooPendingDispatchArbiter → OooPendingTrapExitSequencer → OooCsrTrapRequestMux/CsrFile`。focused marker 精确为 `illegal_fp_cases=4 illegal_classified=4 arch_trap=4 fp_disabled=4 backend_blocked=4 legal_fp_cases=1 legal_backend_present=1`；全核 marker 为 `arch_trap_capture=1 capture_pc_match=1 capture_tval_match=1 ordinary_backend_present=0 core_backend_present=0 commit_oracle_hits=1 illegal_fp_commit=0 handler=1 mret=1 cause=2 csr_mepc_match=1 csr_mtval_match=1`。六个 current-source compile-success RTL 验证变体分别覆盖 ordinary/lane1 exclusion、合法正路径、final sink、trap PC 与 trap tval，另有 1/1 commit-observer 非空性探针；全部被定向 oracle 拒绝且 production source unchanged。模块 109/109、FDG 单测 12/12。永久入口 `make -C npc/rv64 check-fdg-arch-trap` 连续双跑 result/raw/variant/module/program SHA 全相同；result `6238dbef481273da7d6acc00156a9bf1a23c90ebfb610498053377b66df88fb0`，design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；九项 directed architecture GREEN，但 full-core `ARCH_STABLE=GAP/blockers=44`、`ppa=UNQUALIFIED`、`promotion_eligible=false`，且尚无当前 official/AM/DiffTest 同源 aggregate。v2/v3 no-tools reviewer 均判 PASS、无 P0/P1；不外推逐 lane commit sensitivity、连续 trap/flush metadata 配对、early-classifier 变体 completeness、任意日志 token 无碰撞或全核晋级。

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
