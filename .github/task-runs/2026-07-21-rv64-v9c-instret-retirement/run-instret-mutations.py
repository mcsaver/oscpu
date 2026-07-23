#!/usr/bin/env python3
"""Compile and dynamically reject local RV64 INSTRET RTL source variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import shutil
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-instret-rtl-mutations-v1"
SUITE_RUN_ID = "2026-07-21-rv64-v9c-instret-retirement"


@dataclasses.dataclass(frozen=True)
class MutationSpec:
    name: str
    purpose: str
    source_rel: str
    make_variable: str
    old: str
    new: str
    expected_marker: str


MUTATIONS = (
    MutationSpec(
        name="exception_filter_removed",
        purpose=(
            "Remove lane-0 synchronous-exception filtering from the final "
            "architectural retirement count."),
        source_rel="npc/rv64/vsrc/writeback/OooCommitOutputMux.v",
        make_variable="RTL_OOO_COMMIT_OUTPUT_MUX",
        old=(
            "wire commit0_isa_retire_w = "
            "commit0_valid_o && !commit0_exception_o;"),
        new="wire commit0_isa_retire_w = commit0_valid_o;",
        expected_marker="[INSTRET-G1-FINAL-EQ]",
    ),
    MutationSpec(
        name="final_control_source_removed",
        purpose=(
            "Replace final lane-0 retirement selection with the pre-mux core "
            "lane, omitting serialized control pseudo-commits."),
        source_rel="npc/rv64/vsrc/writeback/OooCommitOutputMux.v",
        make_variable="RTL_OOO_COMMIT_OUTPUT_MUX",
        old=(
            "wire commit0_isa_retire_w = "
            "commit0_valid_o && !commit0_exception_o;"),
        new=(
            "wire commit0_isa_retire_w = "
            "core_commit0_valid_i && !core_commit0_exception_i;"),
        expected_marker="[INSTRET-G1-FINAL-EQ]",
    ),
    MutationSpec(
        name="csr_uses_core_count",
        purpose=(
            "Reconnect CsrFile minstret to the core-local completion count "
            "instead of the final visible retirement count."),
        source_rel="npc/rv64/vsrc/core/NpcCoreTop.v",
        make_variable="RTL_NPC_CORE_TOP",
        old=".instret_inc_i(retire_count_o),",
        new=".instret_inc_i(ooo_core_retire_count_w),",
        expected_marker="[CHECK-FAIL] INSTRET CsrFile edge delta",
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def reconstruct_mutant(root: pathlib.Path, spec: MutationSpec) -> tuple[str, str]:
    source = (root / spec.source_rel).resolve(strict=True)
    if not source.is_relative_to(root):
        raise ValueError(f"{spec.name}: source escapes repository")
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL anchor is not unique")
    return text, text.replace(spec.old, spec.new, 1)


def repository_path(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    resolved = value.resolve()
    if not resolved.is_relative_to(root):
        raise ValueError(f"output escapes repository: {resolved}")
    return resolved


def run_one(
    root: pathlib.Path,
    output_dir: pathlib.Path,
    spec: MutationSpec,
) -> dict[str, object]:
    original_text, mutant_text = reconstruct_mutant(root, spec)
    original_path = root / spec.source_rel
    original_sha = sha256_bytes(original_text.encode("utf-8"))
    mutant_sha = sha256_bytes(mutant_text.encode("utf-8"))
    if original_sha == mutant_sha:
        raise ValueError(f"{spec.name}: reconstructed variant is a no-op")

    log_path = output_dir / f"{spec.name}.log"
    with tempfile.TemporaryDirectory(prefix=f"instret-{spec.name}-") as temp_name:
        temp = pathlib.Path(temp_name)
        mutant_path = temp / original_path.name
        mutant_path.write_text(mutant_text, encoding="utf-8")
        result_dir = temp / "result"
        build_dir = temp / "build"
        target = result_dir / "logs/tb_ooo_sv39_boot.log"
        command = [
            "make", "-C", str(root / "npc/rv64/testbench"),
            f"RESULT_DIR={result_dir}",
            f"BUILD_DIR={build_dir}",
            f"{spec.make_variable}={mutant_path}",
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
            "\n[MUTATION-DRIVER]\n" + driver_text if driver_text else "")
        log_path.write_text(combined, encoding="utf-8")
        compiled_image = build_dir / "tb_ooo_sv39_boot.vvp"
        compile_success = (
            compiled_image.is_file()
            and "[COMPILE]" in test_log
            and "compile returned nonzero status" not in test_log
        )
        marker_observed = spec.expected_marker in test_log
        dynamic_rejected = (
            compile_success
            and completed.returncode != 0
            and marker_observed
            and "[RESULT] FAIL status=" in test_log
            and "[RESULT] PASS" not in test_log
        )

    return {
        "name": spec.name,
        "purpose": spec.purpose,
        "source": spec.source_rel,
        "make_variable": spec.make_variable,
        "original_sha256": original_sha,
        "mutant_sha256": mutant_sha,
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

    source_paths = sorted({spec.source_rel for spec in MUTATIONS})
    before = {name: sha256_file(root / name) for name in source_paths}
    results = [run_one(root, log_dir, spec) for spec in MUTATIONS]
    after = {name: sha256_file(root / name) for name in source_paths}
    compile_success = sum(bool(row["compile_success"]) for row in results)
    dynamic_rejected = sum(bool(row["dynamic_rejected"]) for row in results)
    payload = {
        "schema": SCHEMA,
        "suite_run_id": SUITE_RUN_ID,
        "required": len(MUTATIONS),
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
        f"[INSTRET-G1-RTL-MUTATIONS] required={len(MUTATIONS)} "
        f"compile_success={compile_success} "
        f"dynamic_rejected={dynamic_rejected} "
        f"source_unchanged={str(before == after).lower()}"
    )
    return 0 if (
        compile_success == len(MUTATIONS)
        and dynamic_rejected == len(MUTATIONS)
        and before == after
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
