#!/usr/bin/env python3
"""Create one compile-success OOO-2 path mutant in a caller-owned temp file."""

from __future__ import annotations

import argparse
from pathlib import Path


MUTATIONS: dict[str, tuple[tuple[str, str], ...]] = {
    "backend_owner_binding": ((
        ".universal_owner_present_i(\n"
        "        mem_issue_res_valid_q || mem_issue1_res_valid_q),",
        ".universal_owner_present_i(1'b0),",
    ),),
    "dispatch_owner_forwarding": ((
        ".universal_owner_present_i(universal_owner_present_i),",
        ".universal_owner_present_i(1'b0),",
    ),),
    "selector_owner_to_alu": ((
        "      universal_owner_present_i ?\n"
        "      first_alu_onehot_w :",
        "      universal_owner_present_i ?\n"
        "      8'b0 :",
    ), (
        "assign issue1_found_o = universal_owner_present_i ?\n"
        "      (!owner_memory_pair_peek_w && first_alu_valid_w) :\n"
        "      (memory_pair_w || partner_valid_w);",
        "assign issue1_found_o = universal_owner_present_i ?\n"
        "      1'b0 :\n"
        "      (memory_pair_w || partner_valid_w);",
    )),
    "iq_issue1_owner_mask": ((
        "assign issue1_valid_o =\n"
        "      issue1_found_w && !recover_active_i && !kill_valid_i;",
        "assign issue1_valid_o =\n"
        "      issue1_found_w && !universal_owner_present_i &&\n"
        "      !recover_active_i && !kill_valid_i;",
    ),),
    "backend_issue1_ready_mask": ((
        "assign issue1_ready_w = iq_issue1_plain_mem_class_w ?\n"
        "      (iq_memory_pair_w ?\n"
        "       ((iq_issue0_producer_current_w && issue1_producer_current_w) ?\n"
        "        mem_issue_pair_capture_w : mem_issue_pair_stale1_drop_w) : 1'b0) :\n"
        "      (!mem_issue1_res_valid_q && !flush_i &&\n"
        "       !checkpoint_restore_hold_w &&\n"
        "       !issue_block_w && !mem_rsp_waiting_for_wb_w);",
        "assign issue1_ready_w = iq_issue1_plain_mem_class_w ?\n"
        "      (iq_memory_pair_w ?\n"
        "       ((iq_issue0_producer_current_w && issue1_producer_current_w) ?\n"
        "        mem_issue_pair_capture_w : mem_issue_pair_stale1_drop_w) : 1'b0) :\n"
        "      (!mem_issue1_res_valid_q && !flush_i &&\n"
        "       !checkpoint_restore_hold_w &&\n"
        "       !issue_block_w && !mem_rsp_waiting_for_wb_w &&\n"
        "       !mem_issue_res_valid_q);",
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
                f"[V8M-MUTATOR][FAIL] {args.mutation} replacement "
                f"{index}: expected one anchor, got {count}"
            )
        text = text.replace(old, new, 1)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    print(f"[V8M-MUTATOR][PASS] {args.mutation} -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
