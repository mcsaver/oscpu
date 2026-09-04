#!/usr/bin/env python3
"""Compute a deterministic content identity for a source directory or tarball."""

import argparse
import hashlib
import os
import stat
import tarfile


def add_field(digest: "hashlib._Hash", value: bytes) -> None:
    digest.update(len(value).to_bytes(8, "big"))
    digest.update(value)


def entry_identity(path: bytes, kind: bytes, mode: int, payload: bytes) -> bytes:
    digest = hashlib.sha256()
    add_field(digest, path)
    add_field(digest, kind)
    # Git source identity records only the executable bits.  GNU tar applies
    # the extracting user's umask to ordinary rw bits, so including 0664 vs
    # 0644 would make byte-identical official trees spuriously different.
    add_field(digest, f"{mode & 0o111:o}".encode("ascii"))
    add_field(digest, payload)
    return digest.digest()


def hash_fd(fd: int) -> bytes:
    digest = hashlib.sha256()
    while True:
        chunk = os.read(fd, 1024 * 1024)
        if not chunk:
            break
        digest.update(chunk)
    return digest.digest()


def directory_entries(root: str) -> list[tuple[bytes, bytes]]:
    root_bytes = os.fsencode(os.path.realpath(root))
    if not os.path.isdir(root_bytes):
        raise RuntimeError(f"source root is not a directory: {root}")

    entries: list[tuple[bytes, bytes]] = []

    def visit(directory: bytes, relative: bytes) -> None:
        with os.scandir(directory) as iterator:
            children = sorted(iterator, key=lambda item: item.name)
        for child in children:
            child_name = child.name
            child_relative = child_name if not relative else relative + b"/" + child_name
            child_path = os.path.join(directory, child_name)
            before = os.lstat(child_path)
            if stat.S_ISDIR(before.st_mode):
                identity = entry_identity(child_relative, b"d", before.st_mode, b"")
                entries.append((child_relative, identity))
                visit(child_path, child_relative)
            elif stat.S_ISLNK(before.st_mode):
                target = os.readlink(child_path)
                if isinstance(target, str):
                    target = os.fsencode(target)
                after = os.lstat(child_path)
                if (before.st_dev, before.st_ino, before.st_ctime_ns) != (
                    after.st_dev,
                    after.st_ino,
                    after.st_ctime_ns,
                ):
                    raise RuntimeError(f"source symlink changed while hashing: {child_path!r}")
                identity = entry_identity(child_relative, b"l", before.st_mode, target)
                entries.append((child_relative, identity))
            elif stat.S_ISREG(before.st_mode):
                flags = os.O_RDONLY | os.O_CLOEXEC
                if hasattr(os, "O_NOFOLLOW"):
                    flags |= os.O_NOFOLLOW
                fd = os.open(child_path, flags)
                try:
                    opened = os.fstat(fd)
                    if (before.st_dev, before.st_ino) != (opened.st_dev, opened.st_ino):
                        raise RuntimeError(
                            f"source file identity changed before hashing: {child_path!r}"
                        )
                    payload = opened.st_size.to_bytes(8, "big") + hash_fd(fd)
                    after = os.fstat(fd)
                    if (
                        opened.st_size,
                        opened.st_mtime_ns,
                        opened.st_ctime_ns,
                    ) != (after.st_size, after.st_mtime_ns, after.st_ctime_ns):
                        raise RuntimeError(
                            f"source file changed while hashing: {child_path!r}"
                        )
                finally:
                    os.close(fd)
                identity = entry_identity(child_relative, b"f", before.st_mode, payload)
                entries.append((child_relative, identity))
            else:
                raise RuntimeError(f"unsupported source entry type: {child_path!r}")

    visit(root_bytes, b"")
    return entries


def normalized_tar_path(name: str, prefix: str) -> bytes | None:
    raw = os.fsencode(name.rstrip("/"))
    prefix_bytes = os.fsencode(prefix.rstrip("/"))
    if raw == prefix_bytes:
        return None
    expected = prefix_bytes + b"/"
    if not raw.startswith(expected):
        raise RuntimeError(f"tar member escapes required prefix {prefix!r}: {name!r}")
    relative = raw[len(expected) :]
    components = relative.split(b"/")
    if not relative or any(component in (b"", b".", b"..") for component in components):
        raise RuntimeError(f"unsafe tar member path: {name!r}")
    return relative


def tar_entries(path: str, prefix: str) -> list[tuple[bytes, bytes]]:
    entries: list[tuple[bytes, bytes]] = []
    seen: set[bytes] = set()
    with tarfile.open(path, mode="r:*") as archive:
        for member in archive:
            relative = normalized_tar_path(member.name, prefix)
            if relative is None:
                continue
            if relative in seen:
                raise RuntimeError(f"duplicate tar member after prefix removal: {member.name!r}")
            seen.add(relative)
            if member.isdir():
                kind = b"d"
                payload = b""
            elif member.issym():
                kind = b"l"
                payload = os.fsencode(member.linkname)
            elif member.isfile() or member.islnk():
                kind = b"f"
                stream = archive.extractfile(member)
                if stream is None:
                    raise RuntimeError(f"cannot read tar member: {member.name!r}")
                digest = hashlib.sha256()
                size = 0
                with stream:
                    while True:
                        chunk = stream.read(1024 * 1024)
                        if not chunk:
                            break
                        size += len(chunk)
                        digest.update(chunk)
                if size != member.size:
                    raise RuntimeError(f"short tar member: {member.name!r}")
                payload = size.to_bytes(8, "big") + digest.digest()
            else:
                raise RuntimeError(f"unsupported tar member type: {member.name!r}")
            entries.append(
                (relative, entry_identity(relative, kind, member.mode, payload))
            )
    return entries


def tree_identity(entries: list[tuple[bytes, bytes]]) -> str:
    digest = hashlib.sha256()
    for path, identity in sorted(entries, key=lambda item: item[0]):
        add_field(digest, path)
        add_field(digest, identity)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--directory")
    source.add_argument("--tar")
    parser.add_argument("--strip-prefix")
    args = parser.parse_args()

    if args.directory:
        if args.strip_prefix:
            parser.error("--strip-prefix is only valid with --tar")
        entries = directory_entries(args.directory)
    else:
        if not args.strip_prefix:
            parser.error("--tar requires --strip-prefix")
        entries = tar_entries(args.tar, args.strip_prefix)
    print(tree_identity(entries))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
