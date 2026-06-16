# E2E Resolved Profile

- `source`: stored
- `profile`: nemu-dev-gate
- `ok`: True
- `expanded_node_count`: 4
- `profile_order`: nemu-dev-gate, nemu-dev, nemu-ubuntu-focused, software-flow
- `modules`: nemu, software-flow
- `owners`: nemu, software-flow
- `command`: scripts/agent-e2e.sh --profile nemu-dev-gate
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile nemu-dev-gate

## Include Edges
- `nemu-dev-gate` -> `nemu-dev`
- `nemu-dev` -> `nemu-ubuntu-focused`
- `nemu-ubuntu-focused` -> `software-flow`

## Nodes
1. `software-flow-contract` source=`software-flow` module=`software-flow` owner=`software-flow` function=`e2e_software_flow_contract`
2. `nemu-ubuntu-static` source=`nemu-ubuntu-focused` module=`nemu` owner=`nemu` function=`e2e_nemu_ubuntu_static_gate`
3. `nemu-ubuntu-slice-contract` source=`nemu-ubuntu-focused` module=`nemu` owner=`nemu` function=`e2e_nemu_ubuntu_slice_contract`
4. `nemu-dev-focused-gate` source=`nemu-dev-gate` module=`nemu` owner=`nemu` function=`e2e_nemu_ubuntu_focused_gate`

