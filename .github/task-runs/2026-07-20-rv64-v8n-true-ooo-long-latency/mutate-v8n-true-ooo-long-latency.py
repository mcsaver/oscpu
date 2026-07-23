#!/usr/bin/env python3
"""Create one compile-success OOO-1 semantic mutant in a temp source."""

from __future__ import annotations

import argparse
from pathlib import Path


ISSUE1_READY = (
    "assign issue1_ready_w = iq_issue1_plain_mem_class_w ?\n"
    "      (iq_memory_pair_w ?\n"
    "       ((iq_issue0_producer_current_w && issue1_producer_current_w) ?\n"
    "        mem_issue_pair_capture_w : mem_issue_pair_stale1_drop_w) : 1'b0) :\n"
    "      (!mem_issue1_res_valid_q && !flush_i &&\n"
    "       !checkpoint_restore_hold_w &&\n"
    "       !issue_block_w && !mem_rsp_waiting_for_wb_w);"
)

MUTATIONS: dict[str, tuple[tuple[str, str], ...]] = {
    "serial_issue1": ((
        ISSUE1_READY,
        "assign issue1_ready_w = 1'b0;",
    ),),
    "miq_issue1_freeze": ((
        ISSUE1_READY,
        ISSUE1_READY[:-2] + " && !miq_head_valid_w);",
    ),),
    "muldiv_issue1_freeze": ((
        ISSUE1_READY,
        ISSUE1_READY[:-2] + " && !muldiv_owner_valid_w);",
    ),),
    "retire_before_head_done": ((
        "assign head0_base_ready_w = !recovering_w && commit_ready_i &&\n"
        "                              (count_q != {ROB_COUNT_W{1'b0}}) &&\n"
        "                              valid_q[head_q] && head_done_w &&\n"
        "                              !head0_csr_mem_hold_w;",
        "assign head0_base_ready_w = !recovering_w && commit_ready_i &&\n"
        "                              (count_q != {ROB_COUNT_W{1'b0}}) &&\n"
        "                              valid_q[head_q] && head1_done_w &&\n"
        "                              !head0_csr_mem_hold_w;",
    ),),
    "load_owner_pid_truncate": ((
        "assign mem_completion_producer_id_w =\n"
        "      mem_owner_producer_id_table_w[\n"
        "          miq_head_owner_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];",
        "assign mem_completion_producer_id_w =\n"
        "      {{PRODUCER_GEN_W{1'b0}},\n"
        "       mem_owner_producer_id_table_w[\n"
        "           miq_head_owner_token_w*PRODUCER_ID_W +: ROB_INDEX_W]};",
    ),),
    "muldiv_owner_pid_truncate": ((
        "assign owner_producer_id_o = producer_id_q;",
        "assign owner_producer_id_o =\n"
        "      {{PRODUCER_GEN_W{1'b0}}, producer_id_q[ROB_INDEX_W-1:0]};",
    ),),
    "muldiv_resp_pid_truncate": ((
        "assign resp_producer_id_o = producer_id_q;",
        "assign resp_producer_id_o =\n"
        "      {{PRODUCER_GEN_W{1'b0}}, producer_id_q[ROB_INDEX_W-1:0]};",
    ),),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    text = args.source.read_text(encoding="utf-8")
    for index, (old, new) in enumerate(MUTATIONS[args.mutation]):
        count = text.count(old)
        if count != 1:
            raise SystemExit(
                f"[V8N-MUTATOR][FAIL] {args.mutation} replacement "
                f"{index}: expected one anchor, got {count}"
            )
        text = text.replace(old, new, 1)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    print(f"[V8N-MUTATOR][PASS] {args.mutation} -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
