#!/usr/bin/env python3
"""Compile and dynamically reject local RV64 IFU-FETCH-G2 RTL variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-ifu-fetch-provenance-rtl-variants-v1"
SUITE_RUN_ID = "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design"
TRANSIENT_DIR_TOKEN = "<IFU_FETCH_V9H_TRANSIENT_TMP>"


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


BRIDGE = "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
DECODE = "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v"

VARIANTS = (
    VariantSpec(
        name="bridge_output_forgets_fault_frontier",
        purpose=(
            "Replace the registered first-failing-halfword frontier with a "
            "constant four-byte split at the bridge response interface."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "  assign fetch_rsp_resp0_bytes_o = cache_result_window_w ? "
            "3'd4 : resp0_bytes_q;"
        ),
        new="  assign fetch_rsp_resp0_bytes_o = 3'd4;",
        expected_marker="raw resp0_bytes is exact F=2/4/6",
    ),
    VariantSpec(
        name="bridge_invalid_pte_records_word_split",
        purpose=(
            "Record a four-byte word boundary instead of the exact accepted "
            "halfword frontier when the second-page PTE is invalid."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "            end else if (pte_invalid(ifu_axi_rdata_i) ||\n"
            "                         pte_reserved_fault(ifu_axi_rdata_i,\n"
            "                                            fetch_ctx_exec_svpbmt_en_q,\n"
            "                                            walk_level_q) ||\n"
            "                         (!pte_leaf(ifu_axi_rdata_i) &&\n"
            "                          (walk_level_q == 2'd0))) begin\n"
            "              inst0_q <= fetch_data_q[`INST_W-1:0];\n"
            "              inst1_q <= fetch_data_q[`XLEN-1:`INST_W];\n"
            "              resp0_q <= RESP_OK;\n"
            "              resp1_q <= RESP_PAGE_FAULT;\n"
            "              resp0_bytes_q <= fetch_offset_q;\n"
            "              state_q <= S_RESP;"
        ),
        new=(
            "            end else if (pte_invalid(ifu_axi_rdata_i) ||\n"
            "                         pte_reserved_fault(ifu_axi_rdata_i,\n"
            "                                            fetch_ctx_exec_svpbmt_en_q,\n"
            "                                            walk_level_q) ||\n"
            "                         (!pte_leaf(ifu_axi_rdata_i) &&\n"
            "                          (walk_level_q == 2'd0))) begin\n"
            "              inst0_q <= fetch_data_q[`INST_W-1:0];\n"
            "              inst1_q <= fetch_data_q[`XLEN-1:`INST_W];\n"
            "              resp0_q <= RESP_OK;\n"
            "              resp1_q <= RESP_PAGE_FAULT;\n"
            "              resp0_bytes_q <= 3'd4;\n"
            "              state_q <= S_RESP;"
        ),
        expected_marker="raw resp0_bytes is exact F=2/4/6",
    ),
    VariantSpec(
        name="bridge_scratch_preserves_unfetched_poison",
        purpose=(
            "Preserve the preceding successful packet instead of clearing a "
            "new slow-fetch scratch register, allowing stale transaction "
            "bytes to leak into the unfetched fault suffix."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "          paddr0_q <= fetch_ctx_candidate_pc_q;\n"
            "          paddr1_q <= {`XLEN{1'b0}};\n"
            "          packet_cross_page_q <= 1'b0;\n"
            "          walk_second_q <= 1'b0;\n"
            "          second_page_ready_q <= 1'b0;\n"
            "          fetch_offset_q <= 3'd0;\n"
            "          fetch_data_q <= {`XLEN{1'b0}};"
        ),
        new=(
            "          paddr0_q <= fetch_ctx_candidate_pc_q;\n"
            "          paddr1_q <= {`XLEN{1'b0}};\n"
            "          packet_cross_page_q <= 1'b0;\n"
            "          walk_second_q <= 1'b0;\n"
            "          second_page_ready_q <= 1'b0;\n"
            "          fetch_offset_q <= 3'd0;\n"
            "          fetch_data_q <= fetch_data_q;"
        ),
        expected_marker="raw instruction tail after F is zero",
    ),
    VariantSpec(
        name="bridge_releases_fault_response_without_ready",
        purpose=(
            "Release the registered response owner on valid alone instead of "
            "the valid/ready handshake, dropping a backpressured fault tuple."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "        S_RESP: begin\n"
            "          // Registered skid/slow response. The pre-open SRAM window lets an\n"
            "          // atomic replacement fire its read on this edge; the following\n"
            "          // S_CACHE_READ cycle is already the successor result cycle.\n"
            "          if (fetch_rsp_fire_w) begin"
        ),
        new=(
            "        S_RESP: begin\n"
            "          // Registered skid/slow response. The pre-open SRAM window lets an\n"
            "          // atomic replacement fire its read on this edge; the following\n"
            "          // S_CACHE_READ cycle is already the successor result cycle.\n"
            "          if (fetch_rsp_valid_o) begin"
        ),
        expected_marker="G2 FFA 32+32 response arrives",
    ),
    VariantSpec(
        name="bridge_uses_live_candidate_for_fault_frontier",
        purpose=(
            "Drive the fault frontier from the continuously sampled candidate "
            "PC instead of the registered response transaction owner."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "  assign fetch_rsp_resp0_bytes_o = cache_result_window_w ? "
            "3'd4 : resp0_bytes_q;"
        ),
        new=(
            "  assign fetch_rsp_resp0_bytes_o = cache_result_window_w ? "
            "3'd4 : fetch_ctx_candidate_pc_q[2:0];"
        ),
        expected_marker="raw resp0_bytes is exact F=2/4/6",
    ),
    VariantSpec(
        name="bridge_misplaces_second_halfword_lane",
        purpose=(
            "Insert the packet byte-offset-two halfword into the byte-offset-"
            "four lane, breaking independently patterned prefix provenance."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_page_end_fault",
        old="        3'd2: insert_fetch_halfword[31:16] = halfword;",
        new="        3'd2: insert_fetch_halfword[47:32] = halfword;",
        expected_marker="successful raw prefix retained",
    ),
    VariantSpec(
        name="bridge_continues_after_invalid_pte_frontier",
        purpose=(
            "Continue to an instruction address owner after an invalid PTE "
            "instead of closing the fetch transaction at its fault frontier."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "            end else if (pte_invalid(ifu_axi_rdata_i) ||\n"
            "                         pte_reserved_fault(ifu_axi_rdata_i,\n"
            "                                            fetch_ctx_exec_svpbmt_en_q,\n"
            "                                            walk_level_q) ||\n"
            "                         (!pte_leaf(ifu_axi_rdata_i) &&\n"
            "                          (walk_level_q == 2'd0))) begin\n"
            "              inst0_q <= fetch_data_q[`INST_W-1:0];\n"
            "              inst1_q <= fetch_data_q[`XLEN-1:`INST_W];\n"
            "              resp0_q <= RESP_OK;\n"
            "              resp1_q <= RESP_PAGE_FAULT;\n"
            "              resp0_bytes_q <= fetch_offset_q;\n"
            "              state_q <= S_RESP;\n"
            "            end else if (pte_leaf(ifu_axi_rdata_i)) begin"
        ),
        new=(
            "            end else if (pte_invalid(ifu_axi_rdata_i) ||\n"
            "                         pte_reserved_fault(ifu_axi_rdata_i,\n"
            "                                            fetch_ctx_exec_svpbmt_en_q,\n"
            "                                            walk_level_q) ||\n"
            "                         (!pte_leaf(ifu_axi_rdata_i) &&\n"
            "                          (walk_level_q == 2'd0))) begin\n"
            "              inst0_q <= fetch_data_q[`INST_W-1:0];\n"
            "              inst1_q <= fetch_data_q[`XLEN-1:`INST_W];\n"
            "              resp0_q <= RESP_OK;\n"
            "              resp1_q <= RESP_PAGE_FAULT;\n"
            "              resp0_bytes_q <= fetch_offset_q;\n"
            "              state_q <= S_AR0;\n"
            "            end else if (pte_leaf(ifu_axi_rdata_i)) begin"
        ),
        expected_marker="fault frontier immediately blocks younger AR",
    ),
    VariantSpec(
        name="bridge_fills_partial_packet_before_fault_closure",
        purpose=(
            "Write the packet cache after any successful instruction halfword "
            "instead of only after a complete non-cross-page packet."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "  wire fetch_cache_fill_complete_w =\n"
            "      (state_q == S_R0) && ifu_axi_rvalid_i &&\n"
            "      (ifu_axi_rresp_i == RESP_OK) &&\n"
            "      !fetch_more_after_r_w && !packet_cross_page_q;"
        ),
        new=(
            "  wire fetch_cache_fill_complete_w =\n"
            "      (state_q == S_R0) && ifu_axi_rvalid_i &&\n"
            "      (ifu_axi_rresp_i == RESP_OK);"
        ),
        expected_marker="fault transaction emits no cache fill",
    ),
    VariantSpec(
        name="decoder_treats_equal_boundary_as_fault",
        purpose=(
            "Treat an instruction range ending exactly at the successful "
            "frontier as touching the second-page fault suffix."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_fetch_page_end_fault",
        old="      end else if (end_byte > {2'b00, resp0_bytes}) begin",
        new="      end else if (end_byte >= {2'b00, resp0_bytes}) begin",
        expected_marker="G2 FFC 32+C slot0 response",
    ),
    VariantSpec(
        name="decoder_treats_zero_frontier_as_success",
        purpose=(
            "Bypass resp1 when the successful byte frontier is zero, allowing "
            "raw bytes with no successful ownership to decode."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_fetch_packet_decode",
        old="      end else if (end_byte > {2'b00, resp0_bytes}) begin",
        new=(
            "      end else if ((end_byte > {2'b00, resp0_bytes}) &&\n"
            "                   (resp0_bytes != 3'd0)) begin"
        ),
        expected_marker="G2 F0 slot0 response",
    ),
    VariantSpec(
        name="decoder_slot0_checks_only_prefix",
        purpose=(
            "Use only the first halfword when assigning slot0 response, "
            "allowing a 32-bit instruction tail in the fault suffix."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "      byte_range_resp(4'd0, dec0_len_bytes_w, rsp_resp0_bytes_i,\n"
            "                      rsp_resp0_i, rsp_resp1_i);"
        ),
        new=(
            "      byte_range_resp(4'd0, 4'd2, rsp_resp0_bytes_i,\n"
            "                      rsp_resp0_i, rsp_resp1_i);"
        ),
        expected_marker="G2 FFE 32+C slot0 response",
    ),
    VariantSpec(
        name="decoder_slot1_checks_only_prefix",
        purpose=(
            "Use only the first halfword when assigning slot1 response, "
            "allowing a 32-bit slot1 tail in the fault suffix."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "      byte_range_resp(dec1_start_byte_w, dec1_len_bytes_w,\n"
            "                      rsp_resp0_bytes_i, rsp_resp0_i, rsp_resp1_i);"
        ),
        new=(
            "      byte_range_resp(dec1_start_byte_w, 4'd2,\n"
            "                      rsp_resp0_bytes_i, rsp_resp0_i, rsp_resp1_i);"
        ),
        expected_marker="G2 FFC C+32 slot1 response",
    ),
    VariantSpec(
        name="decoder_slot1_starts_at_fixed_halfword",
        purpose=(
            "Ignore a 32-bit slot0 length and force slot1 byte-range ownership "
            "to start at the first two-byte boundary."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_fetch_page_end_fault",
        old="  wire [3:0] dec1_start_byte_w = dec0_len_bytes_w;",
        new="  wire [3:0] dec1_start_byte_w = 4'd2;",
        expected_marker="G2 FFC 32+C slot1 response",
    ),
    VariantSpec(
        name="decoder_reads_faulted_slot0_prefix",
        purpose=(
            "Read raw slot0 length bits even when the slot0 prefix response "
            "is faulted instead of using the safe compressed prefix."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_fetch_packet_decode",
        old=(
            "  wire [15:0] dec0_half_w = dec0_prefix_valid_w ? "
            "half0_w : 16'h0001;"
        ),
        new="  wire [15:0] dec0_half_w = half0_w;",
        expected_marker="fault semantic packet next uses safe prefixes",
    ),
    VariantSpec(
        name="decoder_slot0_sanitizes_only_prefix_fault",
        purpose=(
            "Sanitize slot0 only when its prefix faults, exposing a raw "
            "32-bit instruction whose upper half lies in the fault suffix."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_fetch_page_end_fault",
        old=(
            "  assign dec0_inst_o = (dec0_range_resp_w != RESP_OK) ? "
            "32'h0000_0013 :"
        ),
        new=(
            "  assign dec0_inst_o = (dec0_prefix_resp_w != RESP_OK) ? "
            "32'h0000_0013 :"
        ),
        expected_marker="slot0 faulted inst is NOP",
    ),
    VariantSpec(
        name="decoder_slot1_sanitizes_only_prefix_fault",
        purpose=(
            "Sanitize slot1 only when its prefix faults, exposing raw upper "
            "halfword data when the full 32-bit range crosses the frontier."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_fetch_packet_decode",
        old=(
            "  assign dec1_inst_o = (dec1_effective_resp_w != RESP_OK) ? "
            "32'h0000_0013 :"
        ),
        new=(
            "  assign dec1_inst_o = (dec1_prefix_resp_w != RESP_OK) ? "
            "32'h0000_0013 :"
        ),
        expected_marker="fault-tail poison slot1 sanitized",
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


def normalize_log_directory(
    root: pathlib.Path,
    log_dir: pathlib.Path,
    transient_dir: pathlib.Path,
) -> tuple[int, int]:
    resolved_log_dir = repository_path(root, log_dir)
    if not resolved_log_dir.is_dir():
        raise ValueError(f"log directory is missing: {resolved_log_dir}")
    transient = transient_dir.resolve(strict=True)
    if transient.is_relative_to(root):
        raise ValueError("transient compile directory must be outside repository")
    if transient.parent != pathlib.Path("/tmp") or not transient.name.startswith(
        "rv64-ifu-fetch-v9h."
    ):
        raise ValueError(f"unexpected transient compile directory: {transient}")
    logs = sorted(resolved_log_dir.glob("*.log"))
    if not logs:
        raise ValueError("log inventory is empty")
    replacements = 0
    for log_path in logs:
        resolved_log = log_path.resolve(strict=True)
        if log_path.is_symlink() or resolved_log.parent != resolved_log_dir:
            raise ValueError(f"log is not an exact regular file: {log_path}")
        text = resolved_log.read_text(encoding="utf-8")
        replacements += text.count(str(transient))
        resolved_log.write_text(
            normalize_transient_paths(text, transient), encoding="utf-8")
    return len(logs), replacements


def reconstruct_variant(
    root: pathlib.Path,
    spec: VariantSpec,
) -> tuple[str, str]:
    source = (root / spec.source_rel).resolve(strict=True)
    if not source.is_relative_to(root):
        raise ValueError(f"{spec.name}: source escapes repository")
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL variant anchor is not unique")
    return text, text.replace(spec.old, spec.new, 1)


def run_one(
    root: pathlib.Path,
    output_dir: pathlib.Path,
    spec: VariantSpec,
) -> dict[str, object]:
    original_text, variant_text = reconstruct_variant(root, spec)
    original_path = root / spec.source_rel
    log_path = output_dir / f"{spec.name}.log"
    with tempfile.TemporaryDirectory(
        prefix=f"rv64-v9h-{spec.name}.", dir="/tmp",
    ) as temp_name:
        temp = pathlib.Path(temp_name)
        variant_path = temp / original_path.name
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
            timeout=180)
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver = completed.stdout + completed.stderr
        combined = test_log + (
            "\n[RTL-VERIFICATION-VARIANT-DRIVER]\n" + driver
            if driver else "")
        log_path.write_text(
            normalize_transient_paths(combined, temp), encoding="utf-8")
        compiled_image = build_dir / f"{spec.test_name}.vvp"
        compile_success = (
            compiled_image.is_file() and "[COMPILE]" in test_log
            and "compile returned nonzero status" not in test_log)
        marker_observed = spec.expected_marker in test_log
        dynamic_rejected = (
            compile_success and completed.returncode != 0 and marker_observed
            and "[RESULT] FAIL status=" in test_log
            and "[RESULT] PASS" not in test_log)
    return {
        "name": spec.name,
        "debt_id": "IFU-FETCH-G2",
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
    parser.add_argument("--normalize-log-dir", type=pathlib.Path)
    parser.add_argument("--transient-dir", type=pathlib.Path)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)

    if args.normalize_log_dir is not None or args.transient_dir is not None:
        if (args.normalize_log_dir is None or args.transient_dir is None
                or args.output is not None):
            parser.error(
                "log normalization requires --normalize-log-dir and "
                "--transient-dir without --output")
        count, replacements = normalize_log_directory(
            root, args.normalize_log_dir, args.transient_dir)
        print(
            f"[IFU-FETCH-LOG-NORMALIZATION] logs={count} "
            f"replacements={replacements} token={TRANSIENT_DIR_TOKEN}")
        return 0

    if args.output is None:
        parser.error("RTL verification-variant mode requires --output")
    output = repository_path(root, args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    log_dir = output.parent / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    source_paths = sorted({spec.source_rel for spec in VARIANTS})
    before = {name: sha256_file(root / name) for name in source_paths}
    results = [run_one(root, log_dir, spec) for spec in VARIANTS]
    after = {name: sha256_file(root / name) for name in source_paths}
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
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    print(
        f"[IFU-FETCH-RTL-VARIANTS] required={len(VARIANTS)} "
        f"compile_success={compile_success} dynamic_rejected={dynamic_rejected} "
        f"source_unchanged={str(before == after).lower()}")
    return 0 if (
        compile_success == len(VARIANTS)
        and dynamic_rejected == len(VARIANTS)
        and before == after
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
