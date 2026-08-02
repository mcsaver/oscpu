#!/usr/bin/env python3
"""STORE-BRESP positive-log warning classifier with exact V13R TB binding."""

from __future__ import annotations

import collections
import pathlib
from typing import Any

import warning_audit as base


ROOT = base.ROOT
V13R_OPTIONAL_IFU_AD = (
    "./tests/tb_ooo_int_backend_v8x_bridge.svh:130: warning: Instantiating "
    "module OooDualMemBridgeWrapper with dangling input port 7 "
    "(ifu_ad_update_invalidate_all_i) floating."
)


def classify_warning_line(line: str) -> str | None:
    category = base.classify_warning_line(line)
    if category is not None:
        return category
    if line == V13R_OPTIONAL_IFU_AD:
        return "ICARUS_EXACT_V13R_OPTIONAL_IFU_AD_INPUT"
    return None


def audit(logs: list[pathlib.Path]) -> dict[str, Any]:
    warning_lines: list[str] = []
    categories: collections.Counter[str] = collections.Counter()
    per_log: list[dict[str, Any]] = []
    for path in logs:
        lines = path.read_text(encoding="utf-8").splitlines()
        joined = "\n".join(lines)
        if any(marker in joined for marker in base.FAIL_MARKERS):
            raise ValueError(f"positive STORE-BRESP log contains failure marker: {path}")
        local_count = 0
        for index, line in enumerate(lines):
            if "warning:" not in line.lower():
                continue
            warning_lines.append(line)
            local_count += 1
            if line == base.TIMEUNIT_HEADER:
                if not base.validate_timeunit_block(lines, index):
                    raise ValueError(f"malformed Icarus timeunit warning block: {path}")
                categories["ICARUS_EXACT_TIMEUNIT_DECLARATION_DIAGNOSTIC"] += 1
                continue
            category = classify_warning_line(line)
            if category is None:
                raise ValueError(f"unexplained current RTL compile warning: {line}")
            categories[category] += 1
        per_log.append(
            {
                "path": path.resolve().relative_to(ROOT).as_posix(),
                "warning_count": local_count,
            }
        )
    return {
        "status": "EXPLAINED",
        "count": len(warning_lines),
        "unique_lines": sorted(set(warning_lines)),
        "category_counts": dict(sorted(categories.items())),
        "per_log": per_log,
        "unexplained_warning_count": 0,
        "assertion_failure_observed": False,
        "classification": "STORE_CURRENT_SOURCE_AND_EXACT_TB_BOUND_ICARUS_DIAGNOSTICS",
    }
