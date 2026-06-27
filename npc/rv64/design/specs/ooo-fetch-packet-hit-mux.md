# OooFetchPacketHitMux Boundary Spec

## 1. Requirement

Branch and JALR prefetch hits can use packet payload from two sources:

- the same-cycle fetch response capture;
- the stored branch prefetch buffer payload.

Both paths use identical source-selection equations.  `OooFetchPacketHitMux`
extracts the repeated packet mux so prefetch-hit payload semantics are local and
testable.

The parent keeps ownership of hit/match predicates, target validation,
prefetch-buffer state, redirect decisions and FIFO seed policy.

## 2. Interface Contract

Inputs:

- `rsp_select_i`: select same-cycle response payload when true;
- response packet payload: slot0/slot1 PC, next PC, instruction, response and
  packet next PC;
- buffered packet payload with the same shape.

Outputs:

- selected hit packet payload with the same shape.

The module does not decide whether a hit is available, does not compare target
PC, and does not mutate any buffer or FIFO state.

## 3. State Machine

There is no internal state.

Combinational rule: every output selects response payload when `rsp_select_i`
is true, otherwise buffered payload.

## 4. Invariants

- All selected fields come from the same source in a given cycle.
- Payload bits are copied exactly; opcode and response fields are not decoded.
- The module is valid for both branch-prefetch and JALR-prefetch hit payloads.
