# V9D FDG-G1 current-design contract

## Scope

- Engineering domain: local RV64 Verilog/SystemVerilog dual-issue OoO processor.
- Source-to-sink path: `OooFetchHeadClassifyGate` / `OooFetchHeadPairGate` →
  `OooFrontendDispatchGate` → `OooFrontendBackendDispatchMux` →
  `OooCoreTopGlue` backend dispatch interface.
- Precise-trap owner path: `OooPendingDispatchArbiter` →
  `OooPendingTrapExitSequencer` → `OooCsrTrapRequestMux` / `CsrFile`.
- Production RTL is expected to remain unchanged. This slice rebinds FDG-G1
  verification evidence to the current full-RTL design identifier.

## Contract

1. A valid head0 carrying `OOO_SLOT_FACT_ARCH_TRAP` must never assert the
   ordinary frontend-to-backend admission signal in the same cycle.
2. The same head0 must not appear as either backend lane operation through the
   final frontend backend-dispatch mux.
3. The precise-trap owner captures the instruction PC, illegal-instruction
   cause and instruction-value `tval` exactly once; the invalid FP encoding
   never reaches architectural commit.
4. A legal FADD.S positive control must continue to use the FP/backend path.
   Closing the whole admission path is not a valid implementation.
5. The gate is combinational and does not own a transaction. READY affects
   fire, not the validity predicate. No new state, reset, stall or recovery
   behavior is introduced.
6. This architecture closure does not qualify synthesis, STA, Power or PPA
   promotion. `ppa=UNQUALIFIED` and `promotion_eligible=false` remain mandatory.
7. Canonical replay must serialize byte-stable evidence for the same RTL and
   oracle cohort. Only the exact per-run temporary compilation root may be
   replaced by a declared token before log hashing; diagnostic text, source
   paths, compile arguments, result markers and return codes remain intact.

## Required evidence

- Four illegal/reserved FP encodings plus one legal FADD.S positive control on
  the real decode/classify/admission chain.
- A clocked full-core M-mode program proving exact trap capture PC/tval,
  `mcause/mepc/mtval`, no ordinary or final backend presentation, no
  invalid-instruction commit, one known legal commit-observer hit, and handler
  return.
- Six compile-success RTL source variants covering the missing
  ordinary-admission exclusion, missing lane1 dual-dispatch exclusion,
  over-gated positive path, final backend-mux leak, CSR trap-PC offset and CSR
  trap-tval corruption; every variant must be dynamically rejected by its
  directed oracle.
- One compile-success verification configuration must point the same commit
  observation chain at a known older ADDI and make the zero-commit oracle fail,
  proving that observer is dynamically non-vacuous.
- A fresh exact module aggregate derived from the current `TESTS` inventory.
- Full RTL and relevant source SHA-256 bindings under one current design ID.
- Two consecutive canonical runs with identical module, RTL-variant, oracle,
  raw-log and result SHA-256 values.

## Canonical command

`make -C npc/rv64 check-fdg-arch-trap`
