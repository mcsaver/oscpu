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

BRIEF_CORE_PATHS = (
    "AGENTS.md",
    ".github/AGENTS.md",
    ".github/copilot-instructions.md",
    ".github/memory/project-status.md",
    ".github/memory/known-issues.md",
    ".github/e2e/README.md",
)


def count_by(conn: sqlite3.Connection, table: str, field: str) -> dict[str, int]:
    return {
        row[field]: row["c"]
        for row in conn.execute(
            f"SELECT {field}, COUNT(*) AS c FROM {table} GROUP BY {field} ORDER BY {field}"
        )
    }


def stats_payload(conn: sqlite3.Connection, db_path: Path) -> dict[str, Any]:
    meta = fetch_meta(conn)
    access = conn.execute(
        "SELECT COUNT(*) AS c, MAX(used_at) AS last_used_at FROM access_log"
    ).fetchone()
    return {
        "op": "stat",
        "ok": True,
        "db": str(db_path),
        "schema_version": meta.get("schema_version", ""),
        "fts5": meta.get("fts5", "0") == "1",
        "root": meta.get("root", ""),
        "last_rebuild_at": meta.get("last_rebuild_at", ""),
        "last_used_at": access["last_used_at"] or "",
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
        "evidence_assets": conn.execute("SELECT COUNT(*) AS c FROM evidence_assets").fetchone()["c"],
        "access_log_entries": access["c"],
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


def brief_profile_paths(profile: str) -> list[str]:
    profile = profile.strip().replace("\\", "/").strip("/")
    if not profile:
        return []
    return [
        f".github/e2e/profiles/{profile}.tsv",
        f".github/e2e/modules/{profile}.md",
        f".github/agents/{profile}.agent.md",
        f".github/memory/modules/{profile}.md",
    ]


def add_brief_rows(
    rows_by_chunk: dict[str, sqlite3.Row],
    rows: Sequence[sqlite3.Row],
    token_budget: int,
) -> int:
    used = sum(int(row["token_estimate"] or 0) for row in rows_by_chunk.values())
    added = 0
    for row in rows:
        chunk_id = row["chunk_id"]
        tokens = int(row["token_estimate"] or 0)
        if chunk_id in rows_by_chunk:
            continue
        if rows_by_chunk and used + tokens > token_budget:
            break
        rows_by_chunk[chunk_id] = row
        used += tokens
        added += 1
    return added


def stored_rows_for_path(conn: sqlite3.Connection, path: str, limit: int) -> list[sqlite3.Row]:
    _, rows = path_stored_rows(conn, normalize_index_path(path), None, limit)
    return rows


def profile_name_from_path(path: str) -> str | None:
    if path.startswith(".github/e2e/profiles/") and path.endswith(".tsv"):
        return Path(path).stem
    if path.startswith(".github/e2e/modules/") and path.endswith(".md"):
        return Path(path).stem
    return None


def task_run_id_from_path(path: str) -> str | None:
    parts = Path(path).parts
    if len(parts) >= 3 and parts[:2] == (".github", "task-runs"):
        return parts[2]
    return None


def markdown_fields(content: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for raw_line in content.splitlines():
        line = raw_line.strip()
        if not line.startswith("- `") or "`:" not in line:
            continue
        key_end = line.find("`:", 3)
        if key_end == -1:
            continue
        fields[line[3:key_end]] = line[key_end + 2 :].strip()
    return fields


def is_db_backed_payload(path: str, content: str) -> bool:
    return f"DB-backed {path}" in content and "load --source stored" in content


def merged_document_rows(
    conn: sqlite3.Connection,
    kinds: Sequence[str],
    paths: Sequence[str] | None = None,
) -> list[dict[str, Any]]:
    kind_placeholders = ",".join("?" for _ in kinds)
    live_where = [f"f.kind IN ({kind_placeholders})", "f.index_status = 'indexed'"]
    live_params: list[object] = list(kinds)
    stored_where = [f"kind IN ({kind_placeholders})"]
    stored_params: list[object] = list(kinds)
    if paths:
        normalized = [normalize_index_path(path) for path in paths]
        path_placeholders = ",".join("?" for _ in normalized)
        live_where.append(f"f.path IN ({path_placeholders})")
        live_params.extend(normalized)
        stored_where.append(f"path IN ({path_placeholders})")
        stored_params.extend(normalized)

    stored_rows = conn.execute(
        f"""
        SELECT path, kind, title, description, content, 'stored' AS source
        FROM db_documents
        WHERE {' AND '.join(stored_where)}
        ORDER BY path
        """,
        stored_params,
    ).fetchall()
    merged: dict[str, dict[str, Any]] = {row["path"]: dict(row) for row in stored_rows}

    live_rows = conn.execute(
        f"""
        SELECT f.path, f.kind, f.title, f.description, t.content, 'live' AS source
        FROM files f
        JOIN file_text t ON t.path = f.path
        WHERE {' AND '.join(live_where)}
        ORDER BY f.path
        """,
        live_params,
    ).fetchall()
    for row in live_rows:
        content = row["content"] or ""
        if not is_db_backed_payload(row["path"], content):
            merged[row["path"]] = dict(row)
    return [merged[path] for path in sorted(merged)]


def profile_suggestions(
    conn: sqlite3.Connection,
    terms: Sequence[str],
    requested_profile: str,
    limit: int,
) -> list[dict[str, Any]]:
    rows = merged_document_rows(conn, ("e2e-profile", "e2e-module"))
    suggestions: dict[str, dict[str, Any]] = {}
    normalized_terms = [term.lower() for term in terms if term]
    for row in rows:
        profile = profile_name_from_path(row["path"])
        if not profile:
            continue
        haystack = " ".join(
            str(row[key] or "")
            for key in ("path", "title", "description", "content")
        ).lower()
        matched_terms = [term for term in normalized_terms if term in haystack]
        name_hits = [term for term in normalized_terms if term in profile.lower()]
        score = len(matched_terms) + (2 * len(name_hits))
        if requested_profile and profile == requested_profile:
            score += 8
            matched_terms.append("requested-profile")
        if score <= 0:
            continue
        entry = suggestions.setdefault(
            profile,
            {
                "profile": profile,
                "score": 0,
                "matched_terms": [],
                "source_paths": [],
                "command": f"scripts/agent-e2e.sh --profile {profile}",
            },
        )
        entry["score"] += score
        entry["matched_terms"] = sorted(set(entry["matched_terms"]) | set(matched_terms) | set(name_hits))
        if row["path"] not in entry["source_paths"]:
            entry["source_paths"].append(row["path"])
    return sorted(
        suggestions.values(),
        key=lambda item: (-int(item["score"]), item["profile"]),
    )[:limit]


PROFILE_NODE_FIELDS = ("node_id", "module", "function", "owner_agent", "inputs", "outputs")


def parse_profile_entries(content: str) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    for raw_line in content.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        parts = [part.strip() for part in line.split("|")]
        if parts[0] == "@include":
            if len(parts) > 1 and parts[1]:
                entries.append({"type": "include", "profile": parts[1]})
            continue
        if parts[0] == "node_id":
            continue
        values = [*parts, *([""] * len(PROFILE_NODE_FIELDS))][: len(PROFILE_NODE_FIELDS)]
        entries.append({"type": "node", "node": dict(zip(PROFILE_NODE_FIELDS, values))})
    return entries


def parse_profile_rows(content: str) -> tuple[list[str], list[dict[str, str]]]:
    includes: list[str] = []
    nodes: list[dict[str, str]] = []
    for entry in parse_profile_entries(content):
        if entry["type"] == "include":
            includes.append(entry["profile"])
        elif entry["type"] == "node":
            nodes.append(entry["node"])
    return includes, nodes


def stored_profile_row(conn: sqlite3.Connection, profile: str) -> dict[str, Any] | None:
    path = f".github/e2e/profiles/{profile}.tsv"
    rows = merged_document_rows(conn, ("e2e-profile",), [path])
    return rows[0] if rows else None


def profile_catalog_payload(conn: sqlite3.Connection, request: dict[str, Any]) -> dict[str, Any]:
    terms = request_terms(request)
    include_nodes = bool(request.get("include_nodes", False))
    limit = request_int(request, "limit", 80)
    normalized_terms = [term.lower() for term in terms if term]
    rows = merged_document_rows(conn, ("e2e-profile",))
    profiles: list[dict[str, Any]] = []
    for row in rows:
        profile = profile_name_from_path(row["path"])
        if not profile:
            continue
        includes, nodes = parse_profile_rows(row["content"] or "")
        haystack = " ".join(
            [
                profile,
                str(row["path"] or ""),
                str(row["title"] or ""),
                str(row["description"] or ""),
                str(row["content"] or ""),
            ]
        ).lower()
        matched_terms = [term for term in normalized_terms if term in haystack]
        name_hits = [term for term in normalized_terms if term in profile.lower()]
        score = len(matched_terms) + (2 * len(name_hits))
        if normalized_terms and score <= 0:
            continue
        entry: dict[str, Any] = {
            "profile": profile,
            "path": row["path"],
            "title": row["title"] or profile,
            "description": row["description"] or "",
            "includes": includes,
            "node_count": len(nodes),
            "modules": sorted({node["module"] for node in nodes if node.get("module")}),
            "owners": sorted({node["owner_agent"] for node in nodes if node.get("owner_agent")}),
            "matched_terms": sorted(set(matched_terms) | set(name_hits)),
            "score": score,
            "command": f"scripts/agent-e2e.sh --profile {profile}",
        }
        if include_nodes:
            entry["nodes"] = nodes
        profiles.append(entry)
    profiles.sort(key=lambda item: (-int(item["score"]), item["profile"]))
    return {
        "op": "profiles",
        "ok": True,
        "source": "live-or-stored",
        "terms": terms,
        "profiles": profiles[:limit],
    }


def resolve_profile_payload(conn: sqlite3.Connection, request: dict[str, Any]) -> dict[str, Any]:
    profile = str(request.get("profile", "")).strip()
    if not profile:
        return {"op": "resolve-profile", "ok": False, "error": "resolve-profile needs profile"}
    include_nodes = bool(request.get("include_nodes", True))
    max_depth = request_int(request, "max_depth", 64)
    profile_order: list[str] = []
    seen_profiles: set[str] = set()
    include_edges: list[dict[str, str]] = []
    expanded_nodes: list[dict[str, str]] = []
    missing_profiles: list[str] = []
    cycles: list[list[str]] = []
    depth_exceeded: list[str] = []

    def visit(current: str, stack: list[str]) -> None:
        if len(stack) > max_depth:
            depth_exceeded.append(current)
            return
        if current in stack:
            cycle_start = stack.index(current)
            cycles.append([*stack[cycle_start:], current])
            return
        row = stored_profile_row(conn, current)
        if row is None:
            if current not in missing_profiles:
                missing_profiles.append(current)
            return
        if current not in seen_profiles:
            seen_profiles.add(current)
            profile_order.append(current)
        next_stack = [*stack, current]
        for entry in parse_profile_entries(row["content"] or ""):
            if entry["type"] == "include":
                included = entry["profile"]
                include_edges.append({"from": current, "to": included})
                visit(included, next_stack)
            elif entry["type"] == "node":
                node = dict(entry["node"])
                node["source_profile"] = current
                expanded_nodes.append(node)

    visit(profile, [])
    modules = sorted({node["module"] for node in expanded_nodes if node.get("module")})
    owners = sorted({node["owner_agent"] for node in expanded_nodes if node.get("owner_agent")})
    payload: dict[str, Any] = {
        "op": "resolve-profile",
        "ok": not missing_profiles and not cycles and not depth_exceeded,
        "source": "live-or-stored",
        "profile": profile,
        "profile_order": profile_order,
        "include_edges": include_edges,
        "expanded_node_count": len(expanded_nodes),
        "modules": modules,
        "owners": owners,
        "missing_profiles": missing_profiles,
        "cycles": cycles,
        "depth_exceeded": depth_exceeded,
        "command": f"scripts/agent-e2e.sh --profile {profile}",
        "validate_command": f"scripts/agent-e2e.sh --validate-profile --profile {profile}",
    }
    if include_nodes:
        payload["nodes"] = expanded_nodes
    return payload


def task_run_artifacts(conn: sqlite3.Connection, run_id: str) -> dict[str, Any]:
    prefix = f".github/task-runs/{run_id}/"
    rows = conn.execute(
        """
        SELECT path, kind
        FROM db_documents
        WHERE path LIKE ?
        ORDER BY path
        """,
        (f"{prefix}%",),
    ).fetchall()
    artifacts: dict[str, Any] = {
        "report_path": "",
        "dispatch_path": "",
        "context_brief_path": "",
        "profile_resolve_path": "",
        "evidence_index_path": "",
        "stored_markdown_count": len(rows),
        "evidence_markdown_count": 0,
        "evidence_asset_count": conn.execute(
            "SELECT COUNT(*) AS c FROM evidence_assets WHERE run_id = ?",
            (run_id,),
        ).fetchone()["c"],
    }
    for row in rows:
        path = row["path"]
        if path == f"{prefix}task-report.md":
            artifacts["report_path"] = path
        elif path == f"{prefix}dispatch-log.md":
            artifacts["dispatch_path"] = path
        elif path == f"{prefix}context-brief.md":
            artifacts["context_brief_path"] = path
        elif path == f"{prefix}profile-resolve.md":
            artifacts["profile_resolve_path"] = path
        elif path == f"{prefix}evidence-index.md":
            artifacts["evidence_index_path"] = path
        elif "/evidence/" in path:
            artifacts["evidence_markdown_count"] += 1
    return artifacts


def task_run_profile_resolve_summary(conn: sqlite3.Connection, run_id: str) -> dict[str, Any]:
    row = conn.execute(
        "SELECT content FROM db_documents WHERE path = ?",
        (f".github/task-runs/{run_id}/profile-resolve.md",),
    ).fetchone()
    if row is None:
        return {}
    fields = markdown_fields(row["content"] or "")
    summary: dict[str, Any] = {}
    if "expanded_node_count" in fields:
        try:
            summary["expanded_node_count"] = int(fields["expanded_node_count"])
        except ValueError:
            summary["expanded_node_count"] = fields["expanded_node_count"]
    if "profile_order" in fields:
        summary["profile_order"] = [
            item.strip()
            for item in fields["profile_order"].split(",")
            if item.strip() and item.strip() != "<none>"
        ]
    return summary


def task_runs_payload(conn: sqlite3.Connection, request: dict[str, Any]) -> dict[str, Any]:
    terms = request_terms(request)
    profile_filter = str(request.get("profile", "")).strip()
    status_filter = str(request.get("status", "")).strip()
    include_artifacts = bool(request.get("include_artifacts", True))
    limit = request_int(request, "limit", 20)
    normalized_terms = [term.lower() for term in terms if term]
    rows = conn.execute(
        """
        SELECT path, title, description, content, stored_at
        FROM db_documents
        WHERE kind = 'task-report'
          AND path LIKE '.github/task-runs/%/task-report.md'
        ORDER BY path DESC
        """
    ).fetchall()
    runs: list[dict[str, Any]] = []
    for row in rows:
        run_id = task_run_id_from_path(row["path"])
        if not run_id:
            continue
        fields = markdown_fields(row["content"] or "")
        profile = fields.get("profile", "")
        status = fields.get("status", "")
        if profile_filter and profile != profile_filter:
            continue
        if status_filter and status != status_filter:
            continue
        haystack = " ".join(
            [
                run_id,
                row["path"] or "",
                row["title"] or "",
                row["description"] or "",
                row["content"] or "",
                profile,
                status,
            ]
        ).lower()
        matched_terms = [term for term in normalized_terms if term in haystack]
        if normalized_terms and not matched_terms:
            continue
        item: dict[str, Any] = {
            "run_id": run_id,
            "task_slug": fields.get("task_slug", ""),
            "profile": profile,
            "status": status,
            "started_at": fields.get("started_at", ""),
            "updated_at": fields.get("updated_at", row["stored_at"] or ""),
            "final_result": fields.get("final_result", ""),
            "matched_terms": matched_terms,
            "report_path": row["path"],
        }
        if include_artifacts:
            item.update(task_run_artifacts(conn, run_id))
            item.update(task_run_profile_resolve_summary(conn, run_id))
        runs.append(item)
    runs.sort(
        key=lambda item: (
            str(item.get("updated_at") or ""),
            str(item.get("started_at") or ""),
            str(item.get("run_id") or ""),
        ),
        reverse=True,
    )
    return {
        "op": "runs",
        "ok": True,
        "source": "stored",
        "terms": terms,
        "profile": profile_filter,
        "status": status_filter,
        "runs": runs[:limit],
    }


def brief_payload(conn: sqlite3.Connection, db_path: Path, request: dict[str, Any]) -> dict[str, Any]:
    terms = request_terms(request)
    profile = str(request.get("profile", "")).strip()
    max_tokens = request_int(request, "max_tokens", 2400, 200)
    core_limit = request_int(request, "core_limit", 1)
    focus_limit = request_int(request, "focus_limit", 8)
    profile_limit = request_int(request, "profile_limit", 5)
    extra_paths = request.get("paths", [])
    if isinstance(extra_paths, str):
        extra_paths = [extra_paths]
    elif not isinstance(extra_paths, Sequence):
        extra_paths = []

    selected_paths: list[str] = []
    for path in [*BRIEF_CORE_PATHS, *brief_profile_paths(profile), *[str(path) for path in extra_paths]]:
        normalized = normalize_index_path(path)
        if normalized not in selected_paths:
            selected_paths.append(normalized)

    rows_by_chunk: dict[str, sqlite3.Row] = {}
    missing_paths: list[str] = []
    for path in selected_paths:
        rows = stored_rows_for_path(conn, path, core_limit)
        if not rows:
            _, rows = path_chunk_rows(conn, path, None, "indexed", core_limit)
        if rows:
            add_brief_rows(rows_by_chunk, rows, max_tokens)
        else:
            missing_paths.append(path)

    if terms:
        meta = fetch_meta(conn)
        focus_rows: list[sqlite3.Row] = []
        try:
            if meta.get("fts5") == "1":
                _, focus_rows = query_stored_rows_fts(conn, terms, None, None, max(focus_limit, focus_limit * 4))
            else:
                _, focus_rows = query_stored_rows_like(conn, terms, None, None, max(focus_limit, focus_limit * 4))
        except sqlite3.Error:
            _, focus_rows = query_stored_rows_like(conn, terms, None, None, max(focus_limit, focus_limit * 4))
        add_brief_rows(rows_by_chunk, focus_rows, max_tokens)
        try:
            if meta.get("fts5") == "1":
                _, live_focus_rows = query_chunk_rows_fts(
                    conn,
                    terms,
                    None,
                    None,
                    "indexed",
                    max(focus_limit, focus_limit * 4),
                )
            else:
                _, live_focus_rows = query_chunk_rows_like(
                    conn,
                    terms,
                    None,
                    None,
                    "indexed",
                    max(focus_limit, focus_limit * 4),
                )
        except sqlite3.Error:
            _, live_focus_rows = query_chunk_rows_like(
                conn,
                terms,
                None,
                None,
                "indexed",
                max(focus_limit, focus_limit * 4),
            )
        add_brief_rows(rows_by_chunk, live_focus_rows, max_tokens)

    chunks = [chunk_to_payload(row) for row in rows_by_chunk.values()]
    token_estimate = sum(int(chunk["token_estimate"] or 0) for chunk in chunks)
    suggestions = profile_suggestions(conn, terms, profile, profile_limit)
    commands = [
        "python3 scripts/github_index_db.py brief <terms> --profile <profile>",
        "python3 scripts/github_index_db.py load --source auto --path <path>",
        "python3 scripts/github_index_db.py audit-db-first",
        "python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence",
        "scripts/agent-e2e.sh --list-profiles",
    ]
    if profile:
        commands.append(f"scripts/agent-e2e.sh --profile {profile}")
    elif suggestions:
        commands.extend(suggestion["command"] for suggestion in suggestions[:3])
    return {
        "op": "brief",
        "ok": True,
        "db": str(db_path),
        "profile": profile,
        "terms": terms,
        "source": "live-or-stored",
        "token_estimate": token_estimate,
        "max_tokens": max_tokens,
        "selected_paths": selected_paths,
        "missing_paths": missing_paths,
        "profile_suggestions": suggestions,
        "commands": commands,
        "chunks": chunks,
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


def usage_payload(conn: sqlite3.Connection, request: dict[str, Any]) -> dict[str, Any]:
    limit = request_int(request, "limit", 20)
    op_filter = str(request.get("filter_op") or request.get("command") or "").strip()
    surface_filter = str(request.get("surface") or "").strip()
    where: list[str] = []
    params: list[object] = []
    if op_filter:
        where.append("op = ?")
        params.append(op_filter)
    if surface_filter:
        where.append("surface = ?")
        params.append(surface_filter)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT id, used_at, surface, op, source, target, ok, result_count, details
        FROM access_log
        {'WHERE ' + ' AND '.join(where) if where else ''}
        ORDER BY used_at DESC, id DESC
        LIMIT ?
        """,
        params,
    ).fetchall()
    total = conn.execute("SELECT COUNT(*) AS c FROM access_log").fetchone()["c"]
    last = conn.execute("SELECT MAX(used_at) AS v FROM access_log").fetchone()["v"] or ""
    by_op = {
        row["op"]: row["c"]
        for row in conn.execute("SELECT op, COUNT(*) AS c FROM access_log GROUP BY op ORDER BY op")
    }
    by_surface = {
        row["surface"]: row["c"]
        for row in conn.execute(
            "SELECT surface, COUNT(*) AS c FROM access_log GROUP BY surface ORDER BY surface"
        )
    }
    entries = []
    for row in rows:
        try:
            details = json.loads(row["details"] or "{}")
        except json.JSONDecodeError:
            details = {}
        entries.append(
            {
                "id": row["id"],
                "used_at": row["used_at"],
                "surface": row["surface"],
                "op": row["op"],
                "source": row["source"],
                "target": row["target"],
                "ok": bool(row["ok"]),
                "result_count": row["result_count"],
                "details": details,
            }
        )
    return {
        "op": "usage",
        "ok": True,
        "source": "access_log",
        "last_used_at": last,
        "total": total,
        "by_op": by_op,
        "by_surface": by_surface,
        "entries": entries,
    }


def evidence_assets_payload(conn: sqlite3.Connection, request: dict[str, Any]) -> dict[str, Any]:
    terms = request_terms(request)
    run_id = str(request.get("run_id") or request.get("run") or "").strip()
    profile = str(request.get("profile") or "").strip()
    kind = str(request.get("kind") or "").strip()
    limit = request_int(request, "limit", 40)
    where: list[str] = []
    params: list[object] = []
    if run_id:
        where.append("run_id = ?")
        params.append(run_id)
    if profile:
        where.append("profile = ?")
        params.append(profile)
    if kind:
        where.append("kind = ?")
        params.append(kind)
    for term in terms:
        like = f"%{term}%"
        where.append(
            "(path LIKE ? OR run_id LIKE ? OR task_slug LIKE ? OR profile LIKE ? OR summary LIKE ? OR markers LIKE ?)"
        )
        params.extend([like, like, like, like, like, like])
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT *
        FROM evidence_assets
        {'WHERE ' + ' AND '.join(where) if where else ''}
        ORDER BY indexed_at DESC, run_id DESC, path
        LIMIT ?
        """,
        params,
    ).fetchall()
    assets = []
    for row in rows:
        try:
            markers = json.loads(row["markers"] or "{}")
        except json.JSONDecodeError:
            markers = {}
        assets.append(
            {
                "path": row["path"],
                "run_id": row["run_id"],
                "task_slug": row["task_slug"],
                "profile": row["profile"],
                "kind": row["kind"],
                "size_bytes": row["size_bytes"],
                "mtime_ns": row["mtime_ns"],
                "sha256": row["sha256"],
                "line_count": row["line_count"],
                "encoding": row["encoding"],
                "summary": row["summary"],
                "head_excerpt": row["head_excerpt"],
                "tail_excerpt": row["tail_excerpt"],
                "markers": markers,
                "indexed_at": row["indexed_at"],
            }
        )
    return {
        "op": "evidence",
        "ok": True,
        "source": "evidence_assets",
        "terms": terms,
        "run_id": run_id,
        "profile": profile,
        "kind": kind,
        "assets": assets,
    }


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
            "brief": {"fields": ["terms?", "profile?", "paths?", "max_tokens?", "profile_limit?"]},
            "profiles": {"fields": ["terms?", "limit?", "include_nodes?"]},
            "resolve-profile": {"fields": ["profile", "include_nodes?", "max_depth?"]},
            "runs": {"fields": ["terms?", "profile?", "status?", "limit?", "include_artifacts?"]},
            "evidence": {"fields": ["terms?", "run_id?", "profile?", "kind?", "limit?"]},
            "usage": {"fields": ["limit?", "surface?", "filter_op?"]},
            "schema": {"fields": []},
        },
    }


def execute_api_request(conn: sqlite3.Connection, db_path: Path, request: dict[str, Any]) -> dict[str, Any]:
    op = str(request.get("op", "schema"))
    try:
        if op in {"usage", "access-log", "used"}:
            return usage_payload(conn, request)
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
        if op in {"brief", "context", "context-pack"}:
            return brief_payload(conn, db_path, request)
        if op in {"profiles", "profile-catalog", "list-profiles"}:
            return profile_catalog_payload(conn, request)
        if op in {"resolve-profile", "profile", "profile-resolve"}:
            return resolve_profile_payload(conn, request)
        if op in {"runs", "task-runs", "run-catalog"}:
            return task_runs_payload(conn, request)
        if op in {"evidence", "evidence-assets", "asset-index"}:
            return evidence_assets_payload(conn, request)
        return {"op": op, "ok": False, "error": f"unknown op: {op}"}
    except Exception as exc:  # API mode must return structured failures.
        return {"op": op, "ok": False, "error": str(exc)}


def api_result_count(response: dict[str, Any]) -> int:
    for key in ("results", "chunks", "profiles", "nodes", "runs", "assets", "entries"):
        value = response.get(key)
        if isinstance(value, list):
            return len(value)
    document = response.get("document")
    if isinstance(document, dict):
        return 1
    if response.get("ok"):
        return 1
    return 0


def api_request_target(request: dict[str, Any]) -> str:
    for key in ("path", "profile", "kind", "status"):
        value = request.get(key)
        if value:
            return str(value)
    terms = request_terms(request)
    return " ".join(terms)


def sanitized_api_request(request: dict[str, Any]) -> dict[str, object]:
    clean: dict[str, object] = {}
    for key, value in request.items():
        if key in {"content", "text"}:
            clean[key] = "<redacted>"
        else:
            clean[key] = value
    return clean


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
    conn = open_db(db_path, readonly=True)
    try:
        responses = [execute_api_request(conn, db_path, request) for request in requests]
    finally:
        conn.close()
    access_rows = []
    for request, response in zip(requests, responses):
        op = str(response.get("op") or request.get("op") or "schema")
        if op == "usage":
            continue
        access_rows.append((request, response, op))
    if access_rows:
        log_conn = None
        try:
            log_conn = open_db(db_path, timeout=0.2, busy_timeout_ms=200)
            init_schema(log_conn)
            for request, response, op in access_rows:
                record_access(
                    log_conn,
                    surface="api",
                    op=op,
                    source=str(response.get("source") or request.get("source") or ""),
                    target=api_request_target(request),
                    ok=bool(response.get("ok")),
                    result_count=api_result_count(response),
                    details={"request": sanitized_api_request(request)},
                )
            log_conn.commit()
        except sqlite3.Error as exc:
            print(f"WARN skip api access log: {exc}", file=sys.stderr)
        finally:
            if log_conn is not None:
                log_conn.close()
    jsonl = args.jsonl or force_jsonl or len(responses) > 1
    if jsonl:
        for response in responses:
            print(json.dumps(response, ensure_ascii=False, separators=(",", ":")))
    else:
        print(json.dumps(responses[0], ensure_ascii=False, indent=2))
    return 0 if all(response.get("ok") for response in responses) else 1


def render_brief_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Agent Brief",
        "",
        f"- `source`: {payload.get('source', '')}",
        f"- `profile`: {payload.get('profile') or '<none>'}",
        f"- `terms`: {' '.join(payload.get('terms') or []) or '<none>'}",
        f"- `token_estimate`: {payload.get('token_estimate', 0)} / {payload.get('max_tokens', 0)}",
        "",
        "## Profile Suggestions",
    ]
    suggestions = payload.get("profile_suggestions") or []
    if suggestions:
        for suggestion in suggestions:
            matched = ", ".join(suggestion.get("matched_terms") or [])
            lines.append(
                f"- `{suggestion['profile']}` score={suggestion['score']} matched={matched or '<none>'} command=`{suggestion['command']}`"
            )
    else:
        lines.append("- <none>")
    lines.extend([
        "",
        "## Commands",
    ])
    for command in payload.get("commands", []):
        lines.append(f"- `{command}`")
    missing = payload.get("missing_paths") or []
    if missing:
        lines.extend(["", "## Missing Paths"])
        for path in missing:
            lines.append(f"- `{path}`")
    lines.extend(["", "## Chunks"])
    for chunk in payload.get("chunks", []):
        lines.extend(
            [
                "",
                f"### {chunk['path']}#{chunk['chunk_id'].split('#')[-1]}",
                "",
                f"- `kind`: {chunk['kind']}",
                f"- `lines`: {chunk['start_line']}-{chunk['end_line']}",
                f"- `tokens`: {chunk['token_estimate']}",
                f"- `heading`: {chunk['heading']}",
            ]
        )
        if chunk.get("summary"):
            lines.append(f"- `summary`: {chunk['summary']}")
        lines.extend(["", chunk.get("text", "")])
    lines.append("")
    return "\n".join(lines)


def render_profiles_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# E2E Profile Catalog",
        "",
        f"- `source`: {payload.get('source', '')}",
        f"- `terms`: {' '.join(payload.get('terms') or []) or '<none>'}",
        f"- `profiles`: {len(payload.get('profiles') or [])}",
        "",
        "## Profiles",
    ]
    for profile in payload.get("profiles", []):
        includes = ", ".join(profile.get("includes") or []) or "<none>"
        modules = ", ".join(profile.get("modules") or []) or "<none>"
        owners = ", ".join(profile.get("owners") or []) or "<none>"
        matched = ", ".join(profile.get("matched_terms") or []) or "<none>"
        lines.extend(
            [
                "",
                f"### {profile['profile']}",
                "",
                f"- `path`: {profile['path']}",
                f"- `nodes`: {profile['node_count']}",
                f"- `includes`: {includes}",
                f"- `modules`: {modules}",
                f"- `owners`: {owners}",
                f"- `matched`: {matched}",
                f"- `command`: {profile['command']}",
            ]
        )
        if profile.get("description"):
            lines.append(f"- `description`: {profile['description']}")
        if profile.get("nodes"):
            lines.append("- `node_ids`: " + ", ".join(node["node_id"] for node in profile["nodes"] if node.get("node_id")))
    lines.append("")
    return "\n".join(lines)


def render_resolved_profile_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# E2E Resolved Profile",
        "",
        f"- `source`: {payload.get('source', '')}",
        f"- `profile`: {payload.get('profile', '')}",
        f"- `ok`: {payload.get('ok')}",
        f"- `expanded_node_count`: {payload.get('expanded_node_count', 0)}",
        f"- `profile_order`: {', '.join(payload.get('profile_order') or []) or '<none>'}",
        f"- `modules`: {', '.join(payload.get('modules') or []) or '<none>'}",
        f"- `owners`: {', '.join(payload.get('owners') or []) or '<none>'}",
        f"- `command`: {payload.get('command', '')}",
        f"- `validate_command`: {payload.get('validate_command', '')}",
    ]
    if payload.get("include_edges"):
        lines.extend(["", "## Include Edges"])
        for edge in payload["include_edges"]:
            lines.append(f"- `{edge['from']}` -> `{edge['to']}`")
    if payload.get("missing_profiles"):
        lines.extend(["", "## Missing Profiles"])
        for missing in payload["missing_profiles"]:
            lines.append(f"- `{missing}`")
    if payload.get("cycles"):
        lines.extend(["", "## Cycles"])
        for cycle in payload["cycles"]:
            lines.append("- " + " -> ".join(f"`{item}`" for item in cycle))
    if payload.get("depth_exceeded"):
        lines.extend(["", "## Depth Exceeded"])
        for profile in payload["depth_exceeded"]:
            lines.append(f"- `{profile}`")
    if payload.get("nodes"):
        lines.extend(["", "## Nodes"])
        for index, node in enumerate(payload["nodes"], start=1):
            lines.append(
                f"{index}. `{node['node_id']}` source=`{node['source_profile']}` "
                f"module=`{node['module']}` owner=`{node['owner_agent']}` function=`{node['function']}`"
            )
    lines.append("")
    return "\n".join(lines)


def render_runs_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# E2E Task Runs",
        "",
        f"- `source`: {payload.get('source', '')}",
        f"- `profile`: {payload.get('profile') or '<any>'}",
        f"- `status`: {payload.get('status') or '<any>'}",
        f"- `terms`: {' '.join(payload.get('terms') or []) or '<none>'}",
        f"- `runs`: {len(payload.get('runs') or [])}",
        "",
        "## Runs",
    ]
    for run in payload.get("runs", []):
        lines.extend(
            [
                "",
                f"### {run['run_id']}",
                "",
                f"- `task_slug`: {run.get('task_slug', '')}",
                f"- `profile`: {run.get('profile', '')}",
                f"- `status`: {run.get('status', '')}",
                f"- `started_at`: {run.get('started_at', '')}",
                f"- `updated_at`: {run.get('updated_at', '')}",
                f"- `report_path`: {run.get('report_path', '')}",
            ]
        )
        if run.get("dispatch_path"):
            lines.append(f"- `dispatch_path`: {run['dispatch_path']}")
        if run.get("context_brief_path"):
            lines.append(f"- `context_brief_path`: {run['context_brief_path']}")
        if run.get("profile_resolve_path"):
            lines.append(f"- `profile_resolve_path`: {run['profile_resolve_path']}")
        if run.get("evidence_index_path"):
            lines.append(f"- `evidence_index_path`: {run['evidence_index_path']}")
        if "evidence_asset_count" in run:
            lines.append(f"- `evidence_asset_count`: {run.get('evidence_asset_count', 0)}")
        if "expanded_node_count" in run:
            lines.append(f"- `expanded_node_count`: {run.get('expanded_node_count', '')}")
        if run.get("profile_order"):
            lines.append("- `profile_order`: " + ", ".join(run["profile_order"]))
        if run.get("final_result"):
            lines.append(f"- `final_result`: {run['final_result']}")
    lines.append("")
    return "\n".join(lines)


def render_usage_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# DB Usage",
        "",
        f"- `source`: {payload.get('source', '')}",
        f"- `last_used_at`: {payload.get('last_used_at') or '<none>'}",
        f"- `total`: {payload.get('total', 0)}",
        "",
        "## Recent Access",
    ]
    entries = payload.get("entries") or []
    if not entries:
        lines.append("- <none>")
    for entry in entries:
        target = entry.get("target") or "<none>"
        source = entry.get("source") or "<none>"
        lines.extend(
            [
                "",
                f"### {entry.get('used_at', '')}",
                "",
                f"- `surface`: {entry.get('surface', '')}",
                f"- `op`: {entry.get('op', '')}",
                f"- `source`: {source}",
                f"- `target`: {target}",
                f"- `ok`: {entry.get('ok')}",
                f"- `result_count`: {entry.get('result_count', 0)}",
            ]
        )
    lines.append("")
    return "\n".join(lines)


def render_evidence_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Evidence Assets",
        "",
        f"- `source`: {payload.get('source', '')}",
        f"- `run_id`: {payload.get('run_id') or '<any>'}",
        f"- `profile`: {payload.get('profile') or '<any>'}",
        f"- `kind`: {payload.get('kind') or '<any>'}",
        f"- `terms`: {' '.join(payload.get('terms') or []) or '<none>'}",
        f"- `assets`: {len(payload.get('assets') or [])}",
        "",
        "## Assets",
    ]
    assets = payload.get("assets") or []
    if not assets:
        lines.append("- <none>")
    for asset in assets:
        markers = json.dumps(asset.get("markers") or {}, ensure_ascii=False, sort_keys=True)
        lines.extend(
            [
                "",
                f"### {asset.get('path', '')}",
                "",
                f"- `run_id`: {asset.get('run_id', '')}",
                f"- `profile`: {asset.get('profile', '')}",
                f"- `kind`: {asset.get('kind', '')}",
                f"- `size_bytes`: {asset.get('size_bytes', 0)}",
                f"- `line_count`: {asset.get('line_count', 0)}",
                f"- `sha256`: {asset.get('sha256', '')}",
                f"- `indexed_at`: {asset.get('indexed_at', '')}",
                f"- `markers`: {markers}",
                f"- `summary`: {asset.get('summary', '')}",
            ]
        )
    lines.append("")
    return "\n".join(lines)


def agent_evidence(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    request = {
        "op": "evidence",
        "terms": args.terms,
        "run_id": args.run_id,
        "profile": args.profile,
        "kind": args.kind,
        "limit": args.limit,
    }
    conn = open_db(db_path, readonly=True)
    try:
        payload = evidence_assets_payload(conn, request)
    finally:
        conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(render_evidence_markdown(payload))
    return 0 if payload.get("ok") else 1


def agent_usage(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    request = {
        "op": "usage",
        "limit": args.limit,
        "surface": args.surface,
        "filter_op": args.filter_op,
    }
    conn = open_db(db_path, readonly=True)
    try:
        payload = usage_payload(conn, request)
    finally:
        conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(render_usage_markdown(payload))
    return 0 if payload.get("ok") else 1


def agent_brief(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    request = {
        "op": "brief",
        "terms": args.terms,
        "profile": args.profile,
        "paths": args.path,
        "max_tokens": args.max_tokens,
        "core_limit": args.core_limit,
        "focus_limit": args.focus_limit,
        "profile_limit": args.profile_limit,
    }
    conn = open_db(db_path, readonly=True)
    try:
        payload = brief_payload(conn, db_path, request)
    finally:
        conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(render_brief_markdown(payload))
    return 0 if payload.get("ok") else 1


def agent_runs(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    request = {
        "op": "runs",
        "terms": args.terms,
        "profile": args.profile,
        "status": args.status,
        "limit": args.limit,
        "include_artifacts": args.include_artifacts,
    }
    conn = open_db(db_path, readonly=True)
    try:
        payload = task_runs_payload(conn, request)
    finally:
        conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(render_runs_markdown(payload))
    return 0 if payload.get("ok") else 1


def agent_profiles(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    request = {
        "op": "profiles",
        "terms": args.terms,
        "limit": args.limit,
        "include_nodes": args.include_nodes,
    }
    conn = open_db(db_path, readonly=True)
    try:
        payload = profile_catalog_payload(conn, request)
    finally:
        conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(render_profiles_markdown(payload))
    return 0 if payload.get("ok") else 1


def agent_resolve_profile(args: argparse.Namespace) -> int:
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    request = {
        "op": "resolve-profile",
        "profile": args.profile,
        "include_nodes": args.include_nodes,
        "max_depth": args.max_depth,
    }
    conn = open_db(db_path)
    init_schema(conn)
    try:
        payload = resolve_profile_payload(conn, request)
    finally:
        conn.close()
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(render_resolved_profile_markdown(payload))
    return 0 if payload.get("ok") else 1
