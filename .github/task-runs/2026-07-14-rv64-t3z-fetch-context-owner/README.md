# T3Z Fetch Context Owner

## Objective

Remove the request-accept control cone from every wide immutable fetch-context
register while preserving same-cycle response replacement and a single
architectural outstanding-PC source.

The fresh T3Y exact-5 ns result is WNS `-0.160 ns`, TNS `-22.07 ns`, loops `0`.
Thirty-nine of the top forty paths end in
`OooFetchPcOutstandingSequencer` PC state.  A frozen-netlist forecast also
shows that moving only this duplicate PC state would expose
`OooFetchAxiBridge.req_satp_q`, so the cut must cover the complete context.

## Architecture contract

1. `OooFetchAxiBridge` owns two complete 132-bit immutable context banks:
   `{pc, paging, priv, satp, svpbmt}`.
2. The inactive bank tracks the live candidate every cycle.  No `valid`,
   `ready`, `fire`, FSM state, or MMU-flush predicate may gate a context-bank
   write.
3. A one-bit selector changes only on reset or accepted request.  Request fire
   toggles the selector and scalar FSM state; it never selects a wide payload D
   input.
4. MMU flush invalidates protocol/FSM ownership but does not clear or swap the
   context banks.  In particular, `S_AD_UPDATE` must retain the old context
   while AW/W/B drain under sticky drop.
5. In `S_RESP`, a stalled response observes the old active context.  Atomic
   response-consume plus replacement captures the new request in the inactive
   bank and exposes it only after the clock edge in `S_CACHE_READ`.
6. `OooFetchRequestMux` preloads the sequential replacement PC from registered
   response presence (`outstanding_valid && fetch_rsp_valid`), not downstream
   ready/fire.  Branch-prefetch priority remains higher than this sequential
   candidate.
7. Bridge active PC is the only outstanding-PC payload source.  It traverses
   `NpcCoreTop -> OooCoreTopGlue -> OooFrontend ->
   OooFetchPcOutstandingSequencer`; the Sequencer retains only validity,
   discard, and next-PC scalar/redirect state.
8. Outstanding PC is meaningful only when outstanding-valid is true.  Special
   branch/JALR prefetch adoption must prove the Bridge active PC equals the
   adopted prefetch PC; it must not mux a live buffer PC that clears on the
   adoption edge.

## Required evidence

- focused RequestMux, Sequencer, Bridge, access-attribute, page-end, xbar,
  Glue, trap, privilege, and Sv39 tests;
- OOO_ASSERT markers for inactive tracking, fire swap, active hold,
  flush-no-swap, response stall, atomic replacement, and special-owner match;
- negative/source mutations for wrong-bank write, missing selector toggle,
  live active overwrite, response-fire selection, AD-flush context clear, and
  reintroduced Sequencer PC state;
- full module regression and source/style/contract checks;
- fresh synthesis with frozen inputs and a zero-exception exact 5.000 ns global
  STA.  Only WNS/TNS nonnegative with loop count zero may claim 200 MHz.

## Reviewer traps

- Do not connect Glue tests' new owner input directly to candidate
  `fetch_req_pc`; response-valid preload intentionally changes that candidate
  before the old response is consumed.  Tests need a clocked Bridge-owner
  shadow.
- Existing Bridge tests that procedurally seed `pc_q` must seed both PC banks
  after `pc_q` becomes a selected wire.
- Invalid outstanding payload differences are not functional failures and must
  not motivate restoration of a 64-bit duplicate owner register.

## Pre-synthesis evidence

- T3Y endpoint mapping is exact: `u_fetch_pc_outstanding/_4455_/D` is
  `outstanding_pc_o[24]`, one of the 64 duplicate Sequencer PC registers
  removed by T3Z; it is not `next_fetch_pc_q`.
- `evidence/module-v2/summary.txt`: 98/98 module testbenches pass after adding
  positive E8 and E6 JALR pending-match adoption coverage.
- Historical `OooJalrPrefetchStatusGate` confirms both branch and JALR
  adoption use the shared `branch_prefetch_pc` as the prefetch request key;
  the new E8/E6 tests prove the common owner assertion is not branch-only.
- `evidence/source-v1/audit.json`: production source audit passes and all seven
  structural mutations are rejected.
- `evidence/temporal-negative-v1/summary.txt`: missing selector swap, wrong
  bank write, and special-owner mismatch are all rejected by the intended
  T3Z assertion marker.  The `$error` text in those logs is expected negative
  evidence, not a regression failure.
- `make -C npc/rv64 lint`, `check-rtl-style`, `check-contract` (156 assertions
  versus baseline 89), and `git diff --check` all pass.

## Fresh synthesis and STA result

- Fresh synthesis completed with exit status 0; every frozen-input comparison
  passed.  Netlist SHA256 is
  `fdd90ea40da2d88e5032c46cdf4c090d6cb24edfb72d2c314a999ea72d6866d5`.
- `evidence/opensta-fresh-t3z-initial/summary.json`: exact 5.000 ns global STA
  reports WNS `-0.850 ns`, TNS `-499.25 ns`, combinational loops `0`, total
  power `0.120 W`.  Therefore T3Z does **not** meet 200 MHz.
- The old Sequencer outstanding-PC endpoint family is gone from the top 40.
  All top-40 paths instead start at netlist DFF `_7808_`, mapped exactly to
  `OooFetchAxiBridge.fetch_ctx_sel_q`.  The worst path crosses
  `u_walk_pte_pmp_checker`, the AXI xbar, and ends at
  `OooMemAxiBridge.state_q[3:0]` (`-0.848 .. -0.835 ns`).  The remaining paths
  from the same selector end in fetch-bridge or xbar state/payload registers.
- Reviewer conclusion: the double bank is functionally correct, but its active
  selector became a high-fanout datapath source.  The next iteration must
  remove that selector from PMP/AXI consumers through a registered execution
  context boundary; buffering or path exceptions would be false closure.
