# V8Y OOO-4 speculation/recovery contract

## Local RV64 RTL scope

This task covers only the authorized local RV64 Verilog/SystemVerilog core,
testbenches, EDA simulation tools and generated evidence.  In this document,
recovery means branch-mispredict pipeline recovery, squash means invalidating
strictly younger micro-operations, and mutation means a compile-success RTL
verification variant used to test an oracle.  No external system is in scope.

## Required behavior

1. Two independently ready branches may be simultaneously exact-open in the
   ROB and resident in the integer IQ.  The lane0 control terminal selects the
   older branch by circular program age.
2. If older branch A is mispredicted, its registered full-ProducerId resolve
   packet is the sole recovery boundary.  Younger branch B must not issue,
   resolve, update the branch-predictor source interface, complete or retire.
3. The survivor prefix remains live: an older completed ALU D and boundary A
   each complete and retire exactly once.  Only the strictly younger suffix is
   removed.
4. The same ledger must pass for linear D/A/B ROB indices 0/1/2 and wrapped
   indices 14/15/0.
5. A real already-fired AXI read transaction drains by exact owner identity;
   a killed registered station owner terminates before issuing a new AXI
   request.  Neither produces WB, retirement or cache fill.
6. After bounded quiet time, ROB, IQ, resolve/EX stages, memory owner tracker,
   terminal collector and complete ProducerId holder census contain no ghost.

## Evidence and claim boundary

- Both release and `OOO_ASSERT` focused simulations must independently pass.
- Nine compile-success RTL verification mutations must compile, activate and
  be rejected by metric-related dynamic witnesses.
- A single suite run binds focused logs, mutations, adjacent regressions,
  exact source manifests and the complete production RTL design digest.
- The only promotable result is OOO-4.  DI-1, DI-2 and overall architecture
  remain RED; PPA remains unqualified and `promotion_eligible=false`.

