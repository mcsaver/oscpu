# V9R SQ-query retry C0 handoff contract

## Scope

- RTL: `OooIntBackend` bank0/bank1 SQ-query retry READY/capture and
  `OooMemAxiBridge` `S_SQ_QUERY` retry fire.
- Cycle boundary: ROB edge-old full-flush pregrant (`C0`) through typed
  full-flush application (`C1`).
- Required behavior: C0 holds the bridge/MIQ owner in its registered location;
  retry transfer resumes only after the barrier is removed.

## Positive evidence

1. Both backend banks keep an exact replay query resident for a forced C0 edge.
2. A real translated page-end load completes as the ROB exception head;
   enabling commit readiness naturally raises a TRAP C0 barrier while a younger
   bank1 replay query is present.
3. The bridge holds `S_SQ_QUERY` state/token during C0 and completes the normal
   nonterminal handoff after barrier release.

## Counterexamples

Each variant must compile and elaborate successfully, then be rejected by the
new cycle-local assertion:

- bank0 retry READY ignores C0;
- bank1 retry READY ignores C0;
- bridge retry fire ignores C0.

## Evidence binding

- The task uses the same complete RTL source-set design-id as the architecture
  hard-gate evaluator.
- The machine summary binds both baseline logs and compiled images, every
  mutated RTL image/log/return code, the exact V9R source set and its SHA-256.
- `CONTROL-EVENT-G1` may close only when the independent architecture validator
  accepts both the complete V9O evidence index and this V9R summary under one
  current design-id.

## Boundary

This task does not create new architectural owner state, does not gate
registered AXI VALID, and does not qualify PPA or architecture freeze.
