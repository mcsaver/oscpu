# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: rv64 producer identity generation
- `focus_scope`: non-history
- `token_estimate`: 2001 / 2400

## Profile Suggestions
- `npc-dev` score=9 matched=requested-profile, rv64 command=`scripts/agent-e2e.sh --profile npc-dev`
- `rv64-linux` score=6 matched=rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `nemu` score=3 matched=generation, identity, rv64 command=`scripts/agent-e2e.sh --profile nemu`
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
- `lines`: 3-9
- `tokens`: 1435
- `heading`: 当前状态
- `summary`: <!-- 已实现的模块、信号位宽等 --> / - 2026-07-19(RV64-v8d-int-ex-completion-cancel): **当前动态可达的整数 EX1 selective-recovery completion 泄漏已 scoped GREEN；global identity/PPA RED**。`OooIntBackend` 以 `age=rob_idx-rob_head`、strict `>` 形成 EX0/EX1 cancel-now 和 effective WB valid；...

## 当前状态
<!-- 已实现的模块、信号位宽等 -->
- 2026-07-19(RV64-v8d-int-ex-completion-cancel): **当前动态可达的整数 EX1 selective-recovery completion 泄漏已 scoped GREEN；global identity/PPA RED**。`OooIntBackend` 以 `age=rob_idx-rob_head`、strict `>` 形成 EX0/EX1 cancel-now 和 effective WB valid；raw stage valid 不再直接授权 forward、WB credit/arbiter、PRF、BusyTable、INT/FP IQ、ROB 或 public completion，两个 PipeStageReg 同源清状态。真实无-force branch ROB0 + younger EX1 ROB1 固定副作用静默与沿后 PRF/Busy/ROB 不变；全 4-bit head/boundary/completion 矩阵两 lane 8192/8192，11/11 compile-success mutation，current 104/104 module、style、contract 295/89 PASS。full lint 115-warning RED 与既有归一化签名一致。当前 lane0 resolve coherence 令 EX0==boundary，故 younger EX0 只有 forced supplemental，不写成动态覆盖；未证明架构错误提交。v8c FP 同步补到 170/170、14/14 mutation 与 FIFO head/ready/三源碰撞；P0 holder census 9/9 并锁 mixed AUTH 不可降格。ProducerId/generation/no-live-reuse、全 carrier exact completion、Q1/CSR、双 memory、official/AM/Linux、fresh PPA/STA/power 未关闭。证据 `.github/task-runs/2026-07-19-rv64-v8d-int-ex-completion-kill-cut/` 及两个 v8c task-run。
- 2026-07-19(RV64-v8b-prep-producer-kill-now-e2e): project/npc memory 先进入 retained DB/index 并通过 snapshot/audit 后，`brief rv64 producer kill now --profile npc-dev --focus-scope non-history` 从当前 `modules/npc.md` 命中 independent primary (`2041/2400`)；task-specific `npc-dev/rv64-producer-kill-now` 5/5 nodes completed/publication-valid，strict guard 首次诊断的 `agent-system+npc-dev+github-index` 三 profile 全 PASS。该 run 只验证 AI 调度与 NPC 入口合同，不代替本轮 104-module、RTL strict/default、Linux 或 PPA gate。
- 2026-07-19(RV64-v8b-prep-producer-kill-now): **CLMUL/FP-arith 两个 production producer-local ambient kill dependency 已 GREEN；global identity/live Q1 RED**。旧 helper 隐式读取 kill-valid/cut/head，Icarus 12.0 在 only-input-change 时保留旧值；修复前 CLMUL/FP TB compile/elaborate 成功但分别 10/3 failures。`OooClmulUnit` 改为显式等宽 circular age，matching request 不入 RUN，RUN/RESP 同拍 mask 并清 state/held ROB/pdest/data；`OooFpArithGate` 的 pure helper 只读 idx/boundary/head，launch、每级 meta 与 stage5 output 显式 gate。release/assert 4/4、age 4096/4096、compile-success mutation 13/13、checker 3/3、leaf style/Yosys、module 104/104、full style/contract 289/89 PASS；strict/default 继承 115 warnings RED且与 pre-v8a 签名 byte-match，nonfatal parse PASS。reviewer scoped P0=0：CLMUL `req_ready` 仅 IDLE，acc/iter 残值不可观察且新 request 全覆盖；FP sink ingress 要求 kill 沿前稳定，不能外推到已入 done FIFO、其他 holder、idx reuse 或 full stale-WB。下一步先做全 holder last-reference/no-live-reuse/collision-stall census，再做 full identity 与 active mismatch `kill_now`→registered Q1/Csr shared abort；Linux/综合/STA/PPA 未测。证据 `.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/`。
- 2026-07-19(RV64-PPA-S2-Q1A-e2e)：Q1A 的 task-specific `npc-dev` 首轮在新 memory 未进入 retained DB/index 时，即使 5/5 node PASS 也被 startup recall 正确 blocked；`update-stored` project/npc memory、snapshot、DB-first audit 与 bounded brief 闭合后，第二轮 completed/publication-valid。agent-system 也证明 slug 必须由当前 non-history 事实支持，不能用只存在于历史 task-run 的 evidence/workflow 词自证。blocked runs 保留；此项不提升 live Q1/PPA 状态。
- 2026-07-19(RV64-PPA-S2-Q1A): **`OooMmuEpochOwner` abort-priority/rearm source-catalog GREEN；production 无实例，live Q1/v8b RED**。新增 registered `abort_valid_i` consumer 与 `abort_rearm_q`：abort 展示拍立即 block 并屏蔽 request/grant，沿上清 state/held bundle 且不写 epoch；只有 abort 当拍存在旧 request envelope 才进入 rearm，continuous-valid 期间 ready=0，valid-low edge 后开放，idle abort 不加 bubble。COMMIT quiet 被定义为 transaction-scoped sticky/irrevocable completion，capture block 不得组合门控 request producer。正例 release/assert、5/5 命名 assertion-negative、13/13 exact compile-success mutation、leaf lint/style/Yosys/static checker、fresh module 104/104、全 style、contract 289/89 均 PASS；strict/default 的 115 warnings（108 TIMESCALEMOD/2 PINCONNECTEMPTY/4 LATCH/1 UNOPTFLAT）与 pre-v8a 三路归一化 byte-match，故仍 RED，nonfatal parse/elab PASS。checker 还锁定 `mmu_epoch_q` 仅 reset/grant-fire 两个时序写点和 vsrc 无 leaf 引用。8-bit identity 已由 nested recovery `F(k)=2^k-1` 反例否决直接落地；下一步必须先定义全 holder last-reference/no-live-reuse/collision-stall，再实现 mismatch-cycle kill-now、下一拍 shared abort 与 CsrFile 同事件清除。独立 reviewer 复核连续/多拍 abort、quiet drop、epoch 与组合环后未发现 scoped blocker。证据 `.github/task-runs/2026-07-19-rv64-q1a-abort-priority/`；无 Linux/综合/STA/PPA 声明。

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
