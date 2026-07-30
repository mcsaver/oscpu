# V11G implementer evidence

## Outcome

- Production `OooStoreQueue.v` SHA-256 remains
  `5a5179a0cbfa01048510cb842615b4f63e106816d06c15afdcec02a6b8c68241`;
  scoped Git diff is empty.
- The verification-only testbench SHA-256 is
  `86ea1b71c03071c965fc09af1068475d0c0bca314b73b6b4338bb23ab1516fb0`.
- Design ID remains
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`.

## Directed evidence

- Four positive profiles pass:
  `assert-g1`, `release-g1`, `assert-g4`, and `release-g4`.
- Twenty-four compile-success RTL mutation cases run at both generation
  widths.  Compile return codes are 48/48 zero; simulation return codes are
  48/48 nonzero; every log contains
  `[V11G-SQ-HOLDER-ORACLE][FAIL]`.
- Raw knownness variants independently cover allocation ProducerId and each
  field of the owner tuple with `OOO_ASSERT` disabled.
- Full RTL snapshot pre/post SHA-256 is
  `665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca`
  with 146 RTL files.
- Focused 16-source manifest pre/post SHA-256 is
  `baa89689a63a464cbcad78a819ee021cf17e923687e1997d11537341bf3a9521`.
- Evidence-tool unit tests: 8/8 PASS.
- Semantic-ledger unit tests: 15/15 PASS.
- Ordinary `tb_ooo_store_queue` regression: 1/1 PASS.

## Ledger boundary

The current ledger contains 44 semantic units: 10 PASS and 34 GAP.
Exactly two units changed status relative to V11F:

- `store-queue-producers`: GAP to PASS.
- `store-queue-owner-tokens`: GAP to PASS.

Global no-live-reuse remains incomplete; whole architecture remains RED and
PPA remains unpromoted.
