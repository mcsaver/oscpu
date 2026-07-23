# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rtl contract
- `focus_scope`: non-history
- `token_estimate`: 2247 / 2400

## Profile Suggestions
- `agent-system` score=20 matched=contract, requested-profile, rtl command=`scripts/agent-e2e.sh --profile agent-system`
- `contracts` score=3 matched=contract command=`scripts/agent-e2e.sh --profile contracts`
- `verilator-tapeout` score=3 matched=contract, rtl command=`scripts/agent-e2e.sh --profile verilator-tapeout`
- `yosys-sta` score=3 matched=contract, rtl command=`scripts/agent-e2e.sh --profile yosys-sta`
- `abstract-machine` score=2 matched=contract command=`scripts/agent-e2e.sh --profile abstract-machine`

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

### .github/memory/modules/yosys-sta.md#chunk-0010

- `kind`: memory-module
- `lines`: 58-67
- `tokens`: 820
- `heading`: 踩坑记录
- `summary`: <!-- 本模块特有的问题和经验 --> / - 2026-07-08: `STA_SYNTH_PUBLIC_AUTONAME=0` 只能跳过末尾 public net `autoname`，不能跳过中段 DFF/cell `rename/autoname t:*DFF* %n`；本轮第一条四黑盒探针在 `PmpChecker` 等模块产生 389M 原始日志并被中止。新增/使用 `STA_SYNTH_DFF_AUTONAME=0` 后，日志出现 `[INFO]: SKIPPING DFF/cell auto...

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- 2026-07-08: `STA_SYNTH_PUBLIC_AUTONAME=0` 只能跳过末尾 public net `autoname`，不能跳过中段 DFF/cell `rename/autoname t:*DFF* %n`；本轮第一条四黑盒探针在 `PmpChecker` 等模块产生 389M 原始日志并被中止。新增/使用 `STA_SYNTH_DFF_AUTONAME=0` 后，日志出现 `[INFO]: SKIPPING DFF/cell autoname`，同配置完成并写出网表。后续 bounded 综合 probe 默认应使用 fast-name 模式，只有人工审查命名需求时再打开可读 autoname。
- 2026-07-08: 顶层 `.gitignore` 曾整目录忽略 `/yosys-sta/`，但 RV64 综合实际依赖本地 `yosys-sta/scripts/yosys.tcl` 与 `scripts/pdk/*.tcl` 的 flow 开关；这会让 fast-name/blackbox 能力变成本机隐含状态。本轮已用精确 allowlist 跟踪 `yosys-sta/Makefile`、`yosys-sta/scripts/*.tcl` 与 `yosys-sta/scripts/pdk/*.tcl` 必要入口，`result/` 等本地产物仍忽略。后续修改 Yosys flow 时必须同步检查 allowlist 与 e2e contract，不再只改 ignored 工具目录。
- 2026-07-08: `STA_SYNTH_PUBLIC_AUTONAME=0` 未阻止本轮 `NpcTop` full stdcell 探针产生大量 rename/autoname-style 输出；`PmpChecker`、issue queue、BPU 等 ABC 回灌后的长名传播会显著放大日志与 runtime。后续应提供 machine netlist/probe 模式，尽量避免把 public/autoname 可读性放进常规 bounded 综合验证内循环。
- 2026-07-08: `SYNTH_BLACKBOX_MODULES` 只应用于显式宏边界实验，默认综合/仿真必须读真实 RTL。不存在的模块名会让 Yosys `select -module` 报错，这是期望行为，可防止拼错模块名产生假绿。blackbox 网表中未知宏面积会在 `stat` 中显示 `Area for cell type ... is unknown!`，交付时必须单列为未闭合边界。
- 2026-07-07: RV64 RTL 直接进 `yosys-sta` 时必须传 `VERILOG_INCLUDE_DIRS="$(VSRCDIR) $(RTL_INCLUDE_DIR)"`，否则 `read_verilog -sv` 会在 `define.v` include 上失败。全顶首次 smoke 不宜 `flatten`，也不宜跑 SAT `share -aggressive`；`yosys-sta` 现有 `SYNTH_FLATTEN`、`SYNTH_SHARE`、`SYNTH_STOP_AFTER_COARSE`、`SYNTH_PUBLIC_AUTONAME` 开关，RV64 默认使用 hierarchy + no-share。`SYNTH_STOP_AFTER_COARSE=1` 只用于 front/coarse 可综合性验证，不可替代标准单元网表和 STA。
- 2026-04-14: 把 `npc/single` 的 RTL 直接喂给 `yosys-sta` 时，不应该把 `NpcSimTop.sv` 混进去；它含有 `import "DPI-C"` 的宿主桥接任务，只适合 Verilator 仿真。当前应把综合对象收敛为 `NpcCore` 及其纯 RTL 子模块。
- 2026-04-14: `WNS/TNS` 过关不代表报告全清；本轮 `NpcCore` 在 500MHz 下时序满足，但 `NpcCore.cap` 仍出现 `ICGX0P5H7L/ECK` 最大电容违规，因此做综合复盘时必须同时看 `synth_check.txt`、`NpcCore.rpt` 和 `NpcCore.cap/trans/fanout`。

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

### .github/memory/modules/yosys-sta.md#chunk-0012

- `kind`: memory-module
- `lines`: 84-102
- `tokens`: 410
- `heading`: 2026-07-13 T3K fresh H7CL 200MHz evidence
- `summary`: - fresh netlist SHA `0161d3d4...b32f`，known area `1573200.16`，synthesis runtime / `1349.67s`。审计冻结 110 RTL、完整 vsrc tree、14 flow inputs、5 liberty、9 evidence / scripts、6 tool binaries及 exact parameter/version，pre/post 全绿；但 / `dynamic_libraries_frozen=false`、`t...

## 2026-07-13 T3K fresh H7CL 200MHz evidence

- fresh netlist SHA `0161d3d4...b32f`，known area `1573200.16`，synthesis runtime
  `1349.67s`。审计冻结 110 RTL、完整 vsrc tree、14 flow inputs、5 liberty、9 evidence
  scripts、6 tool binaries及 exact parameter/version，pre/post 全绿；但
  `dynamic_libraries_frozen=false`、`tool_support_tree_frozen=false`，只可称扩展 provenance，
  不能称 signoff。综合时冻结的 9 个 evidence scripts 已另存快照，避免后续 OpenSTA checker
  修订篡改综合输入身份。
- focused v6 采用 structure cone + physical endpoint intersection：旧网表
  `legacy/head/state/illegal/probe=133/133/133/133/0`，fresh 为
  `0/133/133/133/133`；旧网表冒充 fresh 精确 RED。该证据证明共享 main legality 物理路径
  被 probe 替换，不要求删除所有 commit/pending 合法控制弧。
- global 5ns final-v6：OpenSTA 3.1.0、loops0、top40=40、WNS `-8.720ns`、TNS
  `-199154.36ns`、power `0.117W`；告警集合仍精确为 input303/output1861/
  unconstrained1863。target `--expect miss` PASS、`--expect met` 精确 rc=1，200MHz 未达。
- 当前 top path arrival 约 13.688ns，起于 fetch bridge/ITLB 状态，经过 PMP、packet/RVC
  decode 与 frontend control，落到 fetch-PC-outstanding 寄存器；下一轮 T3L 必须以新的
  source/structure/focused timing contract 证明切点，不能复用 T3K 网表或仅按 top40 token
  计数宣称优化。
