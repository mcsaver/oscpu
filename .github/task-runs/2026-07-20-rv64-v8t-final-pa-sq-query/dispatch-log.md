# v8t/F3 subagent dispatch log

## v8t-f3-architecture-contract-review

- status: `dispatched`
- mode: `self-contained-no-tools`
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-architecture-contract-review.json`
- contract JSON SHA-256: `cea7df32e06b34135a5179f8a8daa3ba6ceab1dd98157a3d8d814baae072f4d1`
- SHA scope: only the JSON contract; it does not bind `contract.md`, `rtl-derivation.md`, RTL, tests, or reviewer output.
- permissions: no tools, no shell, no file access, no network, no writes.
- result boundary: limited-material contract review only; it cannot claim a complete independent repository review.
- scope extension: requires a new versioned JSON plus a fresh validate/render cycle.

### Initial reviewer result

- verdict: `GAP`
- material boundary: limited-material review only; no repository audit claimed.
- P0-1: the prompt did not state that every live plain store already owns a dispatch-time SQ placeholder.
- P0-2: the prompt did not distinguish SQ physical/no-effect terminal from ROB/owner completion.
- P0-3: the prompt did not state that `filled` atomically validates PA/class/mask/data.
- P1-1: decision versus held-response/cache/target capture and formal response fire was underspecified.

### Disposition

- `contract.md` and `rtl-derivation.md` now state the dispatch placeholder census, exact SQ terminal meaning, atomic filled payload, pre-query cross-page exception, and decision/capture/fire boundaries.
- Each counterexample is converted into a required directed test, assertion, source check, and compile-success mutation family.
- Because the supplied materials changed, the initial JSON/SHA remains immutable historical provenance; a v2 JSON must be created, validated, rendered, and reviewed before contract PASS.

Textual review is not GREEN evidence until converted into a directed test, assertion, source check, or compile-success mutation.

## v8t-f3-architecture-contract-rereview

- status: `dispatched`
- mode: `self-contained-no-tools`
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-architecture-contract-rereview.json`
- contract JSON SHA-256: `f8e17cba32da113b10cc9db2e0effc871bbc975e145ac74e908386f4c6c7cef8`
- SHA scope: only the v2 JSON contract; the v1 JSON/SHA and GAP remain immutable provenance.
- permissions: no tools, no shell, no file access, no network, no writes.
- review goal: verify the four v1 gaps are closed and seek further counterexamples without expanding the checkpoint claim.

### v2 reviewer result

- verdict: `GAP`; the reviewer explicitly accepted all four v1 gap dispositions.
- P0-1: the bounded material did not state when a forwarded response acquired bank-local MIQ
  residency, so it could be misread as requiring a synthetic push at forward time.
- P0-2: the bounded material did not normatively bind a captured forward response to F2's exact
  response/drop lifecycle under flush/kill.
- P1-1: because the query faces were called lane0/lane1, the reviewer reasonably asked how two
  same-bank forwards arbitrate, although the implemented topology permits only one active owner per
  bank.

### v2 disposition

- The original canonical bank request fire, before translation/query, atomically consumes the
  reservation owner, pushes its exact expected tuple to the selected bank MIQ, and locks the same
  bank bridge active Q. Query and forward never create a second MIQ entry.
- Each bank bridge has one active transaction and accepts at most one request per cycle. The two
  query faces are bank0/bank1 faces; simultaneous forward/forward therefore means one per bank.
  Same-bank contenders are resolved by the pre-request F2 allocator, with the loser remaining in
  reservation and never reaching query.
- A captured forward response inherits F2 `S_RESP` response-XOR-drop, bank-local MIQ exact-pop,
  tracker holder, killed-WB gating, backpressure stability and PID reuse rules. Allow paths inherit
  the existing cache/NC/IO target-specific cancel/hold/drain rules.
- These facts are now normative in `contract.md` and `rtl-derivation.md` and have corresponding
  directed/assert/source-check/compile-success mutation obligations. Since bounded materials changed,
  the v2 JSON/SHA remains immutable provenance; a v3 create/validate/render/review cycle is required.

Textual review is not GREEN evidence until converted into a directed test, assertion, source check,
or compile-success mutation.

## v8t-f3-architecture-contract-rereview-v3

- status: `dispatched`
- mode: `self-contained-no-tools`
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-architecture-contract-rereview-v3.json`
- contract JSON SHA-256: `be4622a491b0d279e146be8d538a04087af9fb2a7a9e64b64e9df6d4901dafa1`
- canonical pipeline: `create -> validate -> render` all PASS; the exact render was dispatched
  without permission or context edits.
- SHA scope: only the v3 JSON contract; it does not bind the design contract, derivation, RTL,
  tests, reviewer output, or the immutable v1/v2 provenance.
- permissions: no tools, no shell, no file access, no network, no writes.
- review goal: verify v2 MIQ enrollment, one-active-per-bank topology and captured response/drop
  lifecycle dispositions, then seek further bounded-material counterexamples.

### v3 reviewer result

- verdict: `GAP`; v2 MIQ enrollment, single-active safety and captured forward exact-drop were
  accepted as closed.
- P0-1: the supplied material did not extend request-fire conservation across translation/PTW/A-D
  fault and kill states before `S_SQ_QUERY`.
- P0-2: an in-place replaying load can occupy the only same-bank bridge while the older store whose
  fill/B would clear replay also needs that bridge, creating a real circular wait.

### v3 disposition

- Conservation now starts at every bank request fire and covers all translation, PTW, A/D, query,
  target and response states; local faults respond exactly, and pre-query kills use existing
  transport-specific exact-drop/drain rules.
- In-place replay is replaced by an exact bank-local retry handoff. A one-entry retry slot captures
  the complete MIQ head/full PID while the MIQ exact-pops and bridge becomes available; tracker/token
  ownership remains live and later normal request fire re-pushes the same owner without reallocating.
- A load-only admission fence prevents a second ordinary load from occupying this bank's
  active/station path while a retry/load owner exists, while store probes, SQ drains and head AMOs
  remain admissible. Retry versus store uses edge-old full-PID age so the dependency-producing older
  store makes progress.
- Retry-slot kill produces a lossless tagged exact terminal; holder census covers both handoff edges.
- The v3 JSON/SHA and GAP remain immutable provenance. These revised facts require a v4 canonical
  create/validate/render/review before the contract may pass.

## v8t-f3-architecture-contract-rereview-v4

- status: `dispatched`
- mode: `self-contained-no-tools`
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-architecture-contract-rereview-v4.json`
- contract JSON SHA-256: `040f4d24f1f2034cf8f6c97d93cbbe09dcf15013890ab117ec3e864be35dc5ce`
- canonical pipeline: `create -> validate -> render` all PASS; exact render dispatched unchanged.
- SHA scope: only the v4 JSON; design contract, RTL, tests, reviewer output and v1-v3 provenance
  are not bound by it.
- permissions: no tools, no shell, no file access, no network, no writes.
- review goal: verify pre-query conservation, one-slot load-admission invariant, exact retry-holder
  handoffs and same-bank progress before implementation resumes.

### v4 reviewer result

- verdict: `PASS` at contract level; no repository or RTL review was claimed.
- v3 pre-query conservation and same-bank replay dependency blockers are closed.
- One retry slot per bank is sufficient under the frozen load-only admission fence; store probe,
  SQ drain and head AMO remain able to progress, and older store wins retry/store arbitration.
- The holder loop `MIQ+bridge -> retry slot -> MIQ+bridge -> response XOR drop` is complete without
  token reallocation or ROB terminal at retry pop.
- Implementation assertions must cover kill versus retry capture/re-push, exactly one
  response/drop/retry end per MIQ attempt, non-sticky true retry credit, and no registered same-bank
  load-active plus retry-valid overlap.
- Required assumptions remain bounded: external PTW/AXI/B and legal older operations eventually
  progress; prior byte/IO/partial/cross-page clauses remain normative.
- Claim boundary: this PASS authorizes implementation only. F3, F4, DI-5, OOO-3, overall and PPA
  remain incomplete/unqualified until executable evidence closes.

## v8t-f3-p0-evidence-matrix-review

- status: `dispatched`
- mode: `self-contained-no-tools`
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-p0-evidence-matrix-review.json`
- contract JSON SHA-256: `179fe7527a103c470bb7def9c1915802dd4d643d3ad31e2fdec383d26aeaa61b`
- canonical pipeline: `create -> validate -> render` all PASS; exact render dispatched unchanged.
- SHA scope: only the JSON contract; it does not bind the design contract, RTL, tests or reviewer output.
- permissions: no tools, no shell, no file access, no network, no writes.
- review goal: convert every retained F3 P0 category into a nonredundant cycle-level directed/oracle/
  compile-success mutation matrix; bounded-material review only.

## v8t-f3-retry-holder-proof-review

- status: `dispatched`
- mode: `self-contained-no-tools`
- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-retry-holder-proof-review.json`
- contract JSON SHA-256: `5328bef5aa0181660e0092b70a2fcaddac15f2f1ca882d446bce509b508a0354`
- canonical pipeline: `create -> validate -> render` all PASS; exact render dispatched unchanged.
- SHA scope: only the JSON contract; it does not bind the design contract, RTL, tests or reviewer output.
- permissions: no tools, no shell, no file access, no network, no writes.
- review goal: derive the bank-local replay-holder state space, exactly-one resident-or-terminal
  invariants, same-edge races and executable proof obligations; bounded-material review only.

## v8t-f3 implementation evidence review history

### Initial workspace review

- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-implementation-evidence-review.json`
- contract JSON SHA-256: `ea83e152447f24af4be97072bebfa07f9e7258040645e08210040e0135e7ab28`
- mode: `workspace-files`, read-only; allowed commands were `rg`, `sed`, `git status`, `git diff`
  and `sha256sum`; no write/network/account/credential/external-service access.
- process correction: one pre-dispatch validate/render attempt was mistakenly started concurrently.
  Its output was not dispatched. The contract was validated and rendered again sequentially before
  the reviewer received exact JSON/SHA-bound text, preserving the WSL single-flight rule at dispatch.
- result: the reviewer did not return a bounded final verdict after repeated convergence requests;
  the node was interrupted and retained as `review_pending/interrupted`. It is not checkpoint evidence.

### v2 bounded workspace rereview

- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-implementation-evidence-rereview-v2.json`
- contract JSON SHA-256: `6bb1aaf376d1cd3e72722754a6d329b8528f4fb926b83962bdd4c3f65f7d977e`
- canonical `create -> validate -> render`: PASS; exact hardware-professional render dispatched.
- verdict: `GAP`; no P0 RTL counterexample, but the contract named a nonexistent task-run root
  `result.json` while the runner wrote `evidence/focused/result.json`. The reviewer therefore could
  not bind the 38/37 mutation, proof, profile and source-closure evidence.
- disposition: accepted `scope_extension_request`; created v3 with the actual focused evidence path.

### v3 evidence-path closure

- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-implementation-evidence-rereview-v3.json`
- contract JSON SHA-256: `14685ce3d9938b738b1d399fd897570a5f831cf0432d84ada395c052a6e0609c`
- verdict: `PASS` for run `v8t-f3-20260720T124629Z-1151135`; 38/38 activation,
  37/37 required dynamic rejection, 11 profiles, holder proof and F0/F1/F2 were consistent; no P0/P1.
- disposition: superseded as final authorization because the checkpoint finalizer and its tests later
  became functional-source changes. The v3 result remains historical evidence only.

### v4 finalizer review

- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-functional-closure-review-v4.json`
- contract JSON SHA-256: `9d1d9f867dbc5dd8f75a97247180a77644932954930d28f9c6fb03b8e3207fdd`
- reviewed candidate: run `v8t-f3-20260720T132410Z-1173123`, closure
  `2250e9d2c91d4c2fc3e7b760f8a97d627ab78470adc23706eca39024abcd6704`.
- verdict: `GAP`; unresolved P0=`none`, P1=`stale/wrong-run overlay`. The first finalizer only checked
  the reviewer run-id prefix, and its positive unit test used different reviewed/current run IDs.
- disposition: replaced implicit next-run promotion with a two-phase flow. The focused runner always
  preserves a candidate; a promotion-only invocation requires exact run-id, closure, candidate-result
  SHA, mutation-summary SHA and reviewer-contract SHA, and cannot overwrite the candidate.

### v5 final functional-closure review

- contract JSON: `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/subagent-contracts/v8t-f3-functional-closure-review-v5.json`
- contract JSON SHA-256: `454009f9698d152c82375fdb1b5fdd864060bedc854753dc0516e05360ec56d3`
- canonical `create -> validate -> render`: PASS; exact hardware-professional render dispatched with
  read-only `rg/sed/sha256sum` and no external I/O.
- verdict: `PASS`; `unresolved P0/P1 = none`; authorized claim is
  `final_pa_sq_ordering_checkpoint` for F3 only.
- exact binding:
  - candidate run: `v8t-f3-20260720T133351Z-1183319`
  - functional closure: `0be0d3ee3424ee816fe11d0176f2fc5e71849e24bedb764025f4e2dcc8212063`
  - candidate result SHA-256: `030047748ddb9b75bb18e8be2cc164bbc576752d038682c8109c342ee40b8a0a`
  - mutation summary SHA-256: `71c3b1812387bf8f8be68a572b9cb491177c00d66105d5ca02a8175466399af6`
- finalizer evidence: 7/7 unit tests, including wrong-run, candidate tamper, closure mismatch, contract
  mismatch, claim-boundary inflation and missing-review cases.
- canonical reviewer disposition:
  `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/implementation-review-result.json`,
  SHA-256 `e5e80469184a5ba771dd487cb2eaa15d1bb88c81bd98d0fcda631c5a5c5a788e`.
- immutable candidate snapshot:
  `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/`.
- canonical checkpoint artifact:
  `.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/checkpoint-result.json`,
  SHA-256 `9977ea25427c976462ed2e88e2f92ad60fd458f8958d410abad41770ecf3f484`.
- boundary: F3 checkpoint only; DI-5/OOO-3/overall remain `RED`, PPA remains `UNQUALIFIED`,
  `promotion_eligible=false`.

## Retained-memory / e2e closure

- DB-first publication order: update stored project/npc/agent-system memory, refresh shims,
  `snapshot-stored`, then `audit-db-first`; audit PASS.
- bounded non-history briefs: `npc-dev=rv64 final pa sq ordering`,
  `agent-system=rtl hardware professional contract`,
  `github-index=retained memory checkpoint evidence`; all returned `recall_status=complete`.
- task-specific e2e:
  - `.github/task-runs/2026-07-20-rv64-final-pa-sq-ordering/`: `npc-dev` PASS.
  - `.github/task-runs/2026-07-20-rtl-hardware-professional-contract/`: `agent-system` PASS.
  - `.github/task-runs/2026-07-20-retained-memory-checkpoint-evidence/`: `github-index` PASS.
- final strict guard: PASS; 1258 shared-worktree changed paths mapped to exactly the three profiles
  above, each with fresh task-specific evidence.
- evidence catalog: 558 raw assets indexed for this F3 task-run; generated `evidence-index.md` is
  retained and backed up. The disposable materialized memory copies were removed after the DB update;
  they were not functional or review evidence.
