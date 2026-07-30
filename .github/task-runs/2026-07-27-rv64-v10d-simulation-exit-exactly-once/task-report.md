# V10D simulation-exit exactly-once report

## Status

`APPROVED_FOR_CURRENT_SCOPE / RECORD_CLOSED`.

Primary classification: `architecture`.
Auxiliary classifications: `verification`, `tooling/workflow`.

Object: local RV64 OoO `pending_exit` holder, exact
memory-owner terminal eligibility, raw `OooTrapExitEventMux.exit_o`
transaction, and latched
`OooTrapExitOutputSequencer.exit_valid_o/halted_o` status.

Current design-id:
`sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`.

The first bounded-context recall attempts used identifiers that are not yet
present in retained non-history memory and correctly failed closed. Source,
testbench, predecessor task-run and current-design replay evidence are now
bound below; no recall or architecture gate was weakened.

## Initial evidence boundary

- V9Y exact memory-owner terminal scalar: bounded PASS and current source
  identity retained;
- V9Z pending architectural-trap memory-terminal gate: bounded PASS;
- V10A architectural-trap C0/C1/C2 transaction: bounded PASS;
- V10B eight pending SYSTEM kinds: bounded PASS;
- V10C current-design replay: PASS for design-id `c1b531…bb594`;
- current-design closed-debt audit: 15 closed entries and 35 artifact
  references, with zero currentness failures;
- simulation exit C0/C1/C2 raw-event counting: bounded PASS;
- `SERIALIZE-G1=P1 OPEN`;
- `architecture_freeze=GAP`, `ppa=UNQUALIFIED`,
  `promotion_eligible=false`.

## Independent pre-review v1

Verdict: `RTL_BUG_FOUND`.

Contract SHA-256:
`bd482aef4214cecafef36a8934b14f3c73973c46f8c829bd846c82ee934afc96`;
rendered prompt SHA-256:
`25034dbf21e04b43fee4fd16eb60c6870f196aa12a57e1abe5eaeacc77cac258`.

Confirmed root cause:

- `OooPendingDrainResolveGate.pending_serialized_mem_terminal_w` gates only
  `pending_system_i || pending_arch_trap_i`;
- the module has no `pending_exit_i`;
- with ROB/issue drained, stop live, `pending_exit=1`, and an older memory
  owner still active, `drain_complete_o` and
  `OooTrapExitEventMux.exit_o` can assert;
- that edge clears the exit/stop holders and permanently latches
  `exit_valid/halted`, so the defect is an early terminal transaction rather
  than an observational glitch.

The reviewer also retained two separate GAPs:

- branch-spec misaligned trap and exit can be driven simultaneously by the
  standalone mux/output equations, while existing unit tests accept dual
  terminal status; production reachability/priority needs direct proof;
- `core_local_flush` clears pending-exit and stop holders, but existing
  core-glue coverage does not assert raw exit suppression or no new output
  latch.

Existing `NpcSimTop.exit_reported_q` is explicitly excluded from exactly-once
evidence. It consumes latched terminal status and cannot prove that the raw
exit event was neither early nor repeated.

## Root cause and architectural repair

Competing hypotheses were:

1. production exit timing was correct and only raw-event observation was
   absent;
2. `pending_exit` could terminalize before the older memory owner;
3. a raw exit could repeat because the owner/stop holders survived C0;
4. branch recovery and exit could create two terminal transactions;
5. `core_local_flush` could leak a raw exit while killing the holder.

The highest-information clocked experiment falsified hypothesis 1 and
confirmed hypothesis 2. `OooPendingDrainResolveGate` omitted
`pending_exit_i` from the exact memory-owner terminal term. The repair adds
that input and permits drain only when no serialized memory-sensitive owner
is pending or `mem_owner_terminalized_i` is true.

The same transaction slice makes older trap priority explicit:

- `OooTrapExitEventMux.exit_o` is suppressed when a terminal trap is present;
- `OooTrapExitOutputSequencer` cannot set exit status from an illegal
  trap/exit overlap;
- `OooControlPlane` retains the owner/stop/raw-exit assertions and adds
  exit-vs-trap/system onehot, memory-terminal, C1 clear and raw-repeat
  assertions.

No raw-event deduplication was added. `NpcSimTop.exit_reported_q` remains
outside the proof boundary, and no assertion was removed or weakened.

## Directed transaction evidence

Assertion-on and assertion-off runs both PASS for these five production-module
testbenches:

- `tb_ooo_pending_drain_resolve_gate`;
- `tb_ooo_pending_arch_trap_memory_terminal`;
- `tb_ooo_trap_exit_event_mux`;
- `tb_ooo_trap_exit_output_sequencer`;
- `tb_ooo_serialized_owner_exactly_once`.

Observed markers include:

- `[V10D-EXIT-DRAIN-GATE] active=0 exact-terminal=1 PASS`;
- lane0 EBREAK and lane1 ECALL
  `[V10D-EXIT-EXACTLY-ONCE-PASS]`, with C0 raw event, C1 owner/stop clear and
  C2 no repeat;
- `[V10D-EXIT-LOCAL-FLUSH-PASS]`, with no owner, stop, raw exit or output
  latch;
- `[V10D-EXIT-RECOVERY-PRIORITY-PASS]`, with the older branch trap winning
  and no dual latch;
- standalone mux and output-sequencer trap-priority PASS markers.

Seven compile-success RTL variants are rejected 7/7. They independently
remove the exit memory-terminal term, substitute full memory-idle semantics,
retain the exit holder, retain the stop holder, swap lane exit kind, remove
trap priority, and extend raw exit beyond the terminal cycle. The last
variant runs with RTL assertions disabled so the testbench raw-event counter,
not an assertion, rejects C2 repetition.

The complete module aggregate passes 113/113.

## Current-design replay

V10C replay attempt 13 completed after earlier fail-closed stage-order
counterexamples and the final-review workflow correction. The enforced order
is:

`module aggregate -> functional aggregate -> architecture gates ->
candidate/census -> SQ-retry binding -> GAP audit -> index build ->
index verify -> ledger -> closed-evidence currentness`.

For design-id `c1b531…bb594`:

- module tests: 113/113 PASS;
- official RV64 tests: 177/177 PASS;
- AM tests: 59/59 DiffTest PASS, zero architectural mismatches;
- CoreMark and Dhrystone: PASS;
- architecture hard gates: 9/9 GREEN;
- closed-evidence currentness: 15/15 entries, 35 artifacts, zero failures.

The full-core candidate remains intentionally fail-closed because
`SERIALIZE-G1` is still OPEN. Historical V9Q rootfs evidence is bound to old
design-id `4655ea…b91380`, simulator SHA `669c98…6f6c87`,
`OOO_CSR_QUEUE_HEAD=1`, `OOO_TERMINAL_HOLDER_ASSERT=1`; it ended
`FAIL rc=2` at 405,000,000 commits/PC `0xffffffff80002f68` with an empty
`terminal-markers.txt`. It is not current-design system recertification.

## Independent final review

Contract JSON SHA-256:
`9b44a39d41d7ba9bfaab83034962e68aa0f99cd21ae1a414577ad024a3a227a1`;
rendered prompt SHA-256:
`3a2711cdd1d25c0712f95359f99684f53b25106d4cd4e40a918d5c68a68ce4a2`.

Verdict: `APPROVED_FOR_CURRENT_SCOPE`.

The reviewer found no blocking RTL counterexample in the current local
simulation-exit slice. It independently confirmed:

- all twelve collector ingress paths contribute to
  `v9y_terminal_transfer_mask_w` only through `ingress_accept`;
- `mem_owner_terminalized_o` production logic is outside `OOO_ASSERT`;
- `pending_exit_i` participates in the exact memory-owner terminal gate;
- raw exit C0, C1 holder/stop death, C2 no-repeat, local-flush kill and older
  trap priority are observed directly rather than inferred from
  `NpcSimTop.exit_reported_q`;
- assertion-on/off, seven compile-success variants, 113/113 module tests,
  functional counts, 9/9 architecture gates and 15/35/0 currentness all bind
  the same `c1b531…bb594` design.

The review found one evidence-workflow GAP: the V10C stage-order self-test did
not include `control-event-index-verify`, so it could not reject removal or
late execution of index verification. This was reconciled by:

- adding `control-event-index-verify` to `REQUIRED_ORDER`;
- adding negative fixtures for missing verification and verification after
  the debt ledger;
- making the stage-order contract an unconditional preflight for full and
  resumed replay attempts;
- running attempt 13 from `closed-evidence-currentness`.

Attempt 13 persisted all three negative rejection markers plus the complete
PASS order in `stage-logs/attempt-13/replay-stage-order-contract.log`, then
reconfirmed `[V10C-CURRENTNESS][PASS]` with design-id `c1b531…bb594`,
15 closed entries, 35 artifacts and zero failures. Standard and detailed
replay status both end PASS while explicitly retaining
`SERIALIZE-G1=OPEN`.

The review contract contained an incorrect optional candidate path
(`npc/rv64/eval/ppa/evidence/full-core-current.json`). The actual file is
`npc/rv64/eval/ppa/arch-stable/full-core-current.json`; primary readback
confirmed its design-id is `c1b531…bb594` and its nested `claim` remains
`architecture_freeze=GAP`, `ppa=UNQUALIFIED`,
`promotion_eligible=false`. This path correction does not expand the final
review's approved RTL scope.

One non-blocking assumption remains: the standalone output sequencer can
accept a trap in one cycle and exit in a later artificial cycle, while the
integrated holder/run-gate transaction makes that sequence unreachable.
Existing tests cover the same-transaction older-trap overlap; a future
adversarial standalone cross-cycle test may strengthen that boundary.

## Record closure

The stable V10D facts were published to project, NPC and agent-system memory.
Bounded non-history recall is complete for both the simulation-exit and
stage-order/index-verify topics.

Two task-specific e2e runs completed with DB marker publication:

- `npc-dev`: 5/5 PASS at
  `.github/task-runs/2026-07-27-simulation-exit-exactly-once-revtag-v10d/`;
- `agent-system`: 11/11 PASS at
  `.github/task-runs/2026-07-27-stage-order-index-verify-revtag-v10e/`.

The final
`scripts/agent-e2e.sh --guard --guard-mode strict` invocation returned zero:
`changed_paths=553`, `required_profiles=2`, with current evidence PASS for
both `agent-system` and `npc-dev`. The compact marker is
`evidence/strict-guard.status`. The V10D task-run Markdown and non-Markdown evidence
are published through the repository task-run index.

An intermediate run,
`.github/task-runs/2026-07-27-stage-order-index-verify-revtag-v10d-r2/`,
retains a useful fail-closed counterexample: all 11 executable nodes passed,
but the run stayed blocked because the extra `r2` task-slug term had no
independent non-history focus match. The final run uses a controlled
`revtag`, preserving the recalled topic as `stage order index`; no recall gate
was relaxed.

## Review boundary

The reviewer finding is reconciled and the local simulation-exit slice is
approved, and its record closure is complete. This bounded approval does not
by itself close `SERIALIZE-G1`, establish current Linux/rootfs terminal
evidence, freeze the architecture, qualify PPA or make the long-term goal
complete.
