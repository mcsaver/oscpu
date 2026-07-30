# V10F A3 checker replay V2 task report

## Scope

- classification: verification checker replay
- RV64 object: A3 frozen rootfs checker, guest console and system-reset
  terminal transaction
- production RTL edit: none
- source run status: preserved historical FAIL
- architecture/PPA promotion: not eligible

## Source transaction

- design-id:
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`
- simulator SHA-256:
  `dc8a175a53bf45f1f1bd9b2228bf9bdf4f6981eb9e01f66ae86bb500cf91f218`
- cycles: 5,071,521,696
- commits: 1,223,536,213
- A3 source status:
  `FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`
- historical strict result: 16/17, `done_rc=1`, sole FAIL
  `__NPC_CHECK_FAIL__:dmesg-no-critical`
- terminal observation: strict-done, poweroff-begin, kernel power-down,
  syscon poweroff, `GOOD TRAP` and system-reset clean exit each exactly once
  and ordered in `guest/console.log`
- RTL assertion evidence: empty
- design, simulator, configuration and launch artifact binding: no pre/post
  drift

## Checker root cause and repair

The checker extracted from the A3 run image has SHA-256
`83b6a5384bc92a0b6c4977832a5e882c06684de554a8a09e0391a7acff053f9a`,
exactly equal to A3 `strict_checker_sha256`. Its unbounded `BUG:` alternative
matches the `BUG:` suffix inside `printk: debug:`.

The production checker now uses
`(^|[^[:alnum:]_])BUG:`. This is the only regex semantic change:

- frozen A3 console with embedded legacy regex: two matches, both
  `printk: debug:`;
- frozen A3 console with current regex: zero matches;
- benign `printk: debug:` fixture: accepted;
- real `BUG: unable to handle page fault` fixture: rejected;
- unit tests: 3/3 PASS.

No terminal event was deduplicated and no RTL assertion was removed or
weakened.

## Full-system rerun gate

No full rerun is required for this checker-only correction because:

- production core RTL semantics did not change;
- 51 A3 generated Verilator C++/header files have 50 exact matches and one
  source-line-only delta that normalizes to equality;
- eight device-model object hashes are equal;
- the host `cpu-exec.o` delta is diagnostic observation only;
- required A3 frozen inputs, raw terminal chain and post-hash evidence exist.

A4 remains
`FAIL rc=143 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=143 signal=TERM`
and is not PASS evidence.

## Implementer/reviewer reconciliation

- implementer result:
  `A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE`
- independent reviewer:
  `APPROVED_NOT_PROMOTION_ELIGIBLE`
- reviewer contract SHA-256:
  `f4db46c50967c2464b624a35adcec6369e15c9277703de45b10ec61de9edbc21`
- reviewer confirmed the A3 source FAIL was not rewritten and returned the
  single-flight WSL command lane
- nonblocking tool debt: a future replay-tool version should assert
  bidirectional equality of A3/A4 generated filename sets; approved V2 remains
  immutable

## Record and workflow closure

- V10F evidence index contains two canonical assets and DB evidence lookup
  returns both; the nine-source replay manifest verifies 9/9 SHA-256 bindings.
- DB-owned project status, NPC module, agent-system module and known-issues
  memory were updated from complete documents, snapshotted to
  `.github/db-backup` and passed `audit-db-first`.
- `rv64-systemd-contract` task-run
  `.github/task-runs/2026-07-28-rv64-a3-checker-replay/` completed; checker
  unit tests are 3/3, guest contract 13/13, transaction parser 11/11, debug
  contract 7/7 and isolated-rootfs copy PASS.
- `agent-system` task-run
  `.github/task-runs/2026-07-28-a3-printk-debug-replay/` completed after the
  final memory publication, with all 11 profile nodes PASS. Its discovery node
  proves all seven checker-only paths require only `rv64-systemd-contract` while
  `Linux/scripts/check-ubuntu-rootfs.sh` still requires `rv64-linux`.
- scoped strict guard over the twelve implementation/documentation/memory
  paths is PASS for exactly `rv64-systemd-contract` and `agent-system`.
- full dirty-worktree strict guard remains FAIL because unrelated existing
  `Linux/scripts/check-ubuntu-rootfs.sh` and NPC/RTL/PPA/testbench paths require
  missing `rv64-linux` and `npc-dev` evidence (`changed_paths=836`). This is an explicit
  mixed-origin-worktree exemption, not a green result and not a reason to run
  an unrelated full rootfs or full-core regression for this checker-only
  change.

## Final boundary

This task closes only the A3 checker-oracle classification. `SERIALIZE-G1`
remains OPEN, architecture freeze remains GAP, PPA remains UNQUALIFIED and the
long-term RV64 OoO/PPA goal remains active.
