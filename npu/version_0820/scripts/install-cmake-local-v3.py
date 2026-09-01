#!/usr/bin/env python3
"""从 v2 冻结输入资格化工作区内的 CMake 3.31.12。

调用者负责 fail-closed 状态机。本安装器不接受参数、不包含网络下载路径；它稳定读取并
复核 v2 保存的官方 checksum/archive 及下载 provenance，将两份源对象以 exclusive/
no-follow 方式复制到 v3 证据目录，随后安全审计、手工解包并用 RENAME_NOREPLACE 发布。
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
from typing import Any


TASK_ID = "qwen-f32-alu-cmake-tool-v3"
PREDECESSOR_TASK_ID = "qwen-f32-alu-cmake-tool-v2"
VERSION = "3.31.12"
ARCHIVE_TOP = "cmake-3.31.12-linux-x86_64"
CHECKSUM_FILENAME = "cmake-3.31.12-SHA-256.txt"
ARCHIVE_FILENAME = "cmake-3.31.12-linux-x86_64.tar.gz"
CHECKSUM_FILE_SHA256 = (
    "159eb3b123ba8c8403a154c9d3389432276bf3bd21b274f0396fe17a6a7a7d9d"
)
ARCHIVE_SHA256 = (
    "0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c"
)
EXPECTED_ARCHIVE_LINE = f"{ARCHIVE_SHA256}  {ARCHIVE_FILENAME}"

V2_CHECKSUM_DOWNLOAD_SHA256 = (
    "a1e4dea26b1feb265500df8ac0f4f67e10b95606601bb69032143a06fd6a9288"
)
V2_ARCHIVE_DOWNLOAD_SHA256 = (
    "2761148ced5c427be716eaae78cca64043030523241d2ba7bb218dc2a38f55ff"
)
V2_PROVENANCE_SHA256 = (
    "2c23184af1e1ae90c6acc14a2c9c95e35f92878e1d54dd23084f301a72b2e6f3"
)
EXPECTED_CHECKSUM_SIZE = 1663
EXPECTED_ARCHIVE_SIZE = 55_005_786

MAX_CHECKSUM_BYTES = 2 * 1024 * 1024
MAX_ARCHIVE_BYTES = 512 * 1024 * 1024
MAX_EVIDENCE_BYTES = 2 * 1024 * 1024
MAX_MEMBER_COUNT = 100_000
MAX_EXTRACTED_BYTES = 2 * 1024 * 1024 * 1024
IO_CHUNK = 1024 * 1024


class InstallFailure(RuntimeError):
    """带确定 evidence stage 的 fail-closed 拒绝。"""

    def __init__(self, stage: str, message: str):
        super().__init__(message)
        self.stage = stage


def reject(stage: str, message: str) -> None:
    raise InstallFailure(stage, message)


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


def require_regular(
    path: pathlib.Path, stage: str, executable: bool = False
) -> os.stat_result:
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
            data = os.read(descriptor, IO_CHUNK)
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


def publish_bytes_no_replace(
    path: pathlib.Path, payload: bytes, mode: int = 0o600
) -> None:
    """用 exclusive/no-follow 临时文件和 hard link 发布 retained regular file。"""

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
    linked = False
    try:
        view = memoryview(payload)
        offset = 0
        while offset < len(view):
            count = os.write(descriptor, view[offset:])
            if count <= 0:
                reject("evidence-publication", f"short write: {temporary}")
            offset += count
        os.fsync(descriptor)
        os.close(descriptor)
        descriptor = -1
        os.link(temporary, path, follow_symlinks=False)
        linked = True
        temporary.unlink()
        fsync_directory(path.parent)
    except BaseException:
        if descriptor >= 0:
            os.close(descriptor)
        if not linked and not path_absent(temporary):
            temporary.unlink()
        raise


def publish_json_no_replace(path: pathlib.Path, value: Any) -> None:
    payload = (
        json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        + "\n"
    ).encode("utf-8")
    publish_bytes_no_replace(path, payload)


def validate_checksum_file(data: bytes) -> dict[str, Any]:
    stage = "checksum-file-audit"
    if len(data) != EXPECTED_CHECKSUM_SIZE:
        reject(stage, f"checksum-file size mismatch: {len(data)}")
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
        "size_bytes": len(data),
        "line_count": len(lines),
        "archive_entry_count": len(named_entries),
        "archive_line": EXPECTED_ARCHIVE_LINE,
    }


def load_json_exact(
    path: pathlib.Path, expected_sha: str, stage: str
) -> tuple[dict[str, Any], bytes]:
    data = read_regular_stable(path, stage, MAX_EVIDENCE_BYTES)
    actual = sha256_bytes(data)
    if actual != expected_sha:
        reject(stage, f"predecessor evidence hash mismatch: {path}: {actual}")
    try:
        value = json.loads(data)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        reject(stage, f"predecessor evidence is not canonical JSON: {path}: {exc}")
    if not isinstance(value, dict):
        reject(stage, f"predecessor evidence root is not an object: {path}")
    return value, data


def validate_predecessor_provenance(v2_log_root: pathlib.Path) -> dict[str, Any]:
    stage = "predecessor-source-provenance"
    checksum_log_path = v2_log_root / "checksum-download.log"
    archive_log_path = v2_log_root / "archive-download.log"
    provenance_path = v2_log_root / "source-provenance.json"
    checksum_log, checksum_log_data = load_json_exact(
        checksum_log_path, V2_CHECKSUM_DOWNLOAD_SHA256, stage
    )
    archive_log, archive_log_data = load_json_exact(
        archive_log_path, V2_ARCHIVE_DOWNLOAD_SHA256, stage
    )
    provenance, provenance_data = load_json_exact(
        provenance_path, V2_PROVENANCE_SHA256, stage
    )
    if (
        checksum_log.get("return_code") != 0
        or checksum_log.get("sha256") != CHECKSUM_FILE_SHA256
        or checksum_log.get("observed_size_bytes") != EXPECTED_CHECKSUM_SIZE
        or checksum_log.get("content_length") != EXPECTED_CHECKSUM_SIZE
        or checksum_log.get("requested_filename") != CHECKSUM_FILENAME
    ):
        reject(stage, "v2 checksum download provenance mismatch")
    if (
        archive_log.get("return_code") != 0
        or archive_log.get("sha256") != ARCHIVE_SHA256
        or archive_log.get("observed_size_bytes") != EXPECTED_ARCHIVE_SIZE
        or archive_log.get("content_length") != EXPECTED_ARCHIVE_SIZE
        or archive_log.get("requested_filename") != ARCHIVE_FILENAME
    ):
        reject(stage, "v2 archive download provenance mismatch")
    if (
        provenance.get("task_id") != PREDECESSOR_TASK_ID
        or provenance.get("release_version") != VERSION
        or provenance.get("download_count") != 2
        or provenance.get("download_return_codes") != [0, 0]
        or provenance.get("expected_checksum_file_sha256") != CHECKSUM_FILE_SHA256
        or provenance.get("expected_archive_sha256") != ARCHIVE_SHA256
        or provenance.get("checksum_download") != checksum_log
        or provenance.get("archive_download") != archive_log
    ):
        reject(stage, "v2 aggregate source provenance mismatch")
    return {
        "checksum_download_log": {
            "path": str(checksum_log_path),
            "size": len(checksum_log_data),
            "sha256": V2_CHECKSUM_DOWNLOAD_SHA256,
        },
        "archive_download_log": {
            "path": str(archive_log_path),
            "size": len(archive_log_data),
            "sha256": V2_ARCHIVE_DOWNLOAD_SHA256,
        },
        "source_provenance": {
            "path": str(provenance_path),
            "size": len(provenance_data),
            "sha256": V2_PROVENANCE_SHA256,
        },
        "qualified_predecessor_download_count": 2,
        "network_download_count": 0,
    }


def copy_frozen_input(
    source: pathlib.Path,
    destination: pathlib.Path,
    expected_sha: str,
    expected_size: int,
    maximum: int,
) -> tuple[bytes, dict[str, Any]]:
    stage = "predecessor-source-copy"
    source_data = read_regular_stable(source, stage, maximum)
    source_sha = sha256_bytes(source_data)
    if len(source_data) != expected_size or source_sha != expected_sha:
        reject(
            stage,
            f"v2 retained source identity mismatch: {source}: size={len(source_data)} sha256={source_sha}",
        )
    publish_bytes_no_replace(destination, source_data)
    copied_data = read_regular_stable(destination, stage, maximum)
    copied_sha = sha256_bytes(copied_data)
    if copied_data != source_data or len(copied_data) != expected_size or copied_sha != expected_sha:
        reject(stage, f"copied retained source differs from v2 bytes: {destination}")
    return copied_data, {
        "source_path": str(source),
        "source_size": len(source_data),
        "source_sha256": source_sha,
        "copied_path": str(destination),
        "copied_size": len(copied_data),
        "copied_sha256": copied_sha,
        "exclusive_no_follow_copy": True,
        "same_bytes": True,
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
    if len(data) != EXPECTED_ARCHIVE_SIZE:
        reject(stage, f"archive size mismatch before inspection: {len(data)}")
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
    census: list[dict[str, Any]] = []
    regular_count = 0
    directory_count = 0
    descendant_count = 0
    explicit_top_directory_count = 0
    extracted_bytes = 0
    for archive_index, member in enumerate(members):
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
        if canonical == ARCHIVE_TOP:
            if not member.isdir():
                reject(stage, "explicit top-level member is not a directory")
            explicit_top_directory_count += 1
        else:
            if not canonical.startswith(ARCHIVE_TOP + "/"):
                reject(stage, f"member is not strictly below top directory: {canonical}")
            descendant_count += 1
        member.name = canonical
        canonical_members.append(member)
        kind = "directory" if member.isdir() else "regular"
        if member.isdir():
            directory_count += 1
            member_size = 0
        else:
            regular_count += 1
            if member.size < 0:
                reject(stage, f"negative archive member size: {canonical}")
            extracted_bytes += member.size
            if extracted_bytes > MAX_EXTRACTED_BYTES:
                reject(stage, "archive extracted byte total exceeds bounded limit")
            member_size = member.size
        census.append(
            {
                "archive_index": archive_index,
                "path": canonical,
                "kind": kind,
                "mode": f"{member.mode & 0o777:04o}",
                "size": member_size,
            }
        )
    if explicit_top_directory_count not in (0, 1):
        reject(stage, f"explicit top directory cardinality invalid: {explicit_top_directory_count}")
    if descendant_count < 1:
        reject(stage, "archive contains no member strictly below the top directory")
    implicit_top_directory = explicit_top_directory_count == 0
    return canonical_members, {
        "schema_version": 1,
        "task_id": TASK_ID,
        "archive_sha256": ARCHIVE_SHA256,
        "archive_size_bytes": len(data),
        "top_level_directory": ARCHIVE_TOP,
        "explicit_top_directory_count": explicit_top_directory_count,
        "implicit_top_directory": implicit_top_directory,
        "implicit_top_directory_synthesized_mode": "0755" if implicit_top_directory else None,
        "descendant_member_count": descendant_count,
        "member_count": len(canonical_members),
        "member_census_count": len(census),
        "member_census_complete": True,
        "member_census": census,
        "regular_file_count": regular_count,
        "directory_count": directory_count,
        "symlink_count": 0,
        "hardlink_count": 0,
        "special_count": 0,
        "sparse_count": 0,
        "setid_sticky_mode_count": 0,
        "total_regular_size_bytes": extracted_bytes,
        "duplicate_canonical_name_count": 0,
        "path_escape_count": 0,
        "member_policy": "regular-files-and-directories-only-below-single-top",
    }


def require_parent_chain_real(
    stage_root: pathlib.Path, destination: pathlib.Path
) -> None:
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

    # 官方包省略独立顶层目录项时，后代路径仍唯一确定 ARCHIVE_TOP；这里仅合成 0755 容器。
    directory_modes: dict[str, int] = {ARCHIVE_TOP: 0o755}
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
        reopened: dict[str, tarfile.TarInfo] = {}
        for member in archive.getmembers():
            canonical = canonical_member_name(member)
            if canonical in reopened:
                reject(stage, f"duplicate member appeared on reopen: {canonical}")
            reopened[canonical] = member
        flags = (
            os.O_WRONLY
            | os.O_CREAT
            | os.O_EXCL
            | getattr(os, "O_CLOEXEC", 0)
            | getattr(os, "O_NOFOLLOW", 0)
        )
        for audited in regular_members:
            member = reopened.get(audited.name)
            if (
                member is None
                or not member.isreg()
                or member.size != audited.size
                or (member.mode & 0o777) != (audited.mode & 0o777)
            ):
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
                    chunk = source.read(IO_CHUNK)
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
        directory_modes.items(), key=lambda item: (-item[0].count("/"), item[0])
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
    try:
        descriptor = os.open(path, flags)
    except OSError as exc:
        reject(stage, f"cannot open manifest file: {path}: {exc}")
    digest = hashlib.sha256()
    total = 0
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            reject(stage, f"manifest object is not regular: {path}")
        while True:
            chunk = os.read(descriptor, IO_CHUNK)
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
    renameat2.argtypes = [
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_uint,
    ]
    renameat2.restype = ctypes.c_int
    result = renameat2(-100, os.fsencode(source), -100, os.fsencode(destination), 1)
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
    v2_log_root = npu_root / "tmp" / "logs" / PREDECESSOR_TASK_ID
    tools_root = npu_root / "tmp" / "tools"
    staging_root = tools_root / f"{TASK_ID}-staging"
    final_root = tools_root / f"cmake-{VERSION}"
    require_real_directory(log_root, "path-admission")
    require_real_directory(v2_log_root, "path-admission")
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

    provenance = validate_predecessor_provenance(v2_log_root)
    checksum_source = v2_log_root / CHECKSUM_FILENAME
    archive_source = v2_log_root / ARCHIVE_FILENAME
    checksum_path = log_root / CHECKSUM_FILENAME
    archive_path = log_root / ARCHIVE_FILENAME
    checksum_data, checksum_copy = copy_frozen_input(
        checksum_source,
        checksum_path,
        CHECKSUM_FILE_SHA256,
        EXPECTED_CHECKSUM_SIZE,
        MAX_CHECKSUM_BYTES,
    )
    archive_data, archive_copy = copy_frozen_input(
        archive_source,
        archive_path,
        ARCHIVE_SHA256,
        EXPECTED_ARCHIVE_SIZE,
        MAX_ARCHIVE_BYTES,
    )
    checksum_audit = validate_checksum_file(checksum_data)

    input_binding = {
        "schema_version": 1,
        "task_id": TASK_ID,
        "predecessor_task_id": PREDECESSOR_TASK_ID,
        "release_version": VERSION,
        "origin": "official Kitware CMake GitHub release retained by immutable v2",
        "network_download_count": 0,
        "qualified_predecessor_download_count": 2,
        "copied_source_object_count": 2,
        "checksum_copy": checksum_copy,
        "archive_copy": archive_copy,
        "checksum_audit": checksum_audit,
        "predecessor_download_provenance": provenance,
        "workspace_local_only": True,
    }
    input_binding_path = log_root / "predecessor-input-binding.json"
    publish_json_no_replace(input_binding_path, input_binding)

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
        "archive_audit_sha256": sha256_bytes(
            read_regular_stable(archive_audit_path, "installed-tree-manifest")
        ),
        "implicit_top_directory": archive_audit["implicit_top_directory"],
        "explicit_top_directory_count": archive_audit["explicit_top_directory_count"],
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
    input_binding_data = read_regular_stable(input_binding_path, "installer-result")
    archive_audit_data = read_regular_stable(archive_audit_path, "installer-result")
    result = {
        "schema_version": 1,
        "task_id": TASK_ID,
        "result": "PASS",
        "release_version": VERSION,
        "installer_path": str(script),
        "installer_sha256": sha256_bytes(installer_data),
        "installer_invocation_count": 1,
        "network_download_count": 0,
        "qualified_predecessor_download_count": 2,
        "copied_source_object_count": 2,
        "checksum_file_sha256": CHECKSUM_FILE_SHA256,
        "archive_sha256": ARCHIVE_SHA256,
        "predecessor_input_binding_sha256": sha256_bytes(input_binding_data),
        "archive_audit_sha256": sha256_bytes(archive_audit_data),
        "explicit_top_directory_count": archive_audit["explicit_top_directory_count"],
        "implicit_top_directory": archive_audit["implicit_top_directory"],
        "member_count": archive_audit["member_count"],
        "member_census_complete": archive_audit["member_census_complete"],
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
        f"[NPU-QWEN-F32-ALU-CMAKE-TOOL-V3][INSTALLER-PASS] "
        f"version={VERSION} checksum_file_sha256={CHECKSUM_FILE_SHA256} "
        f"archive_sha256={ARCHIVE_SHA256} archive_audit_sha256={sha256_bytes(archive_audit_data)} "
        f"tree_manifest_sha256={manifest_sha} explicit_top_directory_count="
        f"{archive_audit['explicit_top_directory_count']} implicit_top_directory="
        f"{int(archive_audit['implicit_top_directory'])} network_download_count=0 staging_absent=1"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except InstallFailure as exc:
        print(
            f"[NPU-QWEN-F32-ALU-CMAKE-TOOL-V3][INSTALLER-FAIL] "
            f"stage={exc.stage} reason={exc}",
            file=sys.stderr,
        )
        raise SystemExit(1)
    except BaseException as exc:
        print(
            f"[NPU-QWEN-F32-ALU-CMAKE-TOOL-V3][INSTALLER-FAIL] "
            f"stage=unexpected-exception type={type(exc).__name__} reason={exc}",
            file=sys.stderr,
        )
        raise SystemExit(1)
