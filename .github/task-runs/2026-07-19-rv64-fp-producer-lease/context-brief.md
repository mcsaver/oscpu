# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: rv64 fp producer lease
- `focus_scope`: non-history
- `token_estimate`: 2392 / 2400

## Profile Suggestions
- `npc-dev` score=9 matched=requested-profile, rv64 command=`scripts/agent-e2e.sh --profile npc-dev`
- `rv64-linux` score=7 matched=lease, rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `nemu` score=3 matched=fp, lease, rv64 command=`scripts/agent-e2e.sh --profile nemu`
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

### .github/memory/modules/npc.md#chunk-0002

- `kind`: memory-module
- `lines`: 3-8
- `tokens`: 1183
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-19(RV64-v8i-fp-producer-lease): **FP 六类 holder 的 full ProducerId lease、FIFO pending completion capability 与 exact launch credit scoped GREEN；全核 identity/PPA RED**。`OooFpIssueQueue`、issue packet、`OooFpArithGate` 五级 meta、exec...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-19(RV64-v8i-fp-producer-lease): **FP 六类 holder 的 full ProducerId lease、FIFO pending completion capability 与 exact launch credit scoped GREEN；全核 identity/PPA RED**。`OooFpIssueQueue`、issue packet、`OooFpArithGate` 五级 meta、exec1、long meta 与 done FIFO 不再并存 raw identity state；raw ROB idx 仅由 PID 低位投影。result exact-open/claim 是 FP PRF/Busy/wakeup/FIFO-push 的唯一 actual fact，occupied FIFO token 在 formal pop 前以 pending mask 阻断全部非 formal 同 PID source；formal raw route/ready 仍能排 stale token。post-launch Q occupancy `<8` 门控 execution launch，第九 packet 在八 credit 饱和和长背压下保持。reviewer 两个 blocker 已关闭；实现 reviewer 的同槽 replacement 与 stale P/live Q 同 raw-index 盲区已补断言/directed，fixed-priority finite-progress formal proof 保持 residual。focused release/assert 5/5、16项 source audit、10/10 mutation、v8f/v8g/v8h legacy 6/6、module 105/105、style/contract 361/89 PASS；lint 115 与 v8h byte-equal，architecture inventory 仍 RED。branch/pending-system/CSR、完整 census/global no-live-reuse、official/Linux/fresh synthesis/STA/power/Pareto 未运行或未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8i-fp-producer-lease/`。
- 2026-07-19(RV64-v8h-integer-longop-producer-lease): **MulDiv/CLMUL full ProducerId lease 与同沿完成资格 scoped GREEN；global identity/PPA RED**。`OooMulDivUnit/OooClmulUnit` 各以唯一 full PID Q 状态持有身份并从低位投影 ROB idx；edge-old lease 经 onehot union 门控 dispatch，ROB query3/4 exact-open。`OooIntBackend` 以 `EX0 > EX1 > memory > MulDiv > CLMUL` 的 full-PID actual claim 只授权 WB/PRF/Busy/IQ/ROB/public side effect，raw route/ready/mask/FSM 保持 transport；pair candidate 的 tail/tail+1 PID 不同由 assertion/TB/mutation 固化。release/assert 5/5、23/23 compile-success mutation、module 105/105、style/contract 335/89 PASS；strict lint 继承 115 warnings且规范化输出与 v8g byte-equal，architecture inventory 仍 RED。独立 no-tool reviewer 无 blocker但未复核完整 actual cone，持续背压、整圈 generation wrap、全部 death-edge 并发和 source retry/hold 无形式证明；FP/branch/CSR/pending/global census/no-live-reuse、official/Linux/fresh PPA 均未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8h-integer-longop-producer-lease/`。
- 2026-07-19(RV64-v8d-int-ex-completion-cancel): **当前动态可达的整数 EX1 selective-recovery completion 泄漏已 scoped GREEN；global identity/PPA RED**。`OooIntBackend` 以 `age=rob_idx-rob_head`、strict `>` 形成 EX0/EX1 cancel-now 和 effective WB valid；raw stage valid 不再直接授权 forward、WB credit/arbiter、PRF、BusyTable、INT/FP IQ、ROB 或 public completion，两个 PipeStageReg 同源清状态。真实无-force branch ROB0 + younger EX1 ROB1 固定副作用静默与沿后 PRF/Busy/ROB 不变；全 4-bit head/boundary/completion 矩阵两 lane 8192/8192，11/11 compile-success mutation，current 104/104 module、style、contract 295/89 PASS。full lint 115-warning RED 与既有归一化签名一致。当前 lane0 resolve coherence 令 EX0==boundary，故 younger EX0 只有 forced supplemental，不写成动态覆盖；未证明架构错误提交。v8c FP 同步补到 170/170、14/14 mutation 与 FIFO head/ready/三源碰撞；P0 holder census 9/9 并锁 mixed AUTH 不可降格。ProducerId/generation/no-live-reuse、全 carrier exact completion、Q1/CSR、双 memory、official/AM/Linux、fresh PPA/STA/power 未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/` 及两个 v8c task-run。
- 2026-07-19(RV64-v8b-prep-producer-kill-now-e2e): project/npc memory 先进入 retained DB/index 并通过 snapshot/audit 后，`brief rv64 producer kill now --profile npc-dev --focus-scope non-history` 从当前 `modules/npc.md` 命中 independent primary (`2041/2400`)；task-specific `npc-dev/rv64-producer-kill-now` 5/5 nodes completed/publication-valid，strict guard 首次诊断的 `agent-system+npc-dev+github-index` 三 profile 全 PASS。该 run 只验证 AI 调度与 NPC 入口合同，不代替本轮 104-module、RTL strict/default、Linux 或 PPA gate。

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
