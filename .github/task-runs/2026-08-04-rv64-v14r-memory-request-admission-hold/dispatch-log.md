# V14R subagent dispatch log

- `v14r-final-independent-review-v1`: read-only local RV64 RTL review.
- Contract JSON: `.github/task-runs/2026-08-04-rv64-v14r-memory-request-admission-hold/subagent-contracts/v14r-final-independent-review-v1.json`
- Contract JSON SHA-256: `aaa537ba78ca4087a57e2bf6123be43f509de644df14927a048520e951160311`.
- The SHA-256 binds only the contract JSON. The validated `render` output is dispatched verbatim with `fork_turns="none"`.
- WSL single-flight ownership: transferred to this read-only reviewer for the bounded `rg`/`sed`/`sha256sum` command set; ownership returns when the node finishes or reports GAP.

## v1 closeout

- Reviewer returned ownership with `GAP`: production RTL dataflow had no deterministic blocker, but the original contract did not expose the V14Q `invalid_events=1176` log or focused/mutation/link raw logs.
- Actionable TB gaps were implemented before a new review: late contenders remain through exact fire; consume/MIQ metadata are checked against the held source; transport-open recovery cancel, both bank-capacity directions and a single-bank older-probe case were added.
- Mutation coverage is now four independent compile-success variants: holder bypass, cancel fallback, consume/MIQ live split and single-bank probe-order bypass.

## v14r-final-independent-review-v2

- Contract JSON: `.github/task-runs/2026-08-04-rv64-v14r-memory-request-admission-hold/subagent-contracts/v14r-final-independent-review-v2.json`
- Contract JSON SHA-256: `fd86fcd3c77884d30a34ad93ade1cbcdd3ef114dfacd81a3e9e635b588ac94f1`.
- Scope extension is bounded to production RTL/TB/wheels, `verification-v2/`, the V14Q raw owner-timing endpoint and the current V14R raw/replay endpoints.
- WSL single-flight ownership: transferred to the v2 read-only reviewer for only `rg`/`sed`/`sha256sum`; no DUT, synthesis or STA rerun is authorized.

## v2 closeout and v3 oracle follow-up

- v2 reviewer returned ownership with `PASS` for the V14R request-admission contract and explicit
  `GAP` for `ARCH_STABLE`, same-design performance and PPA. The bounded report is retained at
  `evidence/independent-review-v2.md`.
- Two oracle counterexamples were fixed: V14R domain PASS markers now require `tb_errors==0`, and
  each mutation requires its own rejection marker plus final `[RESULT] FAIL`.
- Follow-up contract JSON:
  `.github/task-runs/2026-08-04-rv64-v14r-memory-request-admission-hold/subagent-contracts/v14r-oracle-followup-review-v3.json`
- Follow-up contract JSON SHA-256:
  `5ad7a927a4f8b42f8e53f6042c9c55b97ceece88268c3aa31c125cbd3c98fe35`.
- WSL single-flight ownership: transferred only for the bounded v3 oracle review; no RTL semantic,
  workload, synthesis or STA action is authorized.

## v3 closeout

- v3 reviewer returned WSL single-flight ownership and issued `PASS` only for the focused V14R
  verification oracle. The report is retained at `evidence/oracle-followup-review-v3.md`.
- The review bound 2/2 positive results, four independent compile-success mutations with exact
  rejection markers and final FAIL, absence of a positive domain PASS in the single-bank negative
  log, identical production manifests, and zero retained build/VVP artifacts.
- CoreMark, current `ARCH_STABLE`, same-design performance, synthesis, STA, power and PPA remain
  outside this verdict and keep their recorded GAP/UNQUALIFIED status.
