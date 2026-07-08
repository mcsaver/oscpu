#!/usr/bin/env python3
"""Check RV64 Yosys macro-boundary contract coverage.

This checker intentionally verifies only the contract surface:
- the spec names every required macro boundary in a populated Markdown table;
- the RTL source tree still contains a module declaration for every boundary;
- when a netlist is provided, the netlist keeps an instance of every boundary.

It does not prove timing, area, or semantic equivalence closure.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


DEFAULT_MODULES = (
    "OooFetchPacketCache",
    "OooDataWordCache",
    "OooFpArithGate",
    "OooBranchDirectionPredictor",
)


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise SystemExit(f"FAIL missing file: {path}")


def markdown_rows(text: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|") or not stripped.endswith("|"):
            continue
        cells = [cell.strip() for cell in stripped.strip("|").split("|")]
        if cells and not all(re.fullmatch(r":?-+:?", cell) for cell in cells):
            rows.append(cells)
    return rows


def find_contract_rows(spec_text: str, modules: tuple[str, ...]) -> dict[str, list[str]]:
    rows = markdown_rows(spec_text)
    by_module: dict[str, list[str]] = {}
    for row in rows:
        if not row:
            continue
        for module in modules:
            if row[0] == module:
                by_module[module] = row
    return by_module


def check_spec(spec_path: Path, modules: tuple[str, ...]) -> None:
    text = read_text(spec_path)
    rows = find_contract_rows(text, modules)
    missing = [module for module in modules if module not in rows]
    if missing:
        raise SystemExit(
            "FAIL spec missing contract table rows: " + ", ".join(missing)
        )

    weak_rows: list[str] = []
    for module, row in rows.items():
        if len(row) < 8:
            weak_rows.append(f"{module}: expected >=8 columns, got {len(row)}")
            continue
        for idx in (2, 4, 5, 6):
            if not row[idx] or row[idx] in {"-", "TBD", "todo"}:
                weak_rows.append(f"{module}: empty/weak field at column {idx + 1}")
    if weak_rows:
        raise SystemExit("FAIL weak contract rows:\n" + "\n".join(weak_rows))

    required_words = ("Timing/area", "Semantic", "Next task", "unknown area")
    missing_words = [word for word in required_words if word not in text]
    if missing_words:
        raise SystemExit(
            "FAIL spec missing required contract vocabulary: "
            + ", ".join(missing_words)
        )

    print(f"PASS spec contract rows modules={len(modules)} path={spec_path}")


def iter_rtl_files(root: Path) -> list[Path]:
    if not root.exists():
        raise SystemExit(f"FAIL missing RTL root: {root}")
    return sorted(
        path
        for path in root.rglob("*")
        if path.suffix in {".v", ".sv", ".svh", ".vh"}
    )


def check_rtl_modules(root: Path, modules: tuple[str, ...]) -> None:
    files = iter_rtl_files(root)
    found: dict[str, Path] = {}
    patterns = {
        module: re.compile(rf"(?m)^\s*module\s+{re.escape(module)}\b")
        for module in modules
    }
    for path in files:
        text = path.read_text(encoding="utf-8", errors="ignore")
        for module, pattern in patterns.items():
            if module not in found and pattern.search(text):
                found[module] = path
    missing = [module for module in modules if module not in found]
    if missing:
        raise SystemExit("FAIL RTL missing modules: " + ", ".join(missing))
    for module in modules:
        print(f"PASS rtl module={module} file={found[module]}")


def check_netlist_instances(netlist: Path, modules: tuple[str, ...]) -> None:
    text = read_text(netlist)
    missing: list[str] = []
    for module in modules:
        pattern = re.compile(rf"(?m)^\s*{re.escape(module)}\s+\S+\s*\(")
        if not pattern.search(text):
            missing.append(module)
    if missing:
        raise SystemExit(
            "FAIL netlist missing macro-boundary instances: " + ", ".join(missing)
        )
    for module in modules:
        print(f"PASS netlist instance module={module} file={netlist}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--spec",
        type=Path,
        default=Path("npc/rv64/design/specs/yosys-macro-boundary-contracts.md"),
    )
    parser.add_argument(
        "--rtl-root",
        type=Path,
        default=Path("npc/rv64/vsrc"),
    )
    parser.add_argument(
        "--netlist",
        type=Path,
        default=Path("npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v"),
    )
    parser.add_argument(
        "--module",
        action="append",
        dest="modules",
        help="Required boundary module. May be repeated.",
    )
    parser.add_argument(
        "--skip-netlist",
        action="store_true",
        help="Only check spec and RTL source declarations.",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    modules = tuple(args.modules) if args.modules else DEFAULT_MODULES
    check_spec(args.spec, modules)
    check_rtl_modules(args.rtl_root, modules)
    if not args.skip_netlist:
        check_netlist_instances(args.netlist, modules)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
