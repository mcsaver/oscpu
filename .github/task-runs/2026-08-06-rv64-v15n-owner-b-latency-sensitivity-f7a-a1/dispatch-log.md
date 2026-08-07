# RV64 subagent dispatch log

## v15n-owner-b-latency-sensitivity-review-v1

- Contract: `.github/task-runs/2026-08-06-rv64-v15n-owner-b-latency-sensitivity-f7a-a1/subagent-contracts/v15n-owner-b-latency-sensitivity-review-v1.json`
- Contract SHA-256: `bbbc276bb466c7577d961d77983318d032403f70f244b3e173c57b3d410928ac`
- Task kind: `read-only-review`
- Scope: local RV64 `NpcSimTop` / `AxiDpiSlave` B-channel test intervention, frozen twelve-case execution evidence, checker replay and selector transition.
- WSL shell ownership: transferred to the reviewer for the bounded `rg` / `sed` / `sha256sum` batch; the main agent does not run WSL engineering commands until ownership is returned.
- Reviewer result: `GAP`; frozen H1 data were consistent, but replay v1 could write a fail-open `PASS` because intermediate return codes were not gated.
- Action: retained replay v1 as historical candidate-only evidence; added explicit stage return-code gates plus four forced-failure and one all-pass runner tests; generated `checker-replay-v2` from unchanged frozen logs.
- WSL shell ownership: returned by the reviewer before the correction was implemented.

## v15n-owner-b-latency-sensitivity-review-v2

- Contract: `.github/task-runs/2026-08-06-rv64-v15n-owner-b-latency-sensitivity-f7a-a1/subagent-contracts/v15n-owner-b-latency-sensitivity-review-v2.json`
- Contract SHA-256: `407818d186b7cdfd5eeb33b0665d7c2897849fbf620993436b1c529260848f38`
- Task kind: `read-only-review`.
- Scope: only the fail-closed runner correction, its four forced-failure/one positive tests, checker-replay-v2 receipt and selector binding.
- WSL shell ownership: transferred to the reviewer for one bounded `rg` / `sed` / `sha256sum` batch.
- Reviewer result: `PASS`; no scope extension requested.
- Key bounded unknown: the reviewer inspected the exact test source and aggregate 15/15 log but did not rerun the tests; main-node executed evidence already records the rerun.
- WSL shell ownership: returned; all reviewer commands exited.
