# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: rv64-systemd-contract
- `ok`: True
- `expanded_node_count`: 1
- `profile_order`: rv64-systemd-contract
- `modules`: npc
- `owners`: npc
- `command`: scripts/agent-e2e.sh --profile rv64-systemd-contract
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile rv64-systemd-contract

## Nodes
1. `npc-rv64-systemd-guest-check-contract` source=`rv64-systemd-contract` module=`npc` owner=`npc` function=`e2e_npc_rv64_systemd_guest_check_contract`
