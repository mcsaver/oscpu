# RV64 L2/L3 independent review dispatch

- contract: `.github/task-runs/2026-08-05-rv64-v15c-l2-l3-independent-review-v1/subagent-contracts/rv64-v15c-l2-l3-independent-review-v1.json`
- contract_sha256: `37c46ac68723fbf320de84cc5da41713d150b3bbdafc0c3fd9e96712d241abd7`
- hash_scope: contract JSON only
- task_kind: `read-only-review`
- material_mode: `workspace-files`
- shell_ownership: transferred to the reviewer for one bounded read-only command batch
- parent_goal_status: active

## v1 scope extension

- result: `candidate-only`
- reason: `.github/instructions/agent-lightweight-workflow.instructions.md` was required by `.github/AGENTS.md` but absent from v1 `allowed_paths`
- technical_review_started: `0`
- shell_ownership_returned: `1`

## v2 dispatch

- contract: `.github/task-runs/2026-08-05-rv64-v15c-l2-l3-independent-review-v1/subagent-contracts/rv64-v15c-l2-l3-independent-review-v2.json`
- contract_sha256: `6508f8db46cc0af235e3e8fce66133c85e509294a8741895e9580b72f6865c59`
- hash_scope: contract JSON only
- scope_extension: added `.github/instructions/agent-lightweight-workflow.instructions.md`
- task_kind: `read-only-review`
- material_mode: `workspace-files`
- shell_ownership: transferred to the reviewer for one bounded read-only command batch
- parent_goal_status: active
