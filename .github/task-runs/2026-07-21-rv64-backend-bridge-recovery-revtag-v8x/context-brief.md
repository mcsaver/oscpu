# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: backend bridge selective recovery
- `focus_scope`: non-history
- `token_estimate`: 1826 / 2400

## Profile Suggestions
- `npc-dev` score=9 matched=backend, requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `nemu` score=2 matched=backend, bridge command=`scripts/agent-e2e.sh --profile nemu`
- `npc` score=2 matched=backend command=`scripts/agent-e2e.sh --profile npc`
- `contracts` score=1 matched=backend command=`scripts/agent-e2e.sh --profile contracts`
- `difftest` score=1 matched=backend command=`scripts/agent-e2e.sh --profile difftest`

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
- `tokens`: 1260
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-21(RV64-v8x-backend-bridge-recovery): **V8W 指出的真实 backend+bridge active/station 双 owner 联合动态 coverage gap 已关闭；production RTL 未改，OOO-4/overall 仍 RED，PPA unqualified/unpromoted**。`tb_ooo_int_backend_v8x_bridge.svh` 只在 focused...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-21(RV64-v8x-backend-bridge-recovery): **V8W 指出的真实 backend+bridge active/station 双 owner 联合动态 coverage gap 已关闭；production RTL 未改，OOO-4/overall 仍 RED，PPA unqualified/unpromoted**。`tb_ooo_int_backend_v8x_bridge.svh` 只在 focused 宏下把 `OooIntBackend` 的两 bank request/response、active/tracker/station expected、owner residency、drop、SQ query 与真实 `OooDualMemBridgeWrapper` 全端口直连，TB 仅建模共享 AXI slave。定向轨迹建立同 bank MIQ `[A,B]`、bridge0 `active=A/station=B`，older branch mispredict 单拍且 wrapper `flush_i=0`；唯一 AR 属于 A。迟到 R(A) 同一采样边产生 drop(A)+exact MIQ pop(A)+collector lane2(A)，不产生 response/WB/commit/cache fill；下一周期 station B 晋升，active/tracker/station/residency/head 均为 B，并由 persistent killed authority 在 pre-AXI 精确 drop/pop/terminal，不发 translate/AR。不可变 `{kind,token,epoch,fault_tval}` ledger 强制 A 后 B、各恰一次，最终全状态排空加 6-cycle quiet guard。focused marker 为 `ar=1 drop=2 pop=2 terminal=2 wb=0 commit=0 fill=0 lane1=0 quiet=6 PASS`；两项 compile-success RTL mutation 2/2 目标拒绝、相邻回归 5/5、contract/census PASS。永久入口 `make -C npc/rv64 check-backend-bridge-recovery`；证据 `.github/task-runs/2026-07-21-rv64-v8x-backend-bridge-recovery/`。
- 2026-07-21(RV64-v8w-ooo4-selective-memory-recovery): **OOO-4 的访存选择性恢复子合同为 `PASS_WITH_VERIFICATION_GAP`；OOO-4/overall 仍 RED，PPA unqualified/unpromoted**。`OooMemAxiBridge` 的 selective recovery authority 由 MIQ expected、owner tracker、bridge sticky identity 与 effective-killed 完整合取；`S_SQ_QUERY/S_LOOKUP/S_DEVICE_WAIT` 在尚未形成 AXI owner 时释放，已呈现或握手的 AR/AW/W 按 ready/valid 排空到 R/B，sticky snapshot 保持延迟 R drain，A/D write 的迟到 B 只做 PTE alias maintenance 与一次 exact drop。`OooIntBackend` 两个 bank 的 raw drop 仅在 full tuple、killed MIQ head 与 tracker exact 同时匹配时授权 pop，并独立送入 tagged terminal collector；`A global flush compaction → B new head → late drop(A)` 不误弹 B，B 在记录 final-PA SQ/LQ disposition 后正常完成。权威 GREEN 为 backend 1/1、case14 1/1、full bridge 1/1、wrapper 1/1、related integration 6/6；8 bridge + 10 backend compile-success mutation 18/18 均被动态 witness 拒绝。v3 reviewer 合同 SHA `082356f2bf7338a69d71b8da064421e1717764dbbe642add7c2d5d3033ebf3e5` 未发现限域内新的可达 RTL correctness gap，但仍缺一条真实 backend+bridge 联合动态轨迹，在同一仿真中建立 MIQ `A,B`、bridge `active=A/station=B` 并检查顺序双 drop/pop、精确两个 terminal、无 target/WB、collector/tracker 清零；相邻层用例不能替代该项。证据 `.github/task-runs/2026-07-21-rv64-v8w-speculation-recovery/`。
- 2026-07-21(RV64-v8v-ooo3-memory-ordering): **design-id `sha256:ba9666a7a612bfcb7a07ce58f7953712d4c050eed24da00824b61b74af5e1d27` 的 hash-bound memory-ordering scope 已获 OOO-3 scoped GREEN；DI-1/DI-2/OOO-4/overall 仍 RED，PPA unqualified/unpromoted**。一份共享 16-entry retire-resident `OooLoadQueue` 保存 full ProducerId、final PA/byte mask、checkpoint epoch 与完成/terminal/retire 状态；load 只有在 final-PA SQ disposition 允许后可进入 physical request，完成与 retire exact-once。backend-wide checkpoint request/hold/apply 将 front-end/local/memory flush 与 accepted apply 分域，accepted apply 等待 physical store/AMO write lease、SQ active-write 和 DRAIN owner 闭合；physical store/AMO owner 持续到 B、formal WB 和 lane0 exact retire。canonical `make -C npc/rv64 check-memory-ordering` fresh run `v8v-ooo3-20260721T025332Z-1584072` 通过 OOO-3 11/11、LQ compile-success dynamic mutation 9/9、F2 parent live reconstruction 18/18、architecture unit 37/37；46-source/61-provenance pre/post manifest 字节一致。v1-v4.1 reviewer 反例已转成 LQ lifecycle、recovery-domain、irrevocable-write 与 ControlGate evidence gates；v5 的一个 no-op 怀疑经直接字节比较否定，但更广的证据缺口已转成全部 18 项 live-anchor/nonidentity/per-name-SHA gate；v6 只对该重建性质 PASS。当前 architecture vector 为 `DI-3/DI-4/DI-5/OOO-1/OOO-2/OOO-3=GREEN`，不得外推到完整恢复、全核 arch-stable 或正式 PPA。证据 `.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/`。

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
