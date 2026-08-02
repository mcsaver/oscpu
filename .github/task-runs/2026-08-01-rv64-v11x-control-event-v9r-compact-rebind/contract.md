# V11X CONTROL-EVENT/V9R compact current-evidence contract

- RTL objects: `OooIntBackend` retry bank0/bank1 holders and
  `OooMemAxiBridge` registered `S_SQ_QUERY` owner.
- Cycle boundary: C0 full-flush barrier blocks empty-holder capture and
  resident-holder transfer; release is legal only after C0 drops.
- Positive matrix: both backend banks, forced C0, natural ROB trap-head C0,
  bridge hold and post-barrier release.
- Counterexamples: bank0 READY-open, bank1 READY-open, bridge retry-fire-open,
  bank0 resident-holder fire-open and bank1 resident-holder fire-open must
  compile and be rejected by the exact V9R/V11L assertion or TB marker.
- Retention: `.vvp` images live only below a task-owned `/tmp` root. Retain
  normalized logs, five reconstructible source-changing RTL patches, source snapshots,
  status receipts and one current result JSON.
- Claim: local current-design `CONTROL-EVENT-G1` evidence only; no whole-core
  architecture GREEN, system recertification or PPA promotion.
