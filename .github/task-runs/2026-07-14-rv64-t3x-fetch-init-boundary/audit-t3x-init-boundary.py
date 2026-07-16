#!/usr/bin/env python3
"""Audit the T3X immutable-context / derived-scratch ownership boundary."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
RTL = ROOT / "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"

SCRATCH_INIT = {
    "paddr0_q": "pc_q",
    "paddr1_q": "{`XLEN{1'b0}}",
    "packet_cross_page_q": "1'b0",
    "walk_second_q": "1'b0",
    "second_page_ready_q": "1'b0",
    "fetch_offset_q": "3'd0",
    "fetch_data_q": "{`XLEN{1'b0}}",
    "inst0_q": "{`INST_W{1'b0}}",
    "inst1_q": "{`INST_W{1'b0}}",
    "resp0_q": "RESP_OK",
    "resp1_q": "RESP_OK",
    "resp0_bytes_q": "3'd4",
}

IMMUTABLE_CAPTURE = {
    "pc_q": "fetch_req_pc_i",
    "paging_q": "req_paging_w",
    "req_priv_q": "priv_mode_i",
    "req_satp_q": "satp_i",
    "req_svpbmt_en_q": "svpbmt_en_i",
    "state_q": "S_CACHE_READ",
}


def case_block(text: str, label: str, next_label: str) -> str:
    start = text.index(f"        {label}: begin")
    end = text.index(f"        {next_label}: begin", start)
    return text[start:end]


def has_assignment(block: str, lhs: str, rhs: str) -> bool:
    pattern = rf"\b{re.escape(lhs)}\s*<=\s*{re.escape(rhs)}\s*;"
    return re.search(pattern, block) is not None


def assigned(block: str, lhs: str) -> bool:
    return re.search(rf"\b{re.escape(lhs)}\s*<=", block) is not None


def audit_text(text: str) -> list[str]:
    errors: list[str] = []
    idle = case_block(text, "S_IDLE", "S_CACHE_READ")
    cache_read = case_block(text, "S_CACHE_READ", "S_LOOKUP")
    response = case_block(text, "S_RESP", "S_DRAIN")

    for owner_name, block in (("S_IDLE", idle), ("S_RESP", response)):
        for lhs in SCRATCH_INIT:
            if assigned(block, lhs):
                errors.append(
                    f"{owner_name} illegally drives derived scratch {lhs}"
                )
        for lhs, rhs in IMMUTABLE_CAPTURE.items():
            if not has_assignment(block, lhs, rhs):
                errors.append(
                    f"{owner_name} does not capture immutable {lhs} <= {rhs}"
                )

    for lhs, rhs in SCRATCH_INIT.items():
        if not has_assignment(cache_read, lhs, rhs):
            errors.append(
                f"S_CACHE_READ does not own exact scratch init {lhs} <= {rhs}"
            )

    if "[IFU-T3X-SCRATCH-INIT]" not in text:
        errors.append("missing temporal scratch-init assertion")
    if "t3x_assert_scratch_init_q <= (state_q == S_CACHE_READ)" not in text:
        errors.append("scratch assertion is not armed by registered S_CACHE_READ")
    return errors


def mutate_once(text: str, old: str, new: str) -> str:
    if text.count(old) < 1:
        raise RuntimeError(
            f"mutation anchor is missing: {old!r}"
        )
    return text.replace(old, new, 1)


def self_tests(text: str) -> dict[str, bool]:
    idle_anchor = "            pc_q <= fetch_req_pc_i;\n"
    idle_illegal = mutate_once(
        text,
        idle_anchor,
        idle_anchor + "            fetch_data_q <= {`XLEN{1'b0}};\n",
    )
    missing_init = mutate_once(
        text,
        "          paddr0_q <= pc_q;\n",
        "          // mutation removed paddr0 scratch initialization\n",
    )
    wrong_owner = mutate_once(
        text,
        "          fetch_offset_q <= 3'd0;\n",
        "          fetch_offset_q <= fetch_req_pc_i[2:0];\n",
    )
    return {
        "catches_accept_wide_scratch_drive": bool(audit_text(idle_illegal)),
        "catches_missing_cache_read_init": bool(audit_text(missing_init)),
        "catches_wrong_cache_read_rhs": bool(audit_text(wrong_owner)),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    text = RTL.read_text(encoding="utf-8")
    errors = audit_text(text)
    mutations = self_tests(text)
    passed = not errors and all(mutations.values())
    result = {
        "schema": "t3x-fetch-init-boundary-audit-v1",
        "rtl": str(RTL.relative_to(ROOT)),
        "passed": passed,
        "errors": errors,
        "mutation_self_tests": mutations,
        "ownership": {
            "accept": sorted(IMMUTABLE_CAPTURE),
            "cache_read": sorted(SCRATCH_INIT),
        },
    }
    encoded = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    print(encoded, end="")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
