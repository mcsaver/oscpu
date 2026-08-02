#!/usr/bin/env python3
"""Validate task-local current binding for the remaining seven RV64 P0 gates."""

from __future__ import annotations

import argparse
import copy
import datetime
import hashlib
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
ACTIVE_CONE = HERE / "evidence/active-cone-2/active-cone-audit.json"
V14B_DIR = (
    ROOT
    / ".github/task-runs/2026-08-02-rv64-v14b-architecture-current-"
    "freeze-audit-v1"
)
V14B_RECEIPT = (
    V14B_DIR
    / "evidence/p0-direct-rebind-checker-replay-1/rebind-receipt.json"
)
V14B_SOURCE = (
    V14B_DIR
    / "evidence/p0-direct-rebind-checker-replay-1/source-post-result.json"
)

RESULTS = {
    "FDG-G1": ("fdg-current.json", "npc-rv64-fdg-arch-trap-evidence-v1"),
    "XRET-G1": (
        "xret-current.json",
        "npc-rv64-xret-current-mode-evidence-v1",
    ),
    "IFU-AXI-G1": (
        "ifu-axi-current.json",
        "npc-rv64-ifu-axi-flush-drain-evidence-v1",
    ),
    "IFU-FETCH-G2": (
        "ifu-fetch-current.json",
        "npc-rv64-ifu-fetch-provenance-evidence-v1",
    ),
    "IFU-ACCESS-G1": (
        "ifu-access-current.json",
        "npc-rv64-ifu-access-evidence-v1",
    ),
    "IFU-TVAL-G1": (
        "ifu-tval-current.json",
        "npc-rv64-ifu-tval-evidence-v2",
    ),
    "INSTRET-G1": (
        "instret-current.json",
        "npc-rv64-instret-retirement-evidence-v1",
    ),
}

MUTATIONS = {
    "FDG-G1": ("dynamic/mutations/fdg/summary.json", 6, 1),
    "XRET-G1": ("dynamic/mutations/xret/summary.json", 8, 2),
    "IFU-AXI-G1": (
        "../2026-07-22-rv64-v9g-ifu-axi-current-design/"
        "evidence/mutations/summary.json",
        18,
        0,
    ),
    "IFU-FETCH-G2": (
        "../2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/"
        "evidence/mutations/summary.json",
        16,
        0,
    ),
    "IFU-ACCESS-G1": ("dynamic/mutations/ifu-access/summary.json", 19, 0),
    "IFU-TVAL-G1": ("dynamic/mutations/ifu-tval/summary.json", 12, 0),
    "INSTRET-G1": ("dynamic/mutations/instret/summary.json", 3, 0),
}

METHODS = {
    "FDG-G1": "CURRENT_DYNAMIC_PASS",
    "XRET-G1": "CURRENT_DYNAMIC_PASS",
    "IFU-AXI-G1": "CURRENT_FROZEN_EXECUTION_REPLAY_PASS",
    "IFU-FETCH-G2": "CURRENT_FROZEN_EXECUTION_REPLAY_PASS",
    "IFU-ACCESS-G1": "CURRENT_DYNAMIC_PASS",
    "IFU-TVAL-G1": "CURRENT_DYNAMIC_PASS",
    "INSTRET-G1": "CURRENT_DYNAMIC_PASS",
}


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
        raise ValueError(f"invalid task evidence artifact: {path}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
    }


def verify_result(payload: dict[str, Any], schema: str, gate_id: str) -> None:
    if payload.get("schema") != schema:
        raise ValueError(f"{gate_id}: result schema mismatch")
    if payload.get("status") != "PASS":
        raise ValueError(f"{gate_id}: result status is not PASS")
    if payload.get("design_id") != CURRENT_DESIGN_ID:
        raise ValueError(f"{gate_id}: result is not bound to current RTL")


def verify_mutation(
    payload: dict[str, Any], gate_id: str, required: int, oracle: int
) -> None:
    if (
        payload.get("required") != required
        or payload.get("compile_success") != required
        or payload.get("dynamic_rejected") != required
        or payload.get("source_unchanged") is not True
    ):
        raise ValueError(f"{gate_id}: compile-success RTL counterexample gap")
    if oracle and (
        payload.get("oracle_probes_required") != oracle
        or payload.get("oracle_probes_compile_success") != oracle
        or payload.get("oracle_probes_dynamic_rejected") != oracle
    ):
        raise ValueError(f"{gate_id}: oracle probe gap")


def parse_summary(path: pathlib.Path, expected: int) -> None:
    text = path.read_text(encoding="utf-8")
    values = {
        key: int(value)
        for key, value in re.findall(r"^- (total|passed|failed): (\d+)$", text, re.M)
    }
    if values != {"total": expected, "passed": expected, "failed": 0}:
        raise ValueError(f"RTL testbench summary mismatch: {path}: {values}")


def expect_reject(case_id: str, action: Any, rows: list[dict[str, str]]) -> None:
    try:
        action()
    except ValueError as exc:
        rows.append(
            {"case_id": case_id, "status": "REJECTED", "reason": str(exc)}
        )
        return
    raise ValueError(f"negative checker fixture was accepted: {case_id}")


def negative_self_test(
    result: dict[str, Any], mutation: dict[str, Any], active: dict[str, Any]
) -> dict[str, Any]:
    rows: list[dict[str, str]] = []
    wrong_design = copy.deepcopy(result)
    wrong_design["design_id"] = "sha256:" + "0" * 64
    expect_reject(
        "result-design-id-drift",
        lambda: verify_result(
            wrong_design, "npc-rv64-fdg-arch-trap-evidence-v1", "FDG-G1"
        ),
        rows,
    )
    fail_result = copy.deepcopy(result)
    fail_result["status"] = "FAIL"
    expect_reject(
        "result-status-fail",
        lambda: verify_result(
            fail_result, "npc-rv64-fdg-arch-trap-evidence-v1", "FDG-G1"
        ),
        rows,
    )
    incomplete = copy.deepcopy(mutation)
    incomplete["dynamic_rejected"] = incomplete["required"] - 1
    expect_reject(
        "rtl-counterexample-not-rejected",
        lambda: verify_mutation(incomplete, "FDG-G1", 6, 1),
        rows,
    )
    bad_cone = copy.deepcopy(active)
    bad_cone["status"] = "FAIL"
    expect_reject(
        "active-cone-audit-fail",
        lambda: (
            None
            if bad_cone.get("status") == "PASS"
            else (_ for _ in ()).throw(ValueError("active cone is not PASS"))
        ),
        rows,
    )
    return {"required": 4, "detected": len(rows), "cases": rows}


def mutation_path(evidence_dir: pathlib.Path, relative: str) -> pathlib.Path:
    if relative.startswith("../"):
        return (HERE / relative).resolve(strict=True)
    return (evidence_dir / relative).resolve(strict=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence-dir", required=True, type=pathlib.Path)
    parser.add_argument("--mutation-evidence-dir", type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    evidence_dir = args.evidence_dir.resolve(strict=True)
    output = args.output.resolve()
    if not evidence_dir.is_relative_to(HERE / "evidence"):
        raise ValueError("evidence directory escaped V14C task-run")
    if output.parent != evidence_dir or output.name != "receipt.json":
        raise ValueError("receipt path must be current-bind evidence local")
    if output.exists():
        raise ValueError("refusing to replace current P0 receipt")
    mutation_evidence_dir = (
        args.mutation_evidence_dir.resolve(strict=True)
        if args.mutation_evidence_dir is not None
        else evidence_dir
    )
    if not mutation_evidence_dir.is_relative_to(HERE / "evidence"):
        raise ValueError("mutation evidence escaped V14C task-run")

    active = load(ACTIVE_CONE)
    if (
        active.get("status") != "PASS"
        or active.get("current_design_id") != CURRENT_DESIGN_ID
        or active.get("summary", {}).get("dynamic_rerun_required") != 5
        or active.get("summary", {}).get("frozen_execution_replay_eligible") != 2
    ):
        raise ValueError("active-cone classification is not the approved 5/2 split")

    result_payloads: dict[str, dict[str, Any]] = {}
    result_artifacts: dict[str, dict[str, str]] = {}
    mutation_payloads: dict[str, dict[str, Any]] = {}
    mutation_artifacts: dict[str, dict[str, str]] = {}
    for gate_id, (name, schema) in RESULTS.items():
        path = evidence_dir / "results" / name
        payload = load(path)
        verify_result(payload, schema, gate_id)
        result_payloads[gate_id] = payload
        result_artifacts[gate_id] = artifact(path)
    for gate_id, (relative, required, oracle) in MUTATIONS.items():
        path = mutation_path(mutation_evidence_dir, relative)
        payload = load(path)
        verify_mutation(payload, gate_id, required, oracle)
        mutation_payloads[gate_id] = payload
        mutation_artifacts[gate_id] = artifact(path)

    positive_summary = evidence_dir / "dynamic/positive/summary.txt"
    module_summary = (
        V14B_DIR / "evidence/p0-direct-rebind-1/module-aggregate/summary.txt"
    )
    parse_summary(positive_summary, 18)
    parse_summary(module_summary, 113)
    dpi_log = evidence_dir / "dynamic/positive/axi-dpi-sized.log"
    dpi_text = dpi_log.read_text(encoding="utf-8")
    for marker in (
        "AXI_DPI_SIZED_PASS",
        "SIZED_DPI_GUARD_PASS",
        "AXI_DPI_SIZED_SUITE_PASS",
    ):
        if marker not in dpi_text:
            raise ValueError(f"IFU-ACCESS-G1: missing sized-DPI marker {marker}")

    raw_artifacts: dict[str, dict[str, str]] = {}
    for path in sorted((evidence_dir / "raw").glob("*.log")):
        text = path.read_text(encoding="utf-8")
        if any(marker in text for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:")):
            raise ValueError(f"positive gate log contains failure marker: {path}")
        raw_artifacts[path.stem] = artifact(path)
    if len(raw_artifacts) != 7:
        raise ValueError("positive raw gate log inventory is incomplete")

    post_path = evidence_dir / "source-post-result.json"
    post = load(post_path)
    v14b_source = load(V14B_SOURCE)
    source_set = post.get("rtl_source_set", {})
    if (
        post.get("overall_status") != "GREEN"
        or post.get("exit_code") != 0
        or source_set.get("design_id") != CURRENT_DESIGN_ID
        or source_set.get("file_count") != 146
        or source_set.get("files") != v14b_source.get("rtl_source_set", {}).get("files")
    ):
        raise ValueError("production RTL source map changed during V14C")

    v14b_receipt = load(V14B_RECEIPT)
    canonical_unchanged: dict[str, Any] = {}
    for label, row in v14b_receipt["canonical_unchanged"].items():
        path = ROOT / row["path"]
        current = digest(path)
        unchanged = current == row["sha256_after"]
        canonical_unchanged[label] = {
            "path": row["path"],
            "sha256_before": row["sha256_after"],
            "sha256_after": current,
            "unchanged": unchanged,
        }
        if not unchanged:
            raise ValueError(f"canonical {label} changed during V14C")

    negative = negative_self_test(
        result_payloads["FDG-G1"], mutation_payloads["FDG-G1"], active
    )
    count_dynamic = sum(method == "CURRENT_DYNAMIC_PASS" for method in METHODS.values())
    count_replay = sum(
        method == "CURRENT_FROZEN_EXECUTION_REPLAY_PASS"
        for method in METHODS.values()
    )
    source_run: dict[str, Any]
    if evidence_dir.name.startswith("current-bind-checker-replay-"):
        source_status = HERE / "current-bind-1.status"
        driver_test = evidence_dir / "driver-self-test.log"
        normalization_logs = [
            evidence_dir / "normalize-positive.log",
            evidence_dir / "normalize-sized-dpi.log",
        ]
        if source_status.read_text(encoding="utf-8").strip() != "PASS":
            raise ValueError("unexpected historical source-run status")
        if "[V14C-DRIVER-SELF-TEST][PASS]" not in driver_test.read_text(
            encoding="utf-8"
        ):
            raise ValueError("corrected driver fail-closed self-test missing")
        if not all(
            "[V14C-LOG-NORMALIZATION]" in path.read_text(encoding="utf-8")
            for path in normalization_logs
        ):
            raise ValueError("checker replay log normalization is incomplete")
        source_run = {
            "status": "PASS",
            "status_path": source_status.relative_to(ROOT).as_posix(),
            "accepted_as_delivery": False,
            "failure_classification": "DRIVER_STAGE_RETURN_CODE_LOST",
            "historical_status_rewritten": False,
            "semantic_rtl_results_reused": True,
            "corrected_driver_self_test": artifact(driver_test),
            "normalization_logs": [artifact(path) for path in normalization_logs],
        }
    else:
        source_run = {
            "status": "PASS",
            "accepted_as_delivery": False,
            "failure_classification": "SUPERSEDED_BY_CHECKER_REPLAY",
            "historical_status_rewritten": False,
        }

    main_counterexamples = sum(row[1] for row in MUTATIONS.values())
    oracle_counterexamples = sum(row[2] for row in MUTATIONS.values())
    receipt = {
        "schema": "rv64-v14c-p0-transitive-current-rebind-receipt-v1",
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc
        ).isoformat(),
        "status": "PASS",
        "current_design_id": CURRENT_DESIGN_ID,
        "scope": list(RESULTS),
        "scope_status": METHODS,
        "method_counts": {"dynamic": count_dynamic, "frozen_replay": count_replay},
        "active_cone": artifact(ACTIVE_CONE),
        "positive_rtl": result_artifacts,
        "positive_raw_logs": raw_artifacts,
        "compile_success_rtl_counterexamples": {
            gate_id: {
                "required": MUTATIONS[gate_id][1],
                "detected": payload["dynamic_rejected"],
                "execution": (
                    "CURRENT_DYNAMIC"
                    if METHODS[gate_id] == "CURRENT_DYNAMIC_PASS"
                    else "FROZEN_CLOSURE_REPLAY"
                ),
                "summary": mutation_artifacts[gate_id],
            }
            for gate_id, payload in mutation_payloads.items()
        },
        "checker_negative_fixtures": negative,
        "source_run": source_run,
        "shared_current_module_aggregate": {
            "required": 113,
            "passed": 113,
            "summary": artifact(module_summary),
            "v14b_receipt": artifact(V14B_RECEIPT),
        },
        "dynamic_positive_suite": {
            "required": 18,
            "passed": 18,
            "summary": artifact(positive_summary),
            "sized_dpi": artifact(dpi_log),
        },
        "source_identity": {
            "file_count": 146,
            "pre_post_equal": True,
            "post_checker": artifact(post_path),
        },
        "canonical_unchanged": canonical_unchanged,
        "publication": {
            "task_local_only": True,
            "architecture_debt_ledger_written": False,
            "canonical_architecture_written": False,
            "p0_current_bound_in_task_scope": 9,
            "p0_current_stale_in_task_scope": 0,
            "architecture_gate_state": "RED",
            "arch_stable": False,
            "ppa_state": "BLOCKED_BY_ARCHITECTURE",
            "promotion_eligible": False,
        },
        "counterexample_totals": {
            "main_required": main_counterexamples,
            "oracle_required": oracle_counterexamples,
            "total_required": main_counterexamples + oracle_counterexamples,
            "total_detected": main_counterexamples + oracle_counterexamples,
        },
        "remaining_scope": {
            "p1_not_current_bound": 7,
            "historical_defect_backfill_current_bound": False,
            "holder_semantic_status": "GAP",
            "functional_aggregate_current_bound": False,
            "freeze_empty_input_groups": 12,
        },
    }
    output.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V14C-P0-CURRENT-BIND][PASS] "
        f"design_id={CURRENT_DESIGN_ID} gates=7/7 dynamic={count_dynamic} "
        f"frozen_replay={count_replay} counterexamples="
        f"{main_counterexamples + oracle_counterexamples}/"
        f"{main_counterexamples + oracle_counterexamples} negative=4/4 "
        "source_pre_post=equal p0_current_stale=0 architecture=RED "
        "arch_stable=0 ppa=BLOCKED"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14C-P0-CURRENT-BIND][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
