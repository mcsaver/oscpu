#!/usr/bin/env python3
"""Replay the complete pending-SYSTEM matrix with product queue-head default 1."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
BASE = (
    RUN_DIR.parent
    / "2026-07-27-rv64-v10b-serialized-system-post-fire"
    / "run-v10b-focused-matrix-v3.py"
)
IDENTITY = RUN_DIR / "product-default-identity.json"
MANIFEST = ROOT / "npc/rv64/configs/product-rtl-defaults.mk"
DEFINE = ROOT / "npc/rv64/vsrc/include/define.v"
SPEC = importlib.util.spec_from_file_location(
    "v10b_matrix_v3_for_v10g_product_default", BASE
)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load V10B matrix: {BASE}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)

MATRIX = MODULE.MATRIX
MATRIX.OUT = RUN_DIR / "system-product-default-matrix"
MATRIX.SUMMARY = MATRIX.OUT / "summary.json"
MATRIX.STATUS = MATRIX.OUT / "status.json"
MATRIX.SCHEMA = "rv64-v10g-system-product-default-matrix-v1"
MATRIX.MATRIX_TITLE = "V10G product-default queue-head=1 SYSTEM matrix"


def main() -> int:
    identity = json.loads(IDENTITY.read_text(encoding="utf-8"))
    if identity.get("status") != "PASS":
        raise SystemExit("product-default identity is not PASS")
    manifest_text = MANIFEST.read_text(encoding="utf-8")
    if manifest_text.count("OOO_CSR_QUEUE_HEAD ?= 1") != 1:
        raise SystemExit("product manifest queue-head default is not exactly 1")
    define_text = DEFINE.read_text(encoding="utf-8")
    fallback_anchor = (
        "`ifndef OOO_CSR_QUEUE_HEAD\n"
        "`define OOO_CSR_QUEUE_HEAD 1'b1\n"
        "`endif"
    )
    if define_text.count(fallback_anchor) != 1:
        raise SystemExit("RTL queue-head fallback is not exactly 1")

    rc = MATRIX.main()
    summary = json.loads(MATRIX.SUMMARY.read_text(encoding="utf-8"))
    compile_lines: list[dict[str, object]] = []
    for case in summary["cases"]:
        log = ROOT / case["result_log"]
        compile_line = next(
            (
                line
                for line in log.read_text(encoding="utf-8").splitlines()
                if line.startswith("[COMPILE] ")
            ),
            "",
        )
        compile_lines.append(
            {
                "case": case["name"],
                "compile_line_present": bool(compile_line),
                "queue_head_command_define_present":
                    "-DOOO_CSR_QUEUE_HEAD" in compile_line,
            }
        )
    no_command_override = all(
        item["compile_line_present"]
        and not item["queue_head_command_define_present"]
        for item in compile_lines
    )
    identity_match = (
        summary.get("design_id") == identity.get("current_design_id")
    )
    product_status = bool(
        rc == 0
        and summary.get("all_pass")
        and no_command_override
        and identity_match
    )
    summary["product_default_binding"] = {
        "status": "PASS" if product_status else "GAP",
        "OOO_CSR_QUEUE_HEAD": 1,
        "command_line_override": False,
        "manifest": MANIFEST.relative_to(ROOT).as_posix(),
        "rtl_fallback": DEFINE.relative_to(ROOT).as_posix(),
        "identity": IDENTITY.relative_to(ROOT).as_posix(),
        "identity_match": identity_match,
        "compile_receipts": compile_lines,
    }
    summary["all_pass"] = product_status
    MATRIX.SUMMARY.write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    MATRIX.STATUS.write_text(
        json.dumps(
            {
                "state": "DONE",
                "completed": len(summary["cases"]),
                "total": len(summary["cases"]),
                "all_pass": product_status,
                "product_default_binding": (
                    "PASS" if product_status else "GAP"
                ),
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-PRODUCT-DEFAULT-SYSTEM] "
        f"baselines=3/3 "
        f"compile-success={summary['compile_success_mutations']}/14 "
        f"rejected={summary['dynamically_rejected_mutations']}/14 "
        f"override=none identity={'match' if identity_match else 'drift'} "
        f"{'PASS' if product_status else 'GAP'}"
    )
    return 0 if product_status else 1


if __name__ == "__main__":
    raise SystemExit(main())
