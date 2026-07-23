#!/usr/bin/env python3
"""Rebind one proven workflow-file hash without changing directed evidence semantics.

This task-local utility is intentionally narrow.  It accepts only the known
``npc/rv64/Makefile`` drift introduced by adding a local XRET evidence target.
It requires every architecture gate to fail solely on that provenance drift,
builds a candidate manifest, proves the non-provenance projection unchanged,
and requires all nine architecture gates to become GREEN before replacing the
manifest atomically.
"""

from __future__ import annotations

import argparse
import copy
import datetime
import hashlib
import json
import os
import pathlib
import sys
from typing import Any


SCHEMA = "npc-rv64-architecture-workflow-provenance-rebind-v1"
ALLOWED_PATH = "npc/rv64/Makefile"


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_digest(value: Any) -> str:
    raw = json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def semantic_projection(manifest: dict[str, Any]) -> dict[str, Any]:
    """Return the manifest with per-test source-binding metadata removed."""
    projected = copy.deepcopy(manifest)
    tests = projected.get("tests")
    if isinstance(tests, dict):
        for record in tests.values():
            if isinstance(record, dict):
                record.pop("provenance", None)
                record.pop("source_manifest", None)
    return projected


def json_bytes(value: Any) -> bytes:
    return (
        json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
    ).encode("utf-8")


def gate_failures(result: dict[str, Any]) -> dict[str, list[str]]:
    failures: dict[str, list[str]] = {}
    for gate_id, gate in result.get("gates", {}).items():
        failures[gate_id] = [
            item.get("check_id", "<missing-check-id>")
            for item in gate.get("checks", [])
            if item.get("status") != "GREEN"
        ]
    return failures


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def load_gate_module(root: pathlib.Path) -> Any:
    tools_dir = root / "npc/rv64/eval/ppa/tools"
    sys.path.insert(0, str(tools_dir))
    import architecture_hard_gates  # type: ignore

    return architecture_hard_gates


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path, required=True)
    parser.add_argument("--manifest", type=pathlib.Path, required=True)
    parser.add_argument("--audit", type=pathlib.Path, required=True)
    args = parser.parse_args()

    root = args.repo_root.resolve()
    manifest_path = (root / args.manifest).resolve()
    audit_path = (root / args.audit).resolve()
    require(root in manifest_path.parents, "manifest must stay inside repo root")
    require(root in audit_path.parents, "audit output must stay inside repo root")

    gate = load_gate_module(root)
    original_bytes = manifest_path.read_bytes()
    before = json.loads(original_bytes)
    require(before.get("schema") == gate.EVIDENCE_SCHEMA, "unexpected manifest schema")

    tests = before.get("tests")
    expected_tests = set(gate.EVIDENCE_TEST.values())
    require(isinstance(tests, dict), "tests must be an object")
    require(set(tests) == expected_tests, "manifest must contain exactly nine gate records")

    rtl_sha, rtl_files = gate.rtl_binding(root)
    design_id = f"sha256:{rtl_sha}"
    require(before.get("design_id") == design_id, "manifest is not bound to current RTL")

    pre_result = gate.evaluate(root, manifest_path)
    require(pre_result.get("evidence_errors") == [], "pre-rebind evidence errors are not empty")
    pre_failures = gate_failures(pre_result)
    require(set(pre_failures) == set(gate.GATE_IDS), "pre-result gate inventory mismatch")
    pre_status = pre_result.get("overall_status")
    require(pre_status in {"RED", "GREEN"}, "unexpected pre-rebind gate status")
    if pre_status == "RED":
        for gate_id, test_id in gate.EVIDENCE_TEST.items():
            expected = {
                f"evidence.{test_id}.provenance_files",
                f"evidence.{test_id}.provenance_digest",
            }
            require(
                set(pre_failures[gate_id]) == expected,
                f"{gate_id} has failures beyond the allowed provenance drift: "
                f"{pre_failures[gate_id]}",
            )
    else:
        require(
            all(not failed for failed in pre_failures.values()),
            f"GREEN pre-result contains failed checks: {pre_failures}",
        )

    current_allowed_sha = digest(root / ALLOWED_PATH)
    candidate = copy.deepcopy(before)
    record_audit: dict[str, Any] = {}
    changed_sections = 0
    for test_id in sorted(expected_tests):
        record = tests[test_id]
        require(isinstance(record, dict), f"{test_id}: record must be an object")
        require(isinstance(record.get("provenance"), dict), f"{test_id}: provenance missing")
        section_audit: dict[str, Any] = {}
        for section_name in ("provenance", "source_manifest"):
            section = record.get(section_name)
            if section_name == "source_manifest" and section is None:
                continue
            files = section.get("files") if isinstance(section, dict) else None
            require(isinstance(files, dict), f"{test_id}: {section_name} files missing")
            require(
                section.get("sha256") == gate.canonical_digest(files),
                f"{test_id}: {section_name} aggregate does not bind its recorded map",
            )
            mismatches: list[dict[str, str]] = []
            for rel, recorded_sha in sorted(files.items()):
                live_path = root / rel
                require(live_path.is_file(), f"{test_id}: missing {section_name} file {rel}")
                live_sha = digest(live_path)
                if live_sha != recorded_sha:
                    mismatches.append(
                        {
                            "path": rel,
                            "recorded_sha256": recorded_sha,
                            "live_sha256": live_sha,
                        }
                    )
            require(
                all(entry["path"] == ALLOWED_PATH for entry in mismatches),
                f"{test_id}: {section_name} has drift beyond {ALLOWED_PATH}: {mismatches}",
            )
            if not mismatches:
                continue

            candidate_section = candidate["tests"][test_id][section_name]
            old_aggregate = candidate_section.get("sha256")
            candidate_section["files"][ALLOWED_PATH] = current_allowed_sha
            candidate_section["sha256"] = gate.canonical_digest(
                candidate_section["files"]
            )
            changed_sections += 1
            section_audit[section_name] = {
                "changed_path": ALLOWED_PATH,
                "old_file_sha256": mismatches[0]["recorded_sha256"],
                "new_file_sha256": current_allowed_sha,
                "old_aggregate_sha256": old_aggregate,
                "new_aggregate_sha256": candidate_section["sha256"],
            }
        if section_audit:
            record_audit[test_id] = section_audit

    require(changed_sections > 0, "no allowed source-binding drift remains to rebind")

    before_projection_sha = canonical_digest(semantic_projection(before))
    after_projection_sha = canonical_digest(semantic_projection(candidate))
    require(
        before_projection_sha == after_projection_sha,
        "non-provenance manifest projection changed",
    )
    require(candidate.get("design_id") == design_id, "candidate RTL binding changed")

    manifest_tmp = manifest_path.with_suffix(manifest_path.suffix + ".v9e-rebind.tmp")
    manifest_tmp.write_bytes(json_bytes(candidate))
    try:
        post_result = gate.evaluate(root, manifest_tmp)
        post_failures = gate_failures(post_result)
        require(post_result.get("evidence_errors") == [], "post-rebind evidence errors are not empty")
        require(post_result.get("overall_status") == "GREEN", "post-rebind gates are not GREEN")
        require(
            all(not failed for failed in post_failures.values()),
            f"post-rebind checks failed: {post_failures}",
        )
        for test_id, record in candidate["tests"].items():
            for section_name in ("provenance", "source_manifest"):
                section = record.get(section_name)
                if section_name == "source_manifest" and section is None:
                    continue
                for rel, expected_sha in section["files"].items():
                    require(
                        digest(root / rel) == expected_sha,
                        f"{test_id}: post-rebind {section_name} drift remains at {rel}",
                    )

        after_bytes = manifest_tmp.read_bytes()
        audit = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.datetime.now(
                datetime.timezone.utc
            ).isoformat(),
            "status": "PASS",
            "scope": {
                "object": "local RV64 Verilog/SystemVerilog architecture evidence",
                "operation": "workflow source-binding metadata hash rebind",
                "allowed_changed_path": ALLOWED_PATH,
                "dynamic_directed_tests_rerun": False,
                "claim": (
                    "No directed-test result, command, metric, log, artifact, or RTL "
                    "design binding changed."
                ),
            },
            "manifest": {
                "path": manifest_path.relative_to(root).as_posix(),
                "before_sha256": hashlib.sha256(original_bytes).hexdigest(),
                "after_sha256": hashlib.sha256(after_bytes).hexdigest(),
                "before_semantic_projection_sha256": before_projection_sha,
                "after_semantic_projection_sha256": after_projection_sha,
                "design_id": design_id,
            },
            "current_rtl_binding": {
                "design_id": design_id,
                "file_count": len(rtl_files),
            },
            "allowed_drift": {
                "path": ALLOWED_PATH,
                "live_sha256": current_allowed_sha,
            },
            "records": record_audit,
            "changed_section_count": changed_sections,
            "pre_gate_result": {
                "overall_status": pre_result["overall_status"],
                "failures": pre_failures,
            },
            "post_gate_result": {
                "overall_status": post_result["overall_status"],
                "failures": post_failures,
            },
            "checks": {
                "exact_nine_record_inventory": True,
                "current_rtl_design_binding": True,
                "only_allowed_live_file_drift": True,
                "pre_architecture_gate_state_allowed": True,
                "non_provenance_projection_unchanged": True,
                "all_provenance_and_source_manifests_live": True,
                "post_all_nine_gates_green": True,
            },
        }
        audit_tmp = audit_path.with_suffix(audit_path.suffix + ".tmp")
        audit_path.parent.mkdir(parents=True, exist_ok=True)
        audit_tmp.write_bytes(json_bytes(audit))
        os.replace(manifest_tmp, manifest_path)
        os.replace(audit_tmp, audit_path)
    finally:
        manifest_tmp.unlink(missing_ok=True)

    print(
        f"[ARCH-PROVENANCE-REBIND] records={len(record_audit)} sections={changed_sections} "
        f"allowed_path={ALLOWED_PATH} semantic_projection=UNCHANGED "
        f"pre={pre_status} post=GREEN PASS"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[ARCH-PROVENANCE-REBIND] FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
