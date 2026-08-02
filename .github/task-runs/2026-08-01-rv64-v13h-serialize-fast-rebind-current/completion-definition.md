# V13H completion definition — current-design serialize fast rebind

## Round classification and starting state

- Primary classification: `verification`.
- Secondary classification: `documentation-or-metadata-only` for task-run, architecture-debt
  binding and memory updates.
- Production RTL modification: none planned.
- Scope: `SERIALIZE-G1` queue-head CSR C0/C1/C2 and pending-SYSTEM C0/C1/C2/consumer binding.
- Branch / HEAD at start: `ai` / `dc027b3988777cba9fdb2200d721d24bba6368fc`.
- Worktree: shared and heavily dirty from prior retained RTL/TB changes plus intentional tracked
  artifact deletions. This round will not reset, restore, stash, clean, switch branch or commit.
- Expected current production design-id:
  `sha256:364b1e601773c22ab0594950170674ea6b228bf6b4c9b2c26b0bdcc9a4374d44`;
  the runners must recompute and bind it independently.
- Original evidence: V12C fast gates PASS at design-id
  `sha256:882111fb3d58039cb7414e6331dac0c10d848463df2228dff93ae22dafbed67b`;
  A3 remains a complete historical DUT transaction with legacy-oracle FAIL and versioned replay.
- Debt: `SERIALIZE-G1`, priority P1, current status `STALE_EVIDENCE`.
- Promotion at start: architecture freeze GAP, PPA UNPROMOTED, current system transaction absent.

## Semantic delta and falsifiable experiment

Since V12C, active production RTL has changed through the retained StoreQueue, LoadQueue and
IntIssueQueue mechanisms. The serialize owner modules and product queue-head configuration are
not intentionally changed by V13H, but old execution evidence cannot bind the current design-id.

- Main hypothesis: the queue-local V13A/V13B/V13G mechanisms preserve the existing serialize
  C0/C1/C2, drain, recovery and consumer contracts, so the unchanged V12C runners pass while
  reporting the current design-id and current compiler dependencies.
- Competing hypothesis: an active queue change alters drain visibility, ready/backpressure,
  kill/recovery interaction or compile input selection, and at least one focused marker,
  assertion, negative mutation or dependency closure fails.
- Highest-information experiment: run the canonical current-source V12C queue-head runner
  (2 positive + 3 compile-success negative profiles), then the pending-SYSTEM runner
  (3 baseline + 15 compile-success negative profiles).
- Observations: design-id, product defines, actual Icarus argv/dependencies, positive terminal
  markers, expected negative rejection markers, assertion outcome and physical cleanup receipt.
- Control variables: same runner source, product defaults, testbench targets and mutation set;
  only the live production source binding and new output directory change.
- Expected wallclock: minutes, below the 30-minute high-cost threshold; estimate confidence
  `MEDIUM` from the prior 23-profile V12C attempt.
- Single-flight: uses the sole Windows→WSL engineering lane; root owns it and launches runners
  sequentially. No second WSL engineering process is permitted.
- Stop condition: stop immediately on runner nonzero exit, source-binding mismatch, unexpected
  assertion/marker, compile-input gap or cleanup failure. Do not continue to a broader cohort
  after a focused failure.
- Lower-cost alternative: source hash comparison alone cannot prove cycle behavior or mutation
  sensitivity, so it is insufficient; no Linux/system run is needed for this fast rebind.

## Test disposition and completion boundary

- V12C queue-head and pending-SYSTEM tests: `KEEP`; architecture contracts are unchanged.
- A3 original status, raw transaction and versioned replay: `KEEP`; do not rerun or relabel.
- A4 interrupted status: `KEEP`; it is not current system PASS evidence.
- V11Y full functional cohort: contract `KEEP`, current binding `NOT_RUN` until separately rerun.
- No test may be deleted, skipped, weakened or have its expected architectural result changed.
- A focused PASS may update the current fast-gate binding, but cannot close `SERIALIZE-G1`:
  a complete current-design system transaction is still absent and a >4-hour launch remains
  unauthorized.
- Required terminal state for this round: focused current-design PASS or an evidence-bound FAIL,
  independent review, compact task-run, evidence index/checksums, memory update and exact cleanup.

## Broader functional currentness decision

The two focused serialize runners passed at the expected current design-id. Before changing the
ledger binding, V13H will also run the existing V11Y complete functional cohort against the same
live design. This is a verification action, not a formal PPA or system-certification action.

- Main hypothesis: the retained queue-local RTL changes preserve all 113 module tests, 177
  official instruction cases, 61 AM cases, architectural reference agreement, CoreMark CRC and
  Dhrystone completion.
- Competing hypothesis: a queue-local timing or recovery change escapes the serialize-directed
  profiles but produces an architectural mismatch in the broader cohort.
- Cost basis: the previous complete cohort took about 570 seconds with `--jobs 2`; this is below
  the 30-minute high-cost threshold and is the cheapest existing current-design closure that can
  falsify the competing hypothesis.
- Execution: build fresh module evidence first, then consume its `result.json` with the complete
  functional runner. Do not use `--publish-current`; all outputs remain task-owned until review.
- Single-flight and stop rule: root keeps sole ownership of the WSL engineering lane; stop after
  any nonzero phase, identity drift, mismatch, missing terminal marker or retention violation.
- Explicit boundary: even a complete functional PASS does not replace a current-design Linux
  system transaction and does not make formal PPA promotion eligible.
