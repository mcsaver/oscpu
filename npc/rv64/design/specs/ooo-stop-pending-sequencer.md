# OooStopPendingSequencer

## Scope

`OooStopPendingSequencer` owns the registered `stop_pending` state previously
held inside `OooAluFetchCore`.

It does not own pending payloads, fetch PC/outstanding, FIFO storage, CSR state,
trap/exit outputs, backend drain tracking, or FPR writes.

## Rules

1. Reset and top-level flush clear `stop_pending`.
2. A direct frontend flush could set `stop_pending` only when a direct branch
   fire occurs without a redirect; with `OOO_DBRANCH_DOMAIN_A=1` (current
   default) this arm writes 0 instead — direct branches no longer stop/drain
   (domain-A migration, #105).
3. Branch-spec checkpoint capture, branch-spec resolve, orphan cleanup, branch
   resolve, pending CSR commit, drain completion, and CSR trap clear
   `stop_pending` with the same old priority.
4. Pending jump resolve keeps `stop_pending` for the dispatch-fire hold case and
   clears it for misaligned, no-link commit, or redirect-after-dispatch cases
   (dead arm: the pending jump owner is formally proven empty under
   `OOO_ROB_WALK_MODE=1`).
5. Pending memory resolve (dead arm: pending mem owner proven empty) and SYSTEM
   CSR dispatch-fire are hold-only priority slots.
6. New decode-side stop requests can set `stop_pending` only when the frontend
   can run and the fetch FIFO has a packet. With `OOO_ROB_WALK_MODE=1` the
   branch/JAL/JALR arms are gated off; the live set sources are IRQ, fetch
   fault, arch trap, exit, SYSTEM (incl. illegal CSR), lane1 barrier, and
   unsupported.
7. CSR trap clear is re-applied as the last assignment priority.

## Invariants

- The module is the single owner of `stop_pending`.
- Hold-only branches must not accidentally clear or set the state.
- A late CSR trap clear wins over same-cycle decode-side capture.
- FP no longer participates in `stop_pending` (FP moved to domain A with its
  own rename/IQ/pipelines); `dispatch0_fp_i` is a retained unused port kept
  only to avoid parent wiring churn.

## Verification

Standalone testbench covers reset/flush, direct-branch no-redirect capture,
branch-spec/orphan/CSR/drain clears, jump hold and clear cases, decode-side
capture cases, and late CSR trap override.
