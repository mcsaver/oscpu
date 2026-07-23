#!/usr/bin/env python3
"""Assemble current-design V8L holder-lifecycle evidence from raw RTL runs."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


RUN_DIR = pathlib.Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
EVIDENCE = RUN_DIR / "evidence/focused"
BACKEND = ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v"
GATE_TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"

SPEC = importlib.util.spec_from_file_location("v8l_current_rtl_binding", GATE_TOOL)
assert SPEC is not None and SPEC.loader is not None
gate = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = gate
SPEC.loader.exec_module(gate)


MUTATIONS = {
    "dispatch_drop_int_iq_union":
        "FAIL v8l complete mask differs from independent raw IQ scan",
    "dispatch_lane0_raw_index":
        "[CHECK-FAIL] v8g lane0 live PID stalls dispatch0",
    "int_iq_fire_dies_early":
        "[CHECK-FAIL] v8l resident IQ P blocks exact candidate",
    "backend_drop_mem_res_holder":
        "[CHECK-FAIL] v8l memory reservation reaches complete mask",
    "backend_drop_ex0_holder":
        "[CHECK-FAIL] v8l EX0 handoff keeps complete lease",
    "backend_drop_ex1_holder":
        "[CHECK-FAIL] v8l EX1 reaches complete mask",
    "backend_drop_branch_holder":
        "[CHECK-FAIL] v8l branch packet reaches complete mask",
    "backend_capture_ignores_tracker_ready":
        "[CHECK-FAIL] v8l tracker-backpressure blocks capture",
    "backend_iq_pop_ignores_tracker_ready":
        "[CHECK-FAIL] v8l tracker-backpressure blocks IQ pop",
}


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative(path: pathlib.Path) -> str:
    return path.resolve(strict=True).relative_to(ROOT.resolve()).as_posix()


def require_marker(path: pathlib.Path, marker: str) -> None:
    text = path.read_text(encoding="utf-8")
    if marker not in text:
        raise RuntimeError(f"missing marker {marker!r} in {relative(path)}")


def raw_entry(path: pathlib.Path) -> dict[str, str]:
    if path.is_symlink() or not path.is_file():
        raise RuntimeError(f"raw evidence is not a regular file: {path}")
    return {"path": relative(path), "sha256": sha256(path)}


def normalized_entry(path: pathlib.Path, output: pathlib.Path) -> dict[str, str]:
    """Bind a log after replacing only the runner-owned random temp root."""
    text = path.read_text(encoding="utf-8")
    normalized = re.sub(
        r"/tmp/v8l-global-lease\.[A-Za-z0-9]+",
        "<V8L_TEMP>",
        text,
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(normalized, encoding="utf-8")
    return raw_entry(output)


def main() -> int:
    rtl_sha, rtl_files = gate.rtl_binding(ROOT)
    if not rtl_files:
        raise RuntimeError("canonical RTL source set is empty")
    design_id = f"sha256:{rtl_sha}"

    dispatch_log = EVIDENCE / (
        "baseline-release-dispatch-focus/logs/tb_ooo_dispatch_backend.log")
    backend_log = EVIDENCE / (
        "baseline-release-backend-focus/logs/tb_ooo_int_backend.log")
    legacy_log = EVIDENCE / (
        "baseline-release-legacy-v8g/logs/tb_ooo_int_backend.log")
    positive_requirements = (
        (dispatch_log, "[V8L-INTIQ-DEATH-EDGE]"),
        (dispatch_log, "[V8L-FINITE-GENERATION-WRAP]"),
        (backend_log, "[V8L-TRANSIENT-HOLDER-CENSUS]"),
        (backend_log, "[V8L-TRACKER-BACKPRESSURE]"),
        (legacy_log, "[V8G-MEM-TRACKER-QUARANTINE]"),
    )
    for path, marker in positive_requirements:
        require_marker(path, marker)
        require_marker(path, "[RESULT] PASS")

    backend_text = BACKEND.read_text(encoding="utf-8")
    for label in (
        "[V8L-MEM-HANDOFF-BACKPRESSURE]",
        "[V8L-MEM-INDIRECT-TRACKER]",
    ):
        if label not in backend_text:
            raise RuntimeError(f"production RTL assertion label is missing: {label}")

    summary_log = EVIDENCE / "mutation-summary.log"
    summary_text = summary_log.read_text(encoding="utf-8")
    mutation_records: list[dict[str, Any]] = []
    for name, consequence in MUTATIONS.items():
        expected = (
            f"[V8L-MUTATION][PASS] name={name} compile=PASS "
            f"consequence={consequence}")
        if summary_text.splitlines().count(expected) != 1:
            raise RuntimeError(f"mutation summary does not contain one exact row: {name}")
        mutator_log = EVIDENCE / f"mutation-{name}.mutator.log"
        make_log = EVIDENCE / f"mutation-{name}.make.log"
        require_marker(mutator_log, "[V8L-MUTATOR][PASS]")
        require_marker(make_log, "[MAKE-RC]")
        if "[MAKE-RC] 0" in make_log.read_text(encoding="utf-8"):
            raise RuntimeError(f"semantic mutation was not rejected: {name}")
        mutation_records.append({
            "name": name,
            "compiled": True,
            "rejected": True,
            "consequence": consequence,
            "raw_mutator_log": relative(mutator_log),
            "raw_simulation_log": relative(make_log),
            "mutator_log": normalized_entry(
                mutator_log,
                EVIDENCE / f"normalized/mutation-{name}.mutator.log",
            ),
            "simulation_log": normalized_entry(
                make_log,
                EVIDENCE / f"normalized/mutation-{name}.make.log",
            ),
        })

    mutation_value = {
        "schema": "npc-rv64-holder-lifecycle-mutations-v1",
        "design_id": design_id,
        "compile_success": len(mutation_records),
        "rejected": len(mutation_records),
        "mutations": mutation_records,
    }
    mutation_path = EVIDENCE / "mutation-summary.json"
    mutation_path.write_text(
        json.dumps(mutation_value, ensure_ascii=False, allow_nan=False, indent=2)
        + "\n",
        encoding="utf-8",
    )

    sources = {
        "dispatch": normalized_entry(
            dispatch_log, EVIDENCE / "normalized/baseline-release-dispatch.log"),
        "backend": normalized_entry(
            backend_log, EVIDENCE / "normalized/baseline-release-backend.log"),
        "legacy_memory": normalized_entry(
            legacy_log, EVIDENCE / "normalized/baseline-release-legacy-v8g.log"),
        "mutation_summary": raw_entry(mutation_path),
        "production_rtl": raw_entry(BACKEND),
    }
    lines = [
        "schema=npc-rv64-holder-lifecycle-log-v1",
        f"design_id={design_id}",
        "canonical_command=make -C npc/rv64 check-global-producer-no-live-reuse",
        "V8L-INTIQ-DEATH-EDGE PASS",
        "V8L-FINITE-GENERATION-WRAP PASS",
        "V8L-TRANSIENT-HOLDER-CENSUS PASS",
        "V8L-MEM-HANDOFF-BACKPRESSURE PASS",
        "V8L-MEM-INDIRECT-TRACKER PASS",
        f"compile_success_mutations={len(mutation_records)}",
        f"rejected_mutations={len(mutation_records)}",
    ]
    for label, entry in sorted(sources.items()):
        lines.append(
            f"artifact.{label}.path={entry['path']} sha256={entry['sha256']}")
    lifecycle_path = EVIDENCE / "holder-lifecycle.log"
    lifecycle_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(
        "[V8L-CENSUS-EVIDENCE][PASS] "
        f"design_id={design_id} mutations={len(mutation_records)}/{len(MUTATIONS)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
