#!/usr/bin/env python3
"""Fail-closed structural checker for the v8t/F3 final-PA SQ checkpoint."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from dataclasses import asdict, dataclass


@dataclass(frozen=True)
class Check:
    check_id: str
    passed: bool
    detail: str


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def occurrences(text: str, pattern: str) -> int:
    return len(re.findall(pattern, text, flags=re.S | re.M))


def has_all(text: str, fragments: list[str]) -> tuple[bool, list[str]]:
    missing = [fragment for fragment in fragments if fragment not in text]
    return not missing, missing


def resolve_source(root: pathlib.Path, value: str | None, default: str) -> pathlib.Path:
    path = pathlib.Path(value) if value else root / default
    path = path.resolve(strict=True)
    if value is None:
        path.relative_to(root)
    return path


def load_sources(args: argparse.Namespace) -> dict[str, str]:
    root = pathlib.Path(args.repo_root).resolve(strict=True)
    paths = {
        "sq": resolve_source(
            root, args.sq,
            "npc/rv64/vsrc/memory/OooStoreQueue.v"),
        "bridge": resolve_source(
            root, args.bridge,
            "npc/rv64/vsrc/memory/OooMemAxiBridge.v"),
        "backend": resolve_source(
            root, args.backend,
            "npc/rv64/vsrc/execute/OooIntBackend.v"),
        "wrapper": root / "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v",
        "decode": root / "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
        "slice": root / "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
        "execute": root / "npc/rv64/vsrc/execute/OooExecuteBackend.v",
        "glue": root / "npc/rv64/vsrc/core/OooCoreTopGlue.v",
        "core": root / "npc/rv64/vsrc/core/NpcCoreTop.v",
        "sq_tb": root / "npc/rv64/testbench/tests/tb_ooo_store_queue.sv",
        "bridge_tb": root / "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
        "backend_tb": root / "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
        "contract": root / (
            ".github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/"
            "contract.md"),
        "derivation": root / (
            ".github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/"
            "rtl-derivation.md"),
    }
    result: dict[str, str] = {}
    for key, path in paths.items():
        resolved = path.resolve(strict=True)
        if key not in {"sq", "bridge", "backend"}:
            resolved.relative_to(root)
        result[key] = resolved.read_text(encoding="utf-8")
    return result


def structural_checks(sources: dict[str, str]) -> list[Check]:
    code = {
        key: strip_comments(value)
        for key, value in sources.items()
        if key not in {"contract", "derivation"}
    }
    sq = code["sq"]
    bridge = code["bridge"]
    backend = code["backend"]
    checks: list[Check] = []

    def add(check_id: str, passed: bool, detail: str) -> None:
        checks.append(Check(check_id, bool(passed), detail))

    ok, missing = has_all(sq, [
        "input query0_valid_i", "input query1_valid_i",
        "output query0_allow_o", "output query0_forward_o",
        "output query0_replay_o", "output query1_allow_o",
        "output query1_forward_o", "output query1_replay_o",
        "query0_phys_byte_cam_blk", "query1_phys_byte_cam_blk",
    ])
    add("sq.two_independent_query_faces", ok, f"missing={missing}")

    physical_compare = occurrences(
        sq,
        r"store_byte_addr_r\s*=\s*paddr_q\[entry_idx_r\]\s*\+\s*"
        r"store_byte_i\s*;",
    )
    va_compare = occurrences(
        sq,
        r"store_byte_addr_r\s*=\s*vaddr_q\[entry_idx_r\]",
    )
    add(
        "sq.final_physical_byte_compare_only",
        physical_compare == 2 and va_compare == 0,
        f"paddr_assignments={physical_compare} va_assignments={va_compare}",
    )

    sq_semantics = {
        "head_tail": occurrences(sq, r"entry_idx_r\s*=\s*head_q\s*\+\s*entry_i"),
        "terminal_exclusion": occurrences(
            sq, r"valid_q\[entry_idx_r\].*?!terminal_q\[entry_idx_r\]"),
        "unfilled_poison": occurrences(sq, r"if\s*\(\s*!filled_q\[entry_idx_r\]"),
        "typed_poison": occurrences(sq, r"!typed_attr_admitted\(attr_valid_q\[entry_idx_r\]"),
        "io_poison": occurrences(sq, r"class_q\[entry_idx_r\]\s*==\s*`OOO_MEM_CLASS_IO"),
        "youngest_overwrite": occurrences(
            sq, r"query[01]_forward_data_r\[load_byte_i\*8\s*\+:\s*8\]\s*="),
        "oldest_guard": occurrences(
            sq, r"if\s*\(\s*!covered_r\[load_byte_i\]\s*\)"),
        "full_cover": occurrences(
            sq, r"\(covered_r\s*&\s*query[01]_strb_i\)\s*==\s*query[01]_strb_i"),
    }
    add(
        "sq.fail_closed_youngest_merge_semantics",
        sq_semantics == {
            "head_tail": 2,
            "terminal_exclusion": 2,
            "unfilled_poison": 2,
            "typed_poison": 2,
            "io_poison": 2,
            "youngest_overwrite": 2,
            "oldest_guard": 0,
            "full_cover": 2,
        },
        f"counts={sq_semantics}",
    )

    sq_age = {
        "sent_override": occurrences(
            sq, r"entry_older_r\s*=\s*request_sent_q\[entry_idx_r\]\s*\|\|"
        ),
        "distinct_pid": occurrences(
            sq, r"producer_id_q\[entry_idx_r\]\s*!=\s*"
            r"query[01]_producer_id_i"
        ),
        "edge_old_dist": occurrences(
            sq,
            r"rob_dist\(rob_idx_q\[entry_idx_r\],\s*rob_head_idx_i\)\s*<\s*"
            r"rob_dist\(query[01]_producer_id_i\[ROB_INDEX_W-1:0\],\s*"
            r"rob_head_idx_i\)",
        ),
    }
    age_tb = all(marker in code["sq_tb"] for marker in [
        "F3 ROB-wrap older store forwards",
        "F3 ROB-wrap younger store is excluded",
        "F3 same PID store is excluded",
        "F3 same-age different-generation store is excluded",
    ])
    add(
        "sq.edge_old_full_pid_age",
        sq_age == {"sent_override": 2, "distinct_pid": 2,
                   "edge_old_dist": 2} and age_tb,
        f"counts={sq_age} directed={age_tb}",
    )

    query_face_inputs = {
        "pa0": occurrences(
            sq, r"load_byte_addr_r\s*=\s*query0_paddr_i\s*\+\s*load_byte_i"
        ),
        "pa1": occurrences(
            sq, r"load_byte_addr_r\s*=\s*query1_paddr_i\s*\+\s*load_byte_i"
        ),
        "cover0": occurrences(
            sq, r"\(covered_r\s*&\s*query0_strb_i\)\s*==\s*query0_strb_i"
        ),
        "cover1": occurrences(
            sq, r"\(covered_r\s*&\s*query1_strb_i\)\s*==\s*query1_strb_i"
        ),
    }
    face_tb = all(marker in code["sq_tb"] for marker in [
        "F3 dual forward bank0 data", "F3 dual forward bank1 data",
        "F3 dual retry bank0 onehot", "F3 dual retry bank1 onehot",
    ])
    add(
        "sq.bank_local_query_payloads_not_crossed",
        query_face_inputs == {"pa0": 1, "pa1": 1,
                              "cover0": 1, "cover1": 1} and face_tb,
        f"counts={query_face_inputs} directed={face_tb}",
    )

    invalid_defaults = {
        "query0": occurrences(sq, r"default:\s*query0_replay_r\s*=\s*1'b1"),
        "query1": occurrences(sq, r"default:\s*query1_replay_r\s*=\s*1'b1"),
        "typed_cases": occurrences(
            sq, r"case\s*\(\{typed_attr_admitted\(query[01]_attr_valid_i"
        ),
        "known_asserts": occurrences(sq, r"V8T-SQ-QUERY[01]-KNOWN"),
    }
    invalid_tb = all(marker in code["sq_tb"] for marker in [
        "F3 invalid query attr replays", "F3 reserved query class replays",
        "F3 empty query byte mask replays", "F3 unknown typed-valid replays",
        "V8T_X_FAULT_INJECTION",
    ])
    add(
        "sq.invalid_and_unknown_metadata_fail_closed",
        invalid_defaults == {"query0": 3, "query1": 3,
                             "typed_cases": 2, "known_asserts": 2}
        and invalid_tb,
        f"counts={invalid_defaults} directed={invalid_tb}",
    )

    sq_onehot = {
        bank: all(fragment in sq for fragment in [
            f"assign query{bank}_allow_o = query{bank}_allow_r;",
            f"assign query{bank}_forward_o = query{bank}_forward_r;",
            f"assign query{bank}_replay_o = query{bank}_replay_r;",
        ])
        for bank in (0, 1)
    }
    add("sq.explicit_onehot_decision_registers", all(sq_onehot.values()),
        f"banks={sq_onehot}")

    bridge_fragments = [
        "localparam [3:0] S_SQ_QUERY = 4'd12;",
        "assign mem0_sq_query_valid_o = (state_q == S_SQ_QUERY)",
        "assign mem0_sq_query_paddr_o = paddr_q;",
        "assign mem0_sq_query_wstrb_o = wstrb_q;",
        "wire sq_query_retry_fire_w = mem0_sq_query_valid_o",
        "state_q <= S_SQ_QUERY;",
        "state_q <= S_IDLE;",
        "rsp_rdata_q <= mem0_sq_query_forward_data_i;",
    ]
    ok, missing = has_all(bridge, bridge_fragments)
    add("bridge.registered_query_and_retry_handoff", ok, f"missing={missing}")

    bridge_transitions = {
        "forward_to_response": occurrences(
            bridge,
            r"mem0_sq_query_forward_i\)\s*begin.*?"
            r"rsp_rdata_q\s*<=\s*mem0_sq_query_forward_data_i;.*?"
            r"state_q\s*<=\s*S_RESP;\s*end\s+else\s+if\s*"
            r"\(mem0_sq_query_valid_o"),
        "credited_retry_to_idle": occurrences(
            bridge,
            r"else\s+if\s*\(sq_query_retry_fire_w\)\s*begin\s*"
            r"state_q\s*<=\s*S_IDLE;"),
        "uncredited_hold": occurrences(
            bridge,
            r"else\s+begin\s*state_q\s*<=\s*S_SQ_QUERY;\s*end\s*"
            r"end\s*S_DEVICE_WAIT"),
    }
    add(
        "bridge.exact_forward_retry_state_transitions",
        bridge_transitions == {
            "forward_to_response": 1,
            "credited_retry_to_idle": 1,
            "uncredited_hold": 1,
        },
        f"counts={bridge_transitions}",
    )

    bridge_routes = occurrences(bridge, r"state_q\s*<=\s*S_SQ_QUERY\s*;")
    route_classes = {
        "bare": occurrences(
            bridge,
            r"if\s*\(stg_owner_kind_q\s*==\s*MEM_OWNER_LOAD\)\s*begin\s*"
            r"state_q\s*<=\s*S_SQ_QUERY"),
        "ptw_leaf": occurrences(
            bridge,
            r"if\s*\(active_owner_kind_q\s*==\s*MEM_OWNER_LOAD\)\s*"
            r"state_q\s*<=\s*S_SQ_QUERY;\s*"
            r"else\s+if\s*\(walk_leaf_dcacheable_w\)"),
        "ad_continue": occurrences(
            bridge,
            r"if\s*\(active_owner_kind_q\s*==\s*MEM_OWNER_LOAD\)\s*"
            r"state_q\s*<=\s*S_SQ_QUERY;\s*"
            r"else\s+if\s*\(access_cacheable_w\)"),
        "invalid_hold": occurrences(
            bridge,
            r"else\s+begin\s*state_q\s*<=\s*S_SQ_QUERY\s*;\s*end\s*"
            r"end\s*S_DEVICE_WAIT"),
    }
    add(
        "bridge.bare_ptw_ad_paths_converge_on_query",
        bridge_routes == 4 and route_classes == {
            "bare": 1, "ptw_leaf": 1, "ad_continue": 1,
            "invalid_hold": 1,
        },
        f"route_count={bridge_routes} classes={route_classes}",
    )

    lookup_expr = re.search(
        r"wire\s+sq_query_read_lookup_fire_w\s*=\s*(.*?);",
        bridge, flags=re.S,
    )
    lookup_body = lookup_expr.group(1) if lookup_expr else ""
    add(
        "bridge.only_exact_allow_owns_cache_lookup",
        "mem0_sq_query_allow_i" in lookup_body
        and "mem0_sq_query_forward_i" not in lookup_body
        and "mem0_sq_query_replay_i" not in lookup_body
        and "mem0_sq_query_valid_o" in lookup_body,
        f"expr={lookup_body.strip()}",
    )

    ready_expr = re.search(
        r"assign\s+mem0_req_ready_o\s*=\s*(.*?);",
        bridge, flags=re.S,
    )
    ready_body = ready_expr.group(1) if ready_expr else ""
    add(
        "bridge.query_decision_not_in_request_ready",
        ready_body != "" and "sq_query" not in ready_body,
        f"expr={ready_body.strip()}",
    )

    target_quiet = all(fragment in bridge for fragment in [
        "[V8T-SQ-QUERY-EXACT]",
        "[V8T-SQ-QUERY-ONEHOT]",
        "[V8T-SQ-QUERY-NO-TARGET]",
        "[V8T-SQ-QUERY-REPLAY-HOLD]",
        "[V8T-SQ-QUERY-RETRY-HANDOFF]",
        "[V8T-SQ-QUERY-FORWARD-CAPTURE]",
        "[V8T-SQ-QUERY-FORWARD-DROP]",
    ])
    add("bridge.assertion_oracles_present", target_quiet,
        f"present={target_quiet}")

    fault_routes = {
        "dtlb_permission": occurrences(
            bridge,
            r"req_translate_w\s*&&\s*req_dtlb_perm_fault_w\)\s*begin\s*"
            r"rsp_error_q\s*<=\s*1'b1;\s*"
            r"rsp_page_fault_q\s*<=\s*1'b1;\s*state_q\s*<=\s*S_RESP",
        ),
        "pmp": occurrences(
            bridge,
            r"req_data_pmp_fault_w\)\s*begin\s*"
            r"rsp_error_q\s*<=\s*1'b1;\s*"
            r"rsp_page_fault_q\s*<=\s*1'b0;\s*state_q\s*<=\s*S_RESP",
        ),
        "invalid_pte": occurrences(
            bridge,
            r"end\s+else\s+if\s*\(pte_invalid\(lsu_axi_rdata_i\).*?begin\s*"
            r"rsp_error_q\s*<=\s*1'b1;\s*"
            r"rsp_page_fault_q\s*<=\s*1'b1;\s*state_q\s*<=\s*S_RESP",
        ),
        "late_ad_guard": occurrences(
            bridge,
            r"wire\s+dtlb_fill_valid_w\s*=\s*"
            r"active_expected_identity_match_w\s*&&\s*"
            r"active_tracker_identity_match_w\s*&&\s*"
            r"active_sticky_identity_match_w\s*&&\s*fsm_normal_w\s*&&\s*"
            r"!mem0_expected_effective_killed_i\s*&&\s*"
            r"!killed_write_maintenance_authorized_w",
        ),
    }
    fault_tb = all(marker in code["bridge_tb"] for marker in [
        "F3 PMP access fault never reaches SQ query",
        "F3 PMP fault response stays out of SQ query",
        "F3 DTLB permission fault never reaches SQ query",
        "F3 DTLB fault response stays out of SQ query",
        "F3 invalid PTE never reaches SQ query",
        "F3 invalid PTE response stays out of SQ query",
        "F3 killed A/D late B has no SQ query",
    ])
    add(
        "bridge.prequery_fault_and_late_response_quiet",
        fault_routes == {
            "dtlb_permission": 1, "pmp": 1, "invalid_pte": 1,
            "late_ad_guard": 1,
        } and fault_tb,
        f"routes={fault_routes} directed={fault_tb}",
    )

    backend_exact = [
        "wire mem_sq_query_miq_exact_w", "wire mem1_sq_query_miq_exact_w",
        "wire mem_sq_query_tracker_exact_w", "wire mem1_sq_query_tracker_exact_w",
        "wire mem_sq_query_exact_w", "wire mem1_sq_query_exact_w",
        "assign mem_sq_query_replay_o = ENABLE_DUAL_MEM",
        "assign mem1_sq_query_replay_o = ENABLE_DUAL_MEM",
    ]
    ok, missing = has_all(backend, backend_exact)
    exact_mapping_counts = {
        "producer0": occurrences(
            backend,
            r"mem_sq_query_producer_id_w\s*=\s*"
            r"mem_owner_producer_id_table_w\[\s*"
            r"mem_sq_query_owner_token_i\*PRODUCER_ID_W"),
        "producer1": occurrences(
            backend,
            r"mem1_sq_query_producer_id_w\s*=\s*"
            r"mem_owner_producer_id_table_w\[\s*"
            r"mem1_sq_query_owner_token_i\*PRODUCER_ID_W"),
        "miq0": occurrences(
            backend,
            r"mem_sq_query_miq_exact_w.*?"
            r"miq_head_owner_token_w\s*==\s*mem_sq_query_owner_token_i"),
        "miq1": occurrences(
            backend,
            r"mem1_sq_query_miq_exact_w.*?"
            r"miq1_head_owner_token_w\s*==\s*mem1_sq_query_owner_token_i"),
        "pid0": occurrences(
            backend,
            r"mem_sq_query_tracker_exact_w.*?"
            r"mem_sq_query_producer_id_w\[ROB_INDEX_W-1:0\]\s*==\s*"
            r"miq_head_rob_w"),
        "pid1": occurrences(
            backend,
            r"mem1_sq_query_tracker_exact_w.*?"
            r"mem1_sq_query_producer_id_w\[ROB_INDEX_W-1:0\]\s*==\s*"
            r"miq1_head_rob_w"),
    }
    mapping_ok = all(value == 1 for value in exact_mapping_counts.values())
    add(
        "backend.bank_local_exact_query_mapping",
        ok and mapping_ok,
        f"missing={missing} counts={exact_mapping_counts}",
    )

    retry_fields = [
        "mem_retry0_producer_id_q", "mem_retry1_producer_id_q",
        "mem_retry0_rob_idx_q", "mem_retry1_rob_idx_q",
        "mem_retry0_pdest_q", "mem_retry1_pdest_q",
        "mem_retry0_pdest_fp_q", "mem_retry1_pdest_fp_q",
        "mem_retry0_size_q", "mem_retry1_size_q",
        "mem_retry0_unsigned_q", "mem_retry1_unsigned_q",
        "mem_retry0_addr_q", "mem_retry1_addr_q",
        "mem_retry0_wdata_q", "mem_retry1_wdata_q",
        "mem_retry0_wstrb_q", "mem_retry1_wstrb_q",
        "mem_retry0_owner_token_q", "mem_retry1_owner_token_q",
        "mem_retry0_mmu_epoch_q", "mem_retry1_mmu_epoch_q",
        "mem_retry0_fault_tval_q", "mem_retry1_fault_tval_q",
    ]
    missing = [field for field in retry_fields if field not in backend]
    add("backend.two_complete_retry_holders", not missing,
        f"missing={missing}")

    retry_lifecycle = [
        "miq_queue_pop_valid_w =\n      miq_pop_transport_w || mem_sq_retry0_capture_w",
        "miq1_queue_pop_valid_w =\n      miq1_pop_transport_w || mem_sq_retry1_capture_w",
        "wire push_retry0_w = mem_retry0_req_fire_w;",
        "wire push_retry1_w = mem_retry1_req_fire_w;",
        "mem_retry0_valid_q <= 1'b1;",
        "mem_retry1_valid_q <= 1'b1;",
        "wire mem_retry0_tagged_terminal_w = mem_retry0_cancel_w;",
        "wire mem_retry1_tagged_terminal_w = mem_retry1_cancel_w;",
        "grant_retry0_w ? mem_retry0_owner_token_q :",
        "assign mem1_req_owner_token_o = grant_retry1_w ?\n"
        "      mem_retry1_owner_token_q : grant_mem1_issue0_w ?",
        "assign mem1_req_addr_o = grant_retry1_w ? mem_retry1_addr_q :",
    ]
    ok, missing = has_all(backend, retry_lifecycle)
    add("backend.retry_pop_repush_and_kill_terminal", ok, f"missing={missing}")

    arbitration = {
        "retry0_age": occurrences(
            backend,
            r"mem_retry0_selected_w\s*=\s*mem_retry0_candidate_w\s*&&\s*"
            r"!mem_bank0_store_older_than_retry_w"),
        "retry1_age": occurrences(
            backend,
            r"mem_retry1_selected_w\s*=\s*mem_retry1_candidate_w\s*&&\s*"
            r"!mem_bank1_store_older_than_retry_w"),
        "rob_age": occurrences(
            backend, r"mem_bank[01]_store_older_than_retry_w.*?rob_idx_older_than"),
        "slot0": occurrences(
            backend, r"issue0_dual_ordinary_candidate_w\s*&&\s*"
            r"issue0_dual_bank_slot_open_w"),
        "slot1": occurrences(
            backend, r"issue1_dual_ordinary_candidate_w\s*&&\s*"
            r"issue1_dual_bank_slot_open_w"),
    }
    add(
        "backend.edge_old_store_priority_and_slot_backing",
        arbitration == {
            "retry0_age": 1, "retry1_age": 1, "rob_age": 2,
            "slot0": 1, "slot1": 1,
        } and all(marker in code["backend_tb"] for marker in [
            "V8T older bank1 store suppresses retry",
            "V8T equal-age bank1 store yields to retry",
            "V8T younger bank1 store yields to retry",
        ]),
        f"counts={arbitration}",
    )

    admission = {
        "bank0": occurrences(
            backend,
            r"mem_bank0_load_admission_block_w\s*=\s*mem_retry0_valid_q\s*\|\|"
            r"\s*mem_bridge_active_load_w\s*\|\|\s*mem_bridge_station_load_w"),
        "bank1": occurrences(
            backend,
            r"mem_bank1_load_admission_block_w\s*=\s*mem_retry1_valid_q\s*\|\|"
            r"\s*mem1_bridge_active_load_w\s*\|\|\s*mem1_bridge_station_load_w"),
    }
    admission_directed = all(marker in code["backend_tb"] for marker in [
        "V8T retry0 holder fence blocks load admission",
        "V8T retry1 holder fence blocks load admission",
        "V8T bridge-active fence blocks load admission",
        "V8T bridge-station fence blocks load admission",
    ])
    add("backend.one_retry_slot_load_admission_fence",
        admission == {"bank0": 1, "bank1": 1} and admission_directed,
        f"counts={admission} directed={admission_directed}")

    control_order = {
        "bank0": occurrences(
            backend,
            r"else\s+if\s*\(mem_retry0_cancel_w\s*\|\|\s*"
            r"mem_retry0_req_fire_w\)\s*begin\s*"
            r"mem_retry0_valid_q\s*<=\s*1'b0;\s*end\s*"
            r"else\s+if\s*\(mem_sq_retry0_capture_w\)"),
        "bank1": occurrences(
            backend,
            r"else\s+if\s*\(mem_retry1_cancel_w\s*\|\|\s*"
            r"mem_retry1_req_fire_w\)\s*begin\s*"
            r"mem_retry1_valid_q\s*<=\s*1'b0;\s*end\s*"
            r"else\s+if\s*\(mem_sq_retry1_capture_w\)"),
        "terminal10": occurrences(
            backend,
            r"mem_terminal_ingress10_mask_w\s*=\s*"
            r"mem_retry0_tagged_terminal_w"),
        "terminal11": occurrences(
            backend,
            r"mem_terminal_ingress11_mask_w\s*=\s*"
            r"mem_retry1_tagged_terminal_w"),
    }
    control_directed = all(marker in code["backend_tb"] for marker in [
        "V8T retry0 ready/cancel race blocks request fire",
        "V8T killed retry0 owns terminal lane10",
        "V8T killed retry owns terminal lane11",
        "V8T killed retry blocks request fire",
    ])
    add(
        "backend.retry_control_order_and_symmetric_directed",
        control_order == {
            "bank0": 1, "bank1": 1, "terminal10": 1, "terminal11": 1,
        } and control_directed,
        f"counts={control_order} directed={control_directed}",
    )

    sink_paths = {
        "capture_fp0": occurrences(
            backend,
            r"mem_retry0_pdest_fp_q\s*<=\s*miq_head_pdest_fp_w"),
        "capture_fp1": occurrences(
            backend,
            r"mem_retry1_pdest_fp_q\s*<=\s*miq1_head_pdest_fp_w"),
        "repush_fp0": occurrences(
            backend,
            r"push_retry0_w\s*\?\s*mem_retry0_pdest_fp_q"),
        "repush_fp1": occurrences(
            backend,
            r"push_retry1_w\s*\?\s*mem_retry1_pdest_fp_q"),
        "classify_fp0": occurrences(
            backend,
            r"mem_rsp_fp_load_w\s*=\s*miq_head_pdest_fp_w\s*&&\s*"
            r"mem_wb_is_load_w"),
        "classify_fp1": occurrences(
            backend,
            r"mem1_rsp_fp_load_w\s*=\s*miq1_head_pdest_fp_w\s*&&\s*"
            r"mem1_wb_is_load_w"),
    }
    sink_directed = all(marker in code["backend_tb"] for marker in [
        "V8T retry0 integer response reaches formal WB",
        "V8T retry0 integer response emits no FP-load WB",
        "V8T FP retry response reaches FP-load WB",
        "V8T FP retry response has p0 integer destination",
        "V8T FP retry response emits FP wake",
    ]) and all(marker in code["bridge_tb"] for marker in [
        "F3 forwarded response data held",
        "F3 forwarded response exact token",
    ])
    add(
        "backend.forwarded_integer_fp_sink_equivalence",
        all(value == 1 for value in sink_paths.values()) and sink_directed,
        f"counts={sink_paths} directed={sink_directed}",
    )

    legacy_gate = {
        "issue0": occurrences(
            backend,
            r"issue0_load_waits_for_inflight_store_w\s*=\s*"
            r"!ENABLE_DUAL_MEM\s*&&"),
        "issue1": occurrences(
            backend,
            r"issue1_load_waits_for_inflight_store_w\s*=\s*"
            r"!ENABLE_DUAL_MEM\s*&&"),
        "default_allow": occurrences(
            backend,
            r"mem_sq_query_allow_o\s*=\s*!ENABLE_DUAL_MEM\s*\?"),
    }
    add("backend.canonical_dual_disables_legacy_va_blind_gate",
        legacy_gate == {"issue0": 1, "issue1": 1, "default_allow": 1},
        f"counts={legacy_gate}")

    holder_census = all(fragment in backend for fragment in [
        "mem_retry0_owner_mask_w", "mem_retry1_owner_mask_w",
        "v8l_mem_retry0_token_mask_w", "v8l_mem_retry1_token_mask_w",
        "mem_retry0_valid_q &&", "mem_retry1_valid_q &&",
        "[V8T-RETRY0-HANDOFF-NEXT-Q]", "[V8T-RETRY1-HANDOFF-NEXT-Q]",
        "[V8T-RETRY0-REPUSH-NEXT-Q]", "[V8T-RETRY1-REPUSH-NEXT-Q]",
    ])
    add("backend.retry_holder_census_and_next_q_oracles", holder_census,
        f"present={holder_census}")

    hierarchy_counts: dict[str, dict[str, int]] = {}
    for key in ["decode", "slice", "execute", "glue", "core"]:
        hierarchy_counts[key] = {
            "q0_valid": occurrences(code[key], r"mem_sq_query_valid"),
            "q1_valid": occurrences(code[key], r"mem1_sq_query_valid"),
            "q0_retry": occurrences(code[key], r"mem_sq_query_retry_ready"),
            "q1_retry": occurrences(code[key], r"mem1_sq_query_retry_ready"),
        }
    # Counts reflect each module's role: intermediate hierarchy layers expose
    # and connect the faces, while NpcCoreTop terminates them at the core glue.
    # Requiring a uniform count made harmless hierarchy shape look like a
    # missing connection and did not add structural coverage.
    hierarchy_minimums = {
        "decode": 3,
        "slice": 3,
        "execute": 3,
        "glue": 3,
        "core": 1,
    }
    hierarchy_ok = all(
        all(value >= hierarchy_minimums[key] for value in counts.values())
        for key, counts in hierarchy_counts.items()
    )
    wrapper_counts = {
        "lane0_valid": occurrences(code["wrapper"], r"lane0_sq_query_valid"),
        "lane1_valid": occurrences(code["wrapper"], r"lane1_sq_query_valid"),
        "lane0_retry": occurrences(code["wrapper"], r"lane0_sq_query_retry_ready"),
        "lane1_retry": occurrences(code["wrapper"], r"lane1_sq_query_retry_ready"),
    }
    hierarchy_ok = hierarchy_ok and all(value >= 2 for value in wrapper_counts.values())
    exact_hierarchy_fragments = {
        "decode": [
            ".mem_sq_query_valid_i(mem_sq_query_valid_i)",
            ".mem1_sq_query_valid_i(mem1_sq_query_valid_i)",
            ".mem_sq_query_retry_ready_o(mem_sq_query_retry_ready_o)",
            ".mem1_sq_query_retry_ready_o(mem1_sq_query_retry_ready_o)",
        ],
        "slice": [
            ".mem_sq_query_valid_i(mem_sq_query_valid_i)",
            ".mem1_sq_query_valid_i(mem1_sq_query_valid_i)",
            ".mem_sq_query_retry_ready_o(mem_sq_query_retry_ready_o)",
            ".mem1_sq_query_retry_ready_o(mem1_sq_query_retry_ready_o)",
        ],
        "execute": [
            ".mem_sq_query_valid_i(mem_sq_query_valid_i)",
            ".mem1_sq_query_valid_i(mem1_sq_query_valid_i)",
            ".mem_sq_query_retry_ready_o(core_mem_sq_query_retry_ready_w)",
            ".mem1_sq_query_retry_ready_o(core_mem1_sq_query_retry_ready_w)",
        ],
        "glue": [
            ".mem_sq_query_valid_i(mem_sq_query_valid_i)",
            ".mem1_sq_query_valid_i(mem1_sq_query_valid_i)",
            "assign mem_sq_query_retry_ready_o = core_mem_sq_query_retry_ready_w;",
            "assign mem1_sq_query_retry_ready_o = core_mem1_sq_query_retry_ready_w;",
        ],
        "core": [
            ".lane0_sq_query_valid_o(ooo_mem0_sq_query_valid_w)",
            ".lane1_sq_query_valid_o(ooo_mem1_sq_query_valid_w)",
            ".lane0_sq_query_retry_ready_i(ooo_mem0_sq_query_retry_ready_w)",
            ".lane1_sq_query_retry_ready_i(ooo_mem1_sq_query_retry_ready_w)",
            ".mem_sq_query_valid_i(ooo_mem0_sq_query_valid_w)",
            ".mem1_sq_query_valid_i(ooo_mem1_sq_query_valid_w)",
            ".mem_sq_query_retry_ready_o(ooo_mem0_sq_query_retry_ready_w)",
            ".mem1_sq_query_retry_ready_o(ooo_mem1_sq_query_retry_ready_w)",
        ],
        "wrapper": [
            ".mem0_sq_query_valid_o(lane0_sq_query_valid_o)",
            ".mem0_sq_query_valid_o(lane1_sq_query_valid_o)",
            ".mem0_sq_query_retry_ready_i(lane0_sq_query_retry_ready_i)",
            ".mem0_sq_query_retry_ready_i(lane1_sq_query_retry_ready_i)",
        ],
    }
    hierarchy_missing = {
        key: [fragment for fragment in fragments if fragment not in code[key]]
        for key, fragments in exact_hierarchy_fragments.items()
    }
    hierarchy_ok = hierarchy_ok and not any(hierarchy_missing.values())
    add("hierarchy.two_query_faces_mechanically_propagated", hierarchy_ok,
        f"chain={hierarchy_counts} wrapper={wrapper_counts} "
        f"missing={hierarchy_missing}")

    tb_markers = {
        "sq": "[V8T-F3-SQ-QUERY]" in code["sq_tb"],
        "bridge": "[V8T-F3-BRIDGE-QUERY]" in code["bridge_tb"],
        "backend": "[V8T-F3-BACKEND-RETRY]" in code["backend_tb"],
    }
    add("verification.directed_markers_present", all(tb_markers.values()),
        f"markers={tb_markers}")

    boundary_ok = all(fragment in sources["contract"] for fragment in [
        "final_pa_sq_ordering_checkpoint", "architecture=RED",
        "ppa=UNQUALIFIED", "promotion_eligible=false",
    ]) and "不得扩张到 DI-5/OOO-3/PPA" in sources["derivation"]
    add("claim.checkpoint_boundary_remains_fail_closed", boundary_ok,
        f"present={boundary_ok}")

    return checks


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True)
    parser.add_argument("--sq")
    parser.add_argument("--bridge")
    parser.add_argument("--backend")
    parser.add_argument("--json-out")
    args = parser.parse_args()

    checks = structural_checks(load_sources(args))
    passed = all(check.passed for check in checks)
    payload = {
        "schema_version": 1,
        "gate": "v8t-final-pa-sq-query-source",
        "passed": passed,
        "checks": [asdict(check) for check in checks],
    }
    for check in checks:
        status = "PASS" if check.passed else "FAIL"
        print(f"[V8T-CHECK][{status}] {check.check_id}: {check.detail}")
    if args.json_out:
        path = pathlib.Path(args.json_out)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n",
                        encoding="utf-8")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
