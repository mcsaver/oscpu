#!/usr/bin/env python3
"""Create one compile-success RV64 memory-holder identity variant."""

from __future__ import annotations

import argparse
from pathlib import Path


MUTATIONS: dict[str, tuple[str, str, str]] = {
    "dual_req_token_alias": (
        "OooIntBackend.v",
        "assign mem1_req_owner_token_o = grant_retry1_w ?\n"
        "      mem_retry1_owner_token_q : grant_mem1_issue0_w ?\n"
        "      mem_issue_res_owner_token_q : mem_issue1_res_owner_token_q;",
        "assign mem1_req_owner_token_o = mem_req_owner_token_o;",
    ),
    "station_retain_after_advance": (
        "OooMemAxiBridge.v",
        "end else if (stage_advance_w) begin\n"
        "      stg_valid_q <= 1'b0;\n"
        "    end else if (flush_i && !stg_nokill_q) begin",
        "end else if (stage_advance_w) begin\n"
        "      stg_valid_q <= 1'b1;\n"
        "    end else if (flush_i && !stg_nokill_q) begin",
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(MUTATIONS))
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    expected_name, old, new = MUTATIONS[args.mutation]
    if args.source.name != expected_name:
        raise SystemExit(
            f"[V9Q-MUTATOR][FAIL] expected {expected_name}, "
            f"got {args.source.name}"
        )
    text = args.source.read_text(encoding="utf-8")
    hits = text.count(old)
    if hits != 1:
        raise SystemExit(
            f"[V9Q-MUTATOR][FAIL] name={args.mutation} anchor_hits={hits}"
        )
    mutated = text.replace(old, new, 1)
    if mutated == text or mutated.count(new) != 1:
        raise SystemExit(
            f"[V9Q-MUTATOR][FAIL] name={args.mutation} activation mismatch"
        )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(mutated, encoding="utf-8")
    print(
        f"[V9Q-MUTATOR][PASS] name={args.mutation} "
        f"source={args.source} output={args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
