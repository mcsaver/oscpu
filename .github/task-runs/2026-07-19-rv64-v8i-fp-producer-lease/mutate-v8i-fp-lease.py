#!/usr/bin/env python3
"""Create one exact, compile-success v8i FP lease mutant in a temp path."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import NoReturn


def fail(message: str) -> NoReturn:
    raise SystemExit(f"[V8I-MUTATOR][FAIL] {message}")


@dataclass(frozen=True)
class Mutation:
    kind: str
    relpath: str
    old: str
    new: str


MUTATIONS: dict[str, Mutation] = {
    "iq_drop_generation": Mutation(
        "fp_iq", "scheduling/OooFpIssueQueue.v",
        "        producer_id_q[alloc_idx_r] <= dispatch_producer_id_i;",
        "        producer_id_q[alloc_idx_r] <= "
        "{{PRODUCER_GEN_W{1'b0}}, dispatch_producer_id_i[ROB_INDEX_W-1:0]};",
    ),
    "arith_drop_generation": Mutation(
        "fp_arith", "execute/OooFpArithGate.v",
        "      meta_producer_id_q[1] <= launch_producer_id_i;",
        "      meta_producer_id_q[1] <= "
        "{{PRODUCER_GEN_W{1'b0}}, launch_producer_id_i[ROB_INDEX_W-1:0]};",
    ),
    "backend_result_ignores_pending": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  assign fp_result_authorized_w = fp_result_query_valid_w &&\n"
        "      fp_result_completion_rob_open_w && !fp_result_pending_owned_w &&\n"
        "      !fp_result_same_edge_claimed_w;",
        "  assign fp_result_authorized_w = fp_result_query_valid_w &&\n"
        "      fp_result_completion_rob_open_w &&\n"
        "      !fp_result_same_edge_claimed_w;",
    ),
    "backend_ex0_ignores_pending": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  assign ex0_wb_valid_w = ex0_pre_auth_valid_w && ex0_producer_open_w &&\n"
        "                          !ex0_fp_pending_owned_w;",
        "  assign ex0_wb_valid_w = ex0_pre_auth_valid_w && ex0_producer_open_w;",
    ),
    "backend_union_omits_fp": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      mem_owner_producer_live_mask_w |\n"
        "      muldiv_owner_producer_live_mask_w |\n"
        "      clmul_owner_producer_live_mask_w |\n"
        "      fp_producer_live_mask_w;",
        "      mem_owner_producer_live_mask_w |\n"
        "      muldiv_owner_producer_live_mask_w |\n"
        "      clmul_owner_producer_live_mask_w;",
    ),
    "fp_result_side_effect_ignores_auth": Mutation(
        "fp_backend", "execute/OooFpBackend.v",
        "  assign fp_result_wb_valid_w =\n"
        "      fp_result_raw_valid_w && result_authorized_i;",
        "  assign fp_result_wb_valid_w = fp_result_raw_valid_w;",
    ),
    "fp_launch_ignores_credit": Mutation(
        "fp_backend", "execute/OooFpBackend.v",
        "  assign issue_ready_w = execution_credit_open_w &&\n"
        "                         (!op_long_w || (!long_busy_any_w && !long_meta_valid_q)) &&",
        "  assign issue_ready_w =\n"
        "                         (!op_long_w || (!long_busy_any_w && !long_meta_valid_q)) &&",
    ),
    "backend_formal_uses_raw_route": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  wire fpwb_wb0_valid_w =\n"
        "      fpwb_to_wb0_w && fpwb_completion_authorized_w;\n"
        "  wire fpwb_wb1_valid_w =\n"
        "      fpwb_to_wb1_w && fpwb_completion_authorized_w;",
        "  wire fpwb_wb0_valid_w = fpwb_to_wb0_w;\n"
        "  wire fpwb_wb1_valid_w = fpwb_to_wb1_w;",
    ),
    "rob_query5_ignores_generation": Mutation(
        "rob", "writeback/OooRob.v",
        "  wire completion5_query_exact_w =\n"
        "      {slot_generation_q[completion5_query_idx_w], completion5_query_idx_w} ==\n"
        "      completion5_query_producer_id_i;",
        "  wire completion5_query_exact_w = 1'b1;",
    ),
    "rob_query6_ignores_done": Mutation(
        "rob", "writeback/OooRob.v",
        "  assign completion6_query_match_o = completion6_query_valid_i && !rst && !flush_i &&\n"
        "      valid_q[completion6_query_idx_w] && !done_q[completion6_query_idx_w] &&\n"
        "      completion6_query_exact_w &&",
        "  assign completion6_query_match_o = completion6_query_valid_i && !rst && !flush_i &&\n"
        "      valid_q[completion6_query_idx_w] &&\n"
        "      completion6_query_exact_w &&",
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--case", required=True, choices=sorted(MUTATIONS))
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    run_dir = Path(__file__).resolve().parent
    repo = run_dir.parents[2]
    mutation = MUTATIONS[args.case]
    source = repo / "npc/rv64/vsrc" / mutation.relpath
    source_text = source.read_text(encoding="utf-8")
    count = source_text.count(mutation.old)
    if count != 1:
        fail(f"{args.case}: expected one source anchor, found {count}")
    mutated = source_text.replace(mutation.old, mutation.new, 1)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(mutated, encoding="utf-8")
    print(json.dumps({"case": args.case, "kind": mutation.kind,
                      "source": str(source), "output": str(args.out)},
                     sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
