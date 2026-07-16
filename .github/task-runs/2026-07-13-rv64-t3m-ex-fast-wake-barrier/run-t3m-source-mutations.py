#!/usr/bin/env python3
"""Compile and run three source-level T3M mutants; every mutant must be killed."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
RUN = Path(__file__).resolve().parent
TB = ROOT / "npc/rv64/testbench"
VSRC = ROOT / "npc/rv64/vsrc"
WORK = ROOT / "tmp/2026-07-13-rv64-t3m-ex-fast-wake-barrier/mutation-work"
OUT = RUN / "evidence/mutations"


def replace_once(text: str, old: str, new: str, name: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"[{name}] mutation anchor count={count}, expected 1")
    return text.replace(old, new, 1)


def run_case(name: str, top: str, tb_src: Path, rtl_src: Path, marker: str) -> dict:
    iverilog = shutil.which("iverilog")
    if not iverilog:
        raise SystemExit("iverilog not found")
    paired_vvp = str(Path(iverilog).with_name("vvp"))
    vvp = paired_vvp if os.access(paired_vvp, os.X_OK) else shutil.which("vvp")
    if not vvp:
        raise SystemExit("vvp not found")

    image = WORK / f"{name}.vvp"
    compile_log = OUT / f"{name}.compile.log"
    sim_log = OUT / f"{name}.sim.log"
    command = [
        iverilog,
        "-g2012",
        "-Wall",
        f"-I{VSRC}",
        f"-I{VSRC / 'include'}",
        f"-I{TB / 'common'}",
        "-DOOO_ASSERT",
        "-s",
        top,
        "-o",
        str(image),
        str(tb_src),
        str(rtl_src),
    ]
    comp = subprocess.run(command, cwd=TB, text=True, capture_output=True)
    compile_log.write_text(comp.stdout + comp.stderr, encoding="utf-8")
    if comp.returncode != 0:
        raise SystemExit(f"[{name}] compile failed; compile failure is not a killed mutant")

    sim = subprocess.run([vvp, str(image)], cwd=TB, text=True, capture_output=True)
    output = sim.stdout + sim.stderr
    sim_log.write_text(output, encoding="utf-8")
    killed = sim.returncode != 0 and (marker in output or "[CHECK-FAIL]" in output)
    if not killed:
        raise SystemExit(
            f"[{name}] mutant survived: sim_rc={sim.returncode} marker={marker in output}"
        )
    return {
        "name": name,
        "compile_rc": comp.returncode,
        "sim_rc": sim.returncode,
        "marker": marker,
        "marker_seen": marker in output,
        "check_fail_seen": "[CHECK-FAIL]" in output,
        "status": "KILLED",
    }


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)

    iq_path = VSRC / "scheduling/OooIntIssueQueue.v"
    iq_text = iq_path.read_text(encoding="utf-8")
    prf_path = VSRC / "regread_bypass/OooPhysRegFile.v"
    prf_text = prf_path.read_text(encoding="utf-8")

    same_cycle = replace_once(
        iq_text,
        """                              src1_ready_q[scan_i] &&
                              src2_ready_q[scan_i] &&""",
        """                              (src1_ready_q[scan_i] ||
                               wakeup_match(src1_preg_q[scan_i],
                                            wakeup0_valid_i,
                                            wakeup0_pdest_i,
                                            wakeup1_valid_i,
                                            wakeup1_pdest_i)) &&
                              src2_ready_q[scan_i] &&""",
        "iq-same-cycle-select",
    )
    same_cycle_path = WORK / "OooIntIssueQueue.same-cycle-select.v"
    same_cycle_path.write_text(same_cycle, encoding="utf-8")

    dispatch_drop = replace_once(
        iq_text,
        """      src1_ready_next_r[write_i] =
          dispatch0_src1_ready_i ||
          wakeup_match(dispatch0_src1_preg_i,
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);""",
        """      src1_ready_next_r[write_i] =
          dispatch0_src1_ready_i;""",
        "iq-dispatch-collision-drop",
    )
    dispatch_drop_path = WORK / "OooIntIssueQueue.dispatch-collision-drop.v"
    dispatch_drop_path.write_text(dispatch_drop, encoding="utf-8")

    prf_write_through = replace_once(
        prf_text,
        """  assign read0_data_o =
      (read0_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
                                                 regs_q[read0_addr_i];""",
        """  assign read0_data_o =
      (read0_addr_i == {PHY_REG_ADDR_W{1'b0}}) ? {`XLEN{1'b0}} :
      (write1_valid_i && (write1_addr_i == read0_addr_i)) ? write1_data_i :
      (write0_valid_i && (write0_addr_i == read0_addr_i)) ? write0_data_i :
                                                            regs_q[read0_addr_i];""",
        "prf-write-through",
    )
    prf_write_through_path = WORK / "OooPhysRegFile.write-through.v"
    prf_write_through_path.write_text(prf_write_through, encoding="utf-8")

    results = [
        run_case(
            "iq-same-cycle-select",
            "tb_ooo_int_issue_queue",
            TB / "tests/tb_ooo_int_issue_queue.sv",
            same_cycle_path,
            "[IQ-INT-WAKE-STICKY-ONLY]",
        ),
        run_case(
            "iq-dispatch-collision-drop",
            "tb_ooo_int_issue_queue",
            TB / "tests/tb_ooo_int_issue_queue.sv",
            dispatch_drop_path,
            "[CHECK-FAIL]",
        ),
        run_case(
            "prf-write-through",
            "tb_ooo_phys_reg_file",
            TB / "tests/tb_ooo_phys_reg_file.sv",
            prf_write_through_path,
            "[PRF-INT-READ-STORED-ONLY]",
        ),
    ]
    summary = {"status": "PASS", "mutants": results}
    (OUT / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
