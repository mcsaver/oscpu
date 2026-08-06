# V14X independent RTL review dispatch

- contract: `.github/task-runs/2026-08-04-rv64-v14x-sq-held-launch-lease/subagent-contracts/v14x-independent-review-v1.json`
- contract_sha256: `aef48572a4a80d3fca636dd7cc8b2d4739227f6b9b63789b0b415b041d08bb19`
- hash_scope: contract JSON only
- task_kind: `read-only-review`
- shell_ownership: reviewer receives the single Windows-to-WSL engineering-command lane for this bounded review and returns it on completion.
- review_result: holder functional slice `PASS`; aggregate `check-contract` `GAP` due stale frozen producer-holder graph.
- review_evidence: `evidence/independent-review.md`
- shell_return: reviewer commands ended; Windows process audit observed zero `wsl.exe` process for this workspace.

## Candidate review v2

- contract: `.github/task-runs/2026-08-04-rv64-v14x-sq-held-launch-lease/subagent-contracts/v14x-candidate-review-v2.json`
- contract_sha256: `61b454031d146014000c31680824d204e7532e5135932bb8a50cad3868e28db4`
- hash_scope: contract JSON only
- task_kind: `read-only-review`
- focus: final RTL diff, candidate gate logs and fail-closed retained `result.txt` commit.
- review_result: bounded holder/receipt slice `PASS`; blocking findings `none`.
- review_evidence: detailed local review at `evidence/candidate-review-v2.md`; versioned conclusion at
  `evidence-index.md`.
- evidence_boundary: aggregate current-design contract, repaired full-system replay and PPA remain `GAP`.
- shell_return: reviewer commands ended; no simulation or synthesis was started and ownership was returned.
