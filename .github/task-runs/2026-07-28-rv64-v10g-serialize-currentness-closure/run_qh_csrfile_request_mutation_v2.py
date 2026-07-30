#!/usr/bin/env python3
"""Run the C2 CsrFile replay through product fallback, without a qh define."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
BASE = RUN_DIR / "run_qh_csrfile_request_mutation.py"
SPEC = importlib.util.spec_from_file_location(
    "v10g_qh_csrfile_request_mutation_v1", BASE
)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load CsrFile mutation runner: {BASE}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)

MODULE.OUT = RUN_DIR / "mutations/qh-csrfile-c2-replay-v2"
MODULE.MUTATION_COMMON = MODULE.OUT / "include"
MODULE.MUTATED_CSR_GLUE = MODULE.MUTATION_COMMON / MODULE.CSR_GLUE.name
MODULE.SUMMARY = MODULE.OUT / "summary.json"
ORIGINAL_COMPILE_COMMAND = MODULE.baseline_compile_command


def product_fallback_compile_command() -> list[str]:
    command = [
        arg
        for arg in ORIGINAL_COMPILE_COMMAND()
        if arg != "-DOOO_CSR_QUEUE_HEAD=1"
    ]
    if any("OOO_CSR_QUEUE_HEAD" in arg for arg in command):
        raise RuntimeError("queue-head command define remains")
    return command


MODULE.baseline_compile_command = product_fallback_compile_command


def main() -> int:
    rc = MODULE.main()
    value = json.loads(MODULE.SUMMARY.read_text(encoding="utf-8"))
    value["schema"] = "npc-rv64-v10g-qh-csrfile-request-mutation/v2"
    value["product_config"] = {
        "OOO_CSR_QUEUE_HEAD": 1,
        "command_line_override": False,
        "source": "npc/rv64/vsrc/include/define.v fallback",
        "manifest": "npc/rv64/configs/product-rtl-defaults.mk",
    }
    MODULE.SUMMARY.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-QH-CSRFILE-MUTATION-V2] "
        f"design_id={value['design_id']} override=none {value['status']}"
    )
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
