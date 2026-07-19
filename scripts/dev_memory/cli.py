# This module was split out of scripts/github_index_db.py.
from __future__ import annotations

import argparse
import sqlite3
import sys
from typing import Sequence

from .api import (
    agent_brief,
    agent_evidence,
    agent_profiles,
    agent_resolve_profile,
    agent_runs,
    agent_usage,
    memory_api,
)
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
    def init_database(args: argparse.Namespace) -> int:
        conn = open_db((resolve_repo_path(args.repo_root) / args.db).resolve())
        try:
            init_schema(conn)
        finally:
            conn.close()
        return 0

    init_cmd.set_defaults(func=init_database)

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

    brief_cmd = subparsers.add_parser(
        "brief",
        aliases=["context", "context-pack"],
        help="build a bounded live-or-stored startup context pack for an agent",
    )
    add_common_db_args(brief_cmd)
    brief_cmd.add_argument("terms", nargs="*", help="focus terms for relevant chunks")
    brief_cmd.add_argument("--profile", default="", help="e2e profile or module name to include")
    brief_cmd.add_argument("--path", action="append", default=[], help="extra stored document path to include")
    brief_cmd.add_argument("--max-tokens", type=int, default=2400)
    brief_cmd.add_argument("--core-limit", type=int, default=1)
    brief_cmd.add_argument("--focus-limit", type=int, default=8)
    brief_cmd.add_argument(
        "--focus-scope",
        choices=["all", "non-history"],
        default="all",
        help="allow all focus kinds, or require current non-history focus only",
    )
    brief_cmd.add_argument("--profile-limit", type=int, default=5)
    brief_cmd.add_argument("--json", action="store_true")
    brief_cmd.set_defaults(func=agent_brief)

    profiles_cmd = subparsers.add_parser(
        "profiles",
        aliases=["profile-catalog", "list-profiles"],
        help="list live-or-stored e2e profiles for agent/e2e selection",
    )
    add_common_db_args(profiles_cmd)
    profiles_cmd.add_argument("terms", nargs="*", help="optional terms to filter profile catalog")
    profiles_cmd.add_argument("--limit", type=int, default=80)
    profiles_cmd.add_argument("--include-nodes", action="store_true")
    profiles_cmd.add_argument("--json", action="store_true")
    profiles_cmd.set_defaults(func=agent_profiles)

    resolve_profile_cmd = subparsers.add_parser(
        "resolve-profile",
        aliases=["profile", "profile-resolve"],
        help="expand one live-or-stored e2e profile including transitive includes",
    )
    add_common_db_args(resolve_profile_cmd)
    resolve_profile_cmd.add_argument("profile")
    resolve_profile_cmd.add_argument("--include-nodes", dest="include_nodes", action="store_true")
    resolve_profile_cmd.add_argument("--no-include-nodes", dest="include_nodes", action="store_false")
    resolve_profile_cmd.set_defaults(include_nodes=True)
    resolve_profile_cmd.add_argument("--max-depth", type=int, default=64)
    resolve_profile_cmd.add_argument("--json", action="store_true")
    resolve_profile_cmd.set_defaults(func=agent_resolve_profile)

    runs_cmd = subparsers.add_parser(
        "runs",
        aliases=["task-runs", "run-catalog"],
        help="list retained e2e task-run reports and linked artifacts",
    )
    add_common_db_args(runs_cmd)
    runs_cmd.add_argument("terms", nargs="*", help="optional terms to filter task runs")
    runs_cmd.add_argument("--profile", default="")
    runs_cmd.add_argument("--status", default="")
    runs_cmd.add_argument("--limit", type=int, default=20)
    runs_cmd.add_argument("--include-artifacts", dest="include_artifacts", action="store_true")
    runs_cmd.add_argument("--no-include-artifacts", dest="include_artifacts", action="store_false")
    runs_cmd.set_defaults(include_artifacts=True)
    runs_cmd.add_argument("--json", action="store_true")
    runs_cmd.set_defaults(func=agent_runs)

    evidence_cmd = subparsers.add_parser(
        "evidence",
        aliases=["evidence-assets", "asset-index"],
        help="list structured summaries for raw task-run evidence assets",
    )
    add_common_db_args(evidence_cmd)
    evidence_cmd.add_argument("terms", nargs="*", help="optional terms to filter evidence summaries")
    evidence_cmd.add_argument("--run-id", default="")
    evidence_cmd.add_argument("--profile", default="")
    evidence_cmd.add_argument("--kind", default="")
    evidence_cmd.add_argument("--limit", type=int, default=40)
    evidence_cmd.add_argument("--json", action="store_true")
    evidence_cmd.set_defaults(func=agent_evidence)

    usage_cmd = subparsers.add_parser(
        "usage",
        aliases=["used", "access-log"],
        help="show when this SQLite memory database was used",
    )
    add_common_db_args(usage_cmd)
    usage_cmd.add_argument("--limit", type=int, default=20)
    usage_cmd.add_argument("--surface", choices=["", "cli", "api"], default="")
    usage_cmd.add_argument("--filter-op", default="")
    usage_cmd.add_argument("--json", action="store_true")
    usage_cmd.set_defaults(func=agent_usage)

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
    doctor_cmd.add_argument(
        "--show-nonblocking-drift",
        action="store_true",
        help="show historical archive/live-index-cache diagnostic counters that do not affect --fail-on-drift",
    )
    doctor_cmd.add_argument(
        "--show-diagnostic-details",
        action="store_true",
        help="show nonblocking diagnostic state buckets and sample paths for maintenance triage",
    )
    doctor_cmd.add_argument(
        "--show-status-samples",
        action="store_true",
        help="show sample paths for ordinary indexed/skipped status buckets",
    )
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

    promote_cmd = subparsers.add_parser("promote", help="store indexed memory/log documents inside the database")
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

    backup_cmd = subparsers.add_parser("backup", help="copy indexed memory/log documents into a backup directory")
    add_common_db_args(backup_cmd)
    backup_cmd.add_argument("--path", action="append", default=[])
    backup_cmd.add_argument("--kind", action="append", default=[])
    backup_cmd.add_argument("--backup-dir", default=DEFAULT_DB_BACKUP_ROOT)
    backup_cmd.set_defaults(func=backup_documents)

    snapshot_cmd = subparsers.add_parser(
        "snapshot-stored",
        help="copy current database-owned stored documents into a rehydratable backup manifest",
    )
    add_common_db_args(snapshot_cmd)
    snapshot_cmd.add_argument("--path", action="append", default=[])
    snapshot_cmd.add_argument("--kind", action="append", default=[])
    snapshot_cmd.add_argument("--backup-dir", default=f"{DEFAULT_DB_BACKUP_ROOT}/stored-snapshot")
    snapshot_cmd.add_argument("--yes", action="store_true")
    snapshot_cmd.set_defaults(func=snapshot_stored_documents)

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
        help="store live memory/log Markdown files in the DB, back up originals, and leave compatibility shims",
    )
    add_common_db_args(archive_markdown_cmd)
    archive_markdown_cmd.add_argument("path", nargs="+")
    archive_markdown_cmd.add_argument("--backup-dir", default=DEFAULT_DB_BACKUP_ROOT)
    archive_markdown_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    archive_markdown_cmd.add_argument("--limit", type=int, default=20)
    archive_markdown_cmd.add_argument("--write-shim", action="store_true")
    archive_markdown_cmd.add_argument(
        "--sync-task-run",
        action="store_true",
        help="for one task-run directory, atomically prune stored Markdown paths absent from the live run",
    )
    archive_markdown_cmd.add_argument("--yes", action="store_true")
    archive_markdown_cmd.set_defaults(func=archive_markdown_files)

    publish_task_run_cmd = subparsers.add_parser(
        "publish-task-run",
        help="atomically publish one marker-bound completed task run after staged Markdown sync",
    )
    add_common_db_args(publish_task_run_cmd)
    publish_task_run_cmd.add_argument("path")
    publish_task_run_cmd.add_argument("--yes", action="store_true")
    publish_task_run_cmd.set_defaults(func=publish_task_run)

    index_evidence_cmd = subparsers.add_parser(
        "index-evidence",
        aliases=["evidence-index", "archive-evidence"],
        help="index raw task-run evidence assets without storing full logs in the DB",
    )
    add_common_db_args(index_evidence_cmd)
    index_evidence_cmd.add_argument("path", nargs="+")
    index_evidence_cmd.add_argument("--write-index", action="store_true")
    index_evidence_cmd.add_argument("--backup-dir", default=f"{DEFAULT_DB_BACKUP_ROOT}/stored-snapshot")
    index_evidence_cmd.add_argument("--sample-bytes", type=int, default=65536)
    index_evidence_cmd.add_argument("--excerpt-chars", type=int, default=500)
    index_evidence_cmd.add_argument("--limit", type=int, default=20)
    index_evidence_cmd.add_argument("--json", action="store_true")
    index_evidence_cmd.add_argument("--yes", action="store_true")
    index_evidence_cmd.set_defaults(func=index_evidence_assets)

    materialize_cmd = subparsers.add_parser(
        "materialize",
        help="write stored database documents back to files under an output root",
    )
    add_common_db_args(materialize_cmd)
    materialize_cmd.add_argument("--path", action="append", default=[])
    materialize_cmd.add_argument("--output-root", default=".")
    materialize_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    materialize_cmd.add_argument(
        "--prune-non-retained",
        action="store_true",
        help="after materializing, remove non memory/log stored documents from the DB",
    )
    materialize_cmd.set_defaults(func=materialize_documents)

    restore_cmd = subparsers.add_parser("restore", help="restore files from a backup directory manifest")
    add_common_db_args(restore_cmd)
    restore_cmd.add_argument("--backup-dir", required=True)
    restore_cmd.add_argument("--path", action="append", default=[])
    restore_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    restore_cmd.add_argument("--yes", action="store_true")
    restore_cmd.set_defaults(func=restore_backup)

    rehydrate_cmd = subparsers.add_parser(
        "rehydrate",
        aliases=["import-backup"],
        help="recreate stored documents from backup manifests after the cache DB is missing",
    )
    add_common_db_args(rehydrate_cmd)
    rehydrate_cmd.add_argument("--backup-dir", default="")
    rehydrate_cmd.add_argument("--path", action="append", default=[])
    rehydrate_cmd.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    rehydrate_cmd.add_argument("--limit", type=int, default=20)
    rehydrate_cmd.add_argument("--yes", action="store_true")
    rehydrate_cmd.set_defaults(func=rehydrate_stored_documents)

    audit_cmd = subparsers.add_parser(
        "audit-db-first",
        help="verify DB-owned documents, compatibility shims, and backup manifest coverage",
    )
    add_common_db_args(audit_cmd)
    audit_cmd.add_argument("--kind", action="append", default=[])
    audit_cmd.add_argument("--backup-dir", default="")
    audit_cmd.add_argument("--limit", type=int, default=20)
    audit_cmd.add_argument("--json", action="store_true")
    audit_cmd.add_argument(
        "--show-nonblocking-drift",
        action="store_true",
        help="show archived/live task-run drift samples that do not affect audit success",
    )
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

    skill_audit_cmd = subparsers.add_parser(
        "skill-audit",
        help="verify live .github/skills/*/SKILL.md standardized rule packs",
    )
    skill_audit_cmd.add_argument("--repo-root", default=".")
    skill_audit_cmd.add_argument("--path", default=".github/skills")
    skill_audit_cmd.add_argument("--limit", type=int, default=20)
    skill_audit_cmd.add_argument("--json", action="store_true")
    skill_audit_cmd.set_defaults(func=skill_audit)

    policy_audit_cmd = subparsers.add_parser(
        "policy-audit",
        help="verify agent environment policy, tool scopes, retention roots, and CI gate wiring",
    )
    add_common_db_args(policy_audit_cmd)
    policy_audit_cmd.add_argument("--policy", default=".github/ai-env/contracts/agent-env-policy.json")
    policy_audit_cmd.add_argument("--limit", type=int, default=40)
    policy_audit_cmd.add_argument("--json", action="store_true")
    policy_audit_cmd.set_defaults(func=policy_audit)

    report_audit_cmd = subparsers.add_parser(
        "report-audit",
        help="verify the report-derived AI environment rebuild traceability matrix",
    )
    report_audit_cmd.add_argument("--repo-root", default=".")
    report_audit_cmd.add_argument("--matrix", default=".github/ai-env/contracts/agent-env-rebuild-matrix.json")
    report_audit_cmd.add_argument("--requirement-id", action="append", default=[])
    report_audit_cmd.add_argument("--limit", type=int, default=40)
    report_audit_cmd.add_argument("--json", action="store_true")
    report_audit_cmd.set_defaults(func=report_audit)

    schema_audit_cmd = subparsers.add_parser(
        "schema-audit",
        help="verify the explicit DB schema and read-only API contract against the live SQLite database",
    )
    add_common_db_args(schema_audit_cmd)
    schema_audit_cmd.add_argument("--contract", default=".github/ai-env/contracts/agent-env-schema-contract.json")
    schema_audit_cmd.add_argument("--limit", type=int, default=40)
    schema_audit_cmd.add_argument("--json", action="store_true")
    schema_audit_cmd.set_defaults(func=schema_audit)

    artifact_audit_cmd = subparsers.add_parser(
        "artifact-audit",
        aliases=["runtime-artifact-audit"],
        help="verify runtime/source artifact boundaries and raw evidence index-only retention",
    )
    add_common_db_args(artifact_audit_cmd)
    artifact_audit_cmd.add_argument("--contract", default=".github/ai-env/contracts/agent-env-runtime-artifacts.json")
    artifact_audit_cmd.add_argument("--policy", default=".github/ai-env/contracts/agent-env-policy.json")
    artifact_audit_cmd.add_argument("--schema-contract", default=".github/ai-env/contracts/agent-env-schema-contract.json")
    artifact_audit_cmd.add_argument("--observability-contract", default=".github/ai-env/contracts/agent-env-observability.json")
    artifact_audit_cmd.add_argument("--run-id", default="")
    artifact_audit_cmd.add_argument("--latest", action="store_true")
    artifact_audit_cmd.add_argument("--limit", type=int, default=40)
    artifact_audit_cmd.add_argument("--json", action="store_true")
    artifact_audit_cmd.set_defaults(func=artifact_audit)

    delivery_audit_cmd = subparsers.add_parser(
        "delivery-audit",
        aliases=["commercial-delivery-audit"],
        help="verify commercial delivery package, legacy archive, and packaging boundaries",
    )
    add_common_db_args(delivery_audit_cmd)
    delivery_audit_cmd.add_argument("--contract", default=".github/ai-env/contracts/agent-env-delivery.json")
    delivery_audit_cmd.add_argument("--policy", default=".github/ai-env/contracts/agent-env-policy.json")
    delivery_audit_cmd.add_argument("--limit", type=int, default=40)
    delivery_audit_cmd.add_argument("--json", action="store_true")
    delivery_audit_cmd.set_defaults(func=delivery_audit)

    branch_health_report_cmd = subparsers.add_parser(
        "branch-health-report",
        aliases=["branch-report", "health-dashboard"],
        help="print the lightweight branch health dashboard for the AI environment",
    )
    add_common_db_args(branch_health_report_cmd)
    branch_health_report_cmd.add_argument("--dashboard", default=".github/ai-env/contracts/agent-env-branch-health.json")
    branch_health_report_cmd.add_argument("--review-routing", default="")
    branch_health_report_cmd.add_argument("--matrix", default=".github/ai-env/contracts/agent-env-rebuild-matrix.json")
    branch_health_report_cmd.add_argument("--limit", type=int, default=20)
    branch_health_report_cmd.add_argument("--json", action="store_true")
    branch_health_report_cmd.set_defaults(func=branch_health_report)

    branch_health_audit_cmd = subparsers.add_parser(
        "branch-health-audit",
        aliases=["branch-audit"],
        help="verify review routing and branch health dashboard contracts",
    )
    add_common_db_args(branch_health_audit_cmd)
    branch_health_audit_cmd.add_argument("--dashboard", default=".github/ai-env/contracts/agent-env-branch-health.json")
    branch_health_audit_cmd.add_argument("--review-routing", default="")
    branch_health_audit_cmd.add_argument("--policy", default=".github/ai-env/contracts/agent-env-policy.json")
    branch_health_audit_cmd.add_argument("--limit", type=int, default=40)
    branch_health_audit_cmd.add_argument("--json", action="store_true")
    branch_health_audit_cmd.set_defaults(func=branch_health_audit)

    trace_audit_cmd = subparsers.add_parser(
        "trace-audit",
        aliases=["observability-audit"],
        help="verify task-run trace IDs, run manifests, and observability contract wiring",
    )
    add_common_db_args(trace_audit_cmd)
    trace_audit_cmd.add_argument("--contract", default=".github/ai-env/contracts/agent-env-observability.json")
    trace_audit_cmd.add_argument("--policy", default=".github/ai-env/contracts/agent-env-policy.json")
    trace_audit_cmd.add_argument("--run-id", default="")
    trace_audit_cmd.add_argument("--latest", action="store_true")
    trace_audit_cmd.add_argument("--limit", type=int, default=40)
    trace_audit_cmd.add_argument("--json", action="store_true")
    trace_audit_cmd.set_defaults(func=trace_audit)

    state_audit_cmd = subparsers.add_parser(
        "state-audit",
        aliases=["state-machine-audit", "reviewer-inspector-audit"],
        help="verify state-machine traceback fields and reviewer/inspector profile gates",
    )
    add_common_db_args(state_audit_cmd)
    state_audit_cmd.add_argument("--contract", default=".github/ai-env/contracts/agent-env-state-traceability.json")
    state_audit_cmd.add_argument("--policy", default=".github/ai-env/contracts/agent-env-policy.json")
    state_audit_cmd.add_argument("--review-routing", default=".github/ai-env/contracts/agent-env-review-routing.json")
    state_audit_cmd.add_argument("--run-id", default="")
    state_audit_cmd.add_argument("--latest", action="store_true")
    state_audit_cmd.add_argument("--limit", type=int, default=40)
    state_audit_cmd.add_argument("--json", action="store_true")
    state_audit_cmd.set_defaults(func=state_audit)

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


def cli_access_details(args: argparse.Namespace) -> dict[str, object]:
    details: dict[str, object] = {}
    for key, value in vars(args).items():
        if key == "func":
            continue
        if key in {"content", "stdin"}:
            details[key] = "<redacted>" if value else value
        else:
            details[key] = value
    return details


def cli_access_target(args: argparse.Namespace) -> str:
    for key in ("path", "profile", "backup_dir"):
        value = getattr(args, key, "")
        if value:
            return str(value)
    paths = getattr(args, "paths", None)
    if paths:
        return " ".join(str(path) for path in paths)
    terms = getattr(args, "terms", None)
    if terms:
        return " ".join(str(term) for term in terms)
    return ""


def record_cli_access(args: argparse.Namespace, exit_code: int) -> None:
    command = str(getattr(args, "command", ""))
    if command in {"api", "usage", "used", "access-log", "smoke"}:
        return
    if not hasattr(args, "repo_root") or not hasattr(args, "db"):
        return
    repo_root = resolve_repo_path(args.repo_root)
    db_path = (repo_root / args.db).resolve()
    conn = None
    try:
        conn = open_db(db_path, timeout=0.2, busy_timeout_ms=200)
        init_schema(conn)
        record_access(
            conn,
            surface="cli",
            op=command,
            source=str(getattr(args, "source", "")),
            target=cli_access_target(args),
            ok=exit_code == 0,
            result_count=0,
            details={"args": cli_access_details(args)},
        )
        conn.commit()
    except sqlite3.Error as exc:
        if "database is locked" not in str(exc).lower():
            print(f"WARN skip cli access log: {exc}", file=sys.stderr)
    finally:
        if conn is not None:
            conn.close()


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
            record_access(
                conn,
                surface="cli",
                op="init",
                target=str(db_path),
                ok=True,
                result_count=0,
                details={"db": str(db_path), "fts5": has_fts5},
            )
            conn.commit()
        finally:
            conn.close()
        print(f"PASS init db={db_path}")
        return 0
    try:
        exit_code = args.func(args)
    except (BackupLayoutError, OSError, sqlite3.Error) as exc:
        print(f"FAIL {args.command}: {exc}", file=sys.stderr)
        exit_code = 2
    record_cli_access(args, exit_code)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
