# Agent Brief

- `source`: live-or-stored
- `profile`: yosys-sta
- `terms`: NpcTop OooBranchDirectionPredictor BPU blackbox Yosys synthesis macro boundary debug common spec
- `token_estimate`: 1889 / 2400

## Profile Suggestions
- `yosys-sta` score=22 matched=requested-profile, yosys command=`scripts/agent-e2e.sh --profile yosys-sta`
- `agent-system` score=4 matched=boundary, spec command=`scripts/agent-e2e.sh --profile agent-system`
- `nemu` score=3 matched=common, debug, spec command=`scripts/agent-e2e.sh --profile nemu`
- `contracts` score=2 matched=spec, yosys command=`scripts/agent-e2e.sh --profile contracts`
- `difftest` score=2 matched=boundary, debug command=`scripts/agent-e2e.sh --profile difftest`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile yosys-sta`

## Chunks

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-14
- `tokens`: 321
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境 e2e、自检或降低不确定性，读取 `.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，先用 `scripts/agent-e2e.sh --list-profiles` 选 profile，再生成 task-run 证据包。

请直接打开 [`.github/AGENTS.md`](./.github/AGENTS.md)。

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

### .github/e2e/profiles/yosys-sta.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 42
- `heading`: yosys-sta.tsv
- `summary`: @include|npc-single|||| / yosys-sta-contract|yosys-sta|e2e_yosys_sta_contract|yosys-sta|yosys-sta Makefile/tools/memory|综合/STA 合约入口和工具状态可见

@include|npc-single||||
yosys-sta-contract|yosys-sta|e2e_yosys_sta_contract|yosys-sta|yosys-sta Makefile/tools/memory|综合/STA 合约入口和工具状态可见

### .github/e2e/modules/yosys-sta.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-9
- `tokens`: 155
- `heading`: yosys-sta E2E Contract
- `summary`: - **范围**: Yosys 综合、iEDA STA/功耗、PPA 下游节点。 / - **上游**: NPC 可综合 RTL filelist、SDC、PDK。 / - **下游**: tapeout-readiness、PPA regression。 / - **L0 gate**: `yosys-sta-contract` 检查 Makefile、memory 和工具状态。 / - **L1 gate**: 后续升级为 `make -C npc/single syn-check-env`。 / - *...

# yosys-sta E2E Contract

- **范围**: Yosys 综合、iEDA STA/功耗、PPA 下游节点。
- **上游**: NPC 可综合 RTL filelist、SDC、PDK。
- **下游**: tapeout-readiness、PPA regression。
- **L0 gate**: `yosys-sta-contract` 检查 Makefile、memory 和工具状态。
- **L1 gate**: 后续升级为 `make -C npc/single syn-check-env`。
- **证据**: syn/sta env check、netlist、timing/power report。
- **升级路线**: 将 STA 结果纳入 profile diff，跟踪频率/面积/功耗变化。

### .github/agents/yosys-sta.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 148
- `heading`: yosys-sta.agent.md
- `summary`: --- / description: "Yosys 综合与 STA 时序分析专家。当用户需要对 NPC/RTL 设计进行逻辑综合（Yosys）、静态时序分析（iSTA）、功耗分析（iPA），查看综合报告，优化关键路径时序，配置时钟约束，或分析面积/功耗/时序 PPA 指标时使用。" / tools: [read, edit, search, execute, agent, todo] / --- / 你是 **Yosys 综合与 STA 时序分析**的专家。负责将 RTL 设计综合为门级网表，并进行时序和功耗分析。

---
description: "Yosys 综合与 STA 时序分析专家。当用户需要对 NPC/RTL 设计进行逻辑综合（Yosys）、静态时序分析（iSTA）、功耗分析（iPA），查看综合报告，优化关键路径时序，配置时钟约束，或分析面积/功耗/时序 PPA 指标时使用。"
tools: [read, edit, search, execute, agent, todo]
---

你是 **Yosys 综合与 STA 时序分析**的专家。负责将 RTL 设计综合为门级网表，并进行时序和功耗分析。

### .github/memory/modules/yosys-sta.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-2
- `tokens`: 7
- `heading`: Yosys-STA 模块笔记
- `summary`: Yosys-STA 模块笔记

# Yosys-STA 模块笔记

### .github/memory/known-issues.md#chunk-0004

- `kind`: memory
- `lines`: 19-24
- `tokens`: 798
- `heading`: [112] RV64 Yosys full stdcell synthesis 未闭合：cache/FP 宏边界后卡在 BPU 真库映射与状态阵列宏化(2026-07-07)
- `summary`: - 最新顶层宏边界探针：`NpcTop + OooFetchPacketCache/OooDataWordCache/OooFpArithGate blackbox` 100MHz full stdcell 中，日志显式标记三个 synthesis blackbox boundary，Yosys `check` 两处均为 0 problems；generic ABC 已通过 `OooBranchDirectionPredictor`（`140384` gates / `167328` wires），随后真实库...

- 最新顶层宏边界探针：`NpcTop + OooFetchPacketCache/OooDataWordCache/OooFpArithGate blackbox` 100MHz full stdcell 中，日志显式标记三个 synthesis blackbox boundary，Yosys `check` 两处均为 0 problems；generic ABC 已通过 `OooBranchDirectionPredictor`（`140384` gates / `167328` wires），随后真实库 ABC 继续通过 `OooFpPhysRegFile`（`45706` gates / `52018` wires）、`OooIntIssueQueue`（`62229` gates / `66138` wires）、`OooPhysRegFile`（`44880` gates / `51071` wires）、`OooArchRegFile`（`8072` gates / `8287` wires）、`OooIntBackend`（`40433` gates / `44706` wires）等模块。最终在真实库 ABC 进入 `OooBranchDirectionPredictor` 时被终止，未产出 `NpcTop.netlist.v`。结论：data cache 黑盒边界有效，active blocker 后移到 BPU/predictor table 真库映射与全顶收尾成本。
  - 正确性门禁更新：此前 `Uart.v PROCASSINIT` 阻塞默认 `make lint`/RV64 build；2026-07-08 已通过删除 UART 寄存器声明初始化、保留 reset 同值初始化关闭该门禁。当前 `lint`、RV64 build、`tb_ooo_muldiv_unit`、`smoke-muldiv/smoke-jal-link/smoke-branch-raw/smoke-sret-user-sv39-halfword`、`check-rtl-style`、`check-contract` 均已用当前二进制/当前 RTL 复核，证据 `.github/task-runs/2026-07-08-uart-procassinit-rv64-build-unblock/`。
- **当前规避**: 用 `STA_SYNTH_STOP_AFTER_COARSE=1` 只做 frontend/coarse 可综合性验证；这可证明 RTL 能被 Yosys 读入并完成 coarse generic synthesis，但不可替代标准单元网表、STA、功耗或时序签核。
- **建议修复顺序**: 下一步先把 `OooBranchDirectionPredictor` 的 BHT/局部历史等状态表纳入 memory macro/blackbox/分层综合探索，或拆出可保留 memory 的 predictor table 边界；同时保留 `OooDataWordCache` 与 `OooFetchPacketCache` 的真实 memory macro/SRAM/blackbox 或 memory-preserve 策略。`STA_SYNTH_PUBLIC_AUTONAME=0` 未能避免大规模 rename/autoname-style 日志和耗时，综合 probe 应区分“快速机器网表/证据采集”和“人类可读命名网表”。`debug/` 与 `common/` 的作用之一是审核 RTL 是否符合 spec 语义；上述边界优化必须用 facts/checker/TB 审核 predictor update/predict、cache hit/invalid/fill、B-FP meta、kill age、redirect/facts 与 fflags 对齐语义。然后恢复 `NpcTop` full stdcell synthesis 与 iEDA STA。不要因 PmpChecker/MulDiv/AddSub/internal cone OOC PASS 或 cache/FP/data-cache blackbox 探针越级宣称全顶 STA-ready。
- **证据**: `.github/task-runs/2026-07-07-yosys-rv64-synth-probe/`；`.github/task-runs/2026-07-07-yosys-fetch-packet-cache-valid-next/`；`.github/task-runs/2026-07-08-yosys-pmpchecker-range-share/`；`.github/task-runs/2026-07-08-yosys-fetch-cache-index-config/`；`.github/task-runs/2026-07-08-yosys-fp-arith-gate-ooc/`；`.github/task-runs/2026-07-08-fp-arith-cone-ooc/`；`.github/task-runs/2026-07-08-fp-arith-internal-cones/`；`.github/task-runs/2026-07-08-npctop-cache-fp-blackbox-syn/`；`.github/task-runs/2026-07-08-npctop-cache-data-fp-blackbox-syn/`。

