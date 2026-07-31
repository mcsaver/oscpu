# V11T CLMUL product-path derivation

## Requirement

Prove the current product instance `OooIntBackend.u_clmul_unit` preserves one full ProducerId from accepted request through writeback and ordered retirement. This task adds verification only; it does not change `OooIntBackend.v` or `OooClmulUnit.v`.

## Cycle protocol

1. The stimulus allocates a nonzero-generation, nonzero-index ROB identity and issues a CLMUL-class instruction through integer lane 0.
2. On request fire, `u_clmul_unit` enters `STATE_RUN` and captures the full ProducerId.
3. During every RUN cycle and the RESP terminal edge, owner valid, owner identity, CLMUL live-mask bit, external live-mask bit, and aggregate live-mask bit remain aligned.
4. Raw response routing may assert ready, but completion side effects require an exact full-ProducerId ROB-open match and the fixed claim chain.
5. A same-index, other-generation response probe must be rejected without WB or claim.
6. On the accepted response edge, the old lease remains observable; on the following cycle the holder, identity, and live-mask bit are empty.
7. The matching ROB entry retires exactly once with the independent reference result.
8. A full flush during RUN preserves the old lease on the flush edge and removes it, without WB, on the following cycle.

## Existing state machine

The verification observes the existing `IDLE -> RUN -> RESP -> IDLE` machine. It neither adds a state nor overrides sequential state. `flush_i` and strict-younger kill remain higher-priority death events in the production unit.

## Invariants and negative sensitivity

- birth captures the full `{generation, rob_index}` identity;
- residency never truncates or substitutes either identity field;
- the live-mask bit is indexed by the same full identity;
- wrong-generation exact-open probes cannot authorize a WB side effect;
- accepted response identity and data reach WB and the matching ROB entry;
- response acceptance and full flush each release the holder exactly once;
- every injected RTL variant must compile successfully and fail at its intended lifecycle oracle stage.

## Datapath and observation topology

The expected PID is owned by the testbench allocation schedule. Product-path observations cover `iq_issue0_producer_id_w`, `u_clmul_unit.producer_id_q`, CLMUL owner/live masks, completion query/authorization/claim, WB0/WB1 identity and data, and commit identity/data. Functional data is computed by the testbench `ref_clmul` function for CLMUL and CLMULH.

## Explicit exclusions

CLMUL algorithm changes, production RTL edits, floating-point producers, pending-system producer, full-system replay, synthesis/STA/power, PPA promotion, and architecture-stable promotion are outside this verification task.

