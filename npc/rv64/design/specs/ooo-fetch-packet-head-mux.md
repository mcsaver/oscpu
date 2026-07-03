# OooFetchPacketHeadMux Boundary Spec

> ⚠️ **状态(2026-07-03 RTL 重读)**：bypass 臂为配置性死路——`OOO_ROB_WALK_MODE=1'b1`（默认）
> 使 `fetch_rsp_dispatch_bypass` 恒 0（`OooFrontendRunGate.v:62-70`，防 bypass-after-kill），
> `bypass_valid_i` 永不为真，本 mux 实际恒选 FIFO head 臂；拆除计划见
> `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 1. Requirement

`OooFrontend`（原 `OooAluFetchCore`，已重构删除）can consume the current fetch packet from two mutually
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
