#!/usr/bin/env python3
"""Acquire path-stable advisory locks and exec a command.

The ordinary ``flock PATH command`` interface opens PATH itself and therefore
follows a final symlink.  Shell redirections have the same problem and ``>``
also truncates an existing target before validation.  Build locks live beside
user-selectable output directories, so open them without following symlinks,
validate the opened inode, then preserve the descriptors across exec.
"""

from __future__ import annotations

import fcntl
import os
import stat
import sys


def fail(message: str) -> "NoReturn":
    print(f"safe-flock: {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_args(argv: list[str]) -> tuple[list[str], list[str]]:
    try:
        separator = argv.index("--")
    except ValueError:
        fail("usage: safe-flock.py LOCK [LOCK ...] -- COMMAND [ARG ...]")
    locks = argv[:separator]
    command = argv[separator + 1 :]
    if not locks or not command:
        fail("usage: safe-flock.py LOCK [LOCK ...] -- COMMAND [ARG ...]")
    return locks, command


def validate_open_lock(path: str, fd: int) -> os.stat_result:
    opened = os.fstat(fd)
    if not stat.S_ISREG(opened.st_mode):
        fail(f"lock is not a regular file: {path}")
    if opened.st_nlink != 1:
        fail(f"lock has {opened.st_nlink} hard links (expected 1): {path}")
    if opened.st_uid != os.geteuid():
        fail(f"lock is not owned by uid {os.geteuid()}: {path}")

    try:
        named = os.lstat(path)
    except OSError as exc:
        fail(f"cannot revalidate lock path {path}: {exc}")
    if stat.S_ISLNK(named.st_mode):
        fail(f"lock path became a symbolic link: {path}")
    if (named.st_dev, named.st_ino) != (opened.st_dev, opened.st_ino):
        fail(f"lock path changed while it was being opened: {path}")
    return opened


def main(argv: list[str]) -> "NoReturn":
    raw_locks, command = parse_args(argv)
    locks = sorted(os.path.abspath(os.path.normpath(path)) for path in raw_locks)
    if len(set(locks)) != len(locks):
        fail("two requested lock paths resolve to the same lexical path")

    descriptors: list[tuple[str, int, os.stat_result]] = []
    inodes: dict[tuple[int, int], str] = {}
    flags = os.O_RDWR | os.O_CREAT | os.O_CLOEXEC | os.O_NONBLOCK
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW

    try:
        for path in locks:
            try:
                fd = os.open(path, flags, 0o600)
            except OSError as exc:
                fail(f"cannot safely open lock {path}: {exc}")
            descriptors.append((path, fd, validate_open_lock(path, fd)))

        for path, _fd, opened in descriptors:
            inode = (opened.st_dev, opened.st_ino)
            if inode in inodes:
                fail(f"lock aliases {inodes[inode]}: {path}")
            inodes[inode] = path

        # Acquire by object identity, not by the spelling of the pathname.
        # The same persistent lock can be reached through different symlinked
        # parent directories; lexical ordering would then permit K->B in one
        # process and B->K in another.  Every caller that reaches the same lock
        # inodes now computes the same global order.
        descriptors.sort(key=lambda item: (item[2].st_dev, item[2].st_ino))
        for path, fd, _opened in descriptors:
            try:
                fcntl.flock(fd, fcntl.LOCK_EX)
            except OSError as exc:
                fail(f"cannot acquire lock {path}: {exc}")
            validate_open_lock(path, fd)

        # A pathname validated before waiting for a later lock may have been
        # exchanged while this process was blocked.  Revalidate the complete
        # set only after all locks are held so no stale descriptor is handed to
        # the protected command.
        for path, fd, _opened in descriptors:
            validate_open_lock(path, fd)

        for _path, fd, _opened in descriptors:
            os.set_inheritable(fd, True)
        try:
            os.execvp(command[0], command)
        except OSError as exc:
            fail(f"cannot execute {command[0]}: {exc}")
    finally:
        for _path, fd, _opened in descriptors:
            try:
                os.close(fd)
            except OSError:
                pass


if __name__ == "__main__":
    main(sys.argv[1:])
