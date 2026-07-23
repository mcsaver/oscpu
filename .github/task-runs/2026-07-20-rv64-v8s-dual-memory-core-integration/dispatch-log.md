# v8s/F2 sub-agent dispatch log

## 2026-07-20 architecture-contract review

- task: `v8s-f2-architecture-contract-review`
- mode: `prompt-supplied-self-contained`
- permission: no tools, no shell, no file access, no network, no writes
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/subagent-contracts/v8s-f2-architecture-contract-review.json`
- contract JSON SHA-256: `b0fb98034d2f386d6f1bae24e91446c482216917410f300772176dd4fd90d187`
- SHA scope: only the JSON file above; it does not bind RTL, specs, tests, logs, or this dispatch log.
- execution node: `/root/v8s_f2_contract_review`
- initial state: `review_running`
- final state: `review_complete`
- reviewer verdict: `GAP`
- parent goal state: `active`

The task is a bounded review of a local RV64 Verilog/SystemVerilog architecture
contract. It has no external-service, account, credential, network, or workspace
mutation authority. If the platform does not finish this review, only this node
changes to `review_pending`; the long-running parent goal remains active.

### Actionable counterexamples and disposition

- Close dual consume truth table: in F2 mode each reservation consumes exactly
  on its own local terminal or selected-bank request fire; terminal1 no longer
  depends on edge-old terminal0 empty. Same-bank age and different-bank dual
  grant require dedicated assertions and directed covers.
- Latch/derive bank identity only from each reservation's captured canonical
  byte address; prove stability under backpressure and forbid local-complete plus
  external request double ownership.
- Enumerate each MIQ tuple and prove per-bank in-order response pairing, one
  request-fire to one MIQ push, response XOR drop terminal, cross-bank residency
  exclusion, and full ProducerId no-live-reuse.
- Use one global WB allocator after edge-old EX0/EX1 occupancy; mem0 and mem1
  must receive different slots and independent ROB-open results.
- The existing terminal collector is a 32-token exact pending set, not a bounded
  six-entry FIFO. F2 will expand its parallel ingress census and prove all valid
  exact-live, pairwise-distinct events are accepted atomically; duplicate or
  nonlive tuples fail closed. No independent per-source free-count test is used.
- Preserve the existing producer-lease ordering: flush/kill blocks WB first,
  while MIQ/bridge/drop residency retains the full identity until exact terminal;
  committed SQ/AMO writes continue to B and are never replayed.
- Route ordinary store probes by bank, but keep all physical writes under SQ or
  LEGACY authorization. Peer maintenance remains the F1 no-backpressure
  authorized-B sideband; its same-cycle valid clear is the visibility action,
  so no new acknowledgement is invented.
- Add explicit dual SQ fill/terminal allocation. Two SQ terminal ports are
  globally allocated across two non-backpressurable local exceptions and two
  backpressurable response terminals; response ready is granted only for the
  remaining distinct port(s).
- Require full-top elaboration plus asymmetric sentinel identity checks and
  source fail-closed checks for every hierarchy layer. Until those execute,
  status remains `architecture_checkpoint` and DI-5/OOO-3 stay RED.

## 2026-07-20 revised architecture-contract re-review

- task: `v8s-f2-architecture-contract-rereview`
- mode: `prompt-supplied-self-contained`
- permission: no tools, no shell, no file access, no network, no writes
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/subagent-contracts/v8s-f2-architecture-contract-rereview.json`
- contract JSON SHA-256: `d1068fbf1c504c65f3774a57daf1feeeac007fbe2af82afa1bf01d401ecf1284`
- SHA scope: only the JSON file above
- execution node: `/root/v8s_f2_contract_rereview`
- initial state: `review_running`
- final state: `review_complete`
- reviewer verdict: `GAP` (single narrow launch-edge race)
- parent goal state: `active`

The re-review closed bank routing, dual MIQ identity, terminal-set algebra,
global WB allocation, SQ multi-terminal allocation, flush/kill, and hierarchy
evidence at contract level. It found one same-edge counterexample: an edge-old
empty singleton could launch AMO while ordinary traffic also fired before the
LEGACY-live Q bit became visible. `contract.md` now gives singleton launch atomic
priority, requires `amo_launch_fire -> !ordinary_fire_b0 &&
!ordinary_fire_b1`, and forbids release-edge ordinary look-through. Directed,
assertion, and compile-success mutation obligations were added. This amendment
changes `contract.md`, not either reviewer JSON; their hashes remain scoped only
to their original JSON files.

## 2026-07-20 final architecture-contract review

- task: `v8s-f2-final-architecture-contract-review`
- mode: `prompt-supplied-self-contained`
- permission: no tools, no shell, no file access, no network, no writes
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/subagent-contracts/v8s-f2-final-architecture-contract-review.json`
- contract JSON SHA-256: `fd46504b404175b685beac0d72143325dc293b70be9bdbeadee35ec91ecd200e`
- SHA scope: only the JSON file above
- execution node: `/root/v8s_f2_contract_rereview` follow-up turn
- initial state: `review_running`
- final state: `review_complete`
- reviewer verdict: `PASS` (contract-level only)
- remaining blockers: none at contract level
- parent goal state: `active`

The final reviewer confirmed that singleton launch and release edges are now
unambiguous and that the amendment did not reopen the already-closed bank,
MIQ, terminal-set, WB, SQ, flush, or hierarchy obligations. This PASS only
authorizes implementation under `architecture_checkpoint`; it is not RTL,
test, F2, architecture, or PPA evidence.

## 2026-07-20 implementation evidence review: validation incident

- draft task: `v8s-f2-implementation-evidence-review`
- draft mode: manually assembled self-contained JSON
- draft JSON SHA-256: `6ce32465d61ad6a6f51be277e3b764592797806ab560a3e715ea2251e16b64ee`
- canonical validation: `FAIL`
- disposition: `candidate-only`; the draft and its first reviewer response were
  not accepted as task evidence
- parent goal state: `active`

The canonical validator rejected the draft because its domain, task kind,
context shape, status policy, language policy, source contract and no-tools
material fields did not match the workspace schema. The draft file was replaced
through the Skill's `create -> validate -> render` path. This incident is retained
as the executable reason for the new canonical dispatch policy: a technically
plausible reviewer answer cannot repair an invalid dispatch contract.

## 2026-07-20 implementation evidence review: canonical v1

- task: `v8s-f2-implementation-evidence-review`
- mode: `prompt-supplied-self-contained`
- permission: no tools, no shell, no file access, no network, no writes
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/subagent-contracts/v8s-f2-implementation-evidence-review.json`
- contract JSON SHA-256: `b344fa467e294da8699dd3a6668dec36c0d0d2defa0f6db42398a0c571a85e40`
- review result: `implementation-review-gap.json`
- review result SHA-256: `9c2d0827d13bc235f1283fbb85583d622d78ea22dfcb9ad4bb60d982d57aa4e9`
- execution node: `/root/v8r_f1_implementation_review` follow-up turn
- final state: `review_complete`
- reviewer verdict: `GAP`
- parent goal state: `active`

The v1 reviewer correctly refused to infer canonical connectivity from
`F2_PROMOTED` metadata plus lint. The bounded material had omitted the existing
same-closure hierarchy checker counts and negative self-tests. It also identified
two nonblocking coverage holes: real ROB-index wrap age and dual memory response
hold/recovery while both EX WB slots are occupied. The parent converted both into
directed release/assert tests before requesting a versioned rereview.

## 2026-07-20 implementation evidence rereview: canonical v2

- task: `v8s-f2-implementation-evidence-rereview`
- mode: `prompt-supplied-self-contained`
- permission: no tools, no shell, no file access, no network, no writes
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/subagent-contracts/v8s-f2-implementation-evidence-rereview.json`
- contract JSON SHA-256: `4de07763032377e66b92e5a23394a4a727c81a6a2e327e74d83713fc0922cd6b`
- review result: `implementation-review-result.json`
- review result SHA-256: `4ff6f36bfa07832a3d0df929731fc2c79a95334a2b4621de12fcb2c1778ea6fe`
- execution node: `/root/v8r_f1_implementation_review` follow-up turn
- final state: `review_complete`
- reviewer verdict: `PASS` (bounded evidence only)
- authorized claim: `architecture_checkpoint`
- parent goal state: `active`

The v2 material supplied the 17-check fail-closed source result, exact canonical
parameter and instance census, lane/core face checks, 13 checker mutation-negative
tests, and both new release/assert markers under fresh run
`v8s-f2-20260720T075628Z-1005155`. The reviewer closed the hierarchy, ROB-wrap
and dual-EX-WB gaps. It did not claim raw repository review, hash recomputation,
formal completeness, F3/F4, architecture GREEN, PPA qualification or promotion.
