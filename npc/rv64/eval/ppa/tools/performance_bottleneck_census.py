#!/usr/bin/env python3
"""Build a deterministic CPI residency census from canonical PERF_BASELINE."""

from __future__ import annotations

import argparse
from decimal import Decimal
import json
import os
import pathlib
import sys
import tempfile
from typing import Any


TOOLS_DIR = pathlib.Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import performance_baseline_current as baseline  # noqa: E402


SCHEMA = "npc-rv64-cpi-bottleneck-census-v2"
STATUS = "CPI_BOTTLENECK_CENSUS"
CYCLE_BUCKETS = (
    "useful", "rob_empty", "dependency", "issue_terminal",
    "execution_latency", "memory_latency", "head_lifecycle_unknown",
    "exception_redirect", "memory_commit", "serialization", "unknown",
)
SLOT_BUCKETS = (
    "retired", "rob_empty", "dependency", "issue_terminal",
    "execution_latency", "memory_latency", "head_lifecycle_unknown",
    "exception_redirect", "memory_commit", "serialization", "unknown",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise baseline.BaselineError(message)


def lexical_parts(value: str, label: str) -> tuple[str, ...]:
    require(isinstance(value, str) and value, f"{label} path is invalid")
    require("\\" not in value, f"{label} path must use workspace separators")
    pure = pathlib.PurePosixPath(value)
    require(not pure.is_absolute(), f"{label} path must be workspace relative")
    require(all(part not in ("", ".", "..") for part in pure.parts),
            f"{label} path contains an unsafe component")
    return pure.parts


def argument_relative(
    root: pathlib.Path, value: pathlib.Path, label: str,
) -> str:
    if value.is_absolute():
        try:
            relative_value = value.relative_to(root)
        except ValueError as exc:
            raise baseline.BaselineError(
                f"{label} escapes workspace") from exc
    else:
        relative_value = value
    raw = relative_value.as_posix()
    lexical_parts(raw, label)
    return raw


def workspace_path(
    root: pathlib.Path, value: str, label: str, *, must_exist: bool = True,
) -> pathlib.Path:
    parts = lexical_parts(value, label)
    current = root
    for part in parts:
        current = current / part
        if current.exists() or current.is_symlink():
            require(not current.is_symlink(), f"{label} path uses a symlink")
    resolved = root.joinpath(*parts).resolve(strict=False)
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise baseline.BaselineError(f"{label} escapes workspace") from exc
    if must_exist:
        require(resolved.is_file(), f"{label} is missing")
    return resolved


def resolve_input(
    root: pathlib.Path, value: pathlib.Path, label: str,
) -> pathlib.Path:
    return workspace_path(root, argument_relative(root, value, label), label)


def resolve_output(
    root: pathlib.Path, value: pathlib.Path, label: str,
) -> pathlib.Path:
    path = workspace_path(
        root, argument_relative(root, value, label), label, must_exist=False)
    require(not path.exists() or path.is_file(),
            f"{label} must be a regular file path")
    return path


def validate_artifact(
    root: pathlib.Path, value: Any, label: str,
) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} artifact is invalid")
    path = workspace_path(root, value.get("path"), label)
    require(value.get("sha256") == baseline.sha256(path),
            f"{label} sha256 mismatch")
    require(value.get("size_bytes") == path.stat().st_size,
            f"{label} size mismatch")
    return path


def ratio(value: int, total: int) -> str:
    require(isinstance(value, int) and isinstance(total, int) and total > 0,
            "ratio inputs are invalid")
    return format(Decimal(value) / Decimal(total), ".9f")


def ranked(values: dict[str, int], total: int) -> list[dict[str, Any]]:
    require(sum(values.values()) == total, "ranked ledger does not conserve")
    return [
        {
            "name": name,
            "cycles_or_slots": value,
            "fraction": ratio(value, total),
        }
        for name, value in sorted(
            values.items(), key=lambda item: (-item[1], item[0]))
    ]


def validate_current_baseline(
    root: pathlib.Path, path: pathlib.Path,
) -> dict[str, Any]:
    stored = baseline.read_json(path, "canonical performance baseline")
    # current baseline 已进入 direct v3；census 同时保留 v2 replay 兼容，
    # 但两条路径都必须由各自 manifest 重新构造后逐字段相等。
    require(stored.get("schema") in (
                baseline.RESULT_SCHEMA, baseline.DIRECT_RESULT_SCHEMA)
            and stored.get("status") == "PERF_BASELINE",
            "input is not canonical PERF_BASELINE v2/v3")
    manifest_path = baseline.validate_artifact(
        root, stored.get("manifest"), "performance baseline manifest")
    recomputed = baseline.build_result(root, manifest_path)
    require(stored == recomputed, "performance baseline is not canonical")
    require(stored.get("blockers") == []
            and stored.get("ppa") == "UNQUALIFIED"
            and stored.get("promotion_eligible") is False,
            "performance baseline claim boundary mismatch")
    return stored


def workload_census(workload: dict[str, Any]) -> dict[str, Any]:
    cycles = workload["cycles"]
    retired = workload["retired_instructions"]
    stack = workload["cpi_stack"]
    slots = workload["retire_slots"]
    cycle_values = {name: stack[name] for name in CYCLE_BUCKETS}
    slot_values = {name: slots[name] for name in SLOT_BUCKETS}
    memory_values = stack["memory_lifecycle"]
    request_values = stack["memory_request_detail"]
    memory_total = stack["memory_latency"]
    request_total = memory_values["request_outstanding"]
    require(stack["unknown_ratio"] == 0.0,
            "current census requires zero unknown cycle ratio")
    return {
        "cycles": cycles,
        "retired_instructions": retired,
        "cpi": workload["cpi"],
        "ipc": workload["ipc"],
        "cycle_residency_rank": ranked(cycle_values, cycles),
        "memory_lifecycle_rank": ranked(memory_values, memory_total),
        "memory_request_detail_rank": ranked(request_values, request_total),
        "slot_residency_rank": ranked(slot_values, slots["capacity"]),
        "key_ratios": {
            "useful_cycles": ratio(stack["useful"], cycles),
            "memory_latency_cycles": ratio(memory_total, cycles),
            "request_outstanding_cycles": ratio(request_total, cycles),
            "axi_write_response_cycles": ratio(
                request_values["axi_write_response"], cycles),
            "unused_retire_slots": ratio(slots["unused"], slots["capacity"]),
        },
        "unknown_cycle_ratio": "0.000000000",
    }


def build_census(
    root: pathlib.Path, baseline_path: pathlib.Path,
) -> dict[str, Any]:
    current = validate_current_baseline(root, baseline_path)
    workloads = {
        name: workload_census(current["benchmarks"][name])
        for name in ("coremark", "dhrystone_10000")
    }
    dominant = {}
    for name, value in workloads.items():
        dominant[name] = {
            "cycle_residency": value["cycle_residency_rank"][0]["name"],
            "memory_lifecycle": value["memory_lifecycle_rank"][0]["name"],
            "memory_request_detail": value[
                "memory_request_detail_rank"][0]["name"],
        }
    require(all(value == {
        "cycle_residency": "memory_latency",
        "memory_lifecycle": "request_outstanding",
        "memory_request_detail": "axi_write_response",
    } for value in dominant.values()),
        "workloads do not converge on the expected residency hierarchy")
    return {
        "schema": SCHEMA,
        "status": STATUS,
        "design_id": current["design_id"],
        "performance_baseline": baseline.artifact(root, baseline_path),
        "workloads": workloads,
        "cross_workload_observation": {
            "dominant_residency_hierarchy": dominant,
            "converges": True,
            "interpretation": (
                "Both workloads spend the largest cycle residency in a memory "
                "head, primarily while a request is outstanding, with "
                "S_WRITE_RESP as the largest request-state residency."
            ),
            "causal_status": "HYPOTHESIS_NOT_PROVEN",
            "warning": (
                "These are mutually exclusive ROB-head residency buckets, not "
                "transaction counts or proof that AXI B latency is the sole cause."
            ),
        },
        "competing_hypotheses": [
            {
                "id": "H1_B_RESPONSE_LATENCY",
                "statement": (
                    "The downstream memory model's AW/W-to-B latency directly "
                    "dominates the observed S_WRITE_RESP residency."
                ),
            },
            {
                "id": "H2_WRITE_CONCURRENCY",
                "statement": (
                    "A single outstanding bridge/owner policy exposes B latency "
                    "at the ROB head because independent memory work cannot overlap."
                ),
            },
            {
                "id": "H3_HEAD_RESIDENCY_WEIGHTING",
                "statement": (
                    "Long-lived store/AMO owners are overrepresented in a head "
                    "residency ledger even if their transaction frequency is low."
                ),
            },
            {
                "id": "H4_PRE_REQUEST_PIPELINE",
                "statement": (
                    "Reservation-queue and translation-order residency remains "
                    "material, so improving B response alone may shift rather than "
                    "remove the memory bottleneck."
                ),
            },
        ],
        "next_discriminating_measurement": {
            "schema": "npc-rv64-cpi-discriminator-plan-v1",
            "action": (
                "Add diagnostic-only owner-correlated event counts, fixed-bin "
                "duration histograms and bridge/pre-request timing channels so "
                "H1 through H4 can be separated before choosing an RTL change."
            ),
            "channels": {
                "owner_transaction": {
                    "operation_classes": ["STORE", "AMO", "A-D"],
                    "observations": [
                        "per-owner transaction count",
                        "S_WRITE_REQ duration histogram",
                        "S_WRITE_RESP duration histogram",
                    ],
                },
                "bridge_timing": {
                    "observations": [
                        "AW/W completion to BVALID interval",
                        "owner wait before bridge admission",
                        "write in-flight occupancy",
                        "overlap with independent memory work",
                    ],
                },
                "pre_request_pipeline": {
                    "observations": [
                        "reservation-queue entry/exit count and duration histogram",
                        "translation-order entry/exit count and duration histogram",
                        "ROB-head owner correlation for each pre-request interval",
                    ],
                },
            },
            "hypothesis_discrimination_matrix": {
                "H1_B_RESPONSE_LATENCY": [
                    "AW/W completion to BVALID interval",
                    "S_WRITE_RESP duration histogram",
                ],
                "H2_WRITE_CONCURRENCY": [
                    "owner wait before bridge admission",
                    "write in-flight occupancy",
                    "overlap with independent memory work",
                ],
                "H3_HEAD_RESIDENCY_WEIGHTING": [
                    "per-owner transaction count",
                    "S_WRITE_REQ duration histogram",
                    "S_WRITE_RESP duration histogram",
                    "ROB-head owner correlation for each pre-request interval",
                ],
                "H4_PRE_REQUEST_PIPELINE": [
                    "reservation-queue entry/exit count and duration histogram",
                    "translation-order entry/exit count and duration histogram",
                    "ROB-head owner correlation for each pre-request interval",
                ],
            },
            "measurement_contract": [
                "declare fixed histogram bins before workload execution",
                "keep event counts distinct from ROB-head cycle residency",
                "bind every interval to one stable transaction owner and operation class",
                "report complete, overflow, invalid and conservation fields",
            ],
            "must_preserve": [
                "production request/response/retirement semantics",
                "current workload, ROI, simulator, config and latency profile",
                "all existing assertions and v4 conservation checks",
            ],
            "decision_rule": (
                "Select one RTL optimization mechanism only after both workloads "
                "provide complete owner-correlated observations that distinguish "
                "B latency, bridge concurrency, head weighting and pre-request "
                "pipeline residency without unknown or conservation debt."
            ),
        },
        "optimization_candidate_authorized": False,
        "blockers_to_candidate": [
            "the dominant residency has not yet been separated into transaction count and per-transaction duration",
            "the effect of bridge concurrency versus downstream B latency is not yet discriminated",
            "reservation and translation residency has not yet been separated into owner-correlated pre-request intervals",
        ],
        "ppa": "UNQUALIFIED",
        "promotion_eligible": False,
    }


def write_json(
    root: pathlib.Path, path: pathlib.Path, value: dict[str, Any],
) -> None:
    try:
        path.relative_to(root)
    except ValueError as exc:
        raise baseline.BaselineError("census output escapes workspace") from exc
    require(not path.is_symlink(), "census output must not be a symlink")
    path.parent.mkdir(parents=True, exist_ok=True)
    current = root
    for part in path.relative_to(root).parts[:-1]:
        current = current / part
        require(not current.is_symlink(),
                "census output parent must not be a symlink")
    payload = json.dumps(value, indent=2, sort_keys=True) + "\n"
    descriptor, temporary = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        require(not path.is_symlink(), "census output became a symlink")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root", type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5])
    sub = result.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--baseline", type=pathlib.Path, required=True)
    build.add_argument("--output", type=pathlib.Path, required=True)
    verify = sub.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    try:
        if args.command == "build":
            baseline_path = resolve_input(
                root, args.baseline, "performance baseline")
            result = build_census(root, baseline_path)
            output = resolve_output(root, args.output, "census output")
            write_json(root, output, result)
        else:
            input_path = resolve_input(root, args.input, "CPI bottleneck census")
            stored = baseline.read_json(input_path, "CPI bottleneck census")
            baseline_path = validate_artifact(
                root, stored.get("performance_baseline"), "performance baseline")
            result = build_census(root, baseline_path)
            require(stored == result, "stored CPI bottleneck census is not canonical")
    except (baseline.BaselineError, KeyError, OSError, ValueError) as exc:
        print(f"[CPI-BOTTLENECK-CENSUS][FAIL] {exc}", file=sys.stderr)
        return 1
    print(
        "[CPI-BOTTLENECK-CENSUS][PASS] "
        f"design_id={result['design_id']} "
        "dominant=memory_latency/request_outstanding/axi_write_response "
        "candidate_authorized=false ppa=UNQUALIFIED"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
