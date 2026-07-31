# RTL derivation

## Requirement and protocol

`OooPendingSystemSequencer` separates serialized-instruction metadata from the full ProducerId lease. Capture records the pending serialized kind and PC without creating a ROB owner. A CSR dispatch fire records `dispatch_producer_id_i`; ordinary pending metadata maintenance must not invalidate that raw lease.

`OooCsrAccessRequestMux` seals queue-head fallback whenever a raw or logical pending-system CSR claim exists. A pending-system CSR commit is eligible only when the committed full ProducerId and PC match the held transaction.

`OooIntBackend` includes the pending-system raw lease in its global live-mask union so the allocator cannot reuse a live `{generation, rob_idx}`.

## FSM and cycle edges

- Capture edge: pending kind/PC can become resident, but `producer_valid_q` stays clear.
- Dispatch edge: `dispatch_fire_i && valid_q && kind_q == SERIAL_KIND_CSR && !dispatched_q && !producer_valid_q && !clear_i` births the lease.
- Hold cycles: metadata clear, clear-dispatched cleanup, refresh, and recapture leave the raw lease unchanged.
- Death edge: exact pending CSR retirement or the same core-local flush clears the lease.
- Commit edge: full ProducerId equality and PC equality authorize the pending-system CSR request.

## Invariants and independent sensitivity

- Raw lease output is independent of mutable serialized metadata.
- Non-CSR serialized kinds cannot birth a ProducerId.
- Generation bits are retained at birth and compared at commit.
- An ordinary clear cannot terminate an already-live lease.
- The global live mask contains the pending-system lease.

Attempt-2 exercises those invariants through nine positive profiles, three assertion-negative profiles, and ten compile-success RTL mutations producing twelve mutation profiles. Every negative profile must compile successfully and terminate through its declared testbench or assertion marker; compile failure is not accepted as semantic rejection.

## Datapath and topology conclusion

The current `kind_q` consolidation changes the serialized-kind representation but does not alter the ProducerId lease lifecycle. Source inspection and attempt-2 show one elaborated `OooPendingSystemSequencer` product instance and no proven production RTL defect. The closed scope is the `pending-system-producer` unit only.

