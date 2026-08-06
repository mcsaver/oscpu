#!/usr/bin/env python3
"""Build a compact current-design V8L focused result from retained logs."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


MUTATIONS = {
    "dispatch-drop-int-iq-union": "FAIL v8l complete mask differs from independent raw IQ scan",
    "dispatch-lane0-raw-index": "[CHECK-FAIL] v8g lane0 live PID stalls dispatch0",
    "int-iq-fire-dies-early": "[CHECK-FAIL] v8l resident IQ P blocks exact candidate",
    "backend-drop-mem-res-holder": "[CHECK-FAIL] v8l memory reservation reaches complete mask",
    "backend-drop-ex0-holder": "[CHECK-FAIL] v8l EX0 handoff keeps complete lease",
    "backend-drop-ex1-holder": "[CHECK-FAIL] v8l EX1 reaches complete mask",
    "backend-drop-branch-holder": "[CHECK-FAIL] v8l branch packet reaches complete mask",
    "backend-capture-ignores-tracker-ready": "[CHECK-FAIL] v8l tracker-backpressure blocks capture",
    "backend-iq-pop-ignores-tracker-ready": "[CHECK-FAIL] v8l tracker-backpressure blocks IQ pop",
}
BASELINES = {
    "dispatch-assert": "tb_ooo_dispatch_backend",
    "dispatch-release": "tb_ooo_dispatch_backend",
    "backend-assert": "tb_ooo_int_backend",
    "backend-release": "tb_ooo_int_backend",
}


def sha256_file(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def artifact(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    path = path.resolve(strict=True)
    return {
        "path": path.relative_to(root).as_posix(),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--evidence", type=pathlib.Path, required=True)
    parser.add_argument("--runtime", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    evidence = args.evidence.resolve()
    runtime = args.runtime.resolve()
    architecture = load_module(
        root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
        "v15g_v8l_architecture_binding",
    )
    digest, sources = architecture.rtl_binding(root)
    if len(sources) != 146:
        raise RuntimeError(f"unexpected RTL file count: {len(sources)}")
    baselines = []
    for name, test in BASELINES.items():
        log = evidence / "baselines" / name / "logs" / f"{test}.log"
        text = log.read_text(encoding="utf-8", errors="replace")
        if text.count("[RESULT] PASS") != 1 or "[RESULT] FAIL" in text:
            raise RuntimeError(f"baseline did not pass exactly once: {name}")
        baselines.append({"name": name, "test": test, "result": "PASS", "log": artifact(root, log)})
    mutations = []
    for name, marker in MUTATIONS.items():
        case = evidence / "mutations" / name
        log_files = list((case / "logs").glob("*.log"))
        if len(log_files) != 1:
            raise RuntimeError(f"mutation log inventory drift: {name}")
        log = log_files[0]
        text = log.read_text(encoding="utf-8", errors="replace")
        if marker not in text or "[RESULT] FAIL" not in text:
            raise RuntimeError(f"mutation rejection marker is absent: {name}")
        make_log = case / "make.log"
        make_text = make_log.read_text(encoding="utf-8", errors="replace")
        match = re.search(r"^\[MAKE-RC\] (\d+)$", make_text, re.M)
        if match is None or int(match.group(1)) == 0:
            raise RuntimeError(f"mutation did not fail its focused oracle: {name}")
        rtl_files = [path for path in case.glob("*.v") if path.is_file()]
        if len(rtl_files) != 1:
            raise RuntimeError(f"mutation RTL inventory drift: {name}")
        image = runtime / name / f"{log.stem}.vvp"
        if not image.is_file() or image.stat().st_size == 0:
            raise RuntimeError(f"compile-success image is absent: {name}")
        mutations.append(
            {
                "name": name,
                "test": log.stem,
                "result": "REJECTED_COMPILE_SUCCESS_VARIANT",
                "make_return_code": int(match.group(1)),
                "expected_marker": marker,
                "mutated_rtl": artifact(root, rtl_files[0]),
                "log": artifact(root, log),
                "make_log": artifact(root, make_log),
                "compiled_image": {
                    "sha256": sha256_file(image),
                    "size_bytes": image.stat().st_size,
                    "retained": False,
                },
            }
        )
    production = {}
    for name, relative in {
        "issue_queue": "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
        "dispatch_backend": "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
        "int_backend": "npc/rv64/vsrc/execute/OooIntBackend.v",
    }.items():
        production[name] = artifact(root, root / relative)
    payload = {
        "schema": "npc-rv64-v8l-current-focused-v1",
        "status": "PASS",
        "design_id": f"sha256:{digest}",
        "rtl_file_count": len(sources),
        "production_sources": production,
        "baselines": baselines,
        "compile_success_mutations": mutations,
        "counts": {"baselines_passed": 4, "baselines_required": 4, "mutations_rejected": 9, "mutations_required": 9},
        "assertion_modes": ["assert", "release"],
        "cleanup": {"compiled_images_retained": 0, "negative_rtl_sources_retained": 9},
        "scope": "V8L force/release shadow current-design focused rebind; no global holder, architecture, system or PPA promotion",
    }
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(output.suffix + ".tmp")
    temporary.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(output)
    print(
        "[RV64-V8L-CURRENT][PASS] "
        f"design_id=sha256:{digest} baselines=4/4 mutations=9/9 compiled-images=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
