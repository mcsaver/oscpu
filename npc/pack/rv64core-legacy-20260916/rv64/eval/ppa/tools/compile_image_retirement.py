#!/usr/bin/env python3
"""Retire reproducible task-run .vvp images with a hash-bound receipt."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from typing import Any


SCHEMA = "rv64-task-run-compile-image-retirement-v2"
RECEIPT_SCHEMA = "rv64-task-run-compile-image-retirement-receipt-v1"


class RetirementError(RuntimeError):
    """Raised when a compile-image retirement is unsafe or incomplete."""


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def repo_path(root: pathlib.Path, value: str | pathlib.Path) -> pathlib.Path:
    path = pathlib.Path(value)
    if not path.is_absolute():
        path = root / path
    path = path.resolve()
    try:
        path.relative_to(root)
    except ValueError as exc:
        raise RetirementError(f"path escapes repository root: {value}") from exc
    return path


def relative(root: pathlib.Path, path: pathlib.Path) -> str:
    return path.resolve().relative_to(root).as_posix()


def task_run_scope(root: pathlib.Path, value: str | pathlib.Path) -> pathlib.Path:
    scope = repo_path(root, value)
    task_runs = (root / ".github/task-runs").resolve()
    try:
        remainder = scope.relative_to(task_runs)
    except ValueError as exc:
        raise RetirementError("scope is outside .github/task-runs") from exc
    if len(remainder.parts) != 1 or not scope.is_dir() or scope.is_symlink():
        raise RetirementError("scope must be one concrete task-run directory")
    return scope


def entry_digest(entries: list[dict[str, Any]]) -> str:
    lines = [
        f"{item['sha256']}  {item['size_bytes']}  {item['path']}\n"
        for item in entries
    ]
    return hashlib.sha256("".join(lines).encode()).hexdigest()


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RetirementError(f"cannot read manifest {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise RetirementError("manifest root is not an object")
    return payload


def load_json_value(path: pathlib.Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RetirementError(f"cannot read JSON evidence {path}: {exc}") from exc


def build_preview(root: pathlib.Path, scope: pathlib.Path) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    for path in sorted(scope.rglob("*.vvp")):
        if not path.is_file() or path.is_symlink():
            raise RetirementError(f"unsafe compile image: {relative(root, path)}")
        entries.append(
            {
                "path": relative(root, path),
                "sha256": sha256_file(path),
                "size_bytes": path.stat().st_size,
            }
        )
    if not entries:
        raise RetirementError("scope contains no .vvp compile images")
    return {
        "schema_version": SCHEMA,
        "status": "PLANNED",
        "scope_root": relative(root, scope),
        "retired_suffix": ".vvp",
        "selection": "all-reproducible-compile-images-in-one-task-run",
        "entry_count": len(entries),
        "total_size_bytes": sum(item["size_bytes"] for item in entries),
        "entry_path_sha256": entry_digest(entries),
        "entries": entries,
    }


def validate_manifest(
    root: pathlib.Path, payload: dict[str, Any], *, require_pass: bool
) -> tuple[pathlib.Path, list[dict[str, Any]]]:
    allowed_status = {"PASS"} if require_pass else {"PLANNED", "PASS"}
    entries = payload.get("entries")
    if (
        payload.get("schema_version") != SCHEMA
        or payload.get("status") not in allowed_status
        or payload.get("retired_suffix") != ".vvp"
        or payload.get("selection")
        != "all-reproducible-compile-images-in-one-task-run"
        or not isinstance(entries, list)
        or not entries
        or payload.get("entry_count") != len(entries)
    ):
        raise RetirementError("compile-image manifest header is invalid")
    scope = task_run_scope(root, payload.get("scope_root", ""))
    seen: set[str] = set()
    total = 0
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != {
            "path", "sha256", "size_bytes"
        }:
            raise RetirementError("compile-image manifest entry is malformed")
        path_value = entry.get("path")
        digest = entry.get("sha256")
        size = entry.get("size_bytes")
        if (
            not isinstance(path_value, str)
            or path_value in seen
            or not path_value.endswith(".vvp")
            or re.fullmatch(r"[0-9a-f]{64}", str(digest)) is None
            or not isinstance(size, int)
            or size <= 0
        ):
            raise RetirementError("compile-image manifest entry is invalid")
        path = repo_path(root, path_value)
        try:
            path.relative_to(scope)
        except ValueError as exc:
            raise RetirementError("compile image escapes task-run scope") from exc
        seen.add(path_value)
        total += size
    if (
        payload.get("total_size_bytes") != total
        or payload.get("entry_path_sha256") != entry_digest(entries)
    ):
        raise RetirementError("compile-image manifest aggregate is invalid")
    return scope, entries


def apply_retirement(
    root: pathlib.Path, manifest_path: pathlib.Path, receipt_path: pathlib.Path
) -> dict[str, Any]:
    payload = load_json(manifest_path)
    scope, entries = validate_manifest(root, payload, require_pass=False)
    for entry in entries:
        path = repo_path(root, entry["path"])
        if path.exists() and (
            not path.is_file()
            or path.is_symlink()
            or path.stat().st_size != entry["size_bytes"]
            or sha256_file(path) != entry["sha256"]
        ):
            raise RetirementError(f"compile image drifted: {entry['path']}")
    for entry in entries:
        path = repo_path(root, entry["path"])
        if path.exists():
            path.unlink()
    payload["status"] = "PASS"
    write_json(manifest_path, payload)
    verify_retirement(root, payload)
    receipt = {
        "schema_version": RECEIPT_SCHEMA,
        "status": "PASS",
        "scope_root": relative(root, scope),
        "manifest": {
            "path": relative(root, manifest_path),
            "sha256": sha256_file(manifest_path),
            "size_bytes": manifest_path.stat().st_size,
        },
        "retired_count": len(entries),
        "retired_size_bytes": payload["total_size_bytes"],
        "retained_evidence": "logs-json-source-hashes-and-result-markers",
    }
    write_json(receipt_path, receipt)
    return receipt


def verify_retirement(root: pathlib.Path, payload: dict[str, Any]) -> None:
    _, entries = validate_manifest(root, payload, require_pass=True)
    present = [entry["path"] for entry in entries if repo_path(root, entry["path"]).exists()]
    if present:
        raise RetirementError(f"retired compile image still exists: {present[0]}")


def iter_objects(value: Any):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from iter_objects(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_objects(child)


def build_reference_audit(
    root: pathlib.Path,
    manifest_path: pathlib.Path,
    output_path: pathlib.Path,
) -> dict[str, Any]:
    payload = load_json(manifest_path)
    scope, entries = validate_manifest(root, payload, require_pass=True)
    verify_retirement(root, payload)
    manifest_by_path = {entry["path"]: entry for entry in entries}
    references: dict[str, dict[str, Any]] = {}
    json_count = 0
    for json_path in sorted(scope.rglob("*.json")):
        if json_path in {manifest_path, output_path}:
            continue
        if not json_path.is_file() or json_path.is_symlink():
            raise RetirementError(
                f"unsafe JSON evidence path: {relative(root, json_path)}"
            )
        document = load_json_value(json_path)
        json_count += 1
        for record in iter_objects(document):
            path_value = record.get("path")
            digest = record.get("sha256")
            size = record.get("size_bytes")
            if not isinstance(path_value, str) or not path_value.endswith(".vvp"):
                path_value = record.get("artifact")
                digest = record.get("artifact_sha256")
                size = None
            if not isinstance(path_value, str) or not path_value.endswith(".vvp"):
                continue
            candidate = {
                "path": path_value,
                "sha256": digest,
                "size_bytes": size,
            }
            previous = references.get(path_value)
            if previous is not None:
                if (
                    previous["sha256"] != candidate["sha256"]
                    or (
                        previous["size_bytes"] is not None
                        and candidate["size_bytes"] is not None
                        and previous["size_bytes"] != candidate["size_bytes"]
                    )
                ):
                    raise RetirementError(
                        f"conflicting compile-image reference: {path_value}"
                    )
                if previous["size_bytes"] is None:
                    references[path_value] = candidate
            else:
                references[path_value] = candidate
    missing = sorted(set(manifest_by_path) - set(references))
    extra = sorted(set(references) - set(manifest_by_path))
    mismatched = sorted(
        path for path in set(references) & set(manifest_by_path)
        if (
            references[path]["sha256"] != manifest_by_path[path]["sha256"]
            or (
                references[path]["size_bytes"] is not None
                and references[path]["size_bytes"]
                != manifest_by_path[path]["size_bytes"]
            )
        )
    )
    status = "PASS" if not (missing or mismatched) else "GAP"
    return {
        "schema_version": (
            "rv64-task-run-compile-image-reference-closure-v1"
        ),
        "status": status,
        "scope_root": relative(root, scope),
        "manifest": {
            "path": relative(root, manifest_path),
            "sha256": sha256_file(manifest_path),
            "size_bytes": manifest_path.stat().st_size,
        },
        "json_documents_scanned": json_count,
        "manifest_entry_count": len(manifest_by_path),
        "referenced_entry_count": len(references),
        "matched_manifest_entry_count": len(
            set(references) & set(manifest_by_path)
        ),
        "missing_reference_count": len(missing),
        "extra_reference_count": len(extra),
        "mismatched_reference_count": len(mismatched),
        "missing_references": missing,
        "extra_references": extra,
        "mismatched_references": mismatched,
        "claim_boundary": (
            "Every VVP retired by this manifest has an exact path/SHA "
            "reference in retained JSON evidence and an exact size in the "
            "manifest; additional references may belong to independent "
            "per-run cleanup receipts. Per-profile compile configuration, "
            "logs and result markers remain validated by their schema-"
            "specific checker."
        ),
    }


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root", type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5],
    )
    commands = result.add_subparsers(dest="command", required=True)
    preview = commands.add_parser("preview")
    preview.add_argument("--scope", required=True)
    preview.add_argument("--output", required=True)
    apply = commands.add_parser("apply")
    apply.add_argument("--manifest", required=True)
    apply.add_argument("--receipt", required=True)
    verify = commands.add_parser("verify")
    verify.add_argument("--manifest", required=True)
    audit = commands.add_parser("audit-references")
    audit.add_argument("--manifest", required=True)
    audit.add_argument("--output", required=True)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    if args.command == "preview":
        scope = task_run_scope(root, args.scope)
        output = repo_path(root, args.output)
        try:
            output.relative_to(scope)
        except ValueError as exc:
            raise RetirementError("preview manifest must remain in its task-run") from exc
        payload = build_preview(root, scope)
        write_json(output, payload)
        print(
            "[COMPILE-IMAGE-RETIREMENT][PREVIEW] "
            f"count={payload['entry_count']} bytes={payload['total_size_bytes']}"
        )
    elif args.command == "apply":
        manifest = repo_path(root, args.manifest)
        receipt = repo_path(root, args.receipt)
        result = apply_retirement(root, manifest, receipt)
        print(
            "[COMPILE-IMAGE-RETIREMENT][PASS] "
            f"count={result['retired_count']} bytes={result['retired_size_bytes']}"
        )
    elif args.command == "verify":
        manifest = repo_path(root, args.manifest)
        verify_retirement(root, load_json(manifest))
        print("[COMPILE-IMAGE-RETIREMENT][PASS] manifest verified")
    else:
        manifest = repo_path(root, args.manifest)
        output = repo_path(root, args.output)
        result = build_reference_audit(root, manifest, output)
        write_json(output, result)
        if result["status"] != "PASS":
            raise RetirementError(
                "retired compile-image reference closure is incomplete"
            )
        print(
            "[COMPILE-IMAGE-RETIREMENT][PASS] "
            f"reference_closure={result['matched_manifest_entry_count']}"
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RetirementError as exc:
        print(f"[COMPILE-IMAGE-RETIREMENT][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
