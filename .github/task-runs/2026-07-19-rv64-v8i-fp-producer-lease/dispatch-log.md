# v8i dispatch log

- 工程领域：本地 RV64 Verilog/SystemVerilog 数字电路设计与验证。
- 父目标保持 `active`；本节点只处理 FP ProducerId holder/lease/completion authorization。
- Windows/Codex→WSL 工程命令由主 agent single-flight 串行执行。
- reviewer 合同路径、SHA-256、实际权限边界与反例处置在 validate/render/dispatch 后追加。

## v8i contract reviewer dispatch

- 合同 JSON 路径：`.github/task-runs/2026-07-19-rv64-v8i-fp-producer-lease/subagent-contracts/v8i-fp-producer-lease-contract-review.json`
- 合同 JSON SHA-256：`04e2f834fda286ebf4d6ac8429727dd307b73ab7e551e1f74175358c04cda7aa`
- 该 SHA-256 只绑定上述 JSON，不绑定设计 spec、`contract.md`、RTL、测试或派发摘要。
- JSON 上限允许只读 `rg`/`sed`；实际派发进一步收紧为 no tools、no shell、no file access、
  no network、no writes，只消费主 agent 提供的冻结自包含摘要。
- 交付要求：结构化 verdict；每个 gap 必须包含 cycle event、full PID/Q state 与可观察 side
  effect/progress failure，并能转成 directed TB、compile-success mutation 或 residual risk。

## reviewer result / disposition

- verdict：`gap`。
- blocker 1：result actual 到 formal 之间无跨周期唯一 completion owner；已修订为 done FIFO
  occupied PID capability，并要求全部非 formal source 的生产态 pending fence。
- blocker 2：不可背压 arith output 无严格 FIFO credit；已修订为 post-launch Q occupancy 推导的
  execution-launch credit，issue packet 在无 credit 时保持。
- 两项均转入 normative spec、directed TB、compile-success mutation 与 source-bound audit；未被
  降格为 assertion-only 或 residual risk。
- residual RED：branch、pending-system/CSR、全核 holder census、global no-live-reuse 与 PPA。

## implementation reviewer dispatch

- 合同 JSON：`.github/task-runs/2026-07-19-rv64-v8i-fp-producer-lease/subagent-contracts/v8i-fp-producer-lease-implementation-review.json`
- JSON SHA-256：`5bf0f66ec019aee1fa22e2c7292ff5cf77700ff515c3d52fdbe898181973d84e`
- create/validate/render 均 PASS；SHA 只绑定 JSON。
- JSON 上限允许只读 `rg`/`sed`，实际运行进一步收紧为 no tools、no shell、no file access、
  no network、no writes；reviewer 只消费主 agent 提供的实现与证据摘要。
- 只允许返回具体 cycle/PID/Q-state 反例、证据盲区或 bounded pass；不得改 RTL、测试或任务状态。

## implementation reviewer result / disposition

- verdict：`pass`；correctness blocker：0。
- 同槽 FIFO `pop(P)+push(Q)+kill` 盲区已转为生产断言
  `[V8I-FP-FIFO-PUSH-ATOMIC]` 与三组 directed case，分别覆盖旧 P 被 kill/new Q 存活、旧 P
  存活/new Q 被 kill、kill cut 对 P/Q 均不命中；新 push 的 valid/PID/tombstone 必须覆盖旧写。
- stale formal `P={g,i}` raw route 与 `Q={g+1,i}` 同 raw index 盲区已转为 EX0 与 FP-result 两条
  directed actual-positive，证明 full-PID pending/claim 不把 generation 压扁。
- `arith > exec1 > long` 混合压力的独立形式化 finite-progress 证明未运行；保留为 residual risk，
  不以 reviewer `pass`、105/105 module TB 或九操作 credit drain 越级替代。
- 结构化结果：`implementation-review-result.json`。

## report-claim follow-up review

- 同一 implementation reviewer 在 no tools/no shell/no file/network/write 的边界内，只复核
  task-report 核心声明是否越级；返回 `overclaims=[]`。
- reviewer 指出派发给它的精简核心摘要没有逐项重复 branch、pending-system/CSR、全核 holder
  census、finite-generation global no-live-reuse 等免责声明。正式 `task-report.md` 的
  `剩余 RED / UNKNOWN` 已包含这些项目，并在最终裁决再次明确：所有 PASS 只支撑 scoped slice，
  不构成全核正确性、architecture promotion 或 PPA 结论；lint 115 仅是继承集合未新增。
- 因此该 follow-up 的 `gap` 解释为“摘要缺免责声明、正式报告已闭合”，不是新的 RTL blocker，
  也不会改变父目标 `active` 或局部实现 reviewer 的原始 correctness verdict。
