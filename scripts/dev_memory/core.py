#!/usr/bin/env python3
"""SQLite-backed development memory for .github sources.

The live filesystem remains the source for rules, agents, profiles, contracts,
and docs. The database retains fixed-format memory/log documents and indexes
the rest so agents can query, summarize, and load bounded context.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sqlite3
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Sequence


SCHEMA_VERSION = "4"
DEFAULT_ROOT = ".github"
DEFAULT_DB = ".github/cache/github-index.sqlite"
DEFAULT_DB_BACKUP_ROOT = ".github/db-backup"
DEFAULT_MAX_BYTES = 2 * 1024 * 1024
DEFAULT_CHUNK_MAX_CHARS = 3500
DEFAULT_EXTRA_SOURCES = (
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    "CONVENTIONS.md",
    ".windsurfrules",
    ".cursor/rules/agents.mdc",
)
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
CHUNK_KINDS = {
    "agent-rule",
    "agent",
    "skill",
    "instruction",
    "memory",
    "memory-module",
    "e2e-profile",
    "e2e-module",
    "task-template",
    "task-report",
    "dispatch-log",
    "markdown",
}
CHUNK_SUFFIXES = {".md", ".instructions", ".tsv", ".yaml", ".yml"}
DB_RETAINED_KINDS = {
    "memory",
    "memory-module",
    "task-report",
    "dispatch-log",
    "task-run",
}
DB_FIRST_KINDS = set(DB_RETAINED_KINDS)


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


@dataclass(frozen=True)
class FileChunk:
    chunk_id: str
    path: str
    ordinal: int
    heading: str
    start_line: int
    end_line: int
    token_estimate: int
    summary: str
    text: str


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
    if normalized in DEFAULT_EXTRA_SOURCES:
        return normalized
    if not normalized:
        return root
    if normalized == root or normalized.startswith(root + "/"):
        return normalized
    return f"{root}/{normalized}"


def open_db(
    db_path: Path,
    *,
    readonly: bool = False,
    timeout: float = 30.0,
    busy_timeout_ms: int | None = None,
) -> sqlite3.Connection:
    if readonly:
        if not db_path.exists():
            raise sqlite3.OperationalError(f"unable to open database file: {db_path}")
        # UNC 路径（例如 \\wsl$）经 Path.as_uri() 会带 authority，SQLite URI 会拒绝。
        # 只读调用不切 WAL，并在打开后用 query_only 禁写即可避免创建/修改 DB。
        conn = sqlite3.connect(str(db_path), timeout=timeout)
    else:
        db_path.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(db_path), timeout=timeout)
    conn.row_factory = sqlite3.Row
    if busy_timeout_ms is None:
        busy_timeout_ms = int(timeout * 1000)
    conn.execute(f"PRAGMA busy_timeout = {int(busy_timeout_ms)}")
    conn.execute("PRAGMA foreign_keys = ON")
    if readonly:
        # 只读 recall/load/query 路径不能尝试切换 WAL，否则会在已有写者或
        # UNC/WSL 混合访问时拿写锁，反而让 DB/index 记忆入口不可用。
        conn.execute("PRAGMA query_only = ON")
    else:
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

        CREATE TABLE IF NOT EXISTS file_chunks (
          chunk_id TEXT PRIMARY KEY,
          path TEXT NOT NULL REFERENCES files(path) ON DELETE CASCADE,
          ordinal INTEGER NOT NULL,
          heading TEXT NOT NULL,
          start_line INTEGER NOT NULL,
          end_line INTEGER NOT NULL,
          token_estimate INTEGER NOT NULL,
          summary TEXT NOT NULL,
          text TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS db_documents (
          path TEXT PRIMARY KEY,
          kind TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          tags TEXT NOT NULL,
          sha256 TEXT NOT NULL,
          line_count INTEGER NOT NULL,
          content TEXT NOT NULL,
          source_indexed_at TEXT NOT NULL,
          stored_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS db_document_chunks (
          chunk_id TEXT PRIMARY KEY,
          path TEXT NOT NULL REFERENCES db_documents(path) ON DELETE CASCADE,
          ordinal INTEGER NOT NULL,
          heading TEXT NOT NULL,
          start_line INTEGER NOT NULL,
          end_line INTEGER NOT NULL,
          token_estimate INTEGER NOT NULL,
          summary TEXT NOT NULL,
          text TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ts TEXT NOT NULL,
          action TEXT NOT NULL,
          details TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS access_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          used_at TEXT NOT NULL,
          surface TEXT NOT NULL,
          op TEXT NOT NULL,
          source TEXT NOT NULL,
          target TEXT NOT NULL,
          ok INTEGER NOT NULL,
          result_count INTEGER NOT NULL,
          details TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS evidence_assets (
          path TEXT PRIMARY KEY,
          run_id TEXT NOT NULL,
          task_slug TEXT NOT NULL,
          profile TEXT NOT NULL,
          kind TEXT NOT NULL,
          size_bytes INTEGER NOT NULL,
          mtime_ns INTEGER NOT NULL,
          sha256 TEXT NOT NULL,
          line_count INTEGER NOT NULL,
          encoding TEXT NOT NULL,
          summary TEXT NOT NULL,
          head_excerpt TEXT NOT NULL,
          tail_excerpt TEXT NOT NULL,
          markers TEXT NOT NULL,
          indexed_at TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_files_kind ON files(kind);
        CREATE INDEX IF NOT EXISTS idx_files_status ON files(index_status, exists_flag);
        CREATE INDEX IF NOT EXISTS idx_files_declared_status ON files(declared_status);
        CREATE INDEX IF NOT EXISTS idx_file_chunks_path ON file_chunks(path, ordinal);
        CREATE INDEX IF NOT EXISTS idx_file_chunks_heading ON file_chunks(heading);
        CREATE INDEX IF NOT EXISTS idx_db_documents_kind ON db_documents(kind);
        CREATE INDEX IF NOT EXISTS idx_db_document_chunks_path ON db_document_chunks(path, ordinal);
        CREATE INDEX IF NOT EXISTS idx_access_log_used_at ON access_log(used_at);
        CREATE INDEX IF NOT EXISTS idx_access_log_op ON access_log(op, used_at);
        CREATE INDEX IF NOT EXISTS idx_evidence_assets_run ON evidence_assets(run_id, path);
        CREATE INDEX IF NOT EXISTS idx_evidence_assets_profile ON evidence_assets(profile, indexed_at);
        CREATE INDEX IF NOT EXISTS idx_evidence_assets_kind ON evidence_assets(kind);
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
            """
            CREATE VIRTUAL TABLE IF NOT EXISTS chunk_fts USING fts5(
              chunk_id UNINDEXED,
              path UNINDEXED,
              heading,
              summary,
              text,
              tokenize='unicode61'
            )
            """
        )
        conn.execute(
            """
            CREATE VIRTUAL TABLE IF NOT EXISTS document_fts USING fts5(
              chunk_id UNINDEXED,
              path UNINDEXED,
              heading,
              summary,
              text,
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


def record_access(
    conn: sqlite3.Connection,
    *,
    surface: str,
    op: str,
    source: str = "",
    target: str = "",
    ok: bool = True,
    result_count: int = 0,
    details: dict[str, object] | None = None,
) -> None:
    conn.execute(
        """
        INSERT INTO access_log(used_at, surface, op, source, target, ok, result_count, details)
        VALUES(?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            utc_now(),
            surface,
            op,
            source,
            target,
            1 if ok else 0,
            int(result_count),
            json.dumps(details or {}, ensure_ascii=False, sort_keys=True),
        ),
    )


def infer_kind(rel_path: str) -> str:
    path = Path(rel_path)
    parts = path.parts
    suffix = path.suffix.lower()
    name = path.name

    if rel_path == ".github/AGENTS.md":
        return "agent-rule"
    if rel_path in DEFAULT_EXTRA_SOURCES:
        return "agent-shim"
    if rel_path == ".github/copilot-instructions.md":
        return "instruction"
    if len(parts) >= 3 and parts[:2] == (".github", "agents") and name.endswith(".agent.md"):
        return "agent"
    if len(parts) >= 4 and parts[:2] == (".github", "skills") and name == "SKILL.md":
        return "skill"
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


def is_raw_evidence_path(rel_path: str) -> bool:
    normalized = rel_path.replace("\\", "/")
    if normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized.startswith(".github/runtime-artifacts/") or (
        normalized.startswith(".github/task-runs/")
        and "/evidence/" in normalized
    )


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
    if is_raw_evidence_path(rel_path):
        return True
    if rel_path == db_rel_path:
        return True
    if rel_path.endswith("-wal") or rel_path.endswith("-shm"):
        return True
    if suffix in DB_SUFFIXES:
        return True
    if len(parts) >= 3 and parts[:2] == (".github", "cache"):
        return True
    if len(parts) >= 3 and parts[:2] == (".github", "db-backup"):
        return True
    if len(parts) >= 3 and parts[:2] == (".github", "tmp"):
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


def compact_text(value: str, max_chars: int) -> str:
    text = re.sub(r"\s+", " ", value).strip()
    if len(text) <= max_chars:
        return text
    return text[: max(0, max_chars - 3)].rstrip() + "..."


def estimate_tokens(text: str) -> int:
    if not text:
        return 0
    cjk_chars = len(re.findall(r"[\u3400-\u9fff]", text))
    ascii_words = len(re.findall(r"[A-Za-z0-9_./:-]+", text))
    other_chars = max(0, len(text) - cjk_chars)
    return max(1, cjk_chars + ascii_words + other_chars // 6)


def summarize_chunk(text: str, heading: str, max_chars: int = 260) -> str:
    candidates: list[str] = []
    in_fence = False
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if line.startswith("```") or line.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence or not line:
            continue
        if re.match(r"^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?$", line):
            continue
        if line.startswith("#"):
            continue
        candidates.append(line)
        if len(" ".join(candidates)) >= max_chars:
            break
    if not candidates and heading:
        candidates.append(heading)
    return compact_text(" / ".join(candidates), max_chars)


def markdown_sections(text: str, fallback_heading: str) -> list[tuple[str, int, int, list[str]]]:
    lines = text.splitlines()
    if not lines:
        return []
    sections: list[tuple[str, int, int, list[str]]] = []
    heading = fallback_heading
    start_line = 1
    buffer: list[str] = []
    for line_no, line in enumerate(lines, start=1):
        match = re.match(r"^\s{0,3}(#{1,6})\s+(.+?)\s*#*\s*$", line)
        if match and buffer:
            sections.append((heading, start_line, line_no - 1, buffer))
            heading = match.group(2).strip()
            start_line = line_no
            buffer = [line]
            continue
        if match:
            heading = match.group(2).strip()
            start_line = line_no
        buffer.append(line)
    if buffer:
        sections.append((heading, start_line, len(lines), buffer))
    return sections


def split_section_lines(
    heading: str,
    start_line: int,
    lines: list[str],
    max_chars: int,
) -> list[tuple[str, int, int, str]]:
    chunks: list[tuple[str, int, int, str]] = []
    current: list[str] = []
    current_start = start_line
    current_chars = 0
    for offset, line in enumerate(lines):
        line_no = start_line + offset
        line_chars = len(line) + 1
        should_flush = current and current_chars + line_chars > max_chars
        if should_flush and (not line.strip() or current_chars >= max_chars):
            text = "\n".join(current).strip()
            if text:
                chunks.append((heading, current_start, line_no - 1, text))
            current = []
            current_start = line_no
            current_chars = 0
        current.append(line)
        current_chars += line_chars
        if current_chars >= max_chars and not line.strip():
            text = "\n".join(current).strip()
            if text:
                chunks.append((heading, current_start, line_no, text))
            current = []
            current_start = line_no + 1
            current_chars = 0
    if current:
        text = "\n".join(current).strip()
        if text:
            chunks.append((heading, current_start, start_line + len(lines) - 1, text))
    return chunks


def build_file_chunks(path: str, title: str, content: str, max_chars: int = DEFAULT_CHUNK_MAX_CHARS) -> list[FileChunk]:
    chunks: list[FileChunk] = []
    ordinal = 1
    fallback_heading = title or Path(path).name
    for heading, start_line, _end_line, lines in markdown_sections(content, fallback_heading):
        for chunk_heading, chunk_start, chunk_end, chunk_text in split_section_lines(
            heading,
            start_line,
            lines,
            max_chars,
        ):
            chunk_id = f"{path}#chunk-{ordinal:04d}"
            chunks.append(
                FileChunk(
                    chunk_id=chunk_id,
                    path=path,
                    ordinal=ordinal,
                    heading=chunk_heading,
                    start_line=chunk_start,
                    end_line=chunk_end,
                    token_estimate=estimate_tokens(chunk_text),
                    summary=summarize_chunk(chunk_text, chunk_heading),
                    text=chunk_text,
                )
            )
            ordinal += 1
    return chunks


def should_build_chunks(item: IndexedFile) -> bool:
    if item.index_status != "indexed" or not item.content:
        return False
    suffix = Path(item.path).suffix.lower()
    return item.kind in CHUNK_KINDS or suffix in CHUNK_SUFFIXES


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


def delete_chunks_for_path(conn: sqlite3.Connection, path: str, has_fts5: bool) -> None:
    if has_fts5:
        conn.execute("DELETE FROM chunk_fts WHERE path = ?", (path,))
    conn.execute("DELETE FROM file_chunks WHERE path = ?", (path,))


def delete_document_chunks_for_path(conn: sqlite3.Connection, path: str, has_fts5: bool) -> None:
    if has_fts5:
        conn.execute("DELETE FROM document_fts WHERE path = ?", (path,))
    conn.execute("DELETE FROM db_document_chunks WHERE path = ?", (path,))


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
    delete_chunks_for_path(conn, item.path, has_fts5)
    if should_build_chunks(item):
        for chunk in build_file_chunks(item.path, item.title, item.content):
            conn.execute(
                """
                INSERT INTO file_chunks(
                  chunk_id, path, ordinal, heading, start_line, end_line,
                  token_estimate, summary, text
                )
                VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    chunk.chunk_id,
                    chunk.path,
                    chunk.ordinal,
                    chunk.heading,
                    chunk.start_line,
                    chunk.end_line,
                    chunk.token_estimate,
                    chunk.summary,
                    chunk.text,
                ),
            )
            if has_fts5:
                conn.execute(
                    "INSERT INTO chunk_fts(chunk_id, path, heading, summary, text) VALUES(?, ?, ?, ?, ?)",
                    (chunk.chunk_id, chunk.path, chunk.heading, chunk.summary, chunk.text),
                )


def upsert_stored_document(conn: sqlite3.Connection, item: IndexedFile, has_fts5: bool, now: str) -> None:
    conn.execute(
        """
        INSERT INTO db_documents(
          path, kind, title, description, tags, sha256, line_count,
          content, source_indexed_at, stored_at
        )
        VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(path) DO UPDATE SET
          kind=excluded.kind,
          title=excluded.title,
          description=excluded.description,
          tags=excluded.tags,
          sha256=excluded.sha256,
          line_count=excluded.line_count,
          content=excluded.content,
          source_indexed_at=excluded.source_indexed_at,
          stored_at=excluded.stored_at
        """,
        (
            item.path,
            item.kind,
            item.title,
            item.description,
            item.tags,
            item.sha256,
            item.line_count,
            item.content,
            now,
            now,
        ),
    )
    delete_document_chunks_for_path(conn, item.path, has_fts5)
    for chunk in build_file_chunks(item.path, item.title, item.content):
        conn.execute(
            """
            INSERT INTO db_document_chunks(
              chunk_id, path, ordinal, heading, start_line, end_line,
              token_estimate, summary, text
            )
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                chunk.chunk_id,
                chunk.path,
                chunk.ordinal,
                chunk.heading,
                chunk.start_line,
                chunk.end_line,
                chunk.token_estimate,
                chunk.summary,
                chunk.text,
            ),
        )
        if has_fts5:
            conn.execute(
                "INSERT INTO document_fts(chunk_id, path, heading, summary, text) VALUES(?, ?, ?, ?, ?)",
                (chunk.chunk_id, chunk.path, chunk.heading, chunk.summary, chunk.text),
            )


def scan_files(
    repo_root: Path,
    github_root: Path,
    db_path: Path,
    max_bytes: int,
    excludes: Sequence[str],
    includes: Sequence[str],
) -> list[IndexedFile]:
    db_rel_path = repo_path(db_path.relative_to(repo_root)) if db_path.is_relative_to(repo_root) else ""
    results: list[IndexedFile] = []
    seen: set[str] = set()

    def append_path(path: Path) -> None:
        if not path.is_file():
            return
        rel_path = repo_path(path.relative_to(repo_root))
        if rel_path in seen:
            return
        seen.add(rel_path)
        item = index_one_file(repo_root, path, max_bytes, db_rel_path, excludes)
        if item is not None:
            results.append(item)

    for path in sorted(github_root.rglob("*")):
        append_path(path)
    for raw_include in includes:
        target = (repo_root / raw_include).resolve()
        try:
            ensure_inside_root(repo_root, target)
        except ValueError:
            continue
        if target.is_dir():
            for path in sorted(target.rglob("*")):
                append_path(path)
        elif target.exists():
            append_path(target)
    return results


def prune_ignored_index_rows(conn: sqlite3.Connection, has_fts5: bool) -> None:
    patterns = (
        ".github/cache/%",
        ".github/db-backup/%",
        ".github/tmp/%",
        ".github/runtime-artifacts/%",
        ".github/task-runs/%/evidence/%",
    )
    for like in patterns:
        if has_fts5:
            conn.execute("DELETE FROM file_fts WHERE path LIKE ?", (like,))
            conn.execute("DELETE FROM chunk_fts WHERE path LIKE ?", (like,))
        conn.execute("DELETE FROM file_text WHERE path LIKE ?", (like,))
        conn.execute("DELETE FROM file_chunks WHERE path LIKE ?", (like,))
        conn.execute("DELETE FROM files WHERE path LIKE ?", (like,))


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
    items = scan_files(repo_root, github_root, db_path, args.max_bytes, args.exclude, args.include)
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
                    WHERE path NOT IN ({placeholders})
                    """,
                    (now, *sorted(seen)),
                )
            else:
                conn.execute(
                    "UPDATE files SET exists_flag=0, index_status='missing', updated_at=?",
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
            prune_ignored_index_rows(conn, has_fts5)
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
                    "include": args.include,
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
    conn = open_db(db_path, readonly=True)
    meta = fetch_meta(conn)
    total = conn.execute("SELECT COUNT(*) AS c FROM files").fetchone()["c"]
    indexed = conn.execute("SELECT COUNT(*) AS c FROM files WHERE index_status='indexed'").fetchone()["c"]
    chunks = conn.execute("SELECT COUNT(*) AS c FROM file_chunks").fetchone()["c"]
    tokens = conn.execute("SELECT COALESCE(SUM(token_estimate), 0) AS c FROM file_chunks").fetchone()["c"]
    stored = conn.execute("SELECT COUNT(*) AS c FROM db_documents").fetchone()["c"]
    stored_chunks = conn.execute("SELECT COUNT(*) AS c FROM db_document_chunks").fetchone()["c"]
    stored_tokens = conn.execute("SELECT COALESCE(SUM(token_estimate), 0) AS c FROM db_document_chunks").fetchone()["c"]
    evidence_assets = conn.execute("SELECT COUNT(*) AS c FROM evidence_assets").fetchone()["c"]
    access = conn.execute(
        "SELECT COUNT(*) AS c, MAX(used_at) AS last_used_at FROM access_log"
    ).fetchone()
    print(f"db={db_path}")
    print(f"schema_version={meta.get('schema_version', '')}")
    print(f"fts5={meta.get('fts5', '0')}")
    print(f"root={meta.get('root', '')}")
    print(f"last_rebuild_at={meta.get('last_rebuild_at', '')}")
    print(f"last_used_at={access['last_used_at'] or ''}")
    print(f"files={total}")
    print(f"indexed={indexed}")
    print(f"chunks={chunks}")
    print(f"token_estimate={tokens}")
    print(f"stored_documents={stored}")
    print(f"stored_chunks={stored_chunks}")
    print(f"stored_token_estimate={stored_tokens}")
    print(f"evidence_assets={evidence_assets}")
    print(f"access_log_entries={access['c']}")
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
