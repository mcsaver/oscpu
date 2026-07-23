# v8j dispatch log

- 工程领域：本地 RV64 Verilog/SystemVerilog 数字电路设计与验证。
- 父目标保持 `active`；本节点只处理 registered branch-resolve carrier 的生产者归属和控制副作用授权。
- Windows/Codex→WSL 工程命令由主 agent single-flight 串行执行。
- reviewer 只消费冻结、自包含摘要；实际权限收紧为 no tools、no shell、no file/network/write access。
- 合同 JSON 路径、SHA-256、原始反例和处置在 create/validate/render 后追加。

## 当前问题

`OooIntBackend.u_branch_resolve_stage` 与 EX0 由同一次 lane0 control-flow fire 产生，但 resolve q
只保存 raw ROB index。`branch_resolve_valid_o` 目前只由 raw stage valid 与 flush/checkpoint mask
决定，随后直接授权 redirect、ROB walk、BPU update，以及 IQ/FU/MIQ/SQ 的 selective kill。EX0
完成已使用 full ProducerId exact-open；resolve 控制副作用仍在该授权域之外。

## 冻结 reviewer 问题

1. 当 resolve q 保存旧 `P={g,i}`、EX0/ROB 已是新 `Q={g+1,i}` 时，怎样保证 raw index 相等也
   不能让 P 的 redirect/kill/BPU update 取得 actual capability？
2. resolve query 若复用 completion query 的 `producer_target_killed_now()`，会不会形成
   `query→mispredict→kill_valid→query` 组合环？
3. 当前 mispredict 必须保留 boundary P；哪些 reset/flush/checkpoint/prior-recovery/done 死亡沿
   应 fail-closed，哪些同拍 self-kill 不应误杀边界？
4. full-PID coherence 应只用 assertion 报错，还是生产态也应把 branch effect 静默门死？

## contract reviewer dispatch

- 合同 JSON：`.github/task-runs/2026-07-19-rv64-v8j-branch-resolve-producer-authorization/subagent-contracts/v8j-branch-resolve-contract-review.json`

## Contract reviewer disposition

- reviewer verdict：`gap`；命中的是 EX0 coherence 信号类别未写死，方案未被否决。
- 已接受并冻结修正：coherence 只能读取 raw registered `ex0_valid_q` / `ex0_producer_id_q`；
  禁止读取 completion-open、killed-now、WB-valid 或其他 semantic valid。
- 已新增结构前提：当前 `kill_valid_i` 唯一来源为本 authorized resolve；`flush/checkpoint` 不得是
  capability 的组合后代。若未来接口演化打破前提，必须重新做无环仲裁审查。
- reviewer 要求的 self-mispredict 恰好一拍、killed-now-inclusive/semantic-valid mutation 与组合
  依赖审计已加入必需验证。

## Implementation root-cause note

- 首次全模块 smoke 编译成功，但 T3N 连续正确分支的第一条未完成：观测到 slot live、!done、
  exact、`kill=0/recover=0`，completion query 却残留 `killed=1`。
- 根因不是 v8j capability 放宽/收紧，而是既有 killed-now 函数通过函数体隐式读取全局
  `head/kill/recovery`；调用表达式仅显式携带 raw index，同 index 下全局翻转未可靠触发 Icarus
  重新求值，且并行调用共享临时状态。
- 已做根因级修复：函数改为 `automatic`，六项依赖全部显式参数化；新增“PID/index 不变、kill
  先置后撤”定向回归与 sticky-dependency compile-success mutation。
- 修复后 v8j assert/release focused、12 个 mutation 与完整 backend/ROB/Dispatch smoke 均通过；
  仍不形成 timing/PPA 或全核架构 GREEN 结论。

## Implementation reviewer dispatch

- 合同 JSON：`.github/task-runs/2026-07-19-rv64-v8j-branch-resolve-producer-authorization/subagent-contracts/v8j-branch-resolve-implementation-review.json`
- SHA-256：`a17c811e3c338a025a78d0f953515f343225deaf3586c67264164e46fbb35ea0`
- validate/render：PASS；只读路径白名单、`rg`/`sed`、无写路径、无网络/账号/凭据/外部服务。
- 复核范围只含 v8j spec/contract/RTL/TB/evidence；父目标保持 `active`，review 结果只处置本切片。

## Implementation reviewer disposition

- verdict：`pass`；没有可执行 blocker。
- 已接受证据盲区：尚无 elaborated-netlist SCC/formal loop 报告；reviewer 未独立重跑原始波形与
  mutation patch；未来独立同拍 older-kill 不在本合同覆盖内。
- 已冻结禁止外推：lint 115 仅是继承基线不漂移；architecture inventory 仍 RED；不形成
  timing/PPA/promotion、pending-system/CSR、finite-generation global reuse 或全核正确性结论。
- 结果落盘：`implementation-review-result.json`；父目标保持 `active`。
- JSON SHA-256：`70355b973f0b4c11b770d281ea8b5f213e868413d49e93c9809fa857a2bb8e31`
- SHA-256 只绑定上述 JSON，不绑定设计 `contract.md`、spec、RTL、测试或冻结摘要。
- create/validate/render 均 PASS；JSON 上限允许白名单内 `rg`/`sed`，实际派发进一步收紧为
  no tools、no shell、no file/network/write access，只消费主 agent 提供的自包含合同摘要。
