# R4-P0 load-hit control-cone timing recovery contract

Status: ACTIVE CANDIDATE CONTRACT / NOT PROMOTED

Parent checkpoint: `r4-s0-posttranslate-memory-semantics`

## Objective

Recover the R4-S0 exact-5ns promotion reserve from `+0.059167784 ns` to at
least `+0.10 ns` without adding a load-hit pipeline stage, deleting any
post-translation memory semantics, changing fixed-region counters, or
exceeding the R3.6 `minimum_area_efficiency_ratio=0.999` ceiling.

The measured regression is not a classifier-sideband timing arc.  All R4-S0
top-40 paths are:

```text
D-cache SRAM tag -> tag compare -> lookup-hit fusion
-> MIQ response/pop -> WB1 source/write-valid -> PRF write decode
```

The classifier/response/SQ cacheability sideband ends in SQ state and has no
combinational intersection with this cone.  Removing it is therefore both
architecturally forbidden and technically misdirected.

## Candidate set

| Candidate | Change | Expected timing | Area risk | Dynamic-power risk |
| --- | --- | ---: | ---: | ---: |
| P0-A | Derive GPR write-valid from per-source one-hot grant and source-local `pdest!=0`, rather than after the generic WB pdest mux | +0.10..0.25 ns | +50..200 | <+0.03% estimate |
| P0-B | Explicit fixed-group, balanced 49-bit lookup tag equality; no new register | +0.04..0.12 ns | +150..500 possible | +0.02..0.08% estimate |
| P0-AB | A+B | enough margin if estimates compose | combined ceiling applies | diagnostic only until activity-qualified |

These estimates are hypotheses, not evidence.  Mapped synthesis/STA decides.

## Frozen semantics

- No interface, FSM, valid/ready/fire, response priority, WB payload, ROB,
  exception, SQ, translation, cache-maintenance, flush or retirement change.
- `lookup_hit_o` remains the decision cycle immediately following the 1RW
  synchronous lookup issue.  No latency/II trade is allowed.
- WB source selection remains the existing priority and one-hot grant.  Only
  the GPR side-effect enable may be distributively factored.
- p0 remains suppressed for FP load, store probe/drain and any non-GPR source.
- All R4-S0 final-PA/PMA/PBMT and B-terminal invariants remain mandatory.
- Architecture gates remain RED until S1/S2; P0 cannot become an architecture
  seed regardless of its P/A result.

## Non-vacuity and functional gates

- P0-A must compare the new expression cycle-for-cycle with the frozen legacy
  `wb_valid && muxed_pdest!=0` expression under `OOO_ASSERT`, assert WB source
  one-hot, and provide a deliberate mismatch mutation.
- P0-B must compare the balanced tag result cycle-for-cycle with the frozen
  Verilog equality under `OOO_ASSERT` and provide a deliberate mismatch
  mutation.
- Focused backend/D-cache tests, full `102/102`, lint/style and fresh simulator
  build must pass before any PPA run.
- Fixed-region CoreMark and Dhrystone counters must remain bit-exact with S0;
  a promotion-grade rerun additionally requires image-inclusive runtime
  pre/post binding and A-B-B-A-A-B ordering.

## PPA acceptance

Parent area is `1,606,423.28`.  The strict R3.6 area-efficiency ceiling is
`1,607,411.3313313313`, leaving `988.0513313313` area units.

A retained P0 point must satisfy all of:

1. exact 5ns target, TNS=0, violations=0, loops=0 and worst slack >=+0.10 ns;
2. logic area <=`1,607,411.3313313313`;
3. each fixed benchmark throughput ratio >=0.995 and no unexplained counter
   drift;
4. no functional/semantic gate regression;
5. power remains explicitly unqualified unless workload activity coverage and
   macro internal/leakage are complete.

If P0-AB violates area or fails to recover reserve, synthesize A and B as
separate candidates and retain only nondominated points.  Weighted score may
break a tie between qualified points; it cannot compensate for a hard-gate
failure.
