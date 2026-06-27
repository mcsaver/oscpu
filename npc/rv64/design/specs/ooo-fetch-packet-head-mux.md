# OooFetchPacketHeadMux Boundary Spec

## 1. Requirement

`OooAluFetchCore` can consume the current fetch packet from two mutually
exclusive front-end sources:

- a just-returned fetch response that is bypassed directly into dispatch;
- the stored head entry of `OooFetchPacketFifo`.

The source selection is pure combinational payload muxing.  It should be kept
separate from response ready-valid, FIFO storage mutation, packet decode and
redirect/trap recovery state.

`OooFetchPacketHeadMux` extracts only this source selection.

## 2. Interface Contract

Inputs:

- `bypass_valid_i`: parent-selected dispatch bypass predicate;
- `fifo_head_valid_i`: stored FIFO head validity;
- decoded bypass packet fields: slot0/slot1 PC, next PC, instruction and
  response, plus packet next PC;
- FIFO head packet fields with the same shape.

Outputs:

- `head_has_packet_o`;
- selected slot0/slot1 PC, next PC, instruction and response;
- selected packet next PC.

The module does not decide whether bypass is legal.  It does not pop, enqueue
or seed the FIFO, does not inspect instruction contents, and does not update
`next_fetch_pc`.

## 3. State Machine

There is no internal state.

Combinational rules:

1. `head_has_packet_o = fifo_head_valid_i || bypass_valid_i`.
2. If `bypass_valid_i` is true, every payload output comes from decoded bypass
   inputs.
3. Otherwise every payload output comes from FIFO head inputs.

## 4. Invariants

- Bypass has payload priority over FIFO when both predicates are asserted.
- `head_has_packet_o` may be true even when FIFO is empty, as long as bypass is
  valid.
- The module preserves payload bit patterns exactly; it does not reinterpret
  response codes or RVC length.
