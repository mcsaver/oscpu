# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: dual memory axi fabric
- `focus_scope`: non-history
- `token_estimate`: 2085 / 2400

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
- `lines`: 3-9
- `tokens`: 1519
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-20(RV64-v8q-dual-memory-axi-fabric): **canonical design id `sha256:79e445cd976f7a2ace1da6288866b2442846677520052a95eea7c14504ab2cca` 下，未实例化的 `OooDualMemAxiArbiter` 获得 scoped `dual_axi_miss_fabric_leaf_verified`；same-digest...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-20(RV64-v8q-dual-memory-axi-fabric): **canonical design id `sha256:79e445cd976f7a2ace1da6288866b2442846677520052a95eea7c14504ab2cca` 下，未实例化的 `OooDualMemAxiArbiter` 获得 scoped `dual_axi_miss_fabric_leaf_verified`；same-digest DI-3/DI-4/OOO-1/OOO-2 fresh GREEN，DI-5/OOO-3/overall/PPA 继续 RED/unpromoted**。五态 registered-owner FSM 将 read 锁至 R terminal、write 以独立 `aw_seen_q/w_seen_q` 锁至 B terminal，non-owner request READY/response VALID 为零，response READY 仅来自 exact owner，`rr_q` 只在 terminal 更新；全系统同步 reset 组合静默并清所有 transport 状态，逐态 reset 后 orphan R/B 不可见，非法 read+write IDLE 全局 fail-closed。`make -C npc/rv64 check-dual-memory-fabric-foundation` 固化 release/assert/assert-negative、AR/R/AW/W/B stall/skew/fairness/reset matrix、12/12 compile-success semantic mutation、10/10 去注释 fail-closed checker、Verilator/style 与完整 closure pre/post；最终 run `v8q-f0-20260720T030925Z-849762`。canonical core 尚无该实例，F1 仍需双 bridge/cache-hit wrapper 与 peer maintenance，后续还需双 MIQ/final-PA SQ query/completion 和 IPC/PPA 证据。证据 `.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/`。
- 2026-07-20(RV64-v8q-review-workflow): 首轮 reviewer 的 F0-G01..G05 全部由 spec+TB+mutation+checker executable closure 关闭；final contract re-review 和 implementation review 使用 skill 生成、校验、render 的 `self-contained-no-tools` JSON（最终 SHA 分别 `ddfc6d7898c77b2cc660f60579660ba421064e6d6057e95278db7ab0d39b8487`、`191ff2dc5506253ad0c82a3db8eb8f768e72535f8f0de3a44c0d9baaf382e46d`），无 shell/文件/网络/账号/凭据/外部服务/写入，均 pass/blockers=0。source digest 变化会先让旧 architecture evidence fail closed，再 fresh 重发 sibling gates；审查节点若平台暂不处理仅记 `review_pending`，不阻塞父目标、不改变 RTL 语义重试、不以减少平台检查为目标。
- 2026-07-20(RV64-v8q-workflow-e2e): 首次带末尾 `v8q` 的 agent-system/github-index slug 在节点全 PASS 后仍因 startup primary focus 缺失而 blocked，证明召回失败不会被节点绿覆盖。root cause 是 task-slug 归一化把迭代身份误作 non-history AND term；runner 现仅在前有至少两个领域词时过滤末尾 `v<数字><可选字母>`，内部 `v8a` 等架构阶段词保留，纯生命周期 slug 继续 fail closed。正反回归入 agent-system 后，`...contract-v8q-rerun`、`...audit-v8q-rerun` 与 `dual-memory-axi-fabric-v8q-rerun` 三 profile 全 completed。原 blocked 包保留，原 task identity 仍绑定 report/manifest/DB；这是检索输入纠偏，不削弱 reviewer、RTL、架构或 PPA 门。
- 2026-07-20(RV64-v8p-dual-memory-terminal-owners): **当前 design/proof provenance 下 DI-3 pair_matrix scoped GREEN；同 design_id 的 DI-4/OOO-1/OOO-2 fresh sibling 记录保留，architecture/PPA 继续 RED/unpromoted**。`OooIntIssueQueue` 为 resident entry 保存独立 plain-memory-terminal capability并排除 AMO/LR/SC/FP memory，`OooIntIssueSelect8` 按 packed age 把两个合法 entry 送到 terminal0/1；`OooIntBackend` 以原子 pair ready/fire 同沿建立两个 tracker token/full-PID owner、两个完整 reservation Q 和两个 captured-data LSU/AGU，bank1 不得越过 edge-old bank0，shared request 继续串行。SQ 双 bind 按 full PID 精确命中两个 store entry，七入口 collector 在双 dequeue stall 下保存 exact-live tuple 并 exactly-once 排空。永久入口 `make -C npc/rv64 check-pair-matrix` 覆盖 15/15 pair key、LL/LS/SL/SS、8 个互异非零 generation PID、10 个特殊访存排除、单 token 零部分 birth、release/assert 8/8 baseline、15/15 compile-success/elaborated/activated mutation、checker+manifest 28/28 和同摘要原子发布；完整 backend 非 focused release/assert 也通过。独立 no-tools reviewer pass/blocker=0，但只授权 DI-3；DI-1/2/5、OOO-3/4、downstream 双端口、formal exhaustiveness 和 PPA 未证明。证据 `.github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners/`。
- 2026-07-20(RV64-v8o-no-static-lane-semantics): **当前 142-file vsrc closure 与 exact proof provenance 下 DI-4 scoped GREEN；同 design_id 的 OOO-1/OOO-2 保留，architecture/PPA 继续 RED/unpromoted**。生产 RTL 功能未改；`OooIntIssueQueue` 的真实链为 `ctrl_is_alu_terminal_capable` 预译码、`alu_terminal_capable_q` 随 payload/full-PID capture 与 compaction、`OooIntIssueSelect8` 按 resident capability 动态分配 Universal/ALU terminal，并在 older-simple+younger-complex 时显式 pair swap。旧 checker 未识别真实 predicate，存在“没有发现 restriction 因而通过”的假绿；现在对 predicate/metadata/双 capture/compaction/selector/swap/output/binding 做精确非空计数并剥离注释。TB 在 release/assert 两种独立 profile 中把 branch/JAL/JALR/load/store/MulDiv 放到两个 accepted slot，共 12 个 same-edge dual fire、24 个 distinct nonzero-generation full-PID exact match，且 one-free-entry 时 slot1 backpressure 不记 coverage。`disable_pair_swap/static_entry_capability/slot1_capability_capture/muldiv_as_alu/serialize_second_terminal/corrupt_full_pid` 六个 compile-success activated mutation 全被目标语义检出；checker unit 22/22、module 106/106、contract/style PASS，full lint 继承 115 warnings。永久入口 `make -C npc/rv64 check-no-static-lane-semantics`；DI-1/2/3/5、OOO-3/4、双 memory、formal exhaustiveness 与 PPA 未证明。证据 `.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/`。

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
