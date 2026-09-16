#!/usr/bin/env python3
"""Build and verify the RV64 owner-timing causal-analysis receipt."""

from __future__ import annotations

import argparse
from decimal import Decimal
import hashlib
import json
import pathlib
import re
import sys
import tempfile
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOLS_DIR = pathlib.Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import owner_timing_workload_ab as owner_timing  # noqa: E402


SCHEMA = "npc-rv64-owner-timing-causal-analysis-v1"
STATUS = "RESEARCH_REQUIRED"
SELF_PATH = "npc/rv64/eval/ppa/tools/owner_timing_causal_analysis.py"
OWNER_VERIFIER_PATH = "npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py"
DEFAULT_PROBE_SOURCE = (
    "npc/rv64/testbench/tests/tb_ooo_owner_timing_causal_probe.sv")
DEFAULT_ARBITER_RTL = "npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v"
DEFAULT_ADAPTER_RTL = "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"

ROW_RE = re.compile(
    r"^\[OWNER-TIMING-CAUSAL-PROBE\] "
    r"b_delay=(\d+) peer=([01]) store_terminal_cycles=(\d+) "
    r"peer_admission_cycles=(-?\d+) peer_blocked_b_cycles=(-?\d+) "
    r"early_peer_admission=([01])$")
SUMMARY = (
    "[OWNER-TIMING-CAUSAL-PROBE-SUMMARY] "
    "terminal_b_delay_slope=1 peer_admission_b_delay_slope=1 "
    "peer_b_block_slope=1 early_peer_admission=0 "
    "observer_noninterference=1 "
    "conclusion=H1_H2_COUPLED_RESEARCH_REQUIRED")
EXPECTED_CASES = {(delay, peer) for delay in (0, 2, 5) for peer in (0, 1)}


class AnalysisError(RuntimeError):
    """The bound RTL/measurement evidence is incomplete or inconsistent."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AnalysisError(message)


def _strict_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise AnalysisError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path: pathlib.Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=_strict_object,
        )
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise AnalysisError(f"cannot read {label}: {exc}") from exc
    require(isinstance(value, dict), f"{label} must be a JSON object")
    return value


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        while block := stream.read(1024 * 1024):
            value.update(block)
    return value.hexdigest()


def workspace_path(
    root: pathlib.Path, value: str, label: str, *, must_exist: bool = True,
) -> pathlib.Path:
    require(isinstance(value, str) and value, f"{label} path is invalid")
    require("\\" not in value, f"{label} path must use workspace separators")
    pure = pathlib.PurePosixPath(value)
    require(not pure.is_absolute(), f"{label} path must be workspace relative")
    require(all(part not in ("", ".", "..") for part in pure.parts),
            f"{label} path has an invalid component")
    current = root
    for part in pure.parts:
        current = current / part
        if current.exists() or current.is_symlink():
            require(not current.is_symlink(), f"{label} path uses a symlink")
    resolved = root.joinpath(*pure.parts).resolve(strict=False)
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise AnalysisError(f"{label} path escapes workspace") from exc
    if must_exist:
        require(resolved.is_file(), f"{label} file is missing: {value}")
    return resolved


def relative(root: pathlib.Path, path: pathlib.Path) -> str:
    return path.resolve().relative_to(root).as_posix()


def artifact(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    return {
        "path": relative(root, path),
        "sha256": digest(path),
        "size_bytes": path.stat().st_size,
    }


def verify_artifact(
    root: pathlib.Path, value: Any, label: str,
) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} must be an artifact object")
    require(set(value) == {"path", "sha256", "size_bytes"},
            f"{label} field set mismatch")
    path = workspace_path(root, value.get("path"), label)
    require(value.get("sha256") == digest(path), f"{label} sha256 mismatch")
    require(value.get("size_bytes") == path.stat().st_size,
            f"{label} size mismatch")
    return path


def decimal_ratio(numerator: int, denominator: int) -> str:
    require(denominator > 0, "ratio denominator must be positive")
    return format(Decimal(numerator) / Decimal(denominator), ".12f")


def duration_bin_index(cycles: int) -> int:
    """Return the owner-timing contract bin for one completed interval."""
    require(cycles >= 0, "duration must be non-negative")
    if cycles <= 2:
        return cycles
    if cycles <= 4:
        return 3
    if cycles <= 8:
        return 4
    if cycles <= 16:
        return 5
    if cycles <= 32:
        return 6
    if cycles <= 64:
        return 7
    return 8


def parse_probe(path: pathlib.Path) -> dict[str, Any]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        raise AnalysisError(f"cannot read causal probe log: {exc}") from exc
    require(lines.count(SUMMARY) == 1,
            "causal probe summary is missing or duplicated")
    require(lines.count("[PASS] tb_ooo_owner_timing_causal_probe") == 1,
            "causal probe DUT PASS marker is missing or duplicated")
    require(lines.count("[RESULT] PASS") == 1,
            "causal probe runner PASS marker is missing or duplicated")
    require(not any("[OWNER-TIMING-CAUSAL-PROBE][FAIL]" in line
                    or "[RESULT] FAIL" in line for line in lines),
            "causal probe contains a FAIL marker")

    rows: dict[tuple[int, int], dict[str, int]] = {}
    for line in lines:
        match = ROW_RE.fullmatch(line)
        if match is None:
            continue
        delay, peer, terminal, admission, blocked, early = (
            int(item) for item in match.groups())
        key = (delay, peer)
        require(key not in rows, f"duplicate causal probe case: {key}")
        rows[key] = {
            "b_delay": delay,
            "peer": peer,
            "store_terminal_cycles": terminal,
            "peer_admission_cycles": admission,
            "peer_blocked_b_cycles": blocked,
            "early_peer_admission": early,
        }
    require(set(rows) == EXPECTED_CASES, "causal probe case matrix mismatch")

    isolated = [rows[(delay, 0)] for delay in (0, 2, 5)]
    peers = [rows[(delay, 1)] for delay in (0, 2, 5)]
    require(all(item["peer_admission_cycles"] == -1
                and item["peer_blocked_b_cycles"] == -1
                and item["early_peer_admission"] == 0
                for item in isolated),
            "isolated causal probe case has peer activity")
    require(all(item["early_peer_admission"] == 0 for item in peers),
            "peer request crossed the store B terminal")
    require(all(isolated[index]["store_terminal_cycles"]
                == peers[index]["store_terminal_cycles"]
                for index in range(3)),
            "peer offer changed store terminal latency")

    def unit_slope(values: list[int]) -> bool:
        return values[1] - values[0] == 2 and values[2] - values[0] == 5

    require(unit_slope(
        [item["store_terminal_cycles"] for item in isolated]),
        "store terminal B-delay slope is not one")
    require(unit_slope(
        [item["peer_admission_cycles"] for item in peers]),
        "peer admission B-delay slope is not one")
    require(unit_slope(
        [item["peer_blocked_b_cycles"] for item in peers]),
        "peer B-phase blocking slope is not one")

    workload_b_delay = 2
    expected_workload_b_response_cycles = rows[
        (workload_b_delay, 0)]["store_terminal_cycles"]

    return {
        "cases": [rows[key] for key in sorted(rows)],
        "workload_b_delay_cycles": workload_b_delay,
        "expected_workload_b_response_cycles": (
            expected_workload_b_response_cycles),
        "terminal_b_delay_slope": 1,
        "peer_admission_b_delay_slope": 1,
        "peer_b_block_slope": 1,
        "early_peer_admission": 0,
        "observer_noninterference": True,
        "structural_conclusion": "H1_H2_COUPLED",
    }


def analyze_owner_receipt(
    value: dict[str, Any], expected_b_response_cycles: int,
) -> dict[str, Any]:
    try:
        rebuilt = owner_timing.rebuild_receipt(value)
    except (owner_timing.EvidenceError, OSError, KeyError, TypeError) as exc:
        raise AnalysisError(f"owner timing receipt is not canonical: {exc}") from exc
    require(value == rebuilt, "owner timing receipt is not canonical")
    require(value.get("schema") == "npc-rv64-owner-timing-workload-ab-v1",
            "owner timing receipt schema mismatch")
    require(value.get("status") == "OWNER_TIMING_WORKLOAD_MEASURED",
            "owner timing receipt status mismatch")
    checks = value.get("checks", {})
    required_checks = (
        "arch_stable_pre_post", "perf_baseline_pre_post",
        "reference_repetitions_bit_exact", "diagnostic_repetitions_bit_exact",
        "region_counter_noninterference", "owner_state_conservation",
        "owner_interval_conservation", "benchmark_terminal_markers",
        "runtime_cleanup",
    )
    require(isinstance(checks, dict)
            and all(checks.get(name) is True for name in required_checks),
            "owner timing checks are incomplete")
    require(checks.get("owner_overflow") == 0
            and checks.get("owner_invalid_events") == 0,
            "owner timing receipt has invalid owner events")
    authorization = value.get("authorization", {})
    require(authorization.get("hypothesis_selection_authorized") is False
            and authorization.get("optimization_candidate_authorized") is False
            and authorization.get("ppa") == "UNQUALIFIED"
            and authorization.get("promotion_eligible") is False,
            "owner timing receipt exceeds its authorization boundary")

    workloads = value.get("workloads", {})
    require(set(workloads) == {"coremark", "dhrystone_10000"},
            "owner timing workload set mismatch")
    observations: dict[str, Any] = {}
    for name in sorted(workloads):
        workload = workloads[name]
        channels = workload.get("hypothesis_channels", {})
        require(set(channels) == {
            "H1_B_RESPONSE_LATENCY", "H2_WRITE_CONCURRENCY",
            "H3_HEAD_RESIDENCY_WEIGHTING", "H4_PRE_REQUEST_PIPELINE",
        }, f"{name} hypothesis channel set mismatch")
        b_response = channels["H1_B_RESPONSE_LATENCY"]["write_response"]
        aw_w_to_b = channels["H1_B_RESPONSE_LATENCY"]["aw_w_to_b"]
        completed = b_response["completed"]
        b_cycles = b_response["completed_cycles"]
        peer_cycles = b_response["peer_overlap_cycles"]
        require(
            completed > 0
            and expected_b_response_cycles > 0
            and b_cycles == completed * expected_b_response_cycles,
            f"{name} B duration does not match the causal-probe default",
        )
        require(b_response == aw_w_to_b,
                f"{name} write-response and AW/W-to-B ledgers diverge")
        require(b_response["rob_head_cycles"] == b_cycles
                and b_response["rob_head_ratio"] == "1.000000000000",
                f"{name} B interval is not fully ROB-head correlated")
        expected_bins = [0] * 9
        expected_bins[duration_bin_index(expected_b_response_cycles)] = completed
        require(b_response["bins"] == expected_bins,
                f"{name} B duration histogram is not fixed")
        require(0 < peer_cycles < b_cycles,
                f"{name} peer overlap does not discriminate H1/H2")

        concurrency = channels["H2_WRITE_CONCURRENCY"]
        require(concurrency["write_inflight_2"] == 0
                and concurrency["write_inflight_2_ratio"] == "0.000000000000",
                f"{name} unexpectedly observes two writes in flight")
        require(concurrency["write_inflight_0"]
                + concurrency["write_inflight_1"] == workload["cycles"],
                f"{name} write occupancy does not conserve ROI cycles")

        pre_request = channels["H4_PRE_REQUEST_PIPELINE"]
        require(pre_request["translation"]["rob_head_cycles"] == 0,
                f"{name} translation has unexpected ROB-head residency")

        observations[name] = {
            "cycles": workload["cycles"],
            "retired_instructions": workload["retired_instructions"],
            "b_terminal_count": completed,
            "b_response_cycles": b_cycles,
            "b_response_cycles_per_terminal": format(
                Decimal(expected_b_response_cycles), ".12f"),
            "b_response_cycles_per_retired": decimal_ratio(
                b_cycles, workload["retired_instructions"]),
            "b_terminal_per_retired": decimal_ratio(
                completed, workload["retired_instructions"]),
            "b_rob_head_cycles": b_response["rob_head_cycles"],
            "b_peer_overlap_cycles": peer_cycles,
            "b_peer_overlap_ratio": decimal_ratio(peer_cycles, b_cycles),
            "write_inflight_2_cycles": concurrency["write_inflight_2"],
            "admission_rob_head_cycles": concurrency[
                "admission_wait"]["rob_head_cycles"],
            "reservation_rob_head_cycles": pre_request[
                "reservation"]["rob_head_cycles"],
            "sq_query_rob_head_cycles": pre_request[
                "sq_query"]["rob_head_cycles"],
            "translation_rob_head_cycles": pre_request[
                "translation"]["rob_head_cycles"],
        }
    return observations


def build_receipt(
    root: pathlib.Path,
    owner_path: pathlib.Path,
    probe_log_path: pathlib.Path,
    probe_source_path: pathlib.Path,
    arbiter_rtl_path: pathlib.Path,
    adapter_rtl_path: pathlib.Path,
) -> dict[str, Any]:
    owner_value = read_json(owner_path, "owner timing receipt")
    probe_observations = parse_probe(probe_log_path)
    expected_b_response_cycles = probe_observations[
        "expected_workload_b_response_cycles"]
    workload_observations = analyze_owner_receipt(
        owner_value, expected_b_response_cycles)
    h4_material = any(
        max(
            observation["reservation_rob_head_cycles"],
            observation["sq_query_rob_head_cycles"],
        ) >= observation["b_response_cycles"]
        for observation in workload_observations.values()
    )
    return {
        "schema": SCHEMA,
        "status": STATUS,
        "design_id": owner_value["design_id"],
        "inputs": {
            "owner_timing_receipt": artifact(root, owner_path),
            "causal_probe_log": artifact(root, probe_log_path),
            "causal_probe_source": artifact(root, probe_source_path),
            "arbiter_rtl": artifact(root, arbiter_rtl_path),
            "lane_adapter_rtl": artifact(root, adapter_rtl_path),
            "builder": artifact(root, workspace_path(root, SELF_PATH, "builder")),
            "owner_timing_verifier": artifact(
                root, workspace_path(root, OWNER_VERIFIER_PATH,
                                     "owner timing verifier")),
        },
        "workload_observations": workload_observations,
        "l0_causal_probe": probe_observations,
        "hypothesis_assessment": {
            "H1_B_RESPONSE_LATENCY": {
                "status": "SUPPORTED_BUT_COUPLED",
                "basis": (
                    f"fixed {expected_b_response_cycles}-cycle B intervals are "
                    "fully ROB-head correlated and the L0 terminal slope is one"
                ),
            },
            "H2_WRITE_CONCURRENCY": {
                "status": "SUPPORTED_BUT_COUPLED",
                "basis": "write_inflight_2 is zero and the L0 peer-admission slope is one while the B owner is held",
            },
            "H3_HEAD_RESIDENCY_WEIGHTING": {
                "status": "NOT_A_STANDALONE_RTL_CAUSE",
                "basis": "transaction count and fixed duration are explicit, but workload-level recoverable CPI is not yet measured",
            },
            "H4_PRE_REQUEST_PIPELINE": {
                "status": (
                    "MATERIAL_CO_BOTTLENECK" if h4_material
                    else "NOT_PRIMARY_FOR_THIS_INTERVENTION"
                ),
                "basis": (
                    "translation head cycles are zero, but reservation or "
                    "SQ-query head residency reaches the B residency in at "
                    "least one workload"
                    if h4_material else
                    "translation head cycles are zero and reservation/SQ-query "
                    "head cycles are lower than B head cycles in both workloads"
                ),
            },
        },
        "decision": {
            "causal_status": "H1_H2_COUPLED",
            "causal_hypothesis": "UNRESOLVED",
            "material_co_bottlenecks": (
                ["H4_PRE_REQUEST_PIPELINE"] if h4_material else []),
            "reason": (
                "The current single-owner fabric converts B delay one-for-one "
                "into both store-terminal and peer-admission delay; structural "
                "and observational evidence cannot uniquely separate H1 from "
                "H2, and the current CoreMark pre-request residency must remain "
                "visible in the sensitivity result."
                if h4_material else
                "The current single-owner fabric converts B delay one-for-one "
                "into both store-terminal and peer-admission delay; structural "
                "and observational evidence cannot uniquely separate H1 from H2."
            ),
            "next_measurement": "measure.owner-b-latency-sensitivity",
        },
        "checks": {
            "owner_receipt_canonical": True,
            "owner_noninterference": True,
            "fixed_b_duration": True,
            "b_rob_head_correlation": True,
            "write_occupancy_conservation": True,
            "l0_delay_matrix_complete": True,
            "l0_unit_terminal_slope": True,
            "l0_unit_peer_admission_slope": True,
            "l0_no_early_peer_admission": True,
            "production_rtl_semantics_changed": False,
        },
        "authorization": {
            "causal_selection_authorized": False,
            "optimization_candidate_authorized": False,
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
        "claim_boundary": {
            "scope": "current owner-timing receipt plus L0 arbiter/lane-adapter B-delay intervention",
            "workload_level_b_delay_intervention_measured": False,
            "rtl_candidate_authorized": False,
            "ppa_qualified": False,
        },
    }


def rebuild_receipt(value: dict[str, Any]) -> dict[str, Any]:
    require(value.get("schema") == SCHEMA, "causal analysis schema mismatch")
    inputs = value.get("inputs")
    require(isinstance(inputs, dict) and set(inputs) == {
        "owner_timing_receipt", "causal_probe_log", "causal_probe_source",
        "arbiter_rtl", "lane_adapter_rtl", "builder",
        "owner_timing_verifier",
    }, "causal analysis input set mismatch")
    paths = {
        name: verify_artifact(ROOT, reference, f"causal input {name}")
        for name, reference in inputs.items()
    }
    require(relative(ROOT, paths["builder"]) == SELF_PATH,
            "causal analysis builder path mismatch")
    require(relative(ROOT, paths["owner_timing_verifier"])
            == OWNER_VERIFIER_PATH,
            "owner timing verifier path mismatch")
    return build_receipt(
        ROOT,
        paths["owner_timing_receipt"],
        paths["causal_probe_log"],
        paths["causal_probe_source"],
        paths["arbiter_rtl"],
        paths["lane_adapter_rtl"],
    )


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    require(not path.is_symlink(), "output path uses a symlink")
    encoded = json.dumps(
        value, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent,
        prefix=f".{path.name}.", delete=False,
    ) as stream:
        temporary = pathlib.Path(stream.name)
        stream.write(encoded)
    temporary.replace(path)


def resolve_argument(value: pathlib.Path, label: str, *, output: bool = False) -> pathlib.Path:
    try:
        lexical = value.relative_to(ROOT) if value.is_absolute() else value
    except ValueError as exc:
        raise AnalysisError(f"{label} path escapes workspace") from exc
    return workspace_path(ROOT, lexical.as_posix(), label, must_exist=not output)


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    build = subparsers.add_parser("build")
    build.add_argument("--owner-receipt", type=pathlib.Path, required=True)
    build.add_argument("--probe-log", type=pathlib.Path, required=True)
    build.add_argument("--probe-source", type=pathlib.Path,
                       default=pathlib.Path(DEFAULT_PROBE_SOURCE))
    build.add_argument("--arbiter-rtl", type=pathlib.Path,
                       default=pathlib.Path(DEFAULT_ARBITER_RTL))
    build.add_argument("--adapter-rtl", type=pathlib.Path,
                       default=pathlib.Path(DEFAULT_ADAPTER_RTL))
    build.add_argument("--output", type=pathlib.Path, required=True)
    verify = subparsers.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    args = parser.parse_args()

    try:
        if args.command == "build":
            value = build_receipt(
                ROOT,
                resolve_argument(args.owner_receipt, "owner receipt"),
                resolve_argument(args.probe_log, "probe log"),
                resolve_argument(args.probe_source, "probe source"),
                resolve_argument(args.arbiter_rtl, "arbiter RTL"),
                resolve_argument(args.adapter_rtl, "lane adapter RTL"),
            )
            output = resolve_argument(args.output, "output", output=True)
            write_json(output, value)
        else:
            path = resolve_argument(args.input, "causal analysis receipt")
            value = read_json(path, "causal analysis receipt")
            rebuilt = rebuild_receipt(value)
            require(value == rebuilt, "causal analysis receipt is not canonical")
        print(
            "[OWNER-TIMING-CAUSAL-ANALYSIS][PASS] "
            f"status={STATUS} design_id={value['design_id']} "
            "causal_hypothesis=UNRESOLVED "
            "next_measurement=measure.owner-b-latency-sensitivity")
        return 0
    except (AnalysisError, OSError, KeyError, TypeError, ValueError) as exc:
        print(f"[OWNER-TIMING-CAUSAL-ANALYSIS][FAIL] {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
