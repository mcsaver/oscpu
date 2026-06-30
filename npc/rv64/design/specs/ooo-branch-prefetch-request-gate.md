# OooBranchPrefetchRequestGate

> ⚠ **待校正（非过时归档）**：模块仍在用，但本 spec 的「非职责」节漏列了已新增的 `req_ready_i`
> 输入与 `req_fire_o = req_valid_o && req_ready_i` 输出（见 `../../vsrc/frontend/OooBranchPrefetchRequestGate.v:22,27,53`）。
> 以 RTL 为准；待补一节握手描述。

## 需求

`OooBranchPrefetchRequestGate` 承接 `OooAluFetchCore` 中 branch/JALR prefetch
request 的纯组合生成：

- 判断 pending branch 是否可以发起 speculative prefetch。
- 判断 JALR BTB hit 是否可以发起 prefetch。
- 在 branch predicted PC 与 JALR BTB target 之间选择 prefetch request PC。

父模块仍保留 pending branch/jump 状态、BTB/RAS lookup、branch resolve match、
outstanding/discard 时序、prefetch buffer 状态和 fetch request ready-valid 仲裁。

## 协议

输入信号分为三类：

- Branch source：`stop_pending_i`、`pending_branch_i`、
  `pending_branch_dispatched_i`、`branch_resolve_pending_match_i`、
  `branch_pred_pc_i`。
- JALR source：`jalr_btb_hit_i`、`pending_jump_dispatched_i`、
  `jalr_btb_target_i`。`jalr_btb_hit_i` 由父模块的 JALR BTB lookup path 预限定，
  本模块不重新判断 `pending_jump_q` 或 RAS return hint。
- Shared blockers：`branch_prefetch_active_i`、`outstanding_valid_i`、
  `discard_fetch_rsp_i`、`branch_spec_checkpoint_pending_i`、
  `branch_spec_active_i`、`halted_i`、`trap_valid_i`、`exit_valid_i`。

输出信号：

- `branch_req_valid_o` 表示 pending branch prefetch request 可发起。
- `jalr_req_valid_o` 表示 JALR BTB prefetch request 可发起。
- `req_valid_o = branch_req_valid_o || jalr_req_valid_o`。
- `req_pc_o` 在 JALR request valid 时选择 `jalr_btb_target_i`，否则选择
  `branch_pred_pc_i`，保持旧逻辑中 JALR 对 PC mux 的优先级。

## 不变量

- 任一 shared blocker 为真时，branch/JALR request 都必须无效。
- Branch request 必须要求 stop pending、pending branch、branch dispatched，
  且当前 resolve 尚未命中同一 pending branch。
- JALR request 必须要求 BTB hit 且 pending jump 尚未 dispatched。
- 当 branch 与 JALR request 同时为真时，`req_valid_o` 为真，`req_pc_o` 选择
  JALR BTB target，以保持旧的 PC mux 优先级。

## 非职责

- 不产生 `req_fire`，不查看 `fetch_req_ready_i`。
- 不更新 branch prefetch buffer。
- 不比较 branch resolve PC，不执行 BTB lookup。
- 不解释 JALR return hint、RAS、BHT 或 instruction opcode。
