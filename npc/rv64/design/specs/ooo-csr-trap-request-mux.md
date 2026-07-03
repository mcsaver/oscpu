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
- Drained pending architectural trap payload.
- Drained pending SYSTEM facts for ECALL, xRET, and interrupt entry.
- `csr_ecall_cause_i` from `CsrFile`, which depends on current privilege state.
- SATP write and SFENCE commit pulses, used only as privileged predictor
  boundary contributors.

## Rules

1. Commit exception trap valid is lane0 exception OR lane1 exception.
2. If both commit lanes are exceptional, lane0 payload wins.
3. Pending architectural trap and pending ECALL are eligible only when
   `stop_pending_i && drain_complete_i`.
4. Execute trap valid is pending architectural trap fire OR pending ECALL trap.
5. If architectural trap fire and ECALL trap are both true, architectural trap
   payload wins, matching the old parent mux.
6. Pending interrupt entry and xRET are eligible only through the same drained
   pending SYSTEM boundary.
7. SRET is detected from `pending_system_inst_i[31:20]`; `mret_valid_o` remains
   the generic xRET boundary pulse, while `real_mret_valid_o` excludes SRET.
8. `priv_predictor_boundary_o` is asserted for any CSR trap, any xRET, SATP
   write commit, or SFENCE commit.

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

## Verification

- Standalone module testbench covers lane priority, drained gating, ECALL vs
  architectural trap priority, IRQ request formation, xRET/SRET split, and
  privileged predictor boundary contributors.
- Integration must still run `tb_ooo_alu_fetch_core`, lint, build, module
  regression, and privileged/FP official tests because CSR/trap timing is a
  cross-cutting precise exception boundary.
