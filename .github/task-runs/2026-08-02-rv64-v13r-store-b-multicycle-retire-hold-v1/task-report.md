# V13R store-B multi-cycle fallback and retirement-hold contract

## Round identity

- goal work classification: `verification`
- lightweight agent-flow execution profile: `development`
- auxiliary classification: none
- semantic delta: testbench/Make target/evidence driver only
- production RTL impact: none; all production modules are read-only
- debt ID: `VD-V13P-BRESP-BP-02`
- branch: `ai`
- opening HEAD: `dc027b3988777cba9fdb2200d721d24bba6368fc`
- workspace state: user/agent parallel modifications are preserved; this
  round records only explicit paths and does not enumerate the Git worktree
- original evidence:
  `.github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/`
- promotion state: `NOT_ELIGIBLE_PPA_PENDING`
- single-flight owner: main agent until an explicitly contracted reviewer owns
  the WSL shell
- expected focused runtime: less than 15 seconds; no long/system run

## Root-cause hypotheses

- H1: two genuinely scheduled dual-ALU WB waves can occupy both formal-WB
  slots at `C_B` and `C_B+1`.  The bridge must still accept aggregate B at
  `C_B`, hold the exact DECERR response in `S_RESP`, and allow the DRAIN
  response to fire exactly once at `C_F=C_B+2`.
- H2: after `C_F`, external `commit_ready=0` may delay the target store
  exception retirement without replaying the response.  SQ terminal and ROB
  done remain registered, while the STORE owner/SQ entry stay live until the
  real `C_C` edge.
- H3: V13Q's one-cycle result was accidentally sufficient only because the
  response snapshot was consumed immediately; a second stalled cycle or
  poisoned B input can expose an unstable snapshot or automatic `S_RESP`
  drop.
- competing hypothesis C1: the second ALU pair is not actually accepted or
  issued, so an apparent two-cycle check observes no real second WB wave.
- competing hypothesis C2: `commit_ready` only hides the output but SQ owner
  release still occurs from response terminal, causing an early lifecycle
  death.
- competing hypothesis C3: global counters count unrelated younger ALU events
  or the earlier probe rather than the target DRAIN.

Highest-information experiment: one isolated lane0 store with real Sv39
VA-to-PA translation, DECERR aggregate B, two pipelined dual-ALU waves and a
three-cycle `commit_ready` hold.  The test must observe both dispatch/issue/WB
waves, poison B inputs after the handshake, and bind lifecycle checks to the
target store PC/token or DRAIN-qualified event.

## Pre-experiment frozen cycle hypothesis

This section preserves the falsifiable schedule written before simulation.
The authoritative post-experiment contract is the correction immediately
below; the original hypothesis is retained rather than rewritten as if it had
passed.

- `C_B`: external `d_axi_bvalid && d_axi_bready` for the selected lane0 store.
- `C_F`: target `miq_drain_rsp_fire_w` / formal-WB / SQ-terminal edge.
- `C_C`: target store exception commit edge.
- At `C_B`, WB wave 0 occupies both integer WB slots.  B is accepted by the
  arbiter/bridge, but DRAIN fire, memory WB, SQ terminal, MIQ pop and commit are
  all zero; next state is `S_RESP`.
- At `C_B+1`, WB wave 1 occupies both slots.  AXI BVALID is withdrawn and
  BRESP is changed to OKAY.  `S_RESP` must still expose the original DECERR,
  exact owner token and original VA; all target terminal counts remain zero.
- At `C_F=C_B+2`, all sinks have credit and exactly one DRAIN response/formal
  WB/SQ terminal/DRAIN-qualified MIQ pop occurs with cause 7 and original VA.
  There is no same-cycle commit or SQ release.
- For three following retirement-hold cycles, `commit_ready=0` requires no
  target commit/release, no repeated response/WB/terminal/pop, SQ count one and
  STORE owner live.
- When `commit_ready` becomes one, exactly one registered exception commit may
  occur with cause 7/original VA, C0 trap barrier and exact SQ release.  Owner
  clears only after that edge.

## Post-experiment contract correction

H1 was rejected by two compile-and-run attempts.  The second dual-ALU pair was
accepted into the IQ, but while the response waited for formal WB,
`mem_rsp_waiting_for_wb_w` made `issue1_ready_w=0`.  At the edge after `C_B`,
only the pair's lane0 member reached `ex0_wb_slot_occupied_w`; one member
remained in the IQ and slot1 was deliberately left for the response.  The
first attempt therefore observed `issue_count=1`, `ex0_slot=1`, `ex1_slot=0`
and response acceptance at `C_B+1`.  Treating `execute0/1_valid` as two ALU
slot owners was a false oracle because one output already belonged to the
memory response.

The corrected, implemented contract is:

- bridge unit layer: accept DECERR at the external B edge with response ready
  low, poison live BVALID/BRESP immediately afterward, and hold the exact
  `S_RESP` owner token/error/original VA across three full response-stall
  edges before one final consume;
- integrated backend layer at `C_B`: the first real dual-ALU wave occupies
  both edge-old formal-WB slots, the B transport edge succeeds, and no target
  DRAIN/WB/SQ-terminal/MIQ-pop/commit occurs;
- integrated backend layer at `C_B+1`: the pending-response starvation gate
  blocks lane1 refill, permits only the next lane0 ALU, leaves slot1 for the
  exact DECERR response, and establishes a bounded anti-starvation response
  rather than an unreachable second all-ALU stall;
- after the exact store formal-WB edge, the store is the done exceptional ROB
  head and all non-ready retirement permits are open.  Three complete rising
  edges with `commit_ready=0` retain SQ count one and the same live STORE owner
  without response/WB/SQ-terminal/MIQ-pop/commit/release replay;
- restoring `commit_ready` exposes exactly one store exception commit with
  exact producer ID, cause 7, original VA, C0 trap barrier and SQ release;
  owner clears only after that edge.

This correction does not weaken the bridge hold requirement.  It separates a
lossless multi-cycle holder property from the backend's intentional
simple-ALU anti-starvation reachability bound.

## Planned sensitivity checks

Three compile-success negative RTL variants must be dynamically rejected:

1. `S_RESP` returns to IDLE after one cycle even when response ready is zero;
2. fallback capture treats DECERR as OKAY;
3. ROB head retirement ignores `commit_ready_i`.

No assertion may be removed or weakened.  A compile error, missing target
marker, timeout or infrastructure error is not mutation PASS.

## Test disposition

- V13Q store-error/backpressure focused test: `KEEP`; its direct and one-cycle
  fallback contract is unchanged and must remain PASS.
- V13P aggregate-B fusion focused tests: `KEEP`; direct/fallback/drop semantics
  are unchanged.
- V8X backend bridge recovery: `KEEP`; bridge configuration wiring is shared.
- no existing test is `REBIND`, `UPDATE_CONTRACT` or
  `OBSOLETE_WITH_EVIDENCE` in this verification-only round.

## Evidence boundary

The result closes a three-stall-edge bridge holder with poisoned live B,
integrated DECERR fallback, the simple-ALU anti-starvation response bound, and
a three-cycle exact-owner retirement hold for one isolated lane0 store.  It
does not prove an integrated multi-cycle stall generated by other simultaneous
WB producers, arbitrary-duration temporal properties, asymmetric SQ-terminal
credit, concurrent lane1 owners, system workload, synthesis, STA, power, area
or PPA promotion.

## Independent review and evidence correction

The first final reviewer accepted the bounded cycle semantics but found the
15-source manifest incomplete for the real backend compile cohort.  It also
found that regressions did not reference the manifest and mutation startup did
not invalidate every old per-variant receipt before variant 0.

The corrected Make source-closure target and drivers generated a 61-entry
manifest covering the exact two V13R TB source/dependency cohorts, headers,
checker, `filelist.mk`, spec and evidence drivers.  Focused, mutation-suite and
regression receipts were rerun against the same manifest SHA
`75691729620e5cf093bd08accf5bd48dc59742f78dd6d75c21cdba640fe74aaa`.
The reviewer independently verified 61/61 current hashes, the common SHA in
all three receipts, and all-variant mutation pre-clean, then returned delta
PASS.  Final round status is `VERIFICATION_PASS_WITH_DECLARED_GAPS`.
