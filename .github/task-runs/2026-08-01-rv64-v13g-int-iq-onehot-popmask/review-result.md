# V13G independent final review

- Verdict: `APPROVED_DEVELOPMENT_CHECKPOINT`
- Scope: local RV64 `OooIntIssueQueue.compact_remove_w`,
  `OooIntIssueSelect8` owner onehot, and the frozen V13F/V13G/V13B evidence.
- Contract: `subagent-contracts/v13g-int-iq-onehot-popmask-final-review-v1.json`
- Contract SHA-256:
  `f3cf111f9f4cf8a64f432a745059e4ff8d2d404b4d41022a9b07fa1da434d7f5`
- Shell disposition: all contract-scoped WSL commands stopped; single-flight shell ownership
  was returned to the primary node before evidence finalization.

## RTL equivalence boundary

The parent removes entry `i` when the Q-only memory-pair transaction fires for entry 0/1,
or when a regular issue lane fires and its encoded owner index equals `i`. V13G replaces the
regular-lane comparison with `issue*_fire_w & issue*_onehot_w[i]` and retains the pair mask
`8'b0000_0011`. The predicates are cycle-equivalent when controls are known 0/1, each firing
owner is exact-onehot, the two regular lane owners are mutually exclusive, and the Q-only
memory-pair path performs its single-handshake atomic pop2.

Survivors are still copied in entry order into monotonically increasing `write_i`, followed by
dispatch0 and dispatch1 append. Packed age, full payload and ProducerId order therefore remain
unchanged. Survivor/dispatch wake absorption, `rst/flush > kill > normal`, and kill-survivor
same-cycle wake behavior are outside the executable diff and remain intact.

The Q-only pair atomicity follows from one
`memory_pair_peek_valid_o && memory_pair_peek_ready_i` transaction: its selector projects
entry0/1, regular issue valids are quiet in that cycle, and the remove mask is exactly
`0000_0011`.

## Functional observations

- V11F stimulus-owned edge model passes at `OOO_PRODUCER_GEN_W=1` and `=4`, including birth/hold,
  overtake, single/dual compaction, memory-pair ready-hold/pop2/append, kill, flush and reset.
- The G4 full IQ testbench reaches the V8U/R3P2/T3D/T3H/R3P1/registered-owner/V8F markers and
  ends with `[PASS] tb_ooo_int_issue_queue`.
- `tb_ooo_dispatch_backend`, `tb_ooo_int_backend` and `tb_ooo_alu_decode_backend` pass 3/3.
- The generic G1 full testbench is deliberately not claimed as PASS: parent and candidate both
  retain the same 12 `V8O dispatch generation nonzero` mismatches and exit FAIL. The frozen
  logs are a configuration/oracle-width GAP, not evidence against or in favor of the RTL delta.

## PPA and identity observations

Local `OooIntIssueQueue`, 200 MHz, flatten=1, share=0:

| Metric | Parent | Candidate | Delta |
| --- | ---: | ---: | ---: |
| coarse cells | 4,430 | 4,385 | -45 |
| coarse `$eq` | 198 | 184 | -14 |
| coarse `$logic_and` | 379 | 353 | -26 |
| coarse `$mux` / `$pmux` | 1,614 / 1,481 | 1,614 / 1,481 | unchanged |
| mapped cells | 34,468 | 33,284 | -1,184 |
| mapped area | 75,205.48 | 74,917.64 | -287.84 (-0.383%) |
| sequential area | 19,293.12 | 19,293.12 | unchanged |
| 5 ns worst slack | +2.233862638 ns | +2.406632185 ns | +0.172769547 ns |

Both local coarse/mapped checks report zero problems, and TNS/WNS are 0/0. The parent
`valid_q[0] -> entry0 payload D` family leaves top40; the candidate worst endpoint is
`valid_q[5] -> bht_idx_q[1] D`.

NpcTop coarse, 200 MHz, flatten=0, share=0:

- cells `51,129 -> 51,084`, wire bits `1,690,602 -> 1,690,585`;
- `$eq 3,631 -> 3,617`, `$logic_and 7,828 -> 7,802`;
- `$mux/$pmux` remain `15,471/2,659`; both sides report zero check problems;
- candidate elapsed time is 235.22 s.

Parent design-id is
`sha256:29c0afe820a5ce58a1299da1faaefabce6f9038156f628e9f0f3ff3b6e23f483`;
candidate design-id is
`sha256:364b1e601773c22ab0594950170674ea6b228bf6b4c9b2c26b0bdcc9a4374d44`.
Each candidate pre/post identity file is byte-identical. Across the bound parent/candidate RTL
set, the only mismatch is `OooIntIssueQueue.v`. The reconstructed local-PPA input hash
`13bc5b6fee1c8c9a8c6ec877baaad24773a978c650c2ac5634348d0cc8c21e51` differs from final RTL
only in explanatory comments; executable tokens and `compact_remove_w` are identical.

## Explicit GAP and NOT_RUN boundary

- Existing onehot assertions reject known multi-hot, but an assertion using ordinary `!=` is
  not a fail-closed proof when a selector bit is X. No selector X/Z injection or formal
  four-state equivalence was run. Multi-hot and X/Z behavior is outside the approval scope.
- The Q-only memory-pair path is covered by one atomic handshake. The two ordinary issue lanes
  expose independent READY signals; their downstream atomic coupling was not reviewed here.
- Full-core mapped synthesis/STA, qualified power, the complete architecture cohort, and a new
  system transaction were not run.

The review therefore approves the retained RTL as a development checkpoint. It does not grant
full-core PPA, power, architecture-wide, system, or signoff promotion.
