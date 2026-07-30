# V11H evidence index

- `evidence/pre-fix-prior-terminal-recovery/`: frozen pre-fix legal-interface
  counterexample.
- `evidence/load-queue-producer-attempt-1/`: preserved malformed-mutation
  runner FAIL.
- `evidence/load-queue-producer-attempt-2/`: preserved current-design graph
  binding FAIL.
- `evidence/load-queue-producer-attempt-3/`: 4 positive profiles, 31×2
  negative RTL simulations, summary PASS, original runner
  `FAIL@semantic-ledger-unit`.
- `evidence/load-queue-producer-attempt-3-checker-replay/`: frozen-input
  receipt, new checker positive/negative units, semantic ledger and PASS
  status for the pre-knownness-assertion design; historical after the current
  RTL change.
- `evidence/load-queue-producer-attempt-4/`: current-design 4-profile matrix,
  raw-Q knownness assertion probe, 31×2 negative RTL simulations and summary;
  original runner `FAIL@semantic-ledger-unit` is preserved.
- `evidence/load-queue-producer-attempt-4-checker-replay/`: attempt-4
  frozen-input receipt, exact system-rerun scope checks, replay builder 5/5,
  LoadQueue evidence checker 10/10, semantic ledger 24/24 and PASS status; no
  RTL simulation reexecution.
- `evidence/current-instance-graph/`: historical pre-knownness-assertion
  Yosys graph and PASS replay.
- `evidence/current-instance-graph-v2-initialization-attempt-1/`: preserved
  FAIL caused by stale census design/config bindings.
- `evidence/current-instance-graph-v2-replay-attempt-1/` plus
  `v11h-current-instance-graph-v2-attempt-1.status`: preserved census-unit
  FAIL caused by the old canonical evidence path.
- `evidence/current-instance-graph-v2/`: current-design Yosys result, receipt,
  canonical full hierarchy, script/log, census audit and PASS replay.
- `evidence/current-instance-graph-runner-attempt-1.md`: preserved runner
  publication-order FAIL.
- `evidence/ordinary-regression-attempt-1/` and review: both DUT simulations
  passed, but the old result filter produced a preserved FAIL.
- `evidence/ordinary-regression-attempt-2/`: LoadQueue and IntBackend standard
  regression PASS for the pre-knownness-assertion design.
- `evidence/ordinary-regression-attempt-3/`: current LoadQueue and IntBackend
  standard regression PASS; no V11H assertion marker.
- `evidence/architecture-hard-gates-with-manifest.json`: current 146-file
  architecture observation before the raw-Q assertion update, overall RED.
- `evidence/architecture-hard-gates-with-manifest-v2.json`: current
  design/Makefile observation, all DI-1..DI-5 and OOO-1..OOO-4 remain RED.
- `final-review-v2-result.md`: preserved independent GAP and its two blockers.
- `final-review-v3-result.md`: independent bounded APPROVE after both blockers
  were closed.
- `post-review-environment-closure.md`: post-review bounded briefs,
  `npc-dev` 5/5 and `agent-system` 11/11 published profile evidence, strict
  guard results, DB audits, final source identity and mixed-worktree commit
  boundary. This record does not widen the v3 technical verdict.
- `.github/task-runs/2026-07-30-semantic-replay-attempt-revtag-v11h/`:
  independently published `npc-dev` profile evidence used by the scoped
  strict guard.
- `.github/task-runs/2026-07-30-loadqueue-attempt-revtag-v11h/`:
  independently published the first current-source `agent-system` profile
  evidence.
- `.github/task-runs/2026-07-30-loadqueue-closure-revtag-v11h/`:
  fresh 11/11 `agent-system` publication after retained memory update; this is
  the final environment evidence used by scoped strict guard.
