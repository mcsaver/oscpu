# V10E current-design system recert contract

## Classification

- primary: `verification`
- auxiliary: `tooling/workflow`
- production RTL edit: none
- debt: `SERIALIZE-G1` (`P1`, `OPEN`)

## Local RV64 object

The object is the current local RV64 dual-issue OoO design-id
`sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`
running the isolated Ubuntu 22.04 systemd-strict rootfs transaction with:

- `OOO_CSR_QUEUE_HEAD=1`;
- `OOO_ASSERT=1`;
- `OOO_TERMINAL_HOLDER_ASSERT=1`;
- zero UART RX bytes;
- fresh per-run rootfs work image;
- exact simulator, kernel, OpenSBI, DTB and rootfs hashes;
- generated Verilator manifest proof for `--assert`,
  `+define+OOO_CSR_QUEUE_HEAD=1`, `+define+OOO_ASSERT` and
  `+define+OOO_TERMINAL_HOLDER_ASSERT=1`;
- one workspace-global lock shared by the V10E and historical V9S asynchronous
  system runners;
- 17 strict guest PASS labels, strict done marker, natural poweroff,
  reset-syscon/`GOOD TRAP` and clean simulator exit.

## Original system observations

1. Historical V9Q design-id `4655ea…b91380` reached 405,000,000 commits but
   ended `FAIL rc=2`; its terminal marker file is empty.
2. Historical systemd-strict design-id `c358ce…c07e8d` reached 16/17 strict
   labels and 710,753,508 commits, then hit the 3,000,000,000-cycle limit
   while executing the final `dmesg-no-critical` check. It did not emit the
   strict done marker, natural poweroff, reset-syscon or `GOOD TRAP`.
3. Neither historical result is current-design system evidence.

## Competing hypotheses

- H1: the old systemd-strict failure was a bounded-run truncation; the
  current design completes all 17 labels and the terminal transaction when
  given a 6,000,000,000-cycle budget.
- H2: the current design still contains a progress or terminal lifecycle
  defect; it stalls, triggers an RTL assertion, misses a guest label, or
  fails to exit through reset-syscon before the expanded budget.
- H3: a simulator/config/boot-artifact mismatch, rather than RTL behavior,
  invalidates the run before a system conclusion is possible.

## Highest-information experiment

Build a unique assertion-on simulator from the current design, prove its
generated define manifest, rebuild and statically check the strict rootfs,
bind and post-check every immutable input hash, then execute one single-flight
systemd-strict run with:

- max cycles: `6,000,000,000`;
- host timeout: `100,000` seconds;
- commit-gap limit: `1,000,000` cycles;
- progress interval: `5,000,000` commits.

The 6B limit changes only the observation budget. It does not remove or
weaken any guest check, RTL assertion, transaction parser, terminal marker or
success condition.

Cleanup failure, missing simulator, generated-define mismatch, rootfs
pre-image mismatch or config/Makefile/kernel/OpenSBI/DTB mutation must publish
`FAIL`; none may leave the run at `RUNNING` or authorize `PASS`.

## Decision rule

- all bindings + 17/17 + strict done + natural poweroff + reset-syscon +
  `GOOD TRAP` + clean exit: current-design system recertification PASS;
- RTL assertion or terminal-holder marker: current RTL defect candidate;
- no commit progress with live holder state: progress root-cause analysis;
- max-cycle/host timeout with continuing commits: bounded system evidence
  GAP, not RTL PASS or FAIL;
- any binding/config/rootfs mismatch: infrastructure/binding GAP.

No result in this run alone closes `SERIALIZE-G1`, changes the default
configuration, freezes the full architecture or qualifies PPA.
