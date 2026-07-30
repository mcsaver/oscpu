# RV64 V10C current-design architecture evidence replay

## Round classification

- object: local RV64 OoO Verilog/SystemVerilog architecture-debt evidence
- classification: architecture evidence maintenance / verification
- scope: replay canonical directed testbench and compile-success RTL-variant
  entry points; refresh `CLOSED` debt bindings only
- branch: `ai`
- initial HEAD: `af027d1bce085bace474b748dcd89113145f8772`
- initial RTL design-id:
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`
- worktree: mixed-origin dirty worktree; no staged paths; this round does not
  claim ownership of pre-existing changes

## Original observation

`update-current-debt-ledger.py` rejects
`npc/rv64/eval/ppa/evidence/fdg-arch-trap-current.json` because its structured
result is bound to
`sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`.
The ledger top-level design-id is current, while all 15 `CLOSED` entry records
still carry that older design-id. Two structured evidence families are already
current (`F0-G1` and `STORE-BRESP-G1`); 13 require canonical replay.

This is a current-design evidence debt, not evidence of a production RTL
functional defect. `SERIALIZE-G1` remains a separate `P1 OPEN` architecture
debt and is not closed by this replay.

## Competing hypotheses

1. The production RTL still satisfies every closed contract; only structured
   evidence became stale after the RTL source-set identity changed.
2. A current RTL or testbench change invalidated at least one closed contract;
   its canonical positive or compile-success negative variant will fail.
3. The evidence tooling itself no longer binds a complete current RTL source
   set; a canonical run may pass locally but the final ledger audit will reject
   its design-id, artifact hash, or status.

## Experiment and stop budget

- Replay the nine P0 evidence targets.
- Replay the remaining stale P1 fence, vectored-trap, and control-event evidence
  groups.
- Stop at the first failing canonical target; preserve its stage log and do not
  edit production RTL under this verification-only classification.
- Do not weaken assertions, negative RTL variants, source membership, or
  terminal transaction checks.
- Require identical RTL design-id before and after all replay commands.
- Refresh ledger hashes and entry bindings only after every canonical target
  passes.

## Promotion criteria

- every `CLOSED` ledger entry and each non-raw structured artifact binds the
  current RTL design-id;
- every stored artifact SHA-256 matches its on-disk file;
- all replayed canonical targets return zero;
- production RTL design-id is unchanged;
- the task report keeps `SERIALIZE-G1` visibly open until a separate
  owner/holder lifecycle closure proves it.

## Status

`PASS`:

- attempt 1: `FDG-G1` PASS; XRET baseline/module matrix PASS `113/113`;
  XRET compile-success variants reported `8/7` and stopped the replay;
- root cause: the lane1 architectural-trap/system-holder exclusion variant is
  rejected earlier by the current exact-one assertion
  `[V10A-SERIAL-OWNER-ONEHOT] arch and system holders overlap`, while the
  historical evidence driver still required the later CSR-request marker;
- correction: only that mutation's exact expected marker was rebound in
  `run-xret-mutations.py`; production RTL and assertions are unchanged;
- independent read-only verdict: `APPROVED_FOR_CURRENT_SCOPE`, contract
  `eab2ce44e00594705019c670d0104986400c1d404704c9c84086b41eba22e0bb`.

Attempt 2 must regenerate the matrix and continue the remaining canonical
targets. This round remains verification-only.

### Attempt 2 IFU-TVAL stop

Attempt 2 passed:

- `FDG-G1`;
- `XRET-G1` with variants `8/8` and oracle probes `2/2`;
- `MEM-ISSUE-G1`;
- `IFU-AXI-G1`;
- `IFU-FETCH-G2`;
- `IFU-ACCESS-G1`.

`IFU-TVAL-G1` then stopped before compiling its negative variants because the
historical `stop_pending_retains_branch_squash` source anchor no longer
matched the current `OooStopPendingSequencer` priority chain. The production
module now groups checkpoint capture, tracked resolve and
`branch_resolve_untracked_i` in one owner-clear condition.

The verification driver now changes only the unique current
`branch_resolve_untracked_i` term to `1'b0` inside that grouped condition. This
preserves the original negative mechanism—retain `stop_pending_o` after the
untracked branch recovery clears the pending IFU fault tuple—without changing
production RTL or accepting a compile failure as sensitivity evidence.

Attempt 3 must prove that this current-source variant compiles and is rejected
by `[TVAL-G1-CONTROL-RED] c.beqz squash PF`, then continue the remaining
canonical targets.

### Attempt 3 IFU-TVAL static-contract stop

The updated current-source matrix reached simulation and produced:

- focused `8/8` PASS;
- module aggregate `113/113` PASS;
- compile-success variants `12/12`;
- dynamically rejected variants `12/12`;
- production RTL source unchanged.

Evidence generation then stopped because
`ifu_tval_evidence.py` still required the removed two-line
`branch_resolve_untracked_i` clear arm. Its
`stop_branch_squash_clears_validity` static contract now binds the full current
grouped owner-clear condition through the common
`stop_pending_o <= 1'b0` assignment. This proves that untracked branch
recovery is still a validity-death witness rather than merely checking that
the signal name occurs somewhere in the module.

Attempt 4 must rerun the canonical IFU-TVAL target, emit current structured
evidence, and continue downstream.

### Attempt 4 full-core boundary binding stop

Attempt 4 passed:

- `IFU-TVAL-G1`: focused `8/8`, module aggregate `113/113`,
  compile-success variants `12/12`, dynamically rejected variants `12/12`,
  and current grouped-clear static contract;
- `PTW-PMP-G1`, `INSTRET-G1`, `FENCE-G1`, and `VECTORED-TRAP-G1`;
- control-event SQ retry, focused/config variants, RTL mutations, module
  aggregate, and the nine directed architecture gates (`9/9 GREEN`).

`control-event-index` then failed closed because its full-core boundary requires
the canonical candidate design-id to equal the current RTL design-id. The
candidate and producer-holder census still bind
`sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`,
while the current RTL and refreshed architecture/functional evidence bind
`sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`.

This is an omitted current-design evidence-binding stage, not an RTL failure.
Attempt 5 first runs the canonical holder-lifecycle target and the existing
fail-closed V9L candidate/census binder. That binder requires current
architecture and functional evidence and preserves
`architecture_freeze=GAP`, `ppa=UNQUALIFIED`, empty freeze inputs, and
`promotion_eligible=false`; it cannot promote the design. The replay then
regenerates and verifies the control-event index before touching the debt
ledger.

### Attempt 5 transitive V9R binding stop

Attempt 5 passed current holder lifecycle (`8/8` baseline, `9/9`
compile-success mutations, static census PASS), rebound the census/candidate to
the current design while retaining the honest GAP boundary, regenerated the
full-core boundary, and built the control-event index. The independent index
verify then failed closed because V9R SQ-retry evidence had been generated
before the census rebind and therefore retained the prior census artifact hash.

The replay order now places holder lifecycle plus candidate/census binding
before V9R SQ-retry and all control-event evidence. Attempt 6 must regenerate
the transitive V9R evidence, then rebuild and verify the V9O index. The stored
artifact-hash check remains unchanged and is the reason this ordering defect
was observable.

### Attempt 6 final current-design replay

Attempt 6 resumed at `control-event-sq-retry` after the holder census and
candidate had already been rebound by attempt 5. It passed, in order:

- V9R SQ-retry evidence;
- focused/config variants and compile-success control-event RTL mutations;
- module aggregate;
- the directed architecture chain, including DI-1 and DI-2, with final
  architecture hard gates `9/9 GREEN`;
- full-core GAP boundary generation;
- control-event index build and independent hash verification;
- debt-ledger refresh;
- the final closed-evidence currentness audit.

Final result:

- RTL design-id before and after replay:
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`;
- `15/15` `CLOSED` debt entries bind that design-id;
- all `35` stored evidence artifact SHA-256 values match their current files;
- `SERIALIZE-G1` remains `P1 OPEN`;
- the full-core candidate remains
  `architecture_freeze=GAP`, `ppa=UNQUALIFIED`, and
  `promotion_eligible=false`;
- no production RTL file was edited by V10C;
- no assertion, compile-success mutation requirement, exact marker, source-set
  binding, or artifact-hash check was weakened.

The historical V9P rootfs run is not promoted by this result. It binds older
RTL design-id
`sha256:4655eabea13d2ecce9ac94784bbcb0a8bd2151b65bcd7325f950c6abb9b91380`,
simulator SHA-256
`669c983b22ce52beb433e50870e8950c522f8fd2a1072798fb86489bc2af6c87`,
`OOO_CSR_QUEUE_HEAD=1`, and `OOO_TERMINAL_HOLDER_ASSERT=1`; it ended
`FAIL rc=2` after approximately 405 million committed instructions because
NPC did not exit cleanly through reset-syscon, and its terminal-marker file is
empty. It is therefore historical failure evidence, not a current-design
terminal-transaction PASS.

### Tooling transparency

Three local read-only inspection commands were corrected without changing
source or evidence semantics: an `importlib` probe omitted the module's
`sys.modules` registration, a shell heredoc was quoted incorrectly, and a
PowerShell `foreach` pipeline was parsed incorrectly. A later candidate-file
read also used the wrong directory before resolving the canonical
`npc/rv64/eval/ppa/arch-stable/full-core-current.json` path. None of these
commands participated in a canonical replay stage or altered a PASS/FAIL
oracle.

### Final reviews v1/v2 and attempt 8 status-contract correction

Independent final reviewer v1 returned `CHANGES_REQUIRED` for one workflow
blocker while accepting the technical currentness result:

- attempt 6 stage order, design-id stability, `9/9` architecture gates,
  `15/15` closed entries and all `35/35` referenced artifact hashes were
  independently checked;
- the three verification-tool corrections preserve compile-success negative
  sensitivity, exact markers, explicit FAIL/no PASS, source binding and
  production RTL identity;
- the original runner did not use an explicit evidence-complete status bit and
  did not publish HUP/INT/TERM as FAIL with stage/signal/cleanup metadata.

The runner now sources `scripts/task-run-status.sh`, publishes a separate
atomic `task-run.status`, installs HUP/INT/TERM traps, updates the active stage
before each executed command, and marks evidence complete only after the final
currentness audit and unchanged design-id check. The detailed
`replay.status` format remains available for bounded monitoring.

Validation after this status-only correction:

- `bash -n run-current-design-evidence-replay.sh`: PASS;
- the first correction passed `scripts/tests/test-task-run-status.sh`,
  including explicit completion, early exit, command failure, cleanup failure
  and HUP;
- attempt 7 resumed only at `closed-evidence-currentness`; it did not claim to
  rerun the skipped simulation stages;
- attempt 7 final audit:
  `[V10C-CURRENTNESS][PASS] ... closed=15 artifacts=35 failures=0`;
- attempt 7 start/end design-id:
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`;
- standard `task-run.status=PASS` and detailed
  `replay.status state=PASS, stage=complete`.

Independent final reviewer v2 accepted the attempt-6/7 evidence boundary but
returned `CHANGES_REQUIRED` for a narrower deterministic initialization
window: the first correction installed the HUP/INT/TERM signal trap before the
EXIT finalizer. A signal in that interval could leave the standard status at
`RUNNING` and a stale detailed `PASS`. The helper unit test also injected only
HUP and did not exercise the real V10C runner or stale detailed state.

The final correction pre-seeds the standard status path, stage, signal,
evidence-complete and cleanup fields, installs the EXIT finalizer before the
HUP/INT/TERM handlers, and atomically replaces the detailed status on every
exit. Its test-only signal hook is disabled unless all explicit override
variables are supplied; it does not execute in a normal replay.

Final validation:

- `bash -n run-current-design-evidence-replay.sh`: PASS;
- `scripts/tests/test-task-run-status.sh`: PASS for explicit completion, early
  exit, command failure, cleanup failure, and HUP/INT/TERM;
- `test-runner-status-contract.sh`: PASS for stale detailed `PASS`
  replacement at `pre-init` and `active-stage`, for each of HUP, INT and TERM
  (`6/6` runner cases);
- attempt 8 resumed only at `closed-evidence-currentness`; all earlier replay
  stages were explicitly skipped and are not claimed as rerun;
- attempt 8 final audit:
  `[V10C-CURRENTNESS][PASS] ... closed=15 artifacts=35 failures=0`;
- attempt 8 design-id:
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`;
- standard `task-run.status=PASS` and detailed
  `replay.status state=PASS, stage=complete`.

Production RTL, assertions, testbench oracles, compile-success variants,
expected markers, artifact hashes and architecture/PPA boundaries were not
changed by either correction. Independent final reviewer v3 returned
`APPROVED_FOR_CURRENT_SCOPE` after checking:

- the EXIT finalizer is installed before the HUP/INT/TERM handlers;
- standard status fields are pre-seeded before any signal handler can run;
- helper HUP/INT/TERM and runner
  `pre-init/active-stage × HUP/INT/TERM` stale-PASS cases all pass their exact
  negative assertions;
- attempt 8 skips the prior 23 stages and claims only the final currentness
  audit;
- production RTL, assertions, testbench oracles, compile-success variants,
  `SERIALIZE-G1=P1 OPEN`, `architecture_freeze=GAP`, `ppa=UNQUALIFIED`, and
  `promotion_eligible=false` are unchanged.

Final reviewer v3 contract SHA-256:
`cc3eb28ed2ed60ed84e9a57bd326a0642c13da56ea8d77a0d9e31419de12903b`;
rendered prompt SHA-256:
`3ef26f04421ab0b6c48e0e62033fc245fa16b3cbc6dc733e281a3c76efb43c50`.
The reviewer ran no new RTL simulation, synthesis, or STA and returned the
single Windows→WSL engineering-command lane without a residual process.
