# v8u/F4 independent rereview v2

## Verdict

`DI-5 local PASS`, confidence medium-high, with the evidence boundary below. The review consumed
only the supplied, SHA-bound contract material and used no tools, shell, file access or external I/O.
It is not a repository-wide RTL review.

## Resolved DI-5 counterexamples

- Full ProducerId and reverse mapping: IQ/full-core markers report `full_pid`, `reverse_mapping`,
  exact MIQ current/next and ROB-wrap age PASS.
- Asymmetric READY: masks `00/01/10/11` were exercised; only `11` atomically drains the pair, and
  valid/payload hold across READY-low.
- Partial consume/overwrite: directed markers require `no_singleton_turnover=1`, `iq_pop2=0`, both
  old owners to drain and only then a new pair capture.
- Pop/capture coupling and Q-only isolation: compile-success mutations for dequeue-without-capture,
  entry0-only pop and regular issue1 exposure are rejected.
- Query visibility, lookup fire gating and feedback SCC: paired bridge mutations are rejected;
  the feedback mutation recreates the SCC while the baseline has none.
- Wrap/kill/backpressure: ROB wrap age, MIQ wrap/effective-kill, one-credit backpressure, dual-EX
  hold, selective kill and flush exact-drop markers pass.

## Remaining non-blocking hardening

- Cross-product stress of ROB wrap, READY `01/10`, replay, kill/flush and same-edge turnover.
- Explicit ProducerId high-bit truncation, A/B swap, stale-generation and late-response mutations.
- Multiple generation wraps under randomized independent backpressure and per-transaction steady
  scoreboarding.

## Boundary

This verdict establishes only ordinary cached-memory steady dual-bank issue. It does not establish
memory ordering, global speculation recovery, shared raw AXI sustained-miss bandwidth, overall
architecture closure, or synthesis/STA/Power/PPA qualification.
