# V14X SQ/AMO held-launch lease evidence index

## Result

- Bounded holder/receipt slice: `PASS`.
- Immutable predecessor V14W system run: `FAIL`; the historical source-loss assertion is retained unchanged.
- Current-design aggregate contract: `GAP` because the producer-holder graph/census/Yosys receipt is stale.
- Repaired full-system replay and synthesis/STA/power/PPA: not run and not claimed.

## Retained compact evidence

| Evidence | Result | Retained pointer |
| --- | --- | --- |
| Candidate gate summary | PASS | `agent-flow-result.md` |
| SQ/AMO holder focused/link gate | PASS | `agent-flow-logs/rv64-memory-request-hold-link.txt` |
| Terminal collector lane contract | PASS | `agent-flow-logs/rv64-terminal-collector-lane-contract.txt` |
| Changed RTL/TB/spec/runner paths | recorded | `agent-flow-changed-paths.tsv` |
| Engineering decision trace | recorded | `agent-flow-decision-trace.tsv` |
| Evidence status/pointers | recorded | `agent-flow-evidence.tsv` |
| Review dispatch and contract hashes | recorded | `dispatch-log.md` |

The focused/link receipt reports `RESULT=PASS`, `TIER=link`, `MUTATION_TOTAL=6`,
`BUILD_RETAINED=0`, `CLEANUP=PASS` and manifest SHA-256
`d0c57e829352d68c59fbfc0a50d2ca7876390fda2bfa76c95cc4a5723e70b7d4`.

## Review conclusions

- Independent review v1 found no blocker in the holder RTL slice and preserved the aggregate-contract GAP.
- Candidate review v2 found no holder/receipt blocker. It confirmed exact resident source plus
  tracker/PID/ROB-head-owner authorization, common effective selector/fire, six rejected negative RTL variants,
  unchanged fail-loud source-loss behavior and fail-closed result publication.
- Review contracts are retained under `subagent-contracts/`; their SHA-256 values are recorded in
  `dispatch-log.md`. Detailed raw/focused/static logs remain local under `evidence/` and are intentionally excluded
  from the source index; the compact gate logs and conclusions above are the versioned audit surface.

## Next qualification scope

Rebind the current producer-holder graph/census/Yosys receipt, then run the repaired full-system
selective-recovery workload. Only after those complete may architecture-current or PPA qualification advance.
