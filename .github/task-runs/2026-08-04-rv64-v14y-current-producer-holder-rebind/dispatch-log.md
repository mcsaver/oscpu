# V14Y current producer-holder review dispatch

- contract: `.github/task-runs/2026-08-04-rv64-v14y-current-producer-holder-rebind/subagent-contracts/v14y-current-producer-holder-review-v1.json`
- contract_sha256: `8ea0638f4c53752e29cdb898edd8aac5b53e23747dc8f8f78336e3a1a14c17df`
- hash_scope: contract JSON only
- task_kind: `read-only-review`
- focus: current RTL design-id, exact Yosys source closure, 15-module/17-instance graph, five-role evidence hashes and aggregate `check-contract` result.
- shell_ownership: one bounded read-only command batch completed; no Yosys, simulation or synthesis rerun occurred,
  and the command lane was returned.
- review_result: current design-id/source closure/five-role evidence/static graph slice `PASS`; blocking findings `none`.
- review_evidence: `candidate-review.md`
- evidence_boundary: holder lifecycle, full-system behavior, synthesis quality, STA, area, power and PPA remain unqualified.
