# OooCsrTrapRequestMux

## Scope

`OooCsrTrapRequestMux` owns the pure combinational request selection that feeds
`CsrFile` trap/return side effects from the control plane (`control/OooControlPlane`,
historically `OooAluFetchCore`).

It does not own CSR architectural state, CSR read-modify-write legality,
privilege delegation, trap target selection, fetch redirect, backend drain,
pending-owner state, final terminal trap/exit output, or simulation exit.

## Inputs

- Commit exception facts from commit lane 0/1.
- Drained pending architectural trap payload.  The upstream
  `OooPendingDrainResolveGate` must qualify this boundary with the exact
  memory-owner terminal scalar.
- Drained pending SYSTEM facts for ECALL, xRET, and interrupt entry.
- `csr_ecall_cause_i` from `CsrFile`, which depends on current privilege state.
- SATP write and SFENCE commit pulses, used only as privileged predictor
  boundary contributors.

## Rules

1. Commit exception trap valid is lane0 exception OR lane1 exception.
2. If both commit lanes are exceptional, lane0 payload wins.
3. Pending architectural trap and pending SYSTEM requests are eligible only
   when `!core_commit_exception_trap_o && stop_pending_i &&
   drain_complete_i`.  The commit-exception term aligns the emitted request
   pulses with CsrFile's `mem > ex > irq` selected transaction: a same-edge
   ROB-head exception emits only `trap_mem_valid_o`, while the younger pending
   holder is cleared through the existing commit-trap recovery path.  For an
   architectural trap, the upstream drain value must remain zero while any
   older memory owner is active without an accepted exact terminal transfer;
   collector-pending-only state is eligible and does not wait for tracker
   free.
4. Execute trap valid is pending architectural trap fire OR pending ECALL trap.
5. If architectural trap fire and ECALL trap are both true, architectural trap
   payload wins, matching the old parent mux.
6. Pending interrupt entry and xRET are eligible only through the same drained
   pending SYSTEM boundary.
7. SRET is detected from `pending_system_inst_i[31:20]`; `mret_valid_o` remains
   the generic xRET boundary pulse, while `real_mret_valid_o` excludes SRET.
8. `priv_predictor_boundary_o` is asserted for any CSR trap, any xRET, SATP
   write commit, or SFENCE commit.
9. The three output classes remain distinct at the CsrFile boundary.
   Pending-control outputs are masked when `trap_mem_valid_o` wins, while
   CsrFile retains `mem > ex > irq` as a fail-closed final priority.  The
   selected delegation, xEPC/xCAUSE/xTVAL update, and tvec target must not mix
   payloads from losing classes.

## Invariants

- The module is purely combinational and contains no state.
- It never changes CSR state directly.
- It preserves old externally observed parent wires:
  `pending_system_ecall_trap_w`, `pending_arch_trap_fire_w`,
  `csr_trap_mem_*`, `csr_trap_ex_*`, `csr_trap_irq_valid_w`,
  `csr_mret_valid_w`, `csr_sret_valid_w`, and
  `priv_predictor_boundary_w` remain visible in `OooControlPlane`.
- Trap payload outputs are meaningful when their corresponding valid output is
  true; inactive payloads follow the old mux defaults and are not architectural.
- The mux does not form the Vectored offset.  CsrFile alone applies
  `BASE+4×cause` when the selected record is an interrupt and the selected
  mtvec/stvec MODE is 01; synchronous records always select BASE.

## Verification

- Standalone module testbench covers lane priority, drained gating, ECALL vs
  architectural trap priority, IRQ request formation, xRET/SRET split, and
  privileged predictor boundary contributors.
- `tb_ooo_pending_arch_trap_memory_terminal` connects the production drain gate
  directly to this mux and checks active-holder suppression plus exact
  terminal/pending-only fire, payload, and predictor-boundary observations.
- `tb_ooo_serialized_owner_exactly_once` connects the production run gate,
  birth arbiter, pending trap/system sequencers, drain gate, stop sequencer,
  this request mux, and `CsrFile`.  It observes commit-trap request masking,
  same-edge head0/lane1/IRQ birth priority, live-owner exclusion of
  ECALL/IRQ/xRET/CSR/FENCE, C0 request, C1 owner/stop clear and C2 no-repeat.
  It counts every raw request pulse and contains no de-duplication logic.
- Integration must still run `tb_ooo_alu_fetch_core`, lint, build, module
  regression, and privileged/FP official tests because CSR/trap timing is a
  cross-cutting precise exception boundary.
- `make -C npc/rv64 check-vectored-trap` binds the mux outputs through CsrFile
  and the full OoO redirect/xRET path, including simultaneous-source priority
  and compile-success negative RTL variants.

The clocked integration closes the pending architectural-trap subrange for
next-edge owner/stop clear, one CsrFile sample, no repeat, and constructive
exclusion against ECALL/IRQ/xRET/CSR/FENCE.  It does not close the complete
per-kind post-fire lifecycle of the eight pending SYSTEM kinds, simulation
exit, Linux terminal behavior, or physical PPA.
