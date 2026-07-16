#!/usr/bin/env python3
"""Run fail-closed T3P source mutants and one executable owner mutant."""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
RUN = Path(__file__).resolve().parent
CHECKER = RUN / "check-t3p-source-contract.py"
IQ_REL = Path("npc/rv64/vsrc/scheduling/OooIntIssueQueue.v")
IB_REL = Path("npc/rv64/vsrc/execute/OooIntBackend.v")
WORK = ROOT / "tmp/2026-07-13-rv64-t3p-lane1-simple-owner/mutation-work"
OUT = RUN / "evidence/mutations"


def replace_once(text: str, old: str, new: str, name: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"[{name}] mutation anchor count={count}, expected 1")
    return text.replace(old, new, 1)


def materialize(name: str, iq: str, ib: str) -> Path:
    root = WORK / name / "source-root"
    if root.exists():
        raise SystemExit(f"[{name}] refusing stale mutation root: {root}")
    (root / IQ_REL.parent).mkdir(parents=True)
    (root / IB_REL.parent).mkdir(parents=True)
    (root / IQ_REL).write_text(iq, encoding="utf-8")
    (root / IB_REL).write_text(ib, encoding="utf-8")
    return root


def checker_kills(name: str, source_root: Path, expected: str) -> dict[str, object]:
    env = dict(os.environ)
    env["T3P_SOURCE_ROOT"] = str(source_root)
    proc = subprocess.run(
        ["python3", str(CHECKER)],
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
    )
    console = proc.stdout + proc.stderr
    (OUT / f"{name}.checker.log").write_text(console, encoding="utf-8")
    if proc.returncode == 0 or expected not in console:
        raise SystemExit(
            f"[{name}] checker mutant survived/vacuous: rc={proc.returncode} "
            f"expected={expected!r} console={console!r}"
        )
    return {
        "name": name,
        "checker_rc": proc.returncode,
        "expected_marker": expected,
        "status": "KILLED",
    }


def executable_iq_kill(name: str, mutated_iq: Path) -> dict[str, object]:
    result_dir = OUT / f"{name}-simulation"
    build_dir = WORK / f"{name}-build"
    proc = subprocess.run(
        [
            "make",
            "-C",
            str(ROOT / "npc/rv64/testbench"),
            "run",
            "TESTS=tb_ooo_int_issue_queue",
            f"RESULT_DIR={result_dir}",
            f"BUILD_DIR={build_dir}",
            f"RTL_OOO_INT_ISSUE_QUEUE={mutated_iq}",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    console = proc.stdout + proc.stderr
    (OUT / f"{name}.simulation-console.log").write_text(console, encoding="utf-8")
    log_path = result_dir / "logs/tb_ooo_int_issue_queue.log"
    log = log_path.read_text(encoding="utf-8") if log_path.exists() else ""
    if not (
        proc.returncode != 0
        and "[CHECK-FAIL] T3P lane1 skips second load" in log
        and "[RESULT] FAIL" in log
    ):
        raise SystemExit(
            f"[{name}] executable mutant survived/vacuous: rc={proc.returncode} "
            f"log={log_path}"
        )
    return {
        "name": f"{name}-simulation",
        "make_rc": proc.returncode,
        "marker": "[CHECK-FAIL] T3P lane1 skips second load",
        "status": "KILLED",
    }


def main() -> None:
    if WORK.exists():
        raise SystemExit(f"refusing stale mutation workspace: {WORK}")
    WORK.mkdir(parents=True)
    OUT.mkdir(parents=True, exist_ok=True)
    iq = (ROOT / IQ_REL).read_text(encoding="utf-8")
    ib = (ROOT / IB_REL).read_text(encoding="utf-8")

    iq_widen = replace_once(
        iq,
        "!ctrl[`CTRL_JALR_BIT] && !ctrl[`CTRL_LOAD_BIT] &&",
        "!ctrl[`CTRL_JALR_BIT] && 1'b1 && // MUTANT: load may own lane1.",
        "iq-widen-load-owner",
    )
    root_iq = materialize("iq-widen-load-owner", iq_widen, ib)

    ib_widen = replace_once(
        ib,
        "!ctrl[`CTRL_WFI_BIT] && !ctrl[`CTRL_MULDIV_BIT] &&\n"
        "          !ctrl[`CTRL_BITMANIP_BIT] && !ctrl[`CTRL_SFENCE_VMA_BIT] &&",
        "!ctrl[`CTRL_WFI_BIT] && !ctrl[`CTRL_MULDIV_BIT] &&\n"
        "          1'b1 && // MUTANT: bitmanip silently widened into lane1.\n"
        "          !ctrl[`CTRL_SFENCE_VMA_BIT] &&",
        "backend-widen-bitmanip-owner",
    )
    root_ib = materialize("backend-widen-bitmanip-owner", iq, ib_widen)

    ready_reconnect = replace_once(
        ib,
        "assign issue1_ready_w = !flush_i && !issue_block_w &&\n"
        "                          !mem_rsp_waiting_for_wb_w;",
        "assign issue1_ready_w = !flush_i && !issue_block_w &&\n"
        "                          !mem_rsp_waiting_for_wb_w &&\n"
        "                          // MUTANT: execution/address result recoupled to IQ pop.\n"
        "                          (!issue1_is_mem_w || issue1_mem_can_fire_w);",
        "ready-reconnect-memory",
    )
    root_ready = materialize("ready-reconnect-memory", iq, ready_reconnect)

    crosslane = replace_once(
        ib,
        "wire [`XLEN-1:0] issue1_src1_value_w = issue1_src1_data_w;\n"
        "  wire [`XLEN-1:0] issue1_src2_value_w = issue1_src2_data_w;",
        "wire issue1_src1_issue0_forward_w = issue0_fire_w &&\n"
        "      (issue1_src1_preg_w == issue0_pdest_w);\n"
        "  wire issue1_src2_issue0_forward_w = issue0_fire_w &&\n"
        "      (issue1_src2_preg_w == issue0_pdest_w);\n"
        "  wire [`XLEN-1:0] issue1_src1_value_w =\n"
        "      issue1_src1_issue0_forward_w ? issue0_wb_data_w : issue1_src1_data_w;\n"
        "  wire [`XLEN-1:0] issue1_src2_value_w =\n"
        "      issue1_src2_issue0_forward_w ? issue0_wb_data_w : issue1_src2_data_w;",
        "restore-crosslane-forward",
    )
    root_cross = materialize("restore-crosslane-forward", iq, crosslane)

    results = [
        checker_kills(
            "iq-widen-load-owner", root_iq, "IQ owner does not exclude CTRL_LOAD_BIT"
        ),
        executable_iq_kill("iq-widen-load-owner", root_iq / IQ_REL),
        checker_kills(
            "backend-widen-bitmanip-owner",
            root_ib,
            "IntBackend owner does not exclude CTRL_BITMANIP_BIT",
        ),
        checker_kills(
            "ready-reconnect-memory",
            root_ready,
            "issue1 ready is no longer the frozen shallow equation",
        ),
        checker_kills(
            "restore-crosslane-forward",
            root_cross,
            "cross-lane forward artifact remains",
        ),
    ]
    summary = {"status": "PASS", "mutants": results}
    (OUT / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
