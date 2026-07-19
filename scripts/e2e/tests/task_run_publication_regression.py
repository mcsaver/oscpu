#!/usr/bin/env python3
"""Real-SQLite regression for marker-bound task-run publication."""

from __future__ import annotations

import hashlib
import json
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CLI = ROOT / "scripts" / "github_index_db.py"
PROFILE = "agent-system"
ARTIFACTS = {
    "task_report_md_sha256": "task-report.md",
    "run_manifest_json_sha256": "run-manifest.json",
    "context_brief_md_sha256": "context-brief.md",
    "profile_resolve_md_sha256": "profile-resolve.md",
    "evidence_index_md_sha256": "evidence-index.md",
    "dispatch_log_md_sha256": "dispatch-log.md",
    "nodes_tsv_sha256": "nodes.tsv",
}


def cli(repo: Path, db: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [sys.executable, str(CLI), *args, "--repo-root", str(repo), "--db", str(db)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and result.returncode != 0:
        raise AssertionError(
            f"command failed rc={result.returncode}: {' '.join(args)}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def report_text(run_id: str, *, contract: str | None = "db-marker-v1", trailer: str = "") -> str:
    contract_line = f"- `publication_contract`: {contract}\n" if contract is not None else ""
    return (
        "# 任务报告\n\n"
        "## 基本信息\n\n"
        f"- `task_id`: {run_id}\n"
        f"- `trace_id`: e2e:{run_id}\n"
        f"- `task_slug`: {run_id}\n"
        "- `graph_template`: modular-agent-e2e\n"
        f"- `profile`: {PROFILE}\n"
        "- `graph_mode`: static\n"
        f"{contract_line}"
        "- `status`: completed\n"
        "- `started_at`: 2026-07-18 00:00:00 +0800\n"
        "- `updated_at`: 2026-07-18 00:00:01 +0800\n\n"
        "## 收尾结论\n\n"
        "- `final_result`: synthetic publication regression\n"
        f"{trailer}"
    )


def write_publishable_run(repo: Path, run_id: str, *, write_publication: bool = False) -> Path:
    run_dir = repo / ".github" / "task-runs" / run_id
    run_dir.mkdir(parents=True)
    (run_dir / "task-report.md").write_text(report_text(run_id), encoding="utf-8")
    manifest = {
        "run_id": run_id,
        "trace_id": f"e2e:{run_id}",
        "task_slug": run_id,
        "profile": PROFILE,
        "graph_template": "modular-agent-e2e",
        "graph_mode": "static",
        "publication_contract": "db-marker-v1",
        "status": "completed",
    }
    (run_dir / "run-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    (run_dir / "context-brief.md").write_text("# Agent Brief\n\nsynthetic context\n", encoding="utf-8")
    (run_dir / "profile-resolve.md").write_text(
        "# E2E Resolved Profile\n\nsynthetic resolve\n", encoding="utf-8"
    )
    (run_dir / "evidence-index.md").write_text("# Evidence Index\n\nsynthetic index\n", encoding="utf-8")
    (run_dir / "dispatch-log.md").write_text("# 派发日志\n\nsynthetic dispatch\n", encoding="utf-8")
    (run_dir / "nodes.tsv").write_text(
        "node\tagent-system\tagent-system\tPASS\tin\tout\tevidence/node.log\tagent-system\tfn\n",
        encoding="utf-8",
    )
    marker_fields = {"status": "complete", "profile": PROFILE}
    for key, name in ARTIFACTS.items():
        marker_fields[key] = hashlib.sha256((run_dir / name).read_bytes()).hexdigest()
    marker = "".join(f"{key}={value}\n" for key, value in marker_fields.items())
    (run_dir / "complete.marker").write_text(marker, encoding="utf-8")
    if write_publication:
        write_publication_record(run_dir)
    return run_dir


def write_publication_record(run_dir: Path) -> None:
    marker = (run_dir / "complete.marker").read_bytes()
    marker_fields: dict[str, str] = {}
    for line in marker.decode("utf-8").splitlines():
        key, value = line.split("=", 1)
        marker_fields[key] = value
    fields = {
        "task_id": run_dir.name,
        "trace_id": f"e2e:{run_dir.name}",
        "task_slug": run_dir.name,
        "profile": PROFILE,
        "status": "completed",
        "publication_contract": "db-marker-v1",
        "marker_sha256": hashlib.sha256(marker).hexdigest(),
        **{
            key: value
            for key, value in marker_fields.items()
            if key not in {"status", "profile"}
        },
    }
    content = "# Task Run Publication\n\n## 基本信息\n\n" + "".join(
        f"- `{key}`: {value}\n" for key, value in fields.items()
    )
    (run_dir / "completion-publication.md").write_text(content, encoding="utf-8")


def archive_sync(repo: Path, db: Path, run_id: str) -> None:
    cli(
        repo,
        db,
        "archive-markdown",
        f".github/task-runs/{run_id}",
        "--backup-dir",
        ".github/db-backup/publication-regression",
        "--sync-task-run",
        "--yes",
    )


def visible_completed(repo: Path, db: Path) -> list[dict[str, object]]:
    result = cli(repo, db, "runs", "--status", "completed", "--json")
    payload = json.loads(result.stdout)
    return list(payload.get("runs", []))


def db_count(db: Path, table: str, path: str) -> int:
    conn = sqlite3.connect(db)
    try:
        return int(conn.execute(f"SELECT COUNT(*) FROM {table} WHERE path = ?", (path,)).fetchone()[0])
    finally:
        conn.close()


def seed_stale_publication_backup(
    backup_dir: Path,
    publication_path: str,
    publication_content: bytes,
) -> Path:
    stale_file = backup_dir / "files" / publication_path
    stale_file.parent.mkdir(parents=True, exist_ok=True)
    stale_file.write_bytes(publication_content)
    backup_dir.mkdir(parents=True, exist_ok=True)
    (backup_dir / "manifest.json").write_text(
        json.dumps(
            {
                "created_at": "2026-07-18T00:00:00+00:00",
                "updated_at": "2026-07-18T00:00:00+00:00",
                "schema_version": 4,
                "entries": [
                    {
                        "path": publication_path,
                        "kind": "task-run",
                        "size_bytes": len(publication_content),
                        "sha256": hashlib.sha256(publication_content).hexdigest(),
                        "backup_source": "database",
                        "archived_at": "2026-07-18T00:00:00+00:00",
                    }
                ],
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return stale_file


def append_traversal_publication_entry(backup_dir: Path, publication_content: bytes) -> tuple[str, Path]:
    traversal_path = ".github/task-runs/../../../../../../victim/completion-publication.md"
    victim = backup_dir.parents[2] / "victim" / "completion-publication.md"
    victim.parent.mkdir(parents=True, exist_ok=True)
    victim.write_bytes(publication_content)
    manifest_path = backup_dir / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["entries"].append(
        {
            "path": traversal_path,
            "kind": "task-run",
            "size_bytes": len(publication_content),
            "sha256": hashlib.sha256(publication_content).hexdigest(),
            "backup_source": "database",
            "archived_at": "2026-07-18T00:00:00+00:00",
        }
    )
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return traversal_path, victim


def assert_backup_layout_links_fail_closed(
    repo: Path,
    db: Path,
    publication_path: str,
) -> None:
    document_path = str(Path(publication_path).with_name("task-report.md"))
    protected_root = repo.parent / "protected-backup-root"
    protected_document = protected_root / document_path
    sentinel = b"protected backup document\n"
    protected_document.parent.mkdir(parents=True, exist_ok=True)
    protected_document.write_bytes(sentinel)

    def expect_failure(backup_rel: str, expected_error: str) -> None:
        result = cli(
            repo,
            db,
            "backup",
            "--path",
            document_path,
            "--backup-dir",
            backup_rel,
            check=False,
        )
        if (
            result.returncode == 0
            or expected_error not in result.stderr
            or "Traceback" in result.stderr
            or protected_document.read_bytes() != sentinel
        ):
            raise AssertionError(
                f"backup layout did not fail closed: {backup_rel}\n"
                f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
            )

    files_link_rel = ".github/db-backup/publication-files-link"
    files_link_backup = repo / files_link_rel
    files_link_backup.mkdir(parents=True)
    (files_link_backup / "files").symlink_to(protected_root, target_is_directory=True)
    expect_failure(files_link_rel, "backup files directory must not be a symlink")

    objects_link_rel = ".github/db-backup/publication-objects-link"
    objects_link_backup = repo / objects_link_rel
    objects_link_backup.mkdir(parents=True)
    (objects_link_backup / "objects").symlink_to(protected_root, target_is_directory=True)
    expect_failure(objects_link_rel, "backup objects directory must not be a symlink")

    object_intermediate_rel = ".github/db-backup/publication-object-intermediate-link"
    object_intermediate = repo / object_intermediate_rel / "objects"
    object_intermediate.mkdir(parents=True)
    (object_intermediate / "sha256").symlink_to(protected_root, target_is_directory=True)
    expect_failure(
        object_intermediate_rel,
        "backup object path must not contain a symlink",
    )

    intermediate_link_rel = ".github/db-backup/publication-intermediate-link"
    intermediate_files = repo / intermediate_link_rel / "files"
    linked_parent = intermediate_files / Path(document_path).parent
    linked_parent.parent.mkdir(parents=True)
    linked_parent.symlink_to(protected_document.parent, target_is_directory=True)
    expect_failure(intermediate_link_rel, "backup destination escapes files directory")

    destination_link_rel = ".github/db-backup/publication-destination-link"
    destination_file = repo / destination_link_rel / "files" / document_path
    destination_file.parent.mkdir(parents=True)
    destination_file.symlink_to(protected_document)
    expect_failure(destination_link_rel, "backup destination escapes files directory")

    manifest_link_rel = ".github/db-backup/publication-manifest-link"
    manifest_link_backup = repo / manifest_link_rel
    manifest_link_backup.mkdir(parents=True)
    protected_manifest = repo.parent / "protected-manifest.json"
    manifest_sentinel = b"protected manifest\n"
    protected_manifest.write_bytes(manifest_sentinel)
    (manifest_link_backup / "manifest.json").symlink_to(protected_manifest)
    expect_failure(manifest_link_rel, "backup manifest must not be a symlink")
    if protected_manifest.read_bytes() != manifest_sentinel:
        raise AssertionError("backup rewrote a symlinked manifest target")

    destination_hardlink_rel = ".github/db-backup/publication-destination-hardlink"
    destination_hardlink = repo / destination_hardlink_rel / "files" / document_path
    destination_hardlink.parent.mkdir(parents=True)
    destination_hardlink.hardlink_to(protected_document)
    expect_failure(destination_hardlink_rel, "backup destination must have exactly one link")

    manifest_hardlink_rel = ".github/db-backup/publication-manifest-hardlink"
    manifest_hardlink_backup = repo / manifest_hardlink_rel
    manifest_hardlink_backup.mkdir(parents=True)
    protected_hardlink_manifest = repo.parent / "protected-hardlink-manifest.json"
    hardlink_manifest_sentinel = b"protected hardlink manifest\n"
    protected_hardlink_manifest.write_bytes(hardlink_manifest_sentinel)
    hardlinked_manifest = manifest_hardlink_backup / "manifest.json"
    hardlinked_manifest.hardlink_to(protected_hardlink_manifest)
    expect_failure(manifest_hardlink_rel, "backup manifest must have exactly one link")
    if protected_hardlink_manifest.read_bytes() != hardlink_manifest_sentinel:
        raise AssertionError("backup rewrote a hardlinked manifest target")

    invalid_manifest_rel = ".github/db-backup/publication-invalid-manifest"
    invalid_manifest = repo / invalid_manifest_rel / "manifest.json"
    invalid_manifest.parent.mkdir(parents=True)
    invalid_manifest_bytes = b"not valid json\n"
    invalid_manifest.write_bytes(invalid_manifest_bytes)
    expect_failure(invalid_manifest_rel, "cannot read valid backup manifest")
    if invalid_manifest.read_bytes() != invalid_manifest_bytes:
        raise AssertionError("backup replaced an invalid manifest after reporting failure")


def manifest_entry_file(backup_dir: Path, rel_path: str) -> Path:
    manifest = json.loads((backup_dir / "manifest.json").read_text(encoding="utf-8"))
    matches = [entry for entry in manifest["entries"] if entry["path"] == rel_path]
    if len(matches) != 1:
        raise AssertionError(f"manifest entry cardinality mismatch: {rel_path}")
    entry = matches[0]
    object_ref = entry.get("backup_object")
    return backup_dir / object_ref if object_ref else backup_dir / "files" / rel_path


def assert_failed_backup_preserves_previous_snapshot(
    repo: Path,
    db: Path,
    publication_path: str,
) -> None:
    run_root = Path(publication_path).parent
    first_path = str(run_root / "dispatch-log.md")
    second_path = str(run_root / "task-report.md")
    backup_rel = ".github/db-backup/publication-transaction"
    backup_dir = repo / backup_rel
    cli(
        repo,
        db,
        "backup",
        "--path",
        first_path,
        "--path",
        second_path,
        "--backup-dir",
        backup_rel,
    )
    manifest_before = (backup_dir / "manifest.json").read_bytes()
    first_backup = manifest_entry_file(backup_dir, first_path)
    first_backup_before = first_backup.read_bytes()
    first_live = repo / first_path
    second_live = repo / second_path
    first_original = first_live.read_bytes()
    second_original = second_live.read_bytes()
    protected_source = repo.parent / "protected-backup-source.md"
    protected_bytes = b"protected source\n"
    protected_source.write_bytes(protected_bytes)
    try:
        first_live.write_bytes(b"new first document\n")
        second_live.unlink()
        second_live.symlink_to(protected_source)
        result = cli(
            repo,
            db,
            "backup",
            "--path",
            first_path,
            "--path",
            second_path,
            "--backup-dir",
            backup_rel,
            check=False,
        )
    finally:
        first_live.write_bytes(first_original)
        if second_live.is_symlink():
            second_live.unlink()
        second_live.write_bytes(second_original)
    if (
        result.returncode == 0
        or "backup source escapes repository" not in result.stderr
        or "Traceback" in result.stderr
        or (backup_dir / "manifest.json").read_bytes() != manifest_before
        or first_backup.read_bytes() != first_backup_before
        or protected_source.read_bytes() != protected_bytes
    ):
        raise AssertionError(
            "failed backup damaged the previous snapshot\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )

    carried_payload = manifest_entry_file(backup_dir, second_path)
    carried_payload.write_bytes(b"corrupt carried payload\n")
    manifest_with_corrupt_carry = (backup_dir / "manifest.json").read_bytes()
    carry_result = cli(
        repo,
        db,
        "backup",
        "--path",
        first_path,
        "--backup-dir",
        backup_rel,
        check=False,
    )
    if (
        carry_result.returncode == 0
        or "backup payload size/hash mismatch" not in carry_result.stderr
        or "Traceback" in carry_result.stderr
        or (backup_dir / "manifest.json").read_bytes() != manifest_with_corrupt_carry
    ):
        raise AssertionError(
            "backup committed while carrying a corrupt retained payload\n"
            f"stdout:\n{carry_result.stdout}\nstderr:\n{carry_result.stderr}"
        )


def assert_stored_snapshot_and_audit_binding(
    repo: Path,
    db: Path,
    publication_path: str,
) -> None:
    document_path = str(Path(publication_path).with_name("task-report.md"))
    conn = sqlite3.connect(db)
    try:
        stored_content = str(
            conn.execute(
                "SELECT content FROM db_documents WHERE path = ?",
                (document_path,),
            ).fetchone()[0]
        )
    finally:
        conn.close()
    live_path = repo / document_path
    live_original = live_path.read_bytes()
    backup_rel = ".github/db-backup/publication-stored-binding"
    backup_dir = repo / backup_rel
    drift = b"# LIVE-DRIFT\n"
    try:
        live_path.write_bytes(drift)
        cli(
            repo,
            db,
            "snapshot-stored",
            "--path",
            document_path,
            "--backup-dir",
            backup_rel,
            "--yes",
        )
    finally:
        live_path.write_bytes(live_original)
    payload_file = manifest_entry_file(backup_dir, document_path)
    if payload_file.read_bytes() != stored_content.encode("utf-8"):
        raise AssertionError("snapshot-stored selected live drift instead of stored content")

    stale = b"# stale but internally consistent\n"
    stale_digest = hashlib.sha256(stale).hexdigest()
    stale_ref = f"objects/sha256/{stale_digest[:2]}/{stale_digest}"
    stale_object = backup_dir / stale_ref
    stale_object.parent.mkdir(parents=True, exist_ok=True)
    stale_object.write_bytes(stale)
    manifest_path = backup_dir / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entry = next(item for item in manifest["entries"] if item["path"] == document_path)
    entry["size_bytes"] = len(stale)
    entry["sha256"] = stale_digest
    entry["backup_object"] = stale_ref
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    audit = cli(
        repo,
        db,
        "audit-db-first",
        "--backup-dir",
        backup_rel,
        "--json",
        check=False,
    )
    audit_payload = json.loads(audit.stdout)
    if (
        audit.returncode == 0
        or audit_payload.get("ok")
        or document_path not in audit_payload.get("backup_hash_mismatch", [])
        or "Traceback" in audit.stderr
    ):
        raise AssertionError(f"audit accepted a stale self-consistent backup: {audit_payload}")


def assert_shim_backup_uses_stored_payload(temp: Path) -> None:
    repo = temp / "shim-repo"
    repo.mkdir()
    db = temp / "shim-index.sqlite"
    document_path = ".github/memory/shim-source.md"
    document = repo / document_path
    document.parent.mkdir(parents=True)
    original = b"# Stored source\n\noriginal payload\n"
    document.write_bytes(original)
    cli(repo, db, "refresh", document_path)
    cli(
        repo,
        db,
        "migrate",
        "--path",
        document_path,
        "--backup-dir",
        ".github/db-backup/shim-migrate",
        "--yes",
    )
    if b"# DB-backed" not in document.read_bytes():
        raise AssertionError("migrate did not materialize a DB-backed shim")
    backup_rel = ".github/db-backup/shim-ordinary-backup"
    backup_dir = repo / backup_rel
    cli(repo, db, "backup", "--path", document_path, "--backup-dir", backup_rel)
    if manifest_entry_file(backup_dir, document_path).read_bytes() != original:
        raise AssertionError("ordinary backup stored a shim instead of the DB payload")
    audit = cli(repo, db, "audit-db-first", "--backup-dir", backup_rel, "--json")
    if not json.loads(audit.stdout).get("ok"):
        raise AssertionError(f"shim backup did not remain DB-bound: {audit.stdout}")

    bad_repo = temp / "archive-db-open-repo"
    bad_repo.mkdir()
    bad_document_path = ".github/memory/db-open.md"
    bad_document = bad_repo / bad_document_path
    bad_document.parent.mkdir(parents=True)
    bad_document.write_text("# DB open preflight\n", encoding="utf-8")
    bad_db = temp / "bad-db-directory"
    bad_db.mkdir()
    bad_backup = bad_repo / ".github/db-backup/db-open-failure"
    failed_archive = cli(
        bad_repo,
        bad_db,
        "archive-markdown",
        bad_document_path,
        "--backup-dir",
        ".github/db-backup/db-open-failure",
        "--yes",
        check=False,
    )
    if (
        failed_archive.returncode == 0
        or "Traceback" in failed_archive.stderr
        or (bad_backup / "manifest.json").exists()
    ):
        raise AssertionError(
            "archive published a stored-db manifest before DB open succeeded\n"
            f"stdout:\n{failed_archive.stdout}\nstderr:\n{failed_archive.stderr}"
        )

    integrity_repo = temp / "stored-integrity-repo"
    integrity_repo.mkdir()
    integrity_db = temp / "stored-integrity.sqlite"
    integrity_path = ".github/memory/integrity.md"
    integrity_document = integrity_repo / integrity_path
    integrity_document.parent.mkdir(parents=True)
    integrity_content = "# Stored integrity\n"
    integrity_document.write_text(integrity_content, encoding="utf-8")
    cli(
        integrity_repo,
        integrity_db,
        "archive-markdown",
        integrity_path,
        "--backup-dir",
        ".github/db-backup/integrity-seed",
        "--yes",
    )
    conn = sqlite3.connect(integrity_db)
    try:
        with conn:
            conn.execute(
                "UPDATE db_documents SET sha256 = ? WHERE path = ?",
                ("0" * 64, integrity_path),
            )
    finally:
        conn.close()
    corrupt_sha_backup = integrity_repo / ".github/db-backup/corrupt-db-sha/manifest.json"
    corrupt_sha = cli(
        integrity_repo,
        integrity_db,
        "snapshot-stored",
        "--path",
        integrity_path,
        "--backup-dir",
        ".github/db-backup/corrupt-db-sha",
        "--yes",
        check=False,
    )
    if (
        corrupt_sha.returncode == 0
        or "stored DB content/hash mismatch" not in corrupt_sha.stderr
        or "Traceback" in corrupt_sha.stderr
        or corrupt_sha_backup.exists()
    ):
        raise AssertionError("snapshot accepted a stored DB content/hash mismatch")
    conn = sqlite3.connect(integrity_db)
    try:
        with conn:
            conn.execute(
                "UPDATE db_documents SET sha256 = ?, kind = 'task-report' WHERE path = ?",
                (hashlib.sha256(integrity_content.encode("utf-8")).hexdigest(), integrity_path),
            )
    finally:
        conn.close()
    corrupt_kind = cli(
        integrity_repo,
        integrity_db,
        "snapshot-stored",
        "--path",
        integrity_path,
        "--backup-dir",
        ".github/db-backup/corrupt-db-kind",
        "--yes",
        check=False,
    )
    if (
        corrupt_kind.returncode == 0
        or "backup row kind/path mismatch" not in corrupt_kind.stderr
        or "Traceback" in corrupt_kind.stderr
        or (integrity_repo / ".github/db-backup/corrupt-db-kind/manifest.json").exists()
    ):
        raise AssertionError("snapshot accepted a stored DB kind/path mismatch")


def assert_authoritative_snapshot_prevents_resurrection(temp: Path) -> None:
    repo = temp / "authoritative-repo"
    repo.mkdir()
    db = temp / "authoritative-index.sqlite"
    kept_path = ".github/memory/kept.md"
    deleted_path = ".github/memory/deleted.md"
    kept = repo / kept_path
    deleted = repo / deleted_path
    kept.parent.mkdir(parents=True)
    kept.write_text("# Kept\n", encoding="utf-8")
    deleted.write_text("# Deleted\n", encoding="utf-8")
    cli(repo, db, "refresh", kept_path, deleted_path)
    cli(
        repo,
        db,
        "archive-markdown",
        kept_path,
        deleted_path,
        "--backup-dir",
        ".github/db-backup/old-incremental",
        "--yes",
    )
    cli(repo, db, "remove", deleted_path, "--delete-file", "--yes")
    conn = sqlite3.connect(db)
    try:
        with conn:
            conn.execute("DELETE FROM db_documents WHERE path = ?", (deleted_path,))
    finally:
        conn.close()
    new_backup = repo / ".github/db-backup/new-authoritative"
    cli(
        repo,
        db,
        "snapshot-stored",
        "--backup-dir",
        ".github/db-backup/new-authoritative",
        "--yes",
    )
    shutil.copytree(
        new_backup,
        repo / ".github/db-backup/new-authoritative-copy",
    )
    kept_original = kept.read_bytes()
    kept.write_bytes(b"# late live drift must not replace stored truth\n")
    authoritative_manifest = new_backup / "manifest.json"
    authoritative_before = authoritative_manifest.read_bytes()
    same_head = cli(
        repo,
        db,
        "backup",
        "--path",
        kept_path,
        "--backup-dir",
        ".github/db-backup/new-authoritative",
        check=False,
    )
    if (
        same_head.returncode == 0
        or "live-copy cannot replace a stored-db backup entry" not in same_head.stderr
        or "Traceback" in same_head.stderr
        or authoritative_manifest.read_bytes() != authoritative_before
    ):
        raise AssertionError("same-head live drift displaced a stored-db snapshot entry")
    cli(
        repo,
        db,
        "backup",
        "--path",
        kept_path,
        "--backup-dir",
        ".github/db-backup/later-live-copy",
    )
    kept.write_bytes(kept_original)
    old_manifest = repo / ".github/db-backup/old-incremental/manifest.json"
    old_manifest.touch()
    audit = cli(repo, db, "audit-db-first", "--json", check=False)
    audit_payload = json.loads(audit.stdout)
    if (
        audit.returncode != 0
        or not audit_payload.get("ok")
        or deleted_path in audit_payload.get("unexpected_backup", [])
    ):
        raise AssertionError(f"authoritative snapshot did not suppress a deleted path: {audit_payload}")
    manifest = json.loads((new_backup / "manifest.json").read_text(encoding="utf-8"))
    if not manifest.get("authoritative_kinds") or not manifest.get("manifest_generation"):
        raise AssertionError("full stored snapshot lacks an authoritative generation barrier")
    rehydrated_db = temp / "authoritative-rehydrated.sqlite"
    cli(repo, rehydrated_db, "rehydrate", "--yes")
    conn = sqlite3.connect(rehydrated_db)
    try:
        restored_kept = conn.execute(
            "SELECT content FROM db_documents WHERE path = ?", (kept_path,)
        ).fetchone()
    finally:
        conn.close()
    if (
        db_count(rehydrated_db, "db_documents", kept_path) != 1
        or db_count(rehydrated_db, "db_documents", deleted_path) != 0
        or restored_kept is None
        or str(restored_kept[0]).encode("utf-8") != kept_original
    ):
        raise AssertionError(
            "default rehydrate resurrected a deleted path or selected a later live-copy drift"
        )

    cli(repo, db, "remove", kept_path, "--delete-file", "--yes")
    conn = sqlite3.connect(db)
    try:
        with conn:
            conn.execute("DELETE FROM db_documents WHERE path = ?", (kept_path,))
    finally:
        conn.close()
    cli(
        repo,
        db,
        "snapshot-stored",
        "--backup-dir",
        ".github/db-backup/new-authoritative",
        "--yes",
    )
    empty_audit = cli(repo, db, "audit-db-first", "--json", check=False)
    empty_payload = json.loads(empty_audit.stdout)
    if empty_audit.returncode != 0 or not empty_payload.get("ok") or empty_payload.get("backup_entries"):
        raise AssertionError(f"empty authoritative snapshot did not suppress the final old path: {empty_payload}")
    empty_db = temp / "authoritative-empty-rehydrated.sqlite"
    cli(repo, empty_db, "refresh", kept_path)
    empty_rehydrate = cli(repo, empty_db, "rehydrate", "--yes", check=False)
    if (
        empty_rehydrate.returncode == 0
        or "found no retained memory/log backup entries" not in empty_rehydrate.stderr
        or db_count(empty_db, "db_documents", kept_path) != 0
    ):
        raise AssertionError("empty authoritative snapshot allowed a legacy path to rehydrate")


def assert_internal_alias_fails_without_cleanup(temp: Path) -> None:
    repo = temp / "alias-repo"
    repo.mkdir()
    db = temp / "alias-index.sqlite"
    run_root = repo / ".github/task-runs/alias-old"
    run_root.mkdir(parents=True)
    (run_root / "task-report.md").write_text(report_text("alias-old"), encoding="utf-8")
    backup_rel = ".github/db-backup/internal-alias"
    backup_dir = repo / backup_rel
    files_runs = backup_dir / "files/.github/task-runs"
    retained_dir = files_runs / "alias-retained"
    retained_dir.mkdir(parents=True)
    retained_payload = retained_dir / "stale.md"
    retained_bytes = b"retained legacy payload\n"
    retained_payload.write_bytes(retained_bytes)
    (files_runs / "alias-old").symlink_to("alias-retained", target_is_directory=True)
    digest = hashlib.sha256(retained_bytes).hexdigest()
    entries = [
        {
            "path": f".github/task-runs/{run_id}/stale.md",
            "kind": "task-run",
            "size_bytes": len(retained_bytes),
            "sha256": digest,
            "backup_source": "database",
        }
        for run_id in ("alias-old", "alias-retained")
    ]
    manifest_path = backup_dir / "manifest.json"
    manifest_path.write_text(json.dumps({"schema_version": 4, "entries": entries}, indent=2) + "\n")
    manifest_before = manifest_path.read_bytes()
    result = cli(
        repo,
        db,
        "archive-markdown",
        ".github/task-runs/alias-old",
        "--backup-dir",
        backup_rel,
        "--sync-task-run",
        "--yes",
        check=False,
    )
    if (
        result.returncode == 0
        or "backup destination escapes files directory" not in result.stderr
        or "Traceback" in result.stderr
        or manifest_path.read_bytes() != manifest_before
        or retained_payload.read_bytes() != retained_bytes
    ):
        raise AssertionError(
            "internal legacy symlink alias was followed during prepare/cleanup\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )

    kind_repo = temp / "carry-kind-repo"
    kind_repo.mkdir()
    kind_db = temp / "carry-kind.sqlite"
    bad_path = ".github/memory/bad.md"
    bad_bytes = b"# bad legacy kind\n"
    kind_backup_rel = ".github/db-backup/carry-kind"
    kind_backup = kind_repo / kind_backup_rel
    bad_payload = kind_backup / "files" / bad_path
    bad_payload.parent.mkdir(parents=True)
    bad_payload.write_bytes(bad_bytes)
    kind_manifest = kind_backup / "manifest.json"
    kind_manifest.write_text(
        json.dumps(
            {
                "schema_version": 4,
                "entries": [
                    {
                        "path": bad_path,
                        "kind": "task-run",
                        "size_bytes": len(bad_bytes),
                        "sha256": hashlib.sha256(bad_bytes).hexdigest(),
                        "backup_source": "database",
                    }
                ],
            },
            indent=2,
        )
        + "\n"
    )
    kind_manifest_before = kind_manifest.read_bytes()
    good_path = ".github/memory/good.md"
    good_document = kind_repo / good_path
    good_document.parent.mkdir(parents=True, exist_ok=True)
    good_document.write_text("# good\n", encoding="utf-8")
    cli(kind_repo, kind_db, "refresh", good_path)
    kind_result = cli(
        kind_repo,
        kind_db,
        "backup",
        "--path",
        good_path,
        "--backup-dir",
        kind_backup_rel,
        check=False,
    )
    if (
        kind_result.returncode == 0
        or "carried backup entry kind/path mismatch" not in kind_result.stderr
        or "Traceback" in kind_result.stderr
        or kind_manifest.read_bytes() != kind_manifest_before
    ):
        raise AssertionError("backup republished a carried entry with mismatched kind/path")

    empty_repo = temp / "empty-prefix-repo"
    empty_repo.mkdir()
    empty_db = temp / "empty-prefix-index.sqlite"
    empty_run_rel = ".github/task-runs/empty-prefix"
    empty_run = empty_repo / empty_run_rel
    empty_run.mkdir(parents=True)
    empty_report_path = f"{empty_run_rel}/task-report.md"
    empty_report = empty_repo / empty_report_path
    empty_report.write_text(report_text("empty-prefix"), encoding="utf-8")
    empty_backup_rel = ".github/db-backup/empty-prefix"
    cli(
        empty_repo,
        empty_db,
        "archive-markdown",
        empty_run_rel,
        "--backup-dir",
        empty_backup_rel,
        "--sync-task-run",
        "--yes",
    )
    empty_report.unlink()
    cli(
        empty_repo,
        empty_db,
        "archive-markdown",
        empty_run_rel,
        "--backup-dir",
        empty_backup_rel,
        "--sync-task-run",
        "--yes",
    )
    empty_manifest = json.loads(
        (empty_repo / empty_backup_rel / "manifest.json").read_text(encoding="utf-8")
    )
    if (
        any(entry["path"].startswith(empty_run_rel + "/") for entry in empty_manifest["entries"])
        or empty_run_rel not in empty_manifest.get("authoritative_prefixes", {})
        or db_count(empty_db, "db_documents", empty_report_path) != 0
    ):
        raise AssertionError("empty task-run sync did not publish a prefix deletion barrier")


def assert_live_source_and_backup_root_boundaries(temp: Path) -> None:
    symlink_repo = temp / "archive-source-symlink-repo"
    symlink_repo.mkdir()
    symlink_db = temp / "archive-source-symlink.sqlite"
    actual_rel = ".github/memory/actual.md"
    actual = symlink_repo / actual_rel
    actual.parent.mkdir(parents=True)
    actual_sentinel = b"# Actual source\n\nkeep this inode untouched\n"
    actual.write_bytes(actual_sentinel)
    alias = actual.with_name("alias.md")
    alias.symlink_to(actual.name)
    symlink_backup = symlink_repo / ".github/db-backup/archive-source-symlink"
    symlink_result = cli(
        symlink_repo,
        symlink_db,
        "archive-markdown",
        ".github/memory",
        "--backup-dir",
        ".github/db-backup/archive-source-symlink",
        "--write-shim",
        "--yes",
        check=False,
    )
    if (
        symlink_result.returncode == 0
        or "archive source path must not contain a symlink" not in symlink_result.stderr
        or "Traceback" in symlink_result.stderr
        or actual.read_bytes() != actual_sentinel
        or not alias.is_symlink()
        or (symlink_backup / "manifest.json").exists()
        or (symlink_repo / ".github/db-backup/.generation").exists()
    ):
        raise AssertionError(
            "archive followed or published a symlinked live source\n"
            f"stdout:\n{symlink_result.stdout}\nstderr:\n{symlink_result.stderr}"
        )
    if symlink_db.exists() and db_count(symlink_db, "db_documents", actual_rel):
        raise AssertionError("archive stored a source row after symlink preflight failed")

    hardlink_repo = temp / "archive-source-hardlink-repo"
    hardlink_repo.mkdir()
    hardlink_db = temp / "archive-source-hardlink.sqlite"
    protected = temp / "archive-source-protected.md"
    protected_sentinel = b"# Protected external inode\n"
    protected.write_bytes(protected_sentinel)
    hardlink = hardlink_repo / ".github/memory/hard.md"
    hardlink.parent.mkdir(parents=True)
    hardlink.hardlink_to(protected)
    protected_inode = protected.stat().st_ino
    hardlink_backup = hardlink_repo / ".github/db-backup/archive-source-hardlink"
    hardlink_result = cli(
        hardlink_repo,
        hardlink_db,
        "archive-markdown",
        ".github/memory",
        "--backup-dir",
        ".github/db-backup/archive-source-hardlink",
        "--write-shim",
        "--yes",
        check=False,
    )
    if (
        hardlink_result.returncode == 0
        or "archive source must have exactly one link" not in hardlink_result.stderr
        or "Traceback" in hardlink_result.stderr
        or protected.read_bytes() != protected_sentinel
        or hardlink.read_bytes() != protected_sentinel
        or protected.stat().st_ino != protected_inode
        or hardlink.stat().st_ino != protected_inode
        or (hardlink_backup / "manifest.json").exists()
        or (hardlink_repo / ".github/db-backup/.generation").exists()
    ):
        raise AssertionError(
            "archive modified or published a hardlinked live source\n"
            f"stdout:\n{hardlink_result.stdout}\nstderr:\n{hardlink_result.stderr}"
        )
    if hardlink_db.exists() and db_count(
        hardlink_db, "db_documents", ".github/memory/hard.md"
    ):
        raise AssertionError("archive stored a source row after hardlink preflight failed")

    control_repo = temp / "archive-source-control-repo"
    control_repo.mkdir()
    control_db = temp / "archive-source-control.sqlite"
    control_rel = ".github/memory/control.md"
    control = control_repo / control_rel
    control.parent.mkdir(parents=True)
    control_content = b"# Ordinary source\n\narchive exact bytes\n"
    control.write_bytes(control_content)
    control.chmod(0o640)
    control_backup_rel = ".github/db-backup/archive-source-control"
    control_backup = control_repo / control_backup_rel
    cli(
        control_repo,
        control_db,
        "archive-markdown",
        control_rel,
        "--backup-dir",
        control_backup_rel,
        "--write-shim",
        "--yes",
    )
    conn = sqlite3.connect(control_db)
    try:
        stored = conn.execute(
            "SELECT content, sha256 FROM db_documents WHERE path = ?", (control_rel,)
        ).fetchone()
    finally:
        conn.close()
    if (
        stored is None
        or stored[0].encode("utf-8") != control_content
        or stored[1] != hashlib.sha256(control_content).hexdigest()
        or manifest_entry_file(control_backup, control_rel).read_bytes() != control_content
        or b"# DB-backed" not in control.read_bytes()
        or control.stat().st_mode & 0o777 != 0o640
    ):
        raise AssertionError("ordinary single-link archive source did not round-trip exactly")

    migrate_repo = temp / "migrate-live-drift-repo"
    migrate_repo.mkdir()
    migrate_db = temp / "migrate-live-drift.sqlite"
    migrate_rel = ".github/memory/live-drift.md"
    migrate_source = migrate_repo / migrate_rel
    migrate_source.parent.mkdir(parents=True)
    migrate_source.write_text("# old indexed\n", encoding="utf-8")
    migrate_source.chmod(0o600)
    cli(migrate_repo, migrate_db, "refresh", migrate_rel)
    fresh_content = b"# NEW LIVE UNINDEXED\n\nthis must survive migration\n"
    migrate_source.write_bytes(fresh_content)
    migrate_backup_rel = ".github/db-backup/migrate-live-drift"
    migrate_backup = migrate_repo / migrate_backup_rel
    cli(
        migrate_repo,
        migrate_db,
        "migrate",
        "--path",
        migrate_rel,
        "--backup-dir",
        migrate_backup_rel,
        "--yes",
    )
    conn = sqlite3.connect(migrate_db)
    try:
        migrated = conn.execute(
            "SELECT content, sha256 FROM db_documents WHERE path = ?", (migrate_rel,)
        ).fetchone()
    finally:
        conn.close()
    if (
        migrated is None
        or migrated[0].encode("utf-8") != fresh_content
        or migrated[1] != hashlib.sha256(fresh_content).hexdigest()
        or manifest_entry_file(migrate_backup, migrate_rel).read_bytes() != fresh_content
        or b"# DB-backed" not in migrate_source.read_bytes()
        or migrate_source.stat().st_mode & 0o777 != 0o600
    ):
        raise AssertionError("migrate lost an unindexed live modification")

    migrate_hardlink_repo = temp / "migrate-hardlink-repo"
    migrate_hardlink_repo.mkdir()
    migrate_hardlink_db = temp / "migrate-hardlink.sqlite"
    migrate_protected = temp / "migrate-hardlink-protected.md"
    migrate_protected_sentinel = b"# migrate protected inode\n"
    migrate_protected.write_bytes(migrate_protected_sentinel)
    migrate_hardlink_rel = ".github/memory/hard.md"
    migrate_hardlink = migrate_hardlink_repo / migrate_hardlink_rel
    migrate_hardlink.parent.mkdir(parents=True)
    migrate_hardlink.hardlink_to(migrate_protected)
    cli(migrate_hardlink_repo, migrate_hardlink_db, "refresh", migrate_hardlink_rel)
    migrate_hardlink_result = cli(
        migrate_hardlink_repo,
        migrate_hardlink_db,
        "migrate",
        "--path",
        migrate_hardlink_rel,
        "--backup-dir",
        ".github/db-backup/migrate-hardlink",
        "--yes",
        check=False,
    )
    if (
        migrate_hardlink_result.returncode == 0
        or "migrate source must have exactly one link" not in migrate_hardlink_result.stderr
        or "Traceback" in migrate_hardlink_result.stderr
        or migrate_protected.read_bytes() != migrate_protected_sentinel
        or (
            migrate_hardlink_repo / ".github/db-backup/migrate-hardlink/manifest.json"
        ).exists()
    ):
        raise AssertionError(
            "migrate modified or published a hardlinked live source\n"
            f"stdout:\n{migrate_hardlink_result.stdout}\n"
            f"stderr:\n{migrate_hardlink_result.stderr}"
        )

    update_repo = temp / "update-stored-alias-repo"
    update_repo.mkdir()
    update_db = temp / "update-stored-alias.sqlite"
    update_actual_rel = ".github/memory/update-actual.md"
    update_actual = update_repo / update_actual_rel
    update_actual.parent.mkdir(parents=True)
    update_sentinel = b"# update target sentinel\n"
    update_actual.write_bytes(update_sentinel)
    update_alias_rel = ".github/memory/update-alias.md"
    update_alias = update_repo / update_alias_rel
    update_alias.symlink_to(update_actual.name)
    update_symlink = cli(
        update_repo,
        update_db,
        "update-stored",
        update_alias_rel,
        "--content",
        "# replacement must fail\n",
        check=False,
    )
    if (
        update_symlink.returncode == 0
        or "update-stored destination path must not contain a symlink"
        not in update_symlink.stderr
        or "Traceback" in update_symlink.stderr
        or update_actual.read_bytes() != update_sentinel
        or not update_alias.is_symlink()
        or (update_db.exists() and db_count(update_db, "db_documents", update_alias_rel))
    ):
        raise AssertionError("update-stored followed a symlinked destination")
    update_alias.unlink()
    update_protected = temp / "update-stored-protected.md"
    update_protected.write_bytes(update_sentinel)
    update_hardlink_rel = ".github/memory/update-hard.md"
    update_hardlink = update_repo / update_hardlink_rel
    update_hardlink.hardlink_to(update_protected)
    update_hardlink_result = cli(
        update_repo,
        update_db,
        "update-stored",
        update_hardlink_rel,
        "--content",
        "# replacement must fail\n",
        check=False,
    )
    if (
        update_hardlink_result.returncode == 0
        or "update-stored destination must have exactly one link"
        not in update_hardlink_result.stderr
        or "Traceback" in update_hardlink_result.stderr
        or update_protected.read_bytes() != update_sentinel
        or update_hardlink.read_bytes() != update_sentinel
        or db_count(update_db, "db_documents", update_hardlink_rel)
    ):
        raise AssertionError("update-stored modified a hardlinked destination")
    protected_policy = update_repo / "AGENTS.md"
    protected_policy.write_bytes(update_sentinel)
    traversal_rel = ".github/task-runs/../../AGENTS.md"
    traversal_update = cli(
        update_repo,
        update_db,
        "update-stored",
        traversal_rel,
        "--content",
        "# traversal replacement must fail\n",
        check=False,
    )
    canonical_target_rel = ".github/memory/canonical.md"
    canonical_target = update_repo / canonical_target_rel
    canonical_target.write_bytes(update_sentinel)
    folded_rel = ".github/memory/../memory/canonical.md"
    folded_update = cli(
        update_repo,
        update_db,
        "update-stored",
        folded_rel,
        "--content",
        "# folded replacement must fail\n",
        check=False,
    )
    if (
        traversal_update.returncode == 0
        or folded_update.returncode == 0
        or "path must be canonical" not in traversal_update.stderr
        or "path must be canonical" not in folded_update.stderr
        or "Traceback" in traversal_update.stderr
        or "Traceback" in folded_update.stderr
        or protected_policy.read_bytes() != update_sentinel
        or canonical_target.read_bytes() != update_sentinel
        or db_count(update_db, "db_documents", traversal_rel)
        or db_count(update_db, "db_documents", folded_rel)
        or db_count(update_db, "db_documents", canonical_target_rel)
    ):
        raise AssertionError("update-stored accepted a noncanonical lexical alias")

    backup_root_repo = temp / "backup-root-boundary-repo"
    backup_root_repo.mkdir()
    backup_root_db = temp / "backup-root-boundary.sqlite"
    backup_root_rel = ".github/memory/root.md"
    backup_root_source = backup_root_repo / backup_root_rel
    backup_root_source.parent.mkdir(parents=True)
    backup_root_source.write_text("# Backup root boundary\n", encoding="utf-8")
    cli(
        backup_root_repo,
        backup_root_db,
        "archive-markdown",
        backup_root_rel,
        "--backup-dir",
        ".github/db-backup/seed",
        "--yes",
    )
    explicit_escape = cli(
        backup_root_repo,
        backup_root_db,
        "rehydrate",
        "--backup-dir",
        "../outside-backup",
        "--yes",
        check=False,
    )
    if (
        explicit_escape.returncode == 0
        or "backup directory escapes repository" not in explicit_escape.stderr
        or "Traceback" in explicit_escape.stderr
    ):
        raise AssertionError(
            "explicit backup-root escape did not fail cleanly\n"
            f"stdout:\n{explicit_escape.stdout}\nstderr:\n{explicit_escape.stderr}"
        )
    backup_root = backup_root_repo / ".github/db-backup"
    external_backup_root = temp / "external-backup-root"
    shutil.move(str(backup_root), str(external_backup_root))
    backup_root.symlink_to(external_backup_root, target_is_directory=True)
    external_manifest = external_backup_root / "seed/manifest.json"
    external_manifest_before = external_manifest.read_bytes()
    conn = sqlite3.connect(backup_root_db)
    try:
        stored_before = conn.execute(
            "SELECT content, sha256 FROM db_documents WHERE path = ?", (backup_root_rel,)
        ).fetchone()
    finally:
        conn.close()
    default_root = cli(
        backup_root_repo,
        backup_root_db,
        "rehydrate",
        "--yes",
        check=False,
    )
    conn = sqlite3.connect(backup_root_db)
    try:
        stored_after = conn.execute(
            "SELECT content, sha256 FROM db_documents WHERE path = ?", (backup_root_rel,)
        ).fetchone()
    finally:
        conn.close()
    if (
        default_root.returncode == 0
        or "backup directory path must not contain a symlink" not in default_root.stderr
        or "Traceback" in default_root.stderr
        or stored_after != stored_before
        or external_manifest.read_bytes() != external_manifest_before
    ):
        raise AssertionError(
            "default backup-root symlink did not fail before external reads/writes\n"
            f"stdout:\n{default_root.stdout}\nstderr:\n{default_root.stderr}"
        )


def assert_manifest_consumer_and_restore_boundaries(
    repo: Path,
    db: Path,
    publication_path: str,
) -> None:
    traversal_path = ".github/task-runs/../../../../../../consumer-secret/task-report.md"
    traversal_rel = ".github/db-backup/publication-consumer-traversal"
    traversal_dir = repo / traversal_rel
    traversal_file = (traversal_dir / "files" / traversal_path).resolve()
    traversal_bytes = b"# protected consumer content\n"
    traversal_file.parent.mkdir(parents=True, exist_ok=True)
    traversal_file.write_bytes(traversal_bytes)
    traversal_dir.mkdir(parents=True, exist_ok=True)
    (traversal_dir / "manifest.json").write_text(
        json.dumps(
            {
                "schema_version": 4,
                "entries": [
                    {
                        "path": traversal_path,
                        "kind": "task-report",
                        "size_bytes": len(traversal_bytes),
                        "sha256": hashlib.sha256(traversal_bytes).hexdigest(),
                        "backup_source": "database",
                    }
                ],
            },
            indent=2,
        )
        + "\n"
    )
    rehydrate = cli(
        repo,
        db,
        "rehydrate",
        "--backup-dir",
        traversal_rel,
        "--yes",
        check=False,
    )
    if (
        rehydrate.returncode == 0
        or "noncanonical path" not in rehydrate.stderr
        or "Traceback" in rehydrate.stderr
        or db_count(db, "db_documents", traversal_path) != 0
        or traversal_file.read_bytes() != traversal_bytes
    ):
        raise AssertionError(
            "rehydrate consumed a noncanonical manifest path\n"
            f"stdout:\n{rehydrate.stdout}\nstderr:\n{rehydrate.stderr}"
        )

    scope_rel = ".github/db-backup/publication-restore-scope"
    scope_dir = repo / scope_rel
    scope_target_path = "AGENTS.md"
    scope_target = repo / scope_target_path
    scope_sentinel = b"repository policy must not be backup-restorable\n"
    scope_target.write_bytes(scope_sentinel)
    scope_payload = b"malicious in-repository replacement\n"
    scope_digest = hashlib.sha256(scope_payload).hexdigest()
    scope_ref = f"objects/sha256/{scope_digest[:2]}/{scope_digest}"
    scope_object = scope_dir / scope_ref
    scope_object.parent.mkdir(parents=True)
    scope_object.write_bytes(scope_payload)
    (scope_dir / "manifest.json").write_text(
        json.dumps(
            {
                "schema_version": 4,
                "entries": [
                    {
                        "path": scope_target_path,
                        "kind": "agent-shim",
                        "size_bytes": len(scope_payload),
                        "sha256": scope_digest,
                        "backup_object": scope_ref,
                        "backup_source": "database",
                    }
                ],
            },
            indent=2,
        )
        + "\n"
    )
    scoped_restore = cli(
        repo,
        db,
        "restore",
        "--path",
        scope_target_path,
        "--backup-dir",
        scope_rel,
        "--yes",
        check=False,
    )
    if (
        scoped_restore.returncode == 0
        or "non-retained requested paths" not in scoped_restore.stderr
        or "Traceback" in scoped_restore.stderr
        or scope_target.read_bytes() != scope_sentinel
    ):
        raise AssertionError(
            "restore accepted an in-repository path outside retained memory/log scope\n"
            f"stdout:\n{scoped_restore.stdout}\nstderr:\n{scoped_restore.stderr}"
        )

    run_root = Path(publication_path).parent
    first_path = str(run_root / "dispatch-log.md")
    second_path = str(run_root / "task-report.md")
    preflight_rel = ".github/db-backup/publication-restore-preflight"
    preflight_dir = repo / preflight_rel
    cli(
        repo,
        db,
        "backup",
        "--path",
        first_path,
        "--path",
        second_path,
        "--backup-dir",
        preflight_rel,
    )
    first_live = repo / first_path
    first_original = first_live.read_bytes()
    first_sentinel = b"first destination must remain unchanged\n"
    first_live.write_bytes(first_sentinel)
    second_payload = manifest_entry_file(preflight_dir, second_path)
    second_payload.write_bytes(b"corrupt final payload\n")
    restore = cli(
        repo,
        db,
        "restore",
        "--path",
        first_path,
        "--path",
        second_path,
        "--backup-dir",
        preflight_rel,
        "--yes",
        check=False,
    )
    if (
        restore.returncode == 0
        or "backup size/hash mismatch" not in restore.stderr
        or "Traceback" in restore.stderr
        or first_live.read_bytes() != first_sentinel
    ):
        raise AssertionError(
            "restore changed an earlier destination before full preflight\n"
            f"stdout:\n{restore.stdout}\nstderr:\n{restore.stderr}"
        )
    first_live.write_bytes(first_original)

    blocked_path = ".github/task-runs/restore-parent/nested/task-report.md"
    blocked_live = repo / blocked_path
    blocked_live.parent.mkdir(parents=True)
    blocked_original = b"# Nested restore target\n"
    blocked_live.write_bytes(blocked_original)
    cli(
        repo,
        db,
        "archive-markdown",
        blocked_path,
        "--backup-dir",
        ".github/db-backup/publication-regression",
        "--yes",
    )
    target_preflight_rel = ".github/db-backup/publication-restore-target-preflight"
    cli(
        repo,
        db,
        "backup",
        "--path",
        first_path,
        "--path",
        blocked_path,
        "--backup-dir",
        target_preflight_rel,
    )
    first_live.write_bytes(first_sentinel)
    blocked_parent = blocked_live.parent
    blocked_live.unlink()
    blocked_parent.rmdir()
    blocked_parent.write_bytes(b"parent path is an ordinary file\n")
    target_restore = cli(
        repo,
        db,
        "restore",
        "--path",
        first_path,
        "--path",
        blocked_path,
        "--backup-dir",
        target_preflight_rel,
        "--yes",
        check=False,
    )
    if (
        target_restore.returncode == 0
        or "restore destination parent is not a directory" not in target_restore.stderr
        or "Traceback" in target_restore.stderr
        or first_live.read_bytes() != first_sentinel
    ):
        raise AssertionError(
            "restore changed an earlier destination before target-chain preflight\n"
            f"stdout:\n{target_restore.stdout}\nstderr:\n{target_restore.stderr}"
        )
    first_live.write_bytes(first_original)
    blocked_parent.unlink()
    blocked_parent.mkdir()
    blocked_live.write_bytes(blocked_original)
    cli(repo, db, "refresh", blocked_path)

    hardlink_rel = ".github/db-backup/publication-restore-hardlink"
    hardlink_dir = repo / hardlink_rel
    first_live.chmod(0o640)
    expected_mode = first_live.stat().st_mode & 0o7777
    cli(
        repo,
        db,
        "backup",
        "--path",
        first_path,
        "--backup-dir",
        hardlink_rel,
    )
    expected_restore = manifest_entry_file(hardlink_dir, first_path).read_bytes()
    protected_restore = repo.parent / "protected-restore-target.md"
    protected_restore_bytes = b"protected restore target\n"
    protected_restore.write_bytes(protected_restore_bytes)
    first_live.unlink()
    first_live.hardlink_to(protected_restore)
    restored = cli(
        repo,
        db,
        "restore",
        "--path",
        first_path,
        "--backup-dir",
        hardlink_rel,
        "--yes",
        check=False,
    )
    if (
        restored.returncode != 0
        or "Traceback" in restored.stderr
        or protected_restore.read_bytes() != protected_restore_bytes
        or first_live.read_bytes() != expected_restore
        or first_live.stat().st_ino == protected_restore.stat().st_ino
        or first_live.stat().st_mode & 0o7777 != expected_mode
    ):
        raise AssertionError(
            "restore mutated an external hardlink inode or lost the manifest mode\n"
            f"stdout:\n{restored.stdout}\nstderr:\n{restored.stderr}"
        )

    restore_db_sentinel = b"restore must preflight DB open\n"
    first_live.write_bytes(restore_db_sentinel)
    bad_restore_db = repo.parent / "restore-bad-db-directory"
    bad_restore_db.mkdir()
    bad_db_restore = cli(
        repo,
        bad_restore_db,
        "restore",
        "--path",
        first_path,
        "--backup-dir",
        hardlink_rel,
        "--yes",
        check=False,
    )
    if (
        bad_db_restore.returncode == 0
        or "Traceback" in bad_db_restore.stderr
        or first_live.read_bytes() != restore_db_sentinel
    ):
        raise AssertionError(
            "restore changed live content before DB open succeeded\n"
            f"stdout:\n{bad_db_restore.stdout}\nstderr:\n{bad_db_restore.stderr}"
        )


def main() -> int:
    cases = 0
    with tempfile.TemporaryDirectory(prefix="task-run-publication-") as raw_tmp:
        temp = Path(raw_tmp)
        repo = temp / "repo"
        repo.mkdir()
        db = temp / "index.sqlite"

        publishable = write_publishable_run(repo, "atomic-pass")
        archive_sync(repo, db, publishable.name)
        if visible_completed(repo, db):
            raise AssertionError("staged completed report became visible before publication")
        cases += 1

        write_publication_record(publishable)
        cli(repo, db, "publish-task-run", ".github/task-runs/atomic-pass", "--yes")
        cli(repo, db, "publish-task-run", ".github/task-runs/atomic-pass", "--yes")
        completed = visible_completed(repo, db)
        if [(item.get("run_id"), item.get("publication_valid")) for item in completed] != [
            ("atomic-pass", True)
        ] or completed[0].get("final_result") != "synthetic publication regression":
            raise AssertionError(f"published run visibility mismatch: {completed}")
        cases += 1

        archive_sync(repo, db, publishable.name)
        completed = visible_completed(repo, db)
        publication_path = ".github/task-runs/atomic-pass/completion-publication.md"
        if (
            [item.get("run_id") for item in completed] != ["atomic-pass"]
            or db_count(db, "db_documents", publication_path) != 1
        ):
            raise AssertionError("generic task-run sync revoked a published completion")
        cases += 1

        audit = cli(
            repo,
            db,
            "audit-db-first",
            "--backup-dir",
            ".github/db-backup/publication-regression",
            "--json",
        )
        audit_payload = json.loads(audit.stdout)
        if (
            not audit_payload.get("ok")
            or audit_payload.get("publication_backup_exempt") != [publication_path]
            or audit_payload.get("publication_backup_violation")
            or audit_payload.get("missing_backup")
        ):
            raise AssertionError(f"DB-first audit publication ownership mismatch: {audit_payload}")
        cases += 1

        direct_backup_dir = repo / ".github/db-backup/publication-direct-backup"
        direct_backup = cli(
            repo,
            db,
            "backup",
            "--path",
            publication_path,
            "--backup-dir",
            ".github/db-backup/publication-direct-backup",
            check=False,
        )
        if direct_backup.returncode == 0 or (direct_backup_dir / "manifest.json").exists():
            raise AssertionError("direct backup accepted a task-run publication")
        default_backup_dir = repo / ".github/db-backup/publication-default-backup"
        stale_backup_publication = seed_stale_publication_backup(
            default_backup_dir,
            publication_path,
            (publishable / "completion-publication.md").read_bytes(),
        )
        traversal_backup_path, traversal_victim = append_traversal_publication_entry(
            default_backup_dir,
            b"must survive traversal cleanup\n",
        )
        cli(
            repo,
            db,
            "backup",
            "--backup-dir",
            ".github/db-backup/publication-default-backup",
        )
        default_backup_manifest = json.loads(
            (default_backup_dir / "manifest.json").read_text(encoding="utf-8")
        )
        default_backup_paths = {entry["path"] for entry in default_backup_manifest["entries"]}
        backup_audit = cli(
            repo,
            db,
            "audit-db-first",
            "--backup-dir",
            ".github/db-backup/publication-default-backup",
            "--json",
        )
        backup_audit_payload = json.loads(backup_audit.stdout)
        if (
            publication_path in default_backup_paths
            or traversal_backup_path in default_backup_paths
            or stale_backup_publication.exists()
            or not traversal_victim.is_file()
            or backup_audit_payload.get("publication_backup_violation")
            or not backup_audit_payload.get("ok")
        ):
            raise AssertionError(
                f"backup route retained a task-run publication: {backup_audit_payload}"
            )
        assert_backup_layout_links_fail_closed(repo, db, publication_path)
        assert_failed_backup_preserves_previous_snapshot(repo, db, publication_path)
        assert_stored_snapshot_and_audit_binding(repo, db, publication_path)
        assert_manifest_consumer_and_restore_boundaries(repo, db, publication_path)
        assert_shim_backup_uses_stored_payload(temp)
        assert_authoritative_snapshot_prevents_resurrection(temp)
        assert_internal_alias_fails_without_cleanup(temp)
        assert_live_source_and_backup_root_boundaries(temp)
        cases += 1

        direct_snapshot_dir = repo / ".github/db-backup/publication-direct-snapshot"
        direct_snapshot = cli(
            repo,
            db,
            "snapshot-stored",
            "--path",
            publication_path,
            "--backup-dir",
            ".github/db-backup/publication-direct-snapshot",
            "--yes",
            check=False,
        )
        if direct_snapshot.returncode == 0 or (direct_snapshot_dir / "manifest.json").exists():
            raise AssertionError("direct stored snapshot accepted a task-run publication")
        default_snapshot_dir = repo / ".github/db-backup/publication-default-snapshot"
        stale_snapshot_publication = seed_stale_publication_backup(
            default_snapshot_dir,
            publication_path,
            (publishable / "completion-publication.md").read_bytes(),
        )
        cli(
            repo,
            db,
            "snapshot-stored",
            "--backup-dir",
            ".github/db-backup/publication-default-snapshot",
            "--yes",
        )
        default_snapshot_manifest = json.loads(
            (default_snapshot_dir / "manifest.json").read_text(encoding="utf-8")
        )
        default_snapshot_paths = {entry["path"] for entry in default_snapshot_manifest["entries"]}
        snapshot_audit = cli(
            repo,
            db,
            "audit-db-first",
            "--backup-dir",
            ".github/db-backup/publication-default-snapshot",
            "--json",
        )
        snapshot_audit_payload = json.loads(snapshot_audit.stdout)
        if (
            publication_path in default_snapshot_paths
            or stale_snapshot_publication.exists()
            or snapshot_audit_payload.get("publication_backup_violation")
            or not snapshot_audit_payload.get("ok")
        ):
            raise AssertionError(
                f"stored snapshot route retained a task-run publication: {snapshot_audit_payload}"
            )
        cases += 1

        trailing = write_publishable_run(repo, "publication-trailing-content")
        archive_sync(repo, db, trailing.name)
        write_publication_record(trailing)
        with (trailing / "completion-publication.md").open("a", encoding="utf-8") as handle:
            handle.write("\ntrailing content\n")
        failed = cli(
            repo,
            db,
            "publish-task-run",
            ".github/task-runs/publication-trailing-content",
            "--yes",
            check=False,
        )
        publication_path = ".github/task-runs/publication-trailing-content/completion-publication.md"
        if failed.returncode == 0 or db_count(db, "db_documents", publication_path) != 0:
            raise AssertionError("publisher accepted noncanonical trailing publication content")
        cases += 1

        mutated = write_publishable_run(repo, "marker-mutation")
        archive_sync(repo, db, mutated.name)
        write_publication_record(mutated)
        with (mutated / "run-manifest.json").open("a", encoding="utf-8") as handle:
            handle.write(" \n")
        failed = cli(
            repo,
            db,
            "publish-task-run",
            ".github/task-runs/marker-mutation",
            "--yes",
            check=False,
        )
        publication_path = ".github/task-runs/marker-mutation/completion-publication.md"
        if failed.returncode == 0 or db_count(db, "db_documents", publication_path) != 0:
            raise AssertionError("marker mutation was published or left a publication row")
        cases += 1

        conflict = write_publishable_run(repo, "staged-conflict")
        archive_sync(repo, db, conflict.name)
        write_publication_record(conflict)
        conn = sqlite3.connect(db)
        try:
            conn.execute(
                "INSERT INTO db_documents(path, kind, title, description, tags, sha256, line_count, "
                "content, source_indexed_at, stored_at) VALUES(?, ?, '', '', '', '', 1, 'orphan', '', '')",
                (".github/task-runs/staged-conflict/orphan.md", "task-run"),
            )
            conn.commit()
        finally:
            conn.close()
        failed = cli(
            repo,
            db,
            "publish-task-run",
            ".github/task-runs/staged-conflict",
            "--yes",
            check=False,
        )
        publication_path = ".github/task-runs/staged-conflict/completion-publication.md"
        if failed.returncode == 0 or db_count(db, "db_documents", publication_path) != 0:
            raise AssertionError("conflicting staged DB set was published")
        cases += 1

        bad_db_run = write_publishable_run(repo, "db-open-failure")
        archive_sync(repo, db, bad_db_run.name)
        write_publication_record(bad_db_run)
        bad_db = temp / "db-is-directory"
        bad_db.mkdir()
        failed = cli(
            repo,
            bad_db,
            "publish-task-run",
            ".github/task-runs/db-open-failure",
            "--yes",
            check=False,
        )
        backup_manifest = json.loads(
            (repo / ".github/db-backup/publication-regression/manifest.json").read_text(encoding="utf-8")
        )
        backup_paths = {entry["path"] for entry in backup_manifest["entries"]}
        if failed.returncode == 0 or any(
            Path(path).name == "completion-publication.md" for path in backup_paths
        ):
            raise AssertionError("failed publication leaked into a rehydratable backup")
        cases += 1

        sync_dir = repo / ".github/task-runs/all-shim-sync"
        sync_dir.mkdir()
        current_rel = ".github/task-runs/all-shim-sync/current.md"
        obsolete_rel = ".github/task-runs/all-shim-sync/obsolete.md"
        (sync_dir / "current.md").write_text("# current\n", encoding="utf-8")
        (sync_dir / "obsolete.md").write_text("# obsolete\n", encoding="utf-8")
        archive_sync(repo, db, "all-shim-sync")
        (sync_dir / "current.md").write_text(
            f"# DB-backed {current_rel}\n\n"
            f"python3 scripts/github_index_db.py load --source stored --path {current_rel}\n",
            encoding="utf-8",
        )
        (sync_dir / "obsolete.md").unlink()
        archive_sync(repo, db, "all-shim-sync")
        backup_manifest = json.loads(
            (repo / ".github/db-backup/publication-regression/manifest.json").read_text(encoding="utf-8")
        )
        backup_paths = {entry["path"] for entry in backup_manifest["entries"]}
        if (
            db_count(db, "db_documents", current_rel) != 1
            or db_count(db, "db_documents", obsolete_rel) != 0
            or db_count(db, "files", obsolete_rel) != 0
            or obsolete_rel in backup_paths
        ):
            raise AssertionError("all-shim exact sync retained stale DB/index/backup state")
        cases += 1

        rehydrate = cli(
            repo,
            db,
            "rehydrate",
            "--backup-dir",
            ".github/db-backup/publication-regression",
            "--path",
            ".github/task-runs/atomic-pass/completion-publication.md",
            "--yes",
            check=False,
        )
        if rehydrate.returncode == 0:
            raise AssertionError("rehydrate accepted a task-run publication record")
        cases += 1

        generic = write_publishable_run(repo, "generic-route-block")
        write_publication_record(generic)
        generic_rel = ".github/task-runs/generic-route-block/completion-publication.md"
        cli(repo, db, "refresh", generic_rel)
        original_publication = (generic / "completion-publication.md").read_bytes()
        generic_attempts = [
            (
                "update-stored",
                generic_rel,
                "--content",
                "# Task Run Publication\n\ninvalid generic write\n",
            ),
            ("promote", "--path", generic_rel),
            (
                "migrate",
                "--path",
                generic_rel,
                "--backup-dir",
                ".github/db-backup/generic-route-block",
                "--yes",
            ),
        ]
        for attempt in generic_attempts:
            result = cli(repo, db, *attempt, check=False)
            if result.returncode == 0:
                raise AssertionError(f"generic route accepted publication: {attempt[0]}")
        nested_rel = ".github/task-runs/generic-route-block/nested/completion-publication.md"
        nested_attempt = cli(
            repo,
            db,
            "update-stored",
            nested_rel,
            "--content",
            "# Task Run Publication\n",
            check=False,
        )
        if nested_attempt.returncode == 0 or db_count(db, "db_documents", nested_rel) != 0:
            raise AssertionError("generic route accepted a nested publication record")
        if (
            db_count(db, "db_documents", generic_rel) != 0
            or (generic / "completion-publication.md").read_bytes() != original_publication
        ):
            raise AssertionError("generic route inserted or rewrote a task-run publication")
        cases += 1

        legacy_dir = repo / ".github/task-runs/legacy-no-contract"
        legacy_dir.mkdir()
        (legacy_dir / "task-report.md").write_text(
            report_text("legacy-no-contract", contract=None), encoding="utf-8"
        )
        archive_sync(repo, db, "legacy-no-contract")
        downgrade_dir = repo / ".github/task-runs/downgrade-body"
        downgrade_dir.mkdir()
        (downgrade_dir / "task-report.md").write_text(
            report_text(
                "downgrade-body",
                trailer="\n- `publication_contract`: legacy\n",
            ),
            encoding="utf-8",
        )
        archive_sync(repo, db, "downgrade-body")
        nested_dir = repo / ".github/task-runs/nested/sub"
        nested_dir.mkdir(parents=True)
        (nested_dir / "task-report.md").write_text(
            report_text("nested", contract=None), encoding="utf-8"
        )
        cli(
            repo,
            db,
            "archive-markdown",
            ".github/task-runs/nested",
            "--backup-dir",
            ".github/db-backup/publication-regression",
            "--yes",
        )
        completed = visible_completed(repo, db)
        if [item.get("run_id") for item in completed] != ["atomic-pass"]:
            raise AssertionError(f"legacy/downgraded/nested report bypassed publication: {completed}")
        cases += 1

    print(f"PASS task-run-publication-regression cases={cases}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, sqlite3.Error, UnicodeError, ValueError) as exc:
        print(f"FAIL task-run-publication-regression: {exc}", file=sys.stderr)
        raise SystemExit(1)
