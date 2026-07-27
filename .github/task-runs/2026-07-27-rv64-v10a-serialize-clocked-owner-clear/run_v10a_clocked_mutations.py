#!/usr/bin/env python3
"""Compile-success negative RTL variants for V10A serialized owner lifetime."""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
RUN_DIR = Path(__file__).resolve().parent
RESULT_ROOT = RUN_DIR / "mutations"
VSRCDIR = REPO / "npc/rv64/vsrc"
COMMON = REPO / "npc/rv64/testbench/common"
TB = (
    REPO
    / "npc/rv64/testbench/tests/tb_ooo_serialized_owner_exactly_once.sv"
)

MUX = VSRCDIR / "control/OooCsrTrapRequestMux.v"
ARBITER = VSRCDIR / "control/OooPendingDispatchArbiter.v"
LANE1 = VSRCDIR / "control/OooPendingLane1CaptureGate.v"
TRAP_SEQ = VSRCDIR / "control/OooPendingTrapExitSequencer.v"
SYSTEM_SEQ = VSRCDIR / "control/OooPendingSystemSequencer.v"
STOP_SEQ = VSRCDIR / "control/OooStopPendingSequencer.v"
DRAIN = VSRCDIR / "control/OooPendingDrainResolveGate.v"
RUN_GATE = VSRCDIR / "frontend/OooFrontendRunGate.v"
CSR_FILE = VSRCDIR / "core/CsrFile.v"

RTL_SOURCES = (
    MUX,
    ARBITER,
    DRAIN,
    LANE1,
    SYSTEM_SEQ,
    TRAP_SEQ,
    STOP_SEQ,
    CSR_FILE,
    RUN_GATE,
)

MUTATIONS = (
    {
        "name": "drop-commit-trap-request-mask",
        "target": MUX,
        "old": """  wire drained_pending_control_w =
      !core_commit_exception_trap_o &&
      stop_pending_i && drain_complete_i;""",
        "new": """  wire drained_pending_control_w =
      stop_pending_i && drain_complete_i;""",
        "marker": (
            "[CHECK-FAIL] V10A commit trap masks pending arch request"
        ),
    },
    {
        "name": "drop-head0-arch-system-exclusion",
        "target": ARBITER,
        "old": """  assign pending_system_capture_head0_o =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_arch_trap_w &&
      !dispatch0_exit_w &&
      dispatch0_system_w && !dispatch0_csr_w && !head0_csr_illegal_i;""",
        "new": """  assign pending_system_capture_head0_o =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      !dispatch0_exit_w &&
      dispatch0_system_w && !dispatch0_csr_w && !head0_csr_illegal_i;""",
        "marker": "[CHECK-FAIL] V10A head0 system birth suppressed",
    },
    {
        "name": "drop-lane1-arch-system-exclusion",
        "target": LANE1,
        "old": """  assign system_capture_o =
      barrier_base_i && system_raw_w && !csr_illegal_i &&
      !arch_trap_raw_w;""",
        "new": """  assign system_capture_o =
      barrier_base_i && system_raw_w && !csr_illegal_i;""",
        "marker": "[CHECK-FAIL] V10A lane1 system birth suppressed",
    },
    {
        "name": "drop-irq-over-arch-birth-priority",
        "target": ARBITER,
        "old": """  wire trap_exit_capture_arch0_w =
      capture_base_w &&
      !csr_irq_pending_i &&
      !head_fetch_fault0_i &&
      dispatch0_arch_trap_w;""",
        "new": """  wire trap_exit_capture_arch0_w =
      capture_base_w &&
      !head_fetch_fault0_i &&
      dispatch0_arch_trap_w;""",
        "marker": "[CHECK-FAIL] V10A IRQ suppresses arch birth",
    },
    {
        "name": "drop-drain-to-arch-owner-clear",
        "target": ARBITER,
        "old": """  wire trap_exit_clear_resolve_w =
      (!direct_frontend_flush_i && branch_spec_resolve_valid_i) ||
      pending_branch_commit_resolve_i ||
      pending_branch_match_clear_i ||
      (!direct_frontend_flush_i && branch_resolve_untracked_i) ||
      (!direct_frontend_flush_i && pending_system_csr_commit_i) ||
      drain_clear_w;""",
        "new": """  wire trap_exit_clear_resolve_w =
      (!direct_frontend_flush_i && branch_spec_resolve_valid_i) ||
      pending_branch_commit_resolve_i ||
      pending_branch_match_clear_i ||
      (!direct_frontend_flush_i && branch_resolve_untracked_i) ||
      (!direct_frontend_flush_i && pending_system_csr_commit_i);""",
        "marker": "[CHECK-FAIL] V10A C1 clears arch owner",
    },
    {
        "name": "drop-drain-to-stop-clear",
        "target": STOP_SEQ,
        "old": """    end else if (!csr_trap_mem_valid_i &&
                 !direct_frontend_flush_i &&
                 stop_pending_o && drain_complete_i) begin
      stop_pending_o <= 1'b0;
    end""",
        "new": """    end else if (!csr_trap_mem_valid_i &&
                 !direct_frontend_flush_i &&
                 stop_pending_o && drain_complete_i && 1'b0) begin
      stop_pending_o <= 1'b0;
    end""",
        "marker": "[CHECK-FAIL] V10A C1 clears stop",
    },
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(
    command: list[str], cwd: Path
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def main() -> int:
    iverilog = shutil.which("iverilog")
    if not iverilog:
        raise SystemExit("iverilog not found")
    paired_vvp = str(Path(iverilog).resolve().parent / "vvp")
    vvp = paired_vvp if Path(paired_vvp).is_file() else shutil.which("vvp")
    if not vvp:
        raise SystemExit("vvp not found")

    production_text = {
        source: source.read_text(encoding="utf-8")
        for source in RTL_SOURCES
    }
    RESULT_ROOT.mkdir(parents=True, exist_ok=True)
    results = []

    for mutation in MUTATIONS:
        target = mutation["target"]
        source = production_text[target]
        if source.count(mutation["old"]) != 1:
            raise SystemExit(
                f"{mutation['name']}: expected exactly one mutation anchor"
            )

        mutation_dir = RESULT_ROOT / mutation["name"]
        mutation_dir.mkdir(parents=True, exist_ok=True)
        mutated_rtl = mutation_dir / target.name
        mutated_rtl.write_text(
            source.replace(mutation["old"], mutation["new"]),
            encoding="utf-8",
        )
        compile_sources = [
            mutated_rtl if rtl == target else rtl
            for rtl in RTL_SOURCES
        ]
        image = mutation_dir / "tb.vvp"
        compile_command = [
            iverilog,
            "-g2012",
            "-Wall",
            f"-I{VSRCDIR}",
            f"-I{VSRCDIR / 'include'}",
            f"-I{COMMON}",
            "-DOOO_ASSERT",
            "-s",
            "tb_ooo_serialized_owner_exactly_once",
            "-o",
            str(image),
            *[str(path) for path in compile_sources],
            str(TB),
        ]
        compile_result = run(compile_command, REPO)
        (mutation_dir / "compile.log").write_text(
            "$ " + " ".join(compile_command) + "\n" +
            compile_result.stdout,
            encoding="utf-8",
        )

        simulation_result = None
        simulation_output = ""
        if compile_result.returncode == 0:
            simulation_result = run([vvp, str(image)], REPO)
            simulation_output = simulation_result.stdout
        (mutation_dir / "simulation.log").write_text(
            simulation_output, encoding="utf-8"
        )

        compile_success = compile_result.returncode == 0
        simulation_rc = (
            simulation_result.returncode
            if simulation_result is not None
            else None
        )
        marker_observed = mutation["marker"] in simulation_output
        rejected = (
            compile_success
            and simulation_rc is not None
            and simulation_rc != 0
            and marker_observed
        )
        results.append(
            {
                "name": mutation["name"],
                "target": str(target.relative_to(REPO)),
                "compile_rc": compile_result.returncode,
                "compile_success": compile_success,
                "simulation_rc": simulation_rc,
                "expected_rejection_marker": mutation["marker"],
                "marker_observed": marker_observed,
                "rejected": rejected,
                "mutated_rtl_sha256": sha256(mutated_rtl),
            }
        )

    summary = {
        "schema": "rv64-v10a-clocked-owner-mutation-summary-v1",
        "production_rtl_sha256": {
            str(path.relative_to(REPO)): sha256(path)
            for path in RTL_SOURCES
        },
        "testbench": str(TB.relative_to(REPO)),
        "testbench_sha256": sha256(TB),
        "configuration": {
            "iverilog": str(Path(iverilog).resolve()),
            "vvp": str(Path(vvp).resolve()),
            "systemverilog": "2012",
            "OOO_ASSERT": True,
        },
        "passed": all(item["rejected"] for item in results),
        "rejected_count": sum(bool(item["rejected"]) for item in results),
        "total_count": len(results),
        "mutations": results,
    }
    (RESULT_ROOT / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0 if summary["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
