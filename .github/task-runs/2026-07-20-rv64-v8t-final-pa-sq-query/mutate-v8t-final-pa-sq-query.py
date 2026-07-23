#!/usr/bin/env python3
"""Create one compile-success v8t/F3 semantic mutant in a temp source."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Mutation:
    source_name: str
    replacements: tuple[tuple[str, str, int], ...]


MUTATIONS: dict[str, Mutation] = {
    "sq_compare_va": Mutation("OooStoreQueue.v", ((
        "store_byte_addr_r = paddr_q[entry_idx_r] + store_byte_i;",
        "store_byte_addr_r = vaddr_q[entry_idx_r] + store_byte_i;", 2,
    ),)),
    "sq_partial_allow": Mutation("OooStoreQueue.v", ((
        "case ((covered_r & query0_strb_i) == query0_strb_i)\n"
        "                  1'b1: query0_forward_r = 1'b1;\n"
        "                  default: query0_replay_r = 1'b1;",
        "case (|(covered_r & query0_strb_i))\n"
        "                  1'b1: query0_forward_r = 1'b1;\n"
        "                  default: query0_replay_r = 1'b1;", 1,
    ),)),
    "sq_include_terminal": Mutation("OooStoreQueue.v", ((
        "if (valid_q[entry_idx_r] && entry_older_r &&\n"
        "          !terminal_q[entry_idx_r]) begin",
        "if (valid_q[entry_idx_r] && entry_older_r) begin", 2,
    ),)),
    "sq_oldest_byte_wins": Mutation("OooStoreQueue.v", ((
        "covered_r[load_byte_i] = 1'b1;\n"
        "                  query0_forward_data_r[load_byte_i*8 +: 8] =\n"
        "                      data_q[entry_idx_r][store_byte_i*8 +: 8];",
        "if (!covered_r[load_byte_i]) begin\n"
        "                    covered_r[load_byte_i] = 1'b1;\n"
        "                    query0_forward_data_r[load_byte_i*8 +: 8] =\n"
        "                        data_q[entry_idx_r][store_byte_i*8 +: 8];\n"
        "                  end", 1,
    ),)),
    "sq_io_allow": Mutation("OooStoreQueue.v", ((
        "end else if ((query0_class_i == `OOO_MEM_CLASS_IO) ||\n"
        "                     (class_q[entry_idx_r] == `OOO_MEM_CLASS_IO)) begin\n"
        "          poison_r = 1'b1;",
        "end else if (1'b0) begin\n"
        "          poison_r = 1'b1;", 1,
    ),)),
    "sq_unfilled_allow": Mutation("OooStoreQueue.v", ((
        "if (!filled_q[entry_idx_r] ||\n"
        "            !typed_attr_admitted(attr_valid_q[entry_idx_r],\n"
        "                                 class_q[entry_idx_r]) ||\n"
        "            (strb_q[entry_idx_r] == {`STRB_W{1'b0}})) begin\n"
        "          poison_r = 1'b1;",
        "if (1'b0) begin\n"
        "          poison_r = 1'b1;", 2,
    ),)),
    "sq_invalid_metadata_allow": Mutation("OooStoreQueue.v", ((
        "default: query0_replay_r = 1'b1;\n"
        "        endcase\n"
        "      end\n"
        "      default: begin end",
        "default: query0_allow_r = 1'b1;\n"
        "        endcase\n"
        "      end\n"
        "      default: begin end", 1,
    ),)),
    "sq_age_linear0": Mutation("OooStoreQueue.v", ((
        "rob_dist(rob_idx_q[entry_idx_r], rob_head_idx_i) <\n"
        "            rob_dist(query0_producer_id_i[ROB_INDEX_W-1:0],\n"
        "                     rob_head_idx_i)",
        "rob_idx_q[entry_idx_r] <\n"
        "            query0_producer_id_i[ROB_INDEX_W-1:0]", 1,
    ),)),
    "sq_age_equal0": Mutation("OooStoreQueue.v", ((
        "rob_dist(rob_idx_q[entry_idx_r], rob_head_idx_i) <\n"
        "            rob_dist(query0_producer_id_i[ROB_INDEX_W-1:0],\n"
        "                     rob_head_idx_i)",
        "rob_dist(rob_idx_q[entry_idx_r], rob_head_idx_i) <=\n"
        "            rob_dist(query0_producer_id_i[ROB_INDEX_W-1:0],\n"
        "                     rob_head_idx_i)", 1,
    ),)),
    "sq_query1_paddr_cross": Mutation("OooStoreQueue.v", ((
        "load_byte_addr_r = query1_paddr_i + load_byte_i;",
        "load_byte_addr_r = query0_paddr_i + load_byte_i;", 1,
    ),)),
    "sq_query1_poison_allow": Mutation("OooStoreQueue.v", ((
        "default: query1_replay_r = 1'b1;\n"
        "        endcase\n"
        "      end\n"
        "      default: begin end",
        "default: query1_allow_r = 1'b1;\n"
        "        endcase\n"
        "      end\n"
        "      default: begin end", 1,
    ),)),
    "bridge_hold_replay": Mutation("OooMemAxiBridge.v", ((
        "end else if (sq_query_retry_fire_w) begin\n"
        "            state_q <= S_IDLE;",
        "end else if (sq_query_retry_fire_w) begin\n"
        "            state_q <= S_SQ_QUERY;", 1,
    ),)),
    "bridge_release_without_credit": Mutation("OooMemAxiBridge.v", ((
        "end else if (sq_query_retry_fire_w) begin",
        "end else if (mem0_sq_query_valid_o && mem0_sq_query_replay_i) begin",
        1,
    ),)),
    "bridge_route_bare_bypass": Mutation("OooMemAxiBridge.v", ((
        "if (stg_owner_kind_q == MEM_OWNER_LOAD) begin\n"
        "          state_q <= S_SQ_QUERY;",
        "if (stg_owner_kind_q == MEM_OWNER_LOAD) begin\n"
        "          state_q <= S_LOOKUP;", 1,
    ),)),
    "bridge_route_ptw_bypass": Mutation("OooMemAxiBridge.v", ((
        "if (active_owner_kind_q == MEM_OWNER_LOAD)\n"
        "                    state_q <= S_SQ_QUERY;\n"
        "                  else if (walk_leaf_dcacheable_w)",
        "if (active_owner_kind_q == MEM_OWNER_LOAD)\n"
        "                    state_q <= S_LOOKUP;\n"
        "                  else if (walk_leaf_dcacheable_w)", 1,
    ),)),
    "bridge_route_ad_bypass": Mutation("OooMemAxiBridge.v", ((
        "if (active_owner_kind_q == MEM_OWNER_LOAD)\n"
        "                state_q <= S_SQ_QUERY;\n"
        "              else if (access_cacheable_w)",
        "if (active_owner_kind_q == MEM_OWNER_LOAD)\n"
        "                state_q <= S_LOOKUP;\n"
        "              else if (access_cacheable_w)", 1,
    ),)),
    "bridge_forward_lookup": Mutation("OooMemAxiBridge.v", ((
        "rsp_page_fault_q <= 1'b0;\n"
        "            state_q <= S_RESP;\n"
        "          end else if (mem0_sq_query_valid_o &&",
        "rsp_page_fault_q <= 1'b0;\n"
        "            state_q <= S_LOOKUP;\n"
        "          end else if (mem0_sq_query_valid_o &&", 1,
    ),)),
    "bridge_dtlb_fault_query": Mutation("OooMemAxiBridge.v", ((
        "end else if (req_translate_w && req_dtlb_perm_fault_w) begin\n"
        "        rsp_error_q <= 1'b1;\n"
        "        rsp_page_fault_q <= 1'b1;\n"
        "        state_q <= S_RESP;",
        "end else if (req_translate_w && req_dtlb_perm_fault_w) begin\n"
        "        rsp_error_q <= 1'b1;\n"
        "        rsp_page_fault_q <= 1'b1;\n"
        "        state_q <= S_SQ_QUERY;", 1,
    ),)),
    "bridge_pmp_fault_query": Mutation("OooMemAxiBridge.v", ((
        "end else if (req_data_pmp_fault_w) begin\n"
        "        rsp_error_q <= 1'b1;\n"
        "        rsp_page_fault_q <= 1'b0;\n"
        "        state_q <= S_RESP;",
        "end else if (req_data_pmp_fault_w) begin\n"
        "        rsp_error_q <= 1'b1;\n"
        "        rsp_page_fault_q <= 1'b0;\n"
        "        state_q <= S_SQ_QUERY;", 1,
    ),)),
    "bridge_late_ad_dtlb_fill": Mutation("OooMemAxiBridge.v", ((
        "wire dtlb_fill_valid_w =\n"
        "      active_expected_identity_match_w",
        "wire dtlb_fill_valid_w =\n"
        "      (killed_write_maintenance_authorized_w && "
        "ad_update_b_ok_w) ||\n"
        "      active_expected_identity_match_w", 1,
    ),)),
    "retry_no_pop0": Mutation("OooIntBackend.v", ((
        "miq_pop_transport_w || mem_sq_retry0_capture_w",
        "miq_pop_transport_w", 1,
    ),)),
    "retry_no_pop1": Mutation("OooIntBackend.v", ((
        "miq1_pop_transport_w || mem_sq_retry1_capture_w",
        "miq1_pop_transport_w", 1,
    ),)),
    "retry_wrong_token1": Mutation("OooIntBackend.v", ((
        "assign mem1_req_owner_token_o = grant_retry1_w ?\n"
        "      mem_retry1_owner_token_q : grant_mem1_issue0_w ?",
        "assign mem1_req_owner_token_o = grant_retry1_w ?\n"
        "      5'b0 : grant_mem1_issue0_w ?", 1,
    ),)),
    "retry_wrong_token0": Mutation("OooIntBackend.v", ((
        "grant_buffer_w ? mem_buffer_owner_token_q :\n"
        "      grant_retry0_w ? mem_retry0_owner_token_q :",
        "grant_buffer_w ? mem_buffer_owner_token_q :\n"
        "      grant_retry0_w ? 5'b0 :", 1,
    ),)),
    "retry_silent_kill0": Mutation("OooIntBackend.v", ((
        "wire mem_retry0_tagged_terminal_w = mem_retry0_cancel_w;",
        "wire mem_retry0_tagged_terminal_w = 1'b0;", 1,
    ),)),
    "retry_silent_kill1": Mutation("OooIntBackend.v", ((
        "wire mem_retry1_tagged_terminal_w = mem_retry1_cancel_w;",
        "wire mem_retry1_tagged_terminal_w = 1'b0;", 1,
    ),)),
    "retry_priority_invert1": Mutation("OooIntBackend.v", ((
        "wire mem_retry1_selected_w = mem_retry1_candidate_w &&\n"
        "      !mem_bank1_store_older_than_retry_w;",
        "wire mem_retry1_selected_w = mem_retry1_candidate_w &&\n"
        "      mem_bank1_store_older_than_retry_w;", 1,
    ),)),
    "retry_priority_invert0": Mutation("OooIntBackend.v", ((
        "wire mem_retry0_selected_w = mem_retry0_candidate_w &&\n"
        "      !mem_bank0_store_older_than_retry_w;",
        "wire mem_retry0_selected_w = mem_retry0_candidate_w &&\n"
        "      mem_bank0_store_older_than_retry_w;", 1,
    ),)),
    "retry_load_fence_delete1": Mutation("OooIntBackend.v", ((
        "mem_bank1_load_admission_block_w = mem_retry1_valid_q ||\n"
        "      mem1_bridge_active_load_w || mem1_bridge_station_load_w",
        "mem_bank1_load_admission_block_w =\n"
        "      mem1_bridge_active_load_w || mem1_bridge_station_load_w", 1,
    ),)),
    "retry_load_fence_delete0": Mutation("OooIntBackend.v", ((
        "mem_bank0_load_admission_block_w = mem_retry0_valid_q ||\n"
        "      mem_bridge_active_load_w || mem_bridge_station_load_w",
        "mem_bank0_load_admission_block_w =\n"
        "      mem_bridge_active_load_w || mem_bridge_station_load_w", 1,
    ),)),
    "retry_active_fence_delete1": Mutation("OooIntBackend.v", ((
        "mem_bank1_load_admission_block_w = mem_retry1_valid_q ||\n"
        "      mem1_bridge_active_load_w || mem1_bridge_station_load_w",
        "mem_bank1_load_admission_block_w = mem_retry1_valid_q ||\n"
        "      mem1_bridge_station_load_w", 1,
    ),)),
    "retry_station_fence_delete1": Mutation("OooIntBackend.v", ((
        "mem_bank1_load_admission_block_w = mem_retry1_valid_q ||\n"
        "      mem1_bridge_active_load_w || mem1_bridge_station_load_w",
        "mem_bank1_load_admission_block_w = mem_retry1_valid_q ||\n"
        "      mem1_bridge_active_load_w", 1,
    ),)),
    "retry_cancel_priority_delete1": Mutation("OooIntBackend.v", ((
        "end else if (mem_retry1_cancel_w || mem_retry1_req_fire_w) begin",
        "end else if (mem_retry1_req_fire_w) begin", 1,
    ),)),
    "retry_fp_capture_drop1": Mutation("OooIntBackend.v", ((
        "mem_retry1_pdest_fp_q <= miq1_head_pdest_fp_w;",
        "mem_retry1_pdest_fp_q <= 1'b0;", 1,
    ),)),
    "retry_fp_repush_drop1": Mutation("OooIntBackend.v", ((
        "assign miq1_push_pdest_fp_w = push_retry1_w ? "
        "mem_retry1_pdest_fp_q :",
        "assign miq1_push_pdest_fp_w = push_retry1_w ? 1'b0 :", 1,
    ),)),
    "dual_slot_valid_bypass": Mutation("OooIntBackend.v", ((
        "issue1_dual_ordinary_candidate_w &&\n"
        "      issue1_dual_bank_slot_open_w &&",
        "issue1_dual_ordinary_candidate_w &&", 1,
    ),)),
    "legacy_all_load_block": Mutation("OooIntBackend.v", ((
        "issue0_load_waits_for_inflight_store_w =\n"
        "      !ENABLE_DUAL_MEM && issue0_is_load_w",
        "issue0_load_waits_for_inflight_store_w =\n"
        "      issue0_is_load_w", 1,
    ),)),
    "cross_bank_query_pid": Mutation("OooIntBackend.v", ((
        "mem1_sq_query_owner_token_i*PRODUCER_ID_W +: PRODUCER_ID_W",
        "mem_sq_query_owner_token_i*PRODUCER_ID_W +: PRODUCER_ID_W", 1,
    ),)),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()

    mutation = MUTATIONS[args.mutation]
    if args.source.name != mutation.source_name:
        raise SystemExit(
            f"[V8T-MUTATOR][FAIL] {args.mutation}: expected "
            f"{mutation.source_name}, got {args.source.name}"
        )
    text = args.source.read_text(encoding="utf-8")
    counts: list[int] = []
    for old, new, expected_count in mutation.replacements:
        anchor_count = text.count(old)
        counts.append(anchor_count)
        if anchor_count != expected_count:
            raise SystemExit(
                f"[V8T-MUTATOR][FAIL] {args.mutation}: expected "
                f"{expected_count} anchor(s), got {anchor_count}"
            )
        text = text.replace(old, new)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    payload = {
        "schema_version": 1,
        "mutation": args.mutation,
        "source_name": mutation.source_name,
        "anchor_counts": counts,
        "activated": True,
    }
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(
            json.dumps(payload, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    print(
        f"[V8T-MUTATOR][PASS] name={args.mutation} "
        f"source={args.source} output={args.output} anchors={counts}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
