# V10D local RV64 simulation-exit transaction contract

## Scope

This slice covers only the local RV64 OoO simulation-exit/semihost
transaction:

`OooPendingDispatchArbiter`
→ `OooPendingTrapExitSequencer.pending_exit_o`
→ `OooPendingDrainResolveGate`
→ `OooTrapExitEventMux.exit_o`
→ `OooTrapExitOutputSequencer.exit_valid_o/halted_o`.

V9Y/V9Z memory-owner terminal, V10A pending architectural-trap clocked
exactly-once, V10B eight-kind pending SYSTEM post-fire, and V10C
current-design evidence are prerequisites. This slice does not reinterpret
their bounded verdicts.

## Cycle contract

| phase | registered owner/stop | memory terminal | raw event | next-state observation |
| --- | --- | --- | --- | --- |
| birth edge | accepted lane0 or lane1 exit capture | unconstrained | no prior transaction event | `pending_exit=1`, `stop_pending=1`, exact exit kind/payload |
| active-holder C0 | exit owner live | `mem_owner_terminalized=0` | `trap_exit_output_exit=0` | owner, payload and stop remain live |
| terminal C0 | exit owner live | exact accepted terminal or valid pending-only phase | `trap_exit_output_exit=1` exactly once | exit holder and stop clear on the edge; output latches exit kind and halt |
| C1 | no recapture | irrelevant | raw exit event is 0 | `pending_exit=0`, `stop_pending=0`, `exit_valid=1`, `halted=1` |
| C2+ | no recapture | irrelevant | raw exit event remains 0 | latched terminal status remains stable |

`trap_exit_output_exit` is an event pulse. `exit_valid` and `halted` are
latched terminal status. The verification scoreboard counts every raw event
and contains no deduplication state.

## Priority and recovery contract

- lane0/lane1 exit capture must be exact-one and retain the selected
  ECALL/EBREAK classification;
- commit trap, direct frontend flush, pending architectural trap, pending
  SYSTEM, branch/jump/memory resolve, and exit may overlap only through an
  explicit priority or a proved unreachable combination;
- `core_local_flush` must clear the pre-ROB exit holder and the matching stop
  owner without emitting a terminal exit for a squashed transaction;
- an older active memory holder blocks the raw exit event;
- collector-accepted same-edge terminal transfer may authorize the event;
- a duplicate or mismatched memory-terminal ingress remains fail-loud and
  cannot authorize exit;
- no assertion is weakened and no terminal-event filtering or deduplication
  is added.

## Verification ladder

1. independent read-only pre-review of the production signal/priority graph;
2. a focused production-module clocked RED/GREEN test that counts raw exit
   pulses and checks C0/C1/C2 state;
3. compile-success RTL variants for the precise exit gate, holder clear,
   stop clear, lane selection, memory-terminal gate, and raw-event no-repeat;
4. assertion-enabled and assertion-disabled focused runs;
5. current module aggregate, then functional and architecture evidence only
   when production RTL changes;
6. independent final review, memory/task-run/index/e2e/strict guard closure.

## Explicit non-claims

Until all criteria pass, `SERIALIZE-G1=P1 OPEN`,
`architecture_freeze=GAP`, `ppa=UNQUALIFIED`, and
`promotion_eligible=false`. Linux/rootfs terminal completion is a separate
system-level observation.
