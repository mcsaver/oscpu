#!/usr/bin/env python3
"""Fail-closed structural audit for the v8h integer long-op PID lease."""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import NoReturn


def fail(message: str) -> NoReturn:
    raise SystemExit(f"[V8H-LONGOP-LEASE-AUDIT][FAIL] {message}")


def exactly_once(text: str, anchor: str, label: str) -> None:
    count = text.count(anchor)
    if count != 1:
        fail(f"{label}: expected one anchor, found {count}: {anchor!r}")


def require_all(text: str, anchors: tuple[str, ...], label: str) -> None:
    for anchor in anchors:
        if anchor not in text:
            fail(f"{label}: missing {anchor!r}")


def assignment(text: str, signal: str) -> str:
    pattern = re.compile(
        rf"(?:wire(?:\s+\[[^;]+?\])?\s+{re.escape(signal)}|"
        rf"assign\s+{re.escape(signal)})\s*=\s*(.*?);",
        re.DOTALL,
    )
    matches = pattern.findall(text)
    if len(matches) != 1:
        fail(f"{signal}: expected one assignment, found {len(matches)}")
    return matches[0]


def bounded(text: str, start: str, end: str, label: str) -> str:
    if text.count(start) != 1 or text.count(end) != 1:
        fail(f"{label}: missing or ambiguous boundaries")
    begin = text.index(start)
    finish = text.index(end, begin) + len(end)
    return text[begin:finish]


def audit_unit(text: str, name: str) -> None:
    require_all(
        text,
        (
            "parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W",
            "parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W",
            "input [PRODUCER_ID_W-1:0] req_producer_id_i",
            "output [PRODUCER_ID_W-1:0] resp_producer_id_o",
            "output owner_valid_o",
            "output [PRODUCER_ID_W-1:0] owner_producer_id_o",
            "reg [PRODUCER_ID_W-1:0] producer_id_q;",
            "producer_id_q <= req_producer_id_i;",
            "[ROB_INDEX_W-1:0]",
        ),
        f"{name} full-PID interface/state",
    )
    for forbidden in ("req_rob_idx_i", "req_rob_idx_q", "resp_rob_idx_q"):
        if forbidden in text:
            fail(f"{name}: parallel raw owner identity remains: {forbidden}")
    if text.count("reg [PRODUCER_ID_W-1:0] producer_id_q;") != 1:
        fail(f"{name}: producer_id_q is not the unique declared full identity")

    ready = assignment(text, "req_ready_o")
    for required in ("state_q == STATE_IDLE", "!rst", "!flush_i", "!kill_valid_i"):
        if required not in ready:
            fail(f"{name}: request ready lost guard {required}")
    owner_valid = assignment(text, "owner_valid_o").strip()
    if owner_valid != "state_q != STATE_IDLE":
        fail(f"{name}: owner_valid is not a Q-only full-lifetime Moore projection")
    if assignment(text, "owner_producer_id_o").strip() != "producer_id_q":
        fail(f"{name}: owner PID is not the unique Q identity")
    if assignment(text, "resp_producer_id_o").strip() != "producer_id_q":
        fail(f"{name}: response PID is not the unique Q identity")
    raw_projection = assignment(text, "resp_rob_idx_o")
    if "owner_rob_idx_w" not in raw_projection:
        fail(f"{name}: raw response index is not projected from the full PID")
    resp_valid = assignment(text, "resp_valid_o")
    for required in ("state_q == STATE_RESP", "!rst", "!flush_i", "!kill_inflight_w"):
        if required not in resp_valid:
            fail(f"{name}: response valid lost guard {required}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--muldiv", type=Path)
    parser.add_argument("--clmul", type=Path)
    parser.add_argument("--backend", type=Path)
    parser.add_argument("--rob", type=Path)
    parser.add_argument("--dispatch", type=Path)
    args = parser.parse_args()

    run_dir = Path(__file__).resolve().parent
    repo = run_dir.parents[2]
    vsrc = repo / "npc/rv64/vsrc"
    tb = repo / "npc/rv64/testbench/tests"
    muldiv = (args.muldiv or vsrc / "execute/OooMulDivUnit.v").read_text(
        encoding="utf-8"
    )
    clmul = (args.clmul or vsrc / "execute/OooClmulUnit.v").read_text(
        encoding="utf-8"
    )
    backend = (args.backend or vsrc / "execute/OooIntBackend.v").read_text(
        encoding="utf-8"
    )
    rob = (args.rob or vsrc / "writeback/OooRob.v").read_text(encoding="utf-8")
    dispatch = (
        args.dispatch or vsrc / "rename_allocate/OooDispatchBackend.v"
    ).read_text(encoding="utf-8")

    audit_unit(muldiv, "MulDiv")
    audit_unit(clmul, "CLMUL")

    require_all(
        backend,
        (
            ".req_producer_id_i(iq_issue0_producer_id_w)",
            ".resp_producer_id_o(muldiv_resp_producer_id_w)",
            ".resp_producer_id_o(clmul_resp_producer_id_w)",
            ".owner_valid_o(muldiv_owner_valid_w)",
            ".owner_valid_o(clmul_owner_valid_w)",
            ".completion3_query_valid_i(muldiv_resp_valid_w)",
            ".completion3_query_producer_id_i(muldiv_resp_producer_id_w)",
            ".completion4_query_valid_i(clmul_resp_valid_w)",
            ".completion4_query_producer_id_i(clmul_resp_producer_id_w)",
            ".producer_live_mask_i(producer_live_mask_w)",
        ),
        "backend full-PID plumbing",
    )
    if backend.count(".req_producer_id_i(iq_issue0_producer_id_w)") != 2:
        fail("both long-op requests must capture the IQ full ProducerId")

    union = assignment(backend, "producer_live_mask_w")
    for source in (
        "mem_owner_producer_live_mask_w",
        "muldiv_owner_producer_live_mask_w",
        "clmul_owner_producer_live_mask_w",
    ):
        if union.count(source) != 1:
            fail(f"producer live-mask union lost or duplicated {source}")
    for mask, valid, pid in (
        (
            "muldiv_owner_producer_live_mask_w",
            "muldiv_owner_valid_w",
            "muldiv_owner_producer_id_w",
        ),
        (
            "clmul_owner_producer_live_mask_w",
            "clmul_owner_valid_w",
            "clmul_owner_producer_id_w",
        ),
    ):
        expr = assignment(backend, mask)
        if valid not in expr or pid not in expr:
            fail(f"{mask}: onehot lease no longer reads Q owner valid/PID")
        for forbidden in ("resp_ready", "completion_rob_open", "same_edge", "kill"):
            if forbidden in expr:
                fail(f"{mask}: non-Q authority/terminal fact leaked into lease: {forbidden}")

    ex1 = assignment(backend, "ex1_wb_valid_w")
    for required in ("ex1_pre_auth_valid_w", "ex1_producer_open_w", "!ex1_same_edge_claimed_w"):
        if required not in ex1:
            fail(f"EX1 actual claim lost {required}")

    mul_claim = assignment(backend, "muldiv_same_edge_claimed_w")
    for required in (
        "ex0_wb_valid_w",
        "ex0_producer_id_q == muldiv_resp_producer_id_w",
        "ex1_wb_valid_w",
        "ex1_producer_id_q == muldiv_resp_producer_id_w",
        "mem_wb_fire_w",
        "mem_completion_producer_id_w == muldiv_resp_producer_id_w",
    ):
        if required not in mul_claim:
            fail(f"MulDiv same-edge claim lost {required}")
    cl_claim = assignment(backend, "clmul_same_edge_claimed_w")
    for required in (
        "ex0_wb_valid_w",
        "ex1_wb_valid_w",
        "mem_wb_fire_w",
        "muldiv_actual_claim_w",
        "muldiv_resp_producer_id_w == clmul_resp_producer_id_w",
    ):
        if required not in cl_claim:
            fail(f"CLMUL same-edge claim lost {required}")
    for name, expr in (("MulDiv claim", mul_claim), ("CLMUL claim", cl_claim)):
        for forbidden in ("resp_ready", "rsp_to_wb", "owner_producer_live_mask"):
            if forbidden in expr:
                fail(f"{name}: transport/mask fact leaked into actual claim: {forbidden}")

    for name, signal, raw, rob_open, claim in (
        (
            "MulDiv",
            "muldiv_completion_authorized_w",
            "muldiv_resp_valid_w",
            "muldiv_completion_rob_open_w",
            "!muldiv_same_edge_claimed_w",
        ),
        (
            "CLMUL",
            "clmul_completion_authorized_w",
            "clmul_resp_valid_w",
            "clmul_completion_rob_open_w",
            "!clmul_same_edge_claimed_w",
        ),
    ):
        expr = assignment(backend, signal)
        for required in (raw, rob_open, claim):
            if required not in expr:
                fail(f"{name} authorization lost {required}")

    for prefix in ("muldiv", "clmul"):
        ready = assignment(backend, f"{prefix}_resp_ready_w")
        for required in (f"{prefix}_rsp_to_wb0_w", f"{prefix}_rsp_to_wb1_w"):
            if required not in ready:
                fail(f"{prefix} ready lost raw route {required}")
        for forbidden in ("authorized", "rob_open", "same_edge"):
            if forbidden in ready:
                fail(f"{prefix} authority fed raw response ready: {forbidden}")
        for lane in (0, 1):
            route = assignment(backend, f"{prefix}_rsp_to_wb{lane}_w")
            for forbidden in ("authorized", "rob_open", "same_edge"):
                if forbidden in route:
                    fail(f"{prefix} raw route{lane} reads authority: {forbidden}")
            actual = assignment(backend, f"{prefix}_wb{lane}_valid_w")
            if f"{prefix}_rsp_to_wb{lane}_w" not in actual or \
                    f"{prefix}_completion_authorized_w" not in actual:
                fail(f"{prefix} actual lane{lane} is not raw-route AND authorization")

    wb0 = assignment(backend, "wb0_valid_w")
    wb1 = assignment(backend, "wb1_valid_w")
    for lane, expr in ((0, wb0), (1, wb1)):
        for required in (f"muldiv_wb{lane}_valid_w", f"clmul_wb{lane}_valid_w"):
            if required not in expr:
                fail(f"WB{lane} public completion lost actual long-op source {required}")
        for forbidden in (f"muldiv_rsp_to_wb{lane}_w", f"clmul_rsp_to_wb{lane}_w"):
            if forbidden in expr:
                fail(f"WB{lane} public valid consumes raw long-op route: {forbidden}")

    ready_cone = bounded(
        dispatch,
        "  wire dispatch1_pair_ready_w =",
        "  wire dispatch1_fire_w = dispatch1_valid_i && dispatch1_ready_o;",
        "dispatch lease ready cone",
    )
    if ready_cone.count("producer_live_mask_i[") != 3:
        fail("dispatch ready cone must have pair/lane0/lane1 indexed PID lookups")
    for required in (
        "rob_dispatch1_pair_producer_id_w]",
        "rob_dispatch0_producer_id_w]",
        "rob_dispatch1_producer_id_w]",
    ):
        if required not in ready_cone:
            fail(f"dispatch ready cone lost {required}")
    for forbidden in ("memory_producer_live_mask_i", "resp_ready", "completion3_query_match"):
        if forbidden in ready_cone or forbidden in dispatch[:2500]:
            fail(f"dispatch lease interface/cone retained forbidden dependency {forbidden}")
    require_all(
        dispatch,
        ("[V8H-DISPATCH-PAIR-PID-DISTINCT]", ".completion3_query_valid_i(", ".completion4_query_valid_i("),
        "dispatch query bridge/pair proof",
    )

    for query, label in ((3, "MulDiv"), (4, "CLMUL")):
        exact = assignment(rob, f"completion{query}_query_exact_w")
        for required in (
            f"slot_generation_q[completion{query}_query_idx_w]",
            f"completion{query}_query_producer_id_i",
        ):
            if required not in exact:
                fail(f"ROB query{query} exact comparison lost {required}")
        match = assignment(rob, f"completion{query}_query_match_o")
        for required in (
            f"completion{query}_query_valid_i",
            "!rst",
            "!flush_i",
            f"valid_q[completion{query}_query_idx_w]",
            f"!done_q[completion{query}_query_idx_w]",
            f"completion{query}_query_exact_w",
            f"!producer_target_killed_now(completion{query}_query_idx_w)",
        ):
            if required not in match:
                fail(f"ROB {label} query{query} lost exact-open term {required}")
    require_all(
        rob,
        (
            "wire [ROB_INDEX_W-1:0] dispatch1_pair_idx_w =\n      rob_ptr_add(tail_q, 2'd1);",
            "[V8H-ROB-PAIR-PID-DISTINCT]",
        ),
        "ROB pair PID distinct proof",
    )

    int_tb = (tb / "tb_ooo_int_backend.sv").read_text(encoding="utf-8")
    mul_tb = (tb / "tb_ooo_muldiv_unit.sv").read_text(encoding="utf-8")
    cl_tb = (tb / "tb_ooo_clmul_unit.sv").read_text(encoding="utf-8")
    require_all(
        int_tb,
        (
            "[V8H-LONGOP-SAME-EDGE-CLAIM]",
            "v8h EX0/MulDiv authorization fenced",
            "v8h memory/CLMUL actual fenced",
            "v8h equal longops CLMUL fenced",
            "v8h stale MulDiv still drains",
            "v8h exact FP uses remaining lane",
        ),
        "backend directed claim matrix",
    )
    for unit_tb, name in ((mul_tb, "MulDiv"), (cl_tb, "CLMUL")):
        require_all(
            unit_tb,
            ("terminal edge keeps old lease", "death edge keeps old lease"),
            f"{name} death-before-birth tests",
        )

    print("[V8H-LONGOP-LEASE-AUDIT] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
