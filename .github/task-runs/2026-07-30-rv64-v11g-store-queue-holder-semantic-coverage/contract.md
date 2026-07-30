# V11G bounded contract

- Primary RTL object: `OooStoreQueue.producer_id_q`, `owner_valid_q`,
  `owner_kind_q`, `owner_token_q`, and `mmu_epoch_q`.
- Cycle scope: dual allocation, dual exact bind, out-of-order fill, physical
  request, B/probe terminal, exact ROB release, selective/global flush,
  request-sent survival, release+allocation, terminal+release+flush,
  bind+terminal+release, dual terminal, slot generation reuse, and reset.
- Classification: verification-only unless a legal-input production
  counterexample is found.
- Production exclusion: no change to
  `npc/rv64/vsrc/memory/OooStoreQueue.v`.
- Evidence boundary: local module semantic closure only.  This round does not
  promote global no-live-reuse, whole-architecture GREEN, system
  recertification, synthesis, STA, power, or PPA.
- Cost boundary: focused Icarus/VVP only; no Linux/system run and no
  high-cost experiment.
- Single-flight boundary: one Windows-to-WSL engineering command owner at a
  time.

## Success conditions

1. One stimulus-owned four-entry model checks every directed edge and every
   raw entry; DUT raw state and `snoop_*` never construct expected identity.
2. Both `OOO_PRODUCER_GEN_W=1` and `4` pass with `OOO_ASSERT` enabled and
   disabled.
3. Token and epoch values are intentionally not derived from ROB index.
4. All declared compile-success RTL variants build without `OOO_ASSERT` and
   are rejected by `[V11G-SQ-HOLDER-ORACLE][FAIL]`.
5. Full RTL and focused source pre/post bindings do not drift.
6. Only `store-queue-producers` and `store-queue-owner-tokens` may move from
   GAP to PASS.
