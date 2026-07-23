#!/usr/bin/env python3
"""Compile and dynamically reject local RV64 memory-lifecycle RTL variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-memory-issue-lifecycle-rtl-variants-v1"
SUITE_RUN_ID = "2026-07-22-rv64-v9f-memory-issue-lifecycle"
TRANSIENT_DIR_TOKEN = "<MEMORY_LIFECYCLE_TRANSIENT_TMP>"


@dataclasses.dataclass(frozen=True)
class VariantSpec:
    name: str
    debt_id: str
    purpose: str
    source_rel: str
    make_variable: str
    test_name: str
    ivflags: str
    old: str
    new: str
    expected_marker: str


VARIANTS = (
    VariantSpec(
        name="issue1_request_without_terminal_consume",
        debt_id="MEM-ISSUE-G1",
        purpose=(
            "Remove the edge-old terminal0 exclusion from terminal1 request "
            "VALID while retaining it on terminal1 consume."),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        ivflags="-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED",
        old=(
            "  wire issue1_mem_req_valid_w =\n"
            "      ENABLE_DUAL_MEM ? issue1_dual_selected_w :\n"
            "      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&\n"),
        new=(
            "  wire issue1_mem_req_valid_w =\n"
            "      ENABLE_DUAL_MEM ? issue1_dual_selected_w :\n"
            "      (mem_issue1_res_valid_q &&\n"),
        expected_marker=(
            "V9F terminal1 has no early request valid got=1 expected=0"),
    ),
    VariantSpec(
        name="issue1_terminal_consume_without_request",
        debt_id="MEM-ISSUE-G1",
        purpose=(
            "Remove the edge-old terminal0 exclusion from terminal1 consume "
            "while retaining it on terminal1 request VALID."),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        ivflags="-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED",
        old=(
            "  assign mem_issue1_res_consume_fire_w =\n"
            "      ENABLE_DUAL_MEM ?\n"
            "      (mem_issue1_res_dual_local_consume_w || "
            "issue1_mem_request_fire_w) :\n"
            "      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&\n"
            "       mem_issue1_res_ready_w);"),
        new=(
            "  assign mem_issue1_res_consume_fire_w =\n"
            "      ENABLE_DUAL_MEM ?\n"
            "      (mem_issue1_res_dual_local_consume_w || "
            "issue1_mem_request_fire_w) :\n"
            "      (mem_issue1_res_valid_q &&\n"
            "       mem_issue1_res_ready_w);"),
        expected_marker=(
            "V9F terminal1 held behind edge-old terminal0 got=1 expected=0"),
    ),
    VariantSpec(
        name="issue1_normal_launch_false_closed",
        debt_id="MEM-ISSUE-G1",
        purpose=(
            "Close terminal1 normal request VALID so the later positive "
            "launch proves the oracle is not satisfied by permanent hold."),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        ivflags="-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED",
        old=(
            "  wire issue1_mem_req_valid_w =\n"
            "      ENABLE_DUAL_MEM ? issue1_dual_selected_w :\n"
            "      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&\n"),
        new=(
            "  wire issue1_mem_req_valid_w =\n"
            "      ENABLE_DUAL_MEM ? issue1_dual_selected_w :\n"
            "      (1'b0 && mem_issue1_res_valid_q && "
            "!mem_issue_res_valid_q &&\n"),
        expected_marker=(
            "V9F terminal1 request valid after terminal0 clears got=0 "
            "expected=1"),
    ),
    VariantSpec(
        name="issue1_consume_uses_valid_under_backpressure",
        debt_id="MEM-ISSUE-G1",
        purpose=(
            "Use request VALID rather than request fire eligibility to "
            "consume a backpressured terminal1 transaction."),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        ivflags="-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED",
        old=(
            "  assign mem_issue1_res_consume_fire_w =\n"
            "      ENABLE_DUAL_MEM ?\n"
            "      (mem_issue1_res_dual_local_consume_w || "
            "issue1_mem_request_fire_w) :\n"
            "      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&\n"
            "       mem_issue1_res_ready_w);"),
        new=(
            "  assign mem_issue1_res_consume_fire_w =\n"
            "      ENABLE_DUAL_MEM ?\n"
            "      (mem_issue1_res_dual_local_consume_w || "
            "issue1_mem_request_fire_w) :\n"
            "      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&\n"
            "       (mem_issue1_res_ready_w || issue1_mem_req_valid_w));"),
        expected_marker="V9F backpressure holds terminal1 got=0 expected=1",
    ),
    VariantSpec(
        name="miq_birth_uses_valid_under_backpressure",
        debt_id="MEM-ISSUE-G1",
        purpose=(
            "Create the bank0 MIQ owner from request VALID instead of the "
            "accepted request handshake under backpressure."),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        ivflags="-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED",
        old="  assign miq_push_valid_w = mem_req_fire_any_w;",
        new="  assign miq_push_valid_w = mem_req_valid_o;",
        expected_marker=(
            "V9F backpressure forbids MIQ owner birth got=1 expected=0"),
    ),
    VariantSpec(
        name="issue1_terminal_retained_after_launch",
        debt_id="MEM-ISSUE-G1",
        purpose=(
            "Retain terminal1 valid after an accepted launch so the same "
            "transaction is offered again on the following cycle."),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        ivflags="-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED",
        old=(
            "    end else if (mem_issue1_res_consume_fire_w) begin\n"
            "      mem_issue1_res_valid_q <= 1'b0;\n"
            "    end\n"
            "  end\n\n"
            "`ifdef OOO_ASSERT"),
        new=(
            "    end else if (mem_issue1_res_consume_fire_w) begin\n"
            "      mem_issue1_res_valid_q <= 1'b1;\n"
            "    end\n"
            "  end\n\n"
            "`ifdef OOO_ASSERT"),
        expected_marker=(
            "V9F terminal1 clears after exact launch got=1 expected=0"),
    ),
    VariantSpec(
        name="issue1_consume_uses_global_port_fire",
        debt_id="MEM-ISSUE-G1",
        purpose=(
            "Consume terminal1 on any accepted bank0 request instead of only "
            "terminal1's own selected request or local terminal event."),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        ivflags="-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED",
        old=(
            "  assign mem_issue1_res_consume_fire_w =\n"
            "      ENABLE_DUAL_MEM ?\n"
            "      (mem_issue1_res_dual_local_consume_w || "
            "issue1_mem_request_fire_w) :\n"
            "      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&\n"
            "       mem_issue1_res_ready_w);"),
        new=(
            "  assign mem_issue1_res_consume_fire_w =\n"
            "      ENABLE_DUAL_MEM ?\n"
            "      (mem_issue1_res_dual_local_consume_w || "
            "issue1_mem_request_fire_w) :\n"
            "      (mem_issue1_res_valid_q &&\n"
            "       (mem_req_fire_any_w ||\n"
            "        (!mem_issue_res_valid_q && mem_issue1_res_ready_w)));"),
        expected_marker=(
            "V9F competing terminal0 fire does not consume terminal1 "
            "got=1 expected=0"),
    ),
    VariantSpec(
        name="issue0_miq_birth_uses_terminal1_identity",
        debt_id="MEM-ISSUE-G1",
        purpose=(
            "Select terminal1 ROB identity for a terminal0-owned request fire "
            "to prove MIQ birth is qualified by the actual request-mux owner."),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        ivflags="-DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED",
        old=(
            "      push_issue0_w ? mem_issue_res_rob_idx_q :\n"
            "      push_issue1_w ? mem_issue1_res_rob_idx_q :"),
        new=(
            "      push_issue0_w ? mem_issue1_res_rob_idx_q :\n"
            "      push_issue1_w ? mem_issue1_res_rob_idx_q :"),
        expected_marker="V9F competing request MIQ ROB identity got=",
    ),
    VariantSpec(
        name="miq_flush_replays_consumed_drain",
        debt_id="MIQ-FLUSH-G1",
        purpose=(
            "Remove fired-head subtraction from MIQ flush compaction so an "
            "already consumed transport-irrevocable store DRAIN reappears."),
        source_rel="npc/rv64/vsrc/memory/OooMemInflightQueue.v",
        make_variable="RTL_OOO_MEM_INFLIGHT_QUEUE",
        test_name="tb_ooo_mem_inflight_queue",
        ivflags="",
        old=(
            "        if ((rd[ENTRY_W:0] < count_q) && valid_q[src] &&\n"
            "            (kind_q[src] == KIND_DRAIN) &&\n"
            "            !(pop_fire_w && (rd == 0))) begin"),
        new=(
            "        if ((rd[ENTRY_W:0] < count_q) && valid_q[src] &&\n"
            "            (kind_q[src] == KIND_DRAIN)) begin"),
        expected_marker="flush+pop single DRAIN count",
    ),
    VariantSpec(
        name="miq_flush_drops_unconsumed_drain",
        debt_id="MIQ-FLUSH-G1",
        purpose=(
            "Disable the MIQ DRAIN keep-set so an unconsumed, ROB-head-"
            "authorized physical-write owner is removed by pipeline flush."),
        source_rel="npc/rv64/vsrc/memory/OooMemInflightQueue.v",
        make_variable="RTL_OOO_MEM_INFLIGHT_QUEUE",
        test_name="tb_ooo_mem_inflight_queue",
        ivflags="",
        old=(
            "        if ((rd[ENTRY_W:0] < count_q) && valid_q[src] &&\n"
            "            (kind_q[src] == KIND_DRAIN) &&\n"
            "            !(pop_fire_w && (rd == 0))) begin"),
        new=(
            "        if ((rd[ENTRY_W:0] < count_q) && valid_q[src] &&\n"
            "            1'b0 && (kind_q[src] == KIND_DRAIN) &&\n"
            "            !(pop_fire_w && (rd == 0))) begin"),
        expected_marker="flush keeps only unconsumed DRAIN got=",
    ),
    VariantSpec(
        name="miq_flush_treats_valid_head_as_fired",
        debt_id="MIQ-FLUSH-G1",
        purpose=(
            "Subtract a valid DRAIN head during pipeline flush without an "
            "accepted pop handshake, violating the no-fire survivor rule."),
        source_rel="npc/rv64/vsrc/memory/OooMemInflightQueue.v",
        make_variable="RTL_OOO_MEM_INFLIGHT_QUEUE",
        test_name="tb_ooo_mem_inflight_queue",
        ivflags="",
        old=(
            "        if ((rd[ENTRY_W:0] < count_q) && valid_q[src] &&\n"
            "            (kind_q[src] == KIND_DRAIN) &&\n"
            "            !(pop_fire_w && (rd == 0))) begin"),
        new=(
            "        if ((rd[ENTRY_W:0] < count_q) && valid_q[src] &&\n"
            "            (kind_q[src] == KIND_DRAIN) &&\n"
            "            !(head_valid_o && (rd == 0))) begin"),
        expected_marker="flush keeps only unconsumed DRAIN got=",
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
        raise ValueError("raw log already contains the normalization token")
    exact = str(transient.resolve(strict=True))
    if exact not in text:
        raise ValueError("raw log does not bind the current transient directory")
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
        "rv64-memory-lifecycle-v9f."
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
        prefix=f"rv64-v9f-{spec.name}.", dir="/tmp",
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
            f"{spec.make_variable}={variant_path}",
        ]
        if spec.ivflags:
            command.append(f"TB_IVFLAGS_{spec.test_name}={spec.ivflags}")
        command.append(str(target))
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
        "debt_id": spec.debt_id,
        "purpose": spec.purpose,
        "source": spec.source_rel,
        "make_variable": spec.make_variable,
        "test_name": spec.test_name,
        "ivflags": spec.ivflags,
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
            f"[MEMORY-LIFECYCLE-LOG-NORMALIZATION] logs={count} "
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
    by_debt = {
        debt_id: {
            "required": sum(spec.debt_id == debt_id for spec in VARIANTS),
            "compile_success": sum(
                row["debt_id"] == debt_id and bool(row["compile_success"])
                for row in results),
            "dynamic_rejected": sum(
                row["debt_id"] == debt_id and bool(row["dynamic_rejected"])
                for row in results),
        }
        for debt_id in sorted({spec.debt_id for spec in VARIANTS})
    }
    payload = {
        "schema": SCHEMA,
        "suite_run_id": SUITE_RUN_ID,
        "required": len(VARIANTS),
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "by_debt": by_debt,
        "source_unchanged": before == after,
        "source_sha256_before": before,
        "source_sha256_after": after,
        "results": results,
    }
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    print(
        f"[MEMORY-LIFECYCLE-RTL-VARIANTS] required={len(VARIANTS)} "
        f"compile_success={compile_success} dynamic_rejected={dynamic_rejected} "
        f"source_unchanged={str(before == after).lower()}")
    return 0 if (
        compile_success == len(VARIANTS)
        and dynamic_rejected == len(VARIANTS)
        and before == after
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
