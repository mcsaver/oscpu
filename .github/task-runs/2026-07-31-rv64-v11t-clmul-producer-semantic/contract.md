# V11T CLMUL producer lifecycle verification contract

- RTL object: `OooIntBackend.u_clmul_unit` and `OooClmulUnit.producer_id_q`.
- Configuration: `PRODUCER_GEN_W=1` and `PRODUCER_GEN_W=4`, assertion and release baselines.
- Transaction under test: issue lane 0 CLMUL request fire, full ProducerId capture, RUN/RESP residency, exact-open completion authorization, WB identity, ordered retirement, terminal release, and full-flush death.
- Independent identity: the testbench derives `{generation=1, rob_index=2}` from its allocation schedule; it must not derive the expected identity from DUT holder state.
- Negative RTL variants: request birth, identity capture, live-mask index, completion query, exact-open authorization, response handshake, WB identity, and flush death.
- Production RTL: read-only for this task. Any required production change is a new task and requires a fresh interface/transaction freeze.
- Evidence: focused profile matrix, compile-success mutation rejection, four regressions, pre/post source manifest, and independent review.
- Success: every baseline and mutation profile passes its stated oracle, all regressions pass, source pre/post manifests match, and review finds no false-green path.
- Scope boundary: no system replay, synthesis, STA, power, PPA, architecture-ledger promotion, or A3 status rewrite.

