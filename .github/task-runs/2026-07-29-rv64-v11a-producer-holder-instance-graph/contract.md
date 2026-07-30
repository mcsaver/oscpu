# RV64 V11A ProducerId holder instance-graph contract

## Local RTL object

The bounded object is the current product `NpcTop` elaboration and the
`ProducerId`/owner-token holder modules declared by
`npc/rv64/design/arch/producer-holder-census.json`.

The configuration is fixed to:

- top module `NpcTop`;
- `OOO_CSR_QUEUE_HEAD=1`;
- `OOO_TERMINAL_HOLDER_ASSERT=1`;
- the exact `npc/rv64/vsrc` source-set design identifier;
- the exact `npc/rv64/Makefile` and
  `npc/rv64/configs/product-rtl-defaults.mk` hashes recorded in the manifest.

## Claim

This task may set `scope.instance_graph_complete=true` only if a fresh Yosys
hierarchy elaboration proves that every holder-bearing module has an exact,
reachable `NpcTop` instance declaration and that no additional live instance is
omitted. Parameterized module types must be normalized to their source module
name without collapsing distinct instance paths.

The claim is limited to module-instance multiplicity. It does not set
`semantic_complete=true`, does not grant global no-live-reuse, does not grant
whole-architecture GREEN, and does not qualify PPA.

## Required positive evidence

1. Fresh elaboration returns `PASS` for the exact current design ID.
2. All 15 holder-bearing source modules map to the exact live instance set.
3. `OooMemInflightQueue` and `OooMemAxiBridge` each retain both physical
   instances; no deduplication by module name is allowed.
4. The exact ordered 127-file Yosys input list and the path-stable Yosys script
   are frozen by path and SHA-256; the script itself names every input and an
   explicit output placeholder.
5. Five distinct artifacts are bound at exact canonical paths: strict checker
   result, normalized Yosys receipt, canonical full Yosys JSON gzip, canonical
   Yosys script and Yosys log. The receipt must be rebuilt directly from the
   full JSON rather than copied from the result.
6. The full JSON retains the complete Yosys document with deterministic map
   ordering. Canonicalization may normalize only process-local
   `$0x<hex>:` map-key tokens to `$0xADDR:` and must reject a resulting key
   collision; values and all other keys remain unchanged.
7. The frozen-audit path verifies canonical gzip bytes and map ordering,
   rebuilds the reachable graph from the full JSON, and recomputes current
   source/config/declaration/checker, exact input-list and canonical-script
   bindings without invoking Yosys.
8. The canonical Make target always performs a fresh elaboration and requires
   byte-identical result/receipt/full/script/log before accepting the frozen
   audit.
9. The task runner publishes `PASS` only after explicit evidence completion;
   an early command failure or signal leaves a stage-specific `FAIL` and
   cannot retain an older PASS summary.
10. The checker, checker tests, runner tests, fresh runner and shared
    task-status helper/tests are exact ARCH_STABLE workflow inputs.

## Required negative evidence

Unit tests must reject:

- an added but undeclared live holder instance;
- a stale/nonexistent declared instance;
- a census holder module with no declared instance;
- a duplicate module instance collapsed to one path;
- current RTL source drift;
- product configuration drift;
- an edited frozen reachable graph with a refreshed outer artifact hash;
- a synchronized manifest+result+receipt deletion of one duplicate instance
  while the canonical full JSON remains unchanged;
- null or incomplete elaborator provenance;
- synchronized script/result/receipt/full hash edits that do not match rebuilt
  canonical artifacts;
- a noncanonical evidence path even when its bytes and hash are otherwise
  valid;
- any change outside the allowed process-local key token, or a normalization
  collision;
- parent-Make directory tracing contaminating the exact source-list output;
- missing helper source, unit failure, full-JSON mismatch, source drift,
  cleanup signal or stale PASS retention in the runner;
- missing or drifted instance-graph workflow dependencies in ARCH_STABLE.

## Non-goals

- No production Verilog/SystemVerilog behavior change.
- No lifecycle-semantic promotion.
- No full-system rerun.
- No synthesis mapping, STA, power or Pareto publication.
