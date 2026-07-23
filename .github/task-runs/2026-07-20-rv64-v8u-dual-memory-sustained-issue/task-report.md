# v8u/F4 task report

## Current status

- Contract: frozen and implemented.
- Root cause: bank-local final-PA SQ query and synchronous D-cache lookup inserted a one-cycle
  initiation bubble; an initial response-READY reuse also created a delta-cycle feedback SCC.
- RTL implementation: PASS on the canonical 144-file RTL digest
  `sha256:11a8f520a2df3f2e5a8e51e2e63ccab07d2dd842267628bf58d4a63370482fbf`.
- Permanent command: `make -C npc/rv64 check-dual-memory-sustained-issue`.
- Final run: `v8u-f4-20260720T162308Z-1289228` PASS.
- Independent no-tools rereview: DI-5 local PASS with bounded evidence; no unresolved DI-5 blocker.
- Architecture: DI-3/DI-4/DI-5/OOO-1/OOO-2 GREEN; DI-1/DI-2/OOO-3/OOO-4 and OVERALL RED.
- PPA: `UNQUALIFIED`; no synthesis/STA/Power promotion is claimed.

## Implemented transaction DAG

- IQ exposes registered entries 0/1 on a Q-only pair-peek face while both ordinary-memory
  reservations are occupied. The face does not produce ordinary issue valid and does not read
  downstream READY.
- Only exact same-edge consumption of both edge-old reservation owners may form atomic
  `pop2 + alloc2`. Partial consume performs no singleton turnover; the old pair drains before the
  next pair captures.
- MIQ exports exact current/next head state including wrap and effective-kill. The bridge exposes a
  held response query from registered state, while lookup, promotion and pop are qualified only by
  response fire. This removes READY from the query candidate cone.
- Both banks retain separate AGU, MIQ, DTLB, physical SQ query, D-cache admission and completion
  paths. Only the already-verified raw AXI miss/PTW/store/A-D fabric is shared.

## Verification evidence

- Same-design predecessors F0/F1/F2 and pair-matrix all rerun PASS before DI-5 publication.
- The steady system trajectory contains exactly 64 rows, 64 dual-issue cycles and memory issue IPC
  2.000. Both banks record `64,64` at AGU, translation, physical SQ query, cache admission and
  completion.
- Directed evidence covers READY masks `00/01/10/11`, valid/payload hold, full ProducerId, reverse
  mapping, ROB wrap age, one-credit backpressure, dual-EX full hold, selective kill, flush exact
  drop, partial consume and A/B/C consecutive hot responses.
- Seven compile-success/elaboration-success mutations are dynamically rejected. They cut response
  fire qualification, accept partial turnover, dequeue without capture, couple query visibility to
  READY, bypass lookup READY gating, pop only entry0, or expose pair entry1 as regular issue1. One
  mutation recreates the feedback SCC; the baseline reports no `UNOPTFLAT`.
- DI-5 evidence binds the exact command, 18-file proof provenance, complete RTL digest and artifact
  SHA-256 values. Architecture source gates also reject five actual second-face cuts.

## Independent review and residual boundary

- The first bounded review returned `PASS_WITH_EVIDENCE_BOUNDARY` because its supplied material did
  not enumerate full-PID, READY matrix, partial-turnover, wrap and mutation-property evidence.
- A versioned v2 contract supplied those existing markers and mappings. The rereview resolved all
  DI-5 blockers and returned local PASS with medium-high confidence; result is recorded in
  `independent-review-v2.md`.
- Remaining hardening is non-blocking for this local DI-5 slice: cross-product stress combining ROB
  wrap, asymmetric READY, replay, kill/flush and turnover; explicit PID-bit corruption mutations;
  multi-generation-wrap randomized backpressure; and per-transaction steady scoreboarding.
- Shared raw AXI sustained-miss throughput, global memory ordering, global recovery and formal PPA
  qualification remain separate RED gates. The parent optimization goal stays active.

## AI workflow integration

The task uses the `rv64-hardware-professional` wording profile: natural language preserves RV64,
RTL, pipeline, transaction, timing, cache, verification and PPA semantics. It does not introduce a
keyword blacklist, lexical rejection, tool restriction or capability change. Both reviewer rounds
used validated, SHA-bound, self-contained-no-tools task contracts.
