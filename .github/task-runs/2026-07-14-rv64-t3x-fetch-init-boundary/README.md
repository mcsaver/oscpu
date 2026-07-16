# T3X Fetch Init Boundary

## Objective

Close the remaining T3W exact-STA path from fetch FIFO `count_o[0]` through
frontend dispatch/flow control into the wide `OooFetchAxiBridge` request-init
register muxes, without adding a fetch state or changing external latency.

## Baseline

- frozen netlist: T3W `707ba389b5386e5d7ad295b12f9822b47f51262c61550d970d9b6ee09f1dd232`
- exact 5.0 ns STA: WNS `-0.330 ns`, TNS `-118.93 ns`, combinational loops `0`
- mapped startpoint: `u_fetch_packet_fifo/count_o[0]`
- mapped endpoints: `u_ooo_fetch_bridge/fetch_data_q[*]` and `paddr0_q[*]`

## Architectural cut

The external request-fire edge now captures only immutable request context
(`pc`, paging, privilege, SATP, Svpbmt) and enters the already existing
`S_CACHE_READ` state.  `S_CACHE_READ` owns initialization of all derived
physical-address, walk, packet, and response scratch before `S_LOOKUP` can
consume them.  Cache and ITLB issue in `S_CACHE_READ` use only the immutable
context, so this retiming changes neither the state count nor visible latency.

## Required evidence

- focused dirty-owner / cache-read-boundary simulation:
  `evidence/focused-v3/` (`[T3X-IFU-DIRTY-FIRST-FAULT]` and
  `[T3X-IFU-INIT-BOUNDARY]`)
- source ownership audit with three in-memory negative mutations:
  `evidence/structural-source-v1/audit.json`
- temporal assertion negative mutation: `evidence/scratch-init-assert-negative-v1/`
- eight real Sv39 second-page invalid-PTE rows with exact F=2/4/6 split,
  prefix/tail and no-younger-AR/no-fill ownership checks:
  `evidence/second-page-fault-owner-v2/`
- fresh frozen-input synthesis: PASS, netlist SHA256
  `12e786d6d362a36e1e8f19fa398dd258a7e80843657ab718d6c208436490d2f0`
- zero-exception exact OpenSTA at 5.000 ns:
  `evidence/opensta-fresh-t3x-initial/` — WNS `-0.220 ns`, TNS
  `-61.05 ns`, combinational loops `0`

## Result and reviewer boundary

T3X removed every FetchBridge endpoint from the fresh top-40 and improved the
T3W baseline from WNS/TNS `-0.330/-118.93 ns` to `-0.220/-61.05 ns`.  The
remaining top-40 is 25 `OooFetchPcOutstandingSequencer` endpoints plus 15
pending-trap-exit endpoints.  Therefore the request-init ownership cut is
accepted as effective and functionally covered, but it is not a 200 MHz claim;
full architectural regression and final strict guard remain owned by the
eventual timing-closure iteration.
