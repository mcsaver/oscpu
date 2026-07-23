# FDG-G1 RTL derivation and evidence boundary

## Owner and dataflow

`OooFetchHeadClassifyGate` derives the architectural-trap fact from decode,
FP legality, current RISC-V privilege state and fetch-fault facts. The head-pair
gate qualifies that fact with the valid head. `OooFrontendDispatchGate` is the
single owner of ordinary backend admission and consumes the qualified fact as
an exclusion term. `OooFrontendBackendDispatchMux` directly ORs ordinary
admission into both backend lane-valid equations, so that mux is the decisive
sink boundary. `NpcCoreTop.v` does not own this predicate and is not an FDG-G1
owner path.

## Protocol and state

- Handshake: admission is a same-cycle valid predicate; downstream READY only
  determines fire.
- Stall: FIFO/head state remains with the existing frontend owners. The gate
  has no state.
- Trap and recovery: an architectural trap takes the pending precise-trap owner
  path. Ordinary backend presentation is mutually exclusive with that path.
- Exception order: the head0 trap precedes and suppresses the younger lane;
  the invalid encoding cannot allocate, execute or commit as a backend uop.
- Memory order: no memory holder, SQ/LQ/MIQ entry or AXI transaction changes.
- Source of truth: legality is not re-decoded in the dispatch gate; the gate
  consumes the packed architectural-trap fact.

## Verification derivation

The focused matrix detects missing invalid-FP exclusion and detects the false
repair in which all ordinary admission is disabled. The full-core program adds
the real final mux, pending-trap owner, exact capture PC/tval, CSR
`mcause/mepc/mtval`, `mret` return and commit boundary. Its commit observer sees
one known older ADDI through the same two-lane valid/PC transaction interface;
a verification-only compile configuration repoints the zero oracle to that
transaction and must be rejected.

Six compile-success RTL verification variants independently cut the
ordinary-admission exclusion, lane1 dual-dispatch exclusion, legal positive
path, final backend sink, CSR trap PC and CSR trap tval. The fresh module
aggregate protects unrelated local behavior. Module and variant compilation
use isolated temporary build roots; before evidence hashing, only that exact
per-run root is replaced by `<FDG_TRANSIENT_TMP>`. This preserves source paths,
compiler diagnostics, test markers and return codes while making same-input
canonical replay byte-stable. No PPA inference is permitted.
