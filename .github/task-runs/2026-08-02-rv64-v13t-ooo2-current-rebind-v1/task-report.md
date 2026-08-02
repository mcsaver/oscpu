# V13T current-design OOO-2 rebind

## Classification and claim

- Primary class: `architecture`; workflow class: `development`.
- Claim boundary: current-design `OOO-2 selective_scheduling` only. No production RTL, whole-architecture, CPI or PPA promotion.
- Current RTL design-id: `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`.

## Falsifiable hypotheses

- H1: V13I packed IQ state retained selective scheduling and the RED result is only missing current-design evidence.
- H2: packed compaction or owner propagation introduced a real global issue freeze while a registered Universal owner is resident.
- H3: RTL behavior is correct, but the historical runner cannot safely emit a caller-owned scoped task-run or reports a status not derived from authoritative JSON.

The first release backend run immediately observed terminal1 progress with `global_freeze_cycles=0`, rejecting H2. The full rerun confirmed H1. H3 was also confirmed: the historical runner needed scoped output overrides and its refresh summary contained one hard-coded OOO-1 status.

## Implementation

Only `.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/run-focused.sh` changed:

- optional `V8M_EVIDENCE_DIR`, `V8M_ARCH_MANIFEST` and `V8M_ARCH_LOG` outputs, with resolved-path allowlists restricted to the canonical defaults or a task-run evidence subtree;
- refresh summary reads the real OOO-1 status from `architecture-result.json` instead of printing `OOO-1=GREEN` unconditionally.

Defaults remain unchanged, so `make -C npc/rv64 check-selective-scheduling` retains its historical entry point. No file under `npc/rv64/vsrc/**` changed.

## Current-design RTL and EDA observations

- Backend release/assert and IQ-leaf release/assert: 4/4 PASS.
- Backend metric: `blocked_dependents_only=1 younger_independent_issued=1 different_resource_issued=1 global_freeze_cycles=0 target_pid=3`.
- Leaf metric: `[R3P1-REGISTERED-OWNER-SOLE-ALU] PASS`.
- Five compile-success source mutations: 5/5 semantic rejection.
- Static checker/manifest unit tests: 33/33 PASS.
- `sources.pre.sha256` and `sources.post.sha256`: byte-identical.
- Negative path test: `V8M_EVIDENCE_DIR=/tmp/v8m-unsafe` is rejected with rc=1 and `[V8M-RUNNER][FAIL] unsafe evidence path` before any evidence deletion or simulation.
- Scoped manifest contains exactly `selective_scheduling=PASS`; hard-gate result is OOO-2 GREEN with zero RED checks, every other gate RED, overall RED.

## Evidence identity and boundaries

- Scoped manifest SHA-256: `474d45ebbde31bc1425379a75bc5c268317031abb3890d2b205bb41345cc0821`.
- Scoped architecture result SHA-256: `15b3f4bce266540ae9af89bea65bad193f4019ed7d90856b9540141fc0554d79`.
- Canonical architecture manifest was not targeted and remains SHA-256 `a0bd58bf4ef9bdfa7724087af3dcef79a72cb8384d8e1e8131d20957897c1bc1`.
- DI-1, DI-2, DI-5, OOO-1, OOO-3 and OOO-4 were not rerun. Full-system, CPI, synthesis, STA, area and power remain GAP/unpromoted.

## Review and artifact policy

- Two bounded independent reviewer attempts timed out and are explicitly GAP. The main-node reviewer checklist found no scoped OOO-2 blocker and retained the misleading-summary correction as an audit fact.
- Four preliminary manual baseline result directories and their `/tmp` builds were deleted after the complete runner regenerated the same profiles. The complete runner removed its own VVP and mutant sources; task-run retains bounded logs, JSON, source hashes, mutation summary and review records only.

Round status: `VERIFICATION_PASS_WITH_REVIEWER_AGENT_GAP`. Long-term RV64 goal remains active.
