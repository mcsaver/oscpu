#!/usr/bin/env python3
"""Create one compile-success v8l lease mutant in a caller-owned temp path."""

from __future__ import annotations

import argparse
from pathlib import Path


MUTATIONS: dict[str, tuple[str, str]] = {
    "dispatch_drop_int_iq_union": (
        "producer_live_mask_i | int_iq_producer_live_mask_w;",
        "producer_live_mask_i;",
    ),
    "dispatch_lane0_raw_index": (
        "!complete_producer_live_mask_w[\n"
        "                                 rob_dispatch0_producer_id_w] &&",
        "!complete_producer_live_mask_w[\n"
        "                                 rob_dispatch0_producer_id_w[ROB_INDEX_W-1:0]] &&",
    ),
    "int_iq_fire_dies_early": (
        "      if (valid_q[lease_i])\n"
        "        producer_live_mask_r[producer_id_q[lease_i]] = 1'b1;",
        "      if (valid_q[lease_i] &&\n"
        "          !(issue0_fire_w &&\n"
        "            (lease_i[ENTRY_INDEX_W-1:0] == issue0_idx_w)) &&\n"
        "          !(issue1_fire_w &&\n"
        "            (lease_i[ENTRY_INDEX_W-1:0] == issue1_idx_w)))\n"
        "        producer_live_mask_r[producer_id_q[lease_i]] = 1'b1;",
    ),
    "backend_drop_mem_res_holder": (
        "      mem_res_producer_live_mask_w |\n"
        "      ex0_producer_live_mask_w |",
        "      ex0_producer_live_mask_w |",
    ),
    "backend_drop_ex0_holder": (
        "      ex0_producer_live_mask_w |\n"
        "      ex1_producer_live_mask_w |",
        "      ex1_producer_live_mask_w |",
    ),
    "backend_drop_ex1_holder": (
        "      ex1_producer_live_mask_w |\n"
        "      branch_producer_live_mask_w |",
        "      branch_producer_live_mask_w |",
    ),
    "backend_drop_branch_holder": (
        "      branch_producer_live_mask_w |\n"
        "      checkpoint_irrevocable_write_live_mask_w;",
        "      checkpoint_irrevocable_write_live_mask_w;",
    ),
    "backend_capture_ignores_tracker_ready": (
        "  wire mem_issue_res_capture_w =\n"
        "      mem_issue_res_capture_candidate_w && mem_owner_alloc0_ready_w &&\n"
        "      (!mem_issue1_res_capture_candidate_w || mem_owner_alloc1_ready_w);",
        "  wire mem_issue_res_capture_w =\n"
        "      mem_issue_res_capture_candidate_w &&\n"
        "      (!mem_issue1_res_capture_candidate_w || mem_owner_alloc1_ready_w);",
    ),
    "backend_iq_pop_ignores_tracker_ready": (
        "          (iq_issue0_producer_current_w ? mem_owner_alloc0_ready_w :\n"
        "                                          1'b1)) :",
        "          (iq_issue0_producer_current_w ? 1'b1 :\n"
        "                                          1'b1)) :",
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    text = args.source.read_text(encoding="utf-8")
    old, new = MUTATIONS[args.mutation]
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"[V8L-MUTATOR][FAIL] {args.mutation}: expected one anchor, got {count}"
        )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"[V8L-MUTATOR][PASS] {args.mutation} -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
