# V11A dispatch log

## Implementer

- Main agent retained the single Windows-to-WSL engineering shell.
- Fresh `NpcTop` Yosys hierarchy elaboration and byte-identical replay passed.
- Production Verilog/SystemVerilog source semantics were unchanged.

## Independent final review v1

- Contract:
  `.github/task-runs/2026-07-29-rv64-v11a-producer-holder-instance-graph/subagent-contracts/v11a-holder-instance-graph-final-review-v1.json`
- Contract JSON SHA-256:
  `f604cf58ea1d173825d13fe3dc65f83b703a15ac1ae32fd9c9a94639c78d260f`
- The SHA-256 binds only the JSON contract.
- Canonical pipeline: `create -> validate -> render`, all PASS.
- Mode: `workspace-files`, read-only review.
- Shell ownership is handed to the reviewer for the contract-listed read-only
  commands; the main agent runs no WSL engineering command until the reviewer
  returns it.

### Reviewer v1 result

- Verdict: GAP.
- The 17 current paths and both duplicated module pairs were confirmed.
- Blocking counterexamples: synchronized frozen rewrite, incomplete
  ARCH_STABLE dependency closure, out-of-scope topology root, unbound exact
  Yosys inputs/script, and stale runner PASS publication.
- Shell ownership was returned with no residual engineering process.

## Implementer remediation after v1

- Added strict result and normalized-receipt schemas with exact field, count,
  source-list, script, log, elaborator and graph validation.
- Added synchronized duplicate-removal, null elaborator, canonical-script
  drift, parent-Make tracing, and ARCH_STABLE dependency negatives.
- Changed the topology root to `NpcTop`.
- Changed the canonical Make gate to execute the fail-closed fresh runner.
- Added status-helper initialization, stage tracking, signal handling, summary
  invalidation and explicit evidence completion.
- Bound the checker, unit test, fresh runner and status helper into
  ARCH_STABLE workflow inputs.
- Rebound closed-debt and control-event currentness evidence without changing
  production RTL.

## Independent final review v2

- Contract:
  `.github/task-runs/2026-07-29-rv64-v11a-producer-holder-instance-graph/subagent-contracts/v11a-holder-instance-graph-final-review-v2.json`
- Contract JSON SHA-256:
  `a93b238f598ee8a7829f83ef06c954a62348c15e762b20ae5df1a5ec05f21436`
- Canonical pipeline: `create -> validate -> render`, all PASS.
- Mode: `workspace-files`, read-only review.

### Reviewer v2 result

- Verdict: GAP.
- The v1 blockers were materially closed, but a synchronized
  result/receipt/manifest rewrite still lacked an immutable full elaborator
  document as the independent anchor.
- Additional blockers were the missing original ARCH_STABLE unit log,
  noncanonical evidence-path acceptance, missing explicit fresh predecessor
  gate and insufficient dynamic runner stale-PASS fixtures.
- Shell ownership was returned with no residual engineering process.

## Implementer remediation after v2

- Added the complete canonical Yosys JSON gzip as the fifth evidence artifact.
- Rebuilt the receipt and reachable graph directly from that document.
- Limited canonicalization to process-local `$0x<hex>:` map-key tokens and
  added fail-closed collision coverage.
- Enforced five exact canonical evidence paths and hashes.
- Added six dynamic runner fixtures covering missing helper, unit failure,
  full-JSON mismatch, source drift, cleanup signal and success publication.
- Preserved the raw ARCH_STABLE 50/50 log in the V11A evidence directory.
- Added the missing V9N owner-residency refresh before final currentness
  publication.

## Independent final review v3

- Contract:
  `.github/task-runs/2026-07-29-rv64-v11a-producer-holder-instance-graph/subagent-contracts/v11a-holder-instance-graph-final-review-v3.json`
- Contract JSON SHA-256:
  `9cbd239a4c9814c2f87416fc909b949ac6c8ebfa4f44f4eb76ac4d34c9409bc3`
- Canonical pipeline: `create -> validate -> render`, all PASS.
- Mode: `workspace-files`, read-only review.

### Reviewer v3 result

- Verdict: `APPROVED_FOR_CURRENT_SCOPE`.
- Confirmed 15 holder modules, 17 holder instance paths, 194 reachable
  user-module instances and the two dual-instance module pairs.
- Confirmed all five artifact hashes, complete JSON content,
  canonicalization/collision boundary, fresh Make predecessor, stale-PASS
  fixtures, ARCH_STABLE 50/50 and currentness 16/38/32/0.
- Preserved `semantic_complete=false`, whole architecture `RED` and PPA
  `UNPROMOTED`.
- Shell ownership was returned with no writes or residual engineering process.

## E2E publication and guard

- An over-broad slug-derived focus was rejected by bounded non-history recall.
  Its blocked task-run remains unchanged even though its five profile nodes
  individually passed.
- The reduced independent focus `producerid holder` completed the `npc-dev`
  profile as
  `.github/task-runs/2026-07-29-producerid-holder-revtag-v11a/`, 5/5 PASS.
- `evidence-index.md` records all 13 V11A raw evidence assets by path, size,
  SHA-256 and bounded summary.
- A 12-path V11A scoped strict guard explicitly bound that completed
  publication and passed.
- The full mixed-origin worktree guard passed `agent-system`,
  `rv64-systemd-contract` and `npc-dev`; it retained one unrelated
  `rv64-linux` missing-evidence GAP for
  `Linux/scripts/check-ubuntu-rootfs.sh`.
