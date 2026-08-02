# RV64 V11Y dispatch log

- `implementer`: primary agent; production RTL, directed TB/AM, full module and
  functional evidence, checker replay, canonical publication, and compaction.
- `reviewer`: `v11y_replay_review`; read-only frozen-evidence review.
- `first_review`: rejected replay-1 because it predated the exact-path checker.
- `corrective_action`: replaced content-based filtering with exact
  `riscv-tests/isa/<test-id>{,.dump}` allowlist and exposed configuration
  reconstruction.
- `second_review`: `REPLAY_APPROVED` for replay-3; no RTL/synthesis process was
  launched by the reviewer.
- `publication`: identical final replay published; three canonical files passed
  byte comparison.
- `shell_ownership`: single-flight throughout; reviewer returned ownership before
  each primary-agent engineering command.
