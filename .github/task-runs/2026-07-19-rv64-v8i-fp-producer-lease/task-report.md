# RV64 v8i FP ProducerId lease 闭合报告

## 基本信息

- `task_id`: `2026-07-19-rv64-v8i-fp-producer-lease`
- `task_class`: `architecture_closure_without_ppa_promotion`
- `slice_status`: `scoped_completed`
- `parent_goal_state`: `active`
- `promotion_eligible`: `false`

本报告只签收当前 FP issue/execute/result/formal 链上的 full ProducerId 持有、Q-only lease、
result-pending completion owner、exact-open 双查询授权、不可背压算术 launch credit 和
raw-transport/actual-side-effect 分离。固定优先级混合源的形式活性、branch、CSR/
pending-system、完整 holder census、finite-generation global no-live-reuse、全核架构 hard gate、
系统级验证和 PPA 都不在本地 GREEN 内。

## 实现者结论

- `OooFpIssueQueue`、`OooFpArithGate` 与 `OooFpBackend` 的 issue、算术五级 metadata、exec1、
  long、done FIFO 均持有 full ProducerId；ROB index/kill age 只由低位投影。六类 Q-only owner
  合并为 FP live mask，并进入 dispatch birth fence。
- FP result 接受与 formal completion 被拆成两类 exact-open query。结果被接受时原子建立
  `completion_pending_mask`，所有 EX/FP 实际副作用都查询该 owner；只有绑定该 FIFO token 的
  formal 路径能关闭 P，避免结果接受后到 formal 前的跨周期重复完成。
- 不可背压算术输出在 launch 前按在途 metadata、exec1、long 与 FIFO 占用精确预留 8 槽
  credit。credit 不足时 issue packet 保持，已 launch 的结果始终有无损承接位置。
- formal raw route、FIFO pop 与 stale transport 可继续排空；ROB、PRF/FPR、Busy、wakeup、
  public completion 等 actual side effect 只由 full-PID exact-open claim 授权。FP formal 与结果
  查询分别进入整数后端全序。
- full FIFO 同槽 pop+push+kill 的新 token 生存语义由 assertion 和三种定向场景锁定；旧
  generation formal 占 raw route、同 raw index 的新 generation 从 EX0/FP result actual 完成也有
  定向覆盖。

## 功能与静态硬门

| gate | 结果 | 证据 |
|---|---:|---|
| focused release | 5/5 PASS | `evidence/focused-run/summary.md` |
| focused `OOO_ASSERT` | 5/5 PASS | `evidence/focused-run/summary.md` |
| compile-success semantic mutation | 10/10 命中 | `evidence/focused-run/mutation-summary.tsv` |
| focused source pre/post hash | byte-equal | `evidence/focused-run/sources.pre.sha256`、`sources.post.sha256` |
| reviewer counterexamples | pending owner、9-op credit、FIFO replacement、generation-separated transport PASS | `evidence/focused-run/summary.md` |
| legacy focused regression | v8f/v8g/v8h release+assert，6/6 PASS | `evidence/regression/summary.md` |
| module aggregate | 105/105 PASS | `evidence/regression/module-aggregate/summary.txt` |
| regression source pre/post hash | byte-equal | `evidence/regression/sources.pre.sha256`、`sources.post.sha256` |
| structural audit | 16/16 PASS | `evidence/static/structural-audit.log` |
| RTL style / contract | PASS；assertions 361 >= 89 | `evidence/static/check-rtl-style.log`、`check-contract.log` |
| architecture checker self-test | 15/15 PASS | `evidence/static/architecture-hard-gates.log` |
| real architecture inventory | `OVERALL: RED`，预期 rc=2 | `evidence/static/architecture-hard-gates.json` |
| strict lint regression | inherited rc=2、115 warnings；normalized SHA 与 v8h byte-equal | `evidence/static/full-lint.status` |

10 个 mutation 覆盖 full PID 截断、FP live union 漏项、query generation/done 绕过、
pending-owner 绕过、formal raw-route 误授权、结果 side-effect 误授权与 launch-credit 绕过。
lint 非零没有被豁免；本切片只证明 warning 数量与规范化内容未新增。

## 审查者反例与纠偏

1. 合同 reviewer 首先指出：result 接受后到 formal 前没有跨周期 completion owner，会让同 PID
   的第二个 FP/EX 候选再次产生实际效果。合同与 RTL 增加 FIFO occupied-derived
   `completion_pending_mask`，并以延迟一拍的重复 FP/EX 候选定向证明第二次效果被拒绝。
2. reviewer 还指出：8-entry FIFO 满且不可 pop 时，第 9 个不可背压算术结果没有合法 holder。
   实现改为 launch-time 精确信用不变量，并以 shared-WB 持续阻塞、9 个算术操作的定向测试与
   删除 credit guard 的 compile-success mutation 闭合。
3. 实现 reviewer 最终 `pass` 且无 blocker；其要求的同槽 pop/push/kill 原子性和 generation-
   separated transport 已转成 assertion/TB。reviewer 只消费冻结摘要，没有独立文件、shell、
   网络或写权限，因此结论不替代本地验证。
4. reviewer 指出的第三项盲区仍保留：固定优先级 `arith > exec1 > long` 在真实 ROB/dispatch
   回压下的有限周期释放，以及 formal pop/result push/launch/kill 混合时序，尚无独立形式活性
   证明。本轮 9-op 证据只覆盖算术 credit 压力，不把它表述为混合源公平性证明。
5. 回归中发现旧 v8d/v8f 定向测试曾在循环外 force 动态 RHS，并用 raw index 构造不匹配的
   full PID；Icarus 会快照 RHS，旧矩阵并非真正逐点变化。测试已改为每个矩阵点重建 full PID
   与 force 变量，并把 raw transport 和 exact-open authority 分开。这是测试根因纠正，不是对
   RTL 功能退化的掩盖。

## AI 开发环境实战固化

- 两份 reviewer 合同分别为
  `subagent-contracts/v8i-fp-producer-lease-contract-review.json` 与
  `subagent-contracts/v8i-fp-producer-lease-implementation-review.json`；SHA-256 分别为
  `04e2f834fda286ebf4d6ac8429727dd307b73ab7e551e1f74175358c04cda7aa` 和
  `5bf0f66ec019aee1fa22e2c7292ff5cf77700ff515c3d52fdbe898181973d84e`，各自只绑定对应 JSON。
- 实际 reviewer 边界比 JSON 上限更窄：no tools、no shell、no file/network/write access，只读
  自包含冻结摘要；Windows→WSL 工程命令由主 agent single-flight 执行，局部 review 节点不会
  自动把长期父目标标为 blocked。
- 文本 reviewer 结果落入 `dispatch-log.md` 与 `implementation-review-result.json`；反例必须
  转成 spec/TB/assertion/mutation/audit，未闭合部分登记为证据盲区或剩余 RED，不能以 reviewer
  `pass` 代替验证。
- 准确声明本地 RV64 Verilog/SystemVerilog 数字电路范围、指定路径和最小权限，用于减少歧义
  并便于审计；不以规避、削弱或改变平台审查为目标，也不承诺平台零误判。
- retained memory 已更新，并完成 DB snapshot/audit 与 `npc-dev`、`agent-system` bounded brief；
  `.github/task-runs/2026-07-19-rv64-fp-producer-lease/` 与
  `.github/task-runs/2026-07-19-rtl-reviewer-contract-producer-lease/` 均 completed。strict guard
  精确要求并接受 `npc-dev + agent-system`。任一历史失败或后续失败都必须按真实状态保留，不得
  手工改报告制造 GREEN。

## 剩余 RED / UNKNOWN

- 固定优先级 FP arith/exec1/long 混合源在真实回压下的独立形式活性与全部 death-edge 组合；
- branch resolve、CSR/pending-system、其它完成 carrier 和跨模块 actual-valid 完整 cone audit；
- 全核 holder census、finite-generation collision fence 与 global no-live-reuse 形式证明；
- real architecture inventory、strict lint 115 条继承 warning；
- official/DiffTest/AM/Linux、arch-stable freeze、fresh synthesis/STA/power、200 MHz 与 Pareto gate。

## 最终裁决

v8i FP ProducerId lease scoped slice 完成，父目标继续 `active`。本轮没有运行或授权 PPA
promotion；下一主序继续关闭 branch/pending-system/CSR、全核 holder census 与 global
last-reference/no-live-reuse，并在架构 hard gate 闭合前保持 PPA 声明为 unqualified。上述
focused/mutation/legacy/module PASS 只支持本 scoped slice，不构成全核正确性、architecture
promotion 或 PPA 结论；115 条 lint 只证明继承集合未新增，并未被本轮关闭。
