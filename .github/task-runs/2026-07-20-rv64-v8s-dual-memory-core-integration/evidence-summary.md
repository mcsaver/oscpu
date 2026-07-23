# v8s/F2 evidence summary

## Fresh aggregate

- Run: `v8s-f2-20260720T080613Z-1010841`
- Result: `evidence/focused/result.json`
- Final marker: `evidence/focused/final.log`
- Source closure: `2334b38fd33e69d95e7ee2dbe40264a3dfb2fec61a00c0388b4edd233e11d2e2`
- Backend SHA-256: `84024f9bdf7683201e442ba68f630fadfd7cb8d264e1e6ce5ca81dbf895da898`
- Canonical core SHA-256: `e532a990524c11a80d3c16a6107481f33855f6386b64f5aa8f9a256ddbb42ef7`
- Focused TB SHA-256: `a961cddf217549473c8c6dba91ac1a99c4d461f03ff660c8d7d69eac2a21a580`

## Static and topology evidence

- `evidence/focused/static/source-checks.json`: 17/17 source/claim checks PASS, including exact
  parameter handoff, canonical enable count, `dual_wrapper=1/legacy_bridge=0/core_glue=1`, two exact
  lane faces, non-tied mem1 face, two MIQs, independent ROB query, global WB, 10-ingress collector,
  dual SQ ports, holder census and RED/unqualified claim boundary.
- `evidence/focused/static/checker-unit.log`: 13/13 checker mutation-negative tests PASS.
- `evidence/focused/static/npc-core-release-lint.log`, `npc-core-assert-lint.log`,
  `npc-sim-assert-stats-lint.log`: canonical full-top elaboration/lint PASS.
- `evidence/focused/static/f1-permanent-target.log` and `f1-handoff.json`: fresh predecessor PASS,
  `canonical_stage=F2_PROMOTED`, leaf claim only.
- `evidence/focused/static/architecture-hard-gates.json`: expected fail-closed DI-5/OOO-3/overall RED;
  canonical architecture manifest pre/post hashes match.

## Behavioral profiles

- `evidence/focused/profiles/focused-release.run.log`: F2 directed release PASS.
- `evidence/focused/profiles/focused-assert.run.log`: same scenarios under `OOO_ASSERT` PASS.
- `evidence/focused/profiles/legacy-assert.run.log`: reusable default-off path retains v8p behavior.
- Both F2 profiles contain `[V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS` and
  `[V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS`.

## Semantic mutations

`evidence/focused/mutation-summary.log` records 11/11 compile-success, elaborated, activated and
target-rejected mutations: bank1 tie-off, bank swap, age inversion, MIQ1 query alias, WB0 double
claim, SQ terminal1 tie-off, duplicate drop token, killed mem1 WB escape, ordinary-store direct
write, singleton priority bypass and release-edge look-through.

## Independent bounded review

- Invalid manual draft SHA `6ce32465…4ee` failed canonical validation; its response is
  `candidate-only` and is not evidence.
- Canonical v1 contract `subagent-contracts/v8s-f2-implementation-evidence-review.json`, SHA
  `b344fa46…5e40`, produced `implementation-review-gap.json`, SHA `9c2d0827…a4e9`.
- Canonical v2 contract `subagent-contracts/v8s-f2-implementation-evidence-rereview.json`, SHA
  `4de07763…cd6b`, produced `implementation-review-result.json`, SHA `4ff6f36b…a6fe`, verdict PASS
  for `architecture_checkpoint` only.

## Workflow solidification evidence

- RTL task contract: canonical `create -> validate -> render`, verbatim prompt boundary,
  `candidate-only` on validation/prompt drift, versioned scope extension and current-node-only
  platform interruption are encoded in Skill/instruction/config/render output.
- The first `agent-system` forward profile is intentionally retained as blocked: its contract node
  exposed a prose-line-wrap-sensitive e2e check. The gate now checks JSON path, file SHA-256 and
  JSON-only binding as separate semantics instead of accepting a hand-edited report.
- Skill gates: `rtl_task_contract.py audit`, `self-test` (24 cases), `cli-self-test` (19 cases),
  `github_index_db.py skill-audit`, and system `quick_validate.py` all PASS.
- Phase promotion: `check-dual-memory-bridge-wrapper` recognizes exact F1/F2 states; F2 permanent
  target fresh invokes it and binds its run-id/closure.

## Claim boundary

This summary supports only `architecture_checkpoint`. It does not support F3 final-PA SQ
query/replay, F4 sustained IPC/system behavior/equal-capacity banking, architecture GREEN, PPA
qualification or promotion.
