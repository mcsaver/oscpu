#!/usr/bin/env python3
"""Verify and inventory the immutable workspace copy of /tmp/s2-g1*."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
SOURCE = Path("/tmp")
ARCHIVE = REPO / "tmp/2026-07-15-rv64-ppa-architecture-recovery/s2-exact-owner"
COPY = ARCHIVE / "system-tmp"


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def scan(root: Path, names: list[str]) -> dict[str, tuple[str, int, str]]:
    result: dict[str, tuple[str, int, str]] = {}
    for name in names:
        start = root / name
        paths = [start]
        if start.is_dir() and not start.is_symlink():
            paths.extend(sorted(start.rglob("*")))
        for path in paths:
            rel = path.relative_to(root).as_posix()
            if path.is_symlink():
                result[rel] = ("L", 0, os.readlink(path))
            elif path.is_dir():
                result[rel] = ("D", 0, "-")
            elif path.is_file():
                size = path.stat().st_size
                result[rel] = ("F", size, digest(path))
            else:
                result[rel] = ("O", 0, "unsupported")
    return result


def main() -> int:
    source_names = sorted(path.name for path in SOURCE.glob("s2-g1*"))
    copy_names = sorted(path.name for path in COPY.glob("s2-g1*"))
    if source_names != copy_names:
        missing = sorted(set(source_names) - set(copy_names))
        extra = sorted(set(copy_names) - set(source_names))
        print(f"[S2-G1-TMP-ARCHIVE][FAIL] missing={missing} extra={extra}")
        return 1

    source = scan(SOURCE, source_names)
    copied = scan(COPY, copy_names)
    if source != copied:
        all_paths = sorted(set(source) | set(copied))
        for rel in all_paths:
            if source.get(rel) != copied.get(rel):
                print(f"[S2-G1-TMP-ARCHIVE][FAIL] {rel} source={source.get(rel)} copy={copied.get(rel)}")
        return 1

    ARCHIVE.mkdir(parents=True, exist_ok=True)
    inventory_lines = ["type\tsize\tsha256-or-link\tpath"]
    hash_lines: list[str] = []
    files = dirs = links = total_bytes = 0
    for rel, (kind, size, value) in sorted(copied.items()):
        inventory_lines.append(f"{kind}\t{size}\t{value}\tsystem-tmp/{rel}")
        if kind == "F":
            files += 1
            total_bytes += size
            hash_lines.append(f"{value}  system-tmp/{rel}")
        elif kind == "D":
            dirs += 1
        elif kind == "L":
            links += 1
    (ARCHIVE / "inventory.tsv").write_text(
        "\n".join(inventory_lines) + "\n", encoding="utf-8"
    )
    (ARCHIVE / "SHA256SUMS").write_text(
        "\n".join(hash_lines) + "\n", encoding="utf-8"
    )
    summary = (
        f"top_level={len(source_names)}\n"
        f"files={files}\n"
        f"directories={dirs}\n"
        f"symlinks={links}\n"
        f"bytes={total_bytes}\n"
        "source_copy_match=PASS\n"
    )
    (ARCHIVE / "archive-summary.txt").write_text(summary, encoding="utf-8")
    print(
        "[S2-G1-TMP-ARCHIVE][PASS] "
        f"top={len(source_names)} files={files} dirs={dirs} "
        f"links={links} bytes={total_bytes}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
