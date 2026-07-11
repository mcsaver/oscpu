# OooCommitOutputMux Spec

> ⚠️ **状态（2026-07-11 RTL 重读）**：synthetic lane1-ret 相关模块已物理删除；
> branch-append 输入在当前配置下恒 0。mux 活路径是 ctrl pseudo-commit、core commit
> 直通、JAL next-PC 修正与合并观察计数。本文同时登记 `INSTRET-G1`，不把观察计数
> 误写成 CsrFile 已消费的 ISA-precise `minstret` 源。

## Scope

`OooCommitOutputMux` owns the combinational boundary between internal commit
sources and the externally visible two-lane commit/retire observation bus.

This module is a writeback/commit helper. It has no state and does not decide
CSR side effects, trap side effects, ROB retirement, or pending-owner cleanup.

## Inputs

- Control pseudo-commit source from `OooControlCommitSequencer`.
- Branch-append compatibility controls from frontend recovery logic（当前恒 0）。
- Core ROB commit0/commit1 payloads from `OooAluCoreSlice`.
- Core retire count from `OooAluCoreSlice`.

## Output Priority

`commit0` priority:

1. Control pseudo-commit.
2. Core commit0, with JAL next-PC adjusted to architectural target.

`commit1` priority:

1. Suppressed when control pseudo-commit is active.
2. Branch append compatibility source（当前恒 0）。
3. Core commit1 default path。

## Retire Count

当前 RTL 的合并观察计数为：

`core_retire_count + ctrl_commit + synth_branch_append`。

The expression remains width-limited to the existing two-bit output contract.

**CURRENT boundary**：`retire_count_o` 是 output-mux 的合并观察值；
`NpcCoreTop/CsrFile` 当前没有消费它，而是直接消费 raw core count。

**KNOWN GAP INSTRET-G1**：raw core count 按 commit-valid 计数，未过滤 exception；本 mux
虽加 control pseudo-commit，也不能自动修正 raw exception。故无论 raw count 还是当前 mux
输出，都不能在未补 ISA 过滤合同前宣称为 `minstret` 的唯一精确来源。

## Non-Goals

- No ROB entry allocation, wakeup/select, register-file writeback, CSR write, or
  trap redirect policy.
- No state, clock, reset, or ready-valid handshake.
