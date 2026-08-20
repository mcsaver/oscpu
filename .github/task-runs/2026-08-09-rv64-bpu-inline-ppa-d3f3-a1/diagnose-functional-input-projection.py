#!/usr/bin/env python3
"""Print exact frozen/live differences after checker-only input projection."""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from npc.rv64.eval.ppa.tools import full_core_functional_evidence as functional


FROZEN = ROOT / (
    ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-full-core-a1/"
    "evidence/functional/inputs.pre.json"
)


def main() -> None:
    old = functional.execution_relevant_inputs(
        json.loads(FROZEN.read_text(encoding="utf-8"))
    )
    legacy = functional.load_legacy_runner()
    current = functional.execution_relevant_inputs(
        functional.capture_functional_inputs(
            legacy, functional.module_evidence.required_tests()
        )
    )
    for group in sorted(set(old["groups"]) | set(current["groups"])):
        left = old["groups"].get(group, {})
        right = current["groups"].get(group, {})
        for path in sorted(set(left) | set(right)):
            if left.get(path) != right.get(path):
                print(f"GROUP\t{group}\t{path}\t{left.get(path)}\t{right.get(path)}")
    if old.get("toolchain") != current.get("toolchain"):
        print(f"TOOLCHAIN\t{old.get('toolchain')}\t{current.get('toolchain')}")
    old_top = {key: value for key, value in old.items() if key not in {"groups", "toolchain"}}
    current_top = {
        key: value for key, value in current.items()
        if key not in {"groups", "toolchain"}
    }
    if old_top != current_top:
        print(f"TOP\t{old_top}\t{current_top}")


if __name__ == "__main__":
    main()
