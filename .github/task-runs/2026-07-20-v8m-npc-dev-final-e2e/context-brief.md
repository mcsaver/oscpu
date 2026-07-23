# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: rv64 selective scheduling universal reservation issue1
- `focus_scope`: non-history
- `token_estimate`: 1965 / 2400

## Profile Suggestions
- `npc-dev` score=9 matched=requested-profile, rv64 command=`scripts/agent-e2e.sh --profile npc-dev`
- `rv64-linux` score=6 matched=rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `display-vga` score=2 matched=rv64 command=`scripts/agent-e2e.sh --profile display-vga`
- `linux-device` score=2 matched=rv64 command=`scripts/agent-e2e.sh --profile linux-device`
- `nemu` score=2 matched=reservation, rv64 command=`scripts/agent-e2e.sh --profile nemu`

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
- `lines`: 3-8
- `tokens`: 1399
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-20(RV64-v8m-selective-scheduling): **当前 design/proof provenance 绑定下 OOO-2 selective scheduling scoped GREEN；architecture inventory 仍 OVERALL RED，PPA unpromoted**。本轮未改生产 RTL；根因是旧 `architecture_hard_gates.py` 只看到 `mem_issue_r...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-20(RV64-v8m-selective-scheduling): **当前 design/proof provenance 绑定下 OOO-2 selective scheduling scoped GREEN；architecture inventory 仍 OVERALL RED，PPA unpromoted**。本轮未改生产 RTL；根因是旧 `architecture_hard_gates.py` 只看到 `mem_issue_res_valid_q` 对 issue0 的局部停发，未沿生产数据流验证 Universal owner 下 issue1 仍可选择、接收并 fire 独立 ALU。checker 现绑定 Backend owner、Dispatch/IQ 转发、selector owner-to-first-ALU steering、IQ issue1 valid 独立性及 Backend issue1 ready/fire 独立性，并要求精确命令、11 文件哈希与日志 manifest。真实 dispatch load 在 `mem_req_ready=0` 下建立并保持 reservation；older independent ALU 以及“older dependent + same-resource memory”之后的 younger independent ALU 均由 issue1 前进，PC 与完整 ProducerId 精确命中，且无 flush/ROB kill/recovery，`global_freeze_cycles=0`。release/assert focused 4/4、5 个 actual-source compile-success semantic mutation 5/5、checker unit 18/18、fresh module 106/106、contract `400>=89` PASS；full lint 仍为继承 rc=2/115 warnings。独立 no-tools reviewer verdict=pass/blocker=0；残余包括非穷尽 formal、未对任意 older-valid 与每个 valid/ready/fire 子条件逐一 mutation，以及其余架构门全红。永久入口 `make -C npc/rv64 check-selective-scheduling`；证据 `.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/`，不得据此宣称全核 OoO 或 PPA 晋级。
- 2026-07-20(RV64-v8m-workflow-e2e): v8m 已进入 DB-first retained memory、snapshot、evidence index 与 strict guard。`brief selective scheduling Universal reservation issue1 --profile npc-dev --focus-scope non-history` 从当前 NPC memory 命中本条工程事实；`npc-dev`、canonical `no-tools-rtl-subagent-contract` 的 `agent-system`、`db-first-stored-memory-audit` 的 `github-index` 均 completed，strict guard 也据当前工作树推导并接受三项证据。首个混合 `rtl-no-tools-subagent-contract-selective-scheduling` agent-system run 虽 10/10 节点 PASS，因规则层无独立 primary 而正确 blocked，失败包保留，不能被节点绿覆盖。手工 v8m task-run 已登记 152 个 evidence assets。稳定规则：RTL 子 agent 任务写成“本地 RV64 RTL/验证/证据复核”，明确仓库路径、只读/写边界、无网络/凭据/部署/外部目标；冻结材料足够时使用 JSON 固化的 self-contained no-tools 契约。该措辞用于精确界定正常工程范围，不是规避平台审查。
- 2026-07-20(RV64-v8l-global-producer-no-live-reuse): **当前绑定源码的全局 ProducerId holder census、birth fence 与 finite-generation wrap scoped GREEN；architecture/PPA 继续 RED/unpromoted**。`producer_holder_census.py` 从生产源码自动发现并与 manifest 精确对照 direct full-P Q=15、显式组合 full-P reg 豁免=1、packed stage=5、token Q=12、generation authority=1，且拒绝 assertion shadow、非 `_q` full-P reg 逃逸、缺 IntIQ union、raw-index guard、新 holder 漏登记和 ledger 自晋级。`OooIntIssueQueue` 仅从 edge-old `valid_q/producer_id_q` 生成 mask；Dispatch 的 lane0/pair/lane1 birth 使用同一个 exported alloc full-P 对完整 union 查重。IntBackend union 覆盖 tracker、MulDiv/CLMUL、FP、pending CSR 与 mem-res/EX0/EX1/branch transient；MIQ/buffer/bridge/terminal/SQ token 用 tracker live/map 约束，SQ raw full-P 另有独立 scan；各 holder 的本地 raw-state 断言还固定 `valid => P/token known`，防止 X 索引令 union/subset 检查空洞。真实 tracker-full 与 backend credit=0 均证明 memory IQ 不 pop/不 capture；credit 返回后 reservation+token 原子出生。`GEN_W=1` 走 production 路径完成32-P回绕；8/8 assert/release baseline、9/9 compile-success mutation、9/9 checker unit、v8d..v8l 8/8 focused、106/106 module、contract 400/89 PASS。Icarus variable force/release 保值导致的相邻探针遮蔽曾令删 EX1 mutation 假绿，现以互异 full-P + release 后 reset/清零检查闭合；静态摘要也已改为从本轮原始日志/manifest 动态提取计数，陈旧或解析失败即 fail closed。reviewer 仅据自包含摘要给 scoped pass；manifest 仍声明 instance/semantic incomplete，architecture inventory `OVERALL: RED`，无 official/Linux、fresh synthesis/STA/power/Pareto 晋级。证据 `.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/`，`promotion_eligible=false`。
- 2026-07-20(RV64-v8l-workflow-e2e): `agent-system`/`github-index` completed；首个 `npc-dev` 因 slug 未包含 canonical `ProducerId holder census` 领域词而 recall blocked，五个工程节点 PASS 也未覆盖该失败。保留失败包后以语义 slug 重跑 completed。task slug 是 bounded brief 的检索输入，后续 RTL task-run 必须带稳定领域名词而非仅用宽泛 `global-producer`。

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
