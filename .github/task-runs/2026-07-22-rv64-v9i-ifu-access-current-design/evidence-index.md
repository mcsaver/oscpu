# V9I IFU-ACCESS-G1 evidence index

| Artifact | SHA-256 | Purpose |
| --- | --- | --- |
| `npc/rv64/eval/ppa/evidence/ifu-access-current.json` | `9776d139c4d9b406187b17008b6657b8094e59600487ad29ee018c283f3c3898` | current-design structured result |
| `npc/rv64/eval/ppa/evidence/ifu-access.log` | `1a7044ff18ff1df1942fc17863d51eb44668ade3b5559aa8a5d759c7954fd17a` | canonical raw summary |
| `evidence/mutations/summary.json` | `4bd0c81ad4377f781ad1e304daab90a677946b3a89f351fee1b3b923ea4986f2` | 19 current-source negative RTL variants |
| `subagent-contracts/v9i-ifu-access-coverage-review-v2.json` | `00a2e4db3475a6dec764404aca44095eaac88a8289dc2fae0268066b7de09991` | bounded independent review contract |
| `npc/rv64/eval/ppa/evidence/architecture-current.json` | `f362898c079f5e599faab098940f22ce000995c7866eb34541c442db152ca695` | nine directed architecture records |
| `evidence/architecture-hard-gates.json` | `685b1ffdbc7da6c5d286baad3c570ca7c77bdf264e7ed39370794cc315aafb3d` | DI-1…DI-5 and OOO-1…OOO-4 GREEN |
| `npc/rv64/eval/ppa/evidence/arch-stable-current.json` | `5cc70f7d3adb61156c8ee88fbf9251db8236fae630584f8a6d63611781d9d294` | full-core GAP, PPA UNQUALIFIED, 38 blockers |

Focused logs, module aggregate logs and the 19 per-variant logs are nested artifacts of the structured
IFU-ACCESS result and are hash-bound there. `review-v2-result.md` records the bounded reviewer conclusion.
