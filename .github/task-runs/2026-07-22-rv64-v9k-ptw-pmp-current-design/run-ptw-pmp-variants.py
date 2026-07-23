#!/usr/bin/env python3
"""Compile and dynamically reject local RV64 PTW-PMP-G1 RTL variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-ptw-pmp-rtl-variants-v3"
SUITE_RUN_ID = "2026-07-22-rv64-v9k-ptw-pmp-current-design"
TRANSIENT_DIR_TOKEN = "<PTW_PMP_V9K_TRANSIENT_TMP>"


@dataclasses.dataclass(frozen=True)
class VariantSpec:
    name: str
    purpose: str
    source_rel: str
    make_variable: str
    test_name: str
    old: str
    new: str
    expected_marker: str


IFU = "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
LSU = "npc/rv64/vsrc/memory/OooMemAxiBridge.v"

IFU_CHECKER = """PmpChecker u_walk_pte_write_pmp_checker (
    .paddr_i(walk_pte_addr_q),
    .access_size_i(4'd8),
    .priv_mode_i(`PRIV_S),
    .access_read_i(1'b0),
    .access_write_i(1'b1),"""
LSU_CHECKER = """PmpChecker u_walk_pte_write_pmp_checker (
    .paddr_i(walk_pte_addr_w),
    .access_size_i(4'd8),
    .priv_mode_i(`PRIV_S),
    .access_read_i(1'b0),
    .access_write_i(1'b1),"""

IFU_DENY_CONDITION = """exec_ad_update_needed(ifu_axi_rdata_i) &&
                           walk_pte_write_pmp_fault_w) begin"""
LSU_DENY_CONDITION = """walk_ad_needed_w &&
                           walk_pte_write_pmp_fault_w) begin"""

IFU_DENY_BLOCK = """              end else if (exec_ad_update_needed(ifu_axi_rdata_i) &&
                           walk_pte_write_pmp_fault_w) begin
                // PTE 可读但不可写：按原取指类型返回 instruction access fault。
                inst0_q <= fetch_data_q[`INST_W-1:0];
                inst1_q <= fetch_data_q[`XLEN-1:`INST_W];
                resp0_q <= RESP_OK;
                resp1_q <= RESP_ACCESS_FAULT;
                resp0_bytes_q <= fetch_offset_q;
                state_q <= S_RESP;"""
LSU_DENY_BLOCK = """              end else if (walk_ad_needed_w &&
                           walk_pte_write_pmp_fault_w) begin
                // PTE 可读但不可写：原始 load/store 报 access fault，不是 page fault。
                rsp_error_q <= 1'b1;
                rsp_page_fault_q <= 1'b0;
                state_q <= S_RESP;"""

IFU_AW = "assign ifu_axi_awvalid_o = (state_q == S_AD_UPDATE) && !aw_done_q;"
IFU_W = "assign ifu_axi_wvalid_o = (state_q == S_AD_UPDATE) && !w_done_q;"
IFU_AWADDR = "assign ifu_axi_awaddr_o = walk_pte_addr_q;"
LSU_AW = """assign lsu_axi_awvalid_o =
      (active_owner_verified_q && (state_q == S_WRITE_REQ) && !aw_done_q) ||
      (active_owner_verified_q && (state_q == S_AD_UPDATE) && !aw_done_q);"""
LSU_W = """assign lsu_axi_wvalid_o =
      (active_owner_verified_q && (state_q == S_WRITE_REQ) && !w_done_q) ||
      (active_owner_verified_q && (state_q == S_AD_UPDATE) && !w_done_q);"""
LSU_AWADDR = """assign lsu_axi_awaddr_o =
      (state_q == S_AD_UPDATE) ? walk_pte_addr_w : paddr_q;"""
LSU_WRITE_CHANNELS = f"""{LSU_AW}
  {LSU_AWADDR}
  {LSU_W}"""

LSU_LATE_DENY_COUNTER = """reg v9k_variant_ptw_deny_pending_q;
  reg [2:0] v9k_variant_ptw_deny_stall_q;
  always @(posedge clk) begin
    if (rst) begin
      v9k_variant_ptw_deny_pending_q <= 1'b0;
      v9k_variant_ptw_deny_stall_q <= 3'b0;
    end else if (!cpu_kill_w && walk_ad_write_deny_w) begin
      v9k_variant_ptw_deny_pending_q <= 1'b1;
      v9k_variant_ptw_deny_stall_q <= 3'b0;
    end else if (v9k_variant_ptw_deny_pending_q &&
                 ((mem0_rsp_valid_o && mem0_rsp_ready_i) ||
                  mem0_drop0_valid_o)) begin
      v9k_variant_ptw_deny_pending_q <= 1'b0;
      v9k_variant_ptw_deny_stall_q <= 3'b0;
    end else if (v9k_variant_ptw_deny_pending_q &&
                 mem0_rsp_valid_o && !mem0_rsp_ready_i &&
                 (v9k_variant_ptw_deny_stall_q != 3'd7)) begin
      v9k_variant_ptw_deny_stall_q <=
          v9k_variant_ptw_deny_stall_q + 3'd1;
    end
  end
  wire v9k_variant_late_ptw_deny_leak_w =
      v9k_variant_ptw_deny_pending_q && mem0_rsp_valid_o &&
      (v9k_variant_ptw_deny_stall_q == 3'd2);"""


def checker_variant(
    *, name: str, purpose: str, source: str, make_variable: str,
    test_name: str, checker: str, old_field: str, new_field: str,
    marker: str,
) -> VariantSpec:
    return VariantSpec(
        name=name,
        purpose=purpose,
        source_rel=source,
        make_variable=make_variable,
        test_name=test_name,
        old=checker,
        new=checker.replace(old_field, new_field, 1),
        expected_marker=marker,
    )


def late_deny_leak_variant(
    *, name: str, purpose: str, leak_aw: bool, leak_w: bool,
) -> VariantSpec:
    aw = LSU_AW[:-1] + (
        " ||\n      v9k_variant_late_ptw_deny_leak_w;" if leak_aw else ";")
    w = LSU_W[:-1] + (
        " ||\n      v9k_variant_late_ptw_deny_leak_w;" if leak_w else ";")
    return VariantSpec(
        name=name,
        purpose=purpose,
        source_rel=LSU,
        make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge",
        old=LSU_WRITE_CHANNELS,
        new=f"{LSU_LATE_DENY_COUNTER}\n  {aw}\n  {LSU_AWADDR}\n  {w}",
        expected_marker="[V9K-LSU-PTW-PMP-DENY-QUIET]",
    )


VARIANTS = (
    checker_variant(
        name="ifu_disable_write_request", purpose="Remove the WRITE bit from the IFU PTE update PMP query.",
        source=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", checker=IFU_CHECKER,
        old_field=".access_write_i(1'b1)", new_field=".access_write_i(1'b0)",
        marker="T4F IFU PTE WRITE PMP denies"),
    checker_variant(
        name="ifu_query_final_exec_pa", purpose="Query the translated instruction PA instead of the registered PTE address.",
        source=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", checker=IFU_CHECKER,
        old_field=".paddr_i(walk_pte_addr_q)", new_field=".paddr_i(walk_leaf_current_paddr_w)",
        marker="T4F IFU PTE WRITE PMP denies"),
    checker_variant(
        name="ifu_query_machine_privilege", purpose="Use M-mode instead of the S-mode implicit page-table access privilege.",
        source=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", checker=IFU_CHECKER,
        old_field=".priv_mode_i(`PRIV_S)", new_field=".priv_mode_i(`PRIV_M)",
        marker="T4F IFU PTE WRITE PMP denies"),
    checker_variant(
        name="ifu_shrink_pte_write_to_4b", purpose="Check only 4B of the 8B PTE write.",
        source=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", checker=IFU_CHECKER,
        old_field=".access_size_i(4'd8)", new_field=".access_size_i(4'd4)",
        marker="V9K IFU 8B partial-cover PTE WRITE denies"),
    VariantSpec(
        name="ifu_bypass_write_deny_branch",
        purpose="Ignore a qualified IFU PTE WRITE deny and enter the A-update path.",
        source_rel=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", old=IFU_DENY_CONDITION,
        new=IFU_DENY_CONDITION.replace("walk_pte_write_pmp_fault_w", "1'b0"),
        expected_marker="T4F IFU deny returns response"),
    VariantSpec(
        name="ifu_force_deny_granted_write",
        purpose="Treat every IFU A-update as denied even when the WRITE checker grants.",
        source_rel=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", old=IFU_DENY_CONDITION,
        new=IFU_DENY_CONDITION.replace("walk_pte_write_pmp_fault_w", "1'b1"),
        expected_marker="V9K IFU allow enters A-update"),
    VariantSpec(
        name="ifu_report_page_fault_for_write_deny",
        purpose="Return instruction page fault instead of instruction access fault for a PTE WRITE deny.",
        source_rel=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", old=IFU_DENY_BLOCK,
        new=IFU_DENY_BLOCK.replace("resp1_q <= RESP_ACCESS_FAULT", "resp1_q <= RESP_PAGE_FAULT"),
        expected_marker="T4F IFU deny returns access fault"),
    VariantSpec(
        name="ifu_expose_aw_on_deny",
        purpose="Incorrectly expose AXI AWVALID in the IFU PTE WRITE deny decision cycle.",
        source_rel=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", old=IFU_AW,
        new="assign ifu_axi_awvalid_o = ((state_q == S_AD_UPDATE) && !aw_done_q) || walk_ad_write_deny_w;",
        expected_marker="T4F IFU denied PTE emits no AW"),
    VariantSpec(
        name="ifu_expose_w_on_deny",
        purpose="Incorrectly expose AXI WVALID in the IFU PTE WRITE deny decision cycle.",
        source_rel=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", old=IFU_W,
        new="assign ifu_axi_wvalid_o = ((state_q == S_AD_UPDATE) && !w_done_q) || walk_ad_write_deny_w;",
        expected_marker="T4F IFU denied PTE emits no W"),
    VariantSpec(
        name="ifu_offset_ad_update_awaddr",
        purpose="Drive the IFU A-bit update AWADDR one PTE beyond the physical address checked by PMP.",
        source_rel=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", old=IFU_AWADDR,
        new="assign ifu_axi_awaddr_o = walk_pte_addr_q + 64'd8;",
        expected_marker="V9K IFU allow AWADDR equals checked PTE address"),
    VariantSpec(
        name="ifu_withdraw_w_after_aw_handshake",
        purpose="Withdraw the pending IFU PTE W channel after the independent AW handshake.",
        source_rel=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", old=IFU_W,
        new="assign ifu_axi_wvalid_o = (state_q == S_AD_UPDATE) && !w_done_q && !aw_done_q;",
        expected_marker="V9K IFU AW-first keeps W pending"),
    VariantSpec(
        name="ifu_withdraw_aw_after_w_handshake",
        purpose="Withdraw the pending IFU PTE AW channel after the independent W handshake.",
        source_rel=IFU, make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_bridge", old=IFU_AW,
        new="assign ifu_axi_awvalid_o = (state_q == S_AD_UPDATE) && !aw_done_q && !w_done_q;",
        expected_marker="pending AW was withdrawn before fire"),
    checker_variant(
        name="lsu_disable_write_request", purpose="Remove the WRITE bit from the LSU PTE update PMP query.",
        source=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", checker=LSU_CHECKER,
        old_field=".access_write_i(1'b1)", new_field=".access_write_i(1'b0)",
        marker="T4F LSU PTE WRITE PMP denies"),
    checker_variant(
        name="lsu_query_final_data_pa", purpose="Query the translated data PA instead of the leaf PTE address.",
        source=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", checker=LSU_CHECKER,
        old_field=".paddr_i(walk_pte_addr_w)", new_field=".paddr_i(walk_leaf_paddr_w)",
        marker="T4F LSU PTE WRITE PMP denies"),
    checker_variant(
        name="lsu_query_machine_privilege", purpose="Use M-mode instead of the S-mode implicit page-table access privilege.",
        source=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", checker=LSU_CHECKER,
        old_field=".priv_mode_i(`PRIV_S)", new_field=".priv_mode_i(`PRIV_M)",
        marker="T4F LSU PTE WRITE PMP denies"),
    checker_variant(
        name="lsu_shrink_pte_write_to_4b", purpose="Check only 4B of the 8B LSU PTE write.",
        source=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", checker=LSU_CHECKER,
        old_field=".access_size_i(4'd8)", new_field=".access_size_i(4'd4)",
        marker="T4F LSU PTE WRITE PMP denies"),
    VariantSpec(
        name="lsu_bypass_write_deny_branch",
        purpose="Ignore a qualified LSU PTE WRITE deny and enter the A/D update path.",
        source_rel=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", old=LSU_DENY_CONDITION,
        new=LSU_DENY_CONDITION.replace("walk_pte_write_pmp_fault_w", "1'b0"),
        expected_marker="T4F LSU deny returns response"),
    VariantSpec(
        name="lsu_force_deny_granted_write",
        purpose="Treat every LSU A/D update as denied even when the WRITE checker grants.",
        source_rel=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", old=LSU_DENY_CONDITION,
        new=LSU_DENY_CONDITION.replace("walk_pte_write_pmp_fault_w", "1'b1"),
        expected_marker="sv39 A/D update issues AW"),
    VariantSpec(
        name="lsu_report_page_fault_for_write_deny",
        purpose="Return page fault instead of access fault for an LSU PTE WRITE deny.",
        source_rel=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", old=LSU_DENY_BLOCK,
        new=LSU_DENY_BLOCK.replace("rsp_page_fault_q <= 1'b0", "rsp_page_fault_q <= 1'b1"),
        expected_marker="T4F LSU deny is not page fault"),
    VariantSpec(
        name="lsu_expose_aw_on_deny",
        purpose="Incorrectly expose AXI AWVALID in the LSU PTE WRITE deny decision cycle.",
        source_rel=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", old=LSU_AW,
        new=LSU_AW[:-1] + " ||\n      walk_ad_write_deny_w;",
        expected_marker="T4F LSU denied PTE emits no AW"),
    VariantSpec(
        name="lsu_expose_w_on_deny",
        purpose="Incorrectly expose AXI WVALID in the LSU PTE WRITE deny decision cycle.",
        source_rel=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", old=LSU_W,
        new=LSU_W[:-1] + " ||\n      walk_ad_write_deny_w;",
        expected_marker="T4F LSU denied PTE emits no W"),
    VariantSpec(
        name="lsu_offset_ad_update_awaddr",
        purpose="Drive the LSU A/D update AWADDR one PTE beyond the physical address checked by PMP.",
        source_rel=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", old=LSU_AWADDR,
        new="""assign lsu_axi_awaddr_o =
      (state_q == S_AD_UPDATE) ? (walk_pte_addr_w + 64'd8) : paddr_q;""",
        expected_marker="V9K LSU allow AWADDR equals checked PTE address"),
    VariantSpec(
        name="lsu_withdraw_w_after_aw_handshake",
        purpose="Withdraw the pending LSU PTE W channel after the independent AW handshake.",
        source_rel=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", old=LSU_W,
        new="""assign lsu_axi_wvalid_o =
      (active_owner_verified_q && (state_q == S_WRITE_REQ) && !w_done_q) ||
      (active_owner_verified_q && (state_q == S_AD_UPDATE) && !w_done_q && !aw_done_q);""",
        expected_marker="V9K LSU AW-first keeps PTE W pending"),
    VariantSpec(
        name="lsu_withdraw_aw_after_w_handshake",
        purpose="Withdraw the pending LSU PTE AW channel after the independent W handshake.",
        source_rel=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", old=LSU_AW,
        new="""assign lsu_axi_awvalid_o =
      (active_owner_verified_q && (state_q == S_WRITE_REQ) && !aw_done_q) ||
      (active_owner_verified_q && (state_q == S_AD_UPDATE) && !aw_done_q && !w_done_q);""",
        expected_marker="V9K LSU W-first keeps PTE AW pending"),
    VariantSpec(
        name="lsu_relabel_ptw_deny_response_token_from_live_input",
        purpose="Overwrite the registered LSU PTW-deny response token with the live request token.",
        source_rel=LSU, make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge", old=LSU_DENY_BLOCK,
        new=LSU_DENY_BLOCK.replace(
            "rsp_error_q <= 1'b1;",
            "rsp_owner_token_q <= mem0_req_owner_token_i;\n"
            "                rsp_error_q <= 1'b1;", 1),
        expected_marker="V9K LSU deny response owner token is stable"),
    late_deny_leak_variant(
        name="lsu_late_aw_on_third_denied_response_stall",
        purpose=(
            "Pulse LSU PTE AWVALID on the third stalled access-fault response "
            "cycle after the WRITE checker denied the update."),
        leak_aw=True,
        leak_w=False,
    ),
    late_deny_leak_variant(
        name="lsu_late_w_on_third_denied_response_stall",
        purpose=(
            "Pulse LSU PTE WVALID on the third stalled access-fault response "
            "cycle after the WRITE checker denied the update."),
        leak_aw=False,
        leak_w=True,
    ),
    late_deny_leak_variant(
        name="lsu_late_aw_w_on_third_denied_response_stall",
        purpose=(
            "Pulse both LSU PTE AWVALID and WVALID on the third stalled "
            "access-fault response cycle after the WRITE checker denied the "
            "update."),
        leak_aw=True,
        leak_w=True,
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def repository_path(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    resolved = value.resolve()
    if not resolved.is_relative_to(root):
        raise ValueError(f"output escapes repository: {resolved}")
    return resolved


def normalize_transient_paths(text: str, transient: pathlib.Path) -> str:
    if TRANSIENT_DIR_TOKEN in text:
        raise ValueError("raw log already contains normalization token")
    exact = str(transient.resolve(strict=True))
    if exact not in text:
        raise ValueError("raw log does not bind current transient directory")
    return text.replace(exact, TRANSIENT_DIR_TOKEN)


def normalize_log_path(
    root: pathlib.Path, log_path: pathlib.Path, transient_dir: pathlib.Path,
) -> int:
    resolved_log = repository_path(root, log_path)
    transient = transient_dir.resolve(strict=True)
    if transient.is_relative_to(root) or transient.parent != pathlib.Path("/tmp"):
        raise ValueError(f"unexpected transient compile directory: {transient}")
    if log_path.is_symlink() or not resolved_log.is_file():
        raise ValueError(f"log is not an exact regular file: {log_path}")
    text = resolved_log.read_text(encoding="utf-8")
    replacements = text.count(str(transient))
    if replacements:
        resolved_log.write_text(
            normalize_transient_paths(text, transient), encoding="utf-8")
    return replacements


def normalize_log_directory(
    root: pathlib.Path, log_dir: pathlib.Path, transient_dir: pathlib.Path,
) -> tuple[int, int]:
    resolved_dir = repository_path(root, log_dir)
    logs = sorted(resolved_dir.glob("*.log"))
    if not logs:
        raise ValueError("log inventory is empty")
    return len(logs), sum(
        normalize_log_path(root, path, transient_dir) for path in logs)


def reconstruct_variant(root: pathlib.Path, spec: VariantSpec) -> tuple[str, str]:
    source = (root / spec.source_rel).resolve(strict=True)
    if not source.is_relative_to(root):
        raise ValueError(f"{spec.name}: source escapes repository")
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL variant anchor count={text.count(spec.old)}")
    return text, text.replace(spec.old, spec.new, 1)


def run_one(
    root: pathlib.Path, output_dir: pathlib.Path, spec: VariantSpec,
) -> dict[str, object]:
    original_text, variant_text = reconstruct_variant(root, spec)
    source_path = root / spec.source_rel
    log_path = output_dir / f"{spec.name}.log"
    with tempfile.TemporaryDirectory(
        prefix=f"rv64-v9k-{spec.name}.", dir="/tmp",
    ) as temp_name:
        temp = pathlib.Path(temp_name)
        variant_path = temp / source_path.name
        variant_path.write_text(variant_text, encoding="utf-8")
        result_dir = temp / "result"
        build_dir = temp / "build"
        target = result_dir / "logs" / f"{spec.test_name}.log"
        command = [
            "make", "-B", "-C", str(root / "npc/rv64/testbench"),
            f"RESULT_DIR={result_dir}", f"BUILD_DIR={build_dir}",
            f"{spec.make_variable}={variant_path}", str(target),
        ]
        completed = subprocess.run(
            command, cwd=root, check=False, capture_output=True, text=True,
            timeout=180,
        )
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver = completed.stdout + completed.stderr
        combined = test_log + (
            "\n[RTL-VERIFICATION-VARIANT-DRIVER]\n" + driver if driver else "")
        log_path.write_text(
            normalize_transient_paths(combined, temp), encoding="utf-8")
        compiled_image = build_dir / f"{spec.test_name}.vvp"
        compile_success = (
            compiled_image.is_file() and "[COMPILE]" in test_log
            and "compile returned nonzero status" not in test_log
        )
        marker_observed = spec.expected_marker in test_log
        dynamic_rejected = (
            compile_success and completed.returncode != 0 and marker_observed
            and "[RESULT] FAIL status=" in test_log
            and "[RESULT] PASS" not in test_log
        )
    return {
        "name": spec.name,
        "debt_id": "PTW-PMP-G1",
        "purpose": spec.purpose,
        "source": spec.source_rel,
        "make_variable": spec.make_variable,
        "test_name": spec.test_name,
        "original_sha256": sha256_bytes(original_text.encode("utf-8")),
        "variant_sha256": sha256_bytes(variant_text.encode("utf-8")),
        "expected_marker": spec.expected_marker,
        "marker_observed": marker_observed,
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "make_returncode": completed.returncode,
        "log": {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        },
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path)
    parser.add_argument("--audit", action="store_true")
    parser.add_argument("--normalize-log-dir", type=pathlib.Path)
    parser.add_argument("--transient-dir", type=pathlib.Path)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)
    if args.normalize_log_dir is not None:
        if args.transient_dir is None or args.output is not None or args.audit:
            parser.error("log normalization requires --transient-dir only")
        count, replacements = normalize_log_directory(
            root, args.normalize_log_dir, args.transient_dir)
        print(
            f"[PTW-PMP-LOG-NORMALIZATION] logs={count} "
            f"replacements={replacements} token={TRANSIENT_DIR_TOKEN}")
        return 0
    if args.transient_dir is not None:
        parser.error("--transient-dir requires --normalize-log-dir")
    if args.audit:
        for spec in VARIANTS:
            reconstruct_variant(root, spec)
        print(f"[PTW-PMP-VARIANT-AUDIT] variants={len(VARIANTS)} PASS")
        return 0
    if args.output is None:
        parser.error("variant execution requires --output")
    output = repository_path(root, args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    log_dir = output.parent / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    source_paths = sorted({spec.source_rel for spec in VARIANTS})
    before = {path: sha256_file(root / path) for path in source_paths}
    results = [run_one(root, log_dir, spec) for spec in VARIANTS]
    after = {path: sha256_file(root / path) for path in source_paths}
    compile_success = sum(bool(row["compile_success"]) for row in results)
    dynamic_rejected = sum(bool(row["dynamic_rejected"]) for row in results)
    payload = {
        "schema": SCHEMA,
        "suite_run_id": SUITE_RUN_ID,
        "required": len(VARIANTS),
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "source_unchanged": before == after,
        "source_sha256_before": before,
        "source_sha256_after": after,
        "results": results,
    }
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        f"[PTW-PMP-RTL-VARIANTS] required={len(VARIANTS)} "
        f"compile_success={compile_success} dynamic_rejected={dynamic_rejected} "
        f"source_unchanged={str(before == after).lower()}")
    return 0 if (
        compile_success == len(VARIANTS)
        and dynamic_rejected == len(VARIANTS)
        and before == after
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
