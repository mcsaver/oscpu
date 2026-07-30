# V9O evidence index

- status: `PASS`
- claim scope: `CONTROL-EVENT-G1 current-design review candidate`
- RTL design-id: `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`
- RTL source set: `146` files
- verification source-id: `sha256:5e8107e641f459131fc86220a84ef206870ebc773cc6931ecc65921d8b1c4a92`
- verification source set: `139` files
- provenance SHA-256: `655d0ae2c956bc0e430981b7165fa7d6f3331776ef7141d7fedc1ea20fe9ce33`

## Bound evidence

- focused: `10/10`
- `OOO_CSR_QUEUE_HEAD=1`: `3/3`
- compile-success RTL variants: `11/11` rejected
  (`10` dynamic, `1` full-cone SCC lint)
- default module aggregate: `113/113`
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
- blockers: `53`
- candidate design-id matches current RTL: `true`
- PPA: `UNQUALIFIED`
- promotion eligible: `false`

Machine-readable artifact: `evidence-index.json`.
