#!/usr/bin/env python3
"""Verify and inventory the Q0 bridge-idle /tmp archive."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
SOURCE = Path("/tmp")
ARCHIVE = REPO / (
    "tmp/2026-07-15-rv64-ppa-architecture-recovery/"
    "s2-mmu-epoch/q0-bridge-idle"
)
COPY = ARCHIVE / "system-tmp"
EXPECTED_NAMES = sorted(
    [
        "s2-g1-bridge-green.VqGuMQ",
        "s2-g1-bridge-green.FlQ68Y",
        "s2-g1-wrapper-green.1rs52t",
        "s2-g1-wrapper-smoke-r4",
        "s2-g1-wrapper-smoke-r5",
        "s2-q0-bridge-idle.ACwxDr",
        "s2-q0-bridge-idle.OXA4D7",
        "s2-q0-bridge-idle.mz4kqE",
        "s2-q0-bridge-idle.NpgGhb",
        "s2-q0-bridge-idle.sFeQXw",
    ]
)


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
        if not start.exists() and not start.is_symlink():
            result[name] = ("M", 0, "missing")
            continue
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
    copy_names = sorted(path.name for path in COPY.iterdir())
    if copy_names != EXPECTED_NAMES:
        missing = sorted(set(EXPECTED_NAMES) - set(copy_names))
        extra = sorted(set(copy_names) - set(EXPECTED_NAMES))
        print(f"[S2-Q0-TMP-ARCHIVE][FAIL] missing={missing} extra={extra}")
        return 1

    source = scan(SOURCE, EXPECTED_NAMES)
    copied = scan(COPY, EXPECTED_NAMES)
    if source != copied:
        for rel in sorted(set(source) | set(copied)):
            if source.get(rel) != copied.get(rel):
                print(
                    f"[S2-Q0-TMP-ARCHIVE][FAIL] {rel} "
                    f"source={source.get(rel)} copy={copied.get(rel)}"
                )
        return 1

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

    ARCHIVE.mkdir(parents=True, exist_ok=True)
    (ARCHIVE / "inventory.tsv").write_text(
        "\n".join(inventory_lines) + "\n", encoding="utf-8"
    )
    (ARCHIVE / "SHA256SUMS").write_text(
        "\n".join(hash_lines) + "\n", encoding="utf-8"
    )
    summary = (
        f"top_level={len(EXPECTED_NAMES)}\n"
        f"files={files}\n"
        f"directories={dirs}\n"
        f"symlinks={links}\n"
        f"bytes={total_bytes}\n"
        "source_copy_match=PASS\n"
    )
    (ARCHIVE / "archive-summary.txt").write_text(summary, encoding="utf-8")
    print(
        "[S2-Q0-TMP-ARCHIVE][PASS] "
        f"top={len(EXPECTED_NAMES)} files={files} dirs={dirs} "
        f"links={links} bytes={total_bytes}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
