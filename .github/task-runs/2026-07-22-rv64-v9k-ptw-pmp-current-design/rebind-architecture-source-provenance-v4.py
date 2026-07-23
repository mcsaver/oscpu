#!/usr/bin/env python3
"""Byte-proven V9K-V4 rebind for the strengthened LSU PTW-PMP bridge TB."""

from __future__ import annotations

import argparse
import copy
import datetime
import importlib.util
import json
import os
import pathlib
import sys
from typing import Any


SCHEMA = "npc-rv64-v9k-v4-architecture-source-provenance-rebind-v1"
RUN_ID = "2026-07-22-rv64-v9k-ptw-pmp-current-design"
PTW_RESULT = "npc/rv64/eval/ppa/evidence/ptw-pmp-current.json"
ALLOWED_PATH = "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv"
BASE_SCRIPT = (
    ".github/task-runs/2026-07-22-rv64-v9k-ptw-pmp-current-design/"
    "rebind-architecture-source-provenance-v3.py"
)


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def reconstruct_v3_mem_tb(base: Any, live: bytes) -> tuple[bytes, dict[str, Any]]:
    monitor = b"""  // V9K PTW-PMP temporal monitor.  A denied 8B PTE A/D update owns a quiet
  // interval from the checker decision through the exact response terminal.
  // This checker is intentionally independent of AWREADY/WREADY so an illegal
  // one-cycle AW/W pulse cannot escape merely by handshaking immediately.
  reg v9k_ptw_pmp_deny_pending_q;
  always @(posedge clk) begin
    if (rst) begin
      v9k_ptw_pmp_deny_pending_q <= 1'b0;
    end else begin
      if ((v9k_ptw_pmp_deny_pending_q ||
           (!dut.cpu_kill_w && dut.walk_ad_write_deny_w)) &&
          (lsu_axi_awvalid || lsu_axi_wvalid)) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] [V9K-LSU-PTW-PMP-DENY-QUIET] pending deny exposed AW/W before response terminal @%0t",
                 $time);
      end
      if (!dut.cpu_kill_w && dut.walk_ad_write_deny_w) begin
        v9k_ptw_pmp_deny_pending_q <= 1'b1;
      end else if (v9k_ptw_pmp_deny_pending_q &&
                   ((mem0_rsp_valid && mem0_rsp_ready) ||
                    mem0_drop0_valid)) begin
        v9k_ptw_pmp_deny_pending_q <= 1'b0;
      end
    end
  end

"""
    value, monitor_op = base.remove_once(
        live, monitor, "LSU deny-pending temporal monitor")

    old_task = """  task automatic sv39_ad_write_pmp_deny;
    input [1023:0] what;
    input write_access;
    input [`XLEN-1:0] leaf_flags;
    input partial_cover;
    reg [`XLEN-1:0] orig_pte;
    reg [4:0] deny_owner_token;
    integer hold_cycle;
    begin
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      orig_pte = (SUPERPAGE_PPN << 10) | leaf_flags;
      pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
      pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
      // entry0: TOR [0,0x8000_8000), R-only；entry1: NAPOT all, RWX。
      pmpcfg[0 +: 8] = 8'h09;
      pmpcfg[8 +: 8] = 8'h1f;
      pmpaddr[0 +: `XLEN] = 64'h0000_0000_8000_8000 >> 2;
      pmpaddr[`XLEN +: `XLEN] = {`XLEN{1'b1}};
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = write_access;
      mem0_req_addr = DATA_VA_AD;
      mem0_req_wdata = 64'h1234_5678_9abc_def0;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      deny_owner_token = mem0_req_owner_token;
      lsu_axi_arready = 1'b0;
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1(what, mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      // Poison the live request inputs after acceptance; the response must
      // retain the registered load/store owner, token, epoch and original VA.
      mem0_req_write = !write_access;
      mem0_req_addr = DATA_VA_AD + 64'h80;
      tick();
      #1;
      tb_check1("T4F LSU PTE read remains allowed", lsu_axi_arvalid, 1'b1);
      tb_check64("T4F LSU PTE read address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("T4F LSU waits leaf PTE", lsu_axi_rready, 1'b1);
      lsu_axi_rdata = orig_pte;
      lsu_axi_rresp = 2'b00;
      lsu_axi_rvalid = 1'b1;
      if (partial_cover) begin
        pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
        pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
        pmpcfg[0 +: 8] = 8'h0b;
        pmpcfg[8 +: 8] = 8'h1f;
        pmpaddr[0 +: `XLEN] = (ROOT_PT + 64'd20) >> 2;
        pmpaddr[`XLEN +: `XLEN] = {`XLEN{1'b1}};
      end
      #1;
      tb_check1("T4F LSU final data PMP remains allowed",
                dut.walk_leaf_pmp_fault_w, 1'b0);
      tb_check1("T4F LSU PTE WRITE PMP denies",
                dut.walk_pte_write_pmp_fault_w, 1'b1);
      tb_check1("T4F LSU deny event qualified", dut.walk_ad_write_deny_w,
                1'b1);
      tb_check1("T4F LSU denied PTE emits no AW", lsu_axi_awvalid, 1'b0);
      tb_check1("T4F LSU denied PTE emits no W", lsu_axi_wvalid, 1'b0);
      tick();
      lsu_axi_rvalid = 1'b0;
      lsu_axi_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("T4F LSU deny returns response", mem0_rsp_valid, 1'b1);
      tb_check1("T4F LSU deny is access fault", mem0_rsp_error, 1'b1);
      tb_check1("T4F LSU deny is not page fault", mem0_rsp_page_fault, 1'b0);
      tb_check1("V9K LSU deny response owner kind is stable",
                mem0_rsp_owner_kind == (write_access ? 2'b01 : 2'b00), 1'b1);
      tb_check1("V9K LSU deny response owner token is stable",
                mem0_rsp_owner_token == deny_owner_token, 1'b1);
      tb_check1("V9K LSU deny response epoch is stable",
                mem0_rsp_mmu_epoch == 2'b01, 1'b1);
      tb_check64("V9K LSU deny response fault tval is original VA",
                 mem0_rsp_fault_tval, DATA_VA_AD);
      tb_check1("T4F LSU response still has no AW", lsu_axi_awvalid, 1'b0);
      tb_check1("T4F LSU response still has no W", lsu_axi_wvalid, 1'b0);
      for (hold_cycle = 0; hold_cycle < 2;
           hold_cycle = hold_cycle + 1) begin
        tick();
        #1;
        tb_check1("V9K LSU held deny response remains valid",
                  mem0_rsp_valid, 1'b1);
        tb_check1("V9K LSU held deny remains access fault",
                  mem0_rsp_error, 1'b1);
        tb_check1("V9K LSU held deny remains non-page-fault",
                  mem0_rsp_page_fault, 1'b0);
        tb_check1("V9K LSU held deny owner kind remains stable",
                  mem0_rsp_owner_kind ==
                      (write_access ? 2'b01 : 2'b00), 1'b1);
        tb_check1("V9K LSU held deny owner token remains stable",
                  mem0_rsp_owner_token == deny_owner_token, 1'b1);
        tb_check1("V9K LSU held deny epoch remains stable",
                  mem0_rsp_mmu_epoch == 2'b01, 1'b1);
        tb_check64("V9K LSU held deny fault tval remains original VA",
                   mem0_rsp_fault_tval, DATA_VA_AD);
        tb_check1("V9K LSU held deny response has no AW",
                  lsu_axi_awvalid, 1'b0);
        tb_check1("V9K LSU held deny response has no W",
                  lsu_axi_wvalid, 1'b0);
      end
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      $display("[T4F-LSU-PTW-PMP-WRITE] op=%0s mode=%0s read=allow write=deny access-fault aw=0 w=0 owner=stable held=2",
               write_access ? "store" : "load",
               partial_cover ? "partial8" : "readonly");
    end
  endtask

""".encode("utf-8")
    value, task_op = base.replace_span_once(
        value,
        b"  task automatic sv39_ad_write_pmp_deny;\n",
        "  // 【LSQ·SQ 切换】".encode("utf-8"),
        old_task,
        "LSU deny READY-delay sweep task",
    )

    new_calls = b"""    sv39_ad_write_pmp_deny_sweep("T4F load A-update PTE write denied", 1'b0,
                                 LEAF_NO_ACCESS_FLAGS, 1'b0);
    sv39_ad_write_pmp_deny_sweep("T4F store D-update PTE write denied", 1'b1,
                                 LEAF_NO_DIRTY_FLAGS, 1'b0);
    sv39_ad_write_pmp_deny_sweep(
        "V9K load 8B partial-cover PTE write denied", 1'b0,
        LEAF_NO_ACCESS_FLAGS, 1'b1);
"""
    old_calls = b"""    sv39_ad_write_pmp_deny("T4F load A-update PTE write denied", 1'b0,
                           LEAF_NO_ACCESS_FLAGS, 1'b0);
    sv39_ad_write_pmp_deny("T4F store D-update PTE write denied", 1'b1,
                           LEAF_NO_DIRTY_FLAGS, 1'b0);
    sv39_ad_write_pmp_deny("V9K load 8B partial-cover PTE write denied", 1'b0,
                           LEAF_NO_ACCESS_FLAGS, 1'b1);
"""
    value, calls_op = base.replace_once(
        value, new_calls, old_calls, "LSU deny sweep invocation")
    return value, {"operations": [monitor_op, task_op, calls_op]}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path, required=True)
    parser.add_argument("--manifest", type=pathlib.Path, required=True)
    parser.add_argument("--audit", type=pathlib.Path, required=True)
    args = parser.parse_args()
    root = args.repo_root.resolve(strict=True)
    manifest_path = (root / args.manifest).resolve(strict=True)
    audit_path = (root / args.audit).resolve()
    if not manifest_path.is_relative_to(root) or not audit_path.is_relative_to(root):
        raise ValueError("rebind path escapes repository")

    base = load_module(root / BASE_SCRIPT, "v9k_v4_rebind_base")
    gate = load_module(
        root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
        "v9k_v4_architecture_hard_gates")
    ptw_tool = load_module(
        root / "npc/rv64/eval/ppa/tools/ptw_pmp_evidence.py",
        "v9k_v4_ptw_pmp_evidence")
    original_bytes = manifest_path.read_bytes()
    before = json.loads(original_bytes)
    base.require(before.get("schema") == gate.EVIDENCE_SCHEMA,
                 "unexpected architecture manifest schema")
    tests = before.get("tests")
    expected_tests = set(gate.EVIDENCE_TEST.values())
    base.require(isinstance(tests, dict) and set(tests) == expected_tests,
                 "architecture record inventory is not exact")
    rtl_sha, rtl_files = gate.rtl_binding(root)
    design_id = f"sha256:{rtl_sha}"
    base.require(before.get("design_id") == design_id,
                 "architecture manifest is cross-design")

    pre_result = gate.evaluate(root, manifest_path)
    base.require(pre_result.get("evidence_errors") == [],
                 "pre-rebind evidence structural errors exist")
    base.require(pre_result.get("overall_status") == "RED",
                 "pre-rebind architecture gates must be RED")
    pre_failures = base.gate_failures(pre_result)
    flat_failures = [item for rows in pre_failures.values() for item in rows]
    base.require(flat_failures and all(
        item.endswith((".provenance_files", ".provenance_digest"))
        for item in flat_failures),
        f"pre-rebind has non-provenance failures: {pre_failures}")

    ptw_result_path = root / PTW_RESULT
    ptw_result = json.loads(ptw_result_path.read_text(encoding="utf-8"))
    module = ptw_result.get("module_aggregate", {})
    variants = ptw_result.get("variant_audit", {})
    base.require(ptw_result.get("status") == "PASS", "PTW-PMP result is not PASS")
    base.require(ptw_result.get("design_id") == design_id,
                 "PTW-PMP result is cross-design")
    base.require(module.get("required") == module.get("passed") == 109
                 and module.get("failed") == 0,
                 "PTW-PMP module aggregate is not exact 109/109")
    base.require(variants.get("required") == 28
                 and variants.get("compile_success") == 28
                 and variants.get("dynamic_rejected") == 28,
                 "PTW-PMP RTL variant audit is not exact 28/28")
    ptw_tool.parse_module_aggregate(
        root, root / f".github/task-runs/{RUN_ID}/evidence/"
        "module-aggregate/summary.txt")
    ptw_tool.validate_variants(
        root, root / f".github/task-runs/{RUN_ID}/evidence/"
        "mutations/summary.json")
    static_contract = ptw_tool.validate_static_contract(root)
    base.require(static_contract and all(static_contract.values()),
                 "PTW-PMP static source contract is not fully PASS")
    source_bindings = ptw_result.get("provenance", {}).get("source_bindings", {})
    base.require(source_bindings.get(ALLOWED_PATH) == base.sha256_bytes(
        (root / ALLOWED_PATH).read_bytes()),
        "PTW-PMP result does not bind live LSU bridge TB")

    candidate = copy.deepcopy(before)
    old_hashes: set[str] = set()
    observed_mismatches: set[str] = set()
    record_audit: dict[str, Any] = {}
    changed_sections = 0
    for test_id in sorted(expected_tests):
        record = tests[test_id]
        section_audit: dict[str, Any] = {}
        for section_name in ("provenance", "source_manifest"):
            section = record.get(section_name)
            if section_name == "source_manifest" and section is None:
                continue
            base.require(isinstance(section, dict),
                         f"{test_id}: {section_name} is missing")
            files = section.get("files")
            base.require(isinstance(files, dict),
                         f"{test_id}: {section_name}.files missing")
            base.require(section.get("sha256") == gate.canonical_digest(files),
                         f"{test_id}: recorded {section_name} digest is invalid")
            mismatches: list[dict[str, str]] = []
            for relative, recorded_sha in sorted(files.items()):
                live_path = root / relative
                base.require(live_path.is_file(), f"{test_id}: missing {relative}")
                live_sha = base.sha256_bytes(live_path.read_bytes())
                if live_sha == recorded_sha:
                    continue
                base.require(relative == ALLOWED_PATH,
                             f"{test_id}: drift outside V9K-V4 LSU TB at {relative}")
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
    base.require(observed_mismatches == {ALLOWED_PATH},
                 f"observed source drift set is not exact: {observed_mismatches}")
    base.require(changed_sections > 0, "no source-binding section changed")

    live = (root / ALLOWED_PATH).read_bytes()
    reconstructed, byte_proof = reconstruct_v3_mem_tb(base, live)
    reconstructed_sha = base.sha256_bytes(reconstructed)
    base.require(old_hashes == {reconstructed_sha},
                 f"reconstructed={reconstructed_sha} recorded={old_hashes}")
    byte_proof.update({
        "old_sha256": reconstructed_sha,
        "new_sha256": base.sha256_bytes(live),
        "all_recorded_old_hashes_reconstructed": True,
    })

    before_projection_sha = base.canonical_digest(base.semantic_projection(before))
    after_projection_sha = base.canonical_digest(base.semantic_projection(candidate))
    base.require(before_projection_sha == after_projection_sha,
                 "non-provenance architecture projection changed")

    manifest_tmp = manifest_path.with_suffix(".json.v9k-v4-rebind.tmp")
    manifest_tmp.write_bytes(base.json_bytes(candidate))
    try:
        post_result = gate.evaluate(root, manifest_tmp)
        post_failures = base.gate_failures(post_result)
        base.require(post_result.get("evidence_errors") == [],
                     "post-rebind evidence structural errors exist")
        base.require(post_result.get("overall_status") == "GREEN",
                     "post-rebind architecture gates are not GREEN")
        base.require(all(not failures for failures in post_failures.values()),
                     f"post-rebind checks failed: {post_failures}")
        after_bytes = manifest_tmp.read_bytes()
        audit = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.datetime.now(
                datetime.timezone.utc).isoformat(),
            "status": "PASS",
            "scope": {
                "object": "local RV64 directed architecture evidence",
                "operation": "one-TB byte-proven V9K-V4 source rebind",
                "allowed_changed_paths": [ALLOWED_PATH],
                "production_rtl_changed": False,
                "directed_record_semantics_changed": False,
            },
            "manifest": {
                "path": manifest_path.relative_to(root).as_posix(),
                "before_sha256": base.sha256_bytes(original_bytes),
                "after_sha256": base.sha256_bytes(after_bytes),
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
                "result_sha256": base.sha256_bytes(ptw_result_path.read_bytes()),
                "module_required": 109,
                "module_passed": 109,
                "variants_required": 28,
                "variants_dynamic_rejected": 28,
                "static_contract_checks": len(static_contract),
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
                "only_v9k_v4_lsu_tb_drifted": True,
                "recorded_v3_source_hash_byte_reconstructed": True,
                "current_module_replay_109_of_109": True,
                "current_variants_replay_28_of_28": True,
                "current_static_contract_fully_passed": True,
                "non_provenance_projection_unchanged": True,
                "all_provenance_and_source_manifests_live": True,
                "post_all_nine_gates_green": True,
            },
        }
        audit_tmp = audit_path.with_suffix(".json.tmp")
        audit_path.parent.mkdir(parents=True, exist_ok=True)
        audit_tmp.write_bytes(base.json_bytes(audit))
        os.replace(manifest_tmp, manifest_path)
        os.replace(audit_tmp, audit_path)
    finally:
        manifest_tmp.unlink(missing_ok=True)

    print(
        f"[V9K-V4-ARCH-SOURCE-REBIND] paths=1 records={len(record_audit)} "
        f"sections={changed_sections} module=109/109 variants=28/28 "
        "pre=RED post=GREEN projection=UNCHANGED PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V9K-V4-ARCH-SOURCE-REBIND] FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
