# OOO-3 final review v4.1

## Verdict

- `GAP (P1 evidence false-GREEN sensitivity)`
- RTL request/hold/apply protocol review: PASS.
- OOO-3 promotion at the reviewed checkpoint: blocked until evidence sensitivity is repaired.
- Overall architecture: RED.
- PPA: UNQUALIFIED.

## Counterexample

Adding `branch_spec_restore_i` to `OooCoreSliceControlGate.core_local_flush_o` would let a raw checkpoint request
bypass accepted apply, clear ROB/backend state, and flush both memory request gates while an irrevocable physical
write still owned its edge-old ROB/SQ lifecycle.  The reviewed 41-source/54-provenance chain did not read
`OooCoreSliceControlGate.v`; its dynamic parent mutations only replaced text in `OooIntBackend.v`.  The faulty
ControlGate therefore could compile while the prior OOO-3 oracle remained GREEN.

Whole-`vsrc` `design_id` bound final RTL identity but did not prove oracle sensitivity, and the pre/post source
manifest did not establish same-run stability for ControlGate, MIQ or OwnerTracker.

## Reviewed RTL result

- raw request closes new dispatch, issue, reservation, MIQ push and memory request admission;
- a bank0 non-probe physical write acquires a full-`ProducerId` lease;
- B/formal-WB, matching lane0 retirement and exact SQ release remain live during hold;
- lane1 retirement is blocked while restore is pending;
- accepted apply waits for the lease, SQ active-write state and DRAIN state to become empty;
- accepted apply broadcasts through Decode/CoreSlice/Execute/CoreTop and `OooControlFlushSequencer` to both memory
  request gates;
- delayed OKAY B, raw request with error B on the same edge, and AMO write have exact request/response/commit/apply
  counts in the focused backend test.

## Required closure

1. Add ControlGate, MIQ and OwnerTracker to canonical source/provenance binding.
2. Add a fail-closed ControlGate source check for raw-restore/local-flush separation.
3. Add a compile-success ControlGate bypass mutation.
4. Reject that mutation with an integration scenario containing ControlGate and both memory request gates.
5. Refresh same-design evidence and keep OOO-3, overall and PPA claims distinct.

## Contract binding

- v4 contract SHA-256: `63b4d743cdfb23ce5351146a63ddefc450a5aafa76640f5fc8336ad9171b4c74`
- v4.1 contract SHA-256: `74b89059230c6856789c7fd0ad35ec43f056031ecf60672d05c9c03ee7cbc6b2`
- Review was read-only.  Shell ownership was explicitly returned to the main agent.
