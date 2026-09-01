#!/usr/bin/env python3
"""Install the pinned CMake 3.31.12 tree below this workspace only.

The caller owns the fail-closed task status.  This installer deliberately has
no configurable URL or destination: one invocation downloads the two frozen
official assets, verifies them, extracts regular files/directories manually,
and publishes the validated tree with Linux RENAME_NOREPLACE.
"""

from __future__ import annotations

import ctypes
import errno
import hashlib
import io
import json
import os
import pathlib
import stat
import sys
import tarfile
import urllib.parse
import urllib.request
from typing import Any, BinaryIO


TASK_ID = "qwen-f32-alu-cmake-tool-v1"
VERSION = "3.31.12"
ARCHIVE_TOP = "cmake-3.31.12-linux-x86_64"
CHECKSUM_FILENAME = "cmake-3.31.12-SHA-256.txt"
ARCHIVE_FILENAME = "cmake-3.31.12-linux-x86_64.tar.gz"
CHECKSUM_URL = (
    "https://github.com/Kitware/CMake/releases/download/v3.31.12/"
    + CHECKSUM_FILENAME
)
ARCHIVE_URL = (
    "https://github.com/Kitware/CMake/releases/download/v3.31.12/"
    + ARCHIVE_FILENAME
)
CHECKSUM_FILE_SHA256 = (
    "159eb3b123ba8c8403a154c9d3389432276bf3bd21b274f0396fe17a6a7a7d9d"
)
ARCHIVE_SHA256 = (
    "0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c"
)
EXPECTED_ARCHIVE_LINE = f"{ARCHIVE_SHA256}  {ARCHIVE_FILENAME}"

MAX_CHECKSUM_BYTES = 2 * 1024 * 1024
MAX_ARCHIVE_BYTES = 512 * 1024 * 1024
MAX_MEMBER_COUNT = 100_000
MAX_EXTRACTED_BYTES = 2 * 1024 * 1024 * 1024
DOWNLOAD_CHUNK = 1024 * 1024


class InstallFailure(RuntimeError):
    """A fail-closed installer rejection with an explicit evidence stage."""

    def __init__(self, stage: str, message: str):
        super().__init__(message)
        self.stage = stage


def reject(stage: str, message: str) -> None:
    raise InstallFailure(stage, message)


def lstat_kind(path: pathlib.Path) -> str:
    observed = path.lstat()
    if stat.S_ISREG(observed.st_mode):
        return "regular"
    if stat.S_ISDIR(observed.st_mode):
        return "directory"
    if stat.S_ISLNK(observed.st_mode):
        return "symlink"
    return "special"


def path_absent(path: pathlib.Path) -> bool:
    try:
        path.lstat()
    except FileNotFoundError:
        return True
    return False


def require_real_directory(path: pathlib.Path, stage: str) -> None:
    try:
        observed = path.lstat()
    except FileNotFoundError:
        reject(stage, f"required directory missing: {path}")
    if not stat.S_ISDIR(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        reject(stage, f"directory is not a real directory: {path}")


def require_regular(path: pathlib.Path, stage: str, executable: bool = False) -> os.stat_result:
    try:
        observed = path.lstat()
    except FileNotFoundError:
        reject(stage, f"required file missing: {path}")
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        reject(stage, f"file is not a regular non-symlink: {path}")
    if executable and observed.st_mode & 0o111 == 0:
        reject(stage, f"required executable bit missing: {path}")
    return observed


def read_regular_stable(
    path: pathlib.Path, stage: str, maximum: int | None = None
) -> bytes:
    flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(path, flags)
    except OSError as exc:
        reject(stage, f"cannot open regular file without following links: {path}: {exc}")
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            reject(stage, f"opened object is not regular: {path}")
        if maximum is not None and before.st_size > maximum:
            reject(stage, f"file exceeds size limit: {path}: {before.st_size}")
        chunks: list[bytes] = []
        total = 0
        while True:
            data = os.read(descriptor, DOWNLOAD_CHUNK)
            if not data:
                break
            total += len(data)
            if maximum is not None and total > maximum:
                reject(stage, f"file grew beyond size limit: {path}: {total}")
            chunks.append(data)
        after = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    identity_before = (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns)
    identity_after = (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns)
    if identity_before != identity_after or total != before.st_size:
        reject(stage, f"file changed during stable read: {path}")
    return b"".join(chunks)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fsync_directory(path: pathlib.Path) -> None:
    descriptor = os.open(
        path,
        os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_CLOEXEC", 0),
    )
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def publish_bytes_no_replace(path: pathlib.Path, payload: bytes, mode: int = 0o600) -> None:
    """Atomically publish a retained regular file without replacing any name."""

    require_real_directory(path.parent, "evidence-publication")
    if not path_absent(path):
        reject("evidence-publication", f"refusing to replace retained path: {path}")
    temporary = path.parent / f".{path.name}.tmp.{os.getpid()}"
    if not path_absent(temporary):
        reject("evidence-publication", f"temporary publication collision: {temporary}")
    flags = (
        os.O_WRONLY
        | os.O_CREAT
        | os.O_EXCL
        | getattr(os, "O_CLOEXEC", 0)
        | getattr(os, "O_NOFOLLOW", 0)
    )
    descriptor = os.open(temporary, flags, mode)
    published = False
    try:
        view = memoryview(payload)
        written = 0
        while written < len(view):
            count = os.write(descriptor, view[written:])
            if count <= 0:
                reject("evidence-publication", f"short write: {temporary}")
            written += count
        os.fsync(descriptor)
        os.close(descriptor)
        descriptor = -1
        os.link(temporary, path, follow_symlinks=False)
        published = True
        temporary.unlink()
        fsync_directory(path.parent)
    except BaseException:
        if descriptor >= 0:
            os.close(descriptor)
        if not published and not path_absent(temporary):
            temporary.unlink()
        raise


def publish_json_no_replace(path: pathlib.Path, value: Any) -> None:
    payload = (
        json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        + "\n"
    ).encode("utf-8")
    publish_bytes_no_replace(path, payload)


def sanitized_url(value: str) -> dict[str, Any]:
    parsed = urllib.parse.urlsplit(value)
    return {
        "scheme": parsed.scheme,
        "host": parsed.hostname,
        "port": parsed.port,
        "path": parsed.path,
        "query_present": bool(parsed.query),
        "fragment_present": bool(parsed.fragment),
    }


def validate_https_redirect_url(value: str, stage: str) -> None:
    parsed = urllib.parse.urlsplit(value)
    host = (parsed.hostname or "").lower()
    if parsed.scheme != "https" or parsed.username or parsed.password or parsed.fragment:
        reject(stage, f"unsafe redirect URL: {sanitized_url(value)}")
    if host != "github.com" and not host.endswith(".githubusercontent.com"):
        reject(stage, f"redirect left GitHub HTTPS hosts: {sanitized_url(value)}")


class StrictGitHubRedirectHandler(urllib.request.HTTPRedirectHandler):
    def __init__(self) -> None:
        super().__init__()
        self.chain: list[dict[str, Any]] = []

    def redirect_request(  # type: ignore[override]
        self,
        req: urllib.request.Request,
        fp: BinaryIO,
        code: int,
        msg: str,
        headers: Any,
        newurl: str,
    ) -> urllib.request.Request | None:
        if len(self.chain) >= 5:
            reject("download-redirect", "redirect count exceeded five")
        validate_https_redirect_url(req.full_url, "download-redirect")
        validate_https_redirect_url(newurl, "download-redirect")
        self.chain.append(
            {
                "status": code,
                "from": sanitized_url(req.full_url),
                "to": sanitized_url(newurl),
            }
        )
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def parse_content_length(headers: Any, maximum: int, stage: str) -> int | None:
    values = headers.get_all("Content-Length") or []
    if len(values) > 1 and len(set(values)) != 1:
        reject(stage, f"conflicting Content-Length headers: {values}")
    if not values:
        return None
    raw = values[0].strip()
    if not raw.isascii() or not raw.isdecimal():
        reject(stage, f"invalid Content-Length: {raw!r}")
    length = int(raw)
    if length < 0 or length > maximum:
        reject(stage, f"Content-Length outside bounded range: {length}")
    return length


def download_exact(
    url: str,
    expected_filename: str,
    destination: pathlib.Path,
    maximum: int,
) -> dict[str, Any]:
    stage = f"download-{expected_filename}"
    if url not in (CHECKSUM_URL, ARCHIVE_URL):
        reject(stage, f"URL is not one of the two frozen official inputs: {url}")
    parsed_source = urllib.parse.urlsplit(url)
    if pathlib.PurePosixPath(parsed_source.path).name != expected_filename:
        reject(stage, "source URL filename does not match the frozen destination")
    validate_https_redirect_url(url, stage)
    if not path_absent(destination):
        reject(stage, f"download destination already exists: {destination}")

    redirect_handler = StrictGitHubRedirectHandler()
    opener = urllib.request.build_opener(redirect_handler)
    request = urllib.request.Request(
        url,
        method="GET",
        headers={
            "Accept": "application/octet-stream",
            "Accept-Encoding": "identity",
            "User-Agent": "ysyx-workbench-qwen-f32-cmake-tool-v1",
        },
    )
    flags = (
        os.O_WRONLY
        | os.O_CREAT
        | os.O_EXCL
        | getattr(os, "O_CLOEXEC", 0)
        | getattr(os, "O_NOFOLLOW", 0)
    )
    observed = 0
    digest = hashlib.sha256()
    with opener.open(request, timeout=120) as response:
        if response.getcode() != 200:
            reject(stage, f"unexpected HTTP status: {response.getcode()}")
        final_url = response.geturl()
        validate_https_redirect_url(final_url, stage)
        content_encoding = response.headers.get("Content-Encoding")
        if content_encoding not in (None, "", "identity"):
            reject(stage, f"unexpected Content-Encoding: {content_encoding!r}")
        if response.headers.get("Content-Range") is not None:
            reject(stage, "partial Content-Range response is forbidden")
        declared_length = parse_content_length(response.headers, maximum, stage)
        disposition_filename = response.headers.get_filename()
        if disposition_filename is not None and disposition_filename != expected_filename:
            reject(stage, f"unexpected response filename: {disposition_filename!r}")

        descriptor = os.open(destination, flags, 0o600)
        try:
            while True:
                chunk = response.read(DOWNLOAD_CHUNK)
                if not chunk:
                    break
                observed += len(chunk)
                if observed > maximum:
                    reject(stage, f"download exceeded bounded size: {observed}")
                digest.update(chunk)
                view = memoryview(chunk)
                offset = 0
                while offset < len(view):
                    count = os.write(descriptor, view[offset:])
                    if count <= 0:
                        reject(stage, f"short download write: {destination}")
                    offset += count
            os.fsync(descriptor)
        finally:
            os.close(descriptor)

    if declared_length is not None and observed != declared_length:
        reject(stage, f"Content-Length mismatch: declared={declared_length} observed={observed}")
    stable = read_regular_stable(destination, stage, maximum)
    stable_digest = sha256_bytes(stable)
    if len(stable) != observed or stable_digest != digest.hexdigest():
        reject(stage, "stable re-read did not match downloaded bytes")
    return {
        "requested_url": url,
        "requested_filename": expected_filename,
        "retained_path": str(destination),
        "redirects": redirect_handler.chain,
        "final_url": sanitized_url(final_url),
        "content_disposition_filename": disposition_filename,
        "content_length": declared_length,
        "observed_size_bytes": observed,
        "sha256": stable_digest,
        "stable_read": True,
    }


def validate_checksum_file(data: bytes) -> dict[str, Any]:
    stage = "checksum-file-audit"
    if sha256_bytes(data) != CHECKSUM_FILE_SHA256:
        reject(stage, "checksum-file SHA-256 mismatch")
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        reject(stage, f"checksum file is not UTF-8: {exc}")
    lines = text.splitlines()
    exact_count = sum(line == EXPECTED_ARCHIVE_LINE for line in lines)
    named_entries = []
    for line in lines:
        fields = line.split(maxsplit=1)
        if len(fields) == 2 and fields[1].lstrip("*") == ARCHIVE_FILENAME:
            named_entries.append(line)
    if exact_count != 1 or named_entries != [EXPECTED_ARCHIVE_LINE]:
        reject(
            stage,
            "archive checksum entry is missing, duplicated, or not the exact frozen line",
        )
    return {
        "sha256": CHECKSUM_FILE_SHA256,
        "line_count": len(lines),
        "archive_entry_count": len(named_entries),
        "archive_line": EXPECTED_ARCHIVE_LINE,
    }


def canonical_member_name(member: tarfile.TarInfo) -> str:
    stage = "archive-member-audit"
    raw_name = member.name
    if "\x00" in raw_name or "\\" in raw_name:
        reject(stage, f"archive member has forbidden name bytes: {raw_name!r}")
    if not raw_name or raw_name.startswith("/") or len(raw_name) > 4096:
        reject(stage, f"archive member has invalid absolute/empty/long name: {raw_name!r}")
    name = raw_name[:-1] if raw_name.endswith("/") else raw_name
    parts = name.split("/")
    if any(part in ("", ".", "..") for part in parts):
        reject(stage, f"archive member has non-canonical path component: {raw_name!r}")
    canonical = "/".join(parts)
    if pathlib.PurePosixPath(canonical).is_absolute() or parts[0] != ARCHIVE_TOP:
        reject(stage, f"archive member escapes the single top-level root: {raw_name!r}")
    return canonical


def audit_archive(data: bytes) -> tuple[list[tarfile.TarInfo], dict[str, Any]]:
    stage = "archive-member-audit"
    if sha256_bytes(data) != ARCHIVE_SHA256:
        reject(stage, "archive SHA-256 mismatch before inspection")
    try:
        with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
            members = archive.getmembers()
    except (tarfile.TarError, OSError) as exc:
        reject(stage, f"archive cannot be parsed as gzip tar: {exc}")
    if not members or len(members) > MAX_MEMBER_COUNT:
        reject(stage, f"archive member count outside bounded range: {len(members)}")

    seen: set[str] = set()
    canonical_members: list[tarfile.TarInfo] = []
    regular_count = 0
    directory_count = 0
    extracted_bytes = 0
    top_seen_as_directory = False
    for member in members:
        canonical = canonical_member_name(member)
        if canonical in seen:
            reject(stage, f"duplicate canonical archive member: {canonical}")
        seen.add(canonical)
        if member.issym() or member.islnk():
            reject(stage, f"links are forbidden in the frozen archive: {canonical}")
        if member.isdev() or member.isfifo() or not (member.isdir() or member.isreg()):
            reject(stage, f"special/unknown archive member is forbidden: {canonical}")
        if member.mode & 0o7000:
            reject(stage, f"set-id/sticky archive mode is forbidden: {canonical}")
        if member.sparse:
            reject(stage, f"sparse archive member is forbidden: {canonical}")
        member.name = canonical
        canonical_members.append(member)
        if member.isdir():
            directory_count += 1
            if canonical == ARCHIVE_TOP:
                top_seen_as_directory = True
        else:
            regular_count += 1
            if member.size < 0:
                reject(stage, f"negative archive member size: {canonical}")
            extracted_bytes += member.size
            if extracted_bytes > MAX_EXTRACTED_BYTES:
                reject(stage, "archive extracted byte total exceeds bounded limit")
    if not top_seen_as_directory:
        reject(stage, "archive lacks an explicit top-level directory member")
    return canonical_members, {
        "archive_sha256": ARCHIVE_SHA256,
        "top_level_directory": ARCHIVE_TOP,
        "member_count": len(canonical_members),
        "regular_file_count": regular_count,
        "directory_count": directory_count,
        "symlink_count": 0,
        "hardlink_count": 0,
        "special_count": 0,
        "total_regular_size_bytes": extracted_bytes,
        "duplicate_canonical_name_count": 0,
        "path_escape_count": 0,
        "member_policy": "regular-files-and-directories-only",
    }


def require_parent_chain_real(stage_root: pathlib.Path, destination: pathlib.Path) -> None:
    relative = destination.relative_to(stage_root)
    current = stage_root
    for component in relative.parts[:-1]:
        current = current / component
        observed = current.lstat()
        if not stat.S_ISDIR(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
            reject("archive-extraction", f"non-directory extraction parent: {current}")


def extract_archive_manually(
    data: bytes,
    members: list[tarfile.TarInfo],
    staging_root: pathlib.Path,
) -> pathlib.Path:
    stage = "archive-extraction"
    if not path_absent(staging_root):
        reject(stage, f"staging root already exists: {staging_root}")
    os.mkdir(staging_root, 0o700)

    directory_modes: dict[str, int] = {}
    regular_members: list[tarfile.TarInfo] = []
    for member in members:
        parts = pathlib.PurePosixPath(member.name).parts
        for depth in range(1, len(parts)):
            parent = "/".join(parts[:depth])
            directory_modes.setdefault(parent, 0o755)
        if member.isdir():
            directory_modes[member.name] = member.mode & 0o777
        else:
            regular_members.append(member)

    for relative, _mode in sorted(
        directory_modes.items(), key=lambda item: (item[0].count("/"), item[0])
    ):
        destination = staging_root / pathlib.PurePosixPath(relative)
        if not path_absent(destination):
            reject(stage, f"directory extraction collision: {destination}")
        require_parent_chain_real(staging_root, destination)
        os.mkdir(destination, 0o700)

    try:
        archive = tarfile.open(fileobj=io.BytesIO(data), mode="r:gz")
    except (tarfile.TarError, OSError) as exc:
        reject(stage, f"archive failed to reopen for extraction: {exc}")
    with archive:
        by_name = {member.name: member for member in archive.getmembers()}
        flags = (
            os.O_WRONLY
            | os.O_CREAT
            | os.O_EXCL
            | getattr(os, "O_CLOEXEC", 0)
            | getattr(os, "O_NOFOLLOW", 0)
        )
        for audited in regular_members:
            member = by_name.get(audited.name)
            if member is None or not member.isreg() or member.size != audited.size:
                reject(stage, f"archive member identity changed on reopen: {audited.name}")
            destination = staging_root / pathlib.PurePosixPath(audited.name)
            require_parent_chain_real(staging_root, destination)
            source = archive.extractfile(member)
            if source is None:
                reject(stage, f"regular member lacks payload: {audited.name}")
            descriptor = os.open(destination, flags, 0o600)
            copied = 0
            try:
                while True:
                    chunk = source.read(DOWNLOAD_CHUNK)
                    if not chunk:
                        break
                    copied += len(chunk)
                    if copied > audited.size:
                        reject(stage, f"member exceeded declared size: {audited.name}")
                    view = memoryview(chunk)
                    offset = 0
                    while offset < len(view):
                        count = os.write(descriptor, view[offset:])
                        if count <= 0:
                            reject(stage, f"short extraction write: {audited.name}")
                        offset += count
                if copied != audited.size:
                    reject(
                        stage,
                        f"member size mismatch: {audited.name}: declared={audited.size} copied={copied}",
                    )
                os.fsync(descriptor)
            finally:
                os.close(descriptor)
                source.close()
            os.chmod(destination, audited.mode & 0o777, follow_symlinks=False)

    for relative, mode in sorted(
        directory_modes.items(),
        key=lambda item: (-item[0].count("/"), item[0]),
    ):
        destination = staging_root / pathlib.PurePosixPath(relative)
        observed = destination.lstat()
        if not stat.S_ISDIR(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
            reject(stage, f"extracted directory changed kind: {destination}")
        os.chmod(destination, mode, follow_symlinks=False)
    fsync_directory(staging_root)
    return staging_root / ARCHIVE_TOP


def stable_file_hash_record(path: pathlib.Path, stage: str) -> tuple[int, str]:
    flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(path, flags)
    digest = hashlib.sha256()
    total = 0
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            reject(stage, f"manifest object is not regular: {path}")
        while True:
            chunk = os.read(descriptor, DOWNLOAD_CHUNK)
            if not chunk:
                break
            total += len(chunk)
            digest.update(chunk)
        after = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    if (
        (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns)
        != (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns)
        or total != before.st_size
    ):
        reject(stage, f"manifest file changed during hashing: {path}")
    return total, digest.hexdigest()


def tree_entries(root: pathlib.Path) -> list[dict[str, Any]]:
    stage = "installed-tree-manifest"
    require_real_directory(root, stage)
    entries: list[dict[str, Any]] = []

    def visit(path: pathlib.Path, relative: str) -> None:
        observed = path.lstat()
        mode = stat.S_IMODE(observed.st_mode)
        if stat.S_ISDIR(observed.st_mode) and not stat.S_ISLNK(observed.st_mode):
            entries.append(
                {"path": relative, "kind": "directory", "mode": f"{mode:04o}", "size": 0}
            )
            children = sorted(os.scandir(path), key=lambda entry: entry.name)
            for child in children:
                child_relative = child.name if relative == "." else f"{relative}/{child.name}"
                visit(path / child.name, child_relative)
            return
        if stat.S_ISREG(observed.st_mode):
            size, digest = stable_file_hash_record(path, stage)
            entries.append(
                {
                    "path": relative,
                    "kind": "regular",
                    "mode": f"{mode:04o}",
                    "size": size,
                    "sha256": digest,
                }
            )
            return
        if stat.S_ISLNK(observed.st_mode):
            reject(stage, f"symlink found after links were rejected: {path}")
        reject(stage, f"special object found in installed tree: {path}")

    visit(root, ".")
    return entries


def validate_install_tree(root: pathlib.Path) -> dict[str, Any]:
    stage = "install-tree-validation"
    required_bins = ("cmake", "ctest", "cpack", "ccmake")
    bin_records: dict[str, Any] = {}
    for name in required_bins:
        path = root / "bin" / name
        observed = require_regular(path, stage, executable=True)
        size, digest = stable_file_hash_record(path, stage)
        bin_records[name] = {
            "relative_path": f"bin/{name}",
            "mode": f"{stat.S_IMODE(observed.st_mode):04o}",
            "size": size,
            "sha256": digest,
        }
    share = root / "share" / "cmake-3.31"
    require_real_directory(share, stage)
    entries = tree_entries(root)
    cmake_paths = [
        entry
        for entry in entries
        if entry["path"] == "bin/cmake" and entry["kind"] == "regular"
    ]
    if len(cmake_paths) != 1:
        reject(stage, f"bin/cmake exact regular-file cardinality is {len(cmake_paths)}")
    return {
        "required_bins": bin_records,
        "share_tree": "share/cmake-3.31",
        "entries": entries,
        "entry_count": len(entries),
        "regular_file_count": sum(entry["kind"] == "regular" for entry in entries),
        "directory_count": sum(entry["kind"] == "directory" for entry in entries),
        "symlink_count": 0,
    }


def rename_noreplace(source: pathlib.Path, destination: pathlib.Path) -> None:
    stage = "atomic-install-publication"
    if not path_absent(destination):
        reject(stage, f"final install path already exists: {destination}")
    libc = ctypes.CDLL(None, use_errno=True)
    renameat2 = getattr(libc, "renameat2", None)
    if renameat2 is None:
        reject(stage, "Linux renameat2 is unavailable; unsafe fallback is forbidden")
    renameat2.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
    renameat2.restype = ctypes.c_int
    result = renameat2(
        -100,
        os.fsencode(source),
        -100,
        os.fsencode(destination),
        1,
    )
    if result != 0:
        observed_errno = ctypes.get_errno()
        if observed_errno == errno.EEXIST:
            reject(stage, f"atomic no-replace collision: {destination}")
        reject(stage, f"renameat2(RENAME_NOREPLACE) failed errno={observed_errno}")
    fsync_directory(destination.parent)


def main() -> int:
    if len(sys.argv) != 1:
        reject("argument-admission", "this pinned installer accepts no arguments")
    if os.environ.get("PYTHONDONTWRITEBYTECODE") != "1":
        reject("environment-admission", "PYTHONDONTWRITEBYTECODE=1 is required")

    script = pathlib.Path(__file__).absolute()
    require_regular(script, "path-admission")
    repo_root = script.parents[3].resolve(strict=True)
    npu_root = repo_root / "npu" / "version_0820"
    log_root = npu_root / "tmp" / "logs" / TASK_ID
    tools_root = npu_root / "tmp" / "tools"
    staging_root = tools_root / f"{TASK_ID}-staging"
    final_root = tools_root / f"cmake-{VERSION}"
    require_real_directory(log_root, "path-admission")
    require_real_directory(tools_root, "path-admission")
    if not path_absent(staging_root) or not path_absent(final_root):
        reject("path-admission", "staging/final root must both be fresh and absent")

    for variable in ("TMPDIR", "HOME", "XDG_CACHE_HOME"):
        value = os.environ.get(variable)
        if not value:
            reject("environment-admission", f"{variable} must be explicitly redirected")
        candidate = pathlib.Path(value).absolute()
        try:
            candidate.relative_to(log_root)
        except ValueError:
            reject("environment-admission", f"{variable} escapes task log root: {candidate}")

    checksum_path = log_root / CHECKSUM_FILENAME
    archive_path = log_root / ARCHIVE_FILENAME
    checksum_download = download_exact(
        CHECKSUM_URL, CHECKSUM_FILENAME, checksum_path, MAX_CHECKSUM_BYTES
    )
    checksum_data = read_regular_stable(
        checksum_path, "checksum-file-audit", MAX_CHECKSUM_BYTES
    )
    checksum_audit = validate_checksum_file(checksum_data)

    archive_download = download_exact(
        ARCHIVE_URL, ARCHIVE_FILENAME, archive_path, MAX_ARCHIVE_BYTES
    )
    archive_data = read_regular_stable(archive_path, "archive-digest", MAX_ARCHIVE_BYTES)
    if sha256_bytes(archive_data) != ARCHIVE_SHA256:
        reject("archive-digest", "archive SHA-256 does not match the frozen checksum entry")

    source_provenance = {
        "schema_version": 1,
        "task_id": TASK_ID,
        "release_version": VERSION,
        "origin": "official Kitware CMake GitHub release",
        "checksum_download": checksum_download,
        "archive_download": archive_download,
        "checksum_audit": checksum_audit,
        "expected_checksum_file_sha256": CHECKSUM_FILE_SHA256,
        "expected_archive_sha256": ARCHIVE_SHA256,
        "exact_archive_line": EXPECTED_ARCHIVE_LINE,
        "download_count": 2,
        "workspace_local_only": True,
    }
    provenance_path = log_root / "source-provenance.json"
    publish_json_no_replace(provenance_path, source_provenance)

    members, archive_audit = audit_archive(archive_data)
    archive_audit_path = log_root / "archive-audit.json"
    publish_json_no_replace(archive_audit_path, archive_audit)

    extracted_root = extract_archive_manually(archive_data, members, staging_root)
    validated = validate_install_tree(extracted_root)
    manifest = {
        "schema_version": 1,
        "task_id": TASK_ID,
        "release_version": VERSION,
        "archive_top_level": ARCHIVE_TOP,
        "published_install_name": final_root.name,
        "archive_sha256": ARCHIVE_SHA256,
        "entry_count": validated["entry_count"],
        "regular_file_count": validated["regular_file_count"],
        "directory_count": validated["directory_count"],
        "symlink_count": validated["symlink_count"],
        "entries": validated["entries"],
    }
    manifest_path = log_root / "installed-tree-manifest.json"
    publish_json_no_replace(manifest_path, manifest)
    manifest_data = read_regular_stable(manifest_path, "installed-tree-manifest")
    manifest_sha = sha256_bytes(manifest_data)

    rename_noreplace(extracted_root, final_root)
    try:
        staging_root.rmdir()
    except OSError as exc:
        reject("staging-cleanup", f"staging root did not become empty/absent: {exc}")
    fsync_directory(tools_root)
    if not path_absent(staging_root):
        reject("staging-cleanup", "staging root remains after atomic publication")

    final_validated = validate_install_tree(final_root)
    if final_validated["entries"] != manifest["entries"]:
        reject("post-publication-tree-audit", "installed tree differs from retained manifest")

    installer_data = read_regular_stable(script, "installer-identity")
    result = {
        "schema_version": 1,
        "task_id": TASK_ID,
        "result": "PASS",
        "release_version": VERSION,
        "installer_path": str(script),
        "installer_sha256": sha256_bytes(installer_data),
        "installer_invocation_count": 1,
        "download_count": 2,
        "checksum_file_sha256": CHECKSUM_FILE_SHA256,
        "archive_sha256": ARCHIVE_SHA256,
        "archive_audit_sha256": sha256_bytes(
            read_regular_stable(archive_audit_path, "installer-result")
        ),
        "source_provenance_sha256": sha256_bytes(
            read_regular_stable(provenance_path, "installer-result")
        ),
        "tree_manifest_path": str(manifest_path),
        "tree_manifest_sha256": manifest_sha,
        "tree_entry_count": manifest["entry_count"],
        "install_root": str(final_root),
        "staging_root_absent": True,
        "atomic_publication": "renameat2-RENAME_NOREPLACE",
        "cmake_binary": final_validated["required_bins"]["cmake"],
        "ctest_binary": final_validated["required_bins"]["ctest"],
        "cpack_binary": final_validated["required_bins"]["cpack"],
        "ccmake_binary": final_validated["required_bins"]["ccmake"],
        "share_tree": final_validated["share_tree"],
        "symlink_count": 0,
        "system_write_count": 0,
    }
    result_path = log_root / "installer-result.json"
    publish_json_no_replace(result_path, result)
    print(
        f"[NPU-QWEN-F32-ALU-CMAKE-TOOL-V1][INSTALLER-PASS] "
        f"version={VERSION} archive_sha256={ARCHIVE_SHA256} "
        f"tree_manifest_sha256={manifest_sha} staging_absent=1"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except InstallFailure as exc:
        print(
            f"[NPU-QWEN-F32-ALU-CMAKE-TOOL-V1][INSTALLER-FAIL] "
            f"stage={exc.stage} reason={exc}",
            file=sys.stderr,
        )
        raise SystemExit(1)
    except BaseException as exc:
        print(
            f"[NPU-QWEN-F32-ALU-CMAKE-TOOL-V1][INSTALLER-FAIL] "
            f"stage=unexpected-exception type={type(exc).__name__} reason={exc}",
            file=sys.stderr,
        )
        raise SystemExit(1)
