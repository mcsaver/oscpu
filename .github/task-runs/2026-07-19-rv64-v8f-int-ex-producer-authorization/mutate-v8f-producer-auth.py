#!/usr/bin/env python3
"""Emit one compile-valid v8f ProducerId authorization mutant."""

from __future__ import annotations

import argparse
from pathlib import Path


MUTATIONS: dict[str, tuple[str, str]] = {
    "rob_current0_ignore_generation": (
        """  wire current0_query_exact_w =
      {slot_generation_q[current0_query_idx_w], current0_query_idx_w} ==
      current0_query_producer_id_i;""",
        """  wire current0_query_exact_w =
      current0_query_idx_w ==
      current0_query_producer_id_i[ROB_INDEX_W-1:0];""",
    ),
    "rob_completion0_ignore_generation": (
        """  wire completion0_query_exact_w =
      {slot_generation_q[completion0_query_idx_w], completion0_query_idx_w} ==
      completion0_query_producer_id_i;""",
        """  wire completion0_query_exact_w =
      completion0_query_idx_w ==
      completion0_query_producer_id_i[ROB_INDEX_W-1:0];""",
    ),
    "rob_current0_ignore_valid": (
        """  assign current0_query_match_o = current0_query_valid_i && !rst && !flush_i &&
      valid_q[current0_query_idx_w] && current0_query_exact_w &&
      !producer_target_killed_now(current0_query_idx_w);""",
        """  assign current0_query_match_o = current0_query_valid_i && !rst && !flush_i &&
      current0_query_exact_w &&
      !producer_target_killed_now(current0_query_idx_w);""",
    ),
    "rob_completion0_ignore_done": (
        """  assign completion0_query_match_o = completion0_query_valid_i && !rst && !flush_i &&
      valid_q[completion0_query_idx_w] && !done_q[completion0_query_idx_w] &&
      completion0_query_exact_w &&
      !producer_target_killed_now(completion0_query_idx_w);""",
        """  assign completion0_query_match_o = completion0_query_valid_i && !rst && !flush_i &&
      valid_q[completion0_query_idx_w] &&
      completion0_query_exact_w &&
      !producer_target_killed_now(completion0_query_idx_w);""",
    ),
    "rob_current0_ignore_kill": (
        """  assign current0_query_match_o = current0_query_valid_i && !rst && !flush_i &&
      valid_q[current0_query_idx_w] && current0_query_exact_w &&
      !producer_target_killed_now(current0_query_idx_w);""",
        """  assign current0_query_match_o = current0_query_valid_i && !rst && !flush_i &&
      valid_q[current0_query_idx_w] && current0_query_exact_w;""",
    ),
    "rob_completion0_ignore_kill": (
        """  assign completion0_query_match_o = completion0_query_valid_i && !rst && !flush_i &&
      valid_q[completion0_query_idx_w] && !done_q[completion0_query_idx_w] &&
      completion0_query_exact_w &&
      !producer_target_killed_now(completion0_query_idx_w);""",
        """  assign completion0_query_match_o = completion0_query_valid_i && !rst && !flush_i &&
      valid_q[completion0_query_idx_w] && !done_q[completion0_query_idx_w] &&
      completion0_query_exact_w;""",
    ),
    "rob_current1_lane_alias": (
        """  wire [ROB_INDEX_W-1:0] current1_query_idx_w = current1_query_valid_i ?
      current1_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};""",
        """  wire [ROB_INDEX_W-1:0] current1_query_idx_w = current1_query_valid_i ?
      current0_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};""",
    ),
    "iq_dispatch0_drop_generation": (
        "      producer_id_next_r[write_i] = dispatch0_producer_id_i;",
        "      producer_id_next_r[write_i] = {{(PRODUCER_ID_W-ROB_INDEX_W){1'b0}}, dispatch0_producer_id_i[ROB_INDEX_W-1:0]};",
    ),
    "iq_dispatch1_drop_generation": (
        "      producer_id_next_r[write_i] = dispatch1_producer_id_i;",
        "      producer_id_next_r[write_i] = {{(PRODUCER_ID_W-ROB_INDEX_W){1'b0}}, dispatch1_producer_id_i[ROB_INDEX_W-1:0]};",
    ),
    "iq_compaction_drop_generation": (
        "        producer_id_next_r[write_i] = producer_id_q[compact_i];",
        "        producer_id_next_r[write_i] = {{(PRODUCER_ID_W-ROB_INDEX_W){1'b0}}, producer_id_q[compact_i][ROB_INDEX_W-1:0]};",
    ),
    "iq_issue1_alias_issue0": (
        "  assign issue1_producer_id_o = producer_id_q[issue1_idx_w];",
        "  assign issue1_producer_id_o = issue0_producer_id_o;",
    ),
    "dispatch_current1_query_alias0": (
        "    .current1_query_producer_id_i(issue1_producer_id_o),",
        "    .current1_query_producer_id_i(issue0_producer_id_o),",
    ),
    "dispatch_completion1_query_alias0": (
        "    .completion1_query_producer_id_i(completion1_query_producer_id_i),",
        "    .completion1_query_producer_id_i(completion0_query_producer_id_i),",
    ),
    "backend_early0_raw_authority": (
        """  wire early_wakeup0_valid_w =
      early_wakeup0_raw_valid_w && iq_issue0_producer_current_w;""",
        """  wire early_wakeup0_valid_w =
      early_wakeup0_raw_valid_w;""",
    ),
    "backend_early1_raw_authority": (
        """  wire early_wakeup1_valid_w =
      early_wakeup1_raw_valid_w && issue1_producer_current_w;""",
        """  wire early_wakeup1_valid_w =
      early_wakeup1_raw_valid_w;""",
    ),
    "backend_ex0_no_open_gate": (
        "  assign ex0_wb_valid_w = ex0_pre_auth_valid_w && ex0_producer_open_w;",
        "  assign ex0_wb_valid_w = ex0_pre_auth_valid_w;",
    ),
    "backend_ex1_no_open_gate": (
        "  assign ex1_wb_valid_w = ex1_pre_auth_valid_w && ex1_producer_open_w;",
        "  assign ex1_wb_valid_w = ex1_pre_auth_valid_w;",
    ),
    "backend_mem_capture_drop_generation": (
        "      mem_issue_res_producer_id_q <= iq_issue0_producer_id_w;",
        "      mem_issue_res_producer_id_q <= {{PRODUCER_GEN_W{1'b0}}, iq_issue0_producer_id_w[ROB_INDEX_W-1:0]};",
    ),
    "backend_mem_terminal_use_iq_pid": (
        """  wire [PRODUCER_ID_W-1:0] ex0_up_producer_id_w =
      ex0_up_from_mem_w ? mem_issue_res_producer_id_q :
                          iq_issue0_producer_id_w;""",
        """  wire [PRODUCER_ID_W-1:0] ex0_up_producer_id_w =
      iq_issue0_producer_id_w;""",
    ),
    "backend_ex0_payload_drop_generation": (
        "      {ex0_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],",
        "      {{PRODUCER_GEN_W{1'b0}},",
    ),
    "backend_ex0_forward_raw": (
        "      ex0_wb_valid_w && ex0_down_payload_w[EX_STAGE_FWD_BIT];",
        "      ex0_valid_q && ex0_down_payload_w[EX_STAGE_FWD_BIT];",
    ),
    "backend_gpr0_raw": (
        "      (ex0_wb_valid_w && ex0_wb_pdest_nonzero_w) ||",
        "      (ex0_valid_q && ex0_wb_pdest_nonzero_w) ||",
    ),
    "backend_dispatch_wb0_raw": (
        "    .wb0_valid_i(wb0_valid_w),",
        "    .wb0_valid_i(ex0_valid_q),",
    ),
    "backend_fp_iq_wake1_raw": (
        "    .int_wake1_valid_i(gpr_wb1_write_valid_w),",
        "    .int_wake1_valid_i(ex1_valid_q),",
    ),
    "backend_execute0_raw": (
        "  assign execute0_valid_o = wb0_valid_w;",
        "  assign execute0_valid_o = ex0_valid_q;",
    ),
    "backend_slot0_uses_exact_valid": (
        "  assign ex0_wb_slot_occupied_w = ex0_pre_auth_valid_w;",
        "  assign ex0_wb_slot_occupied_w = ex0_wb_valid_w;",
    ),
    "backend_slot1_uses_exact_valid": (
        "  assign ex1_wb_slot_occupied_w = ex1_pre_auth_valid_w;",
        "  assign ex1_wb_slot_occupied_w = ex1_wb_valid_w;",
    ),
    "backend_slot0_uses_raw_valid": (
        "  assign ex0_wb_slot_occupied_w = ex0_pre_auth_valid_w;",
        "  assign ex0_wb_slot_occupied_w = ex0_valid_q;",
    ),
    "backend_slot1_uses_raw_valid": (
        "  assign ex1_wb_slot_occupied_w = ex1_pre_auth_valid_w;",
        "  assign ex1_wb_slot_occupied_w = ex1_valid_q;",
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
            f"[V8F-MUTATOR][FAIL] {args.mutation}: expected one anchor, found {count}"
        )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(source.replace(old, new, 1), encoding="utf-8")
    print(f"[V8F-MUTATOR][PASS] {args.mutation}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
