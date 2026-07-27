# V9Y serialize memory-owner terminal report

## Status

`PASS` for the V9Y memory-owner terminalized subrange.

Current local RV64 RTL design ID:
`sha256:3c933ec82fd17c6038335f9208b496cacfb755dfd10b9e419c73f276b5e2a428`.

This result does not close pending architectural trap, seven-kind serialized
exactly-once completion/retirement, `SERIALIZE-G1`, architecture-stable,
Linux flag-on, synthesis/STA/power, or PPA.

## Root cause and RED

The pre-fix `OooPendingDrainResolveGate` distinguished ordinary FENCE from
other serialized kinds, but the non-FENCE path could resolve while an older
memory owner still occupied MIQ/bridge/reservation/buffer/retry/SQ state.
CSR had the same omission at `system_csr_dispatch_valid_o`.

The preserved pre-fix RED compiled successfully and observed all three early
events:

- non-CSR active-owner drain;
- CSR active-owner dispatch valid;
- CSR active-owner fire.

Evidence:

- `evidence/red/status.txt`
- `evidence/red/logs/tb_v9y_pending_memory_terminal_red.log`

## RTL contract and implementation

`OooIntBackend` now computes an exact local terminalized-owner scalar from:

- MIQ0/MIQ1 occupancy;
- bridge0/bridge1 active and station residency;
- reservation0/reservation1;
- legacy buffer and `mem_pending_q`;
- retry0/retry1;
- SQ owner tokens;
- same-edge request handoff and reservation birth;
- collector pending, tracker live, collector-accepted terminal ingress, and
  exact STORE release.

`OooMemOwnerTerminalCollector.ingress_accept_o` directly exports its existing
live/kind/epoch/duplicate/pending/same-edge-reenqueue validation. Raw ingress
valid remains an event observation and cannot authorize serialized control.
No duplicate event is merged or removed; all pre-existing collector
fail-loud assertions remain.

The production holder census and the sole
`mem_owner_terminalized_o` assignment are outside `OOO_ASSERT`. The macro
guards only shadow and fail-loud checks, so release simulation and synthesis
consume the same predicate.

The one-bit path is:

`OooIntBackend → OooAluDecodeBackend → OooAluCoreSlice →`
`OooExecuteBackend → OooCoreTopGlue → OooControlPlane →`
`OooPendingDrainResolveGate`.

It gates both:

1. non-CSR pending-system `drain_complete_o`;
2. CSR `system_csr_dispatch_valid_o/fire_o`.

Ordinary FENCE still additionally requires complete `mem_idle_i`.
Collector-pending-only therefore does not wait for dequeue/tracker-free on
the seven non-FENCE kinds.

## Focused phase and acceptance evidence

Assertion-enabled and assertion-disabled V8W backend/collector runs both
observe:

- active holder: `terminalized=0`;
- exact accepted same-edge transfer: `terminalized=1`;
- collector-pending-only: `terminalized=1` while `mem_idle=0`;
- full idle: `terminalized=1`;
- wrong-epoch raw ingress: `accept=0`, `terminalized=0`;
- same-token duplicate lanes: both `accept=0`, `terminalized=0`;
- same-edge dequeue/re-enqueue: `accept=0`;
- all twelve exact lanes accepted together and drained exactly once.

Markers:

- `[V9Y-ACCEPTED-TRANSFER-NEGATIVE]`
- `[V9Y-MEM-TERMINAL-PHASE]`
- `[V9Y-TCOLL-ACCEPT-NEGATIVE]`
- `[V9Y-TCOLL-SAME-EDGE-REENQUEUE]`
- `[V8P-TCOLL-12INGRESS-CAPTURE]`
- `[V8P-TCOLL-12INGRESS-DRAIN]`

Logs:

- `evidence/green-v3/assert/logs/`
- `evidence/green-v3/release/logs/`

The release compile lines contain no `-DOOO_ASSERT`.

Base backend runs in both configurations observe exact SD and FSD final-holder
release:

- `[V9Y-SQ-EXACT-RELEASE] kind= SD ... PASS`
- `[V9Y-SQ-EXACT-RELEASE] kind=FSD ... PASS`

Logs:

- `evidence/green-v3/base-assert/logs/tb_ooo_int_backend.log`
- `evidence/green-v3/base-release/logs/tb_ooo_int_backend.log`

## Negative RTL variants

Six compile-success variants are rejected:

Control gate, `evidence/mutations/summary.json`, 3/3:

1. remove non-CSR memory-terminal gate;
2. remove CSR memory-terminal gate;
3. replace exact predicate with full `mem_idle`.

Acceptance/release configuration,
`evidence/acceptance-mutations/summary.json`, 3/3:

1. use raw ingress as transfer authority;
2. export raw valid as collector acceptance;
3. guard the production predicate with `OOO_ASSERT`.

The latter three compile without `OOO_ASSERT`, reach VVP simulation, and are
rejected by their designated V9Y oracle.

## Layered current-design evidence

- Module aggregate:
  `evidence/module-current-v3/summary.txt`, total 111, passed 111, failed 0.
- Functional aggregate:
  `npc/rv64/eval/ppa/evidence/functional-aggregate-result.json`,
  module 111/111, official 177/177, AM 59/59, DiffTest mismatches 0,
  CoreMark and Dhrystone PASS.
- Architecture:
  `architecture/final-architecture-hard-gates.json`,
  DI-1..DI-5 and OOO-1..OOO-4 all GREEN.
- Functional and architecture evidence bind the same design ID shown above.

Key live SHA-256:

- `OooIntBackend.v`:
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`
- `OooMemOwnerTerminalCollector.v`:
  `9fe9715767ed3a3f6ac3b00ebec7a3450cfd76df4eef313e4c0293cc39d988ff`
- `OooPendingDrainResolveGate.v`:
  `36e55fea1ac5e407344ee6fcf36d80fdfc68263e37738e24a7b3ec2b91eb7514`
- `tb_ooo_int_backend.sv`:
  `6c86fbe71f7d686d86e97b30d53555bbf23a1288e3925b53e11c08f96acacf7b`

## Independent review

- V1 contract/review found the original active-holder control GAP.
- V2 found the assertion-macro placement and raw-ingress authorization
  blockers.
- V3 confirmed both RTL blockers were removed but rejected closure because
  the mutation summary predated the final TB edit.
- The mutations were rerun with the current TB.
- V4 matched the current RTL/TB SHA values, all 3/3 acceptance mutation
  markers, and the common functional/architecture design ID, then returned
  `PASS`.

Review reports and contracts are preserved as
`reviewer-{contract,report}-v1..v4`.

## Workflow and strict-guard evidence

The task-specific `npc-dev` forward test is:

- `.github/task-runs/2026-07-27-serialize-memory-owner-terminal-current/`;
- bounded context recall complete;
- five profile nodes PASS;
- runner exit code 0.

Two earlier forward-test attempts are retained as fail-closed diagnostics, not
completion evidence:

- `2026-07-27-rv64-v9y-serialize-memory-owner-terminal-npc-dev` included the
  version token as an ordinary focus term;
- `2026-07-27-serialize-memory-owner-terminal` ran before the newly written
  V9Y module-memory chunk had been incrementally refreshed into the retained
  index.

In both diagnostics all five profile nodes passed, but bounded context recall
correctly kept the overall run blocked. Refreshing
`.github/memory/{project-status.md,modules/npc.md}` supplied the independent
non-history focus; no recall gate was weakened.

The final strict guard is recorded in `evidence/strict-guard.status`:

- PASS: `agent-system`, `npc-dev`, `difftest`, `github-index`;
- FAIL: `rv64-linux` missing completed evidence.

The `rv64-linux` result remains an explicit system-terminal GAP. The previous
36,000-second current-family rootfs observation did not reach 17/17 guest
checks, natural poweroff, reset-syscon completion, `GOOD TRAP`, or a terminal
transaction marker. V9Y does not claim Linux completion, and repeating the
same bounded configuration would not close this gate.

The raw-evidence index was generated successfully with 491 assets and
296,521,308 bytes, including the strict-guard status:

- `evidence-index.md`;
- SHA-256
  `8e077496388028dff7f8ce4f3053a55be76a6cc9585cc5d3f586c13a2f39c50b`;
- `index-evidence` exit code 0, stored index document refreshed.

## Remaining mainline

`SERIALIZE-G1` remains OPEN. The next work must cover:

- pending architectural trap against the same memory-owner terminal contract;
- seven serialized kinds across both lanes with one combined exactly-once
  observation of architectural side effect, retirement, redirect, holder/stop
  clear, MMU action, and memory terminal;
- full Linux flag-on terminal transaction evidence;
- architecture-stable freeze, then synthesis/STA/power and PPA.

No synthesis, STA, or power conclusion is made here; `ppa=UNQUALIFIED`.
