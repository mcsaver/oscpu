# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: retained memory checkpoint evidence
- `focus_scope`: non-history
- `token_estimate`: 2058 / 2400

## Profile Suggestions
- `github-index` score=19 matched=evidence, memory, requested-profile, retained command=`scripts/agent-e2e.sh --profile github-index`
- `nemu` score=3 matched=checkpoint, evidence, memory command=`scripts/agent-e2e.sh --profile nemu`
- `software-flow` score=3 matched=evidence, memory command=`scripts/agent-e2e.sh --profile software-flow`
- `yosys-sta` score=3 matched=evidence, memory command=`scripts/agent-e2e.sh --profile yosys-sta`
- `abstract-machine` score=2 matched=memory command=`scripts/agent-e2e.sh --profile abstract-machine`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile github-index`

## Missing Paths
- `.github/agents/github-index.agent.md`
- `.github/memory/modules/github-index.md`

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

### .github/e2e/profiles/github-index.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 67
- `heading`: node_id|module|function|owner_agent|inputs|outputs
- `summary`: github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

# node_id|module|function|owner_agent|inputs|outputs
github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

### .github/memory/modules/npc.md#chunk-0007

- `kind`: memory-module
- `lines`: 26-30
- `tokens`: 1573
- `heading`: 当前状态
- `summary`: - 2026-07-19(RV64-PPA-S2-Q1A-e2e)：Q1A 的 task-specific `npc-dev` 首轮在新 memory 未进入 retained DB/index 时，即使 5/5 node PASS 也被 startup recall 正确 blocked；`update-stored` project/npc memory、snapshot、DB-first audit 与 bounded brief 闭合后，第二轮 completed/publication-valid。...

- 2026-07-19(RV64-PPA-S2-Q1A-e2e)：Q1A 的 task-specific `npc-dev` 首轮在新 memory 未进入 retained DB/index 时，即使 5/5 node PASS 也被 startup recall 正确 blocked；`update-stored` project/npc memory、snapshot、DB-first audit 与 bounded brief 闭合后，第二轮 completed/publication-valid。agent-system 也证明 slug 必须由当前 non-history 事实支持，不能用只存在于历史 task-run 的 evidence/workflow 词自证。blocked runs 保留；此项不提升 live Q1/PPA 状态。
- 2026-07-19(RV64-PPA-S2-Q1A): **`OooMmuEpochOwner` abort-priority/rearm source-catalog GREEN；production 无实例，live Q1/v8b RED**。新增 registered `abort_valid_i` consumer 与 `abort_rearm_q`：abort 展示拍立即 block 并屏蔽 request/grant，沿上清 state/held bundle 且不写 epoch；只有 abort 当拍存在旧 request envelope 才进入 rearm，continuous-valid 期间 ready=0，valid-low edge 后开放，idle abort 不加 bubble。COMMIT quiet 被定义为 transaction-scoped sticky/irrevocable completion，capture block 不得组合门控 request producer。正例 release/assert、5/5 命名 assertion-negative、13/13 exact compile-success mutation、leaf lint/style/Yosys/static checker、fresh module 104/104、全 style、contract 289/89 均 PASS；strict/default 的 115 warnings（108 TIMESCALEMOD/2 PINCONNECTEMPTY/4 LATCH/1 UNOPTFLAT）与 pre-v8a 三路归一化 byte-match，故仍 RED，nonfatal parse/elab PASS。checker 还锁定 `mmu_epoch_q` 仅 reset/grant-fire 两个时序写点和 vsrc 无 leaf 引用。8-bit identity 已由 nested recovery `F(k)=2^k-1` 反例否决直接落地；下一步必须先定义全 holder last-reference/no-live-reuse/collision-stall，再实现 mismatch-cycle kill-now、下一拍 shared abort 与 CsrFile 同事件清除。独立 reviewer 复核连续/多拍 abort、quiet drop、epoch 与组合环后未发现 scoped blocker。证据 `.github/task-runs/2026-07-19-rv64-q1a-abort-priority/`；无 Linux/综合/STA/PPA 声明。
- 2026-07-19(RV64-PPA-S2-Q2-v8a-e2e)：v8a 合同的首次真实 `npc-dev --task-slug rv64-q2-v8a-contract` 在 dispatch 前暴露 AI 召回缺陷：profile 与整段 slug 被当作字面 AND term；保留 blocked run 后又证明旧失败 context/task identity 可令重跑循环假绿。修复不触碰 RTL/v8a 锁：runner 语义拆词、profile 解耦并强制 non-history primary，数据库在 live/stored FTS/LIKE 的 LIMIT 前排除 task-run history，artifact validator 拒历史 primary；github-index/agent-system 正反例已 completed。该环境修复只保证 v8a 证据链可审计，不把 314 项 RED、8 个 deferred blocker、full Q2、Linux、200MHz 或 PPA 提升为 GREEN。
- 2026-07-19(RV64-PPA-S2-Q2-v8a): **v7 被反例审查降级为历史 missing-interface inventory；可满足的中性 shadow foundation 已机器冻结，live RTL 仍 RED**。P0/P1 现为 8 项显式 blocker：IFU done/ack-generation 方向矛盾、held head 缺 live-present/flush 语义、8-bit identity 未进入 SQ/owner 且无 reuse guard、CsrFile prepare 非同 owner typed payload、FENCE.I ROB/frontend 跨域 owner、FENCE generation/capture-block 时序未定义、Q1 abort 缺失、checker 未加载 support child direction 的假 RED。v8a 只要求 ABI 宏、ROB precommit/identity-valid shadow、七级 2-permit/3-observation spine、顶层 exact tie-high、lane1 potential classifier 且禁止影响 commit1；不实例化 Q1，不激活 generation/permit，不宣称 full identity、payload、squash、epoch 或 FENCE.I 安全。17/17 checker mutation PASS；双 active-source 各 157、聚合 314 RED，digest `4099e530...b4384b0`，contract/baseline lock=`92c38c83...bd160a3`/`1dc0a5b6...bed98e9`。v7 四文件与 28-path source inventory 未改，162/162 及 hash check 重跑有效。下一原子切片只能先落 neutral shadow + equivalence/focused negative，不能直接复活 v7 full contract。
- 2026-07-18(RV64-PPA-S2-Q2): **machine-mapped mem0 contract/checker hardening checkpoint；live RTL 双变体聚合 1862 structural RED**。协议要求 head0 precommit + CsrFile normalized envelope、lane1 potential boundary 禁退休、held-age memory/IFU squash 双 ack 后才 WAIT_QUIET、legacy context writer 唯一仲裁、registered quiet/no-ingress、grant-fire 真实 leaf consumers 与 valid-owner dynamic epoch；v7 另锁定 mismatch shared abort、registered writer reserve/defer、generation-matched IFU ack、FENCE.I retire serialization、trap CSR/LR/transaction unique-next、active-source、精确宽度/宏值、registered quiet/ack、真实 leaf、valid capture、全 writer 唯一性与 SQ epoch mux provenance；release/OOO_ASSERT elaboration、exact producer/payload、guarded epoch/ROB/irrevocable storage/reset-arm、set-dominant squash completion、internal conditional/replicated-generate、任意深度 concat 与 unknown task actual 也已锁定；并新增 canonical reset/event、完整 ancestor guard path、module lexical binding、module-scope continuous-driver-only、generate shadow、nested selector writer、embedded task actual、unknown child/primitive driver、lexical port/clk/rst ownership、required-port critical audit 与 pre/post source snapshot 约束。checker mutation 162/162，runner 锁定双变体各 931、聚合 1862 RED，`fc5baa96190e9bcac70248f912523f8ae9192045885d6023b6cb940f4675a592` digest、`d830e31698425f431ad92fc907e2748b151399539e9736a0abfc0ee7d9d2d5fa` contract lock 与 `abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88` baseline lock；completion marker 还绑定全部证据哈希，仅在全门通过后生成。当前 issue1 memory 仍常量关闭；该 checkpoint 只用于下一原子实现和反例设计，不是功能/PPA GREEN。

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
