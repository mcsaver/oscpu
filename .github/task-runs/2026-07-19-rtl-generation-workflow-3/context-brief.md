# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: rtl generation workflow
- `focus_scope`: non-history
- `token_estimate`: 2124 / 2400

## Profile Suggestions
- `github-index` score=16 matched=requested-profile command=`scripts/agent-e2e.sh --profile github-index`
- `agent-system` score=2 matched=rtl, workflow command=`scripts/agent-e2e.sh --profile agent-system`
- `nemu` score=1 matched=generation command=`scripts/agent-e2e.sh --profile nemu`
- `verilator-tapeout` score=1 matched=rtl command=`scripts/agent-e2e.sh --profile verilator-tapeout`
- `yosys-sta` score=1 matched=rtl command=`scripts/agent-e2e.sh --profile yosys-sta`

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

### .github/memory/claude-auto-memory/rtl-coding-standard.md#chunk-0001

- `kind`: memory
- `lines`: 1-24
- `tokens`: 832
- `heading`: rtl-coding-standard.md
- `summary`: --- / name: rtl-coding-standard / description: "User's mandatory RTL-writing methodology for this repo — topology-first, hardware-structural, function restrictions" / metadata: / node_type: memory / type: feedback / originSessionId: 0353a89c-6ba9-4a48-b7b5-...

---
name: rtl-coding-standard
description: "User's mandatory RTL-writing methodology for this repo — topology-first, hardware-structural, function restrictions"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 0353a89c-6ba9-4a48-b7b5-b2e6baab6210
---

用户(数字 IC/RTL 工程背景)对本仓库 RTL 写作的强制要求(2026-06-28/29 多次明确给出):

**写代码前先出拓扑,不要直接写 RTL。** 先输出 RTL 级电路拓扑并自审正确性,再翻译成 RTL。拓扑必含 9 项:① module 边界与接口协议 ② 所有状态寄存器 ③ 所有主要组合逻辑块 ④ FSM 状态与转移 ⑤ pipeline stage 与 valid/ready 流向 ⑥ flush/stall/kill/reset 优先级 ⑦ 资源复制或共享 ⑧ 可能的 critical path ⑨ 哪些逻辑允许 function、哪些必须显式 always 块/module。

**按真实硬件结构写,不按软件函数组织代码:**
- 显式区分时序块与组合块;先说明模块的寄存器/组合逻辑/datapath/control FSM。
- `function` 只能用于**小型纯组合 helper**(lzc/barrel-shift/round/saturate/predicate)。
- **禁止**把状态更新、仲裁、valid/ready、flush/kill、issue/select、ROB/LSQ 更新、divider/任何 FSM 封进 function——必须显式写成 always 块/子 module,使寄存器/控制流/共享资源结构可见。
- 每个 for-loop 注明综合后对应什么硬件;每个共享资源显式给出 mux+enable+控制逻辑;注明关键路径大概位置。

**Why:** 用户要的是硬件可见性与可综合质量,不是软件抽象。大 function 把 datapath/控制藏起来,违背其意图;曾把 ~150 行 FMA 塞进 function 被纠正。

**判据细化(2026-06-29 重构 campaign 实证)**:转 function→always@* 时,只转**大型单次使用、隐藏模块主 datapath 的 function**;**小型 helper(立即数/掩码/字段提取/单表达式,6-17 行)与多站点复用的纯组合 function 保留**——复用 helper(如 enc_i 用 17 次、select_op1 用 6 次、clz/popcount/rotate primitive)本就是 function 的正当用途,转成 always@* 反而重复/更乱。已据此把核执行/解码/CSR 全部大型单次 datapath function 转为 always@*(12 文件:FP arith/classify/sgnj/compare/convert/longop、整数 amo/bitmanip/muldiv、RvcDecompressor、CsrFile decode);loop 应用的逐-entry 控制(PMP entry check、issue-queue select)属设计级,非机械转换。批量转换器 `scratchpad/conv_fp_func.py`(嵌套-begin 法:保留 function 原 begin/end 作内嵌块避免孤儿 end)。

**How to apply:** 任何 RTL 改动先走 [[rtl-generation-workflow]] 的拓扑阶段;遵守 [[verilog-not-systemverilog-for-synth]] 的关键字/文件约束(本仓库 iverilog gate 不吃 always_comb)。完整规范固化在 `.github/instructions/rtl-generation-workflow.instructions.md`。参见 [[fp2-fma-fused-fix]] 作为遵循此规范的范例。

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-18
- `tokens`: 643
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`；非平凡任务优先用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile>` 生成 bounded 上下文包。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境 e2e、自检或降低不确定性，读取 `.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，先用 `scripts/agent-e2e.sh --list-profiles` 选 profile，再生成 task-run 证据包。
7. Windows 侧访问本 WSL 工作区时，PowerShell 只作为 `wsl.exe` 启动器，工程命令统一交给 Ubuntu：`wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'`；若 agent/CLI 已在 WSL/Linux 原生 shell 内运行，则直接使用原生命令，不再套 `wsl.exe`。
8. 历史 task-run/evidence 回查使用 `python3 scripts/github_index_db.py runs --profile <profile>` 和 `python3 scripts/github_index_db.py evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志。
9. 交付前必须显式切换“实现者人格”和“审查者人格”：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；冲突未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。

请直接打开 [`.github/AGENTS.md`](./.github/AGENTS.md)。

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

### .github/agents/nvboard.agent.md#chunk-0002

- `kind`: agent
- `lines`: 8-11
- `tokens`: 77
- `heading`: RTL 生成约束
- `summary`: 若任务涉及编写或修改 Verilog/SystemVerilog（含示例模块、测试驱动逻辑），必须遵循 `.github/instructions/rtl-generation-workflow.instructions.md` 的四段式流程：`需求 → 协议规则 + 状态机 + 不变量 + 数据通路约束 → RTL`。

## RTL 生成约束

若任务涉及编写或修改 Verilog/SystemVerilog（含示例模块、测试驱动逻辑），必须遵循 `.github/instructions/rtl-generation-workflow.instructions.md` 的四段式流程：`需求 → 协议规则 + 状态机 + 不变量 + 数据通路约束 → RTL`。

### .github/agents/digital-logic.agent.md#chunk-0002

- `kind`: agent
- `lines`: 8-12
- `tokens`: 87
- `heading`: RTL 生成强制工作流（最高优先级）
- `summary`: 写或改任何 Verilog 前，必须遵循 `.github/instructions/rtl-generation-workflow.instructions.md`： / `需求 → 协议规则 + 状态机 + 不变量 + 数据通路约束 → RTL`，六段（1 / 2a / 2b / 2c / 2d / 3）显式给出，禁止跳过。

## RTL 生成强制工作流（最高优先级）

写或改任何 Verilog 前，必须遵循 `.github/instructions/rtl-generation-workflow.instructions.md`：
`需求 → 协议规则 + 状态机 + 不变量 + 数据通路约束 → RTL`，六段（1 / 2a / 2b / 2c / 2d / 3）显式给出，禁止跳过。
