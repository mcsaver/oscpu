#!/usr/bin/env python3
"""Fail-closed replay for non-DUT RV64 architecture evidence provenance drift."""

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


REPLAY_SCHEMA = "npc-rv64-architecture-provenance-replay-v1"
RECEIPT_SCHEMA = "npc-rv64-architecture-provenance-replay-receipt-v1"
NEGATIVE_SCHEMA = "npc-rv64-architecture-provenance-replay-negative-v1"
MAKEFILE_PATH = "npc/rv64/Makefile"
ARCH_TOOL_PATH = "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
TEST_TO_GATE = {
    "frontend_ii1": "DI-1",
    "width_continuity": "DI-2",
    "pair_matrix": "DI-3",
    "no_static_lane_semantics": "DI-4",
    "dual_memory_issue": "DI-5",
    "true_ooo_long_latency": "OOO-1",
    "selective_scheduling": "OOO-2",
    "memory_ordering": "OOO-3",
    "speculation_recovery": "OOO-4",
}
TEST_TO_MAKE_TARGET = {
    "frontend_ii1": "check-frontend-ii1",
    "width_continuity": "check-width-continuity",
    "pair_matrix": "check-pair-matrix",
    "no_static_lane_semantics": "check-no-static-lane-semantics",
    "dual_memory_issue": "check-dual-memory-sustained-issue",
    "true_ooo_long_latency": "check-true-ooo-long-latency",
    "selective_scheduling": "check-selective-scheduling",
    "memory_ordering": "check-memory-ordering",
    "speculation_recovery": "check-speculation-recovery",
}
EXPECTED_MAKE_RECIPES = {
    "check-selective-scheduling": (
        "@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/run-focused.sh)",
    ),
    "check-true-ooo-long-latency": (
        "@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/run-focused.sh)",
    ),
    "check-no-static-lane-semantics": (
        "@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/run-focused.sh)",
    ),
    "check-pair-matrix": (
        "@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners/run-focused.sh)",
    ),
    "check-dual-memory-sustained-issue": (
        "@bash $(abspath ../../.github/task-runs/2026-07-20-rv64-v8u-dual-memory-sustained-issue/run-focused.sh)",
    ),
    "check-memory-ordering": (
        "@bash $(abspath ../../.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/run-focused.sh)",
        "@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/run-focused.sh)",
    ),
    "check-speculation-recovery": (
        "@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/run-focused.sh)",
    ),
    "check-frontend-ii1": (
        "@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/run-focused.sh)",
    ),
    "check-width-continuity": (
        "@bash $(abspath ../../.github/task-runs/2026-07-21-rv64-v9a-width-continuity/run-focused.sh)",
    ),
}


class ReplayError(ValueError):
    """Raised when provenance replay would exceed its frozen evidence scope."""


def sha256_file(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def canonical_sha(value: Any) -> str:
    encoded = json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=True,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def read_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ReplayError(f"JSON root is not an object: {path}")
    return value


def write_json(path: pathlib.Path, value: Any) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def workspace_file(root: pathlib.Path, relative: str) -> pathlib.Path:
    candidate = pathlib.PurePosixPath(relative)
    if candidate.is_absolute() or ".." in candidate.parts:
        raise ReplayError(f"workspace path is not normalized: {relative}")
    path = (root / candidate).resolve(strict=True)
    if not path.is_relative_to(root) or not path.is_file():
        raise ReplayError(f"workspace artifact is not a regular file: {relative}")
    return path


def load_architecture_tool(root: pathlib.Path) -> Any:
    path = workspace_file(root, ARCH_TOOL_PATH)
    spec = importlib.util.spec_from_file_location(
        "architecture_provenance_replay_arch", path)
    if spec is None or spec.loader is None:
        raise ReplayError("architecture hard-gate checker cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def make_target_recipe(text: str, target: str) -> tuple[str, ...]:
    lines = text.splitlines()
    matches = [
        index for index, line in enumerate(lines)
        if line.startswith(f"{target}:")
    ]
    if len(matches) != 1:
        raise ReplayError(f"Makefile target inventory is not exact: {target}")
    header = lines[matches[0]]
    if header.split(":", 1)[1].strip():
        raise ReplayError(f"Makefile gate target gained prerequisites: {target}")
    recipe: list[str] = []
    for line in lines[matches[0] + 1:]:
        if not line.startswith("\t"):
            break
        recipe.append(line[1:].rstrip())
    return tuple(recipe)


def validate_makefile_gate_projection(text: str) -> dict[str, Any]:
    phony_tokens = [
        token
        for line in text.splitlines()
        if line.startswith(".PHONY:")
        for token in line.split(":", 1)[1].split()
    ]
    targets: dict[str, Any] = {}
    for test_id, target in sorted(TEST_TO_MAKE_TARGET.items()):
        if phony_tokens.count(target) != 1:
            raise ReplayError(
                f"architecture gate .PHONY binding is not exact: {target}")
        observed = make_target_recipe(text, target)
        expected = EXPECTED_MAKE_RECIPES[target]
        if observed != expected:
            raise ReplayError(
                f"architecture gate recipe changed: {target}; "
                f"expected={expected!r} observed={observed!r}")
        targets[test_id] = {"target": target, "recipe": list(observed)}
    return {
        "targets": targets,
        "projection_sha256": canonical_sha(targets),
    }


def validate_rebind_paths(root: pathlib.Path, paths: set[str]) -> dict[str, str]:
    if paths != {MAKEFILE_PATH}:
        raise ReplayError(
            f"exact non-DUT replay path must be {MAKEFILE_PATH}; got={sorted(paths)}")
    result: dict[str, str] = {}
    for relative in sorted(paths):
        if (
            relative.startswith("npc/rv64/vsrc/")
            or relative.startswith("npc/rv64/testbench/")
            or pathlib.PurePosixPath(relative).suffix in {".v", ".sv", ".vh"}
        ):
            raise ReplayError(f"RTL/testbench provenance cannot be rebound: {relative}")
        result[relative] = sha256_file(workspace_file(root, relative))
    return result


def validate_source_manifest(
    root: pathlib.Path, test_id: str, record: dict[str, Any], arch: Any,
    rebind_paths: set[str],
) -> dict[str, str]:
    source_manifest = record.get("source_manifest")
    if source_manifest is None:
        return {}
    files = source_manifest.get("files") if isinstance(source_manifest, dict) else None
    if not isinstance(files, dict) or not files:
        raise ReplayError(f"{test_id}: source_manifest files are absent")
    mismatches: set[str] = set()
    for relative, expected_sha in files.items():
        if not arch.is_sha256(expected_sha):
            raise ReplayError(f"{test_id}: malformed source_manifest hash: {relative}")
        if sha256_file(workspace_file(root, relative)) != expected_sha:
            mismatches.add(relative)
    expected_mismatches = rebind_paths & set(files)
    if mismatches != expected_mismatches:
        raise ReplayError(
            f"{test_id}: source_manifest drift is not exactly the applicable "
            f"allowlist; mismatch={sorted(mismatches)}")
    if source_manifest.get("sha256") != arch.canonical_digest(files):
        raise ReplayError(f"{test_id}: source_manifest aggregate digest drift")
    return {relative: files[relative] for relative in sorted(expected_mismatches)}


def validate_embedded_artifacts(
    root: pathlib.Path, test_id: str, value: Any, arch: Any,
    location: str = "record",
) -> None:
    if isinstance(value, dict):
        path = value.get("path")
        expected_sha = value.get("sha256")
        if isinstance(path, str) and isinstance(expected_sha, str):
            if not arch.is_sha256(expected_sha):
                raise ReplayError(f"{test_id}: malformed artifact hash at {location}")
            if sha256_file(workspace_file(root, path)) != expected_sha:
                raise ReplayError(f"{test_id}: artifact drift at {location}: {path}")
        for key, item in value.items():
            if location == "record.provenance" and key in {"files", "sha256"}:
                continue
            if location == "record" and key == "source_manifest":
                continue
            validate_embedded_artifacts(
                root, test_id, item, arch, f"{location}.{key}")
    elif isinstance(value, list):
        for index, item in enumerate(value):
            validate_embedded_artifacts(
                root, test_id, item, arch, f"{location}[{index}]")


def red_check_ids(result: dict[str, Any], gate_id: str) -> set[str]:
    gate = result.get("gates", {}).get(gate_id, {})
    checks = gate.get("checks") if isinstance(gate, dict) else None
    if not isinstance(checks, list):
        return set()
    return {
        item.get("check_id") for item in checks
        if isinstance(item, dict)
        and item.get("status") == "RED"
        and isinstance(item.get("check_id"), str)
    }


def validate_input_manifest(
    *, root: pathlib.Path, input_path: pathlib.Path,
    manifest: dict[str, Any], rebind_paths: set[str], arch: Any,
) -> tuple[str, dict[str, str], dict[str, Any], dict[str, str]]:
    current_sha = validate_rebind_paths(root, rebind_paths)
    source_sha, _source_files = arch.rtl_binding(root)
    design_id = f"sha256:{source_sha}"
    tests = manifest.get("tests")
    if (
        manifest.get("schema") != arch.EVIDENCE_SCHEMA
        or manifest.get("design_id") != design_id
        or not isinstance(tests, dict)
        or set(tests) != set(TEST_TO_GATE)
    ):
        raise ReplayError("directed manifest schema/design/exact nine-gate inventory mismatch")
    old_hashes: dict[str, str] = {}
    for test_id in sorted(TEST_TO_GATE):
        record = tests[test_id]
        if not isinstance(record, dict):
            raise ReplayError(f"{test_id}: directed evidence record is not an object")
        provenance = record.get("provenance")
        files = provenance.get("files") if isinstance(provenance, dict) else None
        if not isinstance(files, dict) or set(rebind_paths) - set(files):
            raise ReplayError(f"{test_id}: replay path is absent from provenance")
        mismatches: set[str] = set()
        for relative, expected_sha in files.items():
            if not arch.is_sha256(expected_sha):
                raise ReplayError(f"{test_id}: malformed provenance hash: {relative}")
            actual_sha = sha256_file(workspace_file(root, relative))
            if actual_sha != expected_sha:
                mismatches.add(relative)
        if mismatches != rebind_paths:
            raise ReplayError(
                f"{test_id}: provenance drift is not exactly the allowlist; "
                f"mismatch={sorted(mismatches)}")
        for relative in rebind_paths:
            old_hash = files[relative]
            previous = old_hashes.setdefault(relative, old_hash)
            if previous != old_hash:
                raise ReplayError(f"{test_id}: replay source hash is inconsistent")
        source_old_hashes = validate_source_manifest(
            root, test_id, record, arch, rebind_paths)
        for relative, old_hash in source_old_hashes.items():
            previous = old_hashes.setdefault(relative, old_hash)
            if previous != old_hash:
                raise ReplayError(
                    f"{test_id}: source_manifest replay hash is inconsistent")
        validate_embedded_artifacts(root, test_id, record, arch)

    baseline = arch.evaluate(root, input_path)
    if (
        baseline.get("rtl_source_set", {}).get("design_id") != design_id
        or baseline.get("overall_status") != "RED"
        or baseline.get("exit_code") != 1
    ):
        raise ReplayError("input manifest is not the expected current-design provenance-only RED")
    for test_id, gate_id in TEST_TO_GATE.items():
        expected_red = {
            f"evidence.{test_id}.provenance_files",
            f"evidence.{test_id}.provenance_digest",
        }
        if red_check_ids(baseline, gate_id) != expected_red:
            raise ReplayError(
                f"{gate_id}: RED cause exceeds exact provenance drift: "
                f"{sorted(red_check_ids(baseline, gate_id))}")
    projection = validate_makefile_gate_projection(
        workspace_file(root, MAKEFILE_PATH).read_text(encoding="utf-8"))
    return design_id, old_hashes, projection, current_sha


def build_replay_manifest(
    *, manifest: dict[str, Any], design_id: str,
    rebind_paths: set[str], current_sha: dict[str, str],
    input_sha: str, projection_sha: str, replay_tool_sha: str,
    architecture_checker_sha: str, arch: Any,
) -> dict[str, Any]:
    output = copy.deepcopy(manifest)
    output["generated_at_utc"] = datetime.datetime.now(
        datetime.timezone.utc).isoformat()
    output["design_id"] = design_id
    for test_id in sorted(TEST_TO_GATE):
        record = output["tests"][test_id]
        prior_replay = record.get("versioned_replay")
        provenance = record["provenance"]
        for relative in sorted(rebind_paths):
            provenance["files"][relative] = current_sha[relative]
        provenance["sha256"] = arch.canonical_digest(provenance["files"])
        source_manifest = record.get("source_manifest")
        source_rebound_paths: list[str] = []
        if isinstance(source_manifest, dict) and isinstance(
            source_manifest.get("files"), dict
        ):
            source_rebound_paths = sorted(
                rebind_paths & set(source_manifest["files"]))
            for relative in source_rebound_paths:
                source_manifest["files"][relative] = current_sha[relative]
            source_manifest["sha256"] = arch.canonical_digest(
                source_manifest["files"])
        record["versioned_replay"] = {
            "schema": REPLAY_SCHEMA,
            "classification": "NON_DUT_GATE_ENTRY_PROVENANCE_ONLY",
            "source_manifest_sha256": input_sha,
            "source_record_sha256": canonical_sha(manifest["tests"][test_id]),
            "prior_replay_sha256": (
                canonical_sha(prior_replay) if isinstance(prior_replay, dict) else None
            ),
            "replay_tool_sha256": replay_tool_sha,
            "architecture_checker_sha256": architecture_checker_sha,
            "makefile_gate_projection_sha256": projection_sha,
            "provenance_rebound_paths": sorted(rebind_paths),
            "source_manifest_rebound_paths": source_rebound_paths,
            "proof_files_modified": False,
            "gate_log_modified": False,
            "production_rtl_modified": False,
            "dut_rerun": False,
        }
    return output


def evaluate_payload(root: pathlib.Path, payload: dict[str, Any], arch: Any) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="rv64-architecture-replay-") as raw:
        path = pathlib.Path(raw) / "manifest.json"
        write_json(path, payload)
        return arch.evaluate(root, path)


def run_negative_cases(
    root: pathlib.Path, manifest: dict[str, Any], arch: Any,
) -> dict[str, Any]:
    cases: list[dict[str, Any]] = []

    def capture(
        name: str, payload: dict[str, Any], gate_id: str, expected_check: str,
    ) -> None:
        result = evaluate_payload(root, payload, arch)
        red = red_check_ids(result, gate_id)
        if (
            result.get("overall_status") != "RED"
            or result.get("exit_code") != 1
            or expected_check not in red
        ):
            raise ReplayError(f"negative fixture was not detected: {name}")
        cases.append({
            "name": name,
            "gate_id": gate_id,
            "expected_check": expected_check,
            "observed_red_checks": sorted(red),
            "detected": True,
        })

    dropped = copy.deepcopy(manifest)
    del dropped["tests"]["selective_scheduling"]
    capture(
        "missing-ooo2-record", dropped, "OOO-2",
        "evidence.selective_scheduling.record")

    proof = copy.deepcopy(manifest)
    proof_files = proof["tests"]["true_ooo_long_latency"]["provenance"]["proof_files"]
    first_role = sorted(proof_files)[0]
    proof_files[first_role]["sha256"] = "0" * 64
    capture(
        "ooo1-proof-hash-drift", proof, "OOO-1",
        "evidence.true_ooo_long_latency.proof_files")

    rolled_back = copy.deepcopy(manifest)
    rolled_back["tests"]["frontend_ii1"]["provenance"]["files"][MAKEFILE_PATH] = "0" * 64
    capture(
        "di1-makefile-provenance-rollback", rolled_back, "DI-1",
        "evidence.frontend_ii1.provenance_files")

    design = copy.deepcopy(manifest)
    design["design_id"] = "sha256:" + "0" * 64
    capture(
        "aggregate-design-id-drift", design, "DI-1",
        "evidence.design_binding")

    return {
        "schema": NEGATIVE_SCHEMA,
        "status": "PASS",
        "required": 4,
        "detected": len(cases),
        "cases": cases,
    }


def run_replay(
    *, root: pathlib.Path, input_path: pathlib.Path,
    output_dir: pathlib.Path, rebind_paths: set[str],
) -> dict[str, Any]:
    root = root.resolve(strict=True)
    input_path = input_path.resolve(strict=True)
    if not input_path.is_file():
        raise ReplayError("input manifest is not a regular file")
    output_dir = output_dir.resolve()
    if output_dir.exists():
        raise ReplayError("output directory already exists")
    if not output_dir.is_relative_to(root):
        raise ReplayError("output directory must stay inside the workspace")

    arch = load_architecture_tool(root)
    manifest = read_json(input_path)
    design_id, old_hashes, projection, current_sha = validate_input_manifest(
        root=root,
        input_path=input_path,
        manifest=manifest,
        rebind_paths=rebind_paths,
        arch=arch,
    )
    output_dir.mkdir(parents=True)
    input_sha = sha256_file(input_path)
    replay_tool_path = pathlib.Path(__file__).resolve(strict=True)
    replay_tool_sha = sha256_file(replay_tool_path)
    architecture_checker_sha = sha256_file(
        workspace_file(root, ARCH_TOOL_PATH))
    replay = build_replay_manifest(
        manifest=manifest,
        design_id=design_id,
        rebind_paths=rebind_paths,
        current_sha=current_sha,
        input_sha=input_sha,
        projection_sha=projection["projection_sha256"],
        replay_tool_sha=replay_tool_sha,
        architecture_checker_sha=architecture_checker_sha,
        arch=arch,
    )
    replay_path = output_dir / "architecture-current-replay.json"
    result_path = output_dir / "architecture-current-result.json"
    negative_path = output_dir / "negative-summary.json"
    receipt_path = output_dir / "replay-receipt.json"
    write_json(replay_path, replay)
    result = arch.evaluate(root, replay_path)
    write_json(result_path, result)
    if (
        result.get("overall_status") != "GREEN"
        or result.get("exit_code") != 0
        or result.get("rtl_source_set", {}).get("design_id") != design_id
        or any(red_check_ids(result, gate) for gate in TEST_TO_GATE.values())
    ):
        raise ReplayError("rebound current-design directed architecture suite is not GREEN")

    negative = run_negative_cases(root, replay, arch)
    write_json(negative_path, negative)
    receipt = {
        "schema": RECEIPT_SCHEMA,
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc).isoformat(),
        "status": "PASS",
        "classification": "NON_DUT_GATE_ENTRY_PROVENANCE_ONLY",
        "design_id": design_id,
        "rtl_file_count": result["rtl_source_set"]["file_count"],
        "architecture_directed_gates": {
            "status": "GREEN",
            "passed": 9,
            "required": 9,
        },
        "rebound_paths": {
            relative: {
                "before_sha256": old_hashes[relative],
                "after_sha256": current_sha[relative],
            }
            for relative in sorted(rebind_paths)
        },
        "makefile_gate_projection": projection,
        "tools": {
            "architecture_checker": {
                "path": ARCH_TOOL_PATH,
                "sha256": architecture_checker_sha,
            },
            "provenance_replay": {
                "path": replay_tool_path.relative_to(root).as_posix(),
                "sha256": replay_tool_sha,
            },
        },
        "source_manifest": {
            "path": input_path.relative_to(root).as_posix(),
            "sha256": input_sha,
        },
        "replay_manifest": {
            "path": replay_path.relative_to(root).as_posix(),
            "sha256": sha256_file(replay_path),
        },
        "replay_result": {
            "path": result_path.relative_to(root).as_posix(),
            "sha256": sha256_file(result_path),
        },
        "negative_summary": {
            "path": negative_path.relative_to(root).as_posix(),
            "sha256": sha256_file(negative_path),
            "detected": negative["detected"],
            "required": negative["required"],
        },
        "execution_evidence_reused": True,
        "dut_rerun": False,
        "proof_files_modified": False,
        "gate_logs_modified": False,
        "production_rtl_modified": False,
        "canonical_files_written": False,
        "arch_stable": False,
        "ppa": "UNQUALIFIED",
        "unproven_scope": [
            "ARCH_STABLE exact freeze-input inventory",
            "performance measurement contract and CPI baseline",
            "synthesis, STA, power and area qualification",
        ],
        "next_action": "BUILD_AND_AUDIT_CURRENT_ARCH_STABLE_FREEZE_CANDIDATE",
    }
    write_json(receipt_path, receipt)
    return receipt


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    parser.add_argument("--input-manifest", required=True, type=pathlib.Path)
    parser.add_argument("--output-dir", required=True, type=pathlib.Path)
    parser.add_argument(
        "--rebind-path", action="append", required=True,
        help="exact non-DUT provenance path; current contract accepts npc/rv64/Makefile only",
    )
    args = parser.parse_args(argv)
    try:
        receipt = run_replay(
            root=args.repo_root,
            input_path=args.input_manifest,
            output_dir=args.output_dir,
            rebind_paths=set(args.rebind_path),
        )
    except (OSError, ReplayError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        print(f"[RV64-ARCH-PROVENANCE-REPLAY][FAIL] {exc}", file=sys.stderr)
        return 1
    gate = receipt["architecture_directed_gates"]
    negative = receipt["negative_summary"]
    print(
        "[RV64-ARCH-PROVENANCE-REPLAY][PASS] "
        f"design_id={receipt['design_id']} gates={gate['passed']}/{gate['required']} "
        f"negative={negative['detected']}/{negative['required']} "
        "dut_rerun=0 production_rtl_write=0 arch_stable=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
