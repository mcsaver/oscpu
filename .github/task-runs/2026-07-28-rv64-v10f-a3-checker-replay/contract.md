# V10F A3 checker replay contract

## Classification

- primary: verification
- auxiliary: tooling/workflow evidence packaging
- production RTL: unchanged
- architecture contract: unchanged
- PPA eligibility: not evaluated

## Frozen source run

The source run remains immutable and keeps its original status:

`2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3`

Expected source status:

`FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`

## Hypotheses

- H1: A3 completed the RV64 system transaction, while the legacy unbounded
  `BUG:` token classified `printk: debug:` as the only strict-check failure.
- H2: A3 contains another critical dmesg marker, an incomplete terminal
  transaction, an RTL assertion, or a pre/post binding drift.

## Discriminating replay

Replay the current production `bad_dmesg_regex` over the frozen A3 console.
The replay passes only when all of the following are true:

- the legacy regex matches the frozen `printk: debug:` witness;
- the current bounded regex does not match any A3 console line;
- the current regex still matches a real `BUG:` fixture;
- preflight and autocheck are PASS;
- strict has exactly 16/17 PASS labels, `done_rc=1`, and exactly one old
  `dmesg-no-critical` failure;
- strict-done, poweroff-begin, kernel power-down, syscon poweroff, GOOD TRAP,
  and system-reset exit each occur exactly once and in order;
- the terminal line reports 5,071,521,696 cycles and 1,223,536,213 commits;
- the frozen RTL assertion evidence is empty;
- A3 design, simulator, configuration, checker, manifest, kernel, OpenSBI,
  DTB, and rootfs pre/post bindings show no drift;
- all frozen source inputs retain their pre-replay hashes.

## Full-system rerun gate

A full rerun is not required for this oracle correction unless production core
semantics, the actually elaborated RTL, device/simulator execution semantics,
or required A3 frozen evidence changed. The A3/A4 comparison is evidence only
for this gate; interrupted A4 is not system PASS evidence.

