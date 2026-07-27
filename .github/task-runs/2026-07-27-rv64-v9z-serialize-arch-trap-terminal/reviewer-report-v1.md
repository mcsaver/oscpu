# Reviewer v1 report

## Verdict

`GAP` before the V9Z change.

Reviewed RTL path:

```text
OooPendingDrainResolveGate.drain_complete_o
  -> OooCsrTrapRequestMux.pending_arch_trap_fire_o
  -> trap_ex_valid_o / priv_predictor_boundary_o
```

The reviewed pre-fix gate required `mem_owner_terminalized_i` only when
`pending_system_i=1`.  With `pending_arch_trap_i=1`,
`pending_system_i=0`, and an active older memory holder
(`mem_owner_terminalized_i=0`), `drain_complete_o` could therefore assert
and the trap request mux could fire the pending architectural trap early.

## Cycle boundary

Common precondition:

- `stop_pending=1`
- backend drained
- `pending_control_ready=1`
- no replay
- non-FENCE
- `pending_arch_trap=1`
- `pending_system=0`

| owner phase | H active | exact accepted transfer | collector pending | tracker live | terminalized | pre-fix drain/fire | required |
|---|---:|---:|---:|---:|---:|---:|---:|
| active holder | 1 | 0 | 0 | 1 | 0 | 1/1 | 0/0 |
| same-edge exact terminal | 1 | 1 | 0 | 1 | 1 | 1/1 | 1/1 |
| collector-pending-only | 0 | 0 | 1 | 1 | 1 | 1/1 | 1/1 |
| tracker free | 0 | 0 | 0 | 0 | 1 | 1/1 | 1/1 |

The producer scalar in `OooIntBackend` already distinguishes exact accepted
terminal transfer from raw ingress, collector-pending-only state, and active
holder state.  The requested V9Z change must not alter collector/tracker
state or add terminal-event filtering.

## Minimal RTL boundary

The reviewer recommended this sole drain qualification change:

```verilog
wire pending_serialized_mem_terminal_w =
    !(pending_system_i || pending_arch_trap_i) ||
    mem_owner_terminalized_i;
```

The review explicitly rejected these alternatives:

- unconditional `mem_owner_terminalized_i`;
- `mem_idle_i` in place of the exact terminal scalar;
- new state;
- raw collector ingress as transfer authority;
- changes to CSR dispatch or the ordinary-FENCE `mem_idle_i` conjunct.

## Directed verification requested

1. Gate-level active-holder RED and exact-terminal/pending-only GREEN.
2. Gate-to-`OooCsrTrapRequestMux` integration, observing fire, request
   payload, and predictor-boundary outputs.
3. Compile-success mutations for a missing arch-trap term, full-`mem_idle`
   substitution, unconditional owner gating, and removal of the FENCE
   full-idle term.
4. Assertion-on and assertion-off focused configurations.
5. Preservation of the existing FENCE and V9Y owner-terminal assertions.

## Explicit unknowns

This review did not close:

- next-cycle clearing and exactly-once side effects after trap fire;
- architectural-trap overlap with ECALL, IRQ, xRET, CSR, or FENCE;
- simulation-exit ownership;
- the wider seven-kind exactly-once proof;
- `SERIALIZE-G1`, architecture-stable, Linux, or PPA qualification.

The reviewer requested a later scope extension covering
`OooPendingDispatchArbiter`, `OooStopPendingSequencer`,
`OooTrapExitEventMux`, CSR side-effect priority, and the frontend/writeback
redirect consumers.

## Contract and shell ownership

- Contract:
  `subagent-contracts/reviewer-v1.json`
- Contract SHA-256:
  `4e3623d6fe948c48604fa7b21d290e9d7da48dadde0c84d47c5329984c7a4ad9`
- Review mode: read-only local RTL evidence
- WSL engineering processes left running: none
- Unique WSL command ownership: explicitly returned to root

