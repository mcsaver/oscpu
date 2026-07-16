# S1 typed-memory ABI focused checkpoint

## Disposition

- State: `intermediate_checkpoint`
- Archive pool: `development` and `high_uncertainty`
- Architecture feasible: `false`
- Formal Pareto/promotion/canonical/champion: forbidden
- Architecture-feasible seed: still `null`
- Linux/full regression/benchmark/synthesis/STA/PPA: not run

This checkpoint closes the focused CACHED/NC/IO typed request/response ABI,
page>PMP>PMA fault priority, exact post-target provenance, CACHED-only cache
admission, NC/IO routing, exact store provenance, unknown-class ordering, and a
non-vacuous full-cover SQ-forwarding bypass.  It does not provide the second
AGU, two translation/cache admissions, a load queue, tagged dual completions,
or qualified Power.

## Immutable source binding

- Content-addressed RTL bundle SHA-256:
  `a80d45cb559652773c43fe6a765eff2bba7607e968b9565703b26c4a8a87adf1`
- Architecture RTL source-set design id:
  `sha256:4a7d748a600096fa8010abbcef0245f6f524786fb0a2ab42857c7db6f81cf5fa`
- RTL source-set manifest SHA-256:
  `6ed7ec7b570acdac84a02bb29ee4ae0e4ab4c4bb429e603828de249be07c9fd6`
- Bundle contents: 138 architecture-evaluator RTL files; each tar member was
  rehashed against the source-set manifest after creation.

## Focused and independent evidence

| Evidence | SHA-256 | Result |
| --- | --- | --- |
| typed classifier | `8f4af1a3003b7dede25cc515f53ceb4ba4db8d7009f406b16fc5d8719a33ef58` | PASS |
| bridge implementation run | `f513e9c48583aa0213692b19320010a963ac7b57c216bffe00cacd71acbeb97c` | PASS |
| backend implementation run | `7c7e7a2d341477bb04be26b913d633d27a208b842b8fc6382a056d626bcf098b` | PASS |
| store queue | `f4c0d235436b0b4d306d146e24bc50d39e73b73f72bf306f15f3f3bfbe335951` | PASS |
| decode wrapper | `256ea1057d645c98382046cd38df7e36416b178905b55e5e86e439cdadd99190` | PASS |
| core-slice wrapper | `407ba19d500ef4b9cc54710f6dce85fa05eca1323838b67fca435122a9e4501b` | PASS |
| core-glue wrapper | `4bc1fa85d017444083bd9881a9f12cf0125b4d47b93f7413dc6ccff4fafdb46d` | PASS |
| independent backend rerun | `dc37159ccc8fdd354c6f55609dc76e16366f7a591c8dda66c0006493ea54d771` | PASS |
| independent bridge rerun | `19107cee0154a5c0598a0dc54442101598469d0aef022183d4f18a679f151412` | PASS |
| public B-response attr-stall rerun | `1d3da45c0d8a358e7b64ea3c2b3a8178ec6d20bde8ac06733649dc72def1333a` | PASS |

All relevant system `/tmp/s1-*` artifacts, including failed iterations and
compiled builds, are preserved under
`tmp/2026-07-15-rv64-ppa-architecture-recovery/s1-typed-abi/system-tmp/`.
Its 29-file payload inventory SHA-256 is
`3f41973a13d8f419d8cc99d06e1feffba403a8ae49d0492dc2e6cad09cd4d6e6`.

## Explicit blockers and next compensation experiment

- Formal module inventory remains blocked by 103 live tests versus the
  hash-bound 102-test contract/policy.
- Nine DI/OOO gates do not have a complete same-design directed suite.
- DI-5 remains structurally RED: no second live memory terminal/AGU,
  translation admission, physical query, cache admission, completion, or
  memory credit.
- OOO-2 still has a single raw memory reservation; OOO-3 still lacks LQ4.
- Power is unqualified without activity coverage and macro models.

Next: `R4-S1-ID exact-owner-provenance` must establish the real
`{owner_kind, owner_token, mmu_epoch}` lifecycle on the current single-width
chain before enabling the second AGU.  It remains a development checkpoint.
