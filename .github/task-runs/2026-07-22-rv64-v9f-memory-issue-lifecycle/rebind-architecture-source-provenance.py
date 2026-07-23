#!/usr/bin/env python3
"""Rebind three byte-proven local RV64 architecture evidence sources."""

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


SCHEMA = "npc-rv64-v9f-architecture-source-provenance-rebind-v1"
RUN_ID = "2026-07-22-rv64-v9f-memory-issue-lifecycle"
ALLOWED_PATHS = (
    "npc/rv64/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_inflight_queue.sv",
)
MEMORY_RESULT = "npc/rv64/eval/ppa/evidence/memory-issue-lifecycle-current.json"


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


def load_gate_module(root: pathlib.Path) -> Any:
    tools = root / "npc/rv64/eval/ppa/tools"
    sys.path.insert(0, str(tools))
    import architecture_hard_gates  # type: ignore

    return architecture_hard_gates


def load_memory_evidence_module(root: pathlib.Path) -> Any:
    path = root / "npc/rv64/eval/ppa/tools/memory_issue_lifecycle_evidence.py"
    spec = importlib.util.spec_from_file_location(
        "v9f_memory_lifecycle_rebind_evidence", path)
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


def reconstruct_makefile(live: bytes) -> tuple[bytes, dict[str, Any]]:
    block = b"""# V9F MEM-ISSUE-G1 / MIQ-FLUSH-G1 local RV64 memory-transaction lifecycle
# closure. The focused traces prove atomic dual-memory capture, single-port
# terminal ordering, exact request-fire/consume/MIQ-owner identity under
# backpressure and competing owners, plus wrapped/no-pop DRAIN flush
# compaction. Eleven compile-success RTL verification variants must be
# dynamically rejected. PPA remains unqualified.
.PHONY: check-memory-issue-lifecycle
check-memory-issue-lifecycle:
\t@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/run-focused.sh)

"""
    require(live.count(block) == 1, "V9F Makefile target block is not unique")
    offset = live.index(block)
    return live.replace(block, b"", 1), {
        "operation": "remove_exact_block",
        "offset": offset,
        "byte_count": len(block),
        "block_sha256": sha256_bytes(block),
    }


def reconstruct_int_tb(live: bytes) -> tuple[bytes, dict[str, Any]]:
    start = b"  // V9F current-design memory lifecycle.  The plain-memory pair is first\n"
    next_task = b"  task automatic run_lane1_prf_wb_wakeup;\n"
    branch = (
        b"`elsif V9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED\n"
        b"    run_v9f_memory_issue_lifecycle();\n"
    )
    require(live.count(start) == 1, "V9F integer-backend task start is not unique")
    require(live.count(next_task) == 1, "integer-backend next task is not unique")
    require(live.count(branch) == 1, "V9F integer-backend branch is not unique")
    start_offset = live.index(start)
    end_offset = live.index(next_task, start_offset)
    require(end_offset > start_offset, "V9F integer-backend task bounds are invalid")
    task_block = live[start_offset:end_offset]
    reconstructed = live[:start_offset] + live[end_offset:]
    reconstructed = reconstructed.replace(branch, b"", 1)
    return reconstructed, {
        "operation": "remove_exact_task_and_focused_branch",
        "task_offset": start_offset,
        "task_byte_count": len(task_block),
        "task_sha256": sha256_bytes(task_block),
        "branch_byte_count": len(branch),
        "branch_sha256": sha256_bytes(branch),
    }


def replace_once(value: bytes, old: bytes, new: bytes, label: str) -> bytes:
    require(value.count(old) == 1, f"{label} is not unique")
    return value.replace(old, new, 1)


def reconstruct_miq_tb(live: bytes) -> tuple[bytes, dict[str, Any]]:
    new_comment = (
        "    // flush 不带 pop：transport-irrevocable DRAIN head 必须保留，\n"
        "    // LOAD 被清；head valid 不能替代实际 pop fire 作为扣除条件。\n"
    ).encode("utf-8")
    old_comment = (
        "    // flush 不带 pop：DRAIN 必须保留，LOAD 被清；kill 不得误杀 retired DRAIN。\n"
    ).encode("utf-8")
    no_pop_check = (
        b"    #1;\n"
        b"    tb_check1(\"flush stalled DRAIN head is valid without pop\",\n"
        b"              head_valid && !pop_valid, 1'b1);\n"
    )
    marker_line = (
        b"    $display(\"[MIQ-FLUSH-G1-FOCUSED] "
        b"consumed_drain_removed=1 stalled_head_no_pop_preserved=1 "
        b"unconsumed_drain_preserved=1 survivor_identity_match=1 "
        b"wrapped_order=1 PASS\");\n"
    )
    reconstructed = replace_once(
        live, new_comment, old_comment, "MIQ no-pop comment")
    reconstructed = replace_once(
        reconstructed, no_pop_check, b"", "MIQ no-pop check")
    reconstructed = replace_once(
        reconstructed, marker_line, b"", "MIQ focused marker")
    delta = len(live) - len(reconstructed)
    return reconstructed, {
        "operation": "reverse_exact_comment_check_and_marker_edits",
        "live_byte_count": len(live),
        "reconstructed_byte_count": len(reconstructed),
        "net_added_bytes": delta,
    }


RECONSTRUCTORS = {
    "npc/rv64/Makefile": reconstruct_makefile,
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv": reconstruct_int_tb,
    "npc/rv64/testbench/tests/tb_ooo_mem_inflight_queue.sv": reconstruct_miq_tb,
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

    gate = load_gate_module(root)
    original_bytes = manifest_path.read_bytes()
    before = json.loads(original_bytes)
    require(before.get("schema") == gate.EVIDENCE_SCHEMA, "unexpected manifest schema")
    tests = before.get("tests")
    expected_tests = set(gate.EVIDENCE_TEST.values())
    require(isinstance(tests, dict), "architecture tests must be an object")
    require(set(tests) == expected_tests, "architecture record inventory is not exact")
    rtl_sha, rtl_files = gate.rtl_binding(root)
    design_id = f"sha256:{rtl_sha}"
    require(before.get("design_id") == design_id, "architecture manifest is cross-design")

    pre_result = gate.evaluate(root, manifest_path)
    require(pre_result.get("evidence_errors") == [], "pre-rebind evidence errors exist")
    require(pre_result.get("overall_status") == "RED", "pre-rebind gates must be RED")
    pre_failures = gate_failures(pre_result)
    require(set(pre_failures) == set(gate.GATE_IDS), "pre-rebind gate inventory drifted")
    for gate_id, test_id in gate.EVIDENCE_TEST.items():
        expected = {
            f"evidence.{test_id}.provenance_files",
            f"evidence.{test_id}.provenance_digest",
        }
        require(
            set(pre_failures[gate_id]) == expected,
            f"{gate_id} has non-provenance failures: {pre_failures[gate_id]}",
        )

    memory_tool = load_memory_evidence_module(root)
    memory_result_path = root / MEMORY_RESULT
    memory_result = json.loads(memory_result_path.read_text(encoding="utf-8"))
    memory_provenance = memory_result.get("provenance", {})
    memory_sources = memory_provenance.get("source_bindings", {})
    memory_module = memory_result.get("module_aggregate", {})
    require(memory_result.get("status") == "PASS", "memory lifecycle result is not PASS")
    require(memory_result.get("design_id") == design_id, "memory lifecycle result is cross-design")
    require(
        memory_module.get("required") == 109
        and memory_module.get("passed") == 109
        and memory_module.get("failed") == 0,
        "memory lifecycle module aggregate is not exact 109/109",
    )
    memory_tool.parse_module_aggregate(
        root,
        root / f".github/task-runs/{RUN_ID}/evidence/module-aggregate/summary.txt",
    )
    for relative in ALLOWED_PATHS:
        require(
            memory_sources.get(relative) == sha256_bytes((root / relative).read_bytes()),
            f"memory lifecycle result does not bind live {relative}",
        )

    candidate = copy.deepcopy(before)
    observed_mismatches: set[str] = set()
    old_hashes: dict[str, set[str]] = {relative: set() for relative in ALLOWED_PATHS}
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
            require(isinstance(section, dict), f"{test_id}: {section_name} is missing")
            files = section.get("files")
            require(isinstance(files, dict), f"{test_id}: {section_name}.files missing")
            require(
                section.get("sha256") == gate.canonical_digest(files),
                f"{test_id}: recorded {section_name} aggregate is invalid",
            )
            mismatches: list[dict[str, str]] = []
            for relative, recorded_sha in sorted(files.items()):
                live_path = root / relative
                require(live_path.is_file(), f"{test_id}: missing source {relative}")
                live_sha = sha256_bytes(live_path.read_bytes())
                if live_sha == recorded_sha:
                    continue
                require(
                    relative in ALLOWED_PATHS,
                    f"{test_id}: drift outside allowed source set at {relative}",
                )
                observed_mismatches.add(relative)
                old_hashes[relative].add(recorded_sha)
                mismatches.append({
                    "path": relative,
                    "recorded_sha256": recorded_sha,
                    "live_sha256": live_sha,
                })
            if not mismatches:
                continue
            target = candidate["tests"][test_id][section_name]
            old_aggregate = target["sha256"]
            for mismatch in mismatches:
                target["files"][mismatch["path"]] = mismatch["live_sha256"]
            target["sha256"] = gate.canonical_digest(target["files"])
            changed_sections += 1
            section_audit[section_name] = {
                "mismatches": mismatches,
                "old_aggregate_sha256": old_aggregate,
                "new_aggregate_sha256": target["sha256"],
            }
        if section_audit:
            record_audit[test_id] = section_audit
    require(
        observed_mismatches == set(ALLOWED_PATHS),
        f"observed source drift set is not exact: {sorted(observed_mismatches)}",
    )
    require(changed_sections > 0, "no source-binding section changed")

    byte_proofs: dict[str, Any] = {}
    for relative in ALLOWED_PATHS:
        live = (root / relative).read_bytes()
        reconstructed, details = RECONSTRUCTORS[relative](live)
        reconstructed_sha = sha256_bytes(reconstructed)
        require(
            old_hashes[relative] == {reconstructed_sha},
            f"{relative}: reconstructed old hash does not match all records: "
            f"recorded={old_hashes[relative]} reconstructed={reconstructed_sha}",
        )
        byte_proofs[relative] = {
            **details,
            "old_sha256": reconstructed_sha,
            "new_sha256": sha256_bytes(live),
            "all_recorded_old_hashes_reconstructed": True,
        }

    before_projection_sha = canonical_digest(semantic_projection(before))
    after_projection_sha = canonical_digest(semantic_projection(candidate))
    require(
        before_projection_sha == after_projection_sha,
        "non-provenance architecture projection changed",
    )

    manifest_tmp = manifest_path.with_suffix(".json.v9f-rebind.tmp")
    manifest_tmp.write_bytes(json_bytes(candidate))
    try:
        post_result = gate.evaluate(root, manifest_tmp)
        post_failures = gate_failures(post_result)
        require(post_result.get("evidence_errors") == [], "post-rebind evidence errors exist")
        require(post_result.get("overall_status") == "GREEN", "post-rebind gates are not GREEN")
        require(
            all(not failures for failures in post_failures.values()),
            f"post-rebind checks failed: {post_failures}",
        )
        for record in candidate["tests"].values():
            for section_name in ("provenance", "source_manifest"):
                section = record.get(section_name)
                if section_name == "source_manifest" and section is None:
                    continue
                for relative, expected_sha in section["files"].items():
                    require(
                        sha256_bytes((root / relative).read_bytes()) == expected_sha,
                        f"post-rebind source drift remains at {relative}",
                    )

        after_bytes = manifest_tmp.read_bytes()
        audit = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.datetime.now(
                datetime.timezone.utc).isoformat(),
            "status": "PASS",
            "scope": {
                "object": "local RV64 Verilog/SystemVerilog architecture evidence",
                "operation": "three-file byte-proven source provenance rebind",
                "allowed_changed_paths": list(ALLOWED_PATHS),
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
                "source_result": MEMORY_RESULT,
                "result_sha256": sha256_bytes(memory_result_path.read_bytes()),
                "required": 109,
                "passed": 109,
                "failed": 0,
            },
            "byte_delta_proofs": byte_proofs,
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
                "only_exact_three_source_paths_drifted": True,
                "all_three_old_source_hashes_byte_reconstructed": True,
                "current_module_replay_109_of_109": True,
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
        f"[V9F-ARCH-SOURCE-REBIND] paths={len(ALLOWED_PATHS)} "
        f"records={len(record_audit)} sections={changed_sections} "
        "module=109/109 pre=RED post=GREEN projection=UNCHANGED PASS"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V9F-ARCH-SOURCE-REBIND] FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
