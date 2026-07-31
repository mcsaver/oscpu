#!/usr/bin/env python3
"""Freeze and execute the bounded first-phase RV64 EDA artifact cleanup.

The executable plan is intentionally narrower than the repository retention
policy: it removes only reproducible compiler/elaboration caches, never
task-run evidence, logs, netlists, current Linux platform outputs, Git objects,
or nested/registered worktrees.
"""

from __future__ import annotations

import argparse
import bisect
import fcntl
import hashlib
import json
import os
import re
import shutil
import signal
import sqlite3
import stat
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


REPO_ROOT = Path("/home/lyg/PA/ysyx-workbench")
RUN_ID = "2026-07-31-workspace-artifact-cleanup-a1"
RUN_ROOT = REPO_ROOT / ".github" / "task-runs" / RUN_ID
SCRIPT_PATH = RUN_ROOT / "cleanup_first_phase.py"
WRAPPER_PATH = RUN_ROOT / "execute_cleanup.sh"
EVIDENCE_ROOT = RUN_ROOT / "evidence"
PLAN_PATH = EVIDENCE_ROOT / "cleanup-plan.json"
PLAN_SHA_PATH = EVIDENCE_ROOT / "cleanup-plan.sha256"
PLAN_TSV_PATH = EVIDENCE_ROOT / "cleanup-plan.tsv"
PREPARE_SUMMARY_PATH = EVIDENCE_ROOT / "prepare-summary.json"
EXECUTION_PATH = EVIDENCE_ROOT / "execution-result.json"
STATUS_PATH = RUN_ROOT / "cleanup.status"
STAGE_PATH = EVIDENCE_ROOT / "cleanup-stage.json"
JOURNAL_PATH = EVIDENCE_ROOT / "quarantine-journal.jsonl"
LOCK_PATH = EVIDENCE_ROOT / "cleanup.lock"
QUARANTINE_PATH = EVIDENCE_ROOT / ".cleanup-quarantine"

EXPLICIT_PROTECTED_REL = (
    "tmp/r3p2-functional-regress/r2p5-worktree",
    "tmp/r4-dual-hit-sandbox",
    "tmp/r3p2-early-wake-sandbox",
)

DENIED_REL = {
    ".",
    "tmp",
    "npc",
    "npc/rv64",
    "npc/rv64/testbench",
    "Linux",
    "Linux/env",
    "fpga",
    ".github",
    ".github/cache",
    ".github/task-runs",
}

EDA_PROCESS_NAMES = {
    "iverilog",
    "vvp",
    "verilator",
    "verilator_bin",
    "yosys",
    "openroad",
    "vivado",
    "make",
    "ninja",
    "mill",
    "sbt",
    "nemu",
    "npc",
    "emu",
    "qemu-system-riscv64",
}

EVIDENCE_PATH_RE = re.compile(
    r"(?<![A-Za-z0-9_.-])"
    r"((?:tmp|npc/rv64|Linux/env|fpga|\.github/cache)/"
    r"[^\s`\"')\]}>;,]+)"
)
MARKDOWN_LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")


class CleanupError(RuntimeError):
    """Fail-closed cleanup precondition violation."""


class CleanupInterrupted(CleanupError):
    """Catchable HUP/INT/TERM marker used to write a fail-closed cursor."""


def run(
    argv: list[str],
    *,
    cwd: Path = REPO_ROOT,
    check: bool = True,
    input_bytes: bytes | None = None,
) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        argv,
        cwd=cwd,
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


def reject_newline(path: Path) -> None:
    if "\n" in os.fspath(path) or "\r" in os.fspath(path):
        raise CleanupError(f"newline-bearing path is not supported: {path!s}")


def registered_worktrees() -> set[Path]:
    result = run(["git", "worktree", "list", "--porcelain"])
    protected: set[Path] = set()
    for raw_line in result.stdout.decode(errors="surrogateescape").splitlines():
        if not raw_line.startswith("worktree "):
            continue
        candidate = Path(raw_line.removeprefix("worktree ")).resolve(strict=False)
        if candidate != REPO_ROOT and is_within(candidate, REPO_ROOT):
            protected.add(candidate)
    return protected


def explicit_protected_roots() -> set[Path]:
    return {(REPO_ROOT / item).resolve(strict=False) for item in EXPLICIT_PROTECTED_REL}


def protected_roots() -> set[Path]:
    return registered_worktrees() | explicit_protected_roots()


def is_protected(path: Path, roots: Iterable[Path]) -> bool:
    resolved = path.resolve(strict=False)
    return any(is_within(resolved, root) for root in roots)


def contains_git_admin(path: Path) -> bool:
    result = run(
        ["find", os.fspath(path), "-xdev", "-name", ".git", "-print", "-quit"],
        check=False,
    )
    if result.returncode != 0:
        raise CleanupError(
            f"cannot inspect nested Git metadata in {relative(path)}: "
            f"{result.stderr.decode(errors='replace').strip()}"
        )
    return bool(result.stdout.strip(b"\n"))


def classify(path: Path, kind: str) -> str:
    rel = relative(path)
    pure = Path(rel)
    if kind == "file" and rel.startswith("tmp/") and pure.suffix == ".vvp":
        return "tmp-vvp"
    if kind == "dir" and rel.startswith("tmp/") and pure.name == "obj_dir":
        return "tmp-obj-dir"
    exact = {
        ("dir", "fpga/.Xil"): "fpga-xil-cache",
        ("dir", ".github/cache/rv64-functional-v9l"): "functional-cache",
    }
    category = exact.get((kind, rel))
    if category:
        return category
    raise CleanupError(f"path is outside the first-phase class boundary: {kind} {rel}")


def validate_path(path: Path, kind: str, roots: Iterable[Path]) -> None:
    reject_newline(path)
    if path.is_symlink():
        raise CleanupError(f"symbolic-link target is forbidden: {relative(path)}")
    if not path.exists():
        raise CleanupError(f"planned target no longer exists: {relative(path)}")
    if kind == "file" and not path.is_file():
        raise CleanupError(f"planned file changed type: {relative(path)}")
    if kind == "dir" and not path.is_dir():
        raise CleanupError(f"planned directory changed type: {relative(path)}")
    resolved = path.resolve(strict=True)
    if not is_within(resolved, REPO_ROOT) or resolved == REPO_ROOT:
        raise CleanupError(f"target resolves outside the repository: {path!s}")
    rel = relative(resolved)
    if rel in DENIED_REL:
        raise CleanupError(f"broad target is forbidden: {rel}")
    if is_protected(resolved, roots):
        raise CleanupError(f"target enters protected RTL/TB worktree: {rel}")
    classify(resolved, kind)


def discover_candidates(roots: set[Path]) -> list[dict[str, str]]:
    directory_candidates: set[Path] = set()
    file_candidates: set[Path] = set()
    tmp_root = REPO_ROOT / "tmp"

    for root_text, dirs, files in os.walk(tmp_root, topdown=True, followlinks=False):
        root = Path(root_text)
        if root != tmp_root and (root / ".git").exists():
            dirs[:] = []
            continue
        if is_protected(root, roots):
            dirs[:] = []
            continue

        retained_dirs: list[str] = []
        for name in dirs:
            child = root / name
            if child.is_symlink() or is_protected(child, roots):
                continue
            if (child / ".git").exists():
                continue
            if name == "obj_dir":
                directory_candidates.add(child)
                continue
            retained_dirs.append(name)
        dirs[:] = retained_dirs

        for name in files:
            child = root / name
            if child.suffix == ".vvp" and not child.is_symlink():
                file_candidates.add(child)

    for rel in (
        "fpga/.Xil",
        ".github/cache/rv64-functional-v9l",
    ):
        child = REPO_ROOT / rel
        if child.is_dir() and not child.is_symlink():
            directory_candidates.add(child)

    for directory in tuple(directory_candidates):
        if contains_git_admin(directory):
            directory_candidates.remove(directory)

    # Directory targets dominate their contained files so every byte is planned once.
    for file_path in tuple(file_candidates):
        if any(is_within(file_path, directory) for directory in directory_candidates):
            file_candidates.remove(file_path)

    result = [
        {"kind": "dir", "path": relative(item)}
        for item in sorted(directory_candidates, key=lambda value: relative(value))
    ]
    result.extend(
        {"kind": "file", "path": relative(item)}
        for item in sorted(file_candidates, key=lambda value: relative(value))
    )
    for item in result:
        validate_path(REPO_ROOT / item["path"], item["kind"], roots)
        item["category"] = classify(REPO_ROOT / item["path"], item["kind"])
    return result


def git_index_path() -> Path:
    result = run(["git", "rev-parse", "--git-path", "index"])
    raw = result.stdout.decode(errors="surrogateescape").strip()
    path = Path(raw)
    if not path.is_absolute():
        path = REPO_ROOT / path
    return path.resolve(strict=True)


def git_index_state(*, include_content_sha256: bool) -> dict[str, Any]:
    path = git_index_path()
    metadata = path.stat(follow_symlinks=False)
    result: dict[str, Any] = {
        "path": os.fspath(path),
        "device": metadata.st_dev,
        "inode": metadata.st_ino,
        "size": metadata.st_size,
        "mtime_ns": metadata.st_mtime_ns,
    }
    if include_content_sha256:
        result["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result


def git_tracked_paths() -> tuple[list[str], dict[str, Any]]:
    result = run(["git", "ls-files", "-z"])
    paths = sorted(
        item.decode(errors="surrogateescape")
        for item in result.stdout.split(b"\0")
        if item
    )
    return paths, {
        "tracked_path_count": len(paths),
        "tracked_paths_sha256": hashlib.sha256(result.stdout).hexdigest(),
        "index": git_index_state(include_content_sha256=True),
    }


def prefix_member(sorted_paths: list[str], prefix: str) -> str | None:
    position = bisect.bisect_left(sorted_paths, prefix)
    if position >= len(sorted_paths):
        return None
    candidate = sorted_paths[position]
    if candidate == prefix or candidate.startswith(prefix + "/"):
        return candidate
    return None


def normalize_reference(raw: str, source_dir: Path) -> str | None:
    token = raw.strip().strip("`\"'")
    token = token.partition("#")[0].partition("?")[0]
    if not token or "\n" in token or "\r" in token:
        return None
    path = Path(token)
    if path.is_absolute():
        resolved = path.resolve(strict=False)
    elif token.startswith(("tmp/", "npc/", "Linux/", "fpga/", ".github/")):
        resolved = (REPO_ROOT / path).resolve(strict=False)
    else:
        resolved = (source_dir / path).resolve(strict=False)
    if not is_within(resolved, REPO_ROOT):
        return None
    return relative(resolved)


def iter_json_strings(value: Any) -> Iterable[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from iter_json_strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_json_strings(child)


def task_run_references() -> tuple[set[str], dict[str, Any]]:
    references: set[str] = set()
    task_runs = REPO_ROOT / ".github" / "task-runs"
    run_roots = sorted(
        (
            item
            for item in task_runs.iterdir()
            if item.is_dir() and item.resolve(strict=False) != RUN_ROOT
        ),
        key=os.fspath,
    )
    source_hasher = hashlib.sha256()
    source_count = 0
    missing_manifest = 0
    missing_index = 0
    retained_suffixes = {".md", ".json", ".jsonl", ".tsv", ".status", ".txt"}

    for run_root in run_roots:
        manifest = run_root / "run-manifest.json"
        index = run_root / "evidence-index.md"
        if not manifest.is_file():
            missing_manifest += 1
        if not index.is_file():
            missing_index += 1
        if not manifest.is_file() or not index.is_file():
            # Missing retained contracts cannot silently authorize deletion of
            # a same-named volatile cohort.
            references.add(f"tmp/{run_root.name}")

        for source in sorted(
            (
                item
                for item in run_root.iterdir()
                if item.is_file() and item.suffix in retained_suffixes
            ),
            key=os.fspath,
        ):
            try:
                raw_bytes = source.read_bytes()
            except OSError as error:
                raise CleanupError(
                    f"cannot read retained task-run source {relative(source)}: {error}"
                ) from error
            source_count += 1
            source_hasher.update(relative(source).encode())
            source_hasher.update(b"\0")
            source_hasher.update(hashlib.sha256(raw_bytes).digest())
            source_hasher.update(b"\0")
            text = raw_bytes.decode("utf-8", errors="replace")

            if source.name == "run-manifest.json":
                try:
                    content = json.loads(text)
                except json.JSONDecodeError as error:
                    raise CleanupError(
                        f"invalid retained run manifest {relative(source)}: {error}"
                    ) from error
                for raw in iter_json_strings(content):
                    normalized = normalize_reference(raw, source.parent)
                    if normalized:
                        references.add(normalized)

            for raw in MARKDOWN_LINK_RE.findall(text):
                normalized = normalize_reference(raw, source.parent)
                if normalized:
                    references.add(normalized)
            for raw in EVIDENCE_PATH_RE.findall(text):
                normalized = normalize_reference(raw, REPO_ROOT)
                if normalized:
                    references.add(normalized)

    return references, {
        "run_root_count": len(run_roots),
        "retained_source_count": source_count,
        "retained_source_sha256": source_hasher.hexdigest(),
        "missing_manifest_count": missing_manifest,
        "missing_evidence_index_count": missing_index,
    }


def database_references() -> tuple[set[str], dict[str, Any]]:
    db = REPO_ROOT / ".github" / "cache" / "github-index.sqlite"
    if not db.is_file():
        raise CleanupError("evidence database is missing")
    uri = f"file:{db.as_posix()}?mode=ro"
    connection = sqlite3.connect(uri, uri=True)
    try:
        rows = connection.execute(
            "SELECT path FROM evidence_assets ORDER BY path"
        ).fetchall()
    except sqlite3.Error as error:
        raise CleanupError(f"cannot read evidence_assets: {error}") from error
    finally:
        connection.close()
    references: set[str] = set()
    raw_hasher = hashlib.sha256()
    ignored_external = 0
    for row in rows:
        raw = str(row[0])
        raw_hasher.update(raw.encode())
        raw_hasher.update(b"\0")
        normalized = normalize_reference(raw, REPO_ROOT)
        if normalized:
            references.add(normalized)
        else:
            ignored_external += 1
    metadata = db.stat()
    return references, {
        "row_count": len(rows),
        "path_sha256": raw_hasher.hexdigest(),
        "ignored_external_path_count": ignored_external,
        "database_device": metadata.st_dev,
        "database_inode": metadata.st_ino,
        "database_size": metadata.st_size,
        "database_mtime_ns": metadata.st_mtime_ns,
    }


def reference_closure() -> tuple[set[str], dict[str, Any]]:
    task_refs, task_snapshot = task_run_references()
    db_refs, db_snapshot = database_references()
    references = task_refs | db_refs
    closure_hasher = hashlib.sha256()
    for item in sorted(references):
        closure_hasher.update(item.encode())
        closure_hasher.update(b"\0")
    return references, {
        "reference_count": len(references),
        "reference_sha256": closure_hasher.hexdigest(),
        "task_runs": task_snapshot,
        "database": db_snapshot,
    }


def reference_hit(
    references: set[str],
    sorted_references: list[str],
    target: str,
    kind: str,
) -> str | None:
    parts = target.split("/")
    for length in range(len(parts), 0, -1):
        ancestor = "/".join(parts[:length])
        if ancestor in references:
            return ancestor
    if kind == "dir":
        prefix = target + "/"
        position = bisect.bisect_left(sorted_references, prefix)
        if (
            position < len(sorted_references)
            and sorted_references[position].startswith(prefix)
        ):
            return sorted_references[position]
    return None


def filter_protected_candidates(
    candidates: list[dict[str, str]],
    tracked: list[str],
    references: set[str],
) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    tracked_set = set(tracked)
    sorted_references = sorted(references)
    approved: list[dict[str, str]] = []
    rejected: list[dict[str, str]] = []

    for item in candidates:
        rel = item["path"]
        tracked_hit = (
            (rel if rel in tracked_set else None)
            if item["kind"] == "file"
            else prefix_member(tracked, rel)
        )
        if tracked_hit:
            rejected.append({**item, "reason": f"git-tracked:{tracked_hit}"})
            continue
        evidence_hit = reference_hit(
            references, sorted_references, rel, item["kind"]
        )
        if evidence_hit:
            rejected.append({**item, "reason": f"evidence-reference:{evidence_hit}"})
            continue
        approved.append(item)
    return approved, rejected


def du_sizes(paths: list[Path], apparent: bool) -> dict[str, int]:
    if not paths:
        return {}
    argv = ["du", "-s", "-B1", "--null", "--files0-from=-"]
    if apparent:
        argv.insert(1, "--apparent-size")
    payload = b"\0".join(os.fsencode(path) for path in paths) + b"\0"
    result = run(argv, input_bytes=payload)
    sizes: dict[str, int] = {}
    for record in result.stdout.split(b"\0"):
        if not record:
            continue
        size_raw, path_raw = record.split(b"\t", 1)
        path = Path(os.fsdecode(path_raw))
        sizes[relative(path.resolve(strict=True))] = int(size_raw)
    return sizes


def filesystem_available_bytes() -> int:
    info = os.statvfs(REPO_ROOT)
    return info.f_bavail * info.f_frsize


def protected_state(roots: Iterable[Path]) -> list[dict[str, Any]]:
    state: list[dict[str, Any]] = []
    for root in sorted(roots, key=os.fspath):
        if not root.exists():
            state.append({"path": relative(root), "exists": False})
            continue
        head = run(["git", "-C", os.fspath(root), "rev-parse", "HEAD"], check=False)
        status_result = run(
            ["git", "-C", os.fspath(root), "status", "--porcelain=v1", "-z"],
            check=False,
        )
        worktree_diff = run(
            ["git", "-C", os.fspath(root), "diff", "--binary", "--no-ext-diff"],
            check=False,
        )
        index_diff = run(
            [
                "git",
                "-C",
                os.fspath(root),
                "diff",
                "--cached",
                "--binary",
                "--no-ext-diff",
            ],
            check=False,
        )
        status_bytes = status_result.stdout
        state.append(
            {
                "path": relative(root),
                "exists": True,
                "head": head.stdout.decode(errors="replace").strip()
                if head.returncode == 0
                else None,
                "status_entry_count": len(
                    [part for part in status_bytes.split(b"\0") if part]
                ),
                "status_sha256": hashlib.sha256(status_bytes).hexdigest(),
                "tracked_worktree_diff_sha256": hashlib.sha256(
                    worktree_diff.stdout
                ).hexdigest(),
                "tracked_index_diff_sha256": hashlib.sha256(
                    index_diff.stdout
                ).hexdigest(),
            }
        )
    return state


def active_eda_processes() -> list[dict[str, Any]]:
    result = run(["ps", "-eo", "pid=,comm=,args="])
    active: list[dict[str, Any]] = []
    for line in result.stdout.decode(errors="replace").splitlines():
        fields = line.strip().split(None, 2)
        if len(fields) < 2:
            continue
        pid_raw, command = fields[:2]
        arguments = fields[2] if len(fields) == 3 else command
        if command in EDA_PROCESS_NAMES:
            active.append(
                {"pid": int(pid_raw), "command": command, "arguments": arguments}
            )
    return active


def acquire_cleanup_lock():
    EVIDENCE_ROOT.mkdir(parents=True, exist_ok=True)
    handle = LOCK_PATH.open("a+", encoding="utf-8")
    try:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError as error:
        handle.close()
        raise CleanupError("another artifact cleanup holds the exclusive lock") from error
    handle.seek(0)
    handle.truncate()
    handle.write(f"pid={os.getpid()} acquired_at={utc_now()}\n")
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


def enrich_entries(entries: list[dict[str, str]]) -> list[dict[str, Any]]:
    paths = [REPO_ROOT / item["path"] for item in entries]
    allocated = du_sizes(paths, apparent=False)
    apparent = du_sizes(paths, apparent=True)
    enriched: list[dict[str, Any]] = []
    for item in entries:
        path = REPO_ROOT / item["path"]
        metadata = path.stat(follow_symlinks=False)
        enriched.append(
            {
                **item,
                "allocated_bytes": allocated[item["path"]],
                "apparent_bytes": apparent[item["path"]],
                "device": metadata.st_dev,
                "inode": metadata.st_ino,
                "mode": stat.S_IFMT(metadata.st_mode),
                "mtime_ns": metadata.st_mtime_ns,
                "size_bytes": metadata.st_size,
            }
        )
    return enriched


def aggregate(entries: Iterable[dict[str, Any]]) -> dict[str, Any]:
    by_category: dict[str, dict[str, int]] = defaultdict(
        lambda: {"target_count": 0, "allocated_bytes": 0, "apparent_bytes": 0}
    )
    total = {"target_count": 0, "allocated_bytes": 0, "apparent_bytes": 0}
    for item in entries:
        category = by_category[item["category"]]
        for destination in (category, total):
            destination["target_count"] += 1
            destination["allocated_bytes"] += int(item["allocated_bytes"])
            destination["apparent_bytes"] += int(item["apparent_bytes"])
    return {"total": total, "by_category": dict(sorted(by_category.items()))}


def write_prepared_plan(
    plan: dict[str, Any],
    enriched: list[dict[str, Any]],
    rejected: list[dict[str, str]],
) -> None:
    plan_bytes = (
        json.dumps(plan, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode()
    digest = hashlib.sha256(plan_bytes).hexdigest()
    atomic_write(PLAN_PATH, plan_bytes)
    atomic_write(PLAN_SHA_PATH, f"{digest}  {PLAN_PATH.name}\n".encode())

    lines = [
        "category\tkind\tallocated_bytes\tapparent_bytes\tmtime_ns\tpath"
    ]
    for item in enriched:
        lines.append(
            "\t".join(
                [
                    item["category"],
                    item["kind"],
                    str(item["allocated_bytes"]),
                    str(item["apparent_bytes"]),
                    str(item["mtime_ns"]),
                    item["path"],
                ]
            )
        )
    atomic_write(PLAN_TSV_PATH, ("\n".join(lines) + "\n").encode())
    summary = {
        "run_id": RUN_ID,
        "prepared_at": utc_now(),
        "plan_sha256": digest,
        "approved": aggregate(enriched),
        "rejected_target_count": len(rejected),
        "rejected": rejected,
        "active_eda_processes": [],
        "guard_snapshots": plan["guard_snapshots"],
    }
    write_json(PREPARE_SUMMARY_PATH, summary)
    atomic_write(
        STATUS_PATH,
        (
            f"PREPARED plan_sha256={digest} "
            f"targets={len(enriched)} "
            f"allocated_bytes={plan['summary']['total']['allocated_bytes']}\n"
        ).encode(),
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))


def prepare() -> None:
    with acquire_cleanup_lock():
        roots = protected_roots()
        if active_eda_processes():
            raise CleanupError(
                "active EDA/build process detected; refusing to freeze a plan"
            )
        tracked, tracked_snapshot = git_tracked_paths()
        references, reference_snapshot = reference_closure()
        discovered = discover_candidates(roots)
        approved, rejected = filter_protected_candidates(
            discovered, tracked, references
        )
        enriched = enrich_entries(approved)
        plan = {
            "schema_version": 2,
            "run_id": RUN_ID,
            "created_at": utc_now(),
            "repo_root": REPO_ROOT.as_posix(),
            "executor": {
                "python": {
                    "path": relative(SCRIPT_PATH),
                    "sha256": hashlib.sha256(SCRIPT_PATH.read_bytes()).hexdigest(),
                },
                "status_wrapper": {
                    "path": relative(WRAPPER_PATH),
                    "sha256": hashlib.sha256(WRAPPER_PATH.read_bytes()).hexdigest(),
                },
            },
            "policy": {
                "remove_only": [
                    "tmp-vvp",
                    "tmp-obj-dir",
                    "fpga-xil-cache",
                    "functional-cache",
                ],
                "preserve": [
                    "registered-or-nested-git-worktrees",
                    "task-run-evidence-and-logs",
                    "current-linux-platform-builds",
                    "all-npc-build-directories",
                    "linux-env-build-until-current-resolver-is-bound",
                    "git-object-store",
                    "rtl-netlists-sta-and-ppa-results",
                ],
                "execution": "anchored-atomic-quarantine-then-purge",
            },
            "guard_snapshots": {
                "git": tracked_snapshot,
                "evidence_references": reference_snapshot,
            },
            "protected_roots": protected_state(roots),
            "filesystem_available_bytes_before": filesystem_available_bytes(),
            "summary": aggregate(enriched),
            "entries": enriched,
        }
        write_prepared_plan(plan, enriched, rejected)


def validate_frozen_plan(
    plan: dict[str, Any],
) -> tuple[list[dict[str, Any]], set[Path], list[str], set[str]]:
    if plan.get("schema_version") != 2 or plan.get("run_id") != RUN_ID:
        raise CleanupError("plan identity/schema mismatch")
    if plan.get("repo_root") != REPO_ROOT.as_posix():
        raise CleanupError("plan repository root mismatch")
    executor = plan.get("executor")
    if (
        not isinstance(executor, dict)
        or executor.get("python")
        != {
            "path": relative(SCRIPT_PATH),
            "sha256": hashlib.sha256(SCRIPT_PATH.read_bytes()).hexdigest(),
        }
        or executor.get("status_wrapper")
        != {
            "path": relative(WRAPPER_PATH),
            "sha256": hashlib.sha256(WRAPPER_PATH.read_bytes()).hexdigest(),
        }
    ):
        raise CleanupError("executor changed after plan freeze")
    roots = protected_roots()
    frozen_protection = plan.get("protected_roots")
    current_protection = protected_state(roots)
    if frozen_protection != current_protection:
        raise CleanupError("protected RTL/TB worktree state changed after plan freeze")

    entries = plan.get("entries")
    if not isinstance(entries, list):
        raise CleanupError("plan entries are missing")
    seen: set[str] = set()
    for item in entries:
        if not isinstance(item, dict):
            raise CleanupError("malformed plan entry")
        rel = item.get("path")
        kind = item.get("kind")
        if not isinstance(rel, str) or kind not in {"file", "dir"}:
            raise CleanupError("malformed plan path/type")
        if rel in seen:
            raise CleanupError(f"duplicate plan path: {rel}")
        seen.add(rel)
        path = REPO_ROOT / rel
        validate_path(path, kind, roots)
        if classify(path.resolve(strict=True), kind) != item.get("category"):
            raise CleanupError(f"category changed after freeze: {rel}")

    tracked, tracked_snapshot = git_tracked_paths()
    references, reference_snapshot = reference_closure()
    frozen_guards = plan.get("guard_snapshots")
    current_guards = {
        "git": tracked_snapshot,
        "evidence_references": reference_snapshot,
    }
    if frozen_guards != current_guards:
        raise CleanupError("Git/evidence reference closure changed after plan freeze")

    current_candidates: list[dict[str, str]] = [
        {"path": item["path"], "kind": item["kind"], "category": item["category"]}
        for item in entries
    ]
    approved, rejected = filter_protected_candidates(
        current_candidates, tracked, references
    )
    if rejected or len(approved) != len(entries):
        raise CleanupError(
            "Git/evidence protection changed after plan freeze: "
            + json.dumps(rejected, ensure_ascii=False)
        )
    current_enriched = enrich_entries(current_candidates)
    frozen_by_path = {item["path"]: item for item in entries}
    immutable_fields = (
        "kind",
        "category",
        "allocated_bytes",
        "apparent_bytes",
        "device",
        "inode",
        "mode",
        "mtime_ns",
        "size_bytes",
    )
    for current in current_enriched:
        frozen = frozen_by_path[current["path"]]
        for field in immutable_fields:
            if current[field] != frozen.get(field):
                raise CleanupError(
                    f"target changed after plan freeze: {current['path']} field={field}"
                )
    return entries, roots, tracked, references


def assert_git_index_unchanged(frozen: dict[str, Any]) -> None:
    current = git_index_state(include_content_sha256=False)
    expected = {
        key: value
        for key, value in frozen.items()
        if key in {"path", "device", "inode", "size", "mtime_ns"}
    }
    if current != expected:
        raise CleanupError("Git index changed while the cleanup lock was held")


def assert_cached_target_protection(
    item: dict[str, Any],
    roots: set[Path],
    tracked: list[str],
    tracked_set: set[str],
    references: set[str],
    sorted_references: list[str],
    frozen_git_index: dict[str, Any],
) -> None:
    rel = item["path"]
    kind = item["kind"]
    path = REPO_ROOT / rel
    if is_protected(path, roots):
        raise CleanupError(f"target entered protected worktree: {rel}")
    tracked_hit = (
        (rel if rel in tracked_set else None)
        if kind == "file"
        else prefix_member(tracked, rel)
    )
    if tracked_hit:
        raise CleanupError(f"target became Git tracked: {tracked_hit}")
    evidence_hit = reference_hit(references, sorted_references, rel, kind)
    if evidence_hit:
        raise CleanupError(f"target became retained evidence: {evidence_hit}")
    assert_git_index_unchanged(frozen_git_index)


def open_anchored_parent(rel: str) -> tuple[int, str]:
    pure = PurePosixPath(rel)
    if pure.is_absolute() or not pure.parts:
        raise CleanupError(f"invalid anchored path: {rel}")
    if any(part in {"", ".", ".."} for part in pure.parts):
        raise CleanupError(f"unsafe anchored path component: {rel}")
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
                errors.append(f"both-source-and-quarantine-exist:{mapping['item']['path']}")
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
                        "quarantine_name": mapping["quarantine_name"],
                        "at": utc_now(),
                    },
                )
            elif not source_exists:
                errors.append(f"missing-source-and-quarantine:{mapping['item']['path']}")
        except BaseException as error:
            errors.append(f"{mapping['item']['path']}:{type(error).__name__}:{error}")
        finally:
            if parent_fd >= 0:
                os.close(parent_fd)
    journal.flush()
    os.fsync(journal.fileno())
    return errors


def current_guard_snapshots() -> tuple[list[str], set[str], dict[str, Any]]:
    tracked, tracked_snapshot = git_tracked_paths()
    references, reference_snapshot = reference_closure()
    return tracked, references, {
        "git": tracked_snapshot,
        "evidence_references": reference_snapshot,
    }


def execute(expected_digest: str) -> None:
    if os.environ.get("RV64_CLEANUP_WRAPPER_ACTIVE") != "1":
        raise CleanupError("execution must run through execute_cleanup.sh")
    if not re.fullmatch(r"[0-9a-f]{64}", expected_digest):
        raise CleanupError("expected plan SHA-256 must be 64 lowercase hex digits")
    plan_bytes = PLAN_PATH.read_bytes()
    actual_digest = hashlib.sha256(plan_bytes).hexdigest()
    if actual_digest != expected_digest:
        raise CleanupError(
            f"frozen plan digest mismatch: expected={expected_digest} actual={actual_digest}"
        )
    plan = json.loads(plan_bytes)
    if active_eda_processes():
        raise CleanupError("active EDA/build process detected before cleanup")
    if not shutil.rmtree.avoids_symlink_attacks:
        raise CleanupError("platform rmtree lacks descriptor-based symlink protection")
    if QUARANTINE_PATH.exists() or QUARANTINE_PATH.is_symlink():
        raise CleanupError(
            f"quarantine already exists; inspect recovery state: {relative(QUARANTINE_PATH)}"
        )

    started_at = utc_now()
    before_available = filesystem_available_bytes()
    staged: list[dict[str, Any]] = []
    purged: list[str] = []
    purge_started = False
    quarantine_fd = -1
    journal = None
    old_handlers: dict[signal.Signals, Any] = {}
    write_json(
        EXECUTION_PATH,
        {
            "run_id": RUN_ID,
            "status": "RUNNING",
            "started_at": started_at,
            "plan_sha256": actual_digest,
            "stage": "preflight",
            "staged_target_count": 0,
            "purged_target_count": 0,
        },
    )

    def interrupt_handler(signum, _frame) -> None:
        signal_name = signal.Signals(signum).name
        raise CleanupInterrupted(f"received {signal_name}")

    with acquire_cleanup_lock():
        try:
            for signal_name in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM):
                old_handlers[signal_name] = signal.signal(
                    signal_name, interrupt_handler
                )
            write_stage("validating", staged_count=0, purged_count=0)
            entries, roots, tracked, references = validate_frozen_plan(plan)
            tracked_set = set(tracked)
            sorted_references = sorted(references)
            frozen_git_index = plan["guard_snapshots"]["git"]["index"]

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
                assert_cached_target_protection(
                    item,
                    roots,
                    tracked,
                    tracked_set,
                    references,
                    sorted_references,
                    frozen_git_index,
                )
                parent_fd, original_name = open_anchored_parent(item["path"])
                quarantine_name = (
                    f"{index:05d}-"
                    f"{hashlib.sha256(item['path'].encode()).hexdigest()[:20]}"
                )
                mapping = {
                    "item": item,
                    "quarantine_name": quarantine_name,
                }
                staged.append(mapping)
                try:
                    before_stat = os.stat(
                        original_name,
                        dir_fd=parent_fd,
                        follow_symlinks=False,
                    )
                    if not entry_stat_matches(item, before_stat):
                        raise CleanupError(
                            f"anchored target changed before quarantine: {item['path']}"
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
                            f"quarantined inode mismatch: {item['path']}"
                        )
                finally:
                    os.close(parent_fd)

                quarantined_path = QUARANTINE_PATH / quarantine_name
                if item["kind"] == "dir" and contains_git_admin(quarantined_path):
                    raise CleanupError(
                        f"nested Git metadata found after quarantine: {item['path']}"
                    )
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
            current_tracked, current_references, current_guards = (
                current_guard_snapshots()
            )
            if current_guards != plan["guard_snapshots"]:
                raise CleanupError("Git/evidence closure changed during quarantine")
            if protected_state(roots) != plan["protected_roots"]:
                raise CleanupError("protected RTL/TB worktree changed during quarantine")
            if active_eda_processes():
                raise CleanupError("EDA/build process appeared during quarantine")
            # Refresh cached sets from the verified closure before purge.
            tracked = current_tracked
            tracked_set = set(current_tracked)
            references = current_references
            sorted_references = sorted(current_references)
            for mapping in staged:
                assert_cached_target_protection(
                    mapping["item"],
                    roots,
                    tracked,
                    tracked_set,
                    references,
                    sorted_references,
                    frozen_git_index,
                )

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

            _, _, final_guards = current_guard_snapshots()
            if final_guards != plan["guard_snapshots"]:
                raise CleanupError("Git/evidence closure changed during purge")
            protection_after = protected_state(roots)
            if protection_after != plan["protected_roots"]:
                raise CleanupError("protected RTL/TB worktree changed during purge")
            remaining = [
                item["path"]
                for item in entries
                if (REPO_ROOT / item["path"]).exists()
                or (REPO_ROOT / item["path"]).is_symlink()
            ]
            if remaining:
                raise CleanupError(f"planned targets were recreated: {remaining[:8]}")

            after_available = filesystem_available_bytes()
            result = {
                "run_id": RUN_ID,
                "status": "PASS",
                "started_at": started_at,
                "finished_at": utc_now(),
                "plan_sha256": actual_digest,
                "planned_allocated_upper_bound": plan["summary"],
                "removed_target_count": len(purged),
                "filesystem_available_bytes_before": before_available,
                "filesystem_available_bytes_after": after_available,
                "observed_available_bytes_delta": after_available - before_available,
                "protected_roots_after": protection_after,
                "guard_snapshots_after": final_guards,
                "remaining_target_count": 0,
                "quarantine_remaining": False,
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
            if not purge_started and quarantine_fd >= 0 and journal is not None:
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
        raise CleanupError(
            f"run from exact repository root {REPO_ROOT}, got {Path.cwd().resolve()}"
        )
    if args.execute and not args.plan_sha256:
        parser.error("--execute requires --plan-sha256")
    if args.prepare and args.plan_sha256:
        parser.error("--plan-sha256 is only valid with --execute")
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
