# v8p RTL derivation before implementation

## Root cause

`OooIntIssueSelect8` rejects a second resident memory request and
`OooIntBackend` hard-ties the issue1 memory classification, address and request
owner to zero.  The existing tracker already has two allocation ports and the
SQ already allocates two dispatch stores, but production connects only one
memory reservation and one SQ owner-bind port.  Therefore evidence for
LL/LS/SL/SS cannot be created without changing real owner topology.

## Four-stage derivation

1. **Abstract state**: two independently valid reservation owners, each with
   immutable full payload, full ProducerId, kind/token/epoch/tval and one AGU.
   IQ entries retain ALU capability plus a separate plain-memory-terminal
   capability; neither is a program-slot role.
2. **Precedence**: reset/global recovery dominates selective kill, which
   dominates consume, capture and hold.  Pair capture is atomic.  Once
   resident, bank0 is the older memory owner and bank1 cannot consume until
   edge-old bank0 is empty.  Shared request priority remains SQ drain, AMO,
   buffer, bank0, bank1.
3. **Transitions**: accepted IQ pair plus dual tracker credit creates two
   bank owners on one edge.  A bank leaves only through an exact local terminal,
   request/buffer handoff, selective/global cancellation or reset.  Handoff
   keeps the token live; terminal/release ends it exactly once.
4. **Adversarial timing**: dual credit denial, one stale PID, branch/global
   cancel, request stall, local exception, store-store dual bind, bank0 block,
   exact non-zero-generation identity and compile-success mutations distinguish
   real dual ownership from combinational/tie-off/checker-only facsimiles.

The independent review exposed a required refinement: tracker dual allocation
must itself be an atomic package.  Merely ANDing the two IQ ready signals is
insufficient because alloc0 could otherwise commit its own valid/ready birth
while alloc1 stalls.  Production therefore changes tracker event algebra so
dual valid commits both births only under `ready0 && ready1`; standalone alloc0
retains its existing behavior and standalone alloc1 is illegal.

## RTL topology self-review

- The new IQ path reads only resident one-bit metadata; it does not widen
  control decode on the selector critical path.
- Pair ready ends at registered reservation/tracker credit and has no
  bridge/cache/response dependency.
- Both AGUs read captured Q, so neither creates IQ-to-request fall-through.
- Both AGU results are combinationally available at the same time while both
  reservations are full; serialization starts only at the shared request grant.
- Serializing below the AGUs is intentionally conservative and keeps existing
  memory response ordering intact; it is also the explicit reason DI-5 stays
  RED.
- Dual SQ bind is necessary because store-store already owns two dispatch SQ
  entries.  A single bind mux would orphan one token and is rejected.
- Terminal collector capacity must include the second cancellable reservation;
  STORE release remains qualified by SQ authority rather than a generic tagged
  free.
- Packed IQ index is the total age order after compaction; there is no age wrap
  or tie inside this queue.  bank1 uses only edge-old bank0 valid, so same-edge
  bank0 consume/kill cannot create look-through.

This topology satisfies the frozen §2/§3 contract and is ready for independent
counterexample review.  RTL implementation must not begin if that review finds
an unresolved owner, priority, cancellation or non-vacuity hole.
