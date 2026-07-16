# Ordinary FENCE drain-ordering contract

## 1. Scope

This core is a single-hart implementation with no multi-master coherent cache
owner.  Within that product boundary, an ordinary RV64 `FENCE` is an
architectural serialization point: every older backend and memory-side owner
must be quiet before the instruction retires, and no younger device access may
be issued before that retirement.

`FENCE.I`, `SFENCE.VMA`, `WFI`, `ECALL`, xRET and interrupt behavior are not
redefined here.  They retain their existing specific pending-system payloads,
flush/redirect actions and capture priority.

## 2. Owner chain

```text
DecodeUnit CTRL_FENCE
  -> OooFetchHeadClassifyGate SYSTEM + STOP facts
  -> OooPendingDispatchArbiter (IRQ remains higher priority)
  -> OooPendingSystemSequencer (generic system; all specific flags are zero)
  -> OooPendingDrainResolveGate
  -> OooControlCommitSequencer generic system commit
  -> normal commit0 architectural observation, exactly once
```

An ordinary FENCE never enters the integer ROB/IQ as a backend no-op.  A
lane1 FENCE may be captured only after the older lane0 instruction fires; this
preserves the packet's program order while stopping all younger packets.

## 3. Completion predicate

The common backend drain predicate remains:

```text
ROB empty
&& integer issue queue empty
&& no synthetic lane1 retire/drop owner
&& mem_retire_quiet
```

`mem_retire_quiet` proves the SQ is empty and no committed-store drain is in
flight.  Ordinary FENCE adds the following term at the final
`drain_complete` edge only:

```text
mem_idle
```

`mem_idle` is owned by `OooIntBackend` and requires the MIQ, legacy memory
pending owner, bridge-facing request buffer, and memory issue reservation to
be empty.  A bridge transaction accepted from the core remains represented by
the MIQ until its response, so this term also closes the external bridge
in-flight window.  The extra term is deliberately FENCE-specific; it does not
change the established completion predicate for WFI/SFENCE/FENCE.I/ECALL or
other generic control events.

## 4. Priority and retirement invariants

- IRQ capture wins over a simultaneous head0 or lane1 FENCE candidate.
- Direct/external flush clears or resets a pending FENCE and cannot produce a
  ghost control commit.
- `store -> FENCE -> device load` exposes the store probe and committed SQ
  drain before the device read request.
- FENCE retirement requires both the common backend/SQ predicate and
  `mem_idle`.
- The drain edge clears `pending_system` in the same architectural event that
  the control-commit sequencer samples; therefore the FENCE appears on commit0
  for exactly one cycle and contributes one ISA retirement.
- Ordinary FENCE causes no TLB/I-cache flush and no xRET redirect.

## 5. Focused verification

| Test | Contract slice |
| --- | --- |
| `tb_ooo_fetch_head_classify_gate` | ordinary FENCE forms SYSTEM/STOP facts |
| `tb_ooo_fetch_head_pair_gate` | lane0 ordinary + lane1 FENCE boundary |
| `tb_ooo_pending_dispatch_arbiter` | IRQ priority, lane1 capture and flush clear |
| `tb_ooo_pending_drain_resolve_gate` | FENCE-specific MIQ/bridge/reservation idle term; non-FENCE behavior unchanged |
| `tb_ooo_control_commit_sequencer` | one-cycle generic FENCE control commit |
| `tb_ooo_priv_system` | full `store -> FENCE -> device read` ordering, one drain, one FENCE retirement |

