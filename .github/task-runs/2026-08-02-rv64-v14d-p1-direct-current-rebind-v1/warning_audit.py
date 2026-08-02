#!/usr/bin/env python3
"""Fail-closed classifier for current RV64 positive-test Icarus warnings."""

from __future__ import annotations

import collections
import pathlib
import re
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
VSRC = ROOT / "npc/rv64/vsrc"
ROOT_PREFIX = ROOT.as_posix() + "/"
FAIL_MARKERS = ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:")
TIMEUNIT_HEADER = "warning: Some design elements have no explicit time unit and/or"
TIMEUNIT_PRECISION = "       : time precision. This may cause confusing timing results."
TIMEUNIT_AFFECTED = "       : Affected design elements are:"
TIMEUNIT_MODULE = re.compile(
    r"^       :   -- module ([A-Za-z_][A-Za-z0-9_$]*) declared here: "
    r"(/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/[A-Za-z0-9_./-]+):([0-9]+)$"
)
ARRAY_SENSITIVITY = re.compile(
    r"^(/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/[A-Za-z0-9_./-]+):"
    r"([0-9]+): warning: @\* is sensitive to all ([0-9]+) words in array "
    r"'([A-Za-z_][A-Za-z0-9_$]*)'\.$"
)
PMP_OOB = (
    "/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: "
    "warning: returning 'bx for out of bounds array access entry_addr_w[-1]."
)
DANGLING_PORTS = {
    "tests/tb_ooo_dispatch_backend.sv:154: warning: Instantiating module "
    "OooDispatchBackend with dangling input port 222 "
    "(pending_csr_owner_valid_i) floating.",
    "tests/tb_ooo_dispatch_backend.sv:154: warning: Instantiating module "
    "OooDispatchBackend with dangling input port 223 "
    "(pending_csr_owner_producer_id_i) floating.",
}


def current_source_line(path_text: str, line_number: int) -> str | None:
    path = pathlib.Path(path_text).resolve()
    if not path.is_relative_to(VSRC) or not path.is_file():
        return None
    lines = path.read_text(encoding="utf-8").splitlines()
    if line_number < 1 or line_number > len(lines):
        return None
    return lines[line_number - 1]


def classify_warning_line(line: str) -> str | None:
    if line == PMP_OOB:
        return "ICARUS_CONSTANT_UNSELECTED_GENVAR_ARRAY_INDEX"
    if line in DANGLING_PORTS:
        return "ICARUS_EXACT_TESTBENCH_DANGLING_OPTIONAL_INPUT"
    match = ARRAY_SENSITIVITY.fullmatch(line)
    if match is None:
        return None
    path_text, line_text, words_text, array_name = match.groups()
    line_number = int(line_text)
    words = int(words_text)
    source_line = current_source_line(path_text, line_number)
    if (
        source_line is None
        or words not in {1, 2, 3, 4, 8, 16, 32}
        or re.search(rf"\b{re.escape(array_name)}\b", source_line) is None
    ):
        return None
    return "ICARUS_CURRENT_RTL_ARRAY_SENSITIVITY"


def validate_timeunit_block(lines: list[str], index: int) -> bool:
    if index + 3 >= len(lines):
        return False
    if lines[index + 1] != TIMEUNIT_PRECISION or lines[index + 2] != TIMEUNIT_AFFECTED:
        return False
    match = TIMEUNIT_MODULE.fullmatch(lines[index + 3])
    if match is None:
        return False
    module_name, path_text, line_text = match.groups()
    source_line = current_source_line(path_text, int(line_text))
    return source_line is not None and re.search(
        rf"\bmodule\s+{re.escape(module_name)}\b", source_line
    ) is not None


def audit(logs: list[pathlib.Path]) -> dict[str, Any]:
    warning_lines: list[str] = []
    categories: collections.Counter[str] = collections.Counter()
    per_log: list[dict[str, Any]] = []
    for path in logs:
        lines = path.read_text(encoding="utf-8").splitlines()
        if any(marker in "\n".join(lines) for marker in FAIL_MARKERS):
            raise ValueError(f"positive current RTL log contains failure marker: {path}")
        local_count = 0
        for index, line in enumerate(lines):
            if "warning:" not in line.lower():
                continue
            warning_lines.append(line)
            local_count += 1
            if line == TIMEUNIT_HEADER:
                if not validate_timeunit_block(lines, index):
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
        "classification": "CURRENT_SOURCE_BOUND_ICARUS_DIAGNOSTICS",
    }
