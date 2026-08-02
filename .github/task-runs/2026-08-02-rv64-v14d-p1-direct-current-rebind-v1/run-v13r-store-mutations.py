#!/usr/bin/env python3
"""Compile and dynamically reject current RV64 STORE-B holder RTL variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "rv64-v14d-v13r-store-b-rtl-mutations-v1"
CURRENT_DESIGN_ID = (
    "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488"
)


@dataclasses.dataclass(frozen=True)
class MutationSpec:
    name: str
    purpose: str
    source_rel: str
    make_variable: str
    test_name: str
    old: str
    new: str
    expected_marker: str
    expected_fatal: str
    expected_assertion_prefix: str | None
    expected_fail_prefix: str | None


MUTATIONS = (
    MutationSpec(
        name="s-resp-auto-drop",
        purpose=(
            "Drop the registered B response holder even while the downstream "
            "response sink is not ready."
        ),
        source_rel="npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold",
        old="if (rsp_ready_w) begin",
        new="if (rsp_ready_w || !rsp_ready_w) begin",
        expected_marker="[CHECK-FAIL] V13R DECERR holder remains S_RESP",
        expected_fatal="FATAL: <LOCAL-TEMP>/OooMemAxiBridge.v:2598: ",
        expected_assertion_prefix=(
            "[S2-G1-BRG-RSP-HOLD] stalled response vanished without fire/drop"
        ),
        expected_fail_prefix=None,
    ),
    MutationSpec(
        name="decerr-captured-as-okay",
        purpose=(
            "Misclassify the accepted DECERR response while retaining the "
            "registered response transaction."
        ),
        source_rel="npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        make_variable="RTL_OOO_MEM_AXI_BRIDGE",
        test_name="tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold",
        old="rsp_error_q <= (lsu_axi_bresp_i != 2'b00);",
        new="rsp_error_q <= (lsu_axi_bresp_i == 2'b10);",
        expected_marker="[CHECK-FAIL] V13R DECERR holder keeps error",
        expected_fatal="FATAL: <LOCAL-TEMP>/OooMemAxiBridge.v:2248: ",
        expected_assertion_prefix=(
            "[V13P-B-FUSION-FALLBACK] stalled B response was not captured exactly"
        ),
        expected_fail_prefix=None,
    ),
    MutationSpec(
        name="rob-ignores-commit-ready",
        purpose=(
            "Allow exact store retirement while the external commit permit "
            "is held low."
        ),
        source_rel="npc/rv64/vsrc/writeback/OooRob.v",
        make_variable="RTL_OOO_ROB",
        test_name="tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold",
        old="assign head0_base_ready_w = !recovering_w && commit_ready_i &&",
        new="assign head0_base_ready_w = !recovering_w && 1'b1 &&",
        expected_marker=(
            "[CHECK-FAIL] V13R commit_ready hold blocks target commit"
        ),
        expected_fatal="FATAL: common/tb_common.svh:35: ",
        expected_assertion_prefix=None,
        expected_fail_prefix=(
            "[FAIL] tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold errors="
        ),
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def repository_path(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    path = value if value.is_absolute() else root / value
    resolved = path.resolve()
    if not resolved.is_relative_to(root):
        raise ValueError(f"output escapes repository: {value}")
    return resolved


def reconstruct_mutation(
    root: pathlib.Path, spec: MutationSpec,
) -> tuple[str, str]:
    source = (root / spec.source_rel).resolve(strict=True)
    if not source.is_relative_to(root) or source.is_symlink():
        raise ValueError(f"{spec.name}: source escaped current RTL tree")
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: current RTL anchor is not unique")
    return text, text.replace(spec.old, spec.new, 1)


def run_one(
    root: pathlib.Path,
    log_dir: pathlib.Path,
    spec: MutationSpec,
) -> dict[str, object]:
    original, mutated = reconstruct_mutation(root, spec)
    original_sha = sha256_bytes(original.encode("utf-8"))
    variant_sha = sha256_bytes(mutated.encode("utf-8"))
    with tempfile.TemporaryDirectory(prefix=f"rv64-v14d-{spec.name}-") as name:
        temp = pathlib.Path(name)
        variant = temp / pathlib.Path(spec.source_rel).name
        variant.write_text(mutated, encoding="utf-8")
        build_dir = temp / "build"
        result_dir = temp / "result"
        command = [
            "make",
            "-B",
            "-C",
            str(root / "npc/rv64/testbench"),
            f"TESTS={spec.test_name}",
            "EXTRA_TESTS=",
            f"BUILD_DIR={build_dir}",
            f"RESULT_DIR={result_dir}",
            f"{spec.make_variable}={variant}",
            f"RTL_EVIDENCE_SHA={CURRENT_DESIGN_ID.removeprefix('sha256:')}",
            "run",
        ]
        completed = subprocess.run(
            command,
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            timeout=180,
        )
        raw_log = result_dir / f"logs/{spec.test_name}.log"
        text = raw_log.read_text(encoding="utf-8") if raw_log.is_file() else ""
        normalized = text.replace(str(temp), "<LOCAL-TEMP>")
        log_path = log_dir / f"{spec.name}.log"
        log_path.write_text(normalized, encoding="utf-8")
        compiled = build_dir / f"{spec.test_name}.vvp"
        compile_lines = [
            line for line in text.splitlines() if line.startswith("[COMPILE] ")
        ]
        check_fail_lines = [
            line for line in text.splitlines() if line.startswith("[CHECK-FAIL] ")
        ]
        fail_lines = [
            line for line in text.splitlines() if line.startswith("[FAIL] ")
        ]
        result_lines = [
            line for line in text.splitlines() if line.startswith("[RESULT] ")
        ]
        fatal_lines = [
            line for line in normalized.splitlines() if line.startswith("FATAL: ")
        ]
        compile_success = (
            compiled.is_file()
            and len(compile_lines) == 1
            and "compile returned nonzero status" not in text
        )
        marker_observed = sum(
            line.startswith(spec.expected_marker) for line in check_fail_lines
        ) == 1
        assertion_contract = (
            spec.expected_assertion_prefix is None
            or sum(
                line.startswith(spec.expected_assertion_prefix)
                for line in text.splitlines()
            )
            == 1
        )
        fail_contract = (
            len(fail_lines) == 0
            if spec.expected_fail_prefix is None
            else len(fail_lines) == 1
            and fail_lines[0].startswith(spec.expected_fail_prefix)
        )
        dynamic_rejected = (
            compile_success
            and completed.returncode != 0
            and marker_observed
            and assertion_contract
            and fail_contract
            and fatal_lines == [spec.expected_fatal]
            and result_lines == ["[RESULT] FAIL status=1"]
            and "[RESULT] PASS" not in text
            and "[TIMEOUT]" not in text
            and text.count(f"[RTL-DESIGN-ID] {CURRENT_DESIGN_ID}") == 1
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
        "expected_fatal": spec.expected_fatal,
        "marker_observed": marker_observed,
        "check_fail_count": len(check_fail_lines),
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
    parser.add_argument("--root", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)
    output = repository_path(root, args.output)
    if output.exists():
        raise ValueError("refusing to replace V13R mutation summary")
    output.parent.mkdir(parents=True, exist_ok=True)
    log_dir = output.parent / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    source_names = sorted({spec.source_rel for spec in MUTATIONS})
    before = {name: sha256_file(root / name) for name in source_names}
    rows = [run_one(root, log_dir, spec) for spec in MUTATIONS]
    after = {name: sha256_file(root / name) for name in source_names}
    compile_success = sum(bool(row["compile_success"]) for row in rows)
    dynamic_rejected = sum(bool(row["dynamic_rejected"]) for row in rows)
    result = {
        "schema": SCHEMA,
        "current_design_id": CURRENT_DESIGN_ID,
        "required": len(MUTATIONS),
        "compile_success": compile_success,
        "dynamic_rejected": dynamic_rejected,
        "source_unchanged": before == after,
        "source_sha256_before": before,
        "source_sha256_after": after,
        "results": rows,
    }
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        f"[V14D-V13R-STORE-MUTATIONS] required={len(MUTATIONS)} "
        f"compile_success={compile_success} dynamic_rejected={dynamic_rejected} "
        f"source_unchanged={str(before == after).lower()}"
    )
    return 0 if (
        compile_success == len(MUTATIONS)
        and dynamic_rejected == len(MUTATIONS)
        and before == after
    ) else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V14D-V13R-STORE-MUTATIONS][FAIL] {exc}")
        raise SystemExit(1)
