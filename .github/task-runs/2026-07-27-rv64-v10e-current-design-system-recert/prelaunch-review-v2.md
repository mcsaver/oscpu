# V10E pre-launch review v2

## Conclusion

`GAP`: V1 define/rootfs/immutable-input fixes are valid, but status
publication, cleanup, evidence-query and launcher failure paths still admit
false-green or stale-`RUNNING` counterexamples.

Contract JSON:
`.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/subagent-contracts/v10e_runner_prelaunch_review_v2.json`

Contract SHA-256:
`9ea21c8a9a038762e9817ef40c0ddd7f822efcff11cfad844b41c223b58ecbb6`

## Counterexamples

1. A failed `_task_run_status_write "PASS"` returned zero.
2. Cleanup cleared signal traps before post hashes and config restoration.
3. Failure to create `post-binding.txt` was not merged into `cleanup_rc`.
4. `rg` return codes above one were accepted as an empty assertion file or no
   UART event.
5. Runtime guest checker, transaction parser and rootfs helper had only a
   pre-run hash.
6. Two launchers could pass a short lock probe; the losing background child
   exited without publishing `.status`.

## Reconciliation

- PASS write failure now returns non-zero and attempts a FAIL fallback with
  `status_write_rc`;
- cleanup defers and records HUP/INT/TERM until final status publication;
- terminal query and post-binding output return codes feed `cleanup_rc`;
- only `rg rc=1` is accepted as no match; read/tool errors fail;
- all runtime control scripts and immutable boot/config inputs receive
  pre/post hash comparison;
- V10E and V9S background `flock` use contention rc=73, and a child that exits
  before status initialization receives launcher-published FAIL evidence;
- `prelaunch-contract.log` is durable and hash-bound;
- terminal success markers are individually required exactly once;
- 40/40 static negative variants are rejected;
- dynamic fixtures prove PASS-write fallback, global lock exclusion, cleanup
  failure, cleanup TERM, post-binding output failure, `rg rc=2` handling and
  rootfs reuse rejection.

No production Verilog/SystemVerilog file changed. Versioned reviewer v3 must
accept this corrected runner before the 6B-cycle system simulation starts.
