#!/usr/bin/env python3
"""盘点 tmp 中可迁移日志的大小、内容哈希和证据绑定。"""

from __future__ import annotations

import hashlib
import importlib.util
import json
import os
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path("/home/lyg/PA/ysyx-workbench")
RUN_ROOT = (
    REPO_ROOT
    / ".github/task-runs/2026-07-31-tmp-log-selective-migration-a1"
)
EVIDENCE_ROOT = RUN_ROOT / "evidence"
PHASE1_SCRIPT = (
    REPO_ROOT
    / ".github/task-runs/2026-07-31-workspace-artifact-cleanup-a1/"
    "cleanup_first_phase.py"
)


def load_phase1():
    spec = importlib.util.spec_from_file_location("workspace_cleanup_phase1", PHASE1_SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError("无法加载第一阶段引用闭包实现")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.RUN_ROOT = RUN_ROOT
    return module


PHASE1 = load_phase1()


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def relative(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def atomic_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, path)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            block = handle.read(8 * 1024 * 1024)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def is_log(path: Path) -> bool:
    name = path.name.lower()
    return name.endswith((".log", ".log.gz", ".log.xz", ".log.zst"))


def cohort(path: Path) -> str:
    rel = path.relative_to(REPO_ROOT / "tmp")
    return rel.parts[0] if rel.parts else "tmp"


def main() -> int:
    active_before = PHASE1.active_eda_processes()
    if active_before:
        raise RuntimeError(
            "检测到正在运行的仿真/综合/构建进程，拒绝冻结日志盘点："
            + json.dumps(active_before, ensure_ascii=False)
        )
    protected_roots = PHASE1.protected_roots()
    protected_state = PHASE1.protected_state(protected_roots)
    references, reference_snapshot = PHASE1.reference_closure()
    exact_file_references = {
        item
        for item in references
        if (REPO_ROOT / item).is_file() and not (REPO_ROOT / item).is_symlink()
    }

    logs: list[dict[str, Any]] = []
    tmp_root = REPO_ROOT / "tmp"
    for root_raw, dir_names, file_names in os.walk(
        tmp_root, topdown=True, followlinks=False
    ):
        directory = Path(root_raw)
        if directory != tmp_root and (
            PHASE1.is_protected(directory, protected_roots)
            or (directory / ".git").exists()
        ):
            dir_names[:] = []
            continue
        dir_names[:] = [
            name
            for name in dir_names
            if not (directory / name).is_symlink()
            and not PHASE1.is_protected(directory / name, protected_roots)
            and not ((directory / name) / ".git").exists()
        ]
        for name in file_names:
            path = directory / name
            if path.is_symlink() or not is_log(path):
                continue
            metadata = path.stat(follow_symlinks=False)
            rel = relative(path)
            digest = sha256_file(path)
            metadata_after = path.stat(follow_symlinks=False)
            if (
                metadata.st_dev,
                metadata.st_ino,
                metadata.st_size,
                metadata.st_mtime_ns,
            ) != (
                metadata_after.st_dev,
                metadata_after.st_ino,
                metadata_after.st_size,
                metadata_after.st_mtime_ns,
            ):
                raise RuntimeError(f"日志在哈希期间发生变化：{rel}")
            logs.append(
                {
                    "path": rel,
                    "size_bytes": metadata.st_size,
                    "mtime_ns": metadata.st_mtime_ns,
                    "device": metadata.st_dev,
                    "inode": metadata.st_ino,
                    "sha256": digest,
                    "exact_file_reference": rel in exact_file_references,
                    "cohort": cohort(path),
                    "kind": (
                        "yosys"
                        if path.name == "yosys.log"
                        else "synthesis-console"
                        if path.name == "synth-console.log"
                        else "other"
                    ),
                    "compressed": path.name.lower().endswith(
                        (".gz", ".xz", ".zst")
                    ),
                }
            )

    logs.sort(key=lambda item: item["path"])
    by_sha: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for item in logs:
        by_sha[item["sha256"]].append(item)
    duplicate_groups = [
        {
            "sha256": digest,
            "path_count": len(items),
            "size_bytes_each": items[0]["size_bytes"],
            "reclaimable_duplicate_bytes": (len(items) - 1)
            * items[0]["size_bytes"],
            "paths": [item["path"] for item in items],
        }
        for digest, items in by_sha.items()
        if len(items) > 1
    ]
    duplicate_groups.sort(
        key=lambda item: (
            -item["reclaimable_duplicate_bytes"],
            item["sha256"],
        )
    )

    by_kind: dict[str, dict[str, int]] = defaultdict(
        lambda: {"count": 0, "size_bytes": 0, "exact_reference_count": 0}
    )
    by_cohort: dict[str, dict[str, int]] = defaultdict(
        lambda: {"count": 0, "size_bytes": 0, "exact_reference_count": 0}
    )
    for item in logs:
        for target in (by_kind[item["kind"]], by_cohort[item["cohort"]]):
            target["count"] += 1
            target["size_bytes"] += item["size_bytes"]
            target["exact_reference_count"] += int(item["exact_file_reference"])

    yosys_logs = [item for item in logs if item["kind"] == "yosys"]
    latest_yosys = (
        max(yosys_logs, key=lambda item: (item["mtime_ns"], item["path"]))
        if yosys_logs
        else None
    )
    total_bytes = sum(item["size_bytes"] for item in logs)
    exact_reference_bytes = sum(
        item["size_bytes"] for item in logs if item["exact_file_reference"]
    )
    duplicate_bytes = sum(
        item["reclaimable_duplicate_bytes"] for item in duplicate_groups
    )
    summary = {
        "schema_version": 1,
        "created_at": utc_now(),
        "log_count": len(logs),
        "total_bytes": total_bytes,
        "exact_file_reference_count": sum(
            int(item["exact_file_reference"]) for item in logs
        ),
        "exact_file_reference_bytes": exact_reference_bytes,
        "unique_content_count": len(by_sha),
        "duplicate_group_count": len(duplicate_groups),
        "reclaimable_duplicate_bytes": duplicate_bytes,
        "latest_yosys": latest_yosys,
        "by_kind": dict(sorted(by_kind.items())),
        "by_cohort": dict(
            sorted(
                by_cohort.items(),
                key=lambda item: (-item[1]["size_bytes"], item[0]),
            )
        ),
        "protected_roots": protected_state,
        "reference_snapshot": reference_snapshot,
    }
    active_after = PHASE1.active_eda_processes()
    if active_after:
        raise RuntimeError(
            "日志盘点期间出现新的仿真/综合/构建进程："
            + json.dumps(active_after, ensure_ascii=False)
        )
    EVIDENCE_ROOT.mkdir(parents=True, exist_ok=True)
    atomic_json(EVIDENCE_ROOT / "tmp-log-inventory.json", logs)
    atomic_json(EVIDENCE_ROOT / "tmp-log-duplicate-groups.json", duplicate_groups)
    atomic_json(EVIDENCE_ROOT / "tmp-log-summary.json", summary)
    lines = [
        "size_bytes\texact_reference\tkind\tsha256\tpath",
        *[
            "\t".join(
                [
                    str(item["size_bytes"]),
                    "yes" if item["exact_file_reference"] else "no",
                    item["kind"],
                    item["sha256"],
                    item["path"],
                ]
            )
            for item in sorted(
                logs, key=lambda value: (-value["size_bytes"], value["path"])
            )
        ],
    ]
    (EVIDENCE_ROOT / "tmp-log-inventory.tsv").write_text(
        "\n".join(lines) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
