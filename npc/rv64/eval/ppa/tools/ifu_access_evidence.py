#!/usr/bin/env python3
"""Build fail-closed local RV64 IFU-ACCESS-G1 current-design evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-ifu-access-evidence-v1"
VARIANT_SCHEMA = "npc-rv64-ifu-access-rtl-variants-v1"
RUN_ID = "2026-07-22-rv64-v9i-ifu-access-current-design"
CANONICAL_COMMAND = "make -C npc/rv64 check-ifu-access"
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_ifu_access", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

VARIANT_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-ifu-access-variants.py"
VARIANT_SPEC = importlib.util.spec_from_file_location(
    "ifu_access_variants", VARIANT_RUNNER)
assert VARIANT_SPEC is not None and VARIANT_SPEC.loader is not None
variant_model = importlib.util.module_from_spec(VARIANT_SPEC)
sys.modules[VARIANT_SPEC.name] = variant_model
VARIANT_SPEC.loader.exec_module(variant_model)


FOOTPRINT_MARKER = (
    "[ACCESS-G1-MATRIX] footprint=4 poison=4 alignment=16 rresp=36 "
    "rresp_owner=18/18 rresp_sources=12/12/12 walk=12 pmp=14 "
    "pmp_owner=6/6 lifecycle=2 sequence=1 PASS"
)
ATTR_MARKER = (
    "[ACCESS-G1-ATTRS] instruction_size=1 instruction_prot=4 "
    "ptw_size=3 ptw_prot=0 stall_instruction=2 stall_ptw=2 PASS"
)
FIREWALL_MARKER = (
    "[ACCESS-G1-FIREWALL] stall_cycles=4 ifu_redirect=1 "
    "uart_side_effect=0 default_error=2 lsu_data_control=1 PASS"
)
LANE1_MARKER = (
    "[ACCESS-G1-LANE1] rows=9 terminal=4 squash=2 poison=2 pseudo=1 "
    "tval_terminal=4 PASS"
)
OWNER_MAP_MARKER = (
    "[ACCESS-G1-OWNER-MAP] rows=12 lane0=6 lane1=6 capture=12 "
    "pending=12 drain=12 PASS"
)
DPI_MARKER = (
    "AXI_DPI_SIZED_PASS ifetch_lanes=4 data_lanes=2 invalid_read=1 "
    "write_lanes=4 invalid_writes=3 read_calls=6 write_calls=4"
)
GUARD_RE = re.compile(
    r"^SIZED_DPI_GUARD_PASS e2e=AxiDpiSlave-dpi-paddr "
    r"tail_addr=0x000000008000000e bytes=2 guard=PROT_NONE "
    r"guard_probe=SIGSEGV data=0x[0-9a-f]+$",
    re.MULTILINE,
)

FOOTPRINT_METRICS = {
    "footprint_rows": 4,
    "poison_rows": 4,
    "alignment_rows": 16,
    "rresp_rows": 36,
    "rresp_lane0_rows": 18,
    "rresp_lane1_rows": 18,
    "rresp_exokay_rows": 12,
    "rresp_slverr_rows": 12,
    "rresp_decerr_rows": 12,
    "walk_rows": 12,
    "pmp_rows": 14,
    "pmp_lane0_rows": 6,
    "pmp_lane1_rows": 6,
    "lifecycle_rows": 2,
    "sequence_rows": 1,
    "success_side_effect_rows": 4,
    "fault_side_effect_rows": 36,
    "rresp_valid_gate_rows": 1,
    "dual_source_priority_rows": 1,
    "back_to_back_no_reset_rows": 1,
}
ATTR_METRICS = {
    "instruction_size": 1,
    "instruction_prot": 4,
    "ptw_size": 3,
    "ptw_prot": 0,
    "instruction_stall_cycles": 2,
    "ptw_stall_cycles": 2,
}
FIREWALL_METRICS = {
    "stall_cycles": 4,
    "ifu_redirect_rows": 1,
    "uart_side_effects": 0,
    "default_error": 2,
    "lsu_data_control_rows": 1,
}
LANE_METRICS = {
    "legacy_rows": 9,
    "terminal_rows": 4,
    "squash_rows": 2,
    "poison_rows": 2,
    "pseudo_rows": 1,
    "owner_map_rows": 12,
    "owner_map_lane0_rows": 6,
    "owner_map_lane1_rows": 6,
    "owner_map_capture_rows": 12,
    "owner_map_pending_rows": 12,
    "owner_map_drain_rows": 12,
}
DPI_METRICS = {
    "ifetch_lanes": 4,
    "data_lanes": 2,
    "invalid_read": 1,
    "write_lanes": 4,
    "invalid_writes": 3,
    "read_calls": 6,
    "write_calls": 4,
    "tail_bytes": 2,
    "guard_probe_sigsegv": 1,
}
INVARIANTS = {
    "instruction_footprint_is_exact_halfword_sequence": True,
    "frontier_closes_younger_pmp_and_ar": True,
    "non_ok_rresp_closes_fill_and_sram_write": True,
    "rresp_is_sampled_only_on_valid_ready_owner": True,
    "older_rresp_precedes_younger_pmp": True,
    "exact_exec_pmp_range_is_two_bytes": True,
    "unmatched_supervisor_pmp_access_is_denied": True,
    "fixed_window_pmp_reject_only_selects_slow_path": True,
    "instruction_ar_is_two_byte_execute": True,
    "ptw_ar_is_eight_byte_data": True,
    "stalled_ar_address_is_registered": True,
    "device_instruction_read_routes_to_default_error": True,
    "device_instruction_read_has_no_uart_side_effect": True,
    "dpi_ifetch_reads_exact_requested_bytes": True,
    "lane1_fault_owner_survives_capture_pending_and_drain": True,
    "lane1_wrong_path_owner_is_squashed_after_branch_resolution": True,
    "predicted_taken_invalid_lane1_has_no_owner": True,
    "decoder_frontier_selects_exact_lane_owner": True,
    "no_reset_packet_sequence_clears_access_owner_state": True,
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
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{label}: expected one exact [RESULT] PASS marker")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")


def parse_footprint_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_access_footprint", "footprint log")
    exact_counts = {
        FOOTPRINT_MARKER: 1,
        "[ACCESS-G1-SUCCESS-SIDE-EFFECT]": 4,
        "[ACCESS-G1-RRESP-OWNER-CONTROL-PASS]": 36,
        "[ACCESS-G1-PMP-OWNER-CONTROL-PASS]": 12,
        "[ACCESS-G1-RRESP-VALID-GATE]": 1,
        "[ACCESS-G1-DUAL-SOURCE-ORDER]": 1,
        "[ACCESS-G1-BACK-TO-BACK]": 1,
    }
    for marker, count in exact_counts.items():
        if text.count(marker) != count:
            raise ValueError(f"footprint semantic inventory drifted: {marker}")
    return dict(FOOTPRINT_METRICS)


def parse_attrs_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_axi_access_attrs", "attribute log")
    if text.count(ATTR_MARKER) != 1:
        raise ValueError("instruction/PTW AXI attribute marker drifted")
    return dict(ATTR_METRICS)


def parse_firewall_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_axi_exec_firewall", "firewall log")
    if text.count(FIREWALL_MARKER) != 1:
        raise ValueError("execute firewall marker drifted")
    return dict(FIREWALL_METRICS)


def parse_lane_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_ifu_lane1_fault_owner", "lane owner log")
    if text.count(LANE1_MARKER) != 1 or text.count(OWNER_MAP_MARKER) != 1:
        raise ValueError("lane1 owner aggregate marker drifted")
    if text.count("[ACCESS-G1-OWNER-MAP-PASS]") != 12:
        raise ValueError("decoder-to-pending owner row inventory drifted")
    if text.count("[ROW-STAGES]") != 6 or text.count("[ROW-PASS]") != 9:
        raise ValueError("lane1 capture/squash row inventory drifted")
    return dict(LANE_METRICS)


def parse_dpi_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    if text.count(DPI_MARKER) != 1 or text.count("AXI_DPI_SIZED_SUITE_PASS") != 1:
        raise ValueError("sized DPI lane summary drifted")
    if len(list(GUARD_RE.finditer(text))) != 1:
        raise ValueError("sized DPI guard-page marker drifted")
    for marker in ("AXI_DPI_SIZED_FAIL", "SIZED_DPI_GUARD_FAIL"):
        if marker in text:
            raise ValueError(f"sized DPI log contains failure marker {marker}")
    return dict(DPI_METRICS)


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
    if any(not re.fullmatch(r"tb_[a-z0-9_]+", name) for name in tests):
        raise ValueError("module TESTS inventory contains a malformed name")
    return tests


def parse_module_aggregate(
    root: pathlib.Path, summary: pathlib.Path,
) -> dict[str, Any]:
    tests = required_module_tests(root / "npc/rv64/testbench/Makefile")
    text = summary.read_text(encoding="utf-8")
    count = len(tests)
    markers = (
        "# NPC single module testbench summary",
        f"- total: {count}", f"- passed: {count}", "- failed: 0",
    )
    if any(text.count(marker) != 1 for marker in markers):
        raise ValueError("module aggregate summary counts are incomplete")
    log_dir = summary.parent / "logs"
    actual_logs = {path.stem for path in log_dir.glob("*.log") if path.is_file()}
    if actual_logs != set(tests):
        raise ValueError("module aggregate log inventory is not exact")
    records: dict[str, dict[str, str]] = {}
    summary_lines = text.splitlines()
    for test_name in tests:
        if summary_lines.count(f"- PASS {test_name}") != 1:
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
        row_ok = (
            log_path is not None and set(log) == {"path", "sha256"}
            and log.get("sha256") == sha256_file(log_path)
            and row.get("debt_id") == "IFU-ACCESS-G1"
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
            and "/tmp/rv64-v9i-" not in log_text
            and spec.expected_marker in log_text
            and "[RESULT] FAIL status=" in log_text
            and "[RESULT] PASS" not in log_text
        )
        if not row_ok:
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
        "bridge": "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
        "pmp": "npc/rv64/vsrc/memory/PmpChecker.v",
        "xbar": "npc/rv64/vsrc/bus/AxiCrossbar.v",
        "dpi": "npc/rv64/vsrc/sim/AxiDpiSlave.sv",
        "pair": "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
        "dispatch": "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
        "capture": "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
        "arbiter": "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
        "decoder": "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
        "footprint_tb": "npc/rv64/testbench/tests/tb_ooo_fetch_access_footprint.sv",
        "lane_tb": "npc/rv64/testbench/tests/tb_ooo_ifu_lane1_fault_owner.sv",
    }
    texts = {
        name: safe_file(root, root / relative).read_text(encoding="utf-8")
        for name, relative in paths.items()
    }
    anchors = {
        "bridge_exact_instruction_size": (
            "bridge", "ifu_axi_walk_ar_owner_w ? 3'd3 : 3'd1"),
        "bridge_exact_instruction_protection": (
            "bridge", "ifu_axi_walk_ar_owner_w ? 3'b000 : 3'b100"),
        "bridge_exact_exec_pmp_halfword": (
            "bridge", "PmpChecker u_fetch_current_pmp_checker (\n"
            "    .paddr_i(fetch_current_paddr_w),\n"
            "    .access_size_i(4'd2),"),
        "bridge_fault_closes_response": (
            "bridge", "if (ifu_axi_rresp_i != RESP_OK) begin"),
        "bridge_fill_requires_complete_packet": (
            "bridge", "!fetch_more_after_r_w && !packet_cross_page_q;"),
        "pmp_unmatched_supervisor_default_deny": (
            "pmp", "fault_r = (priv_mode_i != `PRIV_M)"),
        "xbar_execute_mask_precedes_arbitration": (
            "xbar", "prot[2] && !SLAVE_EXEC_MASK[decoded]"),
        "xbar_stalled_araddr_uses_registered_owner": (
            "xbar", "s_araddr_r[s*ADDR_W +: ADDR_W] = rd_addr_q[s];"),
        "xbar_buffered_read_releases_on_ready": (
            "xbar", "rd_resp_valid_q[m] && m_rready_i[m]"),
        "dpi_instruction_callback_receives_size": (
            "dpi", "npc_ifetch_sized(s_axi_araddr_i, read_size_v"),
        "pair_requires_visible_lane1": (
            "pair", "fifo_has_packet_i && head_slot1_valid_i"),
        "dispatch_lane1_fault_is_barrier": (
            "dispatch", "(head_fetch_fault1_i ||"),
        "capture_lane1_fault_is_arch_valid": (
            "capture", "(head_fetch_fault_i || csr_illegal_i || arch_trap_raw_w)"),
        "rob_walk_filter_requires_absent_fault_owner": (
            "arbiter", "rob_walk_mode_i && !head_fetch_fault1_i"),
        "decoder_lane1_start_uses_lane0_length": (
            "decoder", "wire [3:0] dec1_start_byte_w = dec0_len_bytes_w;"),
        "footprint_nonvacuous_matrix": (
            "footprint_tb", "[ACCESS-G1-RRESP-OWNER-CONTROL-PASS]"),
        "lane_owner_composition_matrix": (
            "lane_tb", "[ACCESS-G1-OWNER-MAP] rows=12 lane0=6 lane1=6"),
    }
    for name, (source, anchor) in anchors.items():
        if texts[source].count(anchor) < 1:
            raise ValueError(f"static contract anchor drifted: {name}")
    return {name: True for name in anchors}


SOURCE_BINDING_PATHS = (
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
    "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
    "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
    "npc/rv64/vsrc/control/OooStopPendingSequencer.v",
    "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
    "npc/rv64/vsrc/memory/PmpChecker.v",
    "npc/rv64/vsrc/bus/AxiCrossbar.v",
    "npc/rv64/vsrc/sim/AxiDpiSlave.sv",
    "npc/rv64/csrc/dpi.c",
    "npc/rv64/csrc/memory/paddr.c",
    "npc/rv64/testbench/tests/tb_ooo_fetch_access_footprint.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_access_attrs.sv",
    "npc/rv64/testbench/tests/tb_ooo_ifu_lane1_fault_owner.sv",
    "npc/rv64/testbench/tests/tb_axi_exec_firewall.sv",
    "npc/rv64/testbench/cpp/axi_dpi_slave_sized_tb.cpp",
    "npc/rv64/testbench/cpp/sized_dpi_guard_tb.cpp",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{RUN_ID}/contract.md",
    f".github/task-runs/{RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{RUN_ID}/review-summary.md",
    f".github/task-runs/{RUN_ID}/run-focused.sh",
    f".github/task-runs/{RUN_ID}/run-ifu-access-variants.py",
    "npc/rv64/eval/ppa/tools/ifu_access_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_ifu_access_evidence.py",
)


def build(
    *, root: pathlib.Path, footprint_log: pathlib.Path,
    attrs_log: pathlib.Path, firewall_log: pathlib.Path,
    lane_log: pathlib.Path, dpi_log: pathlib.Path,
    module_summary: pathlib.Path, variant_summary: pathlib.Path,
) -> dict[str, Any]:
    metrics = {
        "footprint": parse_footprint_log(footprint_log),
        "attributes": parse_attrs_log(attrs_log),
        "firewall": parse_firewall_log(firewall_log),
        "lane_owner": parse_lane_log(lane_log),
        "dpi": parse_dpi_log(dpi_log),
    }
    module = parse_module_aggregate(root, module_summary)
    variants = validate_variants(root, variant_summary)
    static = validate_static_contract(root)
    rtl_sha, rtl_files = arch.rtl_binding(root)
    source_bindings = {
        relative: sha256_file(safe_file(root, root / relative))
        for relative in SOURCE_BINDING_PATHS
    }
    logs = {
        "footprint": footprint_log,
        "attributes": attrs_log,
        "firewall": firewall_log,
        "lane_owner": lane_log,
        "dpi": dpi_log,
    }
    return {
        "schema": SCHEMA,
        "suite_run_id": RUN_ID,
        "status": "PASS",
        "design_id": f"sha256:{rtl_sha}",
        "canonical_command": CANONICAL_COMMAND,
        "scope": (
            "local RV64 instruction-fetch exact halfword access, execute PMP, "
            "AXI ARSIZE/ARPROT, AxiCrossbar ARPROT[2] default-slave selection, "
            "bounded PMEM DPI reads and precise lane fault owner"
        ),
        "metrics": metrics,
        "invariants": INVARIANTS,
        "focused_tests": {
            name: {"status": "PASS", "log_sha256": sha256_file(path)}
            for name, path in logs.items()
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
            artifact(root, footprint_log, "ifu_access_footprint_focused_log"),
            artifact(root, attrs_log, "ifu_access_attributes_focused_log"),
            artifact(root, firewall_log, "ifu_access_firewall_focused_log"),
            artifact(root, lane_log, "ifu_access_lane_owner_focused_log"),
            artifact(root, dpi_log, "ifu_access_sized_dpi_log"),
            artifact(root, module_summary, "module_aggregate_summary"),
            artifact(root, variant_summary, "rtl_variant_summary"),
        ],
        "claim": {
            "architecture_debts": {"IFU-ACCESS-G1": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def raw_summary(result: dict[str, Any]) -> str:
    footprint = result["metrics"]["footprint"]
    attrs = result["metrics"]["attributes"]
    firewall = result["metrics"]["firewall"]
    lane = result["metrics"]["lane_owner"]
    dpi = result["metrics"]["dpi"]
    variants = result["variant_audit"]
    module = result["module_aggregate"]
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"canonical_command={result['canonical_command']}",
        f"footprint_rows={footprint['footprint_rows']}",
        f"alignment_rows={footprint['alignment_rows']}",
        f"rresp_rows={footprint['rresp_rows']}",
        "rresp_owner_rows="
        f"{footprint['rresp_lane0_rows']}/{footprint['rresp_lane1_rows']}",
        "rresp_source_rows="
        f"{footprint['rresp_exokay_rows']}/"
        f"{footprint['rresp_slverr_rows']}/"
        f"{footprint['rresp_decerr_rows']}",
        f"pmp_rows={footprint['pmp_rows']}",
        "pmp_owner_rows="
        f"{footprint['pmp_lane0_rows']}/{footprint['pmp_lane1_rows']}",
        f"lifecycle_rows={footprint['lifecycle_rows']}",
        f"instruction_arsize={attrs['instruction_size']}",
        f"instruction_arprot={attrs['instruction_prot']}",
        f"ptw_arsize={attrs['ptw_size']}",
        f"ptw_arprot={attrs['ptw_prot']}",
        f"firewall_stall_cycles={firewall['stall_cycles']}",
        f"uart_side_effects={firewall['uart_side_effects']}",
        f"lane_owner_rows={lane['owner_map_rows']}",
        "lane_owner_split="
        f"{lane['owner_map_lane0_rows']}/{lane['owner_map_lane1_rows']}",
        f"dpi_ifetch_lanes={dpi['ifetch_lanes']}",
        f"dpi_tail_bytes={dpi['tail_bytes']}",
        f"compile_success_rtl_variants={variants['compile_success']}",
        f"dynamic_rejected_rtl_variants={variants['dynamic_rejected']}",
        f"module_aggregate={module['passed']}/{module['required']}",
        "production_rtl_changed=false",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[IFU-ACCESS-G1-GATE] PASS",
        "",
    ))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--footprint-log", type=pathlib.Path, required=True)
    parser.add_argument("--attrs-log", type=pathlib.Path, required=True)
    parser.add_argument("--firewall-log", type=pathlib.Path, required=True)
    parser.add_argument("--lane-log", type=pathlib.Path, required=True)
    parser.add_argument("--dpi-log", type=pathlib.Path, required=True)
    parser.add_argument("--module-summary", type=pathlib.Path, required=True)
    parser.add_argument("--variant-summary", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--raw-log", type=pathlib.Path, required=True)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)
    output = args.output.resolve()
    raw_log = args.raw_log.resolve()
    for path in (output, raw_log):
        if not path.is_relative_to(root):
            parser.error(f"output escapes repository: {path}")
        path.parent.mkdir(parents=True, exist_ok=True)
    result = build(
        root=root,
        footprint_log=safe_file(root, args.footprint_log),
        attrs_log=safe_file(root, args.attrs_log),
        firewall_log=safe_file(root, args.firewall_log),
        lane_log=safe_file(root, args.lane_log),
        dpi_log=safe_file(root, args.dpi_log),
        module_summary=safe_file(root, args.module_summary),
        variant_summary=safe_file(root, args.variant_summary),
    )
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    print(
        f"[IFU-ACCESS-EVIDENCE] design_id={result['design_id']} focused=5/5 "
        f"variants={result['variant_audit']['dynamic_rejected']}/"
        f"{result['variant_audit']['required']} status=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
