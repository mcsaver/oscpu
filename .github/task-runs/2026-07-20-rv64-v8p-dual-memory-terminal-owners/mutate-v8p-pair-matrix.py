#!/usr/bin/env python3
"""Create one compile-success DI-3 semantic mutant in a temporary source."""

from __future__ import annotations

import argparse
from pathlib import Path


MUTATIONS: dict[str, tuple[str, str, str]] = {
    "serialize_memory_pair": (
        "OooIntIssueSelect8.v",
        "wire memory_pair_w = !universal_owner_present_i &&\n"
        "      eligible_w[0] && eligible_w[1] &&\n"
        "      plain_memory_capable_i[0] && plain_memory_capable_i[1];",
        "wire memory_pair_w = 1'b0;",
    ),
    "split_pair_ready": (
        "OooIntBackend.v",
        "mem_issue_pair_capture_w : mem_issue_pair_stale1_drop_w",
        "1'b0 : mem_issue_pair_stale1_drop_w",
    ),
    "bank1_tieoff": (
        "OooIntBackend.v",
        "wire mem_issue1_res_capture_w =\n"
        "      mem_issue1_res_capture_candidate_w && "
        "mem_owner_alloc0_ready_w &&\n"
        "      mem_owner_alloc1_ready_w;",
        "wire mem_issue1_res_capture_w = 1'b0;",
    ),
    "owner1_tieoff": (
        "OooIntBackend.v",
        ".alloc1_valid_i(mem_issue1_res_capture_candidate_w)",
        ".alloc1_valid_i(1'b0)",
    ),
    "alloc0_only_birth": (
        "OooMemOwnerTracker.v",
        "wire alloc0_fire_w = alloc_pair_present_w ? alloc_pair_commit_w :",
        "wire alloc0_fire_w = alloc_pair_present_w ?\n"
        "      (alloc0_valid_i && alloc0_ready_o) :",
    ),
    "token_alias": (
        "OooMemOwnerTracker.v",
        "assign alloc1_token_o = alloc1_token_r;",
        "assign alloc1_token_o = alloc0_token_r;",
    ),
    "bank1_raw_fallthrough": (
        "OooIntBackend.v",
        "wire [`XLEN-1:0] mem_issue1_res_eff_addr_w =\n"
        "      mem_issue1_res_src1_data_q + mem_issue1_res_imm_q;",
        "wire [`XLEN-1:0] mem_issue1_res_eff_addr_w =\n"
        "      issue1_src1_value_w + issue1_imm_w;",
    ),
    "agu1_bank0_copy": (
        "OooIntBackend.v",
        "wire [`XLEN-1:0] mem_issue1_res_eff_addr_w =\n"
        "      mem_issue1_res_src1_data_q + mem_issue1_res_imm_q;",
        "wire [`XLEN-1:0] mem_issue1_res_eff_addr_w =\n"
        "      mem_issue_res_eff_addr_w;",
    ),
    "sq_bind1_lost": (
        "OooIntBackend.v",
        ".owner_bind1_valid_i(sq_owner_bind1_valid_w)",
        ".owner_bind1_valid_i(1'b0)",
    ),
    "sq_bind1_cross": (
        "OooIntBackend.v",
        ".owner_bind1_token_i(mem_owner_alloc1_token_w)",
        ".owner_bind1_token_i(mem_owner_alloc0_token_w)",
    ),
    "special_misadmission": (
        "OooIntIssueQueue.v",
        "ctrl_is_plain_memory_terminal_capable =\n"
        "          ctrl[`CTRL_VALID_BIT] && ctrl[`CTRL_NEED_MEM_BIT] &&\n"
        "          (ctrl[`CTRL_LOAD_BIT] || ctrl[`CTRL_STORE_BIT]) &&\n"
        "          !ctrl[`CTRL_AMO_BIT];",
        "ctrl_is_plain_memory_terminal_capable =\n"
        "          ctrl[`CTRL_VALID_BIT] && ctrl[`CTRL_NEED_MEM_BIT] &&\n"
        "          (ctrl[`CTRL_LOAD_BIT] || ctrl[`CTRL_STORE_BIT]);",
    ),
    "bank1_age_bypass": (
        "OooIntBackend.v",
        "assign mem_issue1_res_consume_fire_w =\n"
        "      ENABLE_DUAL_MEM ?\n"
        "      (mem_issue1_res_dual_local_consume_w || issue1_mem_request_fire_w) :\n"
        "      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&\n"
        "       mem_issue1_res_ready_w);",
        "assign mem_issue1_res_consume_fire_w = mem_issue1_res_valid_q;",
    ),
    "pid1_truncation": (
        "OooIntBackend.v",
        "mem_issue1_res_producer_id_q <= issue1_producer_id_w;",
        "mem_issue1_res_producer_id_q <=\n"
        "          {{PRODUCER_GEN_W{1'b0}},\n"
        "           issue1_producer_id_w[ROB_INDEX_W-1:0]};",
    ),
    "bank1_cancel_leak": (
        "OooIntBackend.v",
        "      mem_issue1_res_tagged_terminal_w,\n"
        "      mem_issue_res_tagged_terminal_w,",
        "      1'b0,\n"
        "      mem_issue_res_tagged_terminal_w,",
    ),
    "checker_vacuity": (
        "OooIntBackend.v",
        "LSU u_issue1_lsu (",
        "LSU u_issue1_lsu_hidden (",
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    basename, old, new = MUTATIONS[args.mutation]
    if args.source.name != basename:
      raise SystemExit(
          f"[V8P-MUTATOR][FAIL] {args.mutation}: expected {basename}, "
          f"got {args.source.name}"
      )
    text = args.source.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"[V8P-MUTATOR][FAIL] {args.mutation}: "
            f"expected one anchor, got {count}"
        )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(
        f"[V8P-MUTATOR][PASS] name={args.mutation} "
        f"source={args.source} output={args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
