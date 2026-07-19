#!/usr/bin/env python3
"""RV64 producer/owner holder 的 file/module 级 fail-closed census checker。"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any, Callable


ALLOWED_CLASSES = {"AUTH", "TOMBSTONE", "DETACHED", "EXEMPT"}
ALLOWED_CAPTURE = {
    "ALLOCATE", "REGISTER", "QUEUE", "PIPELINE", "TOKEN_ALLOCATE",
    "TERMINAL_ENQUEUE", "PASS_THROUGH", "NONE", "MIXED",
}
ALLOWED_KILL = {
    "SELECTIVE_WALK", "SELECTIVE", "FLUSH", "ABORT", "DROP_DRAIN",
    "CLEAR", "PASS_THROUGH", "NONE", "MIXED",
}
ALLOWED_TERMINAL = {
    "WB_COMMIT", "ISSUE", "WB", "RESPONSE_DRAIN", "STORE_DRAIN",
    "REDIRECT", "GRANT", "CSR_APPLY", "PASS_THROUGH", "NONE", "MIXED",
}
ALLOWED_SIDE_EFFECT = {
    "ARCHITECTURAL_AUTHORITY", "MEMORY_AUTHORITY", "AUTHORITY_PROXY", "NONE",
}
ALLOWED_PROXY = {
    "STATEFUL_HOLDER", "STATEFUL_INTEGRATOR", "COMBINATIONAL_PROXY",
    "WRAPPER_PROXY", "DEFINITION_ONLY",
}
ALLOWED_FULL_ID = {
    "ROB_INDEX_ONLY", "SHADOW_ZERO_EXTENDED_INDEX",
    "LOCAL_MEMORY_TOKEN_PLUS_ROB_INDEX", "LOCAL_MEMORY_TOKEN_ONLY",
    "ABSENT_NO_ROB_ID", "NOT_APPLICABLE",
}
ALLOWED_CLAIM = {"RED", "LOCAL_GREEN", "EXEMPT"}
EXPECTED_LEDGER = {
    "global_no_live_reuse": "RED",
    "generation_safe_full_identity": "RED",
    "writeback_authorization": "RED",
    "q1_csr_live_owner": "RED",
    "memory_token_domain": "LOCAL_GREEN",
}
EXPECTED_SCHEMA = "rv64-producer-holder-census-v0"
EXPECTED_EXTENSIONS = [".v", ".sv", ".vh", ".svh"]
EXPECTED_DERIVED_DISCOVERY = "bounded-seed-plus-declaration-heuristic"
EXPECTED_SELF_TESTS = 9
EXPECTED_STRONGEST_LIVE_AUTHORITY_IDS = [
    "mem-inflight-authority",
    "memory-terminal-authority",
    "memory-bridge-authority",
]
REQUIRED_DERIVED = {
    ("npc/rv64/vsrc/control/OooPendingSystemSequencer.v", "OooPendingSystemSequencer"),
    ("npc/rv64/vsrc/writeback/OooControlCommitSequencer.v", "OooControlCommitSequencer"),
    ("npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v", "OooPendingTrapExitSequencer"),
    ("npc/rv64/vsrc/memory/OooMmuEpochOwner.v", "OooMmuEpochOwner"),
    ("npc/rv64/vsrc/core/CsrFile.v", "CsrFile"),
    ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "OooMemOwnerTracker"),
    ("npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v", "OooMemOwnerTerminalCollector"),
    ("npc/rv64/vsrc/memory/OooMemAxiBridge.v", "OooMemAxiBridge"),
    ("npc/rv64/vsrc/control/OooControlPlane.v", "OooControlPlane"),
}
EXTENSIONS = {".v", ".sv", ".vh", ".svh"}
CARRIER_RE = re.compile(r"\b(?:OOO_)?ROB_INDEX_W\b")
MODULE_TOKEN_RE = re.compile(r"\bmodule\s+([A-Za-z_][A-Za-z0-9_$]*)|\bendmodule\b")
DERIVED_DECL_RE = re.compile(
    r"\b(?:reg|logic)\b[^;]*(?:held_(?:payload|cause)_q|"
    r"owner_(?:token|kind)_q|active_owner_token_q|pending_system_[A-Za-z0-9_]*_q)[^;]*;",
    re.DOTALL,
)


def strip_comments_and_strings(text: str) -> str:
    """保持字符位置/换行，只移除 comment 与 string 内容。"""
    out = list(text)
    i = 0
    state = "code"
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if state == "code":
            if ch == "/" and nxt == "/":
                out[i] = out[i + 1] = " "
                state = "line"
                i += 2
                continue
            if ch == "/" and nxt == "*":
                out[i] = out[i + 1] = " "
                state = "block"
                i += 2
                continue
            if ch == '"':
                out[i] = " "
                state = "string"
                i += 1
                continue
        elif state == "line":
            if ch == "\n":
                state = "code"
            else:
                out[i] = " "
        elif state == "block":
            if ch == "*" and nxt == "/":
                out[i] = out[i + 1] = " "
                state = "code"
                i += 2
                continue
            if ch != "\n":
                out[i] = " "
        elif state == "string":
            if ch == "\\" and nxt:
                out[i] = out[i + 1] = " "
                i += 2
                continue
            if ch == '"':
                out[i] = " "
                state = "code"
            elif ch != "\n":
                out[i] = " "
        i += 1
    return "".join(out)


def module_spans(clean: str) -> tuple[list[tuple[str, int, int]], list[str]]:
    spans: list[tuple[str, int, int]] = []
    errors: list[str] = []
    open_module: tuple[str, int] | None = None
    for match in MODULE_TOKEN_RE.finditer(clean):
        name = match.group(1)
        if name is not None:
            if open_module is not None:
                errors.append(f"nested/unclosed module before {name}")
            open_module = (name, match.start())
        else:
            if open_module is None:
                errors.append("endmodule without module")
            else:
                spans.append((open_module[0], open_module[1], match.end()))
                open_module = None
    if open_module is not None:
        errors.append(f"module without endmodule: {open_module[0]}")
    return spans, errors


def unit_for_position(spans: list[tuple[str, int, int]], pos: int) -> str | None:
    for name, start, end in spans:
        if start <= pos < end:
            return name
    return None


def load_source_units(repo_root: Path, source_root: Path) -> tuple[
    dict[tuple[str, str | None], int],
    dict[str, set[str]],
    set[tuple[str, str]],
    list[str],
]:
    carrier_units: dict[tuple[str, str | None], int] = {}
    modules_by_path: dict[str, set[str]] = {}
    heuristic_derived: set[tuple[str, str]] = set()
    errors: list[str] = []
    for path in sorted(source_root.rglob("*")):
        if not path.is_file() or path.suffix not in EXTENSIONS:
            continue
        if path.is_symlink():
            errors.append(f"source symlink is not allowed: {path}")
            continue
        rel = path.relative_to(repo_root).as_posix()
        try:
            raw = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            errors.append(f"cannot read source {rel}: {exc}")
            continue
        clean = strip_comments_and_strings(raw)
        spans, span_errors = module_spans(clean)
        errors.extend(f"{rel}: {item}" for item in span_errors)
        modules_by_path[rel] = {name for name, _, _ in spans}
        for match in CARRIER_RE.finditer(clean):
            key = (rel, unit_for_position(spans, match.start()))
            carrier_units[key] = carrier_units.get(key, 0) + 1
        for name, start, end in spans:
            if DERIVED_DECL_RE.search(clean[start:end]):
                heuristic_derived.add((rel, name))
    return carrier_units, modules_by_path, heuristic_derived, errors


def safe_repo_path(repo_root: Path, rel: str) -> tuple[Path | None, str | None]:
    candidate = repo_root / rel
    try:
        resolved = candidate.resolve(strict=True)
        resolved.relative_to(repo_root.resolve(strict=True))
    except (OSError, ValueError) as exc:
        return None, f"unsafe/missing path {rel}: {exc}"
    if candidate.is_symlink():
        return None, f"manifest path may not be symlink: {rel}"
    return resolved, None


def validate_manifest(
    manifest: dict[str, Any],
    repo_root: Path,
    carrier_units: dict[tuple[str, str | None], int],
    modules_by_path: dict[str, set[str]],
    heuristic_derived: set[tuple[str, str]],
) -> list[str]:
    errors: list[str] = []
    if manifest.get("schema_version") != EXPECTED_SCHEMA:
        errors.append(
            f"schema_version must be {EXPECTED_SCHEMA!r}, got {manifest.get('schema_version')!r}"
        )
    scope = manifest.get("scope")
    if not isinstance(scope, dict):
        return ["scope must be an object"]
    exact_scope = {
        "coverage_granularity": "file-module",
        "field_level_complete": False,
        "instance_graph_complete": False,
        "semantic_complete": False,
        "all_carrier_units_required": True,
        "classification_policy": "strongest-live-authority",
        "strongest_live_authority_ids": EXPECTED_STRONGEST_LIVE_AUTHORITY_IDS,
    }
    for key, expected in exact_scope.items():
        if scope.get(key) != expected:
            errors.append(f"scope.{key} must be {expected!r}, got {scope.get(key)!r}")
    if scope.get("source_root") != "npc/rv64/vsrc":
        errors.append("scope.source_root must remain npc/rv64/vsrc")
    if scope.get("extensions") != EXPECTED_EXTENSIONS:
        errors.append(
            f"scope.extensions must be {EXPECTED_EXTENSIONS!r}, got {scope.get('extensions')!r}"
        )
    if scope.get("carrier_token_regex") != r"\b(?:OOO_)?ROB_INDEX_W\b":
        errors.append("scope.carrier_token_regex drifted from checker")
    if scope.get("derived_owner_discovery") != EXPECTED_DERIVED_DISCOVERY:
        errors.append(
            "scope.derived_owner_discovery must remain bounded; open-world completeness is not established"
        )
    expected_carriers = scope.get("expected_carrier_units")
    if expected_carriers != len(carrier_units):
        errors.append(
            f"expected_carrier_units={expected_carriers!r}, live scan={len(carrier_units)}"
        )
    if scope.get("expected_derived_owner_units") != len(REQUIRED_DERIVED):
        errors.append("expected_derived_owner_units does not match checker seed")

    ledger = manifest.get("status_ledger")
    if ledger != EXPECTED_LEDGER:
        errors.append(
            "status_ledger must keep global no-live-reuse/full-id/WB/Q1 RED and memory token LOCAL_GREEN"
        )

    entries = manifest.get("entries")
    if not isinstance(entries, list):
        return errors + ["entries must be a list"]
    if scope.get("expected_manifest_entries") != len(entries):
        errors.append(
            f"expected_manifest_entries={scope.get('expected_manifest_entries')!r}, actual={len(entries)}"
        )

    ids: set[str] = set()
    entries_by_id: dict[str, dict[str, Any]] = {}
    keyed: dict[tuple[str, str | None], dict[str, Any]] = {}
    required_fields = {
        "id", "path", "module", "classification", "carrier_source",
        "derived_owner", "capture", "kill", "terminal", "side_effect",
        "proxy", "full_identity", "claim_status", "notes",
    }
    enum_fields = {
        "classification": ALLOWED_CLASSES,
        "capture": ALLOWED_CAPTURE,
        "kill": ALLOWED_KILL,
        "terminal": ALLOWED_TERMINAL,
        "side_effect": ALLOWED_SIDE_EFFECT,
        "proxy": ALLOWED_PROXY,
        "full_identity": ALLOWED_FULL_ID,
        "claim_status": ALLOWED_CLAIM,
    }
    for index, entry in enumerate(entries):
        label = f"entries[{index}]"
        if not isinstance(entry, dict):
            errors.append(f"{label} must be an object")
            continue
        missing = sorted(required_fields - set(entry))
        if missing:
            errors.append(f"{label} missing fields: {', '.join(missing)}")
            continue
        entry_id = entry["id"]
        if not isinstance(entry_id, str) or not entry_id:
            errors.append(f"{label}.id must be non-empty string")
        elif entry_id in ids:
            errors.append(f"duplicate entry id: {entry_id}")
        ids.add(entry_id)
        if isinstance(entry_id, str):
            entries_by_id[entry_id] = entry
        path = entry["path"]
        module = entry["module"]
        if not isinstance(path, str) or not path.startswith("npc/rv64/vsrc/"):
            errors.append(f"{label}.path is outside source root: {path!r}")
            continue
        if module is not None and not isinstance(module, str):
            errors.append(f"{label}.module must be string or null")
            continue
        _, path_error = safe_repo_path(repo_root, path)
        if path_error:
            errors.append(path_error)
        if module is not None and module not in modules_by_path.get(path, set()):
            errors.append(f"{label} module {module} not found in {path}")
        key = (path, module)
        if key in keyed:
            errors.append(f"duplicate file/module entry: {path}::{module}")
        keyed[key] = entry
        for field, allowed in enum_fields.items():
            if entry[field] not in allowed:
                errors.append(f"{label}.{field} invalid: {entry[field]!r}")
        if not isinstance(entry["carrier_source"], bool):
            errors.append(f"{label}.carrier_source must be boolean")
        if not isinstance(entry["derived_owner"], bool):
            errors.append(f"{label}.derived_owner must be boolean")
        if not isinstance(entry["notes"], str) or not entry["notes"].strip():
            errors.append(f"{label}.notes must be non-empty")
        if entry["claim_status"] == "LOCAL_GREEN" and entry["full_identity"] not in {
            "LOCAL_MEMORY_TOKEN_ONLY", "LOCAL_MEMORY_TOKEN_PLUS_ROB_INDEX"
        }:
            errors.append(f"{label} LOCAL_GREEN is only legal for local memory-token identity")
        if entry["claim_status"] == "LOCAL_GREEN" and "memory" not in path.lower():
            errors.append(f"{label} LOCAL_GREEN escaped memory-local scope")
        if entry["full_identity"] == "NOT_APPLICABLE" and entry["classification"] != "EXEMPT":
            errors.append(f"{label} NOT_APPLICABLE full identity requires EXEMPT")
        if entry["classification"] == "TOMBSTONE" and entry["side_effect"] != "NONE":
            errors.append(
                f"{label} TOMBSTONE file/module entry may not expose live side effects; "
                "mixed AUTH/TOMBSTONE modules must use strongest-live-authority"
            )
        if entry["classification"] == "EXEMPT" and (
            entry["capture"] not in {"NONE", "PASS_THROUGH"}
            or entry["proxy"] == "STATEFUL_HOLDER"
        ):
            errors.append(
                f"{label} EXEMPT file/module entry may not retain producer/owner state"
            )

    for entry_id in EXPECTED_STRONGEST_LIVE_AUTHORITY_IDS:
        entry = entries_by_id.get(entry_id)
        if entry is None:
            errors.append(f"strongest-live-authority entry missing: {entry_id}")
        elif entry.get("classification") != "AUTH":
            errors.append(
                f"strongest-live-authority entry {entry_id} must remain AUTH, "
                f"got {entry.get('classification')!r}"
            )

    for key, count in sorted(carrier_units.items()):
        entry = keyed.get(key)
        if entry is None:
            errors.append(f"uncovered ROB_INDEX_W carrier: {key[0]}::{key[1]} occurrences={count}")
        elif entry.get("carrier_source") is not True:
            errors.append(f"carrier entry not marked carrier_source: {key[0]}::{key[1]}")
    for key, entry in keyed.items():
        if entry.get("carrier_source") is True and key not in carrier_units:
            errors.append(f"stale/false carrier_source entry: {key[0]}::{key[1]}")

    seed_from_manifest: set[tuple[str, str]] = set()
    for item in manifest.get("derived_owner_seed", []):
        if isinstance(item, dict) and isinstance(item.get("path"), str) and isinstance(item.get("module"), str):
            seed_from_manifest.add((item["path"], item["module"]))
        else:
            errors.append("derived_owner_seed entries must contain string path/module")
    if seed_from_manifest != REQUIRED_DERIVED:
        missing = sorted(REQUIRED_DERIVED - seed_from_manifest)
        extra = sorted(seed_from_manifest - REQUIRED_DERIVED)
        errors.append(f"derived_owner_seed drift missing={missing} extra={extra}")
    for key in sorted(REQUIRED_DERIVED):
        entry = keyed.get(key)
        if entry is None:
            errors.append(f"required derived owner missing from entries: {key[0]}::{key[1]}")
        elif entry.get("derived_owner") is not True:
            errors.append(f"required derived owner not marked derived_owner: {key[0]}::{key[1]}")
    for key in sorted(heuristic_derived):
        entry = keyed.get(key)
        if entry is None:
            errors.append(f"heuristic derived holder not covered: {key[0]}::{key[1]}")

    return errors


def canonical_digest(value: Any) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def run_self_tests(
    manifest: dict[str, Any],
    repo_root: Path,
    carriers: dict[tuple[str, str | None], int],
    modules: dict[str, set[str]],
    heuristic: set[tuple[str, str]],
    *,
    emit: bool,
) -> list[str]:
    failures: list[str] = []
    cases: list[tuple[str, Callable[[dict[str, Any]], None], str]] = []

    def remove_carrier(data: dict[str, Any]) -> None:
        data["entries"] = [item for item in data["entries"] if item["id"] != "rob-authority"]
        data["scope"]["expected_manifest_entries"] -= 1

    def remove_derived(data: dict[str, Any]) -> None:
        data["entries"] = [item for item in data["entries"] if item["id"] != "q1a-inactive-owner"]
        data["scope"]["expected_manifest_entries"] -= 1

    def overclaim_fields(data: dict[str, Any]) -> None:
        data["scope"]["field_level_complete"] = True

    def overclaim_global(data: dict[str, Any]) -> None:
        data["status_ledger"]["generation_safe_full_identity"] = "GREEN"

    def erase_local_boundary(data: dict[str, Any]) -> None:
        data["status_ledger"]["memory_token_domain"] = "GREEN"

    def overclaim_derived_discovery(data: dict[str, Any]) -> None:
        data["scope"]["derived_owner_discovery"] = "open-world-complete"

    def weaken_mixed_authority(data: dict[str, Any], classification: str) -> None:
        for item in data["entries"]:
            if item["id"] == "memory-bridge-authority":
                item["classification"] = classification
                return
        raise AssertionError("memory-bridge-authority fixture missing")

    cases.extend([
        ("missing-carrier", remove_carrier, "uncovered ROB_INDEX_W carrier"),
        ("missing-derived-owner", remove_derived, "required derived owner missing"),
        ("field-level-overclaim", overclaim_fields, "scope.field_level_complete"),
        ("global-full-id-overclaim", overclaim_global, "status_ledger"),
        ("memory-local-boundary-erased", erase_local_boundary, "status_ledger"),
        (
            "derived-discovery-overclaim",
            overclaim_derived_discovery,
            "scope.derived_owner_discovery",
        ),
        (
            "mixed-authority-weakened-to-tombstone",
            lambda data: weaken_mixed_authority(data, "TOMBSTONE"),
            "strongest-live-authority entry memory-bridge-authority must remain AUTH",
        ),
        (
            "mixed-authority-weakened-to-exempt",
            lambda data: weaken_mixed_authority(data, "EXEMPT"),
            "strongest-live-authority entry memory-bridge-authority must remain AUTH",
        ),
        (
            "mixed-authority-weakened-to-detached",
            lambda data: weaken_mixed_authority(data, "DETACHED"),
            "strongest-live-authority entry memory-bridge-authority must remain AUTH",
        ),
    ])
    for name, mutate, expected in cases:
        candidate = copy.deepcopy(manifest)
        mutate(candidate)
        errors = validate_manifest(candidate, repo_root, carriers, modules, heuristic)
        if not any(expected in error for error in errors):
            failures.append(f"self-test {name} did not trigger expected oracle {expected!r}: {errors}")
        elif emit:
            print(f"SELFTEST {name}=PASS")
    return failures


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=script_dir.parents[3])
    parser.add_argument("--manifest", type=Path, default=script_dir / "holder-census.json")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--json", action="store_true", dest="json_output")
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    manifest_path = args.manifest.resolve()
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        print(f"CENSUS_RESULT=FAIL manifest={exc}", file=sys.stderr)
        return 1

    source_root = repo_root / "npc/rv64/vsrc"
    carriers, modules, heuristic, scan_errors = load_source_units(repo_root, source_root)
    errors = list(scan_errors)
    errors.extend(validate_manifest(manifest, repo_root, carriers, modules, heuristic))
    self_test_failures: list[str] = []
    if not errors and args.self_test:
        self_test_failures = run_self_tests(
            manifest,
            repo_root,
            carriers,
            modules,
            heuristic,
            emit=not args.json_output,
        )
        errors.extend(self_test_failures)

    result = {
        "result": "PASS" if not errors else "FAIL",
        "coverage_granularity": "file-module",
        "field_level_complete": False,
        "carrier_units": len(carriers),
        "derived_seed_units": len(REQUIRED_DERIVED),
        "heuristic_derived_units": len(heuristic),
        "manifest_entries": len(manifest.get("entries", [])),
        "carrier_digest": canonical_digest([
            [path, module, count] for (path, module), count in sorted(carriers.items())
        ]),
        "manifest_digest": canonical_digest(manifest),
        "status_ledger": manifest.get("status_ledger"),
        "self_tests": EXPECTED_SELF_TESTS if args.self_test and not self_test_failures else 0,
        "errors": errors,
    }
    if args.json_output:
        print(json.dumps(result, ensure_ascii=False, sort_keys=True, indent=2))
    else:
        print(f"CENSUS_SCOPE={result['coverage_granularity']}")
        print(f"CENSUS_FIELD_LEVEL_COMPLETE={int(result['field_level_complete'])}")
        print(f"CENSUS_CARRIER_UNITS={result['carrier_units']}")
        print(f"CENSUS_DERIVED_SEED_UNITS={result['derived_seed_units']}")
        print(f"CENSUS_HEURISTIC_DERIVED_UNITS={result['heuristic_derived_units']}")
        print(f"CENSUS_MANIFEST_ENTRIES={result['manifest_entries']}")
        print(f"CENSUS_CARRIER_DIGEST={result['carrier_digest']}")
        print(f"CENSUS_MANIFEST_DIGEST={result['manifest_digest']}")
        print("GLOBAL_NO_LIVE_REUSE=RED")
        print("GENERATION_SAFE_FULL_IDENTITY=RED")
        print("WRITEBACK_AUTHORIZATION=RED")
        print("Q1_CSR_LIVE_OWNER=RED")
        print("MEMORY_TOKEN_DOMAIN=LOCAL_GREEN")
        if errors:
            for error in errors:
                print(f"ERROR {error}", file=sys.stderr)
        print(f"CENSUS_RESULT={result['result']}")
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
