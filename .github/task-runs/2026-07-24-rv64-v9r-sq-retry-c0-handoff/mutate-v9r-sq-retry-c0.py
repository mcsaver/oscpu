#!/usr/bin/env python3
"""Create one compile-success V9R C0 SQ-query retry handoff variant."""

from __future__ import annotations

import argparse
from pathlib import Path


BACKEND_BANK0 = """  assign mem_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem_sq_query_exact_w && !mem_retry0_valid_q &&
      !mem_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !control_full_flush_barrier_w;
"""

BACKEND_BANK0_OPEN = """  assign mem_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem_sq_query_exact_w && !mem_retry0_valid_q &&
      !mem_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w;
"""

BACKEND_BANK1 = """  assign mem1_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem1_sq_query_exact_w && !mem_retry1_valid_q &&
      !mem1_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !control_full_flush_barrier_w;
"""

BACKEND_BANK1_OPEN = """  assign mem1_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem1_sq_query_exact_w && !mem_retry1_valid_q &&
      !mem1_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w;
"""

BRIDGE_FIRE = """  wire sq_query_retry_fire_w = mem0_sq_query_valid_o &&
      sq_query_decision_onehot_w && mem0_sq_query_replay_i &&
      mem0_sq_query_retry_ready_i && !control_full_flush_barrier_i;
"""

BRIDGE_FIRE_OPEN = """  wire sq_query_retry_fire_w = mem0_sq_query_valid_o &&
      sq_query_decision_onehot_w && mem0_sq_query_replay_i &&
      mem0_sq_query_retry_ready_i;
"""

VARIANTS = {
    "backend-bank0-ready-open": (BACKEND_BANK0, BACKEND_BANK0_OPEN),
    "backend-bank1-ready-open": (BACKEND_BANK1, BACKEND_BANK1_OPEN),
    "bridge-retry-fire-open": (BRIDGE_FIRE, BRIDGE_FIRE_OPEN),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--case", required=True, choices=sorted(VARIANTS))
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    original, replacement = VARIANTS[args.case]
    text = args.source.read_text(encoding="utf-8")
    count = text.count(original)
    if count != 1:
        raise SystemExit(
            f"{args.case}: expected one exact source block, found {count}"
        )
    mutated = text.replace(original, replacement, 1)
    if original in mutated or mutated.count(replacement) != 1:
        raise SystemExit(f"{args.case}: mutation postcondition failed")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(mutated, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
