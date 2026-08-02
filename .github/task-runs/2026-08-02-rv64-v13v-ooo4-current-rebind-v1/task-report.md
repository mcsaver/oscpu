# V13V current-design OOO-4 speculation/recovery rebind

## Classification and claim

- Primary class: `architecture`; supporting class: `tooling/workflow`.
- Claim boundary: current-design `OOO-4 speculation_recovery` only. No production
  RTL, DI-1 through OOO-3, whole-architecture, CPI or PPA promotion claim.
- Current RTL design-id:
  `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`.

## Falsifiable hypotheses and root cause

- H1: current branch recovery semantics still satisfy OOO-4; only the historical
  fixed-path evidence is stale.
- H2: current `OooIntIssueQueue` or `OooMemAxiBridge` changes introduced a real
  age, owner, terminal or drain regression.
- H3: the V8Y source-mutation anchors or evidence manifest representation no
  longer correspond to the current source and testbench.

The lowest-cost current `OOO_ASSERT` focused run passed both linear
`D0/A1/B2` and wrapped `D14/A15/B0` layouts, the 8192-case EX age matrix and
the already-fired AXI read drain. All eleven historical edit anchors remained
unique in current RTL. The complete suite then compiled and dynamically
rejected all nine mutations. H1 is supported; H2 and H3 are not supported in
the tested OOO-4 scope. The actual stale component was the historical evidence
path/design binding, not production recovery semantics.

## Implementation

- The historical V8Y runner now has an opt-in task-run scoped mode. Resolved
  outputs must share one `.github/task-runs/*/evidence` root; scoped mode starts
  from an empty manifest, publishes only `speculation_recovery`, and cannot
  overwrite the canonical architecture manifest or claim predecessor gates.
- The mutation runner no longer uses Git to find the repository and no longer
  leaves a fixed `/tmp` mutant tree. A validated task-run output is retained;
  all VVP/source-copy build intermediates live in an automatically removed
  temporary directory.
- `speculation_recovery_evidence.py` accepts exact task-run inputs, reconstructs
  every declared mutant SHA from one unique live RTL edit anchor, rejects
  no-op/zero/multiple-anchor variants, and publishes 22 named proof roles.
- `architecture_hard_gates.py` checks the exact role inventory, task-run path
  boundary, live artifact hashes, unique gate-log binding and aggregate proof
  digest. Negative tests cover missing roles, content drift and gate-log drift.
- The final added proof role binds `/usr/bin/iverilog` and `/usr/bin/vvp`
  SHA-256 values, the focused assert/release IVFLAGS, mutation defines and the
  exact V8Y target. The evidence builder re-hashes both EDA binaries before
  publication.
- Scoped mode runs the relevant `eval/check-contract.sh` assertion compilation
  and count ratchet directly. Canonical mode retains the historical composed
  predecessor and full `make check-contract` behavior.
- No file under `npc/rv64/vsrc/**` changed in this round.

## Current-design RTL and EDA observations

- Final suite: `v8y-ooo4-20260801T233216Z-243405`.
- Focused simulations: assert/release `2/2 PASS`, each with one `[RESULT] PASS`.
- OOO-4 metrics: `7/7 PASS`.
- Compile-success RTL source mutations: `9/9` compiled, dynamically rejected,
  reconstructed from current RTL and proven non-noop.
- Adjacent `OOO_ASSERT` regressions: `6/6 PASS` for backend, core glue, redirect
  arbiter, BPU update gate, memory AXI bridge and dual-memory wrapper.
- Evidence/manifest unit and counterexample suite in the final runner:
  `41/41 PASS`.
- `sources.pre.sha256` and `sources.post.sha256` are byte-identical; both have
  SHA-256 `86bc7c87b98a79cb54d5c26f7e806864a477f57098e0d189555b9cdde220790c`.
- Scoped manifest contains exactly `speculation_recovery=PASS`; only OOO-4 is
  GREEN. Every other architecture gate and overall are RED; PPA is
  `UNQUALIFIED`, `promotion_eligible=false`.

## Evidence identity

- `result.json`:
  `d684b7244e9fb480c8900f64fba64dc949e59b912a9489506f660b8b108141d7`.
- `architecture-current.json`:
  `f05747b55e698bc5687f90b9eddf86a11d423d32dd01e039582512fb7b397d3f`.
- `speculation-recovery.log`:
  `967fc314e2e6ff285982f9f826dca7104d867bf4c75dfd9d5ec863cd23d8ae05`.
- mutation `summary.json`:
  `87db0eb3308f2824a0cefad4e322aab5b822f821ecbc810bb3b20291304124a4`.
- `simulator-config.txt`:
  `2b779d5cdba7d347d1e5bc7176d81a304b5b32617e346e50baa341b7239af35f`.
- Icarus identities: `iverilog=a6071e4b…b6d8a3`,
  `vvp=a10bd7d4…8f4023`.

## Declared gaps and reuse boundary

- A diagnostic replay of the full aggregate `make check-contract` remains
  `GAP rc=2`: the producer-holder census/frozen instance/Yosys graph binds old
  design-id `882111fb…bed67b`, not current `093c2380…a7488`. Its raw output is
  retained in `evidence/contract-aggregate-gap.log`. This is an independent
  whole-core closure debt and is not used by the scoped OOO-4 record.
- The focused AXI trajectory covers an already-fired read and exact drop/pop/
  terminal behavior. It does not claim an unbounded proof over all AXI channel,
  ID, outstanding-depth or return-order combinations.
- The 8192-entry matrix plus linear/wrap scenarios and nine dynamic mutations
  are strong bounded evidence, not a formal proof of every ProducerId epoch or
  slot-reuse sequence.
- Full-system execution, CPI, synthesis, STA, area and power are NOT_RUN because
  this round changes no production RTL and makes no performance or PPA claim.

## Review and artifact policy

- Frozen-material reviewer v1 approved the scoped OOO-4 claim and identified
  simulator/config identity as the main evidence-strengthening opportunity.
  The 22nd proof role and fresh complete rerun close that actionable gap; the
  v1 contract remains retained as review history.
- Final v2 frozen-material review found no fake-green blocker and approved only
  current-design scoped OOO-4. Its evidence basis and unknowns are retained in
  `dispatch-log.md` and `evidence/pre-delivery-review.md`.
- The deterministic-delivery workflow selected only `rtl-task-contract`; it
  passed in 1.053 s. No strict/global e2e gate was run. The compact workflow
  receipt is retained under
  `.github/task-runs/2026-08-01-rv64-v13v-ooo4-current-rebind-v1/`; the UTC date
  in that path reflects the workflow start timestamp and does not denote a
  second RTL/evidence run.
- The bounded evidence index records 41 assets totaling 2,152,129 bytes. It
  stores path/hash/marker summaries in the evidence database while leaving the
  original RTL logs and JSON results in this task-run.
- The obsolete fixed V8Y mutant tree (117 MiB) and this round's precheck VVP
  tree (14 MiB) were deleted after their retained logs/results were superseded.
  The final runner removed its own temporary builds, and three touched-directory
  Python bytecode caches (about 476 KiB) were removed at closeout. Task-run
  storage contains bounded logs, hashes, contracts and results only; it contains
  no `.vvp`, `.o` or `.a` build intermediate.

Round status: `PASS_WITH_DECLARED_GAPS`. The long-term RV64 goal remains active.
