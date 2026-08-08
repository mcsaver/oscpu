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
2. `pending_system_csr_commit_o` is true only when the pending SYSTEM entry is
   a dispatched CSR with a live raw ProducerId lease, commit0 is a valid
   non-exceptional CSR, and both full ProducerId and PC match. Raw lease or the
   dispatched logical claim seals the queue-head fallback on mismatch.
3. The side-effect/readback CSR access instruction priority is commit0 CSR,
   pending SYSTEM entry, lane1 CSR head, then lane0 head. This view remains the
   only source of `csr_access_*` and may depend on commit/pending state.
4. Lane1 CSR probe is allowed only when dispatch is valid, lane0 is not SYSTEM,
   lane1 is a barrier, and lane1 raw decode says CSR.
5. CSRRS/CSRRC/CSRRSI/CSRRCI with zero rs1/zimm are read-only no-ops.
6. `pending_system_satp_write_commit_o` requires a real pending SYSTEM CSR
   commit, `CSR_SATP`, and a write-needed operation.
7. `pending_system_sfence_commit_o` is gated by the drained pending SYSTEM
   boundary.
8. The legality-only `csr_probe_*` view selects lane1 when rule 4 holds and
   otherwise lane0. Its valid is `head0_csr_raw_i || head1_csr_probe_o`.
9. `csr_probe_*` is head-only: it must not depend on any `core_commit0_*`,
   `pending_system_*`, `csr_access_*`, GPR data, stop, or drain signal.

## Interface and timing contract

| View | Producer inputs | Consumer | Timing | Side effects |
| --- | --- | --- | --- | --- |
| `csr_access_valid/addr/funct3/rs1_idx/rs1_data` | commit0, pending SYSTEM, head fallback | `CsrFile` readback and architectural commit | same-cycle combinational | allowed only when `csr_commit_i` fires and main legality passes |
| `csr_probe_valid/addr/funct3/rs1_idx` | current head0/head1 classification and instruction bits only | `CsrFile` legality probe | same-cycle combinational | forbidden |

There is no ready/valid handshake and no retained payload. Both views may be
valid in the same cycle and may describe different CSR instructions. The probe
answer always belongs to the current head view; commit or pending priority must
never replace it.

The module has no flush/stall state to clear or hold. Upstream flush/capture
gating owns whether a head result is consumed. Trap/exit and privileged-policy
transitions remain higher priority than ordinary pending capture; this module
must not add a post-edge policy bypass or a backward ready path.

## Invariants

- The module is purely combinational and contains no state.
- It preserves old parent-observable wire names when instantiated in
  `OooControlPlane`, especially `pending_system_csr_commit_w`.
- It never asserts CSR commit by looking only at pending state; the matching
  commit0 CSR PC must also be present.
- Inactive payloads follow the old parent mux defaults and are not architectural.
- Changing only commit/pending inputs may change `csr_access_*` but must leave
  every `csr_probe_*` output unchanged.
- The lane selected by `csr_probe_*` is exactly the lane consumed by
  `OooCsrIllegalProbeGate`; legality is never registered or shifted by one cycle.

## Verification

Standalone testbench covers commit0 priority, pending SYSTEM access, lane1
probe gating, read-only set/clear no-op detection, SATP write commit, SFENCE
commit, no-drain suppression, different-instruction access/probe concurrency,
and commit/pending perturbation invariance of the probe view.
