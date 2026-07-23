#!/usr/bin/env python3
"""Build fail-closed local RV64 IFU-FETCH-G2 current-design evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-ifu-fetch-provenance-evidence-v1"
VARIANT_SCHEMA = "npc-rv64-ifu-fetch-provenance-rtl-variants-v1"
RUN_ID = "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design"
CANONICAL_COMMAND = "make -C npc/rv64 check-ifu-fetch-provenance"
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_ifu_fetch", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

VARIANT_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-ifu-fetch-variants.py"
VARIANT_SPEC = importlib.util.spec_from_file_location(
    "ifu_fetch_provenance_variants", VARIANT_RUNNER)
assert VARIANT_SPEC is not None and VARIANT_SPEC.loader is not None
variant_model = importlib.util.module_from_spec(VARIANT_SPEC)
sys.modules[VARIANT_SPEC.name] = variant_model
VARIANT_SPEC.loader.exec_module(variant_model)

PAGE_SUMMARY_RE = re.compile(
    r"^\[G2-CURRENT-DESIGN\] matrix_rows=(\d+) fault_rows=(\d+) "
    r"F2=(\d+) F4=(\d+) F6=(\d+) stall_rows=(\d+) "
    r"stall_cycles=(\d+) post_accept_quiet_cycles=(\d+) "
    r"payload_stability=(\d+) stale_prefill=(\d+) PASS$",
    re.MULTILINE,
)
RAW_SUMMARY_RE = re.compile(
    r"^\[G2-RAW-FAULT-SUMMARY\] F2=(\d+) F4=(\d+) F6=(\d+) "
    r"total=(\d+)$",
    re.MULTILINE,
)
PREFILL_RE = re.compile(
    r"^\[G2-STALE-PREFILL\] pc=([0-9a-f]{16}) raw=([0-9a-f]{16}) "
    r"no_reset_next=(\d+) PASS$",
    re.MULTILINE,
)
POSITIVE_CONTROL_RE = re.compile(
    r"^\[G2-POSITIVE-CONTROL\] instruction_ar=(\d+) "
    r"cache_fill=(\d+) sram_write=(\d+) PASS$",
    re.MULTILINE,
)
BRIDGE_F0_RE = re.compile(
    r"^\[G2-BRIDGE-F0\] split=(\d+) raw_zero=(\d+) "
    r"decoded_fault=(\d+)/(\d+) sanitized=(\d+)/(\d+) "
    r"instruction_ar=(\d+) stall_cycles=(\d+) "
    r"post_accept_quiet_cycles=(\d+) younger_ar=(\d+) "
    r"cache_fill=(\d+) sram_write=(\d+) PASS$",
    re.MULTILINE,
)
MATRIX_RE = re.compile(
    r"^\[G2-MATRIX\] (.+?) pc=([0-9a-f]{16}) raw=([01]+)/([01]+) "
    r"decoded=([01]+)/([01]+) expected=([01]+)/([01]+)$",
    re.MULTILINE,
)
RAW_OWNER_RE = re.compile(
    r"^\[G2-RAW-FAULT-OWNER\] (.+?) F=(\d+) split=(\d+) "
    r"prefix_ok=(\d+) tail_zero=(\d+) inst_ar=(\d+) "
    r"monitor_cycles=(\d+) frontier_cycles=(\d+) younger_ar=(\d+) "
    r"cache_fill=(\d+) sram_write=(\d+) raw=([0-9a-f]{16})$",
    re.MULTILINE,
)
POST_ACCEPT_RE = re.compile(
    r"^\[G2-POST-ACCEPT-QUIET\] (.+?) cycles=(\d+) younger_ar=(\d+) "
    r"cache_fill=(\d+) sram_write=(\d+) PASS$",
    re.MULTILINE,
)
DECODE_POISON_RE = re.compile(
    r"^\[G2-DECODE-POISON\] split=(\d+) resp=(\d+) sanitized=(\d+) "
    r"forged=(\d+) PASS$",
    re.MULTILINE,
)
DECODE_F0_RE = re.compile(
    r"^\[G2-DECODE-F0\] split=(\d+) resp=(\d+)/(\d+) "
    r"sanitized=(\d+)/(\d+) tval=pc PASS$",
    re.MULTILINE,
)

EXPECTED_MATRIX = {
    "G2 FFA C+C": ("0000000000004ffa", "0", "0", "0", "0"),
    "G2 FFA C+32": ("0000000000004ffa", "0", "0", "0", "0"),
    "G2 FFA 32+C": ("0000000000004ffa", "0", "0", "0", "0"),
    "G2 FFA 32+32": ("0000000000004ffa", "0", "10", "0", "10"),
    "G2 FFC C+C": ("0000000000004ffc", "0", "0", "0", "0"),
    "G2 FFC C+32": ("0000000000004ffc", "0", "10", "0", "10"),
    "G2 FFC 32+C": ("0000000000004ffc", "0", "10", "0", "10"),
    "G2 FFC 32+32": ("0000000000004ffc", "0", "10", "0", "10"),
    "G2 FFE C+C tail-garbage-C": (
        "0000000000004ffe", "0", "10", "0", "10"),
    "G2 FFE C+32": ("0000000000004ffe", "0", "10", "0", "10"),
    "G2 FFE 32+C": ("0000000000004ffe", "0", "10", "10", "10"),
    "G2 FFE 32+32": ("0000000000004ffe", "0", "10", "10", "10"),
    "G2 FFE C+32 after stale prefill": (
        "0000000000004ffe", "0", "10", "0", "10"),
}
EXPECTED_FAULT_ROWS = {
    "G2 FFA 32+32": (6, 3, 30, "0000009300100093"),
    "G2 FFC C+32": (4, 2, 28, "0000000000930001"),
    "G2 FFC 32+C": (4, 2, 28, "0000000000100093"),
    "G2 FFC 32+32": (4, 2, 28, "0000000000100093"),
    "G2 FFE C+C tail-garbage-C": (2, 1, 26, "0000000000000001"),
    "G2 FFE C+32": (2, 1, 26, "0000000000000001"),
    "G2 FFE 32+C": (2, 1, 26, "0000000000000093"),
    "G2 FFE 32+32": (2, 1, 26, "0000000000000093"),
    "G2 FFE C+32 after stale prefill": (
        2, 1, 26, "0000000000000001"),
}
PAGE_METRICS = {
    "matrix_rows": 13,
    "fault_rows": 9,
    "frontier_f0_rows": 1,
    "frontier_f2_rows": 5,
    "frontier_f4_rows": 3,
    "frontier_f6_rows": 1,
    "stall_rows": 9,
    "stall_cycles": 18,
    "post_accept_quiet_cycles": 18,
    "payload_stability": 1,
    "stale_prefill": 1,
    "positive_instruction_ar": 4,
    "positive_cache_fill": 1,
    "positive_sram_write": 1,
    "fault_instruction_ar_after_f0": 0,
    "fault_younger_ar": 0,
    "fault_cache_fill": 0,
    "fault_sram_write": 0,
}
DECODE_METRICS = {
    "poison_split": 4,
    "poison_resp": 2,
    "poison_sanitized": 1,
    "poison_forged": 0,
    "f0_split": 0,
    "f0_slot0_resp": 2,
    "f0_slot1_resp": 2,
    "f0_slot0_sanitized": 1,
    "f0_slot1_sanitized": 1,
    "f0_tval_is_pc": 1,
}
INVARIANTS = {
    "frontier_is_first_failing_halfword_offset": True,
    "frontier_reference_is_computed_from_pc_not_dut_split": True,
    "successful_prefix_bytes_are_retained": True,
    "fault_suffix_bytes_are_zero": True,
    "f0_has_no_successful_instruction_bytes": True,
    "decoder_reads_length_only_after_prefix_success": True,
    "decoder_uses_complete_instruction_byte_range": True,
    "faulted_instruction_is_sanitized_to_nop": True,
    "slot1_has_no_independent_owner_after_slot0_fault": True,
    "stalled_response_tuple_is_stable": True,
    "stalled_response_blocks_alternate_request_accept": True,
    "fault_frontier_blocks_younger_address_offers": True,
    "fault_transaction_never_fills_packet_cache": True,
    "fault_transaction_never_writes_packet_sram": True,
    "post_accept_quiet_window_excludes_late_side_effects": True,
    "positive_control_observes_ar_fill_and_sram_write": True,
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


def one_match(regex: re.Pattern[str], text: str, label: str) -> re.Match[str]:
    matches = list(regex.finditer(text))
    if len(matches) != 1:
        raise ValueError(f"{label}: expected one exact semantic marker")
    return matches[0]


def parse_page_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_page_end_fault", "page-end log")

    summary = tuple(int(value) for value in one_match(
        PAGE_SUMMARY_RE, text, "page-end summary").groups())
    if summary != (13, 9, 5, 3, 1, 9, 18, 18, 1, 1):
        raise ValueError(f"page-end summary inventory drifted: {summary}")
    raw_summary = tuple(int(value) for value in one_match(
        RAW_SUMMARY_RE, text, "raw fault summary").groups())
    if raw_summary != (5, 3, 1, 9):
        raise ValueError(f"raw fault summary drifted: {raw_summary}")

    matrix: dict[str, tuple[str, str, str, str, str]] = {}
    for match in MATRIX_RE.finditer(text):
        name, pc, raw0, raw1, dec0, dec1, exp0, exp1 = match.groups()
        if name in matrix or (dec0, dec1) != (exp0, exp1):
            raise ValueError(f"matrix row is duplicate or self-contradictory: {name}")
        matrix[name] = (pc, raw0, raw1, dec0, dec1)
    if matrix != EXPECTED_MATRIX:
        raise ValueError("page-end C/32 matrix inventory is incomplete")

    owners: dict[str, tuple[int, int, int, str]] = {}
    for match in RAW_OWNER_RE.finditer(text):
        (name, frontier, split, prefix_ok, tail_zero, inst_ar,
         monitor_cycles, frontier_cycles, younger_ar, cache_fill,
         sram_write, raw) = match.groups()
        if name in owners:
            raise ValueError(f"duplicate raw fault owner row: {name}")
        values = tuple(map(int, (
            frontier, split, prefix_ok, tail_zero, inst_ar,
            monitor_cycles, frontier_cycles, younger_ar, cache_fill,
            sram_write,
        )))
        expected = EXPECTED_FAULT_ROWS.get(name)
        if expected is None:
            raise ValueError(f"unexpected raw fault owner row: {name}")
        exp_frontier, exp_ar, exp_monitor, exp_raw = expected
        if values != (
            exp_frontier, exp_frontier, 1, 1, exp_ar,
            exp_monitor, 5, 0, 0, 0,
        ) or raw != exp_raw:
            raise ValueError(f"raw fault owner metrics drifted: {name}")
        owners[name] = (exp_frontier, exp_ar, exp_monitor, raw)
    if set(owners) != set(EXPECTED_FAULT_ROWS):
        raise ValueError("raw fault owner row inventory is incomplete")

    post_rows: dict[str, tuple[int, int, int, int]] = {}
    for match in POST_ACCEPT_RE.finditer(text):
        name, cycles, younger, fill, write = match.groups()
        if name in post_rows:
            raise ValueError(f"duplicate post-accept row: {name}")
        post_rows[name] = tuple(map(int, (cycles, younger, fill, write)))
    if set(post_rows) != set(EXPECTED_FAULT_ROWS) or any(
        row != (2, 0, 0, 0) for row in post_rows.values()
    ):
        raise ValueError("post-accept quiet-window inventory is incomplete")

    prefill = one_match(PREFILL_RE, text, "stale prefill").groups()
    if prefill != ("0000000000006000", "8877665744332213", "1"):
        raise ValueError(f"stale prefill marker drifted: {prefill}")
    positive = tuple(int(value) for value in one_match(
        POSITIVE_CONTROL_RE, text, "positive control").groups())
    if positive != (4, 1, 1):
        raise ValueError(f"positive control is vacuous: {positive}")
    f0 = tuple(int(value) for value in one_match(
        BRIDGE_F0_RE, text, "bridge F0").groups())
    if f0 != (0, 1, 2, 2, 1, 1, 0, 2, 2, 0, 0, 0):
        raise ValueError(f"bridge F0 marker drifted: {f0}")
    return dict(PAGE_METRICS)


def parse_decode_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_packet_decode", "packet-decode log")
    poison = tuple(int(value) for value in one_match(
        DECODE_POISON_RE, text, "decode poison").groups())
    if poison != (4, 2, 1, 0):
        raise ValueError(f"decode poison marker drifted: {poison}")
    f0 = tuple(int(value) for value in one_match(
        DECODE_F0_RE, text, "decode F0").groups())
    if f0 != (0, 2, 2, 1, 1):
        raise ValueError(f"decode F0 marker drifted: {f0}")
    return dict(DECODE_METRICS)


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
    aggregate_ok = (
        payload.get("schema") == VARIANT_SCHEMA
        and payload.get("suite_run_id") == RUN_ID
        and payload.get("required") == len(specs)
        and payload.get("compile_success") == len(specs)
        and payload.get("dynamic_rejected") == len(specs)
        and payload.get("source_unchanged") is True
        and payload.get("source_sha256_before")
            == payload.get("source_sha256_after")
        and set(by_name) == set(specs)
    )
    if not aggregate_ok:
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
        log_ok = (
            log_path is not None and set(log) == {"path", "sha256"}
            and log.get("sha256") == sha256_file(log_path)
        )
        row_ok = (
            row.get("debt_id") == "IFU-FETCH-G2"
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
            and log_ok
            and variant_model.TRANSIENT_DIR_TOKEN in log_text
            and "/tmp/rv64-v9h-" not in log_text
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
    bridge = safe_file(
        root, root / "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
    ).read_text(encoding="utf-8")
    decode = safe_file(
        root, root / "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v"
    ).read_text(encoding="utf-8")
    page_tb = safe_file(
        root, root / "npc/rv64/testbench/tests/tb_ooo_fetch_page_end_fault.sv"
    ).read_text(encoding="utf-8")
    decode_tb = safe_file(
        root, root / "npc/rv64/testbench/tests/tb_ooo_fetch_packet_decode.sv"
    ).read_text(encoding="utf-8")

    anchors = {
        "bridge_registered_frontier_output": (
            bridge,
            "assign fetch_rsp_resp0_bytes_o = cache_result_window_w ? 3'd4 : resp0_bytes_q;",
        ),
        "bridge_new_transaction_clears_packet_scratch": (
            bridge, "fetch_data_q <= {`XLEN{1'b0}};"),
        "bridge_halfword_lane_two_is_exact": (
            bridge, "3'd2: insert_fetch_halfword[31:16] = halfword;"),
        "bridge_cache_fill_requires_complete_non_cross_packet": (
            bridge, "!fetch_more_after_r_w && !packet_cross_page_q;"),
        "decoder_uses_strict_half_open_end_boundary": (
            decode, "end_byte > {2'b00, resp0_bytes}"),
        "decoder_slot1_start_uses_slot0_length": (
            decode, "wire [3:0] dec1_start_byte_w = dec0_len_bytes_w;"),
        "decoder_slot0_full_range_sanitizes": (
            decode, "assign dec0_inst_o = (dec0_range_resp_w != RESP_OK)"),
        "decoder_slot1_effective_range_sanitizes": (
            decode, "assign dec1_inst_o = (dec1_effective_resp_w != RESP_OK)"),
        "page_tb_independent_page_boundary_reference": (
            page_tb, "first_page_bytes = 4096 - pc[11:0];"),
        "page_tb_independent_frontier_reference": (
            page_tb, "expected_frontier = first_page_bytes[2:0];"),
        "page_tb_stale_prefill_is_no_reset": (
            page_tb, "[G2-STALE-PREFILL]"),
        "page_tb_positive_monitor_is_non_vacuous": (
            page_tb, "[G2-POSITIVE-CONTROL]"),
        "page_tb_bridge_f0_is_reachable": (page_tb, "[G2-BRIDGE-F0]"),
        "page_tb_post_accept_quiet_is_explicit": (
            page_tb, "[G2-POST-ACCEPT-QUIET]"),
        "decode_tb_fault_tail_poison_is_explicit": (
            decode_tb, "[G2-DECODE-POISON]"),
        "decode_tb_f0_is_explicit": (decode_tb, "[G2-DECODE-F0]"),
    }
    for name, (text, anchor) in anchors.items():
        if text.count(anchor) < 1:
            raise ValueError(f"static contract anchor drifted: {name}")
    return {name: True for name in anchors}


SOURCE_BINDING_PATHS = (
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/cache/OooFetchPacketCache.v",
    "npc/rv64/design/specs/ooo-fetch-axi-bridge.md",
    "npc/rv64/testbench/tests/tb_ooo_fetch_page_end_fault.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_packet_decode.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/testbench/scripts/check_ifu_icache_coherence_contract.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{RUN_ID}/contract.md",
    f".github/task-runs/{RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{RUN_ID}/review-summary.md",
    f".github/task-runs/{RUN_ID}/run-focused.sh",
    f".github/task-runs/{RUN_ID}/run-ifu-fetch-variants.py",
    (
        f".github/task-runs/{RUN_ID}/subagent-contracts/"
        "v9h-ifu-fetch-coverage-review-v1.json"
    ),
    "npc/rv64/eval/ppa/tools/ifu_fetch_provenance_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_ifu_fetch_provenance_evidence.py",
)


def build(
    *, root: pathlib.Path, decode_log: pathlib.Path, page_log: pathlib.Path,
    module_summary: pathlib.Path, variant_summary: pathlib.Path,
) -> dict[str, Any]:
    metrics = {
        "page_end": parse_page_log(page_log),
        "packet_decode": parse_decode_log(decode_log),
    }
    module = parse_module_aggregate(root, module_summary)
    variants = validate_variants(root, variant_summary)
    static = validate_static_contract(root)
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
        "scope": (
            "local RV64 fetch bridge to packet decoder first-failing-halfword "
            "byte provenance for page faults"
        ),
        "metrics": metrics,
        "invariants": INVARIANTS,
        "focused_tests": {
            "page_end": {
                "status": "PASS", "log_sha256": sha256_file(page_log)},
            "packet_decode": {
                "status": "PASS", "log_sha256": sha256_file(decode_log)},
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
            artifact(root, page_log, "ifu_fetch_page_end_focused_log"),
            artifact(root, decode_log, "ifu_fetch_packet_decode_focused_log"),
            artifact(root, module_summary, "module_aggregate_summary"),
            artifact(root, variant_summary, "rtl_variant_summary"),
        ],
        "claim": {
            "architecture_debts": {"IFU-FETCH-G2": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def raw_summary(result: dict[str, Any]) -> str:
    page = result["metrics"]["page_end"]
    decode = result["metrics"]["packet_decode"]
    variants = result["variant_audit"]
    module = result["module_aggregate"]
    bridge = "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
    decoder = "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v"
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"canonical_command={result['canonical_command']}",
        f"matrix_rows={page['matrix_rows']}",
        f"fault_rows={page['fault_rows']}",
        f"frontier_f0_rows={page['frontier_f0_rows']}",
        f"frontier_f2_rows={page['frontier_f2_rows']}",
        f"frontier_f4_rows={page['frontier_f4_rows']}",
        f"frontier_f6_rows={page['frontier_f6_rows']}",
        f"stall_cycles={page['stall_cycles']}",
        f"post_accept_quiet_cycles={page['post_accept_quiet_cycles']}",
        f"positive_instruction_ar={page['positive_instruction_ar']}",
        f"positive_cache_fill={page['positive_cache_fill']}",
        f"positive_sram_write={page['positive_sram_write']}",
        f"fault_younger_ar={page['fault_younger_ar']}",
        f"fault_cache_fill={page['fault_cache_fill']}",
        f"fault_sram_write={page['fault_sram_write']}",
        f"decode_poison_forged={decode['poison_forged']}",
        f"decode_f0_split={decode['f0_split']}",
        f"compile_success_rtl_variants={variants['compile_success']}",
        f"dynamic_rejected_rtl_variants={variants['dynamic_rejected']}",
        "bridge_rtl_variants="
        f"{variants['by_source'][bridge]['dynamic_rejected']}/"
        f"{variants['by_source'][bridge]['required']}",
        "decoder_rtl_variants="
        f"{variants['by_source'][decoder]['dynamic_rejected']}/"
        f"{variants['by_source'][decoder]['required']}",
        f"module_aggregate={module['passed']}/{module['required']}",
        "production_rtl_changed=false",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[IFU-FETCH-G2-GATE] PASS",
        "",
    ))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--decode-log", type=pathlib.Path, required=True)
    parser.add_argument("--page-log", type=pathlib.Path, required=True)
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
        decode_log=safe_file(root, args.decode_log),
        page_log=safe_file(root, args.page_log),
        module_summary=safe_file(root, args.module_summary),
        variant_summary=safe_file(root, args.variant_summary),
    )
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    print(
        f"[IFU-FETCH-EVIDENCE] design_id={result['design_id']} focused=2/2 "
        f"variants={result['variant_audit']['dynamic_rejected']}/"
        f"{result['variant_audit']['required']} status=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
