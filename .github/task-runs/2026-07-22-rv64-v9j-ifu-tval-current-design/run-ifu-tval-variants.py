#!/usr/bin/env python3
"""Compile and dynamically reject local RV64 IFU-TVAL-G1 RTL variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-ifu-tval-rtl-variants-v1"
SUITE_RUN_ID = "2026-07-22-rv64-v9j-ifu-tval-current-design"
TRANSIENT_DIR_TOKEN = "<IFU_TVAL_V9J_TRANSIENT_TMP>"


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


DECODE = "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v"
FIFO = "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v"
FRONTEND = "npc/rv64/vsrc/frontend/OooFrontend.v"
PAIR = "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v"
DISPATCH = "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v"
CAPTURE = "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v"
ARBITER = "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v"
PENDING = "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v"
STOP = "npc/rv64/vsrc/control/OooStopPendingSequencer.v"
CSR = "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v"


VARIANTS = (
    VariantSpec(
        name="decoder_drops_faulting_halfword_offset",
        purpose=(
            "Return packet start PC instead of packet_pc plus the first "
            "failing halfword byte offset."
        ),
        source_rel=DECODE,
        make_variable="RTL_OOO_FETCH_PACKET_DECODE",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "  assign fault_tval_o =\n"
            "      rsp_pc_i + {{(`XLEN-3){1'b0}}, rsp_resp0_bytes_i};"
        ),
        new="  assign fault_tval_o = rsp_pc_i;",
        expected_marker="[TVAL-G1-LIFECYCLE-RED] PF C/C F2",
    ),
    VariantSpec(
        name="fifo_direct_head_substitutes_packet_pc",
        purpose=(
            "Place lane0 packet PC in the direct-head fault-tval field during "
            "an empty enqueue."
        ),
        source_rel=FIFO,
        make_variable="RTL_OOO_FETCH_PACKET_FIFO",
        test_name="tb_ooo_fetch_packet_fifo",
        old=(
            "          enqueue_packet_next_pc_i,\n"
            "          enqueue_fault_tval_i,"
        ),
        new=(
            "          enqueue_packet_next_pc_i,\n"
            "          enqueue_pc0_i,"
        ),
        expected_marker="[CHECK-FAIL] packet A fault-tval",
    ),
    VariantSpec(
        name="fifo_ring_storage_substitutes_packet_pc",
        purpose=(
            "Store lane0 packet PC in the ring fault-tval array instead of "
            "the packet frontier metadata."
        ),
        source_rel=FIFO,
        make_variable="RTL_OOO_FETCH_PACKET_FIFO",
        test_name="tb_ooo_fetch_packet_fifo",
        old="        fault_tval_q[tail_q] <= enqueue_fault_tval_i;",
        new="        fault_tval_q[tail_q] <= enqueue_pc0_i;",
        expected_marker="[T3W-FIFO-HEAD-SHADOW]",
    ),
    VariantSpec(
        name="frontend_projection_substitutes_fifo_pc",
        purpose=(
            "Project the FIFO lane0 PC instead of the registered packet "
            "faulting-halfword address at the OooFrontend head boundary."
        ),
        source_rel=FRONTEND,
        make_variable="RTL_OOO_FRONTEND",
        test_name="tb_ooo_core_top_glue",
        old="  assign head_fetch_fault_tval_w = fifo_head_fault_tval_w;",
        new="  assign head_fetch_fault_tval_w = fifo_head_pc0_w;",
        expected_marker="[CHECK-FAIL] fetch fault handler reads precise mtval",
    ),
    VariantSpec(
        name="lane0_capture_falls_back_to_instruction_pc",
        purpose=(
            "Use lane0 instruction PC for a lane0 fetch fault instead of the "
            "packet faulting-halfword address."
        ),
        source_rel=ARBITER,
        make_variable="RTL_OOO_PENDING_DISPATCH_ARBITER",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "      trap_exit_capture_fetch_fault0_w ? head_fetch_fault_tval_i :"
        ),
        new="      trap_exit_capture_fetch_fault0_w ? head_pc0_i :",
        expected_marker="[TVAL-G1-LIFECYCLE-RED] PF U/C F2",
    ),
    VariantSpec(
        name="lane1_capture_falls_back_to_instruction_pc",
        purpose=(
            "Use lane1 instruction PC for a lane1 fetch fault instead of the "
            "packet faulting-halfword address."
        ),
        source_rel=CAPTURE,
        make_variable="RTL_OOO_PENDING_LANE1_CAPTURE_GATE",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "      head_fetch_fault_i ? head_fetch_fault_tval_i :\n"
            "      head_pc_i;"
        ),
        new="      head_pc_i;",
        expected_marker="[TVAL-G1-LIFECYCLE-RED] PF C/U F4",
    ),
    VariantSpec(
        name="dispatch_barrier_captures_before_ready",
        purpose=(
            "Fire the lane1 fetch-fault barrier while dispatch0 is stalled, "
            "before the current FIFO head tuple is accepted."
        ),
        source_rel=DISPATCH,
        make_variable="RTL_OOO_FRONTEND_DISPATCH_GATE",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "  assign dispatch1_barrier_fire_o =\n"
            "      dispatch1_barrier_o && !dispatch0_unsupported_i && dispatch0_ready_i;"
        ),
        new=(
            "  assign dispatch1_barrier_fire_o =\n"
            "      dispatch1_barrier_o && !dispatch0_unsupported_i;"
        ),
        expected_marker="[TVAL-G1-DISPATCH-STALL-RED]",
    ),
    VariantSpec(
        name="pending_capture_substitutes_trap_pc",
        purpose=(
            "Capture pending trap PC into the tval register instead of the "
            "owned faulting-halfword address."
        ),
        source_rel=PENDING,
        make_variable="RTL_OOO_PENDING_TRAP_EXIT_SEQUENCER",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old="        pending_trap_tval_o <= capture_trap_tval_i;",
        new="        pending_trap_tval_o <= capture_trap_pc_i;",
        expected_marker="[TVAL-G1-LIFECYCLE-RED] PF C/U F4",
    ),
    VariantSpec(
        name="pending_squash_retains_stale_tval",
        purpose=(
            "Retain the pending tval payload when a branch-resolution squash "
            "invalidates the speculative trap owner."
        ),
        source_rel=PENDING,
        make_variable="RTL_OOO_PENDING_TRAP_EXIT_SEQUENCER",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "          pending_trap_pc_o <= {`XLEN{1'b0}};\n"
            "          pending_trap_tval_o <= {`XLEN{1'b0}};"
        ),
        new=(
            "          pending_trap_pc_o <= {`XLEN{1'b0}};\n"
            "          pending_trap_tval_o <= pending_trap_tval_o;"
        ),
        expected_marker="[TVAL-G1-CONTROL-RED] c.beqz squash PF",
    ),
    VariantSpec(
        name="stop_pending_retains_branch_squash",
        purpose=(
            "Retain the fetch-fault stop bit when branch resolution cancels "
            "the speculative pending cause, PC and tval tuple."
        ),
        source_rel=STOP,
        make_variable="RTL_OOO_STOP_PENDING_SEQUENCER",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "      end else if (!direct_frontend_flush_i && branch_resolve_untracked_i) begin\n"
            "        stop_pending_o <= 1'b0;"
        ),
        new=(
            "      end else if (!direct_frontend_flush_i && branch_resolve_untracked_i) begin\n"
            "        stop_pending_o <= stop_pending_o;"
        ),
        expected_marker="[TVAL-G1-CONTROL-RED] c.beqz squash PF",
    ),
    VariantSpec(
        name="csr_request_substitutes_pending_pc",
        purpose=(
            "Drive trap-ex tval from pending PC instead of the pending tval "
            "field when the architectural trap fires."
        ),
        source_rel=CSR,
        make_variable="RTL_OOO_CSR_TRAP_REQUEST_MUX",
        test_name="tb_ooo_ifu_lane1_fault_owner",
        old=(
            "  assign trap_ex_tval_o =\n"
            "      pending_arch_trap_fire_o ? pending_trap_tval_i : {`XLEN{1'b0}};"
        ),
        new=(
            "  assign trap_ex_tval_o =\n"
            "      pending_arch_trap_fire_o ? pending_trap_pc_i : {`XLEN{1'b0}};"
        ),
        expected_marker="[TVAL-G1-LIFECYCLE-RED] PF C/U F4",
    ),
    VariantSpec(
        name="pair_ignores_predicted_taken_lane_visibility",
        purpose=(
            "Create a lane1 fault owner even though a predicted-taken lane0 "
            "compressed branch marks lane1 invalid."
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
        expected_marker="[TVAL-G1-CONTROL-RED] c.beqz pred-taken PF",
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
        "rv64-ifu-tval-v9j."
    ):
        raise ValueError(f"unexpected transient compile directory: {transient}")
    if log_path.is_symlink() or not resolved_log.is_file():
        raise ValueError(f"log is not an exact regular file: {log_path}")
    text = resolved_log.read_text(encoding="utf-8")
    replacements = text.count(str(transient))
    if replacements:
        normalized = normalize_transient_paths(text, transient)
    else:
        if "/tmp/rv64-ifu-tval-v9j." in text:
            raise ValueError("log contains an unbound IFU tval transient path")
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
        prefix=f"rv64-v9j-{spec.name}.", dir="/tmp",
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
        "debt_id": "IFU-TVAL-G1",
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
            f"[IFU-TVAL-LOG-NORMALIZATION] logs={count} "
            f"replacements={replacements} token={TRANSIENT_DIR_TOKEN}"
        )
        return 0
    if args.transient_dir is not None:
        parser.error("--transient-dir requires --normalize-log-dir")
    if args.audit:
        for spec in VARIANTS:
            reconstruct_variant(root, spec)
        print(f"[IFU-TVAL-VARIANT-AUDIT] variants={len(VARIANTS)} PASS")
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
        f"[IFU-TVAL-RTL-VARIANTS] required={len(VARIANTS)} "
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
