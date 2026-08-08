#!/usr/bin/env python3
"""Report exact frozen-vs-live RV64 functional input differences."""

from __future__ import annotations

import json
import pathlib
import sys
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[4]
TOOLS = ROOT / "npc/rv64/eval/ppa/tools"
sys.path.insert(0, str(TOOLS))

import full_core_current_evidence as module_evidence  # noqa: E402
import full_core_functional_evidence as functional_evidence  # noqa: E402


def diff_mapping(label: str, frozen: dict[str, Any], live: dict[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for key in sorted(set(frozen) | set(live)):
        if frozen.get(key) != live.get(key):
            rows.append(
                {
                    "group": label,
                    "key": key,
                    "frozen": frozen.get(key),
                    "live": live.get(key),
                }
            )
    return rows


def main() -> int:
    frozen_path = ROOT / (
        ".github/task-runs/2026-08-07-rv64-v15s-owner-any-live-e7da-a1/"
        "evidence/functional/inputs.pre.json"
    )
    frozen = json.loads(frozen_path.read_text(encoding="utf-8"))
    live = functional_evidence.capture_functional_inputs(
        None, module_evidence.required_tests()
    )
    differences: list[dict[str, Any]] = []
    for key in sorted(set(frozen) | set(live)):
        if key == "groups":
            frozen_groups = frozen.get("groups", {})
            live_groups = live.get("groups", {})
            for group in sorted(set(frozen_groups) | set(live_groups)):
                differences.extend(
                    diff_mapping(
                        group,
                        frozen_groups.get(group, {}),
                        live_groups.get(group, {}),
                    )
                )
        elif key == "toolchain":
            differences.extend(
                diff_mapping(
                    "toolchain", frozen.get("toolchain", {}), live.get("toolchain", {})
                )
            )
        elif frozen.get(key) != live.get(key):
            differences.append(
                {
                    "group": "top-level",
                    "key": key,
                    "frozen": frozen.get(key),
                    "live": live.get(key),
                }
            )
    print(
        json.dumps(
            {
                "schema": "npc-rv64-functional-input-diff-v1",
                "status": "PASS" if not differences else "DRIFT",
                "difference_count": len(differences),
                "differences": differences,
            },
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
    )
    return 0 if not differences else 1


if __name__ == "__main__":
    raise SystemExit(main())
