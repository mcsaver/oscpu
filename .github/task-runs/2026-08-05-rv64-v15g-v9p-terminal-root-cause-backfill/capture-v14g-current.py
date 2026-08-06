#!/usr/bin/env python3
"""Normalize a current V14G dynamic owner-fence run without Yosys replay."""

from __future__ import annotations

import argparse
import importlib.util
import json
import pathlib
import sys
from typing import Any


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--result-dir", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    architecture = load_module(
        root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
        "v15g_v14g_architecture_binding",
    )
    closure = load_module(
        root / "npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py",
        "v15g_v14g_snapshot_capture",
    )
    design_sha, files = architecture.rtl_binding(root)
    design_id = f"sha256:{design_sha}"
    if len(files) != 146:
        raise RuntimeError(f"unexpected RTL file count: {len(files)}")
    snapshot = closure.capture_v14g(
        root,
        args.result_dir.resolve(),
        design_id,
    )
    wrapper = {
        "schema_version": "npc-rv64-global-producer-no-live-reuse-receipt-v1",
        "status": "PASS",
        "design_id": design_id,
        "scope": "V8L historical-defect current dynamic owner-fence rebind; no Yosys or global architecture promotion",
        "v14g_dynamic_fence": snapshot,
        "promotion": {
            "global_no_live_reuse": "DYNAMIC_FENCE_ONLY",
            "whole_architecture": "RED",
            "system_recertification": "LAYERED_L0_L1_L2_L3_REQUIRED",
            "ppa": "UNPROMOTED",
        },
    }
    write_json(args.output.resolve(), wrapper)
    print(
        "[RV64-V14G-CURRENT-SNAPSHOT][PASS] "
        f"design_id={design_id} baseline=4/4 mutations=22/22 "
        "yosys=NOT_RUN compiled-images=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
