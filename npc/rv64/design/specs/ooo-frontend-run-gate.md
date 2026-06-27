# OooFrontendRunGate

## 需求

`OooFrontendRunGate` 承接 `OooAluFetchCore` 中前端运行许可与 fetch credit
相关的纯组合判定：

- 判断 `stop_pending_q` 是否有真实 owner，区分 orphan stop 与 busy stop。
- 生成前端 `can_run`，统一考虑 run、flush、halt、trap、exit 与 stop pending。
- 判断 fetch response 是否可在 FIFO 空时旁路进入 dispatch-visible head。
- 将 outstanding fetch request 规格化为 FIFO credit 计数，并判断是否还有 reserve。

父模块仍保留所有状态所有权，包括 `stop_pending_q` 清理、trap/serial flush 打拍、
outstanding/discard 状态、FIFO 存储和 PC 更新。

## 协议

输入信号分为四类：

- `run/flush/halt/trap/exit`：决定前端是否允许运行。
- `stop pending owner`：所有能够解释 `stop_pending_q` 的 pending/branch-spec owner。
- `fetch response bypass`：FIFO storage head、outstanding、response valid 与 discard。
- `fetch credit`：FIFO count、FIFO depth 与 outstanding valid。

输出信号：

- `orphan_stop_pending_o = stop_pending_i && !stop_pending_owner`。
- `stop_pending_busy_o = stop_pending_i && !orphan_stop_pending_o`。
- `can_run_o = run_i && !core_trap_flush_i && !core_serial_flush_i &&
  !stop_pending_busy_o && !halted_i && !trap_valid_i && !exit_valid_i`。
- `fifo_empty_storage_o = !fifo_storage_head_valid_i`。
- `fetch_rsp_dispatch_bypass_o = fifo_empty_storage_o && can_run_o &&
  outstanding_valid_i && fetch_rsp_valid_i && !discard_fetch_rsp_i`。
- `outstanding_count_o` 是 `outstanding_valid_i` 扩展后的 fetch packet count。
- `fifo_reserve_available_o = (fifo_count_i + outstanding_count_o) < fifo_depth_i`。

## 不变量

- Orphan stop 不阻塞 `can_run_o`，但 busy stop 必须阻塞。
- Trap flush、serial flush、halted、trap valid、exit valid 任一为真时，
  `can_run_o` 必须为假。
- Response bypass 只在 FIFO storage head 为空、前端可运行、有 outstanding response、
  当前 response valid 且未 discard 时成立。
- Reserve credit 只由 FIFO resident packet 与 outstanding request 共同消耗；
  helper 不查看 response ready/fire，也不修改 FIFO 状态。

## 非职责

- 不清理 `stop_pending_q`。
- 不产生 fetch request ready-valid。
- 不决定 FIFO pop/enqueue/seed/clear。
- 不选择 PC，不处理 redirect/trap recovery。
- 不解释 instruction、response code 或分支预测结果。
