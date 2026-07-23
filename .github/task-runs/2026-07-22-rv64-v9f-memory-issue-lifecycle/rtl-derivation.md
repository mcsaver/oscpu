# RV64 V9F RTL derivation and observability plan

This is a current-design evidence slice.  The derivation records the existing
synthesizable topology before any testbench/evidence change.  No production RTL
change is authorized unless the baseline focused run violates the frozen
contract.

## Stage 1 — requirements

- Rebind `MEM-ISSUE-G1` and `MIQ-FLUSH-G1` to the current RTL design-id.
- Exercise the current two-stage memory pair path rather than the obsolete
  direct lane1 look-through assumption.
- Prove both directions of each lifecycle equivalence with compile-success RTL
  verification variants.
- Preserve all processor ports, state elements, throughput policy, reset
  behavior, and memory ordering.
- Out of scope: new execution capability, new memory-port topology, PPA
  promotion, official/AM/DiffTest aggregation, or physical timing claims.

## Stage 2a — protocol rules

1. IQ pair capture fires atomically and only creates reservation state.
2. Single-port terminal1 consume is gated by edge-old `!mem_issue_res_valid_q`.
3. A normal reservation terminal consumes only through its exact request fire
   (or an explicitly enumerated local terminal such as exception/forward).
4. A global bank0 request fire from terminal0 or another producer cannot
   consume terminal1; MIQ payload selection follows the actual one-hot request
   grant, not terminal validity.
5. `mem_req_valid_o && mem_req_ready_i` and `miq_push_valid_w` are equivalent
   for the bank0 request path.
6. MIQ response consume requires an exact owner match at the FIFO head.
7. On global pipeline flush, MIQ compaction scans old logical FIFO order after
   excluding a same-cycle fired head and retains only remaining DRAIN entries.

## Stage 2b — state model

There is no new FSM.  The existing state transition sequence is:

| State | Meaning | Exit |
| --- | --- | --- |
| `IQ_PAIR` | two current memory uops await atomic capture | capture both reservation terminals |
| `TERM0_TERM1` | both terminals resident | terminal0 exact local/request terminal |
| `TERM1_ONLY` | terminal1 remains after terminal0 completion | terminal1 exact request/local terminal |
| `MIQ_RESIDENT` | accepted request has an exact MIQ owner | exact response head pop |
| `DONE` | no reservation or MIQ owner remains | none |

The MIQ itself remains a ring FIFO.  Flush performs a stable compaction of the
set `DRAIN entries in (Q_old minus exact fired head)`.

## Stage 2c — invariants

- **MEM-L1 capture**: a current memory pair captures both reservation terminals
  or neither; IQ dequeue has no direct request side effect.
- **MEM-L2 no look-through**: in single-port mode, edge-old terminal0 valid and
  terminal1 valid imply no terminal1 consume or request on that edge.
- **MEM-L3 launch equivalence**: for a normal terminal1 launch,
  `mem_issue1_res_consume_fire_w == issue1_mem_request_fire_w ==
  push_issue1_w == miq_push_valid_w`, with the same ROB/owner tuple.
- **MEM-L4 hold**: if launch eligibility is false, terminal1 state and its
  identity remain resident and no request/MIQ owner appears.
- **MEM-L5 owner qualification**: when terminal0 owns a request fire while
  terminal1 is resident, terminal1 consume is zero and the MIQ birth contains
  terminal0 ROB/ProducerId-derived identity.
- **MIQ-L1 fired-head subtraction**: flush result count equals old DRAIN count
  minus one exactly when the fired head is DRAIN.
- **MIQ-L2 no over-drop**: an unconsumed DRAIN remains valid and keeps its exact
  payload/owner tuple across flush.
- **MIQ-L3 no duplicate**: a consumed DRAIN cannot reappear after flush.
- **MIQ-L4 no-fire preservation**: a valid DRAIN head with no pop fire remains
  in the keep-set; head validity cannot substitute for the accepted response.

Every focused invariant has a positive observation and a named RTL verification
variant that violates only the relevant equation.  The testbench checks are
independent lifecycle equations, not a textual restatement of the mutated RTL.

## Stage 2d — datapath constraints

- Existing reservation registers and MIQ arrays are unchanged.
- Existing one-hot request grants remain the only bridge payload mux controls.
- No new mux, register, combinational feedback path, or synthesis-visible
  critical path is added by this slice.
- Verification-only work is confined to `.sv` testbench observability and
  repository-local Python evidence parsing/validation.

## Stage 2e — current RTL topology review

1. Module boundaries: `OooIntIssueQueue` -> `OooIntBackend` reservation
   terminals -> request grant mux -> `OooMemInflightQueue`.
2. State registers: `mem_issue_res_*`, `mem_issue1_res_*`, and MIQ
   head/tail/count/entry arrays; reset values and update blocks remain intact.
3. Combination blocks: memory eligibility/order, terminal consume equations,
   one-hot request grants, and MIQ flush keep-set.
4. FSM: no encoded FSM is introduced; the state table above describes the
   distributed lifecycle.
5. Pipeline flow: IQ capture and terminal launch are separate registered
   stages; terminal1 cannot look through terminal0 in the single-port mode.
6. Priority: backend reset/restore/flush before launch; MIQ reset, then flush
   compaction with fired-head subtraction, then normal push/pop/kill.
7. Resources: one external request port in the focused configuration; no new
   resource sharing or replication.
8. Critical path: unchanged request eligibility/grant path; testbench and
   evidence code are nonsynthesizable.
9. Function boundary: no RTL function or synthesizable block is added.

Topology self-review: the existing structure is internally consistent with the
frozen contract.  The obsolete same-edge lane1 assumption belongs to historical
evidence, not to current RTL.  Therefore the implementation action is evidence
and observability only unless the baseline proves otherwise.

## Stage 3 — planned implementation

- Add a dedicated focused testbench compile configuration that calls the
  existing lane0-exception/lane1-memory tasks with current two-stage
  expectations and emits exact event markers.
- Strengthen the standalone MIQ test marker to report consumed-DRAIN and
  stalled-head/unconsumed-DRAIN counts explicitly.
- Add a deterministic local RTL verification-variant runner, result builder,
  unit tests, and debt-specific arch-stable semantic validation.
- Require eleven compile-success variants, including competing-owner consume,
  MIQ identity selection and valid-without-pop DRAIN subtraction cuts.  Bind
  the exact-owner pop predicate and owner-mismatch assertion statically.
- Keep production `.v` files byte-identical in the baseline implementation.
