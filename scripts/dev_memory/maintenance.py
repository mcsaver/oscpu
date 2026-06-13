# This module was split out of scripts/github_index_db.py.
from __future__ import annotations

import argparse
import json
import os
import shutil
import sqlite3
import sys
import tempfile
from pathlib import Path
from typing import Iterable, Sequence

from .core import *
from .queries import *


def classify_drift(repo_root: Path, row: sqlite3.Row, max_bytes: int) -> str:
    path = repo_root / row["path"]
    if not path.exists():
        return "missing"
    stat = path.stat()
    if stat.st_size != row["size_bytes"] or stat.st_mtime_ns != row["mtime_ns"]:
        return "stale"
    if row["index_status"] == "indexed" and stat.st_size <= max_bytes:
        try:
            current_hash = sha256_bytes(path.read_bytes())
        except OSError:
            return "read_error"
        if current_hash != row["sha256"]:
            return "stale"
    return row["index_status"]


def doctor(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    init_schema(conn)
    rows = conn.execute("SELECT * FROM files ORDER BY path").fetchall()
    counts: dict[str, int] = {}
    samples: dict[str, list[str]] = {}
    now = utc_now()
    with conn:
        for row in rows:
            state = classify_drift(repo_root, row, args.max_bytes)
            counts[state] = counts.get(state, 0) + 1
            samples.setdefault(state, [])
            if len(samples[state]) < args.sample_limit:
                samples[state].append(row["path"])
            if args.write_status and state in {"missing", "stale", "read_error"}:
                conn.execute(
                    "UPDATE files SET exists_flag=?, index_status=?, updated_at=? WHERE path=?",
                    (0 if state == "missing" else 1, state, now, row["path"]),
                )
        if args.write_status:
            record_event(conn, "doctor-write-status", {"counts": counts})
    print("doctor=github-index")
    for status in sorted(counts):
        print(f"{status}={counts[status]}")
        for sample in samples.get(status, []):
            print(f"  {sample}")
    conn.close()
    if args.fail_on_drift and any(counts.get(key, 0) for key in ("missing", "stale", "read_error")):
        return 1
    return 0


def child_rows(conn: sqlite3.Connection, prefix: str) -> tuple[dict[str, int], list[sqlite3.Row]]:
    prefix = prefix.rstrip("/")
    like = prefix + "/%"
    rows = conn.execute(
        """
        SELECT path, kind, index_status, title, size_bytes, line_count
        FROM files
        WHERE path = ? OR path LIKE ?
        ORDER BY path
        """,
        (prefix, like),
    ).fetchall()
    dirs: dict[str, int] = {}
    files: list[sqlite3.Row] = []
    base_len = len(prefix.rstrip("/")) + 1
    for row in rows:
        path = row["path"]
        if path == prefix:
            files.append(row)
            continue
        rest = path[base_len:]
        head = rest.split("/", 1)[0]
        if "/" in rest:
            dirs[head] = dirs.get(head, 0) + 1
        else:
            files.append(row)
    return dirs, files


def list_dir(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    init_schema(conn)
    prefix = normalize_index_path(args.path, args.root)
    dirs, files = child_rows(conn, prefix)
    print(f"ls={prefix} dirs={len(dirs)} files={len(files)}")
    shown = 0
    for name, count in sorted(dirs.items()):
        if shown >= args.limit:
            break
        print(f"DIR  {name}/ ({count})")
        shown += 1
    for row in files:
        if shown >= args.limit:
            break
        print(
            f"FILE {Path(row['path']).name} [{row['kind']} {row['index_status']}] "
            f"size={row['size_bytes']} lines={row['line_count']} title={row['title']}"
        )
        shown += 1
    conn.close()
    return 0


def build_tree(rows: Iterable[sqlite3.Row], prefix: str) -> dict[str, object]:
    tree: dict[str, object] = {}
    base = prefix.rstrip("/")
    for row in rows:
        path = row["path"]
        if path == base:
            parts = [Path(path).name]
        else:
            rest = path[len(base) + 1 :] if path.startswith(base + "/") else path
            parts = rest.split("/")
        cursor = tree
        for part in parts[:-1]:
            cursor = cursor.setdefault(part + "/", {})  # type: ignore[assignment]
        cursor[parts[-1]] = row
    return tree


def print_tree_node(node: dict[str, object], depth: int, max_depth: int, limit: int, state: dict[str, int]) -> None:
    if state["shown"] >= limit:
        return
    for name in sorted(node):
        if state["shown"] >= limit:
            return
        value = node[name]
        indent = "  " * depth
        if isinstance(value, dict):
            print(f"{indent}{name}")
            state["shown"] += 1
            if depth + 1 < max_depth:
                print_tree_node(value, depth + 1, max_depth, limit, state)
        else:
            row = value
            print(f"{indent}{name} [{row['kind']} {row['index_status']}]")
            state["shown"] += 1


def tree(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    init_schema(conn)
    prefix = normalize_index_path(args.path, args.root)
    rows = conn.execute(
        """
        SELECT path, kind, index_status, title
        FROM files
        WHERE path = ? OR path LIKE ?
        ORDER BY path
        """,
        (prefix, prefix.rstrip("/") + "/%"),
    ).fetchall()
    print(f"tree={prefix} rows={len(rows)} depth={args.depth}")
    print_tree_node(build_tree(rows, prefix), 0, args.depth, args.limit, {"shown": 0})
    conn.close()
    return 0


def delete_index_row(conn: sqlite3.Connection, path: str, has_fts5: bool) -> None:
    conn.execute("DELETE FROM file_text WHERE path = ?", (path,))
    if has_fts5:
        conn.execute("DELETE FROM file_fts WHERE path = ?", (path,))
    delete_chunks_for_path(conn, path, has_fts5)
    conn.execute("DELETE FROM files WHERE path = ?", (path,))


def refresh_one(conn: sqlite3.Connection, repo_root: Path, db_path: Path, path: str, max_bytes: int) -> str:
    has_fts5 = init_schema(conn)
    now = utc_now()
    rel_path = normalize_index_path(path)
    target = (repo_root / rel_path).resolve()
    ensure_inside_root(repo_root, target)
    with conn:
        if target.exists():
            item = index_one_file(
                repo_root,
                target,
                max_bytes,
                repo_path(db_path.relative_to(repo_root)) if db_path.is_relative_to(repo_root) else "",
                [],
            )
            if item is None:
                return "skipped"
            upsert_file(conn, item, has_fts5, now)
            record_event(conn, "refresh", {"path": rel_path, "status": item.index_status})
            return item.index_status
        conn.execute(
            """
            UPDATE files
            SET exists_flag=0, index_status='missing', updated_at=?
            WHERE path=?
            """,
            (now, rel_path),
        )
        record_event(conn, "refresh-missing", {"path": rel_path})
        return "missing"


def refresh(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    rc = 0
    try:
        for path in args.paths:
            try:
                status = refresh_one(conn, repo_root, db_path, path, args.max_bytes)
            except ValueError as exc:
                print(f"FAIL refresh {path}: {exc}", file=sys.stderr)
                rc = 2
                continue
            print(f"PASS refresh {normalize_index_path(path)} status={status}")
    finally:
        conn.close()
    return rc


def read_add_payload(args: argparse.Namespace) -> bytes:
    sources = [args.content is not None, args.from_file is not None]
    if sum(sources) > 1:
        raise ValueError("use only one of --content or --from-file")
    if args.content is not None:
        return args.content.encode("utf-8")
    if args.from_file is not None:
        return Path(args.from_file).read_bytes()
    if sys.stdin.isatty():
        raise ValueError("provide --content, --from-file, or stdin")
    return sys.stdin.buffer.read()


def add_entry(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    github_root = (repo_root / args.root).resolve()
    rel_path = normalize_index_path(args.path, args.root)
    target = (repo_root / rel_path).resolve()
    try:
        ensure_inside_root(github_root, target)
        payload = read_add_payload(args)
    except (OSError, ValueError) as exc:
        print(f"FAIL add {rel_path}: {exc}", file=sys.stderr)
        return 2
    if target.exists() and not args.replace:
        print(f"FAIL add {rel_path}: file exists; use --replace", file=sys.stderr)
        return 1
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(payload)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    try:
        status = refresh_one(conn, repo_root, db_path, rel_path, args.max_bytes)
    finally:
        conn.close()
    print(f"PASS add {rel_path} bytes={len(payload)} status={status}")
    return 0


def remove_entry(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    github_root = (repo_root / args.root).resolve()
    db_path = (repo_root / args.db).resolve()
    rel_path = normalize_index_path(args.path, args.root)
    target = (repo_root / rel_path).resolve()
    try:
        ensure_inside_root(github_root, target)
    except ValueError as exc:
        print(f"FAIL remove {rel_path}: {exc}", file=sys.stderr)
        return 2
    if args.delete_file:
        if not args.yes:
            print(f"FAIL remove {rel_path}: --delete-file requires --yes", file=sys.stderr)
            return 2
        if target.is_dir():
            print(f"FAIL remove {rel_path}: refusing to delete directory", file=sys.stderr)
            return 2
        if target.exists():
            target.unlink()
    conn = open_db(db_path)
    has_fts5 = init_schema(conn)
    with conn:
        delete_index_row(conn, rel_path, has_fts5)
        record_event(
            conn,
            "remove",
            {"path": rel_path, "delete_file": bool(args.delete_file), "existed": target.exists()},
        )
    conn.close()
    mode = "file+index" if args.delete_file else "index-only"
    print(f"PASS remove {rel_path} mode={mode}")
    if not args.delete_file:
        print("NOTE source file was left untouched; next rebuild will index it again")
    return 0


def document_kinds(args: argparse.Namespace) -> list[str]:
    if args.kind:
        return sorted(set(args.kind))
    return sorted(DB_FIRST_KINDS)


def select_live_document_rows(
    conn: sqlite3.Connection,
    paths: Sequence[str],
    kinds: Sequence[str],
) -> list[sqlite3.Row]:
    if paths:
        normalized = [normalize_index_path(path) for path in paths]
        placeholders = ",".join("?" for _ in normalized)
        return conn.execute(
            f"""
            SELECT f.*, t.content
            FROM files f
            JOIN file_text t ON t.path = f.path
            WHERE f.path IN ({placeholders})
              AND f.index_status='indexed'
            ORDER BY f.path
            """,
            normalized,
        ).fetchall()
    placeholders = ",".join("?" for _ in kinds)
    return conn.execute(
        f"""
        SELECT f.*, t.content
        FROM files f
        JOIN file_text t ON t.path = f.path
        WHERE f.kind IN ({placeholders})
          AND f.index_status='indexed'
          AND (
            f.kind NOT IN ('task-report', 'dispatch-log', 'task-run', 'task-evidence')
            OR f.path LIKE '%.md'
          )
        ORDER BY f.path
        """,
        list(kinds),
    ).fetchall()


def select_stored_document_rows(
    conn: sqlite3.Connection,
    paths: Sequence[str],
    kinds: Sequence[str],
) -> list[sqlite3.Row]:
    if paths:
        normalized = [normalize_index_path(path) for path in paths]
        placeholders = ",".join("?" for _ in normalized)
        return conn.execute(
            f"""
            SELECT path, kind, content
            FROM db_documents
            WHERE path IN ({placeholders})
            ORDER BY path
            """,
            normalized,
        ).fetchall()
    placeholders = ",".join("?" for _ in kinds)
    return conn.execute(
        f"""
        SELECT path, kind, content
        FROM db_documents
        WHERE kind IN ({placeholders})
        ORDER BY path
        """,
        list(kinds),
    ).fetchall()


def row_to_indexed_file(row: sqlite3.Row) -> IndexedFile:
    return IndexedFile(
        path=row["path"],
        kind=row["kind"],
        size_bytes=row["size_bytes"],
        mtime_ns=row["mtime_ns"],
        sha256=row["sha256"],
        line_count=row["line_count"],
        title=row["title"],
        description=row["description"],
        declared_status=row["declared_status"],
        tags=row["tags"],
        exists_flag=row["exists_flag"],
        index_status=row["index_status"],
        content=row["content"] or "",
    )


def indexed_file_from_content(rel_path: str, content: str) -> IndexedFile:
    raw = content.encode("utf-8")
    return IndexedFile(
        path=rel_path,
        kind=infer_kind(rel_path),
        size_bytes=len(raw),
        mtime_ns=0,
        sha256=sha256_bytes(raw),
        line_count=content.count("\n") + (1 if content and not content.endswith("\n") else 0),
        title=extract_title(content, rel_path),
        description=extract_description(content),
        declared_status=extract_declared_status(content),
        tags=extract_tags(rel_path, infer_kind(rel_path), content),
        exists_flag=1,
        index_status="indexed",
        content=content,
    )


def promote_documents(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    has_fts5 = init_schema(conn)
    rows = select_live_document_rows(conn, args.path, document_kinds(args))
    rows = [row for row in rows if not is_db_backed_shim(row["path"], row["content"] or "")]
    if not rows:
        print("FAIL promote found no indexed documents", file=sys.stderr)
        conn.close()
        return 1
    now = utc_now()
    with conn:
        for row in rows:
            upsert_stored_document(conn, row_to_indexed_file(row), has_fts5, now)
        record_event(
            conn,
            "promote-documents",
            {"count": len(rows), "paths": [row["path"] for row in rows[:20]]},
        )
    conn.close()
    print(f"PASS promote stored_documents={len(rows)}")
    for row in rows[: args.limit]:
        print(f"  {row['path']} [{row['kind']}]")
    if len(rows) > args.limit:
        print(f"  ... {len(rows) - args.limit} more")
    return 0


def read_update_stored_payload(args: argparse.Namespace, repo_root: Path) -> str:
    sources = [args.content is not None, args.from_file is not None, bool(args.stdin)]
    if sum(sources) != 1:
        raise ValueError("use exactly one of --content, --from-file, or --stdin")
    if args.content is not None:
        return args.content
    if args.stdin:
        return sys.stdin.read()
    source = Path(args.from_file)
    if not source.is_absolute():
        source = repo_root / source
    source = source.resolve()
    ensure_inside_root(repo_root, source)
    return source.read_text(encoding="utf-8")


def update_stored_document(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    rel_path = normalize_index_path(args.path)
    try:
        content = read_update_stored_payload(args, repo_root)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        print(f"FAIL update-stored {rel_path}: {exc}", file=sys.stderr)
        return 2
    if is_db_backed_shim(rel_path, content) or (
        content.lstrip().startswith("# DB-backed ") and "load --source stored" in content
    ):
        print(
            f"FAIL update-stored {rel_path}: refusing to store DB-backed shim payload",
            file=sys.stderr,
        )
        return 2

    item = indexed_file_from_content(rel_path, content)
    conn = open_db(db_path)
    has_fts5 = init_schema(conn)
    now = utc_now()
    with conn:
        upsert_stored_document(conn, item, has_fts5, now)
        record_event(
            conn,
            "update-stored-document",
            {"path": rel_path, "size_bytes": item.size_bytes, "sha256": item.sha256},
        )
    if args.refresh_shim:
        target = (repo_root / rel_path).resolve()
        try:
            ensure_inside_root(repo_root, target)
        except ValueError as exc:
            conn.close()
            print(f"FAIL update-stored {rel_path}: {exc}", file=sys.stderr)
            return 2
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(db_backed_shim(rel_path, args.backup_dir), encoding="utf-8")
        refresh_one(conn, repo_root, db_path, rel_path, args.max_bytes)
    conn.close()
    print(f"PASS update-stored {rel_path} bytes={item.size_bytes} chunks={len(build_file_chunks(rel_path, item.title, content))}")
    return 0


def resolve_backup_dir(repo_root: Path, backup_dir: str) -> Path:
    target = (repo_root / backup_dir).resolve()
    ensure_inside_root(repo_root, target)
    return target


def write_backup_files(
    repo_root: Path,
    backup_dir: Path,
    rows: Sequence[sqlite3.Row | dict[str, object]],
) -> dict[str, object]:
    files_dir = backup_dir / "files"
    manifest_path = backup_dir / "manifest.json"
    now = utc_now()
    created_at = now
    entries_by_path: dict[str, dict[str, object]] = {}
    if manifest_path.is_file():
        try:
            previous = json.loads(manifest_path.read_text(encoding="utf-8"))
            created_at = str(previous.get("created_at") or now)
            for entry in previous.get("entries", []):
                if isinstance(entry, dict) and "path" in entry:
                    entries_by_path[str(entry["path"])] = entry
        except (OSError, json.JSONDecodeError):
            created_at = now
    files_dir.mkdir(parents=True, exist_ok=True)
    for row in rows:
        rel_path = row["path"]
        src = (repo_root / rel_path).resolve()
        ensure_inside_root(repo_root, src)
        dst = files_dir / rel_path
        dst.parent.mkdir(parents=True, exist_ok=True)
        row_content = row["content"] or ""
        if src.exists():
            raw = src.read_bytes()
            try:
                live_content = raw.decode("utf-8")
            except UnicodeDecodeError:
                live_content = ""
            if row_content and is_db_backed_shim(rel_path, live_content):
                raw = row_content.encode("utf-8")
                dst.write_bytes(raw)
                backup_source = "database"
            else:
                shutil.copy2(src, dst)
                backup_source = "filesystem"
        else:
            raw = row_content.encode("utf-8")
            dst.write_bytes(raw)
            backup_source = "database"
        entries_by_path[rel_path] = {
            "path": rel_path,
            "kind": row["kind"],
            "size_bytes": len(raw),
            "sha256": sha256_bytes(raw),
            "backup_source": backup_source,
            "archived_at": now,
        }
    manifest = {
        "created_at": created_at,
        "updated_at": now,
        "schema_version": SCHEMA_VERSION,
        "entries": [entries_by_path[path] for path in sorted(entries_by_path)],
    }
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return manifest


def backup_documents(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    backup_dir = resolve_backup_dir(repo_root, args.backup_dir)
    conn = open_db(db_path)
    init_schema(conn)
    rows = select_live_document_rows(conn, args.path, document_kinds(args))
    if not rows:
        print("FAIL backup found no indexed documents", file=sys.stderr)
        conn.close()
        return 1
    manifest = write_backup_files(repo_root, backup_dir, rows)
    with conn:
        record_event(
            conn,
            "backup-documents",
            {"backup_dir": repo_path(backup_dir.relative_to(repo_root)), "count": len(rows)},
        )
    conn.close()
    print(
        f"PASS backup documents={len(rows)} backup_dir={repo_path(backup_dir.relative_to(repo_root))} "
        f"manifest_entries={len(manifest['entries'])}"
    )
    return 0


def snapshot_stored_documents(args: argparse.Namespace) -> int:
    if not args.yes:
        print("FAIL snapshot-stored requires --yes", file=sys.stderr)
        return 2
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    backup_dir = resolve_backup_dir(repo_root, args.backup_dir)
    conn = open_db(db_path)
    init_schema(conn)
    rows = select_stored_document_rows(conn, args.path, document_kinds(args))
    if not rows:
        print("FAIL snapshot-stored found no stored documents", file=sys.stderr)
        conn.close()
        return 1
    manifest = write_backup_files(repo_root, backup_dir, rows)
    with conn:
        record_event(
            conn,
            "snapshot-stored-documents",
            {"backup_dir": repo_path(backup_dir.relative_to(repo_root)), "count": len(rows)},
        )
    conn.close()
    print(
        f"PASS snapshot-stored documents={len(rows)} backup_dir={repo_path(backup_dir.relative_to(repo_root))} "
        f"manifest_entries={len(manifest['entries'])}"
    )
    return 0


def db_backed_shim(path: str, backup_dir: str) -> str:
    return f"""# DB-backed {path}

> 本文件是兼容 shim：完整原文已提升到 `.github/cache/github-index.sqlite` 的 stored document。
> 原文备份由 `{backup_dir}/manifest.json` 管理；恢复请使用下方命令。

- 按需加载：`python3 scripts/github_index_db.py load --source stored --path {path}`
- 从备份恢复：`python3 scripts/github_index_db.py restore --backup-dir {backup_dir} --path {path} --yes`
- 重新物化：`python3 scripts/github_index_db.py materialize --path {path}`
"""


def is_db_backed_shim(path: str, content: str) -> bool:
    return f"# DB-backed {path}" in content and "load --source stored" in content


def migrate_to_db(args: argparse.Namespace) -> int:
    if not args.yes:
        print("FAIL migrate requires --yes", file=sys.stderr)
        return 2
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    backup_dir = resolve_backup_dir(repo_root, args.backup_dir)
    conn = open_db(db_path)
    has_fts5 = init_schema(conn)
    rows = select_live_document_rows(conn, args.path, document_kinds(args))
    rows = [row for row in rows if not is_db_backed_shim(row["path"], row["content"] or "")]
    if not rows:
        print("FAIL migrate found no indexed documents", file=sys.stderr)
        conn.close()
        return 1
    now = utc_now()
    with conn:
        for row in rows:
            upsert_stored_document(conn, row_to_indexed_file(row), has_fts5, now)
        record_event(
            conn,
            "migrate-promote-documents",
            {"count": len(rows), "backup_dir": repo_path(backup_dir.relative_to(repo_root))},
        )
    manifest = write_backup_files(repo_root, backup_dir, rows)
    shim_paths: list[str] = []
    for row in rows:
        rel_path = row["path"]
        target = (repo_root / rel_path).resolve()
        ensure_inside_root(repo_root, target)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(db_backed_shim(rel_path, repo_path(backup_dir.relative_to(repo_root))), encoding="utf-8")
        shim_paths.append(rel_path)
        refresh_one(conn, repo_root, db_path, rel_path, args.max_bytes)
    with conn:
        record_event(
            conn,
            "migrate-documents-to-db",
            {"count": len(rows), "backup_dir": repo_path(backup_dir.relative_to(repo_root))},
        )
    conn.close()
    print(
        f"PASS migrate stored_documents={len(rows)} shims={len(shim_paths)} "
        f"backup_dir={repo_path(backup_dir.relative_to(repo_root))} manifest_entries={len(manifest['entries'])}"
    )
    for rel_path in shim_paths[: args.limit]:
        print(f"  {rel_path}")
    if len(shim_paths) > args.limit:
        print(f"  ... {len(shim_paths) - args.limit} more")
    return 0


def archive_markdown_candidates(repo_root: Path, requested_paths: Sequence[str]) -> list[Path]:
    candidates: list[Path] = []
    seen: set[str] = set()
    for raw_path in requested_paths:
        source = Path(raw_path)
        if not source.is_absolute():
            source = repo_root / source
        source = source.resolve()
        ensure_inside_root(repo_root, source)
        if source.is_dir():
            paths = sorted(path for path in source.rglob("*.md") if path.is_file())
        elif source.is_file() and source.suffix.lower() == ".md":
            paths = [source]
        else:
            continue
        for path in paths:
            rel_path = repo_path(path.relative_to(repo_root))
            if (
                rel_path.startswith(".github/cache/")
                or rel_path.startswith(".github/db-backup/")
                or rel_path.startswith(".github/tmp/")
            ):
                continue
            if rel_path in seen:
                continue
            seen.add(rel_path)
            candidates.append(path)
    return candidates


def archive_markdown_files(args: argparse.Namespace) -> int:
    if not args.yes:
        print("FAIL archive-markdown requires --yes", file=sys.stderr)
        return 2
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    backup_dir = resolve_backup_dir(repo_root, args.backup_dir)
    paths = archive_markdown_candidates(repo_root, args.path)
    if not paths:
        print("FAIL archive-markdown found no Markdown files", file=sys.stderr)
        return 1

    rows: list[dict[str, object]] = []
    skipped_shims: list[str] = []
    for path in paths:
        rel_path = repo_path(path.relative_to(repo_root))
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            print(f"FAIL archive-markdown non-utf8 Markdown: {rel_path}", file=sys.stderr)
            return 2
        if is_db_backed_shim(rel_path, content):
            skipped_shims.append(rel_path)
            continue
        item = indexed_file_from_content(rel_path, content)
        rows.append({"path": item.path, "kind": item.kind, "content": item.content, "item": item})
    if not rows:
        print(f"PASS archive-markdown stored_documents=0 shims=0 skipped_shims={len(skipped_shims)}")
        return 0

    manifest = write_backup_files(repo_root, backup_dir, rows)
    conn = open_db(db_path)
    has_fts5 = init_schema(conn)
    now = utc_now()
    with conn:
        for row in rows:
            upsert_stored_document(conn, row["item"], has_fts5, now)
        record_event(
            conn,
            "archive-markdown-files",
            {
                "count": len(rows),
                "backup_dir": repo_path(backup_dir.relative_to(repo_root)),
                "paths": [str(row["path"]) for row in rows[:20]],
            },
        )

    shim_paths: list[str] = []
    for row in rows:
        rel_path = str(row["path"])
        target = (repo_root / rel_path).resolve()
        ensure_inside_root(repo_root, target)
        target.write_text(db_backed_shim(rel_path, repo_path(backup_dir.relative_to(repo_root))), encoding="utf-8")
        shim_paths.append(rel_path)
        refresh_one(conn, repo_root, db_path, rel_path, args.max_bytes)
    conn.close()
    print(
        f"PASS archive-markdown stored_documents={len(rows)} shims={len(shim_paths)} "
        f"skipped_shims={len(skipped_shims)} backup_dir={repo_path(backup_dir.relative_to(repo_root))} "
        f"manifest_entries={len(manifest['entries'])}"
    )
    for rel_path in shim_paths[: args.limit]:
        print(f"  {rel_path}")
    if len(shim_paths) > args.limit:
        print(f"  ... {len(shim_paths) - args.limit} more")
    return 0


EVIDENCE_TEXT_SUFFIXES = {
    ".cmd",
    ".csv",
    ".err",
    ".json",
    ".jsonl",
    ".log",
    ".out",
    ".text",
    ".tsv",
    ".txt",
}


def task_run_id_from_rel_path(rel_path: str) -> str:
    parts = Path(rel_path).parts
    if len(parts) >= 3 and parts[0] == ".github" and parts[1] == "task-runs":
        return parts[2]
    return ""


def parse_markdown_fields(content: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in content.splitlines():
        match = re.match(r"^-\s+`([^`]+)`:\s*(.*)$", line.strip())
        if match:
            fields[match.group(1)] = match.group(2).strip()
    return fields


def task_run_report_fields(repo_root: Path, conn: sqlite3.Connection, run_id: str) -> dict[str, str]:
    rel_path = f".github/task-runs/{run_id}/task-report.md"
    target = repo_root / rel_path
    content = ""
    if target.exists():
        try:
            content = target.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            content = ""
        if content and is_db_backed_shim(rel_path, content):
            content = ""
    if not content:
        row = conn.execute("SELECT content FROM db_documents WHERE path = ?", (rel_path,)).fetchone()
        if row is not None:
            content = row["content"] or ""
    return parse_markdown_fields(content)


def evidence_asset_kind(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix:
        return suffix.lstrip(".")
    return "file"


def read_evidence_sample(path: Path, sample_bytes: int) -> dict[str, object]:
    digest = hashlib.sha256()
    head = bytearray()
    tail = bytearray()
    line_count = 0
    total = 0
    last_byte = b""
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(65536)
            if not chunk:
                break
            digest.update(chunk)
            total += len(chunk)
            line_count += chunk.count(b"\n")
            last_byte = chunk[-1:]
            if len(head) < sample_bytes:
                head.extend(chunk[: sample_bytes - len(head)])
            tail.extend(chunk)
            if len(tail) > sample_bytes:
                del tail[: len(tail) - sample_bytes]
    if total and last_byte != b"\n":
        line_count += 1
    encoding = "utf-8"
    try:
        head_text = bytes(head).decode("utf-8")
        tail_text = bytes(tail).decode("utf-8")
    except UnicodeDecodeError:
        encoding = "binary-or-non-utf8"
        head_text = bytes(head).decode("utf-8", errors="replace")
        tail_text = bytes(tail).decode("utf-8", errors="replace")
    return {
        "sha256": digest.hexdigest(),
        "line_count": line_count,
        "encoding": encoding,
        "head_text": head_text,
        "tail_text": tail_text,
    }


def evidence_markers(text: str) -> dict[str, int | list[str]]:
    markers: dict[str, int | list[str]] = {}
    for name, pattern in {
        "PASS": r"\bPASS\b",
        "FAIL": r"\bFAIL\b",
        "SKIP": r"\bSKIP\b",
        "WARN": r"\bWARN(?:ING)?\b",
        "ERROR": r"\bERROR\b",
        "GOOD_TRAP": r"HIT GOOD TRAP",
        "BAD_TRAP": r"HIT BAD TRAP",
        "PANIC": r"\bpanic\b|\bPANIC\b|Kernel panic",
        "OOPS": r"\bOops\b|\bOOPS\b",
    }.items():
        count = len(re.findall(pattern, text))
        if count:
            markers[name] = count
    symbolic = sorted(set(re.findall(r"__[A-Z0-9_]+__", text)))
    if symbolic:
        markers["symbolic"] = symbolic[:20]
    return markers


def evidence_summary(kind: str, size_bytes: int, line_count: int, markers: dict[str, object], tail: str) -> str:
    marker_bits = []
    for key in ("FAIL", "ERROR", "WARN", "SKIP", "PASS", "GOOD_TRAP", "BAD_TRAP", "PANIC", "OOPS"):
        if key in markers:
            marker_bits.append(f"{key}={markers[key]}")
    if "symbolic" in markers:
        values = markers["symbolic"]
        if isinstance(values, list):
            marker_bits.append("symbolic=" + ",".join(str(value) for value in values[:5]))
    marker_text = "; ".join(marker_bits) if marker_bits else "markers=<none>"
    tail_text = compact_text(tail, 260)
    return compact_text(
        f"{kind} evidence; size={size_bytes} bytes; lines={line_count}; {marker_text}; tail={tail_text}",
        700,
    )


def evidence_asset_candidates(repo_root: Path, requested_paths: Sequence[str]) -> list[Path]:
    candidates: list[Path] = []
    seen: set[str] = set()
    for raw_path in requested_paths:
        source = Path(raw_path)
        if not source.is_absolute():
            source = repo_root / source
        source = source.resolve()
        ensure_inside_root(repo_root, source)
        if source.is_dir():
            paths = sorted(path for path in source.rglob("*") if path.is_file())
        elif source.is_file():
            paths = [source]
        else:
            continue
        for path in paths:
            rel_path = repo_path(path.relative_to(repo_root))
            if (
                rel_path.startswith(".github/cache/")
                or rel_path.startswith(".github/db-backup/")
                or rel_path.startswith(".github/tmp/")
                or rel_path.endswith(".md")
            ):
                continue
            if ".git/" in rel_path or rel_path in seen:
                continue
            run_id = task_run_id_from_rel_path(rel_path)
            if not run_id:
                continue
            seen.add(rel_path)
            candidates.append(path)
    return candidates


def build_evidence_asset(
    repo_root: Path,
    conn: sqlite3.Connection,
    path: Path,
    indexed_at: str,
    sample_bytes: int,
    excerpt_chars: int,
) -> dict[str, object]:
    rel_path = repo_path(path.relative_to(repo_root))
    run_id = task_run_id_from_rel_path(rel_path)
    fields = task_run_report_fields(repo_root, conn, run_id)
    stat = path.stat()
    sample = read_evidence_sample(path, sample_bytes)
    head = compact_text(str(sample["head_text"]), excerpt_chars)
    tail = compact_text(str(sample["tail_text"]), excerpt_chars)
    marker_source = f"{sample['head_text']}\n{sample['tail_text']}"
    markers = evidence_markers(marker_source)
    kind = evidence_asset_kind(path)
    summary = evidence_summary(kind, stat.st_size, int(sample["line_count"]), markers, tail)
    return {
        "path": rel_path,
        "run_id": run_id,
        "task_slug": fields.get("task_slug", ""),
        "profile": fields.get("profile", ""),
        "kind": kind,
        "size_bytes": stat.st_size,
        "mtime_ns": stat.st_mtime_ns,
        "sha256": sample["sha256"],
        "line_count": int(sample["line_count"]),
        "encoding": sample["encoding"],
        "summary": summary,
        "head_excerpt": head,
        "tail_excerpt": tail,
        "markers": json.dumps(markers, ensure_ascii=False, sort_keys=True),
        "indexed_at": indexed_at,
    }


def write_evidence_index_markdown(repo_root: Path, run_id: str, assets: Sequence[dict[str, object]]) -> str:
    target = repo_root / ".github" / "task-runs" / run_id / "evidence-index.md"
    fields: dict[str, str] = {}
    if assets:
        fields = {
            "task_slug": str(assets[0].get("task_slug", "")),
            "profile": str(assets[0].get("profile", "")),
        }
    total_bytes = sum(int(asset.get("size_bytes", 0)) for asset in assets)
    lines = [
        "# Evidence Index",
        "",
        "## 基本信息",
        "",
        f"- `task_id`: {run_id}",
        f"- `task_slug`: {fields.get('task_slug', '')}",
        f"- `profile`: {fields.get('profile', '')}",
        f"- `asset_count`: {len(assets)}",
        f"- `total_size_bytes`: {total_bytes}",
        "",
        "## 证据资产",
        "",
    ]
    for asset in sorted(assets, key=lambda item: str(item["path"])):
        markers = json.loads(str(asset.get("markers") or "{}"))
        marker_text = json.dumps(markers, ensure_ascii=False, sort_keys=True)
        lines.extend(
            [
                f"### {asset['path']}",
                "",
                f"- `kind`: {asset.get('kind', '')}",
                f"- `size_bytes`: {asset.get('size_bytes', 0)}",
                f"- `line_count`: {asset.get('line_count', 0)}",
                f"- `sha256`: {asset.get('sha256', '')}",
                f"- `encoding`: {asset.get('encoding', '')}",
                f"- `indexed_at`: {asset.get('indexed_at', '')}",
                f"- `markers`: {marker_text}",
                f"- `summary`: {asset.get('summary', '')}",
                "",
            ]
        )
    target.write_text("\n".join(lines), encoding="utf-8")
    return repo_path(target.relative_to(repo_root))


def index_evidence_assets(args: argparse.Namespace) -> int:
    if not args.yes:
        print("FAIL index-evidence requires --yes", file=sys.stderr)
        return 2
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    paths = evidence_asset_candidates(repo_root, args.path)
    if not paths:
        print("FAIL index-evidence found no task-run evidence assets", file=sys.stderr)
        return 1
    conn = open_db(db_path)
    init_schema(conn)
    indexed_at = utc_now()
    assets = [
        build_evidence_asset(repo_root, conn, path, indexed_at, args.sample_bytes, args.excerpt_chars)
        for path in paths
    ]
    run_ids = sorted({str(asset["run_id"]) for asset in assets if asset.get("run_id")})
    current_paths = {str(asset["path"]) for asset in assets}
    with conn:
        for run_id in run_ids:
            placeholders = ",".join("?" for _ in current_paths) if current_paths else "''"
            params: list[object] = [run_id]
            if current_paths:
                params.extend(sorted(current_paths))
                conn.execute(
                    f"DELETE FROM evidence_assets WHERE run_id = ? AND path NOT IN ({placeholders})",
                    params,
                )
            else:
                conn.execute("DELETE FROM evidence_assets WHERE run_id = ?", (run_id,))
        for asset in assets:
            conn.execute(
                """
                INSERT OR REPLACE INTO evidence_assets(
                  path, run_id, task_slug, profile, kind, size_bytes, mtime_ns, sha256,
                  line_count, encoding, summary, head_excerpt, tail_excerpt, markers, indexed_at
                )
                VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    asset["path"],
                    asset["run_id"],
                    asset["task_slug"],
                    asset["profile"],
                    asset["kind"],
                    asset["size_bytes"],
                    asset["mtime_ns"],
                    asset["sha256"],
                    asset["line_count"],
                    asset["encoding"],
                    asset["summary"],
                    asset["head_excerpt"],
                    asset["tail_excerpt"],
                    asset["markers"],
                    asset["indexed_at"],
                ),
            )
        record_event(
            conn,
            "index-evidence-assets",
            {"assets": len(assets), "runs": run_ids, "write_index": bool(args.write_index)},
        )
    index_docs: list[str] = []
    if args.write_index:
        assets_by_run: dict[str, list[dict[str, object]]] = {}
        for asset in assets:
            assets_by_run.setdefault(str(asset["run_id"]), []).append(asset)
        for run_id, run_assets in sorted(assets_by_run.items()):
            index_docs.append(write_evidence_index_markdown(repo_root, run_id, run_assets))
    conn.close()
    if args.json:
        print(
            json.dumps(
                {
                    "op": "index-evidence",
                    "ok": True,
                    "assets": len(assets),
                    "runs": run_ids,
                    "index_docs": index_docs,
                },
                ensure_ascii=False,
                indent=2,
            )
        )
    else:
        print(
            f"PASS index-evidence assets={len(assets)} runs={len(run_ids)} "
            f"index_docs={len(index_docs)}"
        )
        for asset in sorted(assets, key=lambda item: str(item["path"]))[: args.limit]:
            print(f"  {asset['path']} [{asset['kind']}] {asset['summary']}")
        if len(assets) > args.limit:
            print(f"  ... {len(assets) - args.limit} more")
    return 0


def materialize_documents(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    dest_root = (repo_root / args.output_root).resolve()
    ensure_inside_root(repo_root, dest_root)
    conn = open_db(db_path)
    init_schema(conn)
    paths = [normalize_index_path(path) for path in args.path]
    if paths:
        placeholders = ",".join("?" for _ in paths)
        rows = conn.execute(
            f"SELECT * FROM db_documents WHERE path IN ({placeholders}) ORDER BY path",
            paths,
        ).fetchall()
    else:
        rows = conn.execute("SELECT * FROM db_documents ORDER BY path").fetchall()
    if not rows:
        print("FAIL materialize found no stored documents", file=sys.stderr)
        conn.close()
        return 1
    for row in rows:
        target = (dest_root / row["path"]).resolve()
        ensure_inside_root(dest_root, target)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(row["content"], encoding="utf-8")
    conn.close()
    print(f"PASS materialize documents={len(rows)} output_root={repo_path(dest_root.relative_to(repo_root))}")
    return 0


def restore_backup(args: argparse.Namespace) -> int:
    if not args.yes:
        print("FAIL restore requires --yes", file=sys.stderr)
        return 2
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    backup_dir = resolve_backup_dir(repo_root, args.backup_dir)
    manifest_path = backup_dir / "manifest.json"
    if not manifest_path.is_file():
        print(f"FAIL restore missing manifest: {manifest_path}", file=sys.stderr)
        return 1
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    wanted = {normalize_index_path(path) for path in args.path}
    restored: list[str] = []
    conn = open_db(db_path)
    init_schema(conn)
    for entry in manifest.get("entries", []):
        rel_path = entry["path"]
        if wanted and rel_path not in wanted:
            continue
        src = (backup_dir / "files" / rel_path).resolve()
        dst = (repo_root / rel_path).resolve()
        ensure_inside_root(backup_dir, src)
        ensure_inside_root(repo_root, dst)
        if not src.is_file():
            print(f"FAIL restore missing backup file: {src}", file=sys.stderr)
            conn.close()
            return 1
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        refresh_one(conn, repo_root, db_path, rel_path, args.max_bytes)
        restored.append(rel_path)
    conn.close()
    if wanted and wanted.difference(restored):
        print(f"FAIL restore missing requested paths: {sorted(wanted.difference(restored))}", file=sys.stderr)
        return 1
    print(f"PASS restore documents={len(restored)} backup_dir={repo_path(backup_dir.relative_to(repo_root))}")
    return 0


def latest_backup_dir(repo_root: Path, backup_root: str) -> Path | None:
    root = (repo_root / backup_root).resolve()
    if not root.is_dir():
        return None
    candidates = [path.parent for path in root.rglob("manifest.json") if path.is_file()]
    if not candidates:
        return None
    return sorted(candidates, key=lambda path: (path.stat().st_mtime_ns, str(path)))[-1]


def resolve_audit_backup_dir(repo_root: Path, backup_dir: str) -> Path | None:
    if backup_dir:
        return resolve_backup_dir(repo_root, backup_dir)
    return latest_backup_dir(repo_root, DEFAULT_DB_BACKUP_ROOT)


def resolve_audit_backup_dirs(repo_root: Path, backup_dir: str) -> list[Path]:
    if backup_dir:
        return [resolve_backup_dir(repo_root, backup_dir)]
    root = (repo_root / DEFAULT_DB_BACKUP_ROOT).resolve()
    if not root.is_dir():
        return []
    return sorted({path.parent for path in root.rglob("manifest.json") if path.is_file()})


def load_backup_manifest(backup_dir: Path | None) -> tuple[dict[str, object] | None, dict[str, dict[str, object]]]:
    if backup_dir is None:
        return None, {}
    manifest_path = backup_dir / "manifest.json"
    if not manifest_path.is_file():
        return None, {}
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = {
        entry["path"]: entry
        for entry in manifest.get("entries", [])
        if isinstance(entry, dict) and "path" in entry
    }
    return manifest, entries


def load_backup_manifests(backup_dirs: Sequence[Path]) -> tuple[list[dict[str, object]], dict[str, dict[str, object]]]:
    manifests: list[dict[str, object]] = []
    entries: dict[str, dict[str, object]] = {}
    ordered_dirs = sorted(backup_dirs, key=lambda path: (path.stat().st_mtime_ns, str(path)) if path.exists() else (0, str(path)))
    for backup_dir in ordered_dirs:
        manifest, manifest_entries = load_backup_manifest(backup_dir)
        if manifest is None:
            continue
        manifests.append(manifest)
        for path, entry in manifest_entries.items():
            merged = dict(entry)
            merged["_backup_dir"] = backup_dir
            entries[path] = merged
    return manifests, entries


def rehydrate_stored_documents(args: argparse.Namespace) -> int:
    if not args.yes:
        print("FAIL rehydrate requires --yes", file=sys.stderr)
        return 2
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    backup_dirs = resolve_audit_backup_dirs(repo_root, args.backup_dir)
    manifests, backup_entries = load_backup_manifests(backup_dirs)
    if not manifests:
        print("FAIL rehydrate found no backup manifests", file=sys.stderr)
        return 1

    wanted = {normalize_index_path(path) for path in args.path}
    selected_paths = sorted(wanted or backup_entries.keys())
    missing = sorted(path for path in selected_paths if path not in backup_entries)
    if missing:
        print(f"FAIL rehydrate missing backup entries: {missing[: args.limit]}", file=sys.stderr)
        return 1

    items: list[IndexedFile] = []
    for rel_path in selected_paths:
        entry = backup_entries[rel_path]
        backup_dir = entry.get("_backup_dir")
        backup_file = backup_dir / "files" / rel_path if isinstance(backup_dir, Path) else None
        if backup_file is None or not backup_file.is_file():
            print(f"FAIL rehydrate missing backup file: {rel_path}", file=sys.stderr)
            return 1
        try:
            content = backup_file.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            print(f"FAIL rehydrate non-utf8 backup file: {rel_path}", file=sys.stderr)
            return 2
        items.append(indexed_file_from_content(rel_path, content))

    conn = open_db(db_path)
    has_fts5 = init_schema(conn)
    now = utc_now()
    with conn:
        for item in items:
            upsert_stored_document(conn, item, has_fts5, now)
        record_event(
            conn,
            "rehydrate-stored-documents",
            {
                "count": len(items),
                "backup_dirs": [repo_path(path.relative_to(repo_root)) for path in backup_dirs],
                "paths": [item.path for item in items[:20]],
            },
        )
    refreshed = 0
    for item in items:
        if (repo_root / item.path).exists():
            refresh_one(conn, repo_root, db_path, item.path, args.max_bytes)
            refreshed += 1
    conn.close()
    print(
        f"PASS rehydrate stored_documents={len(items)} refreshed={refreshed} "
        f"backup_dirs={len(backup_dirs)}"
    )
    for item in items[: args.limit]:
        print(f"  {item.path} [{item.kind}]")
    if len(items) > args.limit:
        print(f"  ... {len(items) - args.limit} more")
    return 0


def select_db_first_candidate_rows(conn: sqlite3.Connection, kinds: Sequence[str]) -> list[sqlite3.Row]:
    placeholders = ",".join("?" for _ in kinds)
    return conn.execute(
        f"""
        SELECT f.path, f.kind, t.content
        FROM files f
        LEFT JOIN file_text t ON t.path = f.path
        WHERE f.kind IN ({placeholders})
          AND f.index_status = 'indexed'
          AND (
            f.kind NOT IN ('task-report', 'dispatch-log', 'task-run', 'task-evidence')
            OR f.path LIKE '%.md'
          )
          AND f.path NOT LIKE '.github/cache/%'
          AND f.path NOT LIKE '.github/db-backup/%'
          AND f.path NOT LIKE '.github/tmp/%'
        ORDER BY f.path
        """,
        list(kinds),
    ).fetchall()


def audit_db_first(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    init_schema(conn)
    kinds = document_kinds(args)
    candidates = select_db_first_candidate_rows(conn, kinds)
    placeholders = ",".join("?" for _ in kinds)
    stored_rows = conn.execute(
        f"SELECT path, kind FROM db_documents WHERE kind IN ({placeholders}) ORDER BY path",
        list(kinds),
    ).fetchall()
    stored = {row["path"]: row["kind"] for row in stored_rows}
    backup_dirs = resolve_audit_backup_dirs(repo_root, args.backup_dir)
    manifests, backup_entries = load_backup_manifests(backup_dirs)

    candidate_paths = {row["path"] for row in candidates}
    missing_stored = sorted(path for path in candidate_paths if path not in stored)
    missing_live = sorted(path for path in stored if path not in candidate_paths)
    not_shim = sorted(
        row["path"]
        for row in candidates
        if row["path"] in stored and not is_db_backed_shim(row["path"], row["content"] or "")
    )
    missing_backup = sorted(path for path in stored if path not in backup_entries)
    backup_hash_mismatch: list[str] = []
    for path, entry in backup_entries.items():
        if path not in stored:
            continue
        backup_dir = entry.get("_backup_dir")
        backup_file = backup_dir / "files" / path if isinstance(backup_dir, Path) else None
        if backup_file is None or not backup_file.is_file():
            missing_backup.append(path)
            continue
        expected = str(entry.get("sha256", ""))
        actual = sha256_bytes(backup_file.read_bytes())
        if expected and actual != expected:
            backup_hash_mismatch.append(path)
    missing_backup = sorted(set(missing_backup))
    backup_hash_mismatch = sorted(set(backup_hash_mismatch))
    ok = not (missing_stored or missing_live or not_shim or missing_backup or backup_hash_mismatch or not manifests)
    payload = {
        "ok": ok,
        "db": str(db_path),
        "kinds": kinds,
        "active_candidates": len(candidates),
        "stored_documents": len(stored),
        "db_backed_shims": len(candidates) - len(missing_stored) - len(not_shim),
        "backup_dir": args.backup_dir or DEFAULT_DB_BACKUP_ROOT,
        "backup_dirs": [repo_path(path.relative_to(repo_root)) for path in backup_dirs],
        "backup_entries": len(backup_entries),
        "missing_stored": missing_stored,
        "missing_live": missing_live,
        "not_db_backed_shim": not_shim,
        "missing_backup": missing_backup,
        "backup_hash_mismatch": backup_hash_mismatch,
    }
    conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        print(
            f"{status} db-first-audit candidates={payload['active_candidates']} "
            f"stored={payload['stored_documents']} shims={payload['db_backed_shims']} "
            f"backup_entries={payload['backup_entries']} backup_dir={payload['backup_dir']}"
        )
        for key in (
            "missing_stored",
            "missing_live",
            "not_db_backed_shim",
            "missing_backup",
            "backup_hash_mismatch",
        ):
            values = payload[key]
            if values:
                print(f"[{key}]")
                for value in values[: args.limit]:
                    print(f"  {value}")
                if len(values) > args.limit:
                    print(f"  ... {len(values) - args.limit} more")
        if not manifests:
            print("FAIL backup manifest not found", file=sys.stderr)
    return 0 if ok else 1


EVIDENCE_MARKDOWN_KINDS = {"task-report", "dispatch-log", "task-run", "task-evidence"}


def audit_markdown_coverage(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    init_schema(conn)
    rows = conn.execute(
        """
        SELECT f.path, f.kind, t.content
        FROM files f
        LEFT JOIN file_text t ON t.path = f.path
        WHERE f.index_status = 'indexed'
          AND f.path LIKE '%.md'
          AND f.path NOT LIKE '.github/cache/%'
          AND f.path NOT LIKE '.github/db-backup/%'
          AND f.path NOT LIKE '.github/tmp/%'
        ORDER BY f.path
        """
    ).fetchall()
    stored = {row["path"] for row in conn.execute("SELECT path FROM db_documents")}
    by_kind: dict[str, int] = {}
    evidence_paths: list[str] = []
    unowned_non_evidence: list[str] = []
    stored_not_shim: list[str] = []
    db_owned = 0
    db_owned_non_evidence = 0
    db_shims = 0
    for row in rows:
        path = row["path"]
        kind = row["kind"]
        by_kind[kind] = by_kind.get(kind, 0) + 1
        if path in stored:
            db_owned += 1
            if kind not in EVIDENCE_MARKDOWN_KINDS:
                db_owned_non_evidence += 1
            if is_db_backed_shim(path, row["content"] or ""):
                db_shims += 1
            else:
                stored_not_shim.append(path)
            continue
        if kind in EVIDENCE_MARKDOWN_KINDS:
            evidence_paths.append(path)
        else:
            unowned_non_evidence.append(path)
    ok = not unowned_non_evidence and not stored_not_shim
    if args.fail_on_live_evidence and evidence_paths:
        ok = False
    payload = {
        "ok": ok,
        "db": str(db_path),
        "active_markdown": len(rows),
        "by_kind": dict(sorted(by_kind.items())),
        "db_owned_markdown": db_owned,
        "db_owned_non_evidence_markdown": db_owned_non_evidence,
        "db_backed_shims": db_shims,
        "live_evidence_markdown": len(evidence_paths),
        "evidence_kinds": sorted(EVIDENCE_MARKDOWN_KINDS),
        "unowned_non_evidence_markdown": unowned_non_evidence,
        "stored_not_db_backed_shim": stored_not_shim,
        "live_evidence_samples": evidence_paths[: args.limit],
    }
    conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        print(
            f"{status} markdown-coverage active_md={payload['active_markdown']} "
            f"db_owned={payload['db_owned_markdown']} "
            f"shims={payload['db_backed_shims']} live_evidence={payload['live_evidence_markdown']}"
        )
        if unowned_non_evidence:
            print("[unowned_non_evidence_markdown]")
            for path in unowned_non_evidence[: args.limit]:
                print(f"  {path}")
            if len(unowned_non_evidence) > args.limit:
                print(f"  ... {len(unowned_non_evidence) - args.limit} more")
        if stored_not_shim:
            print("[stored_not_db_backed_shim]")
            for path in stored_not_shim[: args.limit]:
                print(f"  {path}")
            if len(stored_not_shim) > args.limit:
                print(f"  ... {len(stored_not_shim) - args.limit} more")
        if args.show_evidence and evidence_paths:
            print("[live_evidence_markdown]")
            for path in evidence_paths[: args.limit]:
                print(f"  {path}")
            if len(evidence_paths) > args.limit:
                print(f"  ... {len(evidence_paths) - args.limit} more")
    return 0 if ok else 1


def smoke(args: argparse.Namespace) -> int:
    with tempfile.TemporaryDirectory(prefix="github-index-smoke-") as tmp:
        db_path = Path(tmp) / "github-index.sqlite"
        common = argparse.Namespace(
            repo_root=args.repo_root,
            root=args.root,
            db=str(db_path),
            max_bytes=args.max_bytes,
            exclude=args.exclude,
            include=args.include,
        )
        rc = rebuild(common)
        if rc != 0:
            return rc
        stat_rc = print_stat(argparse.Namespace(repo_root=args.repo_root, db=str(db_path)))
        if stat_rc != 0:
            return stat_rc
        query_rc = query(
            argparse.Namespace(
                repo_root=args.repo_root,
                db=str(db_path),
                terms=args.terms,
                kind=None,
                status="indexed",
                mode="auto",
                limit=args.limit,
                snippet_chars=180,
                json=False,
            )
        )
        if query_rc != 0:
            return query_rc
        summary_rc = summary(
            argparse.Namespace(
                repo_root=args.repo_root,
                db=str(db_path),
                path=".github/memory",
                root=args.root,
                kind=None,
                status="indexed",
                limit=args.limit,
                summary_chars=180,
                json=False,
            )
        )
        if summary_rc != 0:
            return summary_rc
        load_rc = load_chunks(
            argparse.Namespace(
                repo_root=args.repo_root,
                db=str(db_path),
                terms=args.terms,
                path=None,
                root=args.root,
                kind=None,
                status="indexed",
                mode="auto",
                source="auto",
                limit=args.limit,
                max_tokens=1200,
                json=False,
            )
        )
        if load_rc != 0:
            return load_rc
        return doctor(
            argparse.Namespace(
                repo_root=args.repo_root,
                db=str(db_path),
                max_bytes=args.max_bytes,
                write_status=False,
                fail_on_drift=True,
                sample_limit=5,
            )
        )
