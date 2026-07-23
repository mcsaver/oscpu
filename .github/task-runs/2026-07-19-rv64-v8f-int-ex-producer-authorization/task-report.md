# RV64 v8f integer EX ProducerId 架构闭合报告

## 基本信息

- `task_id`: `2026-07-19-rv64-v8f-int-ex-producer-authorization`
- `task_class`: `architecture_closure_with_diagnostic_ppa_probe`
- `slice_status`: `scoped_completed`
- `parent_goal_state`: `active`
- `promotion_eligible`: `false`
- `pre_change_head`: `ef967abae36dc9e8e2e8ad157466f525e543e354`

本报告只签收 integer IQ、lane0 memory reservation 与 EX0/EX1 的 scoped
ProducerId carrier/authorization，以及 v8f.1 shared-WB credit 切点。它不是 full-core
arch-stable 基线，也不签收完整 Domain-A identity、Linux、200 MHz、Power 或 Pareto。

## 根因与合同纠偏

原冻结文本同时声称“ROB exact-open query 不进入 issue/transport ready”和“错误 generation
的 EX packet 当拍释放 WB lane”。静态反例证明两者不能同时成立：旧实现把
`completion_exact_open -> exN_wb_valid -> wb_free_count/source grant -> response/issue ready`
串成组合锥。

`contract-amendment-v8f1.md` 保留原合同字节并仅取代矛盾条目：

1. `exN_pre_auth_valid` 是物理 shared-WB lane occupancy owner；
2. `exN_wb_valid = exN_pre_auth_valid && completion_exact_open` 仍是 ROB/PRF/Busy/IQ wake、
   registered forward 与 public completion 的唯一授权；
3. stale/done/reused 但未被 kill 的 raw packet 保守占用本 lane 一拍；kill/flush/restore
   packet 的 pre-auth 为零，仍当拍释放；
4. v8f.1 不新增状态。v8f 整体 holder carrier 的名义 generation 增量仍为 44 bit。

## 实现者结论

- `OooIntBackend.v` 新增两个纯组合 `exN_wb_slot_occupied_w`，均精确等于
  `exN_pre_auth_valid_w`；shared-WB availability 的 9 个消费点全部改用该 owner。
- actual WB mux/valid、ROB done/data、GPR write、Busy/Int/FP-IQ wake、forward 和 public
  completion 继续由 `exN_wb_valid_w` exact-open 授权；没有把错误 generation 恢复成副作用。
- `tb_ooo_rob.sv` 增加 vacant slot residual-generation 正反例；`tb_ooo_int_backend.sv`
  增加 lane1 early wake generation mismatch、memory reservation 非零 generation
  capture/hold/flush/local-terminal、EX0/EX1 stale occupancy/backpressure，以及 v8d kill-age
  复用，覆盖“保守占槽”和“kill 当拍释放”两个方向。
- `audit-v8f-wb-credit-cut.py` fail closed：精确检查 9 个 occupancy use，并拒绝
  exact-open 或 raw stage valid 回流 availability cone。

## 功能与静态硬门

| gate | 结果 | 证据 |
|---|---:|---|
| focused release | 4/4 PASS | `evidence/focused/summary.txt` |
| focused `OOO_ASSERT` | 4/4 PASS | `evidence/focused/summary.txt` |
| compile-success mutation | 29/29 被定向测试检出 | `evidence/focused/mutation-summary.log` |
| module aggregate | 104/104 PASS | `evidence/module-aggregate-postfix/summary.txt` |
| WB credit structural audit | PASS | `evidence/wb-credit-cut-audit-postfix.log` |
| RTL style / contract | PASS；assertions 308 >= 89 | `evidence/check-rtl-style-postfix.log`、`evidence/check-contract-postfix.log` |
| strict Verilator lint | RED，115 条继承 warning | `evidence/full-lint-postfix.log` |
| lint regression check | normalized signature 与 v8d byte-equal | `evidence/full-lint-postfix.status` |

focused summary 同时明确保留 `ASYNC_MEMORY/MULDIV/CLMUL/FP/BRANCH/GLOBAL_NO_LIVE_REUSE=RED`。
lint RED 未被豁免，只证明本刀未新增 warning signature。

## 诊断性 synthesis / STA

这是架构任务中的 diagnostic probe，不是正式 PPA promotion。run1/run2 冻结相同工具、
liberty/macro、top、5 ns period、参数和独立输出目录；RTL manifest 的唯一差异是
`npc/rv64/vsrc/execute/OooIntBackend.v`。

| metric | run1 pre-fix | run2 post-fix | delta |
|---|---:|---:|---:|
| logic area proxy | 1,633,639.28 | 1,632,831.48 | -807.80 (-0.04945%) |
| sequential area proxy | 455,260.96 | 455,260.96 | 0 |
| WNS @ exact 5 ns partial constraints | -2.986898422 ns | -2.362078667 ns | +0.624819755 ns |
| TNS | -5,606.907714844 ns | -518.397155762 ns | +5,088.510559082 ns |
| violated paths | 40/40 | 40/40 | 0 |

targeted cone v4 还证明结构切点真实：同一 ROB generation DFF 在 run1 可达
`mem_ready/issue1_ready/muldiv_ready/clmul_ready/fp_ready` 五个目标，各 1 hit；run2
全部为 0。到 `rob_wb0_authority` 的路径两侧均为 1，说明 generation 只退出 shared-ready
credit cone，仍保留在 exact completion authorization。OpenSTA 的
`get_fanin -startpoints_only` 对 sequential source 返回 `CK` timing startpoint，故报告同时绑定
semantic `Q` 与 structural `CK`；v1-v3 的错误方法结果保留为反例。

机器裁决位于 `evidence/ppa-current/run1-run2-comparison.json`：

- `claim_tier=diagnostic_rtl_proxy_partial_constraints`
- `area_claim=logic_area_proxy_excluding_unknown_macros`
- `power_claim=unqualified`
- `promotion_eligible=false`
- `target_200mhz_met=false`
- `verdict=DIAGNOSTIC_PROXY_IMPROVED_TARGET_RED`

run1 synthesis wrapper 首次把 module count 猜成 124；审计精确核对后校正为 netlist 实际
121（vsrc input count 为 122）。错误配置与修正过程保留，未篡改已有 netlist。

## AI 开发环境实战固化

- `prepare-rtl-task-contract` 的 `create` 自动声明输出 JSON 自路径；`render` 从实际文件计算并
  显示“JSON 路径 + JSON SHA-256 + 只绑定该 JSON”，旧合同仍兼容。
- 根入口、instruction、skill 与 `AI_ENVIRONMENT.md` 固化 Windows/Codex→WSL single-flight：
  WSL 工程 shell 由主 agent 串行调度，子 agent 只并行无 shell 推理或消费自包含材料；复杂
  Bash 逻辑放入仓库脚本，避免 PowerShell 预展开变量。
- audit、14-case in-memory self-test、14-case subprocess CLI self-test 均 PASS。
- 真实 forward-test 只给子 agent 渲染提示、不授权 shell；它准确回报 JSON 路径、SHA、绑定
  边界、single-flight 和父目标 active。合同为
  `subagent-contracts/v8f-contract-render-forward-test.json`，SHA-256
  `ffb7ffffaf8d78007126526b7c48206f37a41d3732616c3ae39d2a533677072d`。
- agent-system 首次使用 `v8f-contract-binding-hardening` slug 时，10 个业务节点全部 PASS，
  但 bounded recall 无 independent primary，run 正确 blocked 并保留；改用可召回主词
  `rtl-task-contract-agent-system` 后 10/10 completed。
- 最终 reviewer 修复 e2e negative-fixture cleanup 漏项后又生成新鲜 profile evidence：
  `.github/task-runs/2026-07-19-rtl-task-contract-single-flight-3/` 的 agent-system 10/10 completed，
  `.github/task-runs/2026-07-19-rv64-producer-completion-authorization/` 的 npc-dev 5/5
  completed；`scripts/agent-e2e.sh --guard --guard-mode strict` 自动推导这两个 profile 并全部 PASS。
- cleanup 反例的根因是 `guard_context_history_primary` 已创建但未列入 prefix-checked cleanup
  allowlist；补项后 fresh run 没有新增 guard temp 目录。本轮生成的 3 个明确临时目录已删除，
  既有历史 ignored fixture 未批量处理。

## 审查者结论

已由证据关闭：vacant slot 不能仅凭残留 generation 获得 current/open 权限；lane1 early wake
不再跨 generation 粘住 ready；stale EX 不产生副作用且不把 exact-open query 回灌 ready；
selective kill 仍当拍释放 lane；29 个 compile-success mutation 均到达仿真并被检出。

仍为 RED/UNKNOWN/unqualified：

- async memory、MulDiv、CLMUL、FP 与 branch resolve 的完整 ProducerId holder/authorization；
- generation wrap/global live collision fence、完整 owner/holder census 与 full-core P0/P1 清零；
- strict lint 115 条历史 warning、DiffTest/Linux/Ubuntu、系统级恢复与异常序 gate；
- arch-stable source/test/tool/lib/constraint freeze、完整物理约束、宏面积、活动率与可信 Power；
- 200 MHz、Pareto 与任何 full-core PPA promotion。

## 最终裁决

本 scoped 架构切片完成，父目标继续 `active`。由于 full-core architecture gate 未闭合，当前
只能保留 diagnostic proxy 改善与结构切点证据；不得把本报告升级为正式 PPA、200 MHz、Power
或系统级 GREEN。下一主序应回到剩余 holder/authorization 与 global no-live-reuse 架构债务，
待相应范围 P0/P1 为零并冻结 arch-stable 基线后再进入正式单机制 PPA A/B。
