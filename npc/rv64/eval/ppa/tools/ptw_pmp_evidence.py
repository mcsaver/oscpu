#!/usr/bin/env python3
"""Build fail-closed local RV64 PTW-PMP-G1 current-design evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-ptw-pmp-evidence-v4"
VARIANT_SCHEMA = "npc-rv64-ptw-pmp-rtl-variants-v3"
RUN_ID = "2026-07-22-rv64-v9k-ptw-pmp-current-design"
CANONICAL_COMMAND = "make -C npc/rv64 check-ptw-pmp"
SCOPE = (
    "local RV64 IFU and LSU page-table walker PTE 8B S-mode WRITE PMP "
    "decision, checker-address-to-AW binding, independent AXI AW/W "
    "handshakes, access-fault response through handshake, A/D update allow "
    "path and registered transaction ownership; downstream IFU lane owner "
    "and tval propagation remain in IFU-ACCESS-G1 and IFU-TVAL-G1"
)
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_ptw_pmp", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

VARIANT_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-ptw-pmp-variants.py"
VARIANT_SPEC = importlib.util.spec_from_file_location(
    "ptw_pmp_variants", VARIANT_RUNNER)
assert VARIANT_SPEC is not None and VARIANT_SPEC.loader is not None
variant_model = importlib.util.module_from_spec(VARIANT_SPEC)
sys.modules[VARIANT_SPEC.name] = variant_model
VARIANT_SPEC.loader.exec_module(variant_model)


IFU_ALLOW_MARKER = (
    "[V9K-IFU-PTW-PMP-WRITE-ALLOW] read=allow write=allow "
    "checker=grant ad_update=1 awaddr=checked aw=once w=once awsize=3 "
    "split=aw-first stall=2 payload=stable b_after_both=1"
)
IFU_F0_DENY_MARKER = (
    "[T4F-IFU-PTW-PMP-WRITE] read=allow write=deny "
    "access-fault aw=0 w=0"
)
IFU_WIDTH_MARKER = (
    "[V9K-IFU-PTW-PMP-WRITE-WIDTH] bytes=8 "
    "partial-cover=deny aw=0 w=0"
)
IFU_FRONTIER_RE = re.compile(
    r"^\[V9K-IFU-PTW-PMP-WRITE-DENY\] "
    r"frontier=(?P<frontier>[246]) read=allow write=deny "
    r"prefix=(?P<prefix>[246]) access-fault=1 ar=0 aw=0 w=0$"
)
LSU_DENY_RE = re.compile(
    r"^\[T4F-LSU-PTW-PMP-WRITE\] op=(?P<op>load|store) "
    r"mode=(?P<mode>readonly|partial8) read=allow write=deny "
    r"access-fault aw=0 w=0 owner=stable "
    r"response-delay=(?P<delay>0|1|2|3|5) "
    r"awready=1 wready=1 interval=through-handshake$"
)
LSU_ALLOW_RE = re.compile(
    r"^\[V9K-LSU-PTW-PMP-WRITE-ALLOW\] op=(?P<op>load|store) "
    r"read=allow write=allow checker=grant ad_update=1 awaddr=checked "
    r"aw=once w=once awsize=3 split=(?P<split>aw-first|w-first) "
    r"stall=(?P<stall>2) payload=stable b_after_both=1$"
)
IFU_DENY_CONDITION = """exec_ad_update_needed(ifu_axi_rdata_i) &&
                           walk_pte_write_pmp_fault_w) begin"""
LSU_DENY_CONDITION = """walk_ad_needed_w &&
                           walk_pte_write_pmp_fault_w) begin"""
LSU_AW_VALID_ASSIGN = """assign lsu_axi_awvalid_o =
      (active_owner_verified_q && (state_q == S_WRITE_REQ) && !aw_done_q) ||
      (active_owner_verified_q && (state_q == S_AD_UPDATE) && !aw_done_q);"""
LSU_W_VALID_ASSIGN = """assign lsu_axi_wvalid_o =
      (active_owner_verified_q && (state_q == S_WRITE_REQ) && !w_done_q) ||
      (active_owner_verified_q && (state_q == S_AD_UPDATE) && !w_done_q);"""
LSU_DENY_TO_RESPONSE = """end else if (walk_ad_needed_w &&
                           walk_pte_write_pmp_fault_w) begin
                // PTE 可读但不可写：原始 load/store 报 access fault，不是 page fault。
                rsp_error_q <= 1'b1;
                rsp_page_fault_q <= 1'b0;
                state_q <= S_RESP;"""
LSU_STAGE_ADVANCE = """wire stage_advance_w = stg_valid_q && !dcache_rmw_busy_w &&
                         ((state_q == S_IDLE) ||
                          ((state_q == S_RESP) && rsp_ready_w) ||
                          (lookup_hit_fusion_w && rsp_ready_w)) &&
                         (!cpu_kill_w || stg_nokill_q) &&
                         !control_full_flush_barrier_i;"""
LSU_RESPONSE_STALL_BLOCK = """S_RESP: begin
          // 【刀 M】back-to-back accept 已上提为 stage_advance 分支(该分支同时覆盖
          // rsp 消费拍), 本臂只处理"rsp 被消费且无寄存站项可进"的回 IDLE。
          if (rsp_ready_w) begin
            aw_done_q <= 1'b0;
            w_done_q <= 1'b0;
            state_q <= S_IDLE;
          end
        end"""
LSU_RESPONSE_DROP_TERMINAL = "S_RESP: active_drop_terminal_r = 1'b1;"

EXPECTED_IFU_FRONTIERS = [
    {"frontier": value, "prefix": value, "access_fault": True,
     "younger_ar": False, "aw": False, "w": False}
    for value in (2, 4, 6)
]
EXPECTED_LSU_RESPONSE_DELAYS = (0, 1, 2, 3, 5)
EXPECTED_LSU_DENIES = [
    {"op": op, "mode": mode, "access_fault": True,
     "aw": False, "w": False, "owner_stable": True,
     "response_ready_delay": delay, "awready": True, "wready": True,
     "quiet_through_handshake": True}
    for op, mode in (
        ("load", "readonly"),
        ("store", "readonly"),
        ("load", "partial8"),
    )
    for delay in EXPECTED_LSU_RESPONSE_DELAYS
]
EXPECTED_LSU_ALLOWS = [
    {"op": "load", "checker_grant": True, "ad_update": True,
     "awaddr_bound": True, "aw_once": True, "w_once": True, "awsize": 3,
     "split": "w-first", "stall_cycles": 2, "payload_stable": True,
     "b_after_both": True},
    {"op": "store", "checker_grant": True, "ad_update": True,
     "awaddr_bound": True, "aw_once": True, "w_once": True, "awsize": 3,
     "split": "aw-first", "stall_cycles": 2, "payload_stable": True,
     "b_after_both": True},
]

INVARIANTS = {
    "pte_read_grant_does_not_imply_pte_write_grant": True,
    "pte_write_query_uses_registered_pte_physical_address": True,
    "pte_write_query_covers_all_eight_bytes": True,
    "implicit_page_table_access_uses_supervisor_privilege": True,
    "ifu_write_deny_returns_instruction_access_fault": True,
    "ifu_f0_write_deny_has_no_axi_write_owner": True,
    "ifu_f2_f4_f6_preserve_exact_successful_prefix": True,
    "ifu_write_deny_closes_younger_instruction_ar": True,
    "lsu_load_and_store_write_deny_return_access_not_page_fault": True,
    "lsu_write_deny_preserves_owner_kind_token_epoch_and_fault_tval": True,
    "deny_decision_and_response_cycles_have_no_aw_or_w": True,
    "write_grant_enters_ad_update_and_presents_aw_w": True,
    "ad_update_awsize_is_eight_bytes": True,
    "partial_cover_counterexample_detects_four_byte_checker": True,
    "compile_success_rtl_variants_are_dynamically_rejected": True,
    "production_rtl_is_unchanged_by_verification_variants": True,
    "ad_update_awaddr_equals_the_checker_granted_pte_address": True,
    "stalled_awvalid_and_payload_remain_stable_until_handshake": True,
    "stalled_wvalid_and_payload_remain_stable_until_handshake": True,
    "aw_and_w_channels_accept_in_either_order": True,
    "each_ad_update_write_channel_is_accepted_exactly_once": True,
    "ad_update_completion_waits_for_aw_w_and_b": True,
    "lsu_deny_response_tuple_is_stable_for_ready_delay_sweep_0_1_2_3_5": True,
    "lsu_deny_awready_wready_remain_high_during_quiet_interval": True,
    "lsu_deny_temporal_monitor_tracks_checker_deny_to_response_terminal": True,
    "lsu_deny_keeps_aw_w_quiet_through_response_handshake": True,
    "lsu_aw_w_valid_state_decode_excludes_s_resp_for_unbounded_stall": True,
    "lsu_s_resp_advance_requires_response_ready_or_exact_drop_terminal": True,
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def safe_file(root: pathlib.Path, path: pathlib.Path) -> pathlib.Path:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(root):
        raise ValueError(f"artifact escapes repository: {resolved}")
    if path.is_symlink() or not resolved.is_file():
        raise ValueError(f"artifact is not a regular non-symlink file: {path}")
    return resolved


def artifact(root: pathlib.Path, path: pathlib.Path, kind: str) -> dict[str, str]:
    resolved = safe_file(root, path)
    return {
        "kind": kind,
        "path": resolved.relative_to(root).as_posix(),
        "sha256": sha256_file(resolved),
    }


def require_pass_log(text: str, test_name: str, label: str) -> None:
    accepted = {f"[PASS] {test_name}", f"PASS {test_name}"}
    if len([line for line in text.splitlines() if line in accepted]) != 1:
        raise ValueError(f"{label}: expected one exact test PASS line")
    if text.splitlines().count("[RESULT] PASS") != 1:
        raise ValueError(f"{label}: expected one exact result PASS line")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")


def parse_ifu_log(path: pathlib.Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_axi_bridge", "IFU bridge log")
    for marker in (IFU_ALLOW_MARKER, IFU_F0_DENY_MARKER, IFU_WIDTH_MARKER):
        if text.splitlines().count(marker) != 1:
            raise ValueError(f"IFU PTW-PMP marker drifted: {marker}")
    rows = []
    for line in text.splitlines():
        match = IFU_FRONTIER_RE.fullmatch(line)
        if match:
            frontier = int(match.group("frontier"))
            prefix = int(match.group("prefix"))
            rows.append({
                "frontier": frontier,
                "prefix": prefix,
                "access_fault": True,
                "younger_ar": False,
                "aw": False,
                "w": False,
            })
    if rows != EXPECTED_IFU_FRONTIERS:
        raise ValueError("IFU F2/F4/F6 PTE-write-deny manifest drifted")
    return {
        "metrics": {
            "allow_rows": 1,
            "deny_f0_rows": 1,
            "deny_frontier_rows": 3,
            "frontier_f2_rows": 1,
            "frontier_f4_rows": 1,
            "frontier_f6_rows": 1,
            "partial_cover_rows": 1,
            "allow_awaddr_bound_rows": 1,
            "allow_split_aw_first_rows": 1,
            "allow_stall_cycles": 2,
            "allow_payload_stable_rows": 1,
            "allow_exact_once_rows": 1,
        },
        "frontier_manifest": rows,
    }


def parse_lsu_log(path: pathlib.Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_mem_axi_bridge", "LSU bridge log")
    denies: list[dict[str, Any]] = []
    allows: list[dict[str, Any]] = []
    for line in text.splitlines():
        deny = LSU_DENY_RE.fullmatch(line)
        if deny:
            denies.append({
                "op": deny.group("op"),
                "mode": deny.group("mode"),
                "access_fault": True,
                "aw": False,
                "w": False,
                "owner_stable": True,
                "response_ready_delay": int(deny.group("delay")),
                "awready": True,
                "wready": True,
                "quiet_through_handshake": True,
            })
        allow = LSU_ALLOW_RE.fullmatch(line)
        if allow:
            allows.append({
                "op": allow.group("op"),
                "checker_grant": True,
                "ad_update": True,
                "awaddr_bound": True,
                "aw_once": True,
                "w_once": True,
                "awsize": 3,
                "split": allow.group("split"),
                "stall_cycles": int(allow.group("stall")),
                "payload_stable": True,
                "b_after_both": True,
            })
    if denies != EXPECTED_LSU_DENIES:
        raise ValueError("LSU PTE-write-deny manifest drifted")
    if allows != EXPECTED_LSU_ALLOWS:
        raise ValueError("LSU PTE-write-allow manifest drifted")
    return {
        "metrics": {
            "deny_rows": 15,
            "deny_scenarios": 3,
            "readonly_load_rows": 5,
            "readonly_store_rows": 5,
            "partial_cover_rows": 5,
            "allow_rows": 2,
            "owner_stable_rows": 15,
            "response_delay_rows": 15,
            "response_delay_zero_rows": 3,
            "response_delay_nonzero_rows": 12,
            "response_stall_cycles": 33,
            "closed_interval_quiet_rows": 15,
            "ready_high_quiet_rows": 15,
            "allow_awaddr_bound_rows": 2,
            "allow_split_aw_first_rows": 1,
            "allow_split_w_first_rows": 1,
            "allow_stall_cycles": 4,
            "allow_payload_stable_rows": 2,
            "allow_exact_once_rows": 2,
        },
        "deny_manifest": denies,
        "allow_manifest": allows,
    }


def validate_lsu_unbounded_deny_quiet_structure(text: str) -> dict[str, Any]:
    """Prove response-stall AW/W quiet from the exact production state decode."""

    required = {
        "aw_valid_exact_state_decode": LSU_AW_VALID_ASSIGN,
        "w_valid_exact_state_decode": LSU_W_VALID_ASSIGN,
        "pte_write_deny_enters_response": LSU_DENY_TO_RESPONSE,
        "queued_advance_from_response_requires_ready": LSU_STAGE_ADVANCE,
        "response_stall_self_loop": LSU_RESPONSE_STALL_BLOCK,
        "response_kill_has_exact_drop_terminal": LSU_RESPONSE_DROP_TERMINAL,
    }
    for name, anchor in required.items():
        if text.count(anchor) != 1:
            raise ValueError(f"LSU unbounded deny-quiet structure drifted: {name}")
    if "S_RESP" in LSU_AW_VALID_ASSIGN or "S_RESP" in LSU_W_VALID_ASSIGN:
        raise ValueError("LSU response state entered an AXI write VALID decoder")
    return {
        "deny_next_state": "S_RESP",
        "awvalid_state_terms": ["S_WRITE_REQ", "S_AD_UPDATE"],
        "wvalid_state_terms": ["S_WRITE_REQ", "S_AD_UPDATE"],
        "response_state_in_awvalid_decode": False,
        "response_state_in_wvalid_decode": False,
        "stalled_response_state": "S_RESP",
        "queued_request_advance_requires_response_ready": True,
        "c0_barrier_holds_queued_advance": True,
        "kill_path_emits_exact_drop_terminal": True,
        "cycle_bound": "unbounded_by_state_decode",
    }


def required_module_tests(makefile: pathlib.Path) -> list[str]:
    tests: list[str] = []
    collecting = False
    for line in makefile.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not collecting:
            if not stripped.startswith("TESTS :="):
                continue
            collecting = True
            stripped = stripped.removeprefix("TESTS :=").strip()
        continued = stripped.endswith("\\")
        payload = stripped[:-1].strip() if continued else stripped
        if payload:
            tests.extend(payload.split())
        if not continued:
            break
    if not tests or len(tests) != len(set(tests)):
        raise ValueError("module TESTS inventory is empty or duplicated")
    return tests


def parse_module_aggregate(root: pathlib.Path, summary: pathlib.Path) -> dict[str, Any]:
    tests = required_module_tests(root / "npc/rv64/testbench/Makefile")
    text = summary.read_text(encoding="utf-8")
    count = len(tests)
    for marker in (
        "# NPC single module testbench summary",
        f"- total: {count}", f"- passed: {count}", "- failed: 0",
    ):
        if text.count(marker) != 1:
            raise ValueError("module aggregate summary counts are incomplete")
    log_dir = summary.parent / "logs"
    actual = {path.stem for path in log_dir.glob("*.log") if path.is_file()}
    if actual != set(tests):
        raise ValueError("module aggregate log inventory is not exact")
    records: dict[str, dict[str, str]] = {}
    lines = text.splitlines()
    for test_name in tests:
        if lines.count(f"- PASS {test_name}") != 1:
            raise ValueError(f"module aggregate summary missing {test_name}")
        log_path = safe_file(root, log_dir / f"{test_name}.log")
        require_pass_log(
            log_path.read_text(encoding="utf-8"), test_name,
            f"module aggregate {test_name}")
        records[test_name] = {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        }
    return {"required": count, "passed": count, "failed": 0, "tests": records}


def reconstruct_variant(root: pathlib.Path, spec: Any) -> tuple[str, str]:
    source = safe_file(root, root / spec.source_rel)
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL variant anchor is not unique")
    return text, text.replace(spec.old, spec.new, 1)


def validate_variants(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    specs = {spec.name: spec for spec in variant_model.VARIANTS}
    rows = payload.get("results")
    if not isinstance(rows, list):
        raise ValueError("RTL verification-variant result list is missing")
    by_name = {
        row.get("name"): row for row in rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    }
    if not (
        payload.get("schema") == VARIANT_SCHEMA
        and payload.get("suite_run_id") == RUN_ID
        and payload.get("required") == len(specs)
        and payload.get("compile_success") == len(specs)
        and payload.get("dynamic_rejected") == len(specs)
        and payload.get("source_unchanged") is True
        and payload.get("source_sha256_before") == payload.get("source_sha256_after")
        and set(by_name) == set(specs)
    ):
        raise ValueError("RTL verification-variant aggregate is incomplete")
    verified: list[dict[str, Any]] = []
    source_before: dict[str, str] = {}
    for name, spec in specs.items():
        row = by_name[name]
        original, variant = reconstruct_variant(root, spec)
        original_sha = sha256_bytes(original.encode("utf-8"))
        variant_sha = sha256_bytes(variant.encode("utf-8"))
        log = row.get("log")
        log_path = safe_file(root, root / log.get("path", "")) \
            if isinstance(log, dict) else None
        log_text = log_path.read_text(encoding="utf-8") if log_path else ""
        if not (
            log_path is not None and set(log) == {"path", "sha256"}
            and log.get("sha256") == sha256_file(log_path)
            and row.get("debt_id") == "PTW-PMP-G1"
            and row.get("purpose") == spec.purpose
            and row.get("source") == spec.source_rel
            and row.get("make_variable") == spec.make_variable
            and row.get("test_name") == spec.test_name
            and row.get("original_sha256") == original_sha
            and row.get("variant_sha256") == variant_sha
            and row.get("expected_marker") == spec.expected_marker
            and row.get("compile_success") is True
            and row.get("marker_observed") is True
            and row.get("dynamic_rejected") is True
            and isinstance(row.get("make_returncode"), int)
            and row.get("make_returncode") != 0
            and variant_model.TRANSIENT_DIR_TOKEN in log_text
            and "/tmp/rv64-v9k-" not in log_text
            and spec.expected_marker in log_text
            and "[RESULT] FAIL status=" in log_text
            and "[RESULT] PASS" not in log_text
        ):
            raise ValueError(f"{name}: RTL verification variant is stale")
        source_before[spec.source_rel] = original_sha
        verified.append(dict(row))
    if payload.get("source_sha256_before") != source_before:
        raise ValueError("RTL verification-variant source binding is stale")
    by_source = {
        source: {
            "required": sum(spec.source_rel == source for spec in specs.values()),
            "compile_success": sum(
                row["source"] == source and bool(row["compile_success"])
                for row in verified),
            "dynamic_rejected": sum(
                row["source"] == source and bool(row["dynamic_rejected"])
                for row in verified),
        }
        for source in sorted(source_before)
    }
    return {
        "schema": VARIANT_SCHEMA,
        "required": len(specs),
        "compile_success": len(specs),
        "dynamic_rejected": len(specs),
        "by_source": by_source,
        "source_unchanged": True,
        "results": sorted(verified, key=lambda item: item["name"]),
    }


def validate_static_contract(root: pathlib.Path) -> dict[str, bool]:
    paths = {
        "ifu": "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
        "lsu": "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        "pmp": "npc/rv64/vsrc/memory/PmpChecker.v",
        "ifu_tb": "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
        "lsu_tb": "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
    }
    texts = {
        name: safe_file(root, root / relative).read_text(encoding="utf-8")
        for name, relative in paths.items()
    }
    anchors = {
        "ifu_checker_uses_registered_pte_address": (
            "ifu", ".paddr_i(walk_pte_addr_q),\n    .access_size_i(4'd8),"),
        "ifu_checker_uses_supervisor_write": (
            "ifu", ".priv_mode_i(`PRIV_S),\n    .access_read_i(1'b0),\n    .access_write_i(1'b1),"),
        "lsu_checker_uses_pte_address": (
            "lsu", ".paddr_i(walk_pte_addr_w),\n    .access_size_i(4'd8),"),
        "lsu_checker_uses_supervisor_write": (
            "lsu", ".priv_mode_i(`PRIV_S),\n    .access_read_i(1'b0),\n    .access_write_i(1'b1),"),
        "ifu_aw_is_ad_update_state_owned": (
            "ifu", "assign ifu_axi_awvalid_o = (state_q == S_AD_UPDATE) && !aw_done_q;"),
        "ifu_w_is_ad_update_state_owned": (
            "ifu", "assign ifu_axi_wvalid_o = (state_q == S_AD_UPDATE) && !w_done_q;"),
        "ifu_awaddr_is_registered_checker_address": (
            "ifu", "assign ifu_axi_awaddr_o = walk_pte_addr_q;"),
        "ifu_wdata_is_registered_ad_pte": (
            "ifu", "assign ifu_axi_wdata_o = ad_pte_q;"),
        "ifu_completion_requires_aw_w_and_b": (
            "ifu", "wire ifu_ad_write_complete_w = ifu_ad_aw_accepted_next_w &&"),
        "ifu_asserts_aw_payload_hold": (
            "ifu", "[IFU-AD-AW-HOLD] stalled AW valid/payload changed before fire"),
        "ifu_asserts_w_payload_hold": (
            "ifu", "[IFU-AD-W-HOLD] stalled W valid/payload changed before fire"),
        "ifu_asserts_b_after_both_channels": (
            "ifu", "[IFU-AD-B-ORDER] B fired before W was accepted"),
        "lsu_aw_is_registered_write_state_owned": (
            "lsu", "(active_owner_verified_q && (state_q == S_AD_UPDATE) && !aw_done_q);"),
        "lsu_w_is_registered_write_state_owned": (
            "lsu", "(active_owner_verified_q && (state_q == S_AD_UPDATE) && !w_done_q);"),
        "lsu_awaddr_is_checked_pte_in_ad_update": (
            "lsu", "(state_q == S_AD_UPDATE) ? walk_pte_addr_w : paddr_q;"),
        "lsu_wdata_is_registered_ad_pte": (
            "lsu", "assign lsu_axi_wdata_o = (state_q == S_AD_UPDATE) ? ad_pte_q : wdata_q;"),
        "lsu_asserts_aw_payload_hold": (
            "lsu", "[S2-G1-BRG-AW-HOLD] stalled AW withdrew VALID or changed payload"),
        "lsu_asserts_w_payload_hold": (
            "lsu", "[S2-G1-BRG-W-HOLD] stalled W withdrew VALID or changed payload"),
        "lsu_asserts_response_tuple_hold": (
            "lsu", "[S2-G1-BRG-RSP-HOLD] stalled response tuple changed"),
        "pmp_uses_access_last_byte": (
            "pmp", "access_last_addr(paddr_i, access_size_i)"),
        "pmp_first_overlap_requires_full_cover": (
            "pmp", "(!match_full_r ||\n                 (access_read_i"),
        "ifu_asserts_deny_response_and_aw_w_quiet": (
            "ifu", "[IFU-PTW-PMP-WRITE] deny did not become access-fault response"),
        "lsu_asserts_deny_response_and_aw_w_quiet": (
            "lsu", "[MEM-PTW-PMP-WRITE] deny did not become access-fault response"),
        "ifu_tb_covers_exact_frontiers": (
            "ifu_tb", "ptw_ad_write_pmp_frontier_deny(3'd6);"),
        "ifu_tb_checks_awsize": (
            "ifu_tb", "V9K IFU allow presents 8B AWSIZE"),
        "lsu_tb_checks_owner_snapshot": (
            "lsu_tb", "V9K LSU deny response fault tval is original VA"),
        "lsu_tb_checks_awsize": (
            "lsu_tb", "V9K LSU PTE write uses 8B AWSIZE"),
        "ifu_tb_checks_split_channel_order": (
            "ifu_tb", "split=aw-first stall=2 payload=stable b_after_both=1"),
        "lsu_tb_checks_both_split_orders": (
            "lsu_tb", "write_access ? \"aw-first\" : \"w-first\""),
        "lsu_tb_tracks_deny_until_response_terminal": (
            "lsu_tb", "v9k_ptw_pmp_deny_pending_q"),
        "lsu_tb_asserts_pending_deny_aw_w_quiet": (
            "lsu_tb", "[V9K-LSU-PTW-PMP-DENY-QUIET]"),
        "lsu_tb_sweeps_response_ready_0_1_2_3_5": (
            "lsu_tb", "sv39_ad_write_pmp_deny(what, write_access, leaf_flags, partial_cover, 5);"),
        "lsu_tb_keeps_awready_wready_high": (
            "lsu_tb", "response-delay=%0d awready=1 wready=1 interval=through-handshake"),
    }
    for name, (source, anchor) in anchors.items():
        if texts[source].count(anchor) < 1:
            raise ValueError(f"static contract anchor drifted: {name}")
    validate_lsu_unbounded_deny_quiet_structure(texts["lsu"])
    if texts["ifu"].index(IFU_DENY_CONDITION) >= texts["ifu"].index(
        "end else if (exec_ad_update_needed(ifu_axi_rdata_i)) begin"
    ):
        raise ValueError("IFU PTE WRITE deny no longer precedes allow")
    if texts["lsu"].index(LSU_DENY_CONDITION) >= texts["lsu"].index(
        "end else if (walk_ad_needed_w) begin"
    ):
        raise ValueError("LSU PTE WRITE deny no longer precedes allow")
    return {name: True for name in anchors}


SOURCE_BINDING_PATHS = (
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "npc/rv64/vsrc/memory/PmpChecker.v",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{RUN_ID}/contract.md",
    f".github/task-runs/{RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{RUN_ID}/run-focused.sh",
    f".github/task-runs/{RUN_ID}/run-ptw-pmp-variants.py",
    "npc/rv64/eval/ppa/tools/ptw_pmp_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_ptw_pmp_evidence.py",
)


def build(
    *, root: pathlib.Path, ifu_log: pathlib.Path, lsu_log: pathlib.Path,
    module_summary: pathlib.Path, variant_summary: pathlib.Path,
) -> dict[str, Any]:
    ifu = parse_ifu_log(ifu_log)
    lsu = parse_lsu_log(lsu_log)
    module = parse_module_aggregate(root, module_summary)
    variants = validate_variants(root, variant_summary)
    static = validate_static_contract(root)
    lsu_deny_quiet_structure = validate_lsu_unbounded_deny_quiet_structure(
        safe_file(
            root, root / "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
        ).read_text(encoding="utf-8"))
    rtl_sha, rtl_files = arch.rtl_binding(root)
    source_bindings = {
        relative: sha256_file(safe_file(root, root / relative))
        for relative in SOURCE_BINDING_PATHS
    }
    return {
        "schema": SCHEMA,
        "suite_run_id": RUN_ID,
        "status": "PASS",
        "design_id": f"sha256:{rtl_sha}",
        "canonical_command": CANONICAL_COMMAND,
        "scope": SCOPE,
        "metrics": {"ifu": ifu["metrics"], "lsu": lsu["metrics"]},
        "manifests": {
            "ifu_frontier_denies": ifu["frontier_manifest"],
            "lsu_denies": lsu["deny_manifest"],
            "lsu_allows": lsu["allow_manifest"],
            "lsu_deny_quiet_structure": lsu_deny_quiet_structure,
        },
        "invariants": INVARIANTS,
        "focused_tests": {
            "ifu_bridge": {"status": "PASS", "log_sha256": sha256_file(ifu_log)},
            "lsu_bridge": {"status": "PASS", "log_sha256": sha256_file(lsu_log)},
        },
        "module_aggregate": module,
        "variant_audit": variants,
        "static_audit": static,
        "provenance": {
            "rtl_sha256": rtl_sha,
            "files": rtl_files,
            "source_bindings": source_bindings,
        },
        "artifacts": [
            artifact(root, ifu_log, "ptw_pmp_ifu_focused_log"),
            artifact(root, lsu_log, "ptw_pmp_lsu_focused_log"),
            artifact(root, module_summary, "module_aggregate_summary"),
            artifact(root, variant_summary, "rtl_variant_summary"),
        ],
        "claim": {
            "architecture_debts": {"PTW-PMP-G1": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def raw_summary(result: dict[str, Any]) -> str:
    ifu = result["metrics"]["ifu"]
    lsu = result["metrics"]["lsu"]
    variants = result["variant_audit"]
    module = result["module_aggregate"]
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"canonical_command={result['canonical_command']}",
        f"ifu_allow_rows={ifu['allow_rows']}",
        f"ifu_deny_f0_rows={ifu['deny_f0_rows']}",
        f"ifu_deny_frontier_rows={ifu['deny_frontier_rows']}",
        "ifu_deny_frontiers=2/4/6",
        f"ifu_partial_cover_rows={ifu['partial_cover_rows']}",
        f"ifu_allow_awaddr_bound_rows={ifu['allow_awaddr_bound_rows']}",
        f"ifu_allow_split_aw_first_rows={ifu['allow_split_aw_first_rows']}",
        f"ifu_allow_stall_cycles={ifu['allow_stall_cycles']}",
        f"lsu_deny_rows={lsu['deny_rows']}",
        f"lsu_deny_scenarios={lsu['deny_scenarios']}",
        f"lsu_allow_rows={lsu['allow_rows']}",
        f"lsu_owner_stable_rows={lsu['owner_stable_rows']}",
        f"lsu_response_delay_rows={lsu['response_delay_rows']}",
        "lsu_response_delay_sweep=0/1/2/3/5",
        f"lsu_response_stall_cycles={lsu['response_stall_cycles']}",
        f"lsu_closed_interval_quiet_rows={lsu['closed_interval_quiet_rows']}",
        f"lsu_ready_high_quiet_rows={lsu['ready_high_quiet_rows']}",
        "lsu_unbounded_deny_quiet_structure=PASS",
        f"lsu_allow_split_aw_first_rows={lsu['allow_split_aw_first_rows']}",
        f"lsu_allow_split_w_first_rows={lsu['allow_split_w_first_rows']}",
        f"lsu_allow_stall_cycles={lsu['allow_stall_cycles']}",
        f"lsu_partial_cover_rows={lsu['partial_cover_rows']}",
        f"compile_success_rtl_variants={variants['compile_success']}",
        f"dynamic_rejected_rtl_variants={variants['dynamic_rejected']}",
        f"module_aggregate={module['passed']}/{module['required']}",
        "production_rtl_changed=false",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[PTW-PMP-G1-GATE] PASS",
        "",
    ))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--ifu-log", type=pathlib.Path, required=True)
    parser.add_argument("--lsu-log", type=pathlib.Path, required=True)
    parser.add_argument("--module-summary", type=pathlib.Path, required=True)
    parser.add_argument("--variant-summary", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--raw-log", type=pathlib.Path, required=True)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)
    result = build(
        root=root,
        ifu_log=safe_file(root, args.ifu_log),
        lsu_log=safe_file(root, args.lsu_log),
        module_summary=safe_file(root, args.module_summary),
        variant_summary=safe_file(root, args.variant_summary),
    )
    output = args.output.resolve()
    raw_log = args.raw_log.resolve()
    if not output.is_relative_to(root) or not raw_log.is_relative_to(root):
        raise ValueError("evidence output escapes repository")
    output.parent.mkdir(parents=True, exist_ok=True)
    raw_log.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    print(raw_summary(result), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
