# NPC RV64 PPA promotion contract

This directory is the canonical, fail-closed promotion interface for the RV64
dual-issue out-of-order core. Functional, architectural, evidence, and timing
gates are evaluated before any balanced score. A score can never compensate
for a failed hard gate or a regressed qualified axis.

## Claim tiers

- proxy_champion compares fixed-image performance and logic-area proxy. Power
  is not scored, even if a vectorless estimate is present.
- final_champion compares performance, total area including macros, and
  workload-activity total power including macros. All three axes must be
  qualified.

Neither tier permits an automatic tradeoff replacement. A candidate must meet
every policy floor, dominate the accepted baseline on all qualified axes within
the configured Pareto epsilon, exceed the balanced-score threshold, and remain
on the global candidate-set Pareto front.

## One-time architecture-feasible seed

R3.6 is an architecture-infeasible measurement anchor, not an accepted
baseline: it has one complete memory issue/AGU/translation/order/cache owner
and all nine architecture gates remain RED. The first design that restores the
mandatory architecture therefore uses one narrowly scoped transition:

- the normal checker must pass all functional evidence and all nine executable
  architecture gates;
- each benchmark must retain at least 0.995 of R3.6 throughput with equal
  fixed-image region retired counts;
- exact-5ns worst slack is at least +0.10 ns, with nonnegative WNS, zero TNS,
  zero violating paths, and zero combinational loops;
- logic area is at most 1.10 times R3.6, exactly 1766384.312 in the current
  proxy area units.

Only this transition waives baseline dominance and the 0.999 area-efficiency
floor. It is not a second promotion policy. Once the index names a seed, a
second seed transition is rejected and normal dominance, 0.999 area efficiency,
per-benchmark floors, and global-front rules apply again.

Power is fail-closed by claim tier. Unqualified power may produce only an
`architecture_feasible_seed`; it cannot be front-accepted, canonical, or a PPA
champion. A power-qualified seed with qualified macro-inclusive total area may
become the initial feasible comparison baseline, but the transition itself
never calls that design a champion.

If the recorded seed is still power- or total-area-unqualified, later designs
are engineering comparisons only. A formal front remains unavailable until
that same seed is qualified; another seed cannot be used to bypass the rule.

Evaluate the transition with:

    python3 npc/rv64/eval/ppa/tools/architecture_seed.py \
      npc/rv64/eval/ppa/baselines/r3p6-recovery-baseline.json \
      candidate.json

Add `--require-front-baseline` to fail unless both power and macro-inclusive
total area are qualified as well. `--report-only` never suppresses structural
errors.

## Performance evidence schema

A promotable manifest must declare
`performance.evidence_schema = npc-rv64-performance-evidence-v3`. The
promotion policy selects a fixed committed-PC region for both benchmarks. It
has no global `performance.cpi_scope`: each benchmark summary and repetition
declares its own `counter_scope`, and mixing whole-program and region counters
is a structural error. The parser retains explicit v2 compatibility for old
CoreMark whole-program evidence, but v2 is not selectable by this promotion
policy.

Every benchmark has at least three repetitions. Each repetition contains
positive integer `cycles` and `retired_instructions`, and binds one raw log
with both `raw_log_artifact_kind` and `raw_log_artifact_path`. Kinds and paths
cannot be reused by another repetition. The paths must resolve to the matching
artifact records, and the policy makes all six current raw-log kinds mandatory.
Deterministic repetitions may have identical content SHA-256 values; that does
not permit reusing an artifact kind or path. Candidate/accepted evidence must
also list every raw-log member in the `design_binding_manifest.artifacts` map,
as required by the existing exact-membership binding check.

Every raw log is parsed independently as bounded UTF-8 evidence with exactly
one benchmark PASS marker, one GOOD TRAP, one authoritative
`report_run_result`, and a zero exit code. Both benchmarks use
`counter_scope = pc_bounded_region_v1`:

- CoreMark starts at `0x00000000800017a8` and stops at
  `0x00000000800017b0`. The captured start is the first committed hit, and the
  result must report `start_hits=1` and `end_hits=1`. `Iterations=10` and
  `crcfinal=0xfcaf` must match the functional summary in all three logs.
- Dhrystone starts at `0x0000000080000334` and stops at
  `0x000000008000047c`. The captured start is the first committed hit, and the
  result must report `start_hits=10000` and `end_hits=1`. The run count must be
  10000 in all three logs.

For each log, the unique start boundary, unique `kind=end` stop boundary, and
unique region `RESULT` must agree. Selected cycles and retired instructions are
exactly `stop-start`; they must match the repetition and benchmark summary, and
the three selected counter pairs must be bit-exact.

Whole-program exit counters remain mandatory only for semantic and termination
validation: PASS, exactly one GOOD TRAP, zero exit, CoreMark CRC/iteration
checks, Dhrystone run-count checks, and a nonnegative dynamic-tail diagnostic.
Post-region tail cycles or retired instructions may differ between designs.
Whole-program counters never feed CPI, IPC, throughput, repetition equality, or
selected retired-instruction equality under v3.

Missing raw logs remain explicit promotion blockers. Malformed, duplicate,
missing, or ambiguous markers, nonzero exits, semantic/counter/scope mismatches,
hash failures, and workspace-escaping or symlink paths are structural errors.
Report-only mode does not suppress structural errors.

## Checker

Strict checking is the default:

    python3 npc/rv64/eval/ppa/tools/check.py candidate.json
    python3 npc/rv64/eval/ppa/tools/check.py candidate.json --require-promotable
    python3 npc/rv64/eval/ppa/tools/check.py baseline.json --require-accepted

Structural errors always return nonzero. Promotion blockers also return
nonzero unless report-only is explicitly requested:

    python3 npc/rv64/eval/ppa/tools/check.py provisional.json --report-only

The report-only flag never converts a structural error into success.

`baselines/index.json` deliberately leaves `canonical` unset until one design
satisfies every fail-closed hard gate and the applicable power claim boundary.
Its `engineering_recovery_baseline`
field names the exact same-image P/A plus 5 ns proxy point used for the next
optimization round; that field does not make the design architecture-feasible
or promotable. `architecture_feasible_seed` stays null until the one-time
transition is recorded. Historical and provisional points remain diagnostic
only.

`implementation_correctness_checkpoints` is a separate, non-Pareto inventory.
An entry there records a measured semantic or timing floor such as R4-S0 or
R4-P0A, but it cannot replace `engineering_recovery_baseline`, fill
`architecture_feasible_seed`, enter a Pareto front, become canonical, or be
called a champion. Every checkpoint must say `promotable=false`, enumerate its
RED architecture and unqualified-power gates, and distinguish diagnostic
measurements from promotion-grade same-image evidence. In particular, P0A's
image-bound A-B-B-A-A-B counters and +0.103599802 ns exact-5ns reserve strengthen
that checkpoint only: all nine architecture gates are still RED and Power is
still unqualified, so neither result creates a seed or a promotion candidate.

Architecture promotion is likewise not based on manifest booleans. The policy
requires all nine per-gate artifacts, one `architecture_directed_suite`, and
one `architecture_hard_gates_result`. The checker re-runs the executable gate
evaluator against the suite and live RTL, then compares the archived result
with that independent evaluation. DI-1 through DI-5 and OOO-1 through OOO-4
must all be GREEN. In particular, long-latency bypass requires a ROB peak of
at least nine entries: the blocked old instruction plus eight younger
instructions that complete before it.

## Pairwise diagnostic

    python3 npc/rv64/eval/ppa/tools/compare.py       accepted.json candidate.json --require-pairwise-eligible

Pairwise eligibility means the candidate passed checker audit, per-benchmark
and per-axis floors, timing, score, and candidate-dominates-baseline. It is not
a global promotion claim. The legacy --require-promotable option intentionally
returns nonzero and directs callers to front.py. The JSON output always sets
global_pareto_audited and eligible_for_target_promotion to false.

## Global Pareto promotion

Supply the complete same-policy, same-cohort candidate set, with exactly one
accepted baseline and one or more candidate manifests:

    python3 npc/rv64/eval/ppa/tools/front.py       accepted.json candidate-a.json candidate-b.json       --target proxy_champion       --require-winner candidate-a-id

front.py audits every manifest, verifies fixed input artifacts, computes the
global Pareto front, eliminates candidates dominated by any third design, and
chooses the highest balanced-score member among candidates that also dominate
the accepted baseline. The --require-winner gate returns nonzero unless the
named candidate is the selected winner.

Without --require-winner, front.py is still strict and returns nonzero when no
eligible winner exists. Use --report-only for an explicit non-gating front
report.

## Regression tests

    python3 -m unittest discover       -s npc/rv64/eval/ppa/tests -p 'test_*.py' -v

The regression includes three formerly score-eligible counterexamples:

1. performance hiding a 9 percent area regression;
2. performance and area hiding a 2x power regression;
3. geometric-mean performance hiding a 2x CoreMark regression.

All three must remain rejected.

It also locks the one-time seed thresholds, rejects a second seed, proves that
unqualified power cannot grant accepted/canonical/champion status, and verifies
that the normal dominance and 0.999 area-efficiency ratchets remain unchanged.
