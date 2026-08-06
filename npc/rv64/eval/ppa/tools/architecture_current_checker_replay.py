#!/usr/bin/env python3
"""Replay current RV64 architecture provenance after checker-only drift."""

from __future__ import annotations

import argparse
import copy
import datetime
import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
SPEC = importlib.util.spec_from_file_location("architecture_hard_gates", ARCH_TOOL)
assert SPEC is not None and SPEC.loader is not None
arch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = arch
SPEC.loader.exec_module(arch)

SCHEMA = "rv64-architecture-current-checker-replay-v1"
ALLOWED_DRIFT_PATHS = frozenset({
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
})
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


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(
        path.read_text(encoding="utf-8"),
        parse_constant=lambda token: (_ for _ in ()).throw(
            ValueError(f"non-finite JSON constant: {token}")),
    )
    if not isinstance(value, dict):
        raise ValueError(f"JSON root is not an object: {path}")
    return value


def workspace_path(
    root: pathlib.Path, value: pathlib.Path, *, must_exist: bool,
) -> pathlib.Path:
    path = value if value.is_absolute() else root / value
    path = path.resolve(strict=must_exist)
    if not path.is_relative_to(root):
        raise ValueError(f"path escapes workspace: {value}")
    if must_exist and not path.is_file():
        raise ValueError(f"input is not a file: {value}")
    if not must_exist:
        path.parent.mkdir(parents=True, exist_ok=True)
    return path


def atomic_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    try:
        temporary.write_text(
            json.dumps(
                value, allow_nan=False, ensure_ascii=False, indent=2,
                sort_keys=True,
            ) + "\n",
            encoding="utf-8",
        )
        parse_json(temporary)
        temporary.replace(path)
    finally:
        if temporary.exists():
            temporary.unlink()


def required_paths(test_id: str, provenance: dict[str, Any]) -> set[str]:
    if provenance.get("mode") == "task-run-v1" and test_id in TASK_RUN_SOURCE_PATHS:
        return set(TASK_RUN_SOURCE_PATHS[test_id])
    return set(PROVENANCE_PATHS[test_id])


def refresh_record(
    root: pathlib.Path, test_id: str, record: dict[str, Any],
) -> tuple[dict[str, Any], list[str]]:
    updated = copy.deepcopy(record)
    provenance = updated.get("provenance")
    files = provenance.get("files") if isinstance(provenance, dict) else None
    if not isinstance(files, dict) or set(files) != required_paths(test_id, provenance):
        raise ValueError(f"{test_id}: provenance inventory mismatch")
    drift: list[str] = []
    for rel, old_sha in sorted(files.items()):
        path = arch.safe_artifact(root, rel)
        current_sha = arch.digest(path)
        if current_sha == old_sha:
            continue
        if rel not in ALLOWED_DRIFT_PATHS:
            raise ValueError(f"{test_id}: unauthorized provenance drift: {rel}")
        files[rel] = current_sha
        drift.append(rel)
    provenance["sha256"] = arch.canonical_digest(files)
    return updated, drift


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    parser.add_argument("--input", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--result", required=True, type=pathlib.Path)
    parser.add_argument("--receipt", required=True, type=pathlib.Path)
    args = parser.parse_args()
    try:
        root = args.repo_root.resolve(strict=True)
        source = workspace_path(root, args.input, must_exist=True)
        output = workspace_path(root, args.output, must_exist=False)
        result_path = workspace_path(root, args.result, must_exist=False)
        receipt_path = workspace_path(root, args.receipt, must_exist=False)
        if len({source, output, result_path, receipt_path}) != 4:
            raise ValueError("checker replay paths must be distinct")
        before = arch.evaluate(root, source)
        if before.get("evidence_errors"):
            raise ValueError("input architecture manifest has structural errors")
        expected_red_by_test: dict[str, set[str]] = {}
        for gate_id, gate in before["gates"].items():
            test_id = gate["evidence_test"]
            red = {
                item["check_id"] for item in gate["checks"]
                if item["status"] == "RED"
            }
            if red:
                expected = {
                    f"evidence.{test_id}.provenance_files",
                    f"evidence.{test_id}.provenance_digest",
                }
                if red != expected:
                    raise ValueError(
                        f"{gate_id}: non-provenance checker failures: {sorted(red)}")
                expected_red_by_test[test_id] = red
        if not expected_red_by_test:
            raise ValueError("checker replay input has no authorized drift")

        manifest = parse_json(source)
        source_sha, _ = arch.rtl_binding(root)
        design_id = f"sha256:{source_sha}"
        tests = manifest.get("tests")
        if (
            manifest.get("schema") != arch.EVIDENCE_SCHEMA
            or manifest.get("design_id") != design_id
            or not isinstance(tests, dict)
            or set(tests) != set(PROVENANCE_PATHS)
        ):
            raise ValueError("checker replay input inventory/design mismatch")
        updated_tests: dict[str, Any] = {}
        drift_by_test: dict[str, list[str]] = {}
        for test_id, record in tests.items():
            if not isinstance(record, dict):
                raise ValueError(f"{test_id}: evidence record is not an object")
            updated, drift = refresh_record(root, test_id, record)
            updated_tests[test_id] = updated
            if drift:
                drift_by_test[test_id] = drift
        if set(drift_by_test) != set(expected_red_by_test):
            raise ValueError("checker replay drift set does not match RED gates")
        replayed = copy.deepcopy(manifest)
        replayed["generated_at_utc"] = datetime.datetime.now(
            datetime.timezone.utc).isoformat()
        replayed["tests"] = updated_tests
        atomic_json(output, replayed)
        after = arch.evaluate(root, output)
        if (
            after.get("overall_status") != "GREEN"
            or after.get("exit_code") != 0
            or after.get("evidence_errors")
            or any(item.get("status") != "GREEN" for item in after["gates"].values())
        ):
            raise ValueError("checker replay did not close all nine architecture gates")
        atomic_json(result_path, after)
        receipt = {
            "schema": SCHEMA,
            "status": "PASS",
            "claim": "checker_only_provenance_replay",
            "generated_at_utc": datetime.datetime.now(
                datetime.timezone.utc).isoformat(),
            "design_id": design_id,
            "allowed_drift_paths": sorted(ALLOWED_DRIFT_PATHS),
            "updated_tests": sorted(drift_by_test),
            "drift_by_test": drift_by_test,
            "input": {
                "path": source.relative_to(root).as_posix(),
                "sha256": digest(source),
            },
            "output": {
                "path": output.relative_to(root).as_posix(),
                "sha256": digest(output),
            },
            "result": {
                "path": result_path.relative_to(root).as_posix(),
                "sha256": digest(result_path),
                "overall_status": "GREEN",
                "green_gates": sorted(after["gates"]),
            },
            "production_rtl_changed": False,
            "simulation_reexecuted": False,
            "ppa": "UNPROMOTED",
        }
        atomic_json(receipt_path, receipt)
        print(
            "[ARCH-CURRENT-CHECKER-REPLAY][PASS] "
            f"design_id={design_id} updated={len(drift_by_test)} gates=9/9"
        )
        return 0
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[ARCH-CURRENT-CHECKER-REPLAY][FAIL] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
