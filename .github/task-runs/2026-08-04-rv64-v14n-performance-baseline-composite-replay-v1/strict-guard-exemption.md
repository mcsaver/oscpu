# V14N strict guard retained failure and scoped exemption

`scripts/agent-e2e.sh --guard --guard-mode strict` was run with the 16 explicit agent-flow paths.
It returned rc=1 because broad `npc-dev` and `agent-system` profile evidence was not present. The
original output is retained in `strict-guard.log`; it is not rewritten or represented as PASS.

Scoped exemption rationale:

- production RTL, elaborated design, simulator, config, workload image, ROI and device/memory timing
  semantics did not change;
- the affected performance-contract/checker surface passed 75 focused policy/checker/schema/publication
  tests, including legacy-v1 rejection, endpoint-capacity corruption, internally conserving but non-bit-exact
  repetitions, stats-off boundary/final mismatch, historical FAIL rewrite, missing/bad postflight and review
  rejection;
- the frozen A2 evidence was processed by a fail-closed six-stage composite replay, and the current
  ARCH_STABLE pointer passed again after publication;
- an isolated workspace-files reviewer first rejected two concrete gaps, then independently approved only
  after the versioned amendment and fresh postflight were bound;
- `.github/memory/modules/agent-system.md` changed only through the DB-backed memory update; no agent policy,
  guard routing, profile, C pointer or e2e implementation changed.

Running broad `npc-dev` would repeat unrelated RTL/DUT coverage and contradict the repository's
deterministic-delivery cost policy. Running broad `agent-system` solely for a memory entry would likewise add
no discriminating evidence. This exemption authorizes only the V14N PERF_BASELINE receipt and does not waive
future RTL, PPA, policy, routing or release gates.
