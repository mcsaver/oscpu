#!/usr/bin/env python3
"""Rebind byte-proven V9K local RV64 architecture evidence sources."""

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


SCHEMA = "npc-rv64-v9k-architecture-source-provenance-rebind-v1"
RUN_ID = "2026-07-22-rv64-v9k-ptw-pmp-current-design"
PTW_RESULT = "npc/rv64/eval/ppa/evidence/ptw-pmp-current.json"
ALLOWED_PATHS = (
    "npc/rv64/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
)


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


def remove_span_once(
    value: bytes,
    start: bytes,
    end: bytes,
    label: str,
) -> tuple[bytes, dict[str, Any]]:
    require(value.count(start) == 1, f"{label} start anchor is not unique")
    require(value.count(end) == 1, f"{label} end anchor is not unique")
    begin = value.index(start)
    finish = value.index(end)
    require(begin < finish, f"{label} anchor order is invalid")
    removed = value[begin:finish]
    return value[:begin] + value[finish:], {
        "operation": "remove_exact_anchored_span",
        "label": label,
        "offset": begin,
        "byte_count": len(removed),
        "block_sha256": sha256_bytes(removed),
        "start_anchor_sha256": sha256_bytes(start),
        "end_anchor_sha256": sha256_bytes(end),
    }


def reconstruct_makefile(live: bytes) -> tuple[bytes, dict[str, Any]]:
    block = b"""# V9K PTW-PMP-G1 local RV64 page-table PTE WRITE protection closure.  IFU
# and LSU walkers bind independent 8B/S-mode/WRITE checks, access-fault
# response ownership, F=2/4/6 instruction-prefix preservation, deny-cycle
# AW/W quiet and granted A/D update traffic to current-source RTL variants.
# This gate does not qualify physical PPA.
.PHONY: check-ptw-pmp
check-ptw-pmp:
\t@bash $(abspath ../../.github/task-runs/2026-07-22-rv64-v9k-ptw-pmp-current-design/run-focused.sh)

"""
    reconstructed, operation = remove_once(
        live, block, "V9K PTW-PMP Makefile target")
    return reconstructed, {"operations": [operation]}


def reconstruct_fetch_tb(live: bytes) -> tuple[bytes, dict[str, Any]]:
    value = live
    operations: list[dict[str, Any]] = []
    removals = (
        (b"  wire [2:0] ifu_axi_awsize;\n", "IFU AWSIZE observation wire"),
        (
            b"    .ifu_axi_awsize_o(ifu_axi_awsize),\n",
            "IFU AWSIZE observation port",
        ),
        (
            b"""        tb_check1("V9K IFU PTE write uses 8B AWSIZE",
                  ifu_axi_awsize == 3'd3, 1'b1);
""",
            "IFU A-update AWSIZE oracle",
        ),
        (
            b"""    ptw_ad_write_pmp_frontier_deny(3'd2);
    ptw_ad_write_pmp_frontier_deny(3'd4);
    ptw_ad_write_pmp_frontier_deny(3'd6);
    ptw_ad_write_pmp_partial_cover_deny();
""",
            "IFU frontier and partial-cover calls",
        ),
    )
    for block, label in removals:
        value, operation = remove_once(value, block, label)
        operations.append(operation)

    new_allow = b"""      while (ifu_axi_rready !== 1'b1) tick();
      ifu_axi_rdata = leaf_pte_a0;
      ifu_axi_rresp = RESP_OK;
      ifu_axi_rvalid = 1'b1;
      #1;
      tb_check1("V9K IFU PTE WRITE checker grants RW region",
                dut.walk_pte_write_pmp_fault_w, 1'b0);
      tb_check1("V9K IFU allow has no deny event",
                dut.walk_ad_write_deny_w, 1'b0);
      tick();
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("V9K IFU allow enters A-update",
                dut.state_q == S_AD_UPDATE_TB, 1'b1);
      tb_check1("V9K IFU allow presents AW", ifu_axi_awvalid, 1'b1);
      tb_check1("V9K IFU allow presents W", ifu_axi_wvalid, 1'b1);
      tb_check1("V9K IFU allow presents 8B AWSIZE",
                ifu_axi_awsize == 3'd3, 1'b1);
      $display("[V9K-IFU-PTW-PMP-WRITE-ALLOW] read=allow write=allow checker=grant ad_update=1 aw=1 w=1 awsize=3");
"""
    old_allow = (
        "      drive_r(leaf_pte_a0, RESP_OK);          "
        "// A=0 leaf → 触发 A 更新\n"
    ).encode("utf-8")
    value, operation = replace_once(
        value, new_allow, old_allow, "IFU direct checker grant observation")
    operations.append(operation)

    start = (
        "  // V9K current-design rebinding: after F=2/4/6 successful "
        "instruction\n"
    ).encode("utf-8")
    end = (
        "  // T4F：PTE 区域允许隐式 READ、拒绝隐式 WRITE，最终取指 PA 由后续\n"
    ).encode("utf-8")
    value, operation = remove_span_once(
        value, start, end, "IFU F2/F4/F6 and 8B partial-cover tasks")
    operations.append(operation)
    return value, {"operations": operations}


def reconstruct_mem_tb(live: bytes) -> tuple[bytes, dict[str, Any]]:
    value = live
    operations: list[dict[str, Any]] = []
    removals = (
        (b"  wire [2:0] lsu_axi_awsize;\n", "LSU AWSIZE observation wire"),
        (
            b"    .lsu_axi_awsize_o(lsu_axi_awsize),\n",
            "LSU AWSIZE observation port",
        ),
        (
            b"""      tb_check1("V9K LSU PTE WRITE checker grants RW region",
                dut.walk_pte_write_pmp_fault_w, 1'b0);
      tb_check1("V9K LSU allow has no deny event",
                dut.walk_ad_write_deny_w, 1'b0);
""",
            "LSU direct checker grant observation",
        ),
        (
            b"""      tb_check1("V9K LSU PTE write uses 8B AWSIZE",
                lsu_axi_awsize == 3'd3, 1'b1);
""",
            "LSU A-update AWSIZE oracle",
        ),
        (
            b"""      $display("[V9K-LSU-PTW-PMP-WRITE-ALLOW] op=%0s read=allow write=allow checker=grant ad_update=1 aw=1 w=1 awsize=3",
               write_access ? "store" : "load");
""",
            "LSU granted PTE write marker",
        ),
        (b"    input partial_cover;\n", "LSU partial-cover task input"),
        (b"    reg [4:0] deny_owner_token;\n", "LSU deny owner token snapshot"),
        (
            b"      deny_owner_token = mem0_req_owner_token;\n",
            "LSU accepted token capture",
        ),
        (
            b"""      // Poison the live request inputs after acceptance; the response must
      // retain the registered load/store owner, token, epoch and original VA.
      mem0_req_write = !write_access;
      mem0_req_addr = DATA_VA_AD + 64'h80;
""",
            "LSU accepted-owner input replacement stimulus",
        ),
        (
            b"""      if (partial_cover) begin
        pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
        pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
        pmpcfg[0 +: 8] = 8'h0b;
        pmpcfg[8 +: 8] = 8'h1f;
        pmpaddr[0 +: `XLEN] = (ROOT_PT + 64'd20) >> 2;
        pmpaddr[`XLEN +: `XLEN] = {`XLEN{1'b1}};
      end
""",
            "LSU 8B partial-cover PMP setup",
        ),
        (
            b"""      tb_check1("V9K LSU deny response owner kind is stable",
                mem0_rsp_owner_kind == (write_access ? 2'b01 : 2'b00), 1'b1);
      tb_check1("V9K LSU deny response owner token is stable",
                mem0_rsp_owner_token == deny_owner_token, 1'b1);
      tb_check1("V9K LSU deny response epoch is stable",
                mem0_rsp_mmu_epoch == 2'b01, 1'b1);
      tb_check64("V9K LSU deny response fault tval is original VA",
                 mem0_rsp_fault_tval, DATA_VA_AD);
""",
            "LSU denied response owner snapshot oracles",
        ),
    )
    for block, label in removals:
        value, operation = remove_once(value, block, label)
        operations.append(operation)

    new_allow_prefix = b"""      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      orig_pte = (SUPERPAGE_PPN << 10) | leaf_flags;
"""
    old_allow_prefix = b"""      orig_pte = (SUPERPAGE_PPN << 10) | leaf_flags;
"""
    value, operation = replace_once(
        value,
        new_allow_prefix,
        old_allow_prefix,
        "LSU allow task local PMP initialization",
    )
    operations.append(operation)

    new_marker = b"""      $display("[T4F-LSU-PTW-PMP-WRITE] op=%0s mode=%0s read=allow write=deny access-fault aw=0 w=0 owner=stable",
               write_access ? "store" : "load",
               partial_cover ? "partial8" : "readonly");
"""
    old_marker = b"""      $display("[T4F-LSU-PTW-PMP-WRITE] op=%0s read=allow write=deny access-fault aw=0 w=0",
               write_access ? "store" : "load");
"""
    value, operation = replace_once(
        value, new_marker, old_marker, "LSU deny marker extension")
    operations.append(operation)

    new_calls = b"""    sv39_ad_write_pmp_deny("T4F load A-update PTE write denied", 1'b0,
                           LEAF_NO_ACCESS_FLAGS, 1'b0);
    sv39_ad_write_pmp_deny("T4F store D-update PTE write denied", 1'b1,
                           LEAF_NO_DIRTY_FLAGS, 1'b0);
    sv39_ad_write_pmp_deny("V9K load 8B partial-cover PTE write denied", 1'b0,
                           LEAF_NO_ACCESS_FLAGS, 1'b1);
"""
    old_calls = b"""    sv39_ad_write_pmp_deny("T4F load A-update PTE write denied", 1'b0,
                           LEAF_NO_ACCESS_FLAGS);
    sv39_ad_write_pmp_deny("T4F store D-update PTE write denied", 1'b1,
                           LEAF_NO_DIRTY_FLAGS);
"""
    value, operation = replace_once(
        value, new_calls, old_calls, "LSU deny and partial-cover calls")
    operations.append(operation)
    return value, {"operations": operations}


RECONSTRUCTORS: dict[
    str, Callable[[bytes], tuple[bytes, dict[str, Any]]]
] = {
    ALLOWED_PATHS[0]: reconstruct_makefile,
    ALLOWED_PATHS[1]: reconstruct_fetch_tb,
    ALLOWED_PATHS[2]: reconstruct_mem_tb,
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
        "v9k_architecture_hard_gates",
    )
    ptw_tool = load_module(
        root / "npc/rv64/eval/ppa/tools/ptw_pmp_evidence.py",
        "v9k_ptw_pmp_evidence",
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

    ptw_result_path = root / PTW_RESULT
    ptw_result = json.loads(ptw_result_path.read_text(encoding="utf-8"))
    module = ptw_result.get("module_aggregate", {})
    variants = ptw_result.get("variant_audit", {})
    require(ptw_result.get("status") == "PASS", "PTW-PMP result is not PASS")
    require(ptw_result.get("design_id") == design_id,
            "PTW-PMP result is cross-design")
    require(
        module.get("required") == 109
        and module.get("passed") == 109
        and module.get("failed") == 0,
        "PTW-PMP module aggregate is not exact 109/109",
    )
    require(
        variants.get("required") == 18
        and variants.get("compile_success") == 18
        and variants.get("dynamic_rejected") == 18,
        "PTW-PMP RTL variant audit is not exact 18/18",
    )
    ptw_tool.parse_module_aggregate(
        root,
        root / f".github/task-runs/{RUN_ID}/evidence/module-aggregate/summary.txt",
    )
    ptw_tool.validate_variants(
        root,
        root / f".github/task-runs/{RUN_ID}/evidence/mutations/summary.json",
    )
    static_contract = ptw_tool.validate_static_contract(root)
    require(static_contract and all(static_contract.values()),
            "PTW-PMP static source contract is not fully PASS")
    source_bindings = ptw_result.get("provenance", {}).get(
        "source_bindings", {})
    for relative in ALLOWED_PATHS:
        require(
            source_bindings.get(relative)
                == sha256_bytes((root / relative).read_bytes()),
            f"PTW-PMP result does not bind live source {relative}",
        )

    candidate = copy.deepcopy(before)
    observed_mismatches: set[str] = set()
    old_hashes: dict[str, set[str]] = {
        relative: set() for relative in ALLOWED_PATHS
    }
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
                require(relative in ALLOWED_PATHS,
                        f"{test_id}: drift outside V9K sources at {relative}")
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
            f"observed source drift set is not exact: {observed_mismatches}")
    require(changed_sections > 0, "no source-binding section changed")

    byte_proofs: dict[str, Any] = {}
    for relative in ALLOWED_PATHS:
        live = (root / relative).read_bytes()
        reconstructed, proof = RECONSTRUCTORS[relative](live)
        reconstructed_sha = sha256_bytes(reconstructed)
        require(
            old_hashes[relative] == {reconstructed_sha},
            f"{relative}: reconstructed old hash does not match records; "
            f"reconstructed={reconstructed_sha} recorded={old_hashes[relative]}",
        )
        proof.update({
            "old_sha256": reconstructed_sha,
            "new_sha256": sha256_bytes(live),
            "all_recorded_old_hashes_reconstructed": True,
        })
        byte_proofs[relative] = proof

    before_projection_sha = canonical_digest(semantic_projection(before))
    after_projection_sha = canonical_digest(semantic_projection(candidate))
    require(before_projection_sha == after_projection_sha,
            "non-provenance architecture projection changed")

    manifest_tmp = manifest_path.with_suffix(".json.v9k-rebind.tmp")
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
            "current_ptw_pmp_replay": {
                "source_result": PTW_RESULT,
                "result_sha256": sha256_bytes(ptw_result_path.read_bytes()),
                "module_required": 109,
                "module_passed": 109,
                "variants_required": 18,
                "variants_dynamic_rejected": 18,
                "static_contract_checks": len(static_contract),
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
                "only_v9k_source_paths_drifted": True,
                "all_old_source_hashes_byte_reconstructed": True,
                "current_module_replay_109_of_109": True,
                "current_variants_replay_18_of_18": True,
                "current_static_contract_fully_passed": True,
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
        f"[V9K-ARCH-SOURCE-REBIND] paths=3 records={len(record_audit)} "
        f"sections={changed_sections} module=109/109 variants=18/18 "
        "pre=RED post=GREEN projection=UNCHANGED PASS"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V9K-ARCH-SOURCE-REBIND] FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
