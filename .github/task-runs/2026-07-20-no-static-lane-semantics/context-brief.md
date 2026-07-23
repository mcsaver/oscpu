# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: no static lane semantics
- `focus_scope`: non-history
- `token_estimate`: 2033 / 2400

## Profile Suggestions
- `npc-dev` score=8 matched=requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `yosys-sta` score=3 matched=lane, no, static command=`scripts/agent-e2e.sh --profile yosys-sta`
- `agent-system` score=2 matched=no command=`scripts/agent-e2e.sh --profile agent-system`
- `github-index` score=2 matched=no command=`scripts/agent-e2e.sh --profile github-index`
- `nemu` score=2 matched=no, static command=`scripts/agent-e2e.sh --profile nemu`

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
- `tokens`: 1467
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-20(RV64-v8o-no-static-lane-semantics): **当前 142-file vsrc closure 与 exact proof provenance 下 DI-4 scoped GREEN；同 design_id 的 OOO-1/OOO-2 保留，architecture/PPA 继续 RED/unpromoted**。生产 RTL 功能未改；`OooIntIssueQueue` 的真实链为 `ctrl_is_...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-20(RV64-v8o-no-static-lane-semantics): **当前 142-file vsrc closure 与 exact proof provenance 下 DI-4 scoped GREEN；同 design_id 的 OOO-1/OOO-2 保留，architecture/PPA 继续 RED/unpromoted**。生产 RTL 功能未改；`OooIntIssueQueue` 的真实链为 `ctrl_is_alu_terminal_capable` 预译码、`alu_terminal_capable_q` 随 payload/full-PID capture 与 compaction、`OooIntIssueSelect8` 按 resident capability 动态分配 Universal/ALU terminal，并在 older-simple+younger-complex 时显式 pair swap。旧 checker 未识别真实 predicate，存在“没有发现 restriction 因而通过”的假绿；现在对 predicate/metadata/双 capture/compaction/selector/swap/output/binding 做精确非空计数并剥离注释。TB 在 release/assert 两种独立 profile 中把 branch/JAL/JALR/load/store/MulDiv 放到两个 accepted slot，共 12 个 same-edge dual fire、24 个 distinct nonzero-generation full-PID exact match，且 one-free-entry 时 slot1 backpressure 不记 coverage。`disable_pair_swap/static_entry_capability/slot1_capability_capture/muldiv_as_alu/serialize_second_terminal/corrupt_full_pid` 六个 compile-success activated mutation 全被目标语义检出；checker unit 22/22、module 106/106、contract/style PASS，full lint 继承 115 warnings。永久入口 `make -C npc/rv64 check-no-static-lane-semantics`；DI-1/2/3/5、OOO-3/4、双 memory、formal exhaustiveness 与 PPA 未证明。证据 `.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/`。
- 2026-07-20(RV64-v8n-true-ooo-long-latency): **当前 142-file vsrc closure 与 exact proof provenance 下 OOO-1 scoped GREEN；同 design_id 的 OOO-2 记录保留，architecture/PPA 继续 RED/unpromoted**。生产 RTL 功能未改；`tb_ooo_int_backend` 先消耗一整圈 ROB，使 old/young full ProducerId 均带非零 generation，再分别建立真实 cacheable/no-fault/no-store load request 的 MIQ/tracker owner、真实迭代 MUL owner 与 DIVU owner。每个 old owner 从 request/issue accept 到 formal WB 前持续 exact-live；其间 8 个不同 young 各完成 issue accept 和 `ex*_wb_valid && producer_open && !kill` authorized exactly-once WB，并精确出现 4 个 issue0+issue1 同周期 accept。实际 ROB `valid` census 重建的 full-PID set 必须等于 old+8 young 共 9 项；old WB 前 commit 为 0，之后 commit0/1 按派发 PID+PC ledger 严格有序 exactly-once，最终 ROB/IQ/MIQ/tracker/MulDiv owner/free-list 排空。`make -C npc/rv64 check-true-ooo-long-latency` 的 release/assert 6/6、`serial_issue1`、MIQ/MulDiv issue1 freeze、retire-before-head-done 与三类 load/MulDiv PID truncate 共 7/7 compile-success activated mutation、checker+manifest unit 22/22、fresh module 106/106、contract `400>=89` PASS。scope 仅是 long-latency tolerance；异常/device load、store/顺序、kill/recovery、OOO-3、其它 gate 与 PPA 未证明。证据 `.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/`。
- 2026-07-20(RV64-v8n-directed-evidence-workflow): OOO-1 evidence builder 只发布精确命令、定量 marker、源码 pre/post hash、proof/harness exact provenance 与完整 vsrc design_id 均一致的记录。新增共享 `directed_evidence_manifest.py` 以临时文件 parse 后 atomic replace，只保留同 schema/design 的 sibling；单测固定 OOO-2 preservation、stale design drop 和 pre-replace fault 保持旧文件 byte-identical/parseable，OOO-2 builder 也复用同 helper。首轮 no-tools contract review 的 B1-B9 已全部机械闭合，revision 与独立 implementation review 均 strict pass；两者 JSON 只允许 prompt-supplied local RV64 RTL facts，`allowed_commands=[]`、`write_paths=[]`、network/accounts/credentials/external_services=false。合同 JSON SHA 与 design/proof digest 分离，避免协作审计哈希被误作 RTL 证据。
- 2026-07-20(RV64-v8m-selective-scheduling): **当前 design/proof provenance 绑定下 OOO-2 selective scheduling scoped GREEN；architecture inventory 仍 OVERALL RED，PPA unpromoted**。本轮未改生产 RTL；根因是旧 `architecture_hard_gates.py` 只看到 `mem_issue_res_valid_q` 对 issue0 的局部停发，未沿生产数据流验证 Universal owner 下 issue1 仍可选择、接收并 fire 独立 ALU。checker 现绑定 Backend owner、Dispatch/IQ 转发、selector owner-to-first-ALU steering、IQ issue1 valid 独立性及 Backend issue1 ready/fire 独立性，并要求精确命令、11 文件哈希与日志 manifest。真实 dispatch load 在 `mem_req_ready=0` 下建立并保持 reservation；older independent ALU 以及“older dependent + same-resource memory”之后的 younger independent ALU 均由 issue1 前进，PC 与完整 ProducerId 精确命中，且无 flush/ROB kill/recovery，`global_freeze_cycles=0`。release/assert focused 4/4、5 个 actual-source compile-success semantic mutation 5/5、checker unit 18/18、fresh module 106/106、contract `400>=89` PASS；full lint 仍为继承 rc=2/115 warnings。独立 no-tools reviewer verdict=pass/blocker=0；残余包括非穷尽 formal、未对任意 older-valid 与每个 valid/ready/fire 子条件逐一 mutation，以及其余架构门全红。永久入口 `make -C npc/rv64 check-selective-scheduling`；证据 `.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/`，不得据此宣称全核 OoO 或 PPA 晋级。

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
