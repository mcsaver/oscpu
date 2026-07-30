# V11H dispatch log

1. Main node initially classified the round as verification with
   tooling/evidence publication, selected `load-queue-producers`, and froze
   H1/H2/H3.
2. The V8V nine-variant result was audited as compile-success dynamic evidence,
   but its runs used the default assertion-enabled build and did not provide a
   stimulus-owned raw-Q knownness oracle.
3. Main node prepared and validated the canonical pre-review contract:
   contract SHA-256
   `4217b1131e3a87060f5960d3236c614781ec0aa22c30e9c4dccd078af8030d63`;
   rendered SHA-256
   `853a0de6a6f51dd997696dbc42808f3c0c4942db19c701aa346ec505519a53cc`.
4. Isolated reviewer selected H2: a normal terminal may precede completion;
   a following selective/global recovery turned the entry into a killed
   tombstone even though the exact terminal had already occurred, leaving a
   permanent live holder with no future terminal.
5. Pre-fix discriminator compiled with rc=0 and failed with rc=1 at
   `[V11H-LQ-PRIOR-TERMINAL-RECOVERY][FAIL] count=1 live=1 killed=1`.
6. Production `OooLoadQueue.v` added `terminal_seen_q[]`; post-fix discriminator
   reports `prior_terminal=1 recovery_clear=1 ghost=0 PASS`. Classification
   changed from verification to architecture.
7. Focused attempt-1 stayed FAIL because one checker mutation generated
   malformed `&& &&`; attempt-2 completed 4 profiles and 62 negative
   simulations but stayed FAIL because the V11A instance graph was stale.
8. A versioned V11H `NpcTop` instance graph was freshly elaborated at
   design-id
   `sha256:402dca12de007136044cae4c56ddbb633529bb014eabc37784a86257299fab93`.
   The first graph runner replay preserved FAIL at `final-cleanup`; the
   corrected replay is PASS with 15 holder modules, 17 instances and 194
   reachable instances.
9. Focused attempt-3 completed 4 positive profiles and 31×2 compile-success
   negative RTL simulations. It preserved FAIL at `semantic-ledger-unit`
   because the old checker required every historical unit to match the full
   current design-id.
10. The checker now distinguishes `CURRENT_FULL_RTL_BOUND`,
    `CURRENT_SELECTED_SOURCE_AND_TB_BOUND` and historical evidence. V11B–V11G
    can replay only when their exact RTL/TB closure remains byte-identical;
    V8L is historical and cannot be confused with current evidence.
11. The independent attempt-3 checker replay preserves the original FAIL,
    reuses frozen simulation inputs without RTL reexecution, and passes replay
    builder 5/5, LoadQueue evidence checker 8/8 and semantic ledger 21/21.
12. Ordinary regression attempt-1 preserved FAIL because its result filter
    misclassified legal `[V8V-LQ-*] ... PASS` coverage markers. Attempt-2
    passes `tb_ooo_load_queue` and parent `tb_ooo_int_backend` with assertions
    enabled, no `[V11H-LQ-DUP-TERMINAL]`, and identical RTL pre/post binding.
13. Current architecture hard gates remain RED. The directed-suite manifest
    is bound to the pre-V11H design and old Makefile provenance; no PPA or
    system-level promotion is claimed.
14. The first final-review contract generator attempt failed before emitting
    a contract because `git`/`jq` lacked canonical read-command purposes. A
    corrected v2 contract was created, validated and rendered without
    widening the read-only command set.
15. Independent final review v2 returned GAP with two blockers: production
    RTL lacked `valid_q => full producer_id_q known` raw-Q assertion, and the
    attempt-3 `scope.system_rerun` string conflicted with the required
    system-promotion boundary while both V11H checkers ignored that field.
16. `OooLoadQueue` now asserts raw-Q full-PID knownness at
    `[V11H-LQ-PID-KNOWN]`. The semantic TB injects an unknown generation with
    assertions enabled and observes that exact marker; legal profiles remain
    PASS.
17. Current graph v2 initialization preserved a stale census/config FAIL.
    Its first replay also preserved a census-unit FAIL because the checker
    still required the old canonical path. After versioning the canonical
    path, graph v2 is PASS at design-id
    `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`
    with the unchanged 15/17/194 topology.
18. Focused attempt-4 completed 4 positive profiles, one raw-Q assertion
    probe and 31×2 assertion-off negative simulations. The original runner
    remains FAIL at `semantic-ledger-unit` because the corrected checker
    omitted a local `assertion_probe` variable binding after summary
    publication.
19. The attempt-4 frozen-input checker replay preserves that FAIL, performs
    no RTL simulation reexecution, and passes replay builder 5/5, LoadQueue
    evidence checker 10/10 and semantic ledger 24/24. The exact scope requires
    a system rerun before system promotion and records that it has not run.
20. Ordinary regression attempt-3 passes both `tb_ooo_load_queue` and parent
    `tb_ooo_int_backend`; neither `[V11H-LQ-PID-KNOWN]` nor
    `[V11H-LQ-DUP-TERMINAL]` appears. Current architecture hard gates remain
    RED, so PPA is still unpromoted.
21. Versioned final-review v3 contract SHA-256
    `582fcdbe4857a743d7ed96a7a80697bf112e6124dba0491288f76c3408cc10da`
    was validated and dispatched with isolated context. The independent
    reviewer returned bounded APPROVE for `load-queue-producers`, blocker=0,
    and explicitly retained system `REQUIRED_NOT_RUN`, architecture RED and
    PPA UNPROMOTED.
22. Retained project/NPC/agent-system memory was published before environment
    dispatch. The first broad bounded brief remained a fail-closed ordering
    counterexample; the exact V11H profile terms then returned
    `recall_status=complete`.
23. Current-source `npc-dev`
    `2026-07-30-semantic-replay-attempt-revtag-v11h` completed 5/5 and
    `agent-system` `2026-07-30-loadqueue-attempt-revtag-v11h` completed
    11/11. Both task-runs have valid DB publication markers.
24. Full-worktree strict guard retained rc=1 only for the unrelated shared
    `rv64-linux` profile. A first scoped invocation preserved an
    `--evidence-dir` invocation error; the corrected 19-path scoped strict
    guard explicitly consumed both V11H task-run roots and passed
    `npc-dev` plus `agent-system` without weakening the gate.
25. Stored snapshot, DB-first audit, Markdown coverage and both task-run
    runtime-artifact audits passed. Final RTL identity and 39 checker units
    remained unchanged. The mixed worktree commit gate observed 258 tracked
    changes, 1,745 untracked files and one unrelated staged profile, so no
    stage or commit was performed.
26. Publishing the post-review environment memory made the first
    `agent-system` task-run older than that retained input. Fresh task-run
    `2026-07-30-loadqueue-closure-revtag-v11h` completed 11/11; the final
    19-path scoped strict guard consumed it with the unchanged `npc-dev`
    evidence and passed. Full-worktree strict inspected 2,013 files and still
    retained only the unrelated `rv64-linux` GAP. Final commit-gate count is
    258 tracked changes, 1,755 untracked files and one unrelated staged file.
