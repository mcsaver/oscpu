# Review summary

## V1 bounded-material review

- contract: `.github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/subagent-contracts/v9j-ifu-tval-limited-material-review-v1.json`
- contract SHA-256: `a6fc02e6627523b4a9c7a75c705266ace3a3657a948cb4f8f954c2367aa78c1a`
- result: `GAP` in evidence qualification, not a confirmed RTL function error.

The reviewer requested direct constraints for `OooFrontend` head projection,
`OooFrontendDispatchGate` READY acceptance, `OooStopPendingSequencer` field responsibility and an
exact 24-row joint lifecycle manifest.

## Implementer response

1. Added a compile-success `OooFrontend` variant that substitutes FIFO lane0 PC for the projected
   fault frontier; `tb_ooo_core_top_glue` rejects it at the precise `mtval` oracle.
2. Added a READY-stall row and a dispatch-gate variant that removes `dispatch0_ready_i` from
   `dispatch1_barrier_fire_o`; early capture is rejected.
3. Added a stop-sequencer branch-squash variant plus a fail-closed interface audit proving the
   module carries only `stop_pending_o`, not cause/PC/tval payload.
4. Added schema-v2 ordered manifest parsing for all 24 PF/AF/layout/frontier/owner rows; field or
   row-order drift is rejected.

## V2 bounded-material review

- contract: `.github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design/subagent-contracts/v9j-ifu-tval-limited-material-rereview-v2.json`
- contract SHA-256: `ccc091eaa009c44e934e2ed310f1527312ad9083b8adde505a31f1741e04378b`
- result: `PASS`, strictly for `IFU-TVAL-G1` at design ID
  `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`.
- confidence: high; no remaining concrete PC/cause/tval cycle counterexample was found within the
  supplied post-detection owner path.
- scope extension: none.

The reviewer explicitly kept initial AXI/PMP/PMEM fault generation, full-core architecture and PPA
outside this PASS. Current architecture remains `GAP`; PPA remains `UNQUALIFIED`.
