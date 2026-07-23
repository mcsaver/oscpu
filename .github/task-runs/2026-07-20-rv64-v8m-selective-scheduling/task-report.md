# v8m OOO-2 selective-scheduling task report

## Outcome

`OOO-2 selective_scheduling` is scoped GREEN for the current complete RTL
source-set digest and proof provenance.  The architecture remains `OVERALL:
RED`; this task does not authorize PPA work.

No functional RTL was changed.  The production design already preserved an
independent ALU issue path while a registered memory reservation occupied the
Universal terminal.  The defect was an obsolete architecture source predicate
that treated `iq_issue0_ready_w=0` as a global freeze without following issue1.

## Implemented workflow

1. `architecture_hard_gates.py` now audits the complete registered-owner chain:
   backend binding, dispatch/IQ forwarding, selector first-ready-ALU steering,
   IQ issue1-valid independence and backend issue1-ready/fire independence.
2. `tb_ooo_int_backend.sv` establishes a real reservation under
   `mem_req_ready=0`, excludes flush/kill/recovery, and checks exact PC plus full
   ProducerId for both an older independent ALU and a younger independent ALU
   bypassing a dependent ALU and same-resource memory uop.
3. The focused runner exercises release and `OOO_ASSERT` at backend and leaf IQ
   levels, then applies five real-source compile-success mutations in temporary
   files.
4. The evidence builder validates all child markers, mutations and pre/post
   hashes before atomically generating a complete-RTL design binding and exact
   proof/harness provenance.
5. The permanent make entry expects only OOO-2 GREEN and explicitly rejects an
   unexpected architecture-wide GREEN result.
6. The older v8l static runner no longer hardcodes a 15-test architecture
   checker count; it compares the executed count with the discoverable test
   inventory, so adding legitimate checker coverage does not break prior gates.

## Verification

- `make -C npc/rv64 check-selective-scheduling`: PASS.
- Focused baselines: 4/4 (backend + leaf IQ, release + assert).
- Compile-success semantic mutations: 5/5 detected.
- Architecture checker tests: 18/18.
- Fresh module aggregate: 106/106.
- RTL style, ProducerId holder census, check-contract: PASS.
- Immediate assertion inventory: 400 >= 89 baseline.
- Full lint: inherited rc=2 / 115 warnings; recorded as an unchanged signature,
  not as PASS.
- Architecture inventory: OOO-2 GREEN; all other gates RED; OVERALL RED.
- Independent contract and implementation reviews: `pass`; no final blockers or
  false-green findings.

## Workflow persistence and audit

- DB-first retained memory was updated through `update-stored --refresh-shim`,
  snapshotted, and passed `audit-db-first`; the compatibility shims were not
  edited as source-of-truth documents.
- A bounded `npc-dev` brief using the stable terms `selective scheduling`,
  `Universal reservation`, and `issue1` recalled this exact v8m entry from the
  current NPC memory.
- Task-specific e2e runs completed for `npc-dev`, `agent-system`, and
  `github-index`.  The first agent-system attempt is intentionally retained as
  `blocked`: all ten nodes passed, but the mixed NPC/rules slug had no
  independent rules-layer primary.  Re-running with the canonical
  `no-tools-rtl-subagent-contract` terms completed, demonstrating fail-closed
  recall rather than allowing node PASS results to mask a context failure.
- `index-evidence` registered 152 assets for this manual task-run.  The final
  strict guard derived all three required profiles from the dirty worktree and
  passed them with current completed evidence.
- Subagent reviews used self-contained native no-tools contracts.  Their scope
  was stated as local RV64 RTL/proof review, with no network, external target,
  credential, deployment, or unrelated system access.  This is a precise work
  boundary, not a request to bypass platform review.

## Residual risks

- Directed simulation plus structural audit is not a formal proof of every
  queue/backpressure/recovery interleaving.
- Actual-source mutations cover the five cross-layer links, but not yet a
  one-to-one mutation for the arbitrary-older-valid predicate and every
  valid/ready/fire subcondition.
- The inherited lint warnings require later attribution or cleanup before any
  architecture/PPA promotion.
- Remaining DI/OOO gates are independent architecture work, not implied by this
  scoped result.

## Next architecture boundary

Continue from the current hard-gate inventory.  Select the next atomic slice by
checking real RTL feasibility first; do not begin PPA while any DI/OOO gate is
RED.  OOO-1 directed long-latency bypass evidence and the OOO-3 real load-queue
depth are candidate investigations, not yet GREEN claims.
