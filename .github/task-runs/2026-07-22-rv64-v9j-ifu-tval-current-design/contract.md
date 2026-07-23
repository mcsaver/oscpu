# V9J IFU-TVAL-G1 current-design contract

- `debt_id`: `IFU-TVAL-G1`
- `profile`: `npc-dev`
- `canonical_command`: `make -C npc/rv64 check-ifu-tval`
- `production_rtl_change`: none expected; change RTL only if a directed row proves a root cause.
- `ppa`: `UNQUALIFIED`; this task does not promote physical PPA.

## Hardware boundary

For an instruction-fetch response whose successful byte frontier is `F`, the packet owns two
different architectural values:

- `xEPC`: start PC of the instruction that consumes the failing halfword;
- `xTVAL`: `packet_pc + F`, the exact address of the first failing halfword.

The owned path is
`OooFetchPacketDecode -> OooFetchPacketFifo -> OooFrontend head projection ->
OooFetchHeadPairGate/OooPendingDispatchArbiter -> OooPendingTrapExitSequencer ->
OooCsrTrapRequestMux`.

## Required dynamic rows

1. PF and AF over C/C, C/32, 32/C and 32/32 packet shapes, covering `F=0/2/4/6`, lane0/lane1,
   capture, pending hold and drained CSR request.
2. Real page-end PF rows for `F=2/4/6` from the fetch bridge through packet decode.
3. FIFO atomic metadata rows for `F=2/4/6`.
4. A 16-bit `c.beqz` owner followed by a lane1 fault at `F=4`:
   terminal PF/AF, actual-taken squash PF/AF, and predicted-taken invisible-lane PF/AF.
5. A lane1 PF held behind `dispatch0_ready_i=0`; no pending tuple may be captured before
   `dispatch1_barrier_fire_o`, and the accepted tuple must retain `xEPC=PC+2`, `xTVAL=PC+4`
   through pending and drain.
6. An exact 24-row joint manifest binding cause, packet layout, frontier, lane owner, capture,
   pending and drain fields rather than relying only on marginal counters.
7. Exact module aggregate and compile-success wrong-RTL variants that are dynamically rejected,
   including `OooFrontend` head projection, `OooFrontendDispatchGate` READY qualification and
   `OooStopPendingSequencer` branch-squash stop clearing.

## Success conditions

- all focused logs contain one exact PASS result and no failure marker;
- module aggregate is exact for the current `TESTS` inventory;
- every declared RTL variant compiles, is rejected by a cycle-level oracle, and leaves live RTL
  unchanged;
- the stop sequencer static audit proves its interface owns only stop validity and carries no
  cause/PC/tval payload;
- evidence records the current full-RTL `design_id` and exact source/artifact hashes;
- `arch_stable_freeze.py` independently reconstructs the evidence;
- the ledger closes only `IFU-TVAL-G1`; architecture freeze and PPA promotion remain separate.
