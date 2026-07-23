# V9D FDG-G1 independent review summary

## Review identity

- Both reviews used validated, self-contained, no-tools, no-shell contracts.
- v1 contract: `subagent-contracts/v9d-final-review.json`, SHA-256
  `3849f6ffacd6800dc2b468e079c54a6995579a80c341c16b04e344f1c639d27c`.
- v2 contract: `subagent-contracts/v9d-final-review-v2.json`, SHA-256
  `41ce53d0de98305ed1a8803a897f3de52c3517826385db554289f8fd45df49ed`.
- v3 contract: `subagent-contracts/v9d-final-review-v3.json`, SHA-256
  `4df79c556a0c3ecc8d1198e9a758f9056b7d7649096f79f18dd6f6ffd88f8d06`.
- v1 verdict: `FAIL`; no P0, two P1 evidence-boundary findings.
- v2 verdict after evidence hardening: `PASS`; no unresolved P0/P1.
- v3 verdict after canonical-replay determinism hardening: `PASS`; no
  unresolved P0/P1.

## v1 findings and disposition

1. The original frozen packet reported `illegal_fp_commit=0` without proving
   the two-lane commit-valid/PC observer was dynamically non-vacuous.
2. It reported one trap capture and cause 2 without exposing exact capture
   PC/tval and CSR `mepc/mtval` value sensitivity.

The main implementation added one known older ADDI hit through the same commit
observer and a compile-success verification configuration that repoints the
zero oracle at that transaction and is rejected 1/1. It also added exact
capture-PC/tval and CSR `mepc/mtval` metrics, plus compile-success PC-offset and
tval-zero RTL source variants. The canonical result was regenerated before v2.

## v2 verdict and preserved boundary

The reviewer accepted both former P1s as closed for the current design identity
and the listed single illegal-FP full-core transaction. The accepted statement
is limited to four focused illegal FP encodings, one legal FADD.S positive
control, one full-core illegal-instruction trap, exact metadata for that
transaction, handler/MRET return, no ordinary/final backend presentation, and
the aggregate two-lane commit observation under the current configuration.

It does not qualify full-core architecture stability or PPA. Mandatory state is
`ARCH_STABLE=GAP`, 44 blockers, `ppa=UNQUALIFIED` and
`promotion_eligible=false`.

## P2 residuals

1. The aggregate commit observer has one known positive transaction, but lane0
   and lane1 have not each received an independent dynamic sensitivity cut.
2. The metadata evidence covers one trap transaction; consecutive trap or
   trap/flush overlap could require a future cross-transaction PC/tval pairing
   oracle.
3. The discarded early classifier-binding variant remains explicitly excluded
   because the correct upstream trap owner intercepted it before the selected
   ordinary-dispatch oracle. It cannot be counted as classifier mutation
   completeness.

These are retained limitations, not blockers for the stated V9D FDG-G1 claim.

## v3 evidence-serialization review

The final canonical replay exposed random temporary compile-root strings in
module and RTL-variant logs. After exact-root normalization and two identical
canonical result cohorts, v3 independently accepted that:

1. replacing only the current `TemporaryDirectory` root does not hide the
   relevant compiler diagnostics, source names, options, oracle markers,
   return codes or result states;
2. the fail-closed path checks are sufficient when composed with the existing
   109/109 module, 6/6 RTL-variant and 1/1 observer inventory gates;
3. byte-identical double replay supports rebinding the ledger to FDG result
   SHA `6238dbef481273da7d6acc00156a9bf1a23c90ebfb610498053377b66df88fb0`.

v3 retained two additional P2 boundaries. First, a raw diagnostic that already
contains literal `<FDG_TRANSIENT_TMP>` could theoretically collide with a
normalized path; current evidence shows no such input, but normalization is not
claimed as collision-proof for arbitrary log text. Second, the helper's
nonempty-log check is not an inventory proof by itself; completeness continues
to depend on the exact upstream 109/109, 6/6 and 1/1 gates. Neither changes the
existing single-transaction architecture claim or permits PPA promotion.
