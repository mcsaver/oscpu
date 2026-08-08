# RV64 RTL dispatch log

- task: `v15x-performance-baseline-f72e-review-v1`
  - contract: `.github/task-runs/2026-08-08-rv64-v15x-performance-baseline-f72e-a1/subagent-contracts/v15x-performance-baseline-f72e-review-v1.json`
  - contract_sha256: `e0245a6f2dc9a2dcc33d32dfeb9bf4a19200dc2ca7c16c90911379aeb1fdae96`
  - mode: `workspace-files/read-only-review`
  - result: `CANDIDATE_ONLY`
  - reviewed_boundary: `publication schema requires verification contract plus declared checker scratch; v1 was not dispatched`

- task: `v15x-performance-baseline-f72e-review-v2`
  - contract: `.github/task-runs/2026-08-08-rv64-v15x-performance-baseline-f72e-a1/subagent-contracts/v15x-performance-baseline-f72e-review-v2.json`
  - contract_sha256: `7fe946d0bea1ee3d17e796a62fbe399b32e3b469d4b49e886bfee6a989179b29`
  - mode: `workspace-files/verification`
  - shell_ownership: `delegated-single-flight`
  - result: `CANDIDATE_ONLY`
  - shell_ownership: `returned`
  - reviewed_boundary: `result bit-exact rebuild PASS; scope extension requested for runner used by declared review regression`

- task: `v15x-performance-baseline-f72e-review-v3`
  - contract: `.github/task-runs/2026-08-08-rv64-v15x-performance-baseline-f72e-a1/subagent-contracts/v15x-performance-baseline-f72e-review-v3.json`
  - contract_sha256: `d4bc899dd70282a8b96f5c0e2f5dd1e57165c870d43d3417e125c582129a0045`
  - mode: `workspace-files/verification`
  - shell_ownership: `delegated-single-flight`
  - result: `PASS`
  - result_path: `.github/task-runs/2026-08-08-rv64-v15x-performance-baseline-f72e-a1/evidence/performance-baseline-current/independent-review-f72e-v3.md`
  - shell_ownership: `returned`
  - reviewed_boundary: `f72e scoped PERF_BASELINE PASS; global CPI/PPA claims remain unqualified`
