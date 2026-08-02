#!/usr/bin/env python3
"""Replay V13R STORE-B mutation detection with exact assertion-fatal sites."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
RUNNER_PATH = HERE / "run-v13r-store-mutations.py"
CURRENT_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load module: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def load(path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"JSON root is not an object: {path}")
    return payload


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def artifact(path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(ROOT) or not resolved.is_file():
        raise ValueError(f"invalid V13R replay artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def detection_contract(spec: Any, text: str) -> bool:
    lines = text.splitlines()
    markers = [line for line in lines if line.startswith(spec.expected_marker)]
    fatals = [line for line in lines if line.startswith("FATAL: ")]
    results = [line for line in lines if line.startswith("[RESULT] ")]
    failures = [line for line in lines if line.startswith("[FAIL] ")]
    assertion_contract = (
        spec.expected_assertion_prefix is None
        or sum(line.startswith(spec.expected_assertion_prefix) for line in lines) == 1
    )
    fail_contract = (
        len(failures) == 0
        if spec.expected_fail_prefix is None
        else len(failures) == 1
        and failures[0].startswith(spec.expected_fail_prefix)
    )
    return (
        sum(line.startswith("[COMPILE] ") for line in lines) == 1
        and len(markers) == 1
        and fatals == [spec.expected_fatal]
        and assertion_contract
        and fail_contract
        and results == ["[RESULT] FAIL status=1"]
        and "[RESULT] PASS" not in text
        and "[TIMEOUT]" not in text
        and text.count(f"[RTL-DESIGN-ID] {CURRENT_DESIGN_ID}") == 1
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-summary", required=True, type=pathlib.Path)
    parser.add_argument("--source-snapshot", required=True, type=pathlib.Path)
    parser.add_argument("--attempt-status", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence_root = HERE / "evidence"
    raw_summary_path = args.raw_summary.resolve(strict=True)
    snapshot_path = args.source_snapshot.resolve(strict=True)
    attempt_status_path = args.attempt_status.resolve(strict=True)
    output = args.output.resolve()
    for path in (raw_summary_path, snapshot_path, output):
        if not path.is_relative_to(evidence_root):
            raise ValueError("V13R replay path escaped V14D evidence")
    if attempt_status_path != HERE / "store-run-1.status":
        raise ValueError("V13R replay status input is not store-run-1.status")
    if output.exists():
        raise ValueError("refusing to replace V13R mutation checker replay")
    output.parent.mkdir(parents=True, exist_ok=True)

    runner = load_module(RUNNER_PATH, "v14d_v13r_replay_runner")
    summary = load(raw_summary_path)
    snapshot = load(snapshot_path)
    specs = {spec.name: spec for spec in runner.MUTATIONS}
    rows = summary.get("results", [])
    by_name = {row.get("name"): row for row in rows if isinstance(row, dict)}
    source_names = sorted({spec.source_rel for spec in specs.values()})
    live = {name: digest(ROOT / name) for name in source_names}
    if not (
        summary.get("schema") == runner.SCHEMA
        and summary.get("current_design_id") == CURRENT_DESIGN_ID
        and summary.get("required") == len(specs) == 3
        and summary.get("compile_success") == 3
        and summary.get("dynamic_rejected") == 0
        and summary.get("source_unchanged") is True
        and summary.get("source_sha256_before") == live
        and summary.get("source_sha256_after") == live
        and set(by_name) == set(specs)
        and snapshot.get("design_id") == CURRENT_DESIGN_ID
        and snapshot.get("file_count") == 146
    ):
        raise ValueError("V13R raw mutation evidence or source binding drift")

    validated: list[dict[str, Any]] = []
    texts: dict[str, str] = {}
    for name, spec in specs.items():
        row = by_name[name]
        original, mutated = runner.reconstruct_mutation(ROOT, spec)
        original_sha = hashlib.sha256(original.encode("utf-8")).hexdigest()
        variant_sha = hashlib.sha256(mutated.encode("utf-8")).hexdigest()
        log_record = row.get("log", {})
        log_path = ROOT / str(log_record.get("path", ""))
        text = log_path.read_text(encoding="utf-8")
        texts[name] = text
        check_fail_count = sum(
            line.startswith("[CHECK-FAIL] ") for line in text.splitlines()
        )
        if not (
            row.get("source") == spec.source_rel
            and row.get("test_name") == spec.test_name
            and row.get("original_sha256") == original_sha == live[spec.source_rel]
            and row.get("variant_sha256") == variant_sha
            and row.get("expected_marker") == spec.expected_marker
            and row.get("marker_observed") is True
            and row.get("compile_success") is True
            and row.get("dynamic_rejected") is False
            and row.get("make_returncode") == 2
            and row.get("check_fail_count") == check_fail_count
            and log_path.is_file()
            and digest(log_path) == log_record.get("sha256")
            and detection_contract(spec, text)
        ):
            raise ValueError(f"V13R mutation replay contract drift: {name}")
        validated.append(
            {
                "name": name,
                "source": spec.source_rel,
                "test_name": spec.test_name,
                "variant_sha256": variant_sha,
                "expected_fatal": spec.expected_fatal,
                "check_fail_count": check_fail_count,
                "compile_success": True,
                "dynamic_rejected": True,
                "log": artifact(log_path),
            }
        )

    first_spec = specs["s-resp-auto-drop"]
    first_text = texts[first_spec.name]
    if detection_contract(
        first_spec, first_text.replace(first_spec.expected_marker, "[MISSING]", 1)
    ):
        raise ValueError("missing-marker negative fixture escaped")
    if detection_contract(
        first_spec,
        first_text.replace("[RESULT] FAIL status=1", "[RESULT] PASS", 1),
    ):
        raise ValueError("PASS-result negative fixture escaped")
    if detection_contract(
        first_spec, first_text.replace(first_spec.expected_fatal, "FATAL: wrong-site: ", 1)
    ):
        raise ValueError("wrong-fatal-site negative fixture escaped")

    status_text = attempt_status_path.read_text(encoding="utf-8").strip()
    if status_text != "FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0":
        raise ValueError("store-run-1 historical FAIL status drift")
    result = {
        "schema": "rv64-v14d-v13r-mutation-checker-replay-v1",
        "status": "PASS",
        "debt_id": "STORE-BRESP-G1",
        "current_design_id": CURRENT_DESIGN_ID,
        "raw_attempt": {
            "status": status_text,
            "status_artifact": artifact(attempt_status_path),
            "summary": artifact(raw_summary_path),
            "historical_status_rewritten": False,
            "checker_defect": "blanket rejection of expected assertion/testbench FATAL",
        },
        "mutations": {
            "required": 3,
            "compile_success": 3,
            "dynamic_rejected": 3,
            "rows": validated,
        },
        "source_binding": artifact(snapshot_path),
        "checker_self_test": {
            "reject_missing_expected_marker": "PASS",
            "reject_result_pass": "PASS",
            "reject_wrong_fatal_site": "PASS",
        },
        "assertion_weakened": False,
        "canonical_evidence_rewritten": False,
    }
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14D-V13R-MUTATION-REPLAY][PASS] compile_success=3/3 "
        "dynamic_rejected=3/3 negative_fixtures=3/3 historical_fail=preserved"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-V13R-MUTATION-REPLAY][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
