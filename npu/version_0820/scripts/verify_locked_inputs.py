#!/usr/bin/env python3
"""Verify the project-local source and model input locks.

The verifier is intentionally self-contained and uses only the Python standard
library.  It never creates a cache or temporary file.  Paths in either lock are
interpreted relative to the project root (the parent of this script's
directory), and both lexical traversal and symlink traversal outside that root
are rejected.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import stat
import sys
from pathlib import Path, PurePosixPath, PureWindowsPath
from typing import Any, Iterable, Mapping, Sequence


HASH_CHUNK_BYTES = 4 * 1024 * 1024
SHA256_HEX_LENGTH = 64

SOURCE_LOCK_RELATIVE_PATH = "third_party/SOURCES.lock.json"
MODEL_LOCK_RELATIVE_PATH = "models/MODELS.lock.json"

SOURCE_TOP_LEVEL_KEYS = frozenset({"schema_version", "sources"})
MODEL_TOP_LEVEL_KEYS = frozenset({"schema_version", "models"})

SOURCE_REQUIRED_KEYS = frozenset(
    {"name", "upstream", "source_directory", "license"}
)
SOURCE_OPTIONAL_KEYS = frozenset(
    {
        "tag",
        "commit",
        "version",
        "archive",
        "archive_sha256",
        "license_file",
    }
)
SOURCE_ALLOWED_KEYS = SOURCE_REQUIRED_KEYS | SOURCE_OPTIONAL_KEYS

MODEL_REQUIRED_KEYS = frozenset(
    {
        "name",
        "repository",
        "revision",
        "path",
        "size_bytes",
        "sha256",
        "format",
        "license_note",
    }
)
MODEL_ALLOWED_KEYS = MODEL_REQUIRED_KEYS


class LockValidationError(Exception):
    """An expected, user-facing lock validation failure."""


def _quoted(value: Any) -> str:
    """Return a deterministic, single-line representation for a marker field."""

    return json.dumps(value, ensure_ascii=True, separators=(",", ":"))


def _emit_failure(kind: str, name: str, issues: Sequence[str]) -> None:
    print(
        "[LOCK][FAIL]"
        f" kind={kind} name={_quoted(name)} issues={_quoted(list(issues))}",
        file=sys.stderr,
    )


def _is_nonempty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def _validate_exact_keys(
    obj: Mapping[str, Any],
    *,
    required: frozenset[str],
    allowed: frozenset[str],
) -> list[str]:
    issues: list[str] = []
    actual = set(obj)
    missing = sorted(required - actual)
    unknown = sorted(actual - allowed)
    if missing:
        issues.append(f"missing fields: {', '.join(missing)}")
    if unknown:
        issues.append(f"unknown fields: {', '.join(unknown)}")
    return issues


def _validate_string_fields(
    obj: Mapping[str, Any], fields: Iterable[str]
) -> list[str]:
    issues: list[str] = []
    for field in fields:
        if field in obj and not _is_nonempty_string(obj[field]):
            issues.append(f"{field} must be a non-empty string")
    return issues


def _validate_sha256(value: Any, field: str) -> tuple[str | None, list[str]]:
    if not isinstance(value, str):
        return None, [f"{field} must be a 64-character hexadecimal string"]
    normalized = value.lower()
    if len(normalized) != SHA256_HEX_LENGTH:
        return None, [f"{field} must contain exactly 64 hexadecimal characters"]
    try:
        int(normalized, 16)
    except ValueError:
        return None, [f"{field} contains non-hexadecimal characters"]
    return normalized, []


def _resolve_project_path(project_root: Path, raw_path: Any, field: str) -> Path:
    """Resolve a declared relative path without trusting symlink boundaries."""

    if not _is_nonempty_string(raw_path):
        raise LockValidationError(f"{field} must be a non-empty relative path")
    assert isinstance(raw_path, str)

    if "\x00" in raw_path:
        raise LockValidationError(f"{field} contains a NUL byte")
    # Lock paths are portable project paths, so accepting a backslash would make
    # their meaning platform-dependent (a separator on Windows, a character on
    # POSIX).  Reject it and require the canonical forward-slash spelling.
    if "\\" in raw_path:
        raise LockValidationError(f"{field} must use forward slashes")

    posix_path = PurePosixPath(raw_path)
    windows_path = PureWindowsPath(raw_path)
    if posix_path.is_absolute() or windows_path.is_absolute() or windows_path.drive:
        raise LockValidationError(f"{field} must be relative to the project root")
    if ".." in posix_path.parts or ".." in windows_path.parts:
        raise LockValidationError(f"{field} contains forbidden '..' traversal")

    candidate = project_root.joinpath(*posix_path.parts)
    try:
        resolved = candidate.resolve(strict=True)
    except FileNotFoundError as exc:
        raise LockValidationError(f"{field} does not exist: {raw_path}") from exc
    except (OSError, RuntimeError) as exc:
        raise LockValidationError(f"{field} cannot be resolved: {exc}") from exc

    try:
        resolved.relative_to(project_root)
    except ValueError as exc:
        raise LockValidationError(
            f"{field} escapes the project root after symlink resolution: {raw_path}"
        ) from exc
    return resolved


def _require_regular_file(path: Path, field: str) -> None:
    try:
        mode = path.stat().st_mode
    except OSError as exc:
        raise LockValidationError(f"cannot stat {field}: {exc}") from exc
    if not stat.S_ISREG(mode):
        raise LockValidationError(f"{field} is not a regular file")


def _require_directory(path: Path, field: str) -> None:
    try:
        mode = path.stat().st_mode
    except OSError as exc:
        raise LockValidationError(f"cannot stat {field}: {exc}") from exc
    if not stat.S_ISDIR(mode):
        raise LockValidationError(f"{field} is not a directory")


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    try:
        with path.open("rb") as stream:
            while True:
                chunk = stream.read(HASH_CHUNK_BYTES)
                if not chunk:
                    break
                digest.update(chunk)
    except OSError as exc:
        raise LockValidationError(f"cannot hash file: {exc}") from exc
    return digest.hexdigest()


def _load_lock(
    project_root: Path,
    relative_path: str,
    *,
    collection_key: str,
    expected_top_level_keys: frozenset[str],
) -> list[Any]:
    path = _resolve_project_path(project_root, relative_path, "lock path")
    _require_regular_file(path, "lock path")
    try:
        with path.open("r", encoding="utf-8") as stream:
            document = json.load(stream)
    except json.JSONDecodeError as exc:
        raise LockValidationError(
            f"invalid JSON in {relative_path}: line {exc.lineno}, column {exc.colno}"
        ) from exc
    except (OSError, UnicodeError) as exc:
        raise LockValidationError(f"cannot read {relative_path}: {exc}") from exc

    if not isinstance(document, dict):
        raise LockValidationError(f"{relative_path} top level must be an object")
    actual_keys = set(document)
    if actual_keys != expected_top_level_keys:
        missing = sorted(expected_top_level_keys - actual_keys)
        unknown = sorted(actual_keys - expected_top_level_keys)
        details: list[str] = []
        if missing:
            details.append(f"missing fields: {', '.join(missing)}")
        if unknown:
            details.append(f"unknown fields: {', '.join(unknown)}")
        raise LockValidationError(f"{relative_path}: {'; '.join(details)}")

    schema_version = document.get("schema_version")
    if (
        not isinstance(schema_version, int)
        or isinstance(schema_version, bool)
        or schema_version != 1
    ):
        raise LockValidationError(
            f"{relative_path}: unsupported schema_version {_quoted(schema_version)}"
        )

    collection = document.get(collection_key)
    if not isinstance(collection, list):
        raise LockValidationError(f"{relative_path}: {collection_key} must be an array")
    return collection


def _source_identity(entry: Any, index: int) -> str:
    if isinstance(entry, dict) and _is_nonempty_string(entry.get("name")):
        return str(entry["name"])
    return f"#{index}"


def _validate_source_entry(
    entry: Any, index: int, project_root: Path
) -> tuple[bool, str | None]:
    name = _source_identity(entry, index)
    if not isinstance(entry, dict):
        _emit_failure("source", name, ["entry must be an object"])
        return False, None

    issues = _validate_exact_keys(
        entry, required=SOURCE_REQUIRED_KEYS, allowed=SOURCE_ALLOWED_KEYS
    )
    issues.extend(
        _validate_string_fields(
            entry,
            (
                "name",
                "upstream",
                "tag",
                "commit",
                "version",
                "source_directory",
                "license",
                "license_file",
                "archive",
            ),
        )
    )

    has_version = "version" in entry
    has_tag = "tag" in entry
    has_commit = "commit" in entry
    if has_version:
        if has_tag or has_commit:
            issues.append("version cannot be combined with tag or commit")
    elif not (has_tag and has_commit):
        issues.append("source must declare either version or both tag and commit")

    has_archive = "archive" in entry
    has_archive_sha = "archive_sha256" in entry
    if has_archive != has_archive_sha:
        issues.append("archive and archive_sha256 must be declared together")

    archive_sha: str | None = None
    if has_archive_sha:
        archive_sha, sha_issues = _validate_sha256(
            entry.get("archive_sha256"), "archive_sha256"
        )
        issues.extend(sha_issues)

    source_path: Path | None = None
    license_path: Path | None = None
    archive_path: Path | None = None

    if _is_nonempty_string(entry.get("source_directory")):
        try:
            source_path = _resolve_project_path(
                project_root, entry["source_directory"], "source_directory"
            )
            _require_directory(source_path, "source_directory")
        except LockValidationError as exc:
            issues.append(str(exc))

    if "license_file" in entry and _is_nonempty_string(entry.get("license_file")):
        try:
            license_path = _resolve_project_path(
                project_root, entry["license_file"], "license_file"
            )
            _require_regular_file(license_path, "license_file")
        except LockValidationError as exc:
            issues.append(str(exc))

    if has_archive and _is_nonempty_string(entry.get("archive")):
        try:
            archive_path = _resolve_project_path(
                project_root, entry["archive"], "archive"
            )
            _require_regular_file(archive_path, "archive")
            if archive_sha is not None:
                actual_sha = _sha256_file(archive_path)
                if actual_sha != archive_sha:
                    issues.append(
                        "archive SHA-256 mismatch: "
                        f"expected {archive_sha}, actual {actual_sha}"
                    )
        except LockValidationError as exc:
            issues.append(str(exc))

    if issues:
        _emit_failure("source", name, issues)
        return False, name

    marker = (
        "[LOCK][SOURCE][PASS]"
        f" name={_quoted(name)}"
        f" source_directory={_quoted(entry['source_directory'])}"
    )
    if archive_path is not None:
        marker += (
            f" archive={_quoted(entry['archive'])}"
            f" archive_sha256={_quoted(archive_sha)}"
        )
    if license_path is not None:
        marker += f" license_file={_quoted(entry['license_file'])}"
    print(marker)
    return True, name


def _model_identity(entry: Any, index: int) -> str:
    if isinstance(entry, dict) and _is_nonempty_string(entry.get("name")):
        return str(entry["name"])
    return f"#{index}"


def _validate_model_entry(
    entry: Any,
    index: int,
    project_root: Path,
    *,
    allow_partial: bool,
) -> tuple[str, str | None, str | None]:
    """Return (status, name, canonical path), status in pass/partial/fail."""

    name = _model_identity(entry, index)
    if not isinstance(entry, dict):
        _emit_failure("model", name, ["entry must be an object"])
        return "fail", None, None

    issues = _validate_exact_keys(
        entry, required=MODEL_REQUIRED_KEYS, allowed=MODEL_ALLOWED_KEYS
    )
    issues.extend(
        _validate_string_fields(
            entry,
            (
                "name",
                "repository",
                "revision",
                "path",
                "sha256",
                "format",
                "license_note",
            ),
        )
    )

    size_bytes = entry.get("size_bytes")
    if (
        not isinstance(size_bytes, int)
        or isinstance(size_bytes, bool)
        or size_bytes < 0
    ):
        issues.append("size_bytes must be a non-negative integer")

    expected_sha, sha_issues = _validate_sha256(entry.get("sha256"), "sha256")
    issues.extend(sha_issues)

    model_path: Path | None = None
    actual_size: int | None = None
    if _is_nonempty_string(entry.get("path")):
        try:
            model_path = _resolve_project_path(project_root, entry["path"], "path")
            _require_regular_file(model_path, "path")
            actual_size = model_path.stat().st_size
        except (LockValidationError, OSError) as exc:
            issues.append(str(exc))

    if issues:
        _emit_failure("model", name, issues)
        return "fail", name, entry.get("path") if isinstance(entry.get("path"), str) else None

    assert isinstance(size_bytes, int)
    assert actual_size is not None
    assert model_path is not None
    assert expected_sha is not None

    if actual_size < size_bytes:
        if allow_partial:
            print(
                "[LOCK][PARTIAL]"
                f" kind=model name={_quoted(name)} path={_quoted(entry['path'])}"
                f" actual_size={actual_size} expected_size={size_bytes}"
            )
            return "partial", name, str(entry["path"])
        _emit_failure(
            "model",
            name,
            [
                "model file is partial: "
                f"expected {size_bytes} bytes, actual {actual_size} bytes"
            ],
        )
        return "fail", name, str(entry["path"])

    if actual_size > size_bytes:
        _emit_failure(
            "model",
            name,
            [
                "size_bytes mismatch: "
                f"expected {size_bytes} bytes, actual {actual_size} bytes"
            ],
        )
        return "fail", name, str(entry["path"])

    try:
        actual_sha = _sha256_file(model_path)
    except LockValidationError as exc:
        _emit_failure("model", name, [str(exc)])
        return "fail", name, str(entry["path"])
    if actual_sha != expected_sha:
        _emit_failure(
            "model",
            name,
            [f"SHA-256 mismatch: expected {expected_sha}, actual {actual_sha}"],
        )
        return "fail", name, str(entry["path"])

    print(
        "[LOCK][MODEL][PASS]"
        f" name={_quoted(name)} path={_quoted(entry['path'])}"
        f" size_bytes={size_bytes} sha256={_quoted(actual_sha)}"
    )
    return "pass", name, str(entry["path"])


def _duplicate_issues(values: Sequence[str | None], label: str) -> list[str]:
    seen: set[str] = set()
    duplicates: set[str] = set()
    for value in values:
        if value is None:
            continue
        if value in seen:
            duplicates.add(value)
        seen.add(value)
    return [f"duplicate {label}: {value}" for value in sorted(duplicates)]


def _parse_args(argv: Sequence[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify project-local source and model lock integrity."
    )
    parser.add_argument(
        "--allow-partial-model",
        action="store_true",
        help=(
            "report undersized model files as PARTIAL and continue; PARTIAL "
            "objects are never reported as PASS"
        ),
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = _parse_args(argv)
    try:
        project_root = Path(__file__).resolve(strict=True).parent.parent
    except (OSError, RuntimeError) as exc:
        print(
            f"[LOCK][FAIL] kind=verifier name=\"project-root\" issues={_quoted([str(exc)])}",
            file=sys.stderr,
        )
        return 1

    try:
        sources = _load_lock(
            project_root,
            SOURCE_LOCK_RELATIVE_PATH,
            collection_key="sources",
            expected_top_level_keys=SOURCE_TOP_LEVEL_KEYS,
        )
        models = _load_lock(
            project_root,
            MODEL_LOCK_RELATIVE_PATH,
            collection_key="models",
            expected_top_level_keys=MODEL_TOP_LEVEL_KEYS,
        )
    except LockValidationError as exc:
        _emit_failure("lock", "schema", [str(exc)])
        return 1

    failures = 0
    partials = 0
    source_names: list[str | None] = []
    model_names: list[str | None] = []
    model_paths: list[str | None] = []

    for index, entry in enumerate(sources):
        passed, name = _validate_source_entry(entry, index, project_root)
        source_names.append(name)
        if not passed:
            failures += 1

    for index, entry in enumerate(models):
        status, name, model_path = _validate_model_entry(
            entry,
            index,
            project_root,
            allow_partial=args.allow_partial_model,
        )
        model_names.append(name)
        model_paths.append(model_path)
        if status == "partial":
            partials += 1
        elif status == "fail":
            failures += 1

    global_issues = []
    global_issues.extend(_duplicate_issues(source_names, "source name"))
    global_issues.extend(_duplicate_issues(model_names, "model name"))
    global_issues.extend(_duplicate_issues(model_paths, "model path"))
    if global_issues:
        _emit_failure("lock", "uniqueness", global_issues)
        failures += len(global_issues)

    if failures:
        print(
            "[LOCK][FAIL]"
            f" sources={len(sources)} models={len(models)}"
            f" partial={partials} failures={failures}",
            file=sys.stderr,
        )
        return 1

    if partials:
        # In explicitly allowed mode, partial input is a recognized staging
        # state rather than an integrity mismatch.  It deliberately has no
        # aggregate PASS marker, so callers cannot confuse it with readiness.
        print(
            "[LOCK][PARTIAL]"
            f" sources={len(sources)} models={len(models)} partial={partials}"
        )
        return 0

    print(f"[LOCK][PASS] sources={len(sources)} models={len(models)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
