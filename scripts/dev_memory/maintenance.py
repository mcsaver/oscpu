# This module was split out of scripts/github_index_db.py.
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Iterable, Sequence

from .core import *
from .queries import *

_EVIDENCE_UNSAFE_TEXT_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
DB_FIRST_STRICT_LIVE_KINDS = {"memory", "memory-module"}
DOCTOR_RAW_DRIFT_STATES = {"missing", "stale", "read_error"}


def classify_drift(repo_root: Path, row: sqlite3.Row, max_bytes: int) -> str:
    path = repo_root / row["path"]
    if not path.exists():
        return "missing"
    stat = path.stat()
    metadata_changed = (
        stat.st_size != row["size_bytes"] or stat.st_mtime_ns != row["mtime_ns"]
    )
    if not metadata_changed:
        return row["index_status"]
    if row["index_status"] == "indexed" and stat.st_size <= max_bytes:
        try:
            current_hash = sha256_bytes(path.read_bytes())
        except OSError:
            return "read_error"
        if current_hash != row["sha256"]:
            return "stale"
        return row["index_status"]
    if metadata_changed:
        return "stale"
    return row["index_status"]


def doctor_visible_state(row: sqlite3.Row, raw_state: str) -> str:
    if raw_state not in DOCTOR_RAW_DRIFT_STATES:
        return raw_state
    kind = row["kind"]
    if is_strict_db_first_live_kind(kind):
        return raw_state
    if kind in DB_FIRST_KINDS:
        return f"archived_{raw_state}"
    return f"live_index_{raw_state}"


def doctor_is_blocking_drift_state(state: str) -> bool:
    return state in DOCTOR_RAW_DRIFT_STATES


def doctor_is_nonblocking_drift_state(state: str) -> bool:
    return state.startswith("archived_") or state.startswith("live_index_")


def doctor_drift_prefix_count(counts: dict[str, int], prefix: str) -> int:
    return sum(count for state, count in counts.items() if state.startswith(prefix))


def doctor_display_state(state: str) -> str:
    if state.startswith("archived_"):
        return "historical_archive_" + state.removeprefix("archived_")
    if state.startswith("live_index_"):
        return "live_index_cache_" + state.removeprefix("live_index_")
    return state


def doctor_should_print_state(args: argparse.Namespace, state: str) -> bool:
    if doctor_is_nonblocking_drift_state(state):
        return bool(getattr(args, "show_diagnostic_details", False))
    return True


def doctor_should_print_samples(args: argparse.Namespace, state: str) -> bool:
    if doctor_is_blocking_drift_state(state):
        return True
    if doctor_is_nonblocking_drift_state(state):
        return bool(getattr(args, "show_diagnostic_details", False))
    return bool(getattr(args, "show_status_samples", False))


def doctor(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    # 默认 doctor 只是巡检当前索引和文件系统状态，不应主动切 WAL/拿写锁。
    # 只有 --write-status 需要维护索引状态，才使用可写连接并确保 schema。
    write_status = bool(getattr(args, "write_status", False))
    conn = open_db(
        db_path,
        readonly=not write_status,
        timeout=30.0 if write_status else 1.0,
        busy_timeout_ms=None if write_status else 1000,
    )
    if write_status:
        init_schema(conn)
    try:
        rows = conn.execute("SELECT * FROM files ORDER BY path").fetchall()
    except sqlite3.OperationalError as exc:
        if write_status or "database is locked" not in str(exc).lower():
            conn.close()
            raise
        conn.close()
        print("doctor=github-index")
        print("blocking_drift=unknown")
        print("db_status=locked")
        print("db_error=database is locked")
        return 2
    counts: dict[str, int] = {}
    samples: dict[str, list[str]] = {}
    now = utc_now()
    with conn:
        for row in rows:
            raw_state = classify_drift(repo_root, row, args.max_bytes)
            state = doctor_visible_state(row, raw_state)
            counts[state] = counts.get(state, 0) + 1
            samples.setdefault(state, [])
            if len(samples[state]) < args.sample_limit:
                samples[state].append(row["path"])
            if write_status and raw_state in DOCTOR_RAW_DRIFT_STATES:
                conn.execute(
                    "UPDATE files SET exists_flag=?, index_status=?, updated_at=? WHERE path=?",
                    (0 if raw_state == "missing" else 1, raw_state, now, row["path"]),
                )
        if write_status:
            record_event(conn, "doctor-write-status", {"counts": counts})
    blocking_drift = sum(
        count for state, count in counts.items() if doctor_is_blocking_drift_state(state)
    )
    nonblocking_drift = sum(
        count for state, count in counts.items() if doctor_is_nonblocking_drift_state(state)
    )
    archived_drift = doctor_drift_prefix_count(counts, "archived_")
    live_index_drift = doctor_drift_prefix_count(counts, "live_index_")
    print("doctor=github-index")
    print(f"blocking_drift={blocking_drift}")
    if getattr(args, "show_nonblocking_drift", False) or getattr(args, "show_diagnostic_details", False):
        # Verbose diagnostics split historical archive state from live-first index cache state.
        # The summary stays path-free; use --show-diagnostic-details only for maintenance triage.
        print(f"historical_archive_diagnostics={archived_drift}")
        print(f"live_index_cache_diagnostics={live_index_drift}")
        print(f"diagnostic_only={nonblocking_drift}")
        print("diagnostic_only_note=ignored_by_fail_on_drift")
    for status in sorted(counts):
        if not doctor_should_print_state(args, status):
            continue
        print(f"{doctor_display_state(status)}={counts[status]}")
        if not doctor_should_print_samples(args, status):
            continue
        for sample in samples.get(status, []):
            print(f"  {sample}")
    conn.close()
    if args.fail_on_drift and blocking_drift:
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
    has_fts5 = init_schema(conn)
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
    rows = [row for row in rows if row["kind"] in DB_FIRST_KINDS]
    if not rows:
        print("FAIL promote found no retained memory/log documents", file=sys.stderr)
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
    if item.kind not in DB_FIRST_KINDS:
        print(
            f"FAIL update-stored {rel_path}: only memory/log kinds may be database-owned (kind={item.kind})",
            file=sys.stderr,
        )
        return 2
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
    target = (repo_root / rel_path).resolve()
    try:
        ensure_inside_root(repo_root, target)
    except ValueError as exc:
        conn.close()
        print(f"FAIL update-stored {rel_path}: {exc}", file=sys.stderr)
        return 2
    if args.refresh_shim:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(db_backed_shim(rel_path, args.backup_dir), encoding="utf-8")
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
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
    rows = [row for row in rows if row["kind"] in DB_FIRST_KINDS]
    if not rows:
        print("FAIL migrate found no retained memory/log documents", file=sys.stderr)
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
            if infer_kind(rel_path) not in DB_FIRST_KINDS:
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
        print("FAIL archive-markdown found no retained memory/log Markdown files", file=sys.stderr)
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
    live_paths: list[str] = []
    for row in rows:
        rel_path = str(row["path"])
        target = (repo_root / rel_path).resolve()
        ensure_inside_root(repo_root, target)
        if args.write_shim:
            target.write_text(db_backed_shim(rel_path, repo_path(backup_dir.relative_to(repo_root))), encoding="utf-8")
            shim_paths.append(rel_path)
        else:
            live_paths.append(rel_path)
        refresh_one(conn, repo_root, db_path, rel_path, args.max_bytes)
    conn.close()
    print(
        f"PASS archive-markdown stored_documents={len(rows)} live_files={len(live_paths)} shims={len(shim_paths)} "
        f"skipped_shims={len(skipped_shims)} backup_dir={repo_path(backup_dir.relative_to(repo_root))} "
        f"manifest_entries={len(manifest['entries'])}"
    )
    for rel_path in [*live_paths, *shim_paths][: args.limit]:
        print(f"  {rel_path}")
    if len(live_paths) + len(shim_paths) > args.limit:
        print(f"  ... {len(live_paths) + len(shim_paths) - args.limit} more")
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


def sanitize_evidence_text(value: str) -> str:
    return _EVIDENCE_UNSAFE_TEXT_RE.sub(" ", value)


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
    tail_text = compact_text(sanitize_evidence_text(tail), 260)
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
    head_text = sanitize_evidence_text(str(sample["head_text"]))
    tail_text = sanitize_evidence_text(str(sample["tail_text"]))
    head = compact_text(head_text, excerpt_chars)
    tail = compact_text(tail_text, excerpt_chars)
    marker_source = f"{head_text}\n{tail_text}"
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
    has_fts5 = init_schema(conn)
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
    index_doc_statuses: dict[str, str] = {}
    stored_index_docs: list[str] = []
    backup_entries_written = 0
    if args.write_index:
        assets_by_run: dict[str, list[dict[str, object]]] = {}
        for asset in assets:
            assets_by_run.setdefault(str(asset["run_id"]), []).append(asset)
        stored_items: list[IndexedFile] = []
        for run_id, run_assets in sorted(assets_by_run.items()):
            index_doc = write_evidence_index_markdown(repo_root, run_id, run_assets)
            index_docs.append(index_doc)
            index_content = (repo_root / index_doc).read_text(encoding="utf-8")
            index_item = indexed_file_from_content(index_doc, index_content)
            if index_item.kind in DB_FIRST_KINDS:
                stored_items.append(index_item)
            index_doc_statuses[index_doc] = refresh_one(
                conn,
                repo_root,
                db_path,
                index_doc,
                DEFAULT_MAX_BYTES,
            )
        if stored_items:
            now = utc_now()
            with conn:
                for item in stored_items:
                    # evidence-index.md 是 task-run 摘要文档，必须跟随 retained DB/backup，
                    # 否则刚生成的证据索引会在 DB-first audit 中变成当前缺口。
                    upsert_stored_document(conn, item, has_fts5, now)
                record_event(
                    conn,
                    "store-evidence-index-documents",
                    {"count": len(stored_items), "paths": [item.path for item in stored_items]},
                )
            backup_dir = resolve_backup_dir(repo_root, args.backup_dir)
            manifest = write_backup_files(
                repo_root,
                backup_dir,
                [
                    {
                        "path": item.path,
                        "kind": item.kind,
                        "content": item.content,
                    }
                    for item in stored_items
                ],
            )
            stored_index_docs = [item.path for item in stored_items]
            backup_entries_written = len(manifest.get("entries", []))
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
                    "index_doc_statuses": index_doc_statuses,
                    "stored_index_docs": stored_index_docs,
                    "backup_dir": args.backup_dir,
                    "backup_entries": backup_entries_written,
                },
                ensure_ascii=False,
                indent=2,
            )
        )
    else:
        print(
            f"PASS index-evidence assets={len(assets)} runs={len(run_ids)} "
            f"index_docs={len(index_docs)} stored_index_docs={len(stored_index_docs)}"
        )
        if stored_index_docs:
            print(f"  evidence-index backup_dir={args.backup_dir} entries={backup_entries_written}")
        for path, status in sorted(index_doc_statuses.items()):
            print(f"  {path} [index-doc] refreshed status={status}")
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
    has_fts5 = init_schema(conn)
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
        if dest_root == repo_root:
            refresh_one(conn, repo_root, db_path, row["path"], args.max_bytes)
    pruned: list[str] = []
    if args.prune_non_retained:
        if paths:
            prune_rows = [row for row in rows if row["kind"] not in DB_FIRST_KINDS]
        else:
            prune_rows = conn.execute(
                "SELECT path, kind FROM db_documents ORDER BY path"
            ).fetchall()
            prune_rows = [row for row in prune_rows if row["kind"] not in DB_FIRST_KINDS]
        with conn:
            for row in prune_rows:
                delete_document_chunks_for_path(conn, row["path"], has_fts5)
                conn.execute("DELETE FROM db_documents WHERE path = ?", (row["path"],))
                pruned.append(row["path"])
            if pruned:
                record_event(
                    conn,
                    "materialize-prune-non-retained",
                    {"count": len(pruned), "paths": pruned[:20]},
                )
    conn.close()
    print(
        f"PASS materialize documents={len(rows)} output_root={repo_path(dest_root.relative_to(repo_root))} "
        f"pruned_non_retained={len(pruned)}"
    )
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
    if wanted:
        rejected = sorted(path for path in wanted if infer_kind(path) not in DB_FIRST_KINDS)
        if rejected:
            print(f"FAIL rehydrate non-retained requested paths: {rejected[: args.limit]}", file=sys.stderr)
            return 2
        selected_paths = sorted(wanted)
    else:
        selected_paths = sorted(
            path for path in backup_entries.keys() if infer_kind(path) in DB_FIRST_KINDS
        )
    missing = sorted(path for path in selected_paths if path not in backup_entries)
    if missing:
        print(f"FAIL rehydrate missing backup entries: {missing[: args.limit]}", file=sys.stderr)
        return 1
    if not selected_paths:
        print("FAIL rehydrate found no retained memory/log backup entries", file=sys.stderr)
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


def read_live_db_first_candidates(
    repo_root: Path,
    indexed_rows: Sequence[sqlite3.Row],
) -> tuple[dict[str, dict[str, str]], list[str]]:
    candidates: dict[str, dict[str, str]] = {}
    read_errors: list[str] = []
    for row in indexed_rows:
        rel_path = row["path"]
        target = (repo_root / rel_path).resolve()
        try:
            ensure_inside_root(repo_root, target)
        except ValueError:
            read_errors.append(rel_path)
            continue
        if not target.is_file():
            continue
        try:
            content = target.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            read_errors.append(rel_path)
            continue
        candidates[rel_path] = {"path": rel_path, "kind": row["kind"], "content": content}
    return candidates, read_errors


def is_strict_db_first_live_kind(kind: str) -> bool:
    return kind in DB_FIRST_STRICT_LIVE_KINDS


def audit_db_first(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    init_schema(conn)
    kinds = document_kinds(args)
    indexed_candidates = select_db_first_candidate_rows(conn, kinds)
    candidate_by_path, live_read_errors = read_live_db_first_candidates(repo_root, indexed_candidates)
    candidates = list(candidate_by_path.values())
    placeholders = ",".join("?" for _ in kinds)
    stored_rows = conn.execute(
        f"SELECT path, kind, sha256, content FROM db_documents WHERE kind IN ({placeholders}) ORDER BY path",
        list(kinds),
    ).fetchall()
    stored = {row["path"]: row for row in stored_rows}
    unexpected_stored_rows = conn.execute(
        f"SELECT path, kind FROM db_documents WHERE kind NOT IN ({placeholders}) ORDER BY path",
        list(kinds),
    ).fetchall()
    unexpected_stored = [f"{row['path']} [{row['kind']}]" for row in unexpected_stored_rows]
    backup_dirs = resolve_audit_backup_dirs(repo_root, args.backup_dir)
    manifests, backup_entries = load_backup_manifests(backup_dirs)

    candidate_paths = set(candidate_by_path)
    missing_stored = sorted(path for path in candidate_paths if path not in stored)
    missing_live: list[str] = []
    archived_stored_only: list[str] = []
    for path, row in stored.items():
        if path in candidate_paths:
            continue
        if is_strict_db_first_live_kind(row["kind"]):
            missing_live.append(path)
        else:
            archived_stored_only.append(path)
    live_materialized = 0
    db_backed_shims = 0
    content_mismatch: list[str] = []
    live_content_drift: list[str] = []
    for row in candidates:
        path = row["path"]
        if path not in stored:
            continue
        content = row["content"] or ""
        if is_db_backed_shim(path, content):
            db_backed_shims += 1
            continue
        if sha256_bytes(content.encode("utf-8")) != stored[path]["sha256"]:
            if is_strict_db_first_live_kind(row["kind"]):
                content_mismatch.append(path)
            else:
                live_content_drift.append(path)
        else:
            live_materialized += 1
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
    ok = not (
        unexpected_stored
        or missing_stored
        or missing_live
        or content_mismatch
        or live_read_errors
        or missing_backup
        or backup_hash_mismatch
        or not manifests
    )
    payload = {
        "ok": ok,
        "db": str(db_path),
        "kinds": kinds,
        "active_candidates": len(candidates),
        "indexed_candidates": len(indexed_candidates),
        "stored_documents": len(stored),
        "live_materialized": live_materialized,
        "db_backed_shims": db_backed_shims,
        "backup_dir": args.backup_dir or DEFAULT_DB_BACKUP_ROOT,
        "backup_dirs": [repo_path(path.relative_to(repo_root)) for path in backup_dirs],
        "backup_entries": len(backup_entries),
        "unexpected_stored": unexpected_stored,
        "missing_stored": missing_stored,
        "missing_live": missing_live,
        "archived_stored_only": archived_stored_only,
        "content_mismatch": content_mismatch,
        "live_content_drift": live_content_drift,
        "live_read_errors": sorted(live_read_errors),
        "missing_backup": missing_backup,
        "backup_hash_mismatch": backup_hash_mismatch,
        "strict_live_kinds": sorted(DB_FIRST_STRICT_LIVE_KINDS),
    }
    conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        nonblocking_db_first_drift = len(archived_stored_only) + len(live_content_drift)
        print(
            f"{status} db-first-audit candidates={payload['active_candidates']} "
            f"stored={payload['stored_documents']} materialized={payload['live_materialized']} "
            f"shims={payload['db_backed_shims']} "
            f"backup_entries={payload['backup_entries']} backup_dir={payload['backup_dir']}"
        )
        if nonblocking_db_first_drift:
            if args.show_nonblocking_drift:
                print(f"nonblocking_db_first_drift={nonblocking_db_first_drift}")
                print(f"nonblocking_archived_stored_only={len(archived_stored_only)}")
                print(f"nonblocking_live_drift={len(live_content_drift)}")
                for key, label in (
                    ("archived_stored_only", "nonblocking_archived_stored_only"),
                    ("live_content_drift", "nonblocking_live_drift"),
                ):
                    values = payload[key]
                    if values:
                        print(f"[{label}]")
                        for value in values[: args.limit]:
                            print(f"  {value}")
                        if len(values) > args.limit:
                            print(f"  ... {len(values) - args.limit} more")
        for key in (
            "unexpected_stored",
            "missing_stored",
            "missing_live",
            "content_mismatch",
            "live_read_errors",
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
LIVE_RULE_MARKDOWN_KINDS = {"skill"}


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
    stored = {row["path"]: row["kind"] for row in conn.execute("SELECT path, kind FROM db_documents")}
    by_kind: dict[str, int] = {}
    evidence_paths: list[str] = []
    live_rule_paths: list[str] = []
    unowned_non_evidence: list[str] = []
    stored_not_shim: list[str] = []
    stored_unexpected: list[str] = []
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
            if stored[path] not in DB_FIRST_KINDS:
                stored_unexpected.append(path)
            if is_db_backed_shim(path, row["content"] or ""):
                db_shims += 1
            else:
                stored_not_shim.append(path)
            continue
        if kind in EVIDENCE_MARKDOWN_KINDS:
            evidence_paths.append(path)
        elif kind in LIVE_RULE_MARKDOWN_KINDS:
            live_rule_paths.append(path)
        else:
            unowned_non_evidence.append(path)
    ok = not stored_unexpected
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
        "live_rule_markdown": len(live_rule_paths),
        "evidence_kinds": sorted(EVIDENCE_MARKDOWN_KINDS),
        "live_rule_kinds": sorted(LIVE_RULE_MARKDOWN_KINDS),
        "unowned_non_evidence_markdown": unowned_non_evidence,
        "stored_unexpected_markdown": stored_unexpected,
        "stored_not_db_backed_shim": stored_not_shim,
        "live_evidence_samples": evidence_paths[: args.limit],
        "live_rule_samples": live_rule_paths[: args.limit],
    }
    conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        print(
            f"{status} markdown-coverage active_md={payload['active_markdown']} "
            f"db_owned={payload['db_owned_markdown']} "
            f"shims={payload['db_backed_shims']} live_evidence={payload['live_evidence_markdown']} "
            f"live_rules={payload['live_rule_markdown']}"
        )
        if stored_unexpected:
            print("[stored_unexpected_markdown]")
            for path in stored_unexpected[: args.limit]:
                print(f"  {path}")
            if len(stored_unexpected) > args.limit:
                print(f"  ... {len(stored_unexpected) - args.limit} more")
        if args.show_evidence and evidence_paths:
            print("[live_evidence_markdown]")
            for path in evidence_paths[: args.limit]:
                print(f"  {path}")
            if len(evidence_paths) > args.limit:
                print(f"  ... {len(evidence_paths) - args.limit} more")
    return 0 if ok else 1


SKILL_NAME_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,62}[a-z0-9]$")


def parse_skill_frontmatter(text: str) -> tuple[dict[str, str], int, list[str]]:
    lines = text.splitlines()
    errors: list[str] = []
    if not lines or lines[0].strip() != "---":
        return {}, 0, ["missing YAML frontmatter"]
    end = 0
    for idx in range(1, len(lines)):
        if lines[idx].strip() == "---":
            end = idx
            break
    if end == 0:
        return {}, 0, ["unterminated YAML frontmatter"]

    data: dict[str, str] = {}
    for line_no, raw in enumerate(lines[1:end], start=2):
        line = raw.strip()
        if not line:
            continue
        if ":" not in line:
            errors.append(f"line {line_no}: expected key: value")
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        data[key] = value
    return data, end + 1, errors


def audit_one_skill(skill_file: Path, repo_root: Path) -> dict[str, object]:
    rel = repo_path(skill_file.relative_to(repo_root))
    text = skill_file.read_text(encoding="utf-8")
    data, body_start, errors = parse_skill_frontmatter(text)
    folder_name = skill_file.parent.name
    name = data.get("name", "")
    description = data.get("description", "")
    allowed_keys = {"name", "description"}
    extra_keys = sorted(set(data) - allowed_keys)
    body = "\n".join(text.splitlines()[body_start:])

    if name != folder_name:
        errors.append(f"name must match folder: expected {folder_name!r}, got {name!r}")
    if not SKILL_NAME_RE.fullmatch(name):
        errors.append("name must be lower-case hyphen form, 2-64 chars")
    if not description:
        errors.append("description is required")
    if extra_keys:
        errors.append(f"frontmatter has unsupported keys: {', '.join(extra_keys)}")
    if not body.strip():
        errors.append("body is empty")
    if len(text.splitlines()) > 500:
        errors.append("SKILL.md should stay under 500 lines; move details to references/")

    return {
        "path": rel,
        "name": name,
        "description": description,
        "ok": not errors,
        "errors": errors,
    }


def skill_audit(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    skills_root = (repo_root / args.path).resolve()
    try:
        ensure_inside_root(repo_root, skills_root)
    except ValueError as exc:
        print(f"FAIL skill-audit: {exc}", file=sys.stderr)
        return 2

    skill_files = sorted(skills_root.glob("*/SKILL.md")) if skills_root.is_dir() else []
    results = [audit_one_skill(path, repo_root) for path in skill_files]
    missing_root = not skills_root.is_dir()
    ok = bool(results) and not missing_root and all(bool(item["ok"]) for item in results)
    payload = {
        "ok": ok,
        "path": repo_path(skills_root.relative_to(repo_root)) if skills_root.is_relative_to(repo_root) else str(skills_root),
        "skill_count": len(results),
        "missing_root": missing_root,
        "skills": results,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        print(f"{status} skill-audit path={payload['path']} skills={len(results)}")
        if missing_root:
            print(f"  missing skills root: {payload['path']}")
        for item in results:
            item_status = "PASS" if item["ok"] else "FAIL"
            print(f"{item_status} {item['path']} name={item.get('name') or '<missing>'}")
            for error in item["errors"][: args.limit]:
                print(f"  {error}")
    return 0 if ok else 1


AGENT_TOOLS_RE = re.compile(r"^tools:\s*\[(.*?)\]\s*$", re.M)


def split_inline_list(value: str) -> list[str]:
    return [item.strip().strip('"').strip("'") for item in value.split(",") if item.strip()]


def load_policy(repo_root: Path, path: str) -> tuple[dict[str, object], Path]:
    policy_path = (repo_root / path).resolve()
    ensure_inside_root(repo_root, policy_path)
    with policy_path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError("policy root must be a JSON object")

    shim_target = str(data.get("shim_for", "")).strip()
    if shim_target:
        target_path = (repo_root / shim_target).resolve()
        ensure_inside_root(repo_root, target_path)
        if not target_path.is_file():
            raise FileNotFoundError(f"contract shim target missing: {shim_target}")
        if target_path == policy_path:
            raise ValueError(f"contract shim points to itself: {path}")
        with target_path.open("r", encoding="utf-8") as fh:
            target_data = json.load(fh)
        if not isinstance(target_data, dict):
            raise ValueError("contract shim target root must be a JSON object")
        return target_data, target_path

    return data, policy_path


REPORT_REQUIREMENT_IDS = {
    "R1",
    "R2",
    "R3",
    "R4",
    "R5",
    "R6",
    "R7",
    "R8",
    "R9",
}
REPORT_STATUS_VALUES = {"implemented", "partial", "planned"}
REPORT_EVIDENCE_PATH_TYPES = {"path", "task-run"}


def audit_report_matrix_payload(
    repo_root: Path,
    matrix: dict[str, object],
    required_ids: set[str],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    if int(matrix.get("schema_version", 0) or 0) != 1:
        errors.append("schema_version must be 1")
    if not isinstance(matrix.get("source_report"), dict):
        errors.append("source_report must be an object")

    raw_requirements = matrix.get("requirements", [])
    if not isinstance(raw_requirements, list) or not raw_requirements:
        return {
            "requirements": 0,
            "by_status": {},
            "missing_required_ids": sorted(required_ids),
            "duplicates": [],
        }, errors + ["requirements must be a non-empty array"]

    seen: set[str] = set()
    duplicates: list[str] = []
    by_status: dict[str, int] = {}
    requirement_ids: set[str] = set()
    for idx, raw_req in enumerate(raw_requirements):
        if not isinstance(raw_req, dict):
            errors.append(f"requirements[{idx}] must be an object")
            continue
        req_id = str(raw_req.get("id", "")).strip()
        if not req_id:
            errors.append(f"requirements[{idx}] missing id")
            continue
        if req_id in seen:
            duplicates.append(req_id)
            errors.append(f"{req_id}: duplicate requirement id")
        seen.add(req_id)
        requirement_ids.add(req_id)

        for field in ("title", "priority", "layer", "report_basis", "next_action"):
            if not str(raw_req.get(field, "")).strip():
                errors.append(f"{req_id}: missing {field}")
        status = str(raw_req.get("status", "")).strip()
        by_status[status] = by_status.get(status, 0) + 1
        if status not in REPORT_STATUS_VALUES:
            errors.append(f"{req_id}: invalid status {status!r}")

        evidence = raw_req.get("evidence", [])
        if not isinstance(evidence, list) or not evidence:
            errors.append(f"{req_id}: evidence must be a non-empty array")
        else:
            for evidence_idx, item in enumerate(evidence):
                if not isinstance(item, dict):
                    errors.append(f"{req_id}: evidence[{evidence_idx}] must be an object")
                    continue
                evidence_type = str(item.get("type", "")).strip()
                value = str(item.get("value", "")).strip()
                if not evidence_type or not value:
                    errors.append(f"{req_id}: evidence[{evidence_idx}] missing type or value")
                    continue
                if evidence_type in REPORT_EVIDENCE_PATH_TYPES and not (repo_root / value).exists():
                    errors.append(f"{req_id}: evidence path missing: {value}")

        verification = raw_req.get("verification", [])
        if not isinstance(verification, list) or not verification:
            errors.append(f"{req_id}: verification must be a non-empty array")

    missing_required_ids = sorted(required_ids.difference(requirement_ids))
    for req_id in missing_required_ids:
        errors.append(f"missing required report requirement: {req_id}")

    return {
        "requirements": len(raw_requirements),
        "by_status": dict(sorted(by_status.items())),
        "missing_required_ids": missing_required_ids,
        "duplicates": sorted(set(duplicates)),
    }, errors


def report_audit(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    try:
        matrix, matrix_path = load_policy(repo_root, args.matrix)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL report-audit: {exc}", file=sys.stderr)
        return 2
    required_ids = set(args.requirement_id or sorted(REPORT_REQUIREMENT_IDS))
    result, errors = audit_report_matrix_payload(repo_root, matrix, required_ids)
    ok = not errors
    payload = {
        "ok": ok,
        "matrix": repo_path(matrix_path.relative_to(repo_root)),
        **result,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        by_status = ",".join(
            f"{key}={value}" for key, value in payload["by_status"].items()
        )
        print(
            f"{status} report-audit matrix={payload['matrix']} "
            f"requirements={payload['requirements']} {by_status}"
        )
        if errors:
            print("[report_errors]")
            for error in errors[: args.limit]:
                print(f"  {error}")
            if len(errors) > args.limit:
                print(f"  ... {len(errors) - args.limit} more")
    return 0 if ok else 1


def table_columns(conn: sqlite3.Connection, table: str) -> list[str]:
    return [row["name"] for row in conn.execute(f"PRAGMA table_info({table})").fetchall()]


def schema_audit(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    try:
        contract, contract_path = load_policy(repo_root, args.contract)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL schema-audit: {exc}", file=sys.stderr)
        return 2

    errors: list[str] = []
    if int(contract.get("schema_version", 0) or 0) != 1:
        errors.append("schema_version must be 1")
    database = contract.get("database", {})
    if not isinstance(database, dict):
        errors.append("database must be an object")
        database = {}
    expected_runtime_schema = str(database.get("runtime_schema_version", ""))
    tables = contract.get("tables", {})
    if not isinstance(tables, dict) or not tables:
        errors.append("tables must be a non-empty object")
        tables = {}
    api_contract = contract.get("api", {})
    if not isinstance(api_contract, dict):
        errors.append("api must be an object")
        api_contract = {}
    entities = contract.get("entities", [])
    if not isinstance(entities, list) or not entities:
        errors.append("entities must be a non-empty array")
        entities = []

    conn = open_db(db_path, readonly=True)
    try:
        meta = {
            row["key"]: row["value"]
            for row in conn.execute("SELECT key, value FROM meta").fetchall()
        }
        actual_runtime_schema = str(meta.get("schema_version", ""))
        if expected_runtime_schema and actual_runtime_schema != expected_runtime_schema:
            errors.append(
                f"runtime schema mismatch: expected {expected_runtime_schema}, got {actual_runtime_schema}"
            )
        table_results: dict[str, dict[str, object]] = {}
        for table, expected_columns_raw in sorted(tables.items()):
            expected_columns = [str(column) for column in expected_columns_raw]
            actual_columns = table_columns(conn, str(table))
            missing_columns = [column for column in expected_columns if column not in actual_columns]
            extra_columns = [column for column in actual_columns if column not in expected_columns]
            if not actual_columns:
                errors.append(f"table missing: {table}")
            if missing_columns:
                errors.append(f"{table}: missing columns: {', '.join(missing_columns)}")
            table_results[str(table)] = {
                "columns": len(actual_columns),
                "missing_columns": missing_columns,
                "extra_columns": extra_columns,
            }
    finally:
        conn.close()

    from .api import api_schema_payload

    api_schema = api_schema_payload()
    actual_ops = set(api_schema.get("operations", {}).keys())
    required_ops = {str(op) for op in api_contract.get("required_operations", [])}
    missing_ops = sorted(required_ops.difference(actual_ops))
    if missing_ops:
        errors.append(f"api missing operations: {', '.join(missing_ops)}")

    table_names = set(tables.keys())
    entity_results: list[dict[str, object]] = []
    for idx, entity in enumerate(entities):
        if not isinstance(entity, dict):
            errors.append(f"entities[{idx}] must be an object")
            continue
        name = str(entity.get("name", "")).strip()
        backing_tables = [str(table) for table in entity.get("backing_tables", [])]
        if not name:
            errors.append(f"entities[{idx}] missing name")
        if not backing_tables:
            errors.append(f"{name or f'entities[{idx}]'}: missing backing_tables")
        missing_backing = sorted(table for table in backing_tables if table not in table_names)
        if missing_backing:
            errors.append(f"{name}: backing tables absent from contract: {', '.join(missing_backing)}")
        entity_results.append(
            {
                "name": name,
                "layer": str(entity.get("layer", "")),
                "backing_tables": backing_tables,
                "missing_backing": missing_backing,
            }
        )

    ok = not errors
    payload = {
        "ok": ok,
        "contract": repo_path(contract_path.relative_to(repo_root)),
        "db": str(db_path),
        "runtime_schema_version": expected_runtime_schema,
        "tables": table_results if "table_results" in locals() else {},
        "entities": entity_results,
        "api_required_operations": sorted(required_ops),
        "api_missing_operations": missing_ops,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        print(
            f"{status} schema-audit contract={payload['contract']} "
            f"runtime_schema={payload['runtime_schema_version']} "
            f"tables={len(payload['tables'])} api_ops={len(required_ops)}"
        )
        if errors:
            print("[schema_errors]")
            for error in errors[: args.limit]:
                print(f"  {error}")
            if len(errors) > args.limit:
                print(f"  ... {len(errors) - args.limit} more")
    return 0 if ok else 1


def audit_agent_tool_policy(
    conn: sqlite3.Connection,
    policy: dict[str, object],
) -> tuple[list[dict[str, object]], list[str]]:
    errors: list[str] = []
    results: list[dict[str, object]] = []
    tool_policy = policy.get("agent_tools", {})
    if not isinstance(tool_policy, dict):
        return results, ["agent_tools must be an object"]
    allowed_tools = set(str(item) for item in tool_policy.get("allowed_tools", []))
    missing_exemptions = set(str(item) for item in tool_policy.get("missing_tools_exemptions", []))
    allow_mcp = bool(tool_policy.get("allow_mcp_servers", False))
    if not allowed_tools:
        errors.append("agent_tools.allowed_tools must not be empty")

    rows = conn.execute(
        """
        SELECT f.path, t.content
        FROM files f
        JOIN file_text t ON t.path = f.path
        WHERE f.kind = 'agent' AND f.index_status = 'indexed'
        ORDER BY f.path
        """
    ).fetchall()
    if not rows:
        errors.append("no live indexed agent documents found")
        return results, errors

    for row in rows:
        path = row["path"]
        content = row["content"] or ""
        match = AGENT_TOOLS_RE.search(content)
        tools = split_inline_list(match.group(1)) if match else []
        missing_tools = not tools
        unknown_tools = sorted(tool for tool in tools if tool not in allowed_tools)
        has_mcp = "mcp-servers" in content
        agent_errors: list[str] = []
        if missing_tools and path not in missing_exemptions:
            agent_errors.append("missing tools frontmatter")
        if unknown_tools:
            agent_errors.append(f"tools outside allowlist: {', '.join(unknown_tools)}")
        if has_mcp and not allow_mcp:
            agent_errors.append("mcp-servers declared while policy disallows MCP servers")
        errors.extend(f"{path}: {error}" for error in agent_errors)
        results.append(
            {
                "path": path,
                "tools": tools,
                "missing_tools": missing_tools,
                "missing_tools_exempted": missing_tools and path in missing_exemptions,
                "has_mcp_servers": has_mcp,
                "ok": not agent_errors,
                "errors": agent_errors,
            }
        )
    return results, errors


def audit_policy_paths(repo_root: Path, policy: dict[str, object]) -> list[str]:
    errors: list[str] = []
    layers = policy.get("layers", {})
    if not isinstance(layers, dict):
        return ["layers must be an object"]

    database = layers.get("database", {})
    if isinstance(database, dict):
        for path in database.get("backup_roots", []):
            if not (repo_root / str(path)).exists():
                errors.append(f"database backup root missing: {path}")
    else:
        errors.append("layers.database must be an object")

    skill = layers.get("skill", {})
    if isinstance(skill, dict):
        for path in skill.get("live_roots", []):
            if not (repo_root / str(path)).is_dir():
                errors.append(f"skill live root missing: {path}")
    else:
        errors.append("layers.skill must be an object")

    agent = layers.get("agent", {})
    if isinstance(agent, dict):
        maintainer = str(agent.get("maintainer", ""))
        if maintainer and not (repo_root / maintainer).is_file():
            errors.append(f"agent maintainer missing: {maintainer}")
    else:
        errors.append("layers.agent must be an object")

    traceability = policy.get("traceability", {})
    if isinstance(traceability, dict):
        matrix = str(traceability.get("matrix", ""))
        if matrix and not (repo_root / matrix).is_file():
            errors.append(f"traceability matrix missing: {matrix}")
        schema_contract = str(traceability.get("schema_contract", ""))
        if schema_contract and not (repo_root / schema_contract).is_file():
            errors.append(f"traceability schema contract missing: {schema_contract}")
        state_traceability_contract = str(traceability.get("state_traceability_contract", ""))
        if state_traceability_contract and not (repo_root / state_traceability_contract).is_file():
            errors.append(f"traceability state traceability contract missing: {state_traceability_contract}")
        runtime_artifact_contract = str(traceability.get("runtime_artifact_contract", ""))
        if runtime_artifact_contract and not (repo_root / runtime_artifact_contract).is_file():
            errors.append(f"traceability runtime artifact contract missing: {runtime_artifact_contract}")
        delivery_contract = str(traceability.get("delivery_contract", ""))
        if delivery_contract and not (repo_root / delivery_contract).is_file():
            errors.append(f"traceability delivery contract missing: {delivery_contract}")
    elif traceability:
        errors.append("traceability must be an object")

    state_machine = policy.get("state_machine", {})
    if isinstance(state_machine, dict):
        instruction = str(state_machine.get("instruction", ""))
        if instruction and not (repo_root / instruction).is_file():
            errors.append(f"state machine instruction missing: {instruction}")
        contract = str(state_machine.get("contract", ""))
        if contract and not (repo_root / contract).is_file():
            errors.append(f"state machine contract missing: {contract}")
    elif state_machine:
        errors.append("state_machine must be an object")

    delivery = policy.get("delivery", {})
    if isinstance(delivery, dict):
        contract = str(delivery.get("contract", ""))
        if contract and not (repo_root / contract).is_file():
            errors.append(f"delivery contract missing: {contract}")
        package_script = str(delivery.get("package_script", ""))
        if package_script and not (repo_root / package_script).is_file():
            errors.append(f"delivery package script missing: {package_script}")
        delivery_root = str(delivery.get("delivery_root", ""))
        if delivery_root and not (repo_root / delivery_root).is_dir():
            errors.append(f"delivery root missing: {delivery_root}")
        archive_root = str(delivery.get("archive_root", ""))
        if archive_root and not (repo_root / archive_root).is_dir():
            errors.append(f"delivery archive root missing: {archive_root}")
    elif delivery:
        errors.append("delivery must be an object")
    return errors


def audit_ci_policy(repo_root: Path, policy: dict[str, object]) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    ci = policy.get("ci", {})
    if not isinstance(ci, dict):
        return {}, ["ci must be an object"]
    workflow_path = str(ci.get("required_workflow", ""))
    workflow_text = ""
    if not workflow_path:
        errors.append("ci.required_workflow is required")
    else:
        path = repo_root / workflow_path
        if not path.is_file():
            errors.append(f"required workflow missing: {workflow_path}")
        else:
            workflow_text = path.read_text(encoding="utf-8")
    missing_commands: list[str] = []
    if workflow_text:
        for command in ci.get("required_commands", []):
            command_text = str(command)
            if command_text not in workflow_text:
                missing_commands.append(command_text)
        if bool(ci.get("nightly_required", False)) and "schedule:" not in workflow_text:
            errors.append("required workflow is missing schedule trigger")
    errors.extend(f"workflow missing command: {command}" for command in missing_commands)
    return {
        "workflow": workflow_path,
        "missing_commands": missing_commands,
        "nightly_required": bool(ci.get("nightly_required", False)),
    }, errors


def policy_audit(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    errors: list[str] = []
    try:
        policy, policy_path = load_policy(repo_root, args.policy)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL policy-audit: {exc}", file=sys.stderr)
        return 2

    if int(policy.get("schema_version", 0) or 0) != 1:
        errors.append("schema_version must be 1")
    errors.extend(audit_policy_paths(repo_root, policy))

    conn = open_db(db_path, readonly=True)
    try:
        agent_results, agent_errors = audit_agent_tool_policy(conn, policy)
    finally:
        conn.close()
    errors.extend(agent_errors)
    ci_result, ci_errors = audit_ci_policy(repo_root, policy)
    errors.extend(ci_errors)

    ok = not errors
    payload = {
        "ok": ok,
        "policy": repo_path(policy_path.relative_to(repo_root)),
        "agent_count": len(agent_results),
        "agents": agent_results,
        "ci": ci_result,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        print(
            f"{status} policy-audit policy={payload['policy']} "
            f"agents={payload['agent_count']} workflow={ci_result.get('workflow', '<missing>')}"
        )
        for result in agent_results[: args.limit]:
            result_status = "PASS" if result["ok"] else "FAIL"
            tools = ",".join(result["tools"]) if result["tools"] else "<missing>"
            suffix = " exempted" if result.get("missing_tools_exempted") else ""
            print(f"{result_status} {result['path']} tools={tools}{suffix}")
            for error in result["errors"]:
                print(f"  {error}")
        if errors:
            print("[policy_errors]")
            for error in errors[: args.limit]:
                print(f"  {error}")
            if len(errors) > args.limit:
                print(f"  ... {len(errors) - args.limit} more")
    return 0 if ok else 1


BRANCH_HEALTH_REQUIRED_SIGNALS = {
    "current_branch",
    "head_commit",
    "upstream",
    "git_status_counts",
    "review_routes",
    "matrix_status",
    "maintenance_gates",
}
BRANCH_HEALTH_REQUIRED_GATES = {
    "report-audit",
    "schema-audit",
    "artifact-audit",
    "delivery-audit",
    "policy-audit",
    "skill-audit",
    "branch-health-report",
    "branch-health-audit",
    "audit-db-first",
    "audit-markdown-coverage",
    "validate-all-profiles",
}


OBSERVABILITY_REQUIRED_SIGNALS = {
    "trace_id",
    "run_id",
    "task_slug",
    "profile",
    "status",
    "git",
    "artifacts",
    "node_counts",
    "evidence",
}

STATE_TRACEABILITY_REQUIRED_STATES = {
    "recall_context",
    "classify_layer",
    "plan_graph",
    "implement",
    "verify",
    "inspect",
    "persist",
}
STATE_TRACEBACK_REQUIRED_FIELDS = {
    "state_sequence",
    "current_state",
    "failure_state",
    "rollback_target",
    "failure_reason",
    "reviewer",
    "inspector",
    "evidence_policy",
}
STATE_REVIEWER_INSPECTOR_NODES = {
    "state-machine-traceback": "e2e_agent_system_state_traceback",
    "reviewer-inspector-gate": "e2e_agent_system_reviewer_inspector_gate",
}


def git_capture(repo_root: Path, args: Sequence[str]) -> tuple[int, str, str]:
    proc = subprocess.run(
        ["git", "-C", str(repo_root), *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def parse_git_status_porcelain(text: str, limit: int) -> dict[str, object]:
    counts = {"staged": 0, "unstaged": 0, "untracked": 0}
    samples: dict[str, list[str]] = {"staged": [], "unstaged": [], "untracked": []}
    for raw_line in text.splitlines():
        if not raw_line:
            continue
        path = raw_line[3:] if len(raw_line) > 3 else raw_line
        if raw_line.startswith("??"):
            counts["untracked"] += 1
            if len(samples["untracked"]) < limit:
                samples["untracked"].append(path)
            continue
        index_status = raw_line[0]
        worktree_status = raw_line[1] if len(raw_line) > 1 else " "
        if index_status not in {" ", "?"}:
            counts["staged"] += 1
            if len(samples["staged"]) < limit:
                samples["staged"].append(path)
        if worktree_status not in {" ", "?"}:
            counts["unstaged"] += 1
            if len(samples["unstaged"]) < limit:
                samples["unstaged"].append(path)
    return {"counts": counts, "samples": samples}


def matrix_status_counts(repo_root: Path, matrix_path: str) -> dict[str, int]:
    matrix, _ = load_policy(repo_root, matrix_path)
    counts: dict[str, int] = {}
    for raw_req in matrix.get("requirements", []):
        if isinstance(raw_req, dict):
            status = str(raw_req.get("status", "")).strip() or "<missing>"
            counts[status] = counts.get(status, 0) + 1
    return dict(sorted(counts.items()))


def load_branch_health_contracts(
    repo_root: Path,
    dashboard_path: str,
    routing_path_override: str = "",
) -> tuple[dict[str, object], Path, dict[str, object], Path]:
    dashboard, dashboard_file = load_policy(repo_root, dashboard_path)
    routing_path = routing_path_override or str(dashboard.get("review_routing", ""))
    if not routing_path:
        raise ValueError("branch health dashboard missing review_routing")
    routing, routing_file = load_policy(repo_root, routing_path)
    return dashboard, dashboard_file, routing, routing_file


def validate_review_routing_payload(
    repo_root: Path,
    routing: dict[str, object],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    if int(routing.get("schema_version", 0) or 0) != 1:
        errors.append("review routing schema_version must be 1")

    raw_routes = routing.get("review_routes", [])
    if not isinstance(raw_routes, list) or not raw_routes:
        return {"routes": 0, "layers": [], "requirement_routes": 0}, errors + ["review_routes must be a non-empty array"]

    route_ids: set[str] = set()
    layers: set[str] = set()
    for idx, raw_route in enumerate(raw_routes):
        if not isinstance(raw_route, dict):
            errors.append(f"review_routes[{idx}] must be an object")
            continue
        route_id = str(raw_route.get("id", "")).strip()
        layer = str(raw_route.get("layer", "")).strip()
        primary_agent = str(raw_route.get("primary_agent", "")).strip()
        paths = [str(path) for path in raw_route.get("paths", [])]
        required_checks = [str(check) for check in raw_route.get("required_checks", [])]
        if not route_id:
            errors.append(f"review_routes[{idx}] missing id")
        elif route_id in route_ids:
            errors.append(f"duplicate review route id: {route_id}")
        route_ids.add(route_id)
        if layer:
            layers.add(layer)
        else:
            errors.append(f"{route_id or f'review_routes[{idx}]'}: missing layer")
        if not primary_agent:
            errors.append(f"{route_id or f'review_routes[{idx}]'}: missing primary_agent")
        if not paths:
            errors.append(f"{route_id or f'review_routes[{idx}]'}: paths must not be empty")
        for path in paths:
            if not (repo_root / path).exists():
                errors.append(f"{route_id}: route path missing: {path}")
        if not required_checks:
            errors.append(f"{route_id or f'review_routes[{idx}]'}: required_checks must not be empty")

    missing_layers = sorted({"database", "skill", "agent"}.difference(layers))
    for layer in missing_layers:
        errors.append(f"missing review route layer: {layer}")

    requirement_routes = routing.get("requirement_routes", {})
    if not isinstance(requirement_routes, dict):
        errors.append("requirement_routes must be an object")
        requirement_routes = {}
    missing_reqs = sorted(REPORT_REQUIREMENT_IDS.difference(set(requirement_routes)))
    for req_id in missing_reqs:
        errors.append(f"missing review route for requirement: {req_id}")
    for req_id, route_id in sorted(requirement_routes.items()):
        if str(route_id) not in route_ids:
            errors.append(f"{req_id}: unknown review route id: {route_id}")

    return {
        "routes": len(raw_routes),
        "layers": sorted(layers),
        "missing_layers": missing_layers,
        "requirement_routes": len(requirement_routes),
        "missing_requirements": missing_reqs,
    }, errors


def validate_branch_health_dashboard_payload(
    repo_root: Path,
    dashboard: dict[str, object],
    routing_file: Path,
    policy: dict[str, object],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    if int(dashboard.get("schema_version", 0) or 0) != 1:
        errors.append("branch health dashboard schema_version must be 1")
    routing_rel = repo_path(routing_file.relative_to(repo_root))
    if str(dashboard.get("review_routing", "")) != routing_rel:
        errors.append(f"dashboard review_routing must be {routing_rel}")
    if str(dashboard.get("report_command", "")) != "python3 scripts/github_index_db.py branch-health-report":
        errors.append("dashboard report_command must call branch-health-report")
    if str(dashboard.get("audit_command", "")) != "python3 scripts/github_index_db.py branch-health-audit":
        errors.append("dashboard audit_command must call branch-health-audit")

    signals = {str(signal) for signal in dashboard.get("required_signals", [])}
    missing_signals = sorted(BRANCH_HEALTH_REQUIRED_SIGNALS.difference(signals))
    for signal in missing_signals:
        errors.append(f"dashboard missing required signal: {signal}")

    gates = {str(gate) for gate in dashboard.get("maintenance_gates", [])}
    missing_gates = sorted(BRANCH_HEALTH_REQUIRED_GATES.difference(gates))
    for gate in missing_gates:
        errors.append(f"dashboard missing maintenance gate: {gate}")

    traceability = policy.get("traceability", {})
    if isinstance(traceability, dict):
        if str(traceability.get("review_routing", "")) != routing_rel:
            errors.append("policy traceability.review_routing does not match dashboard")
        expected_dashboard = ".github/ai-env/contracts/agent-env-branch-health.json"
        if str(traceability.get("branch_health_dashboard", "")) != expected_dashboard:
            errors.append("policy traceability.branch_health_dashboard missing or mismatched")
    else:
        errors.append("policy traceability must be an object")

    branch_health = policy.get("branch_health", {})
    if isinstance(branch_health, dict):
        if str(branch_health.get("review_routing", "")) != routing_rel:
            errors.append("policy branch_health.review_routing does not match dashboard")
        if str(branch_health.get("dashboard", "")) != ".github/ai-env/contracts/agent-env-branch-health.json":
            errors.append("policy branch_health.dashboard missing or mismatched")
        if str(branch_health.get("report_command", "")) != "python3 scripts/github_index_db.py branch-health-report":
            errors.append("policy branch_health.report_command missing or mismatched")
        if str(branch_health.get("audit_command", "")) != "python3 scripts/github_index_db.py branch-health-audit":
            errors.append("policy branch_health.audit_command missing or mismatched")
    else:
        errors.append("policy branch_health must be an object")

    return {
        "required_signals": sorted(signals),
        "missing_signals": missing_signals,
        "maintenance_gates": sorted(gates),
        "missing_gates": missing_gates,
    }, errors


def branch_health_report(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    try:
        dashboard, dashboard_file, routing, routing_file = load_branch_health_contracts(
            repo_root,
            args.dashboard,
            args.review_routing,
        )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL branch-health-report: {exc}", file=sys.stderr)
        return 2

    branch_rc, branch, branch_err = git_capture(repo_root, ["rev-parse", "--abbrev-ref", "HEAD"])
    head_rc, head, head_err = git_capture(repo_root, ["rev-parse", "--short", "HEAD"])
    upstream_rc, upstream, upstream_err = git_capture(
        repo_root,
        ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"],
    )
    status_rc, status_text, status_err = git_capture(repo_root, ["status", "--porcelain=v1"])
    status_payload = parse_git_status_porcelain(status_text if status_rc == 0 else "", args.limit)
    matrix_counts = matrix_status_counts(repo_root, args.matrix)
    route_count = len(routing.get("review_routes", [])) if isinstance(routing.get("review_routes", []), list) else 0

    errors = []
    if branch_rc != 0:
        errors.append(f"git branch query failed: {branch_err}")
    if head_rc != 0:
        errors.append(f"git head query failed: {head_err}")
    if status_rc != 0:
        errors.append(f"git status query failed: {status_err}")

    payload = {
        "ok": not errors,
        "dashboard": repo_path(dashboard_file.relative_to(repo_root)),
        "review_routing": repo_path(routing_file.relative_to(repo_root)),
        "current_branch": branch if branch_rc == 0 else "<unknown>",
        "head_commit": head if head_rc == 0 else "<unknown>",
        "upstream": upstream if upstream_rc == 0 and upstream else "<none>",
        "upstream_error": upstream_err if upstream_rc != 0 else "",
        "git_status": status_payload,
        "review_routes": route_count,
        "matrix_status": matrix_counts,
        "maintenance_gates": dashboard.get("maintenance_gates", []),
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if payload["ok"] else "FAIL"
        counts = payload["git_status"]["counts"]  # type: ignore[index]
        matrix = ",".join(f"{key}={value}" for key, value in matrix_counts.items())
        print(
            f"{status} branch-health-report branch={payload['current_branch']} "
            f"head={payload['head_commit']} upstream={payload['upstream']} "
            f"staged={counts['staged']} unstaged={counts['unstaged']} untracked={counts['untracked']} "
            f"routes={route_count} matrix={matrix}"
        )
        samples = payload["git_status"]["samples"]  # type: ignore[index]
        for bucket in ("staged", "unstaged", "untracked"):
            items = samples[bucket]
            if items:
                print(f"[{bucket}]")
                for item in items[: args.limit]:
                    print(f"  {item}")
        if errors:
            print("[branch_health_errors]")
            for error in errors[: args.limit]:
                print(f"  {error}")
    return 0 if payload["ok"] else 1


def branch_health_audit(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    try:
        dashboard, dashboard_file, routing, routing_file = load_branch_health_contracts(
            repo_root,
            args.dashboard,
            args.review_routing,
        )
        policy, policy_file = load_policy(repo_root, args.policy)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL branch-health-audit: {exc}", file=sys.stderr)
        return 2

    routing_result, routing_errors = validate_review_routing_payload(repo_root, routing)
    dashboard_result, dashboard_errors = validate_branch_health_dashboard_payload(
        repo_root,
        dashboard,
        routing_file,
        policy,
    )
    maintain_path = repo_root / "scripts/agent-maintain.sh"
    maintain_text = maintain_path.read_text(encoding="utf-8") if maintain_path.is_file() else ""
    maintain_errors: list[str] = []
    for token in ("branch-health-report", "branch-health-audit"):
        if token not in maintain_text:
            maintain_errors.append(f"scripts/agent-maintain.sh missing {token}")

    errors = routing_errors + dashboard_errors + maintain_errors
    ok = not errors
    payload = {
        "ok": ok,
        "dashboard": repo_path(dashboard_file.relative_to(repo_root)),
        "review_routing": repo_path(routing_file.relative_to(repo_root)),
        "policy": repo_path(policy_file.relative_to(repo_root)),
        "routing": routing_result,
        "dashboard_contract": dashboard_result,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        print(
            f"{status} branch-health-audit dashboard={payload['dashboard']} "
            f"routes={routing_result.get('routes', 0)} "
            f"signals={len(dashboard_result.get('required_signals', []))} "
            f"gates={len(dashboard_result.get('maintenance_gates', []))}"
        )
        if errors:
            print("[branch_health_audit_errors]")
            for error in errors[: args.limit]:
                print(f"  {error}")
            if len(errors) > args.limit:
                print(f"  ... {len(errors) - args.limit} more")
    return 0 if ok else 1


def _string_set(value: object) -> set[str]:
    if not isinstance(value, list):
        return set()
    return {str(item) for item in value}


def _string_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value]


DELIVERY_SENSITIVE_MARKERS = (
    "/home/" + "lyg",
    "C:/Users/" + "17279",
    "\\Users\\" + "17279",
    "260" + "10035",
    "ysyx_" + "260" + "10035",
    "BEGIN " + "PRIVATE",
    "gh" + "p_",
    "AK" + "IA",
)


def validate_delivery_contract(
    repo_root: Path,
    contract: dict[str, object],
    contract_path: Path,
    policy: dict[str, object],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    contract_rel = repo_path(contract_path.relative_to(repo_root))
    if int(contract.get("schema_version", 0) or 0) != 1:
        errors.append("delivery contract schema_version must be 1")
    if str(contract.get("owner_layer", "")) != "agent":
        errors.append("delivery contract owner_layer must be agent")
    if str(contract.get("audit_command", "")) != "python3 scripts/github_index_db.py delivery-audit":
        errors.append("delivery contract audit_command must call delivery-audit")

    delivery_root = str(contract.get("delivery_root", "")).strip()
    package_script = str(contract.get("package_script", "")).strip()
    package_root = str(contract.get("package_root", "")).strip()
    archive_root = str(contract.get("archive_root", "")).strip()
    required_string_fields = {
        "delivery_root": delivery_root,
        "package_script": package_script,
        "package_root": package_root,
        "archive_root": archive_root,
    }
    for field, value in required_string_fields.items():
        if not value:
            errors.append(f"delivery contract missing {field}")

    if delivery_root and not (repo_root / delivery_root).is_dir():
        errors.append(f"delivery root missing: {delivery_root}")
    if package_script:
        script_path = repo_root / package_script
        if not script_path.is_file():
            errors.append(f"package script missing: {package_script}")
        else:
            script_text = script_path.read_text(encoding="utf-8")
            for token in ("PACKAGE_ROOT", "copy_file", "sanitize_package_text", "PACKAGE_FILELIST.txt", "ysyx-ai-dev-env-commercial"):
                if token not in script_text:
                    errors.append(f"package script missing token: {token}")
    if package_root and not (repo_root / package_root).is_dir():
        errors.append(f"package root missing: {package_root}")
    if archive_root and not (repo_root / archive_root).is_dir():
        errors.append(f"archive root missing: {archive_root}")

    active_legacy_roots = _string_list(contract.get("active_legacy_roots_must_be_absent", []))
    if not active_legacy_roots:
        errors.append("active_legacy_roots_must_be_absent must not be empty")
    for rel_path in active_legacy_roots:
        if (repo_root / rel_path).exists():
            errors.append(f"active legacy root still present: {rel_path}")

    archive_required_paths = _string_list(contract.get("archive_required_paths", []))
    if not archive_required_paths:
        errors.append("archive_required_paths must not be empty")
    for rel_path in archive_required_paths:
        if not (repo_root / rel_path).exists():
            errors.append(f"archive required path missing: {rel_path}")

    required_delivery_docs = _string_list(contract.get("required_delivery_docs", []))
    if not required_delivery_docs:
        errors.append("required_delivery_docs must not be empty")
    for rel_path in required_delivery_docs:
        if not (repo_root / rel_path).is_file():
            errors.append(f"delivery doc missing: {rel_path}")

    required_package_paths = _string_list(contract.get("required_package_paths", []))
    if not required_package_paths:
        errors.append("required_package_paths must not be empty")
    for rel_path in required_package_paths:
        if not (repo_root / rel_path).exists():
            errors.append(f"package required path missing: {rel_path}")

    package_file_count = 0
    filelist_entries: list[str] = []
    sensitive_hits: list[str] = []
    if package_root:
        package_root_path = repo_root / package_root
        filelist_path = package_root_path / "PACKAGE_FILELIST.txt"
        if filelist_path.is_file():
            filelist_entries = [line.strip() for line in filelist_path.read_text(encoding="utf-8").splitlines() if line.strip()]
            package_file_count = len(filelist_entries)
            if package_file_count < 80:
                errors.append(f"package filelist too small: {package_file_count}")
            absolute_entries = [entry for entry in filelist_entries if Path(entry).is_absolute()]
            for entry in absolute_entries[:10]:
                errors.append(f"package filelist contains absolute path: {entry}")
            for entry in (
                "README.md",
                "PACKAGING_MANIFEST.md",
                ".github/ai-env/contracts/agent-env-delivery.json",
                ".github/ai-env/contracts/agent-env-policy.json",
                "scripts/agent-maintain.sh",
                "scripts/github_index_db.py",
            ):
                if entry not in filelist_entries:
                    errors.append(f"package filelist missing entry: {entry}")
        else:
            errors.append("package filelist missing: PACKAGE_FILELIST.txt")

        if (package_root_path / ".github/e2e/modules/modules").exists():
            errors.append("package contains duplicated .github/e2e/modules/modules directory")
        if (package_root_path / ".github/e2e/profiles/profiles").exists():
            errors.append("package contains duplicated .github/e2e/profiles/profiles directory")

        if package_root_path.is_dir():
            marker_bytes = [(marker, marker.encode("utf-8")) for marker in DELIVERY_SENSITIVE_MARKERS]
            for item in sorted(package_root_path.rglob("*")):
                if not item.is_file():
                    continue
                try:
                    data = item.read_bytes()
                except OSError:
                    continue
                for marker, needle in marker_bytes:
                    if needle in data:
                        sensitive_hits.append(f"{repo_path(item.relative_to(package_root_path))}:{marker}")
                        break
            for hit in sensitive_hits[:10]:
                errors.append(f"package contains local/private marker: {hit}")

    policy_traceability = policy.get("traceability", {})
    if isinstance(policy_traceability, dict):
        if str(policy_traceability.get("delivery_contract", "")) != contract_rel:
            errors.append("policy traceability.delivery_contract missing or mismatched")
    else:
        errors.append("policy traceability must be an object")

    policy_delivery = policy.get("delivery", {})
    if isinstance(policy_delivery, dict):
        expected = {
            "contract": contract_rel,
            "audit_command": "python3 scripts/github_index_db.py delivery-audit",
            "delivery_root": delivery_root,
            "archive_root": archive_root,
            "package_script": package_script,
        }
        for key, value in expected.items():
            if str(policy_delivery.get(key, "")) != value:
                errors.append(f"policy delivery.{key} missing or mismatched")
    else:
        errors.append("policy delivery must be an object")

    return {
        "delivery_root": delivery_root,
        "package_root": package_root,
        "archive_root": archive_root,
        "active_legacy_roots": active_legacy_roots,
        "archive_required_paths": len(archive_required_paths),
        "delivery_docs": len(required_delivery_docs),
        "required_package_paths": len(required_package_paths),
        "package_file_count": package_file_count,
        "sensitive_hits": sensitive_hits,
    }, errors


def delivery_audit(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    try:
        contract, contract_path = load_policy(repo_root, args.contract)
        policy, policy_path = load_policy(repo_root, args.policy)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL delivery-audit: {exc}", file=sys.stderr)
        return 2

    contract_result, errors = validate_delivery_contract(repo_root, contract, contract_path, policy)
    ok = not errors
    payload = {
        "ok": ok,
        "contract": repo_path(contract_path.relative_to(repo_root)),
        "policy": repo_path(policy_path.relative_to(repo_root)),
        "contract_result": contract_result,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        print(
            f"{status} delivery-audit contract={payload['contract']} "
            f"delivery_root={contract_result.get('delivery_root', '<missing>')} "
            f"package_files={contract_result.get('package_file_count', 0)} "
            f"archive={contract_result.get('archive_root', '<missing>')}"
        )
        if errors:
            print("[delivery_audit_errors]")
            for error in errors[: args.limit]:
                print(f"  {error}")
            if len(errors) > args.limit:
                print(f"  ... {len(errors) - args.limit} more")
    return 0 if ok else 1


def read_live_or_stored_text(repo_root: Path, conn: sqlite3.Connection, rel_path: str) -> str:
    target = repo_root / rel_path
    content = ""
    if target.is_file():
        try:
            content = target.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            content = ""
        if content and not is_db_backed_shim(rel_path, content):
            return content
    row = conn.execute("SELECT content FROM db_documents WHERE path = ?", (rel_path,)).fetchone()
    if row is not None:
        return row["content"] or ""
    return content


def validate_runtime_artifact_contract(
    repo_root: Path,
    conn: sqlite3.Connection,
    contract: dict[str, object],
    contract_path: Path,
    policy: dict[str, object],
    schema_contract: dict[str, object],
    observability_contract: dict[str, object],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    contract_rel = repo_path(contract_path.relative_to(repo_root))
    if int(contract.get("schema_version", 0) or 0) != 1:
        errors.append("runtime artifact contract schema_version must be 1")
    if str(contract.get("owner_layer", "")) != "database":
        errors.append("runtime artifact contract owner_layer must be database")
    if str(contract.get("audit_command", "")) != "python3 scripts/github_index_db.py artifact-audit":
        errors.append("runtime artifact contract audit_command must call artifact-audit")

    artifact_store = contract.get("artifact_store", {})
    if not isinstance(artifact_store, dict):
        errors.append("artifact_store must be an object")
        artifact_store = {}
    local_root = str(artifact_store.get("local_root", ""))
    if local_root != ".github/runtime-artifacts":
        errors.append("artifact_store.local_root must be .github/runtime-artifacts")
    elif not (repo_root / local_root).is_dir():
        errors.append(f"artifact store root missing: {local_root}")
    if not bool(artifact_store.get("gitignore_required", False)):
        errors.append("artifact_store.gitignore_required must be true")
    pointer_formats = _string_set(artifact_store.get("pointer_formats", []))
    for pointer in ("run-manifest.json", "evidence-index.md", "evidence_assets"):
        if pointer not in pointer_formats:
            errors.append(f"artifact_store.pointer_formats missing: {pointer}")

    runtime_roots = _string_set(contract.get("runtime_payload_roots", []))
    for root in (".github/task-runs/*/evidence", ".github/runtime-artifacts"):
        if root not in runtime_roots:
            errors.append(f"runtime_payload_roots missing: {root}")

    retention = contract.get("retention", {})
    if not isinstance(retention, dict):
        errors.append("retention must be an object")
        retention = {}
    max_tracked = 0
    try:
        max_tracked = int(retention.get("max_tracked_evidence_bytes", 0) or 0)
    except (TypeError, ValueError):
        max_tracked = 0
    if bool(retention.get("raw_evidence_fulltext_in_db", True)):
        errors.append("retention.raw_evidence_fulltext_in_db must be false")
    if str(retention.get("raw_evidence_index_table", "")) != "evidence_assets":
        errors.append("retention.raw_evidence_index_table must be evidence_assets")
    if not bool(retention.get("raw_evidence_index_required", False)):
        errors.append("retention.raw_evidence_index_required must be true")
    if not bool(retention.get("large_artifacts_externalized", False)):
        errors.append("retention.large_artifacts_externalized must be true")
    if not bool(retention.get("waveform_artifacts_externalized", False)):
        errors.append("retention.waveform_artifacts_externalized must be true")
    if max_tracked <= 0:
        errors.append("retention.max_tracked_evidence_bytes must be positive")

    gitignore_path = repo_root / ".gitignore"
    gitignore_lines: set[str] = set()
    if gitignore_path.is_file():
        gitignore_lines = {
            line.strip()
            for line in gitignore_path.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        }
    else:
        errors.append(".gitignore missing")
    required_ignore_patterns = [str(pattern) for pattern in contract.get("ignore_patterns_required", [])]
    for pattern in required_ignore_patterns:
        if pattern not in gitignore_lines:
            errors.append(f".gitignore missing runtime artifact pattern: {pattern}")

    report_hooks = _string_set(contract.get("report_hooks", []))
    report_sh = repo_root / "scripts/e2e/lib/report.sh"
    report_text = report_sh.read_text(encoding="utf-8") if report_sh.is_file() else ""
    for hook in ("e2e_index_task_run_evidence_assets", "raw_evidence_index_only", "run-manifest.json", "archive-markdown"):
        if hook not in report_hooks:
            errors.append(f"runtime artifact contract report_hooks missing: {hook}")
        if hook not in report_text:
            errors.append(f"report.sh missing runtime artifact hook: {hook}")

    maintenance = contract.get("maintenance", {})
    if not isinstance(maintenance, dict):
        errors.append("maintenance must be an object")
        maintenance = {}
    required_gates = _string_set(maintenance.get("required_gates", []))
    if "artifact-audit" not in required_gates:
        errors.append("maintenance.required_gates missing artifact-audit")
    required_nodes = _string_set(maintenance.get("required_profile_nodes", []))
    if "runtime-artifact-boundary" not in required_nodes:
        errors.append("maintenance.required_profile_nodes missing runtime-artifact-boundary")

    maintain_path = repo_root / "scripts/agent-maintain.sh"
    maintain_text = maintain_path.read_text(encoding="utf-8") if maintain_path.is_file() else ""
    if "artifact-audit" not in maintain_text:
        errors.append("scripts/agent-maintain.sh missing artifact-audit")
    profile_text = read_live_or_stored_text(
        repo_root,
        conn,
        ".github/e2e/profiles/agent-system.tsv",
    )
    if "runtime-artifact-boundary" not in profile_text:
        errors.append("agent-system profile missing runtime-artifact-boundary node")

    policy_traceability = policy.get("traceability", {})
    if isinstance(policy_traceability, dict):
        if str(policy_traceability.get("runtime_artifact_contract", "")) != contract_rel:
            errors.append("policy traceability.runtime_artifact_contract missing or mismatched")
    else:
        errors.append("policy traceability must be an object")
    policy_retention = policy.get("retention", {})
    if isinstance(policy_retention, dict):
        if str(policy_retention.get("runtime_artifact_contract", "")) != contract_rel:
            errors.append("policy retention.runtime_artifact_contract missing or mismatched")
        if bool(policy_retention.get("raw_evidence_fulltext_in_db", True)):
            errors.append("policy retention.raw_evidence_fulltext_in_db must be false")
        if not bool(policy_retention.get("raw_evidence_index_required", False)):
            errors.append("policy retention.raw_evidence_index_required must be true")
        if not bool(policy_retention.get("runtime_artifact_store_required", False)):
            errors.append("policy retention.runtime_artifact_store_required must be true")
        if not bool(policy_retention.get("large_runtime_artifacts_externalized", False)):
            errors.append("policy retention.large_runtime_artifacts_externalized must be true")
        if not bool(policy_retention.get("waveform_artifacts_externalized", False)):
            errors.append("policy retention.waveform_artifacts_externalized must be true")
    else:
        errors.append("policy retention must be an object")

    policy_runtime = policy.get("runtime_artifacts", {})
    if isinstance(policy_runtime, dict):
        if str(policy_runtime.get("contract", "")) != contract_rel:
            errors.append("policy runtime_artifacts.contract missing or mismatched")
        if str(policy_runtime.get("audit_command", "")) != "python3 scripts/github_index_db.py artifact-audit":
            errors.append("policy runtime_artifacts.audit_command missing or mismatched")
        if str(policy_runtime.get("raw_evidence_policy", "")) != "index-only":
            errors.append("policy runtime_artifacts.raw_evidence_policy must be index-only")
        if str(policy_runtime.get("artifact_store_root", "")) != ".github/runtime-artifacts":
            errors.append("policy runtime_artifacts.artifact_store_root missing or mismatched")
    else:
        errors.append("policy runtime_artifacts must be an object")

    database_layer = policy.get("layers", {}).get("database", {}) if isinstance(policy.get("layers", {}), dict) else {}
    if isinstance(database_layer, dict):
        if str(database_layer.get("raw_evidence_policy", "")) != "index-only":
            errors.append("policy layers.database.raw_evidence_policy must be index-only")
        artifact_roots = _string_set(database_layer.get("artifact_store_roots", []))
        for root in (".github/runtime-artifacts", ".github/task-runs/*/evidence"):
            if root not in artifact_roots:
                errors.append(f"policy layers.database.artifact_store_roots missing: {root}")
    else:
        errors.append("policy layers.database must be an object")

    schema_retention = schema_contract.get("retention", {})
    if isinstance(schema_retention, dict):
        if str(schema_retention.get("runtime_artifact_contract", "")) != contract_rel:
            errors.append("schema retention.runtime_artifact_contract missing or mismatched")
        if str(schema_retention.get("raw_evidence_index_table", "")) != "evidence_assets":
            errors.append("schema retention.raw_evidence_index_table must be evidence_assets")
        if bool(schema_retention.get("raw_evidence_fulltext_in_db", True)):
            errors.append("schema retention.raw_evidence_fulltext_in_db must be false")
    else:
        errors.append("schema retention must be an object")

    db_mapping = observability_contract.get("database_mapping", {})
    if isinstance(db_mapping, dict):
        if str(db_mapping.get("raw_evidence_table", "")) != "evidence_assets":
            errors.append("observability database_mapping.raw_evidence_table must be evidence_assets")
        if str(db_mapping.get("runtime_artifact_contract", "")) != contract_rel:
            errors.append("observability database_mapping.runtime_artifact_contract missing or mismatched")
        if str(db_mapping.get("runtime_artifact_store", "")) != ".github/runtime-artifacts":
            errors.append("observability database_mapping.runtime_artifact_store missing or mismatched")
    else:
        errors.append("observability database_mapping must be an object")

    raw_document_rows = conn.execute(
        """
        SELECT path
        FROM db_documents
        WHERE path LIKE '.github/task-runs/%/evidence/%'
           OR path LIKE '.github/runtime-artifacts/%'
        ORDER BY path
        LIMIT 20
        """
    ).fetchall()
    if raw_document_rows:
        errors.extend(f"raw runtime payload stored as db_document: {row['path']}" for row in raw_document_rows)

    tracked_errors: list[str] = []
    tracked_runtime_files = 0
    tracked_heavy_files = 0
    heavy_suffixes = {suffix.lower() for suffix in _string_set(contract.get("heavy_artifact_suffixes", []))}
    git_rc, git_out, git_err = git_capture(
        repo_root,
        ["ls-files", "--", ".github/task-runs", ".github/runtime-artifacts"],
    )
    if git_rc != 0:
        errors.append(f"git ls-files for runtime artifacts failed: {git_err}")
    else:
        for rel_path in [line.strip() for line in git_out.splitlines() if line.strip()]:
            if rel_path.startswith(".github/runtime-artifacts/"):
                if rel_path != ".github/runtime-artifacts/.gitkeep":
                    tracked_errors.append(f"runtime artifact store payload is tracked: {rel_path}")
                tracked_runtime_files += 1
            if "/evidence/" in rel_path:
                tracked_runtime_files += 1
                path = repo_root / rel_path
                suffix = Path(rel_path).suffix.lower()
                if suffix in heavy_suffixes:
                    tracked_heavy_files += 1
                    tracked_errors.append(f"heavy task-run evidence payload is tracked: {rel_path}")
                if max_tracked > 0 and path.is_file() and path.stat().st_size > max_tracked:
                    tracked_errors.append(
                        f"task-run evidence exceeds tracked size limit ({max_tracked} bytes): {rel_path}"
                    )
    errors.extend(tracked_errors)

    asset_rows = conn.execute("SELECT COUNT(*) AS c FROM evidence_assets").fetchone()["c"]
    return {
        "runtime_payload_roots": sorted(runtime_roots),
        "ignore_patterns": len(required_ignore_patterns),
        "db_evidence_assets": int(asset_rows),
        "db_raw_documents": len(raw_document_rows),
        "tracked_runtime_files": tracked_runtime_files,
        "tracked_heavy_files": tracked_heavy_files,
        "max_tracked_evidence_bytes": max_tracked,
    }, errors


def validate_runtime_artifact_run(
    repo_root: Path,
    conn: sqlite3.Connection,
    run_id: str,
    manifest: dict[str, object],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    db_policy = manifest.get("db", {})
    if not isinstance(db_policy, dict):
        errors.append("run manifest db must be an object")
        db_policy = {}
    if not bool(db_policy.get("raw_evidence_index_only", False)):
        errors.append("run manifest db.raw_evidence_index_only must be true")

    artifacts = manifest.get("artifacts", {})
    evidence_dir = ""
    if isinstance(artifacts, dict):
        evidence_dir = str(artifacts.get("evidence_dir", ""))
        if not evidence_dir:
            errors.append("run manifest artifacts.evidence_dir missing")
        elif not (repo_root / evidence_dir).is_dir():
            errors.append(f"run manifest evidence_dir missing: {evidence_dir}")
    else:
        errors.append("run manifest artifacts must be an object")

    evidence = manifest.get("evidence", {})
    expected_assets = 0
    total_size = 0
    if isinstance(evidence, dict):
        try:
            expected_assets = int(evidence.get("asset_count", 0) or 0)
        except (TypeError, ValueError):
            expected_assets = 0
        try:
            total_size = int(evidence.get("total_size_bytes", 0) or 0)
        except (TypeError, ValueError):
            total_size = 0
        if expected_assets <= 0:
            errors.append("run manifest evidence.asset_count must be positive")
    else:
        errors.append("run manifest evidence must be an object")

    asset_count = conn.execute(
        "SELECT COUNT(*) AS c FROM evidence_assets WHERE run_id = ?",
        (run_id,),
    ).fetchone()["c"]
    if int(asset_count) < expected_assets:
        errors.append(
            f"evidence_assets rows for run {run_id} below manifest asset_count: {asset_count} < {expected_assets}"
        )
    raw_doc_count = conn.execute(
        """
        SELECT COUNT(*) AS c
        FROM db_documents
        WHERE path LIKE ?
        """,
        (f".github/task-runs/{run_id}/evidence/%",),
    ).fetchone()["c"]
    if int(raw_doc_count) != 0:
        errors.append(f"run raw evidence stored in db_documents: {raw_doc_count}")

    return {
        "run_id": run_id,
        "manifest_asset_count": expected_assets,
        "db_evidence_assets": int(asset_count),
        "raw_db_documents": int(raw_doc_count),
        "total_size_bytes": total_size,
    }, errors


def artifact_audit(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    try:
        contract, contract_path = load_policy(repo_root, args.contract)
        policy, policy_path = load_policy(repo_root, args.policy)
        schema_contract, schema_path = load_policy(repo_root, args.schema_contract)
        observability_contract, observability_path = load_policy(repo_root, args.observability_contract)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL artifact-audit: {exc}", file=sys.stderr)
        return 2

    conn = open_db(db_path, readonly=True)
    try:
        contract_result, errors = validate_runtime_artifact_contract(
            repo_root,
            conn,
            contract,
            contract_path,
            policy,
            schema_contract,
            observability_contract,
        )
        run_result: dict[str, object] = {}
        run_id = str(args.run_id or "").strip()
        if not run_id and args.latest:
            run_id = latest_run_manifest_id(repo_root)
        if run_id:
            try:
                manifest, _manifest_path = load_run_manifest(repo_root, run_id)
                run_result, run_errors = validate_runtime_artifact_run(repo_root, conn, run_id, manifest)
            except (OSError, ValueError, json.JSONDecodeError) as exc:
                run_errors = [str(exc)]
            errors.extend(run_errors)
    finally:
        conn.close()

    ok = not errors
    payload = {
        "ok": ok,
        "contract": repo_path(contract_path.relative_to(repo_root)),
        "policy": repo_path(policy_path.relative_to(repo_root)),
        "schema_contract": repo_path(schema_path.relative_to(repo_root)),
        "observability_contract": repo_path(observability_path.relative_to(repo_root)),
        "contract_result": contract_result,
        "run": run_result,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        run_text = ""
        if run_result:
            run_text = (
                f" run={run_result.get('run_id')} "
                f"manifest_assets={run_result.get('manifest_asset_count')} "
                f"db_assets={run_result.get('db_evidence_assets')}"
            )
        print(
            f"{status} artifact-audit contract={payload['contract']} "
            f"roots={len(contract_result.get('runtime_payload_roots', []))} "
            f"ignore_patterns={contract_result.get('ignore_patterns', 0)} "
            f"tracked_runtime_files={contract_result.get('tracked_runtime_files', 0)} "
            f"tracked_heavy_files={contract_result.get('tracked_heavy_files', 0)}{run_text}"
        )
        if errors:
            print("[artifact_audit_errors]")
            for error in errors[: args.limit]:
                print(f"  {error}")
            if len(errors) > args.limit:
                print(f"  ... {len(errors) - args.limit} more")
    return 0 if ok else 1


def load_run_manifest(repo_root: Path, run_id: str) -> tuple[dict[str, object], Path]:
    manifest_path = repo_root / ".github" / "task-runs" / run_id / "run-manifest.json"
    ensure_inside_root(repo_root, manifest_path.resolve())
    with manifest_path.open("r", encoding="utf-8") as fh:
        manifest = json.load(fh)
    if not isinstance(manifest, dict):
        raise ValueError("run manifest root must be a JSON object")
    return manifest, manifest_path


def latest_run_manifest_id(repo_root: Path) -> str:
    run_root = repo_root / ".github" / "task-runs"
    if not run_root.is_dir():
        return ""
    manifests = sorted(run_root.glob("*/run-manifest.json"), reverse=True)
    return manifests[0].parent.name if manifests else ""


def validate_observability_contract(
    repo_root: Path,
    contract: dict[str, object],
    contract_path: Path,
    policy: dict[str, object],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    if int(contract.get("schema_version", 0) or 0) != 1:
        errors.append("observability contract schema_version must be 1")
    if str(contract.get("trace_id_format", "")) != "e2e:<run_id>":
        errors.append("trace_id_format must be e2e:<run_id>")
    if str(contract.get("run_manifest_path", "")) != ".github/task-runs/<run_id>/run-manifest.json":
        errors.append("run_manifest_path must be .github/task-runs/<run_id>/run-manifest.json")
    if str(contract.get("generated_by", "")) != "scripts/e2e/lib/report.sh":
        errors.append("generated_by must be scripts/e2e/lib/report.sh")

    signals = {str(signal) for signal in contract.get("required_manifest_fields", [])}
    missing_signals = sorted(OBSERVABILITY_REQUIRED_SIGNALS.difference(signals))
    for signal in missing_signals:
        errors.append(f"observability contract missing manifest field: {signal}")

    db_mapping = contract.get("database_mapping", {})
    if isinstance(db_mapping, dict):
        if str(db_mapping.get("raw_evidence_table", "")) != "evidence_assets":
            errors.append("database_mapping.raw_evidence_table must be evidence_assets")
        if "run-manifest.json" not in str(db_mapping.get("run_manifest_index", "")):
            errors.append("database_mapping.run_manifest_index must mention run-manifest.json")
    else:
        errors.append("database_mapping must be an object")

    traceability = policy.get("traceability", {})
    if isinstance(traceability, dict):
        expected_contract = repo_path(contract_path.relative_to(repo_root))
        if str(traceability.get("observability_contract", "")) != expected_contract:
            errors.append("policy traceability.observability_contract missing or mismatched")
    else:
        errors.append("policy traceability must be an object")

    observability = policy.get("observability", {})
    if isinstance(observability, dict):
        if not bool(observability.get("run_manifest_required", False)):
            errors.append("policy observability.run_manifest_required must be true")
        if not bool(observability.get("trace_id_required", False)):
            errors.append("policy observability.trace_id_required must be true")
    else:
        errors.append("policy observability must be an object")

    report_sh = repo_root / "scripts/e2e/lib/report.sh"
    report_text = report_sh.read_text(encoding="utf-8") if report_sh.is_file() else ""
    for token in ("E2E_RUN_MANIFEST_FILE", "e2e_render_run_manifest", "trace_id", "run-manifest.json"):
        if token not in report_text:
            errors.append(f"report.sh missing {token}")

    maintain_sh = repo_root / "scripts/agent-maintain.sh"
    maintain_text = maintain_sh.read_text(encoding="utf-8") if maintain_sh.is_file() else ""
    if "trace-audit" not in maintain_text:
        errors.append("scripts/agent-maintain.sh missing trace-audit")

    return {
        "required_manifest_fields": sorted(signals),
        "missing_manifest_fields": missing_signals,
    }, errors


def validate_run_manifest_payload(
    repo_root: Path,
    conn: sqlite3.Connection,
    run_id: str,
    manifest: dict[str, object],
    manifest_path: Path,
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    if int(manifest.get("schema_version", 0) or 0) != 1:
        errors.append("run manifest schema_version must be 1")
    if str(manifest.get("run_id", "")) != run_id:
        errors.append(f"run manifest run_id mismatch: expected {run_id}")
    if str(manifest.get("trace_id", "")) != f"e2e:{run_id}":
        errors.append(f"run manifest trace_id must be e2e:{run_id}")
    for field in sorted(OBSERVABILITY_REQUIRED_SIGNALS):
        if field not in manifest:
            errors.append(f"run manifest missing field: {field}")

    artifacts = manifest.get("artifacts", {})
    artifact_count = 0
    if isinstance(artifacts, dict):
        for name, raw_path in sorted(artifacts.items()):
            path = str(raw_path)
            if path and not (repo_root / path).exists():
                errors.append(f"run manifest artifact missing: {name}={path}")
            if path:
                artifact_count += 1
    else:
        errors.append("run manifest artifacts must be an object")

    node_counts = manifest.get("node_counts", {})
    total_nodes = 0
    if isinstance(node_counts, dict):
        try:
            total_nodes = int(node_counts.get("total", 0) or 0)
        except (TypeError, ValueError):
            total_nodes = 0
        if total_nodes <= 0:
            errors.append("run manifest node_counts.total must be positive")
    else:
        errors.append("run manifest node_counts must be an object")

    manifest_rel = repo_path(manifest_path.relative_to(repo_root))
    row = conn.execute(
        "SELECT path, kind, markers FROM evidence_assets WHERE path = ?",
        (manifest_rel,),
    ).fetchone()
    if row is None:
        errors.append(f"run manifest not indexed in evidence_assets: {manifest_rel}")
    elif row["kind"] != "json":
        errors.append(f"run manifest evidence kind must be json, got {row['kind']}")

    db_asset_count = conn.execute(
        "SELECT COUNT(*) AS c FROM evidence_assets WHERE run_id = ?",
        (run_id,),
    ).fetchone()["c"]
    if db_asset_count <= 0:
        errors.append(f"no evidence assets indexed for run: {run_id}")

    return {
        "run_id": run_id,
        "trace_id": str(manifest.get("trace_id", "")),
        "profile": str(manifest.get("profile", "")),
        "status": str(manifest.get("status", "")),
        "artifacts": artifact_count,
        "nodes": total_nodes,
        "evidence_assets": int(db_asset_count),
    }, errors


def trace_audit(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    try:
        contract, contract_path = load_policy(repo_root, args.contract)
        policy, policy_path = load_policy(repo_root, args.policy)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL trace-audit: {exc}", file=sys.stderr)
        return 2

    contract_result, errors = validate_observability_contract(repo_root, contract, contract_path, policy)
    run_result: dict[str, object] = {}
    run_id = str(args.run_id or "").strip()
    if not run_id and args.latest:
        run_id = latest_run_manifest_id(repo_root)
    if run_id:
        conn = open_db(db_path, readonly=True)
        try:
            manifest, manifest_path = load_run_manifest(repo_root, run_id)
            run_result, run_errors = validate_run_manifest_payload(repo_root, conn, run_id, manifest, manifest_path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            run_errors = [str(exc)]
        finally:
            conn.close()
        errors.extend(run_errors)

    ok = not errors
    payload = {
        "ok": ok,
        "contract": repo_path(contract_path.relative_to(repo_root)),
        "policy": repo_path(policy_path.relative_to(repo_root)),
        "contract_result": contract_result,
        "run": run_result,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        run_text = ""
        if run_result:
            run_text = (
                f" run={run_result.get('run_id')} trace={run_result.get('trace_id')} "
                f"nodes={run_result.get('nodes')} evidence_assets={run_result.get('evidence_assets')}"
            )
        print(
            f"{status} trace-audit contract={payload['contract']} "
            f"fields={len(contract_result.get('required_manifest_fields', []))}{run_text}"
        )
        if errors:
            print("[trace_audit_errors]")
            for error in errors[: args.limit]:
                print(f"  {error}")
            if len(errors) > args.limit:
                print(f"  ... {len(errors) - args.limit} more")
    return 0 if ok else 1


def read_repo_or_stored_text(repo_root: Path, conn: sqlite3.Connection, path: str) -> str:
    rel_path = normalize_index_path(path)
    target = repo_root / rel_path
    content = ""
    if target.is_file():
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
    return content


def validate_state_traceability_contract(
    repo_root: Path,
    conn: sqlite3.Connection,
    contract: dict[str, object],
    contract_path: Path,
    policy: dict[str, object],
    routing: dict[str, object],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    if int(contract.get("schema_version", 0) or 0) != 1:
        errors.append("state traceability contract schema_version must be 1")
    if str(contract.get("state_machine_doc", "")) != ".github/instructions/agent-env-state-machine.instructions.md":
        errors.append("state_machine_doc must be .github/instructions/agent-env-state-machine.instructions.md")
    if str(contract.get("profile", "")) != ".github/e2e/profiles/agent-system.tsv":
        errors.append("profile must be .github/e2e/profiles/agent-system.tsv")
    if str(contract.get("audit_command", "")) != "python3 scripts/github_index_db.py state-audit":
        errors.append("audit_command must call state-audit")

    states = {str(state) for state in contract.get("required_states", [])}
    missing_states = sorted(STATE_TRACEABILITY_REQUIRED_STATES.difference(states))
    for state in missing_states:
        errors.append(f"state traceability contract missing state: {state}")

    traceback_fields = {str(field) for field in contract.get("required_traceback_fields", [])}
    missing_fields = sorted(STATE_TRACEBACK_REQUIRED_FIELDS.difference(traceback_fields))
    for field in missing_fields:
        errors.append(f"state traceability contract missing traceback field: {field}")

    node_map: dict[str, str] = {}
    raw_nodes = contract.get("reviewer_inspector_nodes", [])
    if isinstance(raw_nodes, list):
        for idx, raw_node in enumerate(raw_nodes):
            if not isinstance(raw_node, dict):
                errors.append(f"reviewer_inspector_nodes[{idx}] must be an object")
                continue
            node_id = str(raw_node.get("node_id", "")).strip()
            function = str(raw_node.get("function", "")).strip()
            if node_id:
                node_map[node_id] = function
    else:
        errors.append("reviewer_inspector_nodes must be an array")
    for node_id, function in sorted(STATE_REVIEWER_INSPECTOR_NODES.items()):
        if node_map.get(node_id) != function:
            errors.append(f"reviewer/inspector node missing or mismatched: {node_id}->{function}")

    traceability = policy.get("traceability", {})
    if isinstance(traceability, dict):
        expected_contract = repo_path(contract_path.relative_to(repo_root))
        if str(traceability.get("state_traceability_contract", "")) != expected_contract:
            errors.append("policy traceability.state_traceability_contract missing or mismatched")
    else:
        errors.append("policy traceability must be an object")

    state_machine = policy.get("state_machine", {})
    if isinstance(state_machine, dict):
        if str(state_machine.get("contract", "")) != ".github/ai-env/contracts/agent-env-state-traceability.json":
            errors.append("policy state_machine.contract missing or mismatched")
        if str(state_machine.get("audit_command", "")) != "python3 scripts/github_index_db.py state-audit":
            errors.append("policy state_machine.audit_command missing or mismatched")
        if not bool(state_machine.get("traceback_required", False)):
            errors.append("policy state_machine.traceback_required must be true")
        policy_states = {str(state) for state in state_machine.get("states", [])}
        for state in sorted(STATE_TRACEABILITY_REQUIRED_STATES.difference(policy_states)):
            errors.append(f"policy state_machine missing state: {state}")
        if str(state_machine.get("inspector", "")) != "agent-system":
            errors.append("policy state_machine.inspector must be agent-system")
        if str(state_machine.get("coordinator", "")) != "ysyx-coordinator":
            errors.append("policy state_machine.coordinator must be ysyx-coordinator")
        profile_nodes = {str(node) for node in state_machine.get("reviewer_profile_nodes", [])}
        for node_id in sorted(STATE_REVIEWER_INSPECTOR_NODES):
            if node_id not in profile_nodes:
                errors.append(f"policy state_machine missing reviewer profile node: {node_id}")
    else:
        errors.append("policy state_machine must be an object")

    requirement_routes = routing.get("requirement_routes", {})
    if isinstance(requirement_routes, dict):
        if str(requirement_routes.get("R7", "")) != "agent-layer":
            errors.append("review routing must map R7 to agent-layer")
    else:
        errors.append("review routing requirement_routes must be an object")
    agent_route = None
    for raw_route in routing.get("review_routes", []):
        if isinstance(raw_route, dict) and str(raw_route.get("id", "")) == "agent-layer":
            agent_route = raw_route
            break
    if not isinstance(agent_route, dict):
        errors.append("review routing missing agent-layer route")
        agent_route = {}
    if str(agent_route.get("primary_agent", "")) != "ysyx-coordinator":
        errors.append("agent-layer primary_agent must be ysyx-coordinator")
    if str(agent_route.get("inspector", "")) != "agent-system":
        errors.append("agent-layer inspector must be agent-system")
    agent_checks = {str(check) for check in agent_route.get("required_checks", [])}
    if "state-audit" not in agent_checks:
        errors.append("agent-layer required_checks missing state-audit")

    state_doc = read_repo_or_stored_text(
        repo_root,
        conn,
        ".github/instructions/agent-env-state-machine.instructions.md",
    )
    for token in sorted(STATE_TRACEABILITY_REQUIRED_STATES):
        if token not in state_doc:
            errors.append(f"state machine instruction missing state: {token}")
    for token in ("state_traceback", "state-machine-traceback", "reviewer-inspector-gate"):
        if token not in state_doc:
            errors.append(f"state machine instruction missing {token}")

    profile_text = read_repo_or_stored_text(
        repo_root,
        conn,
        ".github/e2e/profiles/agent-system.tsv",
    )
    for node_id, function in sorted(STATE_REVIEWER_INSPECTOR_NODES.items()):
        if f"{node_id}|agent-system|{function}|agent-system|" not in profile_text:
            errors.append(f"agent-system profile missing node: {node_id}")

    report_sh = repo_root / "scripts/e2e/lib/report.sh"
    report_text = report_sh.read_text(encoding="utf-8") if report_sh.is_file() else ""
    for token in ("state_traceback", "failure_state", "rollback_target", "state_sequence"):
        if token not in report_text:
            errors.append(f"report.sh missing {token}")

    agent_system_sh = repo_root / "scripts/e2e/modules/agent_system.sh"
    agent_system_text = agent_system_sh.read_text(encoding="utf-8") if agent_system_sh.is_file() else ""
    for function in sorted(STATE_REVIEWER_INSPECTOR_NODES.values()):
        if function not in agent_system_text:
            errors.append(f"agent_system.sh missing {function}")

    maintain_sh = repo_root / "scripts/agent-maintain.sh"
    maintain_text = maintain_sh.read_text(encoding="utf-8") if maintain_sh.is_file() else ""
    if "state-audit" not in maintain_text:
        errors.append("scripts/agent-maintain.sh missing state-audit")

    return {
        "states": sorted(states),
        "missing_states": missing_states,
        "traceback_fields": sorted(traceback_fields),
        "missing_traceback_fields": missing_fields,
        "reviewer_inspector_nodes": dict(sorted(node_map.items())),
    }, errors


def validate_state_traceback_payload(
    repo_root: Path,
    conn: sqlite3.Connection,
    run_id: str,
    manifest: dict[str, object],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    traceback = manifest.get("state_traceback", {})
    if not isinstance(traceback, dict):
        return {"run_id": run_id}, ["run manifest state_traceback must be an object"]

    for field in sorted(STATE_TRACEBACK_REQUIRED_FIELDS):
        if field not in traceback:
            errors.append(f"run manifest state_traceback missing field: {field}")
    sequence = [str(state) for state in traceback.get("state_sequence", [])] if isinstance(traceback.get("state_sequence", []), list) else []
    for state in sorted(STATE_TRACEABILITY_REQUIRED_STATES.difference(set(sequence))):
        errors.append(f"run manifest state_traceback.state_sequence missing state: {state}")
    current_state = str(traceback.get("current_state", ""))
    if current_state not in STATE_TRACEABILITY_REQUIRED_STATES:
        errors.append(f"run manifest state_traceback.current_state invalid: {current_state}")
    if str(traceback.get("reviewer", "")) != "ysyx-coordinator":
        errors.append("run manifest state_traceback.reviewer must be ysyx-coordinator")
    if str(traceback.get("inspector", "")) != "agent-system":
        errors.append("run manifest state_traceback.inspector must be agent-system")

    status = str(manifest.get("status", ""))
    if status == "completed" and current_state != "persist":
        errors.append("completed run state_traceback.current_state must be persist")
    if status != "completed":
        if not str(traceback.get("failure_state", "")):
            errors.append("non-completed run state_traceback.failure_state must be set")
        if not str(traceback.get("rollback_target", "")):
            errors.append("non-completed run state_traceback.rollback_target must be set")

    report_fields = task_run_report_fields(repo_root, conn, run_id)
    for field in sorted(STATE_TRACEBACK_REQUIRED_FIELDS):
        if field not in report_fields:
            errors.append(f"task report missing state traceback field: {field}")
    if report_fields.get("current_state") and report_fields.get("current_state") != current_state:
        errors.append("task report current_state does not match run manifest")

    return {
        "run_id": run_id,
        "current_state": current_state,
        "reviewer": str(traceback.get("reviewer", "")),
        "inspector": str(traceback.get("inspector", "")),
        "traceback_fields": len([field for field in STATE_TRACEBACK_REQUIRED_FIELDS if field in traceback]),
    }, errors


def state_audit(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    try:
        contract, contract_path = load_policy(repo_root, args.contract)
        policy, policy_path = load_policy(repo_root, args.policy)
        routing, routing_path = load_policy(repo_root, args.review_routing)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL state-audit: {exc}", file=sys.stderr)
        return 2

    conn = open_db(db_path, readonly=True)
    try:
        contract_result, errors = validate_state_traceability_contract(
            repo_root,
            conn,
            contract,
            contract_path,
            policy,
            routing,
        )
        run_result: dict[str, object] = {}
        run_id = str(args.run_id or "").strip()
        if not run_id and args.latest:
            run_id = latest_run_manifest_id(repo_root)
        if run_id:
            try:
                manifest, _manifest_path = load_run_manifest(repo_root, run_id)
                run_result, run_errors = validate_state_traceback_payload(
                    repo_root,
                    conn,
                    run_id,
                    manifest,
                )
            except (OSError, ValueError, json.JSONDecodeError) as exc:
                run_errors = [str(exc)]
            errors.extend(run_errors)
    finally:
        conn.close()

    ok = not errors
    payload = {
        "ok": ok,
        "contract": repo_path(contract_path.relative_to(repo_root)),
        "policy": repo_path(policy_path.relative_to(repo_root)),
        "review_routing": repo_path(routing_path.relative_to(repo_root)),
        "contract_result": contract_result,
        "run": run_result,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        status = "PASS" if ok else "FAIL"
        run_text = ""
        if run_result:
            run_text = (
                f" run={run_result.get('run_id')} current_state={run_result.get('current_state')} "
                f"reviewer={run_result.get('reviewer')} inspector={run_result.get('inspector')}"
            )
        print(
            f"{status} state-audit contract={payload['contract']} "
            f"states={len(contract_result.get('states', []))} "
            f"nodes={len(contract_result.get('reviewer_inspector_nodes', {}))}{run_text}"
        )
        if errors:
            print("[state_audit_errors]")
            for error in errors[: args.limit]:
                print(f"  {error}")
            if len(errors) > args.limit:
                print(f"  ... {len(errors) - args.limit} more")
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
                show_nonblocking_drift=False,
                show_diagnostic_details=False,
                show_status_samples=False,
                sample_limit=5,
            )
        )
