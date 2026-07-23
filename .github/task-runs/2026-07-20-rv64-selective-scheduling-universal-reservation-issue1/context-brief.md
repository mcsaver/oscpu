# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: rv64 selective scheduling universal reservation issue1
- `focus_scope`: non-history
- `token_estimate`: 2137 / 2400

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
- `tokens`: 1571
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-20(RV64-v8m-selective-scheduling): **当前 design/proof provenance 绑定下 OOO-2 selective scheduling scoped GREEN；architecture inventory 仍 OVERALL RED，PPA unpromoted**。本轮未改生产 RTL；根因是旧 `architecture_hard_gates.py` 只看到 `mem_issue_r...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-20(RV64-v8m-selective-scheduling): **当前 design/proof provenance 绑定下 OOO-2 selective scheduling scoped GREEN；architecture inventory 仍 OVERALL RED，PPA unpromoted**。本轮未改生产 RTL；根因是旧 `architecture_hard_gates.py` 只看到 `mem_issue_res_valid_q` 对 issue0 的局部停发，未沿生产数据流验证 Universal owner 下 issue1 仍可选择、接收并 fire 独立 ALU。checker 现绑定 Backend owner、Dispatch/IQ 转发、selector owner-to-first-ALU steering、IQ issue1 valid 独立性及 Backend issue1 ready/fire 独立性，并要求精确命令、11 文件哈希与日志 manifest。真实 dispatch load 在 `mem_req_ready=0` 下建立并保持 reservation；older independent ALU 以及“older dependent + same-resource memory”之后的 younger independent ALU 均由 issue1 前进，PC 与完整 ProducerId 精确命中，且无 flush/ROB kill/recovery，`global_freeze_cycles=0`。release/assert focused 4/4、5 个 actual-source compile-success semantic mutation 5/5、checker unit 18/18、fresh module 106/106、contract `400>=89` PASS；full lint 仍为继承 rc=2/115 warnings。独立 no-tools reviewer verdict=pass/blocker=0；残余包括非穷尽 formal、未对任意 older-valid 与每个 valid/ready/fire 子条件逐一 mutation，以及其余架构门全红。永久入口 `make -C npc/rv64 check-selective-scheduling`；证据 `.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/`，不得据此宣称全核 OoO 或 PPA 晋级。
- 2026-07-20(RV64-v8l-global-producer-no-live-reuse): **当前绑定源码的全局 ProducerId holder census、birth fence 与 finite-generation wrap scoped GREEN；architecture/PPA 继续 RED/unpromoted**。`producer_holder_census.py` 从生产源码自动发现并与 manifest 精确对照 direct full-P Q=15、显式组合 full-P reg 豁免=1、packed stage=5、token Q=12、generation authority=1，且拒绝 assertion shadow、非 `_q` full-P reg 逃逸、缺 IntIQ union、raw-index guard、新 holder 漏登记和 ledger 自晋级。`OooIntIssueQueue` 仅从 edge-old `valid_q/producer_id_q` 生成 mask；Dispatch 的 lane0/pair/lane1 birth 使用同一个 exported alloc full-P 对完整 union 查重。IntBackend union 覆盖 tracker、MulDiv/CLMUL、FP、pending CSR 与 mem-res/EX0/EX1/branch transient；MIQ/buffer/bridge/terminal/SQ token 用 tracker live/map 约束，SQ raw full-P 另有独立 scan；各 holder 的本地 raw-state 断言还固定 `valid => P/token known`，防止 X 索引令 union/subset 检查空洞。真实 tracker-full 与 backend credit=0 均证明 memory IQ 不 pop/不 capture；credit 返回后 reservation+token 原子出生。`GEN_W=1` 走 production 路径完成32-P回绕；8/8 assert/release baseline、9/9 compile-success mutation、9/9 checker unit、v8d..v8l 8/8 focused、106/106 module、contract 400/89 PASS。Icarus variable force/release 保值导致的相邻探针遮蔽曾令删 EX1 mutation 假绿，现以互异 full-P + release 后 reset/清零检查闭合；静态摘要也已改为从本轮原始日志/manifest 动态提取计数，陈旧或解析失败即 fail closed。reviewer 仅据自包含摘要给 scoped pass；manifest 仍声明 instance/semantic incomplete，architecture inventory `OVERALL: RED`，无 official/Linux、fresh synthesis/STA/power/Pareto 晋级。证据 `.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/`，`promotion_eligible=false`。
- 2026-07-20(RV64-v8l-workflow-e2e): `agent-system`/`github-index` completed；首个 `npc-dev` 因 slug 未包含 canonical `ProducerId holder census` 领域词而 recall blocked，五个工程节点 PASS 也未覆盖该失败。保留失败包后以语义 slug 重跑 completed。task slug 是 bounded brief 的检索输入，后续 RTL task-run 必须带稳定领域名词而非仅用宽泛 `global-producer`。
- 2026-07-20(RV64-v8k-pending-csr-producer-lease): **dispatched pending CSR 的 full ProducerId lease、exact commit 与 feedback-free admission scoped GREEN；全核 architecture/PPA 继续 RED**。pre-ROB capture 不制造 P；真实 lane0 ROB enqueue 沿才把 full `P={generation,rob_idx}` 锁入 `OooPendingSystemSequencer`，raw Q lease 直接并入 external live mask，ordinary clear/`clear_dispatched` 不能切断 post-dispatch owner。CSR side effect 只由 logical claim + raw lease + commit0 full-PID exact match + PC coherence 授权；raw lease 或 logical claim 任一存在都封住 queue-head fallback，partial metadata、same-index/different-generation 与 PC mismatch 两路静默。完整 `pending_system_clear` 不再反喂 admission，新增 feedback-free gate；pending jump 只有 `resolve_ready && (misaligned || nolink_commit || redirect_after_dispatch)` 才能取消，裸 ready 自锁反例由 cross-ready TB 和 `pending_jump_ready_overcancels` mutation 关闭。focused source audit 14/14、release/assert、两个 expected-fail assertion probes、10/10 compile-success semantic mutation、legacy v8d-v8j 6/6、fresh module aggregate 106/106、style/contract `388>=89` PASS；full lint 仍为继承 rc=2/115 warnings且 normalized SHA `414dbc39...06e2b` 与 v8j 相同，real architecture inventory 明确 `OVERALL: RED`。implementation reviewer verdict=pass/blocker=0，但完整 SCC/formal、原始 mutation 独立复跑与 core-local flush/commit 同沿协议仍为盲区；non-CSR pending、完整 holder census、finite-generation global no-live-reuse、official/Linux、fresh synthesis/STA/power/Pareto 未关闭。证据 `.github/task-runs/2026-07-20-rv64-v8k-pending-csr-producer-lease/`，`promotion_eligible=false`。

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
