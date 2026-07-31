# V11I evidence attempt ledger

| attempt | status | RV64 object / observation | disposition |
| --- | --- | --- | --- |
| terminal-lifecycle-1 | FAIL | TB elaboration could not resolve the local LQ entry-count name | preserved; fixed with a TB-local value derived from `ROB_INDEX_W` |
| terminal-lifecycle-2 | FAIL (3/4) | production assert/release and stale assert passed; release raw-Q oracle sampled collector dequeue one edge early | preserved; corrected only the observation edge |
| terminal-lifecycle-3 | PASS | lane6 reservation-terminal token wrap matrix 4/4 | valid intermediate evidence; superseded by response-lane coverage |
| terminal-lifecycle-4 | PASS | same lane6 matrix through the permanent Make entry | valid intermediate evidence; superseded |
| terminal-lifecycle-5 | PASS | old owners changed to request/MIQ/response lane0; matrix 4/4 | valid intermediate evidence before final raw-file validator |
| terminal-lifecycle-6 | PASS | lane0 matrix after tracker semantic-checker filelist repair | valid intermediate evidence |
| terminal-lifecycle-7 | PASS | lane0 matrix with per-profile raw artifact hashes | valid intermediate evidence |
| terminal-lifecycle-8 | PASS | independent evidence validator added | valid intermediate evidence |
| terminal-lifecycle-9 | PASS with evidence-binding GAP | lane0 matrix is 4/4, but immutable `contract.testbench_observation` still says lane6; current validator rejects it | preserved; superseded without rewriting |
| terminal-lifecycle-10 | PASS with checker-test GAP | lane0 response-terminal contract and 4/4 matrix are valid, but the missing-focused-define negative test rejected the fixture path before the intended field check | preserved; superseded without rewriting |
| terminal-lifecycle-11 | PASS | lane0 contract, exact compile-define provenance, targeted missing-define error, 4/4 matrix, runner 6/6 and validator 8/8 | current selected evidence; final review pending |
| layered-regression-1 | FAIL | collector PASS; tracker elaboration lacked `tb_ooo_mem_owner_tracker_semantic_checker.sv` in Make sources | preserved; root cause was verification filelist |
| layered-regression-2 | PASS (7/7) | collector, tracker, LQ, ordinary parent, bridge, dual wrapper and V8X parent recovery | current layered evidence |

No failed or superseded directory, log, status, or summary was rewritten.
