# E2E Resolved Profile

- `source`: live-or-stored
- `profile`: nemu-dev-full-gate
- `ok`: True
- `expanded_node_count`: 4
- `profile_order`: nemu-dev-full-gate, nemu-dev, nemu-ubuntu-focused, software-flow
- `modules`: nemu, software-flow
- `owners`: nemu, software-flow
- `command`: scripts/agent-e2e.sh --profile nemu-dev-full-gate
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile nemu-dev-full-gate

## Include Edges
- `nemu-dev-full-gate` -> `nemu-dev`
- `nemu-dev` -> `nemu-ubuntu-focused`
- `nemu-ubuntu-focused` -> `software-flow`

## Nodes
1. `software-flow-contract` source=`software-flow` module=`software-flow` owner=`software-flow` function=`e2e_software_flow_contract`
2. `nemu-ubuntu-static` source=`nemu-ubuntu-focused` module=`nemu` owner=`nemu` function=`e2e_nemu_ubuntu_static_gate`
3. `nemu-ubuntu-slice-contract` source=`nemu-ubuntu-focused` module=`nemu` owner=`nemu` function=`e2e_nemu_ubuntu_slice_contract`
4. `nemu-dev-full-focused-gate` source=`nemu-dev-full-gate` module=`nemu` owner=`nemu` function=`e2e_nemu_ubuntu_full_focused_gate`

