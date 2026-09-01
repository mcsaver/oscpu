#!/usr/bin/env python3
"""Collect the directly relevant result of one Qwen F32 ALU compile.

This is intentionally a build-result checker, not a provenance or workflow
verifier.  It checks the generated RTL filelist/configuration, required linked
artifacts, and the maintained warning baseline once after a successful build.
"""

from __future__ import annotations

import argparse
import collections
import json
import pathlib
import re
import shlex
import sys


PRIMARY_WARNING = re.compile(
    r"^%Warning-([A-Z0-9_]+):\s+(.+?):([0-9]+):([0-9]+):"
)
OTHER_DIAGNOSTIC = re.compile(
    r"(^|[\s:])(%Warning(?:-[A-Z0-9_]+)?|warning:|"
    r"%Error(?:-[A-Z0-9_]+)?|error:|fatal error:)",
    re.IGNORECASE,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-root", required=True, type=pathlib.Path)
    parser.add_argument("--npu-root", required=True, type=pathlib.Path)
    parser.add_argument("--cmake-build-dir", required=True, type=pathlib.Path)
    parser.add_argument("--verilated-dir", required=True, type=pathlib.Path)
    parser.add_argument("--verilator-bin", required=True, type=pathlib.Path)
    parser.add_argument("--verilator-std", required=True, type=pathlib.Path)
    parser.add_argument("--warning-baseline", required=True, type=pathlib.Path)
    parser.add_argument("--log", action="append", required=True, type=pathlib.Path)
    parser.add_argument("--actual-warnings", required=True, type=pathlib.Path)
    parser.add_argument("--summary", required=True, type=pathlib.Path)
    parser.add_argument("--source", action="append", required=True)
    return parser.parse_args()


def require_regular(path: pathlib.Path) -> pathlib.Path:
    resolved = path.resolve(strict=True)
    if not resolved.is_file():
        raise RuntimeError(f"required regular file is missing: {path}")
    return resolved


def workspace_relative(path: pathlib.Path, workspace_root: pathlib.Path) -> str:
    return path.resolve(strict=True).relative_to(workspace_root).as_posix()


def resolve_reported_path(
    raw: str, workspace_root: pathlib.Path, npu_root: pathlib.Path
) -> pathlib.Path:
    path = pathlib.Path(raw)
    if path.is_absolute():
        return path.resolve(strict=True)
    for candidate in (workspace_root / path, npu_root / path):
        if candidate.exists():
            return candidate.resolve(strict=True)
    raise RuntimeError(f"diagnostic names a missing source: {raw}")


def read_warning_baseline(path: pathlib.Path) -> list[tuple[str, str, int, int]]:
    rows: list[tuple[str, str, int, int]] = []
    for line_number, raw in enumerate(require_regular(path).read_text().splitlines(), 1):
        fields = raw.split("\t")
        if len(fields) != 4:
            raise RuntimeError(
                f"invalid warning baseline row {line_number}: expected four TSV fields"
            )
        category, source, source_line, column = fields
        rows.append((category, source, int(source_line), int(column)))
    if not rows:
        raise RuntimeError("warning baseline is empty")
    return rows


def collect_warnings(
    logs: list[pathlib.Path],
    workspace_root: pathlib.Path,
    npu_root: pathlib.Path,
) -> tuple[list[tuple[str, str, int, int]], list[str]]:
    warnings: list[tuple[str, str, int, int]] = []
    other_diagnostics: list[str] = []
    for log in logs:
        for raw in require_regular(log).read_text(errors="replace").splitlines():
            match = PRIMARY_WARNING.match(raw)
            if match:
                source = resolve_reported_path(
                    match.group(2), workspace_root, npu_root
                )
                warnings.append(
                    (
                        match.group(1),
                        workspace_relative(source, workspace_root),
                        int(match.group(3)),
                        int(match.group(4)),
                    )
                )
            elif OTHER_DIAGNOSTIC.search(raw):
                other_diagnostics.append(raw)
    return warnings, other_diagnostics


def read_verilator_filelist(
    verfiles: pathlib.Path,
) -> tuple[list[pathlib.Path], list[str]]:
    source_rows: list[pathlib.Path] = []
    command_rows: list[str] = []
    for raw in require_regular(verfiles).read_text(errors="strict").splitlines():
        if not raw or raw.startswith("#"):
            continue
        fields = shlex.split(raw, comments=False, posix=True)
        if not fields:
            continue
        if fields[0] == "S":
            if len(fields) != 8:
                raise RuntimeError(f"unexpected Verilator S row: {raw}")
            source_rows.append(pathlib.Path(fields[-1]).resolve(strict=True))
        elif fields[0] == "C":
            if len(fields) != 2:
                raise RuntimeError(f"unexpected Verilator C row: {raw}")
            command_rows.append(fields[1])
    if len(command_rows) != 1:
        raise RuntimeError(
            f"expected one Verilator configuration row, found {len(command_rows)}"
        )
    return source_rows, shlex.split(command_rows[0], comments=False, posix=True)


def require_pair(argv: list[str], option: str) -> str:
    positions = [index for index, value in enumerate(argv) if value == option]
    if len(positions) != 1 or positions[0] + 1 >= len(argv):
        raise RuntimeError(f"Verilator configuration requires one {option} value")
    return argv[positions[0] + 1]


def verify_configuration(
    argv: list[str],
    expected_sources: list[pathlib.Path],
    npu_root: pathlib.Path,
    verilated_dir: pathlib.Path,
) -> None:
    required_flags = {
        "--cc",
        "-O3",
        "-Wall",
        "-Wno-fatal",
        "--no-assert",
        "--no-trace",
    }
    missing = sorted(required_flags - set(argv))
    if missing:
        raise RuntimeError(f"Verilator configuration is missing flags: {missing}")
    if require_pair(argv, "--top-module") != "TensorNpuCoprocessor":
        raise RuntimeError("unexpected Verilator top module")
    if pathlib.Path(require_pair(argv, "--Mdir")).resolve() != verilated_dir:
        raise RuntimeError("Verilator output directory differs from the requested build")
    if f"-I{npu_root / 'rtl'}" not in argv:
        raise RuntimeError("Verilator configuration is missing the NPU RTL include path")
    cflags_index = argv.index("-CFLAGS")
    cflags = argv[cflags_index + 1 : -len(expected_sources)]
    for flag in ("-O3", "-DNDEBUG", "-march=native", "-fPIC"):
        if flag not in cflags:
            raise RuntimeError(f"generated model CFLAGS are missing {flag}")
    if len(argv) < len(expected_sources):
        raise RuntimeError("Verilator configuration is shorter than the RTL filelist")
    actual_sources = [
        pathlib.Path(value).resolve(strict=True)
        for value in argv[-len(expected_sources) :]
    ]
    if actual_sources != expected_sources:
        raise RuntimeError("generated Verilator source order differs from CMake input order")


def main() -> int:
    args = parse_args()
    workspace_root = args.workspace_root.resolve(strict=True)
    npu_root = args.npu_root.resolve(strict=True)
    cmake_build_dir = args.cmake_build_dir.resolve(strict=True)
    verilated_dir = args.verilated_dir.resolve(strict=True)
    expected_sources = [
        require_regular(npu_root / relative) for relative in args.source
    ]

    artifacts = {
        "verilator_filelist": require_regular(
            verilated_dir / "VTensorNpuCoprocessor__verFiles.dat"
        ),
        "verilated_archive": require_regular(
            verilated_dir / "VTensorNpuCoprocessor__ALL.a"
        ),
        "backend_module": require_regular(cmake_build_dir / "libggml-npu.so"),
        "backend_test": require_regular(cmake_build_dir / "test-npu-backend"),
        "compile_commands": require_regular(cmake_build_dir / "compile_commands.json"),
    }

    source_rows, verilator_argv = read_verilator_filelist(
        artifacts["verilator_filelist"]
    )
    expected_members = set(
        expected_sources
        + [require_regular(args.verilator_bin), require_regular(args.verilator_std)]
    )
    if len(source_rows) != len(set(source_rows)):
        raise RuntimeError("generated Verilator filelist contains duplicate source rows")
    if set(source_rows) != expected_members:
        missing = sorted(str(path) for path in expected_members - set(source_rows))
        extra = sorted(str(path) for path in set(source_rows) - expected_members)
        raise RuntimeError(
            f"generated Verilator source membership mismatch; missing={missing} extra={extra}"
        )
    verify_configuration(
        verilator_argv, expected_sources, npu_root, verilated_dir
    )

    baseline = read_warning_baseline(args.warning_baseline)
    actual, other_diagnostics = collect_warnings(
        args.log, workspace_root, npu_root
    )
    args.actual_warnings.write_text(
        "".join(
            f"{category}\t{source}\t{line}\t{column}\n"
            for category, source, line, column in actual
        )
    )
    missing_warnings = list(
        (collections.Counter(baseline) - collections.Counter(actual)).elements()
    )
    extra_warnings = list(
        (collections.Counter(actual) - collections.Counter(baseline)).elements()
    )
    if missing_warnings or extra_warnings or other_diagnostics:
        raise RuntimeError(
            "warning oracle mismatch; "
            f"missing={missing_warnings} extra={extra_warnings} "
            f"other={other_diagnostics}"
        )

    category_counts = dict(
        sorted(collections.Counter(row[0] for row in actual).items())
    )
    summary = {
        "status": "PASS",
        "scope": "compile-only",
        "source_count": len(expected_sources),
        "generated_source_row_count": len(source_rows),
        "configuration": {
            "top_module": "TensorNpuCoprocessor",
            "optimization": "O3",
            "assertions": "off",
            "trace": "off",
        },
        "warnings": {
            "expected": len(baseline),
            "actual": len(actual),
            "categories": category_counts,
            "unexpected_diagnostics": 0,
        },
        "artifacts": {name: str(path) for name, path in artifacts.items()},
        "binary_runs": 0,
        "model_runs": 0,
    }
    args.summary.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError) as error:
        print(f"[QWEN-F32-ALU-COMPILE][RESULT-FAIL] {error}", file=sys.stderr)
        raise SystemExit(1)
