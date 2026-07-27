# V9N evidence index

## Canonical commands

- `make -C npc/rv64 check-memory-ordering`
- `make -C npc/rv64 check-width-continuity`
- `bash .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/refresh-dependent-architecture-evidence.sh`
- `bash npc/rv64/eval/ppa/run-arch-stable-audit.sh`

## Current artifacts

| Artifact | SHA-256 | Meaning |
| --- | --- | --- |
| `npc/rv64/eval/ppa/evidence/irrevocable-owner-residency-current.json` | `34090add201aece110bc3423fec7460e33cecb35ce2da1ac73ca788a7cb0d709` | V9N result, PASS |
| `npc/rv64/eval/ppa/evidence/irrevocable-owner-residency.log` | `379d16ebbe790b80315943d2420581c9446c8690ffcd076ab1aba44b592e1746` | V9N raw marker log |
| `npc/rv64/eval/ppa/evidence/architecture-current.json` | `b7813cbdff61a4e8fc4ca6d64c08cd8e29ba48c65d2a13c9a73c18b710917ffb` | 9-gate current-design suite |
| `npc/rv64/eval/ppa/evidence/memory-ordering.log` | `b48ef30badeb26b475be44edc9974fb05a91b962fa03c404e086b1a7a22013d1` | OOO-3/V9N composed raw log |
| `npc/rv64/eval/ppa/evidence/arch-stable-current.json` | `7e4c3aedc4d5a2b1c1118bfe94c0bcbd44566b22be1d3f67322c237af36ad98e` | honest GAP, 38 blockers |
| `evidence/final-arch-stable-audit.json` | `15dee55b51a38ef5daa8173b6cb6f66da242d22d635cfc7e6314019af03e3116` | final read-only audit, honest GAP/38 |
| `evidence/rtl-variants/summary.json` | `4f1b0eef8f3d7b621b423a72dfb64d77dfa30c2e081b3397cf5205a1e0474d53` | 2/2 compile-success dynamic rejection |
| `evidence/dependent-architecture-refresh.log` | `b2eb29e50b1f90472c67d01ed8c70311539a98e625e2dad3ef1dacba8a958608` | 10/10 dependent targets PASS |

相对 `evidence/...` 路径均以本 task-run 目录为根。PPA 保持 `UNQUALIFIED`，
promotion=false。
