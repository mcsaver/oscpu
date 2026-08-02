#!/usr/bin/env python3
"""Create one compile-success DI-4 semantic mutant in a temp source."""

from __future__ import annotations

import argparse
from pathlib import Path


MUTATIONS: dict[str, tuple[str, str]] = {
    "disable_pair_swap": (
        "wire swap_w = !universal_owner_present_i && first_req_valid_w &&\n"
        "      first_req_is_alu_w && partner_valid_w && !partner_is_alu_w;",
        "wire swap_w = 1'b0;",
    ),
    "static_entry_capability": (
        "assign select_alu_capable_w[select_g] =\n"
        "          alu_terminal_capable_q[select_g];",
        "assign select_alu_capable_w[select_g] = (select_g == 0);",
    ),
    "slot1_capability_capture": (
        "alu_terminal_capable_next_r[write_i] =\n"
        "          ctrl_is_alu_terminal_capable(dispatch1_ctrl_i) &&\n"
        "          !dispatch1_fp_pdest_i && !dispatch1_fp_st_src_en_i;",
        "alu_terminal_capable_next_r[write_i] = 1'b1;",
    ),
    "muldiv_as_alu": (
        "          !ctrl[`CTRL_WFI_BIT] && !ctrl[`CTRL_MULDIV_BIT] &&\n"
        "          !ctrl[`CTRL_BITMANIP_BIT] && !ctrl[`CTRL_SFENCE_VMA_BIT] &&",
        "          !ctrl[`CTRL_WFI_BIT] &&\n"
        "          !ctrl[`CTRL_BITMANIP_BIT] && !ctrl[`CTRL_SFENCE_VMA_BIT] &&",
    ),
    "serialize_second_terminal": (
        "assign issue1_found_o = universal_owner_present_i ?\n"
        "      (!owner_memory_pair_peek_w && first_alu_valid_w) :\n"
        "      (memory_pair_w || partner_valid_w);",
        "assign issue1_found_o = 1'b0;",
    ),
    "corrupt_full_pid": (
        "assign issue0_producer_id_o = producer_id_q[issue0_idx_w];",
        "assign issue0_producer_id_o = {PRODUCER_ID_W{1'b0}};",
    ),
}

# The executable DI-4 target remains valid across the V13I IQ representation
# change.  Keep the historical per-field anchor above and accept exactly one
# packed-entry anchor when that is the live representation; accepting zero or
# multiple anchors is still fail-closed.
ALTERNATE_MUTATIONS: dict[str, tuple[tuple[str, str], ...]] = {
    "slot1_capability_capture": ((
        "ctrl_is_alu_terminal_capable(dispatch1_ctrl_i) &&\n"
        "        !dispatch1_fp_pdest_i && !dispatch1_fp_st_src_en_i,",
        "1'b1,",
    ),),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    text = args.source.read_text(encoding="utf-8")
    candidates = (MUTATIONS[args.mutation],) + ALTERNATE_MUTATIONS.get(
        args.mutation, ())
    matches = [
        (old, new) for old, new in candidates if text.count(old) == 1
    ]
    if len(matches) != 1:
        raise SystemExit(
            f"[V8O-MUTATOR][FAIL] {args.mutation}: "
            f"expected one representation anchor, got {len(matches)}"
        )
    old, new = matches[0]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"[V8O-MUTATOR][PASS] {args.mutation} -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
