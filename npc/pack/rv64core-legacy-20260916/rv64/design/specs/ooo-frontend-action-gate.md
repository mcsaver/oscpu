# OooFrontendActionGate

## 需求

`OooFrontendActionGate` 承接 `OooAluFetchCore`（现已重构为 `OooFrontend` wrapper）中分散的前端动作谓词：

- direct JAL/branch/return fast path 是否触发前端直接 flush。
- 当前 dispatch-visible head packet 是否应暂停普通顺序取指。
- FIFO head 是否应被 pop。
- 当前 fetch response packet 是否包含 control-stop 指令并已进入可入队路径。
- CSR/trap flush 是否应阻止本拍 fetch request valid。

父模块仍保留 PC 选择、redirect、FIFO 存储、response ready-valid、dispatch
sequencer、pending/commit/trap 和所有时序状态所有权。

## 协议

输入信号均为父模块已经解码或仲裁后的 predicate：

- Direct fast-path fire：`direct_jal_fire_i`、`direct_branch0_fire_i`、
  `direct_branch1_fire_i`、`direct_ret0_fire_i`、`direct_ret1_fire_i`、
  `direct_jump_spec_fire_i`（B2：非返回 JALR 投机续取）。
- Dispatch-visible head：`can_run_i`、`fifo_has_packet_i`、
  `branch_spec_dispatch_block_i`、slot0/slot1 barrier/unsupported predicates。
- FIFO pop：`dispatch_fire_i`、`dbranch_dispatch_fire_i`（domain-A：head0
  分支普通 dispatch fire）、`dispatch1_barrier_fire_i`、`direct_jal0_fire_i`。
- Response control-stop：`fetch_rsp_fire_i`、`fetch_rsp_can_enqueue_i`、
  decoded packet control-stop bits。
- Trap request blocker：CSR trap memory/execute/interrupt valid 与 core-local
  trap/serial flush。

输出信号为纯组合：

- `direct_frontend_flush_o` 是任一 direct fast-path fire 的 OR。
- `stop_head_o` 只在前端可运行、有 head packet、未被 branch-spec block 且 head
  需要 barrier/unsupported/direct 处理时为真（head0 条件分支臂被
  `OOO_DBRANCH_DOMAIN_A=1` 恒关，分支不再 stop head）。
- `fifo_pop_o` 保留旧语义：normal dispatch、domain-A 分支普通 dispatch、
  lane1 barrier dispatch 或 lane0 direct JAL 会消费当前 head packet。
- `fetch_rsp_control_stop_o` 只在 response 已 fire、可 enqueue 且 decoded packet
  含 control-stop 时为真。
- `fetch_request_blocked_by_trap_o` 在 CSR trap pending 或 core trap/serial flush
  pending 时阻止 request valid。

## 不变量

- Branch-spec dispatch block 必须压低 `stop_head_o`。
- `stop_head_o` 不直接 pop FIFO；FIFO pop 只由 dispatch/fire 类输入决定。
- Direct branch/return fast-path flush 不等价于 FIFO pop，只有 `direct_jal0_fire_i`
  进入本 helper 的 FIFO pop 规则。
- Response control-stop 不查看 response payload 内容，只消费父模块已解码出的
  control-stop bits。
- Trap request blocker 不更新 trap 状态，也不决定 redirect PC。

## 非职责

- 不生成 fetch request/response ready-valid。
- 不选择或更新 PC。
- 不写 FIFO，不处理 seed/clear。
- 不解释 opcode、CSR cause、branch target 或 RAS。
- 不持有任何状态。

## V9O C0 队头全清空屏障

新增 `control_full_flush_barrier_i`。它是 ROB 稳定队头在 C0 的全清空预授权，不是
`flush_i`：

- 屏障为 1 时，`direct_frontend_flush_o=0`、`fifo_pop_o=0`，并使
  `fetch_request_blocked_by_trap_o=1`；
- `stop_head_o` 可保持原有观测语义，但不得由此消费 packet；
- response control-stop 解码仍可观测已返回 packet，不能产生 enqueue/pop/PC 侧效应；
- C1 才由类型化 apply 触发现有 frontend clear。

新增不变量：

- **FE-ACT-I6 C0 no new action**：屏障拍不得产生 direct frontend flush、FIFO pop
  或新 fetch request；
- **FE-ACT-I7 no state ownership**：屏障只组合门控准入，不在 helper 内锁存。

变更记录补充：

- 2026-07-23（V9O）：加入 C0 队头全清空屏障，暂停新的前端动作而不清状态。
