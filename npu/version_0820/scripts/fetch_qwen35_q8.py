#!/usr/bin/env python3
"""Resumable, parallel, project-local fetcher for the pinned Qwen GGUF.

The existing destination is treated as a verified-by-final-hash prefix.  New
HTTP ranges are kept under tmp/ until the complete SHA-256 matches, then the
assembled file atomically replaces the destination.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import os
from pathlib import Path
import re
import sys
import time
import urllib.error
import urllib.request


MODEL_REVISION = "316dea3b5462fd5755862bcec45a2f901bc0ba6b"
MODEL_FILENAME = "Qwen3.5-0.8B-Q8_0.gguf"
MODEL_SIZE = 833_592_096
MODEL_SHA256 = "37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f"
MODEL_URL = (
    "https://huggingface.co/ggml-org/Qwen3.5-0.8B-GGUF/resolve/"
    f"{MODEL_REVISION}/{MODEL_FILENAME}?download=true"
)
CONTENT_RANGE_RE = re.compile(r"^bytes (\d+)-(\d+)/(\d+)$")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def download_range(
    url: str,
    part_path: Path,
    start: int,
    end: int,
    retries: int,
) -> tuple[int, int]:
    expected = end - start + 1
    if part_path.is_file() and part_path.stat().st_size == expected:
        return start, expected
    if part_path.exists():
        part_path.unlink()

    temporary = part_path.with_suffix(part_path.suffix + ".tmp")
    for attempt in range(1, retries + 1):
        if temporary.exists():
            temporary.unlink()
        request = urllib.request.Request(
            url,
            headers={
                "Range": f"bytes={start}-{end}",
                "User-Agent": "opensource-npu-qwen-fetch/1.0",
                "Accept-Encoding": "identity",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                if response.status != 206:
                    raise RuntimeError(f"range {start}-{end}: HTTP {response.status}, expected 206")
                content_range = response.headers.get("Content-Range", "")
                match = CONTENT_RANGE_RE.fullmatch(content_range)
                actual = tuple(int(value) for value in match.groups()) if match else None
                if actual != (start, end, MODEL_SIZE):
                    raise RuntimeError(
                        f"range {start}-{end}: invalid Content-Range {content_range!r}"
                    )
                written = 0
                with temporary.open("wb") as output:
                    while True:
                        block = response.read(1024 * 1024)
                        if not block:
                            break
                        output.write(block)
                        written += len(block)
                if written != expected:
                    raise RuntimeError(
                        f"range {start}-{end}: received {written} bytes, expected {expected}"
                    )
            temporary.replace(part_path)
            return start, expected
        except (OSError, RuntimeError, urllib.error.URLError) as error:
            if attempt == retries:
                raise RuntimeError(
                    f"range {start}-{end} failed after {retries} attempts: {error}"
                ) from error
            time.sleep(min(8, 2 ** (attempt - 1)))
    raise AssertionError("unreachable")


def parse_args(project_root: Path) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--destination",
        type=Path,
        default=project_root / "models" / MODEL_FILENAME,
    )
    parser.add_argument("--workers", type=int, default=8)
    parser.add_argument("--chunk-mib", type=int, default=16)
    parser.add_argument("--retries", type=int, default=8)
    return parser.parse_args()


def main() -> int:
    project_root = Path(__file__).resolve().parent.parent
    args = parse_args(project_root)
    destination = args.destination.resolve()
    allowed_root = project_root.resolve()
    try:
        destination.relative_to(allowed_root)
    except ValueError:
        print(f"destination must remain inside {allowed_root}: {destination}", file=sys.stderr)
        return 2
    if args.workers < 1 or args.chunk_mib < 1 or args.retries < 1:
        print("workers, chunk-mib, and retries must all be positive", file=sys.stderr)
        return 2

    destination.parent.mkdir(parents=True, exist_ok=True)
    workspace = project_root / "tmp" / "model-download" / MODEL_REVISION
    parts_dir = workspace / "parts"
    parts_dir.mkdir(parents=True, exist_ok=True)

    prefix_size = destination.stat().st_size if destination.exists() else 0
    if prefix_size > MODEL_SIZE:
        print(f"existing file is too large: {prefix_size} > {MODEL_SIZE}", file=sys.stderr)
        return 2
    if prefix_size == MODEL_SIZE:
        actual_hash = sha256_file(destination)
        if actual_hash == MODEL_SHA256:
            print(f"[MODEL][PASS] size={MODEL_SIZE} sha256={actual_hash}")
            return 0
        print(f"complete-size file has wrong SHA-256: {actual_hash}", file=sys.stderr)
        return 3

    chunk_bytes = args.chunk_mib * 1024 * 1024
    ranges: list[tuple[int, int, Path]] = []
    start = prefix_size
    while start < MODEL_SIZE:
        end = min(MODEL_SIZE - 1, start + chunk_bytes - 1)
        part_path = parts_dir / f"{start:012d}-{end:012d}.part"
        ranges.append((start, end, part_path))
        start = end + 1

    print(
        f"model={MODEL_FILENAME} prefix={prefix_size} remaining={MODEL_SIZE - prefix_size} "
        f"ranges={len(ranges)} workers={args.workers}"
    )
    completed = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(download_range, MODEL_URL, path, start, end, args.retries): (start, end)
            for start, end, path in ranges
        }
        try:
            for future in concurrent.futures.as_completed(futures):
                _, count = future.result()
                completed += count
                print(
                    f"downloaded={completed}/{MODEL_SIZE - prefix_size} "
                    f"({100.0 * completed / (MODEL_SIZE - prefix_size):.1f}%)",
                    flush=True,
                )
        except Exception as error:
            for pending in futures:
                pending.cancel()
            print(f"download failed: {error}", file=sys.stderr)
            return 4

    assembled = workspace / f"{MODEL_FILENAME}.assembled"
    digest = hashlib.sha256()
    total = 0
    with assembled.open("wb") as output:
        if prefix_size:
            with destination.open("rb") as prefix:
                for block in iter(lambda: prefix.read(4 * 1024 * 1024), b""):
                    output.write(block)
                    digest.update(block)
                    total += len(block)
        for start, end, part_path in ranges:
            expected = end - start + 1
            if part_path.stat().st_size != expected:
                print(f"part changed before assembly: {part_path}", file=sys.stderr)
                return 5
            with part_path.open("rb") as part:
                for block in iter(lambda: part.read(4 * 1024 * 1024), b""):
                    output.write(block)
                    digest.update(block)
                    total += len(block)
        output.flush()
        os.fsync(output.fileno())

    actual_hash = digest.hexdigest()
    if total != MODEL_SIZE or actual_hash != MODEL_SHA256:
        print(
            f"assembled model mismatch: size={total}/{MODEL_SIZE} "
            f"sha256={actual_hash}/{MODEL_SHA256}",
            file=sys.stderr,
        )
        return 6
    assembled.replace(destination)
    print(f"[MODEL][PASS] size={total} sha256={actual_hash}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
