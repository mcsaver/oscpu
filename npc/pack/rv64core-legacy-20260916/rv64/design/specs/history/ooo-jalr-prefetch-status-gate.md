# OooJalrPrefetchStatusGate

> ⚠️ **状态(2026-07-03 RTL 重读)**:活文件中的死通道——`OOO_ROB_WALK_MODE=1` 下 `pending_jump_i` 恒 0(pending jump capture 被 `!rob_walk_mode_i` 门死)且 `branch_prefetch_active_i` 恒 0(prefetch req 恒不发起),`match_o` 及全部 hit 输出恒 0;拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 需求

`OooJalrPrefetchStatusGate` 承接 `OooFrontend` 中 JALR branch-prefetch
hit status 的纯组合判定：

- 在已 dispatch 的 JALR target 与当前 resolve target 之间选择可比较 target。
- 判断 active branch prefetch PC 是否命中 JALR target。
- 基于 buffered packet 与 same-cycle response capture 生成 JALR hit status。
- 区分 hit available 与 pending match，供父模块继续执行 outstanding/recovery 更新。

父模块仍保留 JALR operand resolve、misalign 判定、JALR BTB update、hit packet mux、
prefetch buffer 状态和 PC/outstanding/discard 时序所有权。

## 协议

输入信号分为四类：

- JALR owner：`stop_pending_i`、`pending_jump_i`、`pending_jump_jalr_i`。
- Target source：`pending_jump_dispatched_i`、`pending_jump_target_i`、
  `pending_jump_resolve_ready_i`、`pending_jump_resolved_target_i`、
  `pending_jump_misaligned_i`。
- Prefetch source：`branch_prefetch_active_i`、`branch_prefetch_pc_i`。
- Hit source：`branch_prefetch_buffer_valid_i`、
  `branch_prefetch_rsp_capture_i`。

输出信号：

- `match_o` 表示 active branch prefetch PC 命中当前 JALR target。
- `buffer_match_o = match_o && branch_prefetch_buffer_valid_i`。
- `rsp_match_o = match_o && branch_prefetch_rsp_capture_i`。
- `hit_available_o = buffer_match_o || rsp_match_o`。
- `pending_match_o = match_o && !hit_available_o`。

## 不变量

- Target ready 必须来自已 dispatch JALR target 或当前 resolve-ready target。
- 已 dispatch target 优先于当前 resolve target，以保持旧逻辑 target mux 语义。
- JALR match 必须要求 active、stop pending、pending jump、JALR 类型、target ready、
  非 misaligned，且 prefetch PC 等于所选 target。
- Buffered hit 与 same-cycle response hit 可独立产生，`hit_available_o` 是二者 OR。
- Match 成立但没有 buffered hit 或 same-cycle response hit 时，必须产生
  `pending_match_o`。

## 非职责

- 不计算 JALR target 本身，不执行 rs1+imm。
- 不产生或更新 JALR BTB。
- 不选择 hit packet payload。
- 不更新 outstanding、discard、next fetch PC 或 recovery 状态。
- 不写入或清空 branch prefetch buffer。
