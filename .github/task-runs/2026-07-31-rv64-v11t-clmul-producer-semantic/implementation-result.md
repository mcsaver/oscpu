# V11T CLMUL producer semantic result

## Outcome

`OooIntBackend.u_clmul_unit` now has current-design, product-path verification for the `clmul-producer` lifecycle without a production RTL change. The authoritative attempt is `evidence/attempt-2`: 22/22 focused profiles and 4/4 ordinary regressions PASS, including nine compile-success RTL mutations at generation widths 1 and 4.

The canonical producer/holder ledger is bound to design-id `sha256:82febf4aa834d61be398197015257714cc53d81f9291a2ba998ba28644041ac4` and advances only `clmul-producer`, yielding 36 PASS / 8 GAP across 44 semantic units. Whole architecture remains `RED`; PPA remains `UNPROMOTED`.

## Implemented verification and evidence flow

- Added the V11T focused overlay `npc/rv64/testbench/tests/tb_ooo_int_backend_v11t_clmul_producer.svh` and its deterministic runner/unit tests.
- Used stimulus-owned `{generation=1,index=2}` and exercised CLMUL plus CLMULH through the real `OooIntBackend.u_clmul_unit` instance.
- Observed request capture, RUN/RESP owner masks, wrong-generation exact-open rejection, WB0 identity/data, exactly-once retirement, accepted-terminal edge-old release and full-flush death.
- Bound nine compile-success mutations to their declared lifecycle stages and retained their logs/manifests/hashes.
- Reconstructed and hash-checked the generated focused TB in the semantic checker, then required all 36 retired secondary artifact records to be present and the corresponding paths to be absent.
- Reused older unit evidence only when its selected RTL/TB sources remain byte-current; only the testbench Makefile orchestration path is excluded from semantic drift, while actual RTL/TB drift remains fail-closed.
- Replaced repeated full-Yosys-tree parsing with the existing hash-bound V11O reachability projection. A normal ledger baseline fell from about 11.2 s / 1.5 GB peak to about 1.66 s / 50 MB without removing a semantic check.

## Retention and cleanup

- Retained authoritative attempt-2 results, logs, manifests and hashes; no `.vvp`, generated negative RTL or generated focused TB remains.
- The authoritative runner retired 36 secondary artifacts totaling 283,273,537 bytes; the later attempt/temp selection removed another 1,598,753 bytes, for 284,872,290 bytes removed in this round.
- Retained the current compact instance-graph audit and one latest full Yosys graph in the AxiCrossbar naming task-run.
- Migrated the current semantic ledger to `npc/rv64/design/arch/producer-holder-semantic-coverage.json`.
- Deleted superseded attempt-1 and five interrupted-unit-test temporary JSON files after recording their paths, sizes and summary hash in `cleanup-selection.json`; 1,598,753 workspace bytes were removed by this final selection step.
- Routed all negative-contract JSON fixtures to `.github/runtime-artifacts/test-scratch/producer-holder-semantic/case-*` with per-test teardown. The retained V11T cleanup receipt is now an explicit policy binding, so mutated summaries no longer need to be written beside authoritative evidence.
- Retained the compact 97-test result in `evidence/semantic-checker-tests.log`; post-test runtime scratch and repository-root `tmp*.json` counts are both zero.

## Claim boundary

V11T does not claim eight-younger pressure, global no-live-reuse, exhaustive timing interleavings, system recertification, synthesis, STA, power or PPA. A3 original `FAIL rc=1` and strict 16/17 remain unchanged; its frozen-input checker interpretation remains “system transaction complete, legacy dmesg oracle false positive.”

The next high-information semantic unit is `pending-system-producer`; seven floating-point producer paths remain after it.
