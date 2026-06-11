# This module was split out of scripts/github_index_db.py.
from __future__ import annotations

import argparse
import sys
from typing import Sequence

from .api import memory_api
from .core import *
from .maintenance import *
from .queries import *

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
    rebuild_cmd.add_argument(
        "--include",
        action="append",
        default=list(DEFAULT_EXTRA_SOURCES),
        help="additional repo-relative file or directory to index; defaults include agent entry shims",
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

    summary_cmd = subparsers.add_parser(
        "summary",
        aliases=["compact"],
        help="print compressed summaries for indexed files under a path",
    )
    add_common_db_args(summary_cmd)
    summary_cmd.add_argument("path", nargs="?", default=DEFAULT_ROOT)
    summary_cmd.add_argument("--root", default=DEFAULT_ROOT)
    summary_cmd.add_argument("--kind")
    summary_cmd.add_argument("--status")
    summary_cmd.add_argument("--limit", type=int, default=40)
    summary_cmd.add_argument("--summary-chars", type=int, default=240)
    summary_cmd.add_argument("--json", action="store_true")
    summary_cmd.set_defaults(func=summary)

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

    load_cmd = subparsers.add_parser(
        "load",
        help="load only matching indexed chunks by query terms or path",
    )
    add_common_db_args(load_cmd)
    load_cmd.add_argument("terms", nargs="*")
    load_cmd.add_argument("--path")
    load_cmd.add_argument("--root", default=DEFAULT_ROOT)
    load_cmd.add_argument("--kind")
    load_cmd.add_argument("--status")
    load_cmd.add_argument("--mode", choices=["auto", "fts", "like"], default="auto")
    load_cmd.add_argument("--source", choices=["auto", "live", "stored"], default="auto")
    load_cmd.add_argument("--limit", type=int, default=8)
    load_cmd.add_argument("--max-tokens", type=int, default=1800)
    load_cmd.add_argument("--json", action="store_true")
    load_cmd.set_defaults(func=load_chunks)

    api_cmd = subparsers.add_parser(
        "api",
        help="read-only JSON/JSONL API for external AI memory clients",
    )
    add_common_db_args(api_cmd)
    api_cmd.add_argument("--request", help="single JSON request object or array")
    api_cmd.add_argument(
        "--jsonl",
        action="store_true",
        help="read newline-delimited JSON requests and write newline-delimited JSON responses",
    )
    api_cmd.set_defaults(func=memory_api)

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

    promote_cmd = subparsers.add_parser("promote", help="store indexed agent/memory documents inside the database")
    add_common_db_args(promote_cmd)
    promote_cmd.add_argument("--path", action="append", default=[])
    promote_cmd.add_argument("--kind", action="append", default=[])
    promote_cmd.add_argument("--limit", type=int, default=20)
    promote_cmd.set_defaults(func=promote_documents)

    update_stored_cmd = subparsers.add_parser(
        "update-stored",
        help="update one database-owned stored document from explicit content",
    )
    add_common_db_args(update_stored_cmd)
    update_stored_cmd.add_argument("path")
    update_stored_cmd.add_argument("--content")
    update_stored_cmd.add_argument("--from-file")
    update_stored_cmd.add_argument("--stdin", action="store_true")
    update_stored_cmd.add_argument("--refresh-shim", action="store_true")
    update_stored_cmd.add_argument("--backup-dir", default=DEFAULT_DB_BACKUP_ROOT)
    update_stored_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    update_stored_cmd.set_defaults(func=update_stored_document)

    backup_cmd = subparsers.add_parser("backup", help="copy indexed agent/memory documents into a backup directory")
    add_common_db_args(backup_cmd)
    backup_cmd.add_argument("--path", action="append", default=[])
    backup_cmd.add_argument("--kind", action="append", default=[])
    backup_cmd.add_argument("--backup-dir", default=DEFAULT_DB_BACKUP_ROOT)
    backup_cmd.set_defaults(func=backup_documents)

    migrate_cmd = subparsers.add_parser(
        "migrate",
        help="promote documents into the DB, back up originals, and leave compatibility shims",
    )
    add_common_db_args(migrate_cmd)
    migrate_cmd.add_argument("--path", action="append", default=[])
    migrate_cmd.add_argument("--kind", action="append", default=[])
    migrate_cmd.add_argument("--backup-dir", default=DEFAULT_DB_BACKUP_ROOT)
    migrate_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    migrate_cmd.add_argument("--limit", type=int, default=20)
    migrate_cmd.add_argument("--yes", action="store_true")
    migrate_cmd.set_defaults(func=migrate_to_db)

    archive_markdown_cmd = subparsers.add_parser(
        "archive-markdown",
        help="store live Markdown files in the DB, back up originals, and leave compatibility shims",
    )
    add_common_db_args(archive_markdown_cmd)
    archive_markdown_cmd.add_argument("path", nargs="+")
    archive_markdown_cmd.add_argument("--backup-dir", default=DEFAULT_DB_BACKUP_ROOT)
    archive_markdown_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    archive_markdown_cmd.add_argument("--limit", type=int, default=20)
    archive_markdown_cmd.add_argument("--yes", action="store_true")
    archive_markdown_cmd.set_defaults(func=archive_markdown_files)

    materialize_cmd = subparsers.add_parser(
        "materialize",
        help="write stored database documents back to files under an output root",
    )
    add_common_db_args(materialize_cmd)
    materialize_cmd.add_argument("--path", action="append", default=[])
    materialize_cmd.add_argument("--output-root", default=".")
    materialize_cmd.set_defaults(func=materialize_documents)

    restore_cmd = subparsers.add_parser("restore", help="restore files from a backup directory manifest")
    add_common_db_args(restore_cmd)
    restore_cmd.add_argument("--backup-dir", required=True)
    restore_cmd.add_argument("--path", action="append", default=[])
    restore_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    restore_cmd.add_argument("--yes", action="store_true")
    restore_cmd.set_defaults(func=restore_backup)

    audit_cmd = subparsers.add_parser(
        "audit-db-first",
        help="verify DB-owned documents, compatibility shims, and backup manifest coverage",
    )
    add_common_db_args(audit_cmd)
    audit_cmd.add_argument("--kind", action="append", default=[])
    audit_cmd.add_argument("--backup-dir", default="")
    audit_cmd.add_argument("--limit", type=int, default=20)
    audit_cmd.add_argument("--json", action="store_true")
    audit_cmd.set_defaults(func=audit_db_first)

    markdown_audit_cmd = subparsers.add_parser(
        "audit-markdown-coverage",
        help="verify active Markdown is DB-owned; optionally fail while task-run evidence is still live",
    )
    add_common_db_args(markdown_audit_cmd)
    markdown_audit_cmd.add_argument("--limit", type=int, default=20)
    markdown_audit_cmd.add_argument("--json", action="store_true")
    markdown_audit_cmd.add_argument("--show-evidence", action="store_true")
    markdown_audit_cmd.add_argument("--fail-on-live-evidence", action="store_true")
    markdown_audit_cmd.set_defaults(func=audit_markdown_coverage)

    smoke_cmd = subparsers.add_parser("smoke", help="run rebuild/stat/query/doctor on a temp DB")
    smoke_cmd.add_argument("--repo-root", default=".")
    smoke_cmd.add_argument("--root", default=DEFAULT_ROOT)
    smoke_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    smoke_cmd.add_argument("--exclude", action="append", default=[])
    smoke_cmd.add_argument(
        "--include",
        action="append",
        default=list(DEFAULT_EXTRA_SOURCES),
        help="additional repo-relative file or directory to index",
    )
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
