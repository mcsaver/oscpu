#!/usr/bin/env python3
"""Positive and negative unit cases for the F0 functional diagnostic classifier."""

from __future__ import annotations

import importlib.util
import pathlib
import sys


HERE = pathlib.Path(__file__).resolve().parent
CHECKER = HERE / "build-f0-summary.py"


def main() -> int:
    spec = importlib.util.spec_from_file_location("v14e_f0_summary_checker_test", CHECKER)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load F0 summary checker")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    accepted = (
        "command=verilator -Wno-fatal --cc OooCoreTop.v",
        "NPC_RUN_ARGS=--diff=<REPO>/frozen/riscv64-nemu-interpreter-so",
        "all workload phases completed",
    )
    rejected = (
        "FATAL: simulation terminated before GOOD TRAP",
        "%Error: OooCoreTop.v: transaction owner mismatch",
        "OooCoreTop.v:42: warning: combinational loop",
        "[CHECK-FAIL] retirement transaction mismatch",
        "difftest mismatch at committed instruction 42",
    )
    known = (
        "<REPO>/npc/rv64/csrc/monitor/disasm.c:40:43: warning: "
        "‘/nemu/tools/capstone/repo/li...’ directive output may be truncated "
        "writing 42 bytes into a region of size between 1 and 4096 "
        "[-Wformat-truncation=]"
    )
    for line in accepted:
        if module.classify_functional_line(line) != "NONE":
            raise RuntimeError(f"accepted line was rejected: {line}")
    if module.classify_functional_line("difftest_mismatches=0") != "ZERO_MISMATCH":
        raise RuntimeError("zero-mismatch marker was not classified exactly")
    if module.classify_functional_line(known) != "KNOWN_HOST_PATH_FORMAT_TRUNCATION":
        raise RuntimeError("known host path warning was not classified exactly")
    for line in rejected:
        if module.classify_functional_line(line) != "DIAGNOSTIC":
            raise RuntimeError(f"diagnostic line was accepted: {line}")
    print(
        "[V14E-F0-DIAGNOSTIC-CLASSIFIER][PASS] accepted=3/3 "
        "zero_mismatch=1/1 known_host_warning=1/1 rejected=5/5"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
