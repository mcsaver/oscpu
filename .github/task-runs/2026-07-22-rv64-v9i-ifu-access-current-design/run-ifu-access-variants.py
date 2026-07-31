#!/usr/bin/env python3
"""Compile and dynamically reject local RV64 IFU-ACCESS-G1 RTL variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-ifu-access-rtl-variants-v1"
SUITE_RUN_ID = "2026-07-22-rv64-v9i-ifu-access-current-design"
TRANSIENT_DIR_TOKEN = "<IFU_ACCESS_V9I_TRANSIENT_TMP>"


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
PMP = "npc/rv64/vsrc/memory/PmpChecker.v"
CROSSBAR = "npc/rv64/vsrc/bus/AxiCrossbar.v"
PAIR = "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v"
DISPATCH = "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v"
CAPTURE = "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v"
ARBITER = "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v"
DECODE = "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v"


VARIANTS = (
    VariantSpec(
        name="bridge_overfetches_compressed_pair",
        purpose=(
            "Force an additional instruction halfword after a complete C/C "
            "packet instead of stopping at its four-byte footprint."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_access_footprint",
        old=(
            "      3'd2: begin\n"
            "        // L0=C 时当前 halfword 是 L1 prefix；否则是 L0 tail。\n"
            "        fetch_more_after_r_r =\n"
            "            (fetch_data_after_r_w[1:0] == 2'b11) ||\n"
            "            (fetch_data_after_r_w[17:16] == 2'b11);\n"
            "        fetch_next_offset_r = 3'd4;\n"
            "      end"
        ),
        new=(
            "      3'd2: begin\n"
            "        // Verification variant: continue after every offset-two beat.\n"
            "        fetch_more_after_r_r = 1'b1;\n"
            "        fetch_next_offset_r = 3'd4;\n"
            "      end"
        ),
        expected_marker="[ACCESS-G1-FOOTPRINT-RED] C/C",
    ),
    VariantSpec(
        name="bridge_ignores_instruction_rresp",
        purpose=(
            "Treat a completed instruction R beat as successful regardless "
            "of its non-OK response code."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_access_footprint",
        old=(
            "        S_R0: begin\n"
            "          if (ifu_axi_rvalid_i) begin\n"
            "            if (ifu_axi_rresp_i != RESP_OK) begin"
        ),
        new=(
            "        S_R0: begin\n"
            "          if (ifu_axi_rvalid_i) begin\n"
            "            if (1'b0 && (ifu_axi_rresp_i != RESP_OK)) begin"
        ),
        expected_marker="[ACCESS-G1-RRESP-RED] C/C F=0",
    ),
    VariantSpec(
        name="bridge_samples_rresp_without_rvalid",
        purpose=(
            "Advance the instruction response state without an RVALID "
            "handshake, allowing inactive RRESP wires to affect the owner."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_access_footprint",
        old=(
            "        S_R0: begin\n"
            "          if (ifu_axi_rvalid_i) begin\n"
            "            if (ifu_axi_rresp_i != RESP_OK) begin"
        ),
        new=(
            "        S_R0: begin\n"
            "          if (1'b1) begin\n"
            "            if (ifu_axi_rresp_i != RESP_OK) begin"
        ),
        expected_marker=(
            "[ACCESS-G1-LIFECYCLE-RED] RRESP is sampled only on "
            "RVALID/RREADY and one halfword is outstanding"
        ),
    ),
    VariantSpec(
        name="bridge_exact_exec_pmp_uses_eight_bytes",
        purpose=(
            "Check an eight-byte range at each instruction halfword frontier "
            "instead of the exact two-byte executable range."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_access_footprint",
        old=(
            "  PmpChecker u_fetch_current_pmp_checker (\n"
            "    .paddr_i(fetch_current_paddr_w),\n"
            "    .access_size_i(4'd2),"
        ),
        new=(
            "  PmpChecker u_fetch_current_pmp_checker (\n"
            "    .paddr_i(fetch_current_paddr_w),\n"
            "    .access_size_i(4'd8),"
        ),
        expected_marker="[ACCESS-G1-PMP-RED] PMP C/C F=2",
    ),
    VariantSpec(
        name="pmp_unmatched_s_mode_exec_allows",
        purpose=(
            "Allow an unmatched S-mode executable access instead of applying "
            "the architectural default-deny rule."
        ),
        source_rel=PMP,
        make_variable="RTL_PMP_CHECKER",
        test_name="tb_ooo_fetch_access_footprint",
        old=(
            "    end else begin\n"
            "      fault_r = (priv_mode_i != `PRIV_M) &&\n"
            "                (access_read_i || access_write_i || access_exec_i);\n"
            "    end"
        ),
        new=(
            "    end else begin\n"
            "      fault_r = 1'b0;\n"
            "    end"
        ),
        expected_marker=(
            "[ACCESS-G1-PMP-RED] M-fill then S/no-PMP cache hit "
            "default-denies at F=0"
        ),
    ),
    VariantSpec(
        name="bridge_fills_partial_packet_before_fault",
        purpose=(
            "Assert packet-cache fill after a successful prefix beat even "
            "when the complete instruction footprint is still outstanding."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_access_footprint",
        old=(
            "  wire fetch_cache_fill_complete_w =\n"
            "      (state_q == S_R0) && ifu_axi_rvalid_i &&\n"
            "      (ifu_axi_rresp_i == RESP_OK) &&\n"
            "      !fetch_more_after_r_w && !packet_cross_page_q;"
        ),
        new=(
            "  wire fetch_cache_fill_complete_w =\n"
            "      (state_q == S_R0) && ifu_axi_rvalid_i &&\n"
            "      (ifu_axi_rresp_i == RESP_OK) &&\n"
            "      !packet_cross_page_q;"
        ),
        expected_marker="[ACCESS-G1-RRESP-RED] C/C F=2",
    ),
    VariantSpec(
        name="bridge_instruction_arsize_is_eight_bytes",
        purpose=(
            "Drive an eight-byte AXI size for instruction reads instead of "
            "the exact two-byte halfword transfer."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_access_attrs",
        old=(
            "  assign ifu_axi_arsize_o = ifu_axi_walk_ar_owner_w ? 3'd3 : 3'd1;"
        ),
        new="  assign ifu_axi_arsize_o = 3'd3;",
        expected_marker="[IFU-AXI-LANE] instruction AR is not a natural 2B beat",
    ),
    VariantSpec(
        name="bridge_instruction_arprot_is_data",
        purpose=(
            "Classify instruction reads as AXI data accesses instead of "
            "instruction/execute accesses."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_access_attrs",
        old=(
            "  assign ifu_axi_arprot_o = ifu_axi_walk_ar_owner_w ? 3'b000 : 3'b100;"
        ),
        new="  assign ifu_axi_arprot_o = 3'b000;",
        expected_marker="[IFU-AXI-LANE] PTW AR is not an aligned 8B beat",
    ),
    VariantSpec(
        name="bridge_ptw_arsize_is_two_bytes",
        purpose=(
            "Drive a two-byte AXI size for an implicit PTE read instead of "
            "the required aligned eight-byte transfer."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_access_attrs",
        old=(
            "  assign ifu_axi_arsize_o = ifu_axi_walk_ar_owner_w ? 3'd3 : 3'd1;"
        ),
        new="  assign ifu_axi_arsize_o = 3'd1;",
        expected_marker="[IFU-AXI-LANE] PTW AR is not an aligned 8B beat",
    ),
    VariantSpec(
        name="bridge_ptw_arprot_is_execute",
        purpose=(
            "Classify implicit PTE reads as instruction accesses instead of "
            "AXI data accesses."
        ),
        source_rel=BRIDGE,
        make_variable="RTL_OOO_FETCH_AXI_BRIDGE",
        test_name="tb_ooo_fetch_axi_access_attrs",
        old=(
            "  assign ifu_axi_arprot_o = ifu_axi_walk_ar_owner_w ? 3'b000 : 3'b100;"
        ),
        new="  assign ifu_axi_arprot_o = 3'b100;",
        expected_marker="[IFU-AXI-LANE] instruction AR is not a natural 2B beat",
    ),
    VariantSpec(
        name="xbar_ignores_slave_execute_mask",
        purpose=(
            "Ignore SLAVE_EXEC_MASK[decoded] while ARPROT[2] marks an "
            "instruction read, allowing the decoded device slave to accept AR."
        ),
        source_rel=CROSSBAR,
        make_variable="RTL_AXI_XBAR",
        test_name="tb_axi_exec_firewall",
        old=(
            "      decode_read_slave = (prot[2] && !SLAVE_EXEC_MASK[decoded]) ?\n"
            "                          default_slave_idx() : decoded;"
        ),
        new="      decode_read_slave = decoded;",
        expected_marker="IFU UART is redirected to default",
    ),
    VariantSpec(
        name="xbar_stalled_ar_uses_live_master_address",
        purpose=(
            "Drive slave ARADDR during ARVALID backpressure from live "
            "m_araddr_i instead of rd_addr_q for the registered read owner."
        ),
        source_rel=CROSSBAR,
        make_variable="RTL_AXI_XBAR",
        test_name="tb_axi_exec_firewall",
        old="        s_araddr_r[s*ADDR_W +: ADDR_W] = rd_addr_q[s];",
        new=(
            "        s_araddr_r[s*ADDR_W +: ADDR_W] =\n"
            "            m_addr_slice(m_araddr_i, master_int(rd_owner_q[s]));"
        ),
        expected_marker="stalled executable AR cycle1 ARADDR low",
    ),
    VariantSpec(
        name="xbar_releases_buffered_read_without_master_ready",
        purpose=(
            "Release the buffered read owner on RVALID alone instead of the "
            "master RVALID/RREADY handshake."
        ),
        source_rel=CROSSBAR,
        make_variable="RTL_AXI_XBAR",
        test_name="tb_axi_xbar",
        old=(
            "        if (rd_resp_valid_q[m] && m_rready_i[m]) begin\n"
            "          rd_resp_valid_q[m] <= 1'b0;\n"
            "          rd_master_busy_q[m] <= 1'b0;\n"
            "        end"
        ),
        new=(
            "        if (rd_resp_valid_q[m]) begin\n"
            "          rd_resp_valid_q[m] <= 1'b0;\n"
            "          rd_master_busy_q[m] <= 1'b0;\n"
            "        end"
        ),
        expected_marker="buffered read stall stable rvalid",
    ),
    VariantSpec(
        name="pair_drops_lane1_fault_behind_branch",
        purpose=(
            "Suppress a visible lane1 fetch fault solely because lane0 is a "
            "conditional branch."
        ),
        source_rel=PAIR,
        make_variable="RTL_OOO_FETCH_HEAD_PAIR_GATE",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "  assign head_fetch_fault1_o =\n"
            "      fifo_has_packet_i && head_slot1_valid_i && !head_fetch_fault0_o &&\n"
            "      !head0_facts_o[`OOO_SLOT_FACT_JUMP] &&\n"
            "      !head0_facts_o[`OOO_SLOT_FACT_STOP] && (head_resp1_i != 2'b00);"
        ),
        new=(
            "  assign head_fetch_fault1_o =\n"
            "      fifo_has_packet_i && head_slot1_valid_i && !head_fetch_fault0_o &&\n"
            "      !head0_facts_o[`OOO_SLOT_FACT_BRANCH] &&\n"
            "      !head0_facts_o[`OOO_SLOT_FACT_JUMP] &&\n"
            "      !head0_facts_o[`OOO_SLOT_FACT_STOP] && (head_resp1_i != 2'b00);"
        ),
        expected_marker="[ROW-FAIL] pred-NT correct-NT branch + lane1 PF",
    ),
    VariantSpec(
        name="pair_ignores_slot1_visibility",
        purpose=(
            "Retain a lane1 fault owner even when fetch-time predicted-taken "
            "control marks slot1 invalid."
        ),
        source_rel=PAIR,
        make_variable="RTL_OOO_FETCH_HEAD_PAIR_GATE",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "  assign head_fetch_fault1_o =\n"
            "      fifo_has_packet_i && head_slot1_valid_i && !head_fetch_fault0_o &&\n"
            "      !head0_facts_o[`OOO_SLOT_FACT_JUMP] &&\n"
            "      !head0_facts_o[`OOO_SLOT_FACT_STOP] && (head_resp1_i != 2'b00);"
        ),
        new=(
            "  assign head_fetch_fault1_o =\n"
            "      fifo_has_packet_i && !head_fetch_fault0_o &&\n"
            "      !head0_facts_o[`OOO_SLOT_FACT_JUMP] &&\n"
            "      !head0_facts_o[`OOO_SLOT_FACT_STOP] && (head_resp1_i != 2'b00);"
        ),
        expected_marker="[ROW-FAIL] pred-taken poison lane1 PF is invisible",
    ),
    VariantSpec(
        name="dispatch_barrier_ignores_lane1_fetch_fault",
        purpose=(
            "Explicitly mask the dispatch barrier while lane1 owns a fetch "
            "fault, even when the slot facts also classify an arch trap."
        ),
        source_rel=DISPATCH,
        make_variable="RTL_OOO_FRONTEND_DISPATCH_GATE",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "  assign dispatch1_barrier_o =\n"
            "      lane1_base_w &&\n"
            "      (head_fetch_fault1_i ||\n"
            "       head1_exit_raw_i ||"
        ),
        new=(
            "  assign dispatch1_barrier_o =\n"
            "      lane1_base_w && !head_fetch_fault1_i &&\n"
            "      (head_fetch_fault1_i ||\n"
            "       head1_exit_raw_i ||"
        ),
        expected_marker="[ROW-FAIL] ordinary head0 + lane1 PF",
    ),
    VariantSpec(
        name="lane1_capture_drops_fetch_fault_arch_valid",
        purpose=(
            "Explicitly mask precise trap-valid while lane1 owns a fetch "
            "fault, regardless of the parallel arch-trap slot fact."
        ),
        source_rel=CAPTURE,
        make_variable="RTL_OOO_PENDING_LANE1_CAPTURE_GATE",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "  assign trap_exit_arch_valid_o =\n"
            "      barrier_base_i &&\n"
            "      (head_fetch_fault_i || csr_illegal_i || arch_trap_raw_w);"
        ),
        new=(
            "  assign trap_exit_arch_valid_o =\n"
            "      barrier_base_i && !head_fetch_fault_i &&\n"
            "      (head_fetch_fault_i || csr_illegal_i || arch_trap_raw_w);"
        ),
        expected_marker="[ROW-FAIL] ordinary head0 + lane1 PF",
    ),
    VariantSpec(
        name="arbiter_rob_walk_filters_real_lane1_access_fault",
        purpose=(
            "Apply the pseudo ACCESS filter without requiring absence of "
            "lane1 fetch-fault provenance."
        ),
        source_rel=ARBITER,
        make_variable="RTL_OOO_PENDING_DISPATCH_ARBITER",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "      (trap_exit_capture_lane1_w && trap_exit_lane1_arch_valid_w &&\n"
            "       // rob-walk 下仍过滤无 provenance 的 pseudo default ACCESS；真实 lane1\n"
            "       // fetch AF 由 head_fetch_fault1_i 证明 owner，必须 capture 后等待 branch resolve。\n"
            "       !(rob_walk_mode_i && !head_fetch_fault1_i &&\n"
            "         (trap_exit_lane1_cause_w == `EXC_INST_ACCESS_FAULT)));"
        ),
        new=(
            "      (trap_exit_capture_lane1_w && trap_exit_lane1_arch_valid_w &&\n"
            "       !(rob_walk_mode_i &&\n"
            "         (trap_exit_lane1_cause_w == `EXC_INST_ACCESS_FAULT)));"
        ),
        expected_marker="[ROW-FAIL] ordinary head0 + lane1 AF",
    ),
    VariantSpec(
        name="decoder_starts_lane1_at_fixed_halfword",
        purpose=(
            "Start lane1 byte-range ownership at offset two even when lane0 "
            "is a four-byte instruction."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old="  wire [3:0] dec1_start_byte_w = dec0_len_bytes_w;",
        new="  wire [3:0] dec1_start_byte_w = 4'd2;",
        expected_marker="[ACCESS-G1-OWNER-MAP-RED] U/C F=4",
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
    root: pathlib.Path,
    log_path: pathlib.Path,
    transient_dir: pathlib.Path,
) -> int:
    resolved_log = repository_path(root, log_path)
    transient = transient_dir.resolve(strict=True)
    if transient.is_relative_to(root):
        raise ValueError("transient compile directory must be outside repository")
    if transient.parent != pathlib.Path("/tmp") or not transient.name.startswith(
        "rv64-ifu-access-v9i."
    ):
        raise ValueError(f"unexpected transient compile directory: {transient}")
    if log_path.is_symlink() or not resolved_log.is_file():
        raise ValueError(f"log is not an exact regular file: {log_path}")
    text = resolved_log.read_text(encoding="utf-8")
    replacements = text.count(str(transient))
    if replacements:
        normalized = normalize_transient_paths(text, transient)
    else:
        if "/tmp/rv64-ifu-access-v9i." in text:
            raise ValueError("log contains an unbound IFU access transient path")
        normalized = text
    resolved_log.write_text(normalized, encoding="utf-8")
    return replacements


def normalize_log_directory(
    root: pathlib.Path,
    log_dir: pathlib.Path,
    transient_dir: pathlib.Path,
) -> tuple[int, int]:
    resolved_dir = repository_path(root, log_dir)
    if not resolved_dir.is_dir():
        raise ValueError(f"log directory is missing: {resolved_dir}")
    logs = sorted(resolved_dir.glob("*.log"))
    if not logs:
        raise ValueError("log inventory is empty")
    replacements = sum(
        normalize_log_path(root, path, transient_dir) for path in logs)
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
        prefix=f"rv64-v9i-{spec.name}.", dir="/tmp",
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
            timeout=180,
        )
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver = completed.stdout + completed.stderr
        combined = test_log + (
            "\n[RTL-VERIFICATION-VARIANT-DRIVER]\n" + driver
            if driver else ""
        )
        log_path.write_text(
            normalize_transient_paths(combined, temp), encoding="utf-8")
        compiled_image = build_dir / f"{spec.test_name}.vvp"
        compile_success = (
            compiled_image.is_file()
            and "[COMPILE]" in test_log
            and "compile returned nonzero status" not in test_log
        )
        marker_observed = spec.expected_marker in test_log
        dynamic_rejected = (
            compile_success
            and completed.returncode != 0
            and marker_observed
            and "[RESULT] FAIL status=" in test_log
            and "[RESULT] PASS" not in test_log
        )
    return {
        "name": spec.name,
        "debt_id": "IFU-ACCESS-G1",
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
    parser.add_argument("--normalize-log", type=pathlib.Path)
    parser.add_argument("--transient-dir", type=pathlib.Path)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)
    normalize_modes = sum(value is not None for value in (
        args.normalize_log_dir, args.normalize_log))
    if normalize_modes:
        if (
            normalize_modes != 1 or args.transient_dir is None
            or args.output is not None or args.audit
        ):
            parser.error(
                "log normalization requires one log input and --transient-dir")
        if args.normalize_log_dir is not None:
            count, replacements = normalize_log_directory(
                root, args.normalize_log_dir, args.transient_dir)
        else:
            count = 1
            replacements = normalize_log_path(
                root, args.normalize_log, args.transient_dir)
        print(
            f"[IFU-ACCESS-LOG-NORMALIZATION] logs={count} "
            f"replacements={replacements} token={TRANSIENT_DIR_TOKEN}")
        return 0
    if args.transient_dir is not None:
        parser.error("--transient-dir requires a log normalization mode")
    if args.audit:
        for spec in VARIANTS:
            reconstruct_variant(root, spec)
        print(f"[IFU-ACCESS-VARIANT-AUDIT] variants={len(VARIANTS)} PASS")
        return 0
    if args.output is None:
        parser.error("variant execution requires --output")
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
        encoding="utf-8",
    )
    print(
        f"[IFU-ACCESS-RTL-VARIANTS] required={len(VARIANTS)} "
        f"compile_success={compile_success} "
        f"dynamic_rejected={dynamic_rejected} "
        f"source_unchanged={str(before == after).lower()}"
    )
    return 0 if (
        compile_success == len(VARIANTS)
        and dynamic_rejected == len(VARIANTS)
        and before == after
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
