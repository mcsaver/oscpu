# Profile Resolve

- `profile`: workspace-artifact-retention
- `graph_template`: modular-agent-e2e
- `graph_mode`: static
- `scope`: task-local
- `global_profile_installed`: false

该 task-local profile 仅记录本次 RV64 EDA artifact retention 图，不注册为
全局 e2e profile，也不会满足 `agent-system`、`npc-dev` 或 `nemu-dev`
guard。节点定义见 `nodes.tsv`；长期复用前应先把 forward-test 提升为正式
profile，而不是让一次性 task-run 自证全局环境能力。
