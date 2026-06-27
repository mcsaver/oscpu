# OooCommitOutputMux Spec

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
