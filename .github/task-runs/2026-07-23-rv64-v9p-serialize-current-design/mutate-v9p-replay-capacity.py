#!/usr/bin/env python3
"""Create the compile-success V9P replay-capacity admission mutation."""

from __future__ import annotations

import argparse
from pathlib import Path


CORRECT = """  wire issue0_dual_load_admission_block_w =
      issue0_is_load_w && !issue0_is_amo_w &&
      (issue0_dual_bank1_w ?
       (mem_bank1_load_admission_block_w ||
        (issue0_sq_block_r && mem_bank1_load_replay_residency_w)) :
       (mem_bank0_load_admission_block_w ||
        (issue0_sq_block_r && mem_bank0_load_replay_residency_w)));
  wire issue1_dual_load_admission_block_w =
      issue1_is_load_w && !issue1_is_amo_w &&
      (issue1_dual_bank1_w ?
       (mem_bank1_load_admission_block_w ||
        (issue1_sq_block_r && mem_bank1_load_replay_residency_w)) :
       (mem_bank0_load_admission_block_w ||
        (issue1_sq_block_r && mem_bank0_load_replay_residency_w)));
"""

FENCE_OPEN = """  wire issue0_dual_load_admission_block_w =
      issue0_is_load_w && !issue0_is_amo_w &&
      (issue0_dual_bank1_w ? mem_bank1_load_admission_block_w :
                            mem_bank0_load_admission_block_w);
  wire issue1_dual_load_admission_block_w =
      issue1_is_load_w && !issue1_is_amo_w &&
      (issue1_dual_bank1_w ? mem_bank1_load_admission_block_w :
                            mem_bank0_load_admission_block_w);
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    text = args.source.read_text(encoding="utf-8")
    count = text.count(CORRECT)
    if count != 1:
        raise SystemExit(
            f"expected one replay-capacity admission block, found {count}"
        )
    mutated = text.replace(CORRECT, FENCE_OPEN, 1)
    if CORRECT in mutated or mutated.count(FENCE_OPEN) != 1:
        raise SystemExit("mutation postcondition failed")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(mutated, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
