#!/usr/bin/env python3
"""Atomic, design-bound merge helper for RV64 directed-evidence records."""

from __future__ import annotations

import json
import pathlib
from typing import Any


def _load_preservable_tests(
    manifest: pathlib.Path,
    *,
    schema: str,
    design_id: str,
) -> dict[str, Any]:
    if not manifest.is_file():
        return {}
    value = json.loads(
        manifest.read_text(encoding="utf-8"),
        parse_constant=lambda item: (_ for _ in ()).throw(
            ValueError(f"non-finite constant {item}")),
    )
    if not isinstance(value, dict):
        raise ValueError("existing evidence manifest is not an object")
    if value.get("schema") != schema or value.get("design_id") != design_id:
        return {}
    tests = value.get("tests")
    if not isinstance(tests, dict):
        raise ValueError("matching evidence manifest has non-object tests")
    return dict(tests)


def merge_directed_record(
    manifest: pathlib.Path,
    *,
    schema: str,
    design_id: str,
    generated_at_utc: str,
    test_id: str,
    record: dict[str, Any],
    fault_before_replace: bool = False,
) -> dict[str, Any]:
    """Merge one record and replace the manifest only after a complete write.

    Records are preserved only when the existing top-level schema and complete
    RTL design binding match.  ``fault_before_replace`` is a deterministic
    unit-test injection point proving that the previous manifest remains
    parseable and unchanged if publication is interrupted.
    """

    if not test_id or not isinstance(record, dict):
        raise ValueError("test_id and object record are required")
    tests = _load_preservable_tests(
        manifest, schema=schema, design_id=design_id)
    tests[test_id] = record
    value = {
        "design_id": design_id,
        "generated_at_utc": generated_at_utc,
        "schema": schema,
        "tests": tests,
    }
    temporary = manifest.with_suffix(manifest.suffix + ".tmp")
    try:
        temporary.write_text(
            json.dumps(
                value, allow_nan=False, indent=2, ensure_ascii=False,
                sort_keys=True,
            ) + "\n",
            encoding="utf-8",
        )
        # Parse the exact bytes that would be published before replacing the
        # old manifest.  This also rejects partial/non-finite output.
        json.loads(temporary.read_text(encoding="utf-8"))
        if fault_before_replace:
            raise RuntimeError("injected failure before atomic replace")
        temporary.replace(manifest)
    finally:
        if temporary.exists():
            temporary.unlink()
    return value
