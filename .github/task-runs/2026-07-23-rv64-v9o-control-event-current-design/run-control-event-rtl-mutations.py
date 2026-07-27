#!/usr/bin/env python3
"""Compile and reject local RV64 control-event RTL source variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-control-event-rtl-mutations-v3"
SUITE_RUN_ID = "2026-07-23-rv64-v9o-control-event-current-design"


@dataclasses.dataclass(frozen=True)
class MutationSpec:
    name: str
    oracle_family: str
    purpose: str
    source_rel: str
    make_variable: str
    test_name: str
    old: str
    new: str
    expected_markers: tuple[str, ...]
    extra_ivflags: tuple[str, ...] = ()
    rejection_mode: str = "dynamic"


MUTATIONS = (
    MutationSpec(
        name="strict_younger_changed_to_greater_equal",
        oracle_family="strict-younger-boundary",
        purpose=(
            "Change both current-kill and recovery completion cuts from "
            "strictly-younger (>) to boundary-inclusive (>=)."
        ),
        source_rel="npc/rv64/vsrc/writeback/OooRob.v",
        make_variable="RTL_OOO_ROB",
        test_name="tb_ooo_rob",
        old=(
            "producer_target_killed_now = target_age > boundary_age;\n"
            "      end else if (recovery_valid) begin\n"
            "        boundary_age = recovery_kill_idx - head_idx;\n"
            "        producer_target_killed_now = target_age > boundary_age;"
        ),
        new=(
            "producer_target_killed_now = target_age >= boundary_age;\n"
            "      end else if (recovery_valid) begin\n"
            "        boundary_age = recovery_kill_idx - head_idx;\n"
            "        producer_target_killed_now = target_age >= boundary_age;"
        ),
        expected_markers=(
            "v8f kill boundary remains completion-open",
            "v8f recovery preserves boundary completion query",
            "v8j generic completion also keeps equal boundary open",
        ),
    ),
    MutationSpec(
        name="c0_request_does_not_reach_c1",
        oracle_family="c0-c1-phase",
        purpose=(
            "Suppress the registered apply-valid bit so a C0 request cannot "
            "produce the required C1 typed apply."
        ),
        source_rel=(
            "npc/rv64/vsrc/control/OooControlEventApplySequencer.v"
        ),
        make_variable="RTL_OOO_CONTROL_EVENT_APPLY_SEQUENCER",
        test_name="tb_ooo_control_event_apply_sequencer",
        old="apply_valid_q <= request_valid_i;",
        new="apply_valid_q <= 1'b0;",
        expected_markers=("trap apply C1 valid got=0 exp=1",),
    ),
    MutationSpec(
        name="typed_reason_is_not_latched",
        oracle_family="typed-reason",
        purpose=(
            "Replace the accepted typed reason with NONE while retaining the "
            "C1 pulse and kill boundary."
        ),
        source_rel=(
            "npc/rv64/vsrc/control/OooControlEventApplySequencer.v"
        ),
        make_variable="RTL_OOO_CONTROL_EVENT_APPLY_SEQUENCER",
        test_name="tb_ooo_control_event_apply_sequencer",
        old="apply_reason_q <= request_reason_i;",
        new="apply_reason_q <= `REDIR_REASON_NONE;",
        expected_markers=("trap apply C1 reason got=0 exp=3",),
    ),
    MutationSpec(
        name="c0_request_is_reconstructed_from_trap_pulse",
        oracle_family="single-c0-source",
        purpose=(
            "Replace the sole ROB full-pregrant request source with the "
            "architectural trap pulse; a real queue-head CSR must then lose "
            "its required C1 typed apply."
        ),
        source_rel="npc/rv64/vsrc/core/OooCoreTopGlue.v",
        make_variable="RTL_OOO_CORE_TOP_GLUE",
        test_name="tb_ooo_core_top_glue_v9o_csr_qh",
        old=(
            "assign control_event_request_valid_w = "
            "control_full_flush_barrier_w;"
        ),
        new=(
            "assign control_event_request_valid_w = "
            "csr_trap_mem_valid_w;"
        ),
        expected_markers=(
            "V9O macro-on real queue-head CSR emits C1 typed apply",
        ),
    ),
    MutationSpec(
        name="pending_csr_owner_ignores_producer_id",
        oracle_family="pending-csr-owner",
        purpose=(
            "Classify any live pending CSR lease as the ROB head owner without "
            "the exact ProducerId comparison."
        ),
        source_rel="npc/rv64/vsrc/writeback/OooRob.v",
        make_variable="RTL_OOO_ROB",
        test_name="tb_ooo_rob",
        old=(
            "wire head0_pending_csr_owner_match_w =\n"
            "      pending_csr_owner_valid_i && head0_is_csr_w &&\n"
            "      ({slot_generation_q[head_q], head_q} ==\n"
            "       pending_csr_owner_producer_id_i);"
        ),
        new=(
            "wire head0_pending_csr_owner_match_w =\n"
            "      pending_csr_owner_valid_i && head0_is_csr_w;"
        ),
        expected_markers=(
            "V9O mismatched pending owner keeps queue-head full pregrant",
        ),
        extra_ivflags=("-DOOO_CSR_QUEUE_HEAD=1",),
    ),
    MutationSpec(
        name="head0_pregrant_does_not_mask_branch_event",
        oracle_family="control-event-priority",
        purpose=(
            "Expose an authorized younger branch packet even when an older "
            "head0 control event has the cycle-free pregrant."
        ),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        old=(
            "wire branch_resolve_production_w =\n"
            "      branch_resolve_authorized_w && "
            "!control_event_pregrant_w;"
        ),
        new=(
            "wire branch_resolve_production_w =\n"
            "      branch_resolve_authorized_w;"
        ),
        expected_markers=(
            "V9O C0 suppresses younger branch event",
            "V9O pending CSR pregrant suppresses younger branch event",
        ),
    ),
    MutationSpec(
        name="head0_pregrant_does_not_mask_branch_recovery",
        oracle_family="control-event-priority",
        purpose=(
            "Allow the younger branch recovery pulse to start ROB walk while "
            "an older head0 control event is selected."
        ),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_int_backend",
        old=(
            "assign branch_resolve_mispredict_w =\n"
            "      branch_resolve_mispredict_request_w &&\n"
            "      !control_event_pregrant_w;"
        ),
        new=(
            "assign branch_resolve_mispredict_w =\n"
            "      branch_resolve_mispredict_request_w;"
        ),
        expected_markers=(
            "V9O C0 suppresses younger branch recovery",
            "V9O pending CSR pregrant suppresses younger branch recovery",
        ),
    ),
    MutationSpec(
        name="queue_head_mode_requires_both_memory_pair_ids_at_head",
        oracle_family="csr-memory-order",
        purpose=(
            "Restore the over-constrained rule that requires both members of "
            "a dual-memory pair to equal the single ROB head."
        ),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_ooo_core_top_glue",
        old=(
            "wire mem_issue_res_requires_head_w =\n"
            "      iq_issue0_ctrl_w[`CTRL_AMO_BIT];\n"
            "  wire mem_issue_res_admit_w =\n"
            "      !mem_issue_res_requires_head_w ||\n"
            "      (rob_head_valid_w && "
            "(iq_issue0_rob_idx_w == rob_head_idx_w));\n"
            "  // Lane1 reservation is only the plain-memory partner of an "
            "already\n"
            "  // classified pair; special/AMO memory is excluded before "
            "this point.\n"
            "  wire mem_issue1_res_admit_w = 1'b1;"
        ),
        new=(
            "wire mem_issue_res_requires_head_w =\n"
            "      iq_issue0_ctrl_w[`CTRL_AMO_BIT] || "
            "`OOO_CSR_QUEUE_HEAD;\n"
            "  wire mem_issue_res_admit_w =\n"
            "      !mem_issue_res_requires_head_w ||\n"
            "      (rob_head_valid_w && "
            "(iq_issue0_rob_idx_w == rob_head_idx_w));\n"
            "  wire mem_issue1_res_admit_w =\n"
            "      !`OOO_CSR_QUEUE_HEAD ||\n"
            "      (rob_head_valid_w && "
            "(issue1_rob_idx_w == rob_head_idx_w));"
        ),
        expected_markers=(
            "[CHECK-FAIL] memory program reaches ebreak got=0 expected=1",
        ),
        extra_ivflags=("-DOOO_CSR_QUEUE_HEAD=1",),
    ),
    MutationSpec(
        name="registered_read_address_valid_is_barrier_gated",
        oracle_family="registered-axi-owner",
        purpose=(
            "Place the C0 barrier on the registered S_READ_ADDR AXI VALID "
            "path, illegally withdrawing a held owner."
        ),
        source_rel="npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge",
        old=(
            "(active_owner_verified_q && (state_q == S_READ_ADDR)) ||"
        ),
        new=(
            "(active_owner_verified_q && (state_q == S_READ_ADDR) &&\n"
            "       !control_full_flush_barrier_i) ||"
        ),
        expected_markers=("V9O C0 keeps registered ARVALID",),
    ),
    MutationSpec(
        name="registered_write_valids_are_barrier_gated",
        oracle_family="registered-axi-owner",
        purpose=(
            "Place the C0 barrier on registered AW/W VALID paths, illegally "
            "withdrawing both split-channel owners under backpressure."
        ),
        source_rel="npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge",
        old=(
            "assign lsu_axi_awvalid_o =\n"
            "      (active_owner_verified_q && (state_q == S_WRITE_REQ) && "
            "!aw_done_q) ||\n"
            "      (active_owner_verified_q && (state_q == S_AD_UPDATE) && "
            "!aw_done_q);\n"
            "  assign lsu_axi_awaddr_o ="
        ),
        new=(
            "assign lsu_axi_awvalid_o =\n"
            "      !control_full_flush_barrier_i &&\n"
            "      ((active_owner_verified_q && (state_q == S_WRITE_REQ) && "
            "!aw_done_q) ||\n"
            "       (active_owner_verified_q && (state_q == S_AD_UPDATE) && "
            "!aw_done_q));\n"
            "  assign lsu_axi_awaddr_o ="
        ),
        expected_markers=("V9O C0 keeps registered AWVALID",),
    ),
    MutationSpec(
        name="pregrant_reads_current_completion_ready",
        oracle_family="cycle-free-pregrant",
        purpose=(
            "Reconnect C0 pregrant to commit_ready with current formal-WB/LQ "
            "release bypasses instead of the registered-completion-only "
            "terminal permit."
        ),
        source_rel="npc/rv64/vsrc/writeback/OooRob.v",
        make_variable="RTL_OOO_ROB",
        test_name="tb_ooo_rob",
        old=(
            "!rst && !flush_i && !recover_q && "
            "commit_pregrant_ready_i &&"
        ),
        new=(
            "!rst && !flush_i && !recover_q && commit_ready_i &&"
        ),
        expected_markers=(
            "%Warning-UNOPTFLAT: <LOCAL-TEMP>/OooRob.v:361:26:",
        ),
        rejection_mode="lint-unoptflat",
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


def reconstruct_mutation(
    root: pathlib.Path,
    spec: MutationSpec,
) -> tuple[str, str]:
    source = (root / spec.source_rel).resolve(strict=True)
    if not source.is_relative_to(root) or source.is_symlink():
        raise ValueError(f"{spec.name}: source is outside the local RTL tree")
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL anchor is not unique")
    return text, text.replace(spec.old, spec.new, 1)


def run_full_cone_lint(
    root: pathlib.Path,
    replacement_rel: str | None = None,
    replacement_path: pathlib.Path | None = None,
) -> subprocess.CompletedProcess[str]:
    vsrc = root / "npc/rv64/vsrc"
    sources = sorted(vsrc.rglob("*.v"))
    if replacement_rel is not None:
        original = (root / replacement_rel).resolve(strict=True)
        sources = [path for path in sources if path.resolve() != original]
    command = [
        "verilator",
        "--lint-only",
        "--timing",
        "-Wall",
        "-Wno-fatal",
        "-DOOO_ASSERT",
        f"-I{vsrc}",
        f"-I{vsrc / 'include'}",
        "--top-module",
        "NpcCoreTop",
        *[str(path) for path in sources],
    ]
    if replacement_path is not None:
        command.append(str(replacement_path))
    return subprocess.run(
        command,
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
        timeout=180,
    )


def run_one(
    root: pathlib.Path,
    output_dir: pathlib.Path,
    spec: MutationSpec,
) -> dict[str, object]:
    original_text, mutation_text = reconstruct_mutation(root, spec)
    original_path = root / spec.source_rel
    original_sha = sha256_bytes(original_text.encode("utf-8"))
    mutation_sha = sha256_bytes(mutation_text.encode("utf-8"))
    if original_sha == mutation_sha:
        raise ValueError(f"{spec.name}: reconstructed mutation is a no-op")

    log_path = output_dir / f"{spec.name}.log"
    with tempfile.TemporaryDirectory(
        prefix=f"rv64-control-{spec.name}-",
    ) as temp_name:
        temp = pathlib.Path(temp_name)
        mutation_path = temp / original_path.name
        mutation_path.write_text(mutation_text, encoding="utf-8")
        result_dir = temp / "result"
        build_dir = temp / "build"
        target = result_dir / f"logs/{spec.test_name}.log"
        ivflags = [
            "-g2012",
            "-Wall",
            f"-I{root / 'npc/rv64/vsrc'}",
            f"-I{root / 'npc/rv64/vsrc/include'}",
            f"-I{root / 'npc/rv64/testbench/common'}",
            "-DOOO_ASSERT",
            *spec.extra_ivflags,
        ]
        command = [
            "make",
            "-C",
            str(root / "npc/rv64/testbench"),
            "-B",
            f"RESULT_DIR={result_dir}",
            f"BUILD_DIR={build_dir}",
            f"IVFLAGS={' '.join(ivflags)}",
            f"{spec.make_variable}={mutation_path}",
            str(target),
        ]
        completed = subprocess.run(
            command,
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            timeout=180,
        )
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver_text = completed.stdout + completed.stderr
        combined = test_log
        if driver_text:
            combined += "\n[RTL-MUTATION-DRIVER]\n" + driver_text
        combined = combined.replace(str(temp), "<LOCAL-TEMP>")
        log_path.write_text(combined, encoding="utf-8")

        compiled_image = build_dir / f"{spec.test_name}.vvp"
        compile_success = (
            compiled_image.is_file()
            and "[COMPILE] " in test_log
            and "compile returned nonzero status" not in test_log
        )
        lint_returncode: int | None = None
        lint_text = ""
        if spec.rejection_mode == "lint-unoptflat":
            lint_completed = run_full_cone_lint(
                root,
                replacement_rel=spec.source_rel,
                replacement_path=mutation_path,
            )
            lint_returncode = lint_completed.returncode
            lint_text = lint_completed.stdout + lint_completed.stderr
            lint_text = lint_text.replace(str(temp), "<LOCAL-TEMP>")
            combined += "\n[FULL-CONE-LINT]\n" + lint_text
            log_path.write_text(combined, encoding="utf-8")

        oracle_text = (
            lint_text
            if spec.rejection_mode == "lint-unoptflat"
            else test_log
        )
        observed_markers = {
            marker: marker in oracle_text for marker in spec.expected_markers
        }
        dynamic_rejected = (
            spec.rejection_mode == "dynamic"
            and compile_success
            and completed.returncode != 0
            and all(observed_markers.values())
            and "[RESULT] FAIL" in test_log
            and "[RESULT] PASS" not in test_log
        )
        lint_rejected = (
            spec.rejection_mode == "lint-unoptflat"
            and compile_success
            and completed.returncode == 0
            and "[RESULT] PASS" in test_log
            and all(observed_markers.values())
        )
        rejected = dynamic_rejected or lint_rejected

    return {
        "name": spec.name,
        "oracle_family": spec.oracle_family,
        "purpose": spec.purpose,
        "source": spec.source_rel,
        "make_variable": spec.make_variable,
        "test_name": spec.test_name,
        "rejection_mode": spec.rejection_mode,
        "extra_ivflags": list(spec.extra_ivflags),
        "original_sha256": original_sha,
        "mutation_sha256": mutation_sha,
        "expected_markers": list(spec.expected_markers),
        "observed_markers": observed_markers,
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "lint_rejected": lint_rejected,
        "rejected": rejected,
        "make_returncode": completed.returncode,
        "lint_returncode": lint_returncode,
        "log": {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        },
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args(argv)

    root = args.root.resolve(strict=True)
    output = repository_path(root, args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    log_dir = output.parent / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    import architecture_hard_gates as architecture
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import evidence_source_set

    rtl_sha_before, rtl_files_before = architecture.rtl_binding(root)
    verification_sha_before, verification_files_before = (
        evidence_source_set.verification_binding(root)
    )
    source_paths = sorted({spec.source_rel for spec in MUTATIONS})
    before = {name: sha256_file(root / name) for name in source_paths}
    baseline_lint = run_full_cone_lint(root)
    baseline_lint_text = baseline_lint.stdout + baseline_lint.stderr
    baseline_lint_path = output.parent / "baseline-verilator.log"
    baseline_lint_path.write_text(baseline_lint_text, encoding="utf-8")
    baseline_unoptflat = "%Warning-UNOPTFLAT" in baseline_lint_text
    results = [run_one(root, log_dir, spec) for spec in MUTATIONS]
    after = {name: sha256_file(root / name) for name in source_paths}
    rtl_sha_after, rtl_files_after = architecture.rtl_binding(root)
    verification_sha_after, verification_files_after = (
        evidence_source_set.verification_binding(root)
    )
    full_rtl_source_unchanged = (
        rtl_sha_before == rtl_sha_after
        and rtl_files_before == rtl_files_after
    )
    verification_source_unchanged = (
        verification_sha_before == verification_sha_after
        and verification_files_before == verification_files_after
    )
    compile_success = sum(bool(row["compile_success"]) for row in results)
    dynamic_rejected = sum(bool(row["dynamic_rejected"]) for row in results)
    lint_rejected = sum(bool(row["lint_rejected"]) for row in results)
    rejected = sum(bool(row["rejected"]) for row in results)
    payload = {
        "schema": SCHEMA,
        "suite_run_id": SUITE_RUN_ID,
        "required": len(MUTATIONS),
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "lint_rejected": lint_rejected,
        "rejected": rejected,
        "baseline_unoptflat": baseline_unoptflat,
        "baseline_lint": {
            "returncode": baseline_lint.returncode,
            "path": baseline_lint_path.relative_to(root).as_posix(),
            "sha256": sha256_file(baseline_lint_path),
        },
        "design_id": f"sha256:{rtl_sha_before}",
        "rtl_source_set": {
            "design_id": f"sha256:{rtl_sha_before}",
            "file_count": len(rtl_files_before),
            "files": rtl_files_before,
            "sha256": rtl_sha_before,
        },
        "full_rtl_source_unchanged": full_rtl_source_unchanged,
        "verification_source_set": {
            "file_count": len(verification_files_before),
            "files": verification_files_before,
            "sha256": verification_sha_before,
        },
        "verification_source_unchanged": verification_source_unchanged,
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
        f"[CONTROL-EVENT-G1-RTL-MUTATIONS] required={len(MUTATIONS)} "
        f"compile_success={compile_success} "
        f"rejected={rejected} "
        f"dynamic_rejected={dynamic_rejected} "
        f"lint_rejected={lint_rejected} "
        f"design_id=sha256:{rtl_sha_before} "
        f"baseline_unoptflat={str(baseline_unoptflat).lower()} "
        f"source_unchanged={str(before == after).lower()} "
        f"full_rtl_source_unchanged={str(full_rtl_source_unchanged).lower()} "
        f"verification_source_unchanged={str(verification_source_unchanged).lower()}"
    )
    return 0 if (
        compile_success == len(MUTATIONS)
        and rejected == len(MUTATIONS)
        and dynamic_rejected == len(MUTATIONS) - 1
        and lint_rejected == 1
        and not baseline_unoptflat
        and before == after
        and full_rtl_source_unchanged
        and verification_source_unchanged
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
