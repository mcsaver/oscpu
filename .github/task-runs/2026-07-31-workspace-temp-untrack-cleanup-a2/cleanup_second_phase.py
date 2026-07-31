#!/usr/bin/env python3
"""生成并执行第二阶段工作区临时产物清理。

本轮只处理可复现的编译/仿真缓存和构建子树。结果、日志、综合网表、
task-run 证据引用、系统回放输入以及含未提交 RTL/TB 的工作树均保留。
计划内若包含 Git 已跟踪临时文件，则只移除这些精确索引项。
"""

from __future__ import annotations

import argparse
import bisect
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
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


REPO_ROOT = Path("/home/lyg/PA/ysyx-workbench")
RUN_ID = "2026-07-31-workspace-temp-untrack-cleanup-a2"
RUN_ROOT = REPO_ROOT / ".github" / "task-runs" / RUN_ID
EVIDENCE_ROOT = RUN_ROOT / "evidence"
SCRIPT_PATH = RUN_ROOT / "cleanup_second_phase.py"
WRAPPER_PATH = RUN_ROOT / "execute_cleanup.sh"
PLAN_PATH = EVIDENCE_ROOT / "cleanup-plan.json"
PLAN_SHA_PATH = EVIDENCE_ROOT / "cleanup-plan.sha256"
PLAN_TSV_PATH = EVIDENCE_ROOT / "cleanup-plan.tsv"
PREVIEW_PATH = EVIDENCE_ROOT / "cleanup-preview.json"
EXECUTION_PATH = EVIDENCE_ROOT / "cleanup-result.json"
STATUS_PATH = RUN_ROOT / "cleanup.status"
STAGE_PATH = EVIDENCE_ROOT / "cleanup-stage.json"
JOURNAL_PATH = EVIDENCE_ROOT / "quarantine-journal.jsonl"
QUARANTINE_PATH = EVIDENCE_ROOT / ".cleanup-quarantine"

# 与第一阶段共用同一把锁，避免两个清理器并发搬移工作区 inode。
SHARED_LOCK_PATH = (
    REPO_ROOT
    / ".github/task-runs/2026-07-31-workspace-artifact-cleanup-a1/evidence/cleanup.lock"
)
PHASE1_SCRIPT = (
    REPO_ROOT
    / ".github/task-runs/2026-07-31-workspace-artifact-cleanup-a1/"
    "cleanup_first_phase.py"
)

EXACT_CLEAN_ROOTS = {
    "npc/rv64/build": "current-rv64-build",
    "npc/rv64/testbench/build": "current-rv64-testbench-build",
    "Linux/env/build": "linux-host-build",
    ".github/cache/rv64-functional-v9l": "rv64-functional-cache",
    "fpga/.Xil": "fpga-tool-cache",
}

DIRECT_TRANSIENT_SUFFIXES = {
    ".a",
    ".class",
    ".d",
    ".gcda",
    ".gcno",
    ".gch",
    ".la",
    ".lo",
    ".o",
    ".obj",
    ".pid",
    ".profraw",
    ".pyc",
    ".pyo",
    ".so",
    ".swo",
    ".swp",
    ".tmp",
    ".vvp",
}

RETAINED_SUFFIXES = {
    ".csv",
    ".diff",
    ".fst",
    ".ghw",
    ".html",
    ".json",
    ".jsonl",
    ".log",
    ".map",
    ".marker",
    ".md",
    ".out",
    ".patch",
    ".pcap",
    ".report",
    ".rpt",
    ".sha1",
    ".sha256",
    ".sha512",
    ".stat",
    ".stats",
    ".status",
    ".stderr",
    ".stdout",
    ".toml",
    ".trace",
    ".tsv",
    ".txt",
    ".vcd",
    ".vpd",
    ".wlf",
    ".xml",
    ".yaml",
    ".yml",
}

RETAINED_COMPOUND_SUFFIXES = tuple(
    f"{suffix}{compression}"
    for suffix in (
        ".csv",
        ".json",
        ".jsonl",
        ".log",
        ".md",
        ".report",
        ".rpt",
        ".status",
        ".stderr",
        ".stdout",
        ".trace",
        ".tsv",
        ".txt",
        ".vcd",
    )
    for compression in (".gz", ".xz", ".zst")
)

RETAINED_NAMES = {
    "checksum",
    "checksums",
    "checksums.txt",
    "manifest",
    "readme",
    "readme.md",
    "sha256sums",
}

BUILD_DIR_NAMES = {
    ".cache",
    ".xil",
    "__pycache__",
    "build",
    "cmakefiles",
    "obj",
    "obj_dir",
    "objects",
    "out",
    "target",
}

BUILD_DIR_RE = re.compile(r"(?:^|[-_])build(?:$|[-_][a-z0-9])", re.IGNORECASE)


class CleanupError(RuntimeError):
    """清理前置条件或执行不变量失败。"""


class CleanupInterrupted(CleanupError):
    """HUP/INT/TERM 中断标记。"""


def load_phase1_module():
    spec = importlib.util.spec_from_file_location("workspace_cleanup_phase1", PHASE1_SCRIPT)
    if spec is None or spec.loader is None:
        raise CleanupError(f"无法加载第一阶段清理库：{PHASE1_SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


PHASE1 = load_phase1_module()
# 引用闭包排除当前正在生成的清理 run，避免 status/preview 自身改变冻结快照。
PHASE1.RUN_ROOT = RUN_ROOT


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


def relative(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def acquire_cleanup_lock():
    SHARED_LOCK_PATH.parent.mkdir(parents=True, exist_ok=True)
    handle = SHARED_LOCK_PATH.open("a+", encoding="utf-8")
    try:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError as error:
        handle.close()
        raise CleanupError("已有工作区清理器持有排他锁") from error
    handle.seek(0)
    handle.truncate()
    handle.write(f"run_id={RUN_ID} pid={os.getpid()} acquired_at={utc_now()}\n")
    handle.flush()
    os.fsync(handle.fileno())
    return handle


def write_stage(
    stage: str,
    *,
    staged_count: int,
    purged_count: int,
    detail: str | None = None,
) -> None:
    value: dict[str, Any] = {
        "run_id": RUN_ID,
        "stage": stage,
        "updated_at": utc_now(),
        "staged_target_count": staged_count,
        "purged_target_count": purged_count,
    }
    if detail:
        value["detail"] = detail
    write_json(STAGE_PATH, value)


def active_engineering_processes() -> list[dict[str, Any]]:
    return PHASE1.active_eda_processes()


def git_stage_entries() -> tuple[dict[str, list[dict[str, Any]]], dict[str, Any]]:
    result = run(["git", "ls-files", "--stage", "-z"])
    entries: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for raw in result.stdout.split(b"\0"):
        if not raw:
            continue
        header, path_raw = raw.split(b"\t", 1)
        mode_raw, oid_raw, stage_raw = header.split(b" ", 2)
        path = path_raw.decode(errors="surrogateescape")
        entries[path].append(
            {
                "mode": mode_raw.decode(),
                "oid": oid_raw.decode(),
                "stage": int(stage_raw),
            }
        )
    return dict(entries), {
        "entry_count": sum(len(value) for value in entries.values()),
        "path_count": len(entries),
        "stage_stream_sha256": hashlib.sha256(result.stdout).hexdigest(),
        "index": PHASE1.git_index_state(include_content_sha256=True),
    }


def projected_index_sha256(
    entries: dict[str, list[dict[str, Any]]], excluded: set[str]
) -> str:
    digest = hashlib.sha256()
    for path in sorted(entries):
        if path in excluded:
            continue
        for item in sorted(
            entries[path],
            key=lambda value: (value["stage"], value["mode"], value["oid"]),
        ):
            digest.update(
                (
                    f"{item['mode']} {item['oid']} {item['stage']}\t{path}\0"
                ).encode(errors="surrogateescape")
            )
    return digest.hexdigest()


def ancestor_reference(path: str, references: set[str]) -> str | None:
    parts = path.split("/")
    for length in range(len(parts), 0, -1):
        candidate = "/".join(parts[:length])
        if candidate in references:
            return candidate
    return None


def descendant_reference(
    path: str, sorted_references: list[str]
) -> str | None:
    prefix = path + "/"
    position = bisect.bisect_left(sorted_references, prefix)
    if (
        position < len(sorted_references)
        and sorted_references[position].startswith(prefix)
    ):
        return sorted_references[position]
    return None


def exact_file_references(references: set[str]) -> set[str]:
    """目录指针只保留记录语义；只有现存精确文件引用保护原始 payload。"""
    result: set[str] = set()
    for item in references:
        path = REPO_ROOT / item
        if path.is_file() and not path.is_symlink():
            result.add(item)
    return result


def string_set_snapshot(values: set[str]) -> dict[str, Any]:
    digest = hashlib.sha256()
    for value in sorted(values):
        digest.update(value.encode(errors="surrogateescape"))
        digest.update(b"\0")
    return {"count": len(values), "sha256": digest.hexdigest()}


def is_retained_record(path: Path, latest_yosys_product_root: Path | None) -> bool:
    name = path.name.lower()
    if name in RETAINED_NAMES or name.startswith(("readme.", "manifest.")):
        return True
    if name.endswith(RETAINED_COMPOUND_SUFFIXES):
        return True
    if path.suffix.lower() in RETAINED_SUFFIXES:
        return True
    # 完整综合网表只保留最新一组；被正式证据引用的旧网表在更早的引用检查中已保留。
    if path.suffix.lower() in {".v", ".sv"} and any(
        token in name for token in ("netlist", "synth", "mapped", "gate")
    ):
        return latest_yosys_product_root is not None and is_within(
            path, latest_yosys_product_root
        )
    if path.suffix.lower() == ".sdc":
        return latest_yosys_product_root is not None and is_within(
            path, latest_yosys_product_root
        )
    return False


def is_direct_transient_file(path: Path) -> bool:
    name = path.name.lower()
    if name.endswith(".netlist.v.sim"):
        return True
    if ".so." in name:
        return True
    return path.suffix.lower() in DIRECT_TRANSIENT_SUFFIXES


def is_build_directory(path: Path) -> bool:
    name = path.name.lower()
    return name in BUILD_DIR_NAMES or BUILD_DIR_RE.search(name) is not None


def contains_git_admin(path: Path) -> bool:
    return PHASE1.contains_git_admin(path)


def path_is_protected(path: Path, protected_roots: Iterable[Path]) -> bool:
    return PHASE1.is_protected(path, protected_roots)


def latest_yosys_product_root(protected_roots: set[Path]) -> Path | None:
    candidates: list[tuple[int, str, Path]] = []
    tmp_root = REPO_ROOT / "tmp"
    for root_raw, dir_names, file_names in os.walk(
        tmp_root, topdown=True, followlinks=False
    ):
        directory = Path(root_raw)
        if directory != tmp_root and (
            path_is_protected(directory, protected_roots)
            or (directory / ".git").exists()
        ):
            dir_names[:] = []
            continue
        dir_names[:] = [
            name
            for name in dir_names
            if not (directory / name).is_symlink()
            and not path_is_protected(directory / name, protected_roots)
            and not ((directory / name) / ".git").exists()
        ]
        if "yosys.log" not in file_names:
            continue
        log_path = directory / "yosys.log"
        metadata = log_path.stat(follow_symlinks=False)
        candidates.append((metadata.st_mtime_ns, relative(directory), directory))
    if not candidates:
        return None
    return max(candidates, key=lambda item: (item[0], item[1]))[2]


def discover_clean_roots(protected_roots: set[Path]) -> list[tuple[Path, str]]:
    roots: list[tuple[Path, str]] = []
    for rel, category in sorted(EXACT_CLEAN_ROOTS.items()):
        path = REPO_ROOT / rel
        if (
            path.is_dir()
            and not path.is_symlink()
            and not path_is_protected(path, protected_roots)
            and not contains_git_admin(path)
        ):
            roots.append((path, category))

    tmp_root = REPO_ROOT / "tmp"
    for root_raw, dir_names, _file_names in os.walk(
        tmp_root, topdown=True, followlinks=False
    ):
        root = Path(root_raw)
        if root != tmp_root and (
            path_is_protected(root, protected_roots) or (root / ".git").exists()
        ):
            dir_names[:] = []
            continue
        retained: list[str] = []
        for name in dir_names:
            child = root / name
            if (
                child.is_symlink()
                or path_is_protected(child, protected_roots)
                or (child / ".git").exists()
            ):
                continue
            if is_build_directory(child):
                roots.append((child, "tmp-build-tree"))
                continue
            retained.append(name)
        dir_names[:] = retained

    # 精确根优先，避免同一子树进入两次计划。
    reduced: list[tuple[Path, str]] = []
    for path, category in sorted(roots, key=lambda item: (len(item[0].parts), os.fspath(item[0]))):
        if any(is_within(path, existing) for existing, _ in reduced):
            continue
        reduced.append((path, category))
    return reduced


def scan_clean_root(
    root: Path,
    category: str,
    protected_roots: set[Path],
    references: set[str],
    sorted_references: list[str],
    latest_yosys_root: Path | None,
) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    candidate_files: set[Path] = set()
    kept: list[dict[str, str]] = []
    directory_rows: list[tuple[Path, list[str], list[str]]] = []
    blocked_directories: set[Path] = set()

    root_rel = relative(root)
    root_ref = ancestor_reference(root_rel, references)
    if root_ref:
        return [], [{"path": root_rel, "reason": f"evidence-ancestor:{root_ref}"}]

    for root_raw, dir_names, file_names in os.walk(
        root, topdown=True, followlinks=False
    ):
        directory = Path(root_raw)
        retained_dirs: list[str] = []
        for name in dir_names:
            child = directory / name
            child_rel = relative(child)
            reason = None
            if child.is_symlink():
                reason = "symlink"
            elif path_is_protected(child, protected_roots):
                reason = "protected-worktree"
            elif (child / ".git").exists():
                reason = "nested-git"
            else:
                hit = ancestor_reference(child_rel, references)
                if hit:
                    reason = f"evidence-ancestor:{hit}"
            if reason:
                kept.append({"path": child_rel, "reason": reason})
                blocked_directories.add(directory)
                continue
            retained_dirs.append(name)
        dir_names[:] = retained_dirs

        for name in file_names:
            child = directory / name
            child_rel = relative(child)
            if child.is_symlink():
                kept.append({"path": child_rel, "reason": "symlink"})
                continue
            evidence_hit = ancestor_reference(child_rel, references)
            if evidence_hit:
                kept.append(
                    {
                        "path": child_rel,
                        "reason": f"evidence-ancestor:{evidence_hit}",
                    }
                )
                continue
            if is_retained_record(child, latest_yosys_root):
                kept.append({"path": child_rel, "reason": "result-or-log"})
                continue
            candidate_files.add(child)
        directory_rows.append((directory, list(dir_names), list(file_names)))

    # 自底向上判断纯候选目录，再选择最高层目录作为原子隔离单元。
    deletable_dirs: set[Path] = set()
    for directory, dir_names, file_names in reversed(directory_rows):
        deletable = directory not in blocked_directories
        for name in dir_names:
            if directory / name not in deletable_dirs:
                deletable = False
                break
        if deletable:
            for name in file_names:
                child = directory / name
                if child not in candidate_files:
                    deletable = False
                    break
        if deletable:
            deletable_dirs.add(directory)

    selected_dirs: set[Path] = set()
    for directory in sorted(deletable_dirs, key=lambda value: len(value.parts)):
        if any(is_within(directory, parent) for parent in selected_dirs):
            continue
        selected_dirs.add(directory)

    entries = [
        {"path": relative(path), "kind": "dir", "category": category}
        for path in sorted(selected_dirs, key=os.fspath)
    ]
    for path in sorted(candidate_files, key=os.fspath):
        if any(is_within(path, directory) for directory in selected_dirs):
            continue
        entries.append(
            {"path": relative(path), "kind": "file", "category": category}
        )
    return entries, kept


def scan_direct_tmp_files(
    protected_roots: set[Path],
    references: set[str],
    selected_dirs: set[Path],
    selected_files: set[Path],
) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    entries: list[dict[str, str]] = []
    kept: list[dict[str, str]] = []
    tmp_root = REPO_ROOT / "tmp"
    for root_raw, dir_names, file_names in os.walk(
        tmp_root, topdown=True, followlinks=False
    ):
        directory = Path(root_raw)
        if any(is_within(directory, selected) for selected in selected_dirs):
            dir_names[:] = []
            continue
        if directory != tmp_root and (
            path_is_protected(directory, protected_roots)
            or (directory / ".git").exists()
        ):
            dir_names[:] = []
            continue
        retained_dirs: list[str] = []
        for name in dir_names:
            child = directory / name
            if child.is_symlink() or path_is_protected(child, protected_roots):
                continue
            if (child / ".git").exists():
                continue
            retained_dirs.append(name)
        dir_names[:] = retained_dirs
        for name in file_names:
            child = directory / name
            if child in selected_files or not is_direct_transient_file(child):
                continue
            child_rel = relative(child)
            if child.is_symlink():
                kept.append({"path": child_rel, "reason": "symlink"})
                continue
            evidence_hit = ancestor_reference(child_rel, references)
            if evidence_hit:
                kept.append(
                    {
                        "path": child_rel,
                        "reason": f"evidence-ancestor:{evidence_hit}",
                    }
                )
                continue
            entries.append(
                {
                    "path": child_rel,
                    "kind": "file",
                    "category": "tmp-transient-file",
                }
            )
    return entries, kept


def discover_candidates(
    protected_roots: set[Path], references: set[str]
) -> tuple[
    list[dict[str, str]],
    list[dict[str, str]],
    list[dict[str, str]],
    str | None,
]:
    sorted_references = sorted(references)
    entries: list[dict[str, str]] = []
    retained: list[dict[str, str]] = []
    latest_yosys_root = latest_yosys_product_root(protected_roots)
    clean_roots = discover_clean_roots(protected_roots)
    for root, category in clean_roots:
        root_entries, root_retained = scan_clean_root(
            root,
            category,
            protected_roots,
            references,
            sorted_references,
            latest_yosys_root,
        )
        entries.extend(root_entries)
        retained.extend(root_retained)

    selected_dirs = {
        REPO_ROOT / item["path"] for item in entries if item["kind"] == "dir"
    }
    selected_files = {
        REPO_ROOT / item["path"] for item in entries if item["kind"] == "file"
    }
    direct_entries, direct_retained = scan_direct_tmp_files(
        protected_roots,
        references,
        selected_dirs,
        selected_files,
    )
    entries.extend(direct_entries)
    retained.extend(direct_retained)

    unique: dict[str, dict[str, str]] = {}
    for item in entries:
        existing = unique.get(item["path"])
        if existing and existing != item:
            raise CleanupError(f"候选分类冲突：{item['path']}")
        unique[item["path"]] = item
    ordered = [unique[path] for path in sorted(unique)]
    roots_snapshot = [
        {"path": relative(path), "category": category}
        for path, category in clean_roots
    ]
    return (
        ordered,
        retained,
        roots_snapshot,
        relative(latest_yosys_root) if latest_yosys_root is not None else None,
    )


def tree_metadata(path: Path) -> dict[str, Any]:
    digest = hashlib.sha256()
    entry_count = 0
    regular_bytes = 0
    for root_raw, dir_names, file_names in os.walk(
        path, topdown=True, followlinks=False
    ):
        directory = Path(root_raw)
        dir_names.sort()
        file_names.sort()
        for name in [*dir_names, *file_names]:
            child = directory / name
            metadata = child.stat(follow_symlinks=False)
            rel = child.relative_to(path).as_posix()
            digest.update(
                (
                    f"{rel}\0{metadata.st_dev}\0{metadata.st_ino}\0"
                    f"{stat.S_IFMT(metadata.st_mode)}\0{metadata.st_size}\0"
                    f"{metadata.st_mtime_ns}\0"
                ).encode(errors="surrogateescape")
            )
            entry_count += 1
            if stat.S_ISREG(metadata.st_mode):
                regular_bytes += metadata.st_size
    return {
        "tree_entry_count": entry_count,
        "tree_regular_bytes": regular_bytes,
        "tree_metadata_sha256": digest.hexdigest(),
    }


def enrich_entries(entries: list[dict[str, str]]) -> list[dict[str, Any]]:
    paths = [REPO_ROOT / item["path"] for item in entries]
    allocated = PHASE1.du_sizes(paths, apparent=False)
    apparent = PHASE1.du_sizes(paths, apparent=True)
    result: list[dict[str, Any]] = []
    for item in entries:
        path = REPO_ROOT / item["path"]
        metadata = path.stat(follow_symlinks=False)
        value: dict[str, Any] = {
            **item,
            "allocated_bytes": allocated[item["path"]],
            "apparent_bytes": apparent[item["path"]],
            "device": metadata.st_dev,
            "inode": metadata.st_ino,
            "mode": stat.S_IFMT(metadata.st_mode),
            "mtime_ns": metadata.st_mtime_ns,
            "size_bytes": metadata.st_size,
        }
        if item["kind"] == "dir":
            value.update(tree_metadata(path))
        result.append(value)
    return result


def aggregate(entries: Iterable[dict[str, Any]]) -> dict[str, Any]:
    by_category: dict[str, dict[str, int]] = defaultdict(
        lambda: {
            "target_count": 0,
            "allocated_bytes": 0,
            "apparent_bytes": 0,
        }
    )
    total = {"target_count": 0, "allocated_bytes": 0, "apparent_bytes": 0}
    for item in entries:
        for destination in (by_category[item["category"]], total):
            destination["target_count"] += 1
            destination["allocated_bytes"] += int(item["allocated_bytes"])
            destination["apparent_bytes"] += int(item["apparent_bytes"])
    return {"total": total, "by_category": dict(sorted(by_category.items()))}


def selected_tracked_paths(
    entries: list[dict[str, Any]],
    index_entries: dict[str, list[dict[str, Any]]],
) -> list[str]:
    selected_files = {
        item["path"] for item in entries if item["kind"] == "file"
    }
    selected_dirs = {
        item["path"] for item in entries if item["kind"] == "dir"
    }
    selected: list[str] = []
    for path in sorted(index_entries):
        if path in selected_files:
            selected.append(path)
            continue
        parts = path.split("/")
        if any("/".join(parts[:length]) in selected_dirs for length in range(1, len(parts))):
            selected.append(path)
    for path in selected:
        stages = index_entries[path]
        if len(stages) != 1 or stages[0]["stage"] != 0:
            raise CleanupError(f"不处理含冲突 stage 的 Git 临时路径：{path}")
    return selected


def prepare() -> None:
    with acquire_cleanup_lock():
        active = active_engineering_processes()
        if active:
            raise CleanupError(
                "检测到正在运行的仿真/综合/构建进程，拒绝冻结清理计划："
                + json.dumps(active, ensure_ascii=False)
            )
        protected_roots = PHASE1.protected_roots()
        protected_snapshot = PHASE1.protected_state(protected_roots)
        references, reference_snapshot = PHASE1.reference_closure()
        protected_file_references = exact_file_references(references)
        index_entries, index_snapshot = git_stage_entries()
        candidates, retained, clean_roots, latest_yosys_root = discover_candidates(
            protected_roots, protected_file_references
        )
        enriched = enrich_entries(candidates)
        tracked = selected_tracked_paths(enriched, index_entries)
        tracked_set = set(tracked)
        tracked_snapshot = {
            "path_count": len(tracked),
            "paths": [
                {
                    "path": path,
                    "index": index_entries[path][0],
                    "worktree_sha256": hashlib.sha256(
                        (REPO_ROOT / path).read_bytes()
                    ).hexdigest(),
                }
                for path in tracked
            ],
            "nonselected_stage_projection_sha256": projected_index_sha256(
                index_entries, tracked_set
            ),
        }
        plan = {
            "schema_version": 1,
            "run_id": RUN_ID,
            "created_at": utc_now(),
            "repo_root": REPO_ROOT.as_posix(),
            "executor": {
                "python": {
                    "path": relative(SCRIPT_PATH),
                    "sha256": hashlib.sha256(SCRIPT_PATH.read_bytes()).hexdigest(),
                },
                "wrapper": {
                    "path": relative(WRAPPER_PATH),
                    "sha256": hashlib.sha256(WRAPPER_PATH.read_bytes()).hexdigest(),
                },
                "phase1_library": {
                    "path": relative(PHASE1_SCRIPT),
                    "sha256": hashlib.sha256(PHASE1_SCRIPT.read_bytes()).hexdigest(),
                },
            },
            "policy": {
                "remove": [
                    "unreferenced-build-tree-non-record-files",
                    "unreferenced-direct-transient-files",
                    "selected-git-index-entries-for-those-temporary-files",
                ],
                "preserve": [
                    "result-and-log-suffixes",
                    "latest-unreferenced-yosys-netlist-and-sdc",
                    "all-evidence-bound-yosys-products",
                    "exact-file-evidence-references",
                    "directory-evidence-pointers-retain-only-results-and-logs",
                    "task-run-and-database-evidence-references",
                    "registered-or-nested-git-worktrees",
                    "three-explicit-dirty-rtl-tb-sandboxes",
                    "rv64-systemd-frozen-inputs-and-runtime-artifacts",
                    "linux-platform-images-and-logs",
                    "github-index-database",
                ],
                "execution": "anchored-quarantine-index-update-purge",
            },
            "clean_roots": clean_roots,
            "latest_yosys_product_root": latest_yosys_root,
            "guard_snapshots": {
                "protected_roots": protected_snapshot,
                "reference_paths": string_set_snapshot(references),
                "reference_metadata_at_prepare": reference_snapshot,
                "exact_file_references": string_set_snapshot(
                    protected_file_references
                ),
                "git_index": index_snapshot,
                "selected_tracked": tracked_snapshot,
            },
            "filesystem_available_bytes_before": PHASE1.filesystem_available_bytes(),
            "summary": aggregate(enriched),
            "retained_item_count": len(retained),
            "retained_reason_counts": dict(
                sorted(
                    (
                        reason,
                        sum(1 for item in retained if item["reason"] == reason),
                    )
                    for reason in {item["reason"] for item in retained}
                )
            ),
            "entries": enriched,
        }
        plan_bytes = (
            json.dumps(plan, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
        ).encode()
        plan_digest = hashlib.sha256(plan_bytes).hexdigest()
        atomic_write(PLAN_PATH, plan_bytes)
        atomic_write(
            PLAN_SHA_PATH,
            f"{plan_digest}  {PLAN_PATH.name}\n".encode(),
        )
        lines = [
            "category\tkind\ttracked\tallocated_bytes\tapparent_bytes\tpath"
        ]
        for item in enriched:
            item_path = item["path"]
            item_tracked = item_path in tracked_set or any(
                tracked_path.startswith(item_path + "/") for tracked_path in tracked
            )
            lines.append(
                "\t".join(
                    [
                        item["category"],
                        item["kind"],
                        "yes" if item_tracked else "no",
                        str(item["allocated_bytes"]),
                        str(item["apparent_bytes"]),
                        item_path,
                    ]
                )
            )
        atomic_write(PLAN_TSV_PATH, ("\n".join(lines) + "\n").encode())
        preview = {
            "run_id": RUN_ID,
            "status": "PASS",
            "prepared_at": utc_now(),
            "plan_sha256": plan_digest,
            "summary": plan["summary"],
            "selected_tracked_path_count": len(tracked),
            "selected_tracked_paths": tracked,
            "retained_item_count": len(retained),
            "retained_reason_counts": plan["retained_reason_counts"],
            "active_engineering_processes": [],
            "plan_tsv": relative(PLAN_TSV_PATH),
        }
        write_json(PREVIEW_PATH, preview)
        atomic_write(
            STATUS_PATH,
            (
                f"PREPARED plan_sha256={plan_digest} "
                f"targets={len(enriched)} tracked={len(tracked)} "
                f"allocated_bytes={plan['summary']['total']['allocated_bytes']}\n"
            ).encode(),
        )
        print(json.dumps(preview, ensure_ascii=False, indent=2, sort_keys=True))


def validate_entry(item: dict[str, Any], protected_roots: set[Path]) -> None:
    rel = item["path"]
    pure = PurePosixPath(rel)
    if pure.is_absolute() or not pure.parts or any(
        part in {"", ".", ".."} for part in pure.parts
    ):
        raise CleanupError(f"非法计划路径：{rel}")
    path = REPO_ROOT / rel
    if path.is_symlink() or not path.exists():
        raise CleanupError(f"计划目标缺失或变为符号链接：{rel}")
    if path_is_protected(path, protected_roots):
        raise CleanupError(f"计划目标进入受保护工作树：{rel}")
    metadata = path.stat(follow_symlinks=False)
    current = {
        "device": metadata.st_dev,
        "inode": metadata.st_ino,
        "mode": stat.S_IFMT(metadata.st_mode),
        "mtime_ns": metadata.st_mtime_ns,
        "size_bytes": metadata.st_size,
    }
    for key, value in current.items():
        if item.get(key) != value:
            raise CleanupError(f"计划目标属性漂移：{rel} field={key}")
    if item["kind"] == "dir":
        if not path.is_dir() or contains_git_admin(path):
            raise CleanupError(f"目录目标类型漂移或出现 Git 元数据：{rel}")
        current_tree = tree_metadata(path)
        for key, value in current_tree.items():
            if item.get(key) != value:
                raise CleanupError(f"目录树内容漂移：{rel} field={key}")
    elif item["kind"] == "file":
        if not path.is_file():
            raise CleanupError(f"文件目标类型漂移：{rel}")
    else:
        raise CleanupError(f"未知计划目标类型：{rel}")


def validate_plan(
    plan: dict[str, Any],
) -> tuple[
    list[dict[str, Any]],
    set[Path],
    set[str],
    dict[str, list[dict[str, Any]]],
]:
    if (
        plan.get("schema_version") != 1
        or plan.get("run_id") != RUN_ID
        or plan.get("repo_root") != REPO_ROOT.as_posix()
    ):
        raise CleanupError("清理计划 schema/run/root 不匹配")
    expected_executor = {
        "python": {
            "path": relative(SCRIPT_PATH),
            "sha256": hashlib.sha256(SCRIPT_PATH.read_bytes()).hexdigest(),
        },
        "wrapper": {
            "path": relative(WRAPPER_PATH),
            "sha256": hashlib.sha256(WRAPPER_PATH.read_bytes()).hexdigest(),
        },
        "phase1_library": {
            "path": relative(PHASE1_SCRIPT),
            "sha256": hashlib.sha256(PHASE1_SCRIPT.read_bytes()).hexdigest(),
        },
    }
    if plan.get("executor") != expected_executor:
        raise CleanupError("计划冻结后执行器发生变化")
    protected_roots = PHASE1.protected_roots()
    if PHASE1.protected_state(protected_roots) != plan["guard_snapshots"]["protected_roots"]:
        raise CleanupError("受保护 RTL/TB 工作树状态发生变化")
    references, _reference_snapshot = PHASE1.reference_closure()
    if string_set_snapshot(references) != plan["guard_snapshots"][
        "reference_paths"
    ]:
        raise CleanupError("task-run/数据库证据引用闭包发生变化")
    protected_file_references = exact_file_references(references)
    if string_set_snapshot(protected_file_references) != plan["guard_snapshots"][
        "exact_file_references"
    ]:
        raise CleanupError("精确文件证据引用集合发生变化")
    index_entries, index_snapshot = git_stage_entries()
    if index_snapshot != plan["guard_snapshots"]["git_index"]:
        raise CleanupError("Git 索引在计划冻结后发生变化")
    tracked_snapshot = plan["guard_snapshots"]["selected_tracked"]
    tracked = {item["path"] for item in tracked_snapshot["paths"]}
    if projected_index_sha256(index_entries, tracked) != tracked_snapshot[
        "nonselected_stage_projection_sha256"
    ]:
        raise CleanupError("非目标 Git 索引项发生变化")
    for item in tracked_snapshot["paths"]:
        path = item["path"]
        if index_entries.get(path) != [item["index"]]:
            raise CleanupError(f"目标 Git 索引项发生变化：{path}")
        if hashlib.sha256((REPO_ROOT / path).read_bytes()).hexdigest() != item[
            "worktree_sha256"
        ]:
            raise CleanupError(f"目标 Git 临时文件内容发生变化：{path}")
        if ancestor_reference(path, protected_file_references):
            raise CleanupError(f"目标 Git 临时文件进入证据引用闭包：{path}")

    entries = plan.get("entries")
    if not isinstance(entries, list):
        raise CleanupError("清理计划缺少 entries")
    seen: set[str] = set()
    for item in entries:
        if not isinstance(item, dict) or not isinstance(item.get("path"), str):
            raise CleanupError("清理计划包含畸形 entry")
        if item["path"] in seen:
            raise CleanupError(f"清理计划包含重复路径：{item['path']}")
        seen.add(item["path"])
        if ancestor_reference(item["path"], protected_file_references):
            raise CleanupError(f"计划目标进入证据引用闭包：{item['path']}")
        if item["kind"] == "dir" and descendant_reference(
            item["path"], sorted(protected_file_references)
        ):
            raise CleanupError(f"目录目标包含证据引用：{item['path']}")
        validate_entry(item, protected_roots)
    return entries, protected_roots, tracked, index_entries


def open_anchored_parent(rel: str) -> tuple[int, str]:
    pure = PurePosixPath(rel)
    if pure.is_absolute() or not pure.parts or any(
        part in {"", ".", ".."} for part in pure.parts
    ):
        raise CleanupError(f"非法锚定路径：{rel}")
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


def entry_stat_matches(item: dict[str, Any], metadata: os.stat_result) -> bool:
    return (
        metadata.st_dev == item["device"]
        and metadata.st_ino == item["inode"]
        and stat.S_IFMT(metadata.st_mode) == item["mode"]
        and metadata.st_mtime_ns == item["mtime_ns"]
        and metadata.st_size == item["size_bytes"]
    )


def journal_record(handle, value: dict[str, Any], *, durable: bool = False) -> None:
    handle.write(
        (json.dumps(value, ensure_ascii=False, sort_keys=True) + "\n").encode()
    )
    handle.flush()
    if durable:
        os.fsync(handle.fileno())


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
            if quarantined_exists and source_exists:
                errors.append(
                    f"source-and-quarantine-both-exist:{mapping['item']['path']}"
                )
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
                    f"source-and-quarantine-both-missing:{mapping['item']['path']}"
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


def remove_selected_index_paths(paths: set[str]) -> None:
    if not paths:
        return
    payload = b"".join(
        path.encode(errors="surrogateescape") + b"\0" for path in sorted(paths)
    )
    result = run(
        ["git", "update-index", "--force-remove", "-z", "--stdin"],
        check=False,
        input_bytes=payload,
    )
    if result.returncode != 0:
        raise CleanupError(
            "Git 索引解除跟踪失败："
            + result.stderr.decode(errors="replace").strip()
        )


def restore_selected_index_paths(
    paths: set[str], before: dict[str, list[dict[str, Any]]]
) -> None:
    if not paths:
        return
    payload = bytearray()
    for path in sorted(paths):
        values = before[path]
        if len(values) != 1 or values[0]["stage"] != 0:
            raise CleanupError(f"无法恢复非 stage-0 索引项：{path}")
        value = values[0]
        payload.extend(
            (
                f"{value['mode']} {value['oid']}\t{path}\0"
            ).encode(errors="surrogateescape")
        )
    result = run(
        ["git", "update-index", "-z", "--index-info"],
        check=False,
        input_bytes=bytes(payload),
    )
    if result.returncode != 0:
        raise CleanupError(
            "Git 索引回滚失败："
            + result.stderr.decode(errors="replace").strip()
        )


def execute(expected_digest: str) -> None:
    if os.environ.get("RV64_CLEANUP_WRAPPER_ACTIVE") != "1":
        raise CleanupError("执行动作必须由 execute_cleanup.sh 启动")
    if not re.fullmatch(r"[0-9a-f]{64}", expected_digest):
        raise CleanupError("计划 SHA-256 参数格式错误")
    plan_bytes = PLAN_PATH.read_bytes()
    actual_digest = hashlib.sha256(plan_bytes).hexdigest()
    if actual_digest != expected_digest:
        raise CleanupError(
            f"计划摘要不匹配：expected={expected_digest} actual={actual_digest}"
        )
    plan = json.loads(plan_bytes)
    active = active_engineering_processes()
    if active:
        raise CleanupError(
            "检测到正在运行的仿真/综合/构建进程："
            + json.dumps(active, ensure_ascii=False)
        )
    if QUARANTINE_PATH.exists() or QUARANTINE_PATH.is_symlink():
        raise CleanupError(f"隔离目录已存在，需先检查恢复状态：{QUARANTINE_PATH}")
    if not shutil.rmtree.avoids_symlink_attacks:
        raise CleanupError("当前 Python 平台不支持 descriptor-safe rmtree")

    started_at = utc_now()
    before_available = PHASE1.filesystem_available_bytes()
    staged: list[dict[str, Any]] = []
    purged: list[str] = []
    index_updated = False
    purge_started = False
    quarantine_fd = -1
    journal = None
    old_handlers: dict[signal.Signals, Any] = {}
    write_json(
        EXECUTION_PATH,
        {
            "run_id": RUN_ID,
            "status": "RUNNING",
            "stage": "preflight",
            "started_at": started_at,
            "plan_sha256": actual_digest,
        },
    )

    def interrupt_handler(signum, _frame) -> None:
        raise CleanupInterrupted(f"收到 {signal.Signals(signum).name}")

    with acquire_cleanup_lock():
        try:
            for signal_name in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM):
                old_handlers[signal_name] = signal.signal(
                    signal_name, interrupt_handler
                )
            write_stage("validating", staged_count=0, purged_count=0)
            entries, protected_roots, tracked, before_index = validate_plan(plan)
            nonselected_digest = plan["guard_snapshots"]["selected_tracked"][
                "nonselected_stage_projection_sha256"
            ]

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
            write_stage("quarantining", staged_count=0, purged_count=0)

            for index, item in enumerate(entries):
                validate_entry(item, protected_roots)
                parent_fd, original_name = open_anchored_parent(item["path"])
                quarantine_name = (
                    f"{index:06d}-"
                    f"{hashlib.sha256(item['path'].encode()).hexdigest()[:20]}"
                )
                mapping = {"item": item, "quarantine_name": quarantine_name}
                staged.append(mapping)
                try:
                    before_stat = os.stat(
                        original_name,
                        dir_fd=parent_fd,
                        follow_symlinks=False,
                    )
                    if not entry_stat_matches(item, before_stat):
                        raise CleanupError(
                            f"隔离前 inode 属性漂移：{item['path']}"
                        )
                    journal_record(
                        journal,
                        {
                            "event": "intent",
                            "path": item["path"],
                            "kind": item["kind"],
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
                    after_stat = os.stat(
                        quarantine_name,
                        dir_fd=quarantine_fd,
                        follow_symlinks=False,
                    )
                    if not entry_stat_matches(item, after_stat):
                        raise CleanupError(
                            f"隔离后 inode 属性不匹配：{item['path']}"
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
                        staged_count=index + 1,
                        purged_count=0,
                    )

            journal.flush()
            os.fsync(journal.fileno())
            if active_engineering_processes():
                raise CleanupError("隔离期间出现新的仿真/综合/构建进程")
            references_after, _reference_snapshot_after = PHASE1.reference_closure()
            if string_set_snapshot(references_after) != plan["guard_snapshots"][
                "reference_paths"
            ]:
                raise CleanupError("隔离期间证据引用闭包发生变化")
            if PHASE1.protected_state(protected_roots) != plan["guard_snapshots"][
                "protected_roots"
            ]:
                raise CleanupError("隔离期间受保护 RTL/TB 工作树发生变化")

            remove_selected_index_paths(tracked)
            index_updated = bool(tracked)
            after_index, _ = git_stage_entries()
            if any(path in after_index for path in tracked):
                raise CleanupError("部分目标 Git 索引项仍存在")
            if projected_index_sha256(after_index, set()) != nonselected_digest:
                raise CleanupError("解除跟踪时改动了非目标 Git 索引项")

            purge_started = True
            write_stage(
                "purging",
                staged_count=len(staged),
                purged_count=0,
            )
            for index, mapping in enumerate(staged):
                item = mapping["item"]
                name = mapping["quarantine_name"]
                if item["kind"] == "file":
                    os.unlink(name, dir_fd=quarantine_fd)
                else:
                    shutil.rmtree(name, dir_fd=quarantine_fd)
                purged.append(item["path"])
                journal_record(
                    journal,
                    {
                        "event": "purged",
                        "path": item["path"],
                        "quarantine_name": name,
                        "at": utc_now(),
                    },
                    durable=(index + 1) % 128 == 0,
                )
                if (index + 1) % 256 == 0:
                    write_stage(
                        "purging",
                        staged_count=len(staged),
                        purged_count=index + 1,
                    )
            journal.flush()
            os.fsync(journal.fileno())
            os.close(quarantine_fd)
            quarantine_fd = -1
            QUARANTINE_PATH.rmdir()

            remaining = [
                item["path"]
                for item in entries
                if (REPO_ROOT / item["path"]).exists()
                or (REPO_ROOT / item["path"]).is_symlink()
            ]
            if remaining:
                raise CleanupError(f"计划目标被重建：{remaining[:8]}")
            final_index, _ = git_stage_entries()
            if any(path in final_index for path in tracked):
                raise CleanupError("清理后目标 Git 索引项重新出现")
            if projected_index_sha256(final_index, set()) != nonselected_digest:
                raise CleanupError("清理后非目标 Git 索引投影发生变化")
            final_references, _final_reference_snapshot = PHASE1.reference_closure()
            if string_set_snapshot(final_references) != plan["guard_snapshots"][
                "reference_paths"
            ]:
                raise CleanupError("清理后证据引用闭包发生变化")
            if any(path in final_references for path in tracked):
                raise CleanupError("已删除 Git 临时路径意外成为保留证据")
            protection_after = PHASE1.protected_state(protected_roots)
            if protection_after != plan["guard_snapshots"]["protected_roots"]:
                raise CleanupError("清理后受保护 RTL/TB 工作树发生变化")

            after_available = PHASE1.filesystem_available_bytes()
            result = {
                "run_id": RUN_ID,
                "status": "PASS",
                "started_at": started_at,
                "finished_at": utc_now(),
                "plan_sha256": actual_digest,
                "removed_target_count": len(purged),
                "removed_git_tracked_path_count": len(tracked),
                "removed_git_tracked_paths": sorted(tracked),
                "planned_summary": plan["summary"],
                "filesystem_available_bytes_before": before_available,
                "filesystem_available_bytes_after": after_available,
                "observed_available_bytes_delta": after_available - before_available,
                "remaining_target_count": 0,
                "quarantine_remaining": False,
                "protected_roots_after": protection_after,
                "result_and_log_policy": "preserved",
            }
            write_json(EXECUTION_PATH, result)
            write_stage(
                "evidence-verified",
                staged_count=len(staged),
                purged_count=len(purged),
            )
            print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        except BaseException as error:
            rollback_errors: list[str] = []
            index_rollback_error: str | None = None
            if not purge_started:
                if index_updated:
                    try:
                        restore_selected_index_paths(tracked, before_index)
                        restored_index, _ = git_stage_entries()
                        expected_full = projected_index_sha256(before_index, set())
                        if projected_index_sha256(restored_index, set()) != expected_full:
                            raise CleanupError("Git 索引回滚后投影不匹配")
                    except BaseException as rollback_error:
                        index_rollback_error = (
                            f"{type(rollback_error).__name__}: {rollback_error}"
                        )
                if quarantine_fd >= 0 and journal is not None:
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
                "stage": "purging" if purge_started else "quarantining",
                "staged_target_count": len(staged),
                "purged_target_count": len(purged),
                "index_updated": index_updated,
                "index_rollback_error": index_rollback_error,
                "rollback_errors": rollback_errors,
                "quarantine_remaining": QUARANTINE_PATH.exists(),
                "error": f"{type(error).__name__}: {error}",
            }
            write_json(EXECUTION_PATH, result)
            write_stage(
                "failed",
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
        raise CleanupError(f"必须从仓库根运行：{REPO_ROOT}")
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
    except CleanupError as error:
        sys.stderr.write(f"cleanup precondition failed: {error}\n")
        raise SystemExit(2)
