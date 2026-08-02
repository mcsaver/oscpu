# Implementation result

## Testbench and runner

- `run_v11u_pending_system_producer_semantic.py` generates isolated overlays for `tb_ooo_int_backend.sv` and `tb_ooo_priv_system.sv`, then selects them through a generated Make include. The shared testbenches retain SHA-256 `252c0df0...90af` and `6e1aeb99...e2a3`.
- Attempt-5 covers the leaf sequencer/mux, isolated backend live-mask at `PRODUCER_GEN_W=1/4`, real parent/wrapper paths, exact commit death and production-net core-local flush death.
- The runner creates 18 compile-success RTL variants, records 21 mutation profiles, retains logs/results/hashes, and removes generated overlays, variants and VVP images only after validation.
- Runner unit tests pass 10/10.

## Semantic checker and ledger

- Policy now binds attempt-5 and the current AXI naming-refresh holder instance graph at design ID `sha256:82febf4aa834d61be398197015257714cc53d81f9291a2ba998ba28644041ac4`.
- The checker validates exact production paths, shared-TB hashes, overlay replacement receipts, generated Make content, EDA tool identities, source pre/post manifests, all profiles/markers/mutations/regressions, terminal runner status and all 66 cleanup records.
- The immutable legacy oracle label is interpreted fail-closed as ten release-mode plus eight assertion-mode mutation cases. A negative fixture rejects inconsistent parent mutation mode metadata.
- V11H frozen checker replay passes. Semantic replay/checker tests pass 112/112; runner tests pass 10/10.
- Ledger attempt-10 remains global `GAP`: 37 of 44 units PASS and seven FP units GAP. `pending-system-producer` is current selected-source/TB bound and PASS.

## Production RTL

No production RTL change was required. There is no full-system, synthesis, STA, power or PPA promotion.
