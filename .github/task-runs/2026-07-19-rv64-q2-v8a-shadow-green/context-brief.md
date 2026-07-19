# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: rv64 q2 v8a shadow
- `focus_scope`: non-history
- `token_estimate`: 1936 / 2400

## Profile Suggestions
- `npc-dev` score=9 matched=requested-profile, rv64 command=`scripts/agent-e2e.sh --profile npc-dev`
- `rv64-linux` score=6 matched=rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `nemu` score=3 matched=q2, rv64, shadow command=`scripts/agent-e2e.sh --profile nemu`
- `display-vga` score=2 matched=rv64 command=`scripts/agent-e2e.sh --profile display-vga`
- `linux-device` score=2 matched=rv64 command=`scripts/agent-e2e.sh --profile linux-device`

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

### .github/memory/modules/npc.md#chunk-0132

- `kind`: memory-module
- `lines`: 834-860
- `tokens`: 727
- `heading`: 2026-07-19 S2-Q2 v8a neutral shadow RTL
- `summary`: - `OooRob` 新增 2 个标量 permit 输入与 3 个 observation 输出；old head0 ready 被抽为 / `head0_base_ready_w`，`commit0_fire_w` 只在末端 AND 两 permit。`commit1_fire_w` 保持旧 / exact RHS并依赖 commit0；`OOO_ASSERT` 立即断言禁止 lane1 越过 head0。candidate 方程只看 / `!recovering && count!=0 && valid...

## 2026-07-19 S2-Q2 v8a neutral shadow RTL

- `OooRob` 新增 2 个标量 permit 输入与 3 个 observation 输出；old head0 ready 被抽为
  `head0_base_ready_w`，`commit0_fire_w` 只在末端 AND 两 permit。`commit1_fire_w` 保持旧
  exact RHS并依赖 commit0；`OOO_ASSERT` 立即断言禁止 lane1 越过 head0。candidate 方程只看
  `!recovering && count!=0 && valid[head] && done`；identity-valid 只看 live head，identity 是
  `head_q` 零扩展至 8 bit，invalid 时 payload 为 don't-care，且不具备 generation/reuse 安全。
- CSR/SFENCE.VMA/xRET/FENCE.I 的 lane1 raw classifier 和 potential/shadow 只作组合观察，禁止
  进入 commit1。端口经 `OooDispatchBackend -> OooIntBackend -> OooAluDecodeBackend ->
  OooAluCoreSlice -> OooExecuteBackend -> OooCoreTopGlue -> NpcCoreTop` 传输；只有 top tie-high，
  全 `npc/rv64` census 为 7 个 RTL + 8 个直接 TB，无 positional/漏接/空 permit。
- `tb_ooo_rob` 在两个 ready entry 下分别拉低两个 permit，要求 commit0/1 均不 fire、count=2，
  双高恢复后双退休；四类 lane1 boundary 均 one-hot/live 且保留旧 commit0/1。public wrapper
  observation 实际 toggle/no-X；candidate-live 强制违约只命中目标 assertion。
- `make -C npc/rv64 check-q2-v8a-shadow` 是 canonical gate：冻结 checker 17/17、补充 checker
  canonical+4 mutation、release/assert 8 个 focused TB、CSR queue-head 显式 0/1、负例、
  pre-bundle 双配置 1036-line legacy trace、module 104/104、style、contract289、strict lint、
  forced default build 与 nonfatal parse 都由同一次 runner 执行并 hash-bound。
- strict lint/default build 的 115-warning RED 与 pre-edit 归一化签名逐行相同，未被修复或豁免；
  所以只能签收 tie-high scoped shadow/interface，不得推出 full identity、active Q1/permit、epoch、
  FENCE.I transaction、形式等价、Linux、200 MHz 或 PPA。下一 RTL 原子必须先冻结 v8b 的
  full-owner identity/payload/abort/quiet/squash/FENCE generation 和 active combinational SCC。
- runner 反例：新增 supplement 一度因 `fi` 位置错误被包进 structural-RED 分支；正常 PASS
  会跳过，旧日志仍可能被 evidence inventory 收入。修复后开工先删除 marker/旧日志，
  supplement 无条件执行并 exact 锁 census=15；broad gates 当次重跑，pre-lint log/normalized
  有固定 SHA。今后任何 runner 分支修改都要同时做 `bash -n`、正常路径产物新鲜度和
  “删旧日志后仍能重建”验证。

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
