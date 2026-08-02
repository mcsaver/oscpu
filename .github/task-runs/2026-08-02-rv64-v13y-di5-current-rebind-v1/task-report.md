# RV64 V13Y — DI-5 current-design rebind

## Classification and claim

- Primary classification: `architecture` (lightweight workflow class: `development`).
- Claim: `DI-5 dual_memory_issue` for two ordinary cached-load transactions from `OooIntIssueQueue` pair selection through AGU, translation, physical LSQ query, cache admission and completion.
- Current RTL identity: `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`, 146 files.
- Production RTL changes: none under `npc/rv64/vsrc/**`.
- Scope result: `APPROVED_FOR_CURRENT_SCOPE`; overall architecture remains RED and PPA remains UNQUALIFIED.

## Implemented evidence workflow

- Added task-run-v1 source/proof inventories for `dual_memory_issue` in `architecture_hard_gates.py`.
- Extended `dual_memory_issue_evidence.py` with bounded task-run paths, exact 54-role proof binding, simulator receipts, positive trace parsing, per-variant compile/source/image receipts, F1 current evidence validation and F2 frozen replay validation.
- Added scoped mode to the historical V8U runner so it publishes only `dual_memory_issue` under the selected task-run and never rewrites the canonical architecture manifest.
- Removed Git repository-root discovery from the V8U runner/mutation path; paths derive from the script location and are constrained to the selected task-run root.
- Updated the `iq_pair_pop_only_entry0` negative RTL cut to the current `compact_remove_w` mask representation: `8'b0000_0011` → `8'b0000_0001`.
- Added focused unit tests for exact 64-cycle parsing, inactive-face rejection, mutation aggregate rejection, current RTL anchor uniqueness, bounded task-run paths, allowed F2 checker/evidence drift and task-run proof role/hash/log binding.

## Positive and negative observations

- Six OOO_ASSERT profiles clean PASS: MIQ, IQ, integer backend, memory AXI bridge, focused backend partial-consume and sustained system.
- Sustained window: 64 cycles; every cycle has `agu=11`, `translation=11`, `query=11`, `cache=11`, `completion=11`.
- Metrics: memory IPC 2.000; dual-issue cycles 64; both faces report 64 accepts/completions at every observed stage.
- Seven compile-success RTL variants each have a single activated cut, live-source SHA, distinct mutant SHA, compiled image SHA, nonzero simulation return, specified RTL oracle, exactly one `[RESULT] FAIL` and no PASS.
- Full-core NpcCoreTop baseline has no `UNOPTFLAT`; `backend_next_requires_response_fire` recreates it.
- Focused checker/manifest/DI-5 unit suite: 44/44 PASS.

## Identity, predecessor and publication binding

- Scoped manifest and live design-id match exactly; the manifest contains only `dual_memory_issue`.
- All 54 proof-role artifacts recompute to their recorded hashes.
- F2 replay source: `2026-08-02-rv64-v13u-ooo3-current-rebind-v1`; same design-id, F2 PASS, 18/18 variants, equal source pre/post, selected RTL and two TB hashes current.
- Five replay drifts are explicitly enumerated and checked as non-DUT evidence changes: the unrelated Makefile census entry, producer-holder census JSON/test, architecture checker, and the old F1 result path superseded by the new current F1 evidence.
- Current F1 binding: 10/10 variants, 8/8 profiles, equal source pre/post, live bridge/dcache/wrapper RTL SHA and unique `[V8R-F1][PASS]` terminal marker.
- Canonical `npc/rv64/eval/ppa/evidence/architecture-current.json` remains `sha256:a0bd58bf4ef9bdfa7724087af3dcef79a72cb8384d8e1e8131d20957897c1bc1`.
- Scoped aggregate: only DI-5 GREEN; `OVERALL: RED`; PPA UNQUALIFIED.

## Execution incident and audit disposition

The first launch set scoped variables in PowerShell but did not pass them through `wsl.exe`; the V8U runner entered canonical mode. F0/F1 completed and F2 stopped fail-closed on source-closure drift. No DI-5 result was published by that attempt.

Canonical startup removed the historical V8U `evidence/final-run` and `evidence/mutations-final` directories. Their exact original bytes are not recoverable; the historical V8U task report remains but cannot replace those raw logs. This is retained as a permanent historical audit GAP in `evidence/INCIDENT-2026-08-02.md`. The newly generated current F1 result is documented in the V8R refresh note and copied into this task-run with hashes; it does not reconstruct the missing V8U history.

The final scoped execution was rerun from compilation through publication and returned:

`[V8U-F4-RUNNER][PASS] run_id=v13y-di5-current-20260802-r2 mode=1 trace=64 ipc=2.000 dual_cycles=64 per_bank_faces=64,64 mutations=7 DI-5=GREEN overall=RED ppa=UNQUALIFIED`

## Implementer and reviewer dispositions

- Implementer: PASS for current-design DI-5; GAP for byte-exact audit of the deleted 2026-07-20 V8U final/mutation logs.
- Independent frozen-material reviewer: `APPROVED_FOR_CURRENT_SCOPE`; no blocking false-green, hash-binding, predecessor or scope-promotion counterexample.
- Review contract: `.github/task-runs/2026-08-02-rv64-v13y-di5-current-rebind-v1/subagent-contracts/v13y-di5-frozen-final-review.json`, SHA-256 `282a20f36286a08b37e4a72c0372c4f5cc9d68fae9c4fd430b38cc240cbdccbc`.

## Lightweight workflow closure

- Explicit-path agent-flow records 13 changed paths in eight directories without whole-worktree Git enumeration.
- The only selected delivery gate was `rtl-task-contract`; audit/self-test/CLI self-test PASS in 1.055 s.
- Recorded workflow overhead is 0.04% against the advisory 40% design target; it is not a delivery gate.
- Final compact task-run contains 91 files (about 1.5 MiB). It contains no `.vvp`, `.pyc`,
  object/archive, `build`, `tmp` or `__pycache__` payload. Reproducible simulator images remain excluded.
- PASS/GAP evidence and the decision trace are in the task-run root; the ordinary evidence index is
  refreshed without a fabricated completion marker or canonical architecture publication.

## Boundaries and next architecture pointer

This evidence proves sustained dual-face throughput for the directed ordinary cached-load configuration. It does not prove same-cycle zero-latency passage of one pair, transaction address/tag/data/retirement correctness, same-bank conflict, miss/MSHR, replay, TLB fault, misalignment, load/store ordering, flush, exception, arbitrary backpressure, unbounded liveness, overall architecture, CPI or PPA.

Next mainline pointer: current-design `DI-1 frontend_ii1`, followed by `DI-2 width_continuity`. Canonical architecture and PPA remain unpromoted until the remaining gates close under the same design/configuration contract.
