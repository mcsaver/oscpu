# Current RV64 full-system recertification contract

## Scope

This contract defines the reusable `NpcSimTop` strict-system execution and the
bounded reuse of retained historical executions.  A fresh run binds the RTL
source snapshot, isolated generated configuration, simulator, Verilator source
manifest, NEMU reference, Linux Image, OpenSBI firmware, DTB, rootfs template,
host checker/parser, tool identity, strict guest transaction and natural syscon
poweroff sequence.  It does not promote the whole architecture or PPA.

The machine policy is
`npc/rv64/design/arch/system-recertification-run-policy-v1.json`; the only
fresh-execution entry is:

```text
npc/rv64/eval/ppa/run-system-recertification-current.sh \
  --run-dir .github/task-runs/<new-run-id> \
  --expected-design-id sha256:<current-id> \
  --expected-file-count <current-count>
```

The entry owns the global RV64 engineering command lane, writes only a new
task-run plus `.github/runtime-artifacts`, and returns after publishing an
initial `RUNNING` status.  The caller monitors that status and must not start a
second WSL engineering process while it remains active.

## Fresh execution state vector

A fresh PASS is a conjunction, not one return code:

- `execution_state=PASS`;
- `terminal_state=PASS_EXACT_ONCE`;
- `artifact_state=CLEANED`;
- `assertion_state=PASS_ZERO_FAILURES`;
- `oracle_state=PASS`;
- `replay_state=NOT_APPLICABLE_FRESH_EXECUTION`.

The canonical run uses `OOO_CSR_QUEUE_HEAD=1`, `OOO_ASSERT=1`,
`OOO_TERMINAL_HOLDER_ASSERT=1`, systemd-strict and zero UART RX bytes.  It
requires preflight 6/6, autocheck 6/6 and strict 17/17; poweroff-begin, kernel
power-down, syscon poweroff, system-reset, GOOD TRAP, instruction-stat and
cycle-stat must each occur once.  The assertion extract must be empty.

The runner creates a minimal `npc/rv64` source sandbox, checks it byte-for-byte
against the pre-run manifest, generates default config there, and builds the
simulator there.  It never rewrites workspace `.config`.  Rootfs validation is
read-only and fails rather than rebuilding the frozen image.  Simulator,
obj_dir, sandbox and rootfs work image are deleted after post-hash capture;
driver/console/NPC logs, bounded build tails, binding, terminal/assertion
extracts, cleanup receipt and semantic summary remain in the task-run.

## Retained V14E execution

The V14E A2 execution for design-id
`sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
remains an immutable historical execution:

- configuration: `OOO_CSR_QUEUE_HEAD=1`, `OOO_ASSERT=1`,
  `OOO_TERMINAL_HOLDER_ASSERT=1`, systemd-strict, zero UART RX bytes;
- 1,231,323,780 committed instructions and 5,055,252,337 cycles;
- preflight 6/6, autocheck 6/6 and strict 17/17;
- one poweroff-begin, kernel power-down, syscon poweroff, GOOD TRAP,
  system-reset, instruction-stat and cycle-stat event in console order;
- zero RTL assertion failures and source/config/simulator pre/post hash drift;
- failed A1 runner-contract attempt remains `FAIL` and is never rewritten.

It is not current for a different production RTL design-id.  Its logs may
continue to validate checker-only changes when every reuse precondition below
holds, but they cannot certify later RTL semantics.

## Replay and reuse

The transaction parser may be replayed on retained console and NPC
logs with `strict-v2`, `natural-poweroff` and producer-closed semantics.  The
current checker/parser contract tests include a positive `printk: debug:` case
and negative real `BUG:` cases.  Checker/parser/report changes require replay;
production RTL, active device-model, host-harness or simulator execution
semantic changes require a DUT rerun.  Regenerable compiled products are not
retained.

The legacy V14E receipt is
`npc/rv64/eval/ppa/evidence/system-recertification-current.json`.  Its bounded
claim was `system_recertification=PASS_CURRENT_CONFIG` and
`SERIALIZE-G1=CURRENT_DYNAMIC_PASS` only while its exact RTL identity remained
current; `whole_architecture=RED` and `ppa=UNPROMOTED` remain mandatory.  A new
fresh run writes its own `system/system-recertification-summary.json` and does
not overwrite this legacy receipt.

## Receipt state model

The receipt keeps the V14E A2 execution and terminal transaction at PASS,
the failed A1 predecessor at its original FAIL state, the current checker
replay at PASS, and the current design/config/artifact binding at exact match.
These are independent fields: a replay may repair an oracle classification,
but cannot rewrite either original runner status.  Missing frozen inputs,
terminal markers, assertion evidence or post-binding hashes requires a new
DUT execution rather than a weaker receipt.

The legacy replay/check entry remains the literal, Kconfig-independent
makefile:

```text
/usr/bin/make -rR --no-print-directory -C npc/rv64 \
  -f eval/ppa/system-recertification-evidence.mk \
  check-system-recertification-current
```

The corresponding `refresh-system-recertification-current` target reruns only
the current parser replay and its checker contract tests.  Neither target
launches `NpcSimTop`; neither target may rewrite `.config`.  They must fail on
a live design-id mismatch and therefore cannot replace the fresh-execution
entry above.
