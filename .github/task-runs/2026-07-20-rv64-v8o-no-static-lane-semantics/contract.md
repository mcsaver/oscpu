# v8o DI-4 no-static-lane-semantics atomic contract

## Scope and claim boundary

This task may promote only architecture gate `DI-4 no_static_lane_semantics`
for the current complete RV64 RTL source set.  It does not promote DI-1,
DI-2, DI-3, DI-5, OOO-3, OOO-4, the architecture-wide result, or any PPA
result.  Independently proven OOO-1 and OOO-2 records may remain GREEN.

The claim is about accepted dispatch package positions and physical execution
terminal capability.  `slot0` and `slot1` mean the two program-order positions
accepted by one dispatch package; they are not permanent execution-lane roles.
The current core still has only one Universal/memory terminal, so proving this
contract must not be described as dual-memory issue.

## Production dataflow contract

For every resident integer-IQ uop, the following chain is required:

1. `OooIntIssueQueue.ctrl_is_alu_terminal_capable` predecodes whether the uop
   can use the fixed-latency physical ALU terminal.
2. `alu_terminal_capable_q[entry]` stores and compacts that fact beside the
   full payload and full `ProducerId`; selection must not recover it from the
   original dispatch position.
3. `OooIntIssueSelect8` consumes per-entry capability and dynamically assigns
   the Universal and ALU terminals.  With an older simple ALU followed by a
   younger complex uop, `issue_pair_swapped_o` must place the younger complex
   uop on Universal and the older simple uop on ALU.
4. With the reverse program order, the older complex uop must naturally use
   Universal and the younger simple uop must use ALU.
5. Both selected entries must retain their exact full `ProducerId`, control
   class and PC through the terminal fire boundary.

The asymmetric physical terminals are legal.  A static meaning attached to
dispatch slot 0/1, entry index, or program-order lane is not.

## Directed behavior contract

A standalone production-IQ test must cover each complex class `branch`, `jal`,
`jalr`, `load`, `store`, and `muldiv` in both accepted dispatch positions.  In
each of the twelve cases:

- the other package position contains a ready independent simple integer ALU;
- both dispatch positions perform `valid && ready` on the same clock edge;
  the test freezes one package witness, program order, control, PC and exact
  full `ProducerId` from that input handshake;
- both uops become resident before selection, so dispatch-to-issue bypass
  cannot satisfy the case; issue is held for one complete cycle while two
  distinct valid entries and their stored capability bits are inspected;
- both physical terminals are ready and both selected uops fire in the same
  cycle, where canonical fire is `issue_valid && issue_ready` sampled on the
  same edge for both terminals;
- the complex uop reaches Universal and the simple uop reaches the ALU
  terminal regardless of program slot;
- exact PC, control class and non-zero-generation full `ProducerId` identify
  both fired uops;
- the pair drains exactly once with no residual IQ entry.

Coverage is derived from the accepted input control bits, accepted slot and
matching terminal-fire identity.  Loop indices or scenario labels may select
stimulus but may not directly set a coverage bit.  A separate one-free-entry
case must make slot0 accept and slot1 backpressure on different cycles and
prove that no permutation or pair-fire counter is credited.

Across the twelve cases, all 24 input transactions use distinct full
`ProducerId` values with non-zero generation fields.  An immutable scoreboard
records them at dispatch acceptance and consumes each exactly once at its
correct physical terminal fire.  Unknown, duplicate, swapped or truncated
identities fail immediately; the accepted and fired masks must be equal at the
end.

The test must emit one unique witness per class/slot and a unique terminal PASS
marker.  Release and `OOO_ASSERT` profiles must produce identical machine
metrics:

- all twelve `program_slot_permutation.<class>.<slot>` values are true;
- `static_lane_role_violations=0`;
- `same_cycle_pair_fires=12`;
- `exact_full_pid_matches=24`.

These metrics prove issue acceptance only.  They do not prove memory ordering,
cache admission, load/store completion, or two LSU resources.

## Static-checker non-vacuity

The DI-4 source checker must recognize the actual predicate
`ctrl_is_alu_terminal_capable`, the actual per-entry carrier
`alu_terminal_capable_q`, and the actual dynamic steering signal
`issue_pair_swapped`.  It must fail closed when any one of these links is
removed or replaced by a dispatch-position/static-entry predicate.  A checker
that passes because it failed to recognize that a capability restriction
exists is a false green.

Unit tests must exercise compile-independent source mutations for missing
predicate, missing per-entry metadata, missing dynamic steering and static
entry/slot binding.  Comment text is stripped before recognition and cannot
satisfy the gate.

For the actual implementation path, the checker must report non-zero,
unambiguous match counts for the predicate definition, capability-state
declaration, both dispatch captures, compaction copy, selector projection,
selector input binding and dynamic swap/output bindings.  The metadata and
steering checks retain independent match inventories and failure reasons; an
empty target set cannot make both pass through a shared boolean shortcut.

## Runtime negative sensitivity

Compile-success temporary RTL mutations must be elaborated before their
semantic failure is accepted.  The focused test must reject at least:

- removal of dynamic pair swapping;
- replacement of per-entry capability with static entry/slot capability;
- loss of slot1 capability capture;
- classification of MulDiv as ALU-terminal capable;
- serialization of the second terminal;
- truncation/corruption of a selected uop's full `ProducerId`.

Mutants live only in a caller-owned temporary directory.  Canonical proof
source hashes must match before and after every run.

Each mutation result records the mutant source hash, elaborated image hash,
compile success, a scenario-specific activation witness and the dedicated
semantic failure label.  Timeout, compilation failure, missing activation or
an unrelated assertion is not a killed mutation.  The unmutated configuration
must pass under the same focused test settings.

## Evidence and durable entry point

The evidence producer must write a workspace-relative log with exactly one
`[ARCH-GATE] no_static_lane_semantics PASS` marker, bind its SHA-256 to
`npc/rv64/eval/ppa/evidence/architecture-current.json`, and bind the record to
the complete current RTL source-set digest and exact proof-harness provenance.
The command must be exactly
`make -C npc/rv64 check-no-static-lane-semantics`.

Release and `OOO_ASSERT` logs are parsed independently; each must contain the
complete 12/0/12/24 metric vector and may not borrow counts from the other
mode.  Provenance separately names and hashes the complete RTL design binding,
TB, checker, builder, build entry points, contracts and mutation source.  The
subtask-contract JSON hash is recorded only as collaboration provenance and is
never used as an RTL or design-contract digest.  Stale log/provenance replay
must be rejected.

Evidence update is an atomic sibling-preserving merge.  A stable make target
must rerun checker unit tests, release/assert focused simulations, all required
mutations, evidence generation and the full architecture inventory.  Success
requires DI-4 GREEN, preserves only independently proven OOO-1/OOO-2 siblings,
and requires architecture `OVERALL: RED` until every other gate is separately
closed.

Before and after publication, the runner must compare the directed-test map:
only `no_static_lane_semantics` may be added or replaced.  OOO-1/OOO-2 may be
preserved only when already bound to the same complete `design_id`; all other
test records remain byte-for-byte equal.  The evaluated GREEN set must be
exactly `{DI-4, OOO-1, OOO-2}` for the current starting state, with every other
gate and overall architecture RED.  No PPA result is emitted.
