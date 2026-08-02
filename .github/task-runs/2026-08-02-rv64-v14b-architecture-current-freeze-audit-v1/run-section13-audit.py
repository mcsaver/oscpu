#!/usr/bin/env python3
"""Build a bounded Section-13 audit for the current local RV64 RTL image."""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CURRENT_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)
BASELINE_DESIGN_ID = (
    "sha256:882111fb3d58039cb7414e6331dac0c10d848463df2228dff93ae22dafbed67b"
)

BASELINE_RESULT = (
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/static/architecture-result.json"
)
CURRENT_RESULT = (
    ".github/task-runs/2026-08-02-rv64-v14a-di2-current-rebind-v1/"
    "evidence/di2-current/static/architecture-result.json"
)
DIRECTED_REPLAY = (
    ".github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/"
    "evidence/replay-1/replay-receipt.json"
)
DEBT_LEDGER = "npc/rv64/design/arch/architecture-debt-ledger.json"
HISTORICAL_LEDGER = "npc/rv64/design/arch/historical-defect-backfill-ledger.json"
HOLDER_CENSUS = "npc/rv64/design/arch/producer-holder-census.json"
HOLDER_SEMANTIC = "npc/rv64/design/arch/producer-holder-semantic-coverage.json"
FUNCTIONAL_AGGREGATE = "npc/rv64/eval/ppa/evidence/functional-aggregate-current.json"
FUNCTIONAL_RESULT = "npc/rv64/eval/ppa/evidence/functional-aggregate-result.json"
ARCH_STABLE_CANDIDATE = "npc/rv64/eval/ppa/arch-stable/full-core-current.json"
ARCH_STABLE_RESULT = "npc/rv64/eval/ppa/evidence/arch-stable-current.json"
CANONICAL_ARCHITECTURE = "npc/rv64/eval/ppa/evidence/architecture-current.json"


def workspace_file(relative: str) -> pathlib.Path:
    path = (ROOT / relative).resolve(strict=True)
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError(f"invalid workspace file: {relative}")
    return path


def load(relative: str) -> dict[str, Any]:
    payload = json.loads(workspace_file(relative).read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"JSON root is not an object: {relative}")
    return payload


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def artifact(relative: str) -> dict[str, str]:
    path = workspace_file(relative)
    return {"path": relative, "sha256": digest(path)}


def source_map(payload: dict[str, Any], label: str) -> dict[str, str]:
    source_set = payload.get("rtl_source_set")
    if not isinstance(source_set, dict):
        raise ValueError(f"{label}: missing rtl_source_set")
    files = source_set.get("files")
    if not isinstance(files, dict) or not files:
        raise ValueError(f"{label}: missing rtl_source_set.files")
    if not all(isinstance(path, str) and isinstance(sha, str)
               for path, sha in files.items()):
        raise ValueError(f"{label}: malformed rtl source map")
    return files


def validate_live_source_map(files: dict[str, str]) -> list[str]:
    mismatches: list[str] = []
    for relative, expected in sorted(files.items()):
        try:
            actual = digest(workspace_file(relative))
        except (OSError, ValueError):
            mismatches.append(relative)
            continue
        if actual != expected:
            mismatches.append(relative)
    return mismatches


def count_by(items: list[dict[str, Any]], field: str) -> dict[str, int]:
    result: dict[str, int] = {}
    for item in items:
        key = str(item.get(field, "<missing>"))
        result[key] = result.get(key, 0) + 1
    return dict(sorted(result.items()))


def debt_audit(
    ledger: dict[str, Any], changed_paths: set[str]
) -> tuple[list[dict[str, Any]], list[str], list[str]]:
    entries = ledger.get("entries")
    if not isinstance(entries, list) or not entries:
        raise ValueError("architecture debt ledger has no entries")
    audited: list[dict[str, Any]] = []
    p0_direct: list[str] = []
    p1_direct: list[str] = []
    for entry in entries:
        if not isinstance(entry, dict) or not isinstance(entry.get("id"), str):
            raise ValueError("malformed architecture debt entry")
        owner_paths = entry.get("owner_paths", [])
        if not isinstance(owner_paths, list) or not all(
            isinstance(path, str) for path in owner_paths
        ):
            raise ValueError(f"{entry['id']}: malformed owner_paths")
        direct = sorted(set(owner_paths) & changed_paths)
        excluded = entry.get("status") == "EXCLUDED_BY_COHORT"
        current = (
            entry.get("status") == "CLOSED"
            and entry.get("current_design_bound") is True
            and entry.get("design_id") == CURRENT_DESIGN_ID
        )
        if excluded:
            effective = "EXCLUDED_BY_FROZEN_COHORT"
            revalidation = "SCOPE_CONTRACT_REVIEW"
        elif current:
            effective = "CURRENT_BOUND"
            revalidation = "NONE"
        elif direct:
            effective = "CURRENT_BINDING_STALE"
            revalidation = "DIRECT_ACTIVE_CONE_RERUN"
        elif entry.get("id") == "F0-G1":
            effective = "CURRENT_BINDING_STALE"
            revalidation = "CURRENT_FULL_FUNCTIONAL_RERUN"
        else:
            effective = "CURRENT_BINDING_STALE"
            revalidation = "TRANSITIVE_CONE_REVIEW_THEN_REPLAY_OR_RERUN"
        if direct and entry.get("priority") == "P0":
            p0_direct.append(entry["id"])
        if direct and entry.get("priority") == "P1":
            p1_direct.append(entry["id"])
        audited.append(
            {
                "id": entry["id"],
                "priority": entry.get("priority"),
                "frozen_status": entry.get("status"),
                "frozen_design_id": entry.get("design_id"),
                "effective_current_status": effective,
                "revalidation_class": revalidation,
                "direct_changed_owner_paths": direct,
                "canonical_command": entry.get("canonical_command"),
            }
        )
    return audited, sorted(p0_direct), sorted(p1_direct)


def historical_audit(
    ledger: dict[str, Any], changed_paths: set[str]
) -> list[dict[str, Any]]:
    entries = ledger.get("entries")
    if not isinstance(entries, list) or not entries:
        raise ValueError("historical defect ledger has no entries")
    result: list[dict[str, Any]] = []
    for entry in entries:
        if not isinstance(entry, dict) or not isinstance(entry.get("id"), str):
            raise ValueError("malformed historical defect entry")
        owners = entry.get("owner_paths", [])
        if not isinstance(owners, list):
            raise ValueError(f"{entry['id']}: malformed owner_paths")
        direct = sorted(set(owners) & changed_paths)
        result.append(
            {
                "id": entry["id"],
                "severity": entry.get("severity"),
                "frozen_status": entry.get("status"),
                "effective_current_status": "CURRENT_BINDING_STALE",
                "direct_changed_owner_paths": direct,
                "revalidation_class": (
                    "DIRECT_ACTIVE_CONE_RERUN"
                    if direct
                    else "TRANSITIVE_CONE_REVIEW_THEN_REPLAY_OR_RERUN"
                ),
            }
        )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True, type=pathlib.Path)
    args = parser.parse_args()
    output_dir = args.output_dir.resolve()
    expected_parent = (HERE / "evidence").resolve()
    if (
        output_dir.parent != expected_parent
        or not output_dir.name.startswith("section13-audit-")
        or not output_dir.name[len("section13-audit-"):].isdigit()
    ):
        raise ValueError(
            "output directory must be task-local evidence/section13-audit-N"
        )
    if output_dir.exists():
        raise ValueError("audit output directory already exists")
    output_dir.mkdir(parents=True)

    baseline_result = load(BASELINE_RESULT)
    current_result = load(CURRENT_RESULT)
    baseline_files = source_map(baseline_result, "baseline")
    current_files = source_map(current_result, "current")
    baseline_source_set = baseline_result["rtl_source_set"]
    current_source_set = current_result["rtl_source_set"]
    if baseline_source_set.get("design_id") != BASELINE_DESIGN_ID:
        raise ValueError("baseline architecture result design-id drift")
    if current_source_set.get("design_id") != CURRENT_DESIGN_ID:
        raise ValueError("current architecture result design-id drift")
    if set(baseline_files) != set(current_files):
        raise ValueError("RTL source inventory changed; path-level audit required")
    live_mismatches = validate_live_source_map(current_files)
    if live_mismatches:
        raise ValueError(f"live RTL drift after current result: {live_mismatches}")
    changed = {
        path: {"baseline_sha256": baseline_files[path],
               "current_sha256": current_files[path]}
        for path in sorted(current_files)
        if baseline_files[path] != current_files[path]
    }
    if not changed:
        raise ValueError("expected a non-empty current RTL delta")
    changed_paths = set(changed)

    directed_replay = load(DIRECTED_REPLAY)
    directed_status = directed_replay.get("directed_nine_gate_status")
    if directed_status != "GREEN":
        raise ValueError("current directed nine-gate replay is not GREEN")
    if directed_replay.get("production_core_rtl_id") != CURRENT_DESIGN_ID:
        raise ValueError("directed replay current design-id drift")
    if directed_replay.get("negative_fixtures", {}).get("detected") != 4:
        raise ValueError("directed replay negative fixture count is incomplete")

    debt = load(DEBT_LEDGER)
    historical = load(HISTORICAL_LEDGER)
    census = load(HOLDER_CENSUS)
    holder_semantic = load(HOLDER_SEMANTIC)
    functional = load(FUNCTIONAL_AGGREGATE)
    functional_result = load(FUNCTIONAL_RESULT)
    stable_candidate = load(ARCH_STABLE_CANDIDATE)
    stable_result = load(ARCH_STABLE_RESULT)

    debt_entries, p0_direct, p1_direct = debt_audit(debt, changed_paths)
    historical_entries = historical_audit(historical, changed_paths)
    debt_current_stale = [
        entry["id"] for entry in debt_entries
        if entry["effective_current_status"] == "CURRENT_BINDING_STALE"
    ]
    p0_current_stale = [
        entry["id"] for entry in debt_entries
        if entry["priority"] == "P0"
        and entry["effective_current_status"] == "CURRENT_BINDING_STALE"
    ]
    p1_current_stale = [
        entry["id"] for entry in debt_entries
        if entry["priority"] == "P1"
        and entry["effective_current_status"] == "CURRENT_BINDING_STALE"
    ]

    holder_status = holder_semantic.get("status")
    functional_current = (
        functional.get("design_id") == CURRENT_DESIGN_ID
        and functional_result.get("design_id") == CURRENT_DESIGN_ID
        and functional_result.get("status") == "PASS"
    )
    freeze_inventory = stable_candidate.get("artifacts", {}).get(
        "cohort_inventory"
    )
    freeze_groups = stable_candidate.get("freeze_inputs", {})
    empty_freeze_groups = sorted(
        name for name, values in freeze_groups.items()
        if not isinstance(values, list) or not values
    )

    blockers = [
        {
            "blocker_id": "SECTION13-P0-CURRENT-BINDING",
            "status": "RED",
            "detail": f"{len(p0_current_stale)} P0 entries are not current-bound",
            "items": sorted(p0_current_stale),
        },
        {
            "blocker_id": "SECTION13-P1-CURRENT-BINDING",
            "status": "RED",
            "detail": f"{len(p1_current_stale)} in-cohort P1 entries are not current-bound",
            "items": sorted(p1_current_stale),
        },
        {
            "blocker_id": "SECTION13-HISTORICAL-BACKFILL-CURRENT-BINDING",
            "status": "RED",
            "detail": "historical backfill ledger is frozen on an older design-id",
            "items": sorted(entry["id"] for entry in historical_entries),
        },
        {
            "blocker_id": "SECTION13-HOLDER-SEMANTIC-COVERAGE",
            "status": "GREEN" if holder_status == "GREEN" else "RED",
            "detail": f"producer/holder semantic coverage status={holder_status}",
            "items": [],
        },
        {
            "blocker_id": "SECTION13-FUNCTIONAL-CURRENT-AGGREGATE",
            "status": "GREEN" if functional_current else "RED",
            "detail": (
                "functional aggregate is current and PASS"
                if functional_current
                else "functional aggregate/result are frozen on an older design-id"
            ),
            "items": [],
        },
        {
            "blocker_id": "SECTION13-FREEZE-INPUT-INVENTORY",
            "status": "GREEN"
            if freeze_inventory and not empty_freeze_groups else "RED",
            "detail": (
                f"cohort_inventory={freeze_inventory!r}; "
                f"empty_groups={len(empty_freeze_groups)}"
            ),
            "items": empty_freeze_groups,
        },
        {
            "blocker_id": "SECTION13-ARCH-STABLE",
            "status": "GREEN"
            if stable_result.get("architecture_freeze") == "GREEN" else "RED",
            "detail": (
                f"frozen result design_id={stable_result.get('design_id')} "
                f"architecture_freeze={stable_result.get('architecture_freeze')}"
            ),
            "items": [],
        },
    ]

    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    result = {
        "schema": "rv64-v14b-section13-current-audit-v1",
        "generated_at_utc": generated_at,
        "audit_execution_status": "PASS",
        "current_design_id": CURRENT_DESIGN_ID,
        "architecture_gate_state": "RED",
        "arch_stable": False,
        "ppa_state": "BLOCKED_BY_ARCHITECTURE",
        "promotion_eligible": False,
        "directed_nine_gate": {
            "status": "GREEN_REPLAY",
            "negative_fixtures": "4/4",
            "dut_rerun": False,
            "receipt": artifact(DIRECTED_REPLAY),
        },
        "rtl_delta": {
            "baseline_design_id": BASELINE_DESIGN_ID,
            "current_design_id": CURRENT_DESIGN_ID,
            "inventory_equal": True,
            "file_count": len(current_files),
            "changed_file_count": len(changed),
            "changed_files": changed,
            "baseline_result": artifact(BASELINE_RESULT),
            "current_result": artifact(CURRENT_RESULT),
            "live_source_map_matches_current_result": True,
        },
        "architecture_debt": {
            "frozen_ledger_design_id": debt.get("design_id"),
            "frozen_status_counts": count_by(debt["entries"], "status"),
            "current_stale_count": len(debt_current_stale),
            "p0_current_stale": sorted(p0_current_stale),
            "p1_current_stale": sorted(p1_current_stale),
            "p0_direct_active_cone": p0_direct,
            "p1_direct_active_cone": p1_direct,
            "entries": debt_entries,
            "ledger": artifact(DEBT_LEDGER),
            "canonical_ledger_written": False,
        },
        "historical_defect_backfill": {
            "frozen_ledger_design_id": historical.get("design_id"),
            "blocking_depths": historical.get("blocking_depths"),
            "entries": historical_entries,
            "ledger": artifact(HISTORICAL_LEDGER),
            "canonical_ledger_written": False,
        },
        "holder_contract": {
            "census_design_id": census.get("design_id"),
            "semantic_design_id": holder_semantic.get("design_id"),
            "semantic_status": holder_status,
            "census": artifact(HOLDER_CENSUS),
            "semantic_coverage": artifact(HOLDER_SEMANTIC),
        },
        "functional_aggregate": {
            "current_bound": functional_current,
            "aggregate_design_id": functional.get("design_id"),
            "result_design_id": functional_result.get("design_id"),
            "result_status": functional_result.get("status"),
            "aggregate": artifact(FUNCTIONAL_AGGREGATE),
            "result": artifact(FUNCTIONAL_RESULT),
        },
        "freeze": {
            "candidate_design_id": stable_candidate.get("design_id"),
            "result_design_id": stable_result.get("design_id"),
            "cohort_inventory": freeze_inventory,
            "empty_input_groups": empty_freeze_groups,
            "architecture_freeze": stable_result.get("architecture_freeze"),
            "ppa": stable_result.get("ppa"),
            "candidate": artifact(ARCH_STABLE_CANDIDATE),
            "result": artifact(ARCH_STABLE_RESULT),
        },
        "blockers": blockers,
        "next_action": {
            "action_id": "P0-DIRECT-ACTIVE-CONE-REBIND",
            "debt_ids": p0_direct,
            "required_claims": [
                "current design-id",
                "positive directed RTL observation",
                "compile-success RTL counterexample rejection",
                "assertion-clean terminal marker",
                "source pre/post identity",
            ],
            "reason": (
                "MEM-ISSUE-G1 and PTW-PMP-G1 directly name changed production "
                "RTL; resolving them discriminates semantic regression from "
                "binding-only staleness before broader replay."
            ),
        },
        "write_boundary": {
            "production_rtl_written": False,
            "canonical_architecture_written": False,
            "canonical_debt_ledger_written": False,
            "canonical_historical_ledger_written": False,
            "task_local_output_only": True,
            "canonical_architecture": artifact(CANONICAL_ARCHITECTURE),
        },
    }
    if p0_direct != ["MEM-ISSUE-G1", "PTW-PMP-G1"]:
        raise ValueError(f"unexpected P0 direct active-cone set: {p0_direct}")
    if any(item["status"] != "RED" for item in blockers):
        raise ValueError("Section-13 blocker matrix unexpectedly contains GREEN")

    output = output_dir / "section13-audit.json"
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    summary = output_dir / "blocker-matrix.txt"
    summary.write_text(
        "\n".join(
            f"{item['status']} {item['blocker_id']} {item['detail']}"
            for item in blockers
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        "[V14B-SECTION13-AUDIT][PASS] "
        f"design_id={CURRENT_DESIGN_ID} rtl_delta={len(changed)} "
        f"directed=GREEN_REPLAY p0_stale={len(p0_current_stale)} "
        f"p1_stale={len(p1_current_stale)} blockers={len(blockers)} "
        "architecture=RED arch_stable=0 ppa=BLOCKED "
        f"next={','.join(p0_direct)}"
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
        print(f"[V14B-SECTION13-AUDIT][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
