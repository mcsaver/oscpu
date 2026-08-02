#!/usr/bin/env python3
"""Audit and combine current-design RV64 architecture gate records locally."""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import pathlib
import subprocess
import sys
from typing import Any


TASK_RUN_ID = "2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1"
HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ARCH_TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
CANONICAL_MANIFEST = ROOT / "npc/rv64/eval/ppa/evidence/architecture-current.json"
EXPECTED_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)
SCHEMA = "npc-rv64-architecture-directed-suite-v2"

SOURCES = (
    (
        "v13s-di34",
        ".github/task-runs/2026-08-02-rv64-v13s-architecture-current-rebind-v1/"
        "evidence/current-architecture-manifest.json",
        ("pair_matrix", "no_static_lane_semantics"),
    ),
    (
        "v13t-ooo2",
        ".github/task-runs/2026-08-02-rv64-v13t-ooo2-current-rebind-v1/"
        "evidence/current-architecture-manifest.json",
        ("selective_scheduling",),
    ),
    (
        "v13u-ooo3",
        ".github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/"
        "evidence/architecture-current.json",
        ("memory_ordering",),
    ),
    (
        "v13v-ooo4",
        ".github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/"
        "evidence/architecture-current.json",
        ("speculation_recovery",),
    ),
    (
        "v13x-ooo1",
        ".github/task-runs/2026-08-02-rv64-v13x-ooo1-current-rebind-v1/"
        "evidence/architecture-current.json",
        ("true_ooo_long_latency",),
    ),
    (
        "v13y-di5",
        ".github/task-runs/2026-08-02-rv64-v13y-di5-current-rebind-v1/"
        "evidence/architecture-current.json",
        ("dual_memory_issue",),
    ),
    (
        "v13z-di1",
        ".github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/"
        "evidence/architecture-current.json",
        ("frontend_ii1",),
    ),
    (
        "v14a-di2",
        ".github/task-runs/2026-08-02-rv64-v14a-di2-current-rebind-v1/"
        "evidence/architecture-current.json",
        ("width_continuity",),
    ),
)

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


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def workspace_file(relative: str) -> pathlib.Path:
    path = (ROOT / relative).resolve(strict=True)
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError(f"invalid workspace file: {relative}")
    return path


def compare_hash_map(mapping: Any) -> dict[str, list[str]]:
    missing: list[str] = []
    mismatch: list[str] = []
    malformed: list[str] = []
    if not isinstance(mapping, dict):
        return {"missing": [], "mismatch": [], "malformed": ["<not-a-map>"]}
    for relative, expected in sorted(mapping.items()):
        if not isinstance(relative, str) or not isinstance(expected, str):
            malformed.append(str(relative))
            continue
        try:
            path = workspace_file(relative)
        except (OSError, ValueError):
            missing.append(relative)
            continue
        if digest(path) != expected:
            mismatch.append(relative)
    return {"missing": missing, "mismatch": mismatch, "malformed": malformed}


def compare_proof_files(mapping: Any) -> dict[str, list[str]]:
    normalized: dict[str, str] = {}
    malformed: list[str] = []
    if not isinstance(mapping, dict):
        return {"missing": [], "mismatch": [], "malformed": ["<not-a-map>"]}
    for role, item in sorted(mapping.items()):
        if (
            not isinstance(role, str)
            or not isinstance(item, dict)
            or not isinstance(item.get("path"), str)
            or not isinstance(item.get("sha256"), str)
        ):
            malformed.append(str(role))
            continue
        normalized[item["path"]] = item["sha256"]
    result = compare_hash_map(normalized)
    result["malformed"].extend(malformed)
    return result


def checker_run(
    manifest: pathlib.Path,
    output: pathlib.Path,
    log: pathlib.Path,
) -> tuple[int, dict[str, Any]]:
    command = (
        sys.executable,
        "-B",
        str(ARCH_TOOL),
        "--repo-root",
        str(ROOT),
        "--evidence-manifest",
        str(manifest),
        "--output",
        str(output),
    )
    completed = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    log.write_text(
        "[COMMAND] " + " ".join(command) + "\n"
        + completed.stdout
        + completed.stderr,
        encoding="utf-8",
    )
    if completed.returncode not in (0, 1):
        raise RuntimeError(
            f"architecture checker infrastructure rc={completed.returncode}: {manifest}"
        )
    payload = json.loads(output.read_text(encoding="utf-8"))
    if payload.get("exit_code") != completed.returncode:
        raise ValueError(f"checker process/result rc mismatch: {manifest}")
    if payload.get("rtl_source_set", {}).get("design_id") != EXPECTED_DESIGN_ID:
        raise ValueError(f"checker live RTL design-id drift: {manifest}")
    return completed.returncode, payload


def record_audit(record: dict[str, Any]) -> dict[str, Any]:
    provenance = record.get("provenance", {})
    source_manifest = record.get("source_manifest", {})
    log = record.get("log", {})
    log_map = (
        {log.get("path"): log.get("sha256")}
        if isinstance(log, dict) and isinstance(log.get("path"), str)
        else {}
    )
    return {
        "status": record.get("status"),
        "task_run_id": record.get("task_run_id"),
        "suite_run_id": record.get("suite_run_id"),
        "proof_mode": provenance.get("mode") if isinstance(provenance, dict) else None,
        "provenance_files": compare_hash_map(
            provenance.get("files", {}) if isinstance(provenance, dict) else {}
        ),
        "source_manifest_files": compare_hash_map(
            source_manifest.get("files", {})
            if isinstance(source_manifest, dict) else {}
        ),
        "proof_files": compare_proof_files(
            provenance.get("proof_files", {}) if isinstance(provenance, dict) else {}
        ),
        "artifacts": compare_hash_map(record.get("artifacts", {})),
        "gate_log": compare_hash_map(log_map),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True, type=pathlib.Path)
    args = parser.parse_args()
    output_dir = args.output_dir.resolve()
    expected_parent = (HERE / "evidence").resolve()
    if (
        output_dir.parent != expected_parent
        or not output_dir.name.startswith("audit-")
        or not output_dir.name[6:].isdigit()
    ):
        raise ValueError("output directory must be task-local evidence/audit-N")
    if output_dir.exists():
        raise ValueError("audit output directory already exists")
    output_dir.mkdir(parents=True)
    per_source_dir = output_dir / "per-source"
    per_source_dir.mkdir()

    combined_tests: dict[str, Any] = {}
    source_results: dict[str, Any] = {}
    input_manifests: dict[str, Any] = {}
    for label, relative, expected_tests in SOURCES:
        manifest = workspace_file(relative)
        payload = json.loads(manifest.read_text(encoding="utf-8"))
        if (
            payload.get("schema") != SCHEMA
            or payload.get("design_id") != EXPECTED_DESIGN_ID
            or set(payload.get("tests", {})) != set(expected_tests)
        ):
            raise ValueError(f"{label}: scoped manifest identity/inventory mismatch")
        for test_id in expected_tests:
            if test_id in combined_tests:
                raise ValueError(f"duplicate architecture record: {test_id}")
            combined_tests[test_id] = payload["tests"][test_id]

        checker_output = per_source_dir / f"{label}.result.json"
        checker_log = per_source_dir / f"{label}.checker.log"
        rc, checker = checker_run(manifest, checker_output, checker_log)
        target_gates = {TEST_TO_GATE[test_id] for test_id in expected_tests}
        source_results[label] = {
            "checker_rc": rc,
            "overall_status": checker["overall_status"],
            "green_gates": sorted(
                gate for gate, value in checker["gates"].items()
                if value["status"] == "GREEN"
            ),
            "target_gates": {
                gate: {
                    "status": checker["gates"][gate]["status"],
                    "red_checks": [
                        item["check_id"]
                        for item in checker["gates"][gate]["checks"]
                        if item["status"] == "RED"
                    ],
                }
                for gate in sorted(target_gates)
            },
            "records": {
                test_id: record_audit(payload["tests"][test_id])
                for test_id in expected_tests
            },
            "manifest": {
                "path": relative,
                "sha256": digest(manifest),
            },
            "checker_result": {
                "path": checker_output.relative_to(ROOT).as_posix(),
                "sha256": digest(checker_output),
            },
            "checker_log": {
                "path": checker_log.relative_to(ROOT).as_posix(),
                "sha256": digest(checker_log),
            },
        }
        input_manifests[label] = source_results[label]["manifest"]

    if set(combined_tests) != set(TEST_TO_GATE):
        raise ValueError("combined architecture record inventory is not exactly nine gates")

    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    combined_manifest = output_dir / "combined-candidate-manifest.json"
    combined_manifest.write_text(
        json.dumps(
            {
                "design_id": EXPECTED_DESIGN_ID,
                "generated_at_utc": generated_at,
                "schema": SCHEMA,
                "tests": combined_tests,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    combined_output = output_dir / "combined-current-result.json"
    combined_log = output_dir / "combined-current-checker.log"
    combined_rc, combined = checker_run(
        combined_manifest, combined_output, combined_log)
    red_checks = {
        gate: [
            item["check_id"]
            for item in value["checks"]
            if item["status"] == "RED"
        ]
        for gate, value in combined["gates"].items()
        if value["status"] == "RED"
    }
    canonical_before = {
        "path": CANONICAL_MANIFEST.relative_to(ROOT).as_posix(),
        "sha256": digest(CANONICAL_MANIFEST),
    }
    result = {
        "schema": "rv64-v14b-current-architecture-closure-audit-v1",
        "generated_at_utc": generated_at,
        "audit_status": "PASS",
        "closure_status": combined["overall_status"],
        "promotion_eligible": False,
        "current_design_id": EXPECTED_DESIGN_ID,
        "rtl_file_count": combined["rtl_source_set"]["file_count"],
        "input_manifests": input_manifests,
        "source_results": source_results,
        "combined": {
            "checker_rc": combined_rc,
            "overall_status": combined["overall_status"],
            "green_gates": sorted(
                gate for gate, value in combined["gates"].items()
                if value["status"] == "GREEN"
            ),
            "red_checks": red_checks,
            "manifest": {
                "path": combined_manifest.relative_to(ROOT).as_posix(),
                "sha256": digest(combined_manifest),
            },
            "result": {
                "path": combined_output.relative_to(ROOT).as_posix(),
                "sha256": digest(combined_output),
            },
            "log": {
                "path": combined_log.relative_to(ROOT).as_posix(),
                "sha256": digest(combined_log),
            },
        },
        "canonical_manifest_before": canonical_before,
        "canonical_manifest_written": False,
        "production_rtl_written": False,
        "next_action": (
            "ARCH_STABLE_FREEZE_AUDIT"
            if combined["overall_status"] == "GREEN"
            else "CLASSIFY_RED_CHECKS_AS_REPLAY_OR_RERUN"
        ),
    }
    result_path = output_dir / "closure-audit.json"
    result_path.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    if digest(CANONICAL_MANIFEST) != canonical_before["sha256"]:
        raise RuntimeError("canonical architecture manifest changed during audit")
    print(
        "[V14B-ARCH-AUDIT][PASS] "
        f"design_id={EXPECTED_DESIGN_ID} sources={len(SOURCES)} records=9 "
        f"combined={combined['overall_status']} green={len(result['combined']['green_gates'])} "
        f"red={len(red_checks)} next={result['next_action']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (
        OSError,
        RuntimeError,
        UnicodeDecodeError,
        ValueError,
        json.JSONDecodeError,
    ) as exc:
        print(f"[V14B-ARCH-AUDIT][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)

