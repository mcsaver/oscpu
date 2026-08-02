#!/usr/bin/env python3
"""生成当前设计 pending-SYSTEM C0/C1/C2 与消费者绑定证据。"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

import run_v12c_serialize_qh_current as common


SCHEMA = "npc-rv64-v12c-serialize-system-current-evidence-v1"
TESTBENCH_DIR_REL = "npc/rv64/testbench"
VSRCDIR_REL = "npc/rv64/vsrc"

TESTBENCH_PATHS = {
    "tb_ooo_priv_system":
        "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
    "tb_ooo_csr_access_request_mux":
        "npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv",
    "tb_ooo_pending_drain_resolve_gate":
        "npc/rv64/testbench/tests/tb_ooo_pending_drain_resolve_gate.sv",
    "tb_ooo_fetch_axi_bridge":
        "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
}


@dataclass(frozen=True)
class Mutation:
    name: str
    module: str
    make_var: str
    old: str
    new: str
    rejection_marker: str
    test: str = "tb_ooo_priv_system"


MUTATIONS = (
    Mutation(
        "disconnect-satp-mmu",
        "memory/OooMemoryAccess.v",
        "RTL_OOO_MEMORY_ACCESS",
        ".pending_system_satp_write_commit_i("
        "pending_system_satp_write_commit_w),",
        ".pending_system_satp_write_commit_i(1'b0),",
        "V10B MMU registered action got=0 expected_prior_source=1",
    ),
    Mutation(
        "disconnect-sfence-mmu",
        "memory/OooMemoryAccess.v",
        "RTL_OOO_MEMORY_ACCESS",
        ".pending_system_sfence_commit_i("
        "pending_system_sfence_commit_w),",
        ".pending_system_sfence_commit_i(1'b0),",
        "V10B MMU registered action got=0 expected_prior_source=1",
    ),
    Mutation(
        "disconnect-fencei-mmu",
        "memory/OooMemoryAccess.v",
        "RTL_OOO_MEMORY_ACCESS",
        ".pending_system_fencei_commit_i("
        "pending_system_fencei_commit_w),",
        ".pending_system_fencei_commit_i(1'b0),",
        "V10B MMU registered action got=0 expected_prior_source=1",
    ),
    Mutation(
        "sfence-reason-to-serial",
        "frontend/OooFrontend.v",
        "RTL_OOO_FRONTEND",
        "commit_e6_system_sfence_w ? `REDIR_REASON_SFENCE :",
        "commit_e6_system_sfence_w ? `REDIR_REASON_SERIAL :",
        "expected_reason=5",
    ),
    Mutation(
        "fencei-reason-to-serial",
        "frontend/OooFrontend.v",
        "RTL_OOO_FRONTEND",
        "commit_e6_system_fencei_w ? `REDIR_REASON_FENCEI :",
        "commit_e6_system_fencei_w ? `REDIR_REASON_SERIAL :",
        "expected_reason=6",
    ),
    Mutation(
        "remove-fence-mem-idle",
        "control/OooPendingDrainResolveGate.v",
        "RTL_OOO_PENDING_DRAIN_RESOLVE_GATE",
        "wire pending_fence_mem_quiet_w =\n"
        "      !pending_system_fence_i || mem_idle_i;",
        "wire pending_fence_mem_quiet_w =\n"
        "      1'b1;",
        "fence waits for MIQ bridge reservation idle got=1 expected=0",
        "tb_ooo_pending_drain_resolve_gate",
    ),
    Mutation(
        "retain-noncsr-holder-after-terminal",
        "control/OooPendingSystemSequencer.v",
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        "end else if (clear_i) begin",
        "end else if (clear_i && (kind_q == SERIAL_KIND_CSR)) begin",
        "V10B C1 owner/stop not clear kind=2",
    ),
    Mutation(
        "retain-stop-after-drain-terminal",
        "control/OooStopPendingSequencer.v",
        "RTL_OOO_STOP_PENDING_SEQUENCER",
        "stop_pending_o && drain_complete_i) begin",
        "stop_pending_o && drain_complete_i && 1'b0) begin",
        "V10B C1 owner/stop not clear kind=2",
    ),
    Mutation(
        "drop-pending-csr-owner-exclusion",
        "writeback/OooRob.v",
        "RTL_OOO_ROB",
        "wire head0_queue_csr_w =\n"
        "      head0_is_csr_w && !head0_pending_csr_owner_match_w;",
        "wire head0_queue_csr_w =\n"
        "      head0_is_csr_w;",
        "[V9O-CONTROL-EVENT-FULL-PROJECTION] C0 barrier was not the final frontend FULL_NEXT winner",
    ),
    Mutation(
        "remove-csr-producerid-match",
        "control/OooCsrAccessRequestMux.v",
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        "pending_system_csr_pid_match_w && "
        "pending_system_csr_pc_match_w;",
        "pending_system_csr_pc_match_w;",
        "FAIL core=1 pend=1",
        "tb_ooo_csr_access_request_mux",
    ),
    Mutation(
        "remove-csr-pc-match",
        "control/OooCsrAccessRequestMux.v",
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        "pending_system_csr_pid_match_w && "
        "pending_system_csr_pc_match_w;",
        "pending_system_csr_pid_match_w;",
        "FAIL core=1 pend=1",
        "tb_ooo_csr_access_request_mux",
    ),
    Mutation(
        "remove-wfi-control-commit",
        "writeback/OooWriteback.v",
        "RTL_OOO_WRITEBACK",
        ".drain_pending_system_i(pending_system_q),",
        ".drain_pending_system_i(\n"
        "        pending_system_q &&\n"
        "        (pending_system_inst_q != 32'h1050_0073)),",
        "wfi synthetic commit observed got=0 expected=1",
    ),
    Mutation(
        "add-mmu-action-to-every-drain",
        "memory/OooMemoryRequestGate.v",
        "RTL_OOO_MEMORY_REQUEST_GATE",
        "(pending_system_satp_write_commit_i || "
        "pending_system_sfence_commit_i ||\n"
        "         pending_system_fencei_commit_i);",
        "(pending_system_satp_write_commit_i || "
        "pending_system_sfence_commit_i ||\n"
        "         pending_system_fencei_commit_i ||\n"
        "         (stop_pending_i && backend_drained_i));",
        "V10B MMU registered action got=1 expected_prior_source=0",
    ),
    Mutation(
        "drop-sfence-inval-ir-classification",
        "decode/DecodeUnit.v",
        "RTL_DECODE_UNIT",
        "(rs2_idx_o == `SYSTEM_RS2_SFENCE_INVAL_IR))) begin",
        "(rs2_idx_o == 5'b11111))) begin",
        "V10B SFENCE-family terminal count",
    ),
    Mutation(
        "disconnect-fencei-fetch-cache-clear",
        "frontend/OooFetchAxiBridge.v",
        "RTL_OOO_FETCH_AXI_BRIDGE",
        "OooFetchPacketCache u_fetch_packet_cache (\n"
        "    .clk(clk),\n"
        "    .rst(rst),\n"
        "    .clear_i(mmu_flush_i),",
        "OooFetchPacketCache u_fetch_packet_cache (\n"
        "    .clk(clk),\n"
        "    .rst(rst),\n"
        "    .clear_i(1'b0),",
        "V10B FENCE.I rejects stale cache hit got=1 expected=0",
        "tb_ooo_fetch_axi_bridge",
    ),
)


def validate_positive_markers(text: str, test: str) -> dict[str, int]:
    if (
        text.count("[RESULT] PASS") != 1
        or "[RESULT] FAIL" in text
        or "[CHECK-FAIL]" in text
    ):
        raise common.EvidenceError(f"{test}: positive terminal marker drifted")
    required = {
        "tb_ooo_priv_system": (
            "[V10B-SYSTEM-MIXED]",
            "[V10B-SATP-MMU]",
            "[V10B-FENCE-POST-FIRE]",
            "[V10G-PRODUCT-QH-SATP]",
            "[PASS] tb_ooo_priv_system",
        ),
        "tb_ooo_csr_access_request_mux": (
            "PASS tb_ooo_csr_access_request_mux",
        ),
    }[test]
    counts: dict[str, int] = {}
    for marker in required:
        matching = [line for line in text.splitlines() if marker in line]
        if len(matching) != 1:
            raise common.EvidenceError(
                f"{test}: expected one positive marker {marker}, found {len(matching)}"
            )
        if marker.startswith("[V10") and not matching[0].rstrip().endswith("PASS"):
            raise common.EvidenceError(f"{test}: positive marker is not PASS: {marker}")
        counts[marker] = 1
    return counts


def validate_negative_markers(text: str, mutation: Mutation) -> dict[str, int]:
    if text.count("[RESULT] FAIL") != 1 or "[RESULT] PASS" in text:
        raise common.EvidenceError(
            f"{mutation.name}: negative terminal marker drifted"
        )
    count = text.count(mutation.rejection_marker)
    if count < 1:
        raise common.EvidenceError(
            f"{mutation.name}: expected rejection marker is absent"
        )
    return {mutation.rejection_marker: count}


def materialize_mutation(
    root: Path, output: Path, mutation: Mutation
) -> tuple[Path, dict[str, object]]:
    source = root / VSRCDIR_REL / mutation.module
    original = source.read_text(encoding="utf-8")
    mutated = common.replace_once(
        original,
        mutation.old,
        mutation.new,
        mutation.name,
    )
    target = output / "generated/mutations" / mutation.name / source.name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(mutated, encoding="utf-8")
    return target, {
        "name": mutation.name,
        "module": common.artifact_record(source, root),
        "make_var": mutation.make_var,
        "test": mutation.test,
        "from": mutation.old,
        "to": mutation.new,
        "rejection_marker": mutation.rejection_marker,
        "mutated": common.artifact_record(target, root),
        "compile_success_required": True,
    }


def write_status(
    output: Path,
    *,
    state: str,
    completed: int,
    total: int,
    current: str,
    result: str | None = None,
) -> None:
    value: dict[str, object] = {
        "state": state,
        "completed": completed,
        "total": total,
        "current": current,
    }
    if result is not None:
        value["result"] = result
    common.atomic_write_json(output / "status.json", value)


def run_case(
    *,
    name: str,
    test: str,
    root: Path,
    output: Path,
    wrapper: Path,
    real_iverilog: Path,
    real_vvp: Path,
    assertions: bool,
    expect_pass: bool,
    mutation: Mutation | None = None,
    mutated_path: Path | None = None,
) -> tuple[dict[str, object], list[common.TemporaryArtifact]]:
    testbench_dir = root / TESTBENCH_DIR_REL
    profile_dir = output / "profiles" / name
    build_dir = profile_dir / "build"
    log = profile_dir / "logs" / f"{test}.log"
    command = [
        "make",
        "-C",
        str(testbench_dir),
        f"RESULT_DIR={profile_dir}",
        f"BUILD_DIR={build_dir}",
        f"IVERILOG={wrapper}",
        f"VVP={real_vvp}",
        f"IVFLAGS={common.base_ivflags(root, assertions, None)}",
    ]
    if mutation is not None and mutated_path is not None:
        command.append(f"{mutation.make_var}={mutated_path}")
    command.append(str(log))
    completed = subprocess.run(
        command,
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=180,
    )
    profile_dir.mkdir(parents=True, exist_ok=True)
    make_log = profile_dir / "make.log"
    make_log.write_text(completed.stdout, encoding="utf-8")
    log_text = log.read_text(encoding="utf-8") if log.is_file() else ""
    markers = (
        validate_positive_markers(log_text, test)
        if expect_pass
        else validate_negative_markers(log_text, mutation)
    )
    if expect_pass != (completed.returncode == 0):
        raise common.EvidenceError(
            f"{name}: Makefile return code did not match expectation"
        )
    compile_record, temporary = common.compile_input_record(
        test=test,
        log_text=log_text,
        profile_dir=profile_dir,
        wrapper=wrapper,
        real_iverilog=real_iverilog,
        compile_cwd=testbench_dir,
        root=root,
    )
    if any(
        str(token).startswith("-DOOO_CSR_QUEUE_HEAD")
        for token in compile_record["compiler_argv"]
    ):
        raise common.EvidenceError(
            f"{name}: queue-head product default was overridden on command line"
        )
    if mutated_path is not None:
        mutated_rel = common.repo_path(mutated_path, root)
        bound = [
            item for item in compile_record["dependencies"]
            if item["path"] == mutated_rel
            and item["role"] == "module"
            and item["sha256"] == common.sha256_file(mutated_path)
        ]
        if len(bound) != 1:
            raise common.EvidenceError(
                f"{name}: mutated RTL is not uniquely bound in compiler dependencies"
            )
    vvp = build_dir / f"{test}.vvp"
    if not vvp.is_file():
        raise common.EvidenceError(f"{name}: compiled image is missing before cleanup")
    temporary.append(common.TemporaryArtifact(vvp, "compiled-vvp"))
    return (
        {
            "name": name,
            "test": test,
            "assertions": assertions,
            "expect_pass": expect_pass,
            "mutation": mutation.name if mutation is not None else None,
            "make_returncode": completed.returncode,
            "result_log": common.artifact_record(log, root),
            "make_log": common.artifact_record(make_log, root),
            "markers": markers,
            "compile_input": compile_record,
            "passed": True,
        },
        temporary,
    )


def cleanup_failed_run(output: Path) -> dict[str, object]:
    patterns = (
        "generated/iverilog-dependency-wrapper.sh",
        "generated/mutations/*/*",
        "profiles/*/build/*.vvp",
        "profiles/*/dependencies/*.deps",
        "profiles/*/dependencies/*.argv",
        "profiles/*/dependencies/*.compile.rc",
    )
    removed: list[str] = []
    for pattern in patterns:
        for path in output.glob(pattern):
            resolved = path.resolve()
            resolved.relative_to(output.resolve())
            if resolved.is_file():
                removed.append(resolved.relative_to(output.resolve()).as_posix())
                resolved.unlink()
    for directory in sorted(
        (path for path in output.rglob("*") if path.is_dir()),
        key=lambda value: len(value.parts),
        reverse=True,
    ):
        try:
            directory.rmdir()
        except OSError:
            pass
    return {"status": "PASS", "removed": len(removed), "paths": sorted(removed)}


def execute(root: Path, output: Path) -> dict[str, object]:
    if (output / "summary.json").exists():
        raise common.EvidenceError(f"refusing to overwrite completed evidence: {output}")
    real_iverilog_text = shutil.which("iverilog")
    if real_iverilog_text is None:
        raise common.EvidenceError("iverilog is unavailable")
    real_iverilog = Path(real_iverilog_text).resolve()
    sibling_vvp = real_iverilog.parent / "vvp"
    real_vvp_text = str(sibling_vvp) if sibling_vvp.is_file() else shutil.which("vvp")
    if real_vvp_text is None:
        raise common.EvidenceError("matching vvp is unavailable")
    real_vvp = Path(real_vvp_text).resolve()

    output.mkdir(parents=True, exist_ok=True)
    product = common.validate_product_configuration(root)
    design_id = common.current_design_id(root)
    wrapper = common.build_compiler_wrapper(output, real_iverilog)
    temporary: list[common.TemporaryArtifact] = [
        common.TemporaryArtifact(wrapper, "compiler-wrapper")
    ]
    mutation_paths: dict[str, Path] = {}
    mutation_records: list[dict[str, object]] = []
    for mutation in MUTATIONS:
        path, record = materialize_mutation(root, output, mutation)
        mutation_paths[mutation.name] = path
        mutation_records.append(record)
        temporary.append(common.TemporaryArtifact(path, "rtl-mutation"))

    baselines = (
        ("priv-system-assert", "tb_ooo_priv_system", True),
        ("priv-system-release", "tb_ooo_priv_system", False),
        ("csr-access-assert", "tb_ooo_csr_access_request_mux", True),
    )
    total = len(baselines) + len(MUTATIONS)
    profiles: list[dict[str, object]] = []
    for name, test, assertions in baselines:
        write_status(
            output,
            state="RUNNING",
            completed=len(profiles),
            total=total,
            current=name,
        )
        record, case_temporary = run_case(
            name=name,
            test=test,
            root=root,
            output=output,
            wrapper=wrapper,
            real_iverilog=real_iverilog,
            real_vvp=real_vvp,
            assertions=assertions,
            expect_pass=True,
        )
        profiles.append(record)
        temporary.extend(case_temporary)

    for mutation in MUTATIONS:
        write_status(
            output,
            state="RUNNING",
            completed=len(profiles),
            total=total,
            current=mutation.name,
        )
        record, case_temporary = run_case(
            name=mutation.name,
            test=mutation.test,
            root=root,
            output=output,
            wrapper=wrapper,
            real_iverilog=real_iverilog,
            real_vvp=real_vvp,
            assertions=True,
            expect_pass=False,
            mutation=mutation,
            mutated_path=mutation_paths[mutation.name],
        )
        profiles.append(record)
        temporary.extend(case_temporary)

    cleanup = common.cleanup_artifacts(temporary, root, output)
    build_controls = {
        path: common.artifact_record(root / path, root)
        for path in (
            common.MAKEFILE_REL,
            common.FILELIST_REL,
            common.DEFINE_REL,
            common.PRODUCT_MANIFEST_REL,
            *TESTBENCH_PATHS.values(),
            "npc/rv64/testbench/scripts/check_tb_result.py",
            "npc/rv64/testbench/common/tb_common.svh",
        )
    }
    result = {
        "schema": SCHEMA,
        "status": "PASS",
        "design_id": design_id,
        "scope": "SERIALIZE-G1 pending-SYSTEM C0/C1/C2 and consumer binding",
        "product_configuration": product,
        "build_controls": build_controls,
        "profiles": profiles,
        "mutations": mutation_records,
        "counts": {
            "baseline_profiles": len(baselines),
            "compile_success_mutations": len(MUTATIONS),
            "dynamically_rejected_mutations": len(MUTATIONS),
            "compilations": total,
        },
        "compile_input_closure": {
            "status": "PASS",
            "actual_compiler_argv_bound": True,
            "icarus_dependency_bound": True,
            "mutation_source_selection_bound": True,
            "product_queue_head_command_override": False,
        },
        "cleanup": cleanup,
        "non_claims": [
            "whole architecture freeze",
            "full-system current-design recertification",
            "PPA promotion",
        ],
    }
    common.atomic_write_json(output / "artifact-cleanup.json", cleanup)
    common.atomic_write_json(output / "summary.json", result)
    (output / "result.txt").write_text(
        "[V12C-SERIALIZE-SYSTEM-CURRENT] "
        f"design_id={design_id} baselines={len(baselines)}/{len(baselines)} "
        f"compile-success={len(MUTATIONS)}/{len(MUTATIONS)} "
        f"rejected={len(MUTATIONS)}/{len(MUTATIONS)} "
        f"cleanup={cleanup['removed']} PASS\n",
        encoding="utf-8",
    )
    write_status(
        output,
        state="DONE",
        completed=total,
        total=total,
        current="complete",
        result="PASS",
    )
    return result


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--output-dir", type=Path, required=True)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    root = args.repo_root.resolve()
    output = (
        args.output_dir.resolve()
        if args.output_dir.is_absolute()
        else (root / args.output_dir).resolve()
    )
    output.relative_to(root)
    try:
        result = execute(root, output)
    except Exception as exc:
        output.mkdir(parents=True, exist_ok=True)
        failure_cleanup = cleanup_failed_run(output)
        common.atomic_write_json(
            output / "failure.json",
            {
                "schema": SCHEMA,
                "status": "FAIL",
                "error": str(exc),
                "cleanup": failure_cleanup,
            },
        )
        write_status(
            output,
            state="DONE",
            completed=0,
            total=3 + len(MUTATIONS),
            current="failed",
            result="FAIL",
        )
        print(f"[V12C-SERIALIZE-SYSTEM-CURRENT] FAIL {exc}", file=sys.stderr)
        return 1
    print(
        "[V12C-SERIALIZE-SYSTEM-CURRENT] "
        f"design_id={result['design_id']} baselines=3/3 "
        f"compile-success={len(MUTATIONS)}/{len(MUTATIONS)} "
        f"rejected={len(MUTATIONS)}/{len(MUTATIONS)} "
        f"cleanup={result['cleanup']['removed']} PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
