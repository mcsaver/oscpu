# V13P aggregate-B response fusion architecture contract

## Classification and evidence level

- primary classification: `architecture`
- secondary intent: `performance-cpi`
- single mechanism: aggregate-B terminal response fusion into the existing
  formal-WB response channel, with the current registered `S_RESP` fallback
- current state: `RTL_IMPLEMENTED_DEVELOPMENT_EVIDENCE`
- promotion state: `NOT_ELIGIBLE`

V13O is a diagnostic input, not a qualified baseline.  Its current-config
CoreMark region contains 1,111,757 request-outstanding cycles, including
690,056 `S_WRITE_RESP` cycles.  Whole-run D-cache statistics report 293,878
store accesses, while region response-terminal residency is 595,831 cycles.
These observations motivate a one-cycle post-B hypothesis but do not prove it.

## Falsifiable hypotheses

- H1: a material fraction of plain-store B terminals arrive while the backend
  has formal-WB route and SQ-terminal credit.  Directly exposing
  that aggregate B removes the otherwise mandatory registered `S_RESP` cycle.
- H2: sink credit is frequently unavailable on the B edge; most terminals use
  the registered fallback and the CPI effect is small.
- H3: downstream B service latency remains dominant.  Fusion can reduce
  response-terminal residency but must not reduce or relabel the edge-old
  `S_WRITE_RESP` wait bucket.
- H4: the saved response-terminal aggregate is mainly non-store lifecycle;
  therefore one-cycle store fusion has little region-cycle effect.

Lowest-cost discriminator: a focused bridge test counts eligible direct fires,
fallbacks and duplicate responses.  Only after those checks pass may the same
current-config CoreMark binary be used for a bound A/B run.

## Stage 0 — six cross-module contracts

| Contract | Frozen rule |
| --- | --- |
| handshake | Direct response `valid` depends on registered `S_WRITE_RESP` owner and aggregate `BVALID`, never on response `ready`.  If `valid && !ready`, the B payload/owner is captured into the existing `S_RESP` registers and held until fire. |
| backpressure | AXI `BREADY` remains owned by the bridge and B is always consumed in `S_WRITE_RESP`; backend backpressure chooses direct fire versus registered fallback, never whether aggregate B exists. |
| flush/kill | Already-accepted nokill physical stores remain visible; a killed escaped write remains a drop terminal only and cannot use the direct architectural response.  No new flush source or priority is introduced. |
| precise exception | `BRESP!=OKAY` still produces cause 7 with SQ-captured original VA, reaches ROB only through formal WB and retires only from registered ROB done on the following cycle. |
| memory order | AW/W acceptance remains nonterminal.  Aggregate B remains the unique physical-store terminal; cache maintenance and SQ terminal occur once on that B edge. |
| recovery/source of truth | Active registered `{owner kind, token, epoch, fault_tval}` is the direct-response source.  Held fallback uses the existing response snapshot.  No owner, token, epoch, ROB tag or completion truth is duplicated. |

Out of scope: AW/W early completion, same-cycle WB-to-ROB-retirement bypass,
additional outstanding writes, store-buffer architectural retirement, B error
policy changes, A/D-update fusion, B-side cache-policy changes and B-cycle
station advance.

## Stage 1 — verifiable requirements

1. Before aggregate B, a store produces neither visible response nor ROB
   completion.
2. In normal `S_WRITE_RESP`, aggregate B presents one direct response using the
   active registered owner and current `BRESP`.
3. If all backend sinks are ready, the direct response fires once and the
   bridge does not present the same transaction from `S_RESP` next cycle.
4. If any sink is not ready, the bridge captures the response and preserves the
   existing stable `S_RESP` handshake until fire.
5. OKAY, SLVERR and DECERR retain their existing zero-data/error/page-fault
   mapping and precise store exception behavior.
6. Killed escaped writes expose only the exact drop terminal.  HW A/D updates
   retain their existing non-fused continuation FSM.
7. D-cache RMW/invalidate occurs on the same aggregate-B edge as before and
   exactly once.
8. The request station cannot advance from `S_WRITE_RESP` on the B edge; next
   request launch timing is not a second optimization mechanism.

## Stage 2a — protocol rules

- Direct path is Mealy: registered state/owner plus current aggregate B produce
  response valid and payload.
- `valid` is independent of `ready`; `ready` is used only in the sequential
  choice `S_IDLE` versus `S_RESP`.
- Backend response identity, formal-WB allocation and SQ terminal grant remain
  unchanged consumers.  Plain-store DRAIN bypasses terminal-collector credit;
  STORE owner death remains the later SQ release mask.
- AXI B is not replayed.  A non-ready direct response must therefore be copied
  into existing response registers on the same edge.
- Back-to-back station acceptance remains restricted to the existing
  `S_IDLE`, ready `S_RESP` and lookup-fusion cases.

## Stage 2b — FSM delta

| Edge-old state/event | Response this cycle | Next state |
| --- | --- | --- |
| `S_WRITE_RESP && !BVALID` | none | `S_WRITE_RESP` |
| normal store `S_WRITE_RESP && BVALID && rsp_ready` | direct aggregate-B response fires | `S_IDLE` |
| normal store `S_WRITE_RESP && BVALID && !rsp_ready` | direct response stalls; payload captured | `S_RESP` |
| killed escaped write `S_WRITE_RESP && BVALID` | no visible response; exact drop terminal | existing kill/drain path to `S_IDLE` |
| `S_RESP && rsp_ready` | registered fallback fires | existing `S_IDLE`/station behavior |

Reset and global priority remain:
`reset > existing stage-advance cases > kill/drop drain > normal FSM`.
`stage_advance` is false in `S_WRITE_RESP`, so it cannot race the new branch.

## Stage 2c — invariants and executable checks

- `direct_valid -> state==S_WRITE_RESP && BVALID && visible exact owner`.
- `direct_valid && ready` implies no registered response for that owner on the
  next cycle.
- `direct_valid && !ready` implies next-cycle `S_RESP` with identical
  `{owner kind, token, epoch, tval, error}`.
- A B terminal yields exactly one of direct fire, registered fallback fire or
  killed-owner drop; never zero and never more than one.
- `direct_valid` never changes `stage_advance`, AW/W completion, cache
  maintenance enable or the aggregate-B definition.
- SLVERR/DECERR direct and fallback paths both produce the same error bit;
  backend cause/tval assertions remain authoritative.

Each new immediate assertion requires a focused negative mutation: disabling
the `ready`-accepted state bypass must produce a duplicate-response failure;
removing fallback capture must fail the held-response test; exposing killed B
must fail the drop/response exclusivity test.

## Stage 2d — datapath constraints

- Add one combinational `data_store_b_response_fusion` predicate; no register,
  queue or token table is added.
- Extend the existing visible-response identity mux so lookup fusion and B
  fusion select active registered owner fields; held `S_RESP` selects snapshot
  fields.
- B fusion selects zero data, current `BRESP!=OKAY`, page-fault zero and the
  current locked typed memory attributes.
- Only the `S_WRITE_RESP` next-state condition reads response ready.  BREADY,
  cache maintenance and collector/SQ terminal equations are unchanged.

## Stage 2e — RTL topology review (9 items)

1. Module/ports: `OooMemAxiBridge`; no port, width, clock or reset change.
2. State registers: no new state.  Existing `state_q`, response payload/owner
   snapshot, AW/W done and owner registers retain reset values.
3. Combinational blocks: one fusion predicate and extensions to response
   valid/payload/identity muxes and visible identity checks.
4. FSM: only normal `S_WRITE_RESP+BVALID` chooses `S_IDLE` on direct fire or
   existing `S_RESP` on stall.
5. Pipeline/flow: aggregate B may reach backend formal WB in the same cycle;
   ROB done remains Q-only and commit remains the following cycle.
6. Priority: reset/kill/drain semantics remain above normal B handling;
   station advance remains impossible in `S_WRITE_RESP`.
7. Resources: the existing single response channel is shared by lookup fusion,
   B fusion and registered response through a mutually exclusive mux.
8. Critical path: new risk is AXI aggregate BVALID/BRESP -> bridge response mux
   -> backend owner/credit/WB mux -> ROB input.  Synthesis/STA is mandatory
   before promotion.
9. Functions: none added; predicate and muxes remain explicit assigns and the
   state update remains in the existing clocked block.

Topology self-review: owner source, fallback storage, reset/kill priority and
single response resource are closed.  The design intentionally leaves the
next-request advance and ROB retirement boundary unchanged.

## Predeclared performance and guardrails

- target counter: lower `cycle_memory_response_terminal` by the number of
  in-region direct B fires; `cycle_memory_request_axi_write_response` is not
  relabeled and may remain unchanged.
- functional binding: retired instruction count, CoreMark iteration/CRC,
  region markers, DiffTest result and all assertion markers must match.
- counter guardrails: three aggregate conservations, unknown=0, overflow=0 and
  invalid-events=0.
- architecture guardrails: no pre-B response, exact B error cause/tval, one SQ
  terminal, one formal WB, one ROB commit and one SQ release per store.
- PPA guardrails: candidate remains unpromoted until the same source/config/tool
  cohort has synthesis/STA/area and no relevant timing regression.

## Implemented RTL delta

- `OooMemAxiBridge` now forms
  `data_store_b_response_fusion_w = data_store_b_terminal_w && fsm_normal_w`.
- The direct response selects the active registered owner tuple, current BRESP,
  zero data and no page fault.  VALID does not read READY.
- A ready direct response returns to `S_IDLE`; a stalled response captures the
  same payload in the existing `S_RESP` snapshot.  No state/register/port was
  added and `stage_advance_w` remains false in `S_WRITE_RESP`.
- AW/W acceptance, aggregate-B terminal definition, killed escaped-write drop,
  cache RMW/invalidate, HW A/D continuation, ROB registered-done and SQ release
  equations remain unchanged.

## Verification result

- Focused bridge TB: PASS.  It covers direct OKAY/SLVERR/DECERR, a stalled
  fallback, a killed exact drop, no pre-B response, no B-cycle station advance
  and no post-fire duplicate.  Marker:
  `[V13P-B-FUSION-CONTRACT][PASS] direct=3 fallback=1 killed-drop=1`.
- Full bridge TB: PASS, marker `[PASS] tb_ooo_mem_axi_bridge`.
- Real wrapper/backend directed TB: PASS.  External AW/W/B stimulus traverses
  `OooDualMemBridgeWrapper` and `OooIntBackend`; the B edge observes one formal
  WB, one SQ terminal, collector ingress zero and no commit.  The following
  registered-ROB cycle commits and exposes the STORE release mask; the next
  edge clears SQ/tracker state.  Marker:
  `[V13P-BACKEND-B-FUSION] ... wb=1 sq_terminal=1 collector=0 registered_commit=1 sq_release=1 ... PASS`.
- Existing wrapper, backend-recovery, Sv39-boot and sustained dual-memory smoke
  tests remain PASS.  These smoke logs are not relabeled as the V13P directed
  lifecycle proof.
- Source-sensitive mutation suite: PASS.  Four compile-success variants are
  retained: direct predicate tie-off, forced duplicate `S_RESP`, removed
  fallback error snapshot and killed-B response exposure.  The latter three
  are independently rejected by `[V13P-B-FUSION-NO-DUP]`,
  `[V13P-B-FUSION-FALLBACK]` and
  `[CHECK-FAIL] V13P killed B cannot fuse got=1 expected=0`.
- Cross-module WB-slot-full, two-local-SQ-terminal and C0-barrier fallback
  traces were not added in this slice.  Backpressure capture is therefore
  bridge-local PASS but remains a full-backend directed GAP.

## CoreMark observation and causal boundary

The fail-closed same-config A/B run changed only the bridge compile source.
Both runs retired 3,183,617 instructions, completed 10 iterations with CRC
`0xfcaf`, reached one GOOD TRAP and preserved the region contract.

| metric | tie-off baseline | candidate | candidate - baseline |
| --- | ---: | ---: | ---: |
| cycles | 5,395,310 | 5,392,187 | -3,123 (-0.0578836%) |
| CPI | 1.6947107645 | 1.6937298048 | -0.0009809597 |
| IPC | 0.5900711915 | 0.5904129438 | +0.0003417523 |
| memory response-terminal cycles | — | — | -125,939 |
| AXI write-response cycles | — | — | +1,482 |

This is a one-pair directional observation, not promotion-grade performance
evidence.  No direct/fallback/drop event counter was present, other lifecycle
buckets moved materially, and the response-terminal delta is not a count of
direct fires.  Causal attribution remains
`GAP_NO_DIRECT_EVENT_COUNTER_AND_SINGLE_AB`.

## Yosys structural diagnostic and PPA boundary

Bundled Yosys `0.66+197` (executable SHA-256
`7c3e3396b38c129dd7485be5a0a0f0da8e495a94c8fd486059e3bea043a588d6`)
synthesized `OooMemAxiBridge` with leaf TLB/cache/checker modules blackboxed.
The tie-off baseline and candidate differ only at the fusion predicate.

- generic cells: 976 -> 985 (`+9`)
- wire bits: 9,491 -> 9,566 (`+75`)
- BVALID/BRESP-to-response intersection: 0 -> 22 objects
- selected longest topological path: absent -> 4 generic stages

This demonstrates a small local structure delta and the intended new Mealy
path.  It is not mapped area, power, STA, end-to-end backend delay or 200 MHz
closure evidence.  Full-source mapped synthesis/STA, power and a repeatable
cohort remain GAP.

## Independent review and decision

Review v1 found no bridge-local correctness counterexample but rejected the
original claim that terminal-collector credit is a plain-store DRAIN sink.
The specs and this report now state the actual contract: DRAIN writes SQ
terminal directly and the STORE owner dies later through SQ release.  Review
v2 found no new correctness/fake-green counterexample in the real-backend TB
or the three independent mutations; it did not finish a field-by-field Yosys
audit, so that evidence retains its diagnostic-only boundary.

Decision: keep the RTL as a development checkpoint, but do not freeze it into
an arch-stable/PPA baseline and do not promote it.  Current status is
`DEVELOPMENT_PASS / NOT_ELIGIBLE_PPA_PENDING`.  Promotion requires a fresh
same-source mapped area/STA/power cohort, a qualified frequency result, and
repeated performance evidence with direct/fallback/drop observability.  The
long-term RV64 goal remains active.
