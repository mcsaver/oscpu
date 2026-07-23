# IFU fault PC/cause/tval owner derivation

## Byte ownership

`rsp_resp0_bytes_i` is the number of consecutive successful bytes starting at `rsp_pc_i`.
`OooFetchPacketDecode` therefore computes the first failing halfword address once at the response
boundary:

```text
fault_tval = rsp_pc + rsp_resp0_bytes
```

Instruction ownership is independently derived from decoded lengths:

- if the lane0 instruction range intersects the failing segment, lane0 owns the fault and
  `xEPC=dec0_pc`;
- otherwise lane1 owns it and `xEPC=dec1_pc`;
- both cases retain the packet-level `fault_tval` without reconstructing it from either slot PC.

This matters for 32-bit instructions whose low halfword succeeds and upper halfword fails.  For
example, with `packet_pc=...0ffe` and `F=2`, `xEPC=...0ffe` while `xTVAL=...1000`.

## Registered lifecycle

The FIFO stores `fault_tval` in the same atomic packet word as PC, responses and decoded metadata.
The frontend projects only the FIFO head field. `OooFrontendDispatchGate` carries no PC/cause/tval
payload; it qualifies the lane1 barrier acceptance event with `dispatch0_ready_i`. Lane0 and lane1
capture select the relevant instruction PC but use the common packet frontier. The pending
sequencer stores and holds `cause/pc/tval` until drain, clears all three on a branch-resolution
squash, and the CSR request mux selects pending `tval` only when the pending architectural trap
fires. `OooStopPendingSequencer` carries only the stop-validity bit; its branch-squash clear is
checked independently from the payload sequencer.

The evidence JSON carries an exact 24-row manifest for PF/AF, C/C, C/U, U/C and U/U layouts,
F0/F2/F4/F6, lane owner and capture/pending/drain status. A separate READY-stall row proves that
the current FIFO-head tuple is not captured before the lane1 barrier acceptance event.

## Compressed control row

For `c.beqz` at `PC0` followed by a 32-bit lane1 instruction with `F=4`:

- lane1 instruction PC is `PC0+2`;
- the failing upper halfword address is `PC0+4`;
- predicted-not-taken terminal PF/AF drains `(xEPC,xTVAL)=(PC0+2,PC0+4)`;
- actual-taken resolution clears the speculative pending tuple;
- predicted-taken makes lane1 invisible, so no fault owner or pending tuple is created.

## PPA boundary

The 64-bit addition remains at the response/FIFO boundary and is not added to the late trap-request
critical path.  This task validates architectural ownership only; it does not qualify timing, area
or power.
