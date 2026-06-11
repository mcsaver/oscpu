# This module was split out of scripts/github_index_db.py.
from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path
from typing import Any, Sequence

from .core import *
from .queries import *

def count_by(conn: sqlite3.Connection, table: str, field: str) -> dict[str, int]:
    return {
        row[field]: row["c"]
        for row in conn.execute(
            f"SELECT {field}, COUNT(*) AS c FROM {table} GROUP BY {field} ORDER BY {field}"
        )
    }


def stats_payload(conn: sqlite3.Connection, db_path: Path) -> dict[str, Any]:
    meta = fetch_meta(conn)
    return {
        "op": "stat",
        "ok": True,
        "db": str(db_path),
        "schema_version": meta.get("schema_version", ""),
        "fts5": meta.get("fts5", "0") == "1",
        "root": meta.get("root", ""),
        "last_rebuild_at": meta.get("last_rebuild_at", ""),
        "files": conn.execute("SELECT COUNT(*) AS c FROM files").fetchone()["c"],
        "indexed": conn.execute("SELECT COUNT(*) AS c FROM files WHERE index_status='indexed'").fetchone()["c"],
        "chunks": conn.execute("SELECT COUNT(*) AS c FROM file_chunks").fetchone()["c"],
        "token_estimate": conn.execute(
            "SELECT COALESCE(SUM(token_estimate), 0) AS c FROM file_chunks"
        ).fetchone()["c"],
        "stored_documents": conn.execute("SELECT COUNT(*) AS c FROM db_documents").fetchone()["c"],
        "stored_chunks": conn.execute("SELECT COUNT(*) AS c FROM db_document_chunks").fetchone()["c"],
        "stored_token_estimate": conn.execute(
            "SELECT COALESCE(SUM(token_estimate), 0) AS c FROM db_document_chunks"
        ).fetchone()["c"],
        "status": count_by(conn, "files", "index_status"),
        "kind": count_by(conn, "files", "kind"),
    }


def request_terms(request: dict[str, Any]) -> list[str]:
    raw = request.get("terms", [])
    if isinstance(raw, str):
        return query_terms([raw])
    if isinstance(raw, Sequence):
        return query_terms([str(term) for term in raw])
    return []


def request_int(request: dict[str, Any], key: str, default: int, minimum: int = 1) -> int:
    try:
        value = int(request.get(key, default))
    except (TypeError, ValueError):
        return default
    return max(minimum, value)


def request_path_prefix(request: dict[str, Any]) -> str | None:
    raw = request.get("path")
    if raw is None or raw == "":
        return None
    return normalize_index_path(str(raw), str(request.get("root", DEFAULT_ROOT)))


def chunk_to_payload(row: sqlite3.Row) -> dict[str, Any]:
    return {
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


def live_summary_rows(
    conn: sqlite3.Connection,
    prefix: str,
    kind: str | None,
    status: str | None,
    limit: int,
) -> list[sqlite3.Row]:
    where = ["(f.path = ? OR f.path LIKE ?)"]
    params: list[object] = [prefix, prefix.rstrip("/") + "/%"]
    if kind:
        where.append("f.kind = ?")
        params.append(kind)
    if status:
        where.append("f.index_status = ?")
        params.append(status)
    params.append(limit)
    return conn.execute(
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
        ORDER BY f.path
        LIMIT ?
        """,
        params,
    ).fetchall()


def stored_summary_rows(
    conn: sqlite3.Connection,
    prefix: str,
    kind: str | None,
    limit: int,
) -> list[sqlite3.Row]:
    where = ["(d.path = ? OR d.path LIKE ?)"]
    params: list[object] = [prefix, prefix.rstrip("/") + "/%"]
    if kind:
        where.append("d.kind = ?")
        params.append(kind)
    params.append(limit)
    return conn.execute(
        f"""
        SELECT
          d.path, d.kind, 'stored' AS index_status, d.title, d.description,
          '' AS declared_status, d.tags, d.line_count,
          COUNT(c.chunk_id) AS chunk_count,
          COALESCE(SUM(c.token_estimate), 0) AS token_estimate,
          (
            SELECT c2.summary
            FROM db_document_chunks c2
            WHERE c2.path = d.path
            ORDER BY c2.ordinal
            LIMIT 1
          ) AS first_summary
        FROM db_documents d
        LEFT JOIN db_document_chunks c ON c.path = d.path
        WHERE {' AND '.join(where)}
        GROUP BY d.path
        ORDER BY d.path
        LIMIT ?
        """,
        params,
    ).fetchall()


def summary_payload_from_rows(rows: Sequence[sqlite3.Row], summary_chars: int) -> list[dict[str, Any]]:
    return [
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
            "summary": compact_text(row["description"] or row["first_summary"] or "", summary_chars),
        }
        for row in rows
    ]


def api_summary(conn: sqlite3.Connection, request: dict[str, Any]) -> dict[str, Any]:
    source = str(request.get("source", "stored"))
    prefix = request_path_prefix(request) or DEFAULT_ROOT
    kind = request.get("kind")
    status = request.get("status")
    limit = request_int(request, "limit", 40)
    summary_chars = request_int(request, "summary_chars", 240, 20)
    rows: list[sqlite3.Row] = []
    source_used = source
    if source in {"auto", "stored"}:
        rows = stored_summary_rows(conn, prefix, str(kind) if kind else None, limit)
        source_used = "stored"
    if source == "live" or (source == "auto" and not rows):
        rows = live_summary_rows(
            conn,
            prefix,
            str(kind) if kind else None,
            str(status) if status else None,
            limit,
        )
        source_used = "live"
    items = summary_payload_from_rows(rows, summary_chars)
    return {
        "op": "summary",
        "ok": True,
        "source": source_used,
        "path": prefix,
        "files": len(items),
        "chunks": sum(item["chunk_count"] for item in items),
        "token_estimate": sum(item["token_estimate"] for item in items),
        "items": items,
    }


def api_load(conn: sqlite3.Connection, request: dict[str, Any]) -> dict[str, Any]:
    terms = request_terms(request)
    path_prefix = request_path_prefix(request)
    if not terms and not path_prefix:
        return {"op": "load", "ok": False, "error": "load needs terms or path"}
    meta = fetch_meta(conn)
    source = str(request.get("source", "stored"))
    mode = str(request.get("mode", "auto"))
    kind = str(request["kind"]) if request.get("kind") else None
    status = str(request["status"]) if request.get("status") else None
    limit = request_int(request, "limit", 8)
    max_tokens = request_int(request, "max_tokens", 1800)
    fetch_limit = max(limit, limit * 4)
    used_mode = "path"
    rows: list[sqlite3.Row] = []
    if source in {"auto", "stored"}:
        if path_prefix and not terms:
            used_mode, rows = path_stored_rows(conn, path_prefix, kind, fetch_limit)
        elif mode in {"auto", "fts"} and meta.get("fts5") == "1":
            try:
                used_mode, rows = query_stored_rows_fts(conn, terms, path_prefix, kind, fetch_limit)
            except sqlite3.Error:
                used_mode, rows = query_stored_rows_like(conn, terms, path_prefix, kind, fetch_limit)
            else:
                if mode == "auto" and not rows:
                    used_mode, rows = query_stored_rows_like(conn, terms, path_prefix, kind, fetch_limit)
        else:
            used_mode, rows = query_stored_rows_like(conn, terms, path_prefix, kind, fetch_limit)
        if source == "stored" and not rows:
            used_mode = "stored-empty"
    if source == "live" or (source == "auto" and not rows):
        if path_prefix and not terms:
            used_mode, rows = path_chunk_rows(conn, path_prefix, kind, status, fetch_limit)
        elif mode in {"auto", "fts"} and meta.get("fts5") == "1":
            try:
                used_mode, rows = query_chunk_rows_fts(conn, terms, path_prefix, kind, status, fetch_limit)
            except sqlite3.Error:
                used_mode, rows = query_chunk_rows_like(conn, terms, path_prefix, kind, status, fetch_limit)
            else:
                if mode == "auto" and not rows:
                    used_mode, rows = query_chunk_rows_like(conn, terms, path_prefix, kind, status, fetch_limit)
        else:
            used_mode, rows = query_chunk_rows_like(conn, terms, path_prefix, kind, status, fetch_limit)
    selected = select_chunks_with_budget(rows[: limit * 4], max_tokens)[:limit]
    chunks = [chunk_to_payload(row) for row in selected]
    return {
        "op": "load",
        "ok": True,
        "source": "stored" if used_mode.startswith("stored") else "live",
        "mode": used_mode,
        "terms": terms,
        "path": path_prefix,
        "chunks": chunks,
        "token_estimate": sum(chunk["token_estimate"] for chunk in chunks),
    }


def api_search(conn: sqlite3.Connection, request: dict[str, Any]) -> dict[str, Any]:
    terms = request_terms(request)
    if not terms:
        return {"op": "search", "ok": False, "error": "search needs terms"}
    source = str(request.get("source", "stored"))
    mode = str(request.get("mode", "auto"))
    kind = str(request["kind"]) if request.get("kind") else None
    status = str(request["status"]) if request.get("status") else None
    path_prefix = request_path_prefix(request)
    limit = request_int(request, "limit", 20)
    snippet_chars = request_int(request, "snippet_chars", 220, 20)
    meta = fetch_meta(conn)
    used_mode = "like"
    results: list[dict[str, Any]] = []
    if source in {"auto", "stored"}:
        fetch_limit = max(limit, limit * 4)
        if mode in {"auto", "fts"} and meta.get("fts5") == "1":
            try:
                used_mode, rows = query_stored_rows_fts(conn, terms, path_prefix, kind, fetch_limit)
            except sqlite3.Error:
                used_mode, rows = query_stored_rows_like(conn, terms, path_prefix, kind, fetch_limit)
            else:
                if mode == "auto" and not rows:
                    used_mode, rows = query_stored_rows_like(conn, terms, path_prefix, kind, fetch_limit)
        else:
            used_mode, rows = query_stored_rows_like(conn, terms, path_prefix, kind, fetch_limit)
        seen: set[str] = set()
        for row in rows:
            if row["path"] in seen:
                continue
            seen.add(row["path"])
            line_offset, snippet = row_snippet(row["text"] or "", terms, snippet_chars)
            line_no = row["start_line"] + line_offset - 1 if line_offset else row["start_line"]
            results.append(
                {
                    "path": row["path"],
                    "kind": row["kind"],
                    "index_status": row["index_status"],
                    "title": row["title"],
                    "mode": used_mode,
                    "line": line_no,
                    "snippet": snippet or row["summary"] or "",
                }
            )
            if len(results) >= limit:
                break
        if source == "stored" or results:
            return {"op": "search", "ok": True, "source": "stored", "terms": terms, "results": results}
    if source in {"auto", "live"}:
        if mode in {"auto", "fts"} and meta.get("fts5") == "1":
            try:
                used_mode, rows = query_rows_fts(conn, terms, kind, status, limit)
            except sqlite3.Error:
                used_mode, rows = query_rows_like(conn, terms, kind, status, limit)
            else:
                if mode == "auto" and not rows:
                    used_mode, rows = query_rows_like(conn, terms, kind, status, limit)
        else:
            used_mode, rows = query_rows_like(conn, terms, kind, status, limit)
        for row in rows:
            line_no, snippet = row_snippet(row["content"] or "", terms, snippet_chars)
            results.append(
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
    return {"op": "search", "ok": True, "source": "live", "terms": terms, "results": results}


def api_show(conn: sqlite3.Connection, request: dict[str, Any]) -> dict[str, Any]:
    raw_path = request.get("path")
    if not raw_path:
        return {"op": "show", "ok": False, "error": "show needs path"}
    target = normalize_index_path(str(raw_path), str(request.get("root", DEFAULT_ROOT)))
    source = str(request.get("source", "auto"))
    include_content = bool(request.get("include_content", False))
    if source in {"auto", "stored"}:
        row = conn.execute("SELECT * FROM db_documents WHERE path = ?", (target,)).fetchone()
        if row is not None:
            data = dict(row)
            if not include_content:
                data.pop("content", None)
            return {"op": "show", "ok": True, "source": "stored", "document": data}
        if source == "stored":
            return {"op": "show", "ok": False, "error": f"not stored: {target}"}
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
        return {"op": "show", "ok": False, "error": f"not indexed: {target}"}
    data = dict(row)
    if not include_content:
        data.pop("content", None)
    return {"op": "show", "ok": True, "source": "live", "document": data}


def api_schema_payload() -> dict[str, Any]:
    return {
        "op": "schema",
        "ok": True,
        "protocol": "github-index-jsonl-v1",
        "default_source": "stored",
        "operations": {
            "stat": {"fields": []},
            "search": {"fields": ["terms", "source?", "path?", "kind?", "limit?", "mode?"]},
            "summary": {"fields": ["path?", "source?", "kind?", "limit?", "summary_chars?"]},
            "load": {"fields": ["terms?", "path?", "source?", "kind?", "limit?", "max_tokens?"]},
            "show": {"fields": ["path", "source?", "include_content?"]},
            "schema": {"fields": []},
        },
    }


def execute_api_request(conn: sqlite3.Connection, db_path: Path, request: dict[str, Any]) -> dict[str, Any]:
    op = str(request.get("op", "schema"))
    try:
        if op in {"schema", "help"}:
            return api_schema_payload()
        if op in {"stat", "stats"}:
            return stats_payload(conn, db_path)
        if op in {"search", "query"}:
            return api_search(conn, request)
        if op in {"summary", "compact"}:
            return api_summary(conn, request)
        if op == "load":
            return api_load(conn, request)
        if op == "show":
            return api_show(conn, request)
        return {"op": op, "ok": False, "error": f"unknown op: {op}"}
    except Exception as exc:  # API mode must return structured failures.
        return {"op": op, "ok": False, "error": str(exc)}


def read_api_requests(args: argparse.Namespace) -> tuple[list[dict[str, Any]], bool]:
    if args.request:
        payload = json.loads(args.request)
        if isinstance(payload, list):
            return payload, True
        return [payload], False
    raw = sys.stdin.read()
    if args.jsonl:
        requests = [json.loads(line) for line in raw.splitlines() if line.strip()]
        return requests, True
    if not raw.strip():
        return [{"op": "schema"}], False
    payload = json.loads(raw)
    if isinstance(payload, list):
        return payload, True
    return [payload], False


def memory_api(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    try:
        requests, force_jsonl = read_api_requests(args)
    except json.JSONDecodeError as exc:
        print(json.dumps({"ok": False, "error": f"invalid json: {exc}"}, ensure_ascii=False))
        return 2
    if not all(isinstance(request, dict) for request in requests):
        print(json.dumps({"ok": False, "error": "api requests must be JSON objects"}, ensure_ascii=False))
        return 2
    conn = open_db(db_path)
    init_schema(conn)
    try:
        responses = [execute_api_request(conn, db_path, request) for request in requests]
    finally:
        conn.close()
    jsonl = args.jsonl or force_jsonl or len(responses) > 1
    if jsonl:
        for response in responses:
            print(json.dumps(response, ensure_ascii=False, separators=(",", ":")))
    else:
        print(json.dumps(responses[0], ensure_ascii=False, indent=2))
    return 0 if all(response.get("ok") for response in responses) else 1
