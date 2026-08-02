# Independent review result before attempt-3

Status: `GAP`

The attempt-2 evidence is mechanically complete for its declared leaf scope: 24/24 profiles passed, four regressions passed, 42 generated artifacts were removed, and no generated residue remained. It proves `OooPendingSystemSequencer`, `OooCsrAccessRequestMux`, and the width-4 `OooIntBackend` lease fence in separate testbenches.

It does not yet prove the production parent binding from ROB allocation to sequencer birth, exact mux commit to producer death, `core_local_flush_w` to sequencer reset, or the raw lease through every wrapper into `OooIntBackend`. The old width-1 backend profile also entered unrelated V8P checks instead of isolating the pending-system lease fence.

Required closure: add bounded, macro-gated `tb_ooo_priv_system` integration and flush observations; add isolated width-1 and width-4 backend profiles; and add compile-success mutations for the ControlPlane authorities and every wrapper link. Preserve all assertions and do not change production RTL unless these profiles expose a real semantic defect.

# Independent review result after attempt-5

Status: `PASS` for the local `pending-system-producer` lifecycle; whole-core, seven FP units, synthesis, STA and PPA remain `GAP`/unpromoted.

The v2 reviewer traced `OooPendingSystemSequencer.producer_id_q` through CSR ROB dispatch birth, exact commit death, `core_local_flush` reset, the wrapper chain and the `OooIntBackend` live-mask reuse fence at `PRODUCER_GEN_W=1/4`. It independently checked attempt-5 as 37/37 profiles, 18 mutations represented by 21 mutation profiles, four regressions, 66 cleanup records, and matching source-before/source-after hashes. No scoped production RTL counterexample was found.

Contract: `.github/task-runs/2026-07-31-rv64-v11u-pending-system-producer-semantic/subagent-contracts/v11u-pending-system-producer-review-v2.json`, SHA-256 `eb5d71e46c255c8827d0e4eee86bd0c83ba3074cb1b778daef77fe718b302f30`. The reviewer made no writes and returned WSL shell ownership.

Retained evidence qualifications:

- Eight parent/wrapper mutations use `OOO_ASSERT` and ten use release mode. The immutable attempt-5 oracle key `compile_success_release_mutation_rejection` is a legacy label; the current checker reports the accurate mixed-mode 10/8 split and rejects inconsistent configuration metadata.
- The focused flush profile forces the production `core_local_flush` net. It proves consumption and death through the production connection plus a disconnect mutation, but does not prove the upstream natural cause of every core-local flush.
- Generated TB/Make overlays were removed after hash and receipt validation. Their isolation is bound by current shared-TB hashes, replacement receipts and cleanup records; the deleted bytes are not retained for later manual reread.
- Ledger scope remains 37 PASS / 7 FP GAP. Full-system recertification, global no-live-reuse, synthesis, STA, power and PPA are not promoted.
