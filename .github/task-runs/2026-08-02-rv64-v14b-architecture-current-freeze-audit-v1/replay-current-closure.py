#!/usr/bin/env python3
"""Versioned checker replay for current-design RV64 directed architecture records."""

from __future__ import annotations

import argparse
import copy
import datetime
import hashlib
import importlib.util
import json
import pathlib
import subprocess
import sys
from typing import Any


TASK_RUN_ID = "2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1"
HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ARCH_TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
POLICY_PATH = HERE / "semantic-delta-policy.json"
AUDIT_PATH = HERE / "evidence/audit-1/closure-audit.json"
CANDIDATE_PATH = HERE / "evidence/audit-1/combined-candidate-manifest.json"
CANONICAL_PATH = ROOT / "npc/rv64/eval/ppa/evidence/architecture-current.json"
EXPECTED_CANONICAL_SHA = (
    "a0bd58bf4ef9bdfa7724087af3dcef79a72cb8384d8e1e8131d20957897c1bc1"
)
EXPECTED_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
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
GATE_TO_TEST = {gate: test for test, gate in TEST_TO_GATE.items()}

ARCH_SPEC = importlib.util.spec_from_file_location("v14b_arch", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def read_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"JSON root is not an object: {path}")
    return value


def workspace_file(relative: str) -> pathlib.Path:
    path = (ROOT / relative).resolve(strict=True)
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError(f"invalid workspace file: {relative}")
    return path


def require_clean_drift(value: Any, expected_mismatch: set[str], label: str) -> None:
    if not isinstance(value, dict):
        raise ValueError(f"{label}: drift result is not an object")
    if set(value.get("mismatch", [])) != expected_mismatch:
        raise ValueError(f"{label}: mismatch inventory changed")
    if value.get("missing") or value.get("malformed"):
        raise ValueError(f"{label}: missing or malformed evidence path")


def validate_policy(policy: dict[str, Any]) -> None:
    if (
        policy.get("schema")
        != "rv64-v14b-architecture-replay-semantic-delta-policy-v1"
        or policy.get("classification") != "NON_DUT_EVIDENCE_PROVENANCE_ONLY"
        or policy.get("current_design_id") != EXPECTED_DESIGN_ID
    ):
        raise ValueError("semantic delta policy identity mismatch")
    for field in (
        "active_functional_cone_impact",
        "dut_input_impact",
        "dut_timing_impact",
        "dut_state_impact",
        "termination_impact",
        "randomization_impact",
    ):
        if policy.get(field) is not False:
            raise ValueError(f"semantic delta policy does not close {field}")
    expected_tests = set(TEST_TO_GATE)
    provenance = policy.get("expected_provenance_drift_by_test")
    sources = policy.get("expected_source_manifest_drift_by_test")
    allowed = policy.get("allowed_paths")
    if (
        not isinstance(provenance, dict)
        or set(provenance) != expected_tests
        or not isinstance(sources, dict)
        or set(sources) != expected_tests
        or not isinstance(allowed, dict)
    ):
        raise ValueError("semantic delta policy inventory mismatch")
    referenced = {
        path for paths in provenance.values() for path in paths
    } | {path for paths in sources.values() for path in paths}
    if referenced != set(allowed):
        raise ValueError("semantic delta allowlist has unused or missing paths")
    for relative, item in allowed.items():
        if (
            relative.startswith("npc/rv64/vsrc/")
            or relative.startswith("npc/rv64/testbench/")
            or relative.endswith((".v", ".sv", ".vh"))
        ):
            raise ValueError(f"production RTL/TB path cannot be replay-rebound: {relative}")
        if (
            not isinstance(item, dict)
            or not arch.is_sha256(item.get("sha256"))
            or not item.get("role")
            or not item.get("justification")
            or digest(workspace_file(relative)) != item["sha256"]
        ):
            raise ValueError(f"semantic delta path binding is stale: {relative}")
    boundary = policy.get("replay_boundary", {})
    for field in (
        "frozen_execution_artifacts_modified",
        "source_task_run_manifests_modified",
        "canonical_manifest_modified",
        "production_rtl_modified",
        "proof_files_rebound",
        "gate_logs_rebound",
    ):
        if boundary.get(field) is not False:
            raise ValueError(f"replay boundary is not immutable: {field}")


def validate_audit(audit: dict[str, Any], policy: dict[str, Any]) -> None:
    if (
        audit.get("schema") != "rv64-v14b-current-architecture-closure-audit-v1"
        or audit.get("audit_status") != "PASS"
        or audit.get("closure_status") != "RED"
        or audit.get("current_design_id") != EXPECTED_DESIGN_ID
        or audit.get("canonical_manifest_written") is not False
        or audit.get("production_rtl_written") is not False
        or audit.get("combined", {}).get("green_gates") != ["DI-2"]
    ):
        raise ValueError("source audit identity or expected state mismatch")
    expected_red = {
        gate: [
            f"evidence.{test}.provenance_files",
            f"evidence.{test}.provenance_digest",
        ]
        for gate, test in GATE_TO_TEST.items()
        if gate != "DI-2"
    }
    if audit.get("combined", {}).get("red_checks") != expected_red:
        raise ValueError("combined candidate has a RED cause beyond provenance drift")

    record_count = 0
    for source in audit.get("source_results", {}).values():
        for test_id, record in source.get("records", {}).items():
            record_count += 1
            expected_provenance = set(
                policy["expected_provenance_drift_by_test"][test_id])
            expected_sources = set(
                policy["expected_source_manifest_drift_by_test"][test_id])
            require_clean_drift(
                record.get("provenance_files"), expected_provenance,
                f"{test_id}.provenance")
            require_clean_drift(
                record.get("source_manifest_files"), expected_sources,
                f"{test_id}.source_manifest")
            for field in ("proof_files", "artifacts", "gate_log"):
                require_clean_drift(record.get(field), set(), f"{test_id}.{field}")
    if record_count != 9:
        raise ValueError("source audit does not contain exactly nine records")


def checker_run(
    manifest: pathlib.Path, output: pathlib.Path, log: pathlib.Path,
) -> tuple[int, dict[str, Any]]:
    command = (
        sys.executable, "-B", str(ARCH_TOOL),
        "--repo-root", str(ROOT),
        "--evidence-manifest", str(manifest),
        "--output", str(output),
    )
    completed = subprocess.run(
        command, cwd=ROOT, text=True, capture_output=True, check=False)
    log.write_text(
        "[COMMAND] " + " ".join(command) + "\n"
        + completed.stdout + completed.stderr,
        encoding="utf-8",
    )
    if completed.returncode not in (0, 1):
        raise RuntimeError(f"checker infrastructure rc={completed.returncode}")
    result = read_json(output)
    if result.get("exit_code") != completed.returncode:
        raise ValueError("checker result/process rc mismatch")
    return completed.returncode, result


def old_record_by_test(audit: dict[str, Any]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for source in audit["source_results"].values():
        manifest_info = source["manifest"]
        path = workspace_file(manifest_info["path"])
        if digest(path) != manifest_info["sha256"]:
            raise ValueError(f"source task-run manifest changed: {path}")
        payload = read_json(path)
        for test_id, record in payload["tests"].items():
            if test_id in result:
                raise ValueError(f"duplicate source record: {test_id}")
            result[test_id] = record
    if set(result) != set(TEST_TO_GATE):
        raise ValueError("source record set is not exactly nine gates")
    return result


def rebind_record(
    test_id: str,
    record: dict[str, Any],
    original: dict[str, Any],
    policy: dict[str, Any],
    policy_sha: str,
    audit_sha: str,
) -> dict[str, Any]:
    value = copy.deepcopy(record)
    provenance = value.get("provenance")
    if not isinstance(provenance, dict) or not isinstance(
        provenance.get("files"), dict
    ):
        raise ValueError(f"{test_id}: provenance file map is absent")
    provenance_paths = policy["expected_provenance_drift_by_test"][test_id]
    for relative in provenance_paths:
        if relative not in provenance["files"]:
            raise ValueError(f"{test_id}: replay path absent from provenance: {relative}")
        provenance["files"][relative] = digest(workspace_file(relative))
    provenance["sha256"] = arch.canonical_digest(provenance["files"])

    source_paths = policy["expected_source_manifest_drift_by_test"][test_id]
    if source_paths:
        source_manifest = value.get("source_manifest")
        if not isinstance(source_manifest, dict) or not isinstance(
            source_manifest.get("files"), dict
        ):
            raise ValueError(f"{test_id}: source manifest is absent")
        for relative in source_paths:
            if relative not in source_manifest["files"]:
                raise ValueError(
                    f"{test_id}: replay path absent from source manifest: {relative}")
            source_manifest["files"][relative] = digest(workspace_file(relative))
        source_manifest["sha256"] = arch.canonical_digest(source_manifest["files"])

    value["versioned_replay"] = {
        "schema": "rv64-v14b-directed-record-replay-v1",
        "classification": "NON_DUT_EVIDENCE_PROVENANCE_ONLY",
        "source_record_sha256": arch.canonical_digest(original),
        "policy_sha256": policy_sha,
        "audit_sha256": audit_sha,
        "current_checker_sha256": digest(ARCH_TOOL),
        "provenance_rebound_paths": provenance_paths,
        "source_manifest_rebound_paths": source_paths,
        "frozen_proof_files_modified": False,
        "frozen_gate_log_modified": False,
        "dut_rerun": False,
        "scope": "current checker interpretation of frozen same-design directed evidence",
    }
    return value


def write_json(path: pathlib.Path, value: Any) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def negative_case(
    name: str,
    manifest_payload: dict[str, Any],
    output_dir: pathlib.Path,
    expected_gate: str,
    expected_check: str,
) -> dict[str, Any]:
    manifest = output_dir / f"{name}.manifest.json"
    output = output_dir / f"{name}.result.json"
    log = output_dir / f"{name}.checker.log"
    write_json(manifest, manifest_payload)
    rc, result = checker_run(manifest, output, log)
    red_checks = [
        item["check_id"] for item in result["gates"][expected_gate]["checks"]
        if item["status"] == "RED"
    ]
    if rc != 1 or result["gates"][expected_gate]["status"] != "RED":
        raise ValueError(f"negative case {name} did not fail closed")
    if expected_check not in red_checks:
        raise ValueError(f"negative case {name} missed witness {expected_check}")
    return {
        "name": name,
        "checker_rc": rc,
        "expected_gate": expected_gate,
        "expected_check": expected_check,
        "red_checks": red_checks,
        "manifest_sha256": digest(manifest),
        "result_sha256": digest(output),
        "log_sha256": digest(log),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True, type=pathlib.Path)
    args = parser.parse_args()
    output_dir = args.output_dir.resolve()
    expected_parent = (HERE / "evidence").resolve()
    if (
        output_dir.parent != expected_parent
        or not output_dir.name.startswith("replay-")
        or not output_dir.name[7:].isdigit()
    ):
        raise ValueError("output directory must be task-local evidence/replay-N")
    if output_dir.exists():
        raise ValueError("replay output directory already exists")
    output_dir.mkdir(parents=True)
    negative_dir = output_dir / "negative"
    negative_dir.mkdir()

    policy = read_json(POLICY_PATH)
    audit = read_json(AUDIT_PATH)
    validate_policy(policy)
    validate_audit(audit, policy)
    if digest(CANONICAL_PATH) != EXPECTED_CANONICAL_SHA:
        raise ValueError("canonical architecture manifest drifted before replay")
    policy_sha = digest(POLICY_PATH)
    audit_sha = digest(AUDIT_PATH)
    original_records = old_record_by_test(audit)
    candidate = read_json(CANDIDATE_PATH)
    if (
        candidate.get("design_id") != EXPECTED_DESIGN_ID
        or set(candidate.get("tests", {})) != set(TEST_TO_GATE)
    ):
        raise ValueError("audit candidate manifest identity mismatch")

    replay_tests = {
        test_id: rebind_record(
            test_id,
            candidate["tests"][test_id],
            original_records[test_id],
            policy,
            policy_sha,
            audit_sha,
        )
        for test_id in sorted(TEST_TO_GATE)
    }
    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    replay_manifest_payload = {
        "design_id": EXPECTED_DESIGN_ID,
        "generated_at_utc": generated_at,
        "schema": "npc-rv64-architecture-directed-suite-v2",
        "tests": replay_tests,
    }
    replay_manifest = output_dir / "current-directed-nine-gate-replay.json"
    replay_result = output_dir / "current-directed-nine-gate-result.json"
    replay_log = output_dir / "current-directed-nine-gate-checker.log"
    write_json(replay_manifest, replay_manifest_payload)
    replay_rc, result = checker_run(replay_manifest, replay_result, replay_log)
    green = sorted(
        gate for gate, value in result["gates"].items()
        if value["status"] == "GREEN")
    if (
        replay_rc != 0
        or result.get("overall_status") != "GREEN"
        or green != sorted(GATE_TO_TEST)
    ):
        raise ValueError(
            f"current directed nine-gate replay remained RED: green={green}")

    negative_cases: list[dict[str, Any]] = []
    dropped = copy.deepcopy(replay_manifest_payload)
    del dropped["tests"]["selective_scheduling"]
    negative_cases.append(negative_case(
        "drop-ooo2-record", dropped, negative_dir, "OOO-2",
        "evidence.selective_scheduling.record"))

    proof_drift = copy.deepcopy(replay_manifest_payload)
    proof_files = proof_drift["tests"]["true_ooo_long_latency"][
        "provenance"]["proof_files"]
    first_role = sorted(proof_files)[0]
    proof_files[first_role]["sha256"] = "0" * 64
    negative_cases.append(negative_case(
        "ooo1-proof-hash-drift", proof_drift, negative_dir, "OOO-1",
        "evidence.true_ooo_long_latency.proof_files"))

    source_rollback = copy.deepcopy(replay_manifest_payload)
    old_arch_sha = original_records["frontend_ii1"]["provenance"]["files"][
        "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"]
    source_rollback["tests"]["frontend_ii1"]["provenance"]["files"][
        "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"] = old_arch_sha
    negative_cases.append(negative_case(
        "di1-provenance-rollback", source_rollback, negative_dir, "DI-1",
        "evidence.frontend_ii1.provenance_files"))

    design_drift = copy.deepcopy(replay_manifest_payload)
    design_drift["design_id"] = "sha256:" + "0" * 64
    negative_cases.append(negative_case(
        "aggregate-design-id-drift", design_drift, negative_dir, "DI-1",
        "evidence.design_binding"))

    negative_summary = {
        "schema": "rv64-v14b-directed-replay-negative-fixtures-v1",
        "status": "PASS",
        "required": 4,
        "detected": len(negative_cases),
        "cases": negative_cases,
    }
    negative_summary_path = negative_dir / "summary.json"
    write_json(negative_summary_path, negative_summary)

    source_manifest_post = {
        label: digest(workspace_file(item["path"]))
        for label, item in audit["input_manifests"].items()
    }
    source_manifest_expected = {
        label: item["sha256"]
        for label, item in audit["input_manifests"].items()
    }
    if source_manifest_post != source_manifest_expected:
        raise RuntimeError("source task-run manifest changed during replay")
    receipt = {
        "schema": "rv64-v14b-current-directed-nine-gate-replay-v1",
        "generated_at_utc": generated_at,
        "status": "PASS",
        "classification": "NON_DUT_EVIDENCE_PROVENANCE_ONLY",
        "production_core_rtl_id": EXPECTED_DESIGN_ID,
        "rtl_file_count": result["rtl_source_set"]["file_count"],
        "execution_evidence_reused": True,
        "dut_rerun": False,
        "checker_replay": True,
        "directed_nine_gate_status": "GREEN",
        "full_section_13_architecture_gate_state": "PENDING_AUDIT",
        "arch_stable": False,
        "promotion_eligible": False,
        "full_system_rerun_required": False,
        "launch_authorization_state": "NOT_REQUIRED",
        "policy": {
            "path": POLICY_PATH.relative_to(ROOT).as_posix(),
            "sha256": policy_sha,
        },
        "source_audit": {
            "path": AUDIT_PATH.relative_to(ROOT).as_posix(),
            "sha256": audit_sha,
        },
        "current_checker": {
            "path": ARCH_TOOL.relative_to(ROOT).as_posix(),
            "sha256": digest(ARCH_TOOL),
        },
        "replay_manifest": {
            "path": replay_manifest.relative_to(ROOT).as_posix(),
            "sha256": digest(replay_manifest),
        },
        "replay_result": {
            "path": replay_result.relative_to(ROOT).as_posix(),
            "sha256": digest(replay_result),
        },
        "replay_log": {
            "path": replay_log.relative_to(ROOT).as_posix(),
            "sha256": digest(replay_log),
        },
        "negative_fixtures": {
            "path": negative_summary_path.relative_to(ROOT).as_posix(),
            "sha256": digest(negative_summary_path),
            "detected": 4,
            "required": 4,
        },
        "source_task_run_manifests_unchanged": True,
        "canonical_manifest": {
            "path": CANONICAL_PATH.relative_to(ROOT).as_posix(),
            "sha256_before": EXPECTED_CANONICAL_SHA,
            "sha256_after": digest(CANONICAL_PATH),
            "written": False,
        },
        "proof_scope": [
            "current checker accepts all nine frozen same-design directed records",
            "only declared non-DUT provenance paths were rebound",
            "source task-run manifests, proof files and gate logs remain byte-identical",
            "missing record, proof hash drift, provenance rollback and design-id drift fail closed"
        ],
        "unproven_scope": [
            "Section 13.1 full architecture gate prerequisites",
            "Section 13.3 arch-stable identity freeze",
            "workload CPI and performance baseline",
            "synthesis, STA, power and area qualification",
            "full-system recertification"
        ],
        "next_action": "AUDIT_SECTION_13_AND_ARCH_STABLE_FREEZE_INVENTORY",
    }
    receipt_path = output_dir / "replay-receipt.json"
    write_json(receipt_path, receipt)
    if digest(CANONICAL_PATH) != EXPECTED_CANONICAL_SHA:
        raise RuntimeError("canonical architecture manifest changed during replay")
    print(
        "[V14B-ARCH-REPLAY][PASS] "
        f"design_id={EXPECTED_DESIGN_ID} directed_gates=9/9 negative=4/4 "
        "dut_rerun=0 canonical_write=0 arch_stable=0 next=SECTION13_AUDIT"
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
        print(f"[V14B-ARCH-REPLAY][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)

