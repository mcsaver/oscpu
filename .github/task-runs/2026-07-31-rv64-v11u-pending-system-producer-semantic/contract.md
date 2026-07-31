# V11U pending-system producer contract

## RV64 RTL object

- Unit: `pending-system-producer`.
- Product instance: `NpcTop.u_core.u_ooo_core.u_control_plane.u_pending_system_sequencer`.
- Production RTL: `OooPendingSystemSequencer.v`, `OooCsrAccessRequestMux.v`, and the `OooIntBackend.v` global live-mask integration.
- ProducerId configurations: `OOO_PRODUCER_GEN_W=1` and `4`.

## Required transaction semantics

1. Pre-ROB pending serialized work owns no ProducerId.
2. Only accepted pending CSR dispatch births the exact allocated `{generation, rob_idx}`.
3. The raw `producer_valid_q/producer_id_q` lease survives mutable metadata clear, `clear_dispatched_i`, refresh, and recapture.
4. Exact pending-CSR retirement or the same core-local flush ends the lease.
5. CSR commit authorization requires the raw/logical claim seal, full ProducerId equality, and PC coherence.
6. The raw lease participates in the `OooIntBackend` live mask and ProducerId reuse fence.

## Evidence boundary

- Current design ID: `sha256:82febf4aa834d61be398197015257714cc53d81f9291a2ba998ba28644041ac4`.
- Local directed simulation and fail-closed evidence checking only.
- No production RTL semantic change, full-system rerun, synthesis, STA, power, or PPA promotion is claimed.
- A3 original `FAIL` remains historical evidence; its system transaction is complete and its old dmesg oracle remains classified as a false positive by the independent checker replay.
- Whole-architecture state remains `GAP`; the seven floating-point producer units remain open.

