#!/usr/bin/env python3
"""Build fail-closed local RV64 IFU-TVAL-G1 current-design evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-ifu-tval-evidence-v2"
VARIANT_SCHEMA = "npc-rv64-ifu-tval-rtl-variants-v1"
RUN_ID = "2026-07-22-rv64-v9j-ifu-tval-current-design"
CANONICAL_COMMAND = "make -C npc/rv64 check-ifu-tval"
SCOPE = (
    "local RV64 instruction-fetch fault PC/cause/tval ownership across "
    "decoder, packet FIFO, compressed-control visibility, pending storage "
    "and drained CSR request"
)
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_ifu_tval", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

VARIANT_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-ifu-tval-variants.py"
VARIANT_SPEC = importlib.util.spec_from_file_location(
    "ifu_tval_variants", VARIANT_RUNNER)
assert VARIANT_SPEC is not None and VARIANT_SPEC.loader is not None
variant_model = importlib.util.module_from_spec(VARIANT_SPEC)
sys.modules[VARIANT_SPEC.name] = variant_model
VARIANT_SPEC.loader.exec_module(variant_model)


DECODER_MARKER = (
    "[T4G-FETCH-FAULT-TVAL-FRONTIER] F=2/4/6 exact portion addresses covered"
)
PAGE_END_MARKER = (
    "[TVAL-G1-PAGE-END] PF=9 F2=5 F4=3 F6=1 "
    "tval=packet_pc+F PASS"
)
FIFO_MARKER = "[TVAL-G1-FIFO-OFFSETS] F2=1 F4=1 F6=1 atomic=3 PASS"
CAPTURE_MARKER = (
    "[T4G-LANE1-FETCH-FAULT-TVAL] page/access faults use portion "
    "frontier, not slot PC"
)
ARBITER_MARKER = (
    "[T4G-PENDING-FETCH-FAULT-TVAL] lane0/lane1 capture preserve "
    "common portion frontier"
)
PENDING_MARKER = (
    "[TVAL-G1-PENDING-SEQUENCER] capture=1 hold_valid_clear=1 "
    "squash_clear=1 late_clear=1 PASS"
)
CSR_MARKER = (
    "[TVAL-G1-CSR-MUX] pending_owner=1 ex_pc_tval_split=1 "
    "system_tval_zero=1 PASS"
)
LIFECYCLE_MARKER = (
    "[TVAL-G1-LIFECYCLE] rows=24 pf=12 af=12 lane0=12 lane1=12 "
    "F0=8 F2=8 F4=6 F6=2 capture=24 pending=24 drain=24 PASS"
)
CONTROL_MARKER = (
    "[TVAL-G1-COMPRESSED-CONTROL] rows=6 terminal=2 squash=2 "
    "poison=2 F=4 xepc=PC+2 tval=PC+4 PASS"
)
DISPATCH_STALL_MARKER = (
    "[TVAL-G1-DISPATCH-STALL] rows=1 blocked=1 accepted=1 pending=1 "
    "drain=1 xepc=PC+2 tval=PC+4 PASS"
)

DECODER_METRICS = {
    "frontier_rows": 4,
    "frontier_f0_rows": 1,
    "frontier_f2_rows": 1,
    "frontier_f4_rows": 1,
    "frontier_f6_rows": 1,
}
PAGE_END_METRICS = {
    "page_fault_rows": 9,
    "frontier_f2_rows": 5,
    "frontier_f4_rows": 3,
    "frontier_f6_rows": 1,
}
FIFO_METRICS = {
    "offset_rows": 3,
    "frontier_f2_rows": 1,
    "frontier_f4_rows": 1,
    "frontier_f6_rows": 1,
}
STAGE_METRICS = {
    "capture_causes": 2,
    "arbiter_lanes": 2,
    "pending_capture": 1,
    "pending_hold_valid_clear": 1,
    "pending_squash_clear": 1,
    "pending_late_clear": 1,
    "csr_pending_owner": 1,
    "csr_pc_tval_split": 1,
    "csr_system_tval_zero": 1,
}
LIFECYCLE_METRICS = {
    "rows": 24,
    "page_fault_rows": 12,
    "access_fault_rows": 12,
    "lane0_rows": 12,
    "lane1_rows": 12,
    "frontier_f0_rows": 8,
    "frontier_f2_rows": 8,
    "frontier_f4_rows": 6,
    "frontier_f6_rows": 2,
    "capture_rows": 24,
    "pending_rows": 24,
    "drain_rows": 24,
}
CONTROL_METRICS = {
    "rows": 6,
    "terminal_rows": 2,
    "squash_rows": 2,
    "poison_rows": 2,
    "frontier": 4,
    "xepc_delta": 2,
    "tval_delta": 4,
}
DISPATCH_STALL_METRICS = {
    "rows": 1,
    "blocked_rows": 1,
    "accepted_rows": 1,
    "pending_rows": 1,
    "drain_rows": 1,
}


def expected_lifecycle_manifest() -> list[dict[str, Any]]:
    base = 0x0000_0000_8000_1000
    layouts = (
        ("C/C", 2, ((0, "L0"), (2, "L1"))),
        ("C/U", 2, ((0, "L0"), (2, "L1"), (4, "L1"))),
        ("U/C", 4, ((0, "L0"), (2, "L0"), (4, "L1"))),
        ("U/U", 4, ((0, "L0"), (2, "L0"), (4, "L1"), (6, "L1"))),
    )
    rows: list[dict[str, Any]] = []
    for cause in ("PF", "AF"):
        for layout, lane0_bytes, frontiers in layouts:
            for frontier, owner in frontiers:
                xepc = base if owner == "L0" else base + lane0_bytes
                rows.append({
                    "row": f"{cause} {layout} F{frontier}",
                    "cause": cause,
                    "layout": layout,
                    "frontier": frontier,
                    "owner": owner,
                    "xepc": f"{xepc:016x}",
                    "tval": f"{base + frontier:016x}",
                    "capture": True,
                    "pending": True,
                    "drain": True,
                })
    return rows


EXPECTED_LIFECYCLE_MANIFEST = expected_lifecycle_manifest()
LIFECYCLE_ROW_RE = re.compile(
    r"^\[TVAL-G1-LIFECYCLE-PASS\] "
    r"(?P<row>(?P<row_cause>PF|AF) (?P<layout>C/C|C/U|U/C|U/U) "
    r"F(?P<row_frontier>[0246])) "
    r"F=(?P<frontier>[0246]) cause=(?P<cause>PF|AF) "
    r"owner=(?P<owner>L0|L1) "
    r"xepc=(?P<xepc>[0-9a-f]{16}) tval=(?P<tval>[0-9a-f]{16})$"
)
INVARIANTS = {
    "fault_tval_is_packet_pc_plus_first_failing_halfword_offset": True,
    "fault_instruction_pc_and_fault_halfword_address_are_independent": True,
    "page_fault_and_access_fault_share_the_same_tval_owner_rule": True,
    "lane0_and_lane1_select_instruction_pc_without_rebuilding_tval": True,
    "fifo_preserves_fault_tval_as_atomic_packet_metadata": True,
    "frontend_head_uses_only_fifo_fault_tval_projection": True,
    "capture_preserves_fault_tval_for_both_instruction_fault_causes": True,
    "pending_storage_holds_cause_pc_tval_until_drain": True,
    "drained_csr_request_uses_pending_tval": True,
    "compressed_branch_fallthrough_fault_keeps_xepc_at_lane1_pc": True,
    "compressed_branch_fallthrough_fault_keeps_tval_at_failing_halfword": True,
    "actual_taken_resolution_clears_speculative_tval": True,
    "predicted_taken_invisible_lane_has_no_tval_owner": True,
    "page_end_bridge_rows_bind_real_f2_f4_f6_frontiers": True,
    "dispatch_backpressure_prevents_early_fault_tuple_capture": True,
    "stop_sequencer_controls_only_stop_validity_not_tval_payload": True,
    "joint_lifecycle_manifest_is_exact": True,
    "production_rtl_is_unchanged_by_verification_variants": True,
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


def parse_decoder_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_packet_decode", "decoder log")
    if text.count(DECODER_MARKER) != 1 or text.count("[G2-DECODE-F0]") != 1:
        raise ValueError("decoder fault-frontier inventory drifted")
    return dict(DECODER_METRICS)


def parse_page_end_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_page_end_fault", "page-end log")
    if text.count(PAGE_END_MARKER) != 1:
        raise ValueError("page-end fault-tval marker drifted")
    if text.count("[G2-RAW-FAULT-OWNER]") != 9:
        raise ValueError("page-end raw fault owner inventory drifted")
    return dict(PAGE_END_METRICS)


def parse_fifo_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_packet_fifo", "FIFO log")
    if text.count(FIFO_MARKER) != 1:
        raise ValueError("FIFO offset aggregate marker drifted")
    if text.count("[TVAL-G1-FIFO-OFFSET-PASS]") != 3:
        raise ValueError("FIFO fault-tval offset row inventory drifted")
    return dict(FIFO_METRICS)


def parse_stage_logs(
    capture_path: pathlib.Path,
    arbiter_path: pathlib.Path,
    pending_path: pathlib.Path,
    csr_path: pathlib.Path,
) -> dict[str, int]:
    records = (
        (capture_path, "tb_ooo_pending_lane1_capture_gate", CAPTURE_MARKER),
        (arbiter_path, "tb_ooo_pending_dispatch_arbiter", ARBITER_MARKER),
        (pending_path, "tb_ooo_pending_trap_exit_sequencer", PENDING_MARKER),
        (csr_path, "tb_ooo_csr_trap_request_mux", CSR_MARKER),
    )
    for path, test_name, marker in records:
        text = path.read_text(encoding="utf-8")
        require_pass_log(text, test_name, f"{test_name} log")
        if text.count(marker) != 1:
            raise ValueError(f"{test_name}: tval stage marker drifted")
    return dict(STAGE_METRICS)


def parse_lifecycle_log(path: pathlib.Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_ifu_lane1_fault_owner", "lifecycle log")
    if text.count(LIFECYCLE_MARKER) != 1:
        raise ValueError("PF/AF lifecycle aggregate marker drifted")
    if text.count(CONTROL_MARKER) != 1:
        raise ValueError("compressed-control aggregate marker drifted")
    if text.count(DISPATCH_STALL_MARKER) != 1:
        raise ValueError("dispatch-stall aggregate marker drifted")
    if text.count("[TVAL-G1-LIFECYCLE-PASS]") != 24:
        raise ValueError("PF/AF lifecycle row inventory drifted")
    if text.count("[TVAL-G1-CONTROL-PASS]") != 6:
        raise ValueError("compressed-control row inventory drifted")
    manifest: list[dict[str, Any]] = []
    for line in text.splitlines():
        if not line.startswith("[TVAL-G1-LIFECYCLE-PASS]"):
            continue
        match = LIFECYCLE_ROW_RE.fullmatch(line)
        if match is None:
            raise ValueError("PF/AF lifecycle row shape drifted")
        fields = match.groupdict()
        if (
            fields["row_cause"] != fields["cause"]
            or int(fields["row_frontier"]) != int(fields["frontier"])
        ):
            raise ValueError("PF/AF lifecycle row fields disagree")
        manifest.append({
            "row": fields["row"],
            "cause": fields["cause"],
            "layout": fields["layout"],
            "frontier": int(fields["frontier"]),
            "owner": fields["owner"],
            "xepc": fields["xepc"],
            "tval": fields["tval"],
            "capture": True,
            "pending": True,
            "drain": True,
        })
    if manifest != EXPECTED_LIFECYCLE_MANIFEST:
        raise ValueError("PF/AF lifecycle joint manifest drifted")
    return {
        "fault_matrix": dict(LIFECYCLE_METRICS),
        "compressed_control": dict(CONTROL_METRICS),
        "dispatch_stall": dict(DISPATCH_STALL_METRICS),
        "lifecycle_manifest": manifest,
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
    if any(not re.fullmatch(r"tb_[a-z0-9_]+", name) for name in tests):
        raise ValueError("module TESTS inventory contains a malformed name")
    return tests


def parse_module_aggregate(
    root: pathlib.Path,
    summary: pathlib.Path,
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
        and payload.get("source_sha256_before")
            == payload.get("source_sha256_after")
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
            and row.get("debt_id") == "IFU-TVAL-G1"
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
            and "/tmp/rv64-v9j-" not in log_text
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
        "decoder": "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
        "fifo": "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v",
        "frontend": "npc/rv64/vsrc/frontend/OooFrontend.v",
        "pair": "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
        "dispatch": "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
        "capture": "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
        "arbiter": "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
        "pending": "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
        "stop": "npc/rv64/vsrc/control/OooStopPendingSequencer.v",
        "csr": "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
        "lifecycle_tb": "npc/rv64/testbench/tests/tb_ooo_ifu_lane1_fault_owner.sv",
        "fifo_tb": "npc/rv64/testbench/tests/tb_ooo_fetch_packet_fifo.sv",
        "core_glue_tb": "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
    }
    texts = {
        name: safe_file(root, root / relative).read_text(encoding="utf-8")
        for name, relative in paths.items()
    }
    anchors = {
        "decoder_computes_packet_frontier": (
            "decoder",
            "rsp_pc_i + {{(`XLEN-3){1'b0}}, rsp_resp0_bytes_i}"),
        "fifo_stores_frontier_field": (
            "fifo", "fault_tval_q[tail_q] <= enqueue_fault_tval_i;"),
        "fifo_direct_head_uses_frontier_field": (
            "fifo", "enqueue_packet_next_pc_i,\n          enqueue_fault_tval_i,"),
        "frontend_enqueues_decoder_frontier": (
            "frontend", ".enqueue_fault_tval_i(fetch_dec_fault_tval_w)"),
        "frontend_projects_fifo_frontier": (
            "frontend", "assign head_fetch_fault_tval_w = fifo_head_fault_tval_w;"),
        "pair_requires_visible_lane1": (
            "pair", "fifo_has_packet_i && head_slot1_valid_i"),
        "dispatch_barrier_fire_requires_head_acceptance": (
            "dispatch",
            "dispatch1_barrier_o && !dispatch0_unsupported_i && dispatch0_ready_i"),
        "lane1_capture_uses_frontier": (
            "capture", "head_fetch_fault_i ? head_fetch_fault_tval_i"),
        "lane0_capture_uses_frontier": (
            "arbiter", "trap_exit_capture_fetch_fault0_w ? head_fetch_fault_tval_i"),
        "pending_captures_tval": (
            "pending", "pending_trap_tval_o <= capture_trap_tval_i;"),
        "pending_squash_clears_tval": (
            "pending", "pending_trap_tval_o <= {`XLEN{1'b0}};"),
        "stop_branch_squash_clears_validity": (
            "stop",
            "                  (branch_spec_checkpoint_capture_i ||\n"
            "                   branch_spec_resolve_valid_i ||\n"
            "                   branch_resolve_untracked_i)) ||\n"
            "                 orphan_stop_pending_i ||\n"
            "                 pending_branch_commit_resolve_i ||\n"
            "                 pending_branch_match_clear_i ||\n"
            "                 head0_csr_owner_kill_i ||\n"
            "                 pending_jump_terminal_clear_w) begin\n"
            "      stop_pending_o <= 1'b0;"),
        "csr_request_selects_pending_tval": (
            "csr", "pending_arch_trap_fire_o ? pending_trap_tval_i"),
        "lifecycle_matrix_is_nonvacuous": (
            "lifecycle_tb", LIFECYCLE_MARKER),
        "compressed_control_matrix_is_nonvacuous": (
            "lifecycle_tb", CONTROL_MARKER),
        "fifo_offset_matrix_is_nonvacuous": (
            "fifo_tb", FIFO_MARKER),
        "dispatch_stall_matrix_is_nonvacuous": (
            "lifecycle_tb", DISPATCH_STALL_MARKER),
        "core_integration_checks_projected_tval": (
            "core_glue_tb",
            'tb_check32("fetch fault handler reads precise mtval"'),
    }
    for name, (source, anchor) in anchors.items():
        if texts[source].count(anchor) < 1:
            raise ValueError(f"static contract anchor drifted: {name}")
    stop_header = texts["stop"].split(");", 1)[0]
    stop_port_declarations = "\n".join(
        line.strip() for line in stop_header.splitlines()
        if line.strip().startswith(("input ", "output "))
    )
    stop_outputs = re.findall(
        r"^output(?:\s+wire|\s+reg)?(?:\s+\[[^\]]+\])?\s+(\w+)",
        stop_port_declarations,
        flags=re.MULTILINE,
    )
    if stop_outputs != ["stop_pending_o"] or re.search(
        r"(?:tval|cause|(?:^|_)pc(?:_|\b))", stop_port_declarations
    ):
        raise ValueError(
            "OooStopPendingSequencer must control only stop validity, not "
            "cause/PC/tval payload")
    result = {name: True for name in anchors}
    result["stop_has_no_fault_payload_ports"] = True
    return result


SOURCE_BINDING_PATHS = (
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
    "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
    "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
    "npc/rv64/vsrc/control/OooStopPendingSequencer.v",
    "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
    "npc/rv64/testbench/tests/tb_ooo_fetch_packet_decode.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_page_end_fault.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_packet_fifo.sv",
    "npc/rv64/testbench/tests/tb_ooo_pending_lane1_capture_gate.sv",
    "npc/rv64/testbench/tests/tb_ooo_pending_dispatch_arbiter.sv",
    "npc/rv64/testbench/tests/tb_ooo_pending_trap_exit_sequencer.sv",
    "npc/rv64/testbench/tests/tb_ooo_csr_trap_request_mux.sv",
    "npc/rv64/testbench/tests/tb_ooo_ifu_lane1_fault_owner.sv",
    "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{RUN_ID}/contract.md",
    f".github/task-runs/{RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{RUN_ID}/run-focused.sh",
    f".github/task-runs/{RUN_ID}/run-ifu-tval-variants.py",
    "npc/rv64/eval/ppa/tools/ifu_tval_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_ifu_tval_evidence.py",
)


def build(
    *, root: pathlib.Path, decoder_log: pathlib.Path,
    page_end_log: pathlib.Path, fifo_log: pathlib.Path,
    capture_log: pathlib.Path, arbiter_log: pathlib.Path,
    pending_log: pathlib.Path, csr_log: pathlib.Path,
    lifecycle_log: pathlib.Path, module_summary: pathlib.Path,
    variant_summary: pathlib.Path,
) -> dict[str, Any]:
    lifecycle = parse_lifecycle_log(lifecycle_log)
    metrics = {
        "decoder": parse_decoder_log(decoder_log),
        "page_end": parse_page_end_log(page_end_log),
        "fifo": parse_fifo_log(fifo_log),
        "stages": parse_stage_logs(
            capture_log, arbiter_log, pending_log, csr_log),
        "fault_matrix": lifecycle["fault_matrix"],
        "compressed_control": lifecycle["compressed_control"],
        "dispatch_stall": lifecycle["dispatch_stall"],
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
        "decoder": decoder_log,
        "page_end": page_end_log,
        "fifo": fifo_log,
        "capture": capture_log,
        "arbiter": arbiter_log,
        "pending": pending_log,
        "csr": csr_log,
        "lifecycle": lifecycle_log,
    }
    kinds = {
        "decoder": "ifu_tval_decoder_focused_log",
        "page_end": "ifu_tval_page_end_focused_log",
        "fifo": "ifu_tval_fifo_focused_log",
        "capture": "ifu_tval_lane1_capture_focused_log",
        "arbiter": "ifu_tval_arbiter_focused_log",
        "pending": "ifu_tval_pending_focused_log",
        "csr": "ifu_tval_csr_focused_log",
        "lifecycle": "ifu_tval_lifecycle_focused_log",
    }
    return {
        "schema": SCHEMA,
        "suite_run_id": RUN_ID,
        "status": "PASS",
        "design_id": f"sha256:{rtl_sha}",
        "canonical_command": CANONICAL_COMMAND,
        "scope": SCOPE,
        "metrics": metrics,
        "manifests": {
            "lifecycle_rows": lifecycle["lifecycle_manifest"],
        },
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
            *(artifact(root, logs[name], kinds[name]) for name in logs),
            artifact(root, module_summary, "module_aggregate_summary"),
            artifact(root, variant_summary, "rtl_variant_summary"),
        ],
        "claim": {
            "architecture_debts": {"IFU-TVAL-G1": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def raw_summary(result: dict[str, Any]) -> str:
    metrics = result["metrics"]
    variants = result["variant_audit"]
    module = result["module_aggregate"]
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"canonical_command={result['canonical_command']}",
        f"decoder_frontier_rows={metrics['decoder']['frontier_rows']}",
        f"page_end_pf_rows={metrics['page_end']['page_fault_rows']}",
        "page_end_offsets="
        f"{metrics['page_end']['frontier_f2_rows']}/"
        f"{metrics['page_end']['frontier_f4_rows']}/"
        f"{metrics['page_end']['frontier_f6_rows']}",
        f"fifo_offset_rows={metrics['fifo']['offset_rows']}",
        f"lifecycle_rows={metrics['fault_matrix']['rows']}",
        "lifecycle_causes="
        f"{metrics['fault_matrix']['page_fault_rows']}/"
        f"{metrics['fault_matrix']['access_fault_rows']}",
        "lifecycle_lanes="
        f"{metrics['fault_matrix']['lane0_rows']}/"
        f"{metrics['fault_matrix']['lane1_rows']}",
        "lifecycle_offsets="
        f"{metrics['fault_matrix']['frontier_f0_rows']}/"
        f"{metrics['fault_matrix']['frontier_f2_rows']}/"
        f"{metrics['fault_matrix']['frontier_f4_rows']}/"
        f"{metrics['fault_matrix']['frontier_f6_rows']}",
        f"compressed_control_rows={metrics['compressed_control']['rows']}",
        "compressed_control_terminal_squash_poison="
        f"{metrics['compressed_control']['terminal_rows']}/"
        f"{metrics['compressed_control']['squash_rows']}/"
        f"{metrics['compressed_control']['poison_rows']}",
        f"lifecycle_manifest_rows={len(result['manifests']['lifecycle_rows'])}",
        f"dispatch_stall_rows={metrics['dispatch_stall']['rows']}",
        f"compile_success_rtl_variants={variants['compile_success']}",
        f"dynamic_rejected_rtl_variants={variants['dynamic_rejected']}",
        f"module_aggregate={module['passed']}/{module['required']}",
        "production_rtl_changed=false",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[IFU-TVAL-G1-GATE] PASS",
        "",
    ))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--decoder-log", type=pathlib.Path, required=True)
    parser.add_argument("--page-end-log", type=pathlib.Path, required=True)
    parser.add_argument("--fifo-log", type=pathlib.Path, required=True)
    parser.add_argument("--capture-log", type=pathlib.Path, required=True)
    parser.add_argument("--arbiter-log", type=pathlib.Path, required=True)
    parser.add_argument("--pending-log", type=pathlib.Path, required=True)
    parser.add_argument("--csr-log", type=pathlib.Path, required=True)
    parser.add_argument("--lifecycle-log", type=pathlib.Path, required=True)
    parser.add_argument("--module-summary", type=pathlib.Path, required=True)
    parser.add_argument("--variant-summary", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--raw-log", type=pathlib.Path, required=True)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)
    result = build(
        root=root,
        decoder_log=safe_file(root, args.decoder_log),
        page_end_log=safe_file(root, args.page_end_log),
        fifo_log=safe_file(root, args.fifo_log),
        capture_log=safe_file(root, args.capture_log),
        arbiter_log=safe_file(root, args.arbiter_log),
        pending_log=safe_file(root, args.pending_log),
        csr_log=safe_file(root, args.csr_log),
        lifecycle_log=safe_file(root, args.lifecycle_log),
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
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    print(raw_summary(result), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
