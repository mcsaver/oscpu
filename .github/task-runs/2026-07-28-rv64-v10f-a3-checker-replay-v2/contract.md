# V10F A3 checker replay V2 contract

## Classification

- primary: verification
- auxiliary: frozen-image checker extraction and evidence packaging
- production RTL: unchanged
- architecture contract: unchanged
- PPA eligibility: not evaluated

## Frozen source run

The source run remains immutable and keeps its original status:

`2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3`

Expected source status:

`FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`

V1 replay remains an immutable preliminary result. V2 is canonical because it
extracts the checker that actually existed in the A3 run image and binds the
extracted bytes to A3 `strict_checker_sha256`.

## Hypotheses

- H1: A3 completed the RV64 system transaction, while its embedded legacy
  checker classified `printk: debug:` as the only strict-check failure.
- H2: The A3 embedded checker differs from its launch binding, another critical
  dmesg marker exists, the terminal transaction is incomplete, an RTL
  assertion fired, or a pre/post binding drift exists.

## Discriminating replay

Read the A3 run image with `debugfs` and replay both the extracted legacy regex
and the current production regex over the same frozen A3 console. V2 passes
only when all of the following are true:

- the extracted checker SHA-256 equals A3 `strict_checker_sha256`;
- the extracted regex is exactly the legacy unbounded-`BUG:` regex;
- the legacy regex matches only the frozen `printk: debug:` lines;
- the current bounded regex matches no A3 console line;
- the current regex accepts `printk: debug:` and still rejects a real `BUG:`;
- checker unit tests pass, including benign and true-fault fixtures;
- preflight and autocheck are PASS;
- strict has exactly 16/17 PASS labels, `done_rc=1`, and exactly one old
  `dmesg-no-critical` failure;
- strict-done, poweroff-begin, kernel power-down, syscon poweroff, GOOD TRAP,
  and system-reset exit each occur exactly once and in order;
- the terminal line reports 5,071,521,696 cycles and 1,223,536,213 commits;
- the frozen RTL assertion evidence is empty;
- A3 design, simulator, configuration, launch artifacts, and rootfs bindings
  show no drift;
- all bounded frozen source inputs retain their pre/post replay hashes.

## Full-system rerun gate

A full rerun is not required for this checker correction unless production core
RTL semantics, the actually elaborated RTL, device/simulator execution
semantics, or required A3 frozen evidence changed. The A3/A4 comparison is
evidence only for this gate; interrupted A4 is not system PASS evidence.

## Conclusion scope

PASS means only:

`A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE`

It does not qualify an architecture or PPA promotion.
