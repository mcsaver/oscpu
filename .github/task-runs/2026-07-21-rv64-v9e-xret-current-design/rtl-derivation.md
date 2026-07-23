# XRET-G1 RTL derivation and evidence boundary

## Owner and dataflow

`OooFetchHeadClassifyGate` is the sole current-mode legality source. It keeps
the raw MRET/SRET facts while adding `priv_system_illegal` to the packed
architectural-trap fact. `OooFetchHeadPairGate` qualifies the head facts. For
head0, `OooPendingDispatchArbiter` gives `dispatch0_arch_trap` priority over
`pending_system_capture_head0`; for lane1, `OooPendingLane1CaptureGate`
requires `!arch_trap_raw` for system capture and emits the instruction PC,
illegal-instruction cause and instruction-value `tval` to the trap owner.

`OooPendingTrapExitSequencer` holds the precise exception until the backend is
drained. `OooCsrTrapRequestMux` then supplies exact PC/cause/tval to
`CsrFile`. Legal xRET instead uses `pending_system_mret`, with the instruction
funct12 distinguishing SRET from MRET. `CsrFile` consumes only already-legal
requests and remains the architectural privilege/status state owner; it does
not duplicate current-mode legality decode.

## Protocol and state

- Handshake: classifier facts are same-cycle combinational values. Pending
  owners capture only under existing FIFO/head fire conditions.
- Stall/drain: legal xRET and architectural exceptions retain the existing
  full-drain serialization mechanism. This slice adds no holder or FSM state.
- Exception order: head0 illegal MRET suppresses younger work. For lane1
  illegal SRET, the older lane0 instruction may retire, while the lane1
  instruction becomes the precise exception owner and cannot commit.
- Recovery: handler return uses the existing MRET path after `mepc` is
  advanced. No branch, memory or AXI recovery contract changes.
- Source of truth: current privilege mode and TSR come from `CsrFile`; the
  classifier is the only legality decision and downstream blocks consume it.

## Verification derivation

The focused matrix covers every current-mode/TSR decision and preserves legal
positive controls. The full-core programs prove both head positions, exact
exception metadata, no illegal CSR request, no illegal commit, handler return,
and the older lane0 retirement rule. Each illegal program also observes its
known setup MRET through the same CSR-request and two-lane commit interfaces;
verification-only sensitivity configurations retarget the zero oracles to
that known transaction and must fail.

Eight compile-success RTL verification variants independently remove or
over-gate classifier predicates, remove head0/lane1 architectural-exception
priority, and corrupt precise exception PC/tval. A fresh module aggregate
protects unrelated local behavior. Module and variant compilation use isolated
temporary roots; before evidence hashing, only that exact root is replaced by
`<XRET_TRANSIENT_TMP>`. No production RTL change or PPA inference is made.
