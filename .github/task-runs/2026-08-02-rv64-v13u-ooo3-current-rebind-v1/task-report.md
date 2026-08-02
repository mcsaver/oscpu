# V13U current-design OOO-3 memory-ordering rebind

## Classification and claim

- Primary class: `verification`; supporting class: `tooling/workflow`.
- Claim boundary: current-design `OOO-3 memory_ordering` only. No production RTL, whole-architecture, CPI or PPA promotion.
- Current RTL design-id: `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`.

## Falsifiable hypotheses and root cause

- H1: the current `OooLoadQueue`/`OooStoreQueue` semantics still satisfy OOO-3 and only the historical evidence is stale.
- H2: the V13B generated hit-vector/onehot refactor and later SQ TB strengthening drifted historical source-mutation and marker anchors without changing the hardware contract.
- H3: the current release, recovery, response-order or terminal lifecycle contains a real RTL regression.

The first current mutation run stopped before compilation at `issue_killed_bypass` because its old procedural anchor no longer existed. Five strict current-representation anchors restored unique cuts; 9/9 mutants then compiled and were dynamically rejected by their exact LQ oracles. The first full runner stopped fail-closed on the historical SQ marker; the live TB emitted the stronger `allow/dual-offset/typed/merge/youngest/partial/x-poison/x-ignore3/terminal/dual PASS` marker. After rebinding that exact marker, the complete runner passed. H1 and H2 are supported; H3 is not supported within the tested OOO-3 scope.

## Implementation

- `run-lq-mutations.py` now selects exactly one historical or current RTL representation per mutation and records `anchor_representation` plus anchor SHA-256. Missing, duplicated or simultaneously live representations fail before compiling a mutant.
- `run-focused.sh` supports an opt-in task-run scoped mode. Resolved outputs must share one `.github/task-runs/*/evidence` root; scoped mode cannot overwrite the canonical architecture manifest, cannot claim predecessor gate closure, and derives its GREEN set from the actual architecture result.
- `memory_ordering_evidence.py` accepts explicit current F2 inputs and run-id, publishes 12 named task-run proof roles and binds every role/path/SHA into the gate log and aggregate proof digest.
- `architecture_hard_gates.py` checks the exact 12-role inventory, task-run path boundary, live artifact hash, unique gate-log binding and aggregate proof digest. Unit tests cover positive binding, stale proof and missing role.
- The current SQ marker is bound exactly; the obsolete marker is not accepted as a permissive alternative.
- `ooo-load-queue.md` now numbers its 12 load-queue invariants continuously. Because the spec is source-manifest bound, the complete runner was rerun after this documentation correction.
- No file under `npc/rv64/vsrc/**` changed in this round.

## Current-design RTL and EDA observations

- Six `OOO_ASSERT` profiles (`lq`, `sq`, `backend`, `backend-dual`, `glue`, `sustained`) are 6/6 PASS; each raw log contains exactly one `[RESULT] PASS` and no accepted failure marker.
- OOO-3 quantitative/boolean metrics are 11/11 PASS.
- LQ compile-success source mutations are 9/9 compiled, exact-oracle observed and dynamically rejected.
- Current F2 parent evidence contributes 18/18 compile-success dual-memory-core mutations and a live TB/RTL hash binding.
- Evidence/manifest unit suite: 38/38 PASS. Hard-gate counterexample suite inside `arch-gates`: 31/31 PASS.
- `sources.pre.sha256` and `sources.post.sha256` are byte-identical, both SHA-256 `a12535809777d3abcc2d67e95d5f89398ed8bd974a59dad334c321b06c1907dd`.
- Scoped manifest contains exactly `memory_ordering=PASS`; OOO-3 is GREEN. Every other architecture gate is RED, overall is RED, PPA is `UNQUALIFIED`, and `promotion_eligible=false`.

## Evidence identity and boundaries

- Scoped manifest SHA-256: `90e4421f343f7b5027c99e23e4631d70a19e8f6ea01b58bb029e8aea9fdff500`.
- Scoped architecture result SHA-256: `c9c4813923841df6adab63fc9f2a8c1a8421796ab38ecfc12e7a8d836d2817f7`.
- LQ mutation result SHA-256: `4d16da0d41fd24ecfbb89830880afc0a0419d43798354bb921612620f364222c`.
- Canonical architecture manifest remains the prior SHA-256 `a0bd58bf4ef9bdfa7724087af3dcef79a72cb8384d8e1e8131d20957897c1bc1` and was not targeted by scoped publication.
- The scoped F2 refresh records a producer-holder/global-census contract GAP caused by packed-IQ and global instance/Yosys binding drift. OOO-3 reuses only the explicitly validated F2 result, mutation summary and control-gate mutation log; it does not claim that global census is closed.
- Full-system, CPI, synthesis, STA, area and power remain NOT_RUN/GAP. Correct memory ordering does not prove useful dual-issue concurrency or performance.
- Global `audit-db-first` remains RED because six unrelated 2026-08-01 historical task-run Markdown files have no stored copies. The four retained V13U Markdown documents were independently materialized and each compared byte-identical (`cmp=0`) to live content; no unrelated historical archive was rewritten.

## Review and artifact policy

- The workspace-files reviewer independently found the duplicated invariant number and returned an initial evidence-PASS/declared-GAP direction, but did not return a formal final response within the bounded window. Its result is `GAP`, not PASS.
- After the numbering correction and complete rerun, a separate no-tools reviewer gave `APPROVED_FOR_CURRENT_SCOPE` for the frozen OOO-3 facts. It explicitly did not claim complete source review, overall architecture, CPI or PPA approval.
- Six duplicate `precheck-*` directories were removed after the complete runner regenerated their content. They were reproducible and are not recoverable as deleted files, but their retained replacements are under `evidence/ooo3-current/`.
- The runner removed its temporary VVP and mutant trees. The task-run retains bounded logs/results/hashes/contracts only; no VVP, object, archive or synthesis intermediate remains.

Round status: `PASS_WITH_DECLARED_GAPS`. The long-term RV64 goal remains active.
