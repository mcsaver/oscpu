# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: producerid holder census system
- `focus_scope`: non-history
- `token_estimate`: 2380 / 2400

## Profile Suggestions
- `agent-system` score=22 matched=requested-profile, system command=`scripts/agent-e2e.sh --profile agent-system`
- `github-index` score=2 matched=system command=`scripts/agent-e2e.sh --profile github-index`
- `contracts` score=1 matched=system command=`scripts/agent-e2e.sh --profile contracts`
- `discovery` score=1 matched=system command=`scripts/agent-e2e.sh --profile discovery`
- `linux-device` score=1 matched=system command=`scripts/agent-e2e.sh --profile linux-device`

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
- `lines`: 1-8
- `tokens`: 439
- `heading`: agent-system.tsv
- `summary`: @include|discovery|||| / three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|AI_ENVIRONMENT.md;.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintai...

@include|discovery||||
three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|AI_ENVIRONMENT.md;.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证一页导航、canonical 路径与 Database/Skill/Agent 三层契约
runtime-artifact-boundary|agent-system|e2e_agent_system_runtime_artifact_boundary|agent-system|.github/ai-env/contracts/agent-env-runtime-artifacts.json;.github/ai-env/contracts/agent-env-policy.json;scripts/agent-maintain.sh|验证源码面与运行态 artifact/store 分层边界
state-machine-traceback|agent-system|e2e_agent_system_state_traceback|agent-system|.github/instructions/agent-env-state-machine.instructions.md;.github/ai-env/contracts/agent-env-state-traceability.json;scripts/e2e/lib/report.sh|验证状态机回退和 task-run state_traceback 字段
reviewer-inspector-gate|agent-system|e2e_agent_system_reviewer_inspector_gate|agent-system|.github/ai-env/contracts/agent-env-review-routing.json;.github/ai-env/contracts/agent-env-policy.json;.github/e2e/profiles/agent-system.tsv|验证 Reviewer/Inspector 路由已落成 profile 执行节点
rtl-task-contract|agent-system|e2e_agent_system_rtl_task_contract|agent-system|.github/ai-env/contracts/agent-env-rtl-task-contract.json;.github/instructions/rtl-agent-task-contract.instructions.md;.github/skills/prepare-rtl-task-contract/SKILL.md;.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py|验证本地 RTL 子任务契约可生成、校验、渲染并拒绝越权 mutation
commercial-delivery-readiness|agent-system|e2e_agent_system_commercial_delivery_readiness|agent-system|.github/ai-env/contracts/agent-env-delivery.json;deliverables/ai-dev-env-commercial-v1;scripts/package-ai-dev-env.sh|验证商业交付包装、旧产物归档和 delivery audit
profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile

### .github/memory/modules/npc.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-8
- `tokens`: 1515
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-20(RV64-v8l-global-producer-no-live-reuse): **当前绑定源码的全局 ProducerId holder census、birth fence 与 finite-generation wrap scoped GREEN；architecture/PPA 继续 RED/unpromoted**。`producer_holder_census.py` 从生产源码自动发现并与 manifest 精确对照 d...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-20(RV64-v8l-global-producer-no-live-reuse): **当前绑定源码的全局 ProducerId holder census、birth fence 与 finite-generation wrap scoped GREEN；architecture/PPA 继续 RED/unpromoted**。`producer_holder_census.py` 从生产源码自动发现并与 manifest 精确对照 direct full-P Q=15、显式组合 full-P reg 豁免=1、packed stage=5、token Q=12、generation authority=1，且拒绝 assertion shadow、非 `_q` full-P reg 逃逸、缺 IntIQ union、raw-index guard、新 holder 漏登记和 ledger 自晋级。`OooIntIssueQueue` 仅从 edge-old `valid_q/producer_id_q` 生成 mask；Dispatch 的 lane0/pair/lane1 birth 使用同一个 exported alloc full-P 对完整 union 查重。IntBackend union 覆盖 tracker、MulDiv/CLMUL、FP、pending CSR 与 mem-res/EX0/EX1/branch transient；MIQ/buffer/bridge/terminal/SQ token 用 tracker live/map 约束，SQ raw full-P 另有独立 scan；各 holder 的本地 raw-state 断言还固定 `valid => P/token known`，防止 X 索引令 union/subset 检查空洞。真实 tracker-full 与 backend credit=0 均证明 memory IQ 不 pop/不 capture；credit 返回后 reservation+token 原子出生。`GEN_W=1` 走 production 路径完成32-P回绕；8/8 assert/release baseline、9/9 compile-success mutation、9/9 checker unit、v8d..v8l 8/8 focused、106/106 module、contract 400/89 PASS。Icarus variable force/release 保值导致的相邻探针遮蔽曾令删 EX1 mutation 假绿，现以互异 full-P + release 后 reset/清零检查闭合；静态摘要也已改为从本轮原始日志/manifest 动态提取计数，陈旧或解析失败即 fail closed。reviewer 仅据自包含摘要给 scoped pass；manifest 仍声明 instance/semantic incomplete，architecture inventory `OVERALL: RED`，无 official/Linux、fresh synthesis/STA/power/Pareto 晋级。证据 `.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/`，`promotion_eligible=false`。
- 2026-07-20(RV64-v8l-workflow-e2e): `agent-system`/`github-index` completed；首个 `npc-dev` 因 slug 未包含 canonical `ProducerId holder census` 领域词而 recall blocked，五个工程节点 PASS 也未覆盖该失败。保留失败包后以语义 slug 重跑 completed。task slug 是 bounded brief 的检索输入，后续 RTL task-run 必须带稳定领域名词而非仅用宽泛 `global-producer`。
- 2026-07-20(RV64-v8k-pending-csr-producer-lease): **dispatched pending CSR 的 full ProducerId lease、exact commit 与 feedback-free admission scoped GREEN；全核 architecture/PPA 继续 RED**。pre-ROB capture 不制造 P；真实 lane0 ROB enqueue 沿才把 full `P={generation,rob_idx}` 锁入 `OooPendingSystemSequencer`，raw Q lease 直接并入 external live mask，ordinary clear/`clear_dispatched` 不能切断 post-dispatch owner。CSR side effect 只由 logical claim + raw lease + commit0 full-PID exact match + PC coherence 授权；raw lease 或 logical claim 任一存在都封住 queue-head fallback，partial metadata、same-index/different-generation 与 PC mismatch 两路静默。完整 `pending_system_clear` 不再反喂 admission，新增 feedback-free gate；pending jump 只有 `resolve_ready && (misaligned || nolink_commit || redirect_after_dispatch)` 才能取消，裸 ready 自锁反例由 cross-ready TB 和 `pending_jump_ready_overcancels` mutation 关闭。focused source audit 14/14、release/assert、两个 expected-fail assertion probes、10/10 compile-success semantic mutation、legacy v8d-v8j 6/6、fresh module aggregate 106/106、style/contract `388>=89` PASS；full lint 仍为继承 rc=2/115 warnings且 normalized SHA `414dbc39...06e2b` 与 v8j 相同，real architecture inventory 明确 `OVERALL: RED`。implementation reviewer verdict=pass/blocker=0，但完整 SCC/formal、原始 mutation 独立复跑与 core-local flush/commit 同沿协议仍为盲区；non-CSR pending、完整 holder census、finite-generation global no-live-reuse、official/Linux、fresh synthesis/STA/power/Pareto 未关闭。证据 `.github/task-runs/2026-07-20-rv64-v8k-pending-csr-producer-lease/`，`promotion_eligible=false`。
- 2026-07-19(RV64-v8j-branch-resolve-producer-authorization): **branch-resolve full ProducerId carrier、cycle-free exact-open query 与 actual control capability scoped GREEN；全核 identity/PPA RED**。`OooIntBackend` 的 resolve q 保存 full PID，raw ROB boundary 仅由低位投影；`OooDispatchBackend` 纯代理专用 query，`OooRob` 只用 edge-old valid/done/full-PID/recover 状态判 open，不读 current self-kill。redirect、ROB walk、BPU update 与所有 selective kill 只由 candidate + query-open + raw registered EX0 full-PID coherence 授权，completion-open/WB-valid/killed-now 等 semantic valid 被结构性排除。既有 `producer_target_killed_now` helper 的 ambient head/kill/recovery 依赖已改为 `automatic` + 六项显式参数，关闭同 PID 只切 kill 时 Icarus 残留旧组合值的测试根因。focused release/assert 3/3、16项 audit、12/12 mutation、v8d-v8i legacy 10/10、module 105/105、style/contract 366/89 PASS；lint 115 与 v8i byte-equal，architecture inventory 仍 RED。reviewer 无 blocker但未独立提供 elaborated SCC/formal loop、原始波形/mutation 复跑或未来多 kill-source 仲裁证据；pending-system/CSR、完整 census/global reuse、official/Linux/fresh synthesis/STA/power/Pareto 未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8j-branch-resolve-producer-authorization/`。

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
