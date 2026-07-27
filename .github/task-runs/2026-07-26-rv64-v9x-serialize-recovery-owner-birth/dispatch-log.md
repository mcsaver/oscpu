# V9X dispatch log

## Shell ownership

- Windows → WSL engineering-command ownership is single-flight.
- During the independent RTL review node, the reviewer owns the only WSL engineering-command lane.
- The root node performs no WSL command while that review node is active.

## Reviewer contract

- Contract: `.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/reviewer-contract-v1.json`
- SHA-256: `f7d5a4ecf4cdc87b743c7e2cb322d148cd311fbbdce08e60e010d9d136f87047`
- Validation: `PASS`
- Dispatch mode: `fork_turns="none"` with the exact canonical render output.
- WSL shell ownership: transferred to `recovery_owner_review` for the duration of the read-only node.

## Post-implementation reviewer contract

- Contract: `.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/reviewer-contract-v2.json`
- SHA-256: `f0e59a75a8687d45813e790d59d1822ab64292494c095f2170bc133d4dd6ef9c`
- Validation: `PASS`
- Dispatch mode: `fork_turns="none"` with the exact canonical render output.
- WSL shell ownership: transferred to `recovery_owner_post_review` for the duration of the read-only node.
- Result: `GAP`; report recorded in `reviewer-report-v2.md`.
- WSL shell ownership: returned to the root node after the read-only review.
- Scope extension: C0/C1 holder path, drain-resolve edge, merged dispatch
  fire, and the existing queue-head flag-on target require a new versioned
  contract.

## Scope-extension verification contract

- Contract: `.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/reviewer-contract-v3.json`
- SHA-256: `7b9b2991642bc0d6f0db77397d97ad46bbd6c437b2676a0c8ffb7842968a4dbc`
- Validation: `PASS`
- Dispatch mode: `fork_turns="none"` with the exact canonical render output.
- Write scope: only `evidence/v3-flag-on` for `BUILD_DIR` and `RESULT_DIR`.
- WSL shell ownership: transferred to `recovery_owner_v3_verify` for the
  duration of source inspection and the one declared flag-on test.
- Result: `GAP`; report recorded in `reviewer-report-v3.md`.
- WSL shell ownership: returned to the root node.
- Follow-up correction: root exported the real
  `OooFrontend.head0_csr_dispatch_fire_w`, connected it to
  `OooControlPlane`, and added `core_local_flush_w` to the trap/exit holder
  reset. The final flag-on oracle and compile-success mutations are recorded
  under `evidence/post-v3`.

## Final independent review contract

- Contract: `.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/reviewer-contract-v4.json`
- SHA-256: `0c24142ece0c242655ac6f1b757a741dcb99071deebf33fd9c1c404746688708`
- Validation: `PASS`
- Dispatch mode: `fork_turns="none"` with the exact canonical render output.
- Write scope: none; source/spec/TB/evidence inspection is read-only.
- WSL shell ownership: transferred to `recovery_owner_final_review` for the
  duration of the final review; root runs no WSL engineering command while the
  node is active.
- Result: `PASS` for the V9X owner-birth sub-scope; `SERIALIZE-G1` remains
  `OPEN`.
- Report: `reviewer-report-v4.md`.
- Confidence boundary: the contract did not reopen the internal generation
  logic of `OooPendingDispatchArbiter`/the C1 gate; mutation summary binds the
  production `OooControlPlane.v` hash rather than one aggregate hash for the
  complete mutant cohort and TB. Neither boundary yielded a current
  owner-birth counterexample.
- WSL shell ownership: returned to root; all reviewer commands ended and no
  background process remains.
