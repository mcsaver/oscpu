# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: semantic replay attempt
- `focus_scope`: non-history
- `token_estimate`: 2392 / 2400

## Profile Suggestions
- `npc-dev` score=8 matched=requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `software-flow` score=1 matched=semantic command=`scripts/agent-e2e.sh --profile software-flow`
- `yosys-sta` score=1 matched=semantic command=`scripts/agent-e2e.sh --profile yosys-sta`

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

### .github/memory/modules/agent-system.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-32
- `tokens`: 581
- `heading`: 2026-07-30 selected-source semantic replay 与原 FAIL 保留
- `summary`: - production RTL 局部变化后，不得把所有历史 summary 的 full design-id / 批量替换为当前值。语义台账分开记录 / `CURRENT_FULL_RTL_BOUND`、`CURRENT_SELECTED_SOURCE_AND_TB_BOUND` 与 / historical/stale；只有 policy 声明的 exact RTL/include/filelist/TB / 集合逐文件匹配，旧局部 evidence 才能继续闭合对应单元。 / - selected-so...

## 2026-07-30 selected-source semantic replay 与原 FAIL 保留

- production RTL 局部变化后，不得把所有历史 summary 的 full design-id
  批量替换为当前值。语义台账分开记录
  `CURRENT_FULL_RTL_BOUND`、`CURRENT_SELECTED_SOURCE_AND_TB_BOUND` 与
  historical/stale；只有 policy 声明的 exact RTL/include/filelist/TB
  集合逐文件匹配，旧局部 evidence 才能继续闭合对应单元。
- selected-source 集合必须由 binding kind 的 canonical exact set
  fail-closed 校验；缺 TB、重标 role、换成无关 RTL 或 manifest/hash 漂移
  都必须拒绝。ledger detail 同时保留 evidence design-id、current
  design-id 和逐文件 live/evidence SHA，不伪装为 full-design replay。
- runner 在完成 DUT 仿真后若只停在 checker 阶段，原 status 继续是 FAIL。
  新 checker 只能通过独立 frozen-input receipt 重放：绑定原 FAIL stage、
  simulation summary、focused/full pre/post、旧 checker log 和新 checker
  sources，并明确 `rtl_simulation_reexecuted=false`。
- V11H 初轮保留 focused attempt-3 的 stale-design checker FAIL；raw-Q
  assertion/schema 扩展后的 attempt-4 又保留 checker-local NameError
  `FAIL@semantic-ledger-unit`。独立 replay 冻结 4+1+62 RTL 输入，以
  5 个 receipt unit、10 个 evidence-tool unit 和 24 个
  semantic-ledger unit 取得 PASS，且 current closure 必须绑定该 receipt，
  不能复用 attempt-3 historical replay。该模式与
  A3 checker-only replay 一致，但不规避 production RTL 变化后的完整系统
  promotion 门。
- 局部 closure 与 system promotion 不得压成一个含糊字符串；exact schema
  应分别记录 local-required、system-promotion-required 与 run 状态，并用
  删除/布尔反转负测封闭假绿。
- 结果 marker 过滤器必须按 failure marker 精确匹配，不能把同前缀的
  testbench coverage `... PASS` 误判为 assertion failure。误判 attempt
  原样保留，新版本 runner 使用独立 attempt 路径重放。

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-18
- `tokens`: 972
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`；AI 环境入口见 `AI_ENVIRONMENT.md`；非平凡任务优先用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile> --focus-scope non-history` 生成 bounded 上下文包。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境整理、e2e、自检或降低不确定性，先读取 `AI_ENVIRONMENT.md`、`.github/instructions/agent-env-layer-contract.instructions.md`、`.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，再用 `scripts/agent-e2e.sh --list-profiles` 选 profile 并生成 task-run 证据包。
7. Windows 侧访问本 WSL 工作区时，PowerShell 只作为 `wsl.exe` 启动器，工程命令统一交给 Ubuntu：`wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'`；若 agent/CLI 已在 WSL/Linux 原生 shell 内运行，则直接使用原生命令，不再套 `wsl.exe`。Windows/Codex→WSL 工程命令默认 single-flight：主 agent 可以把当前唯一 shell ownership 交给一个契约授权的子 agent，但该节点执行期间其它 agent 不得并发运行工程命令；无 shell 推理或自包含材料复核仍可并行。复杂控制流、管道和 Bash 变量放入仓库脚本，避免被 PowerShell 预先解释。
8. 历史 task-run/evidence 回查使用 `python3 scripts/github_index_db.py runs --profile <profile>` 和 `python3 scripts/github_index_db.py evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志。
9. 交付前必须显式执行“实现者 / 审查者”双角色复核：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；分歧未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。
11. 派发本地 RV64 RTL 子 agent 前读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 明确 RTL/spec/TB/evidence 输入、输出路径、结构化 `command/mode/purpose`、最小上下文、产物和成功条件；只读任务只消费合同列出的本地工程材料并使用不落盘命令，其它资料另建研究节点。
12. 本地 RV64 RTL 子 agent 使用 `fork_turns="none"`，初始提示只采用已校验的合同 `render` 输出；所需设计事实写入合同路径或随附材料，不继承父任务完整对话历史。该上下文隔离不降低模型、源码探索、实现、验证或 PPA 能力。

### .github/copilot-instructions.md#chunk-0001

- `kind`: instruction
- `lines`: 1-2
- `tokens`: 11
- `heading`: YSYX 工作区 — 全局指导规范
- `summary`: YSYX 工作区 — 全局指导规范

# YSYX 工作区 — 全局指导规范

### .github/memory/project-status.md#chunk-0001

- `kind`: memory
- `lines`: 1-2
- `tokens`: 8
- `heading`: YSYX 项目状态总览
- `summary`: YSYX 项目状态总览

# YSYX 项目状态总览

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

### .github/memory/modules/npc.md#chunk-0004

- `kind`: memory-module
- `lines`: 23-44
- `tokens`: 303
- `heading`: TB / EDA evidence
- `summary`: - design-id 为 / `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`， / LQ SHA 为 / `4287aa7c746391d522bebcfceb481c01127d35f248da3cc025b5efdef15cf427`。 / - stimulus-owned 四槽 model 逐沿扫描 raw / `valid/launched/completed/killed/terminal_seen...

### TB / EDA evidence

- design-id 为
  `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`，
  LQ SHA 为
  `4287aa7c746391d522bebcfceb481c01127d35f248da3cc025b5efdef15cf427`。
- stimulus-owned 四槽 model 逐沿扫描 raw
  `valid/launched/completed/killed/terminal_seen/producer_id` 与 final-PA
  metadata；DUT 输出只作 observation。GEN_W=1/4、assert/release 四个
  profile PASS；1 个 GEN_W=4 assertion probe 命中
  `[V11H-LQ-PID-KNOWN]`；31×2 assertion-off mutation 仿真全部由
  `[V11H-LQ-PRODUCER-ORACLE][FAIL]` 拒绝。
- 当前实例图为 15 holder modules / 17 instances / 194 reachable；
  fresh Yosys result、receipt、full JSON、script、log 均与 canonical
  逐字节一致。
- focused attempt-4 原始状态保持 `FAIL@semantic-ledger-unit`。独立
  checker replay 绑定冻结的 4+1+62 仿真、source/RTL pre/post 与原失败
  日志，记录 `rtl_simulation_reexecuted=false`，并通过 5/5、10/10、
  24/24 checker tests。
- ordinary LoadQueue 与 parent IntBackend 在 assertions-on、GEN_W=4 下
  PASS；PID-known 与 duplicate-terminal marker 均为 0。
