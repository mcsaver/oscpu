#!/usr/bin/env python3
"""Read-only inventory and claim-map checks for the research paper.

The script deliberately does not edit task-runs, the evidence database, or the
paper.  It reports filesystem facts to stdout so that directory counts are not
mistaken for independent experiments or successful engineering tasks.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path


RUN_DATE_RE = re.compile(r"^(?P<date>20\d{2}-\d{2}-\d{2})(?:-|$)")
ALLOWED_STATUSES = {
    "SUPPORTED",
    "PARTIALLY_SUPPORTED",
    "OBSERVATIONAL_ONLY",
    "CONTRADICTED",
    "MISSING",
}
REQUIRED_COLUMNS = {
    "claim_id",
    "claim_text",
    "research_axis",
    "evidence_status",
    "source_path",
    "raw_evidence_path",
    "claim_boundary",
    "paper_section",
}


def repository_root() -> Path:
    # .../docs/research-paper/scripts/paper_evidence_extract.py -> repository
    return Path(__file__).resolve().parents[3]


def run_inventory(repo: Path) -> dict[str, object]:
    task_runs = repo / ".github" / "task-runs"
    months: dict[str, Counter[str]] = defaultdict(Counter)
    dated_runs = 0
    undated_runs = 0

    for entry in sorted(task_runs.iterdir() if task_runs.is_dir() else []):
        if not entry.is_dir():
            continue
        match = RUN_DATE_RE.match(entry.name)
        if match is None:
            undated_runs += 1
            continue

        dated_runs += 1
        month = match.group("date")[:7]
        row = months[month]
        row["workflow_event_directories"] += 1
        row["task_report"] += int((entry / "task-report.md").is_file())
        row["legacy_report"] += int((entry / "report.md").is_file())
        row["run_manifest"] += int((entry / "run-manifest.json").is_file())
        row["complete_marker"] += int((entry / "complete.marker").is_file())
        row["completion_publication"] += int(
            (entry / "completion-publication.md").is_file()
        )
        row["evidence_index"] += int((entry / "evidence-index.md").is_file())

    selected = {}
    for month in ("2026-04", "2026-05", "2026-06", "2026-07"):
        selected[month] = dict(sorted(months.get(month, Counter()).items()))

    return {
        "schema": "paper-task-run-inventory-v1",
        "repository": str(repo),
        "counting_boundary": (
            "One top-level dated directory is one workflow-event directory. "
            "It is not an independent task, successful run, experiment, or "
            "measure of productivity."
        ),
        "dated_workflow_event_directories_all_time": dated_runs,
        "undated_directories": undated_runs,
        "selected_months": selected,
    }


def resolve_repo_path(repo: Path, value: str) -> tuple[bool | None, str]:
    value = value.strip()
    if not value or value in {"-", "N/A"}:
        return None, ""
    # A field may contain alternatives separated by " | ".  Every declared
    # path is checked, which keeps missing raw evidence visible.
    failures = []
    for item in (part.strip() for part in value.split(" | ")):
        candidate = (repo / item).resolve()
        try:
            candidate.relative_to(repo.resolve())
        except ValueError:
            failures.append(f"outside-repository:{item}")
            continue
        if not candidate.exists():
            failures.append(f"missing:{item}")
    return not failures, ";".join(failures)


def verify_claim_map(repo: Path, path: Path) -> dict[str, object]:
    errors: list[str] = []
    warnings: list[str] = []
    status_counts: Counter[str] = Counter()
    seen_ids: set[str] = set()
    rows = 0

    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        fields = set(reader.fieldnames or [])
        missing_columns = sorted(REQUIRED_COLUMNS - fields)
        if missing_columns:
            errors.append("missing_columns:" + ",".join(missing_columns))

        for line_number, row in enumerate(reader, start=2):
            rows += 1
            claim_id = (row.get("claim_id") or "").strip()
            if not claim_id:
                errors.append(f"line_{line_number}:empty_claim_id")
            elif claim_id in seen_ids:
                errors.append(f"line_{line_number}:duplicate_claim_id:{claim_id}")
            seen_ids.add(claim_id)

            status = (row.get("evidence_status") or "").strip()
            status_counts[status] += 1
            if status not in ALLOWED_STATUSES:
                errors.append(
                    f"line_{line_number}:invalid_evidence_status:{status}"
                )

            for field in ("source_path", "raw_evidence_path"):
                exists, detail = resolve_repo_path(repo, row.get(field) or "")
                if exists is False:
                    warnings.append(
                        f"line_{line_number}:{claim_id}:{field}:{detail}"
                    )

            if not (row.get("claim_boundary") or "").strip():
                errors.append(f"line_{line_number}:{claim_id}:empty_claim_boundary")

    return {
        "schema": "paper-claim-map-check-v1",
        "claim_map": str(path),
        "rows": rows,
        "status_counts": dict(sorted(status_counts.items())),
        "errors": errors,
        "path_warnings": warnings,
        "ok": not errors,
        "note": (
            "A path warning records missing or external material but does not "
            "upgrade or downgrade a research claim automatically."
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=repository_root(),
        help="repository root (default: inferred from this script)",
    )
    parser.add_argument(
        "--verify-claims",
        type=Path,
        help="optional TSV claim-evidence map to validate",
    )
    args = parser.parse_args()

    repo = args.repo_root.resolve()
    result: dict[str, object] = {"inventory": run_inventory(repo)}
    if args.verify_claims is not None:
        claim_map = args.verify_claims
        if not claim_map.is_absolute():
            claim_map = repo / claim_map
        result["claim_map_check"] = verify_claim_map(repo, claim_map.resolve())

    json.dump(result, sys.stdout, ensure_ascii=False, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    claim_check = result.get("claim_map_check")
    if isinstance(claim_check, dict) and not claim_check.get("ok", False):
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
