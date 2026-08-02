#!/usr/bin/env python3
"""Inventory unique warning lines not handled by the current exact classifier."""

from __future__ import annotations

import argparse
import collections
import importlib.util
import json
import pathlib
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ADAPTER = HERE / "f0-warning-audit.py"


def load_adapter() -> Any:
    spec = importlib.util.spec_from_file_location("v14e_f0_warning_gap_adapter", ADAPTER)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load F0 warning adapter")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--module-result", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    result_path = args.module_result.resolve(strict=True)
    result_path.relative_to(HERE / "evidence")
    output = args.output.resolve()
    output.relative_to(HERE)
    if output.exists():
        raise RuntimeError("refusing to replace warning-gap inventory")
    result = json.loads(result_path.read_text(encoding="utf-8"))
    adapter = load_adapter()
    base = adapter.load_base()
    unknown: collections.Counter[str] = collections.Counter()
    total = 0
    classified = 0
    timeunit = 0
    logs = result.get("tests", {}).get("logs", {})
    if not isinstance(logs, dict):
        raise RuntimeError("module log inventory absent")
    for record in logs.values():
        path = (ROOT / str(record["path"])).resolve(strict=True)
        lines = path.read_text(encoding="utf-8").splitlines()
        for line in lines:
            if "warning:" not in line.lower():
                continue
            total += 1
            canonical, _ = adapter.canonicalize_line(line)
            if canonical == base.TIMEUNIT_HEADER:
                timeunit += 1
                classified += 1
            elif adapter.classify_extended_warning_line(canonical, base) is not None:
                classified += 1
            else:
                unknown[line] += 1
    payload = {
        "schema": "rv64-v14e-f0-warning-gap-inventory-v1",
        "design_id": result.get("design_id"),
        "total_warning_lines": total,
        "already_classified": classified,
        "unclassified": sum(unknown.values()),
        "unique_unclassified": len(unknown),
        "timeunit_blocks": timeunit,
        "lines": [
            {"line": line, "count": count}
            for line, count in sorted(unknown.items())
        ],
    }
    output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        "[V14E-F0-WARNING-GAPS] "
        f"total={total} classified={classified} unclassified={payload['unclassified']} "
        f"unique_unclassified={payload['unique_unclassified']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14E-F0-WARNING-GAPS][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
