# OooDirectBranchResolveGate

## 需求

`OooDirectBranchResolveGate` 承接 `OooAluFetchCore` 中 direct branch fast
path 的纯组合事实生成：

- 在 lane0/lane1 direct branch fire 之间选择 branch PC、fallthrough、立即数、
  target、BHT metadata 和 predicted PC。
- 合并 dispatch-resolve 与 issue-resolve 两类 branch resolve 来源。
- 生成 direct branch redirect/taken status。
- 生成 lane0 branch 跳到 lane1 return 的特殊 capture predicate。

父模块仍保留前端 dispatch gate、BPU 表、branch target cache、RAS、pending branch
状态、fetch request mux、trap/recovery 和所有时序状态所有权。

## 协议

输入信号分为五类：

- Fire source：`direct_branch0_fire_i`、`direct_branch1_fire_i`。
- Lane payload：lane0/lane1 PC、next PC、branch immediate。
- BHT source：lane0/lane1 BHT index、valid 和 predicted taken。
- Resolve source：dispatch-resolve 与 issue-resolve 的 valid/PC/next PC/misaligned。
- Control blocker：`trap_redirect_squash_i`、lane1 return candidate 和 synthetic
  lane1 pending/drop 状态。

输出信号：

- `direct_branch_fire_o = direct_branch0_fire_i || direct_branch1_fire_i`。
- `direct_branch_pc_o`、`direct_branch_next_pc_o`、`direct_branch_imm_o`、
  `direct_branch_target_o` 和 `direct_branch_pred_pc_o`。
- `head0_branch_target_o` 供 branch target cache lookup 继续使用。
- `direct_branch_bht_idx_o`、`direct_branch_bht_valid_o`、
  `direct_branch_predict_taken_o`。
- `direct_branch_resolve_valid_o`、`direct_branch_resolve_next_pc_o`、
  `direct_branch_resolve_misaligned_o`、`direct_branch_resolve_redirect_o`、
  `direct_branch_resolve_taken_o`。
- `direct_branch0_lane1_ret_o`。

## 不变量

- lane1 fire 为真时，direct branch payload 与 BHT metadata 必须选择 lane1；
  否则选择 lane0。
- Dispatch-resolve 优先于 issue-resolve，用于选择 resolve next PC 与 misaligned。
- Issue-resolve 只在 direct branch fire 且 resolve PC 等于所选 direct branch PC 时有效。
- Redirect 必须要求 resolve valid、非 misaligned，且未被 trap redirect squash。
- Taken 必须要求 redirect 有效且 resolve next PC 等于 direct branch target。
- lane1 return capture 必须来自 lane0 branch fire、resolve valid、非 misaligned、
  resolve next PC 等于 lane1 PC、lane1 return candidate，且没有 synthetic lane1
  return/drop pending。

## 非职责

- 不读取或更新 BHT/BTB/RAS。
- 不写 pending branch 状态，不更新 next fetch PC。
- 不执行 branch target cache capture/cache lookup。
- 不产生 fetch request，不处理 FIFO/ROB/commit。
