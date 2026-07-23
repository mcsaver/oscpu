# RV64 v8v / OOO-3 memory-ordering contract

## Design state

- state: `v4_evidence_gap_repair_implemented_candidate_refresh_pending`
- live design-id: pending fresh canonical source binding; the pre-v3 evidence digest is stale after RTL/spec/TB/checker edits.
- current gate vector: `OOO-3=GAP/RED` until fresh same-design evidence and independent v5 review; the last bound
  predecessor vector was `DI-3/DI-4/DI-5/OOO-1/OOO-2=GREEN`, while `DI-1/DI-2/OOO-4/OVERALL=RED`.
- PPA status: `UNQUALIFIED`; this checkpoint cannot enter a Pareto archive or replace a baseline.

## Completion definition

This run closes one reversible OOO-3 design point.  It must add a real, at-least-four-entry load queue to the
canonical dual-memory backend, bind it to complete `ProducerId` ownership, and make its lifecycle participate in
load admission/completion/recovery rather than acting as an observational shadow.  Existing per-bank MIQs remain
transport queues unless the frozen topology explicitly transfers load ownership out of them.

The run is complete only when:

1. the load-queue protocol, state transitions, invariants and RTL topology are frozen before RTL edits;
2. focused positive tests cover non-alias bypass, alias forward/replay, two-bank ownership, ROB wrap and recovery;
3. compile-success mutations prove the load queue is behaviorally connected and not checker-only scaffolding;
4. existing SQ late-B semantics remain intact: no physical write before exact ROB-head launch eligibility, one write
   acceptance, one B terminal, no retirement before B, precise B error, and drain-through-recovery;
5. lint/style/contract and relevant module/integration gates pass on the same source digest;
6. the architecture result is reported exactly.  OOO-3 may become GREEN only if every normative metric has
   source-bound directed evidence; otherwise this remains an OOO-3 intermediate checkpoint.

## Closed root cause

The initial architecture audit reported OOO-3 RED because the source inventory had no retire-resident
`OooLoadQueue` and the directed manifest had no `memory_ordering` record.  The implemented design now instantiates a
shared 16-entry LQ as an active dispatch/issue/final-PA/response/recovery/retirement component; the same-design
directed manifest contains a hash-bound `memory_ordering` record.  Bank-local MIQs remain transport FIFOs and are not
relabelled as architectural LQ state.

The v2 independent review then found a recovery-domain split: `checkpoint_restore_i` cleared LQ/MIQ/reservation
while ROB/IQ survived, so an unlaunched load could lose its LQ issue authority permanently.  The repair makes
checkpoint restore a backend-wide recovery edge for Dispatch/ROB/IQ/rename, integer PRF, FP backend and SQ.  An
unlaunched load/store clears with its ROB owner; an already fired transaction remains only as an LQ/SQ tombstone
until the bridge reports its exact terminal.

The v3 independent review found the remaining P1: a physical store could already have fired and set SQ
`request_sent`; destructive restore then removed its ROB owner, so B could no longer lead to the matching ROB
retirement/SQ release.  The repair separates raw request, admission hold and accepted apply.  A bank0 physical
store/AMO request owns an exact full-`ProducerId` lease through B, formal WB and lane0 ROB retirement.  While restore
is pending, new dispatch/issue/request is blocked, lane1 retirement is blocked, and only that exact ROB-head owner
may retire in lane0.  Apply occurs exactly once only after the lease, SQ active-write mask and DRAIN owner are all
empty, then recovers the whole backend and broadcasts the accepted pulse to both memory request gates.

The v4/v4.1 independent review accepted that RTL protocol, then found an evidence-sensitivity gap: the canonical
OOO-3 source/provenance inventories omitted `OooCoreSliceControlGate`, `OooMemInflightQueue` and
`OooMemOwnerTracker`, and no parent mutation proved that raw restore could not bypass accepted apply through
`core_local_flush_o`.  The repair adds those RTL sources, the core-glue TB, a fail-closed ControlGate source check,
and a compile-success parent mutation dynamically rejected by the dual memory-gate integration oracle.

## Frozen topology decision

The bounded topology review selected candidate B: keep the two per-bank MIQs as transport FIFOs and add one shared,
retire-resident `OooLoadQueue`.  The main-agent source census resolved the reviewer's remaining integration unknowns:

- the canonical ROB has 16 entries and can retire two instructions per cycle;
- the bridge final-PA face and SQ already provide two independent physical-byte queries;
- replay is pre-cache-fire: the MIQ owner moves into a bank-local retry holder and later re-enters an MIQ;
- formal architectural completion is limited to the two existing WB ports;
- the lossless memory-owner terminal collector already serializes response/drop/cancel terminals into two exact
  full-owner dequeue events.

The LQ therefore defaults to 16 entries, matching the maximum number of resident ROB loads.  A four-entry syntax-only
queue is rejected because it would fill after two dual-load cycles and invalidate the existing DI-5 sustained path.
Allocation occurs at dispatch, where both program order and the complete ROB-generated `ProducerId` are available.
This also covers local SQ-forward and precise-misalignment completion paths that never allocate an MIQ entry.

## Interface contract freeze

| contract | non-negotiable condition |
| --- | --- |
| handshake | dispatch allocation is `valid && ready`; MIQ launch is exact LQ-hit-qualified; final-PA query payload remains stable until the bridge consumes one disposition; no response-ready to request-valid loop |
| backpressure | 16-entry LQ capacity is a Q-only dual-credit input to dispatch; no same-cycle retire borrowing enters dispatch ready; full LQ cannot silently accept either load lane |
| flush/recovery | `checkpoint_restore_i` is a request; raw-or-pending `checkpoint_restore_hold_w` blocks new dispatch/issue/request; `checkpoint_restore_apply_w` is the sole backend-wide recovery edge across ROB/IQ/rename/PRF/FP/execution/MIQ/retry/SQ/LQ and both memory gates |
| irrevocable write | a physical store/AMO `req_fire` acquires one full-`ProducerId` lease until matching lane0 ROB retirement; B/formal-WB/SQ release remain live during hold, lane1 cannot retire, and apply requires lease/SQ-active/DRAIN all empty |
| exception order | local or transport load faults use the existing formal WB path, set the exact LQ entry done, remain resident, and release only on the matching ROB retirement/recovery event |
| memory order | final-PA SQ query returns exactly one of allow/forward/replay; LQ records PA/byte-mask and disposition; unknown/partial/IO older-store coverage cannot authorize memory data |
| ownership | allocation, issue, query, completion, terminal drain and release compare the full `ProducerId`; simultaneous final-PA queries for one PID fail closed on both ports; ROB-index-only matching is forbidden |
| retirement | ROB head lookup is Q-only and actively consumes LQ `ready`; only a real load commit coincident with `ready` frees the entry |

## Same-cycle priority

Per entry, edge-old identity is resolved before any new allocation.  Priority is:

1. reset;
2. exact retirement commit/fire or killed terminal drain;
3. recovery kill (`launched && !terminal` becomes a tombstone; otherwise clear);
4. formal completion;
5. final-PA disposition update;
6. MIQ launch;
7. allocation into an edge-old free entry.

Raw request and pending state suppress new dispatch, issue and request transport without clearing edge-old holders.
For a live physical-write lease, B/formal WB may complete and only the exact owner may commit in lane0; lane1 is
blocked.  The following safe edge emits accepted apply and performs destructive recovery.  An exact load terminal
concurrent with apply drains and clears the killed entry in that edge.  A completion concurrent with ROB head lookup
may make `ready` true, but free still requires the real commit edge.  The allocator uses only edge-old free entries,
so an old PID is always matched before a slot can be reused.

## Current evidence checkpoint

- canonical runner: `make -C npc/rv64 check-memory-ordering`;
- focused profiles: shared LQ, SQ, default backend, `V8S_DUAL_MEMORY_FOCUSED` backend, core-glue raw/apply isolation,
  and 64-cycle sustained dual memory issue;
- preliminary focused result: default/core-glue and dual-backend simulations pass, including delayed-OKAY store B,
  same-edge error B, AMO write drain, exact request/response/commit/SQ-release/apply counts and no-reset redispatch;
- required fresh result: 11/11 OOO-3 metrics, 9/9 compile-success LQ mutations and 18/18 F2 parent mutations,
  including independent cuts of accepted apply recovery, ROB retire permit, irrevocable-write guard and pending
  lane1 retirement block plus the raw-restore/local-flush ControlGate bypass; the canonical closure contains 46
  source files and 61 provenance files, including the focused mutation-reconstruction unit test and persisted
  ControlGate mutation rejection log;
- architecture boundary until refresh and v5 review: OOO-3=GAP/RED, overall=RED, PPA=UNQUALIFIED.

## Out of scope

- DI-1/DI-2 frontend and width-continuity closure;
- OOO-4 global speculation/recovery closure beyond the load-queue recovery boundary;
- shared raw-AXI sustained miss bandwidth, cache capacity changes, or a new PPA promotion claim;
- weakening any architecture threshold, evidence binding, or existing ProducerId holder rule.
