# Dispatch log

## Status

- Parent objective remains active.
- No child has shell ownership.
- Reviewer inputs are versioned RV64 RTL/spec/TB/evidence excerpts.  Review outputs are limited to microarchitecture
  findings, counterexamples, coverage gaps, confidence basis and any required scope extension.

## v8v-lq-topology-review

- contract JSON: `.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-lq-topology-review.json`
- contract JSON SHA-256: `5824ab836008a5b59756919f960dbfba1175e34027eea72f4dc12f8e7756cd56`
- hash scope: only the JSON contract above; it does not bind `contract.md`, RTL, tests or supplied-material source files.
- dispatch mode: canonical `create -> validate -> render`, frozen-material RTL topology review.

## v8v-ooo3-final-review-v1

- contract JSON: `.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-ooo3-final-review.json`
- contract JSON SHA-256: `edcdf5c70224f8c6b360ff5ad8964bbfcecc0530d6b82fed238ac2aa8105834e`
- verdict: `GAP`
- finding closure:
  - checkpoint restore now drives LQ global recovery and retains launched loads as drainable tombstones;
  - LQ retire lookup `ready` now actively gates ROB commit, while commit/fire remains the only normal free event;
  - canonical `V8S_DUAL_MEMORY_FOCUSED` evidence now binds checkpoint drain, retire authority and final-PA retry;
  - same-PID dual final-PA query is fail-closed on both ports;
  - OOO-3 source topology, fixed provenance inventory and source-manifest live hashes now fail closed under unit cuts.
- dynamic closure: F2 profiles=6, mutations=13; OOO-3 metrics=11, LQ mutations=9; overall remains RED and PPA
  remains UNQUALIFIED.

## v8v-ooo3-final-review-v2

- contract JSON: `.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-ooo3-final-review-v2.json`
- contract JSON SHA-256: `55117ebea8a696ca40013c85902a4286e366e7ccb1ea2f90ed802c1e75ed4928`
- dispatch mode: canonical `create → validate → render`, `workspace-files` read-only RTL review.
- Reviewer must independently search for counterexamples in checkpoint recovery, dual query ownership, ROB
  lookup/commit coupling, evidence replay and PPA claim boundaries.
- verdict: `GAP (P1)`; report: `review-v2-gap.md`.
- counterexample: checkpoint restore cleared LQ/MIQ/reservation/retry but left ROB/IQ live, allowing an unlaunched
  load to lose its LQ issue authority permanently; the launched form left the same architectural-owner split.
- closure implemented:
  - Dispatch/ROB/IQ/rename, integer PRF, FP backend, SQ, LQ and MIQ now observe the same checkpoint recovery edge;
  - focused TB covers unlaunched load/store synchronous clear, two launched tombstones, exact terminal drain and
    no-reset redispatch/retire;
  - F2 now has 15 compile-success mutations, including separate cuts of LQ, Dispatch and SQ recovery;
  - OOO-3 provenance directly binds and parses the F2 result plus all 15 mutation identities.

## Next review

- prepare a new versioned read-only RTL review contract after the refreshed OOO-3 same-design evidence run.

## v8v-ooo3-final-review-v3

- contract JSON: `.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-ooo3-final-review-v3.json`
- contract JSON SHA-256: `016de2d3302a4c7f26717fb1827c43b21a0ff8988d7da37ec2812145ecf163c5`
- dispatch mode: canonical `create → validate → render`, `workspace-files` read-only RTL review.
- verdict: `GAP (P1)`; report: `review-v3-gap.md`.
- counterexample: a physical store could have fired before raw checkpoint restore; destructive recovery removed its
  ROB owner while SQ `request_sent` and B response ownership survived, so no future exact ROB commit/SQ release was
  possible.  A B response concurrent with raw restore was the shortest failing edge.
- repair implemented:
  - raw `checkpoint_restore_i`, admission `checkpoint_restore_hold_w` and destructive
    `checkpoint_restore_apply_w` are distinct protocol events;
  - a bank0 physical store/AMO request holds an exact full-`ProducerId` lease through B/formal-WB/lane0
    ROB-retirement, while hold blocks all new backend owners and lane1 retirement;
  - apply requires the lease, SQ active-write mask and DRAIN owner to be empty, then recovers the full backend and is
    broadcast through `OooControlFlushSequencer` to both memory request gates;
  - focused RTL covers delayed-OKAY store B, raw-restore/error-B same edge and AMO write drain with exact event counts;
  - F2 parent suite now requires 17 compile-success mutations, adding apply-guard and lane1-block bypasses.
- evidence state: preliminary focused simulations PASS; fresh same-design runner and v4 independent review pending.
- claim boundary: OOO-3 remains `GAP/RED`, overall `RED`, PPA `UNQUALIFIED` until those two steps pass.

## v8v-ooo3-final-review-v4/v4.1

- v4 contract JSON: `.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-ooo3-final-review-v4.json`
- v4 contract SHA-256: `63b4d743cdfb23ce5351146a63ddefc450a5aafa76640f5fc8336ad9171b4c74`
- v4.1 contract JSON: `.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-ooo3-final-review-v4.1.json`
- v4.1 contract SHA-256: `74b89059230c6856789c7fd0ad35ec43f056031ecf60672d05c9c03ee7cbc6b2`
- scope extension: v4.1 only added read-only inspection of `OooCoreSliceControlGate.v`; commands remained
  `rg`/`sed`/`git diff`/`sha256sum`, with no network or external service.
- verdict: `GAP (P1 evidence false-GREEN sensitivity)`; the request/hold/apply RTL protocol itself passed review.
- counterexample: adding raw `branch_spec_restore_i` to `core_local_flush_o` compiled and could bypass accepted apply,
  while the previous 41-source/54-provenance OOO-3 chain did not read or dynamically perturb ControlGate.
- repair implemented:
  - canonical source/provenance now binds ControlGate, MIQ, OwnerTracker and the core-glue integration TB/log;
  - `source.checkpoint_raw_restore_fail_closed` constrains the exact ControlGate local-flush expression;
  - F2 parent mutations increase to 18 with a compile-success ControlGate bypass mutant;
  - the core-glue oracle observes `raw_request=1 apply=0 local_flush=0 mem_flush=0,0` and rejects that mutant.
  - the rejection log is persisted, its mutant SHA is reproducible from the bound ControlGate source, and the
    original 45-source/60-provenance inventory binds both; v6 adds one focused non-no-op reconstruction unit source,
    so the refreshed closure requires 46 source files and 61 provenance files.
- evidence state: refreshed F2 parent PASS; candidate OOO-3 same-design run and v5 independent review pending.
- claim boundary: OOO-3 remains `GAP/RED`, overall `RED`, PPA `UNQUALIFIED` until both close.

## v8v-ooo3-mutation-reconstruction-review-v6

- contract JSON: `.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-ooo3-mutation-reconstruction-review-v6.json`
- contract JSON SHA-256: `68e3ce55eb21c30b80b1de162be08bcf72260affee9dd7281d600ad2e84d1b46`
- hash scope: only the JSON contract above; it does not bind RTL, tests, the F2 summary or design contract.
- dispatch mode: canonical `create → validate → render`, `self-contained-no-tools` frozen RTL evidence review;
  reviewer has no WSL shell ownership and consumes only the four supplied hardware facts.
- review target: determine whether `duplicate_bridge_drop_token` changes bytes and whether live-source reconstruction,
  non-no-op checks and per-name mutant SHA-256 equality close the 18-item false-activation evidence gap.
- status: review running; parent objective remains active and OOO-3 claim is unchanged until fresh execution and review
  both close.
