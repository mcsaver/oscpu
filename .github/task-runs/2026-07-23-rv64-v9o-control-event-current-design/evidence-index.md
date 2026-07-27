# V9O evidence index

- status: `PASS`
- claim scope: `CONTROL-EVENT-G1 current-design review candidate`
- RTL design-id: `sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`
- RTL source set: `146` files
- verification source-id: `sha256:c1f64d038c4ead52a3566911186f415ba0d8d56d8567bb10736bbb5025369035`
- verification source set: `135` files
- provenance SHA-256: `b0ccbdf7a2014810b602b4ac5a2377654e2e2f2065f455df949b1bf2ecb791e9`

## Bound evidence

- focused: `10/10`
- `OOO_CSR_QUEUE_HEAD=1`: `3/3`
- compile-success RTL variants: `11/11` rejected
  (`10` dynamic, `1` full-cone SCC lint)
- default module aggregate: `111/111`
- directed architecture hard gates: `9/9 GREEN`
- contract gate: holder census PASS, `471` immediate assertions,
  `13/13` unit tests

## Dynamic control-event oracles

- real full-C0 completion matrix: `8/8` classes,
  `head=15/younger=0`
- dual registered AR barrier: `2` lanes, `4` held cycles,
  `2` exact terminals
- single C0 request source: trap/CSR commit pulses are bidirectional
  pregrant assertions, not alternate request inputs

## Claim boundary

- full-core architecture freeze: `GAP`
- blockers: `95`
- candidate design-id matches current RTL: `true`
- PPA: `UNQUALIFIED`
- promotion eligible: `false`

Machine-readable artifact: `evidence-index.json`.
