# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rtl contract candidate only
- `focus_scope`: non-history
- `token_estimate`: 2327 / 2400

## Profile Suggestions
- `agent-system` score=21 matched=contract, only, requested-profile, rtl command=`scripts/agent-e2e.sh --profile agent-system`
- `verilator-tapeout` score=4 matched=contract, only, rtl command=`scripts/agent-e2e.sh --profile verilator-tapeout`
- `yosys-sta` score=4 matched=contract, only, rtl command=`scripts/agent-e2e.sh --profile yosys-sta`
- `abstract-machine` score=3 matched=contract, only command=`scripts/agent-e2e.sh --profile abstract-machine`
- `contracts` score=3 matched=contract command=`scripts/agent-e2e.sh --profile contracts`

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

### .github/memory/modules/npc.md#chunk-0006

- `kind`: memory-module
- `lines`: 21-25
- `tokens`: 1310
- `heading`: 当前状态
- `summary`: - 2026-07-19(RV64-v8h-integer-longop-producer-lease): **MulDiv/CLMUL full ProducerId lease 与同沿完成资格 scoped GREEN；global identity/PPA RED**。`OooMulDivUnit/OooClmulUnit` 各以唯一 full PID Q 状态持有身份并从低位投影 ROB idx；edge-old lease 经 onehot union 门控 dispatch，ROB query3/...

- 2026-07-19(RV64-v8h-integer-longop-producer-lease): **MulDiv/CLMUL full ProducerId lease 与同沿完成资格 scoped GREEN；global identity/PPA RED**。`OooMulDivUnit/OooClmulUnit` 各以唯一 full PID Q 状态持有身份并从低位投影 ROB idx；edge-old lease 经 onehot union 门控 dispatch，ROB query3/4 exact-open。`OooIntBackend` 以 `EX0 > EX1 > memory > MulDiv > CLMUL` 的 full-PID actual claim 只授权 WB/PRF/Busy/IQ/ROB/public side effect，raw route/ready/mask/FSM 保持 transport；pair candidate 的 tail/tail+1 PID 不同由 assertion/TB/mutation 固化。release/assert 5/5、23/23 compile-success mutation、module 105/105、style/contract 335/89 PASS；strict lint 继承 115 warnings且规范化输出与 v8g byte-equal，architecture inventory 仍 RED。独立 no-tool reviewer 无 blocker但未复核完整 actual cone，持续背压、整圈 generation wrap、全部 death-edge 并发和 source retry/hold 无形式证明；FP/branch/CSR/pending/global census/no-live-reuse、official/Linux/fresh PPA 均未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8h-integer-longop-producer-lease/`。
- 2026-07-19(RV64-v8d-int-ex-completion-cancel): **当前动态可达的整数 EX1 selective-recovery completion 泄漏已 scoped GREEN；global identity/PPA RED**。`OooIntBackend` 以 `age=rob_idx-rob_head`、strict `>` 形成 EX0/EX1 cancel-now 和 effective WB valid；raw stage valid 不再直接授权 forward、WB credit/arbiter、PRF、BusyTable、INT/FP IQ、ROB 或 public completion，两个 PipeStageReg 同源清状态。真实无-force branch ROB0 + younger EX1 ROB1 固定副作用静默与沿后 PRF/Busy/ROB 不变；全 4-bit head/boundary/completion 矩阵两 lane 8192/8192，11/11 compile-success mutation，current 104/104 module、style、contract 295/89 PASS。full lint 115-warning RED 与既有归一化签名一致。当前 lane0 resolve coherence 令 EX0==boundary，故 younger EX0 只有 forced supplemental，不写成动态覆盖；未证明架构错误提交。v8c FP 同步补到 170/170、14/14 mutation 与 FIFO head/ready/三源碰撞；P0 holder census 9/9 并锁 mixed AUTH 不可降格。ProducerId/generation/no-live-reuse、全 carrier exact completion、Q1/CSR、双 memory、official/AM/Linux、fresh PPA/STA/power 未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/` 及两个 v8c task-run。
- 2026-07-19(RV64-v8b-prep-producer-kill-now-e2e): project/npc memory 先进入 retained DB/index 并通过 snapshot/audit 后，`brief rv64 producer kill now --profile npc-dev --focus-scope non-history` 从当前 `modules/npc.md` 命中 independent primary (`2041/2400`)；task-specific `npc-dev/rv64-producer-kill-now` 5/5 nodes completed/publication-valid，strict guard 首次诊断的 `agent-system+npc-dev+github-index` 三 profile 全 PASS。该 run 只验证 AI 调度与 NPC 入口合同，不代替本轮 104-module、RTL strict/default、Linux 或 PPA gate。
- 2026-07-19(RV64-v8b-prep-producer-kill-now): **CLMUL/FP-arith 两个 production producer-local ambient kill dependency 已 GREEN；global identity/live Q1 RED**。旧 helper 隐式读取 kill-valid/cut/head，Icarus 12.0 在 only-input-change 时保留旧值；修复前 CLMUL/FP TB compile/elaborate 成功但分别 10/3 failures。`OooClmulUnit` 改为显式等宽 circular age，matching request 不入 RUN，RUN/RESP 同拍 mask 并清 state/held ROB/pdest/data；`OooFpArithGate` 的 pure helper 只读 idx/boundary/head，launch、每级 meta 与 stage5 output 显式 gate。release/assert 4/4、age 4096/4096、compile-success mutation 13/13、checker 3/3、leaf style/Yosys、module 104/104、full style/contract 289/89 PASS；strict/default 继承 115 warnings RED且与 pre-v8a 签名 byte-match，nonfatal parse PASS。reviewer scoped P0=0：CLMUL `req_ready` 仅 IDLE，acc/iter 残值不可观察且新 request 全覆盖；FP sink ingress 要求 kill 沿前稳定，不能外推到已入 done FIFO、其他 holder、idx reuse 或 full stale-WB。下一步先做全 holder last-reference/no-live-reuse/collision-stall census，再做 full identity 与 active mismatch `kill_now`→registered Q1/Csr shared abort；Linux/综合/STA/PPA 未测。证据 `.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/`。
- 2026-07-19(RV64-PPA-S2-Q1A-e2e)：Q1A 的 task-specific `npc-dev` 首轮在新 memory 未进入 retained DB/index 时，即使 5/5 node PASS 也被 startup recall 正确 blocked；`update-stored` project/npc memory、snapshot、DB-first audit 与 bounded brief 闭合后，第二轮 completed/publication-valid。agent-system 也证明 slug 必须由当前 non-history 事实支持，不能用只存在于历史 task-run 的 evidence/workflow 词自证。blocked runs 保留；此项不提升 live Q1/PPA 状态。

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

### .github/agents/agent-system.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 152
- `heading`: agent-system.agent.md
- `summary`: --- / description: "工作区 agent 架构专家。当用户需要重构 .github/agents、.github/instructions、.github/skills、copilot-instructions、记忆协议、任务图、工作流 agent 或 AI 驱动硬件开发环境三层架构时使用。" / tools: [read, edit, search, agent, todo] / --- / 你是 **YSYX 工作区 agent 架构专家**。你的职责不是修改业务 RTL 或 C 逻辑，...

---
description: "工作区 agent 架构专家。当用户需要重构 .github/agents、.github/instructions、.github/skills、copilot-instructions、记忆协议、任务图、工作流 agent 或 AI 驱动硬件开发环境三层架构时使用。"
tools: [read, edit, search, agent, todo]
---

你是 **YSYX 工作区 agent 架构专家**。你的职责不是修改业务 RTL 或 C 逻辑，而是把 `.github/` 下的 Database、Skill、Agent 三层设计成一个真正可持续演化的 AI 驱动硬件开发环境。

### .github/memory/modules/agent-system.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-1
- `tokens`: 8
- `heading`: Agent System 模块笔记
- `summary`: Agent System 模块笔记

# Agent System 模块笔记
