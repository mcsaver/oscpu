#!/usr/bin/env python3
"""Validate current-design CONTROL-EVENT-G1 dynamic RTL evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CURRENT_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)
V9O_ROOT = ROOT / ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
V9O_LEGACY = V9O_ROOT / "build-evidence-index.py"
V9O_MUTATION_RUNNER = V9O_ROOT / "run-control-event-rtl-mutations.py"
V9R_HELPER = ROOT / "npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
FAIL_MARKERS = ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:")


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
        raise ValueError(f"invalid CONTROL-EVENT artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def validate_positive(
    path: pathlib.Path,
    test_name: str,
    markers: tuple[str, ...],
) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    native = [
        line
        for line in text.splitlines()
        if line in {f"[PASS] {test_name}", f"PASS {test_name}"}
    ]
    required = ("[COMPILE] ", "[RESULT] PASS", *markers)
    if (
        any(text.count(marker) != 1 for marker in required)
        or len(native) != 1
        or text.count(f"[RTL-DESIGN-ID] {CURRENT_DESIGN_ID}") != 1
        or any(marker in text for marker in FAIL_MARKERS)
        or "<CONTROL_EVENT_V11X_TEMP>/" not in text
        or "/tmp/rv64-v14d-control." in text
    ):
        raise ValueError(f"positive CONTROL-EVENT marker drift: {test_name}")
    return artifact(path)


def validate_v9o_mutations(
    evidence: pathlib.Path,
    snapshot: dict[str, Any],
    replay_path: pathlib.Path,
) -> tuple[dict[str, str], dict[str, str], list[dict[str, Any]]]:
    runner = load_module(V9O_MUTATION_RUNNER, "v14d_v9o_mutation_runner")
    summary_path = evidence / "v9o-mutations/summary.json"
    summary = load(summary_path)
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
        and summary.get("rtl_source_set", {}).get("files") == snapshot["files"]
    ):
        raise ValueError("V9O mutation summary drift")
    baseline = summary.get("baseline_lint", {})
    baseline_path = ROOT / str(baseline.get("path", ""))
    if (
        baseline.get("returncode") != 0
        or not baseline_path.is_file()
        or digest(baseline_path) != baseline.get("sha256")
        or "%Warning-UNOPTFLAT" in baseline_path.read_text(encoding="utf-8")
    ):
        raise ValueError("V9O baseline full-cone lint drift")
    rows = summary.get("results", [])
    by_name = {row.get("name"): row for row in rows if isinstance(row, dict)}
    if set(by_name) != {spec.name for spec in runner.MUTATIONS}:
        raise ValueError("V9O mutation inventory drift")
    replay = load(replay_path)
    raw_attempt = replay.get("raw_attempt", {})
    replay_mutation = replay.get("mutation", {})
    if not (
        replay.get("schema") == "rv64-v14d-v9o-lint-checker-replay-v1"
        and replay.get("status") == "PASS"
        and replay.get("current_design_id") == CURRENT_DESIGN_ID
        and raw_attempt.get("summary") == artifact(summary_path)
        and raw_attempt.get("historical_status_rewritten") is False
        and replay_mutation.get("name")
        == "pregrant_reads_current_completion_ready"
        and replay_mutation.get("variant_sha256")
        == "0f627107f81c978a46a141572f8b58919650afdf0903757783a1ceccb101c150"
        and replay_mutation.get("compile_success") is True
        and replay_mutation.get("dynamic_test_passed") is True
        and replay_mutation.get("rejection_mode")
        == "lint-unoptflat-current-lq-locus"
        and replay.get("current_lq_locus", {}).get("observed_count") == 2
        and replay.get("current_lq_locus", {}).get("no_additional_unoptflat")
        is True
        and replay.get("assertion_weakened") is False
    ):
        raise ValueError("V9O current-locus checker replay drift")
    output_rows: list[dict[str, Any]] = []
    for spec in runner.MUTATIONS:
        row = by_name[spec.name]
        original, mutated = runner.reconstruct_mutation(ROOT, spec)
        original_sha = hashlib.sha256(original.encode("utf-8")).hexdigest()
        mutation_sha = hashlib.sha256(mutated.encode("utf-8")).hexdigest()
        expected_dynamic = spec.rejection_mode == "dynamic"
        if not (
            row.get("source") == spec.source_rel
            and row.get("test_name") == spec.test_name
            and row.get("original_sha256") == original_sha
            and row.get("mutation_sha256") == mutation_sha
            and row.get("compile_success") is True
        ):
            raise ValueError(f"V9O mutation contract drift: {spec.name}")
        log_record = row.get("log", {})
        log_path = ROOT / str(log_record.get("path", ""))
        if not log_path.is_file() or digest(log_path) != log_record.get("sha256"):
            raise ValueError(f"V9O mutation log hash drift: {spec.name}")
        text = log_path.read_text(encoding="utf-8")
        if expected_dynamic:
            if not (
                row.get("rejected") is True
                and row.get("dynamic_rejected") is True
                and row.get("lint_rejected") is False
                and row.get("observed_markers")
                == {marker: True for marker in spec.expected_markers}
                and all(text.count(marker) == 1 for marker in spec.expected_markers)
                and text.count("[RESULT] FAIL") == 1
                and "[RESULT] PASS" not in text
            ):
                raise ValueError(f"V9O dynamic mutation escaped: {spec.name}")
            rejection_mode = spec.rejection_mode
            oracle_receipt = None
        else:
            if not (
                row.get("rejected") is False
                and row.get("dynamic_rejected") is False
                and row.get("lint_rejected") is False
                and row.get("observed_markers")
                == {marker: False for marker in spec.expected_markers}
                and text.count("[RESULT] PASS") == 1
                and "[RESULT] FAIL" not in text
                and replay_mutation.get("source") == spec.source_rel
                and replay_mutation.get("test_name") == spec.test_name
                and replay_mutation.get("log") == artifact(log_path)
            ):
                raise ValueError(f"V9O lint replay binding drift: {spec.name}")
            rejection_mode = "lint-unoptflat-current-lq-locus"
            oracle_receipt = artifact(replay_path)
        output_row = {
            "name": spec.name,
            "source": spec.source_rel,
            "test_name": spec.test_name,
            "rejection_mode": rejection_mode,
            "variant_sha256": mutation_sha,
            "log": artifact(log_path),
        }
        if oracle_receipt is not None:
            output_row["oracle_receipt"] = oracle_receipt
        output_rows.append(output_row)
    return artifact(summary_path), artifact(replay_path), output_rows


def validate_v9r(
    evidence: pathlib.Path,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    helper = load_module(V9R_HELPER, "v14d_v9r_helper")
    positives: list[dict[str, Any]] = []
    for test_name, markers in helper.BASELINE_TESTS.items():
        path = evidence / f"v9r-baseline/logs/{test_name}.log"
        positives.append(
            {
                "test": test_name,
                "log": validate_positive(path, test_name, tuple(markers)),
            }
        )
    mutations: list[dict[str, Any]] = []
    status_pattern = re.compile(
        r"^REJECTED_COMPILE_SUCCESS_VARIANT rc=2 "
        r"variant_sha256=([0-9a-f]{64}) TRANSIENT_COMPILED_IMAGE=1$"
    )
    for case_id, spec in helper.VARIANTS.items():
        case_dir = evidence / f"v9r-mutations/{case_id}"
        status_text = (case_dir / "status").read_text(encoding="utf-8").strip()
        match = status_pattern.fullmatch(status_text)
        encoded, metadata = helper.mutated_bytes(ROOT, case_id)
        if match is None or match.group(1) != metadata["variant_sha256"]:
            raise ValueError(f"V9R mutation status drift: {case_id}")
        log_path = case_dir / f"logs/{spec['test_name']}.log"
        text = log_path.read_text(encoding="utf-8")
        if (
            text.count(spec["assertion_marker"]) < 1
            or text.count("[RESULT] FAIL") != 1
            or "[RESULT] PASS" in text
            or "[COMPILE] " not in text
            or hashlib.sha256(encoded).hexdigest() != metadata["variant_sha256"]
        ):
            raise ValueError(f"V9R mutation oracle drift: {case_id}")
        mutations.append(
            {
                "name": case_id,
                "source": spec["production_source"],
                "test_name": spec["test_name"],
                "variant_sha256": metadata["variant_sha256"],
                "log": artifact(log_path),
                "status": artifact(case_dir / "status"),
            }
        )
    return positives, mutations


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=pathlib.Path)
    parser.add_argument("--v9o-evidence", type=pathlib.Path)
    parser.add_argument("--v9r-evidence", type=pathlib.Path)
    parser.add_argument("--v9o-replay", required=True, type=pathlib.Path)
    parser.add_argument("--warning-replay", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence = args.evidence.resolve(strict=True)
    v9o_evidence = (
        args.v9o_evidence.resolve(strict=True) if args.v9o_evidence else evidence
    )
    v9r_evidence = (
        args.v9r_evidence.resolve(strict=True) if args.v9r_evidence else evidence
    )
    v9o_replay = args.v9o_replay.resolve(strict=True)
    warning_replay = args.warning_replay.resolve(strict=True)
    output = args.output.resolve()
    evidence_root = HERE / "evidence"
    if (
        any(
            not path.is_relative_to(evidence_root)
            for path in (
                evidence,
                v9o_evidence,
                v9r_evidence,
                v9o_replay,
                warning_replay,
            )
        )
        or not output.is_relative_to(evidence)
    ):
        raise ValueError("CONTROL-EVENT summary path escaped V14D evidence")
    if output.exists():
        raise ValueError("refusing to replace CONTROL-EVENT summary")

    before = load(evidence / "source-before.json")
    after = load(evidence / "source-after.json")
    if (
        before != after
        or before.get("design_id") != CURRENT_DESIGN_ID
        or before.get("file_count") != 146
    ):
        raise ValueError("CONTROL-EVENT full RTL source identity drift")
    if (evidence / "canonical-before.sha256").read_bytes() != (
        evidence / "canonical-after.sha256"
    ).read_bytes():
        raise ValueError("CONTROL-EVENT canonical ledger write detected")
    if load(v9o_evidence / "source-before.json") != before:
        raise ValueError("V9O attempt and current V9R source cohort differ")
    if (v9o_evidence / "canonical-before.sha256").read_bytes() != (
        evidence / "canonical-before.sha256"
    ).read_bytes():
        raise ValueError("V9O attempt and current V9R canonical cohort differ")
    if not (
        load(v9r_evidence / "source-before.json") == before
        and load(v9r_evidence / "source-after.json") == before
        and (v9r_evidence / "canonical-before.sha256").read_bytes()
        == (evidence / "canonical-before.sha256").read_bytes()
        and (v9r_evidence / "canonical-after.sha256").read_bytes()
        == (evidence / "canonical-before.sha256").read_bytes()
    ):
        raise ValueError("V9R dynamic evidence and current source cohort differ")

    legacy = load_module(V9O_LEGACY, "v14d_v9o_legacy_markers")
    positive_rows: list[dict[str, Any]] = []
    positive_logs: list[pathlib.Path] = []
    for group, marker_map in (
        ("v9o-focused", legacy.FOCUSED_MARKERS),
        ("v9o-config", legacy.CONFIG_MARKERS),
    ):
        for test_name, markers in marker_map.items():
            path = v9o_evidence / f"{group}/logs/{test_name}.log"
            positive_logs.append(path)
            positive_rows.append(
                {
                    "group": group,
                    "test": test_name,
                    "log": validate_positive(path, test_name, tuple(markers)),
                }
            )
    mutation_summary, replay_receipt, v9o_mutations = validate_v9o_mutations(
        v9o_evidence, before, v9o_replay
    )
    v9r_positives, v9r_mutations = validate_v9r(v9r_evidence)
    positive_logs.extend(ROOT / row["log"]["path"] for row in v9r_positives)

    sys.path.insert(0, str(HERE))
    from warning_audit import audit

    warning = audit(positive_logs)
    warning_receipt = load(warning_replay)
    if not (
        warning_receipt.get("schema")
        == "rv64-v14d-control-warning-checker-replay-v1"
        and warning_receipt.get("status") == "PASS"
        and warning_receipt.get("warning_audit") == warning
        and warning_receipt.get("raw_attempt", {}).get(
            "historical_status_rewritten"
        )
        is False
        and warning_receipt.get("assertion_weakened") is False
    ):
        raise ValueError("CONTROL-EVENT warning checker replay drift")
    result = {
        "schema": "rv64-v14d-control-event-current-summary-v1",
        "status": "PASS",
        "debt_id": "CONTROL-EVENT-G1",
        "current_design_id": CURRENT_DESIGN_ID,
        "scope_status": "CURRENT_DYNAMIC_PASS",
        "positive": {
            "required": 16,
            "passed": len(positive_rows) + len(v9r_positives),
            "v9o": positive_rows,
            "v9r": v9r_positives,
        },
        "compile_success_rtl_counterexamples": {
            "required": 16,
            "detected": len(v9o_mutations) + len(v9r_mutations),
            "v9o": v9o_mutations,
            "v9r": v9r_mutations,
            "v9o_raw_summary": mutation_summary,
            "v9o_checker_replay": replay_receipt,
        },
        "source_identity": {
            "file_count": 146,
            "pre_post_equal": True,
            "before": artifact(evidence / "source-before.json"),
            "after": artifact(evidence / "source-after.json"),
        },
        "warning_audit": warning,
        "warning_checker_replay": artifact(warning_replay),
        "canonical_ledger_unchanged": True,
        "evidence_provenance": {
            "v9o_positive_and_raw_mutations": artifact(
                v9o_evidence / "source-before.json"
            ),
            "v9r_current_run": artifact(v9r_evidence / "source-after.json"),
            "historical_attempt_statuses": [
                artifact(HERE / "control-run-1.status"),
                artifact(HERE / "control-run-2.status"),
            ],
            "historical_status_rewritten": False,
        },
        "assertion_failure_observed": False,
        "transient_compiled_images_retained": 0,
        "promotion_eligible": False,
        "ppa": "BLOCKED_BY_ARCHITECTURE",
    }
    if result["positive"]["passed"] != 16:
        raise ValueError("CONTROL-EVENT positive count drift")
    if result["compile_success_rtl_counterexamples"]["detected"] != 16:
        raise ValueError("CONTROL-EVENT mutation count drift")
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14D-CONTROL-EVENT][PASS] positive=16/16 mutations=16/16 "
        "current_design=1 source_unchanged=1 assertions=0 retained_vvp=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-CONTROL-EVENT][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
