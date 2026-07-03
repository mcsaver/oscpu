# OooCommitOutputMux Spec

> ⚠️ **状态（2026-07-03 RTL 重读）**：synthetic lane1-ret / branch-append 两类输入源已被形式化证死（ret capture 依赖拍内解析同拍谓词、append 被 `BRANCH_APPEND_DISPATCH_ENABLE=1'b0` 关死，输入恒 0），ctrl_commit 的 rd/write 元数据亦恒 0——本 mux 实际活路径仅剩 ctrl pseudo-commit 载荷臂 + core commit 直通 + JAL next-PC 修正 + retire count；拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## Scope

`OooCommitOutputMux` owns the combinational boundary between internal commit
sources and the externally visible two-lane commit/retire observation bus.

This module is a writeback/commit helper. It has no state and does not decide
CSR side effects, trap side effects, ROB retirement, or pending-owner cleanup.

## Inputs

- Control pseudo-commit source from `OooControlCommitSequencer`.
- Synthetic lane1 return/branch-append controls from frontend recovery logic.
- Core ROB commit0/commit1 payloads from `OooAluCoreSlice`.
- Core retire count from `OooAluCoreSlice`.

## Output Priority

`commit0` priority:

1. Control pseudo-commit.
2. Synthetic lane1 return before core commit0, or branch-drop replacement.
3. Core commit0, with JAL next-PC adjusted to architectural target.

`commit1` priority:

1. Suppressed when control pseudo-commit is active.
2. Synthetic branch append.
3. Synthetic lane1 return after core commit0.
4. Core commit0 shifted into lane1 when synthetic lane1 return occupies
   commit0.
5. Core commit1 when branch-drop replacement is active.
6. Core commit1 default path.

## Retire Count

`retire_count_o` preserves the legacy expression:

`core_retire_count + ctrl_commit + synth_branch_append + synth_ret_commit -
synth_ret_drop_branch`.

The expression remains width-limited to the existing two-bit output contract.

## Non-Goals

- No ROB entry allocation, wakeup/select, register-file writeback, CSR write, or
  trap redirect policy.
- No state, clock, reset, or ready-valid handshake.
