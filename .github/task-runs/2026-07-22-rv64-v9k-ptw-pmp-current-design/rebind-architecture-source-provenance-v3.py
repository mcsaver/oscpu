#!/usr/bin/env python3
"""Byte-proven V9K-V3 rebind for two strengthened local RV64 bridge TBs."""

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


SCHEMA = "npc-rv64-v9k-v3-architecture-source-provenance-rebind-v1"
RUN_ID = "2026-07-22-rv64-v9k-ptw-pmp-current-design"
PTW_RESULT = "npc/rv64/eval/ppa/evidence/ptw-pmp-current.json"
ALLOWED_PATHS = (
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
)


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def canonical_digest(value: Any) -> str:
    return sha256_bytes(json.dumps(
        value, allow_nan=False, ensure_ascii=False,
        separators=(",", ":"), sort_keys=True).encode("utf-8"))


def json_bytes(value: Any) -> bytes:
    return (json.dumps(
        value, indent=2, ensure_ascii=False, sort_keys=True) + "\n").encode(
            "utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def semantic_projection(manifest: dict[str, Any]) -> dict[str, Any]:
    projected = copy.deepcopy(manifest)
    tests = projected.get("tests")
    if isinstance(tests, dict):
        for record in tests.values():
            if isinstance(record, dict):
                record.pop("provenance", None)
                record.pop("source_manifest", None)
    return projected


def gate_failures(result: dict[str, Any]) -> dict[str, list[str]]:
    return {
        gate_id: [
            check.get("check_id", "<missing-check-id>")
            for check in gate.get("checks", [])
            if check.get("status") != "GREEN"
        ]
        for gate_id, gate in result.get("gates", {}).items()
    }


def replace_once(
    value: bytes, new: bytes, old: bytes, label: str,
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


def remove_once(
    value: bytes, block: bytes, label: str,
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


def replace_span_once(
    value: bytes, start: bytes, end: bytes, old: bytes, label: str,
) -> tuple[bytes, dict[str, Any]]:
    require(value.count(start) == 1, f"{label} start is not unique")
    require(value.count(end) == 1, f"{label} end is not unique")
    begin = value.index(start)
    finish = value.index(end)
    require(begin < finish, f"{label} anchor order is invalid")
    removed = value[begin:finish]
    return value[:begin] + old + value[finish:], {
        "operation": "reverse_exact_anchored_span",
        "label": label,
        "offset": begin,
        "new_byte_count": len(removed),
        "old_byte_count": len(old),
        "new_sha256": sha256_bytes(removed),
        "old_sha256": sha256_bytes(old),
        "start_anchor_sha256": sha256_bytes(start),
        "end_anchor_sha256": sha256_bytes(end),
    }


def reconstruct_fetch_tb(live: bytes) -> tuple[bytes, dict[str, Any]]:
    old_task = """  task automatic drive_ad_write;
    input [1023:0] what;
    input [`XLEN-1:0] exp_addr;
    input [`XLEN-1:0] exp_wdata;
    integer waits;
    begin
      waits = 0;
      while ((ifu_axi_awvalid !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1(what, ifu_axi_awvalid, 1'b1);
      tb_check1(what, ifu_axi_wvalid, 1'b1);
      if (ifu_axi_awvalid === 1'b1) begin
        tb_check64_local(what, ifu_axi_awaddr, exp_addr);
        tb_check1("V9K IFU PTE write uses 8B AWSIZE",
                  ifu_axi_awsize == 3'd3, 1'b1);
        tb_check64_local(what, ifu_axi_wdata, exp_wdata);
        tb_check1(what, &ifu_axi_wstrb, 1'b1);
      end
      tick();                     // AW/W 握手(awready/wready=1 → aw_done/w_done)
      ifu_axi_bvalid = 1'b1;
      ifu_axi_bresp = RESP_OK;
      tick();                     // FSM 见 bvalid → 完成 → re-walk 本级
      ifu_axi_bvalid = 1'b0;
    end
  endtask

""".encode("utf-8")
    value, task_op = replace_span_once(
        live,
        b"  task automatic drive_ad_write;\n",
        b"  // A=0 ",
        old_task,
        "IFU split-ready A-update task",
    )
    new_marker = b"""      drive_ad_write(what, l0_leaf_addr, leaf_pte_a1);
      $display("[V9K-IFU-PTW-PMP-WRITE-ALLOW] read=allow write=allow checker=grant ad_update=1 awaddr=checked aw=once w=once awsize=3 split=aw-first stall=2 payload=stable b_after_both=1");
"""
    old_marker = b"""      $display("[V9K-IFU-PTW-PMP-WRITE-ALLOW] read=allow write=allow checker=grant ad_update=1 aw=1 w=1 awsize=3");
      drive_ad_write(what, l0_leaf_addr, leaf_pte_a1);
"""
    value, marker_op = replace_once(
        value, new_marker, old_marker, "IFU strengthened allow marker")
    return value, {"operations": [task_op, marker_op]}


def reconstruct_mem_tb(live: bytes) -> tuple[bytes, dict[str, Any]]:
    value = live
    operations: list[dict[str, Any]] = []
    for block, label in (
        (b"    integer stall_cycle;\n", "LSU allow stall-cycle counter"),
        (b"""      tb_check64("V9K LSU allow AWADDR equals checked PTE address",
                 lsu_axi_awaddr, dut.walk_pte_addr_w);
""", "LSU checker-address-to-AW oracle"),
    ):
        value, operation = remove_once(value, block, label)
        operations.append(operation)

    value, operation = replace_once(
        value,
        b"    reg [4:0] deny_owner_token;\n    integer hold_cycle;\n",
        b"    reg [4:0] deny_owner_token;\n",
        "LSU deny response hold counter",
    )
    operations.append(operation)

    old_handshake = b"""      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
"""
    value, operation = replace_span_once(
        value,
        b"      // Hold both channels for two cycles, then exercise both legal channel\n",
        b"""      lsu_axi_bvalid = 1'b1;
      lsu_axi_bresp = 2'b00;
      tick();
      lsu_axi_bvalid = 1'b0;

      if (write_access) begin
""",
        old_handshake,
        "LSU split-ready PTE write sequence",
    )
    operations.append(operation)
    value, operation = replace_once(
        value,
        b"""      tb_check1("sv39 A/D update write full strb", &lsu_axi_wstrb, 1'b1);

      lsu_axi_awready = 1'b1;
""",
        b"""      tb_check1("sv39 A/D update write full strb", &lsu_axi_wstrb, 1'b1);
      lsu_axi_awready = 1'b1;
""",
        "LSU pre-split formatting restoration",
    )
    operations.append(operation)

    new_allow_marker = b"""      $display("[V9K-LSU-PTW-PMP-WRITE-ALLOW] op=%0s read=allow write=allow checker=grant ad_update=1 awaddr=checked aw=once w=once awsize=3 split=%0s stall=2 payload=stable b_after_both=1",
               write_access ? "store" : "load",
               write_access ? "aw-first" : "w-first");
"""
    old_allow_marker = b"""      $display("[V9K-LSU-PTW-PMP-WRITE-ALLOW] op=%0s read=allow write=allow checker=grant ad_update=1 aw=1 w=1 awsize=3",
               write_access ? "store" : "load");
"""
    value, operation = replace_once(
        value, new_allow_marker, old_allow_marker,
        "LSU strengthened allow marker")
    operations.append(operation)

    value, operation = replace_span_once(
        value,
        b"      for (hold_cycle = 0; hold_cycle < 2;\n",
        b"      $display(\"[T4F-LSU-PTW-PMP-WRITE]",
        b"""      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
""",
        "LSU two-cycle held response oracle",
    )
    operations.append(operation)

    new_deny_marker = b"""      $display("[T4F-LSU-PTW-PMP-WRITE] op=%0s mode=%0s read=allow write=deny access-fault aw=0 w=0 owner=stable held=2",
"""
    old_deny_marker = b"""      $display("[T4F-LSU-PTW-PMP-WRITE] op=%0s mode=%0s read=allow write=deny access-fault aw=0 w=0 owner=stable",
"""
    value, operation = replace_once(
        value, new_deny_marker, old_deny_marker,
        "LSU held response marker")
    operations.append(operation)
    return value, {"operations": operations}


RECONSTRUCTORS: dict[
    str, Callable[[bytes], tuple[bytes, dict[str, Any]]]
] = {
    ALLOWED_PATHS[0]: reconstruct_fetch_tb,
    ALLOWED_PATHS[1]: reconstruct_mem_tb,
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
        "v9k_v3_architecture_hard_gates")
    ptw_tool = load_module(
        root / "npc/rv64/eval/ppa/tools/ptw_pmp_evidence.py",
        "v9k_v3_ptw_pmp_evidence")
    original_bytes = manifest_path.read_bytes()
    before = json.loads(original_bytes)
    require(before.get("schema") == gate.EVIDENCE_SCHEMA,
            "unexpected architecture manifest schema")
    tests = before.get("tests")
    expected_tests = set(gate.EVIDENCE_TEST.values())
    require(isinstance(tests, dict) and set(tests) == expected_tests,
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
    flat_failures = [item for rows in pre_failures.values() for item in rows]
    require(flat_failures, "pre-rebind source drift was not observed")
    require(all(item.endswith((".provenance_files", ".provenance_digest"))
                for item in flat_failures),
            f"pre-rebind has non-provenance failures: {pre_failures}")

    ptw_result_path = root / PTW_RESULT
    ptw_result = json.loads(ptw_result_path.read_text(encoding="utf-8"))
    module = ptw_result.get("module_aggregate", {})
    variants = ptw_result.get("variant_audit", {})
    require(ptw_result.get("status") == "PASS", "PTW-PMP result is not PASS")
    require(ptw_result.get("design_id") == design_id,
            "PTW-PMP result is cross-design")
    require(module.get("required") == module.get("passed") == 109
            and module.get("failed") == 0,
            "PTW-PMP module aggregate is not exact 109/109")
    require(variants.get("required") == 25
            and variants.get("compile_success") == 25
            and variants.get("dynamic_rejected") == 25,
            "PTW-PMP RTL variant audit is not exact 25/25")
    ptw_tool.parse_module_aggregate(
        root, root / f".github/task-runs/{RUN_ID}/evidence/"
        "module-aggregate/summary.txt")
    ptw_tool.validate_variants(
        root, root / f".github/task-runs/{RUN_ID}/evidence/"
        "mutations/summary.json")
    static_contract = ptw_tool.validate_static_contract(root)
    require(static_contract and all(static_contract.values()),
            "PTW-PMP static source contract is not fully PASS")
    source_bindings = ptw_result.get("provenance", {}).get(
        "source_bindings", {})
    for relative in ALLOWED_PATHS:
        require(source_bindings.get(relative) == sha256_bytes(
            (root / relative).read_bytes()),
            f"PTW-PMP result does not bind live source {relative}")

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
                    f"{test_id}: recorded {section_name} digest is invalid")
            mismatches: list[dict[str, str]] = []
            for relative, recorded_sha in sorted(files.items()):
                live_path = root / relative
                require(live_path.is_file(), f"{test_id}: missing {relative}")
                live_sha = sha256_bytes(live_path.read_bytes())
                if live_sha == recorded_sha:
                    continue
                require(relative in ALLOWED_PATHS,
                        f"{test_id}: drift outside V9K-V3 TBs at {relative}")
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
        require(old_hashes[relative] == {reconstructed_sha},
                f"{relative}: reconstructed={reconstructed_sha} "
                f"recorded={old_hashes[relative]}")
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

    manifest_tmp = manifest_path.with_suffix(".json.v9k-v3-rebind.tmp")
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
                "operation": "two-TB byte-proven V9K-V3 source rebind",
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
                "variants_required": 25,
                "variants_dynamic_rejected": 25,
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
                "only_v9k_v3_tb_paths_drifted": True,
                "all_old_source_hashes_byte_reconstructed": True,
                "current_module_replay_109_of_109": True,
                "current_variants_replay_25_of_25": True,
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
        f"[V9K-V3-ARCH-SOURCE-REBIND] paths=2 records={len(record_audit)} "
        f"sections={changed_sections} module=109/109 variants=25/25 "
        "pre=RED post=GREEN projection=UNCHANGED PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V9K-V3-ARCH-SOURCE-REBIND] FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
