#!/usr/bin/env python3
"""Fail-closed source contract for the T3P lane1 simple-ALU owner boundary."""

from __future__ import annotations

import json
import os
import re
from pathlib import Path


ROOT = Path(
    os.environ.get("T3P_SOURCE_ROOT", str(Path(__file__).resolve().parents[3]))
).resolve()
IQ_PATH = ROOT / "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v"
IB_PATH = ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"[T3P-SOURCE] FAIL: {message}")


def function_body(text: str, name: str) -> str:
    match = re.search(
        rf"\bfunction\s+{re.escape(name)}\s*;(?P<body>.*?)\bendfunction\b",
        text,
        flags=re.S,
    )
    require(match is not None, f"missing function {name}")
    return match.group("body")


def main() -> None:
    iq = IQ_PATH.read_text(encoding="utf-8")
    ib = IB_PATH.read_text(encoding="utf-8")
    iq_owner = function_body(iq, "ctrl_is_lane1_simple_alu")
    ib_owner = function_body(ib, "is_lane1_simple_alu_ctrl")

    # Both producer and consumer must encode the same conservative class
    # boundary.  Requiring each named bit prevents one side from silently
    # widening lane1 while the other keeps a shallow unconditional ready.
    excluded_bits = (
        "CTRL_ILLEGAL_BIT",
        "CTRL_BRANCH_BIT",
        "CTRL_JAL_BIT",
        "CTRL_JALR_BIT",
        "CTRL_LOAD_BIT",
        "CTRL_STORE_BIT",
        "CTRL_ECALL_BIT",
        "CTRL_EBREAK_BIT",
        "CTRL_FENCE_BIT",
        "CTRL_SYSTEM_BIT",
        "CTRL_MISC_MEM_BIT",
        "CTRL_CSR_BIT",
        "CTRL_MRET_BIT",
        "CTRL_WFI_BIT",
        "CTRL_MULDIV_BIT",
        "CTRL_BITMANIP_BIT",
        "CTRL_SFENCE_VMA_BIT",
        "CTRL_SRET_BIT",
        "CTRL_AMO_BIT",
        "CTRL_SFENCE_TVM_BIT",
        "CTRL_FENCEI_BIT",
    )
    for body_name, body in (("IQ", iq_owner), ("IntBackend", ib_owner)):
        require("CTRL_VALID_BIT" in body, f"{body_name} owner lacks valid domain")
        for bit in excluded_bits:
            require(f"!ctrl[`{bit}]" in body, f"{body_name} owner does not exclude {bit}")

    require(
        "ctrl_is_lane1_simple_alu(ctrl_q[scan_i])" in iq,
        "IQ second-candidate scan is not owned by the simple classifier",
    )
    require("[IQ-LANE1-SIMPLE-OWNER]" in iq, "IQ owner assertion missing")
    require("[INT-LANE1-SIMPLE-OWNER]" in ib, "backend owner assertion missing")

    # The ready equation is intentionally shallow and must retain the formal
    # WB starvation guard.  No address, SQ, SC, memory or long-op predicate may
    # be reintroduced into this assignment.
    ready_match = re.search(
        r"assign\s+issue1_ready_w\s*=\s*(?P<expr>.*?);",
        ib,
        flags=re.S,
    )
    require(ready_match is not None, "issue1 ready assignment missing")
    ready_expr = re.sub(r"\s+", " ", ready_match.group("expr")).strip()
    require(
        ready_expr
        == "!flush_i && !issue_block_w && !mem_rsp_waiting_for_wb_w",
        f"issue1 ready is no longer the frozen shallow equation: {ready_expr}",
    )

    # RAW-I1 is a sticky-ready scheduling invariant.  The old combinational
    # current-result path must be physically absent, not merely select=0.
    for forbidden in (
        "issue0_current_result_valid_w",
        "issue1_src1_issue0_forward_w",
        "issue1_src2_issue0_forward_w",
    ):
        require(forbidden not in ib, f"cross-lane forward artifact remains: {forbidden}")
    require(
        "wire [`XLEN-1:0] issue1_src1_value_w = issue1_src1_data_w;" in ib,
        "lane1 src1 is not a direct stored-PRF alias",
    )
    require(
        "wire [`XLEN-1:0] issue1_src2_value_w = issue1_src2_data_w;" in ib,
        "lane1 src2 is not a direct stored-PRF alias",
    )
    require("[INT-ISSUE-CONTRACT RAW-I1]" in ib, "RAW-I1 assertion missing")

    report = {
        "status": "PASS",
        "files": [str(IQ_PATH.relative_to(ROOT)), str(IB_PATH.relative_to(ROOT))],
        "lane1_owner": "fixed-latency-rv64i-simple-alu",
        "excluded_control_bits": list(excluded_bits),
        "issue1_ready_inputs": [
            "flush_i",
            "issue_block_w",
            "mem_rsp_waiting_for_wb_w",
        ],
        "cross_lane_current_result_forward": "physically-absent",
        "lane1_operand_source": "stored-prf-only",
    }
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
