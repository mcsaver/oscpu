# V11H independent pre-review result

- RTL object: `OooLoadQueue` exact ProducerId holder and normal/killed memory
  terminal lifecycle.
- Configuration: public module contract and existing directed LoadQueue
  testbench; no assertion weakening.
- Decision: H2 confirmed, H1 and H3 rejected.
- Counterexample: allocate → launch → normal terminal before formal completion
  → next-cycle selective/global recovery. The pre-fix RTL set `killed_q=1`
  despite the exact terminal already having occurred. No second terminal is
  legal or expected, so `valid_q`/ProducerId remained live indefinitely.
- Required repair boundary: retain exact terminal history as state; block new
  physical operation after normal terminal; clear a terminal-seen recovery
  target directly; keep duplicate terminal as a fatal contract violation.
- Evidence gap identified: V8V nine mutations did not provide a
  stimulus-owned raw-Q model, assertion-off variants, GEN_W=1/4 matrix, or
  prior-terminal lifecycle coverage.
- Reviewer result: architecture repair plus four-profile/raw-Q mutation matrix
  required before closure.
