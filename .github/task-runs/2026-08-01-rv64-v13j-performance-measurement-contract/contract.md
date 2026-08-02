# V13J performance measurement contract

- classification: `tooling/workflow`
- secondary intent: `performance-cpi`
- production RTL change: none
- object: current V13I full-core RV64 measurement identity and committed-PC region semantics
- success: freeze exact measurement inputs while keeping CPI stack, issue/retire lost-slot and baseline qualification fail-closed until separately proven
- canonical outputs:
  - `npc/rv64/design/arch/performance-measurement-contract-v1.json`
  - `npc/rv64/design/arch/performance-measurement-contract.md`

This round does not launch a full-system workload, does not modify workload binaries, and does not claim a qualified CPI baseline.
