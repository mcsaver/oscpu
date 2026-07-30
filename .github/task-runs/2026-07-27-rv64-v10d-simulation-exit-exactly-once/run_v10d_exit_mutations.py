#!/usr/bin/env python3
"""Compile-success negative RTL variants for V10D simulation-exit timing."""

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
TB = REPO / "npc/rv64/testbench/tests/tb_ooo_serialized_owner_exactly_once.sv"

CSR_MUX = VSRCDIR / "control/OooCsrTrapRequestMux.v"
ARBITER = VSRCDIR / "control/OooPendingDispatchArbiter.v"
DRAIN = VSRCDIR / "control/OooPendingDrainResolveGate.v"
LANE1 = VSRCDIR / "control/OooPendingLane1CaptureGate.v"
SYSTEM_SEQ = VSRCDIR / "control/OooPendingSystemSequencer.v"
TRAP_SEQ = VSRCDIR / "control/OooPendingTrapExitSequencer.v"
STOP_SEQ = VSRCDIR / "control/OooStopPendingSequencer.v"
EVENT_MUX = VSRCDIR / "control/OooTrapExitEventMux.v"
OUTPUT_SEQ = VSRCDIR / "control/OooTrapExitOutputSequencer.v"
CSR_FILE = VSRCDIR / "core/CsrFile.v"
RUN_GATE = VSRCDIR / "frontend/OooFrontendRunGate.v"

RTL_SOURCES = (
    CSR_MUX,
    ARBITER,
    DRAIN,
    LANE1,
    SYSTEM_SEQ,
    TRAP_SEQ,
    STOP_SEQ,
    EVENT_MUX,
    OUTPUT_SEQ,
    CSR_FILE,
    RUN_GATE,
)

TERMINAL_BLOCK = """  wire pending_serialized_mem_terminal_w =
      !(pending_system_i || pending_arch_trap_i || pending_exit_i) ||
      mem_owner_terminalized_i;"""

CLEAR_EXIT_BLOCK = """  assign pending_trap_exit_clear_exit_o =
      trap_exit_clear_resolve_w ||
      (direct_frontend_flush_i && direct_branch_fire_w) ||
      pending_jump_clear_from_resolve_w ||
      trap_exit_capture_clear_exit_w;"""

STOP_DRAIN_CLEAR_BLOCK = """    end else if (!csr_trap_mem_valid_i &&
                 !direct_frontend_flush_i &&
                 stop_pending_o && drain_complete_i) begin
      stop_pending_o <= 1'b0;
    end"""

EXIT_KIND_BLOCK = """  assign pending_trap_exit_capture_exit_ecall_o =
      trap_exit_capture_exit0_w ? dispatch0_ecall_w :
                                  trap_exit_lane1_exit_ecall_w;
  assign pending_trap_exit_capture_exit_ebreak_o =
      trap_exit_capture_exit0_w ? dispatch0_ebreak_w :
                                  trap_exit_lane1_exit_ebreak_w;"""

TRAP_PRIORITY_TERM = """      !terminal_trap_w &&
      !pending_arch_trap_i &&"""

MUTATIONS = (
    {
        "name": "drop-exit-memory-terminal-term",
        "assertions": True,
        "edits": (
            (
                DRAIN,
                TERMINAL_BLOCK,
                """  wire pending_serialized_mem_terminal_w =
      !(pending_system_i || pending_arch_trap_i) ||
      mem_owner_terminalized_i;""",
            ),
        ),
        "marker": "[CHECK-FAIL] V10D active memory holder blocks drain",
    },
    {
        "name": "replace-exact-terminal-with-full-mem-idle",
        "assertions": True,
        "edits": (
            (
                DRAIN,
                TERMINAL_BLOCK,
                """  wire pending_serialized_mem_terminal_w =
      !(pending_system_i || pending_arch_trap_i || pending_exit_i) ||
      mem_idle_i;""",
            ),
        ),
        "marker": "[CHECK-FAIL] V10D active memory holder blocks drain",
    },
    {
        "name": "drop-exit-holder-drain-clear",
        "assertions": True,
        "edits": (
            (
                ARBITER,
                CLEAR_EXIT_BLOCK,
                """  assign pending_trap_exit_clear_exit_o =
      (direct_frontend_flush_i && direct_branch_fire_w) ||
      pending_jump_clear_from_resolve_w ||
      trap_exit_capture_clear_exit_w;""",
            ),
        ),
        "marker": "[CHECK-FAIL] V10D C1 clears exit owner",
    },
    {
        "name": "drop-stop-drain-clear",
        "assertions": True,
        "edits": (
            (
                STOP_SEQ,
                STOP_DRAIN_CLEAR_BLOCK,
                """    end else if (!csr_trap_mem_valid_i &&
                 !direct_frontend_flush_i &&
                 stop_pending_o && drain_complete_i && 1'b0) begin
      stop_pending_o <= 1'b0;
    end""",
            ),
        ),
        "marker": "[CHECK-FAIL] V10D C1 clears stop",
    },
    {
        "name": "swap-exit-kind-selection",
        "assertions": True,
        "edits": (
            (
                ARBITER,
                EXIT_KIND_BLOCK,
                """  assign pending_trap_exit_capture_exit_ecall_o =
      trap_exit_capture_exit0_w ? dispatch0_ebreak_w :
                                  trap_exit_lane1_exit_ebreak_w;
  assign pending_trap_exit_capture_exit_ebreak_o =
      trap_exit_capture_exit0_w ? dispatch0_ecall_w :
                                  trap_exit_lane1_exit_ecall_w;""",
            ),
        ),
        "marker": "[CHECK-FAIL] V10D exit capture ecall kind",
    },
    {
        "name": "drop-trap-over-exit-priority",
        "assertions": True,
        "edits": (
            (
                EVENT_MUX,
                TRAP_PRIORITY_TERM,
                """      !pending_arch_trap_i &&""",
            ),
        ),
        "marker": (
            "[CHECK-FAIL] V10D older branch recovery excludes raw exit"
        ),
    },
    {
        "name": "extend-raw-exit-beyond-terminal-cycle",
        "assertions": False,
        "edits": (
            (
                ARBITER,
                CLEAR_EXIT_BLOCK,
                """  assign pending_trap_exit_clear_exit_o =
      (direct_frontend_flush_i && direct_branch_fire_w) ||
      pending_jump_clear_from_resolve_w ||
      trap_exit_capture_clear_exit_w;""",
            ),
            (
                STOP_SEQ,
                STOP_DRAIN_CLEAR_BLOCK,
                """    end else if (!csr_trap_mem_valid_i &&
                 !direct_frontend_flush_i &&
                 stop_pending_o && drain_complete_i && 1'b0) begin
      stop_pending_o <= 1'b0;
    end""",
            ),
        ),
        "marker": "[CHECK-FAIL] V10D C2 raw exit no-repeat",
    },
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=REPO,
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
        source: source.read_text(encoding="utf-8") for source in RTL_SOURCES
    }
    RESULT_ROOT.mkdir(parents=True, exist_ok=True)
    results = []

    for mutation in MUTATIONS:
        mutation_dir = RESULT_ROOT / mutation["name"]
        rtl_dir = mutation_dir / "rtl"
        rtl_dir.mkdir(parents=True, exist_ok=True)
        mutated_text: dict[Path, str] = {}

        for target, old, new in mutation["edits"]:
            source = mutated_text.get(target, production_text[target])
            if source.count(old) != 1:
                raise SystemExit(
                    f"{mutation['name']}: expected exactly one anchor in "
                    f"{target.relative_to(REPO)}"
                )
            mutated_text[target] = source.replace(old, new)

        mutated_paths: dict[Path, Path] = {}
        for target, source in mutated_text.items():
            mutated_path = rtl_dir / target.name
            mutated_path.write_text(source, encoding="utf-8")
            mutated_paths[target] = mutated_path

        compile_sources = [
            mutated_paths.get(source, source) for source in RTL_SOURCES
        ]
        image = mutation_dir / "tb.vvp"
        compile_command = [
            iverilog,
            "-g2012",
            "-Wall",
            f"-I{VSRCDIR}",
            f"-I{VSRCDIR / 'include'}",
            f"-I{COMMON}",
        ]
        if mutation["assertions"]:
            compile_command.append("-DOOO_ASSERT")
        compile_command.extend(
            [
                "-s",
                "tb_ooo_serialized_owner_exactly_once",
                "-o",
                str(image),
                *[str(path) for path in compile_sources],
                str(TB),
            ]
        )
        compile_result = run(compile_command)
        (mutation_dir / "compile.log").write_text(
            "$ " + " ".join(compile_command) + "\n" + compile_result.stdout,
            encoding="utf-8",
        )

        simulation_result = None
        simulation_output = ""
        if compile_result.returncode == 0:
            simulation_result = run([str(vvp), str(image), "+V10D_ONLY"])
            simulation_output = simulation_result.stdout
        (mutation_dir / "simulation.log").write_text(
            simulation_output, encoding="utf-8"
        )

        simulation_rc = (
            simulation_result.returncode
            if simulation_result is not None
            else None
        )
        marker_observed = mutation["marker"] in simulation_output
        rejected = (
            compile_result.returncode == 0
            and simulation_rc is not None
            and simulation_rc != 0
            and marker_observed
        )
        results.append(
            {
                "name": mutation["name"],
                "compile_rc": compile_result.returncode,
                "compile_success": compile_result.returncode == 0,
                "simulation_rc": simulation_rc,
                "assertions": mutation["assertions"],
                "expected_rejection_marker": mutation["marker"],
                "marker_observed": marker_observed,
                "rejected": rejected,
                "mutated_rtl_sha256": {
                    str(target.relative_to(REPO)): sha256(path)
                    for target, path in mutated_paths.items()
                },
            }
        )

    summary = {
        "schema": "rv64-v10d-simulation-exit-mutation-summary-v1",
        "production_rtl_sha256": {
            str(path.relative_to(REPO)): sha256(path) for path in RTL_SOURCES
        },
        "testbench": str(TB.relative_to(REPO)),
        "testbench_sha256": sha256(TB),
        "configuration": {
            "iverilog": str(Path(iverilog).resolve()),
            "vvp": str(Path(vvp).resolve()),
            "systemverilog": "2012",
            "simulation_plusarg": "+V10D_ONLY",
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
