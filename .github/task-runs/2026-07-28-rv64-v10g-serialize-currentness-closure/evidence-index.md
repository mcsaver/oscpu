# V10G evidence index

- run-id: `2026-07-28-rv64-v10g-serialize-currentness-closure`
- design-id:
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`
- bounded status: `BOUNDED_COMPLETE`
- `SERIALIZE-G1`: `CLOSED` for Phase1 current scope
- architecture freeze: `GAP`
- PPA: `UNQUALIFIED`

| evidence | result | SHA-256 |
| --- | --- | --- |
| `semantic-delta-identity.json` | A3/A4 layered identity and rerun decision | `0df921bc53d6a5c7070e5f3da9e2e2c4d460e987d1f16b1cc1b9978f1dbafaab` |
| `product-default-identity.json` | product configuration/current RTL binding PASS | `e140aa5744947ad87bfef6e5e159fb075b8c4ab480ba07672371061e7ed87cf1` |
| `product-default-qh-fallback-v1/summary.json` | assert/release queue-head C0/C1/C2 PASS | `ea36f9855b2658e63ea3b5f7264ed9e5a668f6e91701113338bdafc93732d445` |
| `mutations/qh-csr-c2-replay-v5/summary.json` | typed-apply C2 version rejected | `ffa04d8ce4c4aebf0379e23f545ee3815c6dd4dbb7c4ebd7cd42bfda5b0fbb3e` |
| `mutations/qh-csrfile-c2-replay-v2/summary.json` | CsrFile request C2 version rejected | `c2f5ec7b1c1f31ac2ed0be79a4ef5f7e24775839d3135a5dd29e2bcc19499111` |
| `system-product-default-matrix-v2/summary.json` | 3/3 baseline and 14/14 RTL versions | `867d337884749799e3dbf59f0c9e782a6eaf107e67c987c5cb13151c5bc223d4` |
| `product-default-current-replay/task-run.status` | 26/26 layered replay completed | `c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431` |
| `serialize-g1-closure-candidate-v2.json` | immutable final-review candidate | `158cf6328943a275cd3e12eac780c0cc48223012e2692ca9d9e7f9dace110bab` |
| `subagent-contracts/serialize-currentness-final-review-v2.json` | isolated reviewer contract | `b1316f46171145a8265393d29a0069a9b12f0eb61ae8f13e68b43d8c21aa1af2` |
| `final-reviewer-report-v2.md` | `APPROVED_FOR_CURRENT_SCOPE` | `c79a301cdb5a2ae9210bf872d6cb786a78adcbdc41244f53b20716bfdb2ff93b` |
| `subagent-contracts/serialize-currentness-final-review-v3.json` | isolated currentness reviewer contract | `17447bad26426b3695ba8811f91c7b4894ecbea507c4f546f84f0c029533ff6e` |
| `subagent-contracts/serialize-currentness-final-review-v3.rendered.txt` | exact isolated reviewer prompt | `3109c511e1a87111581cd159d7f153559b00e6a26f34db5450e5fa370a9a13c5` |
| `final-currentness-reviewer-report-v3.md` | `APPROVED_FOR_CURRENT_SCOPE`; ARCH_STABLE/PPA boundaries preserved | `0d816e291693986cdc7e40a92ce6d48eeca0306ffaef22b7de613b922a21f207` |
| `checker-bound-evidence-replay/summary.json` | 9/9 checker replay; inputs unchanged | `d8ed4f5db9ee176a25ed762eba0710b1c95adf2abfc5665f94c6fc3ab859202d` |
| `arch-stable-audit-current.json` | verified GAP; 32 honest blockers | `313b777c2420feeae83315a45688dc290202b38f2225fed2e595fec0fefddce6` |
| `npc/rv64/design/arch/historical-defect-backfill-ledger.json` | 5 entries; two blocking VD1 | `8cf26cb226a20f4c07e145294776698bf464aba442363ac3d4b73f119ee9e0b9` |

Canonical replay:

`python3 .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/verify_serialize_g1_closure.py`

Current hard-boundary replay:

`python3 npc/rv64/eval/ppa/tools/arch_stable_freeze.py verify .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/arch-stable-audit-current.json`
