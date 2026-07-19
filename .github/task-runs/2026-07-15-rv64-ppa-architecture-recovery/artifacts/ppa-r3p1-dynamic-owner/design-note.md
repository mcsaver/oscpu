# R3.1 Dynamic Universal Owner Candidate

Status: review-only recovery candidate; canonical RTL/tests are untouched.

## Outcome

This candidate closes the R3 P0 orphan-capture hole while preserving the R3 dynamic capability steering model:

- no fetch/decode/dispatch program position is statically bound to a physical issue terminal;
- physical `issue0` is the Universal terminal and physical `issue1` is a fixed-latency ALU terminal;
- an older simple ALU and a younger complex uop can issue together after capability steering;
- a registered memory reservation may occupy Universal while a sole ready ALU still advances on the ALU terminal;
- a swapped younger memory can enter the reservation only if its older ALU partner actually fires in the same cycle.

This is not a 200 MHz or final-PPA claim. Linux, synthesis, STA, benchmark A/B, and power measurement were intentionally not run.
Under the current canonical DI-3/DI-4/DI-5 contract, this single-Universal/single-memory-owner design is explicitly an
`architecture_infeasible` intermediate recovery step, not a baseline replacement.

## Frozen baseline

- Isolated sandbox baseline commit: `6695728f68d6f62952a35f1b8ee90d8fff331c06`.
- The sandbox was created from the task's current index plus relevant unstaged files; before final export its PPA-contract
  baseline was synchronized to the concurrent canonical LQ/dual-memory contract, without touching canonical source.
- Commit/tree metadata is archived in `sandbox-baseline.txt`; the construction sandbox was removed after export so a later
  `git add .` cannot accidentally stage a nested repository or simulator build products.
- `candidate.patch` is a single diff from that frozen baseline and contains exactly eight files.
- The prior R3 capability-steering patch is included in this cumulative candidate; R3.1 is the safety/liveness completion on top.

## Exact review scope

RTL:

- `npc/rv64/vsrc/scheduling/OooIntIssueQueue.v`
- `npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v`
- `npc/rv64/vsrc/execute/OooIntBackend.v`

Directed tests:

- `npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv`
- `npc/rv64/testbench/tests/tb_ooo_dispatch_backend.sv`
- `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`

Normative text:

- `npc/rv64/design/specs/ooo-int-issue-queue.md`
- `npc/rv64/design/arch/rv64-architecture-ppa-contract.md`

## Architecture

### Dynamic terminal assignment

Each resident IQ entry stores one predecoded `alu_terminal_capable_q` bit beside its payload. The oldest-first scan selects the first two eligible ready residents and assigns them by capability:

| Program-order pair | Universal (`issue0`) | ALU (`issue1`) |
| --- | --- | --- |
| older complex, younger simple | older complex | younger simple |
| older simple, younger complex | younger complex | older simple |
| two simple ALUs | older simple | younger simple |
| registered Universal owner + sole simple | quiet | sole simple |

`issue_pair_swapped_o` explicitly marks the age-reversed physical assignment. Terminal number is a resource identity, not program age. ROB in-order commit remains the architectural ordering authority.

### R3 P0 and the R3.1 fix

R3 allowed an older simple ALU to move to `issue1` while a younger memory moved to Universal. Before R3.1, reservation capture depended only on Universal credit/admission. With Universal base-ready high and ALU ready low, the younger memory could pop and become the registered owner while the older ALU remained in the IQ. That creates an age inversion and can deadlock or serialize the older work behind the younger reservation.

R3.1 defines, for a swapped younger memory:

`effective_universal_ready = universal_base_ready && issue1_fire`

The same predicate gates both IQ pop-ready and `mem_issue_res_capture_w`; therefore pop and capture remain equivalent.

| Ready bits `{Universal-base, ALU}` | Result |
| --- | --- |
| `00` | hold both |
| `01` | fire only the older ALU; younger memory remains |
| `10` | hold both; orphan memory capture is forbidden |
| `11` | fire/capture both atomically |

The coupling is intentionally limited to swapped memory. A swapped branch, jump, or long operation does not establish a blocking reservation owner and may obey ordinary OoO terminal readiness.

### Registered owner liveness

`mem_issue_res_valid_q` is passed upward as `universal_owner_present_i`. It is a registered occupancy fact, never a combinational credit/ready fact. While asserted:

- raw IQ `issue0_valid` is suppressed;
- the scan continues and chooses the oldest ready ALU-capable resident for `issue1`;
- the sole-resident ALU case is legal;
- complex and memory residents remain queued;
- clearing the owner restores ordinary dynamic steering.

Only one LSU/request/MIQ/SQ owner exists. R3.1 does not add a second LSU or reconnect memory logic to the ALU terminal.

## Safety invariants

- Universal registered owner and resident `issue0_valid` are mutually exclusive.
- Two physical terminals never reference the same IQ index.
- `issue1` may only reference an entry whose stored ALU-terminal capability bit is set.
- A swapped pair has older `issue1`, younger `issue0`, and compatible capability bits.
- Swapped younger-memory capture implies older `issue1_fire` in the same cycle.
- Natural-age and swapped-age packets are checked for the relevant RAW direction; terminal numbers are not assumed to encode age.
- Capability metadata moves with insertion/compaction and remains attached to kill survivors.
- Memory capture remains non-fallthrough: no request or execution side effect occurs on the capture edge.

## Directed evidence

All evidence below was generated inside the isolated sandbox with `OOO_ASSERT` enabled.

| Test | Evidence | Result |
| --- | --- | --- |
| `tb_ooo_int_issue_queue` | R3 matrix for branch/JAL/JALR/load/store in both program orders; swapped ready `00/01/10/11`; registered owner + sole ALU | PASS |
| `tb_ooo_dispatch_backend` | interface/plumbing regression | PASS |
| `tb_ooo_int_backend` | held reservation + sole younger ALU exactly once; ALU terminal has no LSU owner; swapped MMIO atomic capture/head release; real iterative DIVU + 8 independent younger ALUs | PASS |

Key observed markers:

- `[R3P1-READY-MATRIX]` for all four ready combinations.
- `[R3P1-REGISTERED-OWNER-SOLE-ALU] PASS`.
- `[T3V-MEM-RES-RELEASE] younger_fire=1 younger_wb=1 younger_commit=1`.
- `[R3P1-SWAPPED-MMIO-ATOMIC] ... PASS`.
- `[R3P1-DIVU-8-YOUNGER] cycles=39 mask=ff commits=9 PASS`.

Logs are archived in `module-test-logs/`; the concise extraction is `module-test-markers.txt`.

## PPA assessment

Performance:

- removes serialization for the required ALU+branch/JAL/JALR/load/store pair orientations;
- allows independent ALU progress while a registered Universal reservation is occupied;
- demonstrates eight independent younger ALUs complete before an older iterative DIVU retires.

Area:

- adds one capability bit per 8-entry integer-IQ slot, one swap marker, and small steering/contract logic;
- adds no PRF port, execution unit, LSU, queue, or architectural state.

Power:

- expected delta is limited to capability flops and additional select activity;
- no workload activity or macro-inclusive power evidence exists, so the power axis is unqualified.

Timing risks:

- the oldest-first scan now includes capability steering and a one-older-memory exception;
- swapped-memory Universal ready depends on the shallow ALU-terminal fire predicate;
- the new scan/ready cones must be measured by fresh synthesis and STA before any 200 MHz claim.

## Known limitations and rejection boundaries

- General memory disambiguation is still conservative: a memory remains blocked behind arbitrary older valid entries except the single older-ready-ALU atomic pair. This does not close the full non-alias younger-load-over-older-store OOO contract.
- The physical ALU terminal remains simple-only and there is only one memory owner. Dynamic steering closes the R3 pair subset,
  but the candidate still fails canonical DI-3 dual-memory pairs, DI-4 lane capability, and DI-5 dual-memory datapath.
- Module tests do not establish full functional closure, Linux boot, benchmark CPI, area, power, or 5 ns timing.
- This candidate must not be promoted as a PPA champion until fresh same-source functional/benchmark/synthesis/STA evidence passes the task's architecture and PPA contract.

## Review/apply checklist

1. Run `git apply --check candidate.patch`; it passed against both the frozen sandbox index and the current canonical working state at export time.
2. Confirm `git apply --numstat candidate.patch` lists exactly the eight files above.
3. Re-run the three archived module targets with a fresh build/result directory.
4. Review the swapped-memory implication and symmetric RAW assertions before broader integration.
5. If accepted, continue with full required module/regression gates, then benchmark A/B and fresh synthesis/STA; do not skip directly to a 200 MHz claim.
