# v8n OOO-1 true long-latency OoO atomic contract

## Scope and claim boundary

This task may promote only architecture gate `OOO-1 true_ooo_long_latency` for
the current complete RV64 RTL source set.  It must preserve the already proven
same-design `OOO-2 selective_scheduling` and `DI-4 no_static_lane_semantics`
records, and it does not itself promote DI-1..DI-5, OOO-3, OOO-4, the
architecture-wide result, or any PPA result.  PPA work remains out of scope
while the architecture inventory is RED.

The task starts by testing an existing production capability.  No functional
RTL edit is planned unless a directed production-path case exposes a real
defect.  A testbench marker or hand-written JSON is not sufficient evidence.

## Six-class interface contract

The focused TB binds abstract events to these production predicates; a bare
`valid` or an event observed while its kill/open qualification is false is not
counted:

- dispatch accept: `dispatch*_valid && dispatch*_ready`;
- integer issue accept: `issue*_valid_w && issue*_ready_w`, equivalently the
  corresponding `issue*_fire_w`;
- load request accept: `mem_req_valid && mem_req_ready`, followed by an exact
  live `miq_head_valid_w`/tracker tuple;
- long-op residency: `muldiv_owner_valid_w` with the recorded full
  `muldiv_owner_producer_id_w`;
- young formal completion: authorized `ex0_wb_valid_w` or `ex1_wb_valid_w`
  with `ex*_producer_open_w && !ex*_kill_now_w`;
- old formal completion: authorized `mem_wb{0,1}_valid_w` or
  `muldiv_wb{0,1}_valid_w` with the recorded owner ProducerId;
- retirement accept: `commit0_valid` / `commit1_valid`, whose production
  definitions already include commit readiness and ROB-head qualification.

### Handshake and ownership

- An old plain load must be dispatched normally, captured by the registered
  memory issue station, accepted on `mem_req_valid_o && mem_req_ready_i`, and
  remain represented by the MIQ/tracker until an exact response is accepted.
- An old MUL or DIV must be dispatched normally, accepted by
  `OooMulDivUnit`, and retain its full `ProducerId` through its response.
- Eight independent younger integer ALUs must be accepted through ordinary
  two-wide dispatch and complete through the real EX/WB terminals.
- Every accepted and completed uop is identified by full `ProducerId`; raw ROB
  index equality alone is not accepted as proof.

### Stall and progress

- While the old load response is withheld, `miq_head_valid_w` must not by
  itself close `issue1_ready_w` for a ready independent ALU.
- While the old iterative MUL or DIV owner is resident,
  `muldiv_owner_valid_w` must not by itself close `issue1_ready_w` for a ready
  independent ALU.
- Ordinary reset, flush, checkpoint recovery, issue blocking, formal WB credit,
  dependency, and resource-conflict gates remain legal.  The directed window
  must observe these unrelated gates open rather than bypassing them.
- For each old-operation class, at least eight distinct younger uops must
  complete before the old operation completes, with ROB peak at least nine.
- The eight young uops must also show four cycles where both real integer
  issue terminals accept different recorded ProducerIds while the exact old
  owner is live.  This is a non-vacuity condition for this dual-issue core; it
  does not promote any DI gate.

### Flush and recovery

- The measured bypass window excludes reset, flush, checkpoint restore, ROB
  kill, and recovery.  The task does not modify their existing priority or
  cancellation behavior.
- A canceled or wrong-path uop cannot satisfy a completion count.  Full
  `ProducerId` membership and live production-path dispatch are required.

### Exception and memory ordering

- The load-miss case uses a normal aligned cacheable load, no stores, no fault,
  and an exact MIQ/tracker response.  It therefore proves latency tolerance,
  not load/store disambiguation or OOO-3.
- The younger ALUs may complete out of order, but no younger architectural
  retirement is legal before the old operation's formal completion reaches
  the ROB Q.  All nine uops must then retire exactly once in program order.

### Identity and exactly-once completion

- The suite records the old and all eight younger full ProducerIds at accepted
  dispatch.
- Before scoring, it consumes one complete ROB turn so every scored ProducerId
  has a non-zero generation field; a raw-index-only comparison cannot pass.
- Every younger EX completion must match one recorded younger ProducerId and
  each recorded younger ProducerId must complete exactly once before the old
  completion.  The old MIQ/tracker or MulDiv owner must remain continuously
  live with the same full ProducerId at every scored young issue and WB event.
- The memory or MulDiv completion must match the recorded old ProducerId and
  occur exactly once.  Commit0 and commit1 must match the recorded nine-entry
  ProducerId/PC sequence without duplicates or omissions.

### Priority

- Existing reset/flush/recovery priority remains unchanged.
- Formal completion writes ROB state first; architectural retirement is
  Q-only on a later edge.  No WB-to-retire same-cycle bypass may satisfy the
  ordered-retirement check.

## Directed behavior and machine metrics

One focused production-backend test must run release and `OOO_ASSERT`
profiles for all three old-operation classes:

1. accepted plain load with response withheld after request acceptance;
2. real iterative RV64 `MUL` using non-trivial non-zero operands;
3. real iterative RV64 `DIVU` using `UINT64_MAX / 3`.

Each class dispatches exactly eight independent younger ALUs, proves four
dual-issue accepts and their distinct full-ProducerId completions before the
old completion, observes nine actual valid ROB entries whose full-PID set
matches the dispatch ledger, rejects early retirement, then completes the old
operation and checks exact in-order retirement plus ROB/IQ/MIQ/tracker/
MulDiv-owner/free-list drain.  The test emits
exactly one record:

```text
[V8N-TRUE-OOO-METRICS] load_miss=8 mul=8 div=8 rob_peak=<n> retire_order_violations=0
```

A separate binding record reports eight owner-live issue accepts, four dual
issue cycles, eight owner-live formal WBs for each class, and nine real valid
ROB entries.  The evidence builder requires the release and assert records to
match exactly.

and exactly one terminal marker:

```text
[V8N-TRUE-OOO-LONG-LATENCY] load-miss/mul/div exact-PID completion and ordered-retire PASS
```

## Negative sensitivity

Compile-success, runtime-rejected mutations must include at least:

- closing issue terminal 1 whenever an MIQ owner is resident;
- closing issue terminal 1 whenever a MulDiv owner is resident;
- permitting retirement of a younger done entry while the old ROB head is not
  done, or an equivalently direct corruption of the in-order retire boundary.
- forcing terminal 1 permanently closed, which must fail the four-dual-accept
  quota even if terminal 0 eventually serializes all eight uops;
- truncating a non-index ProducerId bit independently in the load completion,
  MulDiv owner, or MulDiv response-to-ROB path.

Mutation sources live only in a caller-owned temporary directory.  Every
mutant must elaborate successfully, fail the focused semantic test with a
mutation-specific `[CHECK-FAIL] v8n` diagnostic after a scenario activation
witness, and leave canonical source hashes identical before and after the run.

## Evidence and durable entry point

The evidence producer must write a workspace-relative log containing exactly
one `[ARCH-GATE] true_ooo_long_latency PASS` marker, bind its SHA-256 and exact
proof provenance in `npc/rv64/eval/ppa/evidence/architecture-current.json`,
and bind the manifest to the complete current RTL source-set digest used by
`architecture_hard_gates.py`.

Evidence updates are atomic merges: the producer must preserve every existing
record whose design binding and schema match the current source set.  The
OOO-2 producer must obey the same rule so rerunning either permanent target
cannot erase the other proven record.

The merge helper has executable fault-injection tests: matching OOO-2 and
sibling records survive an OOO-1 update; an injected failure before atomic
replace leaves the old file byte-identical and parseable; stale design/schema
records are not carried into a new binding.  `design_id` binds the full RV64
`vsrc` closure, while the exact provenance map independently binds this
contract, derivation, runner, mutator, checker/tests, evidence helper/builder,
Make entry point, and focused TB.  The JSON contract SHA is never treated as a
design digest.

A stable `make -C npc/rv64 check-true-ooo-long-latency` entry point must rerun
checker self-tests, focused release/assert simulations, compile-success
mutations, evidence generation, and the architecture inventory.  Success
requires OOO-1 GREEN, preserved OOO-2/DI-4 GREEN, and architecture
`OVERALL: RED` until the remaining clauses are independently closed.
