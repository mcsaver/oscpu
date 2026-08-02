#!/usr/bin/env python3
"""Exact path-representation adapter for the current RTL warning classifier."""

from __future__ import annotations

import collections
import functools
import hashlib
import importlib.util
import pathlib
import re
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE_CHECKER = ROOT / (
    ".github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1/"
    "warning_audit.py"
)
NORMALIZED_PREFIX = "<REPO>/npc/rv64/vsrc/"
CANONICAL_PREFIX = (ROOT / "npc/rv64/vsrc").as_posix() + "/"
TESTBENCH = ROOT / "npc/rv64/testbench"
TIMESCALE_INHERITED = re.compile(
    r"^(.+):([0-9]+): warning: timescale for "
    r"([A-Za-z_][A-Za-z0-9_$]*) inherited from another file\.$"
)
DANGLING_INPUT = re.compile(
    r"^tests/([A-Za-z0-9_./-]+\.sv):([0-9]+): warning: Instantiating module "
    r"([A-Za-z_][A-Za-z0-9_$]*) with dangling input port ([0-9]+) "
    r"\(([A-Za-z_][A-Za-z0-9_$]*)\) floating\.$"
)
PORT_WIDTH = re.compile(
    r"^tests/([A-Za-z0-9_./-]+\.sv):([0-9]+): warning: Port ([0-9]+) "
    r"\(([A-Za-z_][A-Za-z0-9_$]*)\) of ([A-Za-z_][A-Za-z0-9_$]*) "
    r"expects ([0-9]+) bits, got ([0-9]+)\.$"
)


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def load_base() -> Any:
    spec = importlib.util.spec_from_file_location("v14e_f0_base_warning_audit", BASE_CHECKER)
    if spec is None or spec.loader is None:
        raise ValueError("cannot load V14D warning classifier")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def canonicalize_line(line: str) -> tuple[str, bool]:
    count = line.count(NORMALIZED_PREFIX)
    if count == 0:
        return line, False
    if count != 1:
        raise ValueError(f"ambiguous normalized RTL path representation: {line}")
    return line.replace(NORMALIZED_PREFIX, CANONICAL_PREFIX, 1), True


def source_line(path: pathlib.Path, line_number: int) -> str | None:
    resolved = path.resolve()
    if (
        not resolved.is_relative_to(ROOT)
        or not resolved.is_file()
        or line_number < 1
    ):
        return None
    lines = resolved.read_text(encoding="utf-8").splitlines()
    return lines[line_number - 1] if line_number <= len(lines) else None


def testbench_path(path_text: str) -> pathlib.Path | None:
    path = (TESTBENCH / path_text).resolve()
    if not path.is_relative_to(TESTBENCH) or not path.is_file():
        return None
    return path


@functools.lru_cache(maxsize=None)
def module_source(module_name: str) -> pathlib.Path | None:
    declaration = re.compile(rf"^\s*module\s+{re.escape(module_name)}\b", re.MULTILINE)
    matches = [
        path
        for path in (ROOT / "npc/rv64/vsrc").rglob("*")
        if path.is_file()
        and path.suffix.lower() in {".v", ".sv"}
        and declaration.search(path.read_text(encoding="utf-8"))
    ]
    return matches[0] if len(matches) == 1 else None


def instance_is_current(path: pathlib.Path, line_number: int, module_name: str) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines()
    if line_number < 1 or line_number > len(lines):
        return False
    start = max(0, line_number - 33)
    context = "\n".join(lines[start:line_number])
    return re.search(rf"\b{re.escape(module_name)}\b", context) is not None


def module_port_is_current(module_name: str, port_name: str, direction: str) -> bool:
    path = module_source(module_name)
    if path is None:
        return False
    pattern = re.compile(
        rf"^\s*{re.escape(direction)}\b[^\n;]*\b{re.escape(port_name)}\b",
        re.MULTILINE,
    )
    return pattern.search(path.read_text(encoding="utf-8")) is not None


def classify_extended_warning_line(line: str, base: Any) -> str | None:
    category = base.classify_warning_line(line)
    if category is not None:
        return category
    match = TIMESCALE_INHERITED.fullmatch(line)
    if match is not None:
        path_text, line_text, module_name = match.groups()
        if path_text.startswith("tests/"):
            path = testbench_path(path_text)
        else:
            path = pathlib.Path(path_text).resolve()
            if not path.is_relative_to(ROOT / "npc/rv64/vsrc"):
                path = None
        line_number = int(line_text)
        current = source_line(path, line_number) if path is not None else None
        if current is not None and re.search(
            rf"\bmodule\s+{re.escape(module_name)}\b", current
        ):
            return "ICARUS_CURRENT_SOURCE_INHERITED_TIMESCALE"
        return None
    match = DANGLING_INPUT.fullmatch(line)
    if match is not None:
        path_text, line_text, module_name, port_number, port_name = match.groups()
        path = testbench_path("tests/" + path_text)
        if (
            path is not None
            and int(port_number) > 0
            and instance_is_current(path, int(line_text), module_name)
            and module_port_is_current(module_name, port_name, "input")
        ):
            return "ICARUS_CURRENT_TESTBENCH_DANGLING_INPUT"
        return None
    match = PORT_WIDTH.fullmatch(line)
    if match is not None:
        path_text, line_text, port_number, port_name, module_name, expected, observed = match.groups()
        path = testbench_path("tests/" + path_text)
        if (
            path is not None
            and int(port_number) > 0
            and int(expected) > 0
            and int(observed) > 0
            and int(expected) != int(observed)
            and instance_is_current(path, int(line_text), module_name)
            and module_port_is_current(module_name, port_name, "output")
        ):
            return "ICARUS_CURRENT_TESTBENCH_OUTPUT_WIDTH_DIAGNOSTIC"
        return None
    return None


def audit(logs: list[pathlib.Path]) -> dict[str, Any]:
    base = load_base()
    warning_lines: list[str] = []
    canonical_lines: list[str] = []
    categories: collections.Counter[str] = collections.Counter()
    representations: collections.Counter[str] = collections.Counter()
    per_log: list[dict[str, Any]] = []
    for path in logs:
        lines = path.read_text(encoding="utf-8").splitlines()
        if any(marker in "\n".join(lines) for marker in base.FAIL_MARKERS):
            raise ValueError(f"positive current RTL log contains failure marker: {path}")
        local_count = 0
        for index, line in enumerate(lines):
            if "warning:" not in line.lower():
                continue
            canonical, adapted = canonicalize_line(line)
            warning_lines.append(line)
            canonical_lines.append(canonical)
            local_count += 1
            representations["NORMALIZED_REPO_PREFIX" if adapted else "CANONICAL_OR_RELATIVE"] += 1
            if canonical == base.TIMEUNIT_HEADER:
                block = [canonical]
                for offset in (1, 2, 3):
                    if index + offset >= len(lines):
                        raise ValueError(f"truncated Icarus timeunit warning block: {path}")
                    block.append(canonicalize_line(lines[index + offset])[0])
                if not base.validate_timeunit_block(block, 0):
                    raise ValueError(f"malformed Icarus timeunit warning block: {path}")
                categories["ICARUS_EXACT_TIMEUNIT_DECLARATION_DIAGNOSTIC"] += 1
                continue
            category = classify_extended_warning_line(canonical, base)
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
        "unique_canonical_lines": sorted(set(canonical_lines)),
        "category_counts": dict(sorted(categories.items())),
        "path_representation_counts": dict(sorted(representations.items())),
        "per_log": per_log,
        "unexplained_warning_count": 0,
        "assertion_failure_observed": False,
        "classification": "CURRENT_SOURCE_BOUND_ICARUS_DIAGNOSTICS_WITH_EXACT_PATH_ADAPTER",
        "base_checker": {
            "path": BASE_CHECKER.relative_to(ROOT).as_posix(),
            "sha256": digest(BASE_CHECKER),
        },
    }
