# NPU script entry points

## Current compile entry

The recommended entry point for the current Qwen F32 ALU/backend compile is:

```bash
bash scripts/run-qwen-f32-alu-families-compile-v14.sh
```

One invocation performs the low-cost dependency checks, configures the current
`runtime/llama-npu-backend` CMake source, compiles the current 21-source RTL
filelist, and collects the native return codes, generated filelist/configuration,
required artifacts, and maintained warning oracle result. It does not execute
the generated backend test, a model, or a Qwen workload.

Useful options are:

```bash
# Dependency diagnostics only; this is optional and is not a later build gate.
bash scripts/run-qwen-f32-alu-families-compile-v14.sh --preflight

# Reuse a caller-selected build directory and choose parallelism.
bash scripts/run-qwen-f32-alu-families-compile-v14.sh \
  --build-dir /path/to/build --jobs 8
```

Without `--build-dir`, the runner creates an independent directory under
`tmp/build/`. Logs are always placed in a fresh run directory, and the final
message reports both locations. No historical output root must exist or be
absent before the build can start.

`qwen_f32_alu_warning_baseline.tsv` is the maintained warning oracle for this
compile. `qwen_f32_alu_compile_result.py` checks it once after a successful
build and verifies the generated RTL source membership/order, O3/no-assert/
no-trace configuration, and required linked artifacts. These are direct build
correctness checks; they are not workflow authorization or provenance seals.

## Versioned wrappers are historical snapshots

The v1-era experiment artifacts and versioned scripts predating the current
entry—especially
`run-qwen-f32-alu-families-compile-v2.sh` through
`run-qwen-f32-alu-families-compile-v13.sh`—are historical experiment and
failure-investigation snapshots. The same applies to the older versioned
`run-qwen-f32-add-owner-*`, `run-qwen-f32-alu-cmake-tool-*`,
`run-qwen-f32-alu-families-*`, graph-manifest, and regression recovery scripts.

They are not dependencies of v14, are not ordinary task gates, and must not be
replayed merely to authorize a current compile. Their receipts, hashes,
markers, immutable-output assumptions, and verifier self-tests describe the
specific historical experiment only. Use one explicitly only when reproducing
that experiment or carrying out a specifically requested forensic/release
identity investigation.

## Current regression entry

The current RTL regression entry remains:

```bash
bash scripts/run_npu_regression.sh
```

Its default path builds and runs all 53 current tests from source once in a
fresh per-invocation build/log/cache directory. Native Verilator and test-binary
return codes, unexpected build diagnostics, and each test's functional marker
decide the result. It does not re-run the runner's own verifier tests, adopt old
binaries, or publish receipt/hash closure.

The former multi-attempt recovery implementation is available only as an
explicit compatibility boundary:

```bash
bash scripts/run_npu_regression.sh --legacy-forensic [legacy-option]
```

This compatibility mode is for historical investigation, not for ordinary RTL
development or validation.

`build_llama.sh`, `build_npu_backend.sh`, and `run_qwen_strict_smoke.sh` retain
their direct build/runtime correctness checks. Locked third-party/model identity
checks there protect actual ABI or workload semantics; they do not create a
separate agent authorization epoch.

## Current strict multi-token Qwen entry

The deterministic raw-`x` strict-NPU workload has two supported scripted
depths. Both are real NPU/Verilator executions. The default is the complete
eight-token oracle:

```bash
bash scripts/run_qwen_strict_smoke.sh --scripted
```

For the shortest real run that still crosses the bootstrap-to-steady
recurrent/KV-state boundary, use the exact two-token prefix profile:

```bash
bash scripts/run_qwen_strict_smoke.sh --scripted-prefix-2
```

Before execution, both profiles regenerate the eight-token CPU reference as an
oracle-only check and audit the two graph phases used by consecutive decode:

- dispatch 1 is the 1714-node bootstrap graph;
- dispatch 2 and every later dispatch use the 1714-node steady graph;
- the canonical node IDs, node indices, owner count, and 1080 required-owner
  count stay fixed across phases;
- the only required-owner shape transition is the 36 recurrent
  `cache_r`/`cache_s` P17/P18 SCALE owners becoming zero-cardinality in the
  steady graph.

The graph collector captures every dispatch from 1 through 8 in a fresh run:
dispatch 1 is bootstrap, dispatch 2 is the first steady graph, and dispatches
3..8 are six individually captured consecutive-repeat manifests. The work
before each targeted dispatch runs on CPU solely to construct graph state. The
bundle requires all six intermediate repeats in exact order and requires each
to be graph-identical to dispatch 2; a missing dispatch or any middle/tail drift
fails closed. Collector output is structural evidence only: it is required to
contain no strict execution ledger or timing evidence and is never accepted as
an NPU token PASS.

The collector immediately runs the graph manifest suite against the artifacts
from that invocation. The strict path binds fresh dispatch-1..8 paths and
requires all 39 tests to pass with zero skips or softened outcomes. The ordinary
self-contained developer invocation runs 27 unit/static tests and reports the
12 real-bundle integration cases as explicit opt-in skips. Neither mode searches
or depends on historical `tmp/` output.

Every `llama-completion` subprocess starts from a hermetic NPU-mode environment:
the ambient required/admission/collector/strict-sampling/profile/identity/fused
mode variables and the upstream backend-sampling alias are removed before the
current phase opts into its exact variables. An exported developer-shell NPU
mode therefore cannot silently alter collection, CPU oracle, cache creation,
admission, interactive, or real scripted execution.

The built backend then runs a two-row admission matrix. It binds both the
bootstrap graph and a prompt-cache-backed steady graph and requires
`required_seen=1080`, `supported=1080`, `assigned=1080`, `unsupported=0`, and
`compute_started=0` in each row. Cache creation must freshly save the two-token
session before the last token. The read-only steady admission must load exactly
two prompt tokens, report an exact prompt match, preserve the session identity,
and attempt replay only after reaching the controlled admission boundary; replay
is stopped before scheduler allocation or compute and must not complete. This
proves that both descriptor variants and the steady state are accepted
fail-closed, but is not a token-generation PASS.

During the real run, every generated token must have one fresh strict RTL
dispatch, one 1080-owner SystemTop command/completion ledger, and one
full-vocabulary NPU ARGMAX ledger. The 36 steady P17/P18 SCALE owners remain
required NPU transactions and complete successfully in SystemTop; each has zero
elements, starts no F32 child, and produces no physical raw32 portal request or
payload traffic. Consequently, each dispatch still reports 367 F32 owner
transactions, while dispatch 1 has 367 nonempty/first-hold transactions and a
steady dispatch has 331.

The frozen phase-aware ledger is:

| profile/phase | required completions | F32 owner transactions | F32 nonempty / first holds | F32 raw reads (bytes) | F32 raw writes (bytes) |
| --- | ---: | ---: | ---: | ---: | ---: |
| dispatch 1 bootstrap | 1080 | 367 | 367 | 211292672 | 115820800 |
| each dispatch 2+ steady | 1080 | 367 | 331 | 191091200 | 95619328 |
| `prefix-2` total | 2160 | 734 | 698 | 402383872 | 211440128 |
| `extended-8` total | 8640 | 2936 | 2684 | 1548931072 | 785156096 |

Thus multi-token F32 traffic is `bootstrap + (tokens - 1) * steady`; multiplying
the first-token byte/first-hold ledger by the token count is incorrect. Counts
that intentionally remain per-dispatch, such as 1080 required completions, 367
F32 owner transactions, and one 248320-element ARGMAX, still scale with the
number of generated tokens.

Strict execution logs are parsed with closed, whole-line grammars. Each frozen
strict/System/functional/raw32/sampler marker must contain exactly its required
lower-case field set as unsigned decimal values. Unknown fields (including a
new field whose value is zero), duplicate or missing fields, malformed tokens,
extra whitespace, and trailing text all fail instead of being ignored.

A run succeeds only after the actual RTL-generated IDs equal the exact CPU
oracle prefix and every per-dispatch and cumulative ledger closes, with
`required_cpu_fallback=0`, `cpu_fallback_attempts=0`,
`host_tensor_arithmetic=0`, no unsupported required operation, and no RTL
failure. A CPU oracle PASS, graph bundle PASS, admission-matrix PASS, or directed
zero-cardinality test is necessary supporting evidence, not a multi-token NPU
execution PASS. The observed one-token RTL cost is about 8218 seconds, so two
and eight tokens are expected to take roughly 4.57 and 18.26 hours respectively.

A successful scripted run publishes
`qwen35-08b-q8_0-npu-strict-system-v4`. The v4 envelope contains the projected
bootstrap/steady/total phase ledger, frozen bootstrap and steady manifest
identities, the ordered dispatch-3..8 bundle identity, and the two-row admission
artifact identity including prompt-cache creation/replay evidence. These
identities are validated against the turn before the final marker is printed.
They make a completed run self-describing; they do not assert that an
eight-token RTL run has already occurred.

`--admission-only` runs the complete bootstrap-plus-steady admission matrix and
then exits before RTL compute. Interactive mode defaults to two generated
tokens; override it explicitly with
`NPU_STRICT_INTERACTIVE_MAX_TOKENS=<N>` when a longer manual run is intended.
