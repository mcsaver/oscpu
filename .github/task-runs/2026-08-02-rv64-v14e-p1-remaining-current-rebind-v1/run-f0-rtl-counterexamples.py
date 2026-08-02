#!/usr/bin/env python3
"""Run the F0-G1 focused release and three production-RTL counterexamples."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import shutil
import sys
from typing import Any


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DESIGN_ID = "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
LEGACY_RUNNER = ROOT / (
    ".github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design/"
    "run-v9l-rtl-verification-variants.py"
)


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def artifact(path: pathlib.Path) -> dict[str, object]:
    resolved = path.resolve(strict=True)
    resolved.relative_to(ROOT)
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def load_runner() -> Any:
    spec = importlib.util.spec_from_file_location("v14e_f0_v9l_runner", LEGACY_RUNNER)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load V9L RTL counterexample runner")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def normalized_copy(source: pathlib.Path, destination: pathlib.Path, work: pathlib.Path) -> None:
    text = source.read_text(encoding="utf-8", errors="replace")
    text = text.replace(str(work.resolve()), "<F0_RTL_TEMP>")
    text = text.replace(str(ROOT.resolve()), "<REPO>")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(text, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--work-dir", required=True, type=pathlib.Path)
    parser.add_argument("--output-dir", required=True, type=pathlib.Path)
    args = parser.parse_args()
    work = args.work_dir.resolve()
    output = args.output_dir.resolve()
    work.relative_to(ROOT)
    output.relative_to(HERE / "evidence")
    if output.exists():
        raise RuntimeError("refusing to replace F0 RTL counterexample evidence")

    runner = load_runner()
    runner.OUTPUT = work
    if work.exists():
        if work.is_symlink() or not work.is_dir() or any(work.iterdir()):
            raise RuntimeError(f"F0 RTL work directory is not empty: {work}")
    else:
        work.mkdir(parents=True)
    design_id = runner.current_design_id()
    if design_id != DESIGN_ID:
        raise RuntimeError(f"current design drift: {design_id}")

    sources_before = {
        runner.relative(path): digest(path)
        for path in (runner.SQ_RTL, runner.BRIDGE_RTL, runner.BACKEND_RTL)
    }
    sq_variant = runner.make_variant(
        "sq-launch-admission-substitution",
        runner.SQ_RTL,
        runner.SQ_OWNER_CURRENT,
        runner.SQ_OWNER_VARIANT,
    )
    bridge_variant = runner.make_variant(
        "bridge-no-credit-broad-assertion",
        runner.BRIDGE_RTL,
        runner.BRIDGE_CURRENT,
        runner.BRIDGE_VARIANT,
    )
    backend_variant = runner.make_variant(
        "retry-distinct-residency-broad-assertion",
        runner.BACKEND_RTL,
        runner.BACKEND_CURRENT,
        runner.BACKEND_VARIANT,
    )

    release = runner.run_release_case()
    cases = (
        (
            "sq-launch-admission-substitution",
            "tb_ooo_store_queue",
            "[V9L-SQ-POST-LAUNCH-OWNER]",
            [f"RTL_OOO_STORE_QUEUE={sq_variant}"],
            "Post-launch store authorization incorrectly uses first-launch admission.",
            [runner.SQ_RTL, sq_variant, runner.SQ_TB],
            None,
            runner.SQ_RTL,
            sq_variant,
        ),
        (
            "bridge-no-credit-broad-assertion",
            "tb_ooo_mem_axi_bridge",
            "[V9L-SQ-LOOKAHEAD-CREDIT]",
            [f"RTL_OOO_MEM_AXI_BRIDGE={bridge_variant}"],
            "The obsolete SQ lookahead assertion ignores response-credit semantics.",
            [runner.BRIDGE_RTL, bridge_variant],
            None,
            runner.BRIDGE_RTL,
            bridge_variant,
        ),
        (
            "retry-distinct-residency-broad-assertion",
            "tb_ooo_int_backend",
            "[V9L-RETRY-OWNER-DISJOINT]",
            [
                f"RTL_OOO_INT_BACKEND={backend_variant}",
                "TB_IVFLAGS_tb_ooo_int_backend=-DV8S_DUAL_MEMORY_FOCUSED",
            ],
            "The obsolete retry assertion rejects a distinct station owner.",
            [runner.BACKEND_RTL, backend_variant],
            None,
            runner.BACKEND_RTL,
            backend_variant,
        ),
    )
    records: list[dict[str, Any]] = []
    production: list[dict[str, Any]] = []
    for (
        name,
        test,
        marker,
        overrides,
        description,
        source_files,
        stimulus,
        production_source,
        variant_path,
    ) in cases:
        record = runner.run_case(
            name=name,
            test=test,
            expected_label=marker,
            make_overrides=overrides,
            description=description,
            source_files=source_files,
            expected_stimulus=stimulus,
        )
        records.append(record)
        production.append(
            {
                "name": name,
                "source": artifact(production_source),
                "variant_sha256": digest(variant_path),
                "compile_artifact_sha256_before_cleanup": record["compiled_image_sha256"],
                "compile_succeeded": bool(record["compile_succeeded"]),
                "dynamic_rejected": bool(record["simulation_rejected_variant"]),
                "target_assertion": record["target_assertion"],
                "target_assertion_count": record["target_assertion_count"],
                "driver_rc": record["return_code"],
            }
        )

    sources_after = {
        runner.relative(path): digest(path)
        for path in (runner.SQ_RTL, runner.BRIDGE_RTL, runner.BACKEND_RTL)
    }
    if sources_after != sources_before:
        raise RuntimeError("F0 production RTL changed during counterexample execution")
    if not bool(release.get("passed")) or not all(
        row["compile_succeeded"] and row["dynamic_rejected"] for row in production
    ):
        raise RuntimeError("F0 focused release or production RTL counterexample failed")
    fingerprints = {
        (str(row["source"]["path"]), str(row["variant_sha256"]))
        for row in production
    }
    if len(fingerprints) != 3:
        raise RuntimeError("F0 production RTL counterexample fingerprints alias")

    output.mkdir(parents=True)
    release_source = work / release["name"] / "result/logs/tb_ooo_int_backend.log"
    release_log = output / "logs/retry-distinct-residency-release.log"
    normalized_copy(release_source, release_log, work)
    for row, record in zip(production, records, strict=True):
        source_log = ROOT / str(record["test_log"])
        destination = output / "logs" / f"{row['name']}.log"
        normalized_copy(source_log, destination, work)
        row["log"] = artifact(destination)
    release_record = {
        "name": release["name"],
        "required_marker": release["required_marker"],
        "required_marker_count": release["required_marker_count"],
        "compile_artifact_sha256_before_cleanup": release["compiled_image_sha256"],
        "compile_succeeded": bool(release["compile_succeeded"]),
        "passed": bool(release["passed"]),
        "log": artifact(release_log),
    }
    summary = {
        "schema": "rv64-v14e-f0-production-rtl-counterexamples-v1",
        "status": "PASS",
        "current_design_id": design_id,
        "runner": artifact(LEGACY_RUNNER),
        "focused_release": release_record,
        "production_rtl": {
            "required": 3,
            "compile_success": 3,
            "dynamic_rejected": 3,
            "unique_rtl_variant_fingerprints": 3,
            "results": production,
        },
        "verification_only_mutations_executed": 0,
        "source_unchanged": True,
        "task_output_compiled_images_retained": 0,
        "work_dir_cleanup_required_by_caller": True,
    }
    (output / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[V14E-F0-RTL][PASS] release=1/1 production_rtl_mutations=3/3 "
        "unique_variants=3 source_unchanged=1"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14E-F0-RTL][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
