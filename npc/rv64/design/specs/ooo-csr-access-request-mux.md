# OooCsrAccessRequestMux

## Scope

`OooCsrAccessRequestMux` owns the pure combinational selection of the CSR access
request sent to `CsrFile` from the control plane (`control/OooControlPlane`,
historically `OooAluFetchCore`).

It does not own CSR state, CSR legality, CSR write side effects, trap entry,
return side effects, redirect, pending-owner state, or final terminal output.

## Rules

1. `core_commit0_csr_o` is true only for a valid, non-exceptional commit0
   SYSTEM instruction whose funct3 is not zero.
2. `pending_system_csr_commit_o` is true when the pending SYSTEM CSR entry has
   been dispatched and the matching commit0 CSR reaches the same PC.
3. CSR access instruction priority is commit0 CSR, pending SYSTEM entry,
   lane1 CSR probe, then lane0 head.
4. Lane1 CSR probe is allowed only when dispatch is valid, lane0 is not SYSTEM,
   lane1 is a barrier, and lane1 raw decode says CSR.
5. CSRRS/CSRRC/CSRRSI/CSRRCI with zero rs1/zimm are read-only no-ops.
6. `pending_system_satp_write_commit_o` requires a real pending SYSTEM CSR
   commit, `CSR_SATP`, and a write-needed operation.
7. `pending_system_sfence_commit_o` is gated by the drained pending SYSTEM
   boundary.

## Invariants

- The module is purely combinational and contains no state.
- It preserves old parent-observable wire names when instantiated in
  `OooControlPlane`, especially `pending_system_csr_commit_w`.
- It never asserts CSR commit by looking only at pending state; the matching
  commit0 CSR PC must also be present.
- Inactive payloads follow the old parent mux defaults and are not architectural.

## Verification

Standalone testbench covers commit0 priority, pending SYSTEM access, lane1
probe gating, read-only set/clear no-op detection, SATP write commit, SFENCE
commit, and no-drain suppression.
