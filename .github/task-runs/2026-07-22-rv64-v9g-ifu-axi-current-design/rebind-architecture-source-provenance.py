#!/usr/bin/env python3
"""Rebind byte-proven V9G local RV64 architecture evidence sources."""

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
from typing import Any, Callable


SCHEMA = "npc-rv64-v9g-architecture-source-provenance-rebind-v1"
RUN_ID = "2026-07-22-rv64-v9g-ifu-axi-current-design"
ALLOWED_PATHS = (
    "npc/rv64/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
)
IFU_RESULT = "npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain-current.json"


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


def load_ifu_evidence_module(root: pathlib.Path) -> Any:
    path = root / "npc/rv64/eval/ppa/tools/ifu_axi_flush_drain_evidence.py"
    spec = importlib.util.spec_from_file_location(
        "v9g_ifu_axi_rebind_evidence", path)
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


def remove_once(
    value: bytes,
    block: bytes,
    label: str,
) -> tuple[bytes, dict[str, Any]]:
    require(value.count(block) == 1, f"{label} is not unique")
    offset = value.index(block)
    return value.replace(block, b"", 1), {
        "operation": "remove_exact_block",
        "label": label,
        "offset": offset,
        "byte_count": len(block),
        "block_sha256": sha256_bytes(block),
    }


def replace_once(
    value: bytes,
    new: bytes,
    old: bytes,
    label: str,
) -> tuple[bytes, dict[str, Any]]:
    require(value.count(new) == 1, f"{label} is not unique")
    offset = value.index(new)
    return value.replace(new, old, 1), {
        "operation": "reverse_exact_replacement",
        "label": label,
        "offset": offset,
        "new_byte_count": len(new),
        "old_byte_count": len(old),
        "new_sha256": sha256_bytes(new),
        "old_sha256": sha256_bytes(old),
    }


def reconstruct_makefile(live: bytes) -> tuple[bytes, dict[str, Any]]:
    block = b"""# V9G IFU-AXI-G1 local RV64 instruction-fetch A-update write lifecycle
# closure. The bridge matrix covers independent AW/W acceptance, same-cycle
# flush plus final channel/B completion, repeated flush backpressure, payload
# stability and semantic quiet; the bridge+xbar trace proves B-owner release
# and a queued later master transaction. Compile-success RTL verification
# variants must be dynamically rejected. PPA remains unqualified.
.PHONY: check-ifu-axi-flush-drain
check-ifu-axi-flush-drain:
	@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/run-focused.sh)

"""
    reconstructed, operation = remove_once(live, block, "V9G Makefile target")
    return reconstructed, {"operations": [operation]}


def reconstruct_bridge_tb(live: bytes) -> tuple[bytes, dict[str, Any]]:
    value = live
    operations: list[dict[str, Any]] = []

    removals = (
        (
            b"    tb_check1(\"flush does not reissue accepted AW\", "
            b"ifu_axi_awvalid, 1'b0);\n",
            "accepted AW no-reissue oracle",
        ),
        (
            b"    tb_check1(\"flush blocks new fetch accept\", "
            b"fetch_req_ready, 1'b0);\n"
            b"    tb_check1(\"flush blocks fetch response\", "
            b"fetch_rsp_valid, 1'b0);\n"
            b"    tb_check1(\"flush blocks read address channel\", "
            b"ifu_axi_arvalid, 1'b0);\n",
            "single-flush semantic quiet oracles",
        ),
        (
            """    // flush 与第一笔 AW fire 同拍：accepted bit 必须记账，W/B 可在后续拍完成。
    reset_protocol_case();
    seed_ad_update(64'h0000_0000_2345_004f);
    mmu_flush = 1'b1;
    ifu_axi_awready = 1'b1;
    ifu_axi_wready = 1'b0;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_awready = 1'b0;
    #1;
    tb_check1("flush+first AW keeps owner", dut.state_q == S_AD_UPDATE_TB, 1'b1);
    tb_check1("flush+first AW records fire", dut.aw_done_q, 1'b1);
    tb_check1("flush+first AW leaves W pending", dut.w_done_q, 1'b0);
    ifu_axi_wready = 1'b1;
    tick();
    ifu_axi_wready = 1'b0;
    ifu_axi_bvalid = 1'b1;
    tick();
    ifu_axi_bvalid = 1'b0;
    check_dropped_write_quiet("flush+first-AW delayed completion drains to IDLE");

""".encode("utf-8"),
            "flush plus first AW case",
        ),
        (
            """    // 对称地，flush 与第一笔 W fire 同拍，AW/B 延后。
    reset_protocol_case();
    seed_ad_update(64'h0000_0000_3456_004f);
    mmu_flush = 1'b1;
    ifu_axi_awready = 1'b0;
    ifu_axi_wready = 1'b1;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_wready = 1'b0;
    #1;
    tb_check1("flush+first W keeps owner", dut.state_q == S_AD_UPDATE_TB, 1'b1);
    tb_check1("flush+first W records fire", dut.w_done_q, 1'b1);
    tb_check1("flush+first W leaves AW pending", dut.aw_done_q, 1'b0);
    ifu_axi_awready = 1'b1;
    tick();
    ifu_axi_awready = 1'b0;
    ifu_axi_bvalid = 1'b1;
    tick();
    ifu_axi_bvalid = 1'b0;
    check_dropped_write_quiet("flush+first-W delayed completion drains to IDLE");

""".encode("utf-8"),
            "flush plus first W case",
        ),
        (
            """    // accepted_next 对称边界：W 已完成，flush + 最后 AW fire + B fire 全同拍。
    reset_protocol_case();
    seed_ad_update(64'h0000_0000_6789_004f);
    ifu_axi_awready = 1'b0;
    ifu_axi_wready = 1'b1;
    tick();
    ifu_axi_wready = 1'b0;
    tb_check1("same-beat symmetric setup W accepted", dut.w_done_q, 1'b1);
    mmu_flush = 1'b1;
    ifu_axi_awready = 1'b1;
    ifu_axi_bvalid = 1'b1;
    ifu_axi_bresp = 2'b10;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_awready = 1'b0;
    ifu_axi_bvalid = 1'b0;
    ifu_axi_bresp = RESP_OK;
    check_dropped_write_quiet("flush+last-AW+B completes to IDLE");

""".encode("utf-8"),
            "flush plus last AW and B case",
        ),
        (
            """    // 两 accepted 位原先都为 0；AW/W/B 与 flush 全同拍仍必须一次完成。
    reset_protocol_case();
    seed_ad_update(64'h0000_0000_89ab_004f);
    mmu_flush = 1'b1;
    ifu_axi_awready = 1'b1;
    ifu_axi_wready = 1'b1;
    ifu_axi_bvalid = 1'b1;
    ifu_axi_bresp = 2'b10;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_awready = 1'b0;
    ifu_axi_wready = 1'b0;
    ifu_axi_bvalid = 1'b0;
    ifu_axi_bresp = RESP_OK;
    check_dropped_write_quiet("flush+AW+W+B completes to IDLE");

""".encode("utf-8"),
            "flush plus AW W B all-fire case",
        ),
        (
            b"      tb_check1(\"repeated flush blocks fetch accept\", "
            b"fetch_req_ready, 1'b0);\n"
            b"      tb_check1(\"repeated flush blocks fetch response\", "
            b"fetch_rsp_valid, 1'b0);\n"
            b"      tb_check1(\"repeated flush blocks read address\", "
            b"ifu_axi_arvalid, 1'b0);\n",
            "repeated-flush semantic quiet oracles",
        ),
        (
            b"    $display(\"[IFU-AXI-G1-FOCUSED] aw_first=1 w_first=1 "
            b"first_aw_with_flush=1 first_w_with_flush=1 "
            b"last_aw_b_with_flush=1 last_w_b_with_flush=1 "
            b"all_aw_w_b_with_flush=1 both_done_flush_b_error=1 "
            b"both_stalled_flush_cycles=2 dropped_bresp_error=1 "
            b"normal_bresp_error=1 payload_stability=1 drop_quiet=1 PASS\");\n",
            "V9G focused semantic marker",
        ),
    )
    for block, label in removals:
        value, operation = remove_once(value, block, label)
        operations.append(operation)

    new_both_done = b"""    mmu_flush = 1'b1;
    ifu_axi_bvalid = 1'b1;
    ifu_axi_bresp = 2'b10;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_bvalid = 1'b0;
    ifu_axi_bresp = RESP_OK;
    check_dropped_write_quiet("both-done flush+B-error drains to IDLE");
"""
    old_both_done = b"""    mmu_flush = 1'b1;
    ifu_axi_bvalid = 1'b1;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_bvalid = 1'b0;
    check_dropped_write_quiet("flush+B drains to IDLE");
"""
    value, operation = replace_once(
        value,
        new_both_done,
        old_both_done,
        "both-done flush plus B-error case",
    )
    operations.append(operation)
    return value, {"operations": operations}


RECONSTRUCTORS: dict[
    str, Callable[[bytes], tuple[bytes, dict[str, Any]]]
] = {
    "npc/rv64/Makefile": reconstruct_makefile,
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv": (
        reconstruct_bridge_tb
    ),
}


def refresh_existing_audit(
    root: pathlib.Path,
    manifest_path: pathlib.Path,
    audit_path: pathlib.Path,
    gate: Any,
) -> None:
    """Revalidate the final IFU result without rewriting the bound manifest."""

    require(audit_path.is_file(), "existing provenance audit is missing")
    audit = json.loads(audit_path.read_text(encoding="utf-8"))
    require(audit.get("schema") == SCHEMA, "unexpected provenance audit schema")
    require(audit.get("status") == "PASS", "provenance audit is not PASS")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest_bytes = manifest_path.read_bytes()
    declared_manifest = audit.get("manifest", {})
    require(
        declared_manifest.get("after_sha256") == sha256_bytes(manifest_bytes),
        "architecture manifest changed after provenance rebind",
    )
    require(
        declared_manifest.get("after_semantic_projection_sha256")
            == canonical_digest(semantic_projection(manifest)),
        "architecture semantic projection changed after provenance rebind",
    )
    post_result = gate.evaluate(root, manifest_path)
    post_failures = gate_failures(post_result)
    require(post_result.get("evidence_errors") == [],
            "current architecture evidence has structural errors")
    require(post_result.get("overall_status") == "GREEN",
            "current architecture hard gates are not GREEN")
    require(all(not failures for failures in post_failures.values()),
            f"current architecture hard-gate failures: {post_failures}")

    byte_proofs = audit.get("byte_delta_proofs", {})
    require(set(byte_proofs) == set(ALLOWED_PATHS),
            "byte-delta proof path inventory drifted")
    for relative in ALLOWED_PATHS:
        require(
            byte_proofs[relative].get("new_sha256")
                == sha256_bytes((root / relative).read_bytes()),
            f"live architecture source drifted after rebind: {relative}",
        )

    ifu_tool = load_ifu_evidence_module(root)
    ifu_result_path = root / IFU_RESULT
    ifu_result = json.loads(ifu_result_path.read_text(encoding="utf-8"))
    rtl_sha, _ = gate.rtl_binding(root)
    design_id = f"sha256:{rtl_sha}"
    module = ifu_result.get("module_aggregate", {})
    variants = ifu_result.get("variant_audit", {})
    require(ifu_result.get("status") == "PASS",
            "final IFU AXI result is not PASS")
    require(ifu_result.get("design_id") == design_id,
            "final IFU AXI result is cross-design")
    require(
        module.get("required") == 109
        and module.get("passed") == 109
        and module.get("failed") == 0,
        "final IFU AXI module aggregate is not exact 109/109",
    )
    require(
        variants.get("required") == 18
        and variants.get("compile_success") == 18
        and variants.get("dynamic_rejected") == 18,
        "final IFU AXI variant audit is not exact 18/18",
    )
    ifu_tool.parse_module_aggregate(
        root,
        root / f".github/task-runs/{RUN_ID}/evidence/"
        "module-aggregate/summary.txt",
    )
    ifu_tool.validate_variants(
        root,
        root / f".github/task-runs/{RUN_ID}/evidence/mutations/summary.json",
    )
    sources = ifu_result.get("provenance", {}).get("source_bindings", {})
    for relative in ALLOWED_PATHS:
        require(
            sources.get(relative) == sha256_bytes((root / relative).read_bytes()),
            f"final IFU AXI result does not bind live {relative}",
        )

    replay = audit.get("current_module_replay")
    require(isinstance(replay, dict), "current module replay record is missing")
    previous_sha = replay.get("result_sha256")
    final_sha = sha256_bytes(ifu_result_path.read_bytes())
    replay.update({
        "source_result": IFU_RESULT,
        "result_sha256": final_sha,
        "required": 109,
        "passed": 109,
        "failed": 0,
    })
    history = audit.setdefault("refresh_history", [])
    require(isinstance(history, list), "refresh history must be a list")
    history.append({
        "refreshed_at_utc": datetime.datetime.now(
            datetime.timezone.utc).isoformat(),
        "previous_result_sha256": previous_sha,
        "final_result_sha256": final_sha,
        "reason": (
            "contract and RTL-derivation source bindings were finalized after "
            "the architecture provenance rebind; the directed architecture "
            "manifest and its semantic projection remained byte-identical"
        ),
    })
    audit["refreshed_at_utc"] = history[-1]["refreshed_at_utc"]
    checks = audit.setdefault("checks", {})
    require(isinstance(checks, dict), "provenance audit checks are missing")
    checks["final_ifu_result_revalidated_after_source_document_freeze"] = True
    audit["post_gate_result"] = {
        "overall_status": post_result["overall_status"],
        "failures": post_failures,
    }
    temp = audit_path.with_suffix(".json.refresh.tmp")
    temp.write_bytes(json_bytes(audit))
    os.replace(temp, audit_path)
    print(
        "[V9G-ARCH-SOURCE-REBIND-REFRESH] manifest=UNCHANGED "
        "projection=UNCHANGED module=109/109 variants=18/18 gates=9/9 PASS"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path, required=True)
    parser.add_argument("--manifest", type=pathlib.Path, required=True)
    parser.add_argument("--audit", type=pathlib.Path, required=True)
    parser.add_argument("--refresh-audit", action="store_true")
    args = parser.parse_args()
    root = args.repo_root.resolve(strict=True)
    manifest_path = (root / args.manifest).resolve(strict=True)
    audit_path = (root / args.audit).resolve()
    require(manifest_path.is_relative_to(root), "manifest escapes repository")
    require(audit_path.is_relative_to(root), "audit escapes repository")

    gate = load_gate_module(root)
    if args.refresh_audit:
        refresh_existing_audit(root, manifest_path, audit_path, gate)
        return 0
    original_bytes = manifest_path.read_bytes()
    before = json.loads(original_bytes)
    require(before.get("schema") == gate.EVIDENCE_SCHEMA,
            "unexpected manifest schema")
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
            "pre-rebind evidence errors exist")
    require(pre_result.get("overall_status") == "RED",
            "pre-rebind gates must be RED")
    pre_failures = gate_failures(pre_result)
    require(set(pre_failures) == set(gate.GATE_IDS),
            "pre-rebind gate inventory drifted")
    for gate_id, test_id in gate.EVIDENCE_TEST.items():
        expected = {
            f"evidence.{test_id}.provenance_files",
            f"evidence.{test_id}.provenance_digest",
        }
        require(set(pre_failures[gate_id]) == expected,
                f"{gate_id} has non-provenance failures: "
                f"{pre_failures[gate_id]}")

    ifu_tool = load_ifu_evidence_module(root)
    ifu_result_path = root / IFU_RESULT
    ifu_result = json.loads(ifu_result_path.read_text(encoding="utf-8"))
    ifu_sources = ifu_result.get("provenance", {}).get("source_bindings", {})
    module = ifu_result.get("module_aggregate", {})
    variants = ifu_result.get("variant_audit", {})
    require(ifu_result.get("status") == "PASS",
            "IFU AXI lifecycle result is not PASS")
    require(ifu_result.get("design_id") == design_id,
            "IFU AXI lifecycle result is cross-design")
    require(
        module.get("required") == 109
        and module.get("passed") == 109
        and module.get("failed") == 0,
        "IFU AXI lifecycle module aggregate is not exact 109/109",
    )
    require(
        variants.get("required") == 18
        and variants.get("compile_success") == 18
        and variants.get("dynamic_rejected") == 18,
        "IFU AXI lifecycle variant audit is not exact 18/18",
    )
    ifu_tool.parse_module_aggregate(
        root,
        root / f".github/task-runs/{RUN_ID}/evidence/"
        "module-aggregate/summary.txt",
    )
    ifu_tool.validate_variants(
        root,
        root / f".github/task-runs/{RUN_ID}/evidence/mutations/summary.json",
    )
    for relative in ALLOWED_PATHS:
        require(
            ifu_sources.get(relative)
                == sha256_bytes((root / relative).read_bytes()),
            f"IFU AXI lifecycle result does not bind live {relative}",
        )

    candidate = copy.deepcopy(before)
    observed_mismatches: set[str] = set()
    old_hashes: dict[str, set[str]] = {
        relative: set() for relative in ALLOWED_PATHS}
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
                require(live_path.is_file(),
                        f"{test_id}: missing source {relative}")
                live_sha = sha256_bytes(live_path.read_bytes())
                if live_sha == recorded_sha:
                    continue
                require(relative in ALLOWED_PATHS,
                        f"{test_id}: drift outside allowed source set at "
                        f"{relative}")
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
    require(observed_mismatches == set(ALLOWED_PATHS),
            "observed source drift set is not exact: "
            f"{sorted(observed_mismatches)}")
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
    require(before_projection_sha == after_projection_sha,
            "non-provenance architecture projection changed")

    manifest_tmp = manifest_path.with_suffix(".json.v9g-rebind.tmp")
    manifest_tmp.write_bytes(json_bytes(candidate))
    try:
        post_result = gate.evaluate(root, manifest_tmp)
        post_failures = gate_failures(post_result)
        require(post_result.get("evidence_errors") == [],
                "post-rebind evidence errors exist")
        require(post_result.get("overall_status") == "GREEN",
                "post-rebind gates are not GREEN")
        require(all(not failures for failures in post_failures.values()),
                f"post-rebind checks failed: {post_failures}")

        after_bytes = manifest_tmp.read_bytes()
        audit = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.datetime.now(
                datetime.timezone.utc).isoformat(),
            "status": "PASS",
            "scope": {
                "object": (
                    "local RV64 Verilog/SystemVerilog architecture evidence"),
                "operation": "two-file byte-proven source provenance rebind",
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
                "source_result": IFU_RESULT,
                "result_sha256": sha256_bytes(ifu_result_path.read_bytes()),
                "required": 109,
                "passed": 109,
                "failed": 0,
            },
            "current_variant_replay": {
                "required": 18,
                "compile_success": 18,
                "dynamic_rejected": 18,
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
                "only_exact_two_source_paths_drifted": True,
                "both_old_source_hashes_byte_reconstructed": True,
                "current_module_replay_109_of_109": True,
                "current_variants_replay_18_of_18": True,
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
        f"[V9G-ARCH-SOURCE-REBIND] paths={len(ALLOWED_PATHS)} "
        f"records={len(record_audit)} sections={changed_sections} "
        "module=109/109 variants=18/18 pre=RED post=GREEN "
        "projection=UNCHANGED PASS"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V9G-ARCH-SOURCE-REBIND] FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
