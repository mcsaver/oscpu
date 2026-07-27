# RV64 V9T 12-lane terminal collector contract

## RTL object and design binding

- Production RTL design: `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`.
- Collector instance: `OooIntBackend.u_mem_owner_terminal_collector`.
- Collector parameter: `INGRESS_N=12`.
- Owner identity: exact `{kind, token, epoch}` tuple from the edge-old
  `OooMemOwnerTracker` state.

## Required behavior

1. The twelve ordered ingress lanes remain structurally connected to the
   production collector in their declared order.
2. Twelve distinct live owner tuples may arrive on one cycle while both
   dequeue ports are stalled.
3. Registered output tuples remain stable under backpressure.
4. Every captured tuple drains exactly once; no tuple may be silently dropped,
   merged, deduplicated or fabricated.
5. Duplicate ingress, pending duplicate, same-edge re-enqueue, non-live owner,
   tuple mismatch and conservation failures remain fail-loud assertions.
6. The V9R full-flush C0 producer-side contract remains unchanged:
   `OooIntBackend` bank0/bank1 retry READY and
   `OooMemAxiBridge.sq_query_retry_fire_w` are closed while the barrier is
   asserted.

## Success evidence

- Focused collector release and `OOO_ASSERT` configurations both emit exact
  12-ingress capture/drain markers and `[RESULT] PASS`.
- The DI-3 source checker proves the exact twelve-lane ordered concatenation;
  a lane10/lane11 ordering swap makes the check RED.
- Pair-matrix evidence reports `collector_ingress_peak=12` and
  `collector_exact_drains=12`.
- The current 110-test Icarus Verilog module inventory passes with stable RTL
  and verification source identities.

## Non-promotion boundary

This contract closes only the local collector topology and the bounded
producer/holder handoff evidence. It does not declare the systemd-strict guest
transaction complete, close `SERIALIZE-G1`, freeze the full core, or qualify
PPA. The exact lane pair responsible for the historical duplicate assertion
was not printed by that historical run and remains unknown.
