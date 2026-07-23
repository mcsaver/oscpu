#!/usr/bin/env python3
"""Fail-closed structural audit for the v8f.1 EX/WB credit cut."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import NoReturn


def fail(message: str) -> NoReturn:
    raise SystemExit(f"[V8F-WB-CREDIT-CUT-AUDIT][FAIL] {message}")


def exactly_once(text: str, anchor: str, label: str) -> None:
    count = text.count(anchor)
    if count != 1:
        fail(f"{label}: expected one anchor, found {count}")


def bounded(text: str, start: str, end: str, label: str) -> str:
    if text.count(start) != 1 or text.count(end) != 1:
        fail(f"{label}: boundaries are missing or ambiguous")
    begin = text.index(start)
    finish = text.index(end, begin) + len(end)
    return text[begin:finish]


def main() -> int:
    run_dir = Path(__file__).resolve().parent
    repo_root = run_dir.parents[2]
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "source",
        nargs="?",
        type=Path,
        default=repo_root / "npc/rv64/vsrc/execute/OooIntBackend.v",
    )
    args = parser.parse_args()
    text = args.source.read_text(encoding="utf-8")

    exactly_once(
        text,
        "  assign ex0_wb_slot_occupied_w = ex0_pre_auth_valid_w;",
        "EX0 occupancy owner",
    )
    exactly_once(
        text,
        "  assign ex1_wb_slot_occupied_w = ex1_pre_auth_valid_w;",
        "EX1 occupancy owner",
    )
    exactly_once(
        text,
        "  assign ex0_wb_valid_w = ex0_pre_auth_valid_w && ex0_producer_open_w;",
        "EX0 exact authorization",
    )
    exactly_once(
        text,
        "  assign ex1_wb_valid_w = ex1_pre_auth_valid_w && ex1_producer_open_w;",
        "EX1 exact authorization",
    )

    credit = bounded(
        text,
        "  wire [1:0] wb_free_count_w =",
        "  wire wb_slot_free_w = (wb_free_count_w != 2'b00);",
        "WB free-count cone",
    )
    grants = bounded(
        text,
        "  wire mem_rsp_to_wb0_w =",
        "  assign fpwb_ready_w = fpwb_to_wb0_w || fpwb_to_wb1_w;",
        "shared-WB grant cone",
    )
    availability = credit + grants
    for forbidden in (
        "ex0_wb_valid_w",
        "ex1_wb_valid_w",
        "ex0_producer_open_w",
        "ex1_producer_open_w",
        "ex0_valid_q",
        "ex1_valid_q",
    ):
        if forbidden in availability:
            fail(f"exact/raw completion leaked into availability cone: {forbidden}")

    expected_counts = {
        "ex0_wb_slot_occupied_w": 5,
        "ex1_wb_slot_occupied_w": 4,
    }
    for signal, expected in expected_counts.items():
        actual = availability.count(signal)
        if actual != expected:
            fail(f"{signal} availability uses drifted: {actual} != {expected}")

    side_effect_anchors = (
        "ex0_wb_valid_w && ex0_down_payload_w[EX_STAGE_FWD_BIT]",
        "ex1_wb_valid_w && ex1_down_payload_w[EX_STAGE_FWD_BIT]",
        "assign wb0_valid_w =\n      ex0_wb_valid_w ||",
        "assign wb1_valid_w =\n      ex1_wb_valid_w ||",
        "(ex0_wb_valid_w && ex0_wb_pdest_nonzero_w)",
        "(ex1_wb_valid_w && ex1_wb_pdest_nonzero_w)",
    )
    for anchor in side_effect_anchors:
        if anchor not in text:
            fail(f"exact-gated side-effect anchor missing: {anchor!r}")

    print(
        "[V8F-WB-CREDIT-CUT-AUDIT] PASS "
        "availability_uses=9 exact_or_raw_availability_uses=0 "
        "actual_completion_exact_gated=1"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
