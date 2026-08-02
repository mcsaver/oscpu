# Dispatch log

## Implementer

- Verified the current `OooIntBackend` already contains R3.4 topology and corrected the stale specification pointer.
- Froze the V13I base measurement identities, CoreMark/Dhrystone committed-PC boundaries and deterministic repetition policy.
- Kept overlapping OoO buckets, global issue-slot accounting, retire lost-slot accounting and baseline promotion explicitly GAP.

## Reviewer

- Contract JSON: `.github/task-runs/2026-08-01-rv64-v13j-performance-measurement-contract/subagent-contracts/v13j-performance-contract-review.json`
- Contract JSON SHA-256: `47bb67fff09376ccadb73573e5bfe02a24d34c965f811854a9e22bb851aa7386`
- The SHA-256 binds only that JSON contract.
- Read-only workspace review receives sole WSL engineering-shell ownership until it returns.
