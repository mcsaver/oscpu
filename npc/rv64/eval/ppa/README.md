# NPC RV64 PPA promotion contract

This directory is the canonical, fail-closed promotion interface for the RV64
dual-issue out-of-order core. Functional, architectural, evidence, and timing
gates are evaluated before any balanced score. A score can never compensate
for a failed hard gate or a regressed qualified axis.

## Full-core architecture-stable audit

正式 PPA 之前先运行本地 RV64 RTL full-core 冻结资格门：

```bash
bash npc/rv64/eval/ppa/run-arch-stable-audit.sh
```

普通模式验证检查器正例/反例、重新生成 exact-input 结果并复核其 digest；当前存在真实架构
债务时命令仍成功交付 `architecture_freeze=GAP`，但绝不授予稳定资格。只有 promotion
入口使用以下命令，且所有 P0/P1、holder census、同源功能 aggregate 和冻结输入全部闭合时
才允许返回成功：

```bash
bash npc/rv64/eval/ppa/run-arch-stable-audit.sh --require-stable
```

机器入口为 `arch-stable/full-core-current.json`，P0/P1 真源为
`../../design/arch/architecture-debt-ledger.json`；`TESTS` 清单由当前
`../../testbench/Makefile` 动态推导，不接受历史固定计数。该门只签发架构稳定 cohort，结果
始终保持 `ppa=UNQUALIFIED`、`promotion_eligible=false`，后续仍需独立建立正式 PPA 基线。

冻结声明与 normative cohort 均使用带 `kind/path/sha256` 的 artifact；config、generated
header、RTL/test filelist、全部 design spec、完整 testbench source/support/runner、EDA 工具
可执行文件及版本输出、Liberty/macro inventory、SDC、程序镜像、仿真器和冻结工作流自身必须
exact-membership 一致。检查器会调用当前架构 hard-gate 与 producer-holder census builder
重算 source closure，不接受仅填写 GREEN/PASS 的摘要。

同源 functional aggregate 必须逐项绑定模块测试的 compile/simulation rc 与唯一 PASS 原始日志；
official 177/177、当前 AM CPU-test 源目录的动态 exact inventory 全部 PASS、DiffTest mismatch=0、CoreMark 10 次且 CRC `0xfcaf`、
Dhrystone 10000 次及 GOOD TRAP 均需绑定冻结 config/simulator/image 和原始日志。测试清单比较采用
无重复的 exact set，不把合法的清单排序差异误判为功能变化。每个语义 marker 必须作为完整行
恰好出现一次；空日志、重复 marker、非 canonical 路径，以及通过 symlink、hardlink 或等价
device/inode 身份复用同一日志文件，均按结构错误拒绝。

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
`performance.evidence_schema = npc-rv64-performance-evidence-v8`. The
promotion policy selects a fixed committed-PC region for both benchmarks. It
has no global `performance.cpi_scope`: each benchmark summary and repetition
declares its own `counter_scope`, and mixing whole-program and region counters
is a structural error. The parser retains explicit v2 compatibility for old
CoreMark whole-program evidence, but v2 is not selectable by this promotion
policy.

The policy binds both
`design/arch/performance-measurement-contract-v1.json` and
`design/arch/performance-counter-schema-v4.json` by canonical workspace path,
ID, and SHA-256.  The latter is intentionally named
`PARTIAL_CONSERVING_MEMORY_REQUEST_DETAIL_V4`: it is a mutually-exclusive cycle
and two-lane retirement-slot ledger with a full-`ProducerId` ROB-head split, an
exact-token memory holder split, and a conserving request-phase subledger; it
is not yet the final frontend and global issue-terminal causal CPI stack.

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
`report_run_result`, one termination-time region `FINAL`, one termination-time
`COUNTERS_FINAL`, and a zero exit code. Both benchmarks use
`counter_scope = pc_bounded_region_v1`:

- CoreMark starts at `0x00000000800017a8` and stops at
  `0x00000000800017b0`. The captured start is the first committed hit, and the
  termination-time `FINAL` must report `start_hits=1` and `end_hits=1`.
  `Iterations=10` and
  `crcfinal=0xfcaf` must match the functional summary in all three logs.
- Dhrystone starts at `0x0000000080000334` and stops at
  `0x000000008000047c`. The captured start is the first committed hit, and the
  termination-time `FINAL` must report `start_hits=10000` and `end_hits=1`.
  The run count must be
  10000 in all three logs.

For each log, the unique start boundary, unique `kind=end` stop boundary, and
unique region `FINAL` must agree. `FINAL` is emitted only when the simulator
run terminates, carries the final marker-hit totals, requires
`schema=npc-rv64-region-final-v1`,
`counter_scope=pc_bounded_region_v1`, `complete=1`, and
`termination_rc=0`. An early legacy `RESULT` cannot substitute for `FINAL`.
Selected cycles and retired instructions are exactly `stop-start`; they must
match the repetition and benchmark summary, and the three selected counter
pairs must be bit-exact.

`COUNTERS_FINAL` requires
`schema=npc-rv64-performance-counter-v4`, `complete=1`, `available=1`,
`overflow=0`, `invalid_events=0`, and `conservation=1`. Cycle reasons are
mutually exclusive and sum to region cycles. The compatibility aggregate
`head_not_complete` must equal dependency + issue-terminal + execution-latency
+ memory-latency + head-lifecycle-unknown for both cycle and retirement-slot
ledgers. `memory_latency` must independently equal reservation-queue +
translation-order + request-outstanding + response-terminal + retry +
memory-lifecycle-unknown. Any individual bucket, including dependency or
retry, may legally be zero.
Request-outstanding must independently equal cache-lookup + device-wait +
AXI-read-address + AXI-read-data + AXI-write-request + AXI-write-response +
request-detail-unknown for both ledgers. A nonzero request-detail-unknown count
also contributes to the fail-closed unknown ratio.
Retirement capacity is exactly
`2 * cycles + end_lane - start_lane`; current baseline qualification also
requires `start_lane == end_lane`, so capacity is `2 * cycles`. Retired slots
must equal selected region retired instructions, all unused-slot reasons must
sum to the remaining capacity, and
`(cycle_memory_lifecycle_unknown + cycle_head_lifecycle_unknown +
cycle_unknown) / cycles` may not exceed 1%.
Counter stacks and lost-slot ledgers must be bit-exact across the three
deterministic repetitions. Missing or duplicated counter markers cannot be
replaced by legacy overlap buckets.

Whole-program exit counters remain mandatory only for semantic and termination
validation: PASS, exactly one GOOD TRAP, zero exit, CoreMark CRC/iteration
checks, Dhrystone run-count checks, and a nonnegative dynamic-tail diagnostic.
Post-region tail cycles or retired instructions may differ between designs.
Whole-program counters never feed CPI, IPC, throughput, repetition equality, or
selected retired-instruction equality under v8. Historical v3/v4/v5/v6/v7 parsing
remains available only when a caller explicitly selects the older evidence
schema.

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
