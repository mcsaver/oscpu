# E2E Resolved Profile

- `source`: stored
- `profile`: nemu-ubuntu-full-gate
- `ok`: True
- `expanded_node_count`: 4
- `profile_order`: nemu-ubuntu-full-gate, nemu-ubuntu, nemu-ubuntu-focused, software-flow
- `modules`: nemu, software-flow
- `owners`: nemu, software-flow
- `command`: scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate
- `validate_command`: scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu-full-gate

## Include Edges
- `nemu-ubuntu-full-gate` -> `nemu-ubuntu`
- `nemu-ubuntu` -> `nemu-ubuntu-focused`
- `nemu-ubuntu-focused` -> `software-flow`

## Nodes
1. `software-flow-contract` source=`software-flow` module=`software-flow` owner=`software-flow` function=`e2e_software_flow_contract`
2. `nemu-ubuntu-static` source=`nemu-ubuntu-focused` module=`nemu` owner=`nemu` function=`e2e_nemu_ubuntu_static_gate`
3. `nemu-ubuntu-slice-contract` source=`nemu-ubuntu-focused` module=`nemu` owner=`nemu` function=`e2e_nemu_ubuntu_slice_contract`
4. `nemu-ubuntu-full-focused-gate` source=`nemu-ubuntu-full-gate` module=`nemu` owner=`nemu` function=`e2e_nemu_ubuntu_full_focused_gate`

