# Agent Brief

- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: OooDataWordCache data cache debug common facts checker yosys macro boundary
- `token_estimate`: 2348 / 2400

## Profile Suggestions
- `yosys-sta` score=9 matched=boundary, checker, macro, yosys command=`scripts/agent-e2e.sh --profile yosys-sta`
- `npc-dev` score=8 matched=requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `agent-system` score=6 matched=boundary, data, facts command=`scripts/agent-e2e.sh --profile agent-system`
- `nemu` score=4 matched=cache, common, data, debug command=`scripts/agent-e2e.sh --profile nemu`
- `difftest` score=2 matched=boundary, debug command=`scripts/agent-e2e.sh --profile difftest`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
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
- `lines`: 3-10
- `tokens`: 1461
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-08: **四黑盒 macro-boundary contract 已进入 NPC specs 索引**。新增 `design/specs/yosys-macro-boundary-contracts.md`，覆盖 `OooFetchPacketCache`、`OooDataWordCache`、`OooFpArithGate`、`OooBranchDirectionPredictor` 四个 synthesis blackbox bound...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-08: **四黑盒 macro-boundary contract 已进入 NPC specs 索引**。新增 `design/specs/yosys-macro-boundary-contracts.md`，覆盖 `OooFetchPacketCache`、`OooDataWordCache`、`OooFpArithGate`、`OooBranchDirectionPredictor` 四个 synthesis blackbox boundary 的 timing/area/语义缺口和任务清单；`design/specs/README.md` 已索引该文档。新增 `yosys-sta/scripts/check_macro_contracts.py`，验证 spec、RTL module declaration 和当前 `NpcTop.netlist.v` 中实例存在。边界：checker 只证明合同覆盖，不证明 STA-ready；后续仍需 `vsrc/debug` 与 `vsrc/common` facts/checker/TB 审核 RTL/spec 语义。证据 `.github/task-runs/2026-07-08-yosys-macro-boundary-contracts/`。
- 2026-07-08: **Yosys-STA fast-name/blackbox flow 已可被 Git 看到，但本轮不改变 RTL 行为**。为避免四黑盒综合依赖 ignored 本机工具目录，顶层 `.gitignore` 已 allowlist `yosys-sta/Makefile`、`yosys-sta/scripts/*.tcl` 与 `yosys-sta/scripts/pdk/*.tcl` 必要入口，`yosys-sta/Makefile` 显式 export `SYNTH_DFF_AUTONAME`；`result/` 等本地综合产物仍忽略。NPC 侧语义边界不变：下一步仍是四个黑盒的 timing/area/OOC contract，并用 `vsrc/debug` 与 `vsrc/common` 审核 RTL 是否符合 spec 语义。证据 `.github/task-runs/2026-07-08-yosys-sta-flow-versioned/`。
- 2026-07-08: **`NpcTop + fetch-cache/data-cache/FP-arith/BPU blackbox` 已产出首版全顶 full stdcell 网表**。本轮不启动 Ubuntu/rootfs，只在 `.github/task-runs/2026-07-08-npctop-cache-data-fp-bpu-blackbox-syn/` 内用 `STA_SYNTH_BLACKBOX_MODULES="OooFetchPacketCache OooDataWordCache OooFpArithGate OooBranchDirectionPredictor"` 和 fast-name 模式跑 100MHz synthesis。结果：四处黑盒边界被 Yosys 识别；完整 log 后续两处 `check` 为 0 problems；`NpcTop.netlist.v` 落盘 `62190606` bytes，Yosys 正常 `End of script`。边界：这不是完整 PPA/STA-ready，四个黑盒均为 unknown area；`synth_check.txt` 的 7 个 `$print` warning 属早期诊断快照。下一步应把四个边界做成有 timing/area/语义 contract 的 macro/OOC 策略，并用 `vsrc/debug` 与 `vsrc/common` 的 facts/checker/TB 审核 RTL 是否符合 spec 语义。
- 2026-07-08: **`NpcTop + fetch-cache/data-cache/FP-arith blackbox` 探针把全顶综合阻断点后移到 BPU 真库 ABC**。本轮不改生产 RTL，只在 `.github/task-runs/2026-07-08-npctop-cache-data-fp-blackbox-syn/` 内用 `STA_SYNTH_BLACKBOX_MODULES="OooFetchPacketCache OooDataWordCache OooFpArithGate"` 跑 100MHz full stdcell。结果：三处黑盒边界被 Yosys 识别；两处 `check` 为 0 problems；generic ABC 已通过 `OooBranchDirectionPredictor`，真实库 ABC 又通过 `OooFpPhysRegFile`、`OooRob`、`OooIntIssueQueue`、`OooPhysRegFile`、`OooArchRegFile`、`OooIntBackend` 等模块；最终在真实库 ABC 进入 `OooBranchDirectionPredictor` 时 timeout/Terminated，未产出 `NpcTop.netlist.v`。下一步应把 BPU/predictor table、regfile/issue-queue 等状态结构纳入 memory macro/分层综合候选，同时继续保留 cache/data-cache/FP 宏边界；任何 predictor/cache/regfile/issue-queue 的 macro 或时序改写，都必须把 `vsrc/debug` 与 `vsrc/common` 当作 RTL/spec 语义审核层，配套 facts、checker 或 focused/random TB 后再给出正确性结论。边界：未启动 Ubuntu/rootfs，不宣称 STA-ready。
- 2026-07-08: **`NpcTop + fetch-cache/FP-arith blackbox` 探针把全顶综合下一堵墙定位到 `OooDataWordCache`**。本轮不改生产 RTL，只在 `.github/task-runs/2026-07-08-npctop-cache-fp-blackbox-syn/` 内用 `STA_SYNTH_BLACKBOX_MODULES="OooFetchPacketCache OooFpArithGate"` 跑 100MHz full stdcell。结果：两个黑盒边界被 Yosys 识别，`check` 0 problems；`OooBranchDirectionPredictor`、`PmpChecker`、`AxiLitePlic` 均已通过 ABC；最终停在 `OooDataWordCache` gate extraction，且 data cache 优化阶段出现 `2418361`/`2237909` cells。下一步若做 data/fetch cache 的 SRAM/memory macro/blackbox 或 memory-preserve 边界，必须把 `vsrc/debug` 与 `vsrc/common` 当作 RTL/spec 语义审核层使用：优先查/补 facts、checker 或 focused TB，覆盖 cache hit/tag/context、fill/store/invalidate、flush/redirect 与异常可见性，不可只凭 Yosys 通过判断语义等价。边界：未启动 Ubuntu/rootfs，未产出全顶 stdcell netlist，不宣称 STA-ready。
- 2026-07-08: **`OooFpArithGate` Mul/FMA internal standalone OOC 拆账完成，下一步转正式结构边界与语义审核**。本轮不改生产 RTL，只在 `.github/task-runs/2026-07-08-fp-arith-internal-cones/` 内新增临时 `OooFpArithInternalConeProbes.v`，拆出 Mul product、Mul normalize/round、FMA ref/shift、FMA 128-bit align/add、FMA normalize/round 5 个 standalone probe。5 个 probe coarse/full 均 PASS：Mul product full `19488` gates、area `41726.44`、Yosys `80.47s`；Mul norm+round area `9883.16`；FMA ref area `6006.00`；FMA align+add area `22277.92`；FMA norm+round area `11052.44`。结论：上一轮 Mul/FMA output cone timeout 不是单个内部 helper 不可综合，而是完整宽 datapath、double/single 双路径与 output mux 累计后造成 ABC 长尾。后续若把 probe 结论转成生产 RTL 拆分，必须用 `vsrc/common` facts 与 `vsrc/debug` checker 审核 spec 语义，重点覆盖 B-FP meta、kill age、redirect/facts 与 value/fflags 对齐。

