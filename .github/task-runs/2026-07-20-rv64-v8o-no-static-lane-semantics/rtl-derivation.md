# v8o DI-4 derivation

## Root cause and current implementation

The production IQ already implements capability-based steering:

```text
dispatch ctrl
  -> ctrl_is_alu_terminal_capable(ctrl)
  -> alu_terminal_capable_q[resident entry]
  -> OooIntIssueSelect8.alu_capable_i
  -> first request / first capable-ALU selection
  -> optional issue_pair_swapped
  -> Universal issue0 + fixed-latency ALU issue1
```

This is an asymmetric two-terminal machine, not a static program-lane machine.
The existing R3 IQ matrix demonstrates branch/JAL/JALR/load/store in both
program orders, but it does not bind a DI-4 evidence record and does not cover
MulDiv or non-zero-generation full identity.

## Checker false-green found before implementation

`architecture_hard_gates.py` currently searches for several generic capability
predicate names but does not recognize the actual
`ctrl_is_alu_terminal_capable` function.  Consequently
`capability_predicate` is false and both DI-4 source checks pass through
`not capability_predicate` without proving metadata or steering.  This must be
repaired before any evidence may promote DI-4.

## Four-stage RTL derivation

1. **Abstract state**: each resident entry carries payload, age, readiness,
   exact full `ProducerId`, and one ALU-terminal-capability bit.  The physical
   Universal terminal accepts every covered class; the physical ALU terminal
   accepts only simple fixed-latency integer ALU work.
2. **Precedence**: recovery/kill suppresses issue; a registered Universal owner
   suppresses resident Universal issue but may leave ALU issue available;
   otherwise oldest-ready selection and capability steering determine owners.
   For an older simple plus younger complex pair, the swap is atomic: the
   memory/control/long-op owner may not pop unless the older simple owner also
   fires under the existing handshake rule.
3. **State transitions**: capability and full identity enter only on accepted
   dispatch, compact beside the surviving payload on issue/kill, and leave on
   the exact selected fire.  Dispatch slot number is never retained as a
   capability field.
4. **Adversarial timing**: both program-slot permutations, all six complex
   classes, dual terminal backpressure/open handshakes, exact identity, and
   compile-success mutations distinguish true dynamic steering from
   serialization, static slot binding, or payload substitution.

The coverage ledger is rooted at the same-edge dispatch accepts, not at the
stimulus loop.  Both entries are held resident for one full cycle before issue,
then canonical `valid && ready` fires are sampled on one edge.  A split-accept
negative and a 24-entry immutable full-ProducerId scoreboard make package,
residency, same-cycle and identity claims non-vacuous.

## Intended implementation footprint

No production RTL functional edit is planned unless the new test exposes a
real defect.  Expected changes are the DI-4 checker and unit tests, a focused
IQ test branch, evidence builder, reproducible runner/mutator, durable make
target and task-run evidence.  Any discovered RTL defect reopens this
derivation and prevents promotion until separately repaired and reviewed.
