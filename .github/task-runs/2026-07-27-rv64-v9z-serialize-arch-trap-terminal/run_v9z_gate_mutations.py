#!/usr/bin/env python3
"""Compile-success negative RTL variants for the V9Z drain boundary."""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
RESULT_ROOT = Path(__file__).resolve().parent / "mutations"
GATE = REPO / "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v"
MUX = REPO / "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v"
TB = (
    REPO
    / "npc/rv64/testbench/tests/tb_ooo_pending_arch_trap_memory_terminal.sv"
)
VSRCDIR = REPO / "npc/rv64/vsrc"
COMMON = REPO / "npc/rv64/testbench/common"

TERMINAL_BLOCK = """  wire pending_serialized_mem_terminal_w =
      !(pending_system_i || pending_arch_trap_i) ||
      mem_owner_terminalized_i;"""
FENCE_BLOCK = """  wire pending_fence_mem_quiet_w =
      !pending_system_fence_i || mem_idle_i;"""

MUTATIONS = (
    {
        "name": "drop-arch-trap-terminal-term",
        "old": TERMINAL_BLOCK,
        "new": """  wire pending_serialized_mem_terminal_w =
      !pending_system_i || mem_owner_terminalized_i;""",
        "marker": "[CHECK-FAIL] V9Z active memory holder blocks drain",
    },
    {
        "name": "use-full-mem-idle-for-serialized-controls",
        "old": TERMINAL_BLOCK,
        "new": """  wire pending_serialized_mem_terminal_w =
      !(pending_system_i || pending_arch_trap_i) || mem_idle_i;""",
        "marker": "[CHECK-FAIL] V9Z exact terminal admits drain",
    },
    {
        "name": "unconditional-memory-owner-gate",
        "old": TERMINAL_BLOCK,
        "new": """  wire pending_serialized_mem_terminal_w =
      mem_owner_terminalized_i;""",
        "marker": (
            "[CHECK-FAIL] V9Z unrelated drained control ignores memory holder"
        ),
    },
    {
        "name": "drop-ordinary-fence-full-idle-term",
        "old": FENCE_BLOCK,
        "new": """  wire pending_fence_mem_quiet_w = 1'b1;""",
        "marker": (
            "[CHECK-FAIL] V9Z overlapping FENCE still waits full memory idle"
        ),
    },
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
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

    source = GATE.read_text(encoding="utf-8")
    RESULT_ROOT.mkdir(parents=True, exist_ok=True)
    results = []

    for mutation in MUTATIONS:
        if source.count(mutation["old"]) != 1:
            raise SystemExit(
                f"{mutation['name']}: expected exactly one mutation anchor"
            )

        mutation_dir = RESULT_ROOT / mutation["name"]
        mutation_dir.mkdir(parents=True, exist_ok=True)
        mutated_gate = mutation_dir / GATE.name
        mutated_gate.write_text(
            source.replace(mutation["old"], mutation["new"]),
            encoding="utf-8",
        )
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
            "tb_ooo_pending_arch_trap_memory_terminal",
            "-o",
            str(image),
            str(mutated_gate),
            str(MUX),
            str(TB),
        ]
        compile_result = run(compile_command, REPO)
        (mutation_dir / "compile.log").write_text(
            "$ " + " ".join(compile_command) + "\n" + compile_result.stdout,
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
            simulation_result.returncode if simulation_result is not None else None
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
                "compile_rc": compile_result.returncode,
                "compile_success": compile_success,
                "simulation_rc": simulation_rc,
                "expected_rejection_marker": mutation["marker"],
                "marker_observed": marker_observed,
                "rejected": rejected,
                "mutated_rtl_sha256": sha256(mutated_gate),
            }
        )

    summary = {
        "schema": "rv64-v9z-gate-mutation-summary-v1",
        "production_gate": str(GATE.relative_to(REPO)),
        "production_gate_sha256": sha256(GATE),
        "trap_mux_sha256": sha256(MUX),
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
