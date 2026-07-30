# V11A holder instance-graph derivation

## Initial alternatives

- **H1:** the V8L field census plus its dynamic markers already implied complete
  current `NpcTop` instance multiplicity.
- **H2:** V8L proved selected holder lifecycles but did not enumerate every live
  instance, so an independent elaboration graph was required.
- **H3:** one or more holder-bearing module definitions had zero or multiple
  current product instances, making source-level module counting insufficient.

## Lowest-cost discriminator

A read-only Yosys `read_verilog -sv; hierarchy -check -top NpcTop; proc;
write_json` run used the 127 canonical synthesizable RTL inputs with
`OOO_CSR_QUEUE_HEAD=1` and `OOO_TERMINAL_HOLDER_ASSERT=1`.

Observed result:

- current design ID:
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`;
- reachable user-module instances: 194;
- holder-bearing modules: 15;
- holder instances: 17;
- duplicated holder modules: 2;
- `OooMemInflightQueue`: 2 instances;
- `OooMemAxiBridge`: 2 instances.

Therefore H1 is rejected as a proof method, H2 is retained, and H3 is confirmed
for the two dual-memory modules. All holder-bearing modules are live; none has
zero instances.

## Minimal closure

Independent review v1 confirmed the 17 paths but found five proof-chain gaps:

1. a manifest and result could be rewritten together to remove one duplicated
   instance;
2. the new checker/test/runner were absent from ARCH_STABLE workflow binding;
3. the declared topology root excluded the sibling dual-memory bridge;
4. the exact Yosys source list and script were not frozen;
5. an interrupted runner could leave an older PASS summary.

The closure therefore uses five distinct frozen artifacts:

- `holder-instance-graph.json`: strict result schema, counts, holder subset,
  source/config/declaration/checker and elaborator bindings;
- `yosys-instance-graph-receipt.json`: independent normalized 194-row
  elaboration receipt;
- `yosys-instance-graph.full.json.gz`: the complete canonical Yosys JSON
  document;
- `yosys-instance-graph.ys`: canonical script naming the ordered 127-file input
  list and a stable output placeholder;
- `yosys-instance-graph.log`: exact elaborator log bytes.

Independent review v2 then showed that result/receipt agreement was not
sufficiently independent when both could be rewritten together. It also
required the original ARCH_STABLE log, canonical evidence paths, a fresh
predecessor gate and dynamic stale-PASS runner fixtures.

The final frozen audit therefore rebuilds the receipt and reachable graph
directly from the complete JSON. The full document uses deterministic map
ordering and only normalizes process-local Yosys map-key tokens matching
`$0x<hex>:` to `$0xADDR:`; values and all other keys are retained, and a
normalization collision fails closed. Two independent normalized documents
were byte-equal at 197,075,777 uncompressed bytes with SHA-256
`7e72dfd26d4f3c20d799588f9ba46d580d0aa8aa47b8ef084905dc52299bc454`.

The canonical Make target performs a fresh Yosys elaboration and requires all
five outputs to be byte-identical before the census audit runs. This rejects
the synchronized-deletion counterexample without treating frozen evidence
alone as a fresh hierarchy proof.

Two additional integration counterexamples were exposed by the canonical Make
entry:

- an inherited working directory initially prevented Python package lookup;
- parent-Make directory tracing initially contaminated `print-synth-rtl`
  stdout.

The runner now enters the repository root explicitly, and the source-list
query uses `--no-print-directory`; both failures were observed as
stage-specific FAIL with `evidence_complete=0` before the final PASS replay.

Final focused observations:

- instance-graph and dynamic runner unit tests: 23/23 PASS;
- holder-census unit tests: 15/15 PASS;
- shared task-status shell tests: PASS;
- ARCH_STABLE unit tests: 50/50 PASS, including missing/drifted workflow
  dependency negatives;
- fresh result/receipt/full/script/log replay: byte-identical PASS;
- V11A task status: PASS;
- V9N owner-residency refresh, V9R/V10C currentness replay and V9O index
  verification: PASS;
- closed currentness: 16 entries, 38 artifacts, 32 semantic checks,
  0 failures;
- current design ID remained
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`;
- currentness postflight reported `production_rtl_unchanged=true`.

Independent review v3 returned `APPROVED_FOR_CURRENT_SCOPE` after checking the
five exact artifact hashes, both duplicated module pairs, complete JSON
contents, canonicalization boundary, fresh predecessor, stale-PASS fixtures,
ARCH_STABLE 50/50 and currentness 16/38/32/0.

Only evidence/checker/test/manifest/Makefile workflow files changed. No
`npc/rv64/vsrc/**` production file changed. The census advances from
source-field completeness to elaborated-instance completeness, while
`semantic_complete=false`,
`global_no_live_reuse=SEMANTIC_COVERAGE_REQUIRED`, whole architecture `RED` and
PPA `UNPROMOTED` remain explicit.
