# V9D FDG-G1 current-design evidence report

## Implementer checkpoint

Production RTL was already correct and remains unchanged. The slice corrected
the machine owner path and re-bound FDG-G1 to the current RTL identity:

- classification/admission/final sink:
  `OooFetchHeadClassifyGate/OooFetchHeadPairGate` →
  `OooFrontendDispatchGate` → `OooFrontendBackendDispatchMux` →
  `OooCoreTopGlue`;
- precise-trap owner:
  `OooPendingDispatchArbiter` → `OooPendingTrapExitSequencer` →
  `OooCsrTrapRequestMux/CsrFile`;
- `NpcCoreTop.v` is not the owner of the FDG admission predicate.

The full-core program now exposes exact capture PC/tval, CSR `mepc/mtval`, one
known legal commit-observer hit and zero invalid-FP commits. Six current-source
RTL variants cover ordinary admission, lane1 dual dispatch, false-closed
admission, final backend packet presentation, trap PC and trap tval. All six
compile and are dynamically rejected. A verification-only commit-observer
sensitivity configuration also compiles and is rejected 1/1.

Canonical command: `make -C npc/rv64 check-fdg-arch-trap`.

## Current evidence

- design identity:
  `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`;
- focused legality/admission marker: four illegal cases blocked, one legal
  FADD.S reaches backend;
- full-core marker: capture PC/tval 1/1, ordinary/final backend 0, known commit
  hit 1, invalid FP commit 0, cause 2, CSR `mepc/mtval` 1/1, handler/MRET 1/1;
- dynamically derived module aggregate: 109/109 PASS;
- compile-success RTL source variants: 6/6 dynamically rejected;
- commit-observer sensitivity probe: 1/1 dynamically rejected;
- FDG fail-closed unit tests: 12/12 PASS;
- arch-stable audit and related unit tests: 58/58 PASS.

Evidence SHA-256 values:

- FDG result:
  `6238dbef481273da7d6acc00156a9bf1a23c90ebfb610498053377b66df88fb0`;
- FDG raw log:
  `47eb6b670d2ed21794fc0a2bd549cb8d823328f8e6044a343de8c1212302b765`;
- RTL variant/probe aggregate:
  `0f3b95063c45cdec383e1e7f4754708fbe834db392fc4cf74e51988ee5490459`;
- module aggregate summary:
  `c1512e98d3ba408e6331cba675632ca0f0ae8bcd0a061fe48791ff465cdac8e9`;
- focused/program logs:
  `a04421b43eea75f20a85c849786a14077e7b90663de1a94d1437bbae3583a27f` /
  `17bab7e728bd4c617ab742160ec4543756765db87edc005663d868c1c9c266f3`.

## Architecture and PPA boundary

All DI-1..DI-5 and OOO-1..OOO-4 directed gates remain GREEN on the same RTL
identity. The full-core audit remains an honest `GAP` with 44 blockers because
other debts, the full producer-holder census, a same-design functional
aggregate and freeze inputs remain unresolved. `ppa=UNQUALIFIED` and
`promotion_eligible=false` are unchanged.

## Reviewer checkpoint

The v1 hash-bound review returned `FAIL` with no P0 and two P1 evidence gaps:
commit-observer non-vacuity and exact PC/tval sensitivity. Both were implemented
and re-generated through the canonical command. The versioned v2 review then
returned `PASS` with no P0/P1. Its three P2 residuals are retained in
`review-summary.md`: per-lane commit sensitivity, multi-transaction trap
metadata pairing, and the explicit exclusion of the non-discriminating early
classifier-binding variant.

After the replay-determinism correction, versioned v3 contract SHA
`4df79c556a0c3ecc8d1198e9a758f9056b7d7649096f79f18dd6f6ffd88f8d06`
also returned `PASS` with no P0/P1. It accepted exact temporary-root
normalization, the composed fail-closed inventory boundary and ledger
rebinding. Its P2 limits are a theoretical reserved-token collision and the
requirement that the helper never be treated as a standalone inventory proof.

## Workflow correction

The first planned classifier-binding source cut compiled but was not rejected
because the correct upstream precise-trap owner intercepted the condition before
ordinary dispatch-valid. It was never counted. The contract and derivation were
updated to match the actually discriminating variant set before canonical
evidence regeneration. The module-log parser accepts the repository's two
established exact success formats while still rejecting any failure marker,
nonzero result, missing log or membership drift.

The first DB-memory idempotence replay also failed after the initial successful
publication: the project identity string was not literally present in its
entry, and the agent-system body was omitted by a bounded chunk read. The
updater was changed to exact-line upsert with a literal stable identity and a
20k-token bounded stored read. It removed only the duplicate V9D project entry.
A later exact adjacent-list-line check removed one pre-existing byte-identical
V9C NPC entry; the following execution reported all three documents unchanged.
Both failed replays remain workflow counterexamples rather than being hidden.

## Canonical replay determinism correction

A final canonical replay correctly invalidated the ledger binding even though
the RTL and semantic outcomes were unchanged. The root cause was evidence-only:
Icarus/make diagnostics embedded randomly suffixed module and RTL-variant build
directories under `/tmp`, and those logs were hash-bound into the FDG result.

`run-focused.sh` and `run-fdg-mutations.py` now replace only the exact current
temporary compilation-root string with `<FDG_TRANSIENT_TMP>` before hashing.
Repository paths, source names, compile options, diagnostics, directed-oracle
markers, return codes and result text remain unchanged. Module normalization
also rejects a log directory outside the repository, a transient path outside
the exact `/tmp/rv64-fdg-v9d.*` shape, an empty inventory, a symlink/alias or a
module log that does not contain the current temporary root.

Three tests cover pure exact replacement, all seven live variant/probe logs and
all 109 live module logs. Two consecutive canonical runs then produced the
same six SHA-256 values listed above. The ledger was rebound only after that
double replay; the following arch-stable audit passed 58/58 while remaining an
honest 44-blocker `GAP`.

## AI workflow and database closeout

- `npc-dev` completed at
  `.github/task-runs/2026-07-21-rv64-fdg-arch-trap-final-revtag-v9d/`;
- `agent-system` completed at
  `.github/task-runs/2026-07-21-rtl-evidence-workflow-final-revtag-v9d/`;
- `github-index` completed at
  `.github/task-runs/2026-07-21-github-index-contract-rerun-revtag-v9d/`;
- the earlier `stored-memory-fdg` github-index run remains blocked because its
  broad recall terms selected a primary memory chunk larger than the bounded
  brief budget; its contract node itself passed. The corrected domain-specific
  `github index contract` terms closed recall without changing the profile;
- `--validate-all-profiles`, DB-first audit, Markdown-coverage audit and strict
  guard all passed. The final snapshot contained 6832 stored documents; the
  DB-first audit reported 6939 candidates/6981 stored records and the Markdown
  audit reported `live_evidence=0`. Strict guard found all required final
  `agent-system`, `npc-dev` and `github-index` profile evidence.
