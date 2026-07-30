#!/usr/bin/env python3
"""Audit the RV64 historical-defect validation-depth ledger."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any

import jsonschema


SCHEMA = "npc-rv64-historical-defect-backfill-ledger-v1"
LEDGER_PATH = pathlib.Path(
    "npc/rv64/design/arch/historical-defect-backfill-ledger.json"
)
SCHEMA_PATH = pathlib.Path(
    "npc/rv64/eval/ppa/schemas/"
    "historical-defect-backfill-ledger-v1.schema.json"
)
BLOCKING_DEPTHS = {"VD0", "VD1"}
DEPTH_ORDER = {"VD0": 0, "VD1": 1, "VD2": 2, "VD3": 3, "VD4": 4}


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"top-level JSON object required: {path}")
    return value


def validate_artifact(
    *,
    root: pathlib.Path,
    artifact: dict[str, Any],
    label: str,
    errors: list[str],
) -> None:
    relative = artifact.get("path")
    expected = artifact.get("sha256")
    if not isinstance(relative, str):
        errors.append(f"{label}: artifact path must be a string")
        return
    path = (root / relative).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError:
        errors.append(f"{label}: artifact escapes workspace: {relative}")
        return
    if not path.is_file():
        errors.append(f"{label}: artifact missing: {relative}")
        return
    if sha256_file(path) != expected:
        errors.append(f"{label}: artifact hash drifted: {relative}")


def audit(
    root: pathlib.Path,
    *,
    expected_design_id: str | None = None,
) -> dict[str, Any]:
    root = root.resolve()
    errors: list[str] = []
    ledger_path = root / LEDGER_PATH
    schema_path = root / SCHEMA_PATH
    try:
        ledger = load_json(ledger_path)
        schema = load_json(schema_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return {
            "schema": SCHEMA,
            "valid": False,
            "status": "INVALID",
            "errors": [str(exc)],
            "blocking_ids": [],
            "selected_id": None,
            "counts": {},
        }

    validator = jsonschema.Draft202012Validator(schema)
    for error in sorted(validator.iter_errors(ledger), key=lambda item: list(item.path)):
        location = ".".join(str(part) for part in error.path) or "<root>"
        errors.append(f"schema:{location}: {error.message}")

    if ledger.get("schema") != SCHEMA:
        errors.append(f"ledger schema must equal {SCHEMA}")
    if (
        expected_design_id is not None
        and ledger.get("design_id") != expected_design_id
    ):
        errors.append(
            "ledger design_id does not match the current architecture candidate"
        )

    entries = ledger.get("entries")
    entry_list = entries if isinstance(entries, list) else []
    ids: list[str] = []
    ranks: list[int] = []
    selected_entries: list[dict[str, Any]] = []
    blocking_entries: list[dict[str, Any]] = []
    depth_counts = {depth: 0 for depth in DEPTH_ORDER}
    status_counts = {
        "SELECTED": 0,
        "QUEUED": 0,
        "BACKFILLED": 0,
    }

    for index, entry in enumerate(entry_list):
        if not isinstance(entry, dict):
            continue
        defect_id = entry.get("id")
        rank = entry.get("priority_rank")
        depth = entry.get("validation_depth")
        status = entry.get("status")
        if isinstance(defect_id, str):
            ids.append(defect_id)
        if isinstance(rank, int):
            ranks.append(rank)
        if depth in depth_counts:
            depth_counts[depth] += 1
        if status in status_counts:
            status_counts[status] += 1
        if status == "SELECTED":
            selected_entries.append(entry)
        if depth in BLOCKING_DEPTHS:
            blocking_entries.append(entry)

        owners = entry.get("owner_paths")
        if isinstance(owners, list):
            for owner in owners:
                path = root / owner
                if not isinstance(owner, str) or not path.is_file():
                    errors.append(
                        f"entry[{index}].owner_paths missing regular file: {owner}"
                    )

        for field in ("source_artifacts", "current_evidence"):
            artifacts = entry.get(field)
            if not isinstance(artifacts, list):
                continue
            for artifact_index, artifact in enumerate(artifacts):
                if isinstance(artifact, dict):
                    validate_artifact(
                        root=root,
                        artifact=artifact,
                        label=f"{defect_id}.{field}[{artifact_index}]",
                        errors=errors,
                    )

        if status == "BACKFILLED":
            if depth in BLOCKING_DEPTHS:
                errors.append(
                    f"{defect_id}: BACKFILLED cannot retain {depth}")
            if not entry.get("current_evidence"):
                errors.append(
                    f"{defect_id}: BACKFILLED requires current evidence")
        if status == "SELECTED" and depth not in BLOCKING_DEPTHS:
            errors.append(
                f"{defect_id}: SELECTED must identify a VD0/VD1 blocker")

    if len(ids) != len(set(ids)):
        errors.append("entry ids must be unique")
    if len(ranks) != len(set(ranks)):
        errors.append("priority_rank values must be unique")
    selected_id = ledger.get("selected_id")
    if blocking_entries:
        if len(selected_entries) != 1:
            errors.append(
                "exactly one VD0/VD1 entry must have status SELECTED")
        elif len(selected_entries) == 1:
            selected = selected_entries[0]
            if selected.get("id") != selected_id:
                errors.append("selected_id does not match the SELECTED entry")
            best = min(
                blocking_entries,
                key=lambda entry: (
                    entry.get("priority_rank", sys.maxsize),
                    entry.get("id", ""),
                ),
            )
            if selected.get("id") != best.get("id"):
                errors.append(
                    "SELECTED is not the highest-priority VD0/VD1 entry")
    else:
        if selected_entries:
            errors.append(
                "SELECTED is forbidden after VD0/VD1 reaches zero")
        if selected_id != "NONE":
            errors.append(
                "selected_id must be NONE after VD0/VD1 reaches zero")

    blocking_ids = [
        str(entry.get("id"))
        for entry in sorted(
            blocking_entries,
            key=lambda item: (
                item.get("priority_rank", sys.maxsize),
                item.get("id", ""),
            ),
        )
    ]
    valid = not errors
    status = "INVALID" if not valid else ("GAP" if blocking_ids else "PASS")
    return {
        "schema": SCHEMA,
        "valid": valid,
        "status": status,
        "design_id": ledger.get("design_id"),
        "selected_id": selected_id,
        "blocking_ids": blocking_ids,
        "counts": {
            "entries": len(entry_list),
            "depths": depth_counts,
            "statuses": status_counts,
        },
        "errors": errors,
        "claim": {
            "architecture_freeze": "GAP" if blocking_ids else "ELIGIBLE_FOR_REVIEW",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5],
    )
    parser.add_argument("--expected-design-id")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--require-clear", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    result = audit(
        args.root,
        expected_design_id=args.expected_design_id,
    )
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(
            "[HISTORICAL-DEFECT-BACKFILL] "
            f"status={result['status']} "
            f"entries={result['counts'].get('entries', 0)} "
            f"blocking={','.join(result['blocking_ids']) or 'none'} "
            f"selected={result.get('selected_id') or 'none'} "
            "arch_stable="
            f"{result['claim']['architecture_freeze']} "
            "ppa=UNQUALIFIED"
        )
        for error in result["errors"]:
            print(f"[HISTORICAL-DEFECT-BACKFILL][INVALID] {error}", file=sys.stderr)
    if not result["valid"]:
        return 2
    if args.require_clear and result["status"] != "PASS":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
