# OooBranchAppendDispatchGate Spec

## Scope

`OooBranchAppendDispatchGate` owns the combinational dispatch-side predicates
for branch target/fallthrough lane1 append and branch prefetch direct dispatch
inside `OooAluFetchCore`.

It does not store fetch, pending, RAS, branch prefetch, or outstanding state. It
does not select dispatch payload data, update PC, consume return-continuation
entries, or modify the branch target cache. The parent remains the owner of
all registers, payload muxes, FIFO seed/enqueue sequencing, and PC/outstanding
state transitions.

## Inputs

- Current lane0 branch dispatch fact and return-continuation match.
- Lane1-ret continuation readiness inputs used for the disabled same-cycle
  return-cont append fast path.
- Outstanding fetch PC, bypass response state, and fallthrough safety.
- Branch target cache hit and direct branch resolve facts.
- Branch prefetch buffer/raw-response match inputs and safety checks.
- Dispatch lane1 readiness and fetch response fire status.

## Outputs

- `return_cont_optional` and disabled `return_cont_attempt`.
- Branch target/fallthrough append candidate, attempt, append, and dispatch
  predicates.
- Fallthrough outstanding match/keep/capture predicates.
- Branch prefetch raw-response match, disabled direct-dispatch predicates, and
  branch-prefetch-hit-to-FIFO predicate.
- `dispatch1_optional` for backend dispatch lane1 optional readiness.

## Invariants

- Return-cont optional is true only when lane0 is a branch and the
  return-continuation buffer matches.
- Return-cont same-cycle append remains disabled; `return_cont_attempt` must be
  zero even when `return_cont_attempt_ready` is true.
- Branch target append candidate requires lane0 branch and branch target cache
  hit.
- Branch fallthrough append candidate requires lane0 branch and a fallthrough
  path that is safe with respect to outstanding fetch response state.
- Fallthrough append is safe when fallthrough itself is safe and either there is
  no outstanding fetch, the current fetch response is bypassed, or the
  outstanding PC already matches lane1 fallthrough PC.
- Branch target/fallthrough append attempts remain disabled until the parent
  deliberately enables the fast path through a future architectural change.
- Append dispatch aliases (`return_cont_dispatch`, `branch_target_dispatch`,
  and `branch_fallthrough_dispatch`) must match their corresponding append
  fire predicates.
- Fallthrough outstanding keep/capture are only true for a fallthrough dispatch
  that matches the outstanding PC; fetch response fire selects capture instead
  of keep.
- Branch prefetch direct dispatch remains disabled; buffer/rsp dispatch attempts
  and dispatch fire must be zero even when their raw readiness conditions are
  true.
- Branch prefetch hit goes to FIFO whenever a hit is available and direct
  dispatch did not fire.
- `dispatch1_optional` is true when any optional lane1 source is a candidate:
  return-cont, branch target append, or branch fallthrough append.

## Non-Goals

- No registers or state transitions.
- No dispatch payload data muxing.
- No branch target cache update or invalidation.
- No branch prefetch buffer storage.
- No ready/valid state ownership for backend dispatch.
