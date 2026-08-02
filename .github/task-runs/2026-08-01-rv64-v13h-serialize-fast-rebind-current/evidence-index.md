# V13H compact evidence index

Raw assets are indexed in `.github/cache/github-index.sqlite`; this file intentionally keeps only
the first-order result, log and identity pointers needed for bounded recall.

## Identity and decision

- `evidence/identity/design-id.pre.json` and `design-id.post.json`:
  `b4c9646ffab510f5beaa60887247cc512e93817f151fc4d61876e0fa009b8c9b` each;
  146 production RTL files, byte-identical pre/post, design-id `364b1e...d44`.
- `currentness-decision.json`:
  `6001ce381c15d5f0e35315ea6e1963c5a7b741dcad3e6a08ff461651fd675a51`;
  fast gates PASS, full system RECERT_REQUIRED, ledger STALE_EVIDENCE,
  architecture freeze GAP, PPA UNPROMOTED.

## Focused serialize transactions

- `evidence/qh-current/summary.json`:
  `4cf76dc4e40ee5cd8a32c76968d3ea1209608cc5c7b238ac453c9c77b11e0317`;
  2/2 positive, 2/2 production RTL negatives, 1/1 verification-only TB-wiring
  negative, cleanup 24/24 and retained temporary artifacts 0.
- `evidence/system-current/summary.json`:
  `9b3192be50d64de5a50294fe0a7809cc5f7bb0784724190b669359b77b2447b4`;
  3/3 baseline, 15/15 production RTL negatives dynamically rejected,
  cleanup 88/88 and retained temporary artifacts 0.

## Full functional execution

- `evidence/module-current/result.json`:
  `093ecbeac276d8da8121e20cb5a79fa94fa0bd39c89363f3f4836a3a77066255`;
  module 113/113, input binding unchanged, retained VVP 0.
- `evidence/functional-current/run-result.json`:
  `07e8e5218d718daa0b451d55f7e779f5883d45f6dbb352c3c82ad6bd068d2eba`;
  official 177/177, AM 61/61, DiffTest mismatch 0, mutation 11/11,
  compiled intermediates 0 and no global current publish.
- `evidence/functional-current/functional-aggregate.json`:
  `14c382b52a34a6e018e46df984c581082483334928e8733e8a91ec170e1839a4`;
  CoreMark 10/CRC `0xfcaf` and Dhrystone 10000 each with one GOOD TRAP.
- `evidence/checker-tests.log`:
  `cafe0cfabdd0bd5bea908831e74de4d6c4620d36c19330ef2b0207e7625435a9`;
  14/14 checker tests PASS.

## Review and handoff

- `subagent-contracts/v13h-serialize-current-final-review.json`:
  `114e4a4525945a7295cc5fe261a997e8f4632b95b8b9976908fec6622bf7b0d1`.
- `reviewer-result.md`:
  `3aa28dad6aa3267851a4bd132a657acdf3caf9a0f47634e3032dd0b747f8a8ce`;
  `APPROVED_NOT_PROMOTION_ELIGIBLE`.
- `task-result.json`:
  `b0036cc4579ec8f48b6125e26fec69910dc0eca4fd70811e1c9b03ffcc934355`.
- `task-report.md`:
  `9338fb9584b3c404d24da7704ed9255ec58f094c2db75999684a5126b33cd79b`.

## Retention

No Yosys netlist, VVP, object file or generated mutation source is retained. The approximately
19 MiB task-run keeps result JSON, normalized logs, program images, and the frozen simulator,
reference model and configuration needed to audit or replay the fresh functional execution. These
are first-order evidence artifacts rather than synthesis/runtime scratch.
