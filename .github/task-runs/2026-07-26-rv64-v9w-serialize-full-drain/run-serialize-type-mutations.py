#!/usr/bin/env python3
"""Compile and reject RV64 pending-system type-source RTL variants."""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import subprocess
import tempfile


SCHEMA = "npc-rv64-serialize-type-rtl-mutations-v1"
SUITE_RUN_ID = "2026-07-26-rv64-v9w-serialize-full-drain"
TRANSIENT_TOKEN = "<V9W-LOCAL-TEMP>"


@dataclasses.dataclass(frozen=True)
class Mutation:
    name: str
    purpose: str
    source_rel: str
    make_variable: str
    test_name: str
    old: str
    new: str
    expected_marker: str


MUTATIONS = (
    Mutation(
        name="xret_drives_two_public_kinds",
        purpose=(
            "Make XRET drive both XRET and ECALL public type wires; the "
            "registered exact-one assertion must reject the RTL variant."
        ),
        source_rel="npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
        make_variable="RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        test_name="tb_ooo_pending_system_sequencer",
        old="  assign ecall_o = kind_q == SERIAL_KIND_ECALL;",
        new=(
            "  assign ecall_o = (kind_q == SERIAL_KIND_ECALL) ||\n"
            "                   (kind_q == SERIAL_KIND_XRET);"
        ),
        expected_marker="[V9W-SERIAL-KIND-ONEHOT]",
    ),
    Mutation(
        name="plain_fence_loses_registered_kind",
        purpose=(
            "Classify an admitted ordinary FENCE as NONE; valid/kind "
            "equivalence must reject the RTL variant."
        ),
        source_rel="npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
        make_variable="RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        test_name="tb_ooo_pending_system_sequencer",
        old="        classify_system_kind = SERIAL_KIND_FENCE;",
        new="        classify_system_kind = SERIAL_KIND_NONE;",
        expected_marker="[V9W-SERIAL-KIND-VALID]",
    ),
    Mutation(
        name="sinval_redirect_uses_narrow_raw_decode",
        purpose=(
            "Narrow the SFENCE-family redirect reason to the SFENCE.VMA "
            "encoding; the SINVAL.VMA full-core transaction must retain the "
            "SFENCE typed action and reject this RTL variant."
        ),
        source_rel="npc/rv64/vsrc/frontend/OooFrontend.v",
        make_variable="RTL_OOO_FRONTEND",
        test_name="tb_ooo_priv_system",
        old=(
            "  wire commit_e6_system_sfence_w =\n"
            "      commit_e6_sel_system_w && pending_system_sfence_commit_w;"
        ),
        new=(
            "  wire commit_e6_system_sfence_w =\n"
            "      commit_e6_sel_system_w &&\n"
            "      (pending_system_inst_q[31:25] == "
            "`SYSTEM_FUNCT7_SFENCE_VMA);"
        ),
        expected_marker=(
            "[CHECK-FAIL] sinval uses SFENCE typed redirect got=0 expected=1"
        ),
    ),
    Mutation(
        name="fencei_redirect_drops_holder_type",
        purpose=(
            "Drop the FENCE.I holder-derived commit pulse at the frontend "
            "redirect consumer; the full-core transaction must reject the "
            "generic SERIAL reason."
        ),
        source_rel="npc/rv64/vsrc/frontend/OooFrontend.v",
        make_variable="RTL_OOO_FRONTEND",
        test_name="tb_ooo_priv_system",
        old=(
            "  wire commit_e6_system_fencei_w =\n"
            "      commit_e6_sel_system_w && pending_system_fencei_commit_w;"
        ),
        new=(
            "  wire commit_e6_system_fencei_w =\n"
            "      commit_e6_sel_system_w && 1'b0;"
        ),
        expected_marker=(
            "[CHECK-FAIL] fence.i uses FENCEI typed redirect got=0 expected=1"
        ),
    ),
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def repository_path(root: pathlib.Path, path: pathlib.Path) -> pathlib.Path:
    resolved = path.resolve() if path.is_absolute() else (root / path).resolve()
    if not resolved.is_relative_to(root):
        raise ValueError(f"path escapes repository: {path}")
    return resolved


def build_mutation(root: pathlib.Path, spec: Mutation) -> tuple[str, str]:
    source = repository_path(root, pathlib.Path(spec.source_rel))
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1:
        raise ValueError(
            f"{spec.name}: expected one live RTL anchor, found "
            f"{text.count(spec.old)}"
        )
    mutated = text.replace(spec.old, spec.new, 1)
    if mutated == text:
        raise ValueError(f"{spec.name}: RTL variant is a no-op")
    return text, mutated


def run_mutation(
    root: pathlib.Path,
    log_dir: pathlib.Path,
    spec: Mutation,
) -> dict[str, object]:
    original, mutated = build_mutation(root, spec)
    source_path = root / spec.source_rel
    with tempfile.TemporaryDirectory(
        prefix=f"rv64-v9w-{spec.name}-",
    ) as temp_name:
        temp = pathlib.Path(temp_name)
        replacement = temp / source_path.name
        replacement.write_text(mutated, encoding="utf-8")
        build_dir = temp / "build"
        result_dir = temp / "result"
        target = result_dir / "logs" / f"{spec.test_name}.log"
        ivflags = " ".join(
            (
                "-g2012",
                "-Wall",
                f"-I{root / 'npc/rv64/vsrc'}",
                f"-I{root / 'npc/rv64/vsrc/include'}",
                f"-I{root / 'npc/rv64/testbench/common'}",
                "-DOOO_ASSERT",
            )
        )
        command = [
            "make",
            "-B",
            "-C",
            str(root / "npc/rv64/testbench"),
            f"RESULT_DIR={result_dir}",
            f"BUILD_DIR={build_dir}",
            f"IVFLAGS={ivflags}",
            f"{spec.make_variable}={replacement}",
            str(target),
        ]
        completed = subprocess.run(
            command,
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            timeout=240,
        )
        test_log = (
            target.read_text(encoding="utf-8") if target.is_file() else ""
        )
        combined = test_log
        if completed.stdout or completed.stderr:
            combined += (
                "\n[V9W-RTL-VARIANT-DRIVER]\n"
                + completed.stdout
                + completed.stderr
            )
        combined = combined.replace(str(temp), TRANSIENT_TOKEN)
        log_path = log_dir / f"{spec.name}.log"
        log_path.write_text(combined, encoding="utf-8")

        compile_success = (
            (build_dir / f"{spec.test_name}.vvp").is_file()
            and "[COMPILE] " in test_log
            and "compile returned nonzero status" not in test_log
        )
        marker_observed = spec.expected_marker in test_log
        rejected = (
            compile_success
            and completed.returncode != 0
            and marker_observed
            and "[RESULT] FAIL" in test_log
            and "[RESULT] PASS" not in test_log
        )

    return {
        "name": spec.name,
        "purpose": spec.purpose,
        "source": spec.source_rel,
        "make_variable": spec.make_variable,
        "test": spec.test_name,
        "expected_marker": spec.expected_marker,
        "marker_observed": marker_observed,
        "compile_success": compile_success,
        "rejected": rejected,
        "make_returncode": completed.returncode,
        "original_sha256": sha256_bytes(original.encode("utf-8")),
        "mutation_sha256": sha256_bytes(mutated.encode("utf-8")),
        "log": {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args()

    root = args.root.resolve(strict=True)
    output = repository_path(root, args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    log_dir = output.parent / "mutation-logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    import sys

    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    import architecture_hard_gates as architecture

    source_paths = sorted({row.source_rel for row in MUTATIONS})
    source_before = {
        name: sha256_file(root / name) for name in source_paths
    }
    rtl_sha_before, rtl_files_before = architecture.rtl_binding(root)
    results = [run_mutation(root, log_dir, row) for row in MUTATIONS]
    source_after = {
        name: sha256_file(root / name) for name in source_paths
    }
    rtl_sha_after, rtl_files_after = architecture.rtl_binding(root)
    compile_success = sum(bool(row["compile_success"]) for row in results)
    rejected = sum(bool(row["rejected"]) for row in results)
    source_unchanged = source_before == source_after
    rtl_unchanged = (
        rtl_sha_before == rtl_sha_after
        and rtl_files_before == rtl_files_after
    )
    payload = {
        "schema": SCHEMA,
        "suite_run_id": SUITE_RUN_ID,
        "design_id": f"sha256:{rtl_sha_before}",
        "required": len(MUTATIONS),
        "compile_success": compile_success,
        "rejected": rejected,
        "source_unchanged": source_unchanged,
        "full_rtl_source_unchanged": rtl_unchanged,
        "rtl_source_set": {
            "design_id": f"sha256:{rtl_sha_before}",
            "sha256": rtl_sha_before,
            "file_count": len(rtl_files_before),
            "files": rtl_files_before,
        },
        "results": results,
    }
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V9W-SERIAL-RTL-VARIANTS] "
        f"required={len(MUTATIONS)} compile_success={compile_success} "
        f"rejected={rejected} design_id=sha256:{rtl_sha_before} "
        f"source_unchanged={str(source_unchanged).lower()} "
        f"full_rtl_source_unchanged={str(rtl_unchanged).lower()}"
    )
    return 0 if (
        compile_success == len(MUTATIONS)
        and rejected == len(MUTATIONS)
        and source_unchanged
        and rtl_unchanged
    ) else 1


if __name__ == "__main__":
    raise SystemExit(main())
