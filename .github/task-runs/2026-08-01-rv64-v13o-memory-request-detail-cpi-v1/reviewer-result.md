# V13O independent reviewer result

- conclusion: `APPROVED_CPI_DIAGNOSTIC_ONLY`
- status: `GAP`
- object: `NpcSimTop.sv` request-detail projection, `cpu-exec.cpp`
  conservation and the frozen V13O CoreMark evidence
- configuration: current-config CoreMark v8/v4, 5,395,310 cycles and
  3,183,617 retired instructions

## PASS within the reviewed scope

- RTL/C++ primary-reason and request-detail encodings agree.
- Non-request primary reasons bind detail `NONE`; invalid reverse mappings are
  checked by RTL/host logic.
- Full ProducerId projects through one live token and two independent bridge
  state observations; ambiguous dual matches become `detail_unknown`.
- Cycle, two-slot, endpoint-correction and three-level aggregate conservation
  are internally consistent.
- The six request-detail buckets sum exactly to 1,111,757 request-outstanding
  cycles.

## GAP and claim boundary

- The original reviewer contract did not include V13N raw/result inputs, so it
  could not independently recompute the five claimed V13N aggregates.
- Pre-run execution identity and post-run closure identity are deliberately
  separate; an independent replay under the final closure was requested.
- The saved result reported zero RTL assertion failures, but the reviewer
  contract did not bind the actual Verilator macro list or a negative mutation.
- Production owner tracker, bridge, backend and SQ RTL were outside the review
  contract, so token semantics and precise aggregate-B behavior were not
  independently proved by this review.
- `S_WRITE_RESP=690056` is residency, not exclusive causal latency evidence and
  not authority for store retirement before aggregate B.
- Production/elaborated identity, synthesis, STA and power remain unbound;
  performance-baseline and PPA promotion are not authorized.

The implementer may close the final-closure replay and assertion-flag binding
without changing this review's production-identity and late-B GAP boundaries.

## Replay follow-up

- frozen raw/result/five-hash final closure: `PASS`
- saved build-log flag observation: `PASS`
- build-log SHA to simulator-executable binding: `GAP_POSTHOC_LOG_ONLY`
- final conclusion remains `APPROVED_CPI_DIAGNOSTIC_ONLY / GAP`

The replay must not describe the saved build-log strings as executable-bound
proof because neither the pre-run identity nor the original post-run binding
froze that log SHA.
