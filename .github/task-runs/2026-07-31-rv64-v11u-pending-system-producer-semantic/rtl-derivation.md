# RTL derivation

## Requirement and protocol

`OooPendingSystemSequencer` separates serialized-instruction metadata from the full ProducerId lease. Capture records the pending serialized kind and PC without creating a ROB owner. A CSR dispatch fire records `dispatch_producer_id_i`; ordinary pending metadata maintenance must not invalidate that raw lease.

`OooCsrAccessRequestMux` seals queue-head fallback whenever a raw or logical pending-system CSR claim exists. A pending-system CSR commit is eligible only when the committed full ProducerId and PC match the held transaction.

`OooIntBackend` includes the pending-system raw lease in its global live-mask union so the allocator cannot reuse a live `{generation, rob_idx}`.

Attempt-3 must additionally observe the production path through `tb_ooo_priv_system`: ROB lane-0 allocation births the pending CSR lease, exact retirement kills it, and `core_local_flush_w` resets it. The same full ProducerId must remain visible through `OooControlPlane -> OooCoreTopGlue -> OooExecuteBackend -> OooAluCoreSlice -> OooAluDecodeBackend -> OooIntBackend`. A separate focused backend branch must exercise the raw lease fence at `PRODUCER_GEN_W=1` and `PRODUCER_GEN_W=4` without entering unrelated legacy V8P scenarios.

## FSM and cycle edges

- Capture edge: pending kind/PC can become resident, but `producer_valid_q` stays clear.
- Dispatch edge: `dispatch_fire_i && valid_q && kind_q == SERIAL_KIND_CSR && !dispatched_q && !producer_valid_q && !clear_i` births the lease.
- Hold cycles: metadata clear, clear-dispatched cleanup, refresh, and recapture leave the raw lease unchanged.
- Death edge: exact pending CSR retirement or the same core-local flush clears the lease.
- Commit edge: full ProducerId equality and PC equality authorize the pending-system CSR request.
- Production integration sequence: lane-1 CSR capture precedes lane-0 redispatch; the dispatch edge births ProducerId `P`, cycle C1 observes the raw lease and backend live-mask bit for `P`, the exact commit edge Cn is the only normal death authority, and Cn+1 observes both clear.
- Flush sequence: after the real dispatch edge and before exact commit, a one-cycle `core_local_flush_w` pulse clears the raw lease and backend live-mask bit on the following observation edge.
- The focused monitors are bounded and terminate through explicit PASS markers; they do not add or alter production state transitions.

## Invariants and independent sensitivity

- Raw lease output is independent of mutable serialized metadata.
- Non-CSR serialized kinds cannot birth a ProducerId.
- Generation bits are retained at birth and compared at commit.
- An ordinary clear cannot terminate an already-live lease.
- The global live mask contains the pending-system lease.
- Each production wrapper carries the same valid bit and full ProducerId; dropping any one link must be rejected by a compile-success mutation.
- Exact commit and core-local flush are independently sensitive death paths.
- Generation widths 1 and 4 both block allocation reuse while the lease is live.
- Existing RTL assertions remain enabled for the parent-path profiles and are neither weakened nor bypassed.

Attempt-2 exercises those invariants through nine positive profiles, three assertion-negative profiles, and ten compile-success RTL mutations producing twelve mutation profiles. Every negative profile must compile successfully and terminate through its declared testbench or assertion marker; compile failure is not accepted as semantic rejection.

The independent review classifies attempt-2 as `GAP`, not `PASS`, because its separate leaf testbenches do not bind the production parent path. Attempt-3 therefore adds focused integration, flush, width-1/4 backend, and per-link parent mutations. This is an evidence extension only; it does not authorize a production RTL semantic change.

## Datapath and topology conclusion

The current `kind_q` consolidation changes the serialized-kind representation but does not alter the ProducerId lease lifecycle. Source inspection and attempt-2 show one elaborated `OooPendingSystemSequencer` product instance and no proven production RTL defect, while leaving the production parent binding unproved. Attempt-3 changes only macro-gated testbench monitors, the evidence runner, and compile-success mutations; production datapath and topology remain unchanged. The unit may be classified `PASS` only after these parent-path profiles pass, all mutations are independently rejected, generated images are cleaned, and a fresh reviewer accepts the evidence.

## Attempt-5 closure

Attempt-3 remains the original failed instrumentation run. Attempt-4 proved the expanded matrix, but its focused monitors temporarily changed the two shared testbench files and therefore made older current-source evidence stale. Attempt-5 restores both shared testbenches byte-for-byte and generates the V11U monitors as per-run overlays selected by a generated Make include. The overlays, Make include, negative RTL and compile images are hashed before being removed.

Attempt-5 closes the declared local lifecycle with 37/37 profiles, 18 compile-success RTL mutations executed as 21 mutation profiles, four ordinary regressions and 66 validated retirement records. The eight parent/wrapper mutations run with `OOO_ASSERT`; the remaining ten mutations run in release mode. The immutable attempt-5 field `compile_success_release_mutation_rejection` is therefore a legacy label for mixed-mode compile-success mutation rejection, not a claim that all 18 mutations ran in release mode.

The independent v2 reviewer accepted the scoped birth/hold/death/live-mask contract and found no production RTL counterexample. It retained two boundaries: the flush profile forces the production `core_local_flush` net rather than proving the upstream natural flush cause, and no full-system, synthesis, STA or PPA result is implied. Production RTL remains unchanged.
