# v8n scoped OOO-1 true OoO long-latency task report

## Outcome

`OOO-1 true_ooo_long_latency` is scoped GREEN for the current complete RTL
source-set digest and exact proof provenance.  The pre-existing OOO-2 record is
preserved only because it has the same schema and design ID.  The architecture
remains `OVERALL: RED`; this task does not authorize PPA work.

No production RTL function was changed in v8n.  The architecture-first read
showed that the current implementation already allowed independent integer work
to execute behind a real long-latency load or iterative MulDiv owner.  The
missing part was a non-vacuous, identity-safe and permanently discoverable
OOO-1 proof path, so this slice strengthens the testbench, directed mutations,
checker, evidence publication and retained workflow rather than adding another
microarchitectural mechanism.

## Frozen claim

For each of a real cacheable/no-fault/no-store load miss, iterative MUL and
iterative DIVU:

- the old transaction is actually accepted with a non-zero-generation full
  ProducerId and remains the exact live owner until formal writeback;
- eight distinct younger producers are accepted and receive authorized,
  exactly-once formal writeback before the old producer writes back;
- four cycles contain simultaneous `issue0` and `issue1` accepts, so serial
  promotion or an empty second lane cannot satisfy the claim;
- the nine real ROB valid entries reconstruct exactly the old-plus-eight-young
  full-ProducerId set;
- no commit occurs before the old formal writeback, after which all nine
  ProducerId/PC pairs retire in dispatch order and every holder/free-list ledger
  drains.

This is latency tolerance only.  It does not prove exceptional or device loads,
stores or general memory ordering, pipeline cancellation, complete recovery,
OOO-3, any other DI/OOO gate, Linux correctness, frequency, area or power.

## Permanent implementation

1. `tb_ooo_int_backend.sv` gained a focused v8n mode with a full ROB-turn prime,
   actual acceptance/owner-live/formal-WB/commit event binders, full ProducerId
   ledgers, real ROB census and load/MUL/DIV scenarios.
2. `run-focused.sh` runs release and `OOO_ASSERT` baselines and requires three
   activated scenarios in each mode.
3. Seven compile-success actual-source mutations cover serial lane1, MIQ lane1
   freeze, MulDiv lane1 freeze, retirement before head completion, load owner
   PID truncation, MulDiv owner PID truncation and MulDiv response PID
   truncation.  A mutation counts only after its activation marker is observed
   and its dedicated semantic check rejects it.
4. `true_ooo_long_latency_evidence.py` checks the quantitative markers,
   pre/post source hashes, exact proof provenance and the complete 142-file vsrc
   closure before publishing OOO-1.
5. `directed_evidence_manifest.py` provides parse-before-replace atomic merge,
   retains only same-schema/same-design sibling records and drops stale-design
   records.  The OOO-2 builder now uses the same helper.
6. `architecture_hard_gates.py` accepts only
   `make -C npc/rv64 check-true-ooo-long-latency`, requires the complete metrics
   and exact provenance, and still derives architecture-wide RED from the
   remaining gates.
7. The stable issue-queue spec and DB-first project/NPC memories now expose the
   command, claim boundary and evidence rules to future agents.

## Verification

- Permanent v8n gate: PASS, `baselines=6/6 mutations=7/7 OOO-1=GREEN
  OOO-2=GREEN overall=RED`.
- Release/assert scenarios: 3/3 + 3/3.
- Activated compile-success semantic mutations: 7/7.
- Architecture checker tests: 19/19.
- Atomic manifest tests: 3/3, including pre-replace fault injection preserving
  the prior manifest byte-for-byte and parseable.
- Fresh full module aggregate: 106/106.
- `make -C npc/rv64 check-contract`: PASS; ProducerId census PASS and immediate
  assertions `400 >= 89`.
- `scripts/agent-maintain.sh --mode check`: PASS, including RTL task-contract
  audit, 20-case self-test, 18-case CLI self-test, DB-first/Markdown coverage,
  policy, skill, state, trace and profile binding audits.
- Bounded non-history brief for `true ooo long latency`: complete, 1948/2400
  tokens, with the current NPC memory as independent primary.
- Task-specific `npc-dev`, `agent-system` and `github-index` profiles: completed.
- Final strict guard: PASS for all three profiles on the current dirty worktree.
- Full RTL lint was not promoted or reclassified in this no-production-RTL
  slice; the inherited 115-warning strict-lint RED remains a separate blocker.

## Evidence and review binding

- Current complete vsrc design ID:
  `sha256:9735bdc1f101501d0100a335b4d7ac602fa6b002d77cedbcb4245b833c2bb293`.
- The architecture manifest separately records the design closure, permanent
  command, focused log, exact proof/harness file hashes and aggregate
  provenance hash.  A subagent-contract JSON hash is never used as a design or
  proof digest.
- Initial self-contained no-tools contract review returned `gap` with B1-B9.
  Each item was converted into an event binder, identity/census check, activated
  mutation, exact-provenance check or atomic-publication fault test.
- The revision contract review and the independent implementation/evidence
  review both returned strict `pass` with no blocker.  Reviewers received only
  frozen local RV64 RTL facts and had no tools, shell, file access, writes,
  network, accounts, credentials or external services.

## Workflow persistence

- The new Make target and checker make OOO-1 a normal architecture gate rather
  than a one-off log inspection.
- The atomic manifest helper prevents a failed or stale directed run from
  destroying or silently carrying forward sibling gate records.
- Stable facts were written through `update-stored --refresh-shim`, snapshotted
  and passed `audit-db-first`; compatibility shims were not treated as source of
  truth.
- The no-tools review contracts, their exact JSON hashes, dispatch status,
  returned JSON and claim boundaries are retained in this task-run.
- Temporary materialized memory staging was removed after the transactional DB
  update so it cannot become duplicate retained evidence.

## Residual risks

- Directed simulation and seven mutations are not a formal proof of every
  possible queue, backpressure, cancellation or recovery interleaving.
- The testbench, checker and evidence builder can still share an unknown common
  assumption, despite the independent mutations and no-tools counterexample
  reviews.
- Device/exception loads, stores, memory ordering, branch recovery and wider
  load-queue behavior remain outside OOO-1.
- The inherited strict-lint RED and every remaining architecture gate must be
  closed before freezing an architecture baseline or starting PPA promotion.

## Next architecture boundary

Continue from the hard-gate inventory, not from a PPA knob.  Re-read the real
RTL feasibility of the remaining gates and freeze one atomic claim before any
implementation.  OOO-3 real load-queue depth is a candidate investigation, but
it is not implied by OOO-1 and remains RED until it has its own owner/order/
recovery contract and non-vacuous evidence.
