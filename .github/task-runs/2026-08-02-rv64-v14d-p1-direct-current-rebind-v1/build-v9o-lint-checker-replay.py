#!/usr/bin/env python3
"""Replay the V9O cycle-free pregrant lint oracle at the current RTL locus."""

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
CURRENT_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)
RUNNER_PATH = (
    ROOT
    / ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
    / "run-control-event-rtl-mutations.py"
)
MUTATION_NAME = "pregrant_reads_current_completion_ready"
LQ_SOURCE = "npc/rv64/vsrc/memory/OooLoadQueue.v"
ROB_SOURCE = "npc/rv64/vsrc/writeback/OooRob.v"
LQ_SHA256 = "5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f"
ROB_SHA256 = "bbb68a2a819bb8bfb005adfb8f2659e8037ea6280d9dc338415395aeab62c561"
MUTATION_SHA256 = "0f627107f81c978a46a141572f8b58919650afdf0903757783a1ceccb101c150"
EXPECTED_UNOPTFLAT = (
    "%Warning-UNOPTFLAT: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/"
    "OooLoadQueue.v:244:57: Signal unoptimizable: Circular combinational logic: "
    "'NpcCoreTop.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend."
    "u_int_backend.u_load_queue.__VdfgTmp_h5e370351__0'",
    "%Warning-UNOPTFLAT: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/"
    "OooLoadQueue.v:246:57: Signal unoptimizable: Circular combinational logic: "
    "'NpcCoreTop.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend."
    "u_int_backend.u_load_queue.__VdfgTmp_h92f2d77a__0'",
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
        raise ValueError(f"invalid V9O checker artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def unoptflat_lines(text: str) -> tuple[str, ...]:
    return tuple(
        line for line in text.splitlines() if line.startswith("%Warning-UNOPTFLAT:")
    )


def validate_current_locus(baseline_text: str, mutation_text: str) -> None:
    baseline_lines = unoptflat_lines(baseline_text)
    mutation_lines = unoptflat_lines(mutation_text)
    if baseline_lines:
        raise ValueError("baseline full-cone lint contains UNOPTFLAT")
    if mutation_lines != EXPECTED_UNOPTFLAT:
        raise ValueError("current LQ UNOPTFLAT locus is not the exact two-line set")


def expect_rejected(baseline_text: str, mutation_text: str, label: str) -> None:
    try:
        validate_current_locus(baseline_text, mutation_text)
    except ValueError:
        return
    raise ValueError(f"negative checker fixture escaped: {label}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-summary", required=True, type=pathlib.Path)
    parser.add_argument("--source-snapshot", required=True, type=pathlib.Path)
    parser.add_argument("--attempt-status", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()

    raw_summary_path = args.raw_summary.resolve(strict=True)
    snapshot_path = args.source_snapshot.resolve(strict=True)
    attempt_status_path = args.attempt_status.resolve(strict=True)
    output = args.output.resolve()
    evidence_root = HERE / "evidence"
    for path in (raw_summary_path, snapshot_path, output):
        if not path.is_relative_to(evidence_root):
            raise ValueError("V9O replay path escaped V14D evidence")
    if attempt_status_path != HERE / "control-run-1.status":
        raise ValueError("V9O replay status input is not control-run-1.status")
    if output.exists():
        raise ValueError("refusing to replace V9O checker replay")
    output.parent.mkdir(parents=True, exist_ok=True)

    runner = load_module(RUNNER_PATH, "v14d_v9o_replay_runner")
    summary = load(raw_summary_path)
    snapshot = load(snapshot_path)
    files = snapshot.get("files", {})
    if not (
        summary.get("schema") == runner.SCHEMA
        and summary.get("required") == len(runner.MUTATIONS) == 11
        and summary.get("compile_success") == 11
        and summary.get("dynamic_rejected") == 10
        and summary.get("lint_rejected") == 0
        and summary.get("rejected") == 10
        and summary.get("baseline_unoptflat") is False
        and summary.get("design_id") == CURRENT_DESIGN_ID
        and summary.get("source_unchanged") is True
        and summary.get("full_rtl_source_unchanged") is True
        and summary.get("verification_source_unchanged") is True
        and summary.get("rtl_source_set", {}).get("files") == files
        and snapshot.get("design_id") == CURRENT_DESIGN_ID
        and snapshot.get("file_count") == 146
        and files.get(LQ_SOURCE) == LQ_SHA256
        and files.get(ROB_SOURCE) == ROB_SHA256
        and digest(ROOT / LQ_SOURCE) == LQ_SHA256
        and digest(ROOT / ROB_SOURCE) == ROB_SHA256
    ):
        raise ValueError("V9O raw evidence or current source binding drift")

    rows = summary.get("results", [])
    by_name = {row.get("name"): row for row in rows if isinstance(row, dict)}
    specs = {spec.name: spec for spec in runner.MUTATIONS}
    if set(by_name) != set(specs):
        raise ValueError("V9O raw mutation inventory drift")
    row = by_name[MUTATION_NAME]
    spec = specs[MUTATION_NAME]
    original, mutated = runner.reconstruct_mutation(ROOT, spec)
    original_sha = hashlib.sha256(original.encode("utf-8")).hexdigest()
    mutation_sha = hashlib.sha256(mutated.encode("utf-8")).hexdigest()
    if not (
        spec.rejection_mode == "lint-unoptflat"
        and spec.source_rel == ROB_SOURCE
        and row.get("source") == ROB_SOURCE
        and row.get("test_name") == spec.test_name == "tb_ooo_rob"
        and row.get("original_sha256") == original_sha == ROB_SHA256
        and row.get("mutation_sha256") == mutation_sha == MUTATION_SHA256
        and row.get("compile_success") is True
        and row.get("make_returncode") == 0
        and row.get("lint_returncode") == 0
        and row.get("dynamic_rejected") is False
        and row.get("lint_rejected") is False
        and row.get("rejected") is False
        and row.get("observed_markers")
        == {marker: False for marker in spec.expected_markers}
    ):
        raise ValueError("V9O stale-locus raw row drift")

    baseline_record = summary.get("baseline_lint", {})
    baseline_path = ROOT / str(baseline_record.get("path", ""))
    mutation_record = row.get("log", {})
    mutation_path = ROOT / str(mutation_record.get("path", ""))
    if not (
        baseline_record.get("returncode") == 0
        and baseline_path.is_file()
        and digest(baseline_path) == baseline_record.get("sha256")
        and mutation_path.is_file()
        and digest(mutation_path) == mutation_record.get("sha256")
    ):
        raise ValueError("V9O baseline or mutation log hash drift")
    baseline_text = baseline_path.read_text(encoding="utf-8")
    mutation_text = mutation_path.read_text(encoding="utf-8")
    if mutation_text.count("[RESULT] PASS") != 1 or "[RESULT] FAIL" in mutation_text:
        raise ValueError("V9O lint mutation did not retain a passing dynamic test")

    validate_current_locus(baseline_text, mutation_text)
    expected_text = "\n".join(EXPECTED_UNOPTFLAT) + "\n"
    expect_rejected(
        EXPECTED_UNOPTFLAT[0] + "\n" + baseline_text,
        mutation_text,
        "baseline-unoptflat",
    )
    expect_rejected(baseline_text, EXPECTED_UNOPTFLAT[0] + "\n", "missing-lq-line")
    expect_rejected(
        baseline_text,
        expected_text + "%Warning-UNOPTFLAT: unexpected-extra-locus\n",
        "extra-unoptflat",
    )

    status_text = attempt_status_path.read_text(encoding="utf-8").strip()
    if status_text != "FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0":
        raise ValueError("control-run-1 historical FAIL status drift")

    result = {
        "schema": "rv64-v14d-v9o-lint-checker-replay-v1",
        "status": "PASS",
        "debt_id": "CONTROL-EVENT-G1",
        "current_design_id": CURRENT_DESIGN_ID,
        "raw_attempt": {
            "status": status_text,
            "status_artifact": artifact(attempt_status_path),
            "summary": artifact(raw_summary_path),
            "historical_status_rewritten": False,
        },
        "mutation": {
            "name": MUTATION_NAME,
            "source": ROB_SOURCE,
            "test_name": spec.test_name,
            "original_sha256": original_sha,
            "variant_sha256": mutation_sha,
            "compile_success": True,
            "dynamic_test_passed": True,
            "rejection_mode": "lint-unoptflat-current-lq-locus",
            "log": artifact(mutation_path),
        },
        "baseline_full_cone_lint": {
            "unoptflat_count": 0,
            "log": artifact(baseline_path),
        },
        "current_lq_locus": {
            "required_count": 2,
            "observed_count": 2,
            "exact_lines": list(EXPECTED_UNOPTFLAT),
            "no_additional_unoptflat": True,
        },
        "source_binding": {
            "snapshot": artifact(snapshot_path),
            "load_queue": {"path": LQ_SOURCE, "sha256": LQ_SHA256},
            "rob": {"path": ROB_SOURCE, "sha256": ROB_SHA256},
        },
        "checker_self_test": {
            "positive_current_locus": "PASS",
            "reject_baseline_unoptflat": "PASS",
            "reject_missing_lq_line": "PASS",
            "reject_extra_unoptflat": "PASS",
        },
        "assertion_weakened": False,
        "canonical_evidence_rewritten": False,
    }
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14D-V9O-LINT-REPLAY][PASS] baseline_unoptflat=0 "
        "mutation_lq_unoptflat=2/2 negative_fixtures=3/3 historical_fail=preserved"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-V9O-LINT-REPLAY][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
