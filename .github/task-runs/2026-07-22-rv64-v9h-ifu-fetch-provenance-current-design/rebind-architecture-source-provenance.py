#!/usr/bin/env python3
"""Rebind byte-proven V9H Makefile provenance in directed architecture evidence."""

from __future__ import annotations

import argparse
import copy
import datetime
import hashlib
import importlib.util
import json
import os
import pathlib
import sys
from typing import Any


SCHEMA = "npc-rv64-v9h-architecture-source-provenance-rebind-v1"
RUN_ID = "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design"
ALLOWED_PATH = "npc/rv64/Makefile"
IFU_RESULT = "npc/rv64/eval/ppa/evidence/ifu-fetch-provenance-current.json"
V9H_MAKEFILE_BLOCK = b"""# V9H IFU-FETCH-G2 local RV64 page-fault byte-provenance closure. The bridge
# and packet decoder matrix binds F=0/2/4/6, independent PC-derived frontiers,
# stale-tail exclusion, response backpressure ownership, post-accept quiet and
# positive AR/fill/SRAM monitor sensitivity. Compile-success RTL verification
# variants must be dynamically rejected. PPA remains unqualified.
.PHONY: check-ifu-fetch-provenance
check-ifu-fetch-provenance:
\t@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design/run-focused.sh)

"""


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def canonical_digest(value: Any) -> str:
    encoded = json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return sha256_bytes(encoded)


def json_bytes(value: Any) -> bytes:
    return (
        json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
    ).encode("utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def semantic_projection(manifest: dict[str, Any]) -> dict[str, Any]:
    projected = copy.deepcopy(manifest)
    tests = projected.get("tests")
    if isinstance(tests, dict):
        for record in tests.values():
            if isinstance(record, dict):
                record.pop("provenance", None)
                record.pop("source_manifest", None)
    return projected


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def gate_failures(result: dict[str, Any]) -> dict[str, list[str]]:
    return {
        gate_id: [
            check.get("check_id", "<missing-check-id>")
            for check in gate.get("checks", [])
            if check.get("status") != "GREEN"
        ]
        for gate_id, gate in result.get("gates", {}).items()
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path, required=True)
    parser.add_argument("--manifest", type=pathlib.Path, required=True)
    parser.add_argument("--audit", type=pathlib.Path, required=True)
    args = parser.parse_args()
    root = args.repo_root.resolve(strict=True)
    manifest_path = (root / args.manifest).resolve(strict=True)
    audit_path = (root / args.audit).resolve()
    require(manifest_path.is_relative_to(root), "manifest escapes repository")
    require(audit_path.is_relative_to(root), "audit escapes repository")

    gate = load_module(
        root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
        "v9h_architecture_hard_gates",
    )
    evidence_tool = load_module(
        root / "npc/rv64/eval/ppa/tools/ifu_fetch_provenance_evidence.py",
        "v9h_ifu_fetch_evidence",
    )
    original_bytes = manifest_path.read_bytes()
    before = json.loads(original_bytes)
    require(before.get("schema") == gate.EVIDENCE_SCHEMA,
            "unexpected architecture manifest schema")
    tests = before.get("tests")
    expected_tests = set(gate.EVIDENCE_TEST.values())
    require(isinstance(tests, dict), "architecture tests must be an object")
    require(set(tests) == expected_tests,
            "architecture record inventory is not exact")
    rtl_sha, rtl_files = gate.rtl_binding(root)
    design_id = f"sha256:{rtl_sha}"
    require(before.get("design_id") == design_id,
            "architecture manifest is cross-design")

    pre_result = gate.evaluate(root, manifest_path)
    require(pre_result.get("evidence_errors") == [],
            "pre-rebind evidence structural errors exist")
    require(pre_result.get("overall_status") == "RED",
            "pre-rebind architecture gates must be RED")
    pre_failures = gate_failures(pre_result)
    require(set(pre_failures) == set(gate.GATE_IDS),
            "pre-rebind gate inventory drifted")
    for gate_id, test_id in gate.EVIDENCE_TEST.items():
        expected = {
            f"evidence.{test_id}.provenance_files",
            f"evidence.{test_id}.provenance_digest",
        }
        require(set(pre_failures[gate_id]) == expected,
                f"{gate_id} has non-provenance failures: {pre_failures[gate_id]}")

    ifu_result_path = root / IFU_RESULT
    ifu_result = json.loads(ifu_result_path.read_text(encoding="utf-8"))
    module = ifu_result.get("module_aggregate", {})
    variants = ifu_result.get("variant_audit", {})
    require(ifu_result.get("status") == "PASS",
            "IFU fetch provenance result is not PASS")
    require(ifu_result.get("design_id") == design_id,
            "IFU fetch provenance result is cross-design")
    require(
        module.get("required") == 109
        and module.get("passed") == 109
        and module.get("failed") == 0,
        "IFU fetch module aggregate is not exact 109/109",
    )
    require(
        variants.get("required") == 16
        and variants.get("compile_success") == 16
        and variants.get("dynamic_rejected") == 16,
        "IFU fetch RTL variant audit is not exact 16/16",
    )
    evidence_tool.parse_module_aggregate(
        root,
        root / f".github/task-runs/{RUN_ID}/evidence/"
        "module-aggregate/summary.txt",
    )
    evidence_tool.validate_variants(
        root,
        root / f".github/task-runs/{RUN_ID}/evidence/mutations/summary.json",
    )
    sources = ifu_result.get("provenance", {}).get("source_bindings", {})
    require(
        sources.get(ALLOWED_PATH)
            == sha256_bytes((root / ALLOWED_PATH).read_bytes()),
        "IFU fetch result does not bind the live Makefile",
    )

    candidate = copy.deepcopy(before)
    observed_mismatches: set[str] = set()
    old_hashes: set[str] = set()
    record_audit: dict[str, Any] = {}
    changed_sections = 0
    for test_id in sorted(expected_tests):
        record = tests[test_id]
        require(isinstance(record, dict), f"{test_id}: record is not an object")
        section_audit: dict[str, Any] = {}
        for section_name in ("provenance", "source_manifest"):
            section = record.get(section_name)
            if section_name == "source_manifest" and section is None:
                continue
            require(isinstance(section, dict),
                    f"{test_id}: {section_name} is missing")
            files = section.get("files")
            require(isinstance(files, dict),
                    f"{test_id}: {section_name}.files missing")
            require(section.get("sha256") == gate.canonical_digest(files),
                    f"{test_id}: recorded {section_name} aggregate is invalid")
            mismatches: list[dict[str, str]] = []
            for relative, recorded_sha in sorted(files.items()):
                live_path = root / relative
                require(live_path.is_file(), f"{test_id}: missing source {relative}")
                live_sha = sha256_bytes(live_path.read_bytes())
                if live_sha == recorded_sha:
                    continue
                require(relative == ALLOWED_PATH,
                        f"{test_id}: drift outside Makefile at {relative}")
                observed_mismatches.add(relative)
                old_hashes.add(recorded_sha)
                mismatches.append({
                    "path": relative,
                    "recorded_sha256": recorded_sha,
                    "live_sha256": live_sha,
                })
            if not mismatches:
                continue
            target = candidate["tests"][test_id][section_name]
            old_aggregate = target["sha256"]
            target["files"][ALLOWED_PATH] = mismatches[0]["live_sha256"]
            target["sha256"] = gate.canonical_digest(target["files"])
            changed_sections += 1
            section_audit[section_name] = {
                "mismatches": mismatches,
                "old_aggregate_sha256": old_aggregate,
                "new_aggregate_sha256": target["sha256"],
            }
        if section_audit:
            record_audit[test_id] = section_audit
    require(observed_mismatches == {ALLOWED_PATH},
            f"observed source drift set is not exact: {observed_mismatches}")
    require(changed_sections > 0, "no source-binding section changed")

    live_makefile = (root / ALLOWED_PATH).read_bytes()
    require(live_makefile.count(V9H_MAKEFILE_BLOCK) == 1,
            "V9H Makefile block is not unique")
    reconstructed = live_makefile.replace(V9H_MAKEFILE_BLOCK, b"", 1)
    reconstructed_sha = sha256_bytes(reconstructed)
    require(old_hashes == {reconstructed_sha},
            "reconstructed old Makefile hash does not match all records")
    byte_proof = {
        "operation": "remove_exact_v9h_makefile_target_block",
        "offset": live_makefile.index(V9H_MAKEFILE_BLOCK),
        "byte_count": len(V9H_MAKEFILE_BLOCK),
        "block_sha256": sha256_bytes(V9H_MAKEFILE_BLOCK),
        "old_sha256": reconstructed_sha,
        "new_sha256": sha256_bytes(live_makefile),
        "all_recorded_old_hashes_reconstructed": True,
    }

    before_projection_sha = canonical_digest(semantic_projection(before))
    after_projection_sha = canonical_digest(semantic_projection(candidate))
    require(before_projection_sha == after_projection_sha,
            "non-provenance architecture projection changed")

    manifest_tmp = manifest_path.with_suffix(".json.v9h-rebind.tmp")
    manifest_tmp.write_bytes(json_bytes(candidate))
    try:
        post_result = gate.evaluate(root, manifest_tmp)
        post_failures = gate_failures(post_result)
        require(post_result.get("evidence_errors") == [],
                "post-rebind evidence structural errors exist")
        require(post_result.get("overall_status") == "GREEN",
                "post-rebind architecture gates are not GREEN")
        require(all(not failures for failures in post_failures.values()),
                f"post-rebind checks failed: {post_failures}")
        after_bytes = manifest_tmp.read_bytes()
        audit = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.datetime.now(
                datetime.timezone.utc).isoformat(),
            "status": "PASS",
            "scope": {
                "object": "local RV64 directed architecture evidence",
                "operation": "one-file byte-proven source provenance rebind",
                "allowed_changed_paths": [ALLOWED_PATH],
                "production_rtl_changed": False,
                "directed_record_semantics_changed": False,
            },
            "manifest": {
                "path": manifest_path.relative_to(root).as_posix(),
                "before_sha256": sha256_bytes(original_bytes),
                "after_sha256": sha256_bytes(after_bytes),
                "before_semantic_projection_sha256": before_projection_sha,
                "after_semantic_projection_sha256": after_projection_sha,
                "design_id": design_id,
            },
            "current_rtl_binding": {
                "design_id": design_id,
                "file_count": len(rtl_files),
            },
            "current_module_replay": {
                "source_result": IFU_RESULT,
                "result_sha256": sha256_bytes(ifu_result_path.read_bytes()),
                "required": 109,
                "passed": 109,
                "failed": 0,
            },
            "current_variant_replay": {
                "required": 16,
                "compile_success": 16,
                "dynamic_rejected": 16,
            },
            "byte_delta_proofs": {ALLOWED_PATH: byte_proof},
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
                "only_makefile_source_path_drifted": True,
                "old_makefile_hash_byte_reconstructed": True,
                "current_module_replay_109_of_109": True,
                "current_variants_replay_16_of_16": True,
                "non_provenance_projection_unchanged": True,
                "all_provenance_and_source_manifests_live": True,
                "post_all_nine_gates_green": True,
            },
        }
        audit_tmp = audit_path.with_suffix(".json.tmp")
        audit_path.parent.mkdir(parents=True, exist_ok=True)
        audit_tmp.write_bytes(json_bytes(audit))
        os.replace(manifest_tmp, manifest_path)
        os.replace(audit_tmp, audit_path)
    finally:
        manifest_tmp.unlink(missing_ok=True)

    print(
        f"[V9H-ARCH-SOURCE-REBIND] paths=1 records={len(record_audit)} "
        f"sections={changed_sections} module=109/109 variants=16/16 "
        "pre=RED post=GREEN projection=UNCHANGED PASS"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V9H-ARCH-SOURCE-REBIND] FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
