# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rv64 xret current mode
- `focus_scope`: non-history
- `token_estimate`: 2308 / 2400

## Profile Suggestions
- `agent-system` score=17 matched=mode, requested-profile command=`scripts/agent-e2e.sh --profile agent-system`
- `rv64-linux` score=7 matched=mode, rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `display-vga` score=2 matched=rv64 command=`scripts/agent-e2e.sh --profile display-vga`
- `linux-device` score=2 matched=rv64 command=`scripts/agent-e2e.sh --profile linux-device`
- `nemu` score=2 matched=mode, rv64 command=`scripts/agent-e2e.sh --profile nemu`

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
- `lines`: 2-6
- `tokens`: 1291
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-21(RV64-v9e-xret-current-design): **XRET-G1 在当前 design_id 上 CLOSED；production RTL 未改，full-core arch-stable/PPA 未晋级**。legality owner 为 `OooFetchHeadClassifyGate`：MRET 仅 M mode 合法，SRET 在 U mode 非法、S mode+TSR 非法、M mode 不受 TSR...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-21(RV64-v9e-xret-current-design): **XRET-G1 在当前 design_id 上 CLOSED；production RTL 未改，full-core arch-stable/PPA 未晋级**。legality owner 为 `OooFetchHeadClassifyGate`：MRET 仅 M mode 合法，SRET 在 U mode 非法、S mode+TSR 非法、M mode 不受 TSR 阻断；不在 `CsrFile` 重复解码。head0/lane1 exception-versus-system capture 分别由 `OooPendingDispatchArbiter` 与 `OooPendingLane1CaptureGate` 掌握，精确 metadata 经 `OooPendingTrapExitSequencer/OooCsrTrapRequestMux` 进入 CSR。focused marker 为 `cases=7 legal=3 illegal=4 raw_preserved=7 legal_system=3 illegal_arch_trap=4`；四个 full-core marker 分别证明 legal MRET/SRET 各 1 次 request/commit/return，以及 illegal MRET/SRET 各 1 次 precise exception、0 return request、0 faulting commit、cause=2、PC/tval/mepc/mtval exact，lane1 case 另有 `older_lane0=1`。八个 current-source compile-success RTL verification variants 覆盖 mode/TSR legality、false-closed positive control、head0/lane1 routing、PC/tval，另有 2/2 zero-observer sensitivity 配置；全部动态拒绝且 source unchanged。模块 109/109、XRET 单测 10/10、永久入口 `make -C npc/rv64 check-xret-current-mode` 双跑 result/raw/variant/module/focused/program SHA 全相同；result `26f29205929a75a9b824f1ab2b3ac938bb453b8e027f041a0f1e02b364d257a1`，design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。九项 directed architecture GREEN；full-core `ARCH_STABLE=GAP/blockers=44`、`ppa=UNQUALIFIED`、`promotion_eligible=false`，且尚无同设计 full functional aggregate/完整 freeze inputs。
- 2026-07-21(RV64-v9d-fdg-current-design-rebind): **FDG-G1 在当前 design_id 上 CLOSED；production RTL 未改，full-core arch-stable/PPA 未晋级**。分类/admission/final sink 为 `OooFetchHeadClassifyGate/OooFetchHeadPairGate → OooFrontendDispatchGate → OooFrontendBackendDispatchMux → OooCoreTopGlue`；`NpcCoreTop.v` 不是该谓词 owner。precise-trap owner 独立经 `OooPendingDispatchArbiter → OooPendingTrapExitSequencer → OooCsrTrapRequestMux/CsrFile`。focused marker 精确为 `illegal_fp_cases=4 illegal_classified=4 arch_trap=4 fp_disabled=4 backend_blocked=4 legal_fp_cases=1 legal_backend_present=1`；全核 marker 为 `arch_trap_capture=1 capture_pc_match=1 capture_tval_match=1 ordinary_backend_present=0 core_backend_present=0 commit_oracle_hits=1 illegal_fp_commit=0 handler=1 mret=1 cause=2 csr_mepc_match=1 csr_mtval_match=1`。六个 current-source compile-success RTL 验证变体分别覆盖 ordinary/lane1 exclusion、合法正路径、final sink、trap PC 与 trap tval，另有 1/1 commit-observer 非空性探针；全部被定向 oracle 拒绝且 production source unchanged。模块 109/109、FDG 单测 12/12。永久入口 `make -C npc/rv64 check-fdg-arch-trap` 连续双跑 result/raw/variant/module/program SHA 全相同；result `6238dbef481273da7d6acc00156a9bf1a23c90ebfb610498053377b66df88fb0`，design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；九项 directed architecture GREEN，但 full-core `ARCH_STABLE=GAP/blockers=44`、`ppa=UNQUALIFIED`、`promotion_eligible=false`，且尚无当前 official/AM/DiffTest 同源 aggregate。v2/v3 no-tools reviewer 均判 PASS、无 P0/P1；不外推逐 lane commit sensitivity、连续 trap/flush metadata 配对、early-classifier 变体 completeness、任意日志 token 无碰撞或全核晋级。
- 2026-07-21(RV64-v9c-instret-retirement): **INSTRET-G1 在最终同设计上 CLOSED；production RTL 未改，full-core arch-stable/PPA 仍未晋级**。owner/source-of-truth 是 `OooCommitOutputMux` 最终可见 lane：`retire_count_o=popcount(commit_valid && !commit_exception)`，随后唯一连接到`NpcCoreTop.CsrFile.instret_inc_i`；core-local 预 mux 计数不得进入 CSR。Sv39 full-core 程序给出精确event inventory：`exception_lanes=2 exception_zero_delta=2 mret=1 sret=6 sfence_vma=1 control_exact=8 control_total=8 csr_delta_checks=1052`，并由最终 `minstret` 聚合等式关闭尾拍。109/109 动态派生模块测试、3/3 focused 和 3 个 compile-success 当前源码 RTL 变异均通过预期判定；evidence builder/arch-stable validator 现场复算全部 RTL identity、source/log SHA、程序事件、模块membership 与变异源码。永久入口 `make -C npc/rv64 check-instret-retirement`，design `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；`INSTRET-G1=CLOSED` 只覆盖 reset 退出、`mcountinhibit.IR=0`、无软件写 `minstret` 的当前合同，不外推 WFI、程序级 FENCE.I、inhibit 切换、软件写/overflow 或 full-core promotion。当前九项定向architecture GREEN，`ARCH_STABLE=GAP/blockers=45`、`ppa=UNQUALIFIED`、`promotion_eligible=false`。证据 `.github/task-runs/2026-07-21-rv64-v9c-instret-retirement/`。

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
