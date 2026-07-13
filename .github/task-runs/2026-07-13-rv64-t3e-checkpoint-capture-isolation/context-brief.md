# Agent Brief

- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: longop req_ready current_result_valid combinational loop
- `token_estimate`: 1209 / 2400
- `command`: `python3 scripts/github_index_db.py brief "longop req_ready current_result_valid combinational loop" --profile npc-dev`

## Bounded recall result

The DB-first query selected `npc-dev` (score 8) and recalled the root AGENTS
contract, `.github/AGENTS.md`, Copilot instructions, project-status,
known-issues, the e2e README, and `npc-dev.tsv`.  It reported the existing
profile command `scripts/agent-e2e.sh --profile npc-dev` and no more specific
module memory.  Live RTL/netlist evidence was therefore used for the T3E root
cause after this bounded context load.
