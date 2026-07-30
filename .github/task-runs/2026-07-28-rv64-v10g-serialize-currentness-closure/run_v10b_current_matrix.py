#!/usr/bin/env python3
"""Replay the complete V10B SYSTEM assert/release matrix at live 5f9dd."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
BASE = (
    RUN_DIR.parent
    / "2026-07-27-rv64-v10b-serialized-system-post-fire"
    / "run-v10b-focused-matrix-v3.py"
)
SPEC = importlib.util.spec_from_file_location("v10b_matrix_v3_for_v10g", BASE)
if SPEC is None or SPEC.loader is None:
    raise SystemExit(f"cannot load V10B matrix: {BASE}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)

MATRIX = MODULE.MATRIX
MATRIX.OUT = RUN_DIR / "system-current-matrix"
MATRIX.SUMMARY = MATRIX.OUT / "summary.json"
MATRIX.STATUS = MATRIX.OUT / "status.json"
MATRIX.SCHEMA = "rv64-v10g-system-current-matrix-v1"
MATRIX.MATRIX_TITLE = "V10G live-design SYSTEM matrix"


if __name__ == "__main__":
    raise SystemExit(MATRIX.main())

