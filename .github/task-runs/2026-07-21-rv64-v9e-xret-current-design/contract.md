# V9E XRET-G1 current-design contract

## Scope

- Engineering domain: local RV64 Verilog/SystemVerilog dual-issue OoO processor.
- Legality source: `OooFetchHeadClassifyGate` derives MRET/SRET current-mode
  legality from the architectural privilege mode and `mstatus.TSR`.
- Precise-exception owner path: `OooFetchHeadPairGate` /
  `OooPendingLane1CaptureGate` → `OooPendingDispatchArbiter` →
  `OooPendingTrapExitSequencer` → `OooCsrTrapRequestMux` / `CsrFile`.
- Legal-return path: `OooPendingSystemSequencer` →
  `OooCsrTrapRequestMux` → `CsrFile` → frontend return redirect.
- Production RTL is expected to remain unchanged. This slice rebinds
  XRET-G1 verification evidence to the current full-RTL design identifier.

## Contract

1. MRET is legal only in M mode. MRET decoded in S or U mode retains its raw
   xRET/system classification but must produce an illegal-instruction
   architectural exception.
2. SRET is illegal in U mode. In S mode it is also illegal when
   `mstatus.TSR=1`; M-mode SRET is not restricted by TSR.
3. An illegal xRET must select the architectural-exception owner instead of
   the pending-system owner in both head0 and lane1. It must not produce a
   `CsrFile` MRET/SRET request or an architectural commit.
4. The precise exception transports the original instruction PC and the
   zero-extended MRET/SRET encoding as `tval`; the machine handler observes
   `mcause=2`, matching `mepc`/`mtval`, advances `mepc`, and returns.
5. In the lane1 SRET case, the older lane0 ADDI retires exactly once before
   the exception while the lane1 SRET has no architectural side effect.
6. Legal MRET and SRET controls must each produce exactly one `CsrFile`
   request, one synthetic architectural commit, a correct return target, and
   a drained backend. Globally disabling xRET is not a valid implementation.
7. Classifier logic is combinational and owns no transaction. Existing FIFO,
   drain, stall, redirect, reset and recovery owners remain unchanged.
8. This architecture closure does not qualify synthesis, STA, Power or PPA
   promotion. `ppa=UNQUALIFIED` and `promotion_eligible=false` are mandatory.
9. Canonical replay must produce byte-stable evidence for the same RTL and
   oracle cohort. Only the exact per-run temporary compilation root may be
   replaced by `<XRET_TRANSIENT_TMP>` before hashing; all source paths,
   compiler diagnostics, test markers and return codes remain intact.

## Required evidence

- One exact seven-case classifier matrix: legal MRET@M, SRET@S+TSR0 and
  SRET@M+TSR1; illegal MRET@S/U, SRET@U and SRET@S+TSR1.
- Four full-core program markers: legal MRET, legal SRET, illegal head0 MRET
  from S mode, and illegal lane1 SRET from U mode.
- Both illegal programs must contain one known-legal MRET request/commit hit
  through the same observer interfaces, making the zero-side-effect oracles
  non-vacuous.
- Eight compile-success RTL verification variants must cover the three
  legality predicates, an over-gated legal MRET path, head0/lane1 owner
  exclusion, precise trap PC and precise trap tval. Every variant must compile
  and be dynamically rejected by its directed oracle.
- Two compile-success verification configurations must retarget the illegal
  CSR-request and commit zero oracles to the known setup MRET and be rejected.
- A fresh exact module aggregate derived from the current `TESTS` inventory.
- Full RTL and relevant source SHA-256 bindings under one current design ID.
- Two consecutive canonical runs with identical module, RTL-variant,
  oracle-probe, raw-log and result SHA-256 values.

## Canonical command

`make -C npc/rv64 check-xret-current-mode`
