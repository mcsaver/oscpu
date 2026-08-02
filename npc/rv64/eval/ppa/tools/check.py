#!/usr/bin/env python3
"""Fail-closed structural and promotion checker for NPC RV64 PPA manifests."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import pathlib
import re
import sys
from typing import Any

import architecture_hard_gates as architecture_hard_gates_tool


DESIGN_BINDING_SCHEMA = "npc-rv64-design-binding-v1"
COHORT_FINGERPRINT_SCHEMA = "npc-rv64-ppa-cohort-fingerprint-v1"
COHORT_SHARED_ARTIFACT_KINDS = (
    "config_manifest",
    "required_test_manifest",
    "coremark_image",
    "dhrystone_image",
)
CLAIM_BINDING_KEYS = (
    "schema",
    "policy",
    "policy_id",
    "cohort_id",
    "claim_tier",
    "provenance",
    "architecture_contract",
    "functional",
    "performance",
    "timing",
    "area",
    "power",
)
MAX_RAW_LOG_BYTES = 16 * 1024 * 1024
MAX_COUNTER = (1 << 64) - 1
ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
PERFORMANCE_EVIDENCE_SCHEMAS = {
    "npc-rv64-performance-evidence-v2",
    "npc-rv64-performance-evidence-v3",
    "npc-rv64-performance-evidence-v4",
    "npc-rv64-performance-evidence-v5",
    "npc-rv64-performance-evidence-v6",
    "npc-rv64-performance-evidence-v7",
    "npc-rv64-performance-evidence-v8",
}
PERFORMANCE_COUNTER_SCOPES_BY_SCHEMA = {
    "npc-rv64-performance-evidence-v2": {
        "coremark": "whole_program",
        "dhrystone_10000": "pc_bounded_region_v1",
    },
    "npc-rv64-performance-evidence-v3": {
        "coremark": "pc_bounded_region_v1",
        "dhrystone_10000": "pc_bounded_region_v1",
    },
    "npc-rv64-performance-evidence-v4": {
        "coremark": "pc_bounded_region_v1",
        "dhrystone_10000": "pc_bounded_region_v1",
    },
    "npc-rv64-performance-evidence-v5": {
        "coremark": "pc_bounded_region_v1",
        "dhrystone_10000": "pc_bounded_region_v1",
    },
    "npc-rv64-performance-evidence-v6": {
        "coremark": "pc_bounded_region_v1",
        "dhrystone_10000": "pc_bounded_region_v1",
    },
    "npc-rv64-performance-evidence-v7": {
        "coremark": "pc_bounded_region_v1",
        "dhrystone_10000": "pc_bounded_region_v1",
    },
    "npc-rv64-performance-evidence-v8": {
        "coremark": "pc_bounded_region_v1",
        "dhrystone_10000": "pc_bounded_region_v1",
    },
}
# Keep the parser default backward-compatible with v2 callers. Promotion policy
# selects v3 explicitly and therefore never relies on this default.
PERFORMANCE_V2_COUNTER_SCOPES = PERFORMANCE_COUNTER_SCOPES_BY_SCHEMA[
    "npc-rv64-performance-evidence-v2"]
SUPPORTED_COUNTER_SCOPES_BY_BENCHMARK = {
    "coremark": {"whole_program", "pc_bounded_region_v1"},
    "dhrystone_10000": {"pc_bounded_region_v1"},
}
FIXED_REGION_CONTRACTS = {
    "coremark": {
        "display": "CoreMark",
        "start_pc": 0x00000000800017A8,
        "stop_pc": 0x00000000800017B0,
        "start_hits": 1,
        "stop_hits": 1,
    },
    "dhrystone_10000": {
        "display": "Dhrystone",
        "start_pc": 0x0000000080000334,
        "stop_pc": 0x000000008000047C,
        "start_hits": 10000,
        "stop_hits": 1,
    },
}


def repo_root(start: pathlib.Path) -> pathlib.Path:
    for path in (start, *start.parents):
        if (path / ".git").exists():
            return path
    raise RuntimeError("cannot locate repository root")


def reject_json_constant(value: str) -> None:
    raise ValueError(f"non-finite JSON constant is forbidden: {value}")


def read_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle, parse_constant=reject_json_constant)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: top-level JSON must be an object")
    return value


def workspace_file(root: pathlib.Path, rel: Any, label: str) -> pathlib.Path:
    if not isinstance(rel, str) or not rel:
        raise ValueError(f"{label} path is not workspace-relative: {rel!r}")
    pure = pathlib.PurePosixPath(rel)
    if ("\\" in rel or pure.is_absolute() or ".." in pure.parts
            or pure.as_posix() != rel):
        raise ValueError(f"{label} path is not workspace-relative: {rel!r}")
    candidate = root / rel
    cursor = root
    for part in pure.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise ValueError(f"{label} path traverses a symlink: {rel}")
    resolved = candidate.resolve(strict=True)
    if not resolved.is_relative_to(root.resolve()) or not resolved.is_file():
        raise ValueError(f"{label} path escapes workspace or is not a file: {rel}")
    return resolved


def digest(path: pathlib.Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def canonical_digest(value: Any) -> str:
    encoded = json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def is_sha256(value: Any) -> bool:
    return (
        isinstance(value, str)
        and len(value) == 64
        and all(char in "0123456789abcdef" for char in value)
    )


def read_json_object(path: pathlib.Path, label: str) -> dict[str, Any]:
    try:
        return read_json(path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        raise ValueError(f"{label} must be a JSON object: {exc}") from exc


def read_sha256_manifest(path: pathlib.Path, label: str) -> dict[str, str]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as exc:
        raise ValueError(f"{label} must be a UTF-8 sha256sum manifest: {exc}") from exc
    if not lines:
        raise ValueError(f"{label} sha256sum manifest is empty")
    result: dict[str, str] = {}
    for line_number, line in enumerate(lines, start=1):
        if line.count("  ") != 1:
            raise ValueError(
                f"{label}:{line_number}: expected '64hex  relative/path'")
        sha256, rel = line.split("  ", 1)
        pure = pathlib.PurePosixPath(rel)
        if (not is_sha256(sha256) or not rel or "\\" in rel
                or pure.is_absolute() or ".." in pure.parts
                or rel in result):
            raise ValueError(
                f"{label}:{line_number}: invalid or duplicate entry")
        result[rel] = sha256
    return result


def finite_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def strict_nonnegative_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def strict_positive_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def _unique_raw_line(
    lines: list[str],
    selector: re.Pattern[str],
    parser: re.Pattern[str],
    field: str,
    label: str,
) -> re.Match[str]:
    candidates = [line for line in lines if selector.search(line)]
    if len(candidates) != 1:
        raise ValueError(
            f"{label}: expected exactly one {field}, found {len(candidates)}")
    match = parser.fullmatch(candidates[0])
    if match is None:
        raise ValueError(f"{label}: malformed {field}")
    return match


def _bounded_counter(value: str, field: str, label: str) -> int:
    if len(value) > 20:
        raise ValueError(f"{label}: {field} is outside uint64 range")
    parsed = int(value, 10)
    if parsed <= 0 or parsed > MAX_COUNTER:
        raise ValueError(f"{label}: {field} is outside uint64 range")
    return parsed


def _bounded_nonnegative_counter(value: str, field: str, label: str) -> int:
    if len(value) > 20:
        raise ValueError(f"{label}: {field} is outside uint64 range")
    parsed = int(value, 10)
    if parsed < 0 or parsed > MAX_COUNTER:
        raise ValueError(f"{label}: {field} is outside uint64 range")
    return parsed


def _hex_uint64(value: Any, field: str, label: str) -> int:
    if (not isinstance(value, str)
            or re.fullmatch(r"0x[0-9a-fA-F]{1,16}", value) is None):
        raise ValueError(f"{label}: {field} must be a uint64 hex string")
    return int(value, 16)


def policy_region_contract_errors(
    benchmark: str, contract: dict[str, Any], evidence_schema: str
) -> list[str]:
    """Validate the promotion-selected fixed-PC contract for one benchmark."""
    expected = FIXED_REGION_CONTRACTS[benchmark]
    display = expected["display"]
    region = contract.get("region")
    if not isinstance(region, dict):
        return [f"policy {display} region contract is missing"]
    errors: list[str] = []
    try:
        start_pc = _hex_uint64(
            region.get("start_pc"), "start_pc", f"policy {display}")
        stop_pc = _hex_uint64(
            region.get("stop_pc"), "stop_pc", f"policy {display}")
    except ValueError as exc:
        errors.append(str(exc))
    else:
        if (start_pc != expected["start_pc"]
                or stop_pc != expected["stop_pc"]):
            errors.append(f"policy {display} region PCs are invalid")
    if region.get("start_marker_semantics") != "first_committed_hit":
        errors.append(f"policy {display} start semantics are invalid")
    if (evidence_schema in {
            "npc-rv64-performance-evidence-v4",
            "npc-rv64-performance-evidence-v5",
            "npc-rv64-performance-evidence-v6",
            "npc-rv64-performance-evidence-v7",
            "npc-rv64-performance-evidence-v8"}
            and region.get("final_marker_semantics") !=
            "termination_time_total_hits"):
        errors.append(f"policy {display} final semantics are invalid")
    start_hits = region.get("start_hits")
    stop_hits = region.get("stop_hits")
    if (not strict_positive_int(start_hits)
            or not strict_positive_int(stop_hits)
            or start_hits != expected["start_hits"]
            or stop_hits != expected["stop_hits"]):
        errors.append(f"policy {display} region hit counts are invalid")
    return errors


def parse_raw_benchmark_log(
    path: pathlib.Path,
    benchmark: str,
    counter_scope: str | None = None,
    scope_contract: dict[str, Any] | None = None,
    evidence_schema: str | None = None,
    performance_counter_contract: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Parse one simulator benchmark log using unique authoritative markers."""
    label = f"{benchmark} raw log"
    supported_scopes = SUPPORTED_COUNTER_SCOPES_BY_BENCHMARK.get(benchmark)
    if supported_scopes is None:
        raise ValueError(f"unsupported raw benchmark log: {benchmark}")
    if counter_scope is None:
        counter_scope = PERFORMANCE_V2_COUNTER_SCOPES[benchmark]
    if evidence_schema is None:
        evidence_schema = "npc-rv64-performance-evidence-v3"
    if evidence_schema not in PERFORMANCE_EVIDENCE_SCHEMAS:
        raise ValueError(
            f"{label}: unsupported performance evidence schema "
            f"{evidence_schema!r}")
    if counter_scope not in supported_scopes:
        raise ValueError(
            f"{label}: unsupported counter scope {counter_scope!r}")
    if scope_contract is None:
        scope_contract = {}
    if not isinstance(scope_contract, dict):
        raise ValueError(f"{label}: scope contract must be an object")
    counter_unknown_ratio_max: float | None = None
    if evidence_schema in {
            "npc-rv64-performance-evidence-v5",
            "npc-rv64-performance-evidence-v6",
            "npc-rv64-performance-evidence-v7",
            "npc-rv64-performance-evidence-v8"}:
        if not isinstance(performance_counter_contract, dict):
            raise ValueError(
                f"{label}: performance counter contract is missing")
        counter_contract_versions = {
            "npc-rv64-performance-evidence-v5": (
                "npc-rv64-performance-counter-schema-v1",
                "npc-rv64-performance-counter-v1"),
            "npc-rv64-performance-evidence-v6": (
                "npc-rv64-performance-counter-schema-v2",
                "npc-rv64-performance-counter-v2"),
            "npc-rv64-performance-evidence-v7": (
                "npc-rv64-performance-counter-schema-v3",
                "npc-rv64-performance-counter-v3"),
            "npc-rv64-performance-evidence-v8": (
                "npc-rv64-performance-counter-schema-v4",
                "npc-rv64-performance-counter-v4"),
        }
        (expected_counter_contract_schema,
         expected_counter_marker_schema) = counter_contract_versions[
             evidence_schema]
        if (performance_counter_contract.get("schema") !=
                expected_counter_contract_schema):
            raise ValueError(
                f"{label}: unsupported performance counter contract schema")
        if (performance_counter_contract.get("marker_schema") !=
                expected_counter_marker_schema):
            raise ValueError(
                f"{label}: performance counter marker schema mismatch")
        if performance_counter_contract.get("retire_width") != 2:
            raise ValueError(
                f"{label}: performance counter retire width mismatch")
        counter_qualification = performance_counter_contract.get(
            "qualification")
        if not isinstance(counter_qualification, dict):
            raise ValueError(
                f"{label}: performance counter qualification is missing")
        counter_unknown_ratio_max = counter_qualification.get(
            "unknown_or_unclassified_cycle_ratio_max")
        if (not finite_number(counter_unknown_ratio_max)
                or counter_unknown_ratio_max < 0
                or counter_unknown_ratio_max > 1):
            raise ValueError(
                f"{label}: performance counter unknown ratio limit is invalid")
        if (counter_qualification.get(
                "baseline_requires_phase_aligned_boundaries") is not True):
            raise ValueError(
                f"{label}: performance counters require phase-aligned "
                "boundary qualification")
    try:
        size = path.stat().st_size
        if size <= 0 or size > MAX_RAW_LOG_BYTES:
            raise ValueError(
                f"{label}: size must be 1..{MAX_RAW_LOG_BYTES} bytes")
        raw = path.read_bytes()
        text = raw.decode("utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise ValueError(f"{label}: must be a readable UTF-8 file: {exc}") from exc
    if "\x00" in text:
        raise ValueError(f"{label}: NUL bytes are forbidden")
    lines = [ANSI_ESCAPE_RE.sub("", line) for line in text.splitlines()]

    _unique_raw_line(
        lines,
        re.compile(r"HIT GOOD TRAP"),
        re.compile(
            r"\[[^]\r\n]*\bcpu_exec\]\s+npc:\s+HIT GOOD TRAP\s+"
            r"at pc\s*=\s*0x[0-9a-fA-F]+\s*"),
        "GOOD TRAP marker",
        label,
    )
    exit_match = _unique_raw_line(
        lines,
        re.compile(r"report_run_result|exit via ebreak"),
        re.compile(
            r"\[[^]\r\n]*\breport_run_result\]\s+exit via ebreak,\s*"
            r"code=(-?[0-9]+),\s*cycles=([0-9]+),\s*commits=([0-9]+)\s*"),
        "authoritative exit record",
        label,
    )
    exit_text, cycles_text, commits_text = exit_match.groups()
    if len(exit_text.lstrip("-")) > 10:
        raise ValueError(f"{label}: exit code is outside int32 range")
    exit_code = int(exit_text, 10)
    if not -(1 << 31) <= exit_code < (1 << 31):
        raise ValueError(f"{label}: exit code is outside int32 range")
    whole_cycles = _bounded_counter(cycles_text, "cycles", label)
    whole_retired = _bounded_counter(commits_text, "commits", label)
    result: dict[str, Any] = {
        "pass": True,
        "good_trap_count": 1,
        "exit_code": exit_code,
        "counter_scope": counter_scope,
        "cycles": whole_cycles,
        "retired_instructions": whole_retired,
        "whole_program": {
            "cycles": whole_cycles,
            "retired_instructions": whole_retired,
        },
    }

    if benchmark == "coremark":
        _unique_raw_line(
            lines,
            re.compile(r"^\s*CoreMark\s+PASS\b"),
            re.compile(r"\s*CoreMark\s+PASS\s+[0-9]+\s+Marks\s*"),
            "CoreMark PASS marker",
            label,
        )
        iterations = _unique_raw_line(
            lines,
            re.compile(r"^\s*Iterations\s*:"),
            re.compile(r"\s*Iterations\s*:\s*([0-9]+)\s*"),
            "CoreMark iterations",
            label,
        ).group(1)
        crc = _unique_raw_line(
            lines,
            re.compile(r"^\s*\[0\]crcfinal\s*:"),
            re.compile(r"\s*\[0\]crcfinal\s*:\s*(0x[0-9a-fA-F]{4})\s*"),
            "CoreMark final CRC",
            label,
        ).group(1)
        result["iterations"] = _bounded_counter(
            iterations, "iterations", label)
        result["crc"] = crc.lower()
        benchmark_display = "CoreMark"
    elif benchmark == "dhrystone_10000":
        _unique_raw_line(
            lines,
            re.compile(r"^\s*Dhrystone\s+PASS\b"),
            re.compile(r"\s*Dhrystone\s+PASS\s+[0-9]+\s+Marks\s*"),
            "Dhrystone PASS marker",
            label,
        )
        runs = _unique_raw_line(
            lines,
            re.compile(r"^\s*Trying\b.*\bruns through Dhrystone"),
            re.compile(
                r"\s*Trying\s+([0-9]+)\s+runs through Dhrystone\.\s*"),
            "Dhrystone run count",
            label,
        ).group(1)
        result["runs"] = _bounded_counter(runs, "runs", label)
        benchmark_display = "Dhrystone"
    else:
        raise ValueError(f"unsupported raw benchmark log: {benchmark}")

    if counter_scope == "whole_program":
        return result
    region_contract = scope_contract.get("region")
    if not isinstance(region_contract, dict):
        raise ValueError(f"{label}: pc-bounded region contract is missing")
    expected_start_pc = _hex_uint64(
        region_contract.get("start_pc"), "start_pc", label)
    expected_stop_pc = _hex_uint64(
        region_contract.get("stop_pc"), "stop_pc", label)
    if region_contract.get("start_marker_semantics") != "first_committed_hit":
        raise ValueError(
            f"{label}: start marker must select the first committed hit")
    expected_start_hits = region_contract.get("start_hits")
    expected_stop_hits = region_contract.get("stop_hits")
    if (not strict_positive_int(expected_start_hits)
            or not strict_positive_int(expected_stop_hits)):
        raise ValueError(f"{label}: region hit contract is invalid")

    region_errors = [
        line for line in lines
        if re.search(r"\bregion_probe\].*\bERROR\b", line)
    ]
    if region_errors:
        raise ValueError(f"{label}: region probe reported an error")

    boundary_parser = (
        r"\[[^]\r\n]*\bregion_probe\]\s+BOUNDARY\s+kind={kind}\s+"
        r"pc=(0x[0-9a-fA-F]{{1,16}})\s+cycle=([0-9]+)\s+"
        r"retired_before=([0-9]+)\s+lane=([0-9]+)\s+"
        r"cycle_retire=([0-9]+)\s*"
    )
    start_match = _unique_raw_line(
        lines,
        re.compile(r"\bBOUNDARY\s+kind=start\b"),
        re.compile(boundary_parser.format(kind="start")),
        f"{benchmark_display} start boundary marker",
        label,
    )
    stop_match = _unique_raw_line(
        lines,
        re.compile(r"\bBOUNDARY\s+kind=end\b"),
        re.compile(boundary_parser.format(kind="end")),
        f"{benchmark_display} stop boundary marker",
        label,
    )
    require_final = evidence_schema in {
        "npc-rv64-performance-evidence-v4",
        "npc-rv64-performance-evidence-v5",
        "npc-rv64-performance-evidence-v6",
        "npc-rv64-performance-evidence-v7",
        "npc-rv64-performance-evidence-v8",
    }
    if require_final:
        region_match = _unique_raw_line(
            lines,
            re.compile(r"\bregion_probe\].*\bFINAL\b"),
            re.compile(
                r"\[[^]\r\n]*\bregion_probe\]\s+FINAL\s+"
                r"schema=([a-zA-Z0-9_-]+)\s+"
                r"counter_scope=([a-zA-Z0-9_-]+)\s+"
                r"complete=([01])\s+termination_rc=(-?[0-9]+)\s+"
                r"start_seen=([01])\s+end_seen=([01])\s+"
                r"start_hits=([0-9]+)\s+end_hits=([0-9]+)\s+"
                r"start_cycle=([0-9]+)\s+end_cycle=([0-9]+)\s+"
                r"cycles=([0-9]+)\s+start_retired=([0-9]+)\s+"
                r"end_retired=([0-9]+)\s+retired=([0-9]+)\s*"),
            f"{benchmark_display} region FINAL marker",
            label,
        )
    else:
        region_match = _unique_raw_line(
            lines,
            re.compile(r"\bregion_probe\].*\bRESULT\b"),
            re.compile(
                r"\[[^]\r\n]*\bregion_probe\]\s+RESULT\s+"
                r"start_hits=([0-9]+)\s+end_hits=([0-9]+)\s+"
                r"start_cycle=([0-9]+)\s+end_cycle=([0-9]+)\s+"
                r"cycles=([0-9]+)\s+start_retired=([0-9]+)\s+"
                r"end_retired=([0-9]+)\s+retired=([0-9]+)\s*"),
            f"{benchmark_display} region result marker",
            label,
        )

    counter_match: re.Match[str] | None = None
    if evidence_schema == "npc-rv64-performance-evidence-v5":
        counter_match = _unique_raw_line(
            lines,
            re.compile(r"\bregion_probe\].*\bCOUNTERS_FINAL\b"),
            re.compile(
                r"\[[^]\r\n]*\bregion_probe\]\s+COUNTERS_FINAL\s+"
                r"schema=([a-zA-Z0-9_-]+)\s+"
                r"complete=([01])\s+available=([01])\s+"
                r"overflow=([01])\s+invalid_events=([0-9]+)\s+"
                r"start_lane=([0-9]+)\s+end_lane=([0-9]+)\s+"
                r"phase_aligned=([01])\s+cycles=([0-9]+)\s+"
                r"cycle_useful=([0-9]+)\s+cycle_rob_empty=([0-9]+)\s+"
                r"cycle_head_not_complete=([0-9]+)\s+"
                r"cycle_exception_redirect=([0-9]+)\s+"
                r"cycle_memory_commit=([0-9]+)\s+"
                r"cycle_serialization=([0-9]+)\s+"
                r"cycle_unknown=([0-9]+)\s+"
                r"slot_capacity=([0-9]+)\s+retired_slots=([0-9]+)\s+"
                r"unused_slots=([0-9]+)\s+"
                r"slot_rob_empty=([0-9]+)\s+"
                r"slot_head_not_complete=([0-9]+)\s+"
                r"slot_exception_redirect=([0-9]+)\s+"
                r"slot_memory_commit=([0-9]+)\s+"
                r"slot_serialization=([0-9]+)\s+"
                r"slot_unknown=([0-9]+)\s+conservation=([01])\s*"),
            f"{benchmark_display} performance COUNTERS_FINAL marker",
            label,
        )
    elif evidence_schema == "npc-rv64-performance-evidence-v6":
        counter_match = _unique_raw_line(
            lines,
            re.compile(r"\bregion_probe\].*\bCOUNTERS_FINAL\b"),
            re.compile(
                r"\[[^]\r\n]*\bregion_probe\]\s+COUNTERS_FINAL\s+"
                r"schema=([a-zA-Z0-9_-]+)\s+"
                r"complete=([01])\s+available=([01])\s+"
                r"overflow=([01])\s+invalid_events=([0-9]+)\s+"
                r"start_lane=([0-9]+)\s+end_lane=([0-9]+)\s+"
                r"phase_aligned=([01])\s+cycles=([0-9]+)\s+"
                r"cycle_useful=([0-9]+)\s+cycle_rob_empty=([0-9]+)\s+"
                r"cycle_head_not_complete=([0-9]+)\s+"
                r"cycle_dependency=([0-9]+)\s+"
                r"cycle_issue_terminal=([0-9]+)\s+"
                r"cycle_execution_latency=([0-9]+)\s+"
                r"cycle_memory_latency=([0-9]+)\s+"
                r"cycle_head_lifecycle_unknown=([0-9]+)\s+"
                r"cycle_exception_redirect=([0-9]+)\s+"
                r"cycle_memory_commit=([0-9]+)\s+"
                r"cycle_serialization=([0-9]+)\s+"
                r"cycle_unknown=([0-9]+)\s+"
                r"slot_capacity=([0-9]+)\s+retired_slots=([0-9]+)\s+"
                r"unused_slots=([0-9]+)\s+"
                r"slot_rob_empty=([0-9]+)\s+"
                r"slot_head_not_complete=([0-9]+)\s+"
                r"slot_dependency=([0-9]+)\s+"
                r"slot_issue_terminal=([0-9]+)\s+"
                r"slot_execution_latency=([0-9]+)\s+"
                r"slot_memory_latency=([0-9]+)\s+"
                r"slot_head_lifecycle_unknown=([0-9]+)\s+"
                r"slot_exception_redirect=([0-9]+)\s+"
                r"slot_memory_commit=([0-9]+)\s+"
                r"slot_serialization=([0-9]+)\s+"
                r"slot_unknown=([0-9]+)\s+conservation=([01])\s*"),
            f"{benchmark_display} performance COUNTERS_FINAL marker",
            label,
        )
    elif evidence_schema == "npc-rv64-performance-evidence-v7":
        counter_match = _unique_raw_line(
            lines,
            re.compile(r"\bregion_probe\].*\bCOUNTERS_FINAL\b"),
            re.compile(
                r"\[[^]\r\n]*\bregion_probe\]\s+COUNTERS_FINAL\s+"
                r"schema=([a-zA-Z0-9_-]+)\s+"
                r"complete=([01])\s+available=([01])\s+"
                r"overflow=([01])\s+invalid_events=([0-9]+)\s+"
                r"start_lane=([0-9]+)\s+end_lane=([0-9]+)\s+"
                r"phase_aligned=([01])\s+cycles=([0-9]+)\s+"
                r"cycle_useful=([0-9]+)\s+cycle_rob_empty=([0-9]+)\s+"
                r"cycle_head_not_complete=([0-9]+)\s+"
                r"cycle_dependency=([0-9]+)\s+"
                r"cycle_issue_terminal=([0-9]+)\s+"
                r"cycle_execution_latency=([0-9]+)\s+"
                r"cycle_memory_latency=([0-9]+)\s+"
                r"cycle_memory_reservation_queue=([0-9]+)\s+"
                r"cycle_memory_translation_order=([0-9]+)\s+"
                r"cycle_memory_request_outstanding=([0-9]+)\s+"
                r"cycle_memory_response_terminal=([0-9]+)\s+"
                r"cycle_memory_retry=([0-9]+)\s+"
                r"cycle_memory_lifecycle_unknown=([0-9]+)\s+"
                r"cycle_head_lifecycle_unknown=([0-9]+)\s+"
                r"cycle_exception_redirect=([0-9]+)\s+"
                r"cycle_memory_commit=([0-9]+)\s+"
                r"cycle_serialization=([0-9]+)\s+"
                r"cycle_unknown=([0-9]+)\s+"
                r"slot_capacity=([0-9]+)\s+retired_slots=([0-9]+)\s+"
                r"unused_slots=([0-9]+)\s+"
                r"slot_rob_empty=([0-9]+)\s+"
                r"slot_head_not_complete=([0-9]+)\s+"
                r"slot_dependency=([0-9]+)\s+"
                r"slot_issue_terminal=([0-9]+)\s+"
                r"slot_execution_latency=([0-9]+)\s+"
                r"slot_memory_latency=([0-9]+)\s+"
                r"slot_memory_reservation_queue=([0-9]+)\s+"
                r"slot_memory_translation_order=([0-9]+)\s+"
                r"slot_memory_request_outstanding=([0-9]+)\s+"
                r"slot_memory_response_terminal=([0-9]+)\s+"
                r"slot_memory_retry=([0-9]+)\s+"
                r"slot_memory_lifecycle_unknown=([0-9]+)\s+"
                r"slot_head_lifecycle_unknown=([0-9]+)\s+"
                r"slot_exception_redirect=([0-9]+)\s+"
                r"slot_memory_commit=([0-9]+)\s+"
                r"slot_serialization=([0-9]+)\s+"
                r"slot_unknown=([0-9]+)\s+conservation=([01])\s*"),
            f"{benchmark_display} performance COUNTERS_FINAL marker",
            label,
        )
    elif evidence_schema == "npc-rv64-performance-evidence-v8":
        counter_match = _unique_raw_line(
            lines,
            re.compile(r"\bregion_probe\].*\bCOUNTERS_FINAL\b"),
            re.compile(
                r"\[[^]\r\n]*\bregion_probe\]\s+COUNTERS_FINAL\s+"
                r"schema=([a-zA-Z0-9_-]+)\s+"
                r"complete=([01])\s+available=([01])\s+"
                r"overflow=([01])\s+invalid_events=([0-9]+)\s+"
                r"start_lane=([0-9]+)\s+end_lane=([0-9]+)\s+"
                r"phase_aligned=([01])\s+cycles=([0-9]+)\s+"
                r"cycle_useful=([0-9]+)\s+cycle_rob_empty=([0-9]+)\s+"
                r"cycle_head_not_complete=([0-9]+)\s+"
                r"cycle_dependency=([0-9]+)\s+"
                r"cycle_issue_terminal=([0-9]+)\s+"
                r"cycle_execution_latency=([0-9]+)\s+"
                r"cycle_memory_latency=([0-9]+)\s+"
                r"cycle_memory_reservation_queue=([0-9]+)\s+"
                r"cycle_memory_translation_order=([0-9]+)\s+"
                r"cycle_memory_request_outstanding=([0-9]+)\s+"
                r"cycle_memory_request_cache_lookup=([0-9]+)\s+"
                r"cycle_memory_request_device_wait=([0-9]+)\s+"
                r"cycle_memory_request_axi_read_address=([0-9]+)\s+"
                r"cycle_memory_request_axi_read_data=([0-9]+)\s+"
                r"cycle_memory_request_axi_write_request=([0-9]+)\s+"
                r"cycle_memory_request_axi_write_response=([0-9]+)\s+"
                r"cycle_memory_request_detail_unknown=([0-9]+)\s+"
                r"cycle_memory_response_terminal=([0-9]+)\s+"
                r"cycle_memory_retry=([0-9]+)\s+"
                r"cycle_memory_lifecycle_unknown=([0-9]+)\s+"
                r"cycle_head_lifecycle_unknown=([0-9]+)\s+"
                r"cycle_exception_redirect=([0-9]+)\s+"
                r"cycle_memory_commit=([0-9]+)\s+"
                r"cycle_serialization=([0-9]+)\s+"
                r"cycle_unknown=([0-9]+)\s+"
                r"slot_capacity=([0-9]+)\s+retired_slots=([0-9]+)\s+"
                r"unused_slots=([0-9]+)\s+"
                r"slot_rob_empty=([0-9]+)\s+"
                r"slot_head_not_complete=([0-9]+)\s+"
                r"slot_dependency=([0-9]+)\s+"
                r"slot_issue_terminal=([0-9]+)\s+"
                r"slot_execution_latency=([0-9]+)\s+"
                r"slot_memory_latency=([0-9]+)\s+"
                r"slot_memory_reservation_queue=([0-9]+)\s+"
                r"slot_memory_translation_order=([0-9]+)\s+"
                r"slot_memory_request_outstanding=([0-9]+)\s+"
                r"slot_memory_request_cache_lookup=([0-9]+)\s+"
                r"slot_memory_request_device_wait=([0-9]+)\s+"
                r"slot_memory_request_axi_read_address=([0-9]+)\s+"
                r"slot_memory_request_axi_read_data=([0-9]+)\s+"
                r"slot_memory_request_axi_write_request=([0-9]+)\s+"
                r"slot_memory_request_axi_write_response=([0-9]+)\s+"
                r"slot_memory_request_detail_unknown=([0-9]+)\s+"
                r"slot_memory_response_terminal=([0-9]+)\s+"
                r"slot_memory_retry=([0-9]+)\s+"
                r"slot_memory_lifecycle_unknown=([0-9]+)\s+"
                r"slot_head_lifecycle_unknown=([0-9]+)\s+"
                r"slot_exception_redirect=([0-9]+)\s+"
                r"slot_memory_commit=([0-9]+)\s+"
                r"slot_serialization=([0-9]+)\s+"
                r"slot_unknown=([0-9]+)\s+conservation=([01])\s*"),
            f"{benchmark_display} performance COUNTERS_FINAL marker",
            label,
        )

    (start_pc_text, start_cycle_text, start_retired_text,
     start_lane_text, start_cycle_retire_text) = start_match.groups()
    (stop_pc_text, stop_cycle_text, stop_retired_text,
     stop_lane_text, stop_cycle_retire_text) = stop_match.groups()
    if require_final:
        (final_schema, final_scope, complete_text, termination_rc_text,
         start_seen_text, end_seen_text, start_hits_text, stop_hits_text,
         result_start_cycle_text, result_stop_cycle_text, region_cycles_text,
         result_start_retired_text, result_stop_retired_text,
         region_retired_text) = region_match.groups()
        if final_schema != "npc-rv64-region-final-v1":
            raise ValueError(f"{label}: region FINAL schema mismatch")
        if final_scope != counter_scope:
            raise ValueError(f"{label}: region FINAL counter scope mismatch")
        if complete_text != "1" or start_seen_text != "1" or end_seen_text != "1":
            raise ValueError(f"{label}: region FINAL is incomplete")
        if len(termination_rc_text.lstrip("-")) > 10:
            raise ValueError(f"{label}: region FINAL termination_rc is outside int32 range")
        termination_rc = int(termination_rc_text, 10)
        if not -(1 << 31) <= termination_rc < (1 << 31):
            raise ValueError(f"{label}: region FINAL termination_rc is outside int32 range")
        if termination_rc != 0:
            raise ValueError(f"{label}: region FINAL termination_rc is nonzero")
    else:
        (start_hits_text, stop_hits_text, result_start_cycle_text,
         result_stop_cycle_text, region_cycles_text,
         result_start_retired_text, result_stop_retired_text,
         region_retired_text) = region_match.groups()

    start_pc = _hex_uint64(start_pc_text, "start marker pc", label)
    stop_pc = _hex_uint64(stop_pc_text, "stop marker pc", label)
    start_cycle = _bounded_nonnegative_counter(
        start_cycle_text, "start marker cycle", label)
    stop_cycle = _bounded_nonnegative_counter(
        stop_cycle_text, "stop marker cycle", label)
    start_retired = _bounded_nonnegative_counter(
        start_retired_text, "start marker retired_before", label)
    stop_retired = _bounded_nonnegative_counter(
        stop_retired_text, "stop marker retired_before", label)
    start_lane = _bounded_nonnegative_counter(
        start_lane_text, "start marker lane", label)
    stop_lane = _bounded_nonnegative_counter(
        stop_lane_text, "stop marker lane", label)
    start_cycle_retire = _bounded_nonnegative_counter(
        start_cycle_retire_text, "start marker cycle_retire", label)
    stop_cycle_retire = _bounded_nonnegative_counter(
        stop_cycle_retire_text, "stop marker cycle_retire", label)
    start_hits = _bounded_counter(start_hits_text, "start_hits", label)
    stop_hits = _bounded_counter(stop_hits_text, "stop_hits", label)
    result_start_cycle = _bounded_nonnegative_counter(
        result_start_cycle_text, "result start_cycle", label)
    result_stop_cycle = _bounded_nonnegative_counter(
        result_stop_cycle_text, "result end_cycle", label)
    region_cycles = (
        _bounded_nonnegative_counter(
            region_cycles_text, "region cycles", label)
        if require_final
        else _bounded_counter(region_cycles_text, "region cycles", label)
    )
    result_start_retired = _bounded_nonnegative_counter(
        result_start_retired_text, "result start_retired", label)
    result_stop_retired = _bounded_nonnegative_counter(
        result_stop_retired_text, "result end_retired", label)
    region_retired = _bounded_counter(
        region_retired_text, "region retired", label)

    if start_pc != expected_start_pc or stop_pc != expected_stop_pc:
        raise ValueError(f"{label}: region boundary PC mismatch")
    if start_hits != expected_start_hits or stop_hits != expected_stop_hits:
        raise ValueError(f"{label}: region hit count mismatch")
    if start_lane > 1 or stop_lane > 1:
        raise ValueError(f"{label}: region marker lane is invalid")
    if start_cycle_retire > 2 or stop_cycle_retire > 2:
        raise ValueError(f"{label}: region marker cycle_retire is invalid")
    if (start_cycle != result_start_cycle
            or stop_cycle != result_stop_cycle
            or start_retired != result_start_retired
            or stop_retired != result_stop_retired):
        raise ValueError(f"{label}: boundary/result marker mismatch")
    if (stop_cycle < start_cycle
            or stop_retired <= start_retired
            or stop_cycle - start_cycle != region_cycles
            or stop_retired - start_retired != region_retired):
        raise ValueError(f"{label}: region counter arithmetic mismatch")
    if region_cycles == 0:
        raise ValueError(f"{label}: region cycle count must be positive")
    if stop_cycle > whole_cycles or stop_retired > whole_retired:
        raise ValueError(f"{label}: region escapes whole-program counters")

    result["post_region"] = {
        "cycles": whole_cycles - stop_cycle,
        "retired_instructions": whole_retired - stop_retired,
    }
    result["cycles"] = region_cycles
    result["retired_instructions"] = region_retired
    result["region"] = {
        "start_pc": f"0x{start_pc:016x}",
        "stop_pc": f"0x{stop_pc:016x}",
        "start_marker_semantics": "first_committed_hit",
        "start_hits": start_hits,
        "stop_hits": stop_hits,
        "start_cycle": start_cycle,
        "stop_cycle": stop_cycle,
        "start_retired": start_retired,
        "stop_retired": stop_retired,
        "start_lane": start_lane,
        "stop_lane": stop_lane,
        "cycles": region_cycles,
        "retired_instructions": region_retired,
    }
    if require_final:
        result["region"]["final_schema"] = "npc-rv64-region-final-v1"
        result["region"]["final_total_hits"] = True

    if counter_match is not None:
        lifecycle_counter_text: dict[str, str] = {}
        if evidence_schema == "npc-rv64-performance-evidence-v8":
            (counter_marker_schema, counter_complete_text,
             counter_available_text, counter_overflow_text,
             counter_invalid_events_text, counter_start_lane_text,
             counter_stop_lane_text, counter_phase_aligned_text,
             counter_cycles_text, cycle_useful_text, cycle_rob_empty_text,
             cycle_head_not_complete_text, cycle_dependency_text,
             cycle_issue_terminal_text, cycle_execution_latency_text,
             cycle_memory_latency_text,
             cycle_memory_reservation_queue_text,
             cycle_memory_translation_order_text,
             cycle_memory_request_outstanding_text,
             cycle_memory_request_cache_lookup_text,
             cycle_memory_request_device_wait_text,
             cycle_memory_request_axi_read_address_text,
             cycle_memory_request_axi_read_data_text,
             cycle_memory_request_axi_write_request_text,
             cycle_memory_request_axi_write_response_text,
             cycle_memory_request_detail_unknown_text,
             cycle_memory_response_terminal_text,
             cycle_memory_retry_text,
             cycle_memory_lifecycle_unknown_text,
             cycle_head_lifecycle_unknown_text,
             cycle_exception_redirect_text, cycle_memory_commit_text,
             cycle_serialization_text, cycle_unknown_text,
             slot_capacity_text, retired_slots_text, unused_slots_text,
             slot_rob_empty_text, slot_head_not_complete_text,
             slot_dependency_text, slot_issue_terminal_text,
             slot_execution_latency_text, slot_memory_latency_text,
             slot_memory_reservation_queue_text,
             slot_memory_translation_order_text,
             slot_memory_request_outstanding_text,
             slot_memory_request_cache_lookup_text,
             slot_memory_request_device_wait_text,
             slot_memory_request_axi_read_address_text,
             slot_memory_request_axi_read_data_text,
             slot_memory_request_axi_write_request_text,
             slot_memory_request_axi_write_response_text,
             slot_memory_request_detail_unknown_text,
             slot_memory_response_terminal_text,
             slot_memory_retry_text,
             slot_memory_lifecycle_unknown_text,
             slot_head_lifecycle_unknown_text,
             slot_exception_redirect_text, slot_memory_commit_text,
             slot_serialization_text, slot_unknown_text,
             conservation_text) = counter_match.groups()
            expected_counter_marker_schema = (
                "npc-rv64-performance-counter-v4")
            lifecycle_counter_text = {
                "cycle_dependency": cycle_dependency_text,
                "cycle_issue_terminal": cycle_issue_terminal_text,
                "cycle_execution_latency": cycle_execution_latency_text,
                "cycle_memory_latency": cycle_memory_latency_text,
                "cycle_memory_reservation_queue":
                    cycle_memory_reservation_queue_text,
                "cycle_memory_translation_order":
                    cycle_memory_translation_order_text,
                "cycle_memory_request_outstanding":
                    cycle_memory_request_outstanding_text,
                "cycle_memory_request_cache_lookup":
                    cycle_memory_request_cache_lookup_text,
                "cycle_memory_request_device_wait":
                    cycle_memory_request_device_wait_text,
                "cycle_memory_request_axi_read_address":
                    cycle_memory_request_axi_read_address_text,
                "cycle_memory_request_axi_read_data":
                    cycle_memory_request_axi_read_data_text,
                "cycle_memory_request_axi_write_request":
                    cycle_memory_request_axi_write_request_text,
                "cycle_memory_request_axi_write_response":
                    cycle_memory_request_axi_write_response_text,
                "cycle_memory_request_detail_unknown":
                    cycle_memory_request_detail_unknown_text,
                "cycle_memory_response_terminal":
                    cycle_memory_response_terminal_text,
                "cycle_memory_retry": cycle_memory_retry_text,
                "cycle_memory_lifecycle_unknown":
                    cycle_memory_lifecycle_unknown_text,
                "cycle_head_lifecycle_unknown":
                    cycle_head_lifecycle_unknown_text,
                "slot_dependency": slot_dependency_text,
                "slot_issue_terminal": slot_issue_terminal_text,
                "slot_execution_latency": slot_execution_latency_text,
                "slot_memory_latency": slot_memory_latency_text,
                "slot_memory_reservation_queue":
                    slot_memory_reservation_queue_text,
                "slot_memory_translation_order":
                    slot_memory_translation_order_text,
                "slot_memory_request_outstanding":
                    slot_memory_request_outstanding_text,
                "slot_memory_request_cache_lookup":
                    slot_memory_request_cache_lookup_text,
                "slot_memory_request_device_wait":
                    slot_memory_request_device_wait_text,
                "slot_memory_request_axi_read_address":
                    slot_memory_request_axi_read_address_text,
                "slot_memory_request_axi_read_data":
                    slot_memory_request_axi_read_data_text,
                "slot_memory_request_axi_write_request":
                    slot_memory_request_axi_write_request_text,
                "slot_memory_request_axi_write_response":
                    slot_memory_request_axi_write_response_text,
                "slot_memory_request_detail_unknown":
                    slot_memory_request_detail_unknown_text,
                "slot_memory_response_terminal":
                    slot_memory_response_terminal_text,
                "slot_memory_retry": slot_memory_retry_text,
                "slot_memory_lifecycle_unknown":
                    slot_memory_lifecycle_unknown_text,
                "slot_head_lifecycle_unknown":
                    slot_head_lifecycle_unknown_text,
            }
            cycle_fields = (
                "cycle_useful", "cycle_rob_empty", "cycle_dependency",
                "cycle_issue_terminal", "cycle_execution_latency",
                "cycle_memory_latency", "cycle_head_lifecycle_unknown",
                "cycle_exception_redirect", "cycle_memory_commit",
                "cycle_serialization", "cycle_unknown",
            )
            slot_reason_fields = (
                "slot_rob_empty", "slot_dependency", "slot_issue_terminal",
                "slot_execution_latency", "slot_memory_latency",
                "slot_head_lifecycle_unknown", "slot_exception_redirect",
                "slot_memory_commit", "slot_serialization", "slot_unknown",
            )
        elif evidence_schema == "npc-rv64-performance-evidence-v7":
            (counter_marker_schema, counter_complete_text,
             counter_available_text, counter_overflow_text,
             counter_invalid_events_text, counter_start_lane_text,
             counter_stop_lane_text, counter_phase_aligned_text,
             counter_cycles_text, cycle_useful_text, cycle_rob_empty_text,
             cycle_head_not_complete_text, cycle_dependency_text,
             cycle_issue_terminal_text, cycle_execution_latency_text,
             cycle_memory_latency_text,
             cycle_memory_reservation_queue_text,
             cycle_memory_translation_order_text,
             cycle_memory_request_outstanding_text,
             cycle_memory_response_terminal_text,
             cycle_memory_retry_text,
             cycle_memory_lifecycle_unknown_text,
             cycle_head_lifecycle_unknown_text,
             cycle_exception_redirect_text, cycle_memory_commit_text,
             cycle_serialization_text, cycle_unknown_text,
             slot_capacity_text, retired_slots_text, unused_slots_text,
             slot_rob_empty_text, slot_head_not_complete_text,
             slot_dependency_text, slot_issue_terminal_text,
             slot_execution_latency_text, slot_memory_latency_text,
             slot_memory_reservation_queue_text,
             slot_memory_translation_order_text,
             slot_memory_request_outstanding_text,
             slot_memory_response_terminal_text,
             slot_memory_retry_text,
             slot_memory_lifecycle_unknown_text,
             slot_head_lifecycle_unknown_text,
             slot_exception_redirect_text, slot_memory_commit_text,
             slot_serialization_text, slot_unknown_text,
             conservation_text) = counter_match.groups()
            expected_counter_marker_schema = (
                "npc-rv64-performance-counter-v3")
            lifecycle_counter_text = {
                "cycle_dependency": cycle_dependency_text,
                "cycle_issue_terminal": cycle_issue_terminal_text,
                "cycle_execution_latency": cycle_execution_latency_text,
                "cycle_memory_latency": cycle_memory_latency_text,
                "cycle_memory_reservation_queue":
                    cycle_memory_reservation_queue_text,
                "cycle_memory_translation_order":
                    cycle_memory_translation_order_text,
                "cycle_memory_request_outstanding":
                    cycle_memory_request_outstanding_text,
                "cycle_memory_response_terminal":
                    cycle_memory_response_terminal_text,
                "cycle_memory_retry": cycle_memory_retry_text,
                "cycle_memory_lifecycle_unknown":
                    cycle_memory_lifecycle_unknown_text,
                "cycle_head_lifecycle_unknown":
                    cycle_head_lifecycle_unknown_text,
                "slot_dependency": slot_dependency_text,
                "slot_issue_terminal": slot_issue_terminal_text,
                "slot_execution_latency": slot_execution_latency_text,
                "slot_memory_latency": slot_memory_latency_text,
                "slot_memory_reservation_queue":
                    slot_memory_reservation_queue_text,
                "slot_memory_translation_order":
                    slot_memory_translation_order_text,
                "slot_memory_request_outstanding":
                    slot_memory_request_outstanding_text,
                "slot_memory_response_terminal":
                    slot_memory_response_terminal_text,
                "slot_memory_retry": slot_memory_retry_text,
                "slot_memory_lifecycle_unknown":
                    slot_memory_lifecycle_unknown_text,
                "slot_head_lifecycle_unknown":
                    slot_head_lifecycle_unknown_text,
            }
            cycle_fields = (
                "cycle_useful", "cycle_rob_empty", "cycle_dependency",
                "cycle_issue_terminal", "cycle_execution_latency",
                "cycle_memory_latency", "cycle_head_lifecycle_unknown",
                "cycle_exception_redirect", "cycle_memory_commit",
                "cycle_serialization", "cycle_unknown",
            )
            slot_reason_fields = (
                "slot_rob_empty", "slot_dependency", "slot_issue_terminal",
                "slot_execution_latency", "slot_memory_latency",
                "slot_head_lifecycle_unknown", "slot_exception_redirect",
                "slot_memory_commit", "slot_serialization", "slot_unknown",
            )
        elif evidence_schema == "npc-rv64-performance-evidence-v6":
            (counter_marker_schema, counter_complete_text,
             counter_available_text, counter_overflow_text,
             counter_invalid_events_text, counter_start_lane_text,
             counter_stop_lane_text, counter_phase_aligned_text,
             counter_cycles_text, cycle_useful_text, cycle_rob_empty_text,
             cycle_head_not_complete_text, cycle_dependency_text,
             cycle_issue_terminal_text, cycle_execution_latency_text,
             cycle_memory_latency_text, cycle_head_lifecycle_unknown_text,
             cycle_exception_redirect_text, cycle_memory_commit_text,
             cycle_serialization_text, cycle_unknown_text,
             slot_capacity_text, retired_slots_text, unused_slots_text,
             slot_rob_empty_text, slot_head_not_complete_text,
             slot_dependency_text, slot_issue_terminal_text,
             slot_execution_latency_text, slot_memory_latency_text,
             slot_head_lifecycle_unknown_text,
             slot_exception_redirect_text, slot_memory_commit_text,
             slot_serialization_text, slot_unknown_text,
             conservation_text) = counter_match.groups()
            expected_counter_marker_schema = (
                "npc-rv64-performance-counter-v2")
            lifecycle_counter_text = {
                "cycle_dependency": cycle_dependency_text,
                "cycle_issue_terminal": cycle_issue_terminal_text,
                "cycle_execution_latency": cycle_execution_latency_text,
                "cycle_memory_latency": cycle_memory_latency_text,
                "cycle_head_lifecycle_unknown":
                    cycle_head_lifecycle_unknown_text,
                "slot_dependency": slot_dependency_text,
                "slot_issue_terminal": slot_issue_terminal_text,
                "slot_execution_latency": slot_execution_latency_text,
                "slot_memory_latency": slot_memory_latency_text,
                "slot_head_lifecycle_unknown":
                    slot_head_lifecycle_unknown_text,
            }
            cycle_fields = (
                "cycle_useful", "cycle_rob_empty", "cycle_dependency",
                "cycle_issue_terminal", "cycle_execution_latency",
                "cycle_memory_latency", "cycle_head_lifecycle_unknown",
                "cycle_exception_redirect", "cycle_memory_commit",
                "cycle_serialization", "cycle_unknown",
            )
            slot_reason_fields = (
                "slot_rob_empty", "slot_dependency", "slot_issue_terminal",
                "slot_execution_latency", "slot_memory_latency",
                "slot_head_lifecycle_unknown", "slot_exception_redirect",
                "slot_memory_commit", "slot_serialization", "slot_unknown",
            )
        else:
            (counter_marker_schema, counter_complete_text,
             counter_available_text, counter_overflow_text,
             counter_invalid_events_text, counter_start_lane_text,
             counter_stop_lane_text, counter_phase_aligned_text,
             counter_cycles_text, cycle_useful_text, cycle_rob_empty_text,
             cycle_head_not_complete_text, cycle_exception_redirect_text,
             cycle_memory_commit_text, cycle_serialization_text,
             cycle_unknown_text, slot_capacity_text, retired_slots_text,
             unused_slots_text, slot_rob_empty_text,
             slot_head_not_complete_text, slot_exception_redirect_text,
             slot_memory_commit_text, slot_serialization_text,
             slot_unknown_text, conservation_text) = counter_match.groups()
            expected_counter_marker_schema = (
                "npc-rv64-performance-counter-v1")
            cycle_fields = (
                "cycle_useful", "cycle_rob_empty",
                "cycle_head_not_complete", "cycle_exception_redirect",
                "cycle_memory_commit", "cycle_serialization",
                "cycle_unknown",
            )
            slot_reason_fields = (
                "slot_rob_empty", "slot_head_not_complete",
                "slot_exception_redirect", "slot_memory_commit",
                "slot_serialization", "slot_unknown",
            )

        if counter_marker_schema != expected_counter_marker_schema:
            raise ValueError(
                f"{label}: performance COUNTERS_FINAL schema mismatch")
        if counter_complete_text != "1" or counter_available_text != "1":
            raise ValueError(
                f"{label}: performance COUNTERS_FINAL is incomplete")
        if counter_overflow_text != "0":
            raise ValueError(
                f"{label}: performance counter overflow is nonzero")
        if counter_phase_aligned_text != "1" or start_lane != stop_lane:
            raise ValueError(
                f"{label}: performance counter boundary phase is not aligned")
        if conservation_text != "1":
            raise ValueError(
                f"{label}: performance counter conservation marker failed")

        counter_values = {
            "invalid_events": _bounded_nonnegative_counter(
                counter_invalid_events_text, "counter invalid_events", label),
            "start_lane": _bounded_nonnegative_counter(
                counter_start_lane_text, "counter start_lane", label),
            "stop_lane": _bounded_nonnegative_counter(
                counter_stop_lane_text, "counter end_lane", label),
            "cycles": _bounded_nonnegative_counter(
                counter_cycles_text, "counter cycles", label),
            "cycle_useful": _bounded_nonnegative_counter(
                cycle_useful_text, "counter cycle_useful", label),
            "cycle_rob_empty": _bounded_nonnegative_counter(
                cycle_rob_empty_text, "counter cycle_rob_empty", label),
            "cycle_head_not_complete": _bounded_nonnegative_counter(
                cycle_head_not_complete_text,
                "counter cycle_head_not_complete", label),
            "cycle_exception_redirect": _bounded_nonnegative_counter(
                cycle_exception_redirect_text,
                "counter cycle_exception_redirect", label),
            "cycle_memory_commit": _bounded_nonnegative_counter(
                cycle_memory_commit_text, "counter cycle_memory_commit", label),
            "cycle_serialization": _bounded_nonnegative_counter(
                cycle_serialization_text,
                "counter cycle_serialization", label),
            "cycle_unknown": _bounded_nonnegative_counter(
                cycle_unknown_text, "counter cycle_unknown", label),
            "slot_capacity": _bounded_nonnegative_counter(
                slot_capacity_text, "counter slot_capacity", label),
            "retired_slots": _bounded_nonnegative_counter(
                retired_slots_text, "counter retired_slots", label),
            "unused_slots": _bounded_nonnegative_counter(
                unused_slots_text, "counter unused_slots", label),
            "slot_rob_empty": _bounded_nonnegative_counter(
                slot_rob_empty_text, "counter slot_rob_empty", label),
            "slot_head_not_complete": _bounded_nonnegative_counter(
                slot_head_not_complete_text,
                "counter slot_head_not_complete", label),
            "slot_exception_redirect": _bounded_nonnegative_counter(
                slot_exception_redirect_text,
                "counter slot_exception_redirect", label),
            "slot_memory_commit": _bounded_nonnegative_counter(
                slot_memory_commit_text, "counter slot_memory_commit", label),
            "slot_serialization": _bounded_nonnegative_counter(
                slot_serialization_text,
                "counter slot_serialization", label),
            "slot_unknown": _bounded_nonnegative_counter(
                slot_unknown_text, "counter slot_unknown", label),
        }
        for counter_name, counter_text in lifecycle_counter_text.items():
            counter_values[counter_name] = _bounded_nonnegative_counter(
                counter_text, f"counter {counter_name}", label)

        if counter_values["invalid_events"] != 0:
            raise ValueError(
                f"{label}: performance counter invalid_events is nonzero")
        if (counter_values["start_lane"] != start_lane
                or counter_values["stop_lane"] != stop_lane):
            raise ValueError(
                f"{label}: performance counter boundary lane mismatch")
        if counter_values["cycles"] != region_cycles:
            raise ValueError(
                f"{label}: performance counter cycle binding mismatch")
        if evidence_schema in {
                "npc-rv64-performance-evidence-v6",
                "npc-rv64-performance-evidence-v7",
                "npc-rv64-performance-evidence-v8"}:
            cycle_head_parts = (
                "cycle_dependency", "cycle_issue_terminal",
                "cycle_execution_latency", "cycle_memory_latency",
                "cycle_head_lifecycle_unknown",
            )
            slot_head_parts = (
                "slot_dependency", "slot_issue_terminal",
                "slot_execution_latency", "slot_memory_latency",
                "slot_head_lifecycle_unknown",
            )
            if (counter_values["cycle_head_not_complete"] !=
                    sum(counter_values[field] for field in cycle_head_parts)
                    or counter_values["slot_head_not_complete"] !=
                    sum(counter_values[field] for field in slot_head_parts)):
                raise ValueError(
                    f"{label}: performance counter head lifecycle "
                    "aggregate mismatch")
        if evidence_schema in {
                "npc-rv64-performance-evidence-v7",
                "npc-rv64-performance-evidence-v8"}:
            cycle_memory_parts = (
                "cycle_memory_reservation_queue",
                "cycle_memory_translation_order",
                "cycle_memory_request_outstanding",
                "cycle_memory_response_terminal",
                "cycle_memory_retry",
                "cycle_memory_lifecycle_unknown",
            )
            slot_memory_parts = (
                "slot_memory_reservation_queue",
                "slot_memory_translation_order",
                "slot_memory_request_outstanding",
                "slot_memory_response_terminal",
                "slot_memory_retry",
                "slot_memory_lifecycle_unknown",
            )
            if (counter_values["cycle_memory_latency"] !=
                    sum(counter_values[field] for field in cycle_memory_parts)
                    or counter_values["slot_memory_latency"] !=
                    sum(counter_values[field] for field in slot_memory_parts)):
                raise ValueError(
                    f"{label}: performance counter memory lifecycle "
                    "aggregate mismatch")
        if evidence_schema == "npc-rv64-performance-evidence-v8":
            cycle_request_parts = (
                "cycle_memory_request_cache_lookup",
                "cycle_memory_request_device_wait",
                "cycle_memory_request_axi_read_address",
                "cycle_memory_request_axi_read_data",
                "cycle_memory_request_axi_write_request",
                "cycle_memory_request_axi_write_response",
                "cycle_memory_request_detail_unknown",
            )
            slot_request_parts = (
                "slot_memory_request_cache_lookup",
                "slot_memory_request_device_wait",
                "slot_memory_request_axi_read_address",
                "slot_memory_request_axi_read_data",
                "slot_memory_request_axi_write_request",
                "slot_memory_request_axi_write_response",
                "slot_memory_request_detail_unknown",
            )
            if (counter_values["cycle_memory_request_outstanding"] !=
                    sum(counter_values[field] for field in cycle_request_parts)
                    or counter_values["slot_memory_request_outstanding"] !=
                    sum(counter_values[field] for field in slot_request_parts)):
                raise ValueError(
                    f"{label}: performance counter memory request detail "
                    "aggregate mismatch")
        cycle_sum = sum(counter_values[field] for field in cycle_fields)
        if cycle_sum != region_cycles:
            raise ValueError(
                f"{label}: performance counter cycle conservation mismatch")
        if region_cycles > MAX_COUNTER // 2:
            raise ValueError(
                f"{label}: performance counter slot capacity overflow")
        expected_slot_capacity = (
            2 * region_cycles + stop_lane - start_lane)
        if (counter_values["slot_capacity"] != expected_slot_capacity
                or counter_values["slot_capacity"] != 2 * region_cycles):
            raise ValueError(
                f"{label}: performance counter slot capacity mismatch")
        if counter_values["retired_slots"] != region_retired:
            raise ValueError(
                f"{label}: performance counter retired-slot binding mismatch")
        unused_reason_sum = sum(
            counter_values[field] for field in slot_reason_fields)
        if (counter_values["unused_slots"] != unused_reason_sum
                or counter_values["retired_slots"] + unused_reason_sum
                != counter_values["slot_capacity"]):
            raise ValueError(
                f"{label}: performance counter retire-slot conservation mismatch")
        assert counter_unknown_ratio_max is not None
        unknown_cycles = counter_values["cycle_unknown"]
        if evidence_schema in {
                "npc-rv64-performance-evidence-v6",
                "npc-rv64-performance-evidence-v7",
                "npc-rv64-performance-evidence-v8"}:
            unknown_cycles += counter_values["cycle_head_lifecycle_unknown"]
        if evidence_schema in {
                "npc-rv64-performance-evidence-v7",
                "npc-rv64-performance-evidence-v8"}:
            unknown_cycles += counter_values[
                "cycle_memory_lifecycle_unknown"]
        if evidence_schema == "npc-rv64-performance-evidence-v8":
            unknown_cycles += counter_values[
                "cycle_memory_request_detail_unknown"]
        unknown_cycle_ratio = unknown_cycles / region_cycles
        if unknown_cycle_ratio > counter_unknown_ratio_max:
            raise ValueError(
                f"{label}: performance counter unknown cycle ratio exceeds limit")
        result["performance_counter_schema"] = counter_marker_schema
        result["cpi_stack"] = {
            field.removeprefix("cycle_"): counter_values[field]
            for field in cycle_fields
        }
        if evidence_schema in {
                "npc-rv64-performance-evidence-v6",
                "npc-rv64-performance-evidence-v7",
                "npc-rv64-performance-evidence-v8"}:
            result["cpi_stack"]["head_not_complete_aggregate"] = (
                counter_values["cycle_head_not_complete"])
        if evidence_schema in {
                "npc-rv64-performance-evidence-v7",
                "npc-rv64-performance-evidence-v8"}:
            result["cpi_stack"]["memory_lifecycle"] = {
                field.removeprefix("cycle_memory_"):
                    counter_values[field]
                for field in cycle_memory_parts
            }
        if evidence_schema == "npc-rv64-performance-evidence-v8":
            result["cpi_stack"]["memory_request_detail"] = {
                field.removeprefix("cycle_memory_request_"):
                    counter_values[field]
                for field in cycle_request_parts
            }
        result["cpi_stack"]["unknown_ratio"] = unknown_cycle_ratio
        result["retire_slots"] = {
            "capacity": counter_values["slot_capacity"],
            "retired": counter_values["retired_slots"],
            "unused": counter_values["unused_slots"],
            **{
                field.removeprefix("slot_"): counter_values[field]
                for field in slot_reason_fields
            },
        }
        if evidence_schema in {
                "npc-rv64-performance-evidence-v6",
                "npc-rv64-performance-evidence-v7",
                "npc-rv64-performance-evidence-v8"}:
            result["retire_slots"]["head_not_complete_aggregate"] = (
                counter_values["slot_head_not_complete"])
        if evidence_schema in {
                "npc-rv64-performance-evidence-v7",
                "npc-rv64-performance-evidence-v8"}:
            result["retire_slots"]["memory_lifecycle"] = {
                field.removeprefix("slot_memory_"):
                    counter_values[field]
                for field in slot_memory_parts
            }
        if evidence_schema == "npc-rv64-performance-evidence-v8":
            result["retire_slots"]["memory_request_detail"] = {
                field.removeprefix("slot_memory_request_"):
                    counter_values[field]
                for field in slot_request_parts
            }
    return result


def checker_exit_code(errors: list[str], blockers: list[str],
                      report_only: bool) -> int:
    if errors:
        return 1
    if blockers and not report_only:
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=pathlib.Path)
    gate_mode = parser.add_mutually_exclusive_group()
    gate_mode.add_argument("--require-promotable", action="store_true")
    gate_mode.add_argument("--require-accepted", action="store_true")
    gate_mode.add_argument("--report-only", action="store_true")
    parser.add_argument("--skip-large-artifacts", action="store_true")
    parser.add_argument("--target", choices=("proxy_champion", "final_champion"),
                        default="proxy_champion")
    args = parser.parse_args()

    manifest_path = args.manifest.resolve()
    root = repo_root(manifest_path.parent)
    manifest = read_json(manifest_path)
    errors: list[str] = []
    blockers: list[str] = []
    warnings: list[str] = []

    if manifest.get("schema") != "npc-rv64-ppa-baseline-v1":
        errors.append("unsupported manifest schema")
    policy_rel = manifest.get("policy")
    policy_path: pathlib.Path | None = None
    policy_sha256: str | None = None
    if not isinstance(policy_rel, str):
        errors.append("policy path is missing")
        policy: dict[str, Any] = {}
    else:
        try:
            policy_path = workspace_file(root, policy_rel, "policy")
            policy = read_json(policy_path)
            policy_sha256 = digest(policy_path)
        except (OSError, ValueError, json.JSONDecodeError, FileNotFoundError) as exc:
            errors.append(f"cannot read policy: {exc}")
            policy = {}
    if policy and policy.get("schema") != "npc-rv64-ppa-policy-v1":
        errors.append("unsupported policy schema")
    if policy and manifest.get("policy_id") != policy.get("policy_id"):
        errors.append("policy_id does not match policy file")
    if policy and manifest.get("claim_tier") != policy.get("claim_tier"):
        errors.append("claim_tier does not match policy")

    performance_evidence_policy = policy.get("performance_evidence", {})
    if not isinstance(performance_evidence_policy, dict):
        errors.append("policy performance_evidence section must be an object")
        performance_evidence_policy = {}
    expected_performance_schema = performance_evidence_policy.get("schema")
    if (not isinstance(expected_performance_schema, str)
            or expected_performance_schema not in PERFORMANCE_EVIDENCE_SCHEMAS):
        errors.append("unsupported or missing performance evidence policy schema")
        expected_counter_scopes = {}
    else:
        expected_counter_scopes = PERFORMANCE_COUNTER_SCOPES_BY_SCHEMA[
            expected_performance_schema]
    measurement_contract_id: str | None = None
    performance_counter_schema_id: str | None = None
    performance_counter_contract: dict[str, Any] = {}
    if expected_performance_schema in (
            "npc-rv64-performance-evidence-v4",
            "npc-rv64-performance-evidence-v5",
            "npc-rv64-performance-evidence-v6",
            "npc-rv64-performance-evidence-v7",
            "npc-rv64-performance-evidence-v8"):
        measurement_binding = performance_evidence_policy.get(
            "measurement_contract")
        if not isinstance(measurement_binding, dict):
            errors.append("policy performance measurement contract is missing")
        else:
            measurement_path_value = measurement_binding.get("path")
            measurement_id_value = measurement_binding.get("id")
            measurement_sha_value = measurement_binding.get("sha256")
            if (not isinstance(measurement_id_value, str)
                    or not measurement_id_value):
                errors.append("policy performance measurement contract id is invalid")
            else:
                measurement_contract_id = measurement_id_value
            if not is_sha256(measurement_sha_value):
                errors.append(
                    "policy performance measurement contract digest is invalid")
            try:
                measurement_path = workspace_file(
                    root, measurement_path_value,
                    "performance measurement contract")
                measurement_contract = read_json(measurement_path)
            except (OSError, ValueError, json.JSONDecodeError,
                    FileNotFoundError) as exc:
                errors.append(
                    f"cannot read performance measurement contract: {exc}")
                measurement_contract = {}
            if measurement_contract:
                if digest(measurement_path) != measurement_sha_value:
                    errors.append(
                        "performance measurement contract digest mismatch")
                if (measurement_contract.get("schema") !=
                        "npc-rv64-performance-measurement-contract-v1"):
                    errors.append(
                        "unsupported performance measurement contract schema")
                if (measurement_contract.get(
                        "performance_measurement_contract_id") !=
                        measurement_contract_id):
                    errors.append(
                        "performance measurement contract id mismatch")
                baseline_eligible = measurement_contract.get(
                    "performance_baseline_eligible")
                if not isinstance(baseline_eligible, bool):
                    errors.append(
                        "performance baseline eligibility must be boolean")
                elif not baseline_eligible:
                    blockers.append(
                        "performance measurement contract is not baseline eligible")
    if expected_performance_schema in (
            "npc-rv64-performance-evidence-v5",
            "npc-rv64-performance-evidence-v6",
            "npc-rv64-performance-evidence-v7",
            "npc-rv64-performance-evidence-v8"):
        counter_binding = performance_evidence_policy.get("counter_schema")
        if not isinstance(counter_binding, dict):
            errors.append("policy performance counter schema is missing")
        else:
            counter_path_value = counter_binding.get("path")
            counter_id_value = counter_binding.get("id")
            counter_sha_value = counter_binding.get("sha256")
            if not isinstance(counter_id_value, str) or not counter_id_value:
                errors.append("policy performance counter schema id is invalid")
            else:
                performance_counter_schema_id = counter_id_value
            if not is_sha256(counter_sha_value):
                errors.append("policy performance counter schema digest is invalid")
            try:
                counter_path = workspace_file(
                    root, counter_path_value, "performance counter schema")
                performance_counter_contract = read_json(counter_path)
            except (OSError, ValueError, json.JSONDecodeError,
                    FileNotFoundError) as exc:
                errors.append(f"cannot read performance counter schema: {exc}")
                performance_counter_contract = {}
            if performance_counter_contract:
                counter_contract_versions = {
                    "npc-rv64-performance-evidence-v5": (
                        "npc-rv64-performance-counter-schema-v1",
                        "PARTIAL_CONSERVING_RETIREMENT_OBSERVATION_V1"),
                    "npc-rv64-performance-evidence-v6": (
                        "npc-rv64-performance-counter-schema-v2",
                        "PARTIAL_CONSERVING_HEAD_LIFECYCLE_V2"),
                    "npc-rv64-performance-evidence-v7": (
                        "npc-rv64-performance-counter-schema-v3",
                        "PARTIAL_CONSERVING_MEMORY_LIFECYCLE_V3"),
                    "npc-rv64-performance-evidence-v8": (
                        "npc-rv64-performance-counter-schema-v4",
                        "PARTIAL_CONSERVING_MEMORY_REQUEST_DETAIL_V4"),
                }
                (expected_counter_contract_schema,
                 expected_counter_contract_state) = (
                    counter_contract_versions[expected_performance_schema])
                if digest(counter_path) != counter_sha_value:
                    errors.append("performance counter schema digest mismatch")
                if (performance_counter_contract.get("schema") !=
                        expected_counter_contract_schema):
                    errors.append(
                        "unsupported performance counter schema contract")
                if (performance_counter_contract.get(
                        "performance_counter_schema_id") !=
                        performance_counter_schema_id):
                    errors.append("performance counter schema id mismatch")
                if (performance_counter_contract.get("contract_state") !=
                        expected_counter_contract_state):
                    errors.append("performance counter contract state mismatch")
    minimum_repetitions_value = performance_evidence_policy.get(
        "minimum_repetitions")
    if (not strict_positive_int(minimum_repetitions_value)
            or minimum_repetitions_value < 3):
        errors.append("policy minimum_repetitions must be an integer >= 3")
        minimum_repetitions = 3
    else:
        minimum_repetitions = minimum_repetitions_value
    require_bit_exact_repetitions = performance_evidence_policy.get(
        "require_bit_exact_repetition_counters")
    if require_bit_exact_repetitions is not True:
        errors.append(
            "policy must require bit-exact repetition performance counters")

    benchmark_performance_contracts: dict[str, dict[str, Any]] = {}
    performance_raw_artifact_kinds: set[str] = set()
    benchmark_contracts_value = performance_evidence_policy.get(
        "benchmark_contracts")
    if not isinstance(benchmark_contracts_value, dict):
        errors.append("policy benchmark performance contracts are missing")
        benchmark_contracts_value = {}
    if set(benchmark_contracts_value) != set(expected_counter_scopes):
        errors.append("policy benchmark performance contract set is invalid")
    for benchmark, expected_scope in expected_counter_scopes.items():
        contract = benchmark_contracts_value.get(benchmark)
        if not isinstance(contract, dict):
            errors.append(
                f"policy benchmark performance contract is invalid: {benchmark}")
            continue
        if contract.get("counter_scope") != expected_scope:
            errors.append(
                f"policy benchmark counter scope is invalid: {benchmark}")
        raw_kinds = contract.get("raw_log_artifact_kinds")
        raw_kinds_valid = (
            isinstance(raw_kinds, list)
            and len(raw_kinds) >= minimum_repetitions
            and all(isinstance(kind, str) and kind for kind in raw_kinds)
            and len(raw_kinds) == len(set(raw_kinds))
        )
        if not raw_kinds_valid:
            errors.append(
                f"policy raw-log artifact kinds are invalid: {benchmark}")
            continue
        overlap = performance_raw_artifact_kinds.intersection(raw_kinds)
        if overlap:
            errors.append(
                f"policy raw-log artifact kinds overlap: {sorted(overlap)}")
            continue
        performance_raw_artifact_kinds.update(raw_kinds)
        benchmark_performance_contracts[benchmark] = contract

    for benchmark, expected_scope in expected_counter_scopes.items():
        if expected_scope != "pc_bounded_region_v1":
            continue
        contract = benchmark_contracts_value.get(benchmark)
        if isinstance(contract, dict):
            errors.extend(policy_region_contract_errors(
                benchmark, contract, expected_performance_schema))

    promotion_policy = policy.get("promotion", {})
    if not isinstance(promotion_policy, dict):
        errors.append("policy promotion section must be an object")
        promotion_policy = {}
    for name in (
        "minimum_performance_ratio",
        "minimum_per_benchmark_ratio",
        "minimum_area_efficiency_ratio",
        "minimum_power_efficiency_ratio",
        "maximum_area_ratio",
        "minimum_balanced_score",
    ):
        value = promotion_policy.get(name)
        if not finite_number(value) or value <= 0:
            errors.append(f"policy promotion threshold is invalid: {name}")
    if promotion_policy.get("require_candidate_dominates") is not True:
        errors.append("policy must require candidate Pareto dominance")
    if (promotion_policy.get("require_qualified_power_for_final_champion")
            is not True):
        errors.append("policy must require qualified power for final champion")

    pareto_policy = policy.get("pareto_epsilon", {})
    if not isinstance(pareto_policy, dict):
        errors.append("policy pareto_epsilon section must be an object")
        pareto_policy = {}
    for name in ("performance_ratio", "area_ratio", "power_ratio"):
        value = pareto_policy.get(name)
        if (not finite_number(value) or value < 0 or value >= 1):
            errors.append(f"policy Pareto epsilon is invalid: {name}")

    provenance = manifest.get("provenance", {})
    if not isinstance(provenance, dict):
        errors.append("provenance must be an object")
        provenance = {}
    same_design = provenance.get(
        "same_design_across_functional_performance_synthesis_sta")
    if not isinstance(same_design, bool):
        errors.append("same-design attestation must be a boolean")
    if same_design is not True:
        blockers.append("functional/performance/synthesis/STA are not bound to one design_id")
    design_id = manifest.get("design_id")
    if (not isinstance(design_id, str) or not design_id.startswith("sha256:")
            or not is_sha256(design_id.removeprefix("sha256:"))):
        blockers.append("design_id is unbound")
    status = manifest.get("status")
    if status not in {"provisional", "candidate", "accepted", "rejected"}:
        errors.append(f"invalid status: {status!r}")
    elif status not in {"candidate", "accepted"}:
        blockers.append(f"status {status!r} is not eligible for promotion")
    if args.require_accepted and status != "accepted":
        blockers.append(f"status is {status!r}, not 'accepted'")

    artifacts = manifest.get("artifacts", [])
    if not isinstance(artifacts, list):
        errors.append("artifacts must be a list")
        artifacts = []
    artifact_records_by_kind: dict[str, dict[str, Any]] = {}
    artifact_paths_seen: dict[str, str] = {}
    artifact_sha_seen: dict[str, str] = {}
    artifact_kinds_seen: set[str] = set()
    for artifact in artifacts:
        if not isinstance(artifact, dict):
            errors.append("artifact entry must be an object")
            continue
        kind = artifact.get("kind")
        rel = artifact.get("path")
        expected = artifact.get("sha256")
        if not isinstance(kind, str) or not kind:
            errors.append(f"artifact kind is invalid: {kind!r}")
            continue
        if kind in artifact_kinds_seen:
            errors.append(f"duplicate artifact kind: {kind}")
            continue
        artifact_kinds_seen.add(kind)
        if not isinstance(rel, str) or not rel:
            errors.append(f"artifact path is invalid: {rel!r}")
            continue
        if rel in artifact_paths_seen:
            errors.append(
                f"artifact path reused by {artifact_paths_seen[rel]} and {kind}: {rel}")
            continue
        artifact_paths_seen[rel] = kind
        if not is_sha256(expected):
            errors.append(f"artifact SHA is invalid: {rel}")
            continue
        prior_sha_kind = artifact_sha_seen.get(expected)
        duplicate_performance_raw = (
            prior_sha_kind in performance_raw_artifact_kinds
            and kind in performance_raw_artifact_kinds
        )
        if prior_sha_kind is not None and not duplicate_performance_raw:
            errors.append(
                f"artifact content reused by {prior_sha_kind} and {kind}")
            continue
        artifact_sha_seen.setdefault(expected, kind)
        try:
            path = workspace_file(root, rel, "artifact")
        except (OSError, ValueError, FileNotFoundError) as exc:
            errors.append(str(exc))
            continue
        if path.stat().st_size == 0:
            errors.append(f"artifact is empty: {rel}")
            continue
        if args.skip_large_artifacts and path.stat().st_size > 16 * 1024 * 1024:
            warnings.append(f"hash skipped for large artifact: {rel}")
            blockers.append("artifact hashes are incomplete")
            continue
        if digest(path) != expected:
            errors.append(f"artifact SHA mismatch: {rel}")
            continue
        artifact_records_by_kind[kind] = {
            "kind": kind,
            "path": rel,
            "sha256": expected,
            "resolved": path,
        }

    artifact_kinds_present = set(artifact_records_by_kind)
    required_artifact_kinds = policy.get("required_artifact_kinds", [])
    if not isinstance(required_artifact_kinds, list):
        errors.append("policy required_artifact_kinds must be a list")
        required_artifact_kinds = []
    required_artifact_kind_set = {
        kind for kind in required_artifact_kinds
        if isinstance(kind, str) and kind
    }
    for raw_kind in sorted(performance_raw_artifact_kinds):
        if raw_kind not in required_artifact_kind_set:
            errors.append(
                f"policy raw-log artifact kind is not mandatory: {raw_kind}")
    for kind in required_artifact_kinds:
        if not isinstance(kind, str) or not kind:
            errors.append(f"policy artifact kind is invalid: {kind!r}")
        elif kind not in artifact_kinds_present:
            blockers.append(f"required artifact kind missing: {kind}")

    json_artifact_kinds = {
        kind
        for kind in artifact_kinds_present
        if (kind in {
            "design_binding_manifest",
            "config_manifest",
            "required_test_manifest",
            "sta_setup_manifest",
            "sta_summary",
            "macro_area_manifest",
            "power_report",
            "macro_power_manifest",
            "power_workload_manifest",
        } or kind.startswith("architecture_"))
    }
    artifact_json_by_kind: dict[str, dict[str, Any]] = {}
    for kind in sorted(json_artifact_kinds):
        try:
            artifact_json_by_kind[kind] = read_json_object(
                artifact_records_by_kind[kind]["resolved"], kind)
        except ValueError as exc:
            errors.append(str(exc))

    if status in {"candidate", "accepted"}:
        source_record = artifact_records_by_kind.get("source_manifest")
        synthesis_record = artifact_records_by_kind.get(
            "synthesis_rtl_manifest")
        source_entries: dict[str, str] = {}
        synthesis_entries: dict[str, str] = {}
        if source_record is not None:
            try:
                source_entries = read_sha256_manifest(
                    source_record["resolved"], "source_manifest")
            except ValueError as exc:
                errors.append(str(exc))
        if synthesis_record is not None:
            try:
                synthesis_entries = read_sha256_manifest(
                    synthesis_record["resolved"], "synthesis_rtl_manifest")
            except ValueError as exc:
                errors.append(str(exc))
        for rel, sha256 in synthesis_entries.items():
            if source_entries.get(rel) != sha256:
                blockers.append(
                    f"synthesis RTL is not in source_manifest: {rel}")
        simulation_binary = artifact_records_by_kind.get("simulation_binary")
        if simulation_binary is not None:
            with simulation_binary["resolved"].open("rb") as handle:
                if handle.read(4) != b"\x7fELF":
                    errors.append("simulation_binary is not an ELF binary")
        for kind in ("coremark_image", "dhrystone_image"):
            record = artifact_records_by_kind.get(kind)
            if record is not None:
                with record["resolved"].open("rb") as handle:
                    prefix = handle.read(32).lstrip()
                if prefix.startswith((b"{", b"[")):
                    errors.append(f"{kind} is JSON, not a benchmark image")

    design_binding_record = artifact_records_by_kind.get(
        "design_binding_manifest")
    if (isinstance(design_id, str) and design_id.startswith("sha256:")
            and (design_binding_record is None or
                 design_id.removeprefix("sha256:")
                 != design_binding_record["sha256"])):
        blockers.append("design_id is not the design_binding_manifest SHA")

    cohort_members = {
        kind: artifact_records_by_kind[kind]["sha256"]
        for kind in COHORT_SHARED_ARTIFACT_KINDS
        if kind in artifact_records_by_kind
    }
    power_value = manifest.get("power")
    power_qualified_value = (
        power_value.get("qualified_for_promotion")
        if isinstance(power_value, dict) else None
    )
    if (power_qualified_value is True and
            "power_workload_manifest" in artifact_records_by_kind):
        cohort_members["power_workload_manifest"] = (
            artifact_records_by_kind["power_workload_manifest"]["sha256"])
    cohort_complete = (
        policy_sha256 is not None
        and all(kind in cohort_members for kind in COHORT_SHARED_ARTIFACT_KINDS)
        and (power_qualified_value is not True
             or "power_workload_manifest" in cohort_members)
    )
    expected_cohort_sha256: str | None = None
    if cohort_complete:
        area_value = manifest.get("area")
        area_contract = area_value if isinstance(area_value, dict) else {}
        expected_cohort_sha256 = canonical_digest({
            "schema": COHORT_FINGERPRINT_SCHEMA,
            "policy_sha256": policy_sha256,
            "claim_tier": manifest.get("claim_tier"),
            "shared_artifact_sha256": cohort_members,
            "area_contract": {
                "metric_kind": area_contract.get("metric_kind"),
                "unit": area_contract.get("unit"),
                "unknown_cell_types": area_contract.get("unknown_cell_types"),
            },
        })
        if manifest.get("cohort_id") != f"sha256:{expected_cohort_sha256}":
            blockers.append("cohort_id is not the verified shared-input fingerprint")
    else:
        blockers.append("cohort shared-input binding is incomplete")

    manifest_claims_sha256 = canonical_digest({
        key: manifest.get(key) for key in CLAIM_BINDING_KEYS
    })
    binding = artifact_json_by_kind.get("design_binding_manifest")
    if binding is not None:
        if binding.get("schema") != DESIGN_BINDING_SCHEMA:
            errors.append("unsupported design_binding_manifest schema")
        if binding.get("policy") != policy_rel:
            blockers.append("design binding policy path mismatch")
        if binding.get("policy_sha256") != policy_sha256:
            blockers.append("design binding policy SHA mismatch")
        if binding.get("policy_id") != manifest.get("policy_id"):
            blockers.append("design binding policy_id mismatch")
        if binding.get("claim_tier") != manifest.get("claim_tier"):
            blockers.append("design binding claim tier mismatch")
        if binding.get("cohort_id") != manifest.get("cohort_id"):
            blockers.append("design binding cohort mismatch")
        if (expected_cohort_sha256 is not None and
                binding.get("cohort_fingerprint_sha256")
                != expected_cohort_sha256):
            blockers.append("design binding cohort fingerprint mismatch")
        expected_members = {
            kind: {
                "path": record["path"],
                "sha256": record["sha256"],
            }
            for kind, record in artifact_records_by_kind.items()
            if kind != "design_binding_manifest"
        }
        if binding.get("artifacts") != expected_members:
            blockers.append("design binding artifact membership mismatch")
        if binding.get("claims_sha256") != manifest_claims_sha256:
            blockers.append("design binding claims digest mismatch")

    functional = manifest.get("functional", {})
    if not isinstance(functional, dict):
        errors.append("functional must be an object")
        functional = {}
    expected_functional = policy.get("functional", {})
    if not isinstance(expected_functional, dict):
        errors.append("policy functional section must be an object")
        expected_functional = {}
    for key, required_key in (("module", "module_required"),
                              ("official", "official_required"),
                              ("am", "am_required")):
        result = functional.get(key, {})
        required = expected_functional.get(required_key)
        if not isinstance(result, dict):
            errors.append(f"functional result must be an object: {key}")
            result = {}
        for count_name in ("passed", "required", "failed"):
            count = result.get(count_name)
            if not isinstance(count, int) or isinstance(count, bool) or count < 0:
                errors.append(
                    f"functional count must be a non-negative integer: "
                    f"{key}.{count_name}")
        if (result.get("passed") != required
                or result.get("required") != required
                or result.get("failed") != 0):
            blockers.append(f"functional gate failed or drifted: {key}")
    difftest_mismatches = functional.get("difftest_mismatches")
    difftest_limit = expected_functional.get("difftest_max_mismatches")
    if not strict_nonnegative_int(difftest_limit):
        errors.append("policy Difftest mismatch limit must be a non-negative integer")
    if not strict_nonnegative_int(difftest_mismatches):
        errors.append("Difftest mismatch count must be a non-negative integer")
    elif strict_nonnegative_int(difftest_limit) and difftest_mismatches > difftest_limit:
        blockers.append("Difftest mismatch gate failed")
    cm = functional.get("coremark", {})
    if not isinstance(cm, dict):
        errors.append("CoreMark result must be an object")
        cm = {}
    if not isinstance(cm.get("pass"), bool):
        errors.append("CoreMark pass must be a boolean")
    coremark_good_trap = cm.get("good_trap_count")
    if not (cm.get("pass") is True
            and cm.get("iterations")
            == expected_functional.get("coremark_iterations")
            and cm.get("crc") == expected_functional.get("coremark_crc")
            and isinstance(coremark_good_trap, int)
            and not isinstance(coremark_good_trap, bool)
            and coremark_good_trap == 1):
        blockers.append("CoreMark semantic gate failed")
    dh = functional.get("dhrystone", {})
    if not isinstance(dh, dict):
        errors.append("Dhrystone result must be an object")
        dh = {}
    if not isinstance(dh.get("pass"), bool):
        errors.append("Dhrystone pass must be a boolean")
    dhrystone_good_trap = dh.get("good_trap_count")
    if not (dh.get("pass") is True
            and dh.get("runs") == expected_functional.get("dhrystone_runs")
            and isinstance(dhrystone_good_trap, int)
            and not isinstance(dhrystone_good_trap, bool)
            and dhrystone_good_trap == 1):
        blockers.append("Dhrystone semantic gate failed")

    performance = manifest.get("performance", {})
    if not isinstance(performance, dict):
        errors.append("performance must be an object")
        performance = {}
    if (expected_performance_schema in (
            "npc-rv64-performance-evidence-v4",
            "npc-rv64-performance-evidence-v5",
            "npc-rv64-performance-evidence-v6",
            "npc-rv64-performance-evidence-v7",
            "npc-rv64-performance-evidence-v8")
            and performance.get("performance_measurement_contract_id") !=
            measurement_contract_id):
        errors.append("performance measurement contract binding mismatch")
    if (expected_performance_schema in (
            "npc-rv64-performance-evidence-v5",
            "npc-rv64-performance-evidence-v6",
            "npc-rv64-performance-evidence-v7",
            "npc-rv64-performance-evidence-v8")
            and performance.get("performance_counter_schema_id") !=
            performance_counter_schema_id):
        errors.append("performance counter schema binding mismatch")
    mhz = performance.get("qualified_mhz")
    if performance.get("evidence_schema") != expected_performance_schema:
        blockers.append("performance evidence schema is missing or drifted")
    if "cpi_scope" in performance:
        errors.append(
            f"global performance.cpi_scope is forbidden by "
            f"{expected_performance_schema}")
    weighted_log = 0.0
    weight_sum = 0.0
    benchmark_items = performance.get("benchmarks", [])
    if not isinstance(benchmark_items, list):
        errors.append("performance benchmarks must be a list")
        benchmark_items = []
    by_name: dict[str, dict[str, Any]] = {}
    for item in benchmark_items:
        if not isinstance(item, dict):
            errors.append("benchmark entry must be an object")
            continue
        name = item.get("name")
        if not isinstance(name, str) or not name or name in by_name:
            errors.append(f"invalid or duplicate benchmark name: {name!r}")
            continue
        by_name[name] = item
    raw_semantic_specs = {
        "coremark": (
            cm,
            ("pass", "good_trap_count", "iterations", "crc"),
        ),
        "dhrystone_10000": (
            dh,
            ("pass", "good_trap_count", "runs"),
        ),
    }

    weights = policy.get("benchmarks", {})
    if not isinstance(weights, dict) or not weights:
        errors.append("benchmark policy weights are missing")
        weights = {}
    elif set(weights) != set(expected_counter_scopes):
        errors.append("benchmark policy set does not match evidence contracts")
    for name, weight in weights.items():
        if not finite_number(weight) or weight <= 0:
            errors.append(f"invalid benchmark weight: {name}")
            continue
        item = by_name.get(name)
        if not isinstance(item, dict):
            errors.append(f"missing benchmark: {name}")
            continue
        contract = benchmark_performance_contracts.get(name)
        if not isinstance(contract, dict):
            errors.append(
                f"benchmark performance contract is unavailable: {name}")
            continue
        expected_scope = contract.get("counter_scope")
        if item.get("counter_scope") != expected_scope:
            errors.append(
                f"performance counter scope mismatch: {name}")
        expected_raw_kinds_value = contract.get("raw_log_artifact_kinds")
        expected_raw_kinds = (
            expected_raw_kinds_value
            if isinstance(expected_raw_kinds_value, list) else []
        )
        expected_raw_kind_set = set(expected_raw_kinds)
        semantic_spec = raw_semantic_specs.get(name)
        if semantic_spec is None:
            errors.append(f"raw semantic contract is unavailable: {name}")
            continue
        semantic_summary, semantic_fields = semantic_spec

        cycles = item.get("cycles")
        retired = item.get("retired_instructions")
        cpi = item.get("cpi")
        ipc = item.get("ipc")
        throughput = item.get("throughput_mips")
        if (not strict_positive_int(cycles)
                or not strict_positive_int(retired)):
            errors.append(f"cycles/retired must be positive integers: {name}")
            continue

        repetitions = item.get("repetitions")
        used_raw_kinds: set[str] = set()
        used_raw_paths: set[str] = set()
        if not isinstance(repetitions, list):
            blockers.append(f"performance repetitions are missing: {name}")
        else:
            reference_counter_evidence: dict[str, Any] | None = None
            if len(repetitions) < minimum_repetitions:
                blockers.append(
                    f"performance repetition count is insufficient: {name}")
            if len(repetitions) != len(expected_raw_kinds):
                blockers.append(
                    f"performance repetition/raw-log inventory mismatch: {name}")
            for repetition_index, repetition in enumerate(repetitions, start=1):
                repetition_label = f"{name}[{repetition_index}]"
                if not isinstance(repetition, dict):
                    errors.append(
                        f"performance repetition must be an object: "
                        f"{repetition_label}")
                    continue
                repeat_cycles = repetition.get("cycles")
                repeat_retired = repetition.get("retired_instructions")
                if (not strict_positive_int(repeat_cycles)
                        or not strict_positive_int(repeat_retired)):
                    errors.append(
                        f"performance repetition counters must be positive "
                        f"integers: {repetition_label}")
                    continue
                if repetition.get("counter_scope") != expected_scope:
                    errors.append(
                        f"performance repetition counter scope mismatch: "
                        f"{repetition_label}")
                if (require_bit_exact_repetitions
                        and (repeat_cycles != cycles
                             or repeat_retired != retired)):
                    blockers.append(
                        f"performance repetition counters are not bit-exact: "
                        f"{repetition_label}")

                raw_kind = repetition.get("raw_log_artifact_kind")
                raw_path = repetition.get("raw_log_artifact_path")
                if not isinstance(raw_kind, str) or not raw_kind:
                    errors.append(
                        f"performance raw-log artifact kind is invalid: "
                        f"{repetition_label}")
                    continue
                if not isinstance(raw_path, str) or not raw_path:
                    errors.append(
                        f"performance raw-log artifact path is invalid: "
                        f"{repetition_label}")
                    continue
                if raw_kind not in expected_raw_kind_set:
                    errors.append(
                        f"unexpected performance raw-log artifact kind: "
                        f"{repetition_label}={raw_kind}")
                    continue
                if raw_kind in used_raw_kinds:
                    errors.append(
                        f"performance raw-log artifact kind reused: "
                        f"{repetition_label}={raw_kind}")
                used_raw_kinds.add(raw_kind)
                if raw_path in used_raw_paths:
                    errors.append(
                        f"performance raw-log artifact path reused: "
                        f"{repetition_label}={raw_path}")
                used_raw_paths.add(raw_path)

                record = artifact_records_by_kind.get(raw_kind)
                if record is None:
                    blockers.append(
                        f"raw benchmark log evidence is missing: "
                        f"{repetition_label}")
                    continue
                if record["path"] != raw_path:
                    errors.append(
                        f"performance raw-log artifact path mismatch: "
                        f"{repetition_label}")
                try:
                    parsed = parse_raw_benchmark_log(
                        record["resolved"], name, expected_scope, contract,
                        expected_performance_schema,
                        performance_counter_contract)
                except ValueError as exc:
                    errors.append(
                        f"{repetition_label}: {exc}")
                    continue
                if parsed["exit_code"] != 0:
                    errors.append(
                        f"raw benchmark exit code is nonzero: "
                        f"{repetition_label}={parsed['exit_code']}")
                for field in semantic_fields:
                    if semantic_summary.get(field) != parsed[field]:
                        errors.append(
                            f"raw benchmark summary mismatch: "
                            f"{repetition_label}.{field}")
                if (parsed["cycles"] != repeat_cycles
                        or parsed["retired_instructions"] != repeat_retired):
                    errors.append(
                        f"raw benchmark counters mismatch repetition: "
                        f"{repetition_label}")
                if (parsed["cycles"] != cycles
                        or parsed["retired_instructions"] != retired):
                    errors.append(
                        f"raw benchmark counters mismatch summary: "
                        f"{repetition_label}")
                if expected_performance_schema in (
                        "npc-rv64-performance-evidence-v5",
                        "npc-rv64-performance-evidence-v6",
                        "npc-rv64-performance-evidence-v7",
                        "npc-rv64-performance-evidence-v8"):
                    counter_evidence = {
                        "cpi_stack": parsed.get("cpi_stack"),
                        "retire_slots": parsed.get("retire_slots"),
                    }
                    if reference_counter_evidence is None:
                        reference_counter_evidence = counter_evidence
                    elif (require_bit_exact_repetitions
                          and counter_evidence != reference_counter_evidence):
                        errors.append(
                            "performance counter stack is not bit-exact: "
                            f"{repetition_label}")
            if used_raw_kinds != expected_raw_kind_set:
                blockers.append(
                    f"performance raw-log artifact references are incomplete: "
                    f"{name}")
        if not all(finite_number(v) and v > 0 for v in (cpi, ipc, throughput, mhz)):
            errors.append(f"invalid performance number: {name}")
            continue
        if abs(cycles / retired - cpi) > 5e-9:
            errors.append(f"CPI arithmetic mismatch: {name}")
        if abs(1.0 / cpi - ipc) > 5e-9:
            errors.append(f"IPC arithmetic mismatch: {name}")
        if abs(mhz / cpi - throughput) > 5e-9:
            errors.append(f"throughput arithmetic mismatch: {name}")
        weighted_log += float(weight) * math.log(throughput)
        weight_sum += float(weight)
    derived_weighted = performance.get("weighted_throughput_mips")
    if weight_sum <= 0:
        errors.append("benchmark weight sum must be positive")
    elif not finite_number(derived_weighted):
        errors.append("weighted throughput is missing or invalid")
    else:
        derived = math.exp(weighted_log / weight_sum)
        if abs(derived - derived_weighted) > 5e-9:
            errors.append("weighted throughput arithmetic mismatch")

    architecture = manifest.get("architecture_contract", {})
    if not isinstance(architecture, dict):
        errors.append("architecture_contract must be an object")
        architecture = {}
    architecture_policy = policy.get("architecture", {})
    if not isinstance(architecture_policy, dict):
        errors.append("policy architecture section must be an object")
        architecture_policy = {}

    # A candidate may not satisfy the architecture contract with self-reported
    # booleans alone. Re-run the executable nine-gate evaluator against the
    # bound directed-suite artifact and live RTL, then require the archived
    # result to match that independent evaluation (apart from its timestamp).
    hard_suite_record = artifact_records_by_kind.get(
        "architecture_directed_suite")
    hard_result = artifact_json_by_kind.get(
        "architecture_hard_gates_result")
    if hard_suite_record is not None and hard_result is not None:
        try:
            reevaluated = architecture_hard_gates_tool.evaluate(
                root, hard_suite_record["resolved"])
            semantic_keys = (
                "schema",
                "overall_status",
                "exit_code",
                "contract",
                "rtl_source_set",
                "evidence_manifest",
                "evidence_errors",
                "gates",
            )
            archived_semantics = {
                key: hard_result.get(key) for key in semantic_keys
            }
            reevaluated_semantics = {
                key: reevaluated.get(key) for key in semantic_keys
            }
            if archived_semantics != reevaluated_semantics:
                errors.append(
                    "architecture hard-gate result is stale, tampered, or "
                    "not bound to the directed suite and live RTL")
            if (reevaluated.get("schema")
                    != architecture_hard_gates_tool.RESULT_SCHEMA):
                errors.append("unsupported architecture hard-gate result schema")
            gates = reevaluated.get("gates")
            expected_gate_ids = set(architecture_hard_gates_tool.GATE_IDS)
            if not isinstance(gates, dict) or set(gates) != expected_gate_ids:
                errors.append("architecture hard-gate inventory is incomplete")
            elif any(
                not isinstance(gates[gate_id], dict)
                or gates[gate_id].get("status") != "GREEN"
                for gate_id in architecture_hard_gates_tool.GATE_IDS
            ):
                blockers.append("architecture hard gates are not all GREEN")
            if (reevaluated.get("overall_status") != "GREEN"
                    or reevaluated.get("exit_code") != 0):
                blockers.append("architecture hard-gate overall result is RED")
        except (OSError, UnicodeDecodeError, ValueError) as exc:
            errors.append(f"architecture hard-gate re-evaluation failed: {exc}")
    for name, expected in architecture_policy.get("fixed_contract", {}).items():
        if architecture.get(name) != expected:
            blockers.append(f"fixed architecture contract mismatch: {name}")
    for name, minimum in architecture_policy.get("minimum_capacities", {}).items():
        actual = architecture.get(name)
        if not finite_number(actual) or actual < minimum:
            blockers.append(f"architecture capacity below minimum: {name}")

    directed = architecture.get("directed_evidence", {})
    required_directed = architecture_policy.get("required_directed_evidence", [])
    if not isinstance(directed, dict) or not isinstance(required_directed, list) or not required_directed:
        errors.append("architecture directed-evidence schema is missing")
        directed = {}
        required_directed = []
    expected_architecture_bindings = {
        kind: artifact_records_by_kind[kind]["sha256"]
        for kind in ("source_manifest", "config_manifest", "simulation_binary")
        if kind in artifact_records_by_kind
    }
    architecture_evidence_metrics: dict[str, Any] = {}
    for name in required_directed:
        evidence_value = directed.get(name)
        if not isinstance(evidence_value, bool):
            errors.append(f"architecture evidence flag must be a boolean: {name}")
        if evidence_value is not True:
            blockers.append(f"architecture evidence missing: {name}")
        artifact_kind = f"architecture_{name}"
        if artifact_kind not in artifact_kinds_present:
            blockers.append(f"architecture evidence artifact missing: {name}")
            continue
        evidence = artifact_json_by_kind.get(artifact_kind)
        if evidence is None:
            continue
        if evidence.get("schema") != "npc-rv64-architecture-evidence-v1":
            errors.append(f"unsupported architecture evidence schema: {name}")
        if evidence.get("evidence") != name:
            blockers.append(f"architecture evidence name mismatch: {name}")
        if not isinstance(evidence.get("passed"), bool):
            errors.append(f"architecture evidence pass must be a boolean: {name}")
        if evidence.get("passed") is not True:
            blockers.append(f"architecture evidence did not pass: {name}")
        if evidence.get("claims_sha256") != manifest_claims_sha256:
            blockers.append(f"architecture evidence claims binding mismatch: {name}")
        if evidence.get("input_sha256") != expected_architecture_bindings:
            blockers.append(f"architecture evidence input binding mismatch: {name}")
        evidence_metrics = evidence.get("metrics")
        if not isinstance(evidence_metrics, dict):
            errors.append(f"architecture evidence metrics must be an object: {name}")
            continue
        for metric_name, metric_value in evidence_metrics.items():
            if (metric_name in architecture_evidence_metrics
                    and architecture_evidence_metrics[metric_name]
                    != metric_value):
                errors.append(
                    f"conflicting architecture evidence metric: {metric_name}")
            else:
                architecture_evidence_metrics[metric_name] = metric_value

    metrics = architecture.get("directed_metrics", {})
    if not isinstance(metrics, dict):
        errors.append("architecture directed_metrics must be an object")
        metrics = {}
    for metric_name, metric_value in metrics.items():
        if architecture_evidence_metrics.get(metric_name) != metric_value:
            blockers.append(
                f"architecture metric is not bound to directed evidence: {metric_name}")
    scalar_metric_gates = (
        ("frontend_packets_observed", architecture_policy.get("frontend_packets"), "minimum"),
        ("frontend_max_initiation_interval",
         architecture_policy.get("frontend_max_initiation_interval"), "maximum"),
        ("independent_alu_ipc", architecture_policy.get("independent_alu_min_ipc"), "minimum"),
        ("dual_memory_issue_ipc",
         architecture_policy.get("independent_memory_min_ipc"), "minimum"),
        ("minimum_younger_completed_before_old",
         architecture_policy.get("minimum_younger_completed_before_old"), "minimum"),
        ("rob_peak", architecture_policy.get("minimum_rob_peak"), "minimum"),
    )
    for name, limit, direction in scalar_metric_gates:
        actual = metrics.get(name) if isinstance(metrics, dict) else None
        failed = (not finite_number(actual) or not finite_number(limit) or
                  (direction == "minimum" and actual < limit) or
                  (direction == "maximum" and actual > limit))
        if failed:
            blockers.append(f"architecture metric gate failed: {name}")
    for metric_name, policy_name in (("pair_matrix_passed", "required_pair_matrix"),
                                     ("true_ooo_passed", "required_true_ooo")):
        actual = metrics.get(metric_name, [])
        required = architecture_policy.get(policy_name, [])
        actual_valid = (
            isinstance(actual, list)
            and all(isinstance(item, str) and item for item in actual)
            and len(actual) == len(set(actual))
        )
        required_valid = (
            isinstance(required, list)
            and all(isinstance(item, str) and item for item in required)
            and len(required) == len(set(required))
        )
        if not actual_valid or not required_valid:
            errors.append(f"architecture coverage list is invalid: {metric_name}")
        elif not set(required).issubset(set(actual)):
            blockers.append(f"architecture coverage gate failed: {metric_name}")

    timing = manifest.get("timing", {})
    if not isinstance(timing, dict):
        errors.append("timing must be an object")
        timing = {}
    timing_policy = policy.get("timing", {})
    if not isinstance(timing_policy, dict):
        errors.append("policy timing section must be an object")
        timing_policy = {}
    period = timing.get("period_ns")
    policy_period = timing_policy.get("period_ns")
    policy_mhz = timing_policy.get("qualified_mhz")
    if not finite_number(period) or period <= 0:
        blockers.append("timing period is missing or invalid")
    elif period != policy_period:
        blockers.append("timing period does not match policy")
    if (not finite_number(policy_period) or policy_period <= 0 or
            not finite_number(policy_mhz) or
            abs(1000.0 / policy_period - policy_mhz) > 1e-9):
        errors.append("policy period/frequency relation is invalid")
    if timing.get("tier") != policy.get("claim_tier"):
        errors.append("timing tier does not match policy claim tier")
    if timing.get("qualified_mhz") != policy_mhz or mhz != policy_mhz:
        blockers.append("qualified frequency does not match policy")
    worst_slack = timing.get("worst_path_slack_ns")
    if not finite_number(worst_slack) or worst_slack < 0:
        blockers.append("5ns timing has negative/invalid worst slack")
    wns = timing.get("wns_ns")
    if not finite_number(wns):
        errors.append("timing WNS is missing or invalid")
    elif wns < 0:
        blockers.append("timing WNS is negative")
    tns = timing.get("tns_ns")
    violated_paths = timing.get("violated_path_count")
    combinational_loops = timing.get("combinational_loops")
    if not finite_number(tns):
        errors.append("timing TNS is missing or invalid")
    for name, value in (("violated_path_count", violated_paths),
                        ("combinational_loops", combinational_loops)):
        if (not isinstance(value, int) or isinstance(value, bool)
                or value < 0):
            errors.append(f"timing {name} must be a non-negative integer")
    if (tns != timing_policy.get("required_tns_ns", 0.0)
            or violated_paths != timing_policy.get("maximum_violated_paths", 0)
            or combinational_loops
            != timing_policy.get("maximum_combinational_loops", 0)):
        blockers.append("timing TNS/violations/loops gate failed")
    if (not finite_number(worst_slack) or
            worst_slack < timing_policy.get("minimum_worst_slack_ns_for_promotion", math.inf)):
        blockers.append("proxy slack is below promotion margin")
    netlist_sha = timing.get("netlist_sha256")
    mapped_netlist = artifact_records_by_kind.get("mapped_netlist")
    if mapped_netlist is None or netlist_sha != mapped_netlist["sha256"]:
        blockers.append("timing netlist SHA is not bound to mapped_netlist artifact")
    if timing.get("tier") == "rtl_proxy_partial_constraints":
        ideal_clock = timing.get("ideal_clock")
        if not isinstance(ideal_clock, bool):
            errors.append("timing ideal_clock must be a boolean")
        if ideal_clock is not True or timing.get("macro_model_kind") != "placeholder":
            errors.append("proxy tier model declaration is inconsistent")

    sta_summary = artifact_json_by_kind.get("sta_summary")
    if sta_summary is not None:
        for name in (
            "period_ns",
            "wns_ns",
            "tns_ns",
            "worst_path_slack_ns",
            "violated_path_count",
            "combinational_loops",
        ):
            if sta_summary.get(name) != timing.get(name):
                blockers.append(f"STA summary timing mismatch: {name}")
        for name in (
            "synth_binding_match",
            "synth_pre_binding_match",
            "opensta_freeze_match",
            "setup_member_set_match",
            "setup_probe_match",
            "hardening_mutations_passed",
            "timing_paths_met",
            "target_200mhz_met",
        ):
            value = sta_summary.get(name)
            if not isinstance(value, bool):
                errors.append(f"STA summary {name} must be a boolean")
            if value is not True:
                blockers.append(f"STA summary attestation failed: {name}")
        setup_warning_counts = sta_summary.get("setup_warning_counts")
        if not isinstance(setup_warning_counts, dict):
            errors.append("STA summary setup_warning_counts must be an object")
        else:
            for name in (
                "missing_input_delay",
                "missing_output_delay",
                "unconstrained_endpoints",
            ):
                if setup_warning_counts.get(name) != timing.get(name):
                    blockers.append(f"STA setup warning count mismatch: {name}")
        sta_setup = artifact_records_by_kind.get("sta_setup_manifest")
        if (sta_setup is not None
                and sta_summary.get("setup_members_manifest_sha256")
                != sta_setup["sha256"]):
            blockers.append("STA summary is not bound to sta_setup_manifest")

    area = manifest.get("area", {})
    area_policy = policy.get("area_proxy", {})
    if not isinstance(area, dict):
        errors.append("area must be an object")
        area = {}
    if not isinstance(area_policy, dict):
        errors.append("policy area_proxy section must be an object")
        area_policy = {}
    if (area.get("metric_kind") != area_policy.get("metric_kind") or
            area.get("unit") != area_policy.get("unit")):
        blockers.append("area proxy metric or unit drifted")
    if area.get("unknown_cell_types") != area_policy.get("unknown_cell_types"):
        blockers.append("area proxy unknown-cell inventory drifted")
    if not finite_number(area.get("logic_area")) or area.get("logic_area") <= 0:
        errors.append("logic area is invalid")
    macro_area_complete = area.get("macro_area_complete")
    if not isinstance(macro_area_complete, bool):
        errors.append("macro_area_complete must be a boolean")
    if macro_area_complete is not True:
        if args.target == "final_champion":
            blockers.append("total area axis is unqualified")
        warnings.append("total area is unqualified because macro area is incomplete")
    else:
        total_area = area.get("total_area")
        if not finite_number(total_area) or total_area <= 0:
            errors.append("qualified total area is invalid")
        elif (finite_number(area.get("logic_area"))
              and total_area < area["logic_area"]):
            errors.append("qualified total area is smaller than logic area")
        if "macro_area_manifest" not in artifact_kinds_present:
            blockers.append("qualified area is missing macro_area_manifest")
        macro_area_manifest = artifact_json_by_kind.get("macro_area_manifest")
        if macro_area_manifest is not None:
            if macro_area_manifest.get("schema") != "npc-rv64-macro-area-v1":
                errors.append("unsupported macro_area_manifest schema")
            if macro_area_manifest.get("complete") is not True:
                blockers.append("macro area manifest is incomplete")
            models = macro_area_manifest.get("models")
            if not isinstance(models, list) or not models:
                errors.append("macro area models must be a non-empty list")
                models = []
            derived_macro_area = 0.0
            for model in models:
                if not isinstance(model, dict):
                    errors.append("macro area model must be an object")
                    continue
                count = model.get("instance_count")
                model_area = model.get("area")
                if (not isinstance(count, int) or isinstance(count, bool)
                        or count <= 0 or not finite_number(model_area)
                        or model_area <= 0 or not is_sha256(
                            model.get("model_sha256"))):
                    errors.append("macro area model is invalid or placeholder")
                    continue
                derived_macro_area += count * model_area
            if (finite_number(total_area) and finite_number(area.get("logic_area"))
                    and abs(total_area - area["logic_area"] - derived_macro_area)
                    > 1e-9 * max(total_area, 1.0)):
                blockers.append("total area does not equal logic plus macro area")
    power = manifest.get("power", {})
    if not isinstance(power, dict):
        errors.append("power must be an object")
        power = {}
    qualified_power = power.get("qualified_for_promotion")
    if not isinstance(qualified_power, bool):
        errors.append("qualified_for_promotion must be a boolean")
    if qualified_power is not True:
        if args.target == "final_champion":
            blockers.append("power axis is unqualified")
        warnings.append("vectorless power proxy is report-only")
    else:
        power_policy = policy.get("power", {})
        if not isinstance(power_policy, dict):
            errors.append("policy power section must be an object")
            power_policy = {}
        total_power = power.get("total_power_w")
        coverage = power.get("activity_coverage")
        if power.get("metric_kind") != power_policy.get("qualified_metric_kind"):
            blockers.append("qualified power metric kind is invalid")
        if not finite_number(total_power) or total_power <= 0:
            errors.append("qualified total power is invalid")
        macro_power_complete = power.get("macro_power_complete")
        if not isinstance(macro_power_complete, bool):
            errors.append("macro_power_complete must be a boolean")
        require_macro_power = power_policy.get(
            "require_macro_power_complete", True)
        if not isinstance(require_macro_power, bool):
            errors.append(
                "policy require_macro_power_complete must be a boolean")
            require_macro_power = True
        if require_macro_power and macro_power_complete is not True:
            blockers.append("qualified power is missing macro power")
        if (not finite_number(coverage) or
                coverage < power_policy.get("minimum_activity_coverage", 0.95)):
            blockers.append("qualified power activity coverage is insufficient")
        for kind in (
            "power_activity",
            "power_report",
            "macro_power_manifest",
            "power_workload_manifest",
        ):
            if kind not in artifact_kinds_present:
                blockers.append(f"qualified power artifact missing: {kind}")

        workload = artifact_json_by_kind.get("power_workload_manifest")
        if workload is not None:
            if workload.get("schema") != "npc-rv64-power-workload-v1":
                errors.append("unsupported power_workload_manifest schema")
            expected_images = {
                kind: artifact_records_by_kind[kind]["sha256"]
                for kind in ("coremark_image", "dhrystone_image")
                if kind in artifact_records_by_kind
            }
            if workload.get("benchmark_image_sha256") != expected_images:
                blockers.append("power workload benchmark image binding mismatch")

        macro_power_manifest = artifact_json_by_kind.get(
            "macro_power_manifest")
        derived_macro_power = 0.0
        if macro_power_manifest is not None:
            if (macro_power_manifest.get("schema")
                    != "npc-rv64-macro-power-v1"):
                errors.append("unsupported macro_power_manifest schema")
            if macro_power_manifest.get("complete") is not True:
                blockers.append("macro power manifest is incomplete")
            models = macro_power_manifest.get("models")
            if not isinstance(models, list) or not models:
                errors.append("macro power models must be a non-empty list")
                models = []
            for model in models:
                if not isinstance(model, dict):
                    errors.append("macro power model must be an object")
                    continue
                count = model.get("instance_count")
                leakage = model.get("leakage_power_w")
                dynamic = model.get("dynamic_power_w")
                if (not isinstance(count, int) or isinstance(count, bool)
                        or count <= 0 or not finite_number(leakage)
                        or leakage < 0 or not finite_number(dynamic)
                        or dynamic < 0 or leakage + dynamic <= 0
                        or not is_sha256(model.get("model_sha256"))):
                    errors.append("macro power model is invalid or placeholder")
                    continue
                derived_macro_power += count * (leakage + dynamic)

        power_report = artifact_json_by_kind.get("power_report")
        if power_report is not None:
            if power_report.get("schema") != "npc-rv64-power-report-v1":
                errors.append("unsupported power_report schema")
            for name, expected in (
                ("metric_kind", power.get("metric_kind")),
                ("total_power_w", total_power),
                ("activity_coverage", coverage),
                ("netlist_sha256", netlist_sha),
            ):
                if power_report.get(name) != expected:
                    blockers.append(f"power report mismatch: {name}")
            for field, kind in (
                ("power_activity_sha256", "power_activity"),
                ("macro_power_manifest_sha256", "macro_power_manifest"),
                ("power_workload_manifest_sha256",
                 "power_workload_manifest"),
            ):
                record = artifact_records_by_kind.get(kind)
                if record is None or power_report.get(field) != record["sha256"]:
                    blockers.append(f"power report artifact binding mismatch: {field}")
            logic_power = power_report.get("logic_power_w")
            macro_power = power_report.get("macro_power_w")
            if (not finite_number(logic_power) or logic_power < 0
                    or not finite_number(macro_power) or macro_power <= 0):
                errors.append("power report logic/macro components are invalid")
            elif (not finite_number(total_power)
                  or abs(total_power - logic_power - macro_power)
                  > 1e-9 * max(total_power, 1.0)):
                blockers.append("total power does not equal logic plus macro power")
            if (finite_number(macro_power)
                    and abs(macro_power - derived_macro_power)
                    > 1e-9 * max(macro_power, 1.0)):
                blockers.append("power report macro total disagrees with manifest")

    print(f"manifest={manifest.get('baseline_id')}")
    print(f"target={args.target}")
    if errors:
        print("STRUCTURAL FAIL")
        for item in errors:
            print(f"ERROR: {item}")
    else:
        print("STRUCTURAL PASS")
    if errors or blockers:
        print("PROMOTABLE NO")
        for item in sorted(set(blockers)):
            print(f"BLOCKER: {item}")
    else:
        print("PROMOTABLE YES")
    for item in warnings:
        print(f"WARNING: {item}")

    return checker_exit_code(errors, blockers, args.report_only)


if __name__ == "__main__":
    sys.exit(main())
