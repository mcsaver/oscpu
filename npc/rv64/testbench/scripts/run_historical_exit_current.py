#!/usr/bin/env python3
"""Re-run the bounded V10D exit/active-memory contract on current RV64 RTL.

Only logs and a compact JSON receipt are retained.  Icarus images and mutated
RTL live in a temporary directory and are removed after the run.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import shlex
import shutil
import subprocess
import sys
import tempfile
from typing import Any


SCHEMA = "npc-rv64-historical-exit-current-v1"
PLUSARG = "+V10D_ONLY"
BASELINE_MARKERS = {
    "[V10D-EXIT-EXACTLY-ONCE-PASS]": 2,
    "[V10D-EXIT-LOCAL-FLUSH-PASS]": 1,
    "[V10D-EXIT-RECOVERY-PRIORITY-PASS]": 1,
    "[CHECK-FAIL]": 0,
}


class ExitCurrentError(RuntimeError):
    """The current-design focused execution is not auditable or did not pass."""


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start.resolve(), *start.resolve().parents):
        if (candidate / ".github").is_dir() and (candidate / "npc/rv64").is_dir():
            return candidate
    raise ExitCurrentError("cannot locate repository root")


ROOT = find_repo_root(pathlib.Path(__file__))
VSRCDIR = ROOT / "npc/rv64/vsrc"
COMMON = ROOT / "npc/rv64/testbench/common"
TB = ROOT / "npc/rv64/testbench/tests/tb_ooo_serialized_owner_exactly_once.sv"
ARCH_BINDING_TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"

CSR_MUX = VSRCDIR / "control/OooCsrTrapRequestMux.v"
ARBITER = VSRCDIR / "control/OooPendingDispatchArbiter.v"
DRAIN = VSRCDIR / "control/OooPendingDrainResolveGate.v"
SERIALIZED_MEM_TERMINAL_PERMIT = (
    VSRCDIR / "control/OooSerializedMemTerminalPermit.v"
)
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
    SERIALIZED_MEM_TERMINAL_PERMIT,
    LANE1,
    SYSTEM_SEQ,
    TRAP_SEQ,
    STOP_SEQ,
    EVENT_MUX,
    OUTPUT_SEQ,
    CSR_FILE,
    RUN_GATE,
)

SERIALIZED_OWNER_BLOCK = """  wire pending_serialized_owner_w =
      (pending_system_i && !pending_system_csr_i) ||
      pending_arch_trap_i || pending_exit_i;"""

SERIALIZED_TERMINAL_BLOCK = """  wire pending_serialized_mem_terminal_w =
      !pending_serialized_owner_w || serialized_mem_terminal_ready_i;"""

EXIT_DRAIN_TERM = """  assign exit_o =
      drain_reached_w &&"""

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

MUTATIONS: tuple[dict[str, Any], ...] = (
    {
        "name": "drop-exit-memory-terminal-term",
        "assertions": True,
        "edits": ((DRAIN, SERIALIZED_OWNER_BLOCK, """  wire pending_serialized_owner_w =
      (pending_system_i && !pending_system_csr_i) ||
      pending_arch_trap_i;"""),),
        "marker": "[CHECK-FAIL] V10D active memory holder blocks drain",
    },
    {
        "name": "replace-exact-terminal-with-full-mem-idle",
        "assertions": True,
        "edits": ((DRAIN, SERIALIZED_TERMINAL_BLOCK, """  wire pending_serialized_mem_terminal_w =
      !pending_serialized_owner_w || mem_idle_i;"""),),
        "marker": "[CHECK-FAIL] V10D active memory holder blocks drain",
    },
    {
        "name": "drop-exit-holder-drain-clear",
        "assertions": True,
        "edits": ((ARBITER, CLEAR_EXIT_BLOCK, """  assign pending_trap_exit_clear_exit_o =
      (direct_frontend_flush_i && direct_branch_fire_w) ||
      pending_jump_clear_from_resolve_w ||
      trap_exit_capture_clear_exit_w;"""),),
        "marker": "[CHECK-FAIL] V10D C1 clears exit owner",
    },
    {
        "name": "drop-stop-drain-clear",
        "assertions": True,
        "edits": ((STOP_SEQ, STOP_DRAIN_CLEAR_BLOCK, """    end else if (!csr_trap_mem_valid_i &&
                 !direct_frontend_flush_i &&
                 stop_pending_o && drain_complete_i && 1'b0) begin
      stop_pending_o <= 1'b0;
    end"""),),
        "marker": "[CHECK-FAIL] V10D C1 clears stop",
    },
    {
        "name": "swap-exit-kind-selection",
        "assertions": True,
        "edits": ((ARBITER, EXIT_KIND_BLOCK, """  assign pending_trap_exit_capture_exit_ecall_o =
      trap_exit_capture_exit0_w ? dispatch0_ebreak_w :
                                  trap_exit_lane1_exit_ebreak_w;
  assign pending_trap_exit_capture_exit_ebreak_o =
      trap_exit_capture_exit0_w ? dispatch0_ecall_w :
                                  trap_exit_lane1_exit_ecall_w;"""),),
        "marker": "[CHECK-FAIL] V10D exit capture ecall kind",
    },
    {
        "name": "drop-exit-event-drain-gate",
        "assertions": True,
        "edits": ((EVENT_MUX, EXIT_DRAIN_TERM, "  assign exit_o ="),),
        "marker": "[CHECK-FAIL] V10D active memory holder blocks raw exit",
    },
    {
        "name": "extend-raw-exit-beyond-terminal-cycle",
        "assertions": False,
        "edits": (
            (ARBITER, CLEAR_EXIT_BLOCK, """  assign pending_trap_exit_clear_exit_o =
      (direct_frontend_flush_i && direct_branch_fire_w) ||
      pending_jump_clear_from_resolve_w ||
      trap_exit_capture_clear_exit_w;"""),
            (STOP_SEQ, STOP_DRAIN_CLEAR_BLOCK, """    end else if (!csr_trap_mem_valid_i &&
                 !direct_frontend_flush_i &&
                 stop_pending_o && drain_complete_i && 1'b0) begin
      stop_pending_o <= 1'b0;
    end"""),
        ),
        "marker": "[CHECK-FAIL] V10D C2 raw exit no-repeat",
    },
)


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def artifact(path: pathlib.Path) -> dict[str, Any]:
    resolved = path.resolve(strict=True)
    try:
        relative = resolved.relative_to(ROOT)
    except ValueError as exc:
        raise ExitCurrentError(f"retained artifact escapes repository: {path}") from exc
    return {
        "path": relative.as_posix(),
        "sha256": sha256_file(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ExitCurrentError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def tool_record(path_text: str) -> dict[str, str]:
    path = pathlib.Path(path_text).resolve(strict=True)
    version = subprocess.run(
        [str(path), "-V"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=10,
    ).stdout.strip()
    return {"path": str(path), "sha256": sha256_file(path), "version": version}


def compile_and_run(
    *,
    label: str,
    sources: list[pathlib.Path],
    assertions: bool,
    build_root: pathlib.Path,
    result_dir: pathlib.Path,
    iverilog: str,
    vvp: str,
) -> tuple[int, int | None, str, pathlib.Path, pathlib.Path]:
    image = build_root / f"{label}.vvp"
    command = [
        iverilog,
        "-g2012",
        "-Wall",
        f"-I{VSRCDIR}",
        f"-I{VSRCDIR / 'include'}",
        f"-I{COMMON}",
    ]
    if assertions:
        command.append("-DOOO_ASSERT")
    command.extend(
        [
            "-s",
            "tb_ooo_serialized_owner_exactly_once",
            "-o",
            str(image),
            *[str(path) for path in sources],
            str(TB),
        ]
    )
    compile_result = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=120,
    )
    compile_log = result_dir / f"{label}.compile.log"
    compile_log.write_text(
        "$ " + shlex.join(command) + "\n" + compile_result.stdout,
        encoding="utf-8",
    )

    sim_rc: int | None = None
    sim_output = ""
    sim_command: list[str] | None = None
    if compile_result.returncode == 0:
        sim_command = [vvp, str(image), PLUSARG]
        sim_result = subprocess.run(
            sim_command,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=60,
        )
        sim_rc = sim_result.returncode
        sim_output = sim_result.stdout
    sim_log = result_dir / f"{label}.simulation.log"
    sim_log.write_text(
        ("$ " + shlex.join(sim_command) + "\n" if sim_command is not None else "")
        + sim_output,
        encoding="utf-8",
    )
    return compile_result.returncode, sim_rc, sim_output, compile_log, sim_log


def build_current_run(result_dir: pathlib.Path) -> dict[str, Any]:
    result_dir = result_dir.resolve()
    try:
        result_dir.relative_to(ROOT)
    except ValueError as exc:
        raise ExitCurrentError("result directory must be inside the repository") from exc
    if result_dir.exists() and any(result_dir.iterdir()):
        raise ExitCurrentError(f"result directory is not empty: {result_dir}")
    result_dir.mkdir(parents=True, exist_ok=True)

    iverilog = shutil.which("iverilog")
    vvp = shutil.which("vvp")
    if not iverilog or not vvp:
        raise ExitCurrentError("paired Icarus tools are unavailable")

    arch_module = load_module(ARCH_BINDING_TOOL, "historical_exit_current_binding")
    digest, rtl_files = arch_module.rtl_binding(ROOT)
    design_id = f"sha256:{digest}"
    production_text = {source: source.read_text(encoding="utf-8") for source in RTL_SOURCES}
    baseline_rows: list[dict[str, Any]] = []
    mutation_rows: list[dict[str, Any]] = []

    with tempfile.TemporaryDirectory(prefix="rv64-historical-exit-current-") as directory:
        build_root = pathlib.Path(directory)
        for profile, assertions in (("assert", True), ("release", False)):
            label = f"baseline-{profile}"
            compile_rc, sim_rc, output, compile_log, sim_log = compile_and_run(
                label=label,
                sources=list(RTL_SOURCES),
                assertions=assertions,
                build_root=build_root,
                result_dir=result_dir,
                iverilog=iverilog,
                vvp=vvp,
            )
            marker_counts = {marker: output.count(marker) for marker in BASELINE_MARKERS}
            passed = (
                compile_rc == 0
                and sim_rc == 0
                and marker_counts == BASELINE_MARKERS
            )
            baseline_rows.append(
                {
                    "profile": profile,
                    "assertions": assertions,
                    "compile_rc": compile_rc,
                    "simulation_rc": sim_rc,
                    "marker_counts": marker_counts,
                    "passed": passed,
                    "compile_log": artifact(compile_log),
                    "simulation_log": artifact(sim_log),
                }
            )

        for mutation in MUTATIONS:
            mutated_text: dict[pathlib.Path, str] = {}
            for target, old, new in mutation["edits"]:
                source = mutated_text.get(target, production_text[target])
                count = source.count(old)
                if count != 1:
                    raise ExitCurrentError(
                        f"{mutation['name']}: expected one mutation anchor in "
                        f"{target.relative_to(ROOT)}, got {count}"
                    )
                mutated_text[target] = source.replace(old, new, 1)

            mutated_paths: dict[pathlib.Path, pathlib.Path] = {}
            mutation_root = build_root / mutation["name"]
            mutation_root.mkdir(parents=True, exist_ok=True)
            for target, text in mutated_text.items():
                path = mutation_root / target.name
                path.write_text(text, encoding="utf-8")
                mutated_paths[target] = path

            sources = [mutated_paths.get(source, source) for source in RTL_SOURCES]
            compile_rc, sim_rc, output, compile_log, sim_log = compile_and_run(
                label=f"mutation-{mutation['name']}",
                sources=sources,
                assertions=bool(mutation["assertions"]),
                build_root=build_root,
                result_dir=result_dir,
                iverilog=iverilog,
                vvp=vvp,
            )
            marker_count = output.count(mutation["marker"])
            rejected = compile_rc == 0 and sim_rc not in (None, 0) and marker_count > 0
            mutation_rows.append(
                {
                    "name": mutation["name"],
                    "assertions": bool(mutation["assertions"]),
                    "compile_rc": compile_rc,
                    "simulation_rc": sim_rc,
                    "expected_rejection_marker": mutation["marker"],
                    "marker_count": marker_count,
                    "compile_success": compile_rc == 0,
                    "rejected": rejected,
                    "mutated_sources": {
                        target.relative_to(ROOT).as_posix(): sha256_file(path)
                        for target, path in sorted(
                            mutated_paths.items(), key=lambda item: item[0].as_posix()
                        )
                    },
                    "compile_log": artifact(compile_log),
                    "simulation_log": artifact(sim_log),
                }
            )

    passed = all(row["passed"] for row in baseline_rows) and all(
        row["rejected"] for row in mutation_rows
    )
    return {
        "schema": SCHEMA,
        "status": "PASS" if passed else "FAIL",
        "design_id": design_id,
        "rtl_file_count": len(rtl_files),
        "scope": "pending exit C0/C1/C2, exact memory terminal, trap priority and output latch",
        "configuration": {
            "systemverilog": "2012",
            "plusarg": PLUSARG,
            "iverilog": tool_record(iverilog),
            "vvp": tool_record(vvp),
        },
        "source_bindings": [
            {
                "path": path.relative_to(ROOT).as_posix(),
                "role": "testbench" if path == TB else "rtl",
                "sha256": sha256_file(path),
            }
            for path in (*RTL_SOURCES, TB)
        ],
        "baselines": baseline_rows,
        "mutations": mutation_rows,
        "counts": {
            "baseline_profiles_pass": sum(row["passed"] for row in baseline_rows),
            "baseline_profiles_required": len(baseline_rows),
            "compile_success_mutations": sum(row["compile_success"] for row in mutation_rows),
            "dynamically_rejected_mutations": sum(row["rejected"] for row in mutation_rows),
            "mutations_required": len(mutation_rows),
        },
        "production_rtl_change": False,
        "intermediate_products_retained": 0,
        "claim_boundary": (
            "Focused current-design exit/active-memory contract only; whole architecture "
            "remains RED and PPA remains unpromoted."
        ),
        "promotion": {"whole_architecture": "RED", "ppa": "UNPROMOTED"},
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--result-dir", type=pathlib.Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        payload = build_current_run(args.result_dir)
    except (ExitCurrentError, OSError, subprocess.SubprocessError) as exc:
        print(f"[HISTORICAL-EXIT-CURRENT][FAIL] {exc}", file=sys.stderr)
        return 2
    summary_path = args.result_dir.resolve() / "summary.json"
    summary_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[HISTORICAL-EXIT-CURRENT] "
        f"status={payload['status']} "
        f"baseline={payload['counts']['baseline_profiles_pass']}/"
        f"{payload['counts']['baseline_profiles_required']} "
        f"mutations={payload['counts']['dynamically_rejected_mutations']}/"
        f"{payload['counts']['mutations_required']} "
        f"design_id={payload['design_id']}"
    )
    return 0 if payload["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
