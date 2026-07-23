#!/usr/bin/env python3
"""Compile and reject a local RV64 FENCE full-drain RTL source variant."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-fence-rtl-variants-v2"
SUITE_RUN_ID = "2026-07-23-rv64-v9m-fence-ordering-current-design"


@dataclasses.dataclass(frozen=True)
class VariantSpec:
    name: str
    purpose: str
    source_rel: str
    make_variable: str
    test_name: str
    old: str
    new: str
    expected_marker: str


VARIANTS = (
    VariantSpec(
        name="fence_full_memory_idle_removed",
        purpose=(
            "Replace the ordinary-FENCE full memory-owner idle predicate "
            "with constant true; the drain-gate oracle must observe an "
            "early drain_complete_o while mem_idle_i is low."),
        source_rel="npc/rv64/vsrc/control/OooPendingDrainResolveGate.v",
        make_variable="RTL_OOO_PENDING_DRAIN_RESOLVE_GATE",
        test_name="tb_ooo_pending_drain_resolve_gate",
        old=(
            "wire pending_fence_mem_quiet_w =\n"
            "      !pending_system_fence_i || mem_idle_i;"),
        new="wire pending_fence_mem_quiet_w = 1'b1;",
        expected_marker=(
            "[CHECK-FAIL] fence waits for MIQ bridge reservation idle "
            "got=1 expected=0"),
    ),
    VariantSpec(
        name="core_glue_fence_mem_idle_binding_constantized",
        purpose=(
            "Replace the CoreGlue-to-ControlPlane ordinary-FENCE memory-idle "
            "connection with constant true while the program still observes "
            "the independent core_mem_idle_w signal."),
        source_rel="npc/rv64/vsrc/core/OooCoreTopGlue.v",
        make_variable="RTL_OOO_CORE_TOP_GLUE",
        test_name="tb_ooo_priv_system",
        old=".mem_idle_i(core_mem_idle_w),",
        new=".mem_idle_i(1'b1),",
        expected_marker=(
            "[CHECK-FAIL] fence control plane consumes core memory idle "
            "got=0 expected=1"),
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def repository_path(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    resolved = value.resolve()
    if not resolved.is_relative_to(root):
        raise ValueError(f"output escapes repository: {resolved}")
    return resolved


def reconstruct_variant(
    root: pathlib.Path, spec: VariantSpec,
) -> tuple[str, str]:
    source = (root / spec.source_rel).resolve(strict=True)
    if not source.is_relative_to(root) or source.is_symlink():
        raise ValueError(f"{spec.name}: source is outside the local RTL tree")
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL anchor is not unique")
    return text, text.replace(spec.old, spec.new, 1)


def run_one(
    root: pathlib.Path,
    output_dir: pathlib.Path,
    spec: VariantSpec,
) -> dict[str, object]:
    original_text, variant_text = reconstruct_variant(root, spec)
    original_path = root / spec.source_rel
    original_sha = sha256_bytes(original_text.encode("utf-8"))
    variant_sha = sha256_bytes(variant_text.encode("utf-8"))
    if original_sha == variant_sha:
        raise ValueError(f"{spec.name}: reconstructed RTL variant is a no-op")

    log_path = output_dir / f"{spec.name}.log"
    with tempfile.TemporaryDirectory(
        prefix=f"rv64-fence-{spec.name}-",
    ) as temp_name:
        temp = pathlib.Path(temp_name)
        variant_path = temp / original_path.name
        variant_path.write_text(variant_text, encoding="utf-8")
        result_dir = temp / "result"
        build_dir = temp / "build"
        target = result_dir / f"logs/{spec.test_name}.log"
        command = [
            "make", "-C", str(root / "npc/rv64/testbench"), "-B",
            f"RESULT_DIR={result_dir}",
            f"BUILD_DIR={build_dir}",
            f"{spec.make_variable}={variant_path}",
            str(target),
        ]
        completed = subprocess.run(
            command,
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            timeout=120,
        )
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver_text = completed.stdout + completed.stderr
        combined = test_log + (
            "\n[RTL-VARIANT-DRIVER]\n" + driver_text if driver_text else "")
        combined = combined.replace(str(temp), "<LOCAL-TEMP>")
        log_path.write_text(combined, encoding="utf-8")
        compiled_image = build_dir / f"{spec.test_name}.vvp"
        log_lines = test_log.splitlines()
        compile_lines = [
            line for line in log_lines if line.startswith("[COMPILE] ")]
        compile_success = (
            compiled_image.is_file()
            and len(compile_lines) == 1
            and "compile returned nonzero status" not in test_log
        )
        check_fail_lines = [
            line for line in log_lines if line.startswith("[CHECK-FAIL] ")]
        fail_lines = [
            line for line in log_lines if line.startswith("[FAIL] ")]
        result_lines = [
            line for line in log_lines if line.startswith("[RESULT] ")]
        marker_observed = check_fail_lines.count(spec.expected_marker) == 1
        exact_target_failure = (
            check_fail_lines == [spec.expected_marker]
            and fail_lines == [f"[FAIL] {spec.test_name} errors=1"]
            and result_lines == ["[RESULT] FAIL status=1"]
            and not any(line.startswith("ERROR:") for line in log_lines))
        dynamic_rejected = (
            compile_success
            and completed.returncode != 0
            and marker_observed
            and exact_target_failure
            and "[RESULT] PASS" not in test_log
        )

    return {
        "name": spec.name,
        "purpose": spec.purpose,
        "source": spec.source_rel,
        "make_variable": spec.make_variable,
        "test_name": spec.test_name,
        "original_sha256": original_sha,
        "variant_sha256": variant_sha,
        "expected_marker": spec.expected_marker,
        "marker_observed": marker_observed,
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "make_returncode": completed.returncode,
        "log": {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        },
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args(argv)

    root = args.root.resolve(strict=True)
    output = repository_path(root, args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    log_dir = output.parent / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    source_paths = sorted({spec.source_rel for spec in VARIANTS})
    before = {name: sha256_file(root / name) for name in source_paths}
    results = [run_one(root, log_dir, spec) for spec in VARIANTS]
    after = {name: sha256_file(root / name) for name in source_paths}
    compile_success = sum(bool(row["compile_success"]) for row in results)
    dynamic_rejected = sum(bool(row["dynamic_rejected"]) for row in results)
    payload = {
        "schema": SCHEMA,
        "suite_run_id": SUITE_RUN_ID,
        "required": len(VARIANTS),
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "source_unchanged": before == after,
        "source_sha256_before": before,
        "source_sha256_after": after,
        "results": results,
    }
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        f"[FENCE-G1-RTL-VARIANTS] required={len(VARIANTS)} "
        f"compile_success={compile_success} "
        f"dynamic_rejected={dynamic_rejected} "
        f"source_unchanged={str(before == after).lower()}"
    )
    return 0 if (
        compile_success == len(VARIANTS)
        and dynamic_rejected == len(VARIANTS)
        and before == after
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
