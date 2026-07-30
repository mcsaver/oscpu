# V10E completion definition

The raw runner PASS path remains:

- [x] runner contract positive and negative self-tests pass;
- [x] independent reviewer accepts the latest corrected runner and success oracle;
- [x] current RTL design-id equals `c1b531…bb594` before and after;
- [x] simulator, config, kernel, OpenSBI, DTB and rootfs inputs are hash-bound;
- [x] `OOO_CSR_QUEUE_HEAD=1`, `OOO_ASSERT=1` and
  `OOO_TERMINAL_HOLDER_ASSERT=1` are bound;
- [x] zero UART bytes and a per-run rootfs image are observed;
- [ ] strict stage records exactly 17/17 expected PASS labels;
- [x] strict done marker appears exactly once;
- [ ] no strict FAIL marker or RTL assertion failure appears;
- [x] natural poweroff, reset-syscon and `GOOD TRAP` are observed;
- [x] simulator exits cleanly;
- [ ] the fail-closed source-run status is `PASS`.

The A3 frozen-oracle replay path is independently complete when:

- [x] the A3 source status remains the original
  `FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`;
- [x] the checker extracted from the A3 rootfs has SHA-256
  `83b6a538…053f9a`, equal to A3 `strict_checker_sha256`;
- [x] the extracted legacy regex reproduces exactly the two
  `printk: debug:` matches and no competing critical marker;
- [x] the corrected bounded regex has zero A3 console matches, accepts the
  benign debug witness and rejects a real `BUG:` fixture;
- [x] strict history remains 16/17 with the sole
  `__NPC_CHECK_FAIL__:dmesg-no-critical` marker;
- [x] strict-done, poweroff-begin, kernel power-down, syscon poweroff,
  `GOOD TRAP` and system-reset clean exit each occur exactly once and in order
  in the SHA-bound raw guest console;
- [x] terminal counters are 5,071,521,696 cycles and 1,223,536,213 commits;
- [x] RTL assertion evidence is empty and design/simulator/configuration/boot
  artifact pre/post bindings show no drift;
- [x] none of the four full-rerun triggers is present;
- [x] an independent reviewer returns
  `APPROVED_NOT_PROMOTION_ELIGIBLE`;
- [x] record-layer memory, task-run index, task-specific
  `rv64-systemd-contract` plus `agent-system` e2e and scoped strict guard are
  reconciled; the unrelated full-dirty-worktree guard remains an explicit
  non-green exemption.

A3 satisfies the system-transaction replay path. This does not rewrite the
historical FAIL or claim a raw 17/17 runner PASS.

Explicit non-completion:

- timeout, max-cycle exhaustion, continuing progress without terminal
  completion, binding mismatch or infrastructure failure remains `GAP`;
- interrupted A4 remains `FAIL rc=143 ... signal=TERM` and is not PASS
  evidence;
- this system slice does not by itself change the queue-head default, close
  `SERIALIZE-G1`, freeze architecture or qualify synthesis/STA/power/PPA.
