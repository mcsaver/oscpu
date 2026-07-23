#!/usr/bin/env python3
"""Create one exact compile-success v8j branch-resolve mutant."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import NoReturn


def fail(message: str) -> NoReturn:
    raise SystemExit(f"[V8J-MUTATOR][FAIL] {message}")


@dataclass(frozen=True)
class Mutation:
    kind: str
    relpath: str
    old: str
    new: str


MUTATIONS: dict[str, Mutation] = {
    "carrier_corrupts_generation": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      iq_issue0_producer_id_w,\n"
        "      issue0_mispredict_w,",
        "      {{(PRODUCER_GEN_W-1){1'b0}}, 1'b1, issue0_rob_idx_w},\n"
        "      issue0_mispredict_w,",
    ),
    "auth_ignores_query": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  wire branch_resolve_authorized_w =\n"
        "      branch_resolve_candidate_valid_w && branch_resolve_rob_open_w &&\n"
        "      branch_resolve_raw_ex0_coherent_w;",
        "  wire branch_resolve_authorized_w =\n"
        "      branch_resolve_candidate_valid_w &&\n"
        "      branch_resolve_raw_ex0_coherent_w;",
    ),
    "auth_ignores_raw_ex0": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  wire branch_resolve_authorized_w =\n"
        "      branch_resolve_candidate_valid_w && branch_resolve_rob_open_w &&\n"
        "      branch_resolve_raw_ex0_coherent_w;",
        "  wire branch_resolve_authorized_w =\n"
        "      branch_resolve_candidate_valid_w && branch_resolve_rob_open_w;",
    ),
    "coherence_uses_semantic_valid": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  wire branch_resolve_raw_ex0_coherent_w =\n"
        "      ex0_valid_q &&\n"
        "      (branch_resolve_payload_producer_id_w == ex0_producer_id_q);",
        "  wire branch_resolve_raw_ex0_coherent_w =\n"
        "      ex0_wb_valid_w &&\n"
        "      (branch_resolve_payload_producer_id_w == ex0_producer_id_q);",
    ),
    "public_valid_uses_candidate": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  assign branch_resolve_valid_o = branch_resolve_authorized_w;",
        "  assign branch_resolve_valid_o = branch_resolve_candidate_valid_w;",
    ),
    "checkpoint_cancel_removed": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  wire branch_resolve_candidate_valid_w =\n"
        "      branch_resolve_stage_valid_w && !rst && !flush_i &&\n"
        "      !checkpoint_restore_i;",
        "  wire branch_resolve_candidate_valid_w =\n"
        "      branch_resolve_stage_valid_w && !rst && !flush_i;",
    ),
    "projection_corrupts_index": Mutation(
        "backend", "execute/OooIntBackend.v",
        "  wire [ROB_INDEX_W-1:0] branch_resolve_payload_rob_idx_w =\n"
        "      branch_resolve_payload_producer_id_w[ROB_INDEX_W-1:0];",
        "  wire [ROB_INDEX_W-1:0] branch_resolve_payload_rob_idx_w =\n"
        "      ~branch_resolve_payload_producer_id_w[ROB_INDEX_W-1:0];",
    ),
    "rob_query_ignores_generation": Mutation(
        "rob", "writeback/OooRob.v",
        "  wire resolve_query_exact_w =\n"
        "      {slot_generation_q[resolve_query_idx_w], resolve_query_idx_w} ==\n"
        "      resolve_query_producer_id_i;",
        "  wire resolve_query_exact_w = 1'b1;",
    ),
    "rob_query_ignores_done": Mutation(
        "rob", "writeback/OooRob.v",
        "  assign resolve_query_match_o = resolve_query_valid_i && !rst && !flush_i &&\n"
        "      !recover_q && valid_q[resolve_query_idx_w] &&\n"
        "      !done_q[resolve_query_idx_w] && resolve_query_exact_w;",
        "  assign resolve_query_match_o = resolve_query_valid_i && !rst && !flush_i &&\n"
        "      !recover_q && valid_q[resolve_query_idx_w] &&\n"
        "      resolve_query_exact_w;",
    ),
    "rob_query_ignores_recovery": Mutation(
        "rob", "writeback/OooRob.v",
        "  assign resolve_query_match_o = resolve_query_valid_i && !rst && !flush_i &&\n"
        "      !recover_q && valid_q[resolve_query_idx_w] &&\n"
        "      !done_q[resolve_query_idx_w] && resolve_query_exact_w;",
        "  assign resolve_query_match_o = resolve_query_valid_i && !rst && !flush_i &&\n"
        "      valid_q[resolve_query_idx_w] &&\n"
        "      !done_q[resolve_query_idx_w] && resolve_query_exact_w;",
    ),
    "rob_query_reads_current_kill": Mutation(
        "rob", "writeback/OooRob.v",
        "  assign resolve_query_match_o = resolve_query_valid_i && !rst && !flush_i &&\n"
        "      !recover_q && valid_q[resolve_query_idx_w] &&\n"
        "      !done_q[resolve_query_idx_w] && resolve_query_exact_w;",
        "  assign resolve_query_match_o = resolve_query_valid_i && !rst && !flush_i &&\n"
        "      !recover_q && !kill_valid_i && valid_q[resolve_query_idx_w] &&\n"
        "      !done_q[resolve_query_idx_w] && resolve_query_exact_w;",
    ),
    "completion0_kill_dependency_sticky": Mutation(
        "rob", "writeback/OooRob.v",
        "      producer_target_killed_now(completion0_query_idx_w, head_q,\n"
        "                                 kill_valid_i, kill_rob_idx_i,\n"
        "                                 recover_q, kill_idx_q);",
        "      producer_target_killed_now(completion0_query_idx_w, head_q,\n"
        "                                 1'b1, kill_rob_idx_i,\n"
        "                                 recover_q, kill_idx_q);",
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
