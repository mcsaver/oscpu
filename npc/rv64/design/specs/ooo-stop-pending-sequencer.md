# OooStopPendingSequencer

## Scope

`OooStopPendingSequencer` owns the registered `stop_pending` state previously
held inside `OooAluFetchCore`.

It does not own pending payloads, fetch PC/outstanding, FIFO storage, CSR state,
trap/exit outputs, backend drain tracking, or FPR writes.

## Rules

1. Reset and top-level flush clear `stop_pending`.
2. A direct frontend flush can set `stop_pending` only when a direct branch fire
   occurs without a redirect.
3. Branch-spec checkpoint capture, branch-spec resolve, orphan cleanup, branch
   resolve, pending CSR commit, drain completion, and CSR trap clear
   `stop_pending` with the same old priority.
4. Pending jump resolve keeps `stop_pending` for the dispatch-fire hold case and
   clears it for misaligned, no-link commit, or redirect-after-dispatch cases.
5. Pending memory resolve and SYSTEM CSR dispatch-fire are hold-only priority
   slots.
6. New decode-side stop requests can set `stop_pending` only when the frontend
   can run and the fetch FIFO has a packet.
7. CSR trap clear is re-applied as the last assignment priority.

## Invariants

- The module is the single owner of `stop_pending`.
- Hold-only branches must not accidentally clear or set the state.
- A late CSR trap clear wins over same-cycle decode-side capture.
- The parent `OooAluFetchCore` remains the owner of FPR file side effects.

## Verification

Standalone testbench covers reset/flush, direct-branch no-redirect capture,
branch-spec/orphan/CSR/drain clears, jump hold and clear cases, decode-side
capture cases, and late CSR trap override.
