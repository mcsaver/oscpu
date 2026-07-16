#!/usr/bin/env python3
"""动态破坏三类 presence 更新，要求独立 occupancy 断言精确报错。"""

from __future__ import annotations

import difflib
import json
import shutil
import subprocess
from pathlib import Path


TASK_DIR = Path(__file__).resolve().parent
REPO_ROOT = TASK_DIR.parents[2]
RTL = REPO_ROOT / "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v"
TB = REPO_ROOT / "npc/rv64/testbench/tests/tb_ooo_fetch_packet_fifo.sv"
VSRCDIR = REPO_ROOT / "npc/rv64/vsrc"
TBCOMMON = REPO_ROOT / "npc/rv64/testbench/common"
OUT_DIR = TASK_DIR / "evidence/presence-mutation-negative-v1"
MARKER = "[T4B-FIFO-HEAD-PRESENCE]"


def mutate_once(text: str, old: str, new: str, name: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f"{name}: expected exactly one mutation site, got {text.count(old)}")
    return text.replace(old, new, 1)


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, check=False)


def main() -> int:
    source = RTL.read_text(encoding="utf-8")
    mutations = {
        "enqueue_fails_to_set": mutate_once(
            source,
            "2'b10: begin\n          count_q <= count_q + FIFO_COUNT_ONE;\n"
            "          head_valid_q <= 1'b1;",
            "2'b10: begin\n          count_q <= count_q + FIFO_COUNT_ONE;\n"
            "          head_valid_q <= 1'b0;",
            "enqueue_fails_to_set",
        ),
        "multi_pop_always_clears": mutate_once(
            source,
            "head_valid_q <= (count_q > FIFO_COUNT_ONE);",
            "head_valid_q <= 1'b0;",
            "multi_pop_always_clears",
        ),
        "hold_or_swap_drops_presence": mutate_once(
            source,
            "head_valid_q <= head_valid_q;",
            "head_valid_q <= 1'b0;",
            "hold_or_swap_drops_presence",
        ),
        "underflow_ignores_clear_priority": mutate_once(
            source,
            "if (!rst && !clear_i && pop_i && (count_q == FIFO_COUNT_ZERO)) begin",
            "if (!rst && pop_i && (count_q == FIFO_COUNT_ZERO)) begin",
            "underflow_ignores_clear_priority",
        ),
        "overflow_ignores_clear_priority": mutate_once(
            source,
            "if (!rst && !clear_i && enqueue_i && !pop_i &&",
            "if (!rst && enqueue_i && !pop_i &&",
            "overflow_ignores_clear_priority",
        ),
    }
    expected_markers = {
        "enqueue_fails_to_set": MARKER,
        "multi_pop_always_clears": MARKER,
        "hold_or_swap_drops_presence": MARKER,
        "underflow_ignores_clear_priority": "[CONTRACT-FIFO-UNDERFLOW]",
        "overflow_ignores_clear_priority": "[CONTRACT-FIFO-OVFL-REQUEST]",
        "unknown_enqueue_control": "[CONTRACT-FIFO-CONTROL-KNOWN]",
    }

    iverilog = shutil.which("iverilog")
    if not iverilog:
        raise RuntimeError("iverilog not found")
    adjacent_vvp = Path(iverilog).resolve().parent / "vvp"
    vvp = str(adjacent_vvp) if adjacent_vvp.exists() else shutil.which("vvp")
    if not vvp:
        raise RuntimeError("vvp not found")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    results: dict[str, object] = {}
    failed = False
    for name, mutated in mutations.items():
        case_dir = OUT_DIR / name
        case_dir.mkdir(parents=True, exist_ok=True)
        mutant = case_dir / "OooFetchPacketFifo.v"
        mutant.write_text(mutated, encoding="utf-8")
        diff = "".join(difflib.unified_diff(
            source.splitlines(keepends=True), mutated.splitlines(keepends=True),
            fromfile="OooFetchPacketFifo.v", tofile=f"{name}/OooFetchPacketFifo.v",
        ))
        (case_dir / "mutation.diff").write_text(diff, encoding="utf-8")

        image = case_dir / "tb_ooo_fetch_packet_fifo.vvp"
        compile_result = run([
            iverilog, "-g2012", "-Wall", f"-I{VSRCDIR}",
            f"-I{VSRCDIR / 'include'}", f"-I{TBCOMMON}", "-DOOO_ASSERT",
            "-s", "tb_ooo_fetch_packet_fifo", "-o", str(image),
            str(mutant), str(TB),
        ])
        (case_dir / "compile.log").write_text(compile_result.stdout, encoding="utf-8")
        sim_result = run([vvp, str(image)]) if compile_result.returncode == 0 else None
        sim_output = sim_result.stdout if sim_result else ""
        (case_dir / "sim.log").write_text(sim_output, encoding="utf-8")
        expected_marker = expected_markers[name]
        marker_count = sim_output.count(expected_marker)
        rejected = (
            compile_result.returncode == 0
            and sim_result is not None
            and sim_result.returncode != 0
            and marker_count == 1
        )
        failed = failed or not rejected
        results[name] = {
            "compile_rc": compile_result.returncode,
            "sim_rc": None if sim_result is None else sim_result.returncode,
            "expected_marker": expected_marker,
            "marker_count": marker_count,
            "result": "REJECTED" if rejected else "UNEXPECTED",
        }

    # 四态反例不是 RTL mutation，而是把 reset 释放后的第一个 enqueue 动作
    # 故意驱成 X；knownness guard 必须在 pointer/count 分叉前终止仿真。
    name = "unknown_enqueue_control"
    case_dir = OUT_DIR / name
    case_dir.mkdir(parents=True, exist_ok=True)
    tb_source = TB.read_text(encoding="utf-8")
    mutated_tb = mutate_once(
        tb_source,
        "    rst = 1'b0;\n    drive_enqueue_packet(",
        "    rst = 1'b0;\n"
        "    enqueue = 1'bx;\n"
        "    tick();\n"
        "    clear_controls();\n"
        "    drive_enqueue_packet(",
        name,
    )
    mutant_tb = case_dir / "tb_ooo_fetch_packet_fifo.sv"
    mutant_tb.write_text(mutated_tb, encoding="utf-8")
    diff = "".join(difflib.unified_diff(
        tb_source.splitlines(keepends=True), mutated_tb.splitlines(keepends=True),
        fromfile="tb_ooo_fetch_packet_fifo.sv",
        tofile=f"{name}/tb_ooo_fetch_packet_fifo.sv",
    ))
    (case_dir / "mutation.diff").write_text(diff, encoding="utf-8")
    image = case_dir / "tb_ooo_fetch_packet_fifo.vvp"
    compile_result = run([
        iverilog, "-g2012", "-Wall", f"-I{VSRCDIR}",
        f"-I{VSRCDIR / 'include'}", f"-I{TBCOMMON}", "-DOOO_ASSERT",
        "-s", "tb_ooo_fetch_packet_fifo", "-o", str(image),
        str(RTL), str(mutant_tb),
    ])
    (case_dir / "compile.log").write_text(compile_result.stdout, encoding="utf-8")
    sim_result = run([vvp, str(image)]) if compile_result.returncode == 0 else None
    sim_output = sim_result.stdout if sim_result else ""
    (case_dir / "sim.log").write_text(sim_output, encoding="utf-8")
    expected_marker = expected_markers[name]
    marker_count = sim_output.count(expected_marker)
    rejected = (
        compile_result.returncode == 0
        and sim_result is not None
        and sim_result.returncode != 0
        and marker_count == 1
    )
    failed = failed or not rejected
    results[name] = {
        "compile_rc": compile_result.returncode,
        "sim_rc": None if sim_result is None else sim_result.returncode,
        "expected_marker": expected_marker,
        "marker_count": marker_count,
        "result": "REJECTED" if rejected else "UNEXPECTED",
    }

    summary = {
        "status": "PASS" if not failed else "FAIL",
        "markers_by_mutation": expected_markers,
        "mutations": results,
    }
    (OUT_DIR / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
