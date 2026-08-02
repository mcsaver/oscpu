# V13Q reviewer result

## Pre-implementation cycle-oracle review

- reviewer: `v13q_cycle_oracle_review`
- isolated contract:
  `subagent-contracts/v13q-b-response-cycle-oracle-review.json`
- contract SHA-256:
  `57077b66b453032e5518633a002c57242c0a82b3c6f3a3a44d96f0511b5f3349`
- evidence level: frozen-material reasoning only; no repository commands
- verdict at dispatch: `GAP`, used as the test-oracle input rather than a
  claim that RTL had passed

The review defined `C_B` from an actual `BVALID && BREADY` handshake, `C_F`
from the target response fire and commit as a later registered event.  It
required target-qualified exactly-once counters, VA distinct from PA, poisoned
or withdrawn B input after acceptance, real WB-slot occupancy, collector zero,
C0 barrier and a quiet window.  It also warned that one dual-WB wave proves
only `k>=1`, not arbitrary fallback duration.

The implemented V13Q test consumes those requirements.  Multi-cycle stall,
asymmetric SQ-terminal credit and retirement delay remain declared GAPs rather
than being inferred from the one-cycle trace.

## Final repository/evidence review

### Review v1

- reviewer: `v13q_final_review`
- contract SHA-256:
  `93171e7918cd9fe62c160f5189fdf8872a554a42bb7c42de07a6daf77229def7`
- actual bridge/backend/SQ/ROB cycle chain: bounded PASS
- production RTL correctness counterexample: none found
- actionable evidence counterexample: the mutation driver did not remove an
  earlier `result.json` before reconstruction, so an interrupted rerun could
  leave a stale per-variant PASS.

The stale-receipt issue is fixed by pre-run deletion, atomic per-variant
installation and a separate suite receipt.  A new focused runner now removes
old positive artifacts and binds a pre/post-stable critical source cohort.

Review v1 also reported that focused and mutation runtime logs were absent.
That finding was caused by the reviewer's ignored-file discovery path: the
logs are present at their explicit task-run paths.  The positive log digest is
`ca173e37f6da81f871b25587577276ab84a048de3b2e75a58561a77e09a7c4a0`;
all three mutation logs were regenerated after the driver correction.

### Review v2

- reviewer: `v13q_final_review_v2`
- contract SHA-256:
  `ba39c5777ce47866381d8908d7ecc4a110405aaa7f693975bad5d2ee8ad54c5f`
- corrected positive receipt/source binding: PASS
- corrected per-mutation and suite fail-closed receipts: PASS
- explicit positive/mutation logs and digests: PASS
- `OooDualMemAxiArbiter` external B -> selected child B provenance: PASS

The arbiter sends external BVALID/BRESP only to the owner-selected lane,
returns BREADY only from that lane and releases the owner only after B fire.
The wrapper connects lane0 B to `u_bridge0.lsu_axi_b*`; therefore the isolated
V13Q lane0 `C_B` check observes the same acceptance edge as the child bridge.

No production RTL correctness counterexample or further scope extension was
found.  Non-blocking test bounds remain: isolated lane0, one fallback stall
cycle, global counters valid only under the isolated scenario, and a bounded
three-cycle quiet window.

### Same-filesystem receipt delta

- self-contained contract SHA-256:
  `330a9874f12a398bc4eef04ba3b1e756ea05260afaf77de8cdc4c9d4f53a2b41`
- result: PASS

After review v2 noted that a default `/tmp` could make `mv` cross-filesystem,
both runners were changed to stage inside their final evidence filesystem.
`bash -n`, the positive test and all three mutations were rerun; cleanup left
no hidden staging directory or focused VVP.  The reviewer confirmed that this
closes the receipt-install GAP without changing any RTL/PPA conclusion.

Final independent verdict: `PASS_WITH_DECLARED_TEST_MATRIX_GAPS`.
