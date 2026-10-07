#!/usr/bin/env python3
"""Preserve .deb inputs; restore only the dependency closure selected by APT."""
import hashlib
import os
from pathlib import Path
import shlex
import shutil
import sys
import tempfile


def copy_atomic(source, target):
    if target.is_symlink() or (target.exists() and not target.is_file()):
        raise ValueError(f"unsafe package destination: {target}")
    fd, temporary = tempfile.mkstemp(prefix=".package-", dir=target.parent)
    try:
        with os.fdopen(fd, "wb") as output, source.open("rb") as inp:
            shutil.copyfileobj(inp, output)
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def save(store, archives):
    count = 0
    for source in archives.glob("*.deb"):
        if source.is_symlink() or not source.is_file():
            raise ValueError(f"unsafe package input: {source}")
        target = store / source.name
        if target.exists() and not target.is_symlink():
            if hashlib.sha256(target.read_bytes()).digest() == hashlib.sha256(source.read_bytes()).digest():
                continue
        copy_atomic(source, target)
        count += 1
    return count


def restore(store, archives, lines):
    count = 0
    for line in lines:
        if not line.startswith("'"):
            continue  # APT also writes human-readable dependency information.
        fields = shlex.split(line)
        if len(fields) != 4:
            raise ValueError(f"unrecognized APT URI record: {line.rstrip()}")
        _, name, size, checksum = fields
        if Path(name).name != name or not name.endswith(".deb"):
            raise ValueError(f"unsafe APT package name: {name}")
        source = store / name
        if source.is_symlink():
            raise ValueError(f"unsafe saved package: {source}")
        if not source.is_file() or source.stat().st_size != int(size):
            continue
        algorithm, digest = checksum.split(":", 1)
        algorithm = {"MD5Sum": "md5", "SHA256": "sha256", "SHA512": "sha512"}.get(algorithm)
        if algorithm is None:
            continue  # Let APT download/verify an unfamiliar hash format.
        actual = hashlib.new(algorithm, source.read_bytes()).hexdigest()
        if actual.lower() != digest.lower():
            continue
        copy_atomic(source, archives / name)
        count += 1
    return count


def main():
    action, store_arg, archives_arg = sys.argv[1:]
    store, archives = Path(store_arg), Path(archives_arg)
    for path in (store, archives):
        if path.is_symlink() or not path.is_dir():
            raise ValueError(f"unsafe package directory: {path}")
    if store.resolve() == archives.resolve():
        raise ValueError("saved packages and transaction archives must be distinct")
    if action == "save":
        count = save(store, archives)
    elif action == "restore":
        count = restore(store, archives, sys.stdin)
    else:
        raise ValueError(f"unknown action: {action}")
    print(f"[ubuntu-systemd-overlay] package {action}: {count}", file=sys.stderr)


if __name__ == "__main__":
    main()
