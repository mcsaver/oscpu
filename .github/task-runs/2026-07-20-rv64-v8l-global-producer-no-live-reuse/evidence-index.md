# v8l evidence index

## Contract and derivation

- `contract.md` — field, identity, handoff, death-edge, finite-wrap and claim-boundary contract.
- `rtl-derivation.md` — production dataflow/root-cause derivation.
- `holder-census-draft.md` — pre-implementation derivation, explicitly superseded by the manifest.
- `npc/rv64/design/arch/producer-holder-census.json` — permanent machine ledger.
- `npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md` — durable architecture spec.

## Focused and mutation evidence

- `run-focused.sh` — reproducible assert/release baseline and compile-success mutation runner.
- `evidence/focused/runner-summary.log` — `baselines=8/8 mutations=9/9 static=PASS`.
- `evidence/focused/baseline-summary.log` — profile-by-profile focused results.
- `evidence/focused/mutation-summary.log` — each mutation name, compile PASS, and observed consequence.
- `evidence/focused/sources.pre.sha256` / `sources.post.sha256` — canonical source stability proof.
- `evidence/focused/static/producer-holder-census-result.json` — source/manifest/checker hash-bound result.
- `evidence/focused/static/checker-unit.log` — 9 mutation-oriented checker tests, including a non-`_q`
  exact-width full-P register escape attempt.

## Regression and static evidence

- `run-regressions.sh` — v8d..v8l focused and fresh module aggregate runner.
- `evidence/regressions/summary.md` — focused 8/8, aggregate 106/106.
- `evidence/regressions/complete.marker` — hashes of regression evidence.
- `run-static-gates.sh` — style/census/contract/lint-signature/architecture inventory runner.
- `evidence/static-gates/summary.md` — truthful static summary.
- `evidence/static-gates/architecture-gates.log` — checker self-test 15/15 and real `OVERALL: RED`.
- `evidence/static-gates/lint.log` — inherited rc=2 / 115-warning signature.
- `evidence/static-gates/complete.marker` — hashes of static evidence.

## Review evidence

- `subagent-contracts/v8l-global-producer-contract-review.json` — first no-tools contract review contract,
  SHA-256 `59e014f7700d073d01bb9d1575a262181e38464181fedc6ce5289f630c1486c1`.
- `contract-review-result.json` — first verdict `gap`.
- `subagent-contracts/v8l-global-producer-contract-amended-review.json` — amended contract review,
  SHA-256 `2c4e54e9b85759baa2a8e57a7ace7eece4972ca0d48b5d31bc8df0797a4d1708`.
- `contract-amended-review-result.json` — amended verdict `pass`, implementation not yet promoted.
- `subagent-contracts/v8l-global-producer-implementation-review.json` — implementation review contract,
  SHA-256 `67b3f82fb7dfec776ab34d32160e1c1ae31ff7ef74f52eef64c5b7b61110cc99`.
- `implementation-review-result-schema-mismatch.json` — preserved first response; semantically positive but
  contract-invalid and therefore not accepted.
- `implementation-review-result.json` — corrected strict-schema verdict `pass` with claim boundary.

## Workflow e2e evidence

- `.github/task-runs/2026-07-20-rv64-v8l-global-producer-npc-dev-e2e/` — retained blocked run:
  all five engineering nodes PASS, but context brief had no independent primary match because the slug omitted
  the canonical `ProducerId holder census` vocabulary.
- `.github/task-runs/2026-07-20-producerid-holder-census-npc-dev-final/` — final semantic-slug
  `npc-dev` run, completed.
- `.github/task-runs/2026-07-20-producerid-holder-census-agent-system-final/` — final
  `agent-system` run, completed.
- `.github/task-runs/2026-07-20-producerid-holder-census-github-index-final/` — final
  `github-index` run, completed.

## Publication boundary

The evidence supports only `v8l/global_no_live_reuse` scoped GREEN under the bound sources/configuration.
Architecture remains `OVERALL: RED`; PPA is unpromoted.
