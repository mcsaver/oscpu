# v8h dispatch log

- 父目标保持 `active`；本节点只处理本地 RV64 Verilog/SystemVerilog 数字电路的整数长延迟
  ProducerId lease 与完成资格。
- Windows/Codex→WSL 工程命令由主 agent single-flight 串行执行。
- reviewer 合同、SHA 与实际 no-tools 边界将在 JSON `validate/render` 后追加。

## v8h contract reviewer dispatch

- 合同 JSON 路径：`.github/task-runs/2026-07-19-rv64-v8h-integer-longop-producer-lease/subagent-contracts/v8h-longop-lease-contract-review.json`
- 合同 JSON SHA-256：`eb9255def223108204a68b0346fc37b06b3f06d23c3ff00722a33af4ee8f2872`
- 该 SHA-256 只绑定上述 JSON，不绑定设计 spec、`contract.md`、RTL、测试或其它上下文。
- JSON 上限允许只读 `rg`/`sed`；实际派发进一步收紧为 no tools、no shell、no file access、
  no network，只消费主 agent 提供的冻结自包含摘要。
- 交付要求：给出带 cycle event、identity state 与 observable side effect 的具体反例；文本反例
  之后必须由主 agent 转为 spec/TB/mutation/static audit 或剩余风险。

## reviewer result / 主 agent 处置

- reviewer verdict：`gap`。
- blocker 1：edge-old ROB query 会让同 PID 的 EX/memory/long-op 同拍同时看见 open。处置：合同
  修订为 full-PID actual claim 全序 `EX0 > EX1 > memory > MulDiv > CLMUL`；fence 只进 side-effect
  cone，禁止进入 raw route/ready/mask/FSM，并要求逐源删除 mutation。
- blocker 2：registered live mask 不能处理两个同拍 birth candidate 的同 PID 碰撞。处置：现有
  ROB pair candidate 的低 index 位分别为 `tail` 与 `tail+1`；本切片把其结构性不同固化为 Q-only
  assertion、direct TB 和 mutation，而不把 live mask误当 pair arbiter。
- reviewer 的 FP/branch/pending/global no-live-reuse 风险全部保留为 RED；不扩大 v8h 本地
  GREEN 边界。

## v8h implementation reviewer dispatch

- 合同 JSON 路径：`.github/task-runs/2026-07-19-rv64-v8h-integer-longop-producer-lease/subagent-contracts/v8h-longop-lease-implementation-review.json`
- 合同 JSON SHA-256：`5b80eb3009ca573781c470bbf7e815dff645cc3cad214b7efbbe9dd77f603af7`
- 该 SHA-256 只绑定上述 JSON，不绑定设计 spec、RTL、testbench、runner、证据或本结果。
- 实际派发进一步收紧为 no tools、no shell、no file access、no network、no writes；reviewer
  只消费主 agent 提供的冻结实现与验证摘要，父 agent 持续执行主线，不等待性阻塞长期目标。

## implementation reviewer result / 主 agent 处置

- reviewer verdict：`pass`，无 blocker；原始结构化结果保存在
  `implementation-review-result.json`。
- evidence blind spot 1：reviewer 只有摘要，未独立核对 actual-valid 的完整扇出与组合依赖图。
  处置：不把 reviewer pass 当作结构证据；本轮只引用 source-bound audit、focused mutation、
  module aggregate 与 contract/lint 输出，并把独立 cone audit 留作后续 hard gate。
- evidence blind spot 2：持续背压、generation 整圈回绕和全部 death-edge 并发组合尚无形式证明。
  处置：v8h 只签收 bounded directed/mutation 证据；global no-live-reuse/formal 保持 RED。
- residual risk：stale long-op 仍按 raw route 排空，可能占低优先级传输槽；正确性依赖被阻塞
  来源可靠保持或重试。本切片证明 raw transport 与 actual side effect 分离，不宣称该 QoS 风险消失。
- FP full PID、branch/CSR/pending-system、全核 holder census 与 global no-live-reuse 继续 RED；
  reviewer pass 不授权架构或 PPA promotion。

## closeout / e2e

- retained memory 已依次执行 `update-stored`、`snapshot-stored` 与 `audit-db-first`；v8h bounded
  brief 从当前 `modules/npc.md` 命中 independent primary。
- `npc-dev` evidence：`.github/task-runs/2026-07-19-rv64-integer-longop-producer-lease/`，5/5
  completed/publication-valid。
- strict guard 首轮只缺 fresh `agent-system`；补跑
  `.github/task-runs/2026-07-19-rtl-task-contract/` 后，终态 `agent-system+npc-dev` 全 PASS。
- e2e 只签收工作流发现/执行/审计，不替代本 task-run 的 focused/module/static RTL 证据。
