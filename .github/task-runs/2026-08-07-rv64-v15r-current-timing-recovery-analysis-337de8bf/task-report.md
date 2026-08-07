# V15R current timing recovery — RTL derivation

## Evidence boundary

- Design before the candidate: `sha256:337de8bf9bb72a57ab50570313521cd282c49f88df9cb88417c47673af4a6968`.
- Frozen 5 ns mapped reference: area `2181685.8`, `929646` cells, WNS `-18.121620178 ns`, TNS `-495447.71875 ns`, 40/40 violating paths.
- All 40 named paths launch at `OooMemOwnerTracker.next_token_q[0]` and end in the `OooFetchPcOutstandingSequencer` capture bank. The public intermediate net names are synthesis aliases, so only the launch/capture registers and an A/B mapped run are treated as causal evidence.
- This candidate does not authorize production promotion. It must pass focused semantic/mutation checks and a fresh same-configuration mapped synthesis/STA comparison first.

## Interface contract freeze (stage 0)

| Contract | Frozen behavior for this candidate |
| --- | --- |
| Handshake | `mem_issue*_res_capture_w` remains the exact reservation-birth fire. No valid/ready equation, payload, lane atomicity, or cycle boundary changes. |
| Backpressure/stall | Tracker allocation credit, IQ ready propagation, and reservation hold behavior are unchanged. The candidate only changes a local reduction that feeds `mem_owner_terminalized_o`. |
| Flush/kill/reset | Existing reset, checkpoint, flush, selective-kill, and terminal-ingress priorities are unchanged. A capture already suppressed by those gates is not a birth. |
| Exception order | ROB retirement, precise exception, pending-system and pending-architectural-trap ordering are unchanged. |
| Memory order | A same-edge reservation birth is an active owner and therefore forces `mem_owner_terminalized_o=0`. Accepted terminal transfer continues to authorize only an edge-old exact holder. |
| Recovery/single source | Token allocation and `next_token_q` remain solely owned by `OooMemOwnerTracker`; collector acceptance and STORE release remain the only terminal-transfer authority. |

Same-edge priority/invariant table:

| Condition | Required result |
| --- | --- |
| reset | Existing reset state and output behavior; no special candidate state exists. |
| `birth_any=1` | `mem_owner_terminalized_o=0`, regardless of unrelated terminal transfers on other tokens. |
| `birth_any=0` | The existing four mask equations determine `mem_owner_terminalized_o` unchanged. |
| birth token versus live/terminal token | Birth names an edge-old FREE token; terminal transfer names an edge-old LIVE exact holder, hence `birth_mask & (live_mask | terminal_transfer_mask) == 0`. Violation is fail-loud under `OOO_ASSERT`. |

No interface port, state register, clock domain, reset value, flush target, or pipeline boundary changes.

## Four-stage RTL derivation

### Stage 1 — requirements

1. Preserve the exact V9Y owner-terminal phase truth table, including same-edge reservation birth blocking.
2. Remove the allocated token value and its 32-bit dynamic one-hot decode from the production terminalized reduction.
3. Preserve token cursor/allocation semantics and all holder/collector masks.
4. Keep the token-indexed birth mask available only as simulation/assertion observability; it must not feed synthesized production control.
5. Demonstrate sensitivity with bank0 and bank1 birth observations plus a compile-success RTL mutant that deletes the scalar birth gate.

Out of scope: registering `mem_owner_terminalized_o`, changing issue throughput, changing allocator scan/cursor order, collector de-duplication, weakening assertions, and Ubuntu full-system simulation.

### Stage 2a — protocol rules

- `birth_any = mem_issue_res_capture_w || mem_issue1_res_capture_w` is a current-cycle Mealy fact derived from the existing exact capture fires.
- The indexed birth mask and scalar birth fact describe the same event cardinality boundary; only the indexed form carries token identity.
- Because allocation scans edge-old FREE state while terminal transfer/free requires an edge-old LIVE exact tuple, a birth bit cannot be a current transfer bit.
- Therefore, for `birth_any=0`, removing the birth mask from `active_holder_mask` is identity-equivalent; for `birth_any=1`, the explicit scalar gate supplies the same required false result.

### Stage 2b — state machine

No FSM or state update is added or changed. The candidate is a pure combinational factorization of the V9Y phase predicate.

### Stage 2c — invariants

- V15R-I1: `birth_any -> !mem_owner_terminalized_o`; consequence of violation: a serialized control transaction may cross a newly created memory owner.
- V15R-I2: `birth_mask & live_mask == 0`; consequence: allocator used a non-free edge-old token.
- V15R-I3: `birth_mask & terminal_transfer_mask == 0`; consequence: birth and death authority aliased one token in one edge.
- V15R-I4: when `!birth_any`, the four pre-existing V9Y mask clauses are byte-for-byte unchanged.
- V15R-I5: assertion-enabled and assertion-disabled builds consume the same production scalar predicate.

### Stage 2d/2e — data path and RTL topology

1. Module boundary: only internal logic in `OooIntBackend`; existing output `mem_owner_terminalized_o` remains one-bit combinational.
2. State registers: none added/removed/modified.
3. Combination blocks: retain all registered-holder masks and terminal/live/pending mask clauses; add one two-input OR (`birth_any`) and one final inhibit.
4. FSM: none.
5. Pipeline/handshake: no stage, valid, ready, or backpressure edge changes.
6. Priority: reset/flush/capture qualification remains upstream; at this predicate `birth_any` is a hard inhibit, then the existing mask clauses apply.
7. Resource use: no shared resource; the indexed birth decoder remains observational and is expected to be DCE'd from the synthesis top.
8. Expected critical-path effect: remove `alloc*_token -> 32-bit shift -> holder-mask reduction` from production control. Whether `next_token_q` remains critical through other allocation paths is an STA question, not assumed.
9. Function boundary: no function; explicit wires/assigns only.

Topology self-review: port/state/reset/priority ownership is unchanged; the only equivalence assumption is I2/I3, which follows from the existing edge-old allocator/terminal contracts and is independently asserted.

## Planned verification

- Focused V8W backend test in `OOO_ASSERT=1` and `OOO_ASSERT=0` configurations.
- Bank0/bank1 same-cycle birth checks.
- Compile-success assertion-disabled mutant deleting the scalar gate; expected exact check failure.
- Owner-tracker cursor test and relevant memory-owner lifecycle regressions.
- RTL style/contract gates selected once at candidate close.
- One fresh exact 5 ns mapped synthesis/STA A/B run before any promotion decision.

## Executed verification and measured result

- Candidate design: `sha256:f784b60a858e4c947316b67e9d16f1c0715f8328b1424eb5ae9b3a377566cef3`; the production `OooIntBackend.v` SHA-256 bound by the mutation and PPA inputs is `97099f42...e76`.
- Focused V8W and V11M runs pass with `OOO_ASSERT` enabled and disabled.  The logs contain `[V15R-SINGLE-ISSUE-BIRTH-TERMINALIZED][PASS]` and `[V15R-DUAL-ISSUE-BIRTH-TERMINALIZED][PASS]`.
- The assertion-disabled compile-success mutant deletes the complete `!v15r_mem_birth_any_w` inhibit.  It compiles, reaches the intended V8W observation, and is rejected by `[CHECK-FAIL] V15R issue-lane0 birth blocks terminalized got=1 expected=0`; the production RTL hash is unchanged before/after the run.
- `make -C npc/rv64 check-rtl-style` passes.  The direct contract checker passes; the aggregate `make -C npc/rv64 check-contract` fails closed because the frozen producer-holder instance graph still binds the preceding design, not because a current protocol check failed.
- Fresh L0/L1 on `f784...` pass: module `113/113`; official `177/177`; AM `61/61`; DiffTest mismatches `0`; evidence mutations `11/11` compiled and rejected.  No compiled intermediates were retained.
- Exact 5 ns mapped A/B, with the same setup-warning member sets and only `OooIntBackend.v` changed in the synthesis source identity:

| Metric | Reference `337de8bf...` | Candidate `f784b60a...` | Delta |
| --- | ---: | ---: | ---: |
| WNS | `-18.121620178 ns` | `-17.869169235 ns` | `+0.252450943 ns` |
| TNS | `-495447.71875 ns` | `-488025.46875 ns` | `+7422.25 ns` |
| logic area proxy | `2181685.80` | `2181526.48` | `-159.32` |
| total cells including macros | `929651` | `929441` | `-210` |
| vectorless power proxy | `0.135 W` | `0.136 W` | `+0.001 W` |

The vectorless power figure is unqualified and cannot accept or reject the candidate.  Timing remains unqualified: WNS is negative, all reported 40 paths violate, and neither the 200 MHz target nor the 0.1 ns promotion margin is met.  Runtime synthesis products were removed after retaining the summary, reports and output hashes.

## Independent review and disposition

- Contract v2: `.github/task-runs/2026-08-07-rv64-v15r-current-timing-recovery-analysis-337de8bf/subagent-contracts/v15r-mem-birth-factor-review-v2.json`, SHA-256 `1ced1f846b7d1b578e5e59508210cb2cc6cab0e6248718f98a3dcca0e0b23d95`.
- The reviewer found no RTL functional counterexample.  `OooMemOwnerTracker` allocates a birth only from an edge-old FREE token, while terminal transfer/release applies only to an edge-old LIVE token; the scalar inhibit is therefore equivalent to the removed token-indexed term for the current topology.
- `mem_issue1_res_capture_w` currently implies `mem_issue_res_capture_w`.  The V8W bank1 observation is a memory-bank route, not an issue-lane1-only birth; V11M covers dual birth.  Consequently the OR's lane1-only sensitivity is an explicit future-proof term rather than a currently reachable independent case.
- The focused TB can print a local PASS marker after an earlier `tb_check1` failure.  The mutation verdict is nevertheless causal because the runner requires both the exact `[CHECK-FAIL]` text and the final `[RESULT] FAIL`.  Manual review must not accept the local marker alone.
- Accepted disposition: retain `f784...` as the next engineering candidate basis.  Do not publish it as canonical current, Pareto/champion, architecture-stable, or PPA-qualified.
- Explicit GAPs carried into the next slice: no fresh named-path trace for `f784...`; the exact surviving launch/capture register family is therefore unknown, the producer-holder instance graph is stale, and candidate L2/L3 were not run.  Ubuntu remains optional and was not run.

## Selector contract correction discovered at close

The first candidate-close attempt correctly exposed live-design drift, but its
selector gate also reran several upstream current-receipt suites whose frozen
fixtures necessarily bind `337...`.  That coupled ordinary RTL development to
unrelated canonical-current publication work and caused many secondary
failures before their intended test oracle.

`run-optimization-slice-selector.sh --validate-only` now keeps two independent
checks:

1. decision logic and numeric path analysis run against an explicit frozen
   identity, including tamper/negative cases;
2. the live cache is checked separately.  A coherent cache must verify
   canonically.  A design-id-stale cache is accepted only as a fail-closed
   contract observation after a fresh runtime-only build and verify yields
   `STATE_CONFLICT` and `STATE_RECONCILIATION`, with a different live design-id.

The direct verify of the retained `optimization-slice-current.json` still
fails for `f784...`; no canonical state was rewritten.  The corrected bounded
gate runs 42 tests plus the frozen CPI census verifier and reports
`current=stale-fail-closed` in about seven seconds on this workspace.

The next close attempt exposed a second expected static-contract update: the
terminal-collector lane checker still required the pre-V15R terminalized
equation.  It now requires the exact two-lane scalar birth OR, requires the
scalar hard inhibit in `mem_owner_terminalized_o`, and rejects any reintroduced
indexed birth mask in `v9y_active_holder_mask_w`.  Its 13 tests include three
new negative variants for those clauses and all pass.

The post-candidate reviewer then supplied four future-false-green
counterexamples.  They are now implemented as deterministic guards:

- selector validation always builds/verifies an independent live report-only
  state before accepting either branch; `current=canonical` additionally
  requires stored/live design-id equality;
- a fresh, canonical live report is mutated only at `live_design_id`, and
  direct verify must reject it as noncanonical;
- the owner-terminal assignment pattern is semicolon-anchored;
- the collector contract extracts the pre-terminal production assignment
  graph, seeds taint at every `32'b1 << mem_owner_alloc[01]_token_w` decode,
  propagates aliases, and rejects taint at the active/intermediate/final
  terminal sinks.

The first follow-up exposed that these new counts had not yet replaced the
candidate gate logs, and identified Bash command-substitution `errexit` plus
`32'h1`/procedural-reg alias gaps.  The wrapper now calls live validation in
the parent shell, gives every build/verify/ID comparison an explicit failure
return, and has a structural test forbidding the subshell form.  The taint
parser accepts binary/hex/decimal one constants and collects both continuous
and combinational procedural blocking assignments.

The resulting selector suite is 44/44 PASS.  The collector suite is 18/18
PASS and rejects the assignment-tail, wire alias, `always @(*)` reg alias,
intermediate-mask and renamed `32'h1` decode variants in addition to the
original three V15R mutations.  These direct runs are development evidence;
the authoritative candidate gate logs are refreshed by the next
`finish --candidate` execution.
