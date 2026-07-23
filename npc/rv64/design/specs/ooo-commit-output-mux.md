# OooCommitOutputMux Spec

> **状态（2026-07-21 V9C）**：synthetic lane1-ret 相关模块已物理删除；
> branch-append 输入在当前配置下恒 0。mux 活路径是 ctrl pseudo-commit、core commit
> 直通、JAL next-PC 修正与唯一 ISA-retirement 计数。`INSTRET-G1` 已关闭：
> 最终计数只由仲裁后的两条 commit lane 产生并过滤 exception，`NpcCoreTop/CsrFile`
> 消费同一个最终值；全核程序级事件计数、CsrFile 边沿增量与 3/3 可编译 RTL
> 验证变体均绑定当前 `design_id`。

## Scope

`OooCommitOutputMux` owns the combinational boundary between internal commit
sources and the externally visible two-lane commit/retire observation bus.

This module is a writeback/commit helper. It has no state and does not decide
CSR side effects, trap side effects, ROB retirement, or pending-owner cleanup.

## Inputs

- Control pseudo-commit source from `OooControlCommitSequencer`.
- Branch-append compatibility controls from frontend recovery logic（当前恒 0）。
- Core ROB commit0/commit1 payloads from `OooAluCoreSlice`.
- Core ISA-retirement count from `OooAluCoreSlice`，仅用于 writeback 边界断言，
  不参与本 mux 的最终计数逻辑。

## Output Priority

`commit0` priority:

1. Control pseudo-commit.
2. Core commit0, with JAL next-PC adjusted to architectural target.

`commit1` priority:

1. Suppressed when control pseudo-commit is active.
2. Branch append compatibility source（当前恒 0）。
3. Core commit1 default path。

## Retire Count

当前 RTL 的唯一计数为：

`popcount({commit1_valid && !commit1_exception,
commit0_valid && !commit0_exception})`。

这里的 commit 字段是 mux 优先级已经选定的最终输出，因此 ctrl commit 覆盖 core、
或未来 synthetic lane 覆盖 core lane1 时，被隐藏的源不会重复进入计数。显式
AND/XOR 两位 popcount 结构保证值域严格为 0..2，不可能产生 3 或发生多源加法溢出。

**CURRENT boundary**：`retire_count_o` 同时是外部观察值与
`NpcCoreTop/CsrFile.instret_inc_i` 的唯一系统输入。

`OooAluCoreSlice` 的 core count 也按 `valid && !exception` 过滤；`OooWriteback`
在 `OOO_ASSERT` 下逐拍核对 core count 与 core lanes、最终 count 与最终 lanes，防止
ROB dequeue 与 ISA retirement 再次混义。异常 ROB entry 仍以 commit-valid 出队并携带
trap payload，只是不计入 ISA retirement。

## Verification Closure

- `make -C npc/rv64 check-instret-retirement` 运行同一全核 Sv39 程序及三个 focused TB。
- 程序级确定事件清单为：异常 lane 2/2 零增量，MRET 1、SRET 6、SFENCE.VMA 1，
  控制伪提交 8/8 精确单增量，CsrFile 边沿增量检查 1052 次。
- 三个 current-source RTL 验证变体分别移除异常过滤、改用 pre-mux lane0 计数、让
  CsrFile 改接 core-local count；三者均重新编译成功并被最终计数或 CsrFile 边沿检查拒绝。
- 证据：`../../eval/ppa/evidence/instret-retirement-current.json`（仓库根入口：
  `npc/rv64/eval/ppa/evidence/instret-retirement-current.json`）。

## Non-Goals

- No ROB entry allocation, wakeup/select, register-file writeback, CSR write, or
  trap redirect policy.
- No state, clock, reset, or ready-valid handshake.
