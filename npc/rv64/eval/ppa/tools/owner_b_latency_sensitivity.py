#!/usr/bin/env python3
"""Build and verify the RV64 workload-level AXI B-delay sensitivity receipt."""

from __future__ import annotations

import argparse
from decimal import Decimal
import hashlib
import json
import pathlib
import re
import sys
from typing import Any

TOOLS_DIR = pathlib.Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import owner_timing_causal_analysis as causal  # noqa: E402
import owner_timing_workload_ab as owner  # noqa: E402


REPO_ROOT = pathlib.Path(__file__).resolve().parents[5]
SCHEMA = "npc-rv64-owner-b-latency-sensitivity-v1"
SIMULATOR_SCHEMA = "npc-rv64-owner-b-latency-simulator-v1"
CLEANUP_SCHEMA = "npc-rv64-owner-b-latency-cleanup-v1"
DELAYS = (0, 2)
WORKLOADS = ("coremark", "dhrystone_10000")
REPETITIONS = 3
EXPECTED_INSTANCES = frozenset(
    ("u_psram_slave", "u_sdram_slave", "u_legacy_mmio_slave"))
PROBE_RE = re.compile(
    r"^\[OWNER-B-LATENCY-PROBE\] instance=(\S+) "
    r"delay_cycles=([0-9]+) mode=test-only$")
EXECUTION_RE = re.compile(
    r"^delay=([0-9]+) workload=(coremark|dhrystone_10000) "
    r"repetition=([1-3]) rc=0 assertion_markers=0$")
ORIGINAL_MODULE = "module AxiDpiSlave ("
RENAMED_MODULE = "module AxiDpiSlaveOwnerBDelayBase ("


class EvidenceError(ValueError):
    """An input or observation violates the B-delay measurement contract."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def resolve_file(raw: str | pathlib.Path) -> pathlib.Path:
    try:
        return owner.resolve_file(raw)
    except (owner.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error


def resolve_absent(raw: str | pathlib.Path) -> pathlib.Path:
    try:
        return owner.resolve_absent_path(raw)
    except (owner.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error


def file_ref(raw: str | pathlib.Path) -> dict[str, Any]:
    try:
        return owner.file_ref(raw)
    except (owner.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error


def verify_ref(value: Any, label: str) -> pathlib.Path:
    try:
        return owner.verify_ref(value, label)
    except (owner.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error


def load_json(raw: str | pathlib.Path) -> dict[str, Any]:
    try:
        value = owner.load_json(raw)
    except (owner.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error
    require(isinstance(value, dict), "JSON root must be an object")
    return value


def atomic_write(path: pathlib.Path, value: dict[str, Any]) -> None:
    try:
        owner.atomic_write_json(path, value)
    except (owner.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error


def decimal_ratio(numerator: int, denominator: int) -> str:
    require(denominator > 0, "ratio denominator must be positive")
    return format(Decimal(numerator) / Decimal(denominator), ".12f")


def validate_generated_base(
    original_path: pathlib.Path, generated_path: pathlib.Path,
) -> None:
    original = original_path.read_text(encoding="utf-8")
    generated = generated_path.read_text(encoding="utf-8")
    require(
        original.count(ORIGINAL_MODULE) == 1,
        "production AxiDpiSlave module declaration is not unique",
    )
    require(
        RENAMED_MODULE not in original,
        "production source already contains the diagnostic module name",
    )
    expected = original.replace(ORIGINAL_MODULE, RENAMED_MODULE, 1)
    require(
        generated == expected,
        "generated AxiDpiSlave base differs beyond the module-name substitution",
    )


def verify_owner_receipt(path: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    try:
        rebuilt = owner.rebuild_receipt(value)
    except (owner.EvidenceError, OSError, KeyError, TypeError) as error:
        raise EvidenceError(f"owner receipt cannot be rebuilt: {error}") from error
    require(value == rebuilt, "owner receipt differs from rebuilt evidence")
    require(
        value.get("status") == "OWNER_TIMING_WORKLOAD_MEASURED",
        "owner receipt is not measured",
    )
    return value


def verify_causal_receipt(path: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    try:
        rebuilt = causal.rebuild_receipt(value)
    except (causal.AnalysisError, OSError, KeyError, TypeError) as error:
        raise EvidenceError(f"causal receipt cannot be rebuilt: {error}") from error
    require(value == rebuilt, "causal receipt differs from rebuilt evidence")
    require(value.get("status") == "RESEARCH_REQUIRED", "causal status drifted")
    authorization = value.get("authorization", {})
    require(
        authorization.get("causal_selection_authorized") is False,
        "prior causal receipt unexpectedly authorizes a selection",
    )
    return value


def verify_selection_snapshot(
    decision_path: pathlib.Path,
    policy_path: pathlib.Path,
    catalog_path: pathlib.Path,
    research_path: pathlib.Path,
    design_id: str,
) -> dict[str, Any]:
    decision = load_json(decision_path)
    require(
        decision.get("schema") == "npc-rv64-optimization-slice-decision-v1",
        "selector snapshot schema mismatch",
    )
    require(decision.get("decision") == "SELECT", "selector did not select a slice")
    require(
        decision.get("selected_slice", {}).get("id") ==
        "measure.owner-b-latency-sensitivity",
        "selector snapshot does not authorize this measurement",
    )
    require(decision.get("live_design_id") == design_id, "selector design drift")
    state = decision.get("state", {})
    require(state.get("owner_timing_measured") is True, "owner timing fact is absent")
    require(state.get("causal_analysis_completed") is True, "causal fact is absent")
    require(
        state.get("causal_analysis_status") == "RESEARCH_REQUIRED",
        "causal analysis status changed",
    )
    require(
        state.get("causal_selection_authorized") is False,
        "selector snapshot already authorizes a causal candidate",
    )
    inputs = decision.get("inputs", {})
    require(
        inputs.get("policy", {}).get("sha256") == owner.sha256(policy_path),
        "frozen selector policy hash mismatch",
    )
    require(
        inputs.get("catalog", {}).get("sha256") == owner.sha256(catalog_path),
        "frozen selector catalog hash mismatch",
    )
    require(
        inputs.get("research_state", {}).get("sha256") == owner.sha256(research_path),
        "frozen selector research-state hash mismatch",
    )
    return decision


def parse_probe_markers(path: pathlib.Path, delay: int) -> list[str]:
    try:
        lines = owner.clean_lines(path)
    except (owner.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error
    require(
        not any("[OWNER-B-LATENCY-PROBE][FAIL]" in line for line in lines),
        "B-delay probe emitted a failure marker",
    )
    instances: list[str] = []
    for line in lines:
        match = PROBE_RE.fullmatch(line.strip())
        if match is None:
            continue
        require(int(match.group(2)) == delay, "probe delay marker mismatch")
        instances.append(match.group(1).split(".")[-1])
    require(len(instances) == 3, "expected exactly three B-delay instance markers")
    require(set(instances) == EXPECTED_INSTANCES, "B-delay instance set mismatch")
    require(len(set(instances)) == len(instances), "duplicate B-delay instance marker")
    return sorted(instances)


def assertion_marker_count(path: pathlib.Path) -> int:
    text = path.read_text(encoding="utf-8", errors="strict")
    patterns = (
        r"%Error",
        r"Assertion failed",
        r"\[CHECK-FAIL\]",
        r"\[OWNER-B-LATENCY-[A-Z-]+\]\[FAIL\]",
    )
    return sum(len(re.findall(pattern, text, flags=re.IGNORECASE)) for pattern in patterns)


def condition_summary(
    paths: list[pathlib.Path], workload: str, delay: int,
) -> dict[str, Any]:
    require(len(paths) == REPETITIONS, "each delay/workload point needs three logs")
    parsed: list[dict[str, Any]] = []
    instance_sets: list[list[str]] = []
    for path in paths:
        instance_sets.append(parse_probe_markers(path, delay))
        require(assertion_marker_count(path) == 0, "RTL assertion marker is nonzero")
        try:
            parsed.append(owner.parse_diagnostic_log(path, workload))
        except (owner.EvidenceError, OSError) as error:
            raise EvidenceError(str(error)) from error
    try:
        region = owner.require_all_equal(
            [item["region_payload"] for item in parsed], "region payload")
        counter = owner.require_all_equal(
            [item["counter_payload"] for item in parsed], "counter payload")
        signature = owner.require_all_equal(
            [item["owner_signature_sha256"] for item in parsed], "owner payload")
        instances = owner.require_all_equal(instance_sets, "probe instance set")
    except owner.EvidenceError as error:
        raise EvidenceError(str(error)) from error
    first = parsed[0]
    response = first["stage_totals"]["write_response"]
    b_terminals = sum(
        item["b_terminal"] for item in first["class_events"].values())
    require(b_terminals > 0, "B terminal count is zero")
    require(response["completed"] == b_terminals, "B interval/terminal mismatch")
    require(response["right_censored"] == 0, "B interval is right censored")
    require(response["cancelled"] == 0, "B interval is cancelled")
    return {
        "delay_cycles": delay,
        "repetitions": REPETITIONS,
        "logs": [file_ref(path) for path in paths],
        "probe_instances": instances,
        "region_counter_bit_exact": True,
        "owner_timing_bit_exact": True,
        "rtl_assertion_markers": 0,
        "cycles": first["cycles"],
        "retired_instructions": first["retired"],
        "start_hits": first["start_hits"],
        "end_hits": first["end_hits"],
        "start_lane": first["start_lane"],
        "end_lane": first["end_lane"],
        "region_payload_sha256": hashlib.sha256(region.encode()).hexdigest(),
        "counter_payload_sha256": hashlib.sha256(counter.encode()).hexdigest(),
        "owner_signature_sha256": signature,
        "class_events": first["class_events"],
        "occupancy": {
            "write_inflight_0": first["occupancy"][0],
            "write_inflight_1": first["occupancy"][1],
            "write_inflight_2": first["occupancy"][2],
        },
        "b_terminal": b_terminals,
        "write_response": {
            "completed": response["completed"],
            "completed_cycles": response["completed_cycles"],
            "rob_head_cycles": response["rob_head_cycles"],
            "peer_overlap_cycles": response["peer_overlap_cycles"],
            "mean_completed_cycles": decimal_ratio(
                response["completed_cycles"], response["completed"]),
        },
    }


def compare_with_a2(
    baseline: dict[str, Any], measured: dict[str, Any], workload: str,
) -> None:
    expected = baseline["workloads"][workload]
    require(measured["cycles"] == expected["cycles"], "delay0 cycles differ from A2")
    require(
        measured["retired_instructions"] == expected["retired_instructions"],
        "delay0 retired count differs from A2",
    )
    require(
        measured["owner_signature_sha256"] ==
        expected["diagnostic"]["owner_signature_sha256"],
        "delay0 owner payload differs from A2",
    )
    require(measured["class_events"] == expected["class_events"],
            "delay0 transaction ledger differs from A2")
    require(measured["occupancy"] == expected["occupancy"],
            "delay0 occupancy differs from A2")


def sensitivity_summary(
    delay0: dict[str, Any], delay2: dict[str, Any], workload: str,
) -> dict[str, Any]:
    require(delay0["delay_cycles"] == 0 and delay2["delay_cycles"] == 2,
            "unexpected delay points")
    for key in ("retired_instructions", "start_hits", "end_hits", "start_lane", "end_lane"):
        require(delay0[key] == delay2[key], f"{workload} {key} changed")
    require(delay0["b_terminal"] == delay2["b_terminal"],
            f"{workload} B terminal count changed")
    b_terminal_by_class_0 = {
        name: value["b_terminal"]
        for name, value in delay0["class_events"].items()}
    b_terminal_by_class_2 = {
        name: value["b_terminal"]
        for name, value in delay2["class_events"].items()}
    require(b_terminal_by_class_0 == b_terminal_by_class_2,
            f"{workload} B transaction class frequency changed")
    require(
        delay0["class_events"]["store"]["request_fire"] ==
        delay2["class_events"]["store"]["request_fire"],
        f"{workload} store request frequency changed")
    require(delay0["occupancy"]["write_inflight_2"] == 0,
            f"{workload} delay0 unexpectedly reached two writes")
    require(delay2["occupancy"]["write_inflight_2"] == 0,
            f"{workload} delay2 unexpectedly reached two writes")
    b_terminals = delay0["b_terminal"]
    added_response_cycles = 2 * b_terminals
    response_delta = (
        delay2["write_response"]["completed_cycles"] -
        delay0["write_response"]["completed_cycles"])
    require(response_delta == added_response_cycles,
            f"{workload} B response interval did not gain exactly two cycles per terminal")
    require(
        delay2["write_response"]["rob_head_cycles"] ==
        delay2["write_response"]["completed_cycles"],
        f"{workload} delayed B interval left the ROB-head critical path",
    )
    cycle_delta = delay2["cycles"] - delay0["cycles"]
    peer_delta = (
        delay2["write_response"]["peer_overlap_cycles"] -
        delay0["write_response"]["peer_overlap_cycles"])
    request_fire_delta = {
        name: delay2["class_events"][name]["request_fire"] -
        delay0["class_events"][name]["request_fire"]
        for name in sorted(delay0["class_events"])
    }
    return {
        "added_delay_cycles_per_b": 2,
        "b_terminal": b_terminals,
        "added_b_response_cycles": added_response_cycles,
        "workload_cycle_delta": cycle_delta,
        "peer_overlap_cycle_delta": peer_delta,
        "request_fire_delta_by_class": request_fire_delta,
        "b_transaction_frequency_unchanged": True,
        "store_request_frequency_unchanged": True,
        "workload_cycles_per_added_b_cycle": decimal_ratio(
            cycle_delta, added_response_cycles),
        "peer_overlap_per_added_b_cycle": decimal_ratio(
            peer_delta, added_response_cycles),
        "workload_cycles_per_delay_cycle": decimal_ratio(cycle_delta, 2),
        "zero_uncertainty_from_bit_exact_repetitions": True,
    }


def causal_decision(workloads: dict[str, Any]) -> dict[str, Any]:
    sensitive = all(
        workloads[name]["sensitivity"]["workload_cycle_delta"] > 0
        for name in WORKLOADS)
    if sensitive:
        return {
            "status": "H1_B_RESPONSE_LATENCY_SENSITIVE",
            "causal_hypothesis": "H1_B_RESPONSE_LATENCY",
            "causal_selection_authorized": True,
            "next_action": "analyze.owner-b-response-latency-candidate",
            "secondary_observation": "H2_SINGLE_OWNER_REMAINS_A_MEDIATOR",
        }
    return {
        "status": "RESEARCH_REQUIRED",
        "causal_hypothesis": "UNRESOLVED",
        "causal_selection_authorized": False,
        "next_action": "measure.owner-b-latency-sensitivity-narrower",
        "secondary_observation": "NO_COMMON_POSITIVE_WORKLOAD_SLOPE",
    }


def validate_execution_status(path: pathlib.Path) -> dict[str, Any]:
    lines = [line.strip() for line in path.read_text(encoding="utf-8").splitlines()
             if line.strip()]
    cases: set[tuple[int, str, int]] = set()
    for line in lines:
        match = EXECUTION_RE.fullmatch(line)
        require(match is not None, f"invalid execution status row: {line}")
        case = (int(match.group(1)), match.group(2), int(match.group(3)))
        require(case not in cases, "duplicate execution status row")
        cases.add(case)
    expected = {
        (delay, workload, repetition)
        for delay in DELAYS
        for workload in WORKLOADS
        for repetition in range(1, REPETITIONS + 1)
    }
    require(cases == expected, "execution status matrix is incomplete")
    return {"cases": 12, "all_rc_zero": True, "rtl_assertion_markers": 0}


def validate_simulator_identity(path: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    require(value.get("schema") == SIMULATOR_SCHEMA, "simulator schema mismatch")
    require(value.get("build_rc") == 0, "simulator build did not pass")
    require(value.get("CONFIG_NPC_OOO_STATS") == "y", "OOO stats are absent")
    require(value.get("CONFIG_NPC_OOO_OWNER_TIMING") == "y", "owner probe is absent")
    require(value.get("single_binary_for_all_delay_points") is True,
            "delay points do not share one simulator")
    require(value.get("production_rtl_modified") is False,
            "intervention claims a production RTL change")
    sources = value.get("source_substitution", {})
    original = verify_ref(sources.get("production_axi_dpi_slave"), "production slave")
    generated = verify_ref(sources.get("generated_renamed_base"), "generated base")
    verify_ref(sources.get("b_delay_wrapper"), "B-delay wrapper")
    verify_ref(sources.get("b_delay_make_fragment"), "B-delay make fragment")
    verify_ref(sources.get("owner_timing_make_fragment"), "owner make fragment")
    validate_generated_base(original, generated)
    verify_ref(value.get("verilator_manifest"), "Verilator manifest")
    require(re.fullmatch(r"[0-9a-f]{64}", value.get("sha256", "")) is not None,
            "simulator hash is invalid")
    require(isinstance(value.get("size_bytes"), int) and value["size_bytes"] > 0,
            "simulator size is invalid")
    return value


def validate_cleanup(path: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    require(value.get("schema") == CLEANUP_SCHEMA, "cleanup schema mismatch")
    require(value.get("cleanup_rc") == 0, "runtime cleanup failed")
    require(value.get("runtime_absent") is True, "runtime was retained")
    require(isinstance(value.get("deleted_bytes"), int) and value["deleted_bytes"] > 0,
            "cleanup deleted-byte count is invalid")
    runtime = resolve_absent(value.get("runtime_path", ""))
    root = (REPO_ROOT / ".github/runtime-artifacts/owner-b-latency-sensitivity").resolve()
    try:
        runtime.relative_to(root)
    except ValueError as error:
        raise EvidenceError("cleanup path escapes B-delay runtime root") from error
    require(not runtime.exists(), "runtime directory still exists")
    return value


def build_receipt(
    owner_receipt_path: pathlib.Path,
    causal_receipt_path: pathlib.Path,
    selector_path: pathlib.Path,
    selector_policy_path: pathlib.Path,
    selector_catalog_path: pathlib.Path,
    selector_research_path: pathlib.Path,
    production_manifest_path: pathlib.Path,
    simulator_identity_path: pathlib.Path,
    cleanup_path: pathlib.Path,
    execution_status_path: pathlib.Path,
    execution_checker_path: pathlib.Path,
    execution_runner_path: pathlib.Path,
    logs: dict[int, dict[str, list[pathlib.Path]]],
) -> dict[str, Any]:
    baseline = verify_owner_receipt(owner_receipt_path)
    prior = verify_causal_receipt(causal_receipt_path)
    require(baseline["design_id"] == prior["design_id"], "prior receipt design mismatch")
    verify_selection_snapshot(
        selector_path, selector_policy_path, selector_catalog_path,
        selector_research_path, baseline["design_id"])
    try:
        manifest = owner.validate_manifest(production_manifest_path)
    except (owner.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error
    simulator = validate_simulator_identity(simulator_identity_path)
    validate_cleanup(cleanup_path)
    execution = validate_execution_status(execution_status_path)

    workload_results: dict[str, Any] = {}
    for workload in WORKLOADS:
        delay0 = condition_summary(logs[0][workload], workload, 0)
        delay2 = condition_summary(logs[2][workload], workload, 2)
        compare_with_a2(baseline, delay0, workload)
        workload_results[workload] = {
            "delay_points": {"0": delay0, "2": delay2},
            "sensitivity": sensitivity_summary(delay0, delay2, workload),
        }
    decision = causal_decision(workload_results)

    workflow_paths = {
        "builder": pathlib.Path(__file__),
        "replay_runner": REPO_ROOT / "npc/rv64/eval/ppa/replay-owner-b-latency-sensitivity.sh",
        "wrapper": REPO_ROOT / "npc/rv64/eval/ppa/instrumentation/AxiDpiSlaveOwnerBDelayProbe.sv",
        "wrapper_tb": REPO_ROOT / "npc/rv64/eval/ppa/instrumentation/tb_axi_dpi_owner_b_delay_probe.sv",
        "make_fragment": REPO_ROOT / "npc/rv64/eval/ppa/instrumentation/owner-b-latency-sensitivity.mk",
        "owner_parser": pathlib.Path(owner.__file__),
        "causal_parser": pathlib.Path(causal.__file__),
        "unit_tests": REPO_ROOT / "npc/rv64/eval/ppa/tests/test_owner_b_latency_sensitivity.py",
        "status_helper": REPO_ROOT / "scripts/task-run-status.sh",
    }
    return {
        "schema": SCHEMA,
        "status": decision["status"],
        "design_id": baseline["design_id"],
        "scope": "test-only AXI B-response delay intervention on frozen CoreMark10 and Dhrystone10000",
        "inputs": {
            "owner_timing_receipt": file_ref(owner_receipt_path),
            "causal_analysis_receipt": file_ref(causal_receipt_path),
            "selector_snapshot": file_ref(selector_path),
            "selector_policy_snapshot": file_ref(selector_policy_path),
            "selector_catalog_snapshot": file_ref(selector_catalog_path),
            "selector_research_snapshot": file_ref(selector_research_path),
            "production_manifest": manifest,
            "diagnostic_simulator_identity": file_ref(simulator_identity_path),
            "runtime_cleanup": file_ref(cleanup_path),
            "execution_status": file_ref(execution_status_path),
            "execution_artifacts": {
                "checker": file_ref(execution_checker_path),
                "runner": file_ref(execution_runner_path),
            },
            "workflow_artifacts": {
                name: file_ref(path) for name, path in sorted(workflow_paths.items())
            },
        },
        "intervention": {
            "channel": "AXI_B",
            "delay_points_cycles": list(DELAYS),
            "single_simulator_sha256": simulator["sha256"],
            "single_binary_for_all_delay_points": True,
            "production_rtl_modified": False,
            "non_b_channels_passthrough": True,
            "DPI_write_owned_by_original_slave": True,
        },
        "execution": execution,
        "workloads": workload_results,
        "causal_decision": decision,
        "authorization": {
            "causal_selection_authorized": decision["causal_selection_authorized"],
            "optimization_candidate_authorized": False,
            "production_rtl_change_authorized": False,
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
        "checks": {
            "delay0_a2_bit_exact": True,
            "three_repetitions_per_point": True,
            "architectural_terminal_unchanged": True,
            "retired_count_unchanged": True,
            "b_transaction_frequency_unchanged": True,
            "store_request_frequency_unchanged": True,
            "two_added_cycles_per_b_terminal": True,
            "owner_conservation": True,
            "rtl_assertion_markers": 0,
            "runtime_cleanup": True,
        },
        "claim_boundary": {
            "diagnostic_intervention_is_not_production_performance": True,
            "frequency_area_power_not_measured": True,
            "ppa_qualified": False,
            "promotion_authorized": False,
        },
    }


def receipt_paths(data: dict[str, Any]) -> tuple[pathlib.Path, ...]:
    inputs = data.get("inputs", {})
    simple_names = (
        "owner_timing_receipt", "causal_analysis_receipt", "selector_snapshot",
        "selector_policy_snapshot", "selector_catalog_snapshot",
        "selector_research_snapshot",
    )
    paths = [verify_ref(inputs.get(name), name) for name in simple_names]
    manifest_ref = inputs.get("production_manifest")
    require(isinstance(manifest_ref, dict), "production manifest ref is invalid")
    manifest_path = resolve_file(manifest_ref.get("path", ""))
    try:
        expected_manifest = owner.validate_manifest(manifest_path)
    except (owner.EvidenceError, OSError) as error:
        raise EvidenceError(str(error)) from error
    require(manifest_ref == expected_manifest, "production manifest identity drift")
    paths.append(manifest_path)
    for name in (
        "diagnostic_simulator_identity", "runtime_cleanup", "execution_status",
    ):
        paths.append(verify_ref(inputs.get(name), name))
    execution_artifacts = inputs.get("execution_artifacts", {})
    paths.append(verify_ref(execution_artifacts.get("checker"), "execution checker"))
    paths.append(verify_ref(execution_artifacts.get("runner"), "execution runner"))
    return tuple(paths)


def rebuild_receipt(data: dict[str, Any]) -> dict[str, Any]:
    require(data.get("schema") == SCHEMA, "sensitivity receipt schema mismatch")
    paths = receipt_paths(data)
    logs: dict[int, dict[str, list[pathlib.Path]]] = {delay: {} for delay in DELAYS}
    for delay in DELAYS:
        for workload in WORKLOADS:
            entries = (
                data.get("workloads", {}).get(workload, {})
                .get("delay_points", {}).get(str(delay), {}).get("logs", []))
            require(len(entries) == REPETITIONS, "receipt log inventory mismatch")
            logs[delay][workload] = [
                verify_ref(item, f"delay{delay}.{workload}.log") for item in entries]
    return build_receipt(*paths, logs)


def command_validate_source(args: argparse.Namespace) -> int:
    validate_generated_base(resolve_file(args.original), resolve_file(args.generated))
    print("[OWNER-B-LATENCY-SOURCE][PASS] exact_module_rename=1 production_rtl_modified=0")
    return 0


def command_capture_simulator(args: argparse.Namespace) -> int:
    simulator = resolve_file(args.simulator)
    manifest = resolve_file(args.verilator_manifest)
    original = resolve_file(args.original_slave)
    generated = resolve_file(args.generated_base)
    wrapper = resolve_file(args.wrapper)
    fragment = resolve_file(args.make_fragment)
    owner_fragment = resolve_file(args.owner_make_fragment)
    validate_generated_base(original, generated)
    manifest_text = manifest.read_text(encoding="utf-8", errors="strict")
    require(str(generated) in manifest_text, "generated base is absent from Verilator manifest")
    require(str(wrapper) in manifest_text, "B-delay wrapper is absent from Verilator manifest")
    require(str(original) not in manifest_text, "production slave was not substituted")
    require("--assert" in manifest_text, "Verilator assertions are disabled")
    value = {
        "schema": SIMULATOR_SCHEMA,
        "path": owner.rel(simulator),
        "sha256": owner.sha256(simulator),
        "size_bytes": simulator.stat().st_size,
        "build_rc": 0,
        "CONFIG_NPC_OOO_STATS": "y",
        "CONFIG_NPC_OOO_OWNER_TIMING": "y",
        "single_binary_for_all_delay_points": True,
        "production_rtl_modified": False,
        "verilator_manifest": file_ref(manifest),
        "source_substitution": {
            "production_axi_dpi_slave": file_ref(original),
            "generated_renamed_base": file_ref(generated),
            "b_delay_wrapper": file_ref(wrapper),
            "b_delay_make_fragment": file_ref(fragment),
            "owner_timing_make_fragment": file_ref(owner_fragment),
        },
    }
    output = pathlib.Path(args.output)
    if not output.is_absolute():
        output = REPO_ROOT / output
    atomic_write(output, value)
    print(f"[OWNER-B-LATENCY-SIMULATOR][PASS] sha256={value['sha256']}")
    return 0


def command_capture_cleanup(args: argparse.Namespace) -> int:
    runtime = resolve_absent(args.runtime_dir)
    root = (REPO_ROOT / ".github/runtime-artifacts/owner-b-latency-sensitivity").resolve()
    try:
        runtime.relative_to(root)
    except ValueError as error:
        raise EvidenceError("cleanup target escapes B-delay runtime root") from error
    require(not runtime.exists(), "runtime directory still exists")
    require(args.deleted_bytes > 0, "deleted byte count must be positive")
    value = {
        "schema": CLEANUP_SCHEMA,
        "runtime_path": owner.rel(runtime),
        "runtime_absent": True,
        "cleanup_rc": 0,
        "deleted_bytes": args.deleted_bytes,
    }
    output = pathlib.Path(args.output)
    if not output.is_absolute():
        output = REPO_ROOT / output
    atomic_write(output, value)
    print(f"[OWNER-B-LATENCY-CLEANUP][PASS] deleted_bytes={args.deleted_bytes}")
    return 0


def log_matrix(args: argparse.Namespace) -> dict[int, dict[str, list[pathlib.Path]]]:
    return {
        0: {
            "coremark": [resolve_file(path) for path in args.coremark_delay0_log],
            "dhrystone_10000": [
                resolve_file(path) for path in args.dhrystone_delay0_log],
        },
        2: {
            "coremark": [resolve_file(path) for path in args.coremark_delay2_log],
            "dhrystone_10000": [
                resolve_file(path) for path in args.dhrystone_delay2_log],
        },
    }


def command_build(args: argparse.Namespace) -> int:
    value = build_receipt(
        resolve_file(args.owner_receipt), resolve_file(args.causal_receipt),
        resolve_file(args.selector), resolve_file(args.selector_policy),
        resolve_file(args.selector_catalog), resolve_file(args.selector_research),
        resolve_file(args.production_manifest), resolve_file(args.simulator_identity),
        resolve_file(args.cleanup), resolve_file(args.execution_status),
        resolve_file(args.execution_checker), resolve_file(args.execution_runner),
        log_matrix(args))
    output = pathlib.Path(args.output)
    if not output.is_absolute():
        output = REPO_ROOT / output
    atomic_write(output, value)
    decision = value["causal_decision"]
    print(
        "[OWNER-B-LATENCY-SENSITIVITY][PASS] "
        f"status={decision['status']} hypothesis={decision['causal_hypothesis']} "
        f"causal_selection_authorized={int(decision['causal_selection_authorized'])} "
        "candidate_authorized=0 ppa=UNQUALIFIED")
    return 0


def command_verify(args: argparse.Namespace) -> int:
    value = load_json(resolve_file(args.input))
    expected = rebuild_receipt(value)
    require(value == expected, "sensitivity receipt differs from rebuilt evidence")
    decision = value["causal_decision"]
    print(
        "[OWNER-B-LATENCY-SENSITIVITY-VERIFY][PASS] "
        f"status={decision['status']} hypothesis={decision['causal_hypothesis']} "
        f"causal_selection_authorized={int(decision['causal_selection_authorized'])} "
        "candidate_authorized=0 ppa=UNQUALIFIED")
    return 0


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    sub = root.add_subparsers(dest="command", required=True)
    validate = sub.add_parser("validate-source")
    validate.add_argument("--original", required=True)
    validate.add_argument("--generated", required=True)
    validate.set_defaults(func=command_validate_source)

    capture = sub.add_parser("capture-simulator")
    capture.add_argument("--simulator", required=True)
    capture.add_argument("--verilator-manifest", required=True)
    capture.add_argument("--original-slave", required=True)
    capture.add_argument("--generated-base", required=True)
    capture.add_argument("--wrapper", required=True)
    capture.add_argument("--make-fragment", required=True)
    capture.add_argument("--owner-make-fragment", required=True)
    capture.add_argument("--output", required=True)
    capture.set_defaults(func=command_capture_simulator)

    cleanup = sub.add_parser("capture-cleanup")
    cleanup.add_argument("--runtime-dir", required=True)
    cleanup.add_argument("--deleted-bytes", type=int, required=True)
    cleanup.add_argument("--output", required=True)
    cleanup.set_defaults(func=command_capture_cleanup)

    build = sub.add_parser("build")
    for name in (
        "owner-receipt", "causal-receipt", "selector", "selector-policy",
        "selector-catalog", "selector-research", "production-manifest",
        "simulator-identity", "cleanup", "execution-status",
        "execution-checker", "execution-runner", "output",
    ):
        build.add_argument(f"--{name}", required=True)
    for name in (
        "coremark-delay0-log", "dhrystone-delay0-log",
        "coremark-delay2-log", "dhrystone-delay2-log",
    ):
        build.add_argument(f"--{name}", action="append", required=True)
    build.set_defaults(func=command_build)

    verify = sub.add_parser("verify")
    verify.add_argument("--input", required=True)
    verify.set_defaults(func=command_verify)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        return args.func(args)
    except (EvidenceError, OSError, KeyError, TypeError, UnicodeError) as error:
        print(f"[OWNER-B-LATENCY-SENSITIVITY][FAIL] {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
