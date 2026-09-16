#!/usr/bin/env python3
"""Build a repeatable two-run mapped synthesis/STA receipt for current RV64 RTL."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


TOOLS_DIR = pathlib.Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import architecture_hard_gates as architecture  # noqa: E402


REPO_ROOT = pathlib.Path(__file__).resolve().parents[5]
SCHEMA = "npc-rv64-current-reference-ppa-v1"
VARIANT_SCHEMA = "npc-rv64-v15p-mapped-sta-variant-v1"
SELECTED_SLICE = "qualify.current-reference-ppa"
EXPECTED_ADAPTER_SHA256 = (
    "6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22"
)
ADAPTER_PATH = "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
EXPECTED_UNKNOWN_MACROS = {
    "OooBranchDirectionPredictor": 1,
    "OooFpArithGate": 1,
    "Sram4096x113": 2,
    "Sram4096x199": 1,
}


class EvidenceError(ValueError):
    """An input artifact or repeatability claim is not exact."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: pathlib.Path) -> dict[str, Any]:
    def pairs(values: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in values:
            require(key not in result, f"duplicate JSON key in {relative(path)}: {key}")
            result[key] = value
        return result

    try:
        value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=pairs)
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise EvidenceError(f"cannot read JSON {relative(path)}: {error}") from error
    require(isinstance(value, dict), f"JSON root is not an object: {relative(path)}")
    return value


def resolve_workspace(raw: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(raw)
    if not path.is_absolute():
        path = REPO_ROOT / path
    resolved = path.resolve()
    try:
        resolved.relative_to(REPO_ROOT)
    except ValueError as error:
        raise EvidenceError(f"workspace path escapes repository: {raw}") from error
    require(resolved.is_file() and not resolved.is_symlink(),
            f"missing or symlink artifact: {raw}")
    return resolved


def relative(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return str(path.resolve())


def file_ref(path: pathlib.Path) -> dict[str, Any]:
    path = resolve_workspace(path)
    return {
        "path": relative(path),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def verify_ref(value: Any, label: str) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} reference is not an object")
    require(set(value) == {"path", "sha256", "size_bytes"},
            f"{label} reference key set mismatch")
    path = resolve_workspace(value.get("path", ""))
    require(value.get("sha256") == sha256(path), f"{label} SHA-256 drift")
    require(value.get("size_bytes") == path.stat().st_size, f"{label} size drift")
    return path


def resolve_summary_artifact(value: Any, label: str) -> pathlib.Path:
    require(isinstance(value, dict), f"{label} artifact is not an object")
    require(set(value) == {"path", "path_scope", "sha256", "size_bytes"},
            f"{label} artifact key set mismatch")
    scope = value.get("path_scope")
    raw = value.get("path")
    require(isinstance(raw, str) and raw, f"{label} artifact path is invalid")
    if scope == "workspace_relative":
        path = resolve_workspace(raw)
    elif scope == "external_absolute":
        path = pathlib.Path(raw).resolve()
        require(path == pathlib.Path("/home/lyg/tools/OpenSTA/build/sta"),
                f"{label} external artifact is not the frozen OpenSTA binary")
        require(path.is_file() and not path.is_symlink(),
                f"{label} external artifact is missing or a symlink")
    else:
        raise EvidenceError(f"{label} artifact scope is invalid: {scope}")
    require(value.get("sha256") == sha256(path), f"{label} artifact SHA-256 drift")
    require(value.get("size_bytes") == path.stat().st_size,
            f"{label} artifact size drift")
    return path


def parse_key_values(path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        require(line.count("=") == 1,
                f"malformed key/value line {relative(path)}:{number}")
        key, value = line.split("=", 1)
        require(bool(key) and key not in result,
                f"duplicate or empty key in {relative(path)}:{number}")
        result[key] = value
    return result


def verify_status(path: pathlib.Path, label: str) -> None:
    require(path.read_text(encoding="utf-8").strip() == "PASS",
            f"{label} task status is not PASS")


def verify_cleanup(path: pathlib.Path, label: str) -> dict[str, str]:
    values = parse_key_values(path)
    require(values.get("runtime_deleted") == "PASS",
            f"{label} runtime cleanup is not PASS")
    require(values.get("netlist_retained") == "NO" and
            values.get("netlist_sha256_retained") == "YES",
            f"{label} netlist retention boundary mismatch")
    deleted = values.get("runtime_bytes_deleted", "")
    require(deleted.isdigit() and int(deleted) > 100_000_000,
            f"{label} runtime deletion byte count is implausible")
    return values


def verify_manifest_pair(
        before_path: pathlib.Path, after_path: pathlib.Path, label: str) -> None:
    require(before_path.stat().st_size > 10_000,
            f"{label} production manifest is implausibly small")
    require(before_path.read_bytes() == after_path.read_bytes(),
            f"{label} production manifest drifted during execution")


def verify_selector(path: pathlib.Path, design_id: str) -> dict[str, Any]:
    value = load_json(path)
    require(value.get("schema") == "npc-rv64-optimization-slice-decision-v1",
            "selector schema mismatch")
    require(value.get("decision") == "SELECT" and
            value.get("next_action") == "PPA_QUALIFICATION",
            "selector does not request PPA qualification")
    require(value.get("live_design_id") == design_id,
            "selector design-id drift")
    require(value.get("selected_slice", {}).get("id") == SELECTED_SLICE,
            "selector did not select current-reference PPA qualification")
    return value


def verify_policy(path: pathlib.Path) -> dict[str, Any]:
    value = load_json(path)
    require(value.get("schema") == "npc-rv64-ppa-policy-v1" and
            value.get("policy_id") ==
            "rv64-complete-ooo-dual-issue-proxy-200mhz-v1",
            "PPA policy identity mismatch")
    timing = value.get("timing", {})
    require(timing == {
        "period_ns": 5.0,
        "qualified_mhz": 200.0,
        "minimum_worst_slack_ns_for_promotion": 0.1,
        "required_tns_ns": 0.0,
        "maximum_violated_paths": 0,
        "maximum_combinational_loops": 0,
    }, "PPA timing policy mismatch")
    return value


def verify_source_map(value: Any, label: str) -> dict[str, str]:
    require(isinstance(value, dict) and len(value) >= 120,
            f"{label} synthesis source map is incomplete")
    require(value.get(ADAPTER_PATH) == EXPECTED_ADAPTER_SHA256,
            f"{label} adapter SHA-256 mismatch")
    for raw_path, digest in value.items():
        require(isinstance(raw_path, str) and isinstance(digest, str),
                f"{label} synthesis source entry is invalid")
        path = resolve_workspace(raw_path)
        require(sha256(path) == digest,
                f"{label} live synthesis source drift: {raw_path}")
    return dict(sorted(value.items()))


def verify_summary(path: pathlib.Path, label: str) -> dict[str, Any]:
    value = load_json(path)
    require(value.get("schema") == VARIANT_SCHEMA and value.get("status") == "PASS",
            f"{label} mapped synthesis/STA summary is not PASS")
    require(value.get("mode") == "candidate" and value.get("period_ns") == 5.0,
            f"{label} mapped synthesis/STA configuration mismatch")
    verify_source_map(value.get("actual_synthesis_source_sha256"), label)

    resolve_summary_artifact(value.get("source_manifest"), f"{label}.source_manifest")
    for name, record in value.get("artifacts", {}).items():
        resolve_summary_artifact(record, f"{label}.artifacts.{name}")
    synthesis = value.get("synthesis", {})
    require(synthesis.get("check_problems") == 0,
            f"{label} synthesis check is not clean")
    for name in ("synth_check", "synth_stat", "sta_export_check",
                 "sta_netlist_compatibility"):
        resolve_summary_artifact(synthesis.get(name), f"{label}.synthesis.{name}")
    inputs = value.get("inputs", {})
    for name in ("manifest", "parameters", "std_lib", "opensta_binary"):
        resolve_summary_artifact(inputs.get(name), f"{label}.inputs.{name}")

    netlist = value.get("netlist", {})
    require(isinstance(netlist.get("sha256"), str) and
            len(netlist["sha256"]) == 64 and
            isinstance(netlist.get("size_bytes"), int) and
            netlist["size_bytes"] > 100_000_000 and
            netlist.get("runtime_retention") == "DELETE_AFTER_EVIDENCE_CAPTURE",
            f"{label} netlist identity or retention boundary mismatch")
    area = synthesis.get("area", {})
    require(area.get("source") == "yosys_recursive_design_hierarchy" and
            area.get("unknown_macro_instances") == EXPECTED_UNKNOWN_MACROS and
            isinstance(area.get("logic_area_proxy_excluding_unknown_macros"),
                       (int, float)) and
            area["logic_area_proxy_excluding_unknown_macros"] > 100_000,
            f"{label} logic-area proxy is invalid")
    timing = value.get("timing", {})
    require(timing.get("combinational_loops") == 0 and
            timing.get("top_path_count") == 40 and
            isinstance(timing.get("wns_ns"), (int, float)) and
            isinstance(timing.get("tns_ns"), (int, float)) and
            isinstance(timing.get("worst_path_slack_ns"), (int, float)) and
            isinstance(timing.get("violated_path_count"), int),
            f"{label} timing summary is invalid")
    require(value.get("power", {}).get("qualification") ==
            "RELATIVE_ONLY_FIXED_TOGGLE_0P1",
            f"{label} vectorless power boundary mismatch")
    return value


def normalized_parameters(summary: dict[str, Any], label: str) -> dict[str, str]:
    path = resolve_summary_artifact(
        summary["inputs"]["parameters"], f"{label}.inputs.parameters")
    values = parse_key_values(path)
    expected = {
        "mode", "diagnostic", "design", "period_ns", "clock_port", "clock_name",
        "result_root", "synth_flatten", "synth_share",
        "synth_public_autoname", "synth_dff_autoname", "sta_flatten_export",
        "stage_scc", "blackbox_modules", "keep_hierarchy_modules", "opensta",
        "std_lib", "macro_libs",
    }
    require(set(values) == expected, f"{label} parameter key set mismatch")
    require(values["mode"] == "candidate" and
            values["diagnostic"] == "traceable-public-autoname" and
            values["design"] == "NpcTop" and
            values["period_ns"] == "5.0" and values["clock_port"] == "clk" and
            values["clock_name"] == "core_clock",
            f"{label} top/clock parameter mismatch")
    values.pop("result_root")
    return values


def exact_repeatability(first: dict[str, Any], second: dict[str, Any]) -> None:
    fields = (
        ("actual_synthesis_source_sha256",),
        ("netlist", "sha256"),
        ("netlist", "size_bytes"),
        ("synthesis", "area"),
        ("timing",),
        ("setup_warning_closure",),
        ("power",),
    )
    for path in fields:
        left: Any = first
        right: Any = second
        for key in path:
            left = left[key]
            right = right[key]
        require(left == right,
                f"two fresh mapped runs differ at {'.'.join(path)}")
    require(first["artifacts"]["top40"]["sha256"] ==
            second["artifacts"]["top40"]["sha256"],
            "two fresh mapped runs have different top-40 path members")
    require(first["source_manifest"]["sha256"] ==
            second["source_manifest"]["sha256"],
            "two fresh mapped runs have different source manifests")
    require(normalized_parameters(first, "run1") ==
            normalized_parameters(second, "run2"),
            "two fresh mapped runs have different frozen parameters")


def build_receipt(
    selector_path: pathlib.Path,
    policy_path: pathlib.Path,
    run1_summary_path: pathlib.Path,
    run1_status_path: pathlib.Path,
    run1_cleanup_path: pathlib.Path,
    run1_manifest_before_path: pathlib.Path,
    run1_manifest_after_path: pathlib.Path,
    run2_summary_path: pathlib.Path,
    run2_status_path: pathlib.Path,
    run2_cleanup_path: pathlib.Path,
    run2_manifest_before_path: pathlib.Path,
    run2_manifest_after_path: pathlib.Path,
) -> dict[str, Any]:
    design_hex, rtl_entries = architecture.rtl_binding(REPO_ROOT)
    design_id = f"sha256:{design_hex}"
    verify_selector(selector_path, design_id)
    policy = verify_policy(policy_path)
    run1 = verify_summary(run1_summary_path, "run1")
    run2 = verify_summary(run2_summary_path, "run2")
    verify_status(run1_status_path, "run1")
    verify_status(run2_status_path, "run2")
    cleanup1 = verify_cleanup(run1_cleanup_path, "run1")
    cleanup2 = verify_cleanup(run2_cleanup_path, "run2")
    verify_manifest_pair(
        run1_manifest_before_path, run1_manifest_after_path, "run1")
    verify_manifest_pair(
        run2_manifest_before_path, run2_manifest_after_path, "run2")
    exact_repeatability(run1, run2)

    timing = run2["timing"]
    timing_policy = policy["timing"]
    timing_hard_gate_pass = (
        timing["worst_path_slack_ns"] >=
        timing_policy["minimum_worst_slack_ns_for_promotion"] and
        timing["wns_ns"] >= 0.0 and
        timing["tns_ns"] == timing_policy["required_tns_ns"] and
        timing["violated_path_count"] <=
        timing_policy["maximum_violated_paths"] and
        timing["combinational_loops"] <=
        timing_policy["maximum_combinational_loops"]
    )
    status = (
        "REPEATABLE_CURRENT_REFERENCE_TIMING_QUALIFIED"
        if timing_hard_gate_pass
        else "REPEATABLE_CURRENT_REFERENCE_TIMING_HARD_GATE_FAIL"
    )
    return {
        "schema": SCHEMA,
        "status": status,
        "design_id": design_id,
        "rtl_file_count": len(rtl_entries),
        "inputs": {
            "selector_decision": file_ref(selector_path),
            "ppa_policy": file_ref(policy_path),
            "run1_summary": file_ref(run1_summary_path),
            "run1_status": file_ref(run1_status_path),
            "run1_cleanup": file_ref(run1_cleanup_path),
            "run1_production_manifest_before": file_ref(run1_manifest_before_path),
            "run1_production_manifest_after": file_ref(run1_manifest_after_path),
            "run2_summary": file_ref(run2_summary_path),
            "run2_status": file_ref(run2_status_path),
            "run2_cleanup": file_ref(run2_cleanup_path),
            "run2_production_manifest_before": file_ref(run2_manifest_before_path),
            "run2_production_manifest_after": file_ref(run2_manifest_after_path),
            "verification_tool": file_ref(pathlib.Path(__file__)),
        },
        "configuration": {
            "top": "NpcTop",
            "period_ns": 5.0,
            "frequency_mhz": 200.0,
            "timing_tier": "rtl_proxy_partial_constraints",
            "fresh_run_count": 2,
            "seed": 0,
            "threads": 1,
        },
        "repeatability": {
            "status": "PASS",
            "netlist_sha256": run2["netlist"]["sha256"],
            "netlist_size_bytes": run2["netlist"]["size_bytes"],
            "source_manifest_sha256": run2["source_manifest"]["sha256"],
            "top40_path_members_sha256": run2["artifacts"]["top40"]["sha256"],
            "run1_runtime_bytes_deleted": int(cleanup1["runtime_bytes_deleted"]),
            "run2_runtime_bytes_deleted": int(cleanup2["runtime_bytes_deleted"]),
        },
        "area": {
            **run2["synthesis"]["area"],
            "qualification": "LOGIC_AREA_PROXY_ONLY",
            "macro_inclusive_total_area": None,
        },
        "timing": {
            **timing,
            "hard_gate": "PASS" if timing_hard_gate_pass else "FAIL",
            "required_minimum_worst_slack_ns":
                timing_policy["minimum_worst_slack_ns_for_promotion"],
        },
        "power": {
            "vectorless_total_w": run2["power"]["total_vectorless_w"],
            "qualification": "UNQUALIFIED",
            "reason": "fixed-toggle vectorless estimate without workload activity and macro power closure",
        },
        "authorization": {
            "measurement_completed": True,
            "engineering_reference_available": True,
            "accepted_ppa_reference_available": False,
            "new_production_rtl_change_authorized": False,
            "promotion_eligible": False,
            "canonical_baseline_eligible": False,
        },
        "claim_boundary": {
            "repeatable_same_design_mapped_proxy_only": True,
            "timing_failure_cannot_be_compensated_by_performance_or_area": True,
            "vectorless_power_is_not_qualified_power": True,
            "deleted_netlists_are_bound_by_exact_equal_hashes": True,
            "checker_accepted_baseline_not_claimed": True,
        },
        "next_action": (
            "selector.consume-qualified-reference"
            if timing_hard_gate_pass
            else "define.current-timing-recovery-slice"
        ),
    }


INPUT_NAMES = (
    "selector_decision", "ppa_policy", "run1_summary", "run1_status",
    "run1_cleanup", "run1_production_manifest_before",
    "run1_production_manifest_after", "run2_summary", "run2_status",
    "run2_cleanup", "run2_production_manifest_before",
    "run2_production_manifest_after",
)


def rebuild_receipt(value: dict[str, Any]) -> dict[str, Any]:
    require(value.get("schema") == SCHEMA, "current-reference PPA schema mismatch")
    inputs = value.get("inputs", {})
    paths = [verify_ref(inputs.get(name), name) for name in INPUT_NAMES]
    verify_ref(inputs.get("verification_tool"), "verification_tool")
    return build_receipt(*paths)


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    require(not path.is_symlink(), f"refusing symlink output: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    require(not temporary.exists(), f"temporary output already exists: {temporary}")
    temporary.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def build_from_args(args: argparse.Namespace) -> dict[str, Any]:
    return build_receipt(
        resolve_workspace(args.selector),
        resolve_workspace(args.policy),
        resolve_workspace(args.run1_summary),
        resolve_workspace(args.run1_status),
        resolve_workspace(args.run1_cleanup),
        resolve_workspace(args.run1_manifest_before),
        resolve_workspace(args.run1_manifest_after),
        resolve_workspace(args.run2_summary),
        resolve_workspace(args.run2_status),
        resolve_workspace(args.run2_cleanup),
        resolve_workspace(args.run2_manifest_before),
        resolve_workspace(args.run2_manifest_after),
    )


def run_build(args: argparse.Namespace) -> int:
    value = build_from_args(args)
    output = pathlib.Path(args.output)
    if not output.is_absolute():
        output = REPO_ROOT / output
    write_json(output, value)
    print(
        "[CURRENT-REFERENCE-PPA][PASS] "
        f"status={value['status']} design_id={value['design_id']} "
        f"wns_ns={value['timing']['wns_ns']} "
        f"area={value['area']['logic_area_proxy_excluding_unknown_macros']} "
        "accepted_reference=false"
    )
    return 0


def run_verify(args: argparse.Namespace) -> int:
    path = resolve_workspace(args.input)
    value = load_json(path)
    rebuilt = rebuild_receipt(value)
    require(value == rebuilt, "current-reference PPA receipt differs from rebuilt evidence")
    print(
        "[CURRENT-REFERENCE-PPA-VERIFY][PASS] "
        f"status={value['status']} design_id={value['design_id']} "
        f"timing_hard_gate={value['timing']['hard_gate']} "
        "promotion_eligible=false"
    )
    return 0


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    sub = root.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--selector", required=True)
    build.add_argument("--policy", required=True)
    for run in ("run1", "run2"):
        build.add_argument(f"--{run}-summary", required=True)
        build.add_argument(f"--{run}-status", required=True)
        build.add_argument(f"--{run}-cleanup", required=True)
        build.add_argument(f"--{run}-manifest-before", required=True)
        build.add_argument(f"--{run}-manifest-after", required=True)
    build.add_argument("--output", required=True)
    build.set_defaults(func=run_build)
    verify = sub.add_parser("verify")
    verify.add_argument("--input", required=True)
    verify.set_defaults(func=run_verify)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        return args.func(args)
    except (EvidenceError, OSError, KeyError, TypeError, ValueError) as error:
        print(f"[CURRENT-REFERENCE-PPA][FAIL] {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
