#!/usr/bin/env python3
"""Fail-closed structural audit for the v8g async-memory ProducerId lease."""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import NoReturn


def fail(message: str) -> NoReturn:
    raise SystemExit(f"[V8G-MEMORY-LEASE-AUDIT][FAIL] {message}")


def exactly_once(text: str, anchor: str, label: str) -> None:
    count = text.count(anchor)
    if count != 1:
        fail(f"{label}: expected one anchor, found {count}")


def require_all(text: str, anchors: tuple[str, ...], label: str) -> None:
    for anchor in anchors:
        exactly_once(text, anchor, f"{label}: {anchor!r}")


def bounded(text: str, start: str, end: str, label: str) -> str:
    if text.count(start) != 1 or text.count(end) != 1:
        fail(f"{label}: boundaries are missing or ambiguous")
    begin = text.index(start)
    finish = text.index(end, begin) + len(end)
    return text[begin:finish]


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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--bridge",
        type=Path,
        help="override OooMemAxiBridge.v for compile-success structural mutants",
    )
    parser.add_argument(
        "--backend",
        type=Path,
        help="override OooIntBackend.v for compile-success structural mutants",
    )
    args = parser.parse_args()

    run_dir = Path(__file__).resolve().parent
    repo = run_dir.parents[2]
    npc = repo / "npc/rv64/vsrc"
    tracker = (npc / "memory/OooMemOwnerTracker.v").read_text(encoding="utf-8")
    rob = (npc / "writeback/OooRob.v").read_text(encoding="utf-8")
    dispatch = (npc / "rename_allocate/OooDispatchBackend.v").read_text(
        encoding="utf-8"
    )
    sq = (npc / "memory/OooStoreQueue.v").read_text(encoding="utf-8")
    backend_path = args.backend or (npc / "execute/OooIntBackend.v")
    backend = backend_path.read_text(encoding="utf-8")
    bridge_path = args.bridge or (npc / "memory/OooMemAxiBridge.v")
    bridge = bridge_path.read_text(encoding="utf-8")

    bridge_drop = bounded(
        bridge,
        "  always @(*) begin\n    active_drop_terminal_r = 1'b0;",
        "  wire station_drop_terminal_w",
        "bridge raw active-drop terminal",
    )
    for forbidden in ("stage_advance_w", "rsp_ready_w", "mem0_rsp_ready_i"):
        if forbidden in bridge_drop:
            fail(
                "bridge raw drop terminal reads ready/advance: "
                f"{forbidden}"
            )
    require_all(
        bridge_drop,
        (
            "if ((flush_i || drop_rsp_q) && !nokill_busy_w) begin",
            "S_RESP: active_drop_terminal_r = 1'b1;",
        ),
        "bridge ready-independent raw terminal",
    )
    station_query = assignment(bridge, "mem0_station_query_valid_o")
    if station_query.strip() != "stg_valid_q":
        fail("bridge station tracker query is not registered-Q-only")
    station_drop = assignment(bridge, "station_drop_terminal_w")
    for forbidden in ("stage_advance_w", "rsp_ready_w", "mem0_rsp_ready_i"):
        if forbidden in station_drop:
            fail(f"bridge station drop reads ready/advance: {forbidden}")
    for required in ("flush_i", "stg_valid_q", "!stg_nokill_q"):
        if required not in station_drop:
            fail(f"bridge station drop lost condition: {required}")

    require_all(
        tracker,
        (
            "wire alloc0_pid_clear_w =\n      !producer_live_q[alloc0_producer_id_i];",
            "wire alloc1_pid_clear_w =\n      !producer_live_q[alloc1_producer_id_i];",
            "live_next_r = (live_q & ~death_mask_r) | birth_mask_r;",
            "producer_live_next_r =\n        (producer_live_q & ~producer_clear_mask_r) |\n        producer_set_mask_r;",
            "if ((death_mask_r & birth_mask_r) != {TOKEN_COUNT{1'b0}})",
            "if ((producer_clear_mask_r & producer_set_mask_r) !=\n          {PRODUCER_COUNT{1'b0}})",
            "(alloc1_producer_id_i == alloc0_producer_id_i)",
        ),
        "tracker edge-old lease algebra",
    )
    if assignment(tracker, "alloc0_ready_o").count("alloc0_pid_clear_w") != 1:
        fail("tracker alloc0 ready is not gated by edge-old PID mask")
    if assignment(tracker, "alloc1_ready_o").count("alloc1_pid_clear_w") != 1:
        fail("tracker alloc1 ready is not gated by edge-old PID mask")

    dispatch_ready = bounded(
        dispatch,
        "  wire dispatch1_pair_ready_w =",
        "  wire dispatch1_fire_w = dispatch1_valid_i && dispatch1_ready_o;",
        "dispatch ready cone",
    )
    if dispatch_ready.count("memory_producer_live_mask_i[") != 3:
        fail("dispatch ready cone must contain exactly lane0/pair/actual PID lookups")
    for forbidden in (
        "mem_owner_live_mask",
        "miq_",
        "sq_snoop",
        "owner_token",
        "mem_rsp_ready",
    ):
        if forbidden in dispatch_ready:
            fail(f"holder/response signal leaked into Q-only dispatch cone: {forbidden}")
    require_all(
        dispatch_ready,
        (
            "rob_dispatch1_pair_producer_id_w]",
            "rob_dispatch0_producer_id_w]",
            "rob_dispatch1_producer_id_w]",
        ),
        "dispatch indexed lease gates",
    )

    require_all(
        rob,
        (
            "wire completion2_query_exact_w =\n      {slot_generation_q[completion2_query_idx_w], completion2_query_idx_w} ==\n      completion2_query_producer_id_i;",
            "valid_q[completion2_query_idx_w] && !done_q[completion2_query_idx_w] &&\n      completion2_query_exact_w &&",
            "assign head0_launch_open_o = !rst && !flush_i && !recovering_w &&\n      (count_q != {ROB_COUNT_W{1'b0}}) && valid_q[head_q] &&\n      !done_q[head_q];",
            "assign dispatch1_pair_producer_id_o =\n      {dispatch1_pair_generation_candidate_w, dispatch1_pair_idx_w};",
        ),
        "ROB memory query/head/pair contract",
    )

    require_all(
        sq,
        (
            "(producer_id_q[gc] == owner_bind_producer_id_i) &&\n          (rob_idx_q[gc] == owner_bind_rob_idx_i);",
            "(producer_id_q[head_q] == rob_head_producer_id_i) &&\n      (rob_idx_q[head_q] == rob_head_idx_i);",
            "(producer_id_q[head_q] == release_producer_id_i) &&\n      (rob_idx_q[head_q] == release_rob_idx_i)",
            "valid_q[assert_i] && request_sent_q[assert_i] &&\n            !terminal_q[assert_i] &&",
        ),
        "SQ full-PID bind/request/release/post-launch",
    )

    require_all(
        backend,
        (
            "mem_issue_res_present_candidate_w && iq_issue0_producer_current_w;",
            "mem_issue_res_present_candidate_w && !iq_issue0_producer_current_w;",
            "miq_head_valid_w && miq_pop_owner_match_w &&\n      miq_head_tracker_exact_w;",
            "miq_head_tracker_exact_w && mem_holder_phase_valid_w &&\n      mem_completion_rob_open_w &&",
            "wire mem_fatal_irrevocable_response_w = mem_owner_closed_w &&",
            "wire mem_legal_closed_response_w = mem_owner_closed_w &&",
            "wire mem_amo_read_candidate_w = mem_owner_open_w &&",
            "wire mem_rsp_final_fire_w = mem_rsp_fire_w && !mem_amo_read_rsp_w &&\n      !mem_fatal_irrevocable_response_w;",
            "wire miq_load_wb_fire_w =\n      miq_load_rsp_fire_w && mem_owner_open_w;",
            "wire miq_probe_wb_fire_w =\n      miq_probe_rsp_fire_w && mem_owner_open_w &&\n      (mem_rsp_fault_w || !sq_mode_w);",
            "wire mem_legacy_wb_fire_w =\n      mem_rsp_final_fire_w && mem_owner_open_w;",
            "!mem_rsp_waiting_for_wb_w;",
        ),
        "backend response authorization",
    )

    tracker_exact = assignment(backend, "miq_head_tracker_exact_w")
    for required in (
        "mem_owner_live_mask_w",
        "mem_owner_kind_table_w",
        "miq_head_owner_kind_w",
        "mem_owner_epoch_table_w",
        "miq_head_mmu_epoch_w",
    ):
        if required not in tracker_exact:
            fail(f"tracker exact tag lost field: {required}")

    other_raw = assignment(backend, "mem_terminal_other_raw_mask_w")
    for lane in range(1, 6):
        if f"mem_terminal_ingress{lane}_mask_w" not in other_raw:
            fail(f"terminal raw DAG omitted lane{lane}")
    if "mem_terminal_ingress0_mask_w" in other_raw:
        fail("response lane0 fed its own terminal-credit mask")
    credit = assignment(backend, "mem_response_terminal_credit_w")
    if credit.count("mem_terminal_pending_mask_w") != 1 or other_raw.strip() == "":
        fail("terminal credit lost edge-old pending/raw conflict checks")
    if "mem_terminal_other_raw_mask_w" not in credit:
        fail("terminal credit does not reserve higher-priority raw candidates")

    raw_valid_vector = assignment(backend, "mem_terminal_ingress_valid_w")
    for required in (
        "mem_amo_interphase_cancel_w",
        "mem_buffer_tagged_terminal_w",
        "mem_issue_res_tagged_terminal_w",
        "mem_drop1_valid_i",
        "mem_drop0_valid_i",
        "mem_terminal_rsp_valid_w",
    ):
        if required not in raw_valid_vector:
            fail(f"terminal ingress lane mapping drifted: {required}")
    mask_sources = (
        (0, "mem_terminal_rsp_valid_w", "miq_head_owner_token_w"),
        (1, "mem_drop0_valid_i", "mem_drop0_owner_token_i"),
        (2, "mem_drop1_valid_i", "mem_drop1_owner_token_i"),
        (3, "mem_issue_res_tagged_terminal_w", "mem_issue_res_owner_token_q"),
        (4, "mem_buffer_tagged_terminal_w", "mem_buffer_owner_token_q"),
        (5, "mem_amo_interphase_cancel_w", "mem_owner_token_q"),
    )
    for lane, valid, token in mask_sources:
        expr = assignment(backend, f"mem_terminal_ingress{lane}_mask_w")
        for forbidden in (
            "mem_terminal_ingress_valid_w",
            "mem_terminal_ingress_token_w",
        ):
            if forbidden in expr:
                fail(f"terminal mask lane{lane} reads packed vector: {forbidden}")
        if valid not in expr or token not in expr:
            fail(f"terminal mask lane{lane} lost direct scalar source")
    for raw_signal in (
        "mem_amo_interphase_cancel_w",
        "mem_buffer_tagged_terminal_w",
        "mem_issue_res_tagged_terminal_w",
    ):
        expr = assignment(backend, raw_signal)
        for forbidden in ("mem_rsp_ready_o", "mem_rsp_fire_w", "mem_rsp_final_fire_w"):
            if forbidden in expr:
                fail(f"{raw_signal} reads response acceptance: {forbidden}")

    local_complete = assignment(backend, "mem_issue_res_local_complete_w")
    for forbidden in (
        "mem_issue_res_consume_fire_w",
        "issue0_mem_can_fire_w",
        "mem_req_ready_i",
    ):
        if forbidden in local_complete:
            fail(f"local terminal re-entered request-ready cone: {forbidden}")
    for required in (
        "mem_issue_res_valid_q",
        "issue0_global_ready_w",
        "issue0_mem_issue_eligible_w",
        "issue0_mem_exception_w",
        "issue0_sq_fwd_w",
    ):
        if required not in local_complete:
            fail(f"factored local terminal lost condition: {required}")

    buffer_grant = assignment(backend, "grant_buffer_w")
    if "!mem_buffer_kill_w" not in buffer_grant:
        fail("killed buffer may enter request grant")
    buffer_cancel = assignment(backend, "mem_buffer_cancel_w")
    for forbidden in ("mem_buffer_req_fire_w", "mem_req_ready_i"):
        if forbidden in buffer_cancel:
            fail(f"buffer cancel re-entered request-ready cone: {forbidden}")
    for required in (
        "mem_buffer_valid_q",
        "mem_buffer_kill_w",
        "flush_i",
        "checkpoint_restore_i",
    ):
        if required not in buffer_cancel:
            fail(f"buffer cancel lost condition: {required}")

    ready = assignment(backend, "mem_rsp_ready_o")
    for required in (
        "mem_owner_open_w ? mem_open_all_sink_credit_w",
        "mem_fatal_irrevocable_response_w ? 1'b1",
        "mem_legal_closed_response_w ? mem_response_terminal_credit_w",
    ):
        if required not in ready:
            fail(f"response classification/credit arm missing: {required}")

    require_all(
        backend,
        (
            "wire sq_drain_launch_authorized_w = sq_drain_tracker_exact_w &&\n      (sq_drain_tracker_producer_id_w == sq_drain_producer_id_w) &&\n      (sq_drain_producer_id_w == rob_head_producer_id_w) &&\n      rob_head_launch_open_w;",
            "wire mem_amo_launch_authorized_w = mem_amo_tracker_exact_w &&\n      (mem_amo_tracker_producer_id_w == rob_head_producer_id_w) &&\n      (mem_amo_tracker_producer_id_w ==\n       mem_producer_id_q) &&\n      rob_head_launch_open_w;",
            "mem_amo_write_sent_q && mem_pending_q &&\n          (!mem_amo_tracker_exact_w || !rob_head_launch_open_w ||",
            "[V8G-MEM-BOUNDED-COMPLETION]",
        ),
        "physical launch/post-launch/bounded completion",
    )

    print(
        "[V8G-MEMORY-LEASE-AUDIT] PASS "
        "tracker_edge_old=1 dispatch_q_only_lookups=3 rob_query2=1 "
        "sq_full_pid=1 terminal_raw_lanes=5 response_classes=3 "
        "physical_launch_chains=2 bridge_ready_cut=1 local_ready_cut=1 "
        "buffer_ready_cut=1 station_query_q_only=1 station_drop_ready_cut=1 "
        "scalar_terminal_masks=6"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
