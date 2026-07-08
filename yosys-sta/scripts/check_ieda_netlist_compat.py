#!/usr/bin/env python3
"""Check that a Yosys netlist is acceptable for the current iEDA parser.

This is a syntax-surface preflight, not a timing check. It catches simulation
or formal side-effect cells that Yosys may keep for debug assertions but iEDA
cannot parse or time as hardware.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


FORBIDDEN_PATTERNS = {
    "defparam": re.compile(r"^\s*defparam\b", re.MULTILINE),
    "parameterized_instance": re.compile(
        r"^\s*(?:\\?[A-Za-z_][A-Za-z0-9_$\\.]*)\s*#\s*\(",
        re.MULTILINE,
    ),
    "$print": re.compile(r"\\\$print\b|\$print\b"),
    "$assert": re.compile(r"\\\$assert\b|\$assert\b"),
    "$assume": re.compile(r"\\\$assume\b|\$assume\b"),
    "$cover": re.compile(r"\\\$cover\b|\$cover\b"),
    "$check": re.compile(r"\\\$check\b|\$check\b"),
}


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "netlist",
        type=Path,
        nargs="?",
        default=Path("npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v"),
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        text = args.netlist.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise SystemExit(f"FAIL missing netlist: {args.netlist}")

    failures = []
    for name, pattern in FORBIDDEN_PATTERNS.items():
        count = len(pattern.findall(text))
        if count:
            failures.append(f"{name}={count}")

    if failures:
        raise SystemExit(
            "FAIL iEDA netlist compatibility "
            f"netlist={args.netlist} forbidden=" + ", ".join(failures)
        )

    print(
        "PASS iEDA netlist compatibility "
        f"netlist={args.netlist} forbidden=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
