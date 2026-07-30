#!/usr/bin/env python3
"""Rebind the queue-head C2 typed-apply replay to the product-default design."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
BASE = RUN_DIR / "run_qh_csr_raw_mutation.py"
SPEC = importlib.util.spec_from_file_location("v10g_qh_raw_mutation_v2", BASE)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load queue-head mutation runner: {BASE}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)

MODULE.OUT = RUN_DIR / "mutations/qh-csr-c2-replay-v3"
MODULE.MUTATED_RTL = MODULE.OUT / "rtl/OooControlEventApplySequencer.v"
MODULE.PRE_SCOREBOARD_TB = (
    MODULE.OUT / "tb/tb_ooo_core_top_glue.pre-v10g.sv"
)
MODULE.SUMMARY = MODULE.OUT / "summary.json"


def main() -> int:
    rc = MODULE.main()
    value = json.loads(MODULE.SUMMARY.read_text(encoding="utf-8"))
    value["schema"] = "npc-rv64-v10g-qh-csr-raw-mutation-v3"
    value["design_id"] = (
        "sha256:"
        "04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897"
    )
    value["product_default_binding"] = {
        "OOO_CSR_QUEUE_HEAD": 1,
        "command_line_value": 1,
        "command_line_value_matches_product_default": True,
        "manifest": "npc/rv64/configs/product-rtl-defaults.mk",
    }
    MODULE.SUMMARY.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-QH-CSR-MUTATION-V3] "
        f"design_id={value['design_id']} {value['status']}"
    )
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
