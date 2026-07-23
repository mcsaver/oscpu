# V9D FDG-G1 independent review packet

## Review scope

- Engineering scope is the local RV64 Verilog/SystemVerilog dual-issue OoO core only.
- The slice changes verification and evidence workflow files; production RTL is unchanged.
- Current full RTL identity is
  `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`.
- Claim under review is only `FDG-G1=CLOSED` for that identity. Full-core
  `ARCH_STABLE` and PPA promotion are explicitly outside the claim.

## RTL owner and invariant

- Classification/admission path is
  `OooFetchHeadClassifyGate/OooFetchHeadPairGate` →
  `OooFrontendDispatchGate` → `OooFrontendBackendDispatchMux` →
  `OooCoreTopGlue` backend interface.
- Precise-trap owner path is `OooPendingDispatchArbiter` →
  `OooPendingTrapExitSequencer` → `OooCsrTrapRequestMux/CsrFile`.
- A valid head0 with the packed architectural-trap fact must not assert ordinary
  backend admission, must not appear on either final backend lane, and must not
  commit as an invalid FP instruction. The independent trap owner must capture
  cause/PC/tval once and return through MRET.
- A legal FADD.S is the positive control; closing all ordinary admission is an
  invalid implementation.
- The dispatch gate is combinational and owns no transaction state. READY only
  determines fire; it does not redefine the validity predicate.

## Exact dynamic evidence

- Canonical command: `make -C npc/rv64 check-fdg-arch-trap`.
- Focused marker:
  `[FDG-G1-FOCUSED] illegal_fp_cases=4 illegal_classified=4 arch_trap=4 fp_disabled=4 backend_blocked=4 legal_fp_cases=1 legal_backend_present=1 PASS`.
- Full-core program marker:
  `[FDG-G1-PROGRAM] arch_trap_capture=1 capture_pc_match=1 capture_tval_match=1 ordinary_backend_present=0 core_backend_present=0 commit_oracle_hits=1 illegal_fp_commit=0 handler=1 mret=1 cause=2 csr_mepc_match=1 csr_mtval_match=1 PASS`.
- The current module inventory is dynamically derived from the testbench Makefile
  and passed 109/109.
- Six current-source, compile-success RTL verification variants were each
  dynamically rejected by a directed oracle:
  `ordinary_arch_trap_exclusion_removed`,
  `lane1_arch_trap_exclusion_removed`, and
  `ordinary_admission_forced_closed`,
  `final_backend_arch_trap_leak`,
  `trap_ex_pc_corrupted`, and
  `trap_ex_tval_forced_zero`.
- These variants independently cover ordinary admission, lane1 dual dispatch,
  false-closed positive behavior, final backend packet presentation, CSR trap
  PC and CSR trap tval. Aggregate result is compile-success 6/6, dynamic
  rejection 6/6, production source unchanged.
- A compile-success verification configuration points the same two-lane
  commit-valid/PC observer at the known older ADDI. It changes the zero oracle
  to one and is dynamically rejected 1/1. The production program independently
  records `commit_oracle_hits=1` on that exact ADDI while retaining
  `illegal_fp_commit=0` for the faulting PC.
- An early classifier-binding variant was deliberately discarded: the full-core
  trap owner intercepted that condition before ordinary dispatch-valid, so the
  selected dynamic oracle did not reject it. It is not counted in the 3/3 claim.

## Evidence binding and claim boundary

- FDG result artifact SHA-256:
  `e62e1b2c867ddedb103166222b572f503ff1d5975c320bec1eac54038a76731d`.
- FDG raw log SHA-256:
  `47eb6b670d2ed21794fc0a2bd549cb8d823328f8e6044a343de8c1212302b765`.
- RTL-variant summary SHA-256:
  `c175817adc7c463d8f99e07bc565008548c5a75bd247914ff6f54e45e4f345d7`.
- The builder and independent arch-stable validator recompute the full RTL
  identity, exact source bindings, focused/program markers, all 109 module logs,
  all six variant transformations, the commit-observer probe and their directed
  rejection markers.
- FDG-specific unit tests pass 9/9, including semantic cuts of focused/program
  counters, PC/tval and commit-observer cuts, variant/probe aggregate cuts,
  live module inventory and live variant reconstruction.
- All nine directed architecture gates are GREEN on the same RTL identity;
  artifact SHA-256 is
  `f33dfb9229724fda5dba2b35dfafc641e7aac84d45f31207c6ae6ba341b4dd4f`.
- The independent full-core audit passes all FDG ledger binding and semantic
  checks but remains `GAP` with 44 blockers. It states `ppa=UNQUALIFIED` and
  `promotion_eligible=false`; artifact SHA-256 is
  `5f2e0d647ae1d0f281696a993bd506434f121a17b9d974b0719e696505199b76`.

## Adversarial review questions

1. Can an architectural-trap head0 still be presented through any ordinary or
   final backend lane without violating one of the supplied exact counters?
2. Are the six RTL source-cut variants plus the commit-observer probe sensitive
   to false-open, false-closed, metadata-corrupt and vacuous-observer behavior,
   or can a false green survive them?
3. Does the full-core marker establish non-vacuous trap entry, handler return
   and zero invalid-instruction commit without overclaiming all FP legality?
4. Can stale/cross-design evidence satisfy the independent semantic validator?
5. Does any statement incorrectly promote the 9/9 directed architecture result
   into full-core arch-stable or qualified PPA status?

Return `VERDICT=PASS` or `VERDICT=FAIL`, list P0/P1/P2 findings with a concrete
local RTL/evidence counterexample, and state residual limitations and the exact
claim boundary.
