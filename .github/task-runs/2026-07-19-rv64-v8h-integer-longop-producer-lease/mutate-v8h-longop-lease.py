#!/usr/bin/env python3
"""Create one exact, compile-success v8h semantic mutant in a caller temp dir."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import NoReturn


def fail(message: str) -> NoReturn:
    raise SystemExit(f"[V8H-MUTATOR][FAIL] {message}")


@dataclass(frozen=True)
class Mutation:
    kind: str
    relpath: str
    old: str
    new: str


CAPTURE = "            producer_id_q <= req_producer_id_i;"
OWNER = "  assign owner_valid_o = state_q != STATE_IDLE;"
READY = (
    "  assign req_ready_o = (state_q == STATE_IDLE) && !rst && !flush_i && !kill_valid_i;"
)


MUTATIONS: dict[str, Mutation] = {
    "muldiv_drop_generation": Mutation(
        "muldiv", "execute/OooMulDivUnit.v", CAPTURE,
        "            producer_id_q <= {{PRODUCER_GEN_W{1'b0}}, req_producer_id_i[ROB_INDEX_W-1:0]};",
    ),
    "clmul_drop_generation": Mutation(
        "clmul", "execute/OooClmulUnit.v", CAPTURE,
        "            producer_id_q <= {{PRODUCER_GEN_W{1'b0}}, req_producer_id_i[ROB_INDEX_W-1:0]};",
    ),
    "muldiv_resp_only_lease": Mutation(
        "muldiv", "execute/OooMulDivUnit.v", OWNER,
        "  assign owner_valid_o = state_q == STATE_RESP;",
    ),
    "clmul_resp_only_lease": Mutation(
        "clmul", "execute/OooClmulUnit.v", OWNER,
        "  assign owner_valid_o = state_q == STATE_RESP;",
    ),
    "muldiv_early_terminal_release": Mutation(
        "muldiv", "execute/OooMulDivUnit.v", OWNER,
        "  assign owner_valid_o = (state_q != STATE_IDLE) && !((state_q == STATE_RESP) && resp_ready_i);",
    ),
    "clmul_early_terminal_release": Mutation(
        "clmul", "execute/OooClmulUnit.v", OWNER,
        "  assign owner_valid_o = (state_q != STATE_IDLE) && !((state_q == STATE_RESP) && resp_ready_i);",
    ),
    "muldiv_ready_ignores_kill": Mutation(
        "muldiv", "execute/OooMulDivUnit.v", READY,
        "  assign req_ready_o = (state_q == STATE_IDLE) && !rst && !flush_i;",
    ),
    "clmul_ready_ignores_kill": Mutation(
        "clmul", "execute/OooClmulUnit.v", READY,
        "  assign req_ready_o = (state_q == STATE_IDLE) && !rst && !flush_i;",
    ),
    "backend_union_omits_muldiv": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      mem_owner_producer_live_mask_w |\n      muldiv_owner_producer_live_mask_w |\n      clmul_owner_producer_live_mask_w;",
        "      mem_owner_producer_live_mask_w |\n      clmul_owner_producer_live_mask_w;",
    ),
    "backend_union_omits_clmul": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      mem_owner_producer_live_mask_w |\n      muldiv_owner_producer_live_mask_w |\n      clmul_owner_producer_live_mask_w;",
        "      mem_owner_producer_live_mask_w |\n      muldiv_owner_producer_live_mask_w;",
    ),
    "backend_ex1_ignores_ex0_claim": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  assign ex1_wb_valid_w = ex1_pre_auth_valid_w && ex1_producer_open_w &&\n                          !ex1_same_edge_claimed_w;",
        "  assign ex1_wb_valid_w = ex1_pre_auth_valid_w && ex1_producer_open_w;",
    ),
    "backend_muldiv_ignores_ex0_claim": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      (ex0_wb_valid_w &&\n       (ex0_producer_id_q == muldiv_resp_producer_id_w)) ||",
        "      (ex0_wb_valid_w &&\n       (ex0_producer_id_q != muldiv_resp_producer_id_w)) ||",
    ),
    "backend_clmul_ignores_ex1_claim": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      (ex1_wb_valid_w &&\n       (ex1_producer_id_q == clmul_resp_producer_id_w)) ||",
        "      (ex1_wb_valid_w &&\n       (ex1_producer_id_q != clmul_resp_producer_id_w)) ||",
    ),
    "backend_muldiv_ignores_memory_claim": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      (mem_wb_fire_w &&\n       (mem_completion_producer_id_w == muldiv_resp_producer_id_w));",
        "      (mem_wb_fire_w &&\n       (mem_completion_producer_id_w != muldiv_resp_producer_id_w));",
    ),
    "backend_clmul_ignores_memory_claim": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      (mem_wb_fire_w &&\n       (mem_completion_producer_id_w == clmul_resp_producer_id_w)) ||",
        "      (mem_wb_fire_w &&\n       (mem_completion_producer_id_w != clmul_resp_producer_id_w)) ||",
    ),
    "backend_clmul_ignores_muldiv_claim": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      (muldiv_actual_claim_w &&\n       (muldiv_resp_producer_id_w == clmul_resp_producer_id_w));",
        "      (muldiv_actual_claim_w &&\n       (muldiv_resp_producer_id_w != clmul_resp_producer_id_w));",
    ),
    "backend_muldiv_ignores_open": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  wire muldiv_completion_authorized_w = muldiv_resp_valid_w &&\n      muldiv_completion_rob_open_w && !muldiv_same_edge_claimed_w;",
        "  wire muldiv_completion_authorized_w = muldiv_resp_valid_w &&\n      !muldiv_same_edge_claimed_w;",
    ),
    "backend_clmul_ignores_open": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  wire clmul_completion_authorized_w = clmul_resp_valid_w &&\n      clmul_completion_rob_open_w && !clmul_same_edge_claimed_w;",
        "  wire clmul_completion_authorized_w = clmul_resp_valid_w &&\n      !clmul_same_edge_claimed_w;",
    ),
    "backend_muldiv_ready_reads_authority": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  assign muldiv_resp_ready_w = muldiv_rsp_to_wb0_w || muldiv_rsp_to_wb1_w;",
        "  assign muldiv_resp_ready_w = (muldiv_rsp_to_wb0_w || muldiv_rsp_to_wb1_w) &&\n                               muldiv_completion_authorized_w;",
    ),
    "rob_query3_ignores_generation": Mutation(
        "rob", "writeback/OooRob.v",
        "  wire completion3_query_exact_w =\n      {slot_generation_q[completion3_query_idx_w], completion3_query_idx_w} ==\n      completion3_query_producer_id_i;",
        "  wire completion3_query_exact_w = 1'b1;",
    ),
    "rob_query4_ignores_done": Mutation(
        "rob", "writeback/OooRob.v",
        "      valid_q[completion4_query_idx_w] && !done_q[completion4_query_idx_w] &&\n      completion4_query_exact_w &&",
        "      valid_q[completion4_query_idx_w] &&\n      completion4_query_exact_w &&",
    ),
    "rob_pair_candidate_aliases_lane0": Mutation(
        "rob", "writeback/OooRob.v",
        "  wire [ROB_INDEX_W-1:0] dispatch1_pair_idx_w =\n      rob_ptr_add(tail_q, 2'd1);",
        "  wire [ROB_INDEX_W-1:0] dispatch1_pair_idx_w = tail_q;",
    ),
    "dispatch_lane0_truncates_pid": Mutation(
        "dispatch", "rename_allocate/OooDispatchBackend.v",
        "                             !producer_live_mask_i[\n                                 rob_dispatch0_producer_id_w] &&",
        "                             !producer_live_mask_i[\n                                 {{PRODUCER_GEN_W{1'b0}},\n                                  rob_dispatch0_producer_id_w[ROB_INDEX_W-1:0]}] &&",
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
    text = source.read_text(encoding="utf-8")
    count = text.count(mutation.old)
    if count != 1:
        fail(f"{args.case}: expected one source anchor, found {count}")
    mutated = text.replace(mutation.old, mutation.new, 1)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(mutated, encoding="utf-8")
    print(json.dumps({"case": args.case, "kind": mutation.kind,
                      "source": str(source), "output": str(args.out)},
                     sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
