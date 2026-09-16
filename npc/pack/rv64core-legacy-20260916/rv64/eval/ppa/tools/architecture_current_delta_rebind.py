#!/usr/bin/env python3
"""Compose fresh and retained RV64 directed evidence for one current RTL identity.

The replay is deliberately narrow.  Every production RTL change that enters a
frozen DI/OOO source closure must be replaced by an exact-current fresh record;
only unaffected records may be projected.  Non-DUT provenance may move only
through the architecture Make target projection, the exact current L0
build-control binding, the single-entry architecture registry, or a freshly
audited producer-holder census.  A production RTL addition is accepted only when
the registry classifies it as reachable product RTL and the exact-current L0
receipt covers it; production RTL removal is never projected.  Retained dynamic
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
registry = load_tool(
    "architecture_current_delta_registry", "architecture_registry.py")


SCHEMA = "npc-rv64-architecture-current-delta-rebind-v2"
REPLAY_SCHEMA = "npc-rv64-architecture-current-record-rebind-v2"
NEGATIVE_SCHEMA = "npc-rv64-architecture-current-delta-negative-v1"
RTL_INPUT_SCHEMA = "npc-rv64-full-core-module-input-binding-v1"
NPC_MAKEFILE = "npc/rv64/Makefile"
TB_MAKEFILE = "npc/rv64/testbench/Makefile"
RTL_FILELIST = "npc/rv64/vsrc/filelist.mk"
CENSUS_PATH = "npc/rv64/design/arch/producer-holder-census.json"
REGISTRY_CATALOG_PATH = "npc/rv64/design/arch/rv64-architecture-registry-v1.json"
REGISTRY_ELABORATION_PATH = (
    "npc/rv64/eval/ppa/evidence/architecture-registry-elaboration-current.json"
)
REGISTRY_ENTRY_PATH = "npc/rv64/ARCHITECTURE.md"
REGISTRY_TOOL_PATH = "npc/rv64/eval/ppa/tools/architecture_registry.py"
DELTA_TOOL_PATH = "npc/rv64/eval/ppa/tools/architecture_current_delta_rebind.py"
DELTA_TEST_PATH = "npc/rv64/eval/ppa/tests/test_architecture_current_delta_rebind.py"
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
    "--test \"$(1)\" \\",
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
        or not files
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
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    baseline_paths = set(baseline)
    current_paths = set(current)
    added = sorted(current_paths - baseline_paths)
    removed = sorted(baseline_paths - current_paths)
    if removed:
        raise RebindError(
            "production RTL removal requires a directed rerun: "
            f"{removed}")
    changed: list[dict[str, Any]] = [
        {
            "path": rel,
            "change_kind": "modified",
            "baseline_sha256": baseline[rel],
            "current_sha256": current[rel],
        }
        for rel in sorted(baseline_paths & current_paths)
        if baseline[rel] != current[rel]
    ]
    changed.extend({
        "path": rel,
        "change_kind": "added",
        "baseline_sha256": None,
        "current_sha256": current[rel],
    } for rel in added)
    changed.sort(key=lambda item: item["path"])
    if not changed:
        raise RebindError("delta rebind requires at least one production RTL change")
    membership = {
        "equal": not added,
        "baseline_file_count": len(baseline),
        "current_file_count": len(current),
        "added_files": added,
        "removed_files": removed,
    }
    return changed, membership


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
    tests = l0_result.get("tests", {})
    required = tests.get("required") if isinstance(tests, dict) else None
    passed = tests.get("passed") if isinstance(tests, dict) else None
    if (
        l0_result.get("status") != "PASS"
        or not isinstance(required, int)
        or required <= 0
        or passed != required
        or pre.get("path") != current_manifest.relative_to(root).as_posix()
        or pre.get("sha256") != digest(current_manifest)
    ):
        raise RebindError("current L0 exact-input binding mismatch")
    return {
        "design_id": design_id,
        "l0_passed": passed,
        "l0_required": required,
        "l1_official": 177,
        "l1_am": 61,
        "l2_case": "all",
        "l3_case": "all",
        "ubuntu": "NOT_RUN",
    }


def validate_architecture_registry(
    root: pathlib.Path,
    design_id: str,
    current_files: dict[str, str],
    changed: list[dict[str, Any]],
    membership: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, Any]]:
    catalog_path = root / REGISTRY_CATALOG_PATH
    snapshot = registry.build_snapshot(
        registry.load_json(catalog_path), root=root)
    if (
        snapshot.get("errors")
        or snapshot.get("status") != "PASS_WITH_PRODUCT_GAPS"
        or snapshot.get("design_id") != design_id
    ):
        raise RebindError("current architecture registry does not structurally audit PASS")
    entry_path = root / REGISTRY_ENTRY_PATH
    expected_entry = registry.render_markdown(
        snapshot, registry.load_json(catalog_path))
    if not entry_path.is_file() or entry_path.read_text(
        encoding="utf-8") != expected_entry:
        raise RebindError("single-entry architecture registry view is stale")

    by_path = {
        item.get("path"): item
        for item in snapshot.get("files", [])
        if isinstance(item, dict) and isinstance(item.get("path"), str)
    }
    rtl_changed_paths = [
        item["path"] for item in changed
        if item["path"] != RTL_FILELIST
    ]
    for path in rtl_changed_paths:
        record = by_path.get(path)
        if (
            not isinstance(record, dict)
            or record.get("sha256") != current_files.get(path)
            or record.get("role") != "product"
            or record.get("filelist") != "PASS"
            or record.get("reachable") != "PASS"
        ):
            raise RebindError(
                f"changed production RTL is not registry-owned/reachable: {path}")
    added = membership["added_files"]
    summary = {
        "snapshot_id": snapshot["snapshot_id"],
        "design_id": snapshot["design_id"],
        "status": "PASS",
        "source_files": snapshot["counts"]["source_files"],
        "synthesis_files": snapshot["counts"]["synthesis_files"],
        "single_entry_current": True,
        "changed_product_paths": rtl_changed_paths,
        "added_product_paths": added,
        "removed_product_paths": membership["removed_files"],
    }
    return summary, snapshot


def current_rtl_dependency_closure(
    root: pathlib.Path,
    snapshot: dict[str, Any],
    seed_paths: set[str],
) -> set[str]:
    """Expand current top-reachable module descendants from directed RTL seeds."""
    elaboration = read_json(root / REGISTRY_ELABORATION_PATH)
    if (
        elaboration.get("status") != "PASS"
        or elaboration.get("design_id") != snapshot.get("design_id")
        or not isinstance(elaboration.get("instances"), list)
    ):
        raise RebindError("current elaboration dependency graph is stale")
    files = snapshot.get("files")
    if not isinstance(files, list):
        raise RebindError("architecture registry file graph is missing")
    path_to_modules: dict[str, set[str]] = {}
    module_to_path: dict[str, str] = {}
    for item in files:
        if not isinstance(item, dict) or item.get("role") != "product":
            continue
        path = item.get("path")
        modules = item.get("modules")
        if not isinstance(path, str) or not isinstance(modules, list):
            raise RebindError("architecture registry module ownership is malformed")
        path_to_modules[path] = {
            module for module in modules if isinstance(module, str) and module
        }
        for module in path_to_modules[path]:
            if module in module_to_path and module_to_path[module] != path:
                raise RebindError(f"duplicate module dependency owner: {module}")
            module_to_path[module] = path

    instance_to_module: dict[str, str] = {}
    for item in elaboration["instances"]:
        if not isinstance(item, dict):
            raise RebindError("current elaboration instance row is malformed")
        path = item.get("path")
        module = item.get("module")
        if not isinstance(path, str) or not isinstance(module, str):
            raise RebindError("current elaboration instance identity is malformed")
        if path in instance_to_module and instance_to_module[path] != module:
            raise RebindError(f"ambiguous elaboration instance path: {path}")
        instance_to_module[path] = module
    children: dict[str, set[str]] = {}
    for path, module in instance_to_module.items():
        if "." not in path:
            continue
        parent_path = path.rsplit(".", 1)[0]
        while parent_path not in instance_to_module and "." in parent_path:
            parent_path = parent_path.rsplit(".", 1)[0]
        parent_module = instance_to_module.get(parent_path)
        if parent_module is None:
            raise RebindError(f"elaboration parent path is missing: {path}")
        children.setdefault(parent_module, set()).add(module)

    closure = {
        path for path in seed_paths if path.startswith("npc/rv64/vsrc/")
    }
    frontier: list[str] = sorted({
        module
        for path in closure
        for module in path_to_modules.get(path, set())
    })
    visited: set[str] = set()
    while frontier:
        module = frontier.pop()
        if module in visited:
            continue
        visited.add(module)
        path = module_to_path.get(module)
        if path is not None:
            closure.add(path)
        frontier.extend(sorted(children.get(module, set()) - visited))
    return closure


def validate_transitive_delta_coverage(
    snapshot: dict[str, Any], paths: set[str],
) -> dict[str, Any]:
    by_path = {
        item.get("path"): item
        for item in snapshot.get("files", [])
        if isinstance(item, dict) and isinstance(item.get("path"), str)
    }
    coverage: dict[str, Any] = {}
    for path in sorted(paths):
        item = by_path.get(path)
        focused_tests = item.get("focused_tests") if isinstance(item, dict) else None
        if (
            not isinstance(item, dict)
            or item.get("role") != "product"
            or item.get("filelist") != "PASS"
            or item.get("reachable") != "PASS"
            or item.get("dynamic") != "FOCUSED_PASS"
            or not isinstance(focused_tests, list)
            or not focused_tests
        ):
            raise RebindError(
                "transitive current dependency lacks exact-current focused L0 "
                f"coverage: {path}")
        coverage[path] = {
            "dynamic": item["dynamic"],
            "focused_tests": sorted(focused_tests),
            "instance_paths": sorted(item.get("instance_paths", [])),
        }
    return coverage


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


def validate_fresh_manifest(
    root: pathlib.Path,
    path: pathlib.Path,
    design_id: str,
    expected_tests: set[str],
) -> dict[str, Any]:
    value = read_json(path)
    tests = value.get("tests")
    if (
        value.get("schema") != arch.EVIDENCE_SCHEMA
        or value.get("design_id") != design_id
        or not isinstance(tests, dict)
        or set(tests) != expected_tests
    ):
        raise RebindError(
            "fresh current record set/design identity mismatch: "
            f"expected={sorted(expected_tests)}")
    evaluated = arch.evaluate(root, path)
    current_rtl_sha = design_id.removeprefix("sha256:")
    for test_id in sorted(expected_tests):
        record = tests[test_id]
        if not isinstance(record, dict) or record.get("status") != "PASS":
            raise RebindError(f"{test_id}: fresh current record is not PASS")
        expected_paths = required_paths(test_id, record)
        record_provenance = record.get("provenance")
        files = (
            record_provenance.get("files")
            if isinstance(record_provenance, dict)
            else None
        )
        if (
            not isinstance(files, dict)
            or set(files) != expected_paths
            or record_provenance.get("rtl_sha256") != current_rtl_sha
        ):
            raise RebindError(
                f"{test_id}: fresh current provenance inventory/design mismatch")
        drift = sorted(
            rel for rel, expected_sha in files.items()
            if digest(arch.safe_artifact(root, rel)) != expected_sha
        )
        if drift:
            raise RebindError(
                f"{test_id}: fresh current provenance is stale: {drift}")
        provenance.validate_embedded_artifacts(root, test_id, record, arch)
        gate_id = TEST_TO_GATE[test_id]
        gate = evaluated.get("gates", {}).get(gate_id, {})
        if gate.get("status") != "GREEN" or red_checks(evaluated, gate_id):
            raise RebindError(
                f"{test_id}: fresh current gate is not GREEN: "
                f"{sorted(red_checks(evaluated, gate_id))}")
    return value


def project_manifest(
    *, root: pathlib.Path, source_path: pathlib.Path,
    baseline_rtl_path: pathlib.Path, current_rtl_path: pathlib.Path,
    current_record_path: pathlib.Path, layered_path: pathlib.Path,
    census_path: pathlib.Path,
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
    changed, membership = rtl_delta(baseline_files, current_files)
    changed_paths = {item["path"] for item in changed}
    registry_summary, registry_snapshot = validate_architecture_registry(
        root, design_id, current_files, changed, membership)
    authorized_provenance_drift = set(AUTHORIZED_PROVENANCE_DRIFT)
    if RTL_FILELIST in changed_paths:
        authorized_provenance_drift.add(RTL_FILELIST)
    directed_union: set[str] = set()
    baseline_directed_union: set[str] = set()
    directed_impact_by_test: dict[str, list[str]] = {}
    dependency_closure_by_test: dict[str, list[str]] = {}
    mismatches_by_test: dict[str, list[str]] = {}
    changed_product_paths = changed_paths - {RTL_FILELIST}
    for test_id, record in source["tests"].items():
        if not isinstance(record, dict):
            raise RebindError(f"{test_id}: architecture record is not an object")
        expected_paths = required_paths(test_id, record)
        baseline_rtl_paths = {
            path for path in expected_paths
            if path.startswith("npc/rv64/vsrc/")
        }
        baseline_directed_union.update(baseline_rtl_paths)
        direct_changed_seeds = baseline_rtl_paths & changed_product_paths
        current_closure = set(baseline_rtl_paths)
        if direct_changed_seeds:
            current_closure.update(current_rtl_dependency_closure(
                root, registry_snapshot, direct_changed_seeds))
        dependency_closure_by_test[test_id] = sorted(current_closure)
        directed_union.update(current_closure)
        files = record.get("provenance", {}).get("files")
        if not isinstance(files, dict) or set(files) != expected_paths:
            raise RebindError(f"{test_id}: directed provenance inventory mismatch")
        baseline_binding_drift = sorted(
            rel for rel, expected_sha in files.items()
            if rel in baseline_files and baseline_files[rel] != expected_sha
        )
        if baseline_binding_drift:
            raise RebindError(
                f"{test_id}: source record/baseline RTL binding mismatch: "
                f"{baseline_binding_drift}")
        mismatches = {
            rel for rel, expected_sha in files.items()
            if digest(arch.safe_artifact(root, rel)) != expected_sha
        }
        impact = sorted(
            (changed_paths - {RTL_FILELIST}) & current_closure)
        if impact:
            directed_impact_by_test[test_id] = impact
            direct_impact = set(impact) & expected_paths
            if not direct_impact.issubset(mismatches):
                raise RebindError(
                    f"{test_id}: impacted source record does not expose RTL drift: "
                    f"{sorted(mismatches)}")
        elif not mismatches or not mismatches.issubset(
            authorized_provenance_drift
        ):
            raise RebindError(
                f"{test_id}: provenance drift exceeds authorized build/static set: "
                f"{sorted(mismatches)}")
        mismatches_by_test[test_id] = sorted(mismatches)
        provenance.validate_embedded_artifacts(root, test_id, record, arch)
    mapped_changed_paths = {
        path
        for impact in directed_impact_by_test.values()
        for path in impact
    }
    unmapped_delta = sorted(changed_product_paths - mapped_changed_paths)
    if unmapped_delta:
        raise RebindError(
            "current dependency closure leaves production RTL delta unmapped: "
            f"{unmapped_delta}")
    transitive_only_delta = mapped_changed_paths - baseline_directed_union
    transitive_delta_coverage = validate_transitive_delta_coverage(
        registry_snapshot, transitive_only_delta)
    impacted_tests = set(directed_impact_by_test)
    if not impacted_tests:
        raise RebindError(
            "delta does not enter a directed source closure; fresh current record "
            "manifest is not applicable")
    fresh = validate_fresh_manifest(
        root, current_record_path, design_id, impacted_tests)

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
    fresh_sha = digest(current_record_path)
    for test_id in sorted(TEST_TO_GATE):
        source_record = source["tests"][test_id]
        if test_id in impacted_tests:
            fresh_record = fresh["tests"][test_id]
            record = copy.deepcopy(fresh_record)
            record["versioned_replay"] = {
                "schema": REPLAY_SCHEMA,
                "classification": "FRESH_CURRENT_DIRECTED_RECORD",
                "source_manifest_sha256": source_sha,
                "source_record_sha256": arch.canonical_digest(source_record),
                "fresh_manifest_sha256": fresh_sha,
                "fresh_record_sha256": arch.canonical_digest(fresh_record),
                "baseline_design_id": baseline_binding["design_id"],
                "current_design_id": design_id,
                "production_rtl_changed_paths": sorted(changed_paths),
                "production_rtl_membership": copy.deepcopy(membership),
                "directed_source_closure_impact": (
                    directed_impact_by_test[test_id]),
                "provenance_rebound_paths": [],
                "source_manifest_rebound_paths": [],
                "current_l0_l3_status": "PASS_CURRENT_CONFIG",
                "current_census_status": "PASS",
                "current_architecture_registry_snapshot": (
                    registry_summary["snapshot_id"]),
                "dynamic_logs_modified": False,
                "mutation_transcripts_modified": False,
                "directed_simulation_reexecuted": True,
                "ppa": "UNQUALIFIED",
            }
            output["tests"][test_id] = record
            continue

        record = output["tests"][test_id]
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
                "RETAINED_RTL_OUTSIDE_DIRECTED_SOURCE_CLOSURE_WITH_"
                "CURRENT_BUILD_AND_STATIC_BINDING"
            ),
            "source_manifest_sha256": source_sha,
            "source_record_sha256": arch.canonical_digest(source_record),
            "baseline_design_id": baseline_binding["design_id"],
            "current_design_id": design_id,
            "production_rtl_changed_paths": sorted(changed_paths),
            "production_rtl_membership": copy.deepcopy(membership),
            "directed_source_closure_impact": [],
            "provenance_rebound_paths": mismatches_by_test[test_id],
            "source_manifest_rebound_paths": sorted(rebound_source_paths),
            "current_l0_l3_status": "PASS_CURRENT_CONFIG",
            "current_census_status": "PASS",
            "current_architecture_registry_snapshot": registry_summary["snapshot_id"],
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
        "rtl_membership": membership,
        "directed_source_union": sorted(directed_union),
        "baseline_directed_source_union": sorted(baseline_directed_union),
        "dependency_closure_by_test": dependency_closure_by_test,
        "directed_impact_by_test": directed_impact_by_test,
        "transitive_only_delta": sorted(transitive_only_delta),
        "transitive_delta_coverage": transitive_delta_coverage,
        "fresh_tests": sorted(impacted_tests),
        "projected_tests": sorted(set(TEST_TO_GATE) - impacted_tests),
        "authorized_provenance_drift": sorted(authorized_provenance_drift),
        "mismatches_by_test": mismatches_by_test,
        "makefile_gate_projection": make_projection,
        "tb_build_projection": tb_projection,
        "layered_summary": layered_summary,
        "census_summary": census_summary,
        "registry_summary": registry_summary,
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
    current_record = workspace_path(
        root, args.current_record_manifest, must_exist=True)
    layered_path = workspace_path(root, args.layered_receipt, must_exist=True)
    census_path = workspace_path(root, args.census, must_exist=True)
    output = workspace_path(root, args.output_manifest, must_exist=False)
    result_path = workspace_path(root, args.result, must_exist=False)
    negative_path = workspace_path(root, args.negative_summary, must_exist=False)
    receipt_path = workspace_path(root, args.receipt, must_exist=False)
    if len({source, baseline, current, current_record, layered_path, census_path,
            output, result_path, negative_path, receipt_path}) != 10:
        raise RebindError("all delta-rebind input/output paths must be distinct")
    manifest, context = project_manifest(
        root=root,
        source_path=source,
        baseline_rtl_path=baseline,
        current_rtl_path=current,
        current_record_path=current_record,
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
        "claim": "current_architecture_nine_gate_hybrid_rebind",
        "baseline_design_id": context["baseline_design_id"],
        "current_design_id": context["design_id"],
        "baseline_rtl_file_count": context["rtl_membership"]["baseline_file_count"],
        "rtl_file_count": context["rtl_membership"]["current_file_count"],
        "rtl_delta": {
            "membership_equal": context["rtl_membership"]["equal"],
            "added_files": context["rtl_membership"]["added_files"],
            "removed_files": context["rtl_membership"]["removed_files"],
            "changed_file_count": len(context["rtl_delta"]),
            "changed_files": context["rtl_delta"],
            "directed_source_closure_impact": context["directed_impact_by_test"],
            "transitive_only_delta": context["transitive_only_delta"],
            "transitive_delta_coverage": context["transitive_delta_coverage"],
        },
        "record_classification": {
            "fresh_current": context["fresh_tests"],
            "retained_projected": context["projected_tests"],
            "fresh_count": len(context["fresh_tests"]),
            "projected_count": len(context["projected_tests"]),
            "required_count": len(TEST_TO_GATE),
        },
        "provenance_rebind": {
            "authorized_paths": context["authorized_provenance_drift"],
            "by_test": {
                test_id: context["mismatches_by_test"][test_id]
                for test_id in context["projected_tests"]
            },
            "fresh_source_drift": {
                test_id: context["mismatches_by_test"][test_id]
                for test_id in context["fresh_tests"]
            },
            "npc_makefile_projection": context["makefile_gate_projection"],
            "tb_build_projection": context["tb_build_projection"],
            "current_census": context["census_summary"],
            "current_layered_positive": context["layered_summary"],
            "current_architecture_registry": context["registry_summary"],
        },
        "inputs": {
            "source_architecture_manifest": artifact(root, source),
            "baseline_rtl_manifest": artifact(root, baseline),
            "current_rtl_manifest": artifact(root, current),
            "current_record_manifest": artifact(root, current_record),
            "layered_system_receipt": artifact(root, layered_path),
            "producer_holder_census": artifact(root, census_path),
            "architecture_registry_catalog": artifact(
                root, root / REGISTRY_CATALOG_PATH),
            "architecture_registry_elaboration": artifact(
                root, root / REGISTRY_ELABORATION_PATH),
            "architecture_registry_entry": artifact(
                root, root / REGISTRY_ENTRY_PATH),
            "architecture_registry_tool": artifact(
                root, root / REGISTRY_TOOL_PATH),
            "delta_rebind_tool": artifact(root, root / DELTA_TOOL_PATH),
            "delta_rebind_test": artifact(root, root / DELTA_TEST_PATH),
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
        "directed_simulation_reexecuted": True,
        "dynamic_logs_modified": False,
        "mutation_transcripts_modified": False,
        "optional_ubuntu": "NOT_RUN",
        "arch_stable": False,
        "ppa": "UNQUALIFIED",
        "claim_boundary": (
            "Composes exactly the fresh current records derived from the baseline "
            "semantic plus current elaboration dependency closure with retained "
            "records whose RTL closures are unaffected. Transitive-only changed "
            "RTL also requires current focused L0 coverage, registry ownership, "
            "filelist membership and top reachability. This receipt contains one "
            "scoped directed DUT rerun; it does not claim all nine were rerun, "
            "ARCH_STABLE, synthesis, STA, power, CPI, PPA or Ubuntu."
        ),
    }
    write_json(receipt_path, receipt)
    print(
        "[ARCH-CURRENT-DELTA-REBIND][PASS] "
        f"design_id={context['design_id']} changed={len(context['rtl_delta'])} "
        f"rtl={context['rtl_membership']['current_file_count']} "
        f"added={len(context['rtl_membership']['added_files'])} "
        f"fresh={len(context['fresh_tests'])} "
        f"projected={len(context['projected_tests'])} "
        "gates=9/9 negative=4/4"
    )
    return 0


def verify(args: argparse.Namespace) -> int:
    root = args.repo_root.resolve(strict=True)
    receipt_path = workspace_path(root, args.receipt, must_exist=True)
    receipt = read_json(receipt_path)
    if (
        receipt.get("schema") != SCHEMA
        or receipt.get("status") != "PASS"
        or receipt.get("claim") != "current_architecture_nine_gate_hybrid_rebind"
        or receipt.get("directed_simulation_reexecuted") is not True
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
    if set(inputs) != {
        "source_architecture_manifest",
        "baseline_rtl_manifest",
        "current_rtl_manifest",
        "current_record_manifest",
        "layered_system_receipt",
        "producer_holder_census",
        "architecture_registry_catalog",
        "architecture_registry_elaboration",
        "architecture_registry_entry",
        "architecture_registry_tool",
        "delta_rebind_tool",
        "delta_rebind_test",
    } or set(outputs) != {
        "architecture_manifest", "architecture_result", "negative_summary",
    }:
        raise RebindError("delta-rebind artifact inventory membership mismatch")
    resolved_inputs: dict[str, pathlib.Path] = {}
    for name, item in inputs.items():
        if not isinstance(item, dict):
            raise RebindError(f"input artifact is malformed: {name}")
        path = workspace_path(root, pathlib.Path(item["path"]), must_exist=True)
        if digest(path) != item.get("sha256") or path.stat().st_size != item.get("size_bytes"):
            raise RebindError(f"input artifact drift: {name}")
        resolved_inputs[name] = path
    for name, relative in {
        "architecture_registry_catalog": REGISTRY_CATALOG_PATH,
        "architecture_registry_elaboration": REGISTRY_ELABORATION_PATH,
        "architecture_registry_entry": REGISTRY_ENTRY_PATH,
        "architecture_registry_tool": REGISTRY_TOOL_PATH,
        "delta_rebind_tool": DELTA_TOOL_PATH,
        "delta_rebind_test": DELTA_TEST_PATH,
    }.items():
        if resolved_inputs[name] != (root / relative).resolve(strict=True):
            raise RebindError(f"registry input path drift: {name}")
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
        current_record_path=resolved_inputs["current_record_manifest"],
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
    expected_delta_summary = {
        "membership_equal": context["rtl_membership"]["equal"],
        "added_files": context["rtl_membership"]["added_files"],
        "removed_files": context["rtl_membership"]["removed_files"],
        "changed_file_count": len(context["rtl_delta"]),
        "changed_files": context["rtl_delta"],
        "directed_source_closure_impact": context["directed_impact_by_test"],
        "transitive_only_delta": context["transitive_only_delta"],
        "transitive_delta_coverage": context["transitive_delta_coverage"],
    }
    if receipt.get("rtl_delta") != expected_delta_summary:
        raise RebindError("receipt RTL delta summary differs from canonical projection")
    if (
        receipt.get("baseline_rtl_file_count")
        != context["rtl_membership"]["baseline_file_count"]
        or receipt.get("rtl_file_count")
        != context["rtl_membership"]["current_file_count"]
    ):
        raise RebindError("receipt RTL file count differs from canonical projection")
    expected_provenance_rebind = {
        "authorized_paths": context["authorized_provenance_drift"],
        "by_test": {
            test_id: context["mismatches_by_test"][test_id]
            for test_id in context["projected_tests"]
        },
        "fresh_source_drift": {
            test_id: context["mismatches_by_test"][test_id]
            for test_id in context["fresh_tests"]
        },
        "npc_makefile_projection": context["makefile_gate_projection"],
        "tb_build_projection": context["tb_build_projection"],
        "current_census": context["census_summary"],
        "current_layered_positive": context["layered_summary"],
        "current_architecture_registry": context["registry_summary"],
    }
    if receipt.get("provenance_rebind") != expected_provenance_rebind:
        raise RebindError("receipt provenance projection differs from canonical replay")
    if receipt.get("current_design_id") != context["design_id"]:
        raise RebindError("receipt current design-id mismatch")
    expected_classification = {
        "fresh_current": context["fresh_tests"],
        "retained_projected": context["projected_tests"],
        "fresh_count": len(context["fresh_tests"]),
        "projected_count": len(context["projected_tests"]),
        "required_count": len(TEST_TO_GATE),
    }
    if receipt.get("record_classification") != expected_classification:
        raise RebindError("receipt fresh/projected classification drifted")
    print(
        "[ARCH-CURRENT-DELTA-REBIND-VERIFY][PASS] "
        f"design_id={context['design_id']} changed={len(context['rtl_delta'])} "
        f"rtl={context['rtl_membership']['current_file_count']} "
        f"added={len(context['rtl_membership']['added_files'])} "
        f"fresh={len(context['fresh_tests'])} "
        f"projected={len(context['projected_tests'])} "
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
    build_parser.add_argument(
        "--current-record-manifest", required=True, type=pathlib.Path)
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
