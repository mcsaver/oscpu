#!/usr/bin/env python3
"""Compute canonical source-set identities for the local RV64 evidence run."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Sequence


VERIFICATION_SUFFIXES = {".py", ".sh", ".sv", ".svh", ".v"}
VERIFICATION_ROOTS = (
    "npc/rv64/testbench/common",
    "npc/rv64/testbench/scripts",
    "npc/rv64/testbench/tests",
)
VERIFICATION_FILES = (
    "npc/rv64/testbench/Makefile",
    "npc/rv64/vsrc/filelist.mk",
)


def sha256_file(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_digest(files: dict[str, str]) -> str:
    body = "".join(
        f"{digest}  {relative}\n"
        for relative, digest in sorted(files.items())
    )
    return hashlib.sha256(body.encode("utf-8")).hexdigest()


def rtl_binding(root: pathlib.Path) -> tuple[str, dict[str, str]]:
    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    import architecture_hard_gates as architecture

    return architecture.rtl_binding(root)


def verification_binding(
    root: pathlib.Path,
) -> tuple[str, dict[str, str]]:
    paths: set[pathlib.Path] = set()
    for relative in VERIFICATION_FILES:
        paths.add((root / relative).resolve(strict=True))
    for relative in VERIFICATION_ROOTS:
        directory = (root / relative).resolve(strict=True)
        for path in directory.rglob("*"):
            if path.is_file() and path.suffix in VERIFICATION_SUFFIXES:
                paths.add(path.resolve(strict=True))

    files: dict[str, str] = {}
    for path in sorted(paths):
        if not path.is_relative_to(root):
            raise ValueError(f"verification source escapes repository: {path}")
        if path.is_symlink():
            raise ValueError(f"verification source is a symlink: {path}")
        relative = path.relative_to(root).as_posix()
        files[relative] = sha256_file(path)
    return canonical_digest(files), files


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, type=pathlib.Path)
    parser.add_argument(
        "--kind",
        choices=("rtl", "verification"),
        required=True,
    )
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    root = args.root.resolve(strict=True)
    digest, files = (
        rtl_binding(root)
        if args.kind == "rtl"
        else verification_binding(root)
    )
    if args.json:
        print(
            json.dumps(
                {
                    "kind": args.kind,
                    "sha256": digest,
                    "file_count": len(files),
                    "files": files,
                },
                indent=2,
                sort_keys=True,
            )
        )
    else:
        print(digest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
