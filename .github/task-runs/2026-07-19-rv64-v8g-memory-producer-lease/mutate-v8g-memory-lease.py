#!/usr/bin/env python3
"""Emit one compile-valid v8g async-memory lease mutant."""

from __future__ import annotations

import argparse
from pathlib import Path


MUTATIONS: dict[str, tuple[str, str]] = {
    "tracker_alloc0_ignore_live_pid": (
        """  assign alloc0_ready_o = PARAM_SHAPE_VALID && alloc0_found_r &&
      (alloc0_kind_i != OWNER_KIND_RESERVED) && alloc0_pid_clear_w;""",
        """  assign alloc0_ready_o = PARAM_SHAPE_VALID && alloc0_found_r &&
      (alloc0_kind_i != OWNER_KIND_RESERVED);""",
    ),
    "tracker_dual_duplicate_pid": (
        """  assign alloc1_ready_o = PARAM_SHAPE_VALID && alloc1_found_r &&
      (alloc1_kind_i != OWNER_KIND_RESERVED) && alloc1_pid_clear_w &&
      !(alloc0_claim_w &&
        (alloc1_producer_id_i == alloc0_producer_id_i));""",
        """  assign alloc1_ready_o = PARAM_SHAPE_VALID && alloc1_found_r &&
      (alloc1_kind_i != OWNER_KIND_RESERVED) && alloc1_pid_clear_w;""",
    ),
    "rob_query2_ignore_generation": (
        """  wire completion2_query_exact_w =
      {slot_generation_q[completion2_query_idx_w], completion2_query_idx_w} ==
      completion2_query_producer_id_i;""",
        """  wire completion2_query_exact_w =
      completion2_query_idx_w ==
      completion2_query_producer_id_i[ROB_INDEX_W-1:0];""",
    ),
    "rob_query2_ignore_done": (
        """  assign completion2_query_match_o = completion2_query_valid_i && !rst && !flush_i &&
      valid_q[completion2_query_idx_w] && !done_q[completion2_query_idx_w] &&
      completion2_query_exact_w &&
      !producer_target_killed_now(completion2_query_idx_w);""",
        """  assign completion2_query_match_o = completion2_query_valid_i && !rst && !flush_i &&
      valid_q[completion2_query_idx_w] &&
      completion2_query_exact_w &&
      !producer_target_killed_now(completion2_query_idx_w);""",
    ),
    "rob_head_launch_ignore_done": (
        """  assign head0_launch_open_o = !rst && !flush_i && !recovering_w &&
      (count_q != {ROB_COUNT_W{1'b0}}) && valid_q[head_q] &&
      !done_q[head_q];""",
        """  assign head0_launch_open_o = !rst && !flush_i && !recovering_w &&
      (count_q != {ROB_COUNT_W{1'b0}}) && valid_q[head_q];""",
    ),
    "dispatch_lane0_ignore_memory_lease": (
        """                             dispatch1_pair_ready_w &&
                             !memory_producer_live_mask_i[
                                 rob_dispatch0_producer_id_w] &&
                             !dispatch_freeze_w;""",
        """                             dispatch1_pair_ready_w &&
                             !dispatch_freeze_w;""",
    ),
    "dispatch_pair_ignore_memory_lease": (
        """       free_ok1_pair_w && sq_ok1_w &&
       !memory_producer_live_mask_i[
           rob_dispatch1_pair_producer_id_w]);""",
        """       free_ok1_pair_w && sq_ok1_w);""",
    ),
    "dispatch_lane1_ignore_memory_lease": (
        """                             free_ok1_w && sq_ok1_w &&
                             !memory_producer_live_mask_i[
                                 rob_dispatch1_producer_id_w];""",
        """                             free_ok1_w && sq_ok1_w;""",
    ),
    "sq_request_ignore_full_pid": (
        """      rob_head_launch_open_i &&
      (producer_id_q[head_q] == rob_head_producer_id_i) &&
      (rob_idx_q[head_q] == rob_head_idx_i);""",
        """      rob_head_launch_open_i &&
      (rob_idx_q[head_q] == rob_head_idx_i);""",
    ),
    "sq_release_ignore_full_pid": (
        """  assign release_ready_o =
      head_valid_w &&
      (producer_id_q[head_q] == release_producer_id_i) &&
      (rob_idx_q[head_q] == release_rob_idx_i) &&
      (terminal_q[head_q] || terminal_head_now_w);""",
        """  assign release_ready_o =
      head_valid_w &&
      (rob_idx_q[head_q] == release_rob_idx_i) &&
      (terminal_q[head_q] || terminal_head_now_w);""",
    ),
    "sq_release_after_request_sent": (
        "      (terminal_q[head_q] || terminal_head_now_w);",
        "      (request_sent_q[head_q] || terminal_q[head_q] || terminal_head_now_w);",
    ),
    "sq_request_marks_terminal": (
        """      if (req_fire_i && req_valid_o)
        request_sent_q[head_q] <= 1'b1;""",
        """      if (req_fire_i && req_valid_o) begin
        request_sent_q[head_q] <= 1'b1;
        terminal_q[head_q] <= 1'b1;
      end""",
    ),
    "backend_ingress_ignore_current": (
        """  wire mem_issue_res_capture_candidate_w =
      mem_issue_res_present_candidate_w && iq_issue0_producer_current_w;""",
        """  wire mem_issue_res_capture_candidate_w =
      mem_issue_res_present_candidate_w;""",
    ),
    "backend_tracker_ignore_kind": (
        """      (mem_owner_kind_table_w[miq_head_owner_token_w*2 +: 2] ==
       miq_head_owner_kind_w) &&
""",
        "",
    ),
    "backend_tracker_ignore_epoch": (
        """      (mem_owner_epoch_table_w[miq_head_owner_token_w*2 +: 2] ==
       miq_head_mmu_epoch_w);""",
        """      1'b1;""",
    ),
    "backend_query_ignore_tracker_exact": (
        """  assign mem_completion_query_valid_w = mem_rsp_valid_i &&
      miq_head_valid_w && miq_pop_owner_match_w &&
      miq_head_tracker_exact_w;""",
        """  assign mem_completion_query_valid_w = mem_rsp_valid_i &&
      miq_head_valid_w && miq_pop_owner_match_w;""",
    ),
    "backend_amo_read_ignore_owner_open": (
        """  wire mem_amo_read_candidate_w = mem_owner_open_w &&
      miq_head_legacy_w && mem_pending_q && mem_amo_q &&""",
        """  wire mem_amo_read_candidate_w =
      miq_head_legacy_w && mem_pending_q && mem_amo_q &&""",
    ),
    "backend_fatal_enters_normal_final": (
        """  wire mem_rsp_final_fire_w = mem_rsp_fire_w && !mem_amo_read_rsp_w &&
      !mem_fatal_irrevocable_response_w;""",
        """  wire mem_rsp_final_fire_w = mem_rsp_fire_w && !mem_amo_read_rsp_w;""",
    ),
    "backend_load_wb_ignore_owner_open": (
        """  wire miq_load_wb_fire_w =
      miq_load_rsp_fire_w && mem_owner_open_w;""",
        """  wire miq_load_wb_fire_w =
      miq_load_rsp_fire_w;""",
    ),
    "backend_issue1_ignore_response_wait": (
        """  assign issue1_ready_w = !flush_i && !checkpoint_restore_i &&
                          !issue_block_w &&
                          !mem_rsp_waiting_for_wb_w;""",
        """  assign issue1_ready_w = !flush_i && !checkpoint_restore_i &&
                          !issue_block_w;""",
    ),
    "backend_memory_loses_wb1": (
        """  wire mem_rsp_to_wb1_w = mem_wb_fire_w && !mem_rsp_to_wb0_w;""",
        """  wire mem_rsp_to_wb1_w = mem_wb_fire_w && !mem_rsp_to_wb0_w && 1'b0;""",
    ),
    "backend_amo_write_launch_completes_early": (
        """  wire mem_legacy_wb_fire_w =
      mem_rsp_final_fire_w && mem_owner_open_w;""",
        """  wire mem_legacy_wb_fire_w =
      (mem_rsp_final_fire_w && mem_owner_open_w) || push_amo_write_w;""",
    ),
    "backend_store_request_terminals_early": (
        """  wire mem_terminal_rsp_valid_w =
      mem_rsp_final_fire_w ||""",
        """  wire mem_terminal_rsp_valid_w =
      sq_drain_req_fire_w || mem_rsp_final_fire_w ||""",
    ),
    "bridge_drop_reads_stage_advance": (
        """    if ((flush_i || drop_rsp_q) && !nokill_busy_w) begin
      case (state_q)""",
        """    if (stage_advance_w && cpu_kill_w && !nokill_busy_w &&
        (state_q != S_IDLE)) begin
      // Functionally redundant, but closes a collector-ready combinational loop.
      active_drop_terminal_r = 1'b1;
    end else if ((flush_i || drop_rsp_q) && !nokill_busy_w) begin
      case (state_q)""",
    ),
    "bridge_station_query_reads_advance": (
        "  assign mem0_station_query_valid_o = stg_valid_q;",
        "  assign mem0_station_query_valid_o = stage_advance_w;",
    ),
    "bridge_station_drop_reads_advance": (
        """  wire station_drop_terminal_w =
      flush_i && stg_valid_q && !stg_nokill_q;""",
        """  wire station_drop_terminal_w = flush_i && stg_valid_q &&
      !stg_nokill_q && !stage_advance_w;""",
    ),
    "backend_local_terminal_reads_consume": (
        """  wire mem_issue_res_local_complete_w =
      mem_issue_res_valid_q && issue0_global_ready_w &&
      !branch_resolve_mispredict_w && !issue0_sc_premature_w &&
      (!issue0_is_mem_w ||
       (issue0_mem_issue_eligible_w &&
        (issue0_mem_exception_w || issue0_sq_fwd_w)));""",
        """  wire mem_issue_res_local_complete_w =
      mem_issue_res_consume_fire_w &&
      (!issue0_is_mem_w || issue0_mem_exception_w || issue0_sq_fwd_w);""",
    ),
    "backend_raw_mask_reads_packed_vector": (
        """  assign mem_terminal_ingress1_mask_w =
      mem_drop0_valid_i ?
      (32'b1 << mem_drop0_owner_token_i) : 32'b0;""",
        """  assign mem_terminal_ingress1_mask_w =
      mem_terminal_ingress_valid_w[1] ?
      (32'b1 << mem_terminal_ingress_token_w[9:5]) : 32'b0;""",
    ),
}

MULTI_MUTATIONS: dict[str, tuple[tuple[str, str], ...]] = {
    "backend_buffer_kill_handoff_ready_loop": (
        (
            """  wire grant_buffer_w =
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !mem_buffer_kill_w &&
      mem_buffer_req_valid_w;""",
            """  wire grant_buffer_w =
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && mem_buffer_req_valid_w;""",
        ),
        (
            """  wire mem_buffer_cancel_w = mem_buffer_valid_q &&
      (mem_buffer_kill_w || flush_i || checkpoint_restore_i);""",
            """  wire mem_buffer_cancel_w = mem_buffer_valid_q &&
      (mem_buffer_kill_w || flush_i || checkpoint_restore_i) &&
      !mem_buffer_req_fire_w;""",
        ),
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "mutation", choices=sorted(set(MUTATIONS) | set(MULTI_MUTATIONS))
    )
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    source = args.source.read_text(encoding="utf-8")
    replacements = (
        (MUTATIONS[args.mutation],)
        if args.mutation in MUTATIONS
        else MULTI_MUTATIONS[args.mutation]
    )
    for old, new in replacements:
        count = source.count(old)
        if count != 1:
            raise SystemExit(
                f"[V8G-MUTATOR][FAIL] {args.mutation}: "
                f"expected one anchor, found {count}"
            )
        source = source.replace(old, new, 1)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(source, encoding="utf-8")
    print(f"[V8G-MUTATOR][PASS] {args.mutation}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
