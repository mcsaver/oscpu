# V11I terminal lifecycle task report

> Current state: **PASS / APPROVED_FOR_CURRENT_SCOPE**  
> Production RTL changed by V11I: **no**  
> Full-system run launched by V11I: **no**

## Outcome

The local RV64 terminal lifecycle now has current-design evidence across a complete
32-token tracker wrap. Thirty-two LOADs complete through request/MIQ/response lane0;
token0 then binds a different full ProducerId while its reservation and LQ entry stay
live. Production assertions-on/off remain quiet and preserve the new owner.

The generated compile-success stale-response copy demonstrates sensitivity without
changing production RTL:

- assertions-on rejects the accepted old tuple at
  `[V9Y-HOLDER-TERMINAL-NEXT]`;
- assertions-off independently observes the new tracker lease freed and the new
  LQ PID marked terminal, then emits `[V11I-LATE-TUPLE-ABA][FAIL]`.

No deduplication path was added and no assertion was weakened.

## Selected evidence

- Matrix: `evidence/terminal-lifecycle-attempt-11/summary.json` — selected 4/4
  profiles PASS.
- Independent validation:
  `evidence/terminal-lifecycle-attempt-11/validation-receipt.json` — PASS.
- Runner classifier tests: 6/6 PASS.
- Evidence-validator positive/negative tests: 8/8 PASS, including lane6
  contract drift and missing focused compile-define rejection.
- Layered regression:
  `evidence/layered-regression-attempt-2/summary.json` — 7/7 PASS.
- Canonical design-id:
  `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`.
- Full failure/supersession history: `attempt-ledger.md`.

## A3 and current system boundary

A3 remains untouched: original strict `16/17`, `rc=1`, and
`dmesg-no-critical` FAIL are retained; its frozen-input checker replay remains the
separate PASS receipt proving that `printk: debug:` is accepted while true `BUG:`
is rejected. V11I introduces no new system-rerun trigger. Because V11H had already
changed production `OooLoadQueue` semantics, however, old A3 is not current-design
system-promotion evidence; a future full current-design run is still required before
system promotion and was not started here.

## Scope

The result is limited to the current local terminal source, collector, tracker and
LQ contract. Global no-live-reuse remains incomplete; whole architecture and PPA
remain unpromoted. Independent final review v5 returned bounded APPROVE with
`blocker=0`; see `final-review-v5-result.md`.

## Independent reviewer

- H1 confirmed for current production RTL: lane0 response fire and MIQ pop end the
  old source lifetime on the same edge; no hidden stale-tuple state was found.
- H2 remains a compile-success mutation-only local consequence and is rejected in
  assertions-on/off configurations by independent observations.
- H3 remains excluded by edge-old tracker allocation and LQ PID sampling.
- Final v5 disposition: `APPROVED_FOR_CURRENT_SCOPE`;
  `scope_extension_request=none`; confidence high.

## Existing-test disposition

The new goal-level disposition gate is recorded in `test-disposition.md`.
Production semantics are unchanged. Six existing regression modes are `KEEP`; the
owner-tracker test is `REBIND` because only its missing semantic-checker source
binding was repaired. No expected architectural result or checker acceptance set
was changed. Independent disposition review v3 supports those row-level
classifications but found two evidence-binding blockers: attempt-9 retains a stale
lane6 contract field although the receipts are lane0, and this report originally
described compile-define isolation as a plusarg. The document-level disposition is
therefore `UNKNOWN_PENDING_REVIEW`. Both implementation blockers are now
fixed without rewriting attempt-9: attempt-10 records the exact lane0
response-terminal contract, and the validator checks each profile's
focused/assert/mutation compile defines. Independent review v4 confirmed those
bindings and all seven row-level dispositions, but found the missing-focused-define
test rejected a noncanonical commands filename before reaching the intended field
check. The document-level disposition remains `UNKNOWN_PENDING_REVIEW` until the
fixture retains `/commands.json`, asserts the exact error, and a new versioned
attempt is independently reviewed. Attempt-11 implements that correction and binds
the exact target error. Final review v5 independently closed the false-green
counterexample; the document-level state is no longer `UNKNOWN_PENDING_REVIEW`.
The final row-level disposition is six `KEEP` plus tracker `REBIND`, with no
`UPDATE_CONTRACT`, `OBSOLETE_WITH_EVIDENCE`, `RTL_REGRESSION` or unresolved
`UNKNOWN_PENDING_REVIEW`.

## AI workflow evidence

- A bounded `brief V11I --profile npc-dev --focus-scope non-history` recalled the
  current NPC memory. Two earlier longer-term briefs remain recorded as failed
  primary-focus matches; they were not relabeled PASS.
- The first `npc-dev` task-run,
  `2026-07-30-rv64-v11i-terminal-lifecycle-attempt11`, retained its blocked result:
  all five profile nodes passed, but the expanded task-slug terms did not obtain an
  independent non-history focus chunk. Reusing the exact hardware tag `v11i`
  produced completed run `2026-07-30-v11i` with 5/5 nodes PASS.
- The first `agent-system` run, `2026-07-30-v11i-2`, retained its blocked result:
  `three-layer-contract` found eight V11I task-run Markdown files still live-only.
  `archive-markdown --sync-task-run` then stored all 14 Markdown records without
  rewriting their content or status, and `audit-markdown-coverage` reported
  `live_evidence=0`.
- The subsequent `agent-system` run, `2026-07-30-v11i-3`, completed 11/11 nodes.
  These workflow gates do not replace the RTL/TB evidence matrix and do not promote
  system, architecture or PPA scope.
