# v8p DI-3 dual-memory terminal-owner atomic contract

## Claim boundary

This task may promote only `DI-3 pair_matrix` for the current complete RV64
source set.  It proves same-cycle IQ acceptance by two independent registered
memory terminal owners for ordinary integer LL/LS/SL/SS pairs.  It does not
promote DI-1, DI-2, DI-5, OOO-3, OOO-4, the architecture-wide result, or PPA.
OOO-1, OOO-2 and DI-4 may remain GREEN only after their existing evidence is
regenerated against the new complete RTL digest.

The normative interface/state contract is
`npc/rv64/design/specs/ooo-dual-memory-terminal-owners.md`.  In particular,
the second issue owner is not a claim of dual translation, cache admission,
completion, or steady-state memory IPC.

## Required production chain

```text
accepted dispatch payload/full PID
 -> resident IQ per-entry plain-memory capability
 -> packed-age LL/LS/SL/SS pair selection
 -> atomic issue0+issue1 valid/ready fire
 -> two non-fallthrough reservation Q owners
 -> two distinct exact tracker tokens/full PIDs
 -> two captured-data AGU/LSU instances
 -> bank0-age-priority serialized shared request path
```

The second terminal excludes AMO/LR/SC and FP memory operations.  Both banks
must preserve the existing exact memory-owner lease and late-B store authority
rules.  Store-store capture requires two exact SQ owner binds; a single muxed
bind or raw-ROB authorization is a contract failure.

For a current-current memory pair, canonical `issue_fire0`, `issue_fire1`,
`capture0`, `capture1`, `tracker_alloc_fire0` and `tracker_alloc_fire1` are the
same Boolean event.  If either tracker allocation is unavailable, neither
allocation may commit.  The tracker implements atomic dual-valid commit rather
than allowing alloc0 to birth a token while alloc1 stalls.  Applicable SQ binds
are part of the same capture package and are checked by exact onehot association.

Pair ready has a closed root set: resident valid/base-ready and plain-memory
metadata, edge-old empty state of both reservations, recovery gates, current
full-PID queries and dual tracker ready.  No bridge/translation/cache/request/
MIQ/response ready, same-edge consume or free may enter the cone.  Capture has
no downstream fall-through.

Cancellation uses a seven-lane, non-backpressurable collector whose storage is
the same 32-token-indexed pending set as the tracker domain, not a shallow FIFO.
Seven distinct exact-live ingress tuples can be decoded into independent bits
on one edge.  A new legal cancel always owns a live, not-yet-pending token; if
all 32 pending bits are occupied, no such additional live owner can exist.
Thus collector credit is neither required nor allowed in pair ready.  Directed
evidence must still prove simultaneous dual cancel and worst-case seven-lane
ingress conservation under stalled dequeue ports.

## Directed evidence

The durable entry point shall be exactly:

```text
make -C npc/rv64 check-pair-matrix
```

Release and `OOO_ASSERT` profiles independently prove:

- all 15 `PAIR_MATRIX` entries true;
- LL/LS/SL/SS each accepted from two resident IQ entries by one same-edge dual
  fire, never stimulus labels alone;
- eight distinct non-zero-generation full PIDs accepted and consumed exactly
  once across the four memory pairs;
- two reservation valids and two different exact tracker tokens exist on the
  next edge, with captured payload and both AGU results matching the accepted
  immutable scoreboard;
- store-store produces two onehot SQ binds with exact full PID/token identity;
- pair backpressure cannot split, raw capture cannot request on the same edge,
  bank1 cannot pass edge-old bank0, and flush/kill leaves no owner ghost.
- both AGU outputs exist simultaneously while both banks are valid and use
  deliberately different captured base/offset/width/store data; live raw input
  perturbation cannot change either output;
- AMO/LR/SC and FP memory operations cannot select the second memory terminal,
  allocate token1, write bank1 or issue SQ bind1.

The DI-3 evidence record is sibling-preserving and bound to the complete RTL
digest plus exact proof-harness provenance.  The runner must regenerate and
revalidate the previously GREEN OOO-1/OOO-2/DI-4 records after any shared RTL
change; stale sibling evidence may not be copied across `design_id`.

## Required negative sensitivity

Compile-success, activated mutations must reject at least: memory-pair select
serialization, split ready, second reservation tie-off, second owner allocation
tie-off, alloc0-only birth under alloc1 stall, token alias, bank1 raw-payload
fall-through, second AGU tie-off or bank0-result copy, lost/crossed/one-sided
store-store SQ bind, special-memory mis-admission, bank1 age bypass or same-edge
consume bypass, full-PID truncation, cancellation owner leak, and source-checker
vacuity.  Each result records mutant source/image
hashes, compile success, activation witness and the dedicated failure marker.

## Expected architecture result

If and only if all production, directed, mutation and provenance checks pass,
the current GREEN set may become exactly `{DI-3, DI-4, OOO-1, OOO-2}`.
DI-5 and OOO-3 remain RED for explicit source/metric reasons, so architecture
`OVERALL` remains RED and no synthesis/STA/PPA promotion is authorized.
