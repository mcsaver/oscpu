#!/usr/bin/env python3
"""Run the post-oracle-fix product-default pending-SYSTEM matrix."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
BASE = RUN_DIR / "run_v10b_product_default_matrix.py"
SPEC = importlib.util.spec_from_file_location(
    "v10g_product_default_matrix_v1_runner", BASE
)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load product-default matrix: {BASE}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)

MODULE.MATRIX.OUT = RUN_DIR / "system-product-default-matrix-v2"
MODULE.MATRIX.SUMMARY = MODULE.MATRIX.OUT / "summary.json"
MODULE.MATRIX.STATUS = MODULE.MATRIX.OUT / "status.json"
MODULE.MATRIX.SCHEMA = "rv64-v10g-system-product-default-matrix-v2"
MODULE.MATRIX.MATRIX_TITLE = (
    "V10G product-default queue-head=1 SYSTEM matrix v2"
)


if __name__ == "__main__":
    raise SystemExit(MODULE.main())
