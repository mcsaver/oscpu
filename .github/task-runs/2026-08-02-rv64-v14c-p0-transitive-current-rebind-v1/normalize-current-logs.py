#!/usr/bin/env python3
"""Normalize the owned V14C RV64 compile path in task-local logs."""

from __future__ import annotations

import argparse
import pathlib
import sys


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TOKEN = "<V14C_TRANSIENT_TMP>"


def normalize(path: pathlib.Path, transient: pathlib.Path) -> int:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(HERE / "evidence") or not resolved.is_file():
        raise ValueError(f"log is outside the V14C evidence directory: {path}")
    text = resolved.read_text(encoding="utf-8")
    needle = transient.as_posix()
    count = text.count(needle)
    if count:
        resolved.write_text(text.replace(needle, TOKEN), encoding="utf-8")
    return count


def main() -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--log-dir", type=pathlib.Path)
    group.add_argument("--log", type=pathlib.Path)
    parser.add_argument("--transient-dir", required=True, type=pathlib.Path)
    args = parser.parse_args()
    transient = args.transient_dir.resolve()
    if not transient.as_posix().startswith("/tmp/rv64-v14c-p0-transitive."):
        raise ValueError(f"unexpected RV64 transient directory: {transient}")
    paths = (
        sorted(args.log_dir.resolve(strict=True).glob("*.log"))
        if args.log_dir is not None
        else [args.log]
    )
    if not paths:
        raise ValueError("V14C log inventory is empty")
    replacements = sum(normalize(path, transient) for path in paths)
    print(
        f"[V14C-LOG-NORMALIZATION] logs={len(paths)} "
        f"replacements={replacements} token={TOKEN}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeDecodeError, ValueError) as exc:
        print(f"[V14C-LOG-NORMALIZATION][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
