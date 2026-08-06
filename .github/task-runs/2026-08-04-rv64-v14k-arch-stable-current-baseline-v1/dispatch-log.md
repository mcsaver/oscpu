# V14K RV64 subagent dispatch log

## v14k-independent-review

- contract: `.github/task-runs/2026-08-04-rv64-v14k-arch-stable-current-baseline-v1/subagent-contracts/v14k-independent-review.json`
- contract SHA-256: `53bbea21c6e914880319ad62b244c8381a87fa1c8bd7d70c2a352d83dd993191`
- binding: the SHA-256 above binds only the contract JSON.
- task kind: `read-only-review`
- shell ownership: transferred to the reviewer for the declared `rg`, `sed` and `sha256sum` reads; the primary agent runs no WSL engineering command until review completion.
- result: `GAP`; V14E compile sidefiles were intentionally removed but their cleanup receipt was not cross-checked with retained TB execution, QH positive counts were aggregate-only, V14G log return-code headers were not parsed, explicit historical gate selection could precede its architecture-debt dependency, and exit source/config declarations were not bound to the actual invocation.
- disposition: preserved the cleanup policy and added cleanup-manifest/zero-RC-hash/TB-log conjunction; added raw QH and V14G header parsers; normalized the C gate dependency; added exact exit source/tool/config validation.

## v14k-independent-review-v3

- contract: `.github/task-runs/2026-08-04-rv64-v14k-arch-stable-current-baseline-v1/subagent-contracts/v14k-independent-review-v3.json`
- contract SHA-256: `b7f70fb45c8d1b3c8dbdb27c1e47861ee5dc87ef878793851251fa7da6289ecb`
- binding: the SHA-256 above binds only the contract JSON.
- task kind: `read-only-review`
- shell ownership: transferred to the reviewer for the declared `rg`, `sed` and `sha256sum` reads; all reviewer commands ended before the primary agent resumed WSL work.
- first result: `GAP`; the exit compile log did not prove the exact compiler/source argv and the simulation log did not retain the actual `vvp ... +V10D_ONLY` argv.
- second result: `GAP`; the invocation was bound, but a mutation source with the right basename in a different scratch directory could still be accepted.
- final result: `PASS`; compile image is now exactly under `/tmp/rv64-historical-exit-current-*`, each mutation source is exactly `image.parent/<mutation>/<module>.v`, and the cross-scratch counterexample is rejected.

## methodology research node

- mode: public first-party documentation only; no workspace read/write and no WSL command ownership.
- sources adopted as principles: RISC-V ratified specs and ACT, Arm AMBA AXI Issue L, OpenTitan DV/signoff/DVSim, lowRISC style, OpenHW CORE-V, and public ISO/IEC/IEEE lifecycle summaries.
- claim boundary: the repository uses these public principles as a tailored local workflow; it does not claim access to vendor-internal practice, external certification, OpenTitan V3, or full AXI/RISC-V certification from a bounded test result.

## durable decision trace

- Keep only retained logs, compact receipts, hashes and review decisions; regenerated VVP images, mutation RTL and compiler sidefiles remain removed.
- Treat `review` and `analysis` as zero-gate tasks. Run affected-domain evidence during development, then execute C-selected gates and independent review once at the deterministic delivery point.
- A direct historical-defect Make target is a component check. The C pointer is the integrated entry and always normalizes `rv64-architecture-debt-current` before `rv64-historical-defect-current`.
- Preserve the A3 original `FAIL rc=1`; checker replay is a separate PASS receipt. Historical-defect closure does not promote whole architecture or PPA.
- result: `GAP`; aggregate profile fields did not fully bind retained log marker/return-code observations, and the C route did not cover the full 146-file RTL identity or every build-control/schema input.
- disposition: converted to directed unit tests and fixed in the current receipt validator and C path router; no production RTL changed.

## v14k-independent-review-v2

- contract: `.github/task-runs/2026-08-04-rv64-v14k-arch-stable-current-baseline-v1/subagent-contracts/v14k-independent-review-v2.json`
- contract SHA-256: `3b9295e99952346b6c594450059bad41545cb3dabab82cb255dafcce5cd8077e`
- binding: the SHA-256 above binds only the contract JSON.
- task kind: `read-only-review`
- shell ownership: transferred to the reviewer for the declared `rg`, `sed` and `sha256sum` reads; the primary agent runs no WSL engineering command until review completion.
