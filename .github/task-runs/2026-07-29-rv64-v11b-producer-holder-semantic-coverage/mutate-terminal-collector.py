#!/usr/bin/env python3
"""Create one compile-success terminal-collector RTL verification variant."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if text.count(old) != 1:
        raise SystemExit(
            f"[V11B-TCOLL-MUTATOR][FAIL] {label} anchor count="
            f"{text.count(old)} expected=1"
        )
    return text.replace(old, new, 1)


def mutate(text: str, case: str) -> str:
    if case == "drop-ingress-known-assertion":
        start_anchor = (
            "      for (ingress_assert_i = 0; ingress_assert_i < INGRESS_N;\n"
        )
        end_anchor = (
            "      if (out0_valid_q && (^out0_token_q === 1'bx)) begin\n"
        )
        start = text.find(start_anchor)
        end = text.find(end_anchor, start + 1)
        if (
            start < 0
            or end < 0
            or "[V11B-TCOLL-INGRESS-TUPLE-KNOWN]"
            not in text[start:end]
        ):
            raise SystemExit(
                "[V11B-TCOLL-MUTATOR][FAIL] ingress-known block anchors "
                "or marker are missing"
            )
        return (
            text[:start]
            + "      // V11B mutation: valid ingress identity-known guard cut.\n"
            + text[end:]
        )
    if case == "lane1-reuses-lane0-grant":
        return replace_once(
            text,
            "    if (refill0_found_r)\n"
            "      refill_pool_r[refill0_token_r] = 1'b0;\n",
            "    if (refill0_found_r)\n"
            "      refill_pool_r = refill_pool_r;\n",
            case,
        )
    if case == "same-edge-accept-cut":
        return replace_once(
            text,
            "            !ingress_pending_violation_r[ingress_i] &&\n"
            "            !ingress_same_edge_violation_r[ingress_i];\n",
            "            1'b1 &&\n"
            "            1'b1;\n",
            case,
        )
    raise SystemExit(f"[V11B-TCOLL-MUTATOR][FAIL] unsupported case={case}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", required=True)
    parser.add_argument("--input", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--receipt", type=pathlib.Path, required=True)
    args = parser.parse_args()
    source = args.input.resolve()
    output = args.output.resolve()
    receipt = args.receipt.resolve()
    mutated = mutate(source.read_text(encoding="utf-8"), args.case)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(mutated, encoding="utf-8")
    receipt.parent.mkdir(parents=True, exist_ok=True)
    receipt.write_text(
        json.dumps(
            {
                "schema_version": "rv64-v11b-terminal-collector-mutant-v1",
                "case": args.case,
                "source_sha256": sha256(source),
                "mutant_sha256": sha256(output),
                "changed": source.read_bytes() != output.read_bytes(),
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        "[V11B-TCOLL-MUTATOR][PASS] "
        f"case={args.case} mutant_sha256={sha256(output)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
