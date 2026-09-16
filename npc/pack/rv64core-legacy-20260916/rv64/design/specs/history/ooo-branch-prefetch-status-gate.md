# OooBranchPrefetchStatusGate

> ⚠️ **状态(2026-07-03 RTL 重读)**:活文件中的死通道——`OOO_ROB_WALK_MODE=1` 下 prefetch request 恒不发起(`branch_prefetch_active_i` 恒 0)且 pending_branch/pending_jump 恒 0,capture/match/hit 全输出恒 0;拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 需求

`OooBranchPrefetchStatusGate` 承接 `OooFrontend` 中 branch/JALR
prefetch response capture 与 branch resolve hit status 的纯组合判定：

- 判断当前 fetch response 是否应被 branch prefetch path 捕获。
- 判断 active prefetch PC 是否命中当前 branch resolve next PC。
- 在 buffered packet 与 same-cycle response capture 两类来源上生成 hit status。
- 区分 hit available 与 pending match，供父模块继续执行 FIFO seed、buffer clear
  和 recovery 状态更新。

父模块仍保留 branch prefetch buffer 状态寄存器、packet payload 选择、JALR hit
payload 选择、request fire/outstanding、redirect/recovery 和 branch resolve 时序所有权。

## 协议

输入信号分为三类：

- Capture source：`branch_prefetch_active_i`、`branch_prefetch_buffer_valid_i`、
  `stop_pending_i`、`pending_branch_i`、`pending_branch_dispatched_i`、
  `pending_jump_i`、`pending_jump_jalr_i`、`fetch_rsp_fire_i`。
- Match source：`branch_prefetch_pc_i`、
  `core_branch_resolve_next_pc_i`。
- Buffer source：`branch_prefetch_buffer_valid_i`。

输出信号：

- `rsp_capture_o` 表示当前 fetch response 可作为 active branch prefetch 的
  same-cycle response 来源。
- `match_o` 表示 active branch prefetch PC 与当前 branch resolve next PC 相等。
- `buffer_match_o = match_o && branch_prefetch_buffer_valid_i`。
- `rsp_match_o = match_o && rsp_capture_o`。
- `hit_available_o = buffer_match_o || rsp_match_o`。
- `pending_match_o = match_o && !hit_available_o`。

## 不变量

- Response capture 必须要求 prefetch active、buffer 尚未 valid、前端处于
  stop-pending、response fire，且 owner 为 dispatched pending branch 或 pending JALR。
- Match 必须要求 prefetch active；PC 相等但 inactive 时不能产生 match。
- Buffered hit 与 same-cycle response hit 可独立产生，`hit_available_o` 是二者 OR。
- 当 match 成立但没有 buffered hit 或 same-cycle response hit 时，必须产生
  `pending_match_o`。
- Buffer 已 valid 时禁止再次 capture same-cycle response，避免覆盖已有影子包。

## 非职责

- 不选择 hit packet payload，不解释 fetch response 内容。
- 不写入或清空 branch prefetch buffer。
- 不产生 prefetch request、request fire 或 outstanding 状态。
- 不执行 branch target 合法性检查，不更新 redirect PC。
- 不处理 JALR 专用 hit status；JALR path 仍由父模块基于本模块的 capture 结果组合。
