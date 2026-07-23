#!/usr/bin/env python3
"""Compile and reject local RV64 owner-residency RTL source variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile
from typing import Sequence


SCHEMA = "npc-rv64-irrevocable-owner-residency-rtl-variants-v1"
SUITE_RUN_ID = "2026-07-23-rv64-v9n-irrevocable-write-owner-residency"


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
    superseded_same_edge_marker: str


VARIANTS = (
    VariantSpec(
        name="sq_clear_owner_valid_on_request_fire",
        purpose=(
            "Clear the STORE queue owner-valid bit on the same clock edge that "
            "records physical request acceptance.  Request residency remains "
            "visible to legacy checks, while the exact owner tuple disappears; "
            "the independent next-edge checker must reject it."
        ),
        source_rel="npc/rv64/vsrc/memory/OooStoreQueue.v",
        make_variable="RTL_OOO_STORE_QUEUE",
        test_name="tb_v9n_sq_owner_residency",
        old=(
            "      if (req_fire_i && req_valid_o)\n"
            "        request_sent_q[head_q] <= 1'b1;"
        ),
        new=(
            "      if (req_fire_i && req_valid_o) begin\n"
            "        request_sent_q[head_q] <= 1'b1;\n"
            "        owner_valid_q[head_q] <= 1'b0;\n"
            "      end"
        ),
        expected_marker=(
            "[CHECK-FAIL] V9N STORE owner residency lost before exact terminal"
        ),
        superseded_same_edge_marker="[V9L-SQ-POST-LAUNCH-OWNER]",
    ),
    VariantSpec(
        name="amo_clear_kind_on_write_fire",
        purpose=(
            "Clear the AMO singleton type bit on the same clock edge that "
            "records physical write acceptance.  Pending/write-sent remain "
            "visible to the old same-edge owner assertion, while the complete "
            "AMO holder tuple is lost; the next-edge checker must reject it."
        ),
        source_rel="npc/rv64/vsrc/execute/OooIntBackend.v",
        make_variable="RTL_OOO_INT_BACKEND",
        test_name="tb_v9n_amo_owner_residency",
        old=(
            "      if (push_amo_write_w) begin\n"
            "        mem_amo_write_sent_q <= 1'b1;\n"
            "        reservation_valid_q <= 1'b0;\n"
            "        reservation_addr_q <= {`XLEN{1'b0}};\n"
            "        reservation_size_q <= 2'b00;\n"
            "      end"
        ),
        new=(
            "      if (push_amo_write_w) begin\n"
            "        mem_amo_write_sent_q <= 1'b1;\n"
            "        mem_amo_q <= 1'b0;\n"
            "        reservation_valid_q <= 1'b0;\n"
            "        reservation_addr_q <= {`XLEN{1'b0}};\n"
            "        reservation_size_q <= 2'b00;\n"
            "      end"
        ),
        expected_marker=(
            "[CHECK-FAIL] V9N AMO owner residency lost before exact terminal"
        ),
        superseded_same_edge_marker="[V9L-AMO-POST-LAUNCH-OWNER]",
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def repository_path(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    resolved = value if value.is_absolute() else root / value
    resolved = resolved.resolve()
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
        prefix=f"rv64-owner-residency-{spec.name}-",
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
            timeout=180,
        )
        test_log = target.read_text(encoding="utf-8") if target.is_file() else ""
        driver_text = completed.stdout + completed.stderr
        combined = test_log + (
            "\n[RTL-VARIANT-DRIVER]\n" + driver_text if driver_text else ""
        )
        combined = combined.replace(str(temp), "<LOCAL-TEMP>")
        log_path.write_text(combined, encoding="utf-8")

        compiled_image = build_dir / f"{spec.test_name}.vvp"
        log_lines = test_log.splitlines()
        compile_lines = [
            line for line in log_lines if line.startswith("[COMPILE] ")
        ]
        check_fail_lines = [
            line for line in log_lines if line.startswith("[CHECK-FAIL] ")
        ]
        fail_lines = [
            line for line in log_lines if line.startswith("[FAIL] ")
        ]
        result_lines = [
            line for line in log_lines if line.startswith("[RESULT] ")
        ]
        compile_success = (
            compiled_image.is_file()
            and len(compile_lines) == 1
            and "compile returned nonzero status" not in test_log
        )
        marker_observed = check_fail_lines == [spec.expected_marker]
        old_same_edge_assertion_quiet = (
            spec.superseded_same_edge_marker not in test_log
        )
        exact_target_failure = (
            marker_observed
            and fail_lines == [f"[FAIL] {spec.test_name} errors=1"]
            and result_lines == ["[RESULT] FAIL status=1"]
            and "[RESULT] PASS" not in test_log
            and "[TIMEOUT]" not in test_log
            and not any(line.startswith("ERROR:") for line in log_lines)
        )
        dynamic_rejected = (
            compile_success
            and completed.returncode != 0
            and exact_target_failure
            and old_same_edge_assertion_quiet
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
        "old_same_edge_assertion_quiet": old_same_edge_assertion_quiet,
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
        f"[V9N-OWNER-RESIDENCY-RTL-VARIANTS] required={len(VARIANTS)} "
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
