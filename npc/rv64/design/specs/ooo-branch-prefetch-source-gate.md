# OooBranchPrefetchSourceGate

## 需求

`OooBranchPrefetchSourceGate` 承接 `OooAluFetchCore` 中 branch/JALR prefetch
source 的纯组合事实生成：

- 计算 pending branch target。
- 在 branch target 与 branch fallthrough next PC 之间选择 branch prefetch predicted PC。
- 判断 pending JALR 是否是可由 RAS 处理的 return hint。
- 判断 pending JALR 是否需要访问 JALR BTB。

父模块仍保留 pending branch/jump 状态寄存器、RAS 栈状态、JALR BTB lookup 表项、
prefetch request gate、branch resolve、trap/recovery 和 PC/outstanding 时序所有权。

## 协议

输入信号分为三类：

- Branch source：`pending_branch_pc_i`、`pending_branch_imm_i`、
  `pending_branch_next_pc_i`、`pending_branch_pred_taken_i`。
- JALR source：`stop_pending_i`、`pending_jump_i`、`pending_jump_jalr_i`、
  `pending_jump_rd_i`、`pending_jump_rs1_i`、`pending_jump_imm_i`。
- RAS source：`ras_empty_i`。

输出信号：

- `pending_branch_target_o = pending_branch_pc_i + pending_branch_imm_i`。
- `branch_pred_pc_o` 在 `pending_branch_pred_taken_i` 为真时选择
  `pending_branch_target_o`，否则选择 `pending_branch_next_pc_i`。
- `jalr_ret_hint_o` 表示当前 pending JALR 是 `rd=x0, rs1=x1/x5, imm=0` 的
  return hint。
- `jalr_btb_lookup_o` 表示当前 pending JALR 应访问 JALR BTB。

## 不变量

- Branch predicted PC 只由 pending branch 自身的 predicted-taken bit 决定，
  不查看 BTB/RAS/outstanding 状态。
- Return hint 必须同时要求 pending jump、JALR、`rd=x0`、`rs1=x1/x5`、`imm=0`。
- JALR BTB lookup 必须要求 `stop_pending_i && pending_jump_i &&
  pending_jump_jalr_i`。
- 当 return hint 成立且 RAS 非空时，JALR BTB lookup 必须被 RAS path 抑制。
- 当 return hint 成立但 RAS 为空时，JALR BTB lookup 仍可发起，保持旧 fallback 行为。

## 非职责

- 不读写 JALR BTB，不判断 BTB hit。
- 不读写 RAS，不选择 RAS target。
- 不发起 fetch request，不查看 `fetch_req_ready_i`。
- 不判断 branch resolve match，不更新 pending/redirect/recovery 状态。
- 不处理 JALR call/return commit 侧 RAS push/pop 策略。
