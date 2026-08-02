#!/usr/bin/env python3
"""Validate and compact full-functional evidence to results and bounded logs."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any, Iterator


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DESIGN_ID = "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def load(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise RuntimeError(f"JSON root is not an object: {path}")
    return value


def artifact(path: pathlib.Path) -> dict[str, object]:
    resolved = path.resolve(strict=True)
    resolved.relative_to(ROOT)
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def verify_record(record: Any, functional: pathlib.Path, kind: str) -> pathlib.Path:
    if not isinstance(record, dict) or record.get("kind") != kind:
        raise RuntimeError(f"invalid {kind} artifact record")
    path = (ROOT / str(record.get("path"))).resolve(strict=True)
    path.relative_to(functional)
    if digest(path) != record.get("sha256"):
        raise RuntimeError(f"{kind} hash drift: {path}")
    if "size_bytes" in record and path.stat().st_size != record.get("size_bytes"):
        raise RuntimeError(f"{kind} size drift: {path}")
    return path


def iter_kind(value: Any, kind: str) -> Iterator[dict[str, Any]]:
    if isinstance(value, dict):
        if value.get("kind") == kind and "path" in value and "sha256" in value:
            yield value
        for child in value.values():
            yield from iter_kind(child, kind)
    elif isinstance(value, list):
        for child in value:
            yield from iter_kind(child, kind)


def remove_empty_dirs(root: pathlib.Path) -> None:
    if not root.exists():
        return
    for path in sorted(
        (candidate for candidate in root.rglob("*") if candidate.is_dir()),
        key=lambda candidate: len(candidate.parts),
        reverse=True,
    ):
        path.rmdir()
    root.rmdir()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--functional-dir", required=True, type=pathlib.Path)
    args = parser.parse_args()
    functional = args.functional_dir.resolve(strict=True)
    functional.relative_to(HERE / "evidence")
    pre_path = functional / "pre-compaction-artifacts.json"
    post_path = functional / "post-compaction.json"
    if pre_path.exists() or post_path.exists():
        raise RuntimeError("refusing to repeat F0 functional compaction")

    run_result_path = functional / "run-result.json"
    aggregate_path = functional / "functional-aggregate.json"
    aggregate_result_path = functional / "functional-aggregate-result.json"
    descriptor_path = functional / "functional-run-descriptor.json"
    run_result = load(run_result_path)
    aggregate = load(aggregate_path)
    aggregate_result = load(aggregate_result_path)
    descriptor = load(descriptor_path)
    counts = run_result.get("counts")
    if (
        run_result.get("schema") != "npc-rv64-full-core-functional-current-evidence-v1"
        or run_result.get("status") != "PASS"
        or run_result.get("design_id") != DESIGN_ID
        or run_result.get("inputs_unchanged") is not True
        or aggregate.get("design_id") != DESIGN_ID
        or aggregate_result.get("status") != "PASS"
        or aggregate_result.get("exit_code") != 0
        or aggregate_result.get("design_id") != DESIGN_ID
        or aggregate_result.get("counts") != counts
        or descriptor.get("design_id") != DESIGN_ID
        or not isinstance(counts, dict)
        or counts.get("official_required") != 177
        or counts.get("official_passed") != 177
        or counts.get("am_required") != 61
        or counts.get("am_passed") != 61
        or counts.get("difftest_mismatches") != 0
        or counts.get("module_required") != counts.get("module_passed")
        or int(counts.get("module_required", 0)) < 113
        or counts.get("evidence_mutations_compiled") != counts.get("evidence_mutations_rejected")
        or int(counts.get("evidence_mutations_compiled", 0)) < 11
    ):
        raise RuntimeError("full-functional result contract drift")

    artifacts = run_result.get("artifacts")
    if not isinstance(artifacts, dict):
        raise RuntimeError("full-functional artifact inventory absent")
    simulator = verify_record(artifacts.get("simulator"), functional, "simulator_binary")
    reference = verify_record(artifacts.get("reference"), functional, "reference_model_binary")
    configuration = verify_record(artifacts.get("configuration"), functional, "kconfig")
    verify_record(artifacts.get("aggregate"), functional, "functional_aggregate")
    verify_record(artifacts.get("aggregate_result"), functional, "functional_aggregate_result")
    verify_record(artifacts.get("aggregate_log"), functional, "functional_aggregate_log")

    image_records: list[dict[str, Any]] = []
    seen_images: set[pathlib.Path] = set()
    for record in iter_kind(aggregate, "program_image"):
        path = verify_record(record, functional, "program_image")
        path.relative_to(functional / "images")
        if path in seen_images:
            raise RuntimeError(f"duplicate program-image path: {path}")
        seen_images.add(path)
        image_records.append(dict(record))
    expected_images = int(run_result.get("retention", {}).get("program_images_retained", -1))
    if len(image_records) != expected_images or expected_images != 240:
        raise RuntimeError(
            f"program-image inventory drift: observed={len(image_records)} expected={expected_images}"
        )

    pre_receipt = {
        "schema": "rv64-v14e-f0-functional-pre-compaction-v1",
        "status": "PASS",
        "current_design_id": DESIGN_ID,
        "policy": "retain structured results, source/input bindings and bounded logs; remove reproducible simulator/reference/program binaries",
        "run_result": artifact(run_result_path),
        "aggregate": artifact(aggregate_path),
        "aggregate_result": artifact(aggregate_result_path),
        "descriptor": artifact(descriptor_path),
        "configuration_retained": artifact(configuration),
        "removed": {
            "simulator": dict(artifacts["simulator"]),
            "reference": dict(artifacts["reference"]),
            "program_images": sorted(image_records, key=lambda row: str(row["path"])),
        },
        "removed_counts": {
            "simulator": 1,
            "reference": 1,
            "program_images": len(image_records),
        },
    }
    pre_path.write_text(json.dumps(pre_receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    for path in sorted(seen_images):
        path.unlink()
    simulator.unlink()
    reference.unlink()
    remove_empty_dirs(functional / "images")
    forbidden = [
        path
        for path in functional.rglob("*")
        if path.is_file()
        and (path.suffix.lower() in {".bin", ".so", ".o", ".vvp"} or path.name == "NpcSimTop")
    ]
    if forbidden:
        raise RuntimeError(f"reproducible functional artifacts remain: {forbidden[:3]}")

    retained_logs = sorted(path for path in functional.rglob("*.log") if path.is_file())
    post_receipt = {
        "schema": "rv64-v14e-f0-functional-post-compaction-v1",
        "status": "PASS",
        "current_design_id": DESIGN_ID,
        "pre_compaction_receipt": artifact(pre_path),
        "removed_counts": pre_receipt["removed_counts"],
        "retained": {
            "structured_results": [
                artifact(run_result_path),
                artifact(aggregate_path),
                artifact(aggregate_result_path),
                artifact(descriptor_path),
            ],
            "configuration": artifact(configuration),
            "log_files": len(retained_logs),
        },
        "reproducible_binary_products_retained": 0,
        "standalone_binary_replay_available": False,
        "rebuild_binding_available": True,
    }
    post_path.write_text(json.dumps(post_receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        "[V14E-F0-COMPACT][PASS] program_images_removed=240 simulator_removed=1 "
        f"reference_removed=1 logs_retained={len(retained_logs)} binary_products_retained=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14E-F0-COMPACT][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
