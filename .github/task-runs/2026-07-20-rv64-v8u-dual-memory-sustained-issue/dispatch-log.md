# v8u/F4 dispatch log

## v8u_f4_contract_review

- Mode: `self-contained-no-tools`, read-only microarchitecture contract review.
- Contract JSON: `subagent-contracts/v8u_f4_contract_review.json`
- Contract SHA-256: `a200949062219b136771bbaa12877aa0bc78529d6cc5484db27e45a5dce35dd9`
- Result: FAIL on contract completeness, not an RTL verdict.
- Incorporated blockers: per-bank pop cardinality, current A full identity/effective-kill gate,
  lookup capture semantics, kill-over-result, and B-promotion/C-refill ownership.

## v8u_f4_implementation_and_evidence

- Mode: main-agent local RV64 RTL implementation and fail-closed verification.
- Result: `make -C npc/rv64 check-dual-memory-sustained-issue` PASS.
- Run ID: `v8u-f4-20260720T162308Z-1289228`.
- Evidence: 64 steady cycles, IPC 2.000, all five per-bank transaction faces 64/64, 7/7
  compile-success mutations rejected, baseline `UNOPTFLAT=0`.
- Architecture: DI-5 GREEN on the same full RTL digest; OVERALL remains RED and PPA unqualified.

## v8u_f4_final_independent_review

- Mode: validated self-contained-no-tools read-only review.
- Contract: `subagent-contracts/v8u-f4-final-independent-review.json`.
- Contract SHA-256: `eb05ea2eccb1768d922dc74c75d8ef7cfcd4f09bf8793b44b2a5d2fe296581f6`.
- Result: `PASS_WITH_EVIDENCE_BOUNDARY`; requested explicit PID/READY/partial/wrap/mutation mapping.
- Action: generated a versioned v2 contract rather than expanding the old contract orally.

## v8u_f4_final_independent_rereview_v2

- Mode: validated self-contained-no-tools read-only rereview.
- Contract: `subagent-contracts/v8u-f4-final-independent-rereview-v2.json`.
- Contract SHA-256: `44630617d970b7a771e81ef6eccb7602df7ed3887329af1ca204c77af7a32b99`.
- Result: local DI-5 PASS with medium-high confidence and no unresolved DI-5 blocker.
- Remaining scope: cross-product stress and stronger PID/long-wrap mutations; DI-1/DI-2/OOO-3/
  OOO-4, shared-miss throughput and PPA remain outside this verdict.
