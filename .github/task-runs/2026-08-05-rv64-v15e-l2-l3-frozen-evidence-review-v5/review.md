# RV64 V15E L2/L3 frozen-evidence review

## Result

`PASS limited-to-exact-f7a6-A11-A6`

The independent no-tools reviewer found no internal ordering, identity, terminal-count,
or CPI contradiction in the frozen material.  Its result covers only:

- L2 A11 `full-l2`, design identity `sha256:f7a684...53f9`;
- L3 A6 `full-l3`, the same production RTL and simulator identity;
- the exact bound runner/checker/policy/source identities and 21-file seals.

It does not claim current L0, L1, synthesis, STA, PPA, or optional Ubuntu coverage.

## Transaction observations

- L2 ordering is strict from `CASE_SELECT` through selector RX, `CASE_ALL`, MMIO,
  UART/PLIC assertion, `PLIC_UART_IRQ_PASS`, `MINI_SYSTEM_PASS`, syscon, and the
  final cycle count.
- L3 ordering is strict for both ARM/RX/UART-to-PLIC windows and from
  `UART_IRQ_PASS` through `SHUTDOWN_ARM`, `LIGHTWEIGHT_PASS`, kernel powerdown,
  syscon, and the final cycle count.
- Terminal counts are exactly one per required class; critical marker count and
  RTL assertion failure count are zero.

## Reviewer GAP disposition

The compact prompt intentionally omitted several detailed files.  Read-only parent
disposition against the sealed evidence closed these material-only unknowns:

- A11 and A6 `input-hashes-before.sha256` equal their respective after manifests.
- Each `evidence-seal.txt` contains the recomputed SHA-256 of its
  `evidence-files.sha256` plus the verification-log SHA and `verification=PASS`.
- Both sealed `simulator-binding.txt` files record `OOO_ASSERT=1`,
  `OOO_CSR_QUEUE_HEAD=1`, and `OOO_TERMINAL_HOLDER_ASSERT=1`.
- The full A6 `summary.json` contains commit and cycle fields for the L3 phase
  markers; the compact prompt supplied only a subset of those commit values.

Non-blocking residual scope remains: the mutation inventory is not a proof over every
possible log truncation/encoding/manifest-replacement construction, and system-level
markers do not prove every internal microarchitectural state transition.  These limits
do not contradict the exact A11/A6 PASS claim.

## Contract binding

- contract: `.github/task-runs/2026-08-05-rv64-v15e-l2-l3-frozen-evidence-review-v5/subagent-contracts/rv64-v15e-l2-l3-frozen-evidence-review-v5.json`
- contract SHA-256: `0d535adb0243dfac3949e997b67edafbbdbdc487f714afdc6ac5c8c303420fdd`
- invalid first dispatch: discarded before use because its copied prompt contained a
  SHA transcription error; no output from that node is accepted.
