# OoO serialized-control memory-owner terminal contract

## 1. Scope

This contract binds the pending-system and pending architectural-trap paths to
the exact memory-owner phase in the current RV64 dual-issue OoO core.

- Non-FENCE kinds:
  `CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/IRQ`.
- `pending_arch_trap` uses the same exact terminal boundary before its
  execute-trap request may fire.
- Ordinary `FENCE` keeps the stronger complete-`mem_idle` requirement.

The control plane must distinguish three states that all previously projected
to `mem_idle_i == 0`:

1. a live token still held by an active memory stage;
2. a holder making an exact same-edge terminal transfer;
3. a token retained only by `OooMemOwnerTerminalCollector`.

Only state 1 blocks a non-FENCE pending-system or pending architectural-trap
Cresolve edge.

## 2. Twelve collector ingress lanes

Lane numbering is the LSB-first production order in `OooIntBackend`.

| lane | ingress | edge-old holder and death edge |
| ---: | --- | --- |
| 0 | bank0 response | MIQ0/bridge0 response; exact response fire removes the old owner |
| 1 | bank1 response | MIQ1/bridge1 response; exact response fire removes the old owner |
| 2 | bridge0 active drop | bridge0 active FSM reaches its real drop terminal |
| 3 | bridge0 station drop | non-nokill station is cleared on the flush edge |
| 4 | bridge1 active drop | bank1 equivalent of lane 2 |
| 5 | bridge1 station drop | bank1 equivalent of lane 3 |
| 6 | bank0 reservation terminal | non-STORE local completion, kill, or global cancel |
| 7 | bank1 reservation terminal | bank1 equivalent of lane 6 |
| 8 | legacy buffer cancel | non-STORE buffer holder is cleared |
| 9 | AMO interphase cancel | unsent AMO write phase is cancelled and `mem_pending_q` clears |
| 10 | retry0 cancel | retry0 holder is cancelled rather than repushed |
| 11 | retry1 cancel | retry1 equivalent of lane 10 |

STORE release is intentionally not a thirteenth collector lane.
`sq_owner_release_effective_mask_w` enters the tracker release port only after
the existing resident/pending/ingress checks and same-edge STORE overrides.

No ingress event may be merged, suppressed, or deduplicated. Duplicate,
non-live, tuple-mismatch, pending-duplicate, and same-edge-reenqueue events
remain fail-loud in `OooMemOwnerTerminalCollector`.

`ingress_accept_o` is the only same-edge collector-transfer authority. It is
the combinational result after exact live, kind, epoch, intra-batch duplicate,
edge-old pending, and same-edge dequeue/re-enqueue checks. Raw
`ingress_valid_i` remains an event observation and must never authorize
serialized-control progress.

## 3. Token phase algebra

For one token, let:

- `H`: exact active-holder bit;
- `I`: collector-accepted exact ingress or exact STORE release on the current
  edge;
- `P`: collector pending bit;
- `L`: tracker live bit.

| edge-old phase | `H` | `I` | `P` | `L` | `mem_owner_terminalized` |
| --- | ---: | ---: | ---: | ---: | ---: |
| active, no terminal | 1 | 0 | 0 | 1 | 0 |
| same-edge terminal transfer | 1 | 1 | 0 | 1 | 1 |
| collector-pending only | 0 | 0 | 1 | 1 | 1 |
| full idle | 0 | 0 | 0 | 0 | 1 |
| ingress without holder | 0 | 1 | 0 | 1 | 0 and fail-loud at its source |
| orphan live token | 0 | 0 | 0 | 1 | 0 |

The production reduction is local to `OooIntBackend`:

- the token-indexed active-holder mask includes both MIQs, both bridge
  residency masks, both reservations, legacy buffer, `mem_pending_q`, both
  retries, SQ ownership, and same-edge request handoffs;
- same-edge reservation birth is carried separately as
  `mem_birth_any = mem_issue_res_capture || mem_issue1_res_capture`. The
  token-indexed birth mask remains an observability/assertion fact but does not
  feed the production control reduction;
- terminal transfer is the twelve-lane collector-accepted mask OR exact STORE
  release;
- collector pending and tracker live remain separate inputs.

This scalar factorization is exact under the existing edge-old event algebra:
a birth names an edge-old FREE token, while a terminal transfer names an
edge-old LIVE exact holder. Thus `birth_mask & (live_mask |
terminal_transfer_mask) == 0`. With no birth, the four mask clauses below are
unchanged; with any birth, the explicit scalar inhibit produces the same
required non-terminal result without putting the allocated token value and a
32-bit dynamic one-hot decoder in the global control cone.

`mem_owner_terminalized_o` requires:

1. no same-edge reservation birth;
2. no active holder without a current exact transfer;
3. no transfer without an active holder;
4. no live token outside active, transfer, or collector-pending phase;
5. no collector-pending token outside the tracker live set.

The last transfer is shadowed for one cycle under `OOO_ASSERT`; the transferred
tuple must not remain in any edge-old active holder on the next edge. A legal
new same-edge birth is not the old tuple and is checked separately by the
FREE-versus-LIVE disjointness assertions above.

The holder masks and `mem_owner_terminalized_o` assignment are production
logic outside `OOO_ASSERT`. Only fail-loud checks and their shadow state are
conditionally compiled. Therefore assertion-disabled release simulation and
synthesis consume the same exact predicate as assertion-enabled verification.

## 4. Control consumers

The reduced scalar follows:

`OooIntBackend → OooAluDecodeBackend → OooAluCoreSlice →`
`OooExecuteBackend → OooCoreTopGlue → OooControlPlane →`
`OooPendingDrainResolveGate`.

It has three required consumers:

1. `system_csr_dispatch_valid_o`: CSR Cresolve must not create a ROB owner
   while an older active memory holder remains.
2. `drain_complete_o`: a pending system kind must not generate its non-CSR
   side effect while an active memory holder remains.
3. `drain_complete_o → OooCsrTrapRequestMux.pending_arch_trap_fire_o`: a
   pending architectural trap must not generate its CSR execute-trap request,
   redirect boundary, or pending clear while an older memory holder remains
   active.

Ordinary FENCE additionally requires `mem_idle_i`. Collector-pending-only
tokens therefore do not add up to the collector dequeue latency to the seven
non-FENCE kinds or the pending architectural trap, while FENCE keeps its
complete memory graph barrier.

The drain qualifier is:

```text
serialized_mem_terminal =
  !(pending_system || pending_arch_trap) || mem_owner_terminalized

drain_complete =
  stop_pending && backend_drained && pending_control_ready &&
  !pending_replay_wait && serialized_mem_terminal &&
  (!pending_system_fence || mem_idle)
```

This equation preserves unrelated drained control cycles: if neither
serialized owner is present, an active memory holder does not become a new
global drain condition.

## 5. Verification obligations

- Preserve a pre-fix RED for CSR dispatch, non-CSR system drain, and pending
  architectural-trap drain/fire.
- Observe active, same-edge transfer, collector-pending-only, and full-idle
  phases through the production `OooIntBackend` masks.
- Observe wrong-kind/epoch, same-token duplicate, pending duplicate, and
  same-edge dequeue/re-enqueue as rejected collector transfers without
  weakening the existing fail-loud assertions.
- Compile and run the focused backend and collector with `OOO_ASSERT` both
  enabled and disabled; both configurations must observe the same production
  scalar.
- Observe bank0 and bank1 same-edge reservation births forcing the production
  scalar low; reject a compile-success assertion-disabled variant that deletes
  the scalar birth inhibit. Also fail loud if a birth token overlaps the
  edge-old live or accepted-transfer set.
- Observe exact SD/FSD SQ release terminalizing the final STORE holder.
- Reject independent compile-success variants that:
  remove the non-CSR term, remove the CSR term, or replace the exact phase
  predicate with full `mem_idle`; separately reject raw-ingress transfer
  authority, raw-valid collector acceptance, and an assertion-only production
  predicate in an `OOO_ASSERT=0` configuration.  The architectural-trap
  integration additionally rejects a missing arch-trap term, unconditional
  owner gating, and deletion of the ordinary-FENCE full-idle term.
- Bind `OooPendingDrainResolveGate.drain_complete_o` through
  `OooCsrTrapRequestMux` and observe architectural-trap fire, execute-trap
  valid/payload, and privileged predictor boundary.
- Bind the production run gate, pending birth arbiter, trap/system/stop
  sequencers, drain gate and request mux to real `CsrFile`; count every raw
  request without de-duplication and require C0 fire, C1 owner/stop clear,
  one CsrFile sample and C2 no-repeat.
- A same-edge ROB-head exception must suppress lower-priority pending
  architectural-trap and pending SYSTEM request outputs even though CsrFile
  retains its final `mem > ex > irq` fail-closed selector.
- Architectural-trap birth must be exact-one against head0/lane1 SYSTEM and
  IRQ birth.  Once the architectural-trap holder is registered, the
  `stop_pending_busy → !can_run` contract must reject ECALL/IRQ/xRET/CSR/FENCE
  capture until the existing transaction terminalizes.
- Run collector, recovery, control, module aggregate, and system functional
  gates under one current design identity.
- V10A closes post-fire exactly-once for the pending architectural-trap
  holder and its ECALL/IRQ/xRET/CSR/FENCE overlap boundary.  This contract
  still does not close the full post-fire lifecycle of every pending SYSTEM
  kind, simulation exit, full Linux flag-on, architecture-stable, or PPA.

## 6. V15R implementation record

V15R factors the same-edge reservation-birth term out of the token-indexed
active-holder reduction.  Production logic uses
`mem_issue_res_capture_w || mem_issue1_res_capture_w` as a scalar hard inhibit
of `mem_owner_terminalized_o`; the token-indexed birth mask remains only for
assertion observability.  No interface, state, allocator cursor, handshake,
flush, exception, memory-order, or terminal-transfer authority changes.

The equivalence basis is the edge-old state partition in
`OooMemOwnerTracker`: allocation selects FREE, while release/terminal transfer
requires LIVE.  Focused V8W/V11M runs pass with `OOO_ASSERT` on and off, and an
assertion-disabled compile-success mutant deleting the scalar inhibit is
rejected at the intended observation.  A same-configuration 5 ns mapped A/B
improves WNS, TNS and area proxy, but remains 40/40 timing-violating; vectorless
power is unqualified.  This record therefore authorizes retaining the change
as an engineering candidate only.  It does not constitute canonical-current,
PPA, architecture-stable, L2, L3, or Ubuntu signoff.

## 7. V15S owner-set emptiness factorization

The complete-memory-idle predicate needs only the Boolean fact that the
registered owner-token set is empty.  It must not consume the arithmetic
`OooMemOwnerTracker.live_count_o` popcount merely to compare it with zero.
Production `OooIntBackend` therefore derives
`v15s_mem_owner_any_live_w = |mem_owner_live_mask_w` and uses its inverse in
`mem_idle_o`.  The count remains present for conservation assertions,
diagnostics and testbench observability.

This is a same-cycle combinational factorization over the same Q-only
`live_q` state.  It does not change allocation/free authority, token metadata,
terminal collection, memory ordering, flush, CSR retirement or frontend
redirect policy.  With `OOO_ASSERT` enabled, mask emptiness and count zero are
required to agree on every active edge.  Focused validation must observe a
live owner holding `mem_idle_o` low and must reject a compile-success variant
that constantizes the owner-exists reduction.  PPA qualification remains a
separate same-configuration mapped A/B decision.
