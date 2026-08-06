# Task report

Status: PASS for the bounded RV64 terminal collector/host contract.

Implementer evidence:

- canonical dual-log receipt with `INVALID_EVIDENCE > FAIL > PASS` and no terminal-event deduplication;
- one-launch host wrapper with isolated timeout diagnostics, preclear alias fence and post-return producer-closed binding;
- 42/42 deterministic tests, `bash -n` PASS, scoped `git diff --check` PASS;
- A2 remains PASS/PASS/PASS 17/17; A3 remains top/stage FAIL 16/17 and terminal PASS.

Reviewer evidence:

- v1 found five concrete counterexamples and returned GAP;
- v2 executed the expanded tests and frozen-log verification, returned PASS, and confirmed no background process remained;
- detailed results are in `review-v1.md`, `review-v2.md` and `evidence-index.md`.

Not claimed: new full-system simulation, whole-architecture proof, CPI/PPA promotion, or repair of A3 historical status. A3 original FAIL remains unchanged and is interpreted as system transaction complete plus the known old `dmesg-no-critical` oracle false positive.

Strict guard record:

- invocation without explicit paths returned rc=1 because Git worktree enumeration is disabled;
- invocation with `changed-paths.txt` returned rc=1 for missing `rv64-systemd-contract` and `agent-system` profile evidence;
- bounded waiver: the former would duplicate the stronger 42-case executable matrix, A2/A3 canonical replay and independent v2 verification already retained here; the latter was selected only because DB-backed `agent-system.md` memory was updated, while no agent guard/policy implementation changed. The guard FAIL is not rewritten as PASS and does not authorize architecture/PPA promotion.
