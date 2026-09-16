#!/usr/bin/env python3

"""Validate public start/end register identities in an OpenSTA top-N report."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
from typing import Any


HEADER_RE = re.compile(r"^(Startpoint|Endpoint): ([A-Za-z0-9_]+)$")
OPAQUE_RE = re.compile(r"^_[0-9]+_")
REGISTER_DESCRIPTION = (
    "(rising edge-triggered flip-flop clocked by core_clock)"
)


class TraceabilityError(ValueError):
    """The timing report is incomplete or contains opaque/non-register names."""


def inspect_report(path: pathlib.Path, expected_paths: int = 40) -> dict[str, Any]:
    if expected_paths <= 0:
        raise TraceabilityError("expected path count must be positive")
    lines = path.read_text(encoding="utf-8").splitlines()
    names: dict[str, list[str]] = {"Startpoint": [], "Endpoint": []}
    described = 0
    for index, line in enumerate(lines):
        match = HEADER_RE.fullmatch(line)
        if match is None:
            continue
        kind, name = match.groups()
        names[kind].append(name)
        if index + 1 >= len(lines) or lines[index + 1].strip() != REGISTER_DESCRIPTION:
            raise TraceabilityError(
                f"{kind.lower()} {name} lacks the core_clock register description"
            )
        described += 1

    startpoints = names["Startpoint"]
    endpoints = names["Endpoint"]
    public_starts = [
        name for name in startpoints if name.startswith("u_core_") and "_DFF" in name
    ]
    public_ends = [
        name for name in endpoints if name.startswith("u_core_") and "_DFF" in name
    ]
    opaque_starts = [name for name in startpoints if OPAQUE_RE.match(name)]
    opaque_ends = [name for name in endpoints if OPAQUE_RE.match(name)]
    errors: list[str] = []
    if len(startpoints) != expected_paths:
        errors.append(f"startpoints={len(startpoints)} expected={expected_paths}")
    if len(endpoints) != expected_paths:
        errors.append(f"endpoints={len(endpoints)} expected={expected_paths}")
    if len(public_starts) != expected_paths:
        errors.append(
            f"public_flat_startpoints={len(public_starts)} expected={expected_paths}"
        )
    if len(public_ends) != expected_paths:
        errors.append(
            f"public_flat_endpoints={len(public_ends)} expected={expected_paths}"
        )
    if opaque_starts:
        errors.append(f"opaque_startpoints={len(opaque_starts)} expected=0")
    if opaque_ends:
        errors.append(f"opaque_endpoints={len(opaque_ends)} expected=0")
    if described != 2 * expected_paths:
        errors.append(
            f"clocked_register_descriptions={described} expected={2 * expected_paths}"
        )
    return {
        "status": "PASS" if not errors else "FAIL",
        "startpoints": len(startpoints),
        "endpoints": len(endpoints),
        "public_flat_startpoints": len(public_starts),
        "public_flat_endpoints": len(public_ends),
        "opaque_startpoints": len(opaque_starts),
        "opaque_endpoints": len(opaque_ends),
        "clocked_register_descriptions": described,
        "errors": errors,
    }


def write_result(path: pathlib.Path, result: dict[str, Any]) -> None:
    fields = (
        "status",
        "startpoints",
        "endpoints",
        "public_flat_startpoints",
        "public_flat_endpoints",
        "opaque_startpoints",
        "opaque_endpoints",
        "clocked_register_descriptions",
    )
    text = "".join(f"{field}={result[field]}\n" for field in fields)
    for error in result["errors"]:
        text += f"error={error}\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(text, encoding="utf-8")
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--expected-paths", type=int, default=40)
    args = parser.parse_args()
    try:
        result = inspect_report(args.report.resolve(), args.expected_paths)
        write_result(args.output.resolve(), result)
    except (OSError, UnicodeDecodeError, TraceabilityError) as error:
        print(f"[TRACEABLE-PATH-INVENTORY][FAIL] {error}", file=sys.stderr)
        return 1
    if result["status"] != "PASS":
        print(
            "[TRACEABLE-PATH-INVENTORY][FAIL] " + "; ".join(result["errors"]),
            file=sys.stderr,
        )
        return 1
    print(
        "[TRACEABLE-PATH-INVENTORY][PASS] "
        f"paths={args.expected_paths} public_registers={2 * args.expected_paths} "
        "opaque=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
