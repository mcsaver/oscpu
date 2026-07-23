#!/usr/bin/env python3
"""Compile and dynamically reject local RV64 XRET-G1 RTL variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-xret-rtl-mutations-v1"
SUITE_RUN_ID = "2026-07-21-rv64-v9e-xret-current-design"
TRANSIENT_DIR_TOKEN = "<XRET_TRANSIENT_TMP>"


@dataclasses.dataclass(frozen=True)
class MutationSpec:
    name: str
    purpose: str
    source_rel: str
    make_variable: str
    test_name: str
    old: str
    new: str
    expected_marker: str


@dataclasses.dataclass(frozen=True)
class OracleProbeSpec:
    name: str
    purpose: str
    test_name: str
    ivflags: str
    expected_marker: str


MUTATIONS = (
    MutationSpec(
        name="mret_mode_legality_removed",
        purpose=(
            "Remove the MRET current-mode legality predicate at the local "
            "RV64 head classifier."),
        source_rel="npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
        make_variable="RTL_OOO_FETCH_HEAD_CLASSIFY_GATE",
        test_name="tb_ooo_fetch_head_classify_gate",
        old=(
            "  wire mret_mode_illegal_w =\n"
            "      mret_raw_o && (priv_mode_i != `PRIV_M);"),
        new="  wire mret_mode_illegal_w = 1'b0;",
        expected_marker="mret in S-mode illegal got=0 expected=1",
    ),
    MutationSpec(
        name="sret_u_mode_legality_removed",
        purpose=(
            "Remove the U-mode SRET legality predicate at the local RV64 "
            "head classifier."),
        source_rel="npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
        make_variable="RTL_OOO_FETCH_HEAD_CLASSIFY_GATE",
        test_name="tb_ooo_fetch_head_classify_gate",
        old=(
            "  wire sret_mode_illegal_w =\n"
            "      sret_raw_o && (priv_mode_i == `PRIV_U);"),
        new="  wire sret_mode_illegal_w = 1'b0;",
        expected_marker="sret in U-mode illegal got=0 expected=1",
    ),
    MutationSpec(
        name="sret_tsr_legality_removed",
        purpose=(
            "Remove the S-mode mstatus.TSR SRET legality predicate at the "
            "local RV64 head classifier."),
        source_rel="npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
        make_variable="RTL_OOO_FETCH_HEAD_CLASSIFY_GATE",
        test_name="tb_ooo_fetch_head_classify_gate",
        old=(
            "  wire sret_tsr_illegal_w =\n"
            "      sret_raw_o && (priv_mode_i == `PRIV_S) &&\n"
            "      ((mstatus_i & `MSTATUS_TSR) != {`XLEN{1'b0}});"),
        new="  wire sret_tsr_illegal_w = 1'b0;",
        expected_marker="sret under tsr illegal got=0 expected=1",
    ),
    MutationSpec(
        name="legal_mret_overgated",
        purpose=(
            "Classify every MRET as illegal so the M-mode legal positive "
            "control proves the matrix is not satisfied by closing xRET."),
        source_rel="npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
        make_variable="RTL_OOO_FETCH_HEAD_CLASSIFY_GATE",
        test_name="tb_ooo_fetch_head_classify_gate",
        old=(
            "  wire mret_mode_illegal_w =\n"
            "      mret_raw_o && (priv_mode_i != `PRIV_M);"),
        new="  wire mret_mode_illegal_w = mret_raw_o;",
        expected_marker="mret in M-mode legal got=1 expected=0",
    ),
    MutationSpec(
        name="head0_arch_trap_system_exclusion_removed",
        purpose=(
            "Remove the head0 architectural-exception exclusion from the "
            "pending-system capture equation."),
        source_rel="npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
        make_variable="RTL_OOO_PENDING_DISPATCH_ARBITER",
        test_name="tb_ooo_priv_system",
        old=(
            "  assign pending_system_capture_head0_o =\n"
            "      capture_base_w &&\n"
            "      !csr_irq_pending_i &&\n"
            "      !head_fetch_fault0_i &&\n"
            "      !dispatch0_arch_trap_w &&\n"
            "      !dispatch0_exit_w &&\n"
            "      dispatch0_system_w && !dispatch0_csr_w && "
            "!head0_csr_illegal_i;"),
        new=(
            "  assign pending_system_capture_head0_o =\n"
            "      capture_base_w &&\n"
            "      !csr_irq_pending_i &&\n"
            "      !head_fetch_fault0_i &&\n"
            "      !dispatch0_exit_w &&\n"
            "      dispatch0_system_w && !dispatch0_csr_w && "
            "!head0_csr_illegal_i;"),
        expected_marker="[FLUSH-CONTRACT INV-7]",
    ),
    MutationSpec(
        name="lane1_arch_trap_system_exclusion_removed",
        purpose=(
            "Remove the lane1 architectural-exception exclusion from the "
            "pending-system capture equation."),
        source_rel="npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
        make_variable="RTL_OOO_PENDING_LANE1_CAPTURE_GATE",
        test_name="tb_ooo_priv_system",
        old=(
            "  assign system_capture_o =\n"
            "      barrier_base_i && system_raw_w && !csr_illegal_i &&\n"
            "      !arch_trap_raw_w;"),
        new=(
            "  assign system_capture_o =\n"
            "      barrier_base_i && system_raw_w && !csr_illegal_i;"),
        expected_marker=(
            "u-mode illegal sret does not request CsrFile sret "
            "got=1 expected=0"),
    ),
    MutationSpec(
        name="precise_trap_pc_offset",
        purpose=(
            "Offset the architectural-exception PC at the CSR request mux so "
            "the MRET program detects non-exact mepc transport."),
        source_rel="npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
        make_variable="RTL_OOO_CSR_TRAP_REQUEST_MUX",
        test_name="tb_ooo_priv_system",
        old=(
            "  assign trap_ex_pc_o =\n"
            "      pending_arch_trap_fire_o ? pending_trap_pc_i : "
            "pending_system_pc_i;"),
        new=(
            "  assign trap_ex_pc_o =\n"
            "      pending_arch_trap_fire_o ? "
            "(pending_trap_pc_i + 64'd4) : pending_system_pc_i;"),
        expected_marker="s-mode mret mepc got=",
    ),
    MutationSpec(
        name="precise_trap_tval_forced_zero",
        purpose=(
            "Force architectural-exception tval to zero at the CSR request "
            "mux so the MRET program detects instruction-value loss."),
        source_rel="npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
        make_variable="RTL_OOO_CSR_TRAP_REQUEST_MUX",
        test_name="tb_ooo_priv_system",
        old=(
            "  assign trap_ex_tval_o =\n"
            "      pending_arch_trap_fire_o ? pending_trap_tval_i : "
            "{`XLEN{1'b0}};"),
        new=(
            "  assign trap_ex_tval_o =\n"
            "      pending_arch_trap_fire_o ? {`XLEN{1'b0}} : "
            "{`XLEN{1'b0}};"),
        expected_marker="s-mode mret mtval got=",
    ),
)


ORACLE_PROBES = (
    OracleProbeSpec(
        name="csr_request_observer_known_transaction",
        purpose=(
            "Point the illegal-xRET CSR-request zero oracle at the known "
            "setup MRET through a verification-only compile configuration."),
        test_name="tb_ooo_priv_system",
        ivflags="-DXRET_CSR_REQUEST_ORACLE_SENSITIVITY",
        expected_marker=(
            "s-mode illegal mret CSR request count got=0x00000001 "
            "expected=0x00000000"),
    ),
    OracleProbeSpec(
        name="commit_observer_known_transaction",
        purpose=(
            "Point the illegal-xRET commit zero oracle at the known setup "
            "MRET through a verification-only compile configuration."),
        test_name="tb_ooo_priv_system",
        ivflags="-DXRET_COMMIT_ORACLE_SENSITIVITY",
        expected_marker=(
            "s-mode illegal mret commit count got=0x00000001 "
            "expected=0x00000000"),
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def normalize_transient_paths(text: str, temp: pathlib.Path) -> str:
    """Replace only the exact per-run temporary compile directory."""

    return text.replace(str(temp), TRANSIENT_DIR_TOKEN)


def repository_path(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    resolved = value.resolve()
    if not resolved.is_relative_to(root):
        raise ValueError(f"output escapes repository: {resolved}")
    return resolved


def normalize_log_directory(
    root: pathlib.Path,
    log_dir: pathlib.Path,
    transient_dir: pathlib.Path,
) -> tuple[int, int]:
    resolved_log_dir = repository_path(root, log_dir)
    if not resolved_log_dir.is_dir():
        raise ValueError(f"module log directory is missing: {resolved_log_dir}")
    transient = transient_dir.resolve(strict=True)
    if transient.is_relative_to(root):
        raise ValueError("transient compile directory must be outside repository")
    if transient.parent != pathlib.Path("/tmp") or not transient.name.startswith(
        "rv64-xret-v9e."
    ):
        raise ValueError(f"unexpected transient compile directory: {transient}")
    logs = sorted(resolved_log_dir.glob("*.log"))
    if not logs:
        raise ValueError("module log inventory is empty")
    replacements = 0
    for log_path in logs:
        resolved_log = log_path.resolve(strict=True)
        if log_path.is_symlink() or resolved_log.parent != resolved_log_dir:
            raise ValueError(f"module log is not an exact regular file: {log_path}")
        text = resolved_log.read_text(encoding="utf-8")
        occurrences = text.count(str(transient))
        if occurrences < 1:
            raise ValueError(
                f"module log does not bind current transient directory: {log_path}")
        resolved_log.write_text(
            normalize_transient_paths(text, transient), encoding="utf-8")
        replacements += occurrences
    return len(logs), replacements


def reconstruct_mutant(root: pathlib.Path, spec: MutationSpec) -> tuple[str, str]:
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
    spec: MutationSpec,
) -> dict[str, object]:
    original_text, mutant_text = reconstruct_mutant(root, spec)
    original_path = root / spec.source_rel
    original_sha = sha256_bytes(original_text.encode("utf-8"))
    mutant_sha = sha256_bytes(mutant_text.encode("utf-8"))
    log_path = output_dir / f"{spec.name}.log"
    with tempfile.TemporaryDirectory(prefix=f"xret-{spec.name}-") as temp_name:
        temp = pathlib.Path(temp_name)
        mutant_path = temp / original_path.name
        mutant_path.write_text(mutant_text, encoding="utf-8")
        result_dir = temp / "result"
        build_dir = temp / "build"
        target = result_dir / "logs" / f"{spec.test_name}.log"
        command = [
            "make", "-B", "-C", str(root / "npc/rv64/testbench"),
            f"RESULT_DIR={result_dir}", f"BUILD_DIR={build_dir}",
            f"{spec.make_variable}={mutant_path}", str(target),
        ]
        completed = subprocess.run(
            command, cwd=root, check=False, capture_output=True, text=True,
            timeout=180)
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver = completed.stdout + completed.stderr
        combined = test_log + (
            "\n[RTL-VARIANT-DRIVER]\n" + driver if driver else "")
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
        "purpose": spec.purpose,
        "source": spec.source_rel,
        "make_variable": spec.make_variable,
        "test_name": spec.test_name,
        "original_sha256": original_sha,
        "mutant_sha256": mutant_sha,
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


def run_oracle_probe(
    root: pathlib.Path,
    output_dir: pathlib.Path,
    spec: OracleProbeSpec,
) -> dict[str, object]:
    log_path = output_dir / f"{spec.name}.log"
    with tempfile.TemporaryDirectory(prefix=f"xret-{spec.name}-") as temp_name:
        temp = pathlib.Path(temp_name)
        result_dir = temp / "result"
        build_dir = temp / "build"
        target = result_dir / "logs" / f"{spec.test_name}.log"
        command = [
            "make", "-B", "-C", str(root / "npc/rv64/testbench"),
            f"RESULT_DIR={result_dir}", f"BUILD_DIR={build_dir}",
            f"TB_IVFLAGS_{spec.test_name}={spec.ivflags}", str(target),
        ]
        completed = subprocess.run(
            command, cwd=root, check=False, capture_output=True, text=True,
            timeout=180)
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver = completed.stdout + completed.stderr
        combined = test_log + (
            "\n[ORACLE-PROBE-DRIVER]\n" + driver if driver else "")
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
        "purpose": spec.purpose,
        "test_name": spec.test_name,
        "ivflags": spec.ivflags,
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
            f"[XRET-G1-LOG-NORMALIZATION] logs={count} "
            f"replacements={replacements} token={TRANSIENT_DIR_TOKEN}")
        return 0

    if args.output is None:
        parser.error("RTL variant mode requires --output")
    output = repository_path(root, args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    log_dir = output.parent / "logs"
    oracle_log_dir = output.parent / "oracle-logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    oracle_log_dir.mkdir(parents=True, exist_ok=True)

    source_paths = sorted({spec.source_rel for spec in MUTATIONS})
    before = {name: sha256_file(root / name) for name in source_paths}
    results = [run_one(root, log_dir, spec) for spec in MUTATIONS]
    oracle_results = [
        run_oracle_probe(root, oracle_log_dir, spec) for spec in ORACLE_PROBES]
    after = {name: sha256_file(root / name) for name in source_paths}
    compile_success = sum(bool(row["compile_success"]) for row in results)
    dynamic_rejected = sum(bool(row["dynamic_rejected"]) for row in results)
    oracle_compile_success = sum(
        bool(row["compile_success"]) for row in oracle_results)
    oracle_dynamic_rejected = sum(
        bool(row["dynamic_rejected"]) for row in oracle_results)
    payload = {
        "schema": SCHEMA,
        "suite_run_id": SUITE_RUN_ID,
        "required": len(MUTATIONS),
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "source_unchanged": before == after,
        "source_sha256_before": before,
        "source_sha256_after": after,
        "results": results,
        "oracle_probes_required": len(ORACLE_PROBES),
        "oracle_probes_compile_success": oracle_compile_success,
        "oracle_probes_dynamic_rejected": oracle_dynamic_rejected,
        "oracle_probes": oracle_results,
    }
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    print(
        f"[XRET-G1-RTL-VARIANTS] required={len(MUTATIONS)} "
        f"compile_success={compile_success} dynamic_rejected={dynamic_rejected} "
        f"oracle_probes={oracle_dynamic_rejected}/{len(ORACLE_PROBES)} "
        f"source_unchanged={str(before == after).lower()}")
    return 0 if (
        compile_success == len(MUTATIONS)
        and dynamic_rejected == len(MUTATIONS)
        and oracle_compile_success == len(ORACLE_PROBES)
        and oracle_dynamic_rejected == len(ORACLE_PROBES)
        and before == after
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
