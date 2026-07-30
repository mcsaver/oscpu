# RV64 CONTROL-EVENT-G1 current-source rebind contract

## Primary classification

`verification`

Auxiliary classification: `tooling/workflow`.

No production RTL change is authorized by this contract.

## Local RTL object

- `npc/rv64/vsrc/execute/OooIntBackend.v`
  - bank0/bank1 SQ-query retry READY/capture across the edge-old C0 barrier;
- `npc/rv64/vsrc/memory/OooMemAxiBridge.v`
  - `S_SQ_QUERY` retry-holder residency and post-barrier release;
- `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`;
- `npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv`;
- `npc/rv64/testbench/Makefile`;
- V9O/V9R current-design evidence under the canonical 2026-07-23 and
  2026-07-24 task-runs.

## Observed currentness failure

`python3 -m unittest npc.rv64.eval.ppa.tests.test_arch_stable_freeze`
reports exactly three failures:

1. V9R source binding records the old `npc/rv64/testbench/Makefile`;
2. V9R source binding records the old
   `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`;
3. the current candidate test therefore remains `GAP`.

The production hashes in the V9R owner path still match the prior PASS:

- `OooIntBackend.v`:
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`;
- `OooMemAxiBridge.v`:
  `2d6f33182e02e516e03864849e6d7299db44163a847b814f88ba8ea8d821a062`.

## Falsifiable hypotheses

- H1: the new historical testbench branches are macro-isolated and do not
  change the V9R SQ-query retry C0 transaction.
- H2: the new branches perturb V9R elaboration or its raw event oracle.
- H3: the production owner/holder contract has changed despite the matching
  production hashes.

The lowest-cost discriminator is a current-source V9R replay: two positive
testbenches plus the bank0, bank1 and bridge compile-success RTL variants.
H1 survives only if the baseline is 2/2 PASS and all 3/3 variants are
dynamically rejected with the exact raw assertion markers.

## Rebind order

After the V9R discriminator passes, rebuild the V9O current-source evidence
without weakening any checker:

1. V9O focused/config/mutation evidence;
2. current module aggregate;
3. nine directed architecture gates;
4. V9R SQ-query retry C0 evidence;
5. honest full-core GAP boundary;
6. V9O evidence-index build then verify;
7. CONTROL-EVENT-G1 ledger binding;
8. currentness unit tests.

## Success criteria

- RTL design-id remains
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`
  before and after the replay.
- V9R baseline is 2/2 PASS and 3/3 compile-success RTL variants are rejected.
- V9O focused/config/mutations/module/architecture evidence all binds the
  current verification source-id.
- `build-evidence-index.py --verify` returns zero.
- `test_arch_stable_freeze` returns 48/48 PASS.
- Independent reviewer finds no stale hash, false-green oracle, assertion
  weakening, or scope overclaim.

## Non-goals

- no A3/A4 rootfs rerun;
- no synthesis, STA, power or PPA promotion;
- no terminal-event deduplication;
- no assertion removal or weakening;
- no claim that a local currentness rebind alone establishes full-core
  `ARCH_STABLE`.
