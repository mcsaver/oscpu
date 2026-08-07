#!/usr/bin/env python3
"""Rebind retained RV64 architecture-directed evidence to one current RTL identity.

The replay is deliberately narrow.  Production RTL changes are accepted only when
they are outside every frozen DI/OOO directed source closure.  Non-DUT provenance
may move only through the architecture Make target projection, the exact current
L0 build-control binding, or a freshly audited producer-holder census.  Dynamic
logs and mutation transcripts remain immutable and are never described as rerun.
"""

from __future__ import annotations

import argparse
import copy
import datetime
import hashlib
import importlib.util
import json
import pathlib
import sys
import tempfile
from typing import Any


TOOLS_DIR = pathlib.Path(__file__).resolve().parent


def load_tool(name: str, filename: str) -> Any:
    path = TOOLS_DIR / filename
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load tool: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


arch = load_tool("architecture_current_delta_arch", "architecture_hard_gates.py")
provenance = load_tool(
    "architecture_current_delta_provenance", "architecture_provenance_replay.py")
census_tool = load_tool(
    "architecture_current_delta_census", "producer_holder_census.py")
layered = load_tool(
    "architecture_current_delta_layered", "layered_system_signoff.py")


SCHEMA = "npc-rv64-architecture-current-delta-rebind-v1"
REPLAY_SCHEMA = "npc-rv64-architecture-current-record-rebind-v1"
NEGATIVE_SCHEMA = "npc-rv64-architecture-current-delta-negative-v1"
RTL_INPUT_SCHEMA = "npc-rv64-full-core-module-input-binding-v1"
NPC_MAKEFILE = "npc/rv64/Makefile"
TB_MAKEFILE = "npc/rv64/testbench/Makefile"
CENSUS_PATH = "npc/rv64/design/arch/producer-holder-census.json"
AUTHORIZED_PROVENANCE_DRIFT = frozenset({
    NPC_MAKEFILE,
    TB_MAKEFILE,
    CENSUS_PATH,
})
TEST_TO_GATE = {
    test_id: gate_id for gate_id, test_id in arch.EVIDENCE_TEST.items()
}
PROVENANCE_PATHS = {
    "frontend_ii1": arch.FRONTEND_II1_PROVENANCE_PATHS,
    "width_continuity": arch.WIDTH_CONTINUITY_PROVENANCE_PATHS,
    "pair_matrix": arch.PAIR_MATRIX_PROVENANCE_PATHS,
    "true_ooo_long_latency": arch.LONG_LATENCY_PROVENANCE_PATHS,
    "selective_scheduling": arch.SELECTIVE_PROVENANCE_PATHS,
    "no_static_lane_semantics": arch.NO_STATIC_LANE_PROVENANCE_PATHS,
    "dual_memory_issue": arch.DUAL_MEMORY_PROVENANCE_PATHS,
    "memory_ordering": arch.MEMORY_ORDERING_PROVENANCE_PATHS,
    "speculation_recovery": arch.SPECULATION_RECOVERY_PROVENANCE_PATHS,
}
TASK_RUN_SOURCE_PATHS = {
    "frontend_ii1": arch.FRONTEND_II1_TASK_RUN_SOURCE_PATHS,
    "width_continuity": arch.WIDTH_CONTINUITY_TASK_RUN_SOURCE_PATHS,
    "dual_memory_issue": arch.DUAL_MEMORY_SOURCE_PATHS,
    "true_ooo_long_latency": arch.LONG_LATENCY_SOURCE_PATHS,
    "memory_ordering": arch.MEMORY_ORDERING_SOURCE_PATHS,
    "speculation_recovery": arch.SPECULATION_RECOVERY_SOURCE_PATHS,
}

# These fragments freeze the generic compile/sim/oracle transaction used by the
# retained directed variants.  New unrelated TB targets may be added without
# invalidating the projection, while a change to this execution contract fails.
TB_BUILD_CONTRACT_FRAGMENTS = (
    "$(LOG_DIR)/$(1).log: $$(sort $$(TB_SRCS_$(1))) $$(TB_DEPS_$(1)) common/tb_common.svh common/rv32_encode.svh $$(TB_RESULT_CHECKER) Makefile",
    "$(IVERILOG) $(IVFLAGS) $$(TB_IVFLAGS_$(1)) -s $$(if $$(TB_TOP_$(1)),$$(TB_TOP_$(1)),$(1)) -o $(BUILD_DIR)/$(1).vvp $$(sort $$(TB_SRCS_$(1))) >> \"$$$$tmp\" 2>&1; \\",
    "$(VVP) $(BUILD_DIR)/$(1).vvp >> \"$$$$tmp\" 2>&1; \\",
    "$(PYTHON) $(TB_RESULT_CHECKER) \\",
    "echo \"[RESULT] PASS\" >> \"$$$$tmp\"; \\",
    "echo \"[RESULT] FAIL status=$$$$status\" >> \"$$$$tmp\"; \\",
)


class RebindError(ValueError):
    """Raised when retained evidence cannot be projected without a DUT rerun."""


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def is_sha(value: Any) -> bool:
    return (
        isinstance(value, str)
        and len(value) == 64
        and all(char in "0123456789abcdef" for char in value)
    )


def read_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(
        path.read_text(encoding="utf-8"),
        parse_constant=lambda token: (_ for _ in ()).throw(
            RebindError(f"non-finite JSON constant: {token}")),
    )
    if not isinstance(value, dict):
        raise RebindError(f"JSON root is not an object: {path}")
    return value


def workspace_path(
    root: pathlib.Path, value: pathlib.Path, *, must_exist: bool,
) -> pathlib.Path:
    candidate = value if value.is_absolute() else root / value
    candidate = candidate.resolve(strict=must_exist)
    if not candidate.is_relative_to(root):
        raise RebindError(f"path escapes workspace: {value}")
    cursor = root
    for part in candidate.relative_to(root).parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise RebindError(f"path traverses symlink: {value}")
    if must_exist and not candidate.is_file():
        raise RebindError(f"input is not a regular file: {value}")
    if not must_exist:
        candidate.parent.mkdir(parents=True, exist_ok=True)
    return candidate


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    if path.is_symlink() or temporary.is_symlink():
        raise RebindError(f"refuse symlink output: {path}")
    try:
        temporary.write_text(
            json.dumps(
                value, allow_nan=False, ensure_ascii=False, indent=2,
                sort_keys=True,
            ) + "\n",
            encoding="utf-8",
        )
        read_json(temporary)
        temporary.replace(path)
    finally:
        if temporary.exists():
            temporary.unlink()


def artifact(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    return {
        "path": path.relative_to(root).as_posix(),
        "sha256": digest(path),
        "size_bytes": path.stat().st_size,
    }


def required_paths(test_id: str, record: dict[str, Any]) -> set[str]:
    value = record.get("provenance")
    if (
        isinstance(value, dict)
        and value.get("mode") == "task-run-v1"
        and test_id in TASK_RUN_SOURCE_PATHS
    ):
        return set(TASK_RUN_SOURCE_PATHS[test_id])
    return set(PROVENANCE_PATHS[test_id])


def rtl_manifest(
    root: pathlib.Path, path: pathlib.Path, *, require_live: bool,
) -> tuple[dict[str, Any], dict[str, str]]:
    value = read_json(path)
    if set(value) != {"schema", "design_id", "groups", "required_tests"}:
        raise RebindError(f"RTL input manifest inventory mismatch: {path}")
    groups = value.get("groups")
    files = groups.get("rtl") if isinstance(groups, dict) else None
    if (
        value.get("schema") != RTL_INPUT_SCHEMA
        or not isinstance(files, dict)
        or len(files) != 146
        or any(
            not isinstance(rel, str)
            or not rel.startswith("npc/rv64/vsrc/")
            or not is_sha(sha)
            for rel, sha in files.items()
        )
    ):
        raise RebindError(f"RTL input binding is malformed: {path}")
    expected_design = f"sha256:{arch.canonical_digest(files)}"
    if value.get("design_id") != expected_design:
        raise RebindError(f"RTL input binding design-id mismatch: {path}")
    if require_live:
        live_sha, live_files = arch.rtl_binding(root)
        if files != live_files or expected_design != f"sha256:{live_sha}":
            raise RebindError("current RTL input binding differs from live production RTL")
        filelists = groups.get("filelists")
        if (
            not isinstance(filelists, dict)
            or filelists.get(TB_MAKEFILE) != digest(root / TB_MAKEFILE)
        ):
            raise RebindError("current L0 binding does not cover the live TB Makefile")
    return value, files


def rtl_delta(
    baseline: dict[str, str], current: dict[str, str],
) -> list[dict[str, str]]:
    if set(baseline) != set(current):
        raise RebindError("baseline/current production RTL membership differs")
    changed = [
        {
            "path": rel,
            "baseline_sha256": baseline[rel],
            "current_sha256": current[rel],
        }
        for rel in sorted(baseline)
        if baseline[rel] != current[rel]
    ]
    if not changed:
        raise RebindError("delta rebind requires at least one production RTL change")
    return changed


def validate_tb_build_contract(root: pathlib.Path) -> dict[str, Any]:
    text = (root / TB_MAKEFILE).read_text(encoding="utf-8")
    for fragment in TB_BUILD_CONTRACT_FRAGMENTS:
        if text.count(fragment) != 1:
            raise RebindError(f"TB compile/sim contract drift: {fragment}")
    projection = {
        "fragments": list(TB_BUILD_CONTRACT_FRAGMENTS),
        "makefile_sha256": digest(root / TB_MAKEFILE),
    }
    projection["projection_sha256"] = arch.canonical_digest(projection)
    return projection


def validate_layered_receipt(
    root: pathlib.Path, path: pathlib.Path, current_manifest: pathlib.Path,
) -> dict[str, Any]:
    receipt = read_json(path)
    directories = receipt.get("source_directories")
    if not isinstance(directories, dict):
        raise RebindError("layered receipt source directories are missing")
    l1_keys = {"l1_full_core", "l1_checker_replay"} & set(directories)
    if len(l1_keys) != 1:
        raise RebindError("layered receipt L1 authority is ambiguous")
    l1_key = next(iter(l1_keys))
    kwargs: dict[str, Any] = {
        "l0_module_dir": pathlib.Path(directories["l0_module"]),
        "l2_result_dir": pathlib.Path(directories["l2_mini_system"]),
        "l3_result_dir": pathlib.Path(directories["l3_lightweight_linux"]),
        "root": root,
    }
    kwargs["l1_dir" if l1_key == "l1_full_core" else "l1_replay_dir"] = (
        pathlib.Path(directories[l1_key])
    )
    rebuilt = layered.evaluate(**kwargs)
    if rebuilt != receipt or receipt.get("status") != "PASS":
        raise RebindError("layered L0-L3 receipt does not canonically rebuild")
    design_id = receipt.get("rtl_design_id")
    if design_id != read_json(current_manifest).get("design_id"):
        raise RebindError("layered receipt/current RTL manifest design mismatch")
    l0_result_item = receipt["layers"]["L0_DIRECTED_RTL"]["result"]
    l0_result_path = workspace_path(
        root, pathlib.Path(l0_result_item["path"]), must_exist=True)
    if digest(l0_result_path) != l0_result_item.get("sha256"):
        raise RebindError("layered L0 result hash mismatch")
    l0_result = read_json(l0_result_path)
    pre = l0_result.get("inputs", {}).get("pre", {})
    if (
        l0_result.get("status") != "PASS"
        or l0_result.get("tests", {}).get("required") != 113
        or l0_result.get("tests", {}).get("passed") != 113
        or pre.get("path") != current_manifest.relative_to(root).as_posix()
        or pre.get("sha256") != digest(current_manifest)
    ):
        raise RebindError("current L0 113/113 input binding mismatch")
    return {
        "design_id": design_id,
        "l0_passed": 113,
        "l0_required": 113,
        "l1_official": 177,
        "l1_am": 61,
        "l2_case": "all",
        "l3_case": "all",
        "ubuntu": "NOT_RUN",
    }


def validate_census(root: pathlib.Path, path: pathlib.Path, design_id: str) -> dict[str, Any]:
    manifest = read_json(path)
    result = census_tool.audit(root, path, root / "npc/rv64/vsrc")
    if (
        result.get("status") != "PASS"
        or manifest.get("design_id") != design_id
        or result.get("instance_graph", {}).get("design_id") != design_id
    ):
        raise RebindError("current producer-holder census does not audit PASS")
    return {
        "design_id": design_id,
        "status": "PASS",
        "counts": result.get("counts"),
        "instance_graph": result.get("instance_graph"),
    }


def red_checks(result: dict[str, Any], gate_id: str) -> set[str]:
    return {
        item["check_id"]
        for item in result.get("gates", {}).get(gate_id, {}).get("checks", [])
        if item.get("status") == "RED"
    }


def evaluate_payload(
    root: pathlib.Path, payload: dict[str, Any],
) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="rv64-arch-delta-rebind-") as raw:
        path = pathlib.Path(raw) / "manifest.json"
        write_json(path, payload)
        return arch.evaluate(root, path)


def project_manifest(
    *, root: pathlib.Path, source_path: pathlib.Path,
    baseline_rtl_path: pathlib.Path, current_rtl_path: pathlib.Path,
    layered_path: pathlib.Path, census_path: pathlib.Path,
) -> tuple[dict[str, Any], dict[str, Any]]:
    source = read_json(source_path)
    baseline_binding, baseline_files = rtl_manifest(
        root, baseline_rtl_path, require_live=False)
    current_binding, current_files = rtl_manifest(
        root, current_rtl_path, require_live=True)
    design_id = current_binding["design_id"]
    if (
        source.get("schema") != arch.EVIDENCE_SCHEMA
        or source.get("design_id") != baseline_binding["design_id"]
        or not isinstance(source.get("tests"), dict)
        or set(source["tests"]) != set(TEST_TO_GATE)
    ):
        raise RebindError("source architecture manifest/baseline identity mismatch")
    changed = rtl_delta(baseline_files, current_files)
    changed_paths = {item["path"] for item in changed}
    directed_union: set[str] = set()
    mismatches_by_test: dict[str, list[str]] = {}
    for test_id, record in source["tests"].items():
        if not isinstance(record, dict):
            raise RebindError(f"{test_id}: architecture record is not an object")
        expected_paths = required_paths(test_id, record)
        directed_union.update(
            path for path in expected_paths if path.startswith("npc/rv64/vsrc/"))
        files = record.get("provenance", {}).get("files")
        if not isinstance(files, dict) or set(files) != expected_paths:
            raise RebindError(f"{test_id}: directed provenance inventory mismatch")
        mismatches = {
            rel for rel, expected_sha in files.items()
            if digest(arch.safe_artifact(root, rel)) != expected_sha
        }
        if not mismatches or not mismatches.issubset(AUTHORIZED_PROVENANCE_DRIFT):
            raise RebindError(
                f"{test_id}: provenance drift exceeds authorized build/static set: "
                f"{sorted(mismatches)}")
        mismatches_by_test[test_id] = sorted(mismatches)
        provenance.validate_embedded_artifacts(root, test_id, record, arch)
    impacted = changed_paths & directed_union
    if impacted:
        raise RebindError(
            "production RTL delta enters a directed source closure; rerun required: "
            f"{sorted(impacted)}")

    before = arch.evaluate(root, source_path)
    if before.get("overall_status") != "RED" or before.get("exit_code") != 1:
        raise RebindError("source architecture manifest is not an expected stale RED")
    for test_id, gate_id in TEST_TO_GATE.items():
        expected = {
            "evidence.design_binding",
            f"evidence.{test_id}.provenance_files",
            f"evidence.{test_id}.provenance_digest",
        }
        if red_checks(before, gate_id) != expected:
            raise RebindError(
                f"{gate_id}: stale cause exceeds design/provenance projection: "
                f"{sorted(red_checks(before, gate_id))}")

    make_projection = provenance.validate_makefile_gate_projection(
        (root / NPC_MAKEFILE).read_text(encoding="utf-8"))
    tb_projection = validate_tb_build_contract(root)
    layered_summary = validate_layered_receipt(root, layered_path, current_rtl_path)
    census_summary = validate_census(root, census_path, design_id)

    output = copy.deepcopy(source)
    output["generated_at_utc"] = datetime.datetime.now(
        datetime.timezone.utc).isoformat()
    output["design_id"] = design_id
    source_sha = digest(source_path)
    for test_id, record in output["tests"].items():
        source_record = source["tests"][test_id]
        record_files = record["provenance"]["files"]
        for rel in mismatches_by_test[test_id]:
            record_files[rel] = digest(root / rel)
        record["provenance"]["sha256"] = arch.canonical_digest(record_files)
        source_manifest = record.get("source_manifest")
        rebound_source_paths: list[str] = []
        if isinstance(source_manifest, dict) and isinstance(
            source_manifest.get("files"), dict
        ):
            for rel in mismatches_by_test[test_id]:
                if rel in source_manifest["files"]:
                    source_manifest["files"][rel] = digest(root / rel)
                    rebound_source_paths.append(rel)
            source_manifest["sha256"] = arch.canonical_digest(
                source_manifest["files"])
        record["versioned_replay"] = {
            "schema": REPLAY_SCHEMA,
            "classification": (
                "RTL_OUTSIDE_DIRECTED_SOURCE_CLOSURE_WITH_CURRENT_BUILD_AND_STATIC_BINDING"
            ),
            "source_manifest_sha256": source_sha,
            "source_record_sha256": arch.canonical_digest(source_record),
            "baseline_design_id": baseline_binding["design_id"],
            "current_design_id": design_id,
            "production_rtl_changed_paths": sorted(changed_paths),
            "directed_source_closure_impact": [],
            "provenance_rebound_paths": mismatches_by_test[test_id],
            "source_manifest_rebound_paths": sorted(rebound_source_paths),
            "current_l0_l3_status": "PASS_CURRENT_CONFIG",
            "current_census_status": "PASS",
            "dynamic_logs_modified": False,
            "mutation_transcripts_modified": False,
            "directed_simulation_reexecuted": False,
            "ppa": "UNQUALIFIED",
        }
    after = evaluate_payload(root, output)
    if (
        after.get("overall_status") != "GREEN"
        or after.get("exit_code") != 0
        or any(red_checks(after, gate) for gate in TEST_TO_GATE.values())
    ):
        raise RebindError("projected current architecture manifest is not GREEN 9/9")
    context = {
        "design_id": design_id,
        "baseline_design_id": baseline_binding["design_id"],
        "rtl_delta": changed,
        "directed_source_union": sorted(directed_union),
        "mismatches_by_test": mismatches_by_test,
        "makefile_gate_projection": make_projection,
        "tb_build_projection": tb_projection,
        "layered_summary": layered_summary,
        "census_summary": census_summary,
    }
    return output, context


def negative_summary(root: pathlib.Path, manifest: dict[str, Any]) -> dict[str, Any]:
    cases: list[dict[str, Any]] = []

    def capture(name: str, payload: dict[str, Any], gate: str, check: str) -> None:
        result = evaluate_payload(root, payload)
        observed = red_checks(result, gate)
        if result.get("overall_status") != "RED" or check not in observed:
            raise RebindError(f"negative architecture fixture escaped: {name}")
        cases.append({
            "name": name,
            "gate_id": gate,
            "expected_check": check,
            "observed_red_checks": sorted(observed),
            "detected": True,
        })

    missing = copy.deepcopy(manifest)
    del missing["tests"]["selective_scheduling"]
    capture(
        "missing-ooo2-record", missing, "OOO-2",
        "evidence.selective_scheduling.record")
    status = copy.deepcopy(manifest)
    status["tests"]["memory_ordering"]["status"] = "FAIL"
    capture(
        "ooo3-status-fail", status, "OOO-3",
        "evidence.memory_ordering.status")
    design = copy.deepcopy(manifest)
    design["design_id"] = "sha256:" + "0" * 64
    capture(
        "design-id-rollback", design, "DI-1", "evidence.design_binding")
    provenance_rollback = copy.deepcopy(manifest)
    provenance_rollback["tests"]["frontend_ii1"]["provenance"]["files"][
        TB_MAKEFILE] = "0" * 64
    capture(
        "tb-build-provenance-rollback", provenance_rollback, "DI-1",
        "evidence.frontend_ii1.provenance_files")
    return {
        "schema": NEGATIVE_SCHEMA,
        "status": "PASS",
        "required": 4,
        "detected": len(cases),
        "cases": cases,
    }


def normalized_result(value: dict[str, Any]) -> dict[str, Any]:
    result = copy.deepcopy(value)
    result.pop("generated_at_utc", None)
    return result


def build(args: argparse.Namespace) -> int:
    root = args.repo_root.resolve(strict=True)
    source = workspace_path(root, args.source_manifest, must_exist=True)
    baseline = workspace_path(root, args.baseline_rtl_manifest, must_exist=True)
    current = workspace_path(root, args.current_rtl_manifest, must_exist=True)
    layered_path = workspace_path(root, args.layered_receipt, must_exist=True)
    census_path = workspace_path(root, args.census, must_exist=True)
    output = workspace_path(root, args.output_manifest, must_exist=False)
    result_path = workspace_path(root, args.result, must_exist=False)
    negative_path = workspace_path(root, args.negative_summary, must_exist=False)
    receipt_path = workspace_path(root, args.receipt, must_exist=False)
    if len({source, baseline, current, layered_path, census_path, output,
            result_path, negative_path, receipt_path}) != 9:
        raise RebindError("all delta-rebind input/output paths must be distinct")
    manifest, context = project_manifest(
        root=root,
        source_path=source,
        baseline_rtl_path=baseline,
        current_rtl_path=current,
        layered_path=layered_path,
        census_path=census_path,
    )
    write_json(output, manifest)
    result = arch.evaluate(root, output)
    write_json(result_path, result)
    negative = negative_summary(root, manifest)
    write_json(negative_path, negative)
    receipt = {
        "schema": SCHEMA,
        "status": "PASS",
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc).isoformat(),
        "claim": "current_architecture_nine_gate_delta_rebind",
        "baseline_design_id": context["baseline_design_id"],
        "current_design_id": context["design_id"],
        "rtl_file_count": 146,
        "rtl_delta": {
            "membership_equal": True,
            "changed_file_count": len(context["rtl_delta"]),
            "changed_files": context["rtl_delta"],
            "directed_source_closure_impact": [],
        },
        "provenance_rebind": {
            "authorized_paths": sorted(AUTHORIZED_PROVENANCE_DRIFT),
            "by_test": context["mismatches_by_test"],
            "npc_makefile_projection": context["makefile_gate_projection"],
            "tb_build_projection": context["tb_build_projection"],
            "current_census": context["census_summary"],
            "current_layered_positive": context["layered_summary"],
        },
        "inputs": {
            "source_architecture_manifest": artifact(root, source),
            "baseline_rtl_manifest": artifact(root, baseline),
            "current_rtl_manifest": artifact(root, current),
            "layered_system_receipt": artifact(root, layered_path),
            "producer_holder_census": artifact(root, census_path),
        },
        "outputs": {
            "architecture_manifest": artifact(root, output),
            "architecture_result": artifact(root, result_path),
            "negative_summary": artifact(root, negative_path),
        },
        "architecture_directed_gates": {
            "status": "GREEN",
            "passed": 9,
            "required": 9,
        },
        "negative_cases": {
            "status": "PASS",
            "detected": negative["detected"],
            "required": negative["required"],
        },
        "directed_simulation_reexecuted": False,
        "dynamic_logs_modified": False,
        "mutation_transcripts_modified": False,
        "optional_ubuntu": "NOT_RUN",
        "arch_stable": False,
        "ppa": "UNQUALIFIED",
        "claim_boundary": (
            "Rebinds nine retained DI/OOO records only because the exact current "
            "production RTL delta is outside every directed source closure, the "
            "current L0-L3 receipt and census canonically rebuild, and the current "
            "Make execution projections remain exact. It does not claim a directed "
            "DUT rerun, ARCH_STABLE, synthesis, STA, power, CPI, PPA or Ubuntu."
        ),
    }
    write_json(receipt_path, receipt)
    print(
        "[ARCH-CURRENT-DELTA-REBIND][PASS] "
        f"design_id={context['design_id']} changed={len(context['rtl_delta'])} "
        "directed_impact=0 gates=9/9 negative=4/4 dut_rerun=0"
    )
    return 0


def verify(args: argparse.Namespace) -> int:
    root = args.repo_root.resolve(strict=True)
    receipt_path = workspace_path(root, args.receipt, must_exist=True)
    receipt = read_json(receipt_path)
    if (
        receipt.get("schema") != SCHEMA
        or receipt.get("status") != "PASS"
        or receipt.get("claim") != "current_architecture_nine_gate_delta_rebind"
        or receipt.get("directed_simulation_reexecuted") is not False
        or receipt.get("dynamic_logs_modified") is not False
        or receipt.get("mutation_transcripts_modified") is not False
        or receipt.get("optional_ubuntu") != "NOT_RUN"
        or receipt.get("arch_stable") is not False
        or receipt.get("ppa") != "UNQUALIFIED"
    ):
        raise RebindError("delta-rebind receipt contract mismatch")
    inputs = receipt.get("inputs")
    outputs = receipt.get("outputs")
    if not isinstance(inputs, dict) or not isinstance(outputs, dict):
        raise RebindError("delta-rebind artifact inventory is malformed")
    resolved_inputs: dict[str, pathlib.Path] = {}
    for name, item in inputs.items():
        if not isinstance(item, dict):
            raise RebindError(f"input artifact is malformed: {name}")
        path = workspace_path(root, pathlib.Path(item["path"]), must_exist=True)
        if digest(path) != item.get("sha256") or path.stat().st_size != item.get("size_bytes"):
            raise RebindError(f"input artifact drift: {name}")
        resolved_inputs[name] = path
    resolved_outputs: dict[str, pathlib.Path] = {}
    for name, item in outputs.items():
        if not isinstance(item, dict):
            raise RebindError(f"output artifact is malformed: {name}")
        path = workspace_path(root, pathlib.Path(item["path"]), must_exist=True)
        if digest(path) != item.get("sha256") or path.stat().st_size != item.get("size_bytes"):
            raise RebindError(f"output artifact drift: {name}")
        resolved_outputs[name] = path
    expected, context = project_manifest(
        root=root,
        source_path=resolved_inputs["source_architecture_manifest"],
        baseline_rtl_path=resolved_inputs["baseline_rtl_manifest"],
        current_rtl_path=resolved_inputs["current_rtl_manifest"],
        layered_path=resolved_inputs["layered_system_receipt"],
        census_path=resolved_inputs["producer_holder_census"],
    )
    observed_manifest = read_json(resolved_outputs["architecture_manifest"])
    expected["generated_at_utc"] = observed_manifest.get("generated_at_utc")
    if observed_manifest != expected:
        raise RebindError("current architecture manifest differs from canonical replay")
    observed_result = read_json(resolved_outputs["architecture_result"])
    current_result = arch.evaluate(root, resolved_outputs["architecture_manifest"])
    if normalized_result(observed_result) != normalized_result(current_result):
        raise RebindError("architecture result differs from canonical evaluation")
    observed_negative = read_json(resolved_outputs["negative_summary"])
    if observed_negative != negative_summary(root, observed_manifest):
        raise RebindError("negative summary differs from canonical fixtures")
    changed_files = receipt.get("rtl_delta", {}).get("changed_files")
    if changed_files != context["rtl_delta"]:
        raise RebindError("receipt RTL delta differs from canonical projection")
    if receipt.get("current_design_id") != context["design_id"]:
        raise RebindError("receipt current design-id mismatch")
    print(
        "[ARCH-CURRENT-DELTA-REBIND-VERIFY][PASS] "
        f"design_id={context['design_id']} changed={len(context['rtl_delta'])} "
        "gates=9/9 negative=4/4"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    build_parser = commands.add_parser("build")
    build_parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    build_parser.add_argument("--source-manifest", required=True, type=pathlib.Path)
    build_parser.add_argument(
        "--baseline-rtl-manifest", required=True, type=pathlib.Path)
    build_parser.add_argument(
        "--current-rtl-manifest", required=True, type=pathlib.Path)
    build_parser.add_argument("--layered-receipt", required=True, type=pathlib.Path)
    build_parser.add_argument("--census", required=True, type=pathlib.Path)
    build_parser.add_argument("--output-manifest", required=True, type=pathlib.Path)
    build_parser.add_argument("--result", required=True, type=pathlib.Path)
    build_parser.add_argument("--negative-summary", required=True, type=pathlib.Path)
    build_parser.add_argument("--receipt", required=True, type=pathlib.Path)
    build_parser.set_defaults(handler=build)
    verify_parser = commands.add_parser("verify")
    verify_parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    verify_parser.add_argument("--receipt", required=True, type=pathlib.Path)
    verify_parser.set_defaults(handler=verify)
    args = parser.parse_args()
    try:
        return int(args.handler(args))
    except (
        OSError, UnicodeDecodeError, KeyError, RebindError,
        layered.SignoffError, json.JSONDecodeError,
    ) as exc:
        print(f"[ARCH-CURRENT-DELTA-REBIND][FAIL] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
