#!/usr/bin/env python3
"""Validate current-design STORE-BRESP-G1 dynamic RTL evidence."""

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
V9N_RUNNER = (
    ROOT
    / ".github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency"
    / "run-owner-residency-rtl-variants.py"
)
V13R_RUNNER = HERE / "run-v13r-store-mutations.py"
FAIL_MARKERS = ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:")
V9N_POSITIVES = {
    "store": (
        "tb_v9n_sq_owner_residency",
        "[V9N-SQ-NEXT-EDGE-OWNER] launch=1 preserved=1 exact_terminal=1 PASS",
    ),
    "amo": (
        "tb_v9n_amo_owner_residency",
        "[V9N-AMO-NEXT-EDGE-OWNER] launch=1 preserved=1 exact_terminal=1 PASS",
    ),
}
V13R_POSITIVES = {
    "bridge": (
        "tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold",
        (
            "[V13R-B-FUSION-MULTICYCLE][PASS] decerr=1 poisoned_b=1 "
            "s_resp_stall_edges=3 exact_owner=1 exact_tval=1 consume=1",
        ),
    ),
    "backend": (
        "tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold",
        (
            "[V13R-BACKEND-FAIRNESS] first_wave_full=1 lane1_refill_blocked=1 "
            "second_wave_partial=1 response_bound=C_B+1 PASS",
            "[V13R-BACKEND-B-HOLD] decerr_fallback=1 requested_alu_waves=2 "
            "anti_starvation_bound=1 commit_stall_cycles=3 cause7=1 "
            "original_tval=1 exact_terminal=1 owner_hold=1 quiet=3 PASS",
        ),
    ),
}


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
        raise ValueError(f"invalid STORE-BRESP artifact: {path}")
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
    if not (
        text.count("[COMPILE] ") == 1
        and all(text.count(marker) == 1 for marker in markers)
        and len(native) == 1
        and text.count("[RESULT] PASS") == 1
        and text.count(f"[RTL-DESIGN-ID] {CURRENT_DESIGN_ID}") == 1
        and not any(marker in text for marker in FAIL_MARKERS)
        and "/tmp/rv64-v14d-store." not in text
    ):
        raise ValueError(f"positive STORE-BRESP marker drift: {test_name}")
    return artifact(path)


def validate_v9n(
    evidence: pathlib.Path,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, str]]:
    runner = load_module(V9N_RUNNER, "v14d_v9n_store_runner")
    positive_rows: list[dict[str, Any]] = []
    for name, (test_name, marker) in V9N_POSITIVES.items():
        path = evidence / f"v9n-focused/logs/{test_name}.log"
        positive_rows.append(
            {
                "name": name,
                "test": test_name,
                "log": validate_positive(path, test_name, (marker,)),
            }
        )

    summary_path = evidence / "v9n-mutations/summary.json"
    summary = load(summary_path)
    specs = {spec.name: spec for spec in runner.VARIANTS}
    rows = summary.get("results", [])
    by_name = {row.get("name"): row for row in rows if isinstance(row, dict)}
    source_names = sorted({spec.source_rel for spec in specs.values()})
    live = {name: digest(ROOT / name) for name in source_names}
    if not (
        summary.get("schema") == runner.SCHEMA
        and summary.get("required") == len(specs) == 2
        and summary.get("compile_success") == 2
        and summary.get("dynamic_rejected") == 2
        and summary.get("source_unchanged") is True
        and summary.get("source_sha256_before") == live
        and summary.get("source_sha256_after") == live
        and set(by_name) == set(specs)
    ):
        raise ValueError("V9N owner-residency mutation summary drift")

    mutation_rows: list[dict[str, Any]] = []
    for name, spec in specs.items():
        row = by_name[name]
        original, mutated = runner.reconstruct_variant(ROOT, spec)
        original_sha = hashlib.sha256(original.encode("utf-8")).hexdigest()
        variant_sha = hashlib.sha256(mutated.encode("utf-8")).hexdigest()
        log_record = row.get("log", {})
        log_path = ROOT / str(log_record.get("path", ""))
        text = log_path.read_text(encoding="utf-8")
        if not (
            row.get("source") == spec.source_rel
            and row.get("test_name") == spec.test_name
            and row.get("original_sha256") == original_sha
            and row.get("variant_sha256") == variant_sha
            and row.get("expected_marker") == spec.expected_marker
            and row.get("marker_observed") is True
            and row.get("old_same_edge_assertion_quiet") is True
            and row.get("compile_success") is True
            and row.get("dynamic_rejected") is True
            and isinstance(row.get("make_returncode"), int)
            and row.get("make_returncode") != 0
            and log_path.is_file()
            and digest(log_path) == log_record.get("sha256")
            and text.count(spec.expected_marker) == 1
            and text.count("[RESULT] FAIL status=1") == 1
            and "[RESULT] PASS" not in text
            and spec.superseded_same_edge_marker not in text
        ):
            raise ValueError(f"V9N owner-residency mutation drift: {name}")
        mutation_rows.append(
            {
                "name": name,
                "source": spec.source_rel,
                "test_name": spec.test_name,
                "variant_sha256": variant_sha,
                "log": artifact(log_path),
            }
        )

    receipt_path = evidence / "v9n-owner/receipt.json"
    raw_path = evidence / "v9n-owner/receipt.log"
    receipt = load(receipt_path)
    if not (
        receipt.get("schema")
        == "npc-rv64-irrevocable-owner-residency-evidence-v1"
        and receipt.get("status") == "PASS"
        and receipt.get("design_id") == CURRENT_DESIGN_ID
        and receipt.get("claim", {}).get("store_next_edge_owner_residency")
        is True
        and receipt.get("claim", {}).get("amo_next_edge_owner_residency")
        is True
        and receipt.get("mutation_audit", {}).get("required") == 2
        and receipt.get("mutation_audit", {}).get("compile_success") == 2
        and receipt.get("mutation_audit", {}).get("dynamic_rejected") == 2
        and receipt.get("mutation_audit", {}).get("summary")
        == artifact(summary_path)
        and receipt.get("provenance", {}).get("rtl_sha256")
        == CURRENT_DESIGN_ID.removeprefix("sha256:")
        and receipt.get("provenance", {}).get("rtl_file_count") == 146
        and receipt.get("promotion_eligible") is False
    ):
        raise ValueError("V9N current owner-residency receipt drift")
    for row in positive_rows:
        receipt_row = receipt.get("focused", {}).get(row["name"], {})
        if receipt_row.get("log") != row["log"]:
            raise ValueError(f"V9N positive receipt binding drift: {row['name']}")
    raw_text = raw_path.read_text(encoding="utf-8")
    if raw_text.count(
        "[STORE-BRESP-G1-OWNER-RESIDENCY] PASS focused=2 variants=2"
    ) != 1:
        raise ValueError("V9N raw receipt marker drift")
    return positive_rows, mutation_rows, artifact(receipt_path)


def validate_v13r(
    evidence: pathlib.Path,
    replay_path: pathlib.Path,
) -> tuple[
    list[dict[str, Any]],
    list[dict[str, Any]],
    dict[str, str],
    dict[str, str],
]:
    runner = load_module(V13R_RUNNER, "v14d_v13r_store_runner")
    positive_rows: list[dict[str, Any]] = []
    for name, (test_name, markers) in V13R_POSITIVES.items():
        path = evidence / f"v13r-focused/logs/{test_name}.log"
        positive_rows.append(
            {
                "name": name,
                "test": test_name,
                "log": validate_positive(path, test_name, markers),
            }
        )

    summary_path = evidence / "v13r-mutations/summary.json"
    summary = load(summary_path)
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
    ):
        raise ValueError("V13R STORE-B mutation summary drift")
    replay = load(replay_path)
    replay_rows = replay.get("mutations", {}).get("rows", [])
    replay_by_name = {
        row.get("name"): row for row in replay_rows if isinstance(row, dict)
    }
    if not (
        replay.get("schema") == "rv64-v14d-v13r-mutation-checker-replay-v1"
        and replay.get("status") == "PASS"
        and replay.get("current_design_id") == CURRENT_DESIGN_ID
        and replay.get("raw_attempt", {}).get("summary") == artifact(summary_path)
        and replay.get("raw_attempt", {}).get("historical_status_rewritten")
        is False
        and replay.get("mutations", {}).get("required") == 3
        and replay.get("mutations", {}).get("compile_success") == 3
        and replay.get("mutations", {}).get("dynamic_rejected") == 3
        and set(replay_by_name) == set(specs)
        and replay.get("assertion_weakened") is False
    ):
        raise ValueError("V13R STORE-B checker replay drift")

    mutation_rows: list[dict[str, Any]] = []
    for name, spec in specs.items():
        row = by_name[name]
        original, mutated = runner.reconstruct_mutation(ROOT, spec)
        original_sha = hashlib.sha256(original.encode("utf-8")).hexdigest()
        variant_sha = hashlib.sha256(mutated.encode("utf-8")).hexdigest()
        log_record = row.get("log", {})
        log_path = ROOT / str(log_record.get("path", ""))
        text = log_path.read_text(encoding="utf-8")
        matching_markers = [
            line
            for line in text.splitlines()
            if line.startswith(spec.expected_marker)
        ]
        check_fail_count = sum(
            line.startswith("[CHECK-FAIL] ") for line in text.splitlines()
        )
        replay_row = replay_by_name[name]
        if not (
            row.get("source") == spec.source_rel
            and row.get("test_name") == spec.test_name
            and row.get("original_sha256") == original_sha
            and row.get("variant_sha256") == variant_sha
            and row.get("expected_marker") == spec.expected_marker
            and row.get("marker_observed") is True
            and row.get("compile_success") is True
            and row.get("dynamic_rejected") is False
            and row.get("check_fail_count") == check_fail_count
            and isinstance(row.get("make_returncode"), int)
            and row.get("make_returncode") != 0
            and log_path.is_file()
            and digest(log_path) == log_record.get("sha256")
            and len(matching_markers) == 1
            and text.count("[RESULT] FAIL status=1") == 1
            and "[RESULT] PASS" not in text
            and replay_row.get("source") == spec.source_rel
            and replay_row.get("test_name") == spec.test_name
            and replay_row.get("variant_sha256") == variant_sha
            and replay_row.get("expected_fatal") == spec.expected_fatal
            and replay_row.get("check_fail_count") == check_fail_count
            and replay_row.get("compile_success") is True
            and replay_row.get("dynamic_rejected") is True
            and replay_row.get("log") == artifact(log_path)
        ):
            raise ValueError(f"V13R STORE-B mutation drift: {name}")
        mutation_rows.append(
            {
                "name": name,
                "source": spec.source_rel,
                "test_name": spec.test_name,
                "variant_sha256": variant_sha,
                "check_fail_count": check_fail_count,
                "log": artifact(log_path),
                "oracle_receipt": artifact(replay_path),
            }
        )
    return (
        positive_rows,
        mutation_rows,
        artifact(summary_path),
        artifact(replay_path),
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", required=True, type=pathlib.Path)
    parser.add_argument("--test-evidence", type=pathlib.Path)
    parser.add_argument("--v13r-replay", required=True, type=pathlib.Path)
    parser.add_argument("--warning-replay", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence = args.evidence.resolve(strict=True)
    test_evidence = (
        args.test_evidence.resolve(strict=True) if args.test_evidence else evidence
    )
    v13r_replay = args.v13r_replay.resolve(strict=True)
    warning_replay = args.warning_replay.resolve(strict=True)
    output = args.output.resolve()
    evidence_root = HERE / "evidence"
    if (
        any(
            not path.is_relative_to(evidence_root)
            for path in (evidence, test_evidence, v13r_replay, warning_replay)
        )
        or not output.is_relative_to(evidence)
    ):
        raise ValueError("STORE-BRESP summary path escaped V14D evidence")
    if output.exists():
        raise ValueError("refusing to replace STORE-BRESP summary")

    before = load(evidence / "source-before.json")
    after = load(evidence / "source-after.json")
    if not (
        before == after
        and before.get("design_id") == CURRENT_DESIGN_ID
        and before.get("file_count") == 146
    ):
        raise ValueError("STORE-BRESP full RTL source identity drift")
    if (evidence / "canonical-before.sha256").read_bytes() != (
        evidence / "canonical-after.sha256"
    ).read_bytes():
        raise ValueError("STORE-BRESP canonical ledger write detected")
    if load(test_evidence / "source-before.json") != before:
        raise ValueError("STORE-BRESP test evidence and current source cohort differ")
    if (test_evidence / "canonical-before.sha256").read_bytes() != (
        evidence / "canonical-before.sha256"
    ).read_bytes():
        raise ValueError("STORE-BRESP test evidence canonical cohort differs")

    v9n_positive, v9n_mutations, owner_receipt = validate_v9n(test_evidence)
    (
        v13r_positive,
        v13r_mutations,
        v13r_summary,
        v13r_replay_receipt,
    ) = validate_v13r(test_evidence, v13r_replay)
    positive_logs = [
        ROOT / row["log"]["path"]
        for row in (*v9n_positive, *v13r_positive)
    ]
    sys.path.insert(0, str(HERE))
    from store_warning_audit import audit

    warning = audit(positive_logs)
    warning_receipt = load(warning_replay)
    if not (
        warning_receipt.get("schema")
        == "rv64-v14d-store-warning-checker-replay-v1"
        and warning_receipt.get("status") == "PASS"
        and warning_receipt.get("warning_audit") == warning
        and warning_receipt.get("raw_attempt", {}).get(
            "historical_status_rewritten"
        )
        is False
        and warning_receipt.get("assertion_weakened") is False
    ):
        raise ValueError("STORE-BRESP warning checker replay drift")
    result = {
        "schema": "rv64-v14d-store-bresp-current-summary-v1",
        "status": "PASS",
        "debt_id": "STORE-BRESP-G1",
        "current_design_id": CURRENT_DESIGN_ID,
        "scope_status": "CURRENT_DYNAMIC_PASS",
        "positive": {
            "required": 4,
            "passed": len(v9n_positive) + len(v13r_positive),
            "v9n_owner_residency": v9n_positive,
            "v13r_holder_and_retirement": v13r_positive,
        },
        "compile_success_rtl_counterexamples": {
            "required": 5,
            "detected": len(v9n_mutations) + len(v13r_mutations),
            "v9n_owner_residency": v9n_mutations,
            "v13r_holder_and_retirement": v13r_mutations,
            "v9n_receipt": owner_receipt,
            "v13r_summary": v13r_summary,
            "v13r_checker_replay": v13r_replay_receipt,
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
            "dynamic_test_source_binding": artifact(
                test_evidence / "source-before.json"
            ),
            "historical_attempt_statuses": [
                artifact(HERE / "store-run-1.status"),
                artifact(HERE / "store-run-2.status"),
            ],
            "historical_status_rewritten": False,
        },
        "assertion_failure_observed": False,
        "transient_compiled_images_retained": 0,
        "promotion_eligible": False,
        "ppa": "BLOCKED_BY_ARCHITECTURE",
    }
    if result["positive"]["passed"] != 4:
        raise ValueError("STORE-BRESP positive count drift")
    if result["compile_success_rtl_counterexamples"]["detected"] != 5:
        raise ValueError("STORE-BRESP mutation count drift")
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14D-STORE-BRESP][PASS] positive=4/4 mutations=5/5 "
        "current_design=1 source_unchanged=1 assertions=0 retained_vvp=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-STORE-BRESP][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
