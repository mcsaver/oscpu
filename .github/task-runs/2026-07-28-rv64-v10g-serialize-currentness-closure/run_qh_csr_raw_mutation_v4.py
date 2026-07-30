#!/usr/bin/env python3
"""Product-default typed-apply C2 replay with the current request/apply marker."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
BASE = RUN_DIR / "run_qh_csr_raw_mutation.py"
SPEC = importlib.util.spec_from_file_location("v10g_qh_raw_mutation_base", BASE)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load queue-head mutation runner: {BASE}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)

MODULE.OUT = RUN_DIR / "mutations/qh-csr-c2-replay-v4"
MODULE.MUTATED_RTL = MODULE.OUT / "rtl/OooControlEventApplySequencer.v"
MODULE.PRE_SCOREBOARD_TB = (
    MODULE.OUT / "tb/tb_ooo_core_top_glue.pre-v10g.sv"
)
MODULE.SUMMARY = MODULE.OUT / "summary.json"
CURRENT_ID = (
    "sha256:"
    "04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897"
)


def main() -> int:
    base_rc = MODULE.main()
    value = json.loads(MODULE.SUMMARY.read_text(encoding="utf-8"))
    old_case, current_case = value["cases"]
    old_text = (
        MODULE.ROOT / old_case["simulation_log"]
    ).read_text(encoding="utf-8")
    current_text = (
        MODULE.ROOT / current_case["simulation_log"]
    ).read_text(encoding="utf-8")
    combined_marker = (
        "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply"
    )
    unowned_marker = (
        "[CHECK-FAIL] V10G unowned/repeated queue-head CSR apply"
    )
    combined_count = current_text.count(combined_marker)
    unowned_count = current_text.count(unowned_marker)
    passed = bool(
        old_case["compile_returncode"] == 0
        and old_case["simulation_returncode"] == 0
        and old_case["pass_marker"]
        and combined_marker not in old_text
        and unowned_marker not in old_text
        and current_case["compile_returncode"] == 0
        and current_case["simulation_returncode"] == 1
        and not current_case["pass_marker"]
        and combined_count == 3
        and unowned_count == 3
    )
    current_case["c2_request_apply_reject_marker"] = passed
    current_case["c2_request_apply_reject_count"] = combined_count
    current_case["unowned_apply_reject_count"] = unowned_count
    value["schema"] = "npc-rv64-v10g-qh-csr-raw-mutation-v4"
    value["status"] = "PASS" if passed else "GAP"
    value["design_id"] = CURRENT_ID
    value["base_v2_marker_evaluation"] = {
        "returncode": base_rc,
        "status": "GAP_MARKER_SCHEMA_ONLY" if passed else "GAP",
        "obsolete_marker": (
            "[CHECK-FAIL] V10G C2 repeated queue-head CSR apply"
        ),
        "current_marker": combined_marker,
    }
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
        "[V10G-QH-CSR-MUTATION-V4] "
        f"old_rc={old_case['simulation_returncode']} "
        f"current_rc={current_case['simulation_returncode']} "
        f"C2={combined_count} unowned={unowned_count} "
        f"{value['status']}"
    )
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
