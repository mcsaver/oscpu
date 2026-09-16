# OooBranchResolveRecoveryGate Spec

> ⚠️ **状态(2026-07-13 T3E 刷新)**:模块是 F2 误预测恢复的活中枢,但只剩单臂活——mode=1(`OOO_ROB_WALK_MODE=1'b1`)下 untracked 判据被编译期 mux 收紧为"仅后端显式 mispredict"(`branch_resolve_untracked_raw = rob_walk_mode ? (resolve_valid && mispredict && !misaligned) : …`,`OooBranchResolveRecoveryGate.v:54-66`),`branch_resolve_untracked_redirect` 是唯一活 redirect 输出;pending match/tracked redirect/branch-spec checkpoint-capture/restore/spec-redirect 与 direct-branch-wait untracked 各臂因 pending_branch/branch_spec_active/快解析恒 0 而全死。T3E 要求 checkpoint-capture 在本模块生产端显式受 `!rob_walk_mode` 门控，不能只依赖跨层级 pending 常量传播；拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## Scope

`OooBranchResolveRecoveryGate` owns the combinational branch resolve recovery
predicates used by `OooFrontend` (formerly `OooAluFetchCore`).

It does not store branch state, update BPU/RAS tables, modify fetch PC state, or
own the direct branch wait buffer. The parent remains the owner of pending
branch state, branch speculation checkpoint state, direct branch wait storage,
trap squash state, and fetch outstanding/discard state.

## Inputs

- Pending branch owner state: stop pending, pending branch valid, dispatched,
  pending branch PC, and branch-prefetch match.
- Branch resolve payload: valid, PC, next PC, misaligned, and the backend
  explicit mispredict flag (`core_branch_resolve_mispredict_i`, the sole
  untracked-redirect trigger in ROB-walk mode).
- Branch speculation state: checkpoint pending, active, predicted PC, memory
  idle, and pending-load branch dependency.
- Backend quiet sources: execute lane valid and memory response ready flags.
- Direct branch wait state and same-cycle direct branch resolve valid.
- Trap redirect squash.

## Outputs

- Pending branch resolve PC match and qualified pending match.
- Tracked branch resolve redirect.
- Backend-execute quiet and branch-spec checkpoint capture.
- Branch-spec resolve valid, predicted-target match, restore, and redirect.
- Direct-branch-wait resolve match and untracked-direct-branch status.
- Untracked branch resolve status and untracked redirect.

## Invariants

- `branch_resolve_pending_pc_match_o` only checks branch resolve valid and PC
  equality with the pending branch PC.
- `branch_resolve_pending_match_o` additionally requires stop-pending,
  pending-branch, and pending-branch-dispatched ownership.
- Tracked branch redirect requires a qualified pending match, non-misaligned
  resolve, no branch-prefetch match, and no trap redirect squash.
- Branch-spec checkpoint capture requires checkpoint pending, stop-pending,
  pending branch ownership, backend execute quiet, and either memory idle or a
  pending-load branch dependency.
- Branch-spec checkpoint capture is a legacy mode-0 mechanism.  In ROB-walk
  mode it is structurally constant zero inside this module, even if impossible
  legacy owner inputs are driven high in an isolated unit test.  This local
  constant is required because synthesis may preserve hierarchy and therefore
  cannot be trusted to propagate the parent-level `pending_branch=0` proof.
- Branch-spec restore is true when branch-spec resolve is valid and the
  resolved next PC does not match the stored predicted PC. Misaligned resolves
  can request restore but cannot produce a redirect.
- Direct-branch-wait untracked requires wait-buffer PC match, no pending-branch
  match, and no same-cycle direct branch resolve.
- Generic untracked resolve is suppressed when branch-spec resolve is valid
  (legacy mode-0 arm only).
- In ROB-walk mode (`OOO_ROB_WALK_MODE=1`), untracked resolve is exactly
  "resolve valid, explicit mispredict, non-misaligned"; wait-buffer/pending
  matches are ignored by this arm.
- Trap redirect squash masks redirect outputs only; it does not erase the raw
  resolve match predicates.

## T3E timing isolation contract

The 2026-07-13 fresh 5 ns netlist reduced the prior 109 loop report to 16, but
all remaining loops shared this otherwise unreachable feedback:

`long-op response -> full WB/execute_valid -> backend_execute_quiet ->
checkpoint_capture -> issue block -> issue/branch resolve -> long-op kill`.

The sole legal cut is configuration-local and combinational:

```text
checkpoint_capture = !OOO_ROB_WALK_MODE && legacy_capture_predicate
```

No ready/valid handshake, long-op kill timing, full-WB arbitration, issue
priority, redirect priority, or register boundary changes in this slice.  The
mode-0 legacy predicate remains bit-for-bit unchanged.  Acceptance requires a
unit RED that drives every legacy capture input true under mode 1, followed by
a fresh netlist with zero combinational loops; an RTL-only green result is not
sufficient to claim closure.

## Non-Goals

- No registers or FIFO storage.
- No BPU/RAS update policy.
- No fetch request mux priority.
- No trap/interrupt CSR side effects.
