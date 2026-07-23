# V9E XRET-G1 independent review summary

## Verdict

`VERDICT=PASS`. The hash-bound self-contained reviewer reported no unresolved
P0, P1, or P2 defect within the supplied XRET-G1 claim.

## Accepted evidence

- `OooFetchHeadClassifyGate` remains the sole current-mode legality source;
  downstream pending-system and precise-exception owners do not redecode it.
- The seven-case MRET/SRET matrix has a real positive path and covers MRET
  M/S/U plus SRET S+TSR0/S+TSR1/U/M+TSR1.
- The full-core programs make illegal request/commit zero checks non-vacuous,
  retain exact PC/tval, and prove older lane0 retirement next to a lane1
  illegal SRET.
- Eight compile-success local RTL verification variants and two
  verification-only observer configurations are dynamically rejected; the
  reviewer found no listed false-open, false-closed, routing, metadata, or
  zero-observer counterexample that survives them.
- Two canonical replays have byte-identical component hashes, the module
  aggregate is 109/109, XRET-specific tests pass 10/10, and the combined
  semantic audit passes 68/68.
- The first architecture provenance pass is retained as a coverage-gap
  counterexample. The final conclusion uses the corrected pass that also binds
  four optional `source_manifest` sections. Nine directed architecture gates
  are GREEN with no remaining provenance or canonical-reevaluation blocker.

## Residual limitations and exact boundary

- The reviewer evaluated the contract's frozen facts; it did not inspect RTL
  line by line, rerun local commands, or independently calculate artifact
  hashes.
- The listed RTL variants establish sensitivity to those error models, not
  formal completeness or exhaustive privileged-state coverage.
- `XRET-G1=CLOSED` applies only to design
  `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`
  and the stated current-mode paths.
- Full core remains `ARCH_STABLE=GAP` with 44 blockers,
  `PPA=UNQUALIFIED`, and `promotion_eligible=false`.

An implementer-side post-review proof additionally reconstructs the old
Makefile bytes by removing only the exact V9E XRET target block. It is retained
as `evidence/makefile-xret-delta-proof.json` and is not attributed to the
self-contained reviewer.
