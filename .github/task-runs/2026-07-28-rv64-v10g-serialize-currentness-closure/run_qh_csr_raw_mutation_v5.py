#!/usr/bin/env python3
"""Run the typed-apply C2 replay through product fallback, without a qh define."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
BASE = RUN_DIR / "run_qh_csr_raw_mutation_v4.py"
SPEC = importlib.util.spec_from_file_location(
    "v10g_qh_raw_mutation_v4_runner", BASE
)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load typed-apply mutation runner: {BASE}")
V4 = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = V4
SPEC.loader.exec_module(V4)

V4.MODULE.OUT = RUN_DIR / "mutations/qh-csr-c2-replay-v5"
V4.MODULE.MUTATED_RTL = (
    V4.MODULE.OUT / "rtl/OooControlEventApplySequencer.v"
)
V4.MODULE.PRE_SCOREBOARD_TB = (
    V4.MODULE.OUT / "tb/tb_ooo_core_top_glue.pre-v10g.sv"
)
V4.MODULE.SUMMARY = V4.MODULE.OUT / "summary.json"
ORIGINAL_COMPILE_COMMAND = V4.MODULE.baseline_compile_command


def product_fallback_compile_command() -> list[str]:
    command = [
        arg
        for arg in ORIGINAL_COMPILE_COMMAND()
        if arg != "-DOOO_CSR_QUEUE_HEAD=1"
    ]
    if any("OOO_CSR_QUEUE_HEAD" in arg for arg in command):
        raise RuntimeError("queue-head command define remains")
    return command


V4.MODULE.baseline_compile_command = product_fallback_compile_command


def main() -> int:
    rc = V4.main()
    value = json.loads(V4.MODULE.SUMMARY.read_text(encoding="utf-8"))
    value["schema"] = "npc-rv64-v10g-qh-csr-raw-mutation-v5"
    value["product_default_binding"] = {
        "OOO_CSR_QUEUE_HEAD": 1,
        "command_line_override": False,
        "source": "npc/rv64/vsrc/include/define.v fallback",
        "manifest": "npc/rv64/configs/product-rtl-defaults.mk",
    }
    V4.MODULE.SUMMARY.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-QH-CSR-MUTATION-V5] "
        f"design_id={value['design_id']} override=none {value['status']}"
    )
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
