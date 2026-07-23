# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: ooo3 memory ordering producerid reconstruction
- `focus_scope`: non-history
- `token_estimate`: 1795 / 2400

## Profile Suggestions
- `npc-dev` score=8 matched=requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `abstract-machine` score=2 matched=memory command=`scripts/agent-e2e.sh --profile abstract-machine`
- `fceux-am` score=2 matched=memory command=`scripts/agent-e2e.sh --profile fceux-am`
- `software-flow` score=2 matched=memory command=`scripts/agent-e2e.sh --profile software-flow`
- `yosys-sta` score=2 matched=memory command=`scripts/agent-e2e.sh --profile yosys-sta`

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
- `tokens`: 1229
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-21(RV64-v8v-ooo3-memory-ordering): **design-id `sha256:ba9666a7a612bfcb7a07ce58f7953712d4c050eed24da00824b61b74af5e1d27` 的 hash-bound memory-ordering scope 已获 OOO-3 scoped GREEN；DI-1/DI-2/OOO-4/overall 仍 RED，PPA unqualified...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-21(RV64-v8v-ooo3-memory-ordering): **design-id `sha256:ba9666a7a612bfcb7a07ce58f7953712d4c050eed24da00824b61b74af5e1d27` 的 hash-bound memory-ordering scope 已获 OOO-3 scoped GREEN；DI-1/DI-2/OOO-4/overall 仍 RED，PPA unqualified/unpromoted**。一份共享 16-entry retire-resident `OooLoadQueue` 保存 full ProducerId、final PA/byte mask、checkpoint epoch 与完成/terminal/retire 状态；load 只有在 final-PA SQ disposition 允许后可进入 physical request，完成与 retire exact-once。backend-wide checkpoint request/hold/apply 将 front-end/local/memory flush 与 accepted apply 分域，accepted apply 等待 physical store/AMO write lease、SQ active-write 和 DRAIN owner 闭合；physical store/AMO owner 持续到 B、formal WB 和 lane0 exact retire。canonical `make -C npc/rv64 check-memory-ordering` fresh run `v8v-ooo3-20260721T025332Z-1584072` 通过 OOO-3 11/11、LQ compile-success dynamic mutation 9/9、F2 parent live reconstruction 18/18、architecture unit 37/37；46-source/61-provenance pre/post manifest 字节一致。v1-v4.1 reviewer 反例已转成 LQ lifecycle、recovery-domain、irrevocable-write 与 ControlGate evidence gates；v5 的一个 no-op 怀疑经直接字节比较否定，但更广的证据缺口已转成全部 18 项 live-anchor/nonidentity/per-name-SHA gate；v6 只对该重建性质 PASS。当前 architecture vector 为 `DI-3/DI-4/DI-5/OOO-1/OOO-2/OOO-3=GREEN`，不得外推到完整恢复、全核 arch-stable 或正式 PPA。证据 `.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/`。
- 2026-07-20(RV64-v8t-final-pa-sq-query): **F3 在 closure `0be0d3ee3424ee816fe11d0176f2fc5e71849e24bedb764025f4e2dcc8212063` 上获得 `final_pa_sq_ordering_checkpoint`；DI-5/OOO-3/overall/PPA 继续 RED/unqualified，promotion=false**。两路 ordinary load 的 bare、DTLB hit、PTW leaf 与 A/D success 路径统一进入 bank-local `S_SQ_QUERY`；SQ 以 final PA 和 byte mask 做 youngest-older merge，unfilled/invalid/partial/IO conservative replay。每 bank 一个 retry holder 保存 full ProducerId、token/epoch、pdest/FP domain、size/address/mask/data/fault payload，在 query replay 时 exact MIQ pop/capture，随后与 same-bank store 按 edge-old full PID 仲裁并以普通 request fire exact re-push；cancel 优先并进入 terminal lane10/11，holder/active/station 形成 load-only admission fence。fresh run `v8t-f3-20260720T133351Z-1183319` 通过 10 release/assert directed + 1 X-negative、38/38 compile/elaborate/activated/static rejection、37/37 required dynamic rejection、proof 8192 vectors/bank + 25 dual-bank pairs + 729 depth-6 schedules、F0/F1/F2。v5 independent workspace reviewer 精确绑定 candidate/result/mutation/contract SHA，`unresolved P0/P1=none`；canonical checkpoint artifact SHA `9977ea25427c976462ed2e88e2f92ad60fd458f8958d410abad41770ecf3f484`。下一步 F4 仍需 sustained IPC/system aggregate、equal-capacity banking 与 arch-stable physical evidence。证据 `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/`。
- 2026-07-20(RV64-v8s-dual-memory-core-integration): **canonical `NpcCoreTop` 的 F2 双 ordinary-memory integration 在 closure `2334b38fd33e69d95e7ee2dbe40264a3dfb2fec61a00c0388b4edd233e11d2e2` 上获得严格限域的 `architecture_checkpoint`；DI-5/OOO-3/overall/PPA 继续 RED/unqualified，promotion=false**。`ENABLE_DUAL_MEM` 在 Backend→Decode→Slice→Execute→Glue reusable chain 默认 0，只有 canonical core 逐层 exact enable；topology 为 `dual_wrapper=1/legacy_bridge=0/core_glue=1`。`OooIntBackend` 现有两份 reservation/MIQ、独立 bridge face 与 ROB completion-open query，以 captured `addr[3]` 分 bank、同 bank 用 edge-old ROB distance 选较老者；两个 response 共享唯一两槽 WB allocator、双 SQ fill/terminal 分配与 10-ingress/32-token terminal collector，AMO/LR/SC/SQ singleton 仍由 bank0 承载且 launch/release edge 不得 ordinary look-through。`make -C npc/rv64 check-dual-memory-core-integration` 的 release/assert/legacy、full-top lint、17/17 source、13/13 checker negative、11/11 semantic mutation 和 fresh F1 handoff 全 PASS，最终 run `v8s-f2-20260720T080613Z-1010841`。reviewer 反例已新增真实 ROB head=15/raw 15→0 same-bank age 与 EX0/EX1 占满 WB0/WB1 时双 response hold/resume exactly-once 场景；v2 复审仅授权 checkpoint。F3 必须继续实现 final-PA SQ byte query/forward/replay，F4 才能讨论 sustained IPC/system/equal-capacity physical banking 与同源 synthesis/STA/power/Pareto。证据 `.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/`。

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
