# R3.2 Actual-Fire Early Wake + Registered EX Forwarding

Status: isolated review candidate on top of the frozen R3.1 sandbox baseline. Canonical RTL and tests were not modified by this implementation worker; only this evidence directory was exported.

## Outcome

R3.2 removes the avoidable fixed-latency integer RAW bubble without restoring dispatch bypass or a completion-to-select combinational path:

- an IQ entry stores one `fixed_gpr_producer` bit beside its payload;
- an eligible producer generates lookahead wake only on physical terminal `actual fire`;
- lookahead wake updates IQ next-state readiness only, so producer cycle N cannot select its consumer in N;
- the EX stage registers `{forward-valid, pdest, data}` on the same edge;
- the consumer selects and fires in N+1, using tag-matched registered EX0/EX1 data;
- PRF remains stored-only and formal WB remains the only BusyTable/PRF completion source;
- terminal metadata follows dynamic R3/R3.1 swapping, so physical terminal identity is not confused with program age.

The 64-uop dependent `addi` chain observed `fired=64 committed=64 cycles=66`. Every one of the 63 RAW edges checked producer N fire to consumer N+1 fire, registered EX0 hit, ordered PC, and result sequence 1 through 64.

This is not a 200 MHz or final-PPA claim. Linux, full regression, benchmark A/B, synthesis, STA, and power measurement were intentionally not run in this bounded round.

## Frozen baseline and exact scope

- Sandbox baseline commit: `df604c0e6c72e53f1572cd0691ab7061271175cf` (`r3p1-minimal-semantic-port`).
- `candidate.patch` is the pure R3.2 increment from that commit; it does not include R3/R3.1 baseline changes.
- Exact patch scope is seven files: three RTL modules, three directed testbenches, and the integer-IQ specification.

RTL:

- `npc/rv64/vsrc/scheduling/OooIntIssueQueue.v`
- `npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v`
- `npc/rv64/vsrc/execute/OooIntBackend.v`

Tests/specification:

- `npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv`
- `npc/rv64/testbench/tests/tb_ooo_dispatch_backend.sv`
- `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`
- `npc/rv64/design/specs/ooo-int-issue-queue.md`

## Architecture contract

### Eligibility is an allow-list

An early producer must be a valid, nonzero-pdest integer GPR writer with fixed ALU/IMM writeback and no memory stage. The classifier fails closed for load/store/AMO, MulDiv, CLMUL, CSR, FP, branch/JAL/JALR, illegal, fence, system, synchronous-exception, and trap-return classes. Formal WB wake continues to cover every excluded class.

### Sticky-only select boundary

Both full-WB and early wake pulses are ORed only into IQ next-state readiness for resident compaction, same-edge dispatch insertion, and kill survivors. Selection reads only `src*_ready_q`; no wake pulse participates in same-cycle select. Thus the new performance path is a sequential recurrence:

`producer actual fire (N) -> IQ ready + EX payload registers -> consumer select/fire (N+1)`

### Registered data boundary and stalls

The two 145-bit EX stage payloads preserve all legacy formal-WB bit positions and add only bit 144 as forwarding-valid. Four integer source reads (two terminals times two sources) compare against both registered EX tags. EX1 has deterministic priority only for the architecturally illegal duplicate-pdest case.

If a ready consumer is held by downstream backpressure, the transient EX match may disappear, but formal WB writes the producer into stored PRF state on the edge. A later consumer fire therefore falls back to PRF data; no combinational WB write-through was added.

### Recovery

Kill gates both issue terminals, removes the younger suffix, and still lets the surviving prefix absorb a matching early wake. Flush dominates early wake and clears the IQ. These cases are directly marked in the archived IQ log.

## Directed evidence

Command:

`make TESTS="tb_ooo_int_issue_queue tb_ooo_dispatch_backend tb_ooo_int_backend" run`

Result: PASS 3/3 with `OOO_ASSERT` enabled by the module runner.

Key evidence:

- `[R3.2-RAW64] fired=64 committed=64 cycles=66`.
- dual independent producers fire together; two consumers fire in N+1 and independently hit EX0/EX1 with correct results.
- `[R3P2-STALL]` confirms IQ valid/count stability under ready=0 and drain after release.
- `[R3P2-KILL]` confirms a matching early wake reaches only the surviving prefix.
- `[R3P2-FLUSH]` confirms flush dominates a matching early pulse.
- `[R3P2-FIXED-CLASS]` records positive class 0 and excluded classes 1..8 as `fixed=0` (load, AMO, MulDiv, CLMUL, CSR, FP, branch, illegal).

Raw logs and the runner summary are archived beside this note. `git diff --check` and `git apply --cached --check candidate.patch` both passed at export.

## PPA assessment

Performance:

- fixed-latency dependent ALU recurrence improves from formal-WB wake latency to one fire-to-fire cycle when a consumer is resident;
- dual producer/dual consumer coverage proves both physical EX payloads are usable after dynamic terminal assignment;
- no claim is made for aggregate CoreMark/Dhrystone CPI until same-image A/B measurement.

Area:

- adds one metadata bit per 8-entry IQ slot, one forward-valid bit per EX stage, two early-wake tags, eight tag comparisons, and four small source muxes;
- adds no PRF port, execution unit, ROB entry, LSU, or architectural state.

Power:

- extra CAM comparisons and source mux activity may increase dynamic power on dependent integer traffic;
- reduced wasted dependency bubbles may lower energy per completed operation, but no workload power data exists yet.

Timing:

- wake CAMs remain outside the resident select cone, protecting the T3M timing barrier;
- registered EX tag/data now feed source muxes before ALU/AGU use, so the EX-register-to-ALU path must be measured by fresh synthesis/STA;
- no 5 ns closure is inferred from simulation.

## Rejection boundaries and next gates

Do not promote this candidate if any excluded class emits early wake, if a wake pulse enters same-cycle select, if recovery loses/duplicates a resident, or if fresh same-source PPA loses more area/power/timing than the measured CPI gain justifies.

Before baseline promotion, apply the patch on top of accepted R3.1, run the required full module/regression set, then perform benchmark A/B and fresh synthesis/STA/power. Keep the isolated sandbox for those follow-on gates.
