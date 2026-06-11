#!/usr/bin/env python3
"""SQLite index for .github sources.

The filesystem remains the source of truth. This tool stores search text,
metadata, hashes, and drift status so agents can query .github artifacts
without moving or rewriting the original files.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sqlite3
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, Sequence


SCHEMA_VERSION = "1"
DEFAULT_ROOT = ".github"
DEFAULT_DB = ".github/cache/github-index.sqlite"
DEFAULT_MAX_BYTES = 2 * 1024 * 1024
TEXT_EXTENSIONS = {
    "",
    ".bash",
    ".cfg",
    ".cmd",
    ".conf",
    ".env",
    ".gitignore",
    ".ini",
    ".instructions",
    ".json",
    ".log",
    ".md",
    ".py",
    ".sh",
    ".toml",
    ".tsv",
    ".txt",
    ".yaml",
    ".yml",
}
DB_SUFFIXES = {".sqlite", ".sqlite3", ".db", ".db3"}


@dataclass(frozen=True)
class IndexedFile:
    path: str
    kind: str
    size_bytes: int
    mtime_ns: int
    sha256: str
    line_count: int
    title: str
    description: str
    declared_status: str
    tags: str
    exists_flag: int
    index_status: str
    content: str


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def repo_path(path: Path) -> str:
    return path.as_posix()


def resolve_repo_path(value: str) -> Path:
    return Path(value).expanduser().resolve()


def ensure_inside_root(root: Path, target: Path) -> None:
    if not target.resolve().is_relative_to(root.resolve()):
        raise ValueError(f"path escapes root: {target}")


def normalize_index_path(value: str, root: str = DEFAULT_ROOT) -> str:
    normalized = value.replace("\\", "/").strip().strip("/")
    root = root.strip().strip("/")
    if not normalized:
        return root
    if normalized == root or normalized.startswith(root + "/"):
        return normalized
    return f"{root}/{normalized}"


def open_db(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    return conn


def sqlite_has_fts5(conn: sqlite3.Connection) -> bool:
    try:
        conn.execute("CREATE VIRTUAL TABLE temp._github_index_fts_probe USING fts5(x)")
        conn.execute("DROP TABLE temp._github_index_fts_probe")
        return True
    except sqlite3.Error:
        return False


def init_schema(conn: sqlite3.Connection) -> bool:
    has_fts5 = sqlite_has_fts5(conn)
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS meta (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS files (
          path TEXT PRIMARY KEY,
          kind TEXT NOT NULL,
          size_bytes INTEGER NOT NULL,
          mtime_ns INTEGER NOT NULL,
          sha256 TEXT NOT NULL,
          line_count INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          declared_status TEXT NOT NULL,
          tags TEXT NOT NULL,
          exists_flag INTEGER NOT NULL,
          index_status TEXT NOT NULL,
          indexed_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS file_text (
          path TEXT PRIMARY KEY REFERENCES files(path) ON DELETE CASCADE,
          content TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ts TEXT NOT NULL,
          action TEXT NOT NULL,
          details TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_files_kind ON files(kind);
        CREATE INDEX IF NOT EXISTS idx_files_status ON files(index_status, exists_flag);
        CREATE INDEX IF NOT EXISTS idx_files_declared_status ON files(declared_status);
        """
    )
    if has_fts5:
        conn.execute(
            """
            CREATE VIRTUAL TABLE IF NOT EXISTS file_fts USING fts5(
              path UNINDEXED,
              title,
              description,
              tags,
              content,
              tokenize='unicode61'
            )
            """
        )
    conn.execute(
        "INSERT OR REPLACE INTO meta(key, value) VALUES(?, ?)",
        ("schema_version", SCHEMA_VERSION),
    )
    conn.execute(
        "INSERT OR REPLACE INTO meta(key, value) VALUES(?, ?)",
        ("fts5", "1" if has_fts5 else "0"),
    )
    conn.commit()
    return has_fts5


def record_event(conn: sqlite3.Connection, action: str, details: dict[str, object]) -> None:
    conn.execute(
        "INSERT INTO events(ts, action, details) VALUES(?, ?, ?)",
        (utc_now(), action, json.dumps(details, ensure_ascii=False, sort_keys=True)),
    )


def infer_kind(rel_path: str) -> str:
    path = Path(rel_path)
    parts = path.parts
    suffix = path.suffix.lower()
    name = path.name

    if rel_path == ".github/AGENTS.md":
        return "agent-rule"
    if rel_path == ".github/copilot-instructions.md":
        return "instruction"
    if len(parts) >= 3 and parts[:2] == (".github", "agents") and name.endswith(".agent.md"):
        return "agent"
    if len(parts) >= 3 and parts[:2] == (".github", "instructions"):
        return "instruction"
    if len(parts) >= 4 and parts[:3] == (".github", "memory", "modules"):
        return "memory-module"
    if len(parts) >= 3 and parts[:2] == (".github", "memory"):
        return "memory"
    if len(parts) >= 4 and parts[:3] == (".github", "e2e", "profiles"):
        return "e2e-profile"
    if len(parts) >= 4 and parts[:3] == (".github", "e2e", "modules"):
        return "e2e-module"
    if len(parts) >= 4 and parts[:3] == (".github", "task-runs", "templates"):
        return "task-template"
    if len(parts) >= 4 and parts[:2] == (".github", "task-runs"):
        if name == "task-report.md":
            return "task-report"
        if name == "dispatch-log.md":
            return "dispatch-log"
        if "evidence" in parts:
            return "task-evidence"
        return "task-run"
    if len(parts) >= 3 and parts[:2] == (".github", "workflows"):
        return "workflow"
    if suffix == ".md":
        return "markdown"
    if suffix == ".tsv":
        return "tsv"
    if suffix in {".yml", ".yaml"}:
        return "yaml"
    if suffix == ".json":
        return "json"
    if suffix == ".sh":
        return "shell"
    return "text"


def looks_binary(sample: bytes) -> bool:
    return b"\x00" in sample


def matches_exclude(rel_path: str, excludes: Sequence[str]) -> bool:
    normalized = rel_path.replace("\\", "/").rstrip("/")
    for raw in excludes:
        prefix = raw.replace("\\", "/").strip().rstrip("/")
        if not prefix:
            continue
        if normalized == prefix or normalized.startswith(prefix + "/"):
            return True
    return False


def should_skip_path(rel_path: str, db_rel_path: str, excludes: Sequence[str]) -> bool:
    parts = Path(rel_path).parts
    suffix = Path(rel_path).suffix.lower()
    if matches_exclude(rel_path, excludes):
        return True
    if rel_path == db_rel_path:
        return True
    if rel_path.endswith("-wal") or rel_path.endswith("-shm"):
        return True
    if suffix in DB_SUFFIXES:
        return True
    if len(parts) >= 3 and parts[:2] == (".github", "cache"):
        return True
    return False


def is_text_candidate(path: Path) -> bool:
    lower_name = path.name.lower()
    suffix = path.suffix.lower()
    if lower_name in {".gitkeep", ".gitignore"}:
        return True
    return suffix in TEXT_EXTENSIONS


def parse_frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---", 4)
    if end < 0:
        return {}
    metadata: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip().lower()
        value = value.strip().strip("\"'")
        if key:
            metadata[key] = value
    return metadata


def extract_title(text: str, rel_path: str) -> str:
    for line in text.splitlines()[:120]:
        match = re.match(r"\s*#\s+(.+?)\s*$", line)
        if match:
            return match.group(1).strip()
    return Path(rel_path).name


def extract_declared_status(text: str) -> str:
    frontmatter = parse_frontmatter(text)
    if "status" in frontmatter:
        return frontmatter["status"]
    patterns = [
        re.compile(r"^\s*status\s*:\s*(.+?)\s*$", re.IGNORECASE),
        re.compile(r"^\s*-\s*`status`\s*:\s*(.+?)\s*$", re.IGNORECASE),
        re.compile(r"^\s*status\s*=\s*(.+?)\s*$", re.IGNORECASE),
    ]
    for line in text.splitlines()[:240]:
        for pattern in patterns:
            match = pattern.match(line)
            if match:
                return match.group(1).strip().strip("\"'")
    return ""


def extract_tags(rel_path: str, kind: str, text: str) -> str:
    tags = {kind}
    path = Path(rel_path)
    tags.update(part for part in path.parts[1:-1] if part and not part.startswith("."))
    suffix = path.suffix.lower().lstrip(".")
    if suffix:
        tags.add(suffix)
    frontmatter = parse_frontmatter(text)
    raw_tags = frontmatter.get("tags", "")
    for tag in re.split(r"[, \[\]]+", raw_tags):
        tag = tag.strip().strip("\"'")
        if tag:
            tags.add(tag)
    return ",".join(sorted(tags))


def extract_description(text: str) -> str:
    frontmatter = parse_frontmatter(text)
    return frontmatter.get("description", "")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def index_one_file(
    repo_root: Path,
    path: Path,
    max_bytes: int,
    db_rel_path: str,
    excludes: Sequence[str],
) -> IndexedFile | None:
    rel_path = repo_path(path.relative_to(repo_root))
    if should_skip_path(rel_path, db_rel_path, excludes):
        return None

    stat = path.stat()
    kind = infer_kind(rel_path)
    empty = IndexedFile(
        path=rel_path,
        kind=kind,
        size_bytes=stat.st_size,
        mtime_ns=stat.st_mtime_ns,
        sha256="",
        line_count=0,
        title=path.name,
        description="",
        declared_status="",
        tags=kind,
        exists_flag=1,
        index_status="skipped",
        content="",
    )

    if not is_text_candidate(path):
        with path.open("rb") as handle:
            sample = handle.read(8192)
        if looks_binary(sample):
            return empty.__class__(**{**empty.__dict__, "index_status": "skipped_binary"})

    if stat.st_size > max_bytes:
        return empty.__class__(**{**empty.__dict__, "index_status": "skipped_large"})

    raw = path.read_bytes()
    if looks_binary(raw[:8192]):
        return empty.__class__(**{**empty.__dict__, "index_status": "skipped_binary"})

    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        return empty.__class__(**{**empty.__dict__, "index_status": "skipped_encoding"})

    line_count = text.count("\n") + (1 if text and not text.endswith("\n") else 0)
    title = extract_title(text, rel_path)
    description = extract_description(text)
    return IndexedFile(
        path=rel_path,
        kind=kind,
        size_bytes=stat.st_size,
        mtime_ns=stat.st_mtime_ns,
        sha256=sha256_bytes(raw),
        line_count=line_count,
        title=title,
        description=description,
        declared_status=extract_declared_status(text),
        tags=extract_tags(rel_path, kind, text),
        exists_flag=1,
        index_status="indexed",
        content=text,
    )


def upsert_file(conn: sqlite3.Connection, item: IndexedFile, has_fts5: bool, now: str) -> None:
    conn.execute(
        """
        INSERT INTO files(
          path, kind, size_bytes, mtime_ns, sha256, line_count, title,
          description, declared_status, tags, exists_flag, index_status,
          indexed_at, updated_at
        )
        VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(path) DO UPDATE SET
          kind=excluded.kind,
          size_bytes=excluded.size_bytes,
          mtime_ns=excluded.mtime_ns,
          sha256=excluded.sha256,
          line_count=excluded.line_count,
          title=excluded.title,
          description=excluded.description,
          declared_status=excluded.declared_status,
          tags=excluded.tags,
          exists_flag=excluded.exists_flag,
          index_status=excluded.index_status,
          indexed_at=excluded.indexed_at,
          updated_at=excluded.updated_at
        """,
        (
            item.path,
            item.kind,
            item.size_bytes,
            item.mtime_ns,
            item.sha256,
            item.line_count,
            item.title,
            item.description,
            item.declared_status,
            item.tags,
            item.exists_flag,
            item.index_status,
            now,
            now,
        ),
    )
    conn.execute(
        "INSERT OR REPLACE INTO file_text(path, content) VALUES(?, ?)",
        (item.path, item.content),
    )
    if has_fts5:
        conn.execute("DELETE FROM file_fts WHERE path = ?", (item.path,))
        if item.content:
            conn.execute(
                "INSERT INTO file_fts(path, title, description, tags, content) VALUES(?, ?, ?, ?, ?)",
                (item.path, item.title, item.description, item.tags, item.content),
            )


def scan_files(
    repo_root: Path,
    github_root: Path,
    db_path: Path,
    max_bytes: int,
    excludes: Sequence[str],
) -> list[IndexedFile]:
    db_rel_path = repo_path(db_path.relative_to(repo_root)) if db_path.is_relative_to(repo_root) else ""
    results: list[IndexedFile] = []
    for path in sorted(github_root.rglob("*")):
        if not path.is_file():
            continue
        item = index_one_file(repo_root, path, max_bytes, db_rel_path, excludes)
        if item is not None:
            results.append(item)
    return results


def rebuild(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    github_root = (repo_root / args.root).resolve()
    db_path = (repo_root / args.db).resolve()
    if not github_root.is_dir():
        print(f"FAIL root not found: {github_root}", file=sys.stderr)
        return 2

    conn = open_db(db_path)
    has_fts5 = init_schema(conn)
    now = utc_now()
    items = scan_files(repo_root, github_root, db_path, args.max_bytes, args.exclude)
    seen = {item.path for item in items}
    try:
        with conn:
            for item in items:
                upsert_file(conn, item, has_fts5, now)
            placeholders = ",".join("?" for _ in seen)
            if seen:
                conn.execute(
                    f"""
                    UPDATE files
                    SET exists_flag=0, index_status='missing', updated_at=?
                    WHERE path LIKE '.github/%' AND path NOT IN ({placeholders})
                    """,
                    (now, *sorted(seen)),
                )
            else:
                conn.execute(
                    "UPDATE files SET exists_flag=0, index_status='missing', updated_at=? WHERE path LIKE '.github/%'",
                    (now,),
                )
            conn.execute(
                "INSERT OR REPLACE INTO meta(key, value) VALUES(?, ?)",
                ("last_rebuild_at", now),
            )
            conn.execute(
                "INSERT OR REPLACE INTO meta(key, value) VALUES(?, ?)",
                ("root", repo_path(github_root.relative_to(repo_root))),
            )
            conn.execute(
                "INSERT OR REPLACE INTO meta(key, value) VALUES(?, ?)",
                ("max_bytes", str(args.max_bytes)),
            )
            record_event(
                conn,
                "rebuild",
                {
                    "root": repo_path(github_root.relative_to(repo_root)),
                    "db": repo_path(db_path.relative_to(repo_root))
                    if db_path.is_relative_to(repo_root)
                    else str(db_path),
                    "files": len(items),
                    "fts5": has_fts5,
                    "exclude": args.exclude,
                },
            )
    finally:
        conn.close()
    print(f"PASS rebuild files={len(items)} db={db_path}")
    return 0


def fetch_meta(conn: sqlite3.Connection) -> dict[str, str]:
    return {row["key"]: row["value"] for row in conn.execute("SELECT key, value FROM meta")}


def print_stat(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    init_schema(conn)
    meta = fetch_meta(conn)
    total = conn.execute("SELECT COUNT(*) AS c FROM files").fetchone()["c"]
    indexed = conn.execute("SELECT COUNT(*) AS c FROM files WHERE index_status='indexed'").fetchone()["c"]
    print(f"db={db_path}")
    print(f"schema_version={meta.get('schema_version', '')}")
    print(f"fts5={meta.get('fts5', '0')}")
    print(f"root={meta.get('root', '')}")
    print(f"last_rebuild_at={meta.get('last_rebuild_at', '')}")
    print(f"files={total}")
    print(f"indexed={indexed}")
    print("[status]")
    for row in conn.execute(
        "SELECT index_status, COUNT(*) AS c FROM files GROUP BY index_status ORDER BY index_status"
    ):
        print(f"{row['index_status']}={row['c']}")
    print("[kind]")
    for row in conn.execute("SELECT kind, COUNT(*) AS c FROM files GROUP BY kind ORDER BY kind"):
        print(f"{row['kind']}={row['c']}")
    conn.close()
    return 0


def query_terms(raw_terms: Sequence[str]) -> list[str]:
    joined = " ".join(raw_terms).strip()
    if not joined:
        return []
    return [term for term in re.split(r"\s+", joined) if term]


def build_like_where(terms: Sequence[str], params: list[object]) -> str:
    clauses = []
    fields = ("f.path", "f.title", "f.description", "f.tags", "t.content")
    for term in terms:
        sub = []
        like = f"%{term}%"
        for field in fields:
            sub.append(f"{field} LIKE ?")
            params.append(like)
        clauses.append("(" + " OR ".join(sub) + ")")
    return " AND ".join(clauses) if clauses else "1=1"


def fts_query_expression(terms: Sequence[str]) -> str:
    quoted = []
    for term in terms:
        escaped = term.replace('"', '""')
        quoted.append(f'"{escaped}"')
    return " AND ".join(quoted)


def query_rows_like(
    conn: sqlite3.Connection,
    terms: Sequence[str],
    kind: str | None,
    status: str | None,
    limit: int,
) -> tuple[str, list[sqlite3.Row]]:
    params: list[object] = []
    where = build_like_where(terms, params)
    if kind:
        where += " AND f.kind = ?"
        params.append(kind)
    if status:
        where += " AND f.index_status = ?"
        params.append(status)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT f.path, f.kind, f.index_status, f.title, f.description, f.tags, t.content
        FROM files f
        LEFT JOIN file_text t ON t.path = f.path
        WHERE {where}
        ORDER BY
          CASE f.kind
            WHEN 'agent-rule' THEN 0
            WHEN 'agent' THEN 1
            WHEN 'instruction' THEN 2
            WHEN 'memory-module' THEN 3
            WHEN 'e2e-profile' THEN 4
            WHEN 'e2e-module' THEN 5
            ELSE 9
          END,
          f.path
        LIMIT ?
        """,
        params,
    ).fetchall()
    return "like", rows


def query_rows_fts(
    conn: sqlite3.Connection,
    terms: Sequence[str],
    kind: str | None,
    status: str | None,
    limit: int,
) -> tuple[str, list[sqlite3.Row]]:
    where = ["file_fts MATCH ?"]
    params: list[object] = [fts_query_expression(terms)]
    if kind:
        where.append("f.kind = ?")
        params.append(kind)
    if status:
        where.append("f.index_status = ?")
        params.append(status)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT f.path, f.kind, f.index_status, f.title, f.description, f.tags, t.content
        FROM file_fts
        JOIN files f ON f.path = file_fts.path
        LEFT JOIN file_text t ON t.path = f.path
        WHERE {' AND '.join(where)}
        ORDER BY bm25(file_fts), f.path
        LIMIT ?
        """,
        params,
    ).fetchall()
    return "fts", rows


def row_snippet(content: str, terms: Sequence[str], window: int) -> tuple[int, str]:
    if not content:
        return 0, ""
    lowered = content.lower()
    positions = [lowered.find(term.lower()) for term in terms if term]
    positions = [pos for pos in positions if pos >= 0]
    pos = min(positions) if positions else 0
    line_no = content[:pos].count("\n") + 1
    start = max(0, pos - window // 2)
    end = min(len(content), pos + window // 2)
    snippet = content[start:end].replace("\r", " ")
    snippet = re.sub(r"\s+", " ", snippet).strip()
    return line_no, snippet


def query(args: argparse.Namespace) -> int:
    terms = query_terms(args.terms)
    if not terms:
        print("FAIL query needs at least one term", file=sys.stderr)
        return 2
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    init_schema(conn)
    meta = fetch_meta(conn)
    used_mode = "like"
    rows: list[sqlite3.Row]
    if args.mode in {"auto", "fts"} and meta.get("fts5") == "1":
        try:
            used_mode, rows = query_rows_fts(conn, terms, args.kind, args.status, args.limit)
        except sqlite3.Error as exc:
            if args.mode == "fts":
                print(f"FAIL fts query: {exc}", file=sys.stderr)
                return 2
            used_mode, rows = query_rows_like(conn, terms, args.kind, args.status, args.limit)
        else:
            if args.mode == "auto" and not rows:
                used_mode, rows = query_rows_like(conn, terms, args.kind, args.status, args.limit)
    else:
        used_mode, rows = query_rows_like(conn, terms, args.kind, args.status, args.limit)
    if args.json:
        out = []
        for row in rows:
            line_no, snippet = row_snippet(row["content"] or "", terms, args.snippet_chars)
            out.append(
                {
                    "path": row["path"],
                    "kind": row["kind"],
                    "index_status": row["index_status"],
                    "title": row["title"],
                    "description": row["description"],
                    "mode": used_mode,
                    "line": line_no,
                    "snippet": snippet,
                }
            )
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        print(f"query={' '.join(terms)} mode={used_mode} results={len(rows)}")
        for row in rows:
            line_no, snippet = row_snippet(row["content"] or "", terms, args.snippet_chars)
            line_part = f":{line_no}" if line_no else ""
            print(f"{row['path']}{line_part} [{row['kind']} {row['index_status']}] {row['title']}")
            if snippet:
                print(f"  {snippet}")
    conn.close()
    return 0


def show(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path)
    init_schema(conn)
    target = args.path.replace("\\", "/")
    row = conn.execute(
        """
        SELECT f.*, t.content
        FROM files f
        LEFT JOIN file_text t ON t.path = f.path
        WHERE f.path = ?
        """,
        (target,),
    ).fetchone()
    if row is None:
        print(f"FAIL not indexed: {target}", file=sys.stderr)
        return 1
    data = dict(row)
    content = data.pop("content", "") or ""
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        for key in (
            "path",
            "kind",
            "index_status",
            "exists_flag",
            "size_bytes",
            "mtime_ns",
            "sha256",
            "line_count",
            "title",
            "description",
            "declared_status",
            "tags",
            "indexed_at",
            "updated_at",
        ):
            print(f"{key}={data[key]}")
        if args.term and content:
            line_no, snippet = row_snippet(content, [args.term], args.snippet_chars)
            print(f"snippet_line={line_no}")
            print(f"snippet={snippet}")
    conn.close()
    return 0


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
    conn.execute("DELETE FROM files WHERE path = ?", (path,))


def refresh_one(conn: sqlite3.Connection, repo_root: Path, db_path: Path, path: str, max_bytes: int) -> str:
    has_fts5 = init_schema(conn)
    now = utc_now()
    rel_path = normalize_index_path(path)
    target = (repo_root / rel_path).resolve()
    ensure_inside_root(repo_root / DEFAULT_ROOT, target)
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


def smoke(args: argparse.Namespace) -> int:
    with tempfile.TemporaryDirectory(prefix="github-index-smoke-") as tmp:
        db_path = Path(tmp) / "github-index.sqlite"
        common = argparse.Namespace(
            repo_root=args.repo_root,
            root=args.root,
            db=str(db_path),
            max_bytes=args.max_bytes,
            exclude=args.exclude,
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


def add_common_db_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--repo-root", default=".", help="repository root, default: current directory")
    parser.add_argument("--db", default=DEFAULT_DB, help=f"SQLite DB path, default: {DEFAULT_DB}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Index .github files into a metadata/search SQLite database."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_cmd = subparsers.add_parser("init", help="create database schema")
    add_common_db_args(init_cmd)
    init_cmd.set_defaults(func=lambda args: (open_db((resolve_repo_path(args.repo_root) / args.db).resolve()).close() or 0))

    rebuild_cmd = subparsers.add_parser("rebuild", aliases=["build", "update"], help="rebuild index")
    add_common_db_args(rebuild_cmd)
    rebuild_cmd.add_argument("--root", default=DEFAULT_ROOT, help=f"source root, default: {DEFAULT_ROOT}")
    rebuild_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    rebuild_cmd.add_argument(
        "--exclude",
        action="append",
        default=[],
        help="repo-relative path prefix to exclude from indexing; can be repeated",
    )
    rebuild_cmd.set_defaults(func=rebuild)

    stat_cmd = subparsers.add_parser("stat", help="print index statistics")
    add_common_db_args(stat_cmd)
    stat_cmd.set_defaults(func=print_stat)

    query_cmd = subparsers.add_parser(
        "query",
        aliases=["search"],
        help="search indexed metadata and content",
    )
    add_common_db_args(query_cmd)
    query_cmd.add_argument("terms", nargs="+")
    query_cmd.add_argument("--kind")
    query_cmd.add_argument("--status")
    query_cmd.add_argument("--mode", choices=["auto", "fts", "like"], default="auto")
    query_cmd.add_argument("--limit", type=int, default=20)
    query_cmd.add_argument("--snippet-chars", type=int, default=220)
    query_cmd.add_argument("--json", action="store_true")
    query_cmd.set_defaults(func=query)

    ls_cmd = subparsers.add_parser("ls", help="list indexed files like a directory")
    add_common_db_args(ls_cmd)
    ls_cmd.add_argument("path", nargs="?", default=DEFAULT_ROOT)
    ls_cmd.add_argument("--root", default=DEFAULT_ROOT)
    ls_cmd.add_argument("--limit", type=int, default=80)
    ls_cmd.set_defaults(func=list_dir)

    tree_cmd = subparsers.add_parser("tree", help="print an indexed directory tree")
    add_common_db_args(tree_cmd)
    tree_cmd.add_argument("path", nargs="?", default=DEFAULT_ROOT)
    tree_cmd.add_argument("--root", default=DEFAULT_ROOT)
    tree_cmd.add_argument("--depth", type=int, default=3)
    tree_cmd.add_argument("--limit", type=int, default=160)
    tree_cmd.set_defaults(func=tree)

    show_cmd = subparsers.add_parser("show", help="show one indexed file")
    add_common_db_args(show_cmd)
    show_cmd.add_argument("path")
    show_cmd.add_argument("--term")
    show_cmd.add_argument("--snippet-chars", type=int, default=220)
    show_cmd.add_argument("--json", action="store_true")
    show_cmd.set_defaults(func=show)

    doctor_cmd = subparsers.add_parser("doctor", help="compare index status with filesystem")
    add_common_db_args(doctor_cmd)
    doctor_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    doctor_cmd.add_argument("--write-status", action="store_true")
    doctor_cmd.add_argument("--fail-on-drift", action="store_true")
    doctor_cmd.add_argument("--sample-limit", type=int, default=8)
    doctor_cmd.set_defaults(func=doctor)

    refresh_cmd = subparsers.add_parser("refresh", help="refresh one or more files from filesystem")
    add_common_db_args(refresh_cmd)
    refresh_cmd.add_argument("paths", nargs="+")
    refresh_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    refresh_cmd.set_defaults(func=refresh)

    add_cmd = subparsers.add_parser("add", help="add or replace a .github file, then index it")
    add_common_db_args(add_cmd)
    add_cmd.add_argument("path")
    add_cmd.add_argument("--root", default=DEFAULT_ROOT)
    add_cmd.add_argument("--content")
    add_cmd.add_argument("--from-file")
    add_cmd.add_argument("--replace", action="store_true")
    add_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    add_cmd.set_defaults(func=add_entry)

    remove_cmd = subparsers.add_parser("remove", aliases=["rm"], help="remove an index row or a .github file")
    add_common_db_args(remove_cmd)
    remove_cmd.add_argument("path")
    remove_cmd.add_argument("--root", default=DEFAULT_ROOT)
    remove_cmd.add_argument("--delete-file", action="store_true")
    remove_cmd.add_argument("--yes", action="store_true")
    remove_cmd.set_defaults(func=remove_entry)

    smoke_cmd = subparsers.add_parser("smoke", help="run rebuild/stat/query/doctor on a temp DB")
    smoke_cmd.add_argument("--repo-root", default=".")
    smoke_cmd.add_argument("--root", default=DEFAULT_ROOT)
    smoke_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    smoke_cmd.add_argument("--exclude", action="append", default=[])
    smoke_cmd.add_argument("--limit", type=int, default=5)
    smoke_cmd.add_argument("terms", nargs="*", default=["software-flow"])
    smoke_cmd.set_defaults(func=smoke)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command == "init":
        repo_root = resolve_repo_path(args.repo_root)
        db_path = (repo_root / args.db).resolve()
        conn = open_db(db_path)
        try:
            has_fts5 = init_schema(conn)
            record_event(conn, "init", {"db": str(db_path), "fts5": has_fts5})
            conn.commit()
        finally:
            conn.close()
        print(f"PASS init db={db_path}")
        return 0
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
