#!/usr/bin/env python3
"""Create one compile-success F2 semantic mutant in a temporary RTL source."""

from __future__ import annotations

import argparse
from pathlib import Path


MUTATIONS: dict[str, tuple[str, str]] = {
    "bank1_tieoff": (
        "assign mem1_req_valid_o = ENABLE_DUAL_MEM &&\n"
        "      (grant_mem1_issue0_w || grant_mem1_issue1_w);",
        "assign mem1_req_valid_o = 1'b0;",
    ),
    "swap_bank_mapping": (
        "wire issue0_dual_bank1_w = issue0_mem_addr_w[3];\n"
        "  wire issue1_dual_bank1_w = issue1_mem_addr_w[3];",
        "wire issue0_dual_bank1_w = ~issue0_mem_addr_w[3];\n"
        "  wire issue1_dual_bank1_w = ~issue1_mem_addr_w[3];",
    ),
    "invert_same_bank_age": (
        "wire issue0_dual_older_or_tie_w = !rob_idx_older_than(\n"
        "      mem_issue1_res_rob_idx_q, mem_issue_res_rob_idx_q, rob_head_idx_w);",
        "wire issue0_dual_older_or_tie_w = rob_idx_older_than(\n"
        "      mem_issue1_res_rob_idx_q, mem_issue_res_rob_idx_q, rob_head_idx_w);",
    ),
    "alias_miq1_completion_head": (
        "assign mem1_completion_producer_id_w =\n"
        "      mem_owner_producer_id_table_w[\n"
        "          miq1_head_owner_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];",
        "assign mem1_completion_producer_id_w =\n"
        "      mem_owner_producer_id_table_w[\n"
        "          miq_head_owner_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];",
    ),
    "double_claim_wb0": (
        "wire mem1_wb_slot0_grant_w = mem1_open_needs_wb_w &&\n"
        "      mem1_open_nonwb_sink_credit_w && !ex0_wb_slot_occupied_w &&\n"
        "      !mem_wb_slot0_grant_w;",
        "wire mem1_wb_slot0_grant_w = mem1_open_needs_wb_w &&\n"
        "      mem1_open_nonwb_sink_credit_w && !ex0_wb_slot_occupied_w;",
    ),
    "tieoff_sq_terminal1": (
        "wire sq_terminal1_valid_w = sq_terminal1_local1_w ||\n"
        "      sq_terminal1_rsp0_w || sq_terminal1_rsp1_w;",
        "wire sq_terminal1_valid_w = 1'b0;",
    ),
    "duplicate_bridge_drop_token": (
        "mem1_drop1_owner_token_i,\n"
        "      mem1_drop0_owner_token_i,\n"
        "      mem_drop1_owner_token_i,\n"
        "      mem_drop0_owner_token_i,",
        "mem1_drop1_owner_token_i,\n"
        "      mem_drop0_owner_token_i,\n"
        "      mem_drop1_owner_token_i,\n"
        "      mem_drop0_owner_token_i,",
    ),
    "allow_killed_mem1_wb": (
        "wire mem1_owner_open_w = mem1_response_tuple_exact_w &&\n"
        "      miq1_head_tracker_exact_w && mem1_completion_rob_open_w &&\n"
        "      !miq1_head_effective_killed_w && !mem1_completion_done_now_w;",
        "wire mem1_owner_open_w = mem1_response_tuple_exact_w &&\n"
        "      miq1_head_tracker_exact_w && !mem1_completion_done_now_w;",
    ),
    "ordinary_store_direct_write": (
        "assign mem1_req_probe_o = grant_mem1_issue0_w ?\n"
        "      (sq_mode_w && issue0_is_plain_store_w) :\n"
        "      (grant_mem1_issue1_w && sq_mode_w && issue1_is_plain_store_w);",
        "assign mem1_req_probe_o = 1'b0;",
    ),
    "singleton_priority_bypass": (
        "wire grant_mem1_issue1_w = ENABLE_DUAL_MEM &&\n"
        "      mem_request_transport_open_w && !grant_sq_w &&\n"
        "      !grant_amo_write_w && !grant_buffer_w &&\n"
        "      issue1_dual_selected_w &&\n"
        "      issue1_dual_bank1_w && !grant_mem1_issue0_w;",
        "wire grant_mem1_issue1_w =\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       !grant_sq_w && !grant_amo_write_w && !grant_buffer_w &&\n"
        "       issue1_dual_selected_w && issue1_dual_bank1_w &&\n"
        "       !grant_mem1_issue0_w) ||\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       mem_amo_write_req_valid_w && mem_issue1_res_valid_q &&\n"
        "       issue1_dual_bank1_w);",
    ),
    "legacy_release_lookthrough": (
        "wire grant_mem1_issue1_w = ENABLE_DUAL_MEM &&\n"
        "      mem_request_transport_open_w && !grant_sq_w &&\n"
        "      !grant_amo_write_w && !grant_buffer_w &&\n"
        "      issue1_dual_selected_w &&\n"
        "      issue1_dual_bank1_w && !grant_mem1_issue0_w;",
        "wire grant_mem1_issue1_w =\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       !grant_sq_w && !grant_amo_write_w && !grant_buffer_w &&\n"
        "       issue1_dual_selected_w && issue1_dual_bank1_w &&\n"
        "       !grant_mem1_issue0_w) ||\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       mem_rsp_final_fire_w && mem_issue1_res_valid_q &&\n"
        "       issue1_dual_bank1_w);",
    ),
    "omit_checkpoint_lq_recovery": (
        ".flush_valid_i(flush_i || checkpoint_restore_apply_w ||\n"
        "                   branch_resolve_mispredict_w),\n"
        "    .flush_all_i(flush_i || checkpoint_restore_apply_w),",
        ".flush_valid_i(flush_i || branch_resolve_mispredict_w),\n"
        "    .flush_all_i(flush_i),",
    ),
    "omit_checkpoint_dispatch_recovery": (
        ".head0_identity_o(head0_identity_o),\n"
        "    .rst(rst),\n"
        "    .flush_i(flush_i || checkpoint_restore_apply_w),",
        ".head0_identity_o(head0_identity_o),\n"
        "    .rst(rst),\n"
        "    .flush_i(flush_i),",
    ),
    "omit_checkpoint_sq_recovery": (
        ".flush_valid_i(sq_flush_valid_w),\n"
        "    .flush_all_i(flush_i || checkpoint_restore_apply_w),",
        ".flush_valid_i(sq_flush_valid_w),\n"
        "    .flush_all_i(flush_i),",
    ),
    "bypass_lq_retire_permit": (
        ".commit_ready_i(commit_ready_i && !checkpoint_capture_i &&\n"
        "                    !checkpoint_restore_apply_w && !checkpoint_quiesce_i &&\n"
        "                    lq_retire0_permit_w),",
        ".commit_ready_i(commit_ready_i && !checkpoint_capture_i &&\n"
        "                    !checkpoint_restore_apply_w && !checkpoint_quiesce_i),",
    ),
    "bypass_checkpoint_irrevocable_guard": (
        "assign checkpoint_restore_apply_w =\n"
        "      (checkpoint_restore_new_req_w || checkpoint_restore_pending_q) &&\n"
        "      !checkpoint_irrevocable_write_q && sq_no_active_write_w &&\n"
        "      !drain_inflight_q;",
        "assign checkpoint_restore_apply_w =\n"
        "      checkpoint_restore_new_req_w || checkpoint_restore_pending_q;",
    ),
    "bypass_checkpoint_commit1_block": (
        ".commit1_block_i(commit1_block_i || !lq_retire1_permit_w ||\n"
        "                     checkpoint_restore_hold_w),",
        ".commit1_block_i(commit1_block_i || !lq_retire1_permit_w),",
    ),
    "raw_checkpoint_local_flush_bypass": (
        "assign core_local_flush_o =\n"
        "      flush_i || core_trap_flush_i || core_serial_flush_i;",
        "assign core_local_flush_o =\n"
        "      flush_i || core_trap_flush_i || core_serial_flush_i ||\n"
        "      branch_spec_restore_i;",
    ),
}

# F3 inserts bank-local retry arbitration ahead of the original F2 bank1
# request sources.  Keep the predecessor mutations observable in either exact
# phase without accepting a partially mixed anchor set.
F3_MUTATIONS: dict[str, tuple[str, str]] = {
    "bank1_tieoff": (
        "assign mem1_req_valid_o = ENABLE_DUAL_MEM &&\n"
        "      (grant_retry1_w || grant_mem1_issue0_w || "
        "grant_mem1_issue1_w);",
        "assign mem1_req_valid_o = 1'b0;",
    ),
    "ordinary_store_direct_write": (
        "assign mem1_req_probe_o = grant_retry1_w ? 1'b0 :\n"
        "      grant_mem1_issue0_w ?\n"
        "      (sq_mode_w && issue0_is_plain_store_w) :\n"
        "      (grant_mem1_issue1_w && sq_mode_w && issue1_is_plain_store_w);",
        "assign mem1_req_probe_o = 1'b0;",
    ),
    "singleton_priority_bypass": (
        "wire grant_mem1_issue1_w = ENABLE_DUAL_MEM &&\n"
        "      mem_request_transport_open_w && !grant_sq_w &&\n"
        "      !grant_amo_write_w && !grant_buffer_w && !grant_retry1_w &&\n"
        "      issue1_dual_selected_w &&\n"
        "      issue1_dual_bank1_w && !grant_mem1_issue0_w;",
        "wire grant_mem1_issue1_w =\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       !grant_sq_w && !grant_amo_write_w && !grant_buffer_w &&\n"
        "       !grant_retry1_w && issue1_dual_selected_w &&\n"
        "       issue1_dual_bank1_w && !grant_mem1_issue0_w) ||\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       mem_amo_write_req_valid_w && mem_issue1_res_valid_q &&\n"
        "       issue1_dual_bank1_w);",
    ),
    "legacy_release_lookthrough": (
        "wire grant_mem1_issue1_w = ENABLE_DUAL_MEM &&\n"
        "      mem_request_transport_open_w && !grant_sq_w &&\n"
        "      !grant_amo_write_w && !grant_buffer_w && !grant_retry1_w &&\n"
        "      issue1_dual_selected_w &&\n"
        "      issue1_dual_bank1_w && !grant_mem1_issue0_w;",
        "wire grant_mem1_issue1_w =\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       !grant_sq_w && !grant_amo_write_w && !grant_buffer_w &&\n"
        "       !grant_retry1_w && issue1_dual_selected_w &&\n"
        "       issue1_dual_bank1_w && !grant_mem1_issue0_w) ||\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       mem_rsp_final_fire_w && mem_issue1_res_valid_q &&\n"
        "       issue1_dual_bank1_w);",
    ),
}

# v8v inserts the shared retire-resident LQ between the base response
# authorization and the final owner-open signal.  Preserve the original F2
# counterexample strength by explicitly bypassing both the effective-kill cut
# and the LQ response disposition for the killed bank1 LOAD; merely deleting
# the old base-open predicate would now remain fail-closed in the LQ.
V8V_MUTATIONS: dict[str, tuple[str, str]] = {
    "allow_killed_mem1_wb": (
        "wire mem1_owner_open_w = mem1_owner_base_open_w &&\n"
        "      (!miq1_head_load_w || lq_response1_open_w);",
        "wire mem1_owner_open_w = mem1_response_tuple_exact_w &&\n"
        "      miq1_head_tracker_exact_w &&\n"
        "      (!miq1_head_load_w || lq_response1_open_w ||\n"
        "       miq1_head_effective_killed_w);",
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    expected_source = (
        "OooCoreSliceControlGate.v"
        if args.mutation == "raw_checkpoint_local_flush_bypass"
        else "OooIntBackend.v"
    )
    if args.source.name != expected_source:
        raise SystemExit(
            f"[V8S-MUTATOR][FAIL] expected {expected_source}, "
            f"got {args.source.name}"
        )
    text = args.source.read_text(encoding="utf-8")
    candidates = [MUTATIONS[args.mutation]]
    if args.mutation in F3_MUTATIONS:
        candidates.append(F3_MUTATIONS[args.mutation])
    if args.mutation in V8V_MUTATIONS:
        candidates.append(V8V_MUTATIONS[args.mutation])
    hits = [
        (old, new) for old, new in candidates if text.count(old) == 1
    ]
    if len(hits) != 1:
        counts = [text.count(old) for old, _ in candidates]
        raise SystemExit(
            f"[V8S-MUTATOR][FAIL] {args.mutation}: "
            f"expected one exact phase anchor, got counts={counts}"
        )
    old, new = hits[0]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(
        f"[V8S-MUTATOR][PASS] name={args.mutation} "
        f"source={args.source} output={args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
