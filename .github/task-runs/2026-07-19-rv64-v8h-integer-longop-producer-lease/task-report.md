# RV64 v8h 整数长延迟 ProducerId lease 闭合报告

## 基本信息

- `task_id`: `2026-07-19-rv64-v8h-integer-longop-producer-lease`
- `task_class`: `architecture_closure_without_ppa_promotion`
- `slice_status`: `scoped_completed`
- `parent_goal_state`: `active`
- `promotion_eligible`: `false`

本报告只签收 MulDiv/CLMUL 在当前整数后端内的 full ProducerId 持有、Q-only lease、
exact-open completion query 与同沿 actual-claim 全序。FP、branch、CSR/pending-system、完整
holder census、finite-generation global no-live-reuse、全核架构 hard gate、Linux 与 PPA 都不在
本地 GREEN 内。

## 实现者结论

- `OooMulDivUnit` 与 `OooClmulUnit` 各以唯一 `producer_id_q` 持有 full ProducerId；ROB index/
  kill age 只由其低位投影。lease 从 request capture 后 Q 状态出生，在 terminal/kill/flush
  沿仍反映 edge-old owner，下一拍消失；reset/flush/任意 kill-valid 阻止新 capture。
- `OooIntBackend` 把 memory、MulDiv、CLMUL 的 Q-only owner 解码成 live-mask union，交给
  dispatch birth admission；ROB query3/4 只有 exact full PID、entry valid、`!done`、未 reset/
  flush/kill-now 时开放。
- actual completion claim 固定为 `EX0 > EX1 > memory > MulDiv > CLMUL`。claim 只授权
  WB/PRF/Busy/IQ/ROB/public side effects；raw route、ready、mask 与长延迟 FSM 保持 transport
  路径，stale response 仍可排空。
- 同拍 ROB pair candidate 由 `tail` 与 `tail+1` 的 index 结构保证 PID 不同；该事实由 assertion、
  direct TB 与 mutation 锁定，不把 registered live mask 冒充同沿 pair arbiter。

## 功能与静态硬门

| gate | 结果 | 证据 |
|---|---:|---|
| focused release | 5/5 PASS | `evidence/focused/summary.md` |
| focused `OOO_ASSERT` | 5/5 PASS | `evidence/focused/summary.md` |
| compile-success semantic mutation | 23/23 命中 | `evidence/focused/mutation-summary.tsv` |
| source pre/post hash | byte-equal | `evidence/focused/sources.pre.sha256`、`sources.post.sha256` |
| module aggregate | 105/105 PASS | `evidence/module-aggregate.status` |
| structural audit | PASS | `evidence/static/structural-audit.log` |
| RTL style / contract | PASS；assertions 335 >= 89 | `evidence/static/check-rtl-style.log`、`check-contract.log` |
| architecture checker self-test | 15/15 PASS | `evidence/static/architecture-hard-gates.log` |
| real architecture inventory | `OVERALL: RED`，预期 rc=2 | `evidence/static/architecture-hard-gates.json` |
| strict lint regression | inherited rc=2、115 warnings；normalized SHA 与 v8g byte-equal | `evidence/static/full-lint.status` |

23 个 mutation 覆盖 generation 丢失、RESP-only/early-release lease、kill-ready guard、union
漏项、EX/long-op claim 漏项、exact-open 绕过、authority 进入 ready、ROB query 缺陷、pair alias
与 dispatch PID 截断。lint 非零没有被豁免；本切片只证明 warning 数量与规范化内容未新增。

## 审查者反例与纠偏

1. 合同 reviewer 先指出 edge-old ROB query 会允许同 PID 多来源同沿实际完成；合同在改 RTL 前
   修订为五源 full-PID claim 全序，并要求逐源删除 mutation。
2. reviewer 还指出 registered live mask 不能仲裁两个同沿 birth。主 agent 没有扩大 mask 语义，
   而是证明当前 pair PID 由 tail/tail+1 结构性不同，并增加 assertion/TB/mutation。
3. 实现 reviewer 最终 `pass` 且无 blocker，但只消费冻结摘要，未独立复核 actual-valid 完整
   扇出/组合依赖；持续背压、generation 整圈回绕和全部 death-edge 并发组合也无形式证明。
4. reviewer 指出的 QoS 风险保留：stale long-op 走 raw route 排空可能占低优先级传输槽，
   correctness 仍依赖被阻塞来源可靠保持或重试。本轮只证明 transport 与 actual side effect
   分离，不宣称该资源竞争已优化。

## AI 开发环境实战固化

- 两份 reviewer 合同分别为 `subagent-contracts/v8h-longop-lease-contract-review.json` 与
  `subagent-contracts/v8h-longop-lease-implementation-review.json`；SHA-256 分别为
  `eb9255def223108204a68b0346fc37b06b3f06d23c3ff00722a33af4ee8f2872` 和
  `5b80eb3009ca573781c470bbf7e815dff645cc3cad214b7efbbe9dd77f603af7`，各自只绑定对应 JSON。
- 实际 reviewer 边界比 JSON 上限更窄：no tools、no shell、no file/network/write access，只读
  自包含摘要；Windows→WSL 工程命令由父 agent single-flight 执行，review 节点不阻塞父目标。
- 文本 reviewer 结果必须落入 `dispatch-log.md` 与结构化结果，反例转成 spec/TB/mutation/
  audit；无法闭合的内容只能登记为证据盲区或剩余 RED，禁止用 reviewer `pass` 替代验证。
- 准确的本地 Verilog/SystemVerilog 数字电路领域、指定路径和最小权限用于减少歧义并便于
  审计；不以规避平台检查为目标，也不保证平台零误判。
- retained memory 更新后，DB snapshot/audit 与 `brief rv64 integer longop producer lease
  --profile npc-dev --focus-scope non-history` PASS；任务特异
  `.github/task-runs/2026-07-19-rv64-integer-longop-producer-lease/` 为 `npc-dev` 5/5 completed。
- strict guard 首轮只诊断出前序合同工具改动缺 fresh `agent-system` evidence；随后
  `.github/task-runs/2026-07-19-rtl-task-contract/` completed，终态 strict guard 精确要求并接受
  `agent-system+npc-dev`。首轮 fail 保持真实诊断，不手改报告造绿。

## 剩余 RED / UNKNOWN

- FP full PID、branch resolve、CSR/pending-system 与其它 holder 的 completion authorization；
- 全核 holder census、finite-generation collision fence 与 global no-live-reuse 形式证明；
- actual-valid 的独立完整 cone audit、持续背压/死亡沿组合与 source retry/hold 合同；
- DI/OOO real architecture inventory、strict lint 115 条继承 warning；
- official/DiffTest/AM/Linux、arch-stable freeze、fresh synthesis/STA/power、200 MHz 与 Pareto gate。

## 最终裁决

v8h 整数长延迟 scoped slice 完成，父目标继续 `active`。本轮没有运行或授权 PPA promotion；
下一主序继续关闭 FP/branch/pending carrier 与 global last-reference/no-live-reuse，完整架构硬门
闭合后才能进入正式 PPA A/B。
