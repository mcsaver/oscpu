# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: rv64 branch resolve producer authorization
- `focus_scope`: non-history
- `token_estimate`: 1959 / 2400

## Profile Suggestions
- `npc-dev` score=9 matched=requested-profile, rv64 command=`scripts/agent-e2e.sh --profile npc-dev`
- `rv64-linux` score=6 matched=rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `nemu` score=3 matched=branch, resolve, rv64 command=`scripts/agent-e2e.sh --profile nemu`
- `yosys-sta` score=3 matched=branch, resolve, rv64 command=`scripts/agent-e2e.sh --profile yosys-sta`
- `agent-system` score=2 matched=branch, resolve command=`scripts/agent-e2e.sh --profile agent-system`

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
- `tokens`: 1393
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-19(RV64-v8j-branch-resolve-producer-authorization): **branch-resolve full ProducerId carrier、cycle-free exact-open query 与 actual control capability scoped GREEN；全核 identity/PPA RED**。`OooIntBackend` 的 resolve q 保存 full PID...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-19(RV64-v8j-branch-resolve-producer-authorization): **branch-resolve full ProducerId carrier、cycle-free exact-open query 与 actual control capability scoped GREEN；全核 identity/PPA RED**。`OooIntBackend` 的 resolve q 保存 full PID，raw ROB boundary 仅由低位投影；`OooDispatchBackend` 纯代理专用 query，`OooRob` 只用 edge-old valid/done/full-PID/recover 状态判 open，不读 current self-kill。redirect、ROB walk、BPU update 与所有 selective kill 只由 candidate + query-open + raw registered EX0 full-PID coherence 授权，completion-open/WB-valid/killed-now 等 semantic valid 被结构性排除。既有 `producer_target_killed_now` helper 的 ambient head/kill/recovery 依赖已改为 `automatic` + 六项显式参数，关闭同 PID 只切 kill 时 Icarus 残留旧组合值的测试根因。focused release/assert 3/3、16项 audit、12/12 mutation、v8d-v8i legacy 10/10、module 105/105、style/contract 366/89 PASS；lint 115 与 v8i byte-equal，architecture inventory 仍 RED。reviewer 无 blocker但未独立提供 elaborated SCC/formal loop、原始波形/mutation 复跑或未来多 kill-source 仲裁证据；pending-system/CSR、完整 census/global reuse、official/Linux/fresh synthesis/STA/power/Pareto 未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8j-branch-resolve-producer-authorization/`。
- 2026-07-19(RV64-v8i-fp-producer-lease): **FP 六类 holder 的 full ProducerId lease、FIFO pending completion capability 与 exact launch credit scoped GREEN；全核 identity/PPA RED**。`OooFpIssueQueue`、issue packet、`OooFpArithGate` 五级 meta、exec1、long meta 与 done FIFO 不再并存 raw identity state；raw ROB idx 仅由 PID 低位投影。result exact-open/claim 是 FP PRF/Busy/wakeup/FIFO-push 的唯一 actual fact，occupied FIFO token 在 formal pop 前以 pending mask 阻断全部非 formal 同 PID source；formal raw route/ready 仍能排 stale token。post-launch Q occupancy `<8` 门控 execution launch，第九 packet 在八 credit 饱和和长背压下保持。reviewer 两个 blocker 已关闭；实现 reviewer 的同槽 replacement 与 stale P/live Q 同 raw-index 盲区已补断言/directed，fixed-priority finite-progress formal proof 保持 residual。focused release/assert 5/5、16项 source audit、10/10 mutation、v8f/v8g/v8h legacy 6/6、module 105/105、style/contract 361/89 PASS；lint 115 与 v8h byte-equal，architecture inventory 仍 RED。branch/pending-system/CSR、完整 census/global no-live-reuse、official/Linux/fresh synthesis/STA/power/Pareto 未运行或未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8i-fp-producer-lease/`。
- 2026-07-19(RV64-v8h-integer-longop-producer-lease): **MulDiv/CLMUL full ProducerId lease 与同沿完成资格 scoped GREEN；global identity/PPA RED**。`OooMulDivUnit/OooClmulUnit` 各以唯一 full PID Q 状态持有身份并从低位投影 ROB idx；edge-old lease 经 onehot union 门控 dispatch，ROB query3/4 exact-open。`OooIntBackend` 以 `EX0 > EX1 > memory > MulDiv > CLMUL` 的 full-PID actual claim 只授权 WB/PRF/Busy/IQ/ROB/public side effect，raw route/ready/mask/FSM 保持 transport；pair candidate 的 tail/tail+1 PID 不同由 assertion/TB/mutation 固化。release/assert 5/5、23/23 compile-success mutation、module 105/105、style/contract 335/89 PASS；strict lint 继承 115 warnings且规范化输出与 v8g byte-equal，architecture inventory 仍 RED。独立 no-tool reviewer 无 blocker但未复核完整 actual cone，持续背压、整圈 generation wrap、全部 death-edge 并发和 source retry/hold 无形式证明；FP/branch/CSR/pending/global census/no-live-reuse、official/Linux/fresh PPA 均未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8h-integer-longop-producer-lease/`。
- 2026-07-19(RV64-v8d-int-ex-completion-cancel): **当前动态可达的整数 EX1 selective-recovery completion 泄漏已 scoped GREEN；global identity/PPA RED**。`OooIntBackend` 以 `age=rob_idx-rob_head`、strict `>` 形成 EX0/EX1 cancel-now 和 effective WB valid；raw stage valid 不再直接授权 forward、WB credit/arbiter、PRF、BusyTable、INT/FP IQ、ROB 或 public completion，两个 PipeStageReg 同源清状态。真实无-force branch ROB0 + younger EX1 ROB1 固定副作用静默与沿后 PRF/Busy/ROB 不变；全 4-bit head/boundary/completion 矩阵两 lane 8192/8192，11/11 compile-success mutation，current 104/104 module、style、contract 295/89 PASS。full lint 115-warning RED 与既有归一化签名一致。当前 lane0 resolve coherence 令 EX0==boundary，故 younger EX0 只有 forced supplemental，不写成动态覆盖；未证明架构错误提交。v8c FP 同步补到 170/170、14/14 mutation 与 FIFO head/ready/三源碰撞；P0 holder census 9/9 并锁 mixed AUTH 不可降格。ProducerId/generation/no-live-reuse、全 carrier exact completion、Q1/CSR、双 memory、official/AM/Linux、fresh PPA/STA/power 未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/` 及两个 v8c task-run。

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
