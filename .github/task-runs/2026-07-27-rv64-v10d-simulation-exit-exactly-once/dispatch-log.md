# V10D dispatch log

## Simulation-exit pre-review v1

- object: local RV64 `pending_exit` holder, raw exit pulse and latched terminal
  status
- contract:
  `.github/task-runs/2026-07-27-rv64-v10d-simulation-exit-exactly-once/subagent-contracts/pre-reviewer-v1.json`
- contract SHA-256:
  `bd482aef4214cecafef36a8934b14f3c73973c46f8c829bd846c82ee934afc96`
- rendered prompt SHA-256:
  `25034dbf21e04b43fee4fd16eb60c6870f196aa12a57e1abe5eaeacc77cac258`
- mode: read-only review
- shell ownership: returned
- verdict: `RTL_BUG_FOUND`

The reviewer must inspect lane0/lane1 capture, owner/stop birth and death,
memory-terminal gating, exit-event priority, output latching, local recovery
flush, and existing TB observability. It must not run simulation, synthesis,
STA, or edit files.

The reviewer confirmed that `OooPendingDrainResolveGate` omits
`pending_exit_i` from its exact memory-owner terminal condition. A pending
exit can therefore produce a raw exit while an older memory owner remains
active after ROB/issue drain. It also retained branch-spec trap/exit priority
and `core_local_flush` raw-event suppression as explicit directed-test GAPs.
No file was modified and the WSL command lane was returned.

## Implementer evidence ready for final review

- object: local RV64 `pending_exit`, exact memory-owner terminal eligibility,
  raw trap/exit priority and latched terminal status
- current design-id:
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`
- production RTL: exit participates in exact memory-terminal gating; older
  trap wins over exit; no raw-event dedup was added
- assertion-on focused tests: PASS 5/5
- assertion-off focused tests: PASS 5/5
- compile-success negative variants: 7/7 rejected
- module aggregate: PASS 113/113
- functional aggregate: module 113/113, official 177/177, AM DiffTest 59/59,
  zero architectural mismatches
- architecture hard gates: GREEN 9/9
- closed-evidence currentness: PASS, 15 closed entries, 35 artifacts, zero
  failures
- system boundary: historical V9Q rootfs run is old-design `FAIL rc=2`,
  empty terminal marker, and is not current-design recertification
- shell ownership: retained by primary until final reviewer contract dispatch

State: `FINAL_REVIEW_PENDING`. The independent reviewer must prioritize
counterexamples, mutation fidelity, current-design binding and false-GREEN
stage ordering, and must preserve `SERIALIZE-G1=OPEN`,
`architecture_freeze=GAP`, `ppa=UNQUALIFIED`.

## Simulation-exit final review v1

- object: local RV64 collector `ingress_accept` to exact memory-owner
  terminal, `pending_exit` lane pair to raw exit, and current-design evidence
- contract:
  `.github/task-runs/2026-07-27-rv64-v10d-simulation-exit-exactly-once/subagent-contracts/final-reviewer-v1.json`
- contract SHA-256:
  `9b44a39d41d7ba9bfaab83034962e68aa0f99cd21ae1a414577ad024a3a227a1`
- rendered prompt SHA-256:
  `3a2711cdd1d25c0712f95359f99684f53b25106d4cd4e40a918d5c68a68ce4a2`
- contract workflow: canonical `create -> validate -> render`, exact rendered
  text verified against the saved artifact
- mode: read-only counterexample-first review
- permitted actions: declared `rg`, `sed`, read-only git inspection and
  `sha256sum`; no simulation, synthesis, STA or file writes
- shell ownership: returned; reviewer stopped shell commands and wrote no file
- verdict: `APPROVED_FOR_CURRENT_SCOPE`

Reviewer-confirmed local RTL facts:

- `OooIntBackend` maps the twelve collector ingress accepts into the terminal
  transfer mask and drives `mem_owner_terminalized_o` outside `OOO_ASSERT`;
- exit exact-terminal gating, C0/C1/C2 timing, local-flush kill and older-trap
  priority are supported by raw-event testbench observations;
- `NpcSimTop.exit_reported_q` is only a reporting callback guard and is not an
  exactly-once oracle;
- all current-design counts and hard gates bind design-id `c1b531…bb594`.

Non-blocking reviewer finding:

- `test-runner-stage-order.py` omitted
  `control-event-index-verify` from `REQUIRED_ORDER`, so its negative fixture
  could not reject index verification removal or movement after the debt
  ledger.

Reconciliation:

- added index verification to the required order;
- added `missing-index-verify` and `verify-after-ledger` negative fixtures;
- made the stage-order contract an unconditional replay preflight;
- V10C attempt 13 persisted all three negative rejection markers and the full
  stage-order PASS marker, then reconfirmed currentness 15/35/0 and ended
  PASS with `SERIALIZE-G1=OPEN`.

The v1 contract's optional full-core candidate path was incorrect. The actual
read-only path is
`npc/rv64/eval/ppa/arch-stable/full-core-current.json`; primary readback
confirmed design-id `c1b531…bb594` and nested claim
`architecture_freeze=GAP`, `ppa=UNQUALIFIED`,
`promotion_eligible=false`. No reviewer conclusion was expanded beyond the
versioned contract.

## Record closure

- project, NPC and agent-system memory updated with the stable V10D RTL and
  stage-order facts
- bounded non-history recall: complete for simulation-exit and
  stage-order/index-verify
- `npc-dev` task-specific e2e: completed 5/5 at
  `.github/task-runs/2026-07-27-simulation-exit-exactly-once-revtag-v10d/`
- `agent-system` task-specific e2e: completed 11/11 at
  `.github/task-runs/2026-07-27-stage-order-index-verify-revtag-v10e/`
- strict guard: PASS, `changed_paths=553`, `required_profiles=2`, current
  evidence accepted for `agent-system` and `npc-dev`
- task-run Markdown and non-Markdown evidence: published to the repository
  index
- final state: `APPROVED_FOR_CURRENT_SCOPE / RECORD_CLOSED`

The parent debt remains `SERIALIZE-G1=OPEN`; current-design Linux/rootfs
terminal evidence, architecture freeze and PPA qualification remain outside
this closure.

The intermediate
`.github/task-runs/2026-07-27-stage-order-index-verify-revtag-v10d-r2/`
is retained as blocked even though its 11 executable nodes passed: its
uncontrolled `r2` slug term lacked an independent focus match. The final
controlled-revtag run completed without weakening bounded recall.
