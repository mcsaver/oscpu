# V11I test-disposition final review v3

## Disposition

`UNKNOWN_PENDING_REVIEW` / GAP / blocker=2.

## RV64 testbench findings

The reviewer independently supports the seven row-level classifications:

- six existing regression modes are `KEEP`;
- `tb_ooo_mem_owner_tracker.sv` plus its unchanged semantic checker is `REBIND`
  because only the Makefile source binding changed.

All old/new test SHA values were confirmed. Layered-attempt-1 retains the tracker
`Unknown module type`, compile rc=2 and `[RESULT] FAIL`; layered-attempt-2 binds
seven recomputed log hashes and 7/7 PASS. No checker accepted set or expected
architectural result changed.

## Blockers found

1. `test-disposition.md` described the V11I branch as a plusarg. The real isolation
   mechanism is the compile define `-DV11I_TERMINAL_LIFECYCLE_FOCUSED`; default
   and V8X compile commands do not contain that define.
2. Immutable attempt-9 `summary.json` SHA-256 prefix `3c4d536f` records lane6 in
   `contract.testbench_observation`, while its mutation receipts, TB and raw logs
   are lane0. The internal mismatch prevents complete evidence binding.

## Required closure

- preserve attempt-9 unchanged;
- correct the permanent runner to emit the lane0 response-terminal contract;
- make the independent validator reject lane6 and missing focused-define
  provenance;
- generate a new versioned evidence attempt and independently review it.

Contract SHA-256:
`f4e6bd566dbcb67f0276455b3e01de22c9e4849c712a7ce68b771d2123731679`.
The reviewer modified no files and returned WSL shell ownership.

