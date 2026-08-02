# RV64 V11Y current full-core cohort contract

## Object and claim boundary

The object is the local `NpcTop` RV64 dual-issue OoO RTL bound to
`sha256:882111fb3d58039cb7414e6331dac0c10d848463df2228dff93ae22dafbed67b`.
The retained claim is a current-design module and functional cohort PASS. It is
not an architecture freeze, physical PPA qualification, Linux recertification,
or promotion authorization.

## Current module evidence

`module-attempt-3` is the current retained result:

- exact testbench inventory: 113/113 PASS;
- identical pre/post RTL, generated-header, filelist, TB, and runner inputs;
- exact design marker in every normalized log;
- no retained `.vvp`, object directory, or compiler intermediate.

Command:

```text
PYTHONDONTWRITEBYTECODE=1 python3 npc/rv64/eval/ppa/tools/full_core_current_evidence.py module --jobs 2 --output-dir .github/task-runs/2026-08-01-rv64-v11y-full-core-current-cohort/evidence/module-attempt-3
```

`module-attempt-1` preserves the native-marker checker FAIL. Attempt 2 is a
PASS for the earlier `82febf...` RTL and is retained only as history; attempt 3
is the result that feeds the current functional cohort.

## Current functional evidence

`functional-attempt-3` completed all DUT execution phases:

- official architecture tests: 177/177 PASS;
- AM CPU tests with DiffTest: 61/61 PASS, mismatch count 0;
- CoreMark: 10 iterations, CRC `0xfcaf`, one GOOD TRAP;
- Dhrystone: 10000 runs, one GOOD TRAP.

Its original `status.json` remains FAIL because the old input oracle included
177 extensionless official build targets in the source manifest and observed
their expected post-build hash changes. The DUT execution, frozen images,
simulator, reference model, logs, and original status are not rewritten.

## Versioned checker replay

The final replay excludes only these exact paths from both recorded manifests:

- group `official_program_sources`;
- root `npc/rv64/testsuites/core-tests/src/riscv-tests/isa`;
- each of the frozen 177 test IDs as `<test-id>` and `<test-id>.dump`.

This is 354 known build outputs. Exactly 177 extensionless targets changed;
filtered real inputs have zero changes. Any other changed path remains a hard
FAIL. The original `.config` was not frozen, so the replay receipt explicitly
marks its copy as reconstructed and binds the recorded/current-identical
`default_defconfig`, `auto.conf`, and `autoconf.h` instead.

Final command:

```text
PYTHONDONTWRITEBYTECODE=1 python3 npc/rv64/eval/ppa/tools/full_core_functional_replay.py --attempt-dir .github/task-runs/2026-08-01-rv64-v11y-full-core-current-cohort/evidence/functional-attempt-3 --module-result .github/task-runs/2026-08-01-rv64-v11y-full-core-current-cohort/evidence/module-attempt-3/result.json --output-dir .github/task-runs/2026-08-01-rv64-v11y-full-core-current-cohort/evidence/functional-attempt-3-checker-replay-final --publish-current
```

The final replay is PASS, the checker unit suite is 13/13 PASS, evidence
mutations are 11/11 rejected, and the independent reviewer conclusion is
`REPLAY_APPROVED`. Canonical aggregate/result/log are byte-identical to the
final replay artifacts.

## Retention contract

Retain the original attempt-3 FAIL, the final published replay, module-attempt-3,
raw failure logs, compact status/receipt/history records, and canonical
aggregate files. Remove superseded wrapped replay copies, temporary compiler
trees, `.vvp`, objects, and non-replayable images/frozen binaries from failed
development attempts. See `evidence/replay-development-history.json`.
