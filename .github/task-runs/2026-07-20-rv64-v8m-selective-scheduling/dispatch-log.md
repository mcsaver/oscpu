# v8m dispatch log

## Contract review

- Contract JSON: `.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/subagent-contracts/v8m-selective-scheduling-contract-review.json`
- Contract JSON SHA-256: `92f2318854a105f750971f7c2cd40fb8983512363b1f137259439f342e0c91f4`
- Binding note: this SHA-256 binds only the JSON contract, not the design
  contract, RTL, tests, or evidence.
- Mode: native `self-contained-no-tools`; no shell, file access, network,
  accounts, credentials, external services, or writes.
- Status: completed; strict JSON verdict `pass`.
- Result: `contract-review-result.json`.
- Required implementation refinements:
  - identify the target issue1 uop by PC/ProducerId and exclude flush/kill;
  - include an older independent ALU counterexample in addition to dependent
    and same-resource residents;
  - require every mutation to elaborate successfully before accepting its
    semantic rejection.

## Implementation review

- Contract JSON: `.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/subagent-contracts/v8m-selective-scheduling-implementation-review.json`
- Contract JSON SHA-256: `6769b79cf6dfcb9e118400ddaaa15272ced5ef10c3d1198dbae54c4be1d63b73`
- Binding note: this SHA-256 binds only the JSON contract.
- Mode: native `self-contained-no-tools`; no shell, file access, network,
  accounts, credentials, external services, or writes.
- Result: `implementation-review-result.json`, strict verdict `pass`, no
  blockers and no false-green findings.
- Residual hardening: formal/interleaving coverage and one-to-one mutations for
  arbitrary-older-valid plus every valid/ready/fire subcondition remain future
  strengthening, not evidence for a broader claim.
