#!/usr/bin/env python3
"""Create one compile-valid, behavior-invalid OooRob mutation in a temp file."""

from __future__ import annotations

import argparse
from pathlib import Path


MUTATIONS = {
    "dispatch0_no_store": (
        """        slot_generation_q[dispatch0_rob_idx_o] <=
            dispatch0_generation_candidate_w;""",
        """        slot_generation_q[dispatch0_rob_idx_o] <=
            slot_generation_q[dispatch0_rob_idx_o];""",
    ),
    "flush_resets_generation": (
        """        if (rst)
          slot_generation_q[idx] <= {PRODUCER_GEN_W{1'b1}};""",
        """        if (rst || flush_i)
          slot_generation_q[idx] <= {PRODUCER_GEN_W{1'b1}};""",
    ),
    "lane1_alias_lane0": (
        """  assign dispatch1_producer_id_o =
      {dispatch1_generation_candidate_w, dispatch1_rob_idx_o};""",
        """  assign dispatch1_producer_id_o = dispatch0_producer_id_o;""",
    ),
    "dispatch0_drop_generation": (
        """  assign dispatch0_producer_id_o =
      {dispatch0_generation_candidate_w, dispatch0_rob_idx_o};""",
        """  assign dispatch0_producer_id_o =
      {{PRODUCER_GEN_W{1'b0}}, dispatch0_rob_idx_o};""",
    ),
    "dispatch0_swapped_fields": (
        """  assign dispatch0_producer_id_o =
      {dispatch0_generation_candidate_w, dispatch0_rob_idx_o};""",
        """  assign dispatch0_producer_id_o =
      {dispatch0_rob_idx_o, dispatch0_generation_candidate_w};""",
    ),
    "valid_without_fire": (
        """      if (dispatch0_fire_w) begin
        slot_generation_q[dispatch0_rob_idx_o] <=
            dispatch0_generation_candidate_w;""",
        """      if (dispatch0_valid_i) begin
        slot_generation_q[dispatch0_rob_idx_o] <=
            dispatch0_generation_candidate_w;""",
    ),
    "reset_generation_zero": (
        """        if (rst)
          slot_generation_q[idx] <= {PRODUCER_GEN_W{1'b1}};""",
        """        if (rst)
          slot_generation_q[idx] <= {PRODUCER_GEN_W{1'b0}};""",
    ),
    "commit1_alias_commit0": (
        "  assign commit1_producer_id_o = {slot_generation_q[head1_w], head1_w};",
        "  assign commit1_producer_id_o = commit0_producer_id_o;",
    ),
    "walk1_alias_walk0": (
        "  assign walk1_producer_id_o = {slot_generation_q[wptr_m1_w], wptr_m1_w};",
        "  assign walk1_producer_id_o = walk0_producer_id_o;",
    ),
    "ready_ignores_flush": (
        """  assign dispatch0_ready_o = !rst && !flush_i && !recovering_w &&
                             (free_slots_w != {ROB_COUNT_W{1'b0}});""",
        """  assign dispatch0_ready_o = !recovering_w &&
                             (free_slots_w != {ROB_COUNT_W{1'b0}});""",
    ),
    "commit_clears_generation": (
        """      if (commit0_fire_w) begin
        valid_q[head_q] <= 1'b0;""",
        """      if (commit0_fire_w) begin
        slot_generation_q[head_q] <= {PRODUCER_GEN_W{1'b1}};
        valid_q[head_q] <= 1'b0;""",
    ),
    "recovery_clears_generation": (
        """    end else if (recover_q) begin
      // ROB-walk""",
        """    end else if (recover_q) begin
      slot_generation_q[walk_ptr_q] <= {PRODUCER_GEN_W{1'b1}};
      // ROB-walk""",
    ),
    "parent_ready_ignores_reset_flush": (
        """  wire dispatch_freeze_w = rst || flush_i ||
                           rob_recover_active_w || rob_kill_valid_w;""",
        """  wire dispatch_freeze_w =
                           rob_recover_active_w || rob_kill_valid_w;""",
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    source = args.source.read_text(encoding="utf-8")
    old, new = MUTATIONS[args.mutation]
    count = source.count(old)
    if count != 1:
        raise SystemExit(
            f"[V8E-MUTATOR][FAIL] {args.mutation}: expected one anchor, found {count}"
        )
    args.output.write_text(source.replace(old, new, 1), encoding="utf-8")
    print(f"[V8E-MUTATOR][PASS] {args.mutation}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
