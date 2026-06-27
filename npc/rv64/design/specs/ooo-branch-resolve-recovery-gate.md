# OooBranchResolveRecoveryGate Spec

## Scope

`OooBranchResolveRecoveryGate` owns the combinational branch resolve recovery
predicates used by `OooAluFetchCore`.

It does not store branch state, update BPU/RAS tables, modify fetch PC state, or
own the direct branch wait buffer. The parent remains the owner of pending
branch state, branch speculation checkpoint state, direct branch wait storage,
trap squash state, and fetch outstanding/discard state.

## Inputs

- Pending branch owner state: stop pending, pending branch valid, dispatched,
  pending branch PC, and branch-prefetch match.
- Branch resolve payload: valid, PC, next PC, and misaligned.
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
- Branch-spec restore is true when branch-spec resolve is valid and the
  resolved next PC does not match the stored predicted PC. Misaligned resolves
  can request restore but cannot produce a redirect.
- Direct-branch-wait untracked requires wait-buffer PC match, no pending-branch
  match, and no same-cycle direct branch resolve.
- Generic untracked resolve is suppressed when branch-spec resolve is valid.
- Trap redirect squash masks redirect outputs only; it does not erase the raw
  resolve match predicates.

## Non-Goals

- No registers or FIFO storage.
- No BPU/RAS update policy.
- No fetch request mux priority.
- No trap/interrupt CSR side effects.
