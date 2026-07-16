# T3Y Frontend Command Owner

## Objective

Close the two owner families exposed by the fresh T3X exact-5 ns top-40,
without timing exceptions and without changing redirect age ordering:

1. FIFO/head/backend-ready through `direct_frontend_flush` and the redundant
   E5/E6 eligibility mask into the redirect arbiter and `next_fetch_pc_q`;
2. the same accepted-request control cone into outstanding-PC and
   pending-trap-exit payload ownership.

## Fresh baseline

- T3X netlist SHA256:
  `12e786d6d362a36e1e8f19fa398dd258a7e80843657ab718d6c208436490d2f0`
- exact 5.000 ns: WNS `-0.220 ns`, TNS `-61.05 ns`, loops `0`
- top-40 endpoint classes: fetch-PC/outstanding `25`, pending-trap-exit `15`,
  FetchBridge `0`
- worst mapped path:
  `FetchPacketFifo.count_q[0] -> head classify -> backend admission ->`
  `direct_frontend_flush -> commit E5/E6 mask -> RedirectArbiter ->`
  `FetchPcOutstandingSequencer.next_fetch_pc_q[60]`, exact slack `-0.217 ns`

## Required contract

- preserve E1 trap priority and redirect age ordering;
- remove a late `direct_frontend_flush` mask only with an explicit
  direct-vs-owner collision assertion and a non-vacuity/negative check;
- separate outstanding payload capture from the long `fetch_req_fire` select;
  payload is only architecturally meaningful when its valid owner is set;
- prove pending capture predicates are disjoint from direct dispatch before
  removing their redundant late mask;
- run focused owner tests, source/temporal negative tests, fresh synthesis, and
  a new zero-exception exact 5.000 ns global STA before accepting the cut.

## Measured result

- fresh synthesis: PASS, all frozen-input audits PASS;
- netlist SHA256:
  `87ed7ed0bbd6838bda2ee12abf9ec626007bf2ce0a3cead455fad44028a25cd0`;
- exact 5.000 ns, zero timing exceptions: WNS `-0.160 ns`,
  TNS `-22.07 ns`, combinational loops `0`;
- top-40 endpoint classes: fetch-PC/outstanding `39`, other `1`,
  pending-trap-exit `0`;
- evidence:
  `evidence/opensta-fresh-t3y-boolean/summary.json`.

The boolean-owner cut is retained because it removes the pending-trap-exit
family and improves both WNS and TNS from T3X (`-0.220/-61.05 ns`) without
changing redirect age ordering.  It does not by itself meet 200 MHz.  The
next owner boundary is the duplicated outstanding-PC/request-context capture
family; no 200 MHz claim is made from this run.

## Reviewer boundary

- The exact report still violates setup, so this task is an intermediate
  architecture cut, not signoff.
- Forecasting only the Sequencer PC endpoint is insufficient: the accepted
  request `SATP` capture becomes the next wide endpoint.  The follow-up must
  move the complete immutable fetch context, not only PC.
- The non-gating `boolean-csrqh-v1` diagnostic exercises a flag-dependent
  legacy memory-reservation expectation and is not counted as a green T3Y
  result.  The OOO_ASSERT integration and 98/98 module run are the gating
  functional evidence.
