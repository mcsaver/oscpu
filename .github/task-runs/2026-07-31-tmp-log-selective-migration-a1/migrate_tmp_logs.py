#!/usr/bin/env python3
"""选择性迁移 tmp 日志与 Yosys 结果，并清除历史 raw payload。"""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import importlib.util
import json
import os
import re
import shutil
import signal
import stat
import subprocess
import sys
import tarfile
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


REPO_ROOT = Path("/home/lyg/PA/ysyx-workbench")
RUN_ID = "2026-07-31-tmp-log-selective-migration-a1"
RUN_ROOT = REPO_ROOT / ".github/task-runs" / RUN_ID
EVIDENCE_ROOT = RUN_ROOT / "evidence"
INVENTORY_PATH = EVIDENCE_ROOT / "tmp-log-inventory.json"
INVENTORY_SUMMARY_PATH = EVIDENCE_ROOT / "tmp-log-summary.json"
SCRIPT_PATH = RUN_ROOT / "migrate_tmp_logs.py"
WRAPPER_PATH = RUN_ROOT / "execute_migration.sh"
PHASE2_SCRIPT = (
    REPO_ROOT
    / ".github/task-runs/2026-07-31-workspace-temp-untrack-cleanup-a2/"
    "cleanup_second_phase.py"
)
PLAN_PATH = EVIDENCE_ROOT / "migration-plan.json"
PLAN_SHA_PATH = EVIDENCE_ROOT / "migration-plan.sha256"
PLAN_TSV_PATH = EVIDENCE_ROOT / "migration-plan.tsv"
PREVIEW_PATH = EVIDENCE_ROOT / "migration-preview.json"
RESULT_PATH = EVIDENCE_ROOT / "migration-result.json"
STAGE_PATH = EVIDENCE_ROOT / "migration-stage.json"
JOURNAL_PATH = EVIDENCE_ROOT / "migration-journal.jsonl"
STATUS_PATH = RUN_ROOT / "migration.status"
QUARANTINE_PATH = EVIDENCE_ROOT / ".migration-quarantine"
SHARED_LOCK_PATH = (
    REPO_ROOT
    / ".github/task-runs/2026-07-31-workspace-artifact-cleanup-a1/"
    "evidence/cleanup.lock"
)
ARCHIVE_ROOT = (
    REPO_ROOT
    / ".github/runtime-artifacts/rv64-artifact-archive"
    / RUN_ID
)
RUNTIME_MANIFEST_PATH = ARCHIVE_ROOT / "migration-manifest.json"
RUNTIME_CHECKSUM_PATH = ARCHIVE_ROOT / "SHA256SUMS"

ARCHIVE_NAMES = {
    "archive-latest-yosys": "latest-yosys-full.tar.zst",
    "archive-small-logs": "verification-logs.tar.zst",
    "archive-historical-synthesis": "historical-synthesis-results.tar.zst",
}


class MigrationError(RuntimeError):
    """迁移前置条件或执行不变量失败。"""


class MigrationInterrupted(MigrationError):
    """HUP/INT/TERM 中断标记。"""


def load_phase2():
    spec = importlib.util.spec_from_file_location(
        "workspace_cleanup_phase2", PHASE2_SCRIPT
    )
    if spec is None or spec.loader is None:
        raise MigrationError("无法加载第二阶段清理保护库")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.PHASE1.RUN_ROOT = RUN_ROOT
    return module


PHASE2 = load_phase2()


def run(
    argv: list[str],
    *,
    check: bool = True,
    input_bytes: bytes | None = None,
) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        argv,
        cwd=REPO_ROOT,
        input=input_bytes,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=check,
    )


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def relative(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_bytes(data)
    os.replace(temporary, path)


def write_json(path: Path, value: Any) -> None:
    atomic_write(
        path,
        (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode(),
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            block = handle.read(8 * 1024 * 1024)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def active_engineering_processes() -> list[dict[str, Any]]:
    return PHASE2.active_engineering_processes()


def acquire_migration_lock():
    SHARED_LOCK_PATH.parent.mkdir(parents=True, exist_ok=True)
    handle = SHARED_LOCK_PATH.open("a+", encoding="utf-8")
    try:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError as error:
        handle.close()
        raise MigrationError("已有清理/迁移任务持有排他锁") from error
    handle.seek(0)
    handle.truncate()
    handle.write(f"run_id={RUN_ID} pid={os.getpid()} acquired_at={utc_now()}\n")
    handle.flush()
    os.fsync(handle.fileno())
    return handle


def write_stage(
    stage: str,
    *,
    archived_count: int,
    staged_count: int,
    purged_count: int,
    detail: str | None = None,
) -> None:
    value: dict[str, Any] = {
        "run_id": RUN_ID,
        "stage": stage,
        "updated_at": utc_now(),
        "archive_count": archived_count,
        "staged_source_count": staged_count,
        "purged_source_count": purged_count,
    }
    if detail:
        value["detail"] = detail
    write_json(STAGE_PATH, value)


def source_identity(path: Path, *, digest: str | None = None) -> dict[str, Any]:
    if path.is_symlink() or not path.is_file():
        raise MigrationError(f"只迁移普通文件：{relative(path)}")
    metadata = path.stat(follow_symlinks=False)
    return {
        "device": metadata.st_dev,
        "inode": metadata.st_ino,
        "mode": stat.S_IFMT(metadata.st_mode),
        "mtime_ns": metadata.st_mtime_ns,
        "size_bytes": metadata.st_size,
        "sha256": digest if digest is not None else sha256_file(path),
    }


def entry_stat_matches(item: dict[str, Any], metadata: os.stat_result) -> bool:
    return (
        metadata.st_dev == item["device"]
        and metadata.st_ino == item["inode"]
        and stat.S_IFMT(metadata.st_mode) == item["mode"]
        and metadata.st_mtime_ns == item["mtime_ns"]
        and metadata.st_size == item["size_bytes"]
    )


def open_anchored_parent(rel: str) -> tuple[int, str]:
    pure = PurePosixPath(rel)
    if pure.is_absolute() or not pure.parts or any(
        part in {"", ".", ".."} for part in pure.parts
    ):
        raise MigrationError(f"非法锚定路径：{rel}")
    flags = (
        os.O_RDONLY
        | os.O_DIRECTORY
        | getattr(os, "O_NOFOLLOW", 0)
        | getattr(os, "O_CLOEXEC", 0)
    )
    current_fd = os.open(REPO_ROOT, flags)
    try:
        for component in pure.parts[:-1]:
            next_fd = os.open(component, flags, dir_fd=current_fd)
            os.close(current_fd)
            current_fd = next_fd
        return current_fd, pure.parts[-1]
    except BaseException:
        os.close(current_fd)
        raise


def journal_record(handle, value: dict[str, Any], *, durable: bool = False) -> None:
    handle.write(
        (json.dumps(value, ensure_ascii=False, sort_keys=True) + "\n").encode()
    )
    handle.flush()
    if durable:
        os.fsync(handle.fileno())


def string_set_snapshot(values: Iterable[str]) -> dict[str, Any]:
    normalized = sorted(set(values))
    digest = hashlib.sha256()
    for value in normalized:
        digest.update(value.encode(errors="surrogateescape"))
        digest.update(b"\0")
    return {"count": len(normalized), "sha256": digest.hexdigest()}


def load_inventory() -> tuple[list[dict[str, Any]], dict[str, Any]]:
    logs = json.loads(INVENTORY_PATH.read_text(encoding="utf-8"))
    summary = json.loads(INVENTORY_SUMMARY_PATH.read_text(encoding="utf-8"))
    if not isinstance(logs, list) or summary.get("schema_version") != 1:
        raise MigrationError("日志盘点 schema 不匹配")
    if summary.get("log_count") != len(logs):
        raise MigrationError("日志盘点数量不匹配")
    return logs, summary


def collect_regular_files(root: Path) -> list[Path]:
    result: list[Path] = []
    for root_raw, dir_names, file_names in os.walk(
        root, topdown=True, followlinks=False
    ):
        directory = Path(root_raw)
        retained_dirs: list[str] = []
        for name in dir_names:
            child = directory / name
            if child.is_symlink():
                raise MigrationError(f"迁移树内不允许符号链接：{relative(child)}")
            retained_dirs.append(name)
        dir_names[:] = retained_dirs
        for name in file_names:
            child = directory / name
            if child.is_symlink() or not child.is_file():
                raise MigrationError(f"迁移树内仅允许普通文件：{relative(child)}")
            result.append(child)
    return sorted(result, key=lambda item: relative(item))


def discover_sources(
    logs: list[dict[str, Any]], summary: dict[str, Any]
) -> tuple[list[dict[str, Any]], dict[str, list[str]], str]:
    latest = summary.get("latest_yosys")
    if not isinstance(latest, dict) or not isinstance(latest.get("path"), str):
        raise MigrationError("没有可迁移的 latest Yosys 日志")
    latest_log = REPO_ROOT / latest["path"]
    latest_run_root = latest_log.parents[2]
    if latest_run_root.name != "fresh-synth-run2":
        raise MigrationError(
            f"latest Yosys 根不符合 fresh-synth-run2 边界：{relative(latest_run_root)}"
        )
    latest_paths = {relative(path) for path in collect_regular_files(latest_run_root)}

    log_by_path = {item["path"]: item for item in logs}
    if set(log_by_path) != {
        relative(path)
        for path in (REPO_ROOT / "tmp").rglob("*")
        if path.is_file()
        and not path.is_symlink()
        and path.name.lower().endswith((".log", ".log.gz", ".log.xz", ".log.zst"))
        and not any(
            is_within(path.resolve(strict=False), root)
            for root in PHASE2.PHASE1.protected_roots()
        )
        and not any(
            (parent / ".git").exists()
            for parent in [path.parent, *path.parents]
            if is_within(parent.resolve(strict=False), REPO_ROOT / "tmp")
        )
    }:
        raise MigrationError("tmp 日志集合在盘点后发生变化")

    historical_result_paths: set[str] = set()
    netlists = sorted(
        (
            path
            for path in (REPO_ROOT / "tmp").rglob("NpcTop.netlist.v")
            if path.is_file()
            and not path.is_symlink()
            and not any(
                is_within(path.resolve(strict=False), root)
                for root in PHASE2.PHASE1.protected_roots()
            )
        ),
        key=lambda item: relative(item),
    )
    for netlist in netlists:
        if is_within(netlist, latest_run_root):
            continue
        for path in collect_regular_files(netlist.parent):
            if path.name.lower().endswith((".log", ".log.gz", ".log.xz", ".log.zst")):
                continue
            historical_result_paths.add(relative(path))

    actions: dict[str, str] = {}
    for path, item in log_by_path.items():
        if path in latest_paths:
            actions[path] = "archive-latest-yosys"
        elif item["kind"] == "other":
            actions[path] = "archive-small-logs"
        else:
            actions[path] = "delete-obsolete-synthesis-log"
    for path in latest_paths:
        actions[path] = "archive-latest-yosys"
    for path in historical_result_paths:
        if path in actions:
            raise MigrationError(f"历史综合结果与日志动作冲突：{path}")
        actions[path] = "archive-historical-synthesis"

    entries: list[dict[str, Any]] = []
    for rel, action in sorted(actions.items()):
        path = REPO_ROOT / rel
        inventory_item = log_by_path.get(rel)
        identity = source_identity(
            path,
            digest=inventory_item["sha256"] if inventory_item else None,
        )
        entry = {
            "path": rel,
            "action": action,
            "archive": ARCHIVE_NAMES.get(action),
            **identity,
        }
        entries.append(entry)

    archive_members: dict[str, list[str]] = {
        name: [] for name in ARCHIVE_NAMES.values()
    }
    for item in entries:
        archive_name = item.get("archive")
        if archive_name:
            archive_members[archive_name].append(item["path"])
    for paths in archive_members.values():
        paths.sort()
    return entries, archive_members, relative(latest_run_root)


def aggregate(entries: Iterable[dict[str, Any]]) -> dict[str, Any]:
    by_action: dict[str, dict[str, int]] = defaultdict(
        lambda: {"source_count": 0, "source_bytes": 0}
    )
    total = {"source_count": 0, "source_bytes": 0}
    for item in entries:
        for destination in (by_action[item["action"]], total):
            destination["source_count"] += 1
            destination["source_bytes"] += item["size_bytes"]
    return {"total": total, "by_action": dict(sorted(by_action.items()))}


def prepare() -> None:
    with acquire_migration_lock():
        active = active_engineering_processes()
        if active:
            raise MigrationError(
                "检测到正在运行的仿真/综合/构建进程："
                + json.dumps(active, ensure_ascii=False)
            )
        if ARCHIVE_ROOT.exists() or ARCHIVE_ROOT.is_symlink():
            raise MigrationError(f"归档目标已存在：{relative(ARCHIVE_ROOT)}")
        logs, inventory_summary = load_inventory()
        entries, archive_members, latest_root = discover_sources(
            logs, inventory_summary
        )
        tracked, tracked_snapshot = PHASE2.git_stage_entries()
        candidate_paths = {item["path"] for item in entries}
        tracked_hits = sorted(candidate_paths & set(tracked))
        for path in tracked_hits:
            values = tracked[path]
            if len(values) != 1 or values[0]["stage"] != 0:
                raise MigrationError(f"不处理含冲突 stage 的 Git 日志：{path}")
        references, _reference_metadata = PHASE2.PHASE1.reference_closure()
        referenced_candidates = references & candidate_paths
        protected_roots = PHASE2.PHASE1.protected_roots()
        plan = {
            "schema_version": 1,
            "run_id": RUN_ID,
            "created_at": utc_now(),
            "repo_root": REPO_ROOT.as_posix(),
            "executor": {
                "python": {
                    "path": relative(SCRIPT_PATH),
                    "sha256": sha256_file(SCRIPT_PATH),
                },
                "wrapper": {
                    "path": relative(WRAPPER_PATH),
                    "sha256": sha256_file(WRAPPER_PATH),
                },
                "phase2_library": {
                    "path": relative(PHASE2_SCRIPT),
                    "sha256": sha256_file(PHASE2_SCRIPT),
                },
                "inventory": {
                    "path": relative(INVENTORY_PATH),
                    "sha256": sha256_file(INVENTORY_PATH),
                },
                "inventory_summary": {
                    "path": relative(INVENTORY_SUMMARY_PATH),
                    "sha256": sha256_file(INVENTORY_SUMMARY_PATH),
                },
                "tar_version": run(["tar", "--version"]).stdout.decode(
                    errors="replace"
                ).splitlines()[0],
                "zstd_version": run(["zstd", "--version"]).stdout.decode(
                    errors="replace"
                ).strip(),
            },
            "policy": {
                "archive": {
                    "latest_yosys_full_tree": latest_root,
                    "small_verification_logs": "all non-yosys/non-synth-console tmp logs",
                    "historical_synthesis_results": "remaining NpcTop netlists plus sibling text/SDC results",
                },
                "delete_without_payload_archive": [
                    "all non-latest yosys.log",
                    "all non-latest synth-console.log",
                ],
                "preserve_as_metadata": [
                    "original path",
                    "size",
                    "mtime/inode",
                    "sha256",
                    "action/reason",
                    "archive member mapping",
                ],
                "exclude": [
                    "registered/nested Git worktrees",
                    "task-run files",
                    "runtime system evidence",
                    "Linux images/logs",
                ],
            },
            "archive_root": relative(ARCHIVE_ROOT),
            "archive_members": archive_members,
            "latest_yosys_run_root": latest_root,
            "guard_snapshots": {
                "protected_roots": PHASE2.PHASE1.protected_state(protected_roots),
                "candidate_paths": string_set_snapshot(candidate_paths),
                "referenced_candidate_paths": string_set_snapshot(
                    referenced_candidates
                ),
                "git_index": tracked_snapshot,
                "selected_tracked": {
                    "path_count": len(tracked_hits),
                    "paths": [
                        {"path": path, "index": tracked[path][0]}
                        for path in tracked_hits
                    ],
                    "nonselected_stage_projection_sha256": PHASE2.projected_index_sha256(
                        tracked, set(tracked_hits)
                    ),
                },
            },
            "inventory_summary": {
                key: inventory_summary[key]
                for key in (
                    "log_count",
                    "total_bytes",
                    "unique_content_count",
                    "latest_yosys",
                )
            },
            "summary": aggregate(entries),
            "entries": entries,
        }
        plan_bytes = (
            json.dumps(plan, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
        ).encode()
        digest = hashlib.sha256(plan_bytes).hexdigest()
        atomic_write(PLAN_PATH, plan_bytes)
        atomic_write(PLAN_SHA_PATH, f"{digest}  {PLAN_PATH.name}\n".encode())
        lines = ["action\tsize_bytes\tsha256\tarchive\tpath"]
        for item in entries:
            lines.append(
                "\t".join(
                    [
                        item["action"],
                        str(item["size_bytes"]),
                        item["sha256"],
                        item.get("archive") or "-",
                        item["path"],
                    ]
                )
            )
        atomic_write(PLAN_TSV_PATH, ("\n".join(lines) + "\n").encode())
        preview = {
            "run_id": RUN_ID,
            "status": "PASS",
            "prepared_at": utc_now(),
            "plan_sha256": digest,
            "summary": plan["summary"],
            "archive_member_counts": {
                name: len(paths) for name, paths in archive_members.items()
            },
            "referenced_candidate_count": len(referenced_candidates),
            "referenced_candidate_paths": sorted(referenced_candidates),
            "selected_tracked_path_count": len(tracked_hits),
            "selected_tracked_paths": tracked_hits,
            "latest_yosys_run_root": latest_root,
            "archive_root": relative(ARCHIVE_ROOT),
            "active_engineering_processes": [],
        }
        write_json(PREVIEW_PATH, preview)
        atomic_write(
            STATUS_PATH,
            (
                f"PREPARED plan_sha256={digest} "
                f"sources={len(entries)} "
                f"bytes={plan['summary']['total']['source_bytes']}\n"
            ).encode(),
        )
        print(json.dumps(preview, ensure_ascii=False, indent=2, sort_keys=True))


def validate_source(item: dict[str, Any], protected_roots: set[Path]) -> None:
    path = REPO_ROOT / item["path"]
    if path.is_symlink() or not path.is_file():
        raise MigrationError(f"迁移源缺失或类型漂移：{item['path']}")
    if PHASE2.PHASE1.is_protected(path, protected_roots):
        raise MigrationError(f"迁移源进入受保护工作树：{item['path']}")
    metadata = path.stat(follow_symlinks=False)
    if not entry_stat_matches(item, metadata):
        raise MigrationError(f"迁移源 inode 属性漂移：{item['path']}")
    if sha256_file(path) != item["sha256"]:
        raise MigrationError(f"迁移源内容 SHA 漂移：{item['path']}")


def validate_plan(
    plan: dict[str, Any],
) -> tuple[
    list[dict[str, Any]],
    set[Path],
    set[str],
    set[str],
    dict[str, list[dict[str, Any]]],
]:
    if (
        plan.get("schema_version") != 1
        or plan.get("run_id") != RUN_ID
        or plan.get("repo_root") != REPO_ROOT.as_posix()
    ):
        raise MigrationError("迁移计划 schema/run/root 不匹配")
    expected_executor = {
        "python": {
            "path": relative(SCRIPT_PATH),
            "sha256": sha256_file(SCRIPT_PATH),
        },
        "wrapper": {
            "path": relative(WRAPPER_PATH),
            "sha256": sha256_file(WRAPPER_PATH),
        },
        "phase2_library": {
            "path": relative(PHASE2_SCRIPT),
            "sha256": sha256_file(PHASE2_SCRIPT),
        },
        "inventory": {
            "path": relative(INVENTORY_PATH),
            "sha256": sha256_file(INVENTORY_PATH),
        },
        "inventory_summary": {
            "path": relative(INVENTORY_SUMMARY_PATH),
            "sha256": sha256_file(INVENTORY_SUMMARY_PATH),
        },
        "tar_version": run(["tar", "--version"]).stdout.decode(
            errors="replace"
        ).splitlines()[0],
        "zstd_version": run(["zstd", "--version"]).stdout.decode(
            errors="replace"
        ).strip(),
    }
    if plan.get("executor") != expected_executor:
        raise MigrationError("计划冻结后执行器/盘点/工具版本发生变化")
    if ARCHIVE_ROOT.exists() or ARCHIVE_ROOT.is_symlink():
        raise MigrationError(f"归档目标已存在：{relative(ARCHIVE_ROOT)}")
    entries = plan.get("entries")
    if not isinstance(entries, list):
        raise MigrationError("迁移计划缺少 entries")
    candidate_paths = {item["path"] for item in entries}
    if string_set_snapshot(candidate_paths) != plan["guard_snapshots"][
        "candidate_paths"
    ]:
        raise MigrationError("迁移候选路径集合不匹配")
    protected_roots = PHASE2.PHASE1.protected_roots()
    if PHASE2.PHASE1.protected_state(protected_roots) != plan[
        "guard_snapshots"
    ]["protected_roots"]:
        raise MigrationError("受保护 RTL/TB 工作树状态发生变化")
    tracked, tracked_snapshot = PHASE2.git_stage_entries()
    if tracked_snapshot != plan["guard_snapshots"]["git_index"]:
        raise MigrationError("Git 索引在计划冻结后发生变化")
    selected_tracked_snapshot = plan["guard_snapshots"]["selected_tracked"]
    selected_tracked = {
        item["path"] for item in selected_tracked_snapshot["paths"]
    }
    if selected_tracked != candidate_paths & set(tracked):
        raise MigrationError("迁移源的 Git 跟踪集合发生变化")
    for item in selected_tracked_snapshot["paths"]:
        if tracked.get(item["path"]) != [item["index"]]:
            raise MigrationError(f"目标 Git 索引项发生变化：{item['path']}")
    if PHASE2.projected_index_sha256(
        tracked, selected_tracked
    ) != selected_tracked_snapshot["nonselected_stage_projection_sha256"]:
        raise MigrationError("非目标 Git 索引投影发生变化")
    references, _reference_metadata = PHASE2.PHASE1.reference_closure()
    referenced_candidates = references & candidate_paths
    if string_set_snapshot(referenced_candidates) != plan["guard_snapshots"][
        "referenced_candidate_paths"
    ]:
        raise MigrationError("候选文件的证据引用集合发生变化")
    for item in entries:
        validate_source(item, protected_roots)
    return (
        entries,
        protected_roots,
        referenced_candidates,
        selected_tracked,
        tracked,
    )


def create_tar_zstd(
    destination: Path, members: list[str]
) -> dict[str, Any]:
    if not members:
        raise MigrationError(f"归档成员为空：{destination.name}")
    if destination.exists() or destination.is_symlink():
        raise MigrationError(f"归档文件已存在：{relative(destination)}")
    partial = destination.with_name(destination.name + ".partial")
    if partial.exists() or partial.is_symlink():
        raise MigrationError(f"归档 partial 已存在：{relative(partial)}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    tar_process = subprocess.Popen(
        [
            "tar",
            "--create",
            "--format=posix",
            "--file=-",
            f"--directory={REPO_ROOT}",
            "--null",
            "--verbatim-files-from",
            "--files-from=-",
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert tar_process.stdin is not None
    assert tar_process.stdout is not None
    zstd_process = subprocess.Popen(
        [
            "zstd",
            "-T0",
            "-6",
            "--quiet",
            "--force",
            "-o",
            os.fspath(partial),
        ],
        stdin=tar_process.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    tar_process.stdout.close()
    try:
        tar_process.stdin.write(
            b"".join(
                member.encode(errors="surrogateescape") + b"\0"
                for member in members
            )
        )
        tar_process.stdin.close()
        zstd_stdout, zstd_stderr = zstd_process.communicate()
        tar_stderr = tar_process.stderr.read() if tar_process.stderr else b""
        tar_rc = tar_process.wait()
    except BaseException:
        tar_process.kill()
        zstd_process.kill()
        partial.unlink(missing_ok=True)
        raise
    if tar_rc != 0 or zstd_process.returncode != 0:
        partial.unlink(missing_ok=True)
        raise MigrationError(
            f"归档失败 {destination.name}: tar_rc={tar_rc} "
            f"zstd_rc={zstd_process.returncode} "
            f"tar={tar_stderr.decode(errors='replace').strip()} "
            f"zstd={zstd_stderr.decode(errors='replace').strip()} "
            f"stdout={zstd_stdout.decode(errors='replace').strip()}"
        )
    with partial.open("rb") as handle:
        os.fsync(handle.fileno())
    os.replace(partial, destination)
    test = run(["zstd", "--test", "--quiet", os.fspath(destination)], check=False)
    if test.returncode != 0:
        raise MigrationError(f"zstd 完整性检查失败：{relative(destination)}")
    listing = run(
        [
            "tar",
            "--use-compress-program=unzstd",
            "--list",
            "--file",
            os.fspath(destination),
        ],
        check=False,
    )
    if listing.returncode != 0:
        raise MigrationError(f"tar 成员检查失败：{relative(destination)}")
    actual_members = listing.stdout.decode(
        errors="surrogateescape"
    ).splitlines()
    if actual_members != members:
        raise MigrationError(
            f"tar 成员集合/顺序不匹配：{relative(destination)}"
        )
    metadata = destination.stat(follow_symlinks=False)
    return {
        "path": relative(destination),
        "member_count": len(members),
        "size_bytes": metadata.st_size,
        "sha256": sha256_file(destination),
    }


def verify_archive(
    archive: dict[str, Any],
    members: list[str],
    entries_by_path: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    path = REPO_ROOT / archive["path"]
    if (
        path.is_symlink()
        or not path.is_file()
        or path.stat().st_size != archive["size_bytes"]
        or sha256_file(path) != archive["sha256"]
    ):
        raise MigrationError(f"归档身份漂移：{archive['path']}")
    test = run(["zstd", "--test", "--quiet", os.fspath(path)], check=False)
    if test.returncode != 0:
        raise MigrationError(f"归档 zstd 复核失败：{archive['path']}")
    listing = run(
        [
            "tar",
            "--use-compress-program=unzstd",
            "--list",
            "--file",
            os.fspath(path),
        ],
        check=False,
    )
    if listing.returncode != 0 or listing.stdout.decode(
        errors="surrogateescape"
    ).splitlines() != members:
        raise MigrationError(f"归档成员复核失败：{archive['path']}")

    zstd_process = subprocess.Popen(
        [
            "zstd",
            "--decompress",
            "--stdout",
            "--quiet",
            os.fspath(path),
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert zstd_process.stdout is not None
    observed_members: list[str] = []
    payload_bytes = 0
    try:
        with zstd_process.stdout:
            with tarfile.open(fileobj=zstd_process.stdout, mode="r|") as stream:
                for member in stream:
                    index = len(observed_members)
                    if index >= len(members) or member.name != members[index]:
                        raise MigrationError(
                            f"归档 payload 成员顺序漂移：{archive['path']}:"
                            f"{member.name}"
                        )
                    expected = entries_by_path.get(member.name)
                    if expected is None:
                        raise MigrationError(
                            f"归档 payload 成员不在计划中：{archive['path']}:"
                            f"{member.name}"
                        )
                    if not member.isfile():
                        raise MigrationError(
                            f"归档 payload 成员不是普通文件：{archive['path']}:"
                            f"{member.name}"
                        )
                    if member.size != expected["size_bytes"]:
                        raise MigrationError(
                            f"归档 payload 大小不匹配：{archive['path']}:"
                            f"{member.name}"
                        )
                    source = stream.extractfile(member)
                    if source is None:
                        raise MigrationError(
                            f"无法读取归档 payload：{archive['path']}:"
                            f"{member.name}"
                        )
                    digest = hashlib.sha256()
                    while True:
                        block = source.read(8 * 1024 * 1024)
                        if not block:
                            break
                        digest.update(block)
                    if digest.hexdigest() != expected["sha256"]:
                        raise MigrationError(
                            f"归档 payload SHA-256 不匹配：{archive['path']}:"
                            f"{member.name}"
                        )
                    observed_members.append(member.name)
                    payload_bytes += member.size
        zstd_stderr = (
            zstd_process.stderr.read() if zstd_process.stderr is not None else b""
        )
        zstd_rc = zstd_process.wait()
    except BaseException:
        if zstd_process.poll() is None:
            zstd_process.kill()
        zstd_process.wait()
        raise
    if zstd_rc != 0:
        raise MigrationError(
            f"归档 payload 解压失败：{archive['path']}: "
            f"{zstd_stderr.decode(errors='replace').strip()}"
        )
    if observed_members != members:
        raise MigrationError(f"归档 payload 成员数量不匹配：{archive['path']}")
    return {
        "algorithm": "sha256",
        "member_count": len(observed_members),
        "payload_bytes": payload_bytes,
        "source_identity_match": True,
        "verified_at": utc_now(),
    }


def rollback_quarantine(
    quarantine_fd: int,
    staged: list[dict[str, Any]],
    journal,
) -> list[str]:
    errors: list[str] = []
    for mapping in reversed(staged):
        parent_fd = -1
        try:
            parent_fd, original_name = open_anchored_parent(mapping["item"]["path"])
            try:
                os.stat(original_name, dir_fd=parent_fd, follow_symlinks=False)
                source_exists = True
            except FileNotFoundError:
                source_exists = False
            try:
                os.stat(
                    mapping["quarantine_name"],
                    dir_fd=quarantine_fd,
                    follow_symlinks=False,
                )
                quarantined_exists = True
            except FileNotFoundError:
                quarantined_exists = False
            if source_exists and quarantined_exists:
                errors.append(f"source-and-quarantine-exist:{mapping['item']['path']}")
                continue
            if quarantined_exists:
                os.rename(
                    mapping["quarantine_name"],
                    original_name,
                    src_dir_fd=quarantine_fd,
                    dst_dir_fd=parent_fd,
                )
                journal_record(
                    journal,
                    {
                        "event": "rollback",
                        "path": mapping["item"]["path"],
                        "at": utc_now(),
                    },
                )
            elif not source_exists:
                errors.append(
                    f"source-and-quarantine-missing:{mapping['item']['path']}"
                )
        except BaseException as error:
            errors.append(
                f"{mapping['item']['path']}:{type(error).__name__}:{error}"
            )
        finally:
            if parent_fd >= 0:
                os.close(parent_fd)
    journal.flush()
    os.fsync(journal.fileno())
    return errors


def remove_empty_parents(entries: list[dict[str, Any]]) -> int:
    parents: set[Path] = set()
    tmp_root = REPO_ROOT / "tmp"
    for item in entries:
        current = (REPO_ROOT / item["path"]).parent
        while current != tmp_root and is_within(current, tmp_root):
            parents.add(current)
            current = current.parent
    removed = 0
    for directory in sorted(parents, key=lambda item: len(item.parts), reverse=True):
        try:
            directory.rmdir()
            removed += 1
        except OSError:
            pass
    return removed


def execute(expected_digest: str) -> None:
    if os.environ.get("RV64_MIGRATION_WRAPPER_ACTIVE") != "1":
        raise MigrationError("执行必须由 execute_migration.sh 启动")
    if not re.fullmatch(r"[0-9a-f]{64}", expected_digest):
        raise MigrationError("计划 SHA-256 参数格式错误")
    plan_bytes = PLAN_PATH.read_bytes()
    actual_digest = hashlib.sha256(plan_bytes).hexdigest()
    if actual_digest != expected_digest:
        raise MigrationError(
            f"计划摘要不匹配：expected={expected_digest} actual={actual_digest}"
        )
    plan = json.loads(plan_bytes)
    active = active_engineering_processes()
    if active:
        raise MigrationError(
            "检测到正在运行的仿真/综合/构建进程："
            + json.dumps(active, ensure_ascii=False)
        )
    if QUARANTINE_PATH.exists() or QUARANTINE_PATH.is_symlink():
        raise MigrationError(f"隔离目录已存在：{relative(QUARANTINE_PATH)}")

    started_at = utc_now()
    before_available = PHASE2.PHASE1.filesystem_available_bytes()
    archives: list[dict[str, Any]] = []
    staged: list[dict[str, Any]] = []
    purged: list[str] = []
    purge_started = False
    index_updated = False
    quarantine_fd = -1
    journal = None
    old_handlers: dict[signal.Signals, Any] = {}
    write_json(
        RESULT_PATH,
        {
            "run_id": RUN_ID,
            "status": "RUNNING",
            "stage": "preflight",
            "started_at": started_at,
            "plan_sha256": actual_digest,
        },
    )

    def interrupt_handler(signum, _frame) -> None:
        raise MigrationInterrupted(f"收到 {signal.Signals(signum).name}")

    with acquire_migration_lock():
        try:
            for signal_name in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM):
                old_handlers[signal_name] = signal.signal(
                    signal_name, interrupt_handler
                )
            write_stage(
                "validating",
                archived_count=0,
                staged_count=0,
                purged_count=0,
            )
            (
                entries,
                protected_roots,
                referenced_candidates,
                selected_tracked,
                before_index,
            ) = validate_plan(plan)
            entries_by_path = {item["path"]: item for item in entries}
            nonselected_index_digest = plan["guard_snapshots"]["selected_tracked"][
                "nonselected_stage_projection_sha256"
            ]

            write_stage(
                "archiving",
                archived_count=0,
                staged_count=0,
                purged_count=0,
            )
            ARCHIVE_ROOT.mkdir(parents=True, exist_ok=False)
            for archive_name, members in sorted(plan["archive_members"].items()):
                archive = create_tar_zstd(ARCHIVE_ROOT / archive_name, members)
                archives.append(archive)
                write_stage(
                    "archiving",
                    archived_count=len(archives),
                    staged_count=0,
                    purged_count=0,
                )

            archive_by_name = {
                Path(item["path"]).name: item for item in archives
            }
            for archive_name, members in plan["archive_members"].items():
                archive_by_name[archive_name]["payload_verification"] = (
                    verify_archive(
                        archive_by_name[archive_name],
                        members,
                        entries_by_path,
                    )
                )
            manifest_entries: list[dict[str, Any]] = []
            for item in entries:
                archive_name = item.get("archive")
                manifest_entries.append(
                    {
                        "original_path": item["path"],
                        "original_size_bytes": item["size_bytes"],
                        "original_sha256": item["sha256"],
                        "action": item["action"],
                        "archive_path": (
                            archive_by_name[archive_name]["path"]
                            if archive_name
                            else None
                        ),
                        "archive_member": item["path"] if archive_name else None,
                        "reason": (
                            "latest-yosys-full-product"
                            if item["action"] == "archive-latest-yosys"
                            else "small-verification-log-retained-compressed"
                            if item["action"] == "archive-small-logs"
                            else "historical-netlist-and-text-result-retained-compressed"
                            if item["action"] == "archive-historical-synthesis"
                            else "obsolete-raw-synthesis-log-summary-and-sha-retained"
                        ),
                        "was_reference_path": item["path"]
                        in referenced_candidates,
                    }
                )
            runtime_manifest = {
                "schema_version": 1,
                "run_id": RUN_ID,
                "created_at": utc_now(),
                "plan_sha256": actual_digest,
                "source_summary": plan["summary"],
                "archives": archives,
                "entries": manifest_entries,
            }
            write_json(RUNTIME_MANIFEST_PATH, runtime_manifest)
            write_json(EVIDENCE_ROOT / "migration-manifest.json", runtime_manifest)
            checksum_lines = [
                f"{item['sha256']}  {Path(item['path']).name}" for item in archives
            ]
            checksum_lines.append(
                f"{sha256_file(RUNTIME_MANIFEST_PATH)}  {RUNTIME_MANIFEST_PATH.name}"
            )
            atomic_write(
                RUNTIME_CHECKSUM_PATH,
                ("\n".join(checksum_lines) + "\n").encode(),
            )
            QUARANTINE_PATH.mkdir(mode=0o700)
            quarantine_fd = os.open(
                QUARANTINE_PATH,
                os.O_RDONLY
                | os.O_DIRECTORY
                | getattr(os, "O_NOFOLLOW", 0)
                | getattr(os, "O_CLOEXEC", 0),
            )
            atomic_write(JOURNAL_PATH, b"")
            journal = JOURNAL_PATH.open("ab", buffering=0)
            write_stage(
                "quarantining",
                archived_count=len(archives),
                staged_count=0,
                purged_count=0,
            )
            for index, item in enumerate(entries):
                validate_source(item, protected_roots)
                parent_fd, original_name = open_anchored_parent(item["path"])
                quarantine_name = (
                    f"{index:06d}-"
                    f"{hashlib.sha256(item['path'].encode()).hexdigest()[:20]}"
                )
                mapping = {"item": item, "quarantine_name": quarantine_name}
                staged.append(mapping)
                try:
                    metadata = os.stat(
                        original_name,
                        dir_fd=parent_fd,
                        follow_symlinks=False,
                    )
                    if not entry_stat_matches(item, metadata):
                        raise MigrationError(
                            f"隔离前 inode 属性漂移：{item['path']}"
                        )
                    journal_record(
                        journal,
                        {
                            "event": "intent",
                            "path": item["path"],
                            "quarantine_name": quarantine_name,
                            "at": utc_now(),
                        },
                        durable=index % 128 == 0,
                    )
                    os.rename(
                        original_name,
                        quarantine_name,
                        src_dir_fd=parent_fd,
                        dst_dir_fd=quarantine_fd,
                    )
                finally:
                    os.close(parent_fd)
                journal_record(
                    journal,
                    {
                        "event": "staged",
                        "path": item["path"],
                        "quarantine_name": quarantine_name,
                        "at": utc_now(),
                    },
                    durable=(index + 1) % 128 == 0,
                )
                if (index + 1) % 256 == 0:
                    write_stage(
                        "quarantining",
                        archived_count=len(archives),
                        staged_count=index + 1,
                        purged_count=0,
                    )
            journal.flush()
            os.fsync(journal.fileno())

            if active_engineering_processes():
                raise MigrationError("隔离期间出现新的仿真/综合/构建进程")
            if PHASE2.PHASE1.protected_state(protected_roots) != plan[
                "guard_snapshots"
            ]["protected_roots"]:
                raise MigrationError("隔离期间受保护工作树发生变化")
            references_after, _metadata_after = PHASE2.PHASE1.reference_closure()
            if string_set_snapshot(
                references_after & set(entries_by_path)
            ) != plan["guard_snapshots"]["referenced_candidate_paths"]:
                raise MigrationError("隔离期间候选证据引用集合发生变化")
            for archive_name, members in plan["archive_members"].items():
                verify_archive(
                    archive_by_name[archive_name],
                    members,
                    entries_by_path,
                )
            PHASE2.remove_selected_index_paths(selected_tracked)
            index_updated = bool(selected_tracked)
            after_index, _after_index_snapshot = PHASE2.git_stage_entries()
            if any(path in after_index for path in selected_tracked):
                raise MigrationError("部分目标 Git 日志仍在索引中")
            if PHASE2.projected_index_sha256(
                after_index, set()
            ) != nonselected_index_digest:
                raise MigrationError("解除日志跟踪时改动了非目标 Git 索引项")

            purge_started = True
            write_stage(
                "purging",
                archived_count=len(archives),
                staged_count=len(staged),
                purged_count=0,
            )
            for index, mapping in enumerate(staged):
                os.unlink(mapping["quarantine_name"], dir_fd=quarantine_fd)
                purged.append(mapping["item"]["path"])
                journal_record(
                    journal,
                    {
                        "event": "purged",
                        "path": mapping["item"]["path"],
                        "at": utc_now(),
                    },
                    durable=(index + 1) % 128 == 0,
                )
                if (index + 1) % 256 == 0:
                    write_stage(
                        "purging",
                        archived_count=len(archives),
                        staged_count=len(staged),
                        purged_count=index + 1,
                    )
            journal.flush()
            os.fsync(journal.fileno())
            os.close(quarantine_fd)
            quarantine_fd = -1
            QUARANTINE_PATH.rmdir()
            removed_empty_dirs = remove_empty_parents(entries)

            remaining = [
                item["path"]
                for item in entries
                if (REPO_ROOT / item["path"]).exists()
                or (REPO_ROOT / item["path"]).is_symlink()
            ]
            if remaining:
                raise MigrationError(f"迁移源被重建：{remaining[:8]}")
            for archive_name, members in plan["archive_members"].items():
                verify_archive(
                    archive_by_name[archive_name],
                    members,
                    entries_by_path,
                )
            protection_after = PHASE2.PHASE1.protected_state(protected_roots)
            if protection_after != plan["guard_snapshots"]["protected_roots"]:
                raise MigrationError("迁移后受保护工作树发生变化")
            final_index, _final_index_snapshot = PHASE2.git_stage_entries()
            if any(path in final_index for path in selected_tracked):
                raise MigrationError("迁移后目标 Git 日志重新进入索引")
            if PHASE2.projected_index_sha256(
                final_index, set()
            ) != nonselected_index_digest:
                raise MigrationError("迁移后非目标 Git 索引投影发生变化")

            after_available = PHASE2.PHASE1.filesystem_available_bytes()
            result = {
                "run_id": RUN_ID,
                "status": "PASS",
                "started_at": started_at,
                "finished_at": utc_now(),
                "plan_sha256": actual_digest,
                "source_count": len(entries),
                "source_bytes": plan["summary"]["total"]["source_bytes"],
                "archive_count": len(archives),
                "archive_bytes": sum(item["size_bytes"] for item in archives),
                "archives": archives,
                "purged_source_count": len(purged),
                "removed_git_tracked_path_count": len(selected_tracked),
                "removed_git_tracked_paths": sorted(selected_tracked),
                "remaining_source_count": 0,
                "removed_empty_directory_count": removed_empty_dirs,
                "filesystem_available_bytes_before": before_available,
                "filesystem_available_bytes_after": after_available,
                "observed_available_bytes_delta": after_available - before_available,
                "quarantine_remaining": False,
                "runtime_manifest": relative(RUNTIME_MANIFEST_PATH),
                "protected_roots_after": protection_after,
            }
            write_json(RESULT_PATH, result)
            write_stage(
                "evidence-verified",
                archived_count=len(archives),
                staged_count=len(staged),
                purged_count=len(purged),
            )
            print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        except BaseException as error:
            rollback_errors: list[str] = []
            index_rollback_error: str | None = None
            if not purge_started and quarantine_fd >= 0 and journal is not None:
                if index_updated:
                    try:
                        PHASE2.restore_selected_index_paths(
                            selected_tracked, before_index
                        )
                        restored_index, _restored_snapshot = PHASE2.git_stage_entries()
                        if PHASE2.projected_index_sha256(
                            restored_index, set()
                        ) != PHASE2.projected_index_sha256(
                            before_index, set()
                        ):
                            raise MigrationError("Git 索引回滚后投影不匹配")
                    except BaseException as rollback_error:
                        index_rollback_error = (
                            f"{type(rollback_error).__name__}: {rollback_error}"
                        )
                rollback_errors = rollback_quarantine(
                    quarantine_fd, staged, journal
                )
                if not rollback_errors:
                    os.close(quarantine_fd)
                    quarantine_fd = -1
                    QUARANTINE_PATH.rmdir()
            result = {
                "run_id": RUN_ID,
                "status": "FAIL",
                "started_at": started_at,
                "finished_at": utc_now(),
                "plan_sha256": actual_digest,
                "stage": "purging" if purge_started else "pre-purge",
                "archive_count": len(archives),
                "staged_source_count": len(staged),
                "purged_source_count": len(purged),
                "index_updated": index_updated,
                "index_rollback_error": index_rollback_error,
                "rollback_errors": rollback_errors,
                "quarantine_remaining": QUARANTINE_PATH.exists(),
                "archive_root_remaining": ARCHIVE_ROOT.exists(),
                "error": f"{type(error).__name__}: {error}",
            }
            write_json(RESULT_PATH, result)
            write_stage(
                "failed",
                archived_count=len(archives),
                staged_count=len(staged),
                purged_count=len(purged),
                detail=result["error"],
            )
            raise
        finally:
            if journal is not None:
                journal.close()
            if quarantine_fd >= 0:
                os.close(quarantine_fd)
            for signal_name, old_handler in old_handlers.items():
                signal.signal(signal_name, old_handler)


def main() -> int:
    parser = argparse.ArgumentParser()
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--prepare", action="store_true")
    action.add_argument("--execute", action="store_true")
    parser.add_argument("--plan-sha256")
    args = parser.parse_args()
    if Path.cwd().resolve(strict=True) != REPO_ROOT:
        raise MigrationError(f"必须从仓库根运行：{REPO_ROOT}")
    if args.execute and not args.plan_sha256:
        parser.error("--execute 需要 --plan-sha256")
    if args.prepare and args.plan_sha256:
        parser.error("--prepare 不接受 --plan-sha256")
    if args.prepare:
        prepare()
    else:
        execute(args.plan_sha256)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except MigrationError as error:
        sys.stderr.write(f"migration precondition failed: {error}\n")
        raise SystemExit(2)
