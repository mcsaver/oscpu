# v8v RTL derivation

## Stage 1 — requirements

- Provide at least four live load entries for the canonical RV64 backend.
- Preserve dual-bank issue and exact full-`ProducerId` transaction ownership.
- Make the load queue an active correctness component, not a duplicated debug ledger.
- Preserve the already implemented SQ physical-byte disambiguation and late-B precise store retirement contract.
- Keep the design point reversible and report OOO-3/PPA status without extrapolation.

## Stage 2a — protocol rules

1. `lq_alloc{0,1}_fire`: dispatch accepts an ordinary integer/FP load
   (`CTRL_LOAD && !CTRL_AMO`) and the selected edge-old LQ slot is ready.  Lane1 never allocates without its accepted
   lane0 prefix.  The payload is `{full ProducerId, ROB index}`.
2. `lq_launch{0,1}`: a bank request fire pushes `MIQ_KIND_LOAD`.  The owner token is mapped through the edge-old
   owner tracker to a full `ProducerId`; the exact live LQ entry is required.  Retry re-launch is idempotent and does
   not allocate a second entry.
3. `lq_query{0,1}`: the existing bank final-PA query must match MIQ tuple, owner tracker and live LQ entry.  The SQ is
   the sole store-ordering oracle.  LQ records `{PA, byte mask, class, allow/forward/replay}`; a later query for the
   same load must reproduce the stored PA/byte mask/class or replay fail-closed.
4. `lq_completion{0,1}`: the two formal WB ports update the exact LQ entry.  Load-specific local and MIQ response
   sources are separately fail-closed by an LQ live/open query before they may reach WB.
5. `lq_terminal{0,1}`: the two lossless memory-owner terminal dequeue ports map LOAD tokens to full `ProducerId`.
   They clear only killed launched tombstones; normal completed loads stay resident.
6. `lq_release{0,1}`: the edge-old ROB head first performs a Q-only lookup with the exact full `ProducerId`.
   `release_ready` requires an edge-old completed entry or a same-cycle exact completion and actively gates ROB
   commit.  Entry free requires `release_valid && release_ready && release_commit` on the real commit edge.

All readiness used by dispatch or issue is Q-only.  Response READY may consume LQ lookup state, but neither response
READY nor SQ disposition feeds request VALID, LQ allocation credit or producer birth credit.

## Stage 2b — state machine

The synthesized encoding uses orthogonal bits rather than a wide enumerated state:

| state | valid | launched | pa_valid | ordered | completed | killed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| FREE | 0 | x | x | x | x | x |
| DISPATCHED | 1 | 0 | 0 | 0 | 0 | 0 |
| WAIT_PA / WAIT_STORE | 1 | 1 | 0/1 | 0 | 0 | 0 |
| READY_OR_FORWARDED | 1 | 1 | 1 | 1 | 0 | 0 |
| DONE_LIVE / FAULT_LIVE | 1 | 0/1 | 0/1 | 0/1 | 1 | 0 |
| DRAIN_KILLED | 1 | 1 | any | any | 0 | 1 |

`replay` clears `ordered` but retains the recorded final PA tuple.  A pre-transport local completion may move directly
from DISPATCHED to DONE_LIVE.  Transport faults may complete without `ordered` only when the existing response fault
fact is asserted; successful memory data requires `ordered`.

## Stage 2c — invariants

1. A full `ProducerId` appears in at most one live LQ entry.
2. A completion is architecturally visible only for the exact live, non-killed producer.
3. A fired memory transaction is drained exactly once even if its producer is cancelled by recovery.
4. An older unresolved/partial/IO store prevents an allow decision; complete ordinary-store coverage forwards the
   youngest older byte for every requested byte.
5. Queue count equals the number of valid entries across simultaneous dual allocation/release/recovery events.
6. No LQ capacity or completion signal creates a combinational ready/valid cycle across IQ, MIQ, bridge or cache.
7. Every live MIQ LOAD owner has exactly one LQ entry with the same full `ProducerId`; a killed tombstone may remain
   after MIQ removal only until its lossless terminal dequeue.
8. `memory data completion -> launched && ordered && exact live LQ hit`; a fault may bypass `ordered` but not identity.
9. A normal LQ entry releases only on exact ROB retirement; WB/transport terminal alone never releases it.
10. Two allocation, completion, terminal or release ports never update one entry with mutually exclusive events;
    simultaneous final-PA queries for one PID fail closed on both query ports.

## Stage 2d — datapath constraints

`OooLoadQueue` stores only full `ProducerId`, ROB index, final PA, byte mask, typed memory class and lifecycle bits.
It stores no operand, destination-register, returned data, write data, exception tval or bridge token.  MIQ remains the
only bank-local transport payload holder.  Stored PA/mask/class are consumed by repeat-query identity checking, so
they are not assertion-only shadow bits.  The LQ full-PID live mask joins the global Q-only producer birth fence.

## Stage 2e — RTL topology

Frozen candidate B topology:

```text
dispatch fire/load decode --dual alloc/full PID--> shared 16-entry OooLoadQueue
                                                     |
reservation Q --LQ exact-open--> bank grant --fire--+--> per-bank MIQ/bridge
                                                     |
bridge final PA --MIQ+tracker+LQ exact--> SQ byte CAM disposition
                                                     |
bank response --MIQ+tracker+ROB+LQ open--> formal WB --done--> LQ
                                                     |
terminal collector --LOAD full PID-----------------> killed drain
ROB dual head lookup --ordinary-load full PID------> LQ ready --active commit permit
ROB dual commit -----------------------------------> exact release fire/free
```

The LQ is behaviorally indispensable at capacity, issue, final-PA query, response completion, recovery drain and
retirement.  Candidate A is rejected for this design point because moving transport scheduling out of two proven
MIQs would expand the change into a dual-bank scheduler rewrite and risk DI-5.

## Stage 3 — implemented RTL

- Added a shared 16-entry `OooLoadQueue` and connected dual dispatch credits, reservation lookup, MIQ launch,
  final-PA/SQ disposition, response authorization, WB completion, lossless terminal drain and dual ROB retirement.
- Split checkpoint restore into raw request, admission hold and accepted apply.  Hold blocks new dispatch, issue,
  reservation capture, MIQ push and request transport.  A fired physical store/AMO retains one exact full-ProducerId
  lease through B, formal WB and lane0 ROB retirement; lane1 is blocked.  Apply waits for lease/SQ-active/DRAIN all
  empty, then recovers Dispatch/ROB/IQ/rename, PRF, FP, execution stages, SQ/LQ, MIQs, reservations and retries and
  reaches both memory request gates through the control flush sequencer.
- Split retire lookup from commit/fire and fed `lq_retire*_permit_w` into the active ROB commit path.
- Added same-PID dual-query fail-closed logic and complete ProducerId live-mask contribution to the global birth
  fence.
- Added a ControlGate fail-closed check and core-glue integration cut proving raw checkpoint restore cannot enter
  `core_local_flush_w` or either memory request gate before accepted apply.

The bank scheduler and returned-data path remain in the existing two MIQs; no returned data is duplicated into LQ.

## Stage 4 — verification closure

- `tb_ooo_load_queue`: lifecycle, wrap recovery, same-PID dual-query conflict and exact retirement.
- `V8S_DUAL_MEMORY_FOCUSED`: unlaunched load/store recovery, launched load tombstone drain, no-reset
  redispatch/retire, retire lookup/commit authority, final-PA retry lifecycle, delayed-OKAY store B, raw-restore plus
  error-B same edge, and AMO physical-write drain with exact request/response/commit/SQ-release/apply counts.
- `tb_ooo_core_top_glue`: forced raw request with apply held low proves local flush and both memory-gate flushes remain
  low; the matching ControlGate bypass mutant compiles/elaborates and is dynamically rejected.
- Required final closure is 9/9 compile-success LQ mutations and F2 integration suite 18/18 after separate accepted
  apply cuts for LQ, Dispatch/ROB/IQ and SQ, retire-permit cut, physical-write apply-guard bypass and pending lane1
  retirement bypass, plus the raw-restore/local-flush bypass.
- Architecture unit suite includes one negative source cut per critical LQ edge, exact OOO-3 provenance replay, and
  stale/missing source-manifest rejection.
- Current implementation has preliminary focused PASS; fresh same-design aggregate and independent v5 review are
  pending.  Until both close: OOO-3=GAP/RED; DI-1/DI-2/OOO-4 and overall remain RED; PPA remains UNQUALIFIED.
