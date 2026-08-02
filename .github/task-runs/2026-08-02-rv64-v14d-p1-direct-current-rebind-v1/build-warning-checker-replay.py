#!/usr/bin/env python3
"""Replay the current CONTROL-EVENT positive-log warning classifier."""

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
V9O_LEGACY = (
    ROOT
    / ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
    / "build-evidence-index.py"
)
V9R_HELPER = ROOT / "npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load module: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def artifact(path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(ROOT) or not resolved.is_file():
        raise ValueError(f"invalid warning replay artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--v9o-evidence", required=True, type=pathlib.Path)
    parser.add_argument("--v9r-evidence", required=True, type=pathlib.Path)
    parser.add_argument("--attempt-status", required=True, type=pathlib.Path)
    parser.add_argument("--attempt-summary-log", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()

    evidence_root = HERE / "evidence"
    v9o_evidence = args.v9o_evidence.resolve(strict=True)
    v9r_evidence = args.v9r_evidence.resolve(strict=True)
    attempt_status = args.attempt_status.resolve(strict=True)
    attempt_summary_log = args.attempt_summary_log.resolve(strict=True)
    output = args.output.resolve()
    for path in (v9o_evidence, v9r_evidence, attempt_summary_log, output):
        if not path.is_relative_to(evidence_root):
            raise ValueError("warning replay path escaped V14D evidence")
    if attempt_status != HERE / "control-run-2.status":
        raise ValueError("warning replay status input is not control-run-2.status")
    if output.exists():
        raise ValueError("refusing to replace warning checker replay")
    output.parent.mkdir(parents=True, exist_ok=True)

    legacy = load_module(V9O_LEGACY, "v14d_warning_replay_v9o")
    helper = load_module(V9R_HELPER, "v14d_warning_replay_v9r")
    logs: list[pathlib.Path] = []
    for group, marker_map in (
        ("v9o-focused", legacy.FOCUSED_MARKERS),
        ("v9o-config", legacy.CONFIG_MARKERS),
    ):
        for test_name in marker_map:
            logs.append(v9o_evidence / f"{group}/logs/{test_name}.log")
    for test_name in helper.BASELINE_TESTS:
        logs.append(v9r_evidence / f"v9r-baseline/logs/{test_name}.log")
    if len(logs) != 16 or any(not path.is_file() for path in logs):
        raise ValueError("CONTROL-EVENT positive warning-log inventory drift")

    sys.path.insert(0, str(HERE))
    import warning_audit

    audit_result = warning_audit.audit(logs)
    if not (
        audit_result.get("status") == "EXPLAINED"
        and audit_result.get("unexplained_warning_count") == 0
        and audit_result.get("assertion_failure_observed") is False
        and audit_result.get("classification")
        == "CURRENT_SOURCE_BOUND_ICARUS_DIAGNOSTICS"
    ):
        raise ValueError("CONTROL-EVENT warning audit result drift")

    known_array_line = (
        "/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v:304: "
        "warning: @* is sensitive to all 4 words in array 'valid_q'."
    )
    if warning_audit.classify_warning_line(known_array_line) is None:
        raise ValueError("known current RTL array warning was rejected")
    if warning_audit.classify_warning_line("warning: fabricated diagnostic") is not None:
        raise ValueError("unknown warning negative fixture escaped")
    bad_array_line = (
        "/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v:1: "
        "warning: @* is sensitive to all 4 words in array 'fabricated_q'."
    )
    if warning_audit.classify_warning_line(bad_array_line) is not None:
        raise ValueError("source-line-unbound array warning escaped")
    bad_port = next(iter(warning_audit.DANGLING_PORTS)).replace("port 22", "port 92")
    if warning_audit.classify_warning_line(bad_port) is not None:
        raise ValueError("unknown dangling-port warning escaped")
    malformed_timeunit = [
        warning_audit.TIMEUNIT_HEADER,
        warning_audit.TIMEUNIT_PRECISION,
        warning_audit.TIMEUNIT_AFFECTED,
        "       :   -- module Fabricated declared here: /tmp/Fabricated.v:1",
    ]
    if warning_audit.validate_timeunit_block(malformed_timeunit, 0):
        raise ValueError("malformed timeunit warning escaped")

    status_text = attempt_status.read_text(encoding="utf-8").strip()
    summary_text = attempt_summary_log.read_text(encoding="utf-8").strip()
    if status_text != "FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0":
        raise ValueError("control-run-2 historical FAIL status drift")
    if not summary_text.startswith(
        "[V14D-CONTROL-EVENT][FAIL] unexplained current RTL compile warning:"
    ):
        raise ValueError("control-run-2 warning-classifier failure marker drift")

    result = {
        "schema": "rv64-v14d-control-warning-checker-replay-v1",
        "status": "PASS",
        "debt_id": "CONTROL-EVENT-G1",
        "raw_attempt": {
            "status": status_text,
            "status_artifact": artifact(attempt_status),
            "summary_log": artifact(attempt_summary_log),
            "historical_status_rewritten": False,
        },
        "warning_audit": audit_result,
        "positive_logs": [artifact(path) for path in logs],
        "checker": artifact(HERE / "warning_audit.py"),
        "checker_self_test": {
            "accept_current_source_bound_array_warning": "PASS",
            "reject_unknown_warning": "PASS",
            "reject_source_line_unbound_array_warning": "PASS",
            "reject_unknown_dangling_port": "PASS",
            "reject_malformed_timeunit_block": "PASS",
        },
        "assertion_weakened": False,
        "canonical_evidence_rewritten": False,
    }
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14D-WARNING-REPLAY][PASS] positive_logs=16 unexplained=0 "
        "negative_fixtures=4/4 historical_fail=preserved"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-WARNING-REPLAY][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
