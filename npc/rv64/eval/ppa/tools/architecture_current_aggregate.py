#!/usr/bin/env python3
"""Build or verify one exact-current nine-record RV64 architecture manifest."""

from __future__ import annotations

import argparse
import datetime
import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
SPEC = importlib.util.spec_from_file_location("architecture_hard_gates", ARCH_TOOL)
assert SPEC is not None and SPEC.loader is not None
arch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = arch
SPEC.loader.exec_module(arch)

SCHEMA = "rv64-architecture-current-aggregate-v1"
EXPECTED_TESTS = frozenset(arch.EVIDENCE_TEST.values())


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(
        path.read_text(encoding="utf-8"),
        parse_constant=lambda token: (_ for _ in ()).throw(
            ValueError(f"non-finite JSON constant: {token}")),
    )
    if not isinstance(value, dict):
        raise ValueError(f"JSON root is not an object: {path}")
    return value


def workspace_path(
    root: pathlib.Path, value: pathlib.Path, *, must_exist: bool,
) -> pathlib.Path:
    candidate = value if value.is_absolute() else root / value
    candidate = candidate.resolve(strict=must_exist)
    if not candidate.is_relative_to(root):
        raise ValueError(f"path escapes workspace: {value}")
    cursor = root
    for part in candidate.relative_to(root).parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise ValueError(f"path traverses symlink: {value}")
    if must_exist and not candidate.is_file():
        raise ValueError(f"input is not a file: {value}")
    if not must_exist:
        candidate.parent.mkdir(parents=True, exist_ok=True)
    return candidate


def atomic_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    try:
        temporary.write_text(
            json.dumps(
                value, allow_nan=False, ensure_ascii=False, indent=2,
                sort_keys=True,
            ) + "\n",
            encoding="utf-8",
        )
        parse_json(temporary)
        temporary.replace(path)
    finally:
        if temporary.exists():
            temporary.unlink()


def collect(
    root: pathlib.Path, inputs: list[pathlib.Path],
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    if not inputs:
        raise ValueError("at least one input manifest is required")
    source_sha, _ = arch.rtl_binding(root)
    design_id = f"sha256:{source_sha}"
    records: dict[str, Any] = {}
    input_receipts: list[dict[str, Any]] = []
    seen_paths: set[pathlib.Path] = set()
    for raw in inputs:
        path = workspace_path(root, raw, must_exist=True)
        if path in seen_paths:
            raise ValueError(f"duplicate input path: {path.relative_to(root)}")
        seen_paths.add(path)
        value = parse_json(path)
        if set(value) != {"design_id", "generated_at_utc", "schema", "tests"}:
            raise ValueError(f"input manifest top-level inventory mismatch: {path}")
        tests = value.get("tests")
        if value.get("schema") != arch.EVIDENCE_SCHEMA:
            raise ValueError(f"input manifest schema mismatch: {path}")
        if value.get("design_id") != design_id:
            raise ValueError(f"input manifest design-id mismatch: {path}")
        if not isinstance(tests, dict) or not tests:
            raise ValueError(f"input manifest has no test records: {path}")
        overlap = set(records) & set(tests)
        if overlap:
            raise ValueError(f"duplicate test records: {sorted(overlap)}")
        unknown = set(tests) - EXPECTED_TESTS
        if unknown:
            raise ValueError(f"unknown test records: {sorted(unknown)}")
        records.update(tests)
        input_receipts.append({
            "path": path.relative_to(root).as_posix(),
            "sha256": digest(path),
            "tests": sorted(tests),
        })
    if set(records) != EXPECTED_TESTS:
        missing = sorted(EXPECTED_TESTS - set(records))
        raise ValueError(f"architecture record inventory is incomplete: {missing}")
    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    manifest = {
        "design_id": design_id,
        "generated_at_utc": generated_at,
        "schema": arch.EVIDENCE_SCHEMA,
        "tests": records,
    }
    return manifest, sorted(input_receipts, key=lambda item: item["path"])


def build(args: argparse.Namespace) -> int:
    root = args.repo_root.resolve(strict=True)
    output = workspace_path(root, args.output, must_exist=False)
    receipt = workspace_path(root, args.receipt, must_exist=False)
    if output == receipt:
        raise ValueError("manifest and receipt outputs must differ")
    manifest, inputs = collect(root, args.input)
    atomic_json(output, manifest)
    receipt_value = {
        "schema": SCHEMA,
        "status": "PASS",
        "claim": "nine_record_inventory_complete",
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc).isoformat(),
        "design_id": manifest["design_id"],
        "tests": sorted(EXPECTED_TESTS),
        "inputs": inputs,
        "output": {
            "path": output.relative_to(root).as_posix(),
            "sha256": digest(output),
        },
        "architecture_gate_status": "PENDING_INDEPENDENT_CHECK",
        "ppa": "UNPROMOTED",
    }
    atomic_json(receipt, receipt_value)
    print(
        "[ARCH-CURRENT-AGGREGATE][PASS] "
        f"design_id={manifest['design_id']} records={len(EXPECTED_TESTS)}"
    )
    return 0


def verify(args: argparse.Namespace) -> int:
    root = args.repo_root.resolve(strict=True)
    receipt_path = workspace_path(root, args.receipt, must_exist=True)
    receipt = parse_json(receipt_path)
    if (
        receipt.get("schema") != SCHEMA
        or receipt.get("status") != "PASS"
        or receipt.get("claim") != "nine_record_inventory_complete"
        or receipt.get("architecture_gate_status")
        != "PENDING_INDEPENDENT_CHECK"
        or receipt.get("ppa") != "UNPROMOTED"
        or receipt.get("tests") != sorted(EXPECTED_TESTS)
    ):
        raise ValueError("aggregate receipt contract mismatch")
    input_items = receipt.get("inputs")
    output_item = receipt.get("output")
    if not isinstance(input_items, list) or not isinstance(output_item, dict):
        raise ValueError("aggregate receipt artifact inventory is malformed")
    raw_inputs: list[pathlib.Path] = []
    for item in input_items:
        if not isinstance(item, dict) or set(item) != {"path", "sha256", "tests"}:
            raise ValueError("aggregate receipt input record is malformed")
        path = workspace_path(root, pathlib.Path(item["path"]), must_exist=True)
        if digest(path) != item["sha256"]:
            raise ValueError(f"aggregate input hash mismatch: {item['path']}")
        raw_inputs.append(path)
    expected_manifest, expected_inputs = collect(root, raw_inputs)
    expected_manifest["generated_at_utc"] = parse_json(
        workspace_path(root, pathlib.Path(output_item["path"]), must_exist=True)
    ).get("generated_at_utc")
    output = workspace_path(root, pathlib.Path(output_item["path"]), must_exist=True)
    if digest(output) != output_item.get("sha256"):
        raise ValueError("aggregate output hash mismatch")
    if parse_json(output) != expected_manifest or input_items != expected_inputs:
        raise ValueError("aggregate output does not match its exact inputs")
    if receipt.get("design_id") != expected_manifest["design_id"]:
        raise ValueError("aggregate receipt design-id mismatch")
    print(
        "[ARCH-CURRENT-AGGREGATE-VERIFY][PASS] "
        f"design_id={expected_manifest['design_id']} records={len(EXPECTED_TESTS)}"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    build_parser = subparsers.add_parser("build")
    build_parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    build_parser.add_argument("--input", action="append", required=True, type=pathlib.Path)
    build_parser.add_argument("--output", required=True, type=pathlib.Path)
    build_parser.add_argument("--receipt", required=True, type=pathlib.Path)
    build_parser.set_defaults(handler=build)
    verify_parser = subparsers.add_parser("verify")
    verify_parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    verify_parser.add_argument("--receipt", required=True, type=pathlib.Path)
    verify_parser.set_defaults(handler=verify)
    args = parser.parse_args()
    try:
        return int(args.handler(args))
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[ARCH-CURRENT-AGGREGATE][FAIL] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
