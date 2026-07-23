# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rtl contract
- `focus_scope`: non-history
- `token_estimate`: 2296 / 2400

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

### .github/memory/modules/npc.md#chunk-0014

- `kind`: memory-module
- `lines`: 58-62
- `tokens`: 1431
- `heading`: 当前状态
- `summary`: - 2026-07-08: **iverilog 14 前向引用家族清零，module TB 门禁在 oss-cad-suite 工具链下恢复**。三层修复：`testbench/Makefile` VVP 与 iverilog 同源 resolve(版本错配拒跑)；`npc-rv64-core-regress.sh` riscv-tests 判据 `.git`→`isa/Makefile`(vendored 树误 SKIP)；10 个 RTL 文件约 110 处"先用后声明"消除(CsrFile 函数引用后...

- 2026-07-08: **iverilog 14 前向引用家族清零，module TB 门禁在 oss-cad-suite 工具链下恢复**。三层修复：`testbench/Makefile` VVP 与 iverilog 同源 resolve(版本错配拒跑)；`npc-rv64-core-regress.sh` riscv-tests 判据 `.git`→`isa/Makefile`(vendored 树误 SKIP)；10 个 RTL 文件约 110 处"先用后声明"消除(CsrFile 函数引用后声明 PMP 寄存器堆、OooDispatchBackend/OooIntBackend/OooCoreTopGlue/OooFpBackend/OooFpLongOpGate/OooFrontend/OooFetchAxiBridge/OooMemAxiBridge/OooFrontendDispatchGate 的 net-decl-assign/实例端口/函数内三类前向引用)，全部只移/拆声明、驱动逻辑与表达式零改动。验证：core-regress overall_rc=0(module TB 84/84+lint+build+AM+riscv-tests 177/177)、CoreMark 0xfcaf(10 迭代)。**规约沉淀：rv64 RTL 新代码声明必须先于使用**(三类触发形态见上)，module TB 已在 iverilog 14 下把关，写 `wire x = expr;` 若 expr 引用后文信号会直接编译失败。边界：MulDiv 迭代化/PmpChecker range-share 重写后的全状态 difftest 重验(difftest-on 构建)未做——按用户 2026-07-08 决策**刻意推迟到综合驱动的架构重构+FSM 化整体完成后一次性做**(时序化重构中间态 difftest 无意义、会锁死局部形态)；重构期护栏=focused TB/checker+lint+check-contract+大节点 tohost 回归。
- 2026-07-08: **Fetch/D-cache 容量参数已从父级 parameter override 收敛为模块默认宏，服务 iEDA netlist 兼容**。为避免 Yosys 四黑盒网表写出 `OooFetchPacketCache #(...)` / `OooDataWordCache #(...)` parameterized blackbox instance，`OooFetchPacketCache` 默认 `INDEX_W` 改为 `OOO_FETCH_PACKET_CACHE_INDEX_W`，新增 `OOO_DATA_WORD_CACHE_INDEX_W` 并作为 `OooDataWordCache` 默认 `INDEX_W`；`OooFetchAxiBridge` 与 `OooMemAxiBridge` 的 cache 实例不再做参数覆盖。默认容量仍为 4096 项，语义不变。验证：`tb_ooo_fetch_packet_cache` PASS，`tb_ooo_data_word_cache` PASS，`make -C npc/rv64 lint` PASS，`check-rtl-style` PASS，`check-contract` PASS。边界：这是 Yosys/iEDA netlist 方言兼容改动，不是 cache macro timing/area closure；真实 SRAM/Liberty/LEF/OOC timing 仍 open。证据 `.github/task-runs/2026-07-08-ieda-netlist-compat/`。
- 2026-07-08: **`OooFpArithGate` macro/OOC decision placeholder v0 已落到 spec + checker**。`design/specs/ooo-fp-arith-gate.md` 新增 Macro/OOC Contract v0，明确生产语义边界仍是当前 5-cycle RTL：pending latency=`5 cycles`、B-FP launch/out latency=`5 cycles`、launch throughput=`1 op/cycle`，flush/reset 清 latency counter 与 meta/data valid chain，kill 抑制 younger-than-kill `out_valid`，value/fflags 与 meta 在 stage5 对齐。`design/specs/yosys-macro-boundary-contracts.md` 的 FP 行同步为 decision placeholder v0；新增 `yosys-sta/scripts/check_fp_arith_macro_contract.py` 审核 FP spec 与四黑盒总表一致。验证：FP macro decision checker PASS、四黑盒 checker PASS、`tb_ooo_fp_arith_gate` PASS、`check-contract` PASS、`py_compile` PASS。边界：生产 RTL 未改；该 placeholder 不提供真实 Liberty/LEF/OOC timing。后续若改 latency/流水级/生产子边界，必须用 `vsrc/common` facts 与 `vsrc/debug` checker 审核 RTL 是否符合 spec 语义。证据 `.github/task-runs/2026-07-08-fp-arith-macro-decision/`。
- 2026-07-08: **`OooBranchDirectionPredictor` semantic audit + macro/OOC placeholder v0 已落到 spec + checker**。`design/specs/ooo-branch-direction-predictor.md` 新增 debug/common 审核、focused TB 覆盖与 Macro/OOC Contract v0；新增 `vsrc/common/OooBranchDirectionPredictorFacts.vh`、`vsrc/debug/OooBranchDirectionPredictorChecker.sv` 和 `tb_ooo_branch_direction_predictor`。Checker 用独立参考模型跟踪 GHR、gshare BHT、local history/PHT，并审核 lookup/update 可见语义。v0 定义 lookup read latency = `0 cycle`、update visibility = `next cycle`、read ports = two combinational views、reset/clear = valid-only table clear plus GHR zero；默认参数下 state lower bound 是 `26892` bits。验证：placeholder checker PASS、四黑盒 checker PASS、focused TB PASS、`py_compile` PASS。边界：这是 non-signoff placeholder，不提供真实 Liberty/LEF/OOC timing；生产 BPU RTL 行为未改。证据 `.github/task-runs/2026-07-08-branch-direction-predictor-macro-placeholder/`。
- 2026-07-08: **`OooFetchPacketCache` semantic audit + macro/OOC placeholder v0 已落到 spec + checker**。新增 `design/specs/ooo-fetch-packet-cache.md`，冻结 lookup context/exact PC hit、fill、store-driven invalidate、clear 和 8B SMC footprint 语义；新增 `vsrc/common/OooFetchPacketCacheFacts.vh` 与 `vsrc/debug/OooFetchPacketCacheChecker.sv`，并接入 `tb_ooo_fetch_packet_cache`。Macro/OOC Contract v0 定义 lookup read latency = `0 cycle`、fill/invalidate/clear visibility = `next cycle`、同拍优先级 = reset/clear > invalidate > non-blocked fill、reset/clear = valid-only clear；默认 `OOO_FETCH_PACKET_CACHE_INDEX_W=12` 下 state lower bound 是 `819200` bits。验证：placeholder checker PASS、四黑盒 checker PASS、`tb_ooo_fetch_packet_cache` PASS、`py_compile` PASS。边界：这是 non-signoff placeholder，不提供真实 Liberty/LEF/OOC timing；生产 cache RTL 行为未改。证据 `.github/task-runs/2026-07-08-fetch-packet-cache-macro-placeholder/`。

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
