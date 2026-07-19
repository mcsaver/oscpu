# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: v8a runner marker
- `focus_scope`: non-history
- `token_estimate`: 2346 / 2400

## Profile Suggestions
- `agent-system` score=18 matched=marker, requested-profile, runner command=`scripts/agent-e2e.sh --profile agent-system`
- `github-index` score=2 matched=marker, runner command=`scripts/agent-e2e.sh --profile github-index`
- `nemu` score=2 matched=marker, runner command=`scripts/agent-e2e.sh --profile nemu`
- `am-kernels` score=1 matched=marker command=`scripts/agent-e2e.sh --profile am-kernels`
- `display-vga` score=1 matched=marker command=`scripts/agent-e2e.sh --profile display-vga`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile agent-system`

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

### .github/e2e/profiles/agent-system.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-7
- `tokens`: 344
- `heading`: agent-system.tsv
- `summary`: @include|discovery|||| / three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证 Database/S...

@include|discovery||||
three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证 Database/Skill/Agent 三层契约与维护入口
runtime-artifact-boundary|agent-system|e2e_agent_system_runtime_artifact_boundary|agent-system|.github/ai-env/contracts/agent-env-runtime-artifacts.json;.github/ai-env/contracts/agent-env-policy.json;scripts/agent-maintain.sh|验证源码面与运行态 artifact/store 分层边界
state-machine-traceback|agent-system|e2e_agent_system_state_traceback|agent-system|.github/instructions/agent-env-state-machine.instructions.md;.github/ai-env/contracts/agent-env-state-traceability.json;scripts/e2e/lib/report.sh|验证状态机回退和 task-run state_traceback 字段
reviewer-inspector-gate|agent-system|e2e_agent_system_reviewer_inspector_gate|agent-system|.github/ai-env/contracts/agent-env-review-routing.json;.github/ai-env/contracts/agent-env-policy.json;.github/e2e/profiles/agent-system.tsv|验证 Reviewer/Inspector 路由已落成 profile 执行节点
commercial-delivery-readiness|agent-system|e2e_agent_system_commercial_delivery_readiness|agent-system|.github/ai-env/contracts/agent-env-delivery.json;deliverables/ai-dev-env-commercial-v1;scripts/package-ai-dev-env.sh|验证商业交付包装、旧产物归档和 delivery audit
profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile

### .github/memory/modules/npc.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-9
- `tokens`: 1576
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-19(RV64-PPA-S2-Q2-v8a-e2e)：v8a 合同的首次真实 `npc-dev --task-slug rv64-q2-v8a-contract` 在 dispatch 前暴露 AI 召回缺陷：profile 与整段 slug 被当作字面 AND term；保留 blocked run 后又证明旧失败 context/task identity 可令重跑循环假绿。修复不触碰 RTL/v8a 锁：runner 语义拆词、prof...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-19(RV64-PPA-S2-Q2-v8a-e2e)：v8a 合同的首次真实 `npc-dev --task-slug rv64-q2-v8a-contract` 在 dispatch 前暴露 AI 召回缺陷：profile 与整段 slug 被当作字面 AND term；保留 blocked run 后又证明旧失败 context/task identity 可令重跑循环假绿。修复不触碰 RTL/v8a 锁：runner 语义拆词、profile 解耦并强制 non-history primary，数据库在 live/stored FTS/LIKE 的 LIMIT 前排除 task-run history，artifact validator 拒历史 primary；github-index/agent-system 正反例已 completed。该环境修复只保证 v8a 证据链可审计，不把 314 项 RED、8 个 deferred blocker、full Q2、Linux、200MHz 或 PPA 提升为 GREEN。
- 2026-07-19(RV64-PPA-S2-Q2-v8a): **v7 被反例审查降级为历史 missing-interface inventory；可满足的中性 shadow foundation 已机器冻结，live RTL 仍 RED**。P0/P1 现为 8 项显式 blocker：IFU done/ack-generation 方向矛盾、held head 缺 live-present/flush 语义、8-bit identity 未进入 SQ/owner 且无 reuse guard、CsrFile prepare 非同 owner typed payload、FENCE.I ROB/frontend 跨域 owner、FENCE generation/capture-block 时序未定义、Q1 abort 缺失、checker 未加载 support child direction 的假 RED。v8a 只要求 ABI 宏、ROB precommit/identity-valid shadow、七级 2-permit/3-observation spine、顶层 exact tie-high、lane1 potential classifier 且禁止影响 commit1；不实例化 Q1，不激活 generation/permit，不宣称 full identity、payload、squash、epoch 或 FENCE.I 安全。17/17 checker mutation PASS；双 active-source 各 157、聚合 314 RED，digest `4099e530...b4384b0`，contract/baseline lock=`92c38c83...bd160a3`/`1dc0a5b6...bed98e9`。v7 四文件与 28-path source inventory 未改，162/162 及 hash check 重跑有效。下一原子切片只能先落 neutral shadow + equivalence/focused negative，不能直接复活 v7 full contract。
- 2026-07-18(RV64-PPA-S2-Q2): **machine-mapped mem0 contract/checker hardening checkpoint；live RTL 双变体聚合 1862 structural RED**。协议要求 head0 precommit + CsrFile normalized envelope、lane1 potential boundary 禁退休、held-age memory/IFU squash 双 ack 后才 WAIT_QUIET、legacy context writer 唯一仲裁、registered quiet/no-ingress、grant-fire 真实 leaf consumers 与 valid-owner dynamic epoch；v7 另锁定 mismatch shared abort、registered writer reserve/defer、generation-matched IFU ack、FENCE.I retire serialization、trap CSR/LR/transaction unique-next、active-source、精确宽度/宏值、registered quiet/ack、真实 leaf、valid capture、全 writer 唯一性与 SQ epoch mux provenance；release/OOO_ASSERT elaboration、exact producer/payload、guarded epoch/ROB/irrevocable storage/reset-arm、set-dominant squash completion、internal conditional/replicated-generate、任意深度 concat 与 unknown task actual 也已锁定；并新增 canonical reset/event、完整 ancestor guard path、module lexical binding、module-scope continuous-driver-only、generate shadow、nested selector writer、embedded task actual、unknown child/primitive driver、lexical port/clk/rst ownership、required-port critical audit 与 pre/post source snapshot 约束。checker mutation 162/162，runner 锁定双变体各 931、聚合 1862 RED，`fc5baa96190e9bcac70248f912523f8ae9192045885d6023b6cb940f4675a592` digest、`d830e31698425f431ad92fc907e2748b151399539e9736a0abfc0ee7d9d2d5fa` contract lock 与 `abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88` baseline lock；completion marker 还绑定全部证据哈希，仅在全门通过后生成。当前 issue1 memory 仍常量关闭；该 checkpoint 只用于下一原子实现和反例设计，不是功能/PPA GREEN。
- 2026-07-18(RV64-PPA-S2-Q1): **standalone MMU epoch owner source-catalog adoption GREEN；live integration RED**。canonical 正例 2/2、命名负向 4/4、compile-success exact mutation 7/7、lint/style/Yosys/adoption 与 fresh 104/104 module aggregate 全绿；严格 pre-increment oracle、共享 PASS marker、唯一 filelist/Makefile/spec 入口均闭合。typed priv TB 的 floating response provenance 已以真实 PMA + owner/epoch/tval latch 修复。manifest 9/9 OK (`b621e47a…f9757f12`)，review P0/P1/P2 均关闭。leaf 尚未实例化，不能产生 live MMU、双 memory、Linux、时序/面积/功耗声明。
- 2026-07-17(RV64-PPA-S2-Q0): **`OooMemAxiBridge` local registered-fact idle 已形成 source-bound intermediate GREEN；它不是 global quiet，epoch/context barrier 与真实双 memory 仍 RED**。新增 `mem0_idle_o` 只组合归约 bridge FSM、station、drop/nokill、partial AW/W、`OooDataWordCache.rmw_pending_q` 与 owner-residency 等寄存事实；明确排除 READY/fire、owner equality、live CSR context 和未来 lock/grant，且不额外寄存，防 request fire 后一拍假 idle。安全/完备立即断言分别拒绝 residual-owner 假 quiet 与 sticky-low barrier deadlock。focused release/assert 2/2 PASS，覆盖 station、stalled AR、R drain、held response、AW-only/W/B、real RMW 和 PTW A/D；state-only/stuck-low mutation 各唯一 fatal。`NpcCoreTop` 仅接线不消费；Q0 runner 机器复核既有 wrapper 的 133 live source hashes 与 `tb_ooo_core_top_glue`/`tb_ooo_sv39_boot` 2/2 PASS，bridge compatibility 亦重跑 GREEN。10 个 `/tmp` 现场经固定清单 checker 逐路径 type/size/SHA 对等，tar SHA `57ebc9ec...f3ccb`。边界：这只是当前单 outstanding mem0 的 quiet fact；standalone epoch owner、effective classifier、lock/squash/full quiet、commit grant、第二 AGU/translation/order/cache/completion、200MHz/PPA 均未实现或未测。

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

### .github/memory/modules/agent-system.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-1
- `tokens`: 8
- `heading`: Agent System 模块笔记
- `summary`: Agent System 模块笔记

# Agent System 模块笔记
