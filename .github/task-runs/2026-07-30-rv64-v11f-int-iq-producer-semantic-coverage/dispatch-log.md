# V11F RV64 integer IQ ProducerId dispatch log

## Pre-review dispatch

- RTL object: `OooIntIssueQueue.producer_id_q`
- Contract JSON: `.github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/subagent-contracts/v11f-int-iq-producer-pre-review.json`
- Contract JSON SHA-256: `fcf54f1b6bb15031403742a8fca03b66784410886b7912225ddc81019c302051`
- Contract pipeline: `create -> validate -> render` PASS
- Shell ownership: delegated to `v11f_int_iq_pre_review`; root runs no WSL engineering command until return.
- Review boundary: read-only current RTL/TB/spec/evidence audit; no production or evidence file writes.
- Required result: reachable-cycle counterexamples, H1/H2/H3 decision, minimum independent scoreboard and compile-success mutation matrix.

## Pre-review result

- Result: `GAP`; no reachable production `OooIntIssueQueue.producer_id_q` mismatch was found under the frozen IQ-I6 transaction barrier.
- H1 current RTL correctness: supported for birth, hold, compaction, issue/pair death, selective recovery, flush and reset.
- H2 reachable RTL defect: rejected in the allowed scope. The unconstrained `kill_valid_i && dispatch*_valid_i` case violates IQ-I6 and remains an upstream-contract scope boundary.
- H3 V8L sufficiency: rejected. Current ledger gaps are `RAW_IDENTITY_NEGATIVE_COVERAGE_GAP`, `RAW_PRODUCER_ID_KNOWN_NEGATIVE_COVERAGE_GAP`, `UNIT_LIFECYCLE_COVERAGE_GAP` and `SEMANTIC_LIFECYCLE_NOT_CLOSED`.
- Implementation decision: verification-only; production `npc/rv64/vsrc/scheduling/OooIntIssueQueue.v` remains unchanged.
- Required evidence: assert/release × generation width 1/current, independent eight-entry stimulus model, raw-Q/full-mask comparison, X-bearing full-P negatives, and compile-success carrier/death mutations with `OOO_ASSERT` disabled.
- Shell ownership: reviewer returned the sole WSL engineering-command lane to root.

## Final-review dispatch

- RTL object: `OooIntIssueQueue.producer_id_q`
- Contract JSON: `.github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/subagent-contracts/v11f-int-iq-producer-final-review.json`
- Contract JSON SHA-256: `b41dab889c477796f8397cde8dccf7eecc457524c70c193ea8c508e86bda9234`
- Contract pipeline: `create -> validate -> render` PASS。
- Shell ownership: delegated to the read-only reviewer; root ran no WSL engineering
  command until explicit return.
- Runtime note: all three existing subagent slots were retained historical nodes, so
  the exact validated render was dispatched to an idle, unrelated prior reviewer
  node rather than creating a fourth fresh node. No V11F implementation context was
  added outside the render.
- Review boundary: source binding, independent oracle, four profiles, twenty
  compile-success mutations, 40 release simulations, normal regression and
  V11E→V11F ledger diff.

## Final-review result

- Result: `APPROVED_BOUNDED_INTEGER_IQ_PRODUCER_SCOPE`
- Blockers: `0`
- Production IQ scoped diff: empty
- Positive profiles: `4/4 PASS`
- Compile-success mutation cases: `20`
- Mutation simulations: `40/40 rejected`
- Normal IQ regression: `PASS`
- Ledger transition: only `integer-iq-producers: GAP -> PASS`;
  total `7/37 -> 8/36`
- Remaining boundary: upstream kill/flush transaction barrier, 36 semantic units,
  global no-live-reuse, whole architecture, system, synthesis, STA, power and PPA
- Shell ownership: final reviewer returned the sole WSL engineering-command lane
  to root; no reviewer write or residual engineering process.
