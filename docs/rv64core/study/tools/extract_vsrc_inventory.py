#!/usr/bin/env python3
"""从 vsrc 与 Verilator XML 提取讲义用的模块/文件清册。

该工具不替代人工微架构解释；它负责给出文件全集、module 声明、当前顶层
可达性、直接 parent/child 和时序块数量，帮助审查者发现“编译在册但未实例化”
与“只在仿真层出现”的文件。
"""

from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path


SCRIPT = Path(__file__).resolve()
REPO_ROOT = SCRIPT.parents[4]
VSRC_ROOT = REPO_ROOT / "npc" / "rv64" / "vsrc"

MODULE_RE = re.compile(r"(?m)^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)")
POSEDGE_RE = re.compile(r"\balways\s*@\s*\(\s*posedge\b")


def base_module(name: str) -> str:
    """去掉 Verilator 为参数化模块附加的 __... 派生后缀。"""

    return name.split("__", 1)[0]


def load_hierarchy(xml_paths: list[Path]) -> tuple[
    dict[str, int], dict[str, set[str]], dict[str, set[str]]
]:
    counts: dict[str, int] = defaultdict(int)
    parents: dict[str, set[str]] = defaultdict(set)
    children: dict[str, set[str]] = defaultdict(set)

    for xml_path in xml_paths:
        root = ET.parse(xml_path).getroot()
        # Verilator 把 instance hierarchy 直接按 XML 节点嵌套，必须递归取 cell。
        cells = root.findall(".//cell")
        hierarchy_to_module = {
            cell.attrib["hier"]: base_module(cell.attrib["submodname"])
            for cell in cells
        }
        for cell in cells:
            module = base_module(cell.attrib["submodname"])
            hierarchy = cell.attrib["hier"]
            counts[module] += 1

            parent_hierarchy = hierarchy.rsplit(".", 1)[0] if "." in hierarchy else ""
            while parent_hierarchy and parent_hierarchy not in hierarchy_to_module:
                parent_hierarchy = (
                    parent_hierarchy.rsplit(".", 1)[0]
                    if "." in parent_hierarchy
                    else ""
                )
            if parent_hierarchy:
                parent = hierarchy_to_module[parent_hierarchy]
                parents[module].add(parent)
                children[parent].add(module)

    return counts, parents, children


def source_status(
    path: Path, module: str | None, top_counts: dict[str, int], sim_counts: dict[str, int]
) -> str:
    if module is None:
        if path.suffix in {".vh", ".svh"} or path.name in {
            "define.v",
            "OooSlotFacts.v",
            "OooFpPredicates.v",
            "OooFpRound.v",
        }:
            return "header/include"
        return "document/build"
    if top_counts.get(module):
        return "NpcTop-reachable"
    if sim_counts.get(module):
        return "simulation-only"
    if "debug" in path.parts:
        return "focused-checker"
    return "catalog-only"


def short_list(items: set[str]) -> str:
    return ", ".join(sorted(items)) if items else "-"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--top-xml", type=Path)
    parser.add_argument("--sim-xml", type=Path)
    args = parser.parse_args()

    top_counts, top_parents, top_children = load_hierarchy(
        [args.top_xml] if args.top_xml else []
    )
    sim_counts, sim_parents, sim_children = load_hierarchy(
        [args.sim_xml] if args.sim_xml else []
    )

    all_parents: dict[str, set[str]] = defaultdict(set)
    all_children: dict[str, set[str]] = defaultdict(set)
    for mapping in (top_parents, sim_parents):
        for module, values in mapping.items():
            all_parents[module].update(values)
    for mapping in (top_children, sim_children):
        for module, values in mapping.items():
            all_children[module].update(values)

    print(
        "path\tmodule\tstatus\tNpcTop_instances\tSimTop_instances\t"
        "posedge_blocks\tparents\tchildren"
    )
    for path in sorted(item for item in VSRC_ROOT.rglob("*") if item.is_file()):
        text = path.read_text(encoding="utf-8", errors="replace")
        match = MODULE_RE.search(text)
        module = match.group(1) if match else None
        status = source_status(path, module, top_counts, sim_counts)
        rel = path.relative_to(REPO_ROOT).as_posix()
        module_label = module or "-"
        print(
            "\t".join(
                [
                    rel,
                    module_label,
                    status,
                    str(top_counts.get(module_label, 0)),
                    str(sim_counts.get(module_label, 0)),
                    str(len(POSEDGE_RE.findall(text))),
                    short_list(all_parents[module_label]),
                    short_list(all_children[module_label]),
                ]
            )
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
