# RV64 V9F memory issue lifecycle contract

## Scope and design state

- Work object: the local RV64 Verilog/SystemVerilog dual-issue OoO processor,
  its module testbenches, and repository-local evidence tooling.
- Architecture debts: `MEM-ISSUE-G1` (P0) and `MIQ-FLUSH-G1` (P1).
- Parent design-id:
  `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`.
- Design state: architecture-closure evidence slice.  It is not a PPA
  candidate, `promotion_eligible=false`, and any synthesis/STA observation is
  diagnostic only.
- Production RTL starts read-only.  Testbench observability and current-design
  evidence may be added.  A production RTL edit is allowed only after a
  current-design directed case proves a concrete contract failure; such an
  edit must first amend this contract and the RTL derivation.

## Completion definition

The slice is complete only when all of the following are bound to one current
design-id:

1. The memory pair is atomically captured from the integer issue queue into
   `mem_issue_res_*` and `mem_issue1_res_*`; capture does not launch an external
   memory transaction.
2. In the single-memory-port configuration, an edge-old valid terminal0 blocks
   terminal1 look-through.  A local exception in terminal0 may complete on the
   first edge, while terminal1 remains resident and launches on a later edge.
3. For a normal terminal launch, reservation-terminal consume, bridge request
   handshake, request mux ownership, and MIQ owner birth are cycle-exact and
   carry the same ROB/ProducerId-derived identity.
4. A bank0 request owned by terminal0 must not consume terminal1 or create an
   MIQ entry with terminal1 identity.  The held terminal1 launches only on its
   own selected request fire.
5. A same-cycle global pipeline flush plus exact DRAIN response consumes the
   DRAIN head before the MIQ keep-set is computed.  An unconsumed DRAIN remains
   present across flush.
6. MIQ subtraction is both necessary and sufficient: a fired DRAIN head is
   removed, while a valid DRAIN head with no pop fire remains present.  The
   wrapped mixed-entry survivor multiset retains exact identity and FIFO order.
7. The current module inventory aggregate passes, the debt-specific semantic
   validator accepts both closures, and the arch-stable audit is rerun without
   claiming PPA qualification.

Maximum verification boundary: focused Icarus module runs, compile-success RTL
verification variants, current module aggregate, architecture hard gates, and
the arch-stable audit.  Full official/AM/DiffTest execution remains owned by
`F0-G1` and is not silently inferred from this slice.

## Current owner and state chain

| Phase | State/source of truth | Cycle-exact event | Required consequence |
| --- | --- | --- | --- |
| IQ admission | `iq_issue0_*`, `issue1_*`, exact ProducerId current checks | pair capture | both memory reservation terminals capture together or neither captures |
| terminal0 local completion | `mem_issue_res_valid_q` and its captured tuple | `mem_issue_res_consume_fire_w` with local exception | exactly one local terminal; no bridge request or MIQ birth |
| terminal1 hold | `mem_issue1_res_valid_q` | terminal0 is edge-old valid in single-port mode | no terminal1 consume, request handshake, or MIQ birth |
| terminal1 launch | terminal1 captured tuple plus request slot/order predicates | `issue1_mem_request_fire_w` | terminal1 consume, bridge handshake, request mux owner, and MIQ push agree |
| competing terminal0 launch | terminal0 request grant plus both terminals resident | terminal0 request fire | terminal0 MIQ identity is born; terminal1 remains bit-exact and unconsumed |
| request residency | `OooMemInflightQueue` exact owner tuple | `miq_push_valid_w` | one MIQ owner is born for the accepted bridge request |
| response completion | MIQ head exact owner match | `pop_fire_w` | exactly the matched head is consumed |
| global pipeline flush | old MIQ entries plus same-cycle `pop_fire_w` | `flush_i` | compute `filter_DRAIN(Q_old - fired_head)` in FIFO order |

The old 2026-07-12 same-cycle lane0-exception/lane1-request assumption is not a
current contract.  The current single-port topology deliberately forbids
terminal1 look-through behind edge-old terminal0.

## Six interface contracts

### 1. Handshake

- IQ dequeue means exact capture or explicit stale ProducerId drop; it is not
  itself an external memory request.
- A normal memory request is accepted only on `mem_req_valid_o &&
  mem_req_ready_i` (or the bank1 equivalent in the dual-port configuration).
- The same accepted request creates exactly one MIQ owner in that cycle.
- Request payload and owner tuple come from the selected reservation terminal.

### 2. Backpressure and hold

- A closed request slot, memory-order predicate, external ready, or edge-old
  terminal0 keeps terminal1 resident.
- A held terminal cannot create a request or MIQ owner.
- A fire from another request producer is not a terminal1 fire and cannot
  consume terminal1 or select terminal1 MIQ payload.
- Existing valid/ready direction remains unchanged; the proof must not add a
  ready-to-valid combinational dependency.

### 3. Pipeline flush and same-cycle priority

- Backend launch priority remains `reset > restore/flush cancellation > normal
  request launch`.
- MIQ next-state priority is `reset > flush compaction > normal push/pop/kill`,
  but the flush compaction input set first subtracts an exact same-cycle head
  response.
- Transport-irrevocable/nokill store DRAIN owners survive a flush while still
  unconsumed; a merely valid head is not treated as a fired response.

### 4. Precise exception order

- The lane0 local exception completes only its exact reservation terminal.
- The younger lane1 memory terminal is held during that edge; it is neither
  lost nor allowed to create an owner early.
- This slice does not change ROB retirement order or architectural trap
  selection.

### 5. Memory order

- Existing `mem_order_ready`, SQ containment, AMO quiet, LQ credit, and request
  slot predicates remain mandatory.
- The proof only checks identity and lifecycle agreement; it does not relax
  load/store, device, atomic, or committed-store ordering.

### 6. Recovery and single source of truth

- The reservation terminal owns the not-yet-launched transaction tuple.
- The MIQ exact head tuple owns an accepted transaction until its response is
  consumed.
- A global pipeline flush changes membership but cannot duplicate a consumed
  owner or remove an unconsumed, ROB-head-authorized physical-write DRAIN
  owner.  This DRAIN is transport-irrevocable/nokill after request acceptance;
  it need not already have retired architecturally.

## Same-cycle table

| Inputs/state | Terminal consume | Request handshake | MIQ next-state |
| --- | --- | --- | --- |
| terminal0 local exception + terminal1 normal memory, single port | terminal0 only | none for terminal1 | no new terminal1 owner |
| following edge, terminal0 empty + terminal1 eligible + ready | terminal1 | exact terminal1 request | one exact terminal1 owner born |
| terminal0 and terminal1 normal memory, terminal0 owns port fire | terminal0 only | exact terminal0 request | one terminal0 owner born; terminal1 unchanged |
| terminal1 held by ready/slot/order | none | none | unchanged |
| exact DRAIN response + global pipeline flush | exact head pop | no new request from flush-cancelled path | remove fired head, then keep remaining DRAIN entries |
| unconsumed DRAIN + global pipeline flush | none | none | retain DRAIN tuple bit-for-bit |
| valid DRAIN head + no pop fire + global pipeline flush | none | none | retain head; valid alone cannot subtract it |

## Evidence and stop conditions

- Focused positive logs must contain exact event-count markers for both debts;
  zero-only summaries are insufficient.
- Each RTL verification variant must use a unique current-source text anchor,
  compile successfully, and fail for its named directed oracle marker.
- The required inventory is eleven variants: eight for terminal launch,
  backpressure, owner arbitration, identity and exactly-once behavior, plus
  three for DRAIN fired/no-fire flush compaction.  MIQ exact-owner mismatch is
  an asserted illegal input, not a normal response-backpressure scenario.
- Source files must be byte-identical before and after variant execution.
- If the baseline focused run fails, stop evidence promotion and classify the
  result as a current architecture defect; do not weaken the oracle or edit the
  debt status to `CLOSED`.
- Network access, remote hosts, accounts, credentials, and external services
  are outside this local RTL task.
