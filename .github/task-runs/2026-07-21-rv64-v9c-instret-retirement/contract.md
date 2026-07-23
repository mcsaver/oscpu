# RV64 V9C / INSTRET-G1 retirement-count contract

## Local hardware scope

This task applies only to the authorized local RV64 Verilog/SystemVerilog dual-issue OoO processor workspace,
its program-level simulation, architecture specifications, checker scripts, and generated evidence.  Terms such as
pipeline flush, transaction cancellation, exception recovery, counterexample, and compile-success RTL mutation have
only their local processor RTL and verification meanings.  The work uses no network, remote host, account,
credential, third-party service, or unowned system.

## Requirement

Close architecture-debt item `INSTRET-G1` without changing the production retirement datapath unless verification
finds a real defect.  The full-core program test must prove that the unique architectural `minstret` increment source
is the final visible commit bus after control-pseudo-commit priority:

1. every final valid commit lane with `exception=0` contributes exactly one;
2. every final valid commit lane with `exception=1` contributes zero;
3. each actually executed MRET, SRET, and SFENCE.VMA control pseudo-commit contributes exactly one, suppresses lane 1,
   and appears once on the final commit bus;
4. `NpcCoreTop` passes this same final count to `CsrFile`, with no hidden pre-mux or core-completion count source;
5. the observed `minstret` state equals the cycle-by-cycle sum of final non-exception commit lanes.

FENCE.I is not added to this program merely to enlarge scope: its retirement rule is the same final-bus invariant,
while the current `INSTRET-G1` closure requirement names exception, return, and SFENCE control events already present
in the canonical Sv39 program.  WFI remains owned by the separate `WFI-G1` architecture decision.

## Interface and state contract

- Source of truth: `OooCommitOutputMux.retire_count_o` computed from final `commit{0,1}_{valid,exception}_o`.
- Topology: core/ROB commits and control pseudo-commit -> final commit mux -> `retire_count_o` ->
  `NpcCoreTop.instret_inc_i` -> `CsrFile.csr_minstret_q`.
- Timing: the final count is combinational for a cycle and is accumulated by `CsrFile` on the following active edge.
- Range: `retire_count_o` is 0, 1, or 2; encoding `2'b11` is invalid.
- Control event: lane 0 valid, lane 0 non-exceptional, lane 1 invalid, count exactly 1.
- Precise synchronous exception event: the exceptional lane contributes zero and lane 1 is not allowed to retire
  behind that exception.
- Counter state: reset clears `minstret`; an explicit CSR write has its existing priority; `mcountinhibit.IR` may
  suppress automatic increment.  The selected program leaves the inhibit bit clear.

## Verification and evidence gates

- Positive full-core program simulation with explicit event counts and exact log marker.
- Existing focused `OooCommitOutputMux`, `OooAluCoreSlice`, and `CsrFile` simulations remain passing.
- At least three production-source variants, each compiled and elaborated with the current full-core source set:
  exception filtering removed, final control-source count replaced by a pre-mux source, and `NpcCoreTop` counter
  input rewired to the core count.  Each variant must compile successfully and be rejected by a named program-level
  oracle.
- A fail-closed evidence builder binds source SHA-256 values, canonical command, positive log, variant logs, event
  coverage, and current design identity.
- The architecture-stable checker must independently validate `INSTRET-G1` evidence semantics before the ledger may
  mark the item CLOSED.

## Completion and declaration boundary

The item may become CLOSED only after all gates above pass on one current design identity, the module aggregate and
architecture/arch-stable workflows remain consistent, and an independent workspace-file review finds no P0/P1
issue.  This is architecture closure, not formal PPA: `ppa=UNQUALIFIED` and `promotion_eligible=false` remain until
all remaining full-core P0/P1 debt and freeze inputs close.
