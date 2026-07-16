# T4A Fetch Execution Context Boundary

## Objective

Remove `OooFetchAxiBridge.fetch_ctx_sel_q` from every PMP, page-walk, AXI,
and xbar-facing combinational cone while preserving exact request ownership,
response replacement, MMU-flush drain, and A-update provenance.  Cut the
remaining page-walk authorization cone at a registered CHECK boundary.

The fresh T3Z exact-5 ns result is WNS `-0.850 ns`, TNS `-499.25 ns`, loops
`0`.  All top-40 paths start at netlist DFF `_7808_`, mapped exactly to
`fetch_ctx_sel_q`; the worst path crosses the walk-PTE PMP checker and AXI
xbar into `OooMemAxiBridge.state_q`.  T3Z is therefore a measured functional
success but a timing regression, not 200 MHz closure.

## Architecture contract

1. A single complete candidate context `{pc,paging,priv,satp,svpbmt}` captures
   raw live inputs every cycle.  No valid, ready, fire, state, or MMU-flush
   predicate may gate a candidate payload D input.
2. Request fire changes only scalar FSM/credit ownership.  The next cycle is
   always `S_CACHE_READ`; during that cycle the candidate registers contain
   exactly the values sampled on the request-fire edge.
3. Cache and ITLB lookup consume the candidate context only in
   `S_CACHE_READ`.  At that state's closing edge, a complete execution context
   captures the candidate under the local registered-state predicate only.
4. `S_LOOKUP`, PMP, page walk, exact fetch, cache/TLB fill, cross-page handling,
   and A-update consume only the frozen execution context.  They may not read
   the candidate, live request inputs, or an active-bank selector.
5. The architectural owner PC is candidate PC in `S_CACHE_READ` and execution
   PC in all later valid transaction states.  The handoff must be value-stable;
   response stall and MMU flush cannot alter a valid owner.
6. Atomic response-consume plus replacement enters `S_CACHE_READ` with the new
   candidate owner immediately after the edge; the old response observes the
   old execution owner before the edge.
7. `S_AD_UPDATE` retains execution context across ordinary and repeated
   `mmu_flush_i` while AW/W/B drain.  Live candidate changes are irrelevant to
   AWADDR, permissions, re-walk, and fault provenance.
8. The T3Z double-bank selector and all physical bank registers are removed,
   not hidden behind another timing exception or buffer.
9. Every PTE read/re-walk enters `S_WALK_CHECK`, which atomically captures the
   PTE address and 8B READ-side PMP verdict.  `S_WALK_AR` drives AXI only from
   those q values; this does not claim the still-open A-update WRITE-PMP
   contract.
10. `mmu_flush_i` cannot withdraw an already presented stalled AR.  WALK and
    direct-fetch AR use separate DROP owners to hold valid/payload until fire,
    then enter `S_DRAIN` and silently consume R.

## Required evidence

- directed Bridge tests for request fire, candidate/exec handoff, dirty live
  inputs, response replacement, response stall, cross-page walk, and A-update
  flush with deliberately different live context;
- source audit proving unconditional candidate capture, local-state-only exec
  capture, selector removal, and candidate/exec consumer separation;
- temporal negative mutations for gated candidate capture, missing exec
  capture, live/candidate PMP use, owner-handoff mismatch, PTW-boundary bypass,
  corrupted PTW capture, and restored flush gating on ARVALID;
- focused integration tests, full module regression, lint/style/contract;
- fresh frozen-input synthesis and zero-exception exact 5.000 ns global STA.
  Only WNS/TNS nonnegative with loop count zero may claim 200 MHz.

## Reviewer traps

- Candidate is correct only for the one `S_CACHE_READ` cycle after fire; it is
  overwritten at that cycle's closing edge.  Every later consumer must use
  execution context.
- Execution context must capture the old candidate value through nonblocking
  semantics at the `S_CACHE_READ` edge.  Capturing live inputs there is wrong.
- Owner PC cannot always alias candidate (unstable during a long transaction)
  or always alias exec (one cycle late immediately after fire).
- A normal MMU flush may invalidate semantics, but an in-progress A-update is
  a bus owner and must retain the old execution context until B completion.
- A stalled AR is also a bus owner.  Clearing fetch scratch or gating ARVALID
  during flush changes an externally visible payload and violates AXI.

## Current functional evidence

- source audit: PASS, 10/10 architecture mutations rejected;
- temporal negative: PASS, production baseline plus 5 independent dynamic
  mutations (candidate/exec, owner, PTW predecessor/capture, AR hold);
- directed Bridge: PASS with candidate/exec replacement, registered PTW grant
  and deny, WALK/Data stalled-AR flush, repeated flush, flush+READY, poisoned
  live inputs, A-update and dropped-R coverage;
- focused frontend/core/xbar: 8/8; full module regression: 98/98;
- Verilator lint, RTL style and contract ratchet: PASS (166 immediate
  assertions versus baseline 89).

## Physical result

- fresh synthesis: PASS with all frozen-input comparisons PASS;
- netlist SHA256:
  `0f1e7b228942f33e551d579208bc17193ca6f89c20d96c27c337a64cef03928b`;
- zero-exception exact 5.000 ns STA: `WNS=-0.130 ns`, `TNS=-7.45 ns`,
  combinational loops `0`, total power `0.117 W`;
- versus T3Z, WNS improved by `0.720 ns` and TNS by `491.80 ns`, but 200 MHz
  remains unclosed;
- top-40 migrated completely out of the Bridge: all 40 start at one fetch
  packet FIFO flop, 36 end in fetch-PC outstanding and 4 in the issue queue.

T4A therefore closes its intended selector/PTW cone but is not the terminal
timing slice.  T4B must cut the newly measured FIFO-head classification to
dispatch/next-fetch cone; no 200 MHz claim is made here.
