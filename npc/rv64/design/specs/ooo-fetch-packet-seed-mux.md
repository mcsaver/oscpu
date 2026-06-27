# OooFetchPacketSeedMux Boundary Spec

## 1. Requirement

`OooAluFetchCore` owns redirect and recovery policy, but the conversion from
already-computed events into `OooFetchPacketFifo` `clear/seed` inputs is a pure
combinational action encoder.

`OooFetchPacketSeedMux` extracts only that encoder:

- decide whether the fetch packet FIFO should clear;
- decide whether it should seed one replacement packet;
- select the seed packet payload from fallthrough response, branch prefetch hit
  or JALR prefetch hit.

The parent keeps ownership of all event predicates, packet decode, branch/JALR
target validation, pending sequencing, trap/interrupt recovery and FIFO storage.

## 2. Interface Contract

Inputs are parent-generated event predicates:

- high-priority CSR trap and direct frontend flush;
- branch fallthrough capture response;
- branch speculative restore, pending branch commit/resolve, untracked branch;
- pending JALR/jump resolve and redirect cases;
- memory replay dispatch, CSR dispatch and CSR commit boundaries;
- drain-complete pending owner classification.

Inputs also include three packet payload sources:

- fallthrough response packet;
- branch prefetch hit packet;
- JALR prefetch hit packet.

Outputs are exactly the FIFO action interface:

- `clear_o`;
- `seed_valid_o`;
- seed slot0/slot1 PC, next PC, instruction, response and packet next PC.

The module does not generate event predicates, does not pop/enqueue FIFO
storage, and does not update `next_fetch_pc`.

## 3. State Machine

There is no internal state.

Combinational priority mirrors the old parent logic:

1. Start from no clear and no seed.
2. CSR trap clears and is re-applied as the final override.
3. Direct frontend flush clears, unless fallthrough response capture seeds the
   fallthrough packet.
4. Branch speculative restore clears.
5. Pending branch commit/resolve clears, except a valid branch prefetch hit
   seeds the branch prefetch packet.
6. Untracked branch resolve clears.
7. Pending jump/JALR resolve clears on misalignment or redirect without JALR
   prefetch hit; it seeds on redirect with JALR prefetch hit.
8. Pending memory replay dispatch and CSR dispatch are explicit no-op blockers.
9. CSR commit clears.
10. Drain-complete pending owners clear, except pending jump can seed from JALR
    prefetch hit.

## 4. Invariants

- `csr_trap_i` always forces `clear_o=1` and `seed_valid_o=0`.
- A seed and clear are not asserted together.
- Fallthrough, branch prefetch and JALR prefetch seed payloads are copied
  exactly without opcode or response interpretation.
- Memory replay dispatch and CSR dispatch do not mutate FIFO storage and block
  lower-priority drain/commit actions in the same combinational decision.
