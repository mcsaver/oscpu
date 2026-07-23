#!/usr/bin/env python3
"""Generate one bounded compile-success v8u/F4 RTL semantic mutant."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Mutation:
    source_name: str
    old: str
    new: str
    expected_count: int = 1


MUTATIONS: dict[str, Mutation] = {
    "backend_next_requires_response_fire": Mutation(
        "OooIntBackend.v",
        "wire mem_sq_query_next_miq_exact_w = mem_sq_query_station_source_w &&\n"
        "      mem_current_rsp_exact_candidate_w && miq_next_head_load_w &&",
        "wire mem_sq_query_next_miq_exact_w = mem_sq_query_station_source_w &&\n"
        "      mem_current_rsp_exact_fire_w && miq_next_head_load_w &&",
    ),
    "backend_turnover_accepts_partial": Mutation(
        "OooIntBackend.v",
        "iq_memory_pair_peek_valid_w &&\n"
        "      mem_issue_res_consume_fire_w && mem_issue1_res_consume_fire_w &&",
        "iq_memory_pair_peek_valid_w &&\n"
        "      (mem_issue_res_consume_fire_w || mem_issue1_res_consume_fire_w) &&",
    ),
    "backend_peek_dequeue_without_capture": Mutation(
        "OooIntBackend.v",
        "assign iq_memory_pair_peek_ready_w =\n"
        "      mem_issue_pair_turnover_capture_w;",
        "assign iq_memory_pair_peek_ready_w = iq_memory_pair_peek_valid_w;",
    ),
    "bridge_station_query_requires_ready": Mutation(
        "OooMemAxiBridge.v",
        "assign station_sq_lookahead_query_w = lookup_hit_fusion_w &&\n"
        "      stg_valid_q",
        "assign station_sq_lookahead_query_w = lookup_hit_fusion_w &&\n"
        "      rsp_ready_w && stg_valid_q",
    ),
    "bridge_station_lookup_ignores_ready": Mutation(
        "OooMemAxiBridge.v",
        "station_sq_lookahead_query_w && rsp_ready_w &&\n"
        "      sq_query_decision_onehot_w",
        "station_sq_lookahead_query_w &&\n"
        "      sq_query_decision_onehot_w",
    ),
    "iq_pair_pop_only_entry0": Mutation(
        "OooIntIssueQueue.v",
        "!(memory_pair_peek_fire_w &&\n"
        "            ((compact_i == 0) || (compact_i == 1))) &&",
        "!(memory_pair_peek_fire_w && (compact_i == 0)) &&",
    ),
    "iq_pair_exposes_regular_issue1": Mutation(
        "OooIntIssueQueue.v",
        "assign issue1_valid_o =\n"
        "      issue1_found_w && !recover_active_i && !kill_valid_i;",
        "assign issue1_valid_o =\n"
        "      (issue1_found_w || memory_pair_peek_valid_o) &&\n"
        "      !recover_active_i && !kill_valid_i;",
    ),
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
            f"[V8U-F4-MUTATOR][FAIL] {args.mutation}: expected "
            f"{mutation.source_name}, got {args.source.name}"
        )

    source_text = args.source.read_text(encoding="utf-8")
    count = source_text.count(mutation.old)
    if count != mutation.expected_count:
        raise SystemExit(
            f"[V8U-F4-MUTATOR][FAIL] {args.mutation}: expected "
            f"{mutation.expected_count} anchor(s), got {count}"
        )
    mutant_text = source_text.replace(mutation.old, mutation.new)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(mutant_text, encoding="utf-8")

    payload = {
        "schema_version": 1,
        "mutation": args.mutation,
        "source_name": mutation.source_name,
        "anchor_count": count,
        "activated": True,
    }
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(
            json.dumps(payload, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    print(
        f"[V8U-F4-MUTATOR][PASS] name={args.mutation} "
        f"source={args.source} output={args.output} anchors={count}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
