# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: npc-dev
- `ok`: True
- `expanded_node_count`: 5
- `profile_order`: npc-dev, software-flow
- `modules`: npc, software-flow
- `owners`: npc, software-flow
- `command`: `scripts/agent-e2e.sh --profile npc-dev`
- `validate_command`: `scripts/agent-e2e.sh --validate-profile --profile npc-dev`

## Include edges

- `npc-dev -> software-flow`

## Nodes

1. `software-flow-contract` (`software-flow`)
2. `npc-sim-contract` (`npc`)
3. `npc-single-contract` (`npc`)
4. `npc-soc-contract` (`npc`)
5. `npc-rv64-contract` (`npc`)
