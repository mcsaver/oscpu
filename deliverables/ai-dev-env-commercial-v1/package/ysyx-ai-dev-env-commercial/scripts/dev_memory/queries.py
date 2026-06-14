# This module was split out of scripts/github_index_db.py.
from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from typing import Sequence

from .core import *

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
    conn = open_db(db_path, readonly=True)
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


def summary(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path, readonly=True)
    prefix = normalize_index_path(args.path, args.root)
    where = ["(f.path = ? OR f.path LIKE ?)"]
    params: list[object] = [prefix, prefix.rstrip("/") + "/%"]
    if args.kind:
        where.append("f.kind = ?")
        params.append(args.kind)
    if args.status:
        where.append("f.index_status = ?")
        params.append(args.status)
    params.append(args.limit)
    rows = conn.execute(
        f"""
        SELECT
          f.path, f.kind, f.index_status, f.title, f.description,
          f.declared_status, f.tags, f.line_count,
          COUNT(c.chunk_id) AS chunk_count,
          COALESCE(SUM(c.token_estimate), 0) AS token_estimate,
          (
            SELECT c2.summary
            FROM file_chunks c2
            WHERE c2.path = f.path
            ORDER BY c2.ordinal
            LIMIT 1
          ) AS first_summary
        FROM files f
        LEFT JOIN file_chunks c ON c.path = f.path
        WHERE {' AND '.join(where)}
        GROUP BY f.path
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
    total_chunks = sum(row["chunk_count"] for row in rows)
    total_tokens = sum(row["token_estimate"] for row in rows)
    if args.json:
        payload = []
        for row in rows:
            payload.append(
                {
                    "path": row["path"],
                    "kind": row["kind"],
                    "index_status": row["index_status"],
                    "title": row["title"],
                    "description": row["description"],
                    "declared_status": row["declared_status"],
                    "tags": row["tags"],
                    "line_count": row["line_count"],
                    "chunk_count": row["chunk_count"],
                    "token_estimate": row["token_estimate"],
                    "summary": compact_text(row["description"] or row["first_summary"] or "", args.summary_chars),
                }
            )
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(
            f"summary={prefix} files={len(rows)} chunks={total_chunks} "
            f"token_estimate={total_tokens}"
        )
        for row in rows:
            declared = f" status={row['declared_status']}" if row["declared_status"] else ""
            print(
                f"{row['path']} [{row['kind']} {row['index_status']}] "
                f"lines={row['line_count']} chunks={row['chunk_count']} "
                f"tokens={row['token_estimate']}{declared} title={row['title']}"
            )
            text = compact_text(row["description"] or row["first_summary"] or "", args.summary_chars)
            if text:
                print(f"  {text}")
    conn.close()
    return 0


def show(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path, readonly=True)
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


def build_chunk_like_where(terms: Sequence[str], params: list[object]) -> str:
    clauses = []
    fields = ("c.path", "c.heading", "c.summary", "c.text", "f.title", "f.tags")
    for term in terms:
        sub = []
        like = f"%{term}%"
        for field in fields:
            sub.append(f"{field} LIKE ?")
            params.append(like)
        clauses.append("(" + " OR ".join(sub) + ")")
    return " AND ".join(clauses) if clauses else "1=1"


def query_chunk_rows_like(
    conn: sqlite3.Connection,
    terms: Sequence[str],
    path_prefix: str | None,
    kind: str | None,
    status: str | None,
    limit: int,
) -> tuple[str, list[sqlite3.Row]]:
    params: list[object] = []
    where = [build_chunk_like_where(terms, params)]
    if path_prefix:
        where.append("(c.path = ? OR c.path LIKE ?)")
        params.extend([path_prefix, path_prefix.rstrip("/") + "/%"])
    if kind:
        where.append("f.kind = ?")
        params.append(kind)
    if status:
        where.append("f.index_status = ?")
        params.append(status)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT c.*, f.kind, f.index_status, f.title, f.tags
        FROM file_chunks c
        JOIN files f ON f.path = c.path
        WHERE {' AND '.join(where)}
        ORDER BY c.path, c.ordinal
        LIMIT ?
        """,
        params,
    ).fetchall()
    return "chunk-like", rows


def query_chunk_rows_fts(
    conn: sqlite3.Connection,
    terms: Sequence[str],
    path_prefix: str | None,
    kind: str | None,
    status: str | None,
    limit: int,
) -> tuple[str, list[sqlite3.Row]]:
    where = ["chunk_fts MATCH ?"]
    params: list[object] = [fts_query_expression(terms)]
    if path_prefix:
        where.append("(c.path = ? OR c.path LIKE ?)")
        params.extend([path_prefix, path_prefix.rstrip("/") + "/%"])
    if kind:
        where.append("f.kind = ?")
        params.append(kind)
    if status:
        where.append("f.index_status = ?")
        params.append(status)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT c.*, f.kind, f.index_status, f.title, f.tags
        FROM chunk_fts
        JOIN file_chunks c ON c.chunk_id = chunk_fts.chunk_id
        JOIN files f ON f.path = c.path
        WHERE {' AND '.join(where)}
        ORDER BY bm25(chunk_fts), c.path, c.ordinal
        LIMIT ?
        """,
        params,
    ).fetchall()
    return "chunk-fts", rows


def path_chunk_rows(
    conn: sqlite3.Connection,
    path_prefix: str,
    kind: str | None,
    status: str | None,
    limit: int,
) -> tuple[str, list[sqlite3.Row]]:
    params: list[object] = [path_prefix, path_prefix.rstrip("/") + "/%"]
    where = ["(c.path = ? OR c.path LIKE ?)"]
    if kind:
        where.append("f.kind = ?")
        params.append(kind)
    if status:
        where.append("f.index_status = ?")
        params.append(status)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT c.*, f.kind, f.index_status, f.title, f.tags
        FROM file_chunks c
        JOIN files f ON f.path = c.path
        WHERE {' AND '.join(where)}
        ORDER BY c.path, c.ordinal
        LIMIT ?
        """,
        params,
    ).fetchall()
    return "path", rows


def query_stored_rows_like(
    conn: sqlite3.Connection,
    terms: Sequence[str],
    path_prefix: str | None,
    kind: str | None,
    limit: int,
) -> tuple[str, list[sqlite3.Row]]:
    params: list[object] = []
    where = [build_chunk_like_where(terms, params).replace("f.", "d.")]
    if path_prefix:
        where.append("(c.path = ? OR c.path LIKE ?)")
        params.extend([path_prefix, path_prefix.rstrip("/") + "/%"])
    if kind:
        where.append("d.kind = ?")
        params.append(kind)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT c.*, d.kind, 'stored' AS index_status, d.title, d.tags
        FROM db_document_chunks c
        JOIN db_documents d ON d.path = c.path
        WHERE {' AND '.join(where)}
        ORDER BY c.path, c.ordinal
        LIMIT ?
        """,
        params,
    ).fetchall()
    return "stored-like", rows


def query_stored_rows_fts(
    conn: sqlite3.Connection,
    terms: Sequence[str],
    path_prefix: str | None,
    kind: str | None,
    limit: int,
) -> tuple[str, list[sqlite3.Row]]:
    where = ["document_fts MATCH ?"]
    params: list[object] = [fts_query_expression(terms)]
    if path_prefix:
        where.append("(c.path = ? OR c.path LIKE ?)")
        params.extend([path_prefix, path_prefix.rstrip("/") + "/%"])
    if kind:
        where.append("d.kind = ?")
        params.append(kind)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT c.*, d.kind, 'stored' AS index_status, d.title, d.tags
        FROM document_fts
        JOIN db_document_chunks c ON c.chunk_id = document_fts.chunk_id
        JOIN db_documents d ON d.path = c.path
        WHERE {' AND '.join(where)}
        ORDER BY bm25(document_fts), c.path, c.ordinal
        LIMIT ?
        """,
        params,
    ).fetchall()
    return "stored-fts", rows


def path_stored_rows(
    conn: sqlite3.Connection,
    path_prefix: str,
    kind: str | None,
    limit: int,
) -> tuple[str, list[sqlite3.Row]]:
    params: list[object] = [path_prefix, path_prefix.rstrip("/") + "/%"]
    where = ["(c.path = ? OR c.path LIKE ?)"]
    if kind:
        where.append("d.kind = ?")
        params.append(kind)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT c.*, d.kind, 'stored' AS index_status, d.title, d.tags
        FROM db_document_chunks c
        JOIN db_documents d ON d.path = c.path
        WHERE {' AND '.join(where)}
        ORDER BY c.path, c.ordinal
        LIMIT ?
        """,
        params,
    ).fetchall()
    return "stored-path", rows


def select_chunks_with_budget(rows: Sequence[sqlite3.Row], max_tokens: int) -> list[sqlite3.Row]:
    selected: list[sqlite3.Row] = []
    used = 0
    for row in rows:
        tokens = int(row["token_estimate"] or 0)
        if selected and used + tokens > max_tokens:
            break
        selected.append(row)
        used += tokens
        if used >= max_tokens:
            break
    return selected


def load_chunks(args: argparse.Namespace) -> int:
    terms = query_terms(args.terms)
    path_prefix = normalize_index_path(args.path, args.root) if args.path else None
    if not terms and not path_prefix:
        print("FAIL load needs query terms or --path", file=sys.stderr)
        return 2
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = open_db(db_path, readonly=True)
    meta = fetch_meta(conn)
    fetch_limit = max(args.limit, args.limit * 4)
    used_mode = "path"
    rows: list[sqlite3.Row]
    rows = []
    if args.source in {"auto", "stored"}:
        if path_prefix and not terms:
            used_mode, rows = path_stored_rows(conn, path_prefix, args.kind, fetch_limit)
        elif args.mode in {"auto", "fts"} and meta.get("fts5") == "1":
            try:
                used_mode, rows = query_stored_rows_fts(
                    conn,
                    terms,
                    path_prefix,
                    args.kind,
                    fetch_limit,
                )
            except sqlite3.Error as exc:
                if args.source == "stored" and args.mode == "fts":
                    print(f"FAIL stored fts query: {exc}", file=sys.stderr)
                    return 2
                used_mode, rows = query_stored_rows_like(
                    conn,
                    terms,
                    path_prefix,
                    args.kind,
                    fetch_limit,
                )
            else:
                if args.mode == "auto" and not rows:
                    used_mode, rows = query_stored_rows_like(
                        conn,
                        terms,
                        path_prefix,
                        args.kind,
                        fetch_limit,
                    )
        else:
            used_mode, rows = query_stored_rows_like(
                conn,
                terms,
                path_prefix,
                args.kind,
                fetch_limit,
            )
        if args.source == "stored" and not rows:
            used_mode = "stored-empty"
    if args.source == "live" or (args.source == "auto" and not rows):
        if path_prefix and not terms:
            used_mode, rows = path_chunk_rows(conn, path_prefix, args.kind, args.status, fetch_limit)
        elif args.mode in {"auto", "fts"} and meta.get("fts5") == "1":
            try:
                used_mode, rows = query_chunk_rows_fts(
                    conn,
                    terms,
                    path_prefix,
                    args.kind,
                    args.status,
                    fetch_limit,
                )
            except sqlite3.Error as exc:
                if args.mode == "fts":
                    print(f"FAIL chunk fts query: {exc}", file=sys.stderr)
                    return 2
                used_mode, rows = query_chunk_rows_like(
                    conn,
                    terms,
                    path_prefix,
                    args.kind,
                    args.status,
                    fetch_limit,
                )
            else:
                if args.mode == "auto" and not rows:
                    used_mode, rows = query_chunk_rows_like(
                        conn,
                        terms,
                        path_prefix,
                        args.kind,
                        args.status,
                        fetch_limit,
                    )
        else:
            used_mode, rows = query_chunk_rows_like(
                conn,
                terms,
                path_prefix,
                args.kind,
                args.status,
                fetch_limit,
            )
    selected = select_chunks_with_budget(rows[: args.limit * 4], args.max_tokens)[: args.limit]
    token_total = sum(int(row["token_estimate"] or 0) for row in selected)
    if args.json:
        payload = []
        for row in selected:
            payload.append(
                {
                    "chunk_id": row["chunk_id"],
                    "path": row["path"],
                    "kind": row["kind"],
                    "index_status": row["index_status"],
                    "title": row["title"],
                    "heading": row["heading"],
                    "start_line": row["start_line"],
                    "end_line": row["end_line"],
                    "token_estimate": row["token_estimate"],
                    "summary": row["summary"],
                    "text": row["text"],
                }
            )
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        label = path_prefix if path_prefix and not terms else " ".join(terms)
        print(f"load={label} mode={used_mode} chunks={len(selected)} token_estimate={token_total}")
        for row in selected:
            print(
                f"--- {row['chunk_id']} lines={row['start_line']}-{row['end_line']} "
                f"tokens={row['token_estimate']} [{row['kind']} {row['index_status']}]"
            )
            print(f"title={row['title']}")
            print(f"heading={row['heading']}")
            if row["summary"]:
                print(f"summary={row['summary']}")
            print(row["text"])
    conn.close()
    return 0
