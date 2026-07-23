#!/usr/bin/env bash

e2e_github_index_backup_entry_valid() {
  local backup_dir="$1"
  local rel_path="$2"
  local expected_file="${3:-}"
  python3 - "$backup_dir" "$rel_path" "$expected_file" <<'PY'
import hashlib
import json
import sys
from pathlib import Path, PurePosixPath

backup_dir = Path(sys.argv[1]).resolve()
rel_path = sys.argv[2]
expected_file = Path(sys.argv[3]) if sys.argv[3] else None
relative = PurePosixPath(rel_path)
if relative.is_absolute() or any(part in {"", ".", ".."} for part in relative.parts):
    raise SystemExit(f"noncanonical backup path: {rel_path}")
manifest_path = backup_dir / "manifest.json"
if manifest_path.is_symlink() or not manifest_path.is_file():
    raise SystemExit(f"missing ordinary backup manifest: {manifest_path}")
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
entries = [entry for entry in manifest.get("entries", []) if entry.get("path") == rel_path]
if len(entries) != 1:
    raise SystemExit(f"backup entry cardinality mismatch: {rel_path}")
entry = entries[0]
digest = entry.get("sha256")
if not isinstance(digest, str) or len(digest) != 64:
    raise SystemExit(f"invalid backup digest: {rel_path}")
object_ref = entry.get("backup_object")
if object_ref is None:
    payload_parts = ("files", *relative.parts)
else:
    expected_ref = f"objects/sha256/{digest[:2]}/{digest}"
    if object_ref != expected_ref:
        raise SystemExit(f"backup object binding mismatch: {rel_path}")
    payload_parts = PurePosixPath(object_ref).parts
payload = backup_dir
for part in payload_parts:
    payload = payload / part
    if payload.is_symlink():
        raise SystemExit(f"backup payload path contains symlink: {rel_path}")
if not payload.is_file() or payload.stat().st_nlink != 1:
    raise SystemExit(f"missing ordinary backup payload: {rel_path}")
raw = payload.read_bytes()
if entry.get("size_bytes") != len(raw) or hashlib.sha256(raw).hexdigest() != digest:
    raise SystemExit(f"backup payload size/hash mismatch: {rel_path}")
if expected_file is not None and raw != expected_file.read_bytes():
    raise SystemExit(f"backup payload content mismatch: {rel_path}")
PY
}

e2e_github_index_contract() {
  echo "[github-index] contract"
  local rc=0

  e2e_print_required_files \
    scripts/github_index_db.py \
    scripts/dev_memory/core.py \
    scripts/dev_memory/queries.py \
    scripts/dev_memory/api.py \
    scripts/dev_memory/maintenance.py \
    scripts/dev_memory/cli.py \
    scripts/dev_memory/__main__.py \
    scripts/e2e/tests/task_run_publication_regression.py \
    .github/e2e/modules/github-index.md \
    .github/e2e/profiles/github-index.tsv || rc=1

  echo "[github-index] project layout"
  if grep -Fq -- 'from dev_memory.cli import main' "$E2E_ROOT_DIR/scripts/github_index_db.py" &&
     grep -Fq -- 'from .cli import main' "$E2E_ROOT_DIR/scripts/dev_memory/__main__.py" &&
     grep -Fq -- 'def build_parser' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'def rebuild' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'def load_chunks' "$E2E_ROOT_DIR/scripts/dev_memory/queries.py" &&
     grep -Fq -- 'def memory_api' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def migrate_to_db' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def archive_markdown_files' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def publish_task_run' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py"; then
    printf 'PASS github-index implementation lives in dev_memory package with compatibility wrapper\n'
  else
    printf 'FAIL github-index implementation package layout drifted\n'
    rc=1
  fi

  echo "[github-index] tracked persistent sources"
  if git -C "$E2E_ROOT_DIR" ls-files --error-unmatch \
      scripts/github_index_db.py \
      scripts/dev_memory/__init__.py \
      scripts/dev_memory/__main__.py \
      scripts/dev_memory/core.py \
      scripts/dev_memory/queries.py \
      scripts/dev_memory/api.py \
      scripts/dev_memory/maintenance.py \
      scripts/dev_memory/cli.py \
      scripts/e2e/modules/github_index.sh \
      .github/e2e/modules/github-index.md \
      .github/e2e/profiles/github-index.tsv >/dev/null 2>&1; then
    printf 'PASS github-index core persistent sources are tracked; publication regression executable is present\n'
  else
    printf 'FAIL github-index persistent sources are not tracked\n'
    rc=1
  fi

  echo "[github-index] filesystem source and database boundary"
  if grep -Fq 'DEFAULT_ROOT = ".github"' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq 'DEFAULT_DB = ".github/cache/github-index.sqlite"' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq 'sqlite3' "$E2E_ROOT_DIR/scripts/dev_memory/core.py"; then
    printf 'PASS github-index defaults to .github source and .github/cache SQLite index\n'
  else
    printf 'FAIL github-index source/db defaults drifted\n'
    rc=1
  fi
  if grep -Fq '.github/cache/' "$E2E_ROOT_DIR/.gitignore"; then
    printf 'PASS github-index database cache is ignored by git\n'
  else
    printf 'FAIL github-index database cache is not ignored by git\n'
    rc=1
  fi

  echo "[github-index] chunked summary/load interface"
  if grep -Fq -- 'CREATE TABLE IF NOT EXISTS file_chunks' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'chunk_fts' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'aliases=["compact"]' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'def load_chunks' "$E2E_ROOT_DIR/scripts/dev_memory/queries.py"; then
    printf 'PASS github-index exposes chunked summary/load memory interface\n'
  else
    printf 'FAIL github-index chunked summary/load interface drifted\n'
    rc=1
  fi

  echo "[github-index] agent entry shims included in database"
  if grep -Fq -- 'DEFAULT_EXTRA_SOURCES' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- '"AGENTS.md"' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- '".cursor/rules/agents.mdc"' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'agent-shim' "$E2E_ROOT_DIR/scripts/dev_memory/core.py"; then
    printf 'PASS github-index indexes root/multi-agent entry shims by default\n'
  else
    printf 'FAIL github-index default agent entry shim include drifted\n'
    rc=1
  fi

  echo "[github-index] retained memory/log interface"
  if grep -Fq -- 'CREATE TABLE IF NOT EXISTS db_documents' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'DB_RETAINED_KINDS' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'CREATE TABLE IF NOT EXISTS evidence_assets' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'def promote_documents' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def update_stored_document' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'refusing to store DB-backed shim payload' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def migrate_to_db' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def restore_backup' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def snapshot_stored_documents' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def rehydrate_stored_documents' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def audit_db_first' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'DB_FIRST_STRICT_LIVE_KINDS' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def doctor_is_blocking_drift_state' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def doctor_is_nonblocking_drift_state' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def doctor_should_print_state' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def doctor_should_print_samples' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'getattr(args, "show_nonblocking_drift", False)' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'getattr(args, "show_diagnostic_details", False)' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'getattr(args, "show_status_samples", False)' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'show_status_samples=False' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'show_diagnostic_details=False' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'show_nonblocking_drift' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'show_diagnostic_details' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'show_status_samples' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- '"database is locked" not in str(exc).lower()' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'blocking_drift=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def doctor_display_state' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'historical_archive_diagnostics=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'live_index_cache_diagnostics=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'diagnostic_only=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'diagnostic_only_note=ignored_by_fail_on_drift' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'nonblocking_db_first_drift=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'nonblocking_live_drift=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- '--show-nonblocking-drift' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- '--show-diagnostic-details' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- '--show-status-samples' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'archived_stored_only' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def audit_markdown_coverage' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def archive_markdown_files' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def index_evidence_assets' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'stored_index_docs' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'store-evidence-index-documents' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'archive-markdown' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'publish-task-run' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'index-evidence' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- '--backup-dir' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'snapshot-stored' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'rehydrate' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'prune-non-retained' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'choices=["auto", "live", "stored"]' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py"; then
    printf 'PASS github-index exposes retained memory/log promote/update/migrate/restore/audit interface\n'
  else
    printf 'FAIL github-index retained memory/log interface drifted\n'
    rc=1
  fi

  echo "[github-index] e2e task-run archive hook"
  if grep -Fq -- 'e2e_archive_task_run_markdown_to_db' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'publish-task-run "$run_rel"' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- '--sync-task-run' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'e2e_index_task_run_evidence_assets' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'index-evidence "$run_rel"' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- '--backup-dir "$backup_dir"' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'archive-markdown "$run_rel"' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'E2E_TASK_RUN_DB_BACKUP_DIR' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh"; then
    printf 'PASS e2e report layer indexes raw evidence and archives task-run Markdown into DB\n'
  else
    printf 'FAIL e2e report layer does not index evidence and archive task-run Markdown into DB\n'
    rc=1
  fi

  echo "[github-index] e2e context brief hook"
  if grep -Fq -- 'e2e_generate_context_brief' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'E2E_CONTEXT_BRIEF_FILE' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'github_index_db.py" brief' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'e2e_generate_context_brief' "$E2E_ROOT_DIR/scripts/agent-e2e.sh"; then
    printf 'PASS e2e runner generates DB-indexed context brief before dispatch\n'
  else
    printf 'FAIL e2e runner context brief hook missing\n'
    rc=1
  fi

  echo "[github-index] e2e resolved profile hook"
  if grep -Fq -- 'e2e_generate_profile_resolve' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'E2E_PROFILE_RESOLVE_FILE' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'github_index_db.py" resolve-profile' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'e2e_generate_profile_resolve' "$E2E_ROOT_DIR/scripts/agent-e2e.sh"; then
    printf 'PASS e2e runner generates live/indexed resolved profile before dispatch\n'
  else
    printf 'FAIL e2e runner resolved profile hook missing\n'
    rc=1
  fi

  echo "[github-index] external AI JSON API interface"
  if grep -Fq -- 'def memory_api' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'github-index-jsonl-v1' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'api_search' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'api_summary' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'api_load' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def brief_payload' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def profile_suggestions' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def profile_catalog_payload' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def resolve_profile_payload' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def task_runs_payload' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def evidence_assets_payload' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'CREATE TABLE IF NOT EXISTS access_log' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'def record_access' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'def usage_payload' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def agent_brief' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def agent_profiles' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def agent_resolve_profile' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def agent_runs' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def agent_evidence' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def agent_usage' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- '--focus-scope' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'append_excluded_kinds' "$E2E_ROOT_DIR/scripts/dev_memory/queries.py" &&
     grep -Fq -- '--profile-limit' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'profile-catalog' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'resolve-profile' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'run-catalog' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'evidence-assets' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'access-log' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- '"profiles": {"fields"' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- '"resolve-profile": {"fields"' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- '"runs": {"fields"' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- '"evidence": {"fields"' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- '"usage": {"fields"' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'brief' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py"; then
    printf 'PASS github-index exposes external AI JSON/JSONL memory API\n'
  else
    printf 'FAIL github-index external AI API interface drifted\n'
    rc=1
  fi

  echo "[github-index] python syntax"
  python3 - "$E2E_ROOT_DIR/scripts/github_index_db.py" "$E2E_ROOT_DIR"/scripts/dev_memory/*.py <<'PY' || rc=1
import sys
from pathlib import Path

for raw_path in sys.argv[1:]:
    path = Path(raw_path)
    compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY

  echo "[github-index] excluded directory traversal pruning regression"
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$E2E_ROOT_DIR/scripts" python3 - <<'PY' || rc=1
import tempfile
from pathlib import Path

from dev_memory import core

with tempfile.TemporaryDirectory() as raw_root:
    repo = Path(raw_root)
    github = repo / ".github"
    (github / "task-runs" / "old" / "evidence").mkdir(parents=True)
    (github / "db-backup" / "objects").mkdir(parents=True)
    (github / "instructions").mkdir(parents=True)
    (github / "task-runs" / "old" / "task-report.md").write_text("old run\n", encoding="utf-8")
    (github / "task-runs" / "old" / "evidence" / "raw.log").write_text("raw\n", encoding="utf-8")
    (github / "db-backup" / "objects" / "object.md").write_text("backup\n", encoding="utf-8")
    (github / "instructions" / "active.md").write_text("# Active\n", encoding="utf-8")

    original = core.index_one_file
    visited: list[str] = []

    def guarded(repo_root, path, max_bytes, db_rel_path, excludes):
        rel = path.relative_to(repo_root).as_posix()
        if rel.startswith(".github/task-runs/") or rel.startswith(".github/db-backup/"):
            raise AssertionError(f"pruned directory was traversed: {rel}")
        visited.append(rel)
        return original(repo_root, path, max_bytes, db_rel_path, excludes)

    core.index_one_file = guarded
    try:
        items = core.scan_files(
            repo,
            github,
            github / "cache" / "index.sqlite",
            1_048_576,
            [".github/task-runs"],
            [],
        )
    finally:
        core.index_one_file = original

    assert [item.path for item in items] == [".github/instructions/active.md"], visited

print("PASS github-index prunes excluded/retained directories before visiting their files")
PY

  echo "[github-index] atomic task-run publication regression"
  PYTHONDONTWRITEBYTECODE=1 \
    python3 "$E2E_ROOT_DIR/scripts/e2e/tests/task_run_publication_regression.py" || rc=1

  echo "[github-index] temporary rebuild/stat/query/summary/load/show/doctor smoke"
  local tmp_dir tmp_db
  tmp_dir=$(mktemp -d)
  tmp_db="$tmp_dir/github-index.sqlite"
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" rebuild \
    --repo-root "$E2E_ROOT_DIR" \
    --root .github/e2e \
    --db "$tmp_db" \
    --include .github/memory \
    --include .github/agents \
    --exclude "$(e2e_relpath "$E2E_RUN_DIR")" \
    --max-bytes 1048576 || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" stat \
    --repo-root "$E2E_ROOT_DIR" \
    --db "$tmp_db" || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" ls .github/e2e \
    --repo-root "$E2E_ROOT_DIR" \
    --db "$tmp_db" \
    --limit 16 || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" tree .github/e2e \
    --repo-root "$E2E_ROOT_DIR" \
    --db "$tmp_db" \
    --depth 2 \
    --limit 32 || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" show AGENTS.md \
    --repo-root "$E2E_ROOT_DIR" \
    --db "$tmp_db" || rc=1

  local query_out summary_out load_out shim_load_out
  query_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" query software-flow \
      --repo-root "$E2E_ROOT_DIR" \
      --db "$tmp_db" \
      --status indexed \
      --mode auto \
      --limit 8
  ) || rc=1
  printf '%s\n' "$query_out"
  if grep -Fq '.github/agents/software-flow.agent.md' <<< "$query_out" ||
     grep -Fq '.github/memory/modules/software-flow.md' <<< "$query_out" ||
     grep -Fq '.github/e2e/modules/software-flow.md' <<< "$query_out"; then
    printf 'PASS github-index query returns software-flow .github artifacts\n'
  else
    printf 'FAIL github-index query did not return expected software-flow artifacts\n'
    rc=1
  fi

  summary_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" summary .github/memory \
      --repo-root "$E2E_ROOT_DIR" \
      --db "$tmp_db" \
      --status indexed \
      --limit 8
  ) || rc=1
  printf '%s\n' "$summary_out"
  if grep -Fq -- 'summary=.github/memory' <<< "$summary_out" &&
     grep -Fq -- 'chunks=' <<< "$summary_out" &&
     grep -Fq -- 'token_estimate=' <<< "$summary_out"; then
    printf 'PASS github-index summary compresses memory files into chunk/token overview\n'
  else
    printf 'FAIL github-index summary did not expose chunk/token overview\n'
    rc=1
  fi

  load_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load software-flow \
      --repo-root "$E2E_ROOT_DIR" \
      --db "$tmp_db" \
      --kind e2e-profile \
      --status indexed \
      --mode auto \
      --limit 2 \
      --max-tokens 600
  ) || rc=1
  printf '%s\n' "$load_out"
  if grep -Fq -- 'load=software-flow' <<< "$load_out" &&
     grep -Fq -- 'mode=chunk-' <<< "$load_out" &&
     grep -Fq -- '#chunk-' <<< "$load_out"; then
    printf 'PASS github-index load returns bounded matching chunks\n'
  else
    printf 'FAIL github-index load did not return bounded chunks\n'
    rc=1
  fi

  shim_load_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load \
      --path AGENTS.md \
      --repo-root "$E2E_ROOT_DIR" \
      --db "$tmp_db" \
      --limit 1 \
      --max-tokens 1200
  ) || rc=1
  printf '%s\n' "$shim_load_out"
  if grep -Fq -- 'load=AGENTS.md mode=path' <<< "$shim_load_out" &&
     grep -Fq -- '[agent-shim indexed]' <<< "$shim_load_out"; then
    printf 'PASS github-index load returns root AGENTS shim from database\n'
  else
    printf 'FAIL github-index load did not return root AGENTS shim\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" doctor \
    --repo-root "$E2E_ROOT_DIR" \
    --db "$tmp_db" \
    --max-bytes 1048576 \
    --fail-on-drift || rc=1

  echo "[github-index] add/refresh/remove maintenance smoke"
  local mini_repo mini_db
  mini_repo="$tmp_dir/mini-repo"
  mini_db="$tmp_dir/mini-index.sqlite"
  mkdir -p "$mini_repo/.github"
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" add memory/github-index-note.md \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --content $'# Mini github-index note\n\nsoftware-flow github-index maintenance\n' || rc=1
  local excluded_rebuild_out
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" rebuild \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --exclude .github/memory || rc=1
  excluded_rebuild_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" show .github/memory/github-index-note.md \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --json
  ) || rc=1
  if grep -Fq '"exists_flag": 1' <<< "$excluded_rebuild_out" &&
     grep -Fq '"index_status": "indexed"' <<< "$excluded_rebuild_out"; then
    printf 'PASS github-index rebuild preserves explicitly excluded live-index rows\n'
  else
    printf 'FAIL github-index rebuild marked an explicitly excluded row missing\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" ls memory \
    --repo-root "$mini_repo" \
    --db "$mini_db" || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" search github-index \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --mode auto \
    --limit 4 || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load github-index \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --mode auto \
    --limit 2 \
    --max-tokens 300 || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" refresh memory/github-index-note.md \
    --repo-root "$mini_repo" \
    --db "$mini_db" || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" remove memory/github-index-note.md \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --delete-file \
    --yes || rc=1
  if [[ -e "$mini_repo/.github/memory/github-index-note.md" ]]; then
    printf 'FAIL github-index remove left source file behind\n'
    rc=1
  else
    printf 'PASS github-index remove deleted source file in mini repo\n'
  fi

  echo "[github-index] retained memory/log migrate/restore mini smoke"
  cat > "$mini_repo/AGENTS.md" <<'EOF'
# Mini AGENTS

mini live source
EOF
  cat > "$mini_repo/.github/AGENTS.md" <<'EOF'
# Mini Canonical AGENTS

__BRIEF_CANONICAL_REQUIRED__
EOF
  mkdir -p "$mini_repo/.github/memory/modules"
  cat > "$mini_repo/.github/memory/project-status.md" <<'EOF'
# Mini Project Status

mini retained memory source
EOF
  {
    printf '# Brief Focus Memory\n\nBRIEF_PRIORITY_FOCUS CURRENT MEMORY FOCUS '
    for _ in $(seq 1 260); do
      printf 'priorityfiller '
    done
    printf '\n'
  } > "$mini_repo/.github/memory/modules/brief-focus.md"
  mkdir -p "$mini_repo/.github/task-runs/blocked-self"
  cat > "$mini_repo/.github/task-runs/blocked-self/context-brief.md" <<'EOF'
# Agent Brief

- `ok`: false
- `recall_status`: failed
- `profile`: github-index
- `terms`: HISTORY SELF LOOP
EOF
  cat > "$mini_repo/.github/task-runs/blocked-self/task-report.md" <<'EOF'
# 任务报告

## 基本信息

- `task_id`: blocked-self
- `task_slug`: history-self-loop
- `profile`: github-index
- `status`: blocked
EOF
  mkdir -p "$mini_repo/.github/task-runs/history-saturation"
  {
    printf '# Agent Brief\n'
    for history_id in $(seq -w 1 140); do
      printf '\n## Historical hit %s\n\nSATURATED LIVE FOCUS\n' "$history_id"
    done
  } > "$mini_repo/.github/task-runs/history-saturation/context-brief.md"
  cat > "$mini_repo/.github/z-current-focus.md" <<'EOF'
# Current Focus

SATURATED LIVE FOCUS
EOF
  mkdir -p "$mini_repo/.github/agents"
  cat > "$mini_repo/.github/agents/demo.agent.md" <<'EOF'
# Demo Agent

demo stored agent config
EOF
  mkdir -p "$mini_repo/.github/e2e/profiles" "$mini_repo/.github/e2e/modules"
  cat > "$mini_repo/.github/e2e/profiles/base-gate.tsv" <<'EOF'
# node_id|module|function|owner_agent|inputs|outputs
base-smoke|agent-system|e2e_base_smoke|agent-system|base profile input|base profile output
EOF
  cat > "$mini_repo/.github/e2e/profiles/github-index.tsv" <<'EOF'
# node_id|module|function|owner_agent|inputs|outputs
github-index-smoke|github-index|e2e_github_index_contract|github-index|__BRIEF_PROFILE_REQUIRED__|brief profile output
EOF
  cat > "$mini_repo/.github/e2e/profiles/nemu-ubuntu-full-gate.tsv" <<'EOF'
# node_id|module|function|owner_agent|inputs|outputs
@include|base-gate||||
nemu-ubuntu-full-focused-gate|nemu|e2e_nemu_ubuntu_full_focused_gate|nemu|optional full Ubuntu rootfs/systemd guest gate|full Ubuntu rootfs guest gate
EOF
  cat > "$mini_repo/.github/e2e/modules/nemu-ubuntu-full-gate.md" <<'EOF'
# NEMU Ubuntu Full Gate

full Ubuntu rootfs systemd guest gate profile
EOF
  mkdir -p "$mini_repo/.github/instructions" "$mini_repo/.github/shujuku_aireview"
  for focus_id in 1 2 3 4; do
    printf '# Focus Limit %s\n\nFOCUS_LIMIT_MARKER rule-%s\n' \
      "$focus_id" "$focus_id" \
      > "$mini_repo/.github/instructions/focus-limit-$focus_id.instructions.md"
  done
  cat > "$mini_repo/.github/shujuku_aireview/old-focus.md" <<'EOF'
# Historical Review Focus

BRIEF_PRIORITY_FOCUS __EXCLUDED_REVIEW_FOCUS__
EOF
  {
    printf '# Oversized Load Candidate\n\nLOAD_BUDGET_SHARED LOAD_ONLY_OVERSIZE '
    for _ in $(seq 1 260); do
      printf 'oversizefiller '
    done
    printf '\n'
  } > "$mini_repo/.github/instructions/a-budget-oversize.instructions.md"
  cat > "$mini_repo/.github/instructions/z-budget-small.instructions.md" <<'EOF'
# Small Load Candidate

LOAD_BUDGET_SHARED __SMALL_LATER_CHUNK__
EOF
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" rebuild \
    --repo-root "$mini_repo" \
    --db "$mini_db" || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" migrate \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --path .github/memory/modules/brief-focus.md \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" refresh .github/agents/demo.agent.md \
    --repo-root "$mini_repo" \
    --db "$mini_db" || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" migrate \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --path .github/memory/project-status.md \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  if grep -Fq -- 'DB-backed .github/memory/project-status.md' "$mini_repo/.github/memory/project-status.md" &&
     e2e_github_index_backup_entry_valid \
       "$mini_repo/.github/db-backup/test" \
       .github/memory/project-status.md; then
    printf 'PASS github-index migrate leaves retained memory shim and backup\n'
  else
    printf 'FAIL github-index migrate did not leave retained memory shim and backup\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --source stored \
    --path .github/memory/project-status.md \
    --limit 1 \
    --max-tokens 200 || rc=1
  cat > "$mini_repo/updated-memory.md" <<'EOF'
# Mini Project Status

mini retained memory updated in stored db
EOF
  local stored_update_out
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" update-stored .github/memory/project-status.md \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --from-file updated-memory.md || rc=1
  stored_update_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --source stored \
      --path .github/memory/project-status.md \
      --limit 1 \
      --max-tokens 200
  ) || rc=1
  printf '%s\n' "$stored_update_out"
  if grep -Fq -- 'updated in stored db' <<< "$stored_update_out"; then
    printf 'PASS github-index update-stored changes database-owned content\n'
  else
    printf 'FAIL github-index update-stored did not change stored content\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" snapshot-stored \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --path .github/memory/project-status.md \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  if e2e_github_index_backup_entry_valid \
       "$mini_repo/.github/db-backup/test" \
       .github/memory/project-status.md \
       "$mini_repo/updated-memory.md"; then
    printf 'PASS github-index snapshots update-stored content before three-way audit\n'
  else
    printf 'FAIL github-index update-stored snapshot did not bind DB and CAS content\n'
    rc=1
  fi
  cat > "$mini_repo/shim-payload.md" <<'EOF'
# DB-backed .github/memory/project-status.md

- 按需加载：`python3 scripts/github_index_db.py load --source stored --path .github/memory/project-status.md`
EOF
  local shim_update_out shim_update_rc
  shim_update_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" update-stored .github/memory/project-status.md \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --from-file shim-payload.md 2>&1
  )
  shim_update_rc=$?
  printf '%s\n' "$shim_update_out"
  if [[ $shim_update_rc -ne 0 ]] &&
     grep -Fq -- 'refusing to store DB-backed shim payload' <<< "$shim_update_out"; then
    printf 'PASS github-index update-stored refuses DB-backed shim payload\n'
  else
    printf 'FAIL github-index update-stored accepted DB-backed shim payload\n'
    rc=1
  fi
  local readonly_lock_out
  readonly_lock_out=$(
    python3 - "$E2E_ROOT_DIR" "$mini_repo" "$mini_db" <<'PY'
import sqlite3
import subprocess
import sys
from pathlib import Path

e2e_root = Path(sys.argv[1])
mini_repo = Path(sys.argv[2])
mini_db = Path(sys.argv[3])

conn = sqlite3.connect(str(mini_db), timeout=30)
conn.execute("BEGIN IMMEDIATE")
try:
    result = subprocess.run(
        [
            sys.executable,
            str(e2e_root / "scripts/github_index_db.py"),
            "load",
            "--source",
            "stored",
            "--path",
            ".github/memory/project-status.md",
            "--db",
            str(mini_db),
            "--limit",
            "1",
            "--max-tokens",
            "200",
        ],
        cwd=mini_repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
    )
    print(f"rc={result.returncode}")
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print("stderr=" + result.stderr.strip())
    raise SystemExit(result.returncode)
finally:
    conn.rollback()
    conn.close()
PY
  ) || rc=1
  printf '%s\n' "$readonly_lock_out"
  if grep -Fq -- 'rc=0' <<< "$readonly_lock_out" &&
     grep -Fq -- 'updated in stored db' <<< "$readonly_lock_out"; then
    printf 'PASS github-index stored load remains available while access log write is locked\n'
  else
    printf 'FAIL github-index stored load blocked behind access-log/write lock\n'
    rc=1
  fi
  local api_readonly_lock_out
  api_readonly_lock_out=$(
    python3 - "$E2E_ROOT_DIR" "$mini_repo" "$mini_db" <<'PY'
import sqlite3
import subprocess
import sys
from pathlib import Path

e2e_root = Path(sys.argv[1])
mini_repo = Path(sys.argv[2])
mini_db = Path(sys.argv[3])

conn = sqlite3.connect(str(mini_db), timeout=30)
conn.execute("BEGIN IMMEDIATE")
try:
    result = subprocess.run(
        [
            sys.executable,
            str(e2e_root / "scripts/github_index_db.py"),
            "api",
            "--db",
            str(mini_db),
            "--request",
            '{"op":"load","path":".github/memory/project-status.md","source":"stored","limit":1,"max_tokens":200}',
        ],
        cwd=mini_repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
    )
    print(f"rc={result.returncode}")
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print("stderr=" + result.stderr.strip())
    raise SystemExit(result.returncode)
finally:
    conn.rollback()
    conn.close()
PY
  ) || rc=1
  printf '%s\n' "$api_readonly_lock_out"
  if grep -Fq -- 'rc=0' <<< "$api_readonly_lock_out" &&
     grep -Fq -- '"op": "load"' <<< "$api_readonly_lock_out" &&
     grep -Fq -- 'updated in stored db' <<< "$api_readonly_lock_out"; then
    printf 'PASS github-index API load remains available while access log write is locked\n'
  else
    printf 'FAIL github-index API load blocked behind access-log/write lock\n'
    rc=1
  fi
  local api_out
  api_out=$(
    printf '%s\n' \
      '{"op":"stat"}' \
      '{"op":"search","terms":"updated","source":"stored","limit":2}' \
      '{"op":"summary","path":".github/memory/project-status.md","source":"stored","limit":1}' \
      '{"op":"load","path":".github/memory/project-status.md","source":"stored","limit":1,"max_tokens":200}' \
      '{"op":"show","path":".github/memory/project-status.md","source":"stored"}' |
      python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" api \
        --repo-root "$mini_repo" \
        --db "$mini_db" \
        --jsonl
  ) || rc=1
  printf '%s\n' "$api_out"
  if grep -Fq -- '"op":"stat"' <<< "$api_out" &&
     grep -Fq -- '"stored_documents":' <<< "$api_out" &&
     grep -Fq -- '"op":"search"' <<< "$api_out" &&
     grep -Fq -- '"op":"summary"' <<< "$api_out" &&
     grep -Fq -- '"op":"load"' <<< "$api_out" &&
     grep -Fq -- '"op":"show"' <<< "$api_out" &&
     grep -Fq -- 'updated in stored db' <<< "$api_out"; then
    printf 'PASS github-index JSONL API serves stored search/summary/load/show for external AI\n'
  else
    printf 'FAIL github-index JSONL API did not serve expected stored memory data\n'
    rc=1
  fi
  echo "[github-index] strict brief/load budget and recall contract"
  if python3 - "$E2E_ROOT_DIR/scripts/github_index_db.py" "$mini_repo" "$mini_db" <<'PY'
import json
import sqlite3
import subprocess
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
db = Path(sys.argv[3])


def run_cli(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(script),
            *args,
            "--repo-root",
            str(repo),
            "--db",
            str(db),
        ],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=20,
    )


def payload(result: subprocess.CompletedProcess[str]) -> object:
    if not result.stdout.strip():
        raise AssertionError(
            f"missing JSON output rc={result.returncode} stderr={result.stderr.strip()}"
        )
    return json.loads(result.stdout)


def api(request: dict[str, object]) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
    result = run_cli("api", "--request", json.dumps(request, separators=(",", ":")))
    value = payload(result)
    assert isinstance(value, dict)
    return result, value


conn = sqlite3.connect(db)
canonical_tokens = conn.execute(
    "SELECT token_estimate FROM file_chunks WHERE path=? ORDER BY ordinal LIMIT 1",
    (".github/AGENTS.md",),
).fetchone()[0]
profile_tokens = conn.execute(
    "SELECT token_estimate FROM file_chunks WHERE path=? ORDER BY ordinal LIMIT 1",
    (".github/e2e/profiles/github-index.tsv",),
).fetchone()[0]
focus_tokens = conn.execute(
    "SELECT token_estimate FROM db_document_chunks WHERE path=? ORDER BY ordinal LIMIT 1",
    (".github/memory/modules/brief-focus.md",),
).fetchone()[0]
focus_limit_matches = conn.execute(
    "SELECT COUNT(DISTINCT path) FROM file_chunks WHERE text LIKE ?",
    ("%FOCUS_LIMIT_MARKER%",),
).fetchone()[0]
profile_dedup_matches = conn.execute(
    "SELECT COUNT(*) FROM file_chunks WHERE path=? AND text LIKE ?",
    (".github/e2e/profiles/github-index.tsv", "%__BRIEF_PROFILE_REQUIRED__%"),
).fetchone()[0]
conn.close()

tight_budget = int(canonical_tokens) + int(profile_tokens) + int(focus_tokens)
priority_result = run_cli(
    "brief",
    "BRIEF_PRIORITY_FOCUS",
    "--profile",
    "github-index",
    "--focus-limit",
    "1",
    "--max-tokens",
    str(tight_budget),
    "--json",
)
priority = payload(priority_result)
assert isinstance(priority, dict)
priority_paths = [chunk["path"] for chunk in priority["chunks"]]
assert priority_result.returncode == 0, priority
assert priority["ok"] is True and priority["recall_status"] == "complete", priority
assert priority["token_estimate"] <= priority["max_tokens"] == tight_budget, priority
assert priority_paths[:3] == [
    ".github/AGENTS.md",
    ".github/e2e/profiles/github-index.tsv",
    ".github/memory/modules/brief-focus.md",
], priority_paths
assert priority["primary_focus"]["path"] == ".github/memory/modules/brief-focus.md"
assert priority["focus_match_count"] == 1
assert priority["focus_selected_count"] == 1
assert all(not path.startswith(".github/shujuku_aireview/") for path in priority_paths)

api_priority_result, api_priority = api(
    {
        "op": "brief",
        "terms": "BRIEF_PRIORITY_FOCUS",
        "profile": "github-index",
        "focus_limit": 1,
        "max_tokens": tight_budget,
    }
)
assert api_priority_result.returncode == 0, api_priority
assert api_priority["ok"] is True and api_priority["recall_status"] == "complete"
assert api_priority["token_estimate"] <= api_priority["max_tokens"]

history_all_result = run_cli(
    "brief",
    "HISTORY",
    "SELF",
    "LOOP",
    "--profile",
    "github-index",
    "--json",
)
history_all = payload(history_all_result)
assert isinstance(history_all, dict)
assert history_all_result.returncode == 0, history_all
assert history_all["focus_scope"] == "all"
assert history_all["primary_focus"]["path"].startswith(".github/task-runs/blocked-self/")
assert history_all["primary_focus"]["kind"] in {"task-report", "task-run"}

history_scoped_result = run_cli(
    "brief",
    "HISTORY",
    "SELF",
    "LOOP",
    "--profile",
    "github-index",
    "--focus-scope",
    "non-history",
    "--json",
)
history_scoped = payload(history_scoped_result)
assert isinstance(history_scoped, dict)
assert history_scoped_result.returncode != 0, history_scoped
assert history_scoped["ok"] is False and history_scoped["recall_status"] == "failed"
assert history_scoped["focus_scope"] == "non-history"
assert history_scoped["primary_focus"] is None
assert history_scoped["focus_match_count"] == 0

api_history_scoped_result, api_history_scoped = api(
    {
        "op": "brief",
        "terms": "HISTORY SELF LOOP",
        "profile": "github-index",
        "focus_scope": "non-history",
    }
)
assert api_history_scoped_result.returncode != 0, api_history_scoped
assert api_history_scoped["ok"] is False
assert api_history_scoped["primary_focus"] is None

memory_scoped_result = run_cli(
    "brief",
    "CURRENT",
    "MEMORY",
    "FOCUS",
    "--profile",
    "github-index",
    "--focus-scope",
    "non-history",
    "--json",
)
memory_scoped = payload(memory_scoped_result)
assert isinstance(memory_scoped, dict)
assert memory_scoped_result.returncode == 0, memory_scoped
assert memory_scoped["primary_focus"]["path"] == ".github/memory/modules/brief-focus.md"
assert memory_scoped["primary_focus"]["index_status"] == "stored"

def assert_saturated_non_history_focus() -> None:
    result = run_cli(
        "brief",
        "SATURATED",
        "LIVE",
        "FOCUS",
        "--profile",
        "github-index",
        "--focus-scope",
        "non-history",
        "--json",
    )
    value = payload(result)
    assert isinstance(value, dict)
    assert result.returncode == 0, value
    assert value["primary_focus"]["path"] == ".github/z-current-focus.md", value
    assert value["primary_focus"]["kind"] == "markdown", value


assert_saturated_non_history_focus()
conn = sqlite3.connect(db)
original_fts = conn.execute("SELECT value FROM meta WHERE key='fts5'").fetchone()[0]
conn.execute("UPDATE meta SET value='0' WHERE key='fts5'")
conn.commit()
conn.close()
try:
    assert_saturated_non_history_focus()
    like_history_result = run_cli(
        "brief",
        "HISTORY",
        "SELF",
        "LOOP",
        "--profile",
        "github-index",
        "--focus-scope",
        "non-history",
        "--json",
    )
    like_history = payload(like_history_result)
    assert like_history_result.returncode != 0, like_history
    assert like_history["primary_focus"] is None
finally:
    conn = sqlite3.connect(db)
    conn.execute("UPDATE meta SET value=? WHERE key='fts5'", (original_fts,))
    conn.commit()
    conn.close()

default_priority_result = run_cli(
    "brief",
    "BRIEF_PRIORITY_FOCUS",
    "--profile",
    "github-index",
    "--focus-limit",
    "1",
    "--json",
)
default_priority = payload(default_priority_result)
assert isinstance(default_priority, dict)
assert default_priority_result.returncode == 0, default_priority
assert default_priority["ok"] is True and default_priority["recall_status"] == "complete"
assert default_priority["max_tokens"] == 2400

api_default_result, api_default = api(
    {
        "op": "brief",
        "terms": "BRIEF_PRIORITY_FOCUS",
        "profile": "github-index",
        "focus_limit": 1,
    }
)
assert api_default_result.returncode == 0, api_default
assert api_default["ok"] is True and api_default["recall_status"] == "complete"
assert api_default["max_tokens"] == 2400

priority_underflow_result = run_cli(
    "brief",
    "BRIEF_PRIORITY_FOCUS",
    "--profile",
    "github-index",
    "--focus-limit",
    "1",
    "--max-tokens",
    str(tight_budget - 1),
    "--json",
)
priority_underflow = payload(priority_underflow_result)
assert isinstance(priority_underflow, dict)
assert priority_underflow_result.returncode != 0, priority_underflow
assert priority_underflow["ok"] is False and priority_underflow["recall_status"] == "failed"
assert priority_underflow["primary_focus"]["path"] == ".github/memory/modules/brief-focus.md"
assert ".github/memory/modules/brief-focus.md#chunk-0001" in priority_underflow["omitted_by_budget"]
assert "primary focus exceeds remaining token budget" in priority_underflow["error"]

limit_result = run_cli(
    "brief",
    "FOCUS_LIMIT_MARKER",
    "--profile",
    "github-index",
    "--focus-limit",
    "2",
    "--max-tokens",
    "2000",
    "--json",
)
limited = payload(limit_result)
assert isinstance(limited, dict)
limited_focus_paths = [
    chunk["path"]
    for chunk in limited["chunks"]
    if chunk["path"].startswith(".github/instructions/focus-limit-")
]
assert focus_limit_matches >= 4
assert limit_result.returncode == 0, limited
assert limited["focus_limit"] == 2
assert limited["focus_match_count"] == 2
assert limited["focus_selected_count"] <= 2
assert len(limited_focus_paths) <= 2, limited_focus_paths
assert limited["token_estimate"] <= limited["max_tokens"]

no_focus_result = run_cli(
    "brief",
    "NO_INDEPENDENT_FOCUS_MATCH_7F31",
    "--profile",
    "github-index",
    "--max-tokens",
    "1200",
    "--json",
)
no_focus = payload(no_focus_result)
assert isinstance(no_focus, dict)
assert no_focus_result.returncode != 0
assert no_focus["ok"] is False and no_focus["recall_status"] == "failed"
assert no_focus["primary_focus"] is None
assert no_focus["focus_match_count"] == 0
assert "no independent primary focus match" in no_focus["error"]

api_no_focus_result, api_no_focus = api(
    {
        "op": "brief",
        "terms": "NO_INDEPENDENT_FOCUS_MATCH_7F31",
        "profile": "github-index",
        "max_tokens": 1200,
    }
)
assert api_no_focus_result.returncode != 0
assert api_no_focus["ok"] is False and api_no_focus["recall_status"] == "failed"
assert api_no_focus["primary_focus"] is None

profile_dedup_result = run_cli(
    "brief",
    "__BRIEF_PROFILE_REQUIRED__",
    "--profile",
    "github-index",
    "--max-tokens",
    "1200",
    "--json",
)
profile_dedup = payload(profile_dedup_result)
assert isinstance(profile_dedup, dict)
assert profile_dedup_matches >= 1
assert profile_dedup_result.returncode != 0
assert profile_dedup["ok"] is False and profile_dedup["recall_status"] == "failed"
assert profile_dedup["primary_focus"] is None
assert profile_dedup["focus_match_count"] == 0
assert "no independent primary focus match" in profile_dedup["error"]

missing_result = run_cli(
    "brief",
    "--profile",
    "missing-profile",
    "--max-tokens",
    "1000",
    "--json",
)
missing = payload(missing_result)
assert isinstance(missing, dict)
assert missing_result.returncode != 0
assert missing["ok"] is False and missing["recall_status"] == "failed"
assert ".github/e2e/profiles/missing-profile.tsv" in missing["required_missing_paths"]
assert missing["token_estimate"] <= missing["max_tokens"]

api_missing_result, api_missing = api(
    {
        "op": "brief",
        "profile": "missing-profile",
        "max_tokens": 1000,
    }
)
assert api_missing_result.returncode != 0
assert api_missing["ok"] is False and api_missing["recall_status"] == "failed"

oversize_brief_result = run_cli(
    "brief",
    "BRIEF_PRIORITY_FOCUS",
    "--profile",
    "github-index",
    "--focus-limit",
    "1",
    "--max-tokens",
    "50",
    "--json",
)
oversize_brief = payload(oversize_brief_result)
assert isinstance(oversize_brief, dict)
assert oversize_brief_result.returncode != 0
assert oversize_brief["ok"] is False and oversize_brief["recall_status"] == "failed"
assert oversize_brief["token_estimate"] <= oversize_brief["max_tokens"] == 50
assert "token budget" in oversize_brief["error"]

api_oversize_brief_result, api_oversize_brief = api(
    {
        "op": "brief",
        "terms": "BRIEF_PRIORITY_FOCUS",
        "profile": "github-index",
        "focus_limit": 1,
        "max_tokens": 50,
    }
)
assert api_oversize_brief_result.returncode != 0
assert api_oversize_brief["ok"] is False
assert api_oversize_brief["recall_status"] == "failed"
assert api_oversize_brief["token_estimate"] <= api_oversize_brief["max_tokens"] == 50

load_result = run_cli(
    "load",
    "LOAD_BUDGET_SHARED",
    "--source",
    "live",
    "--mode",
    "like",
    "--limit",
    "4",
    "--max-tokens",
    "200",
    "--json",
)
loaded = payload(load_result)
assert isinstance(loaded, list)
assert load_result.returncode == 0, load_result.stderr
assert [chunk["path"] for chunk in loaded] == [
    ".github/instructions/z-budget-small.instructions.md"
], loaded
assert sum(chunk["token_estimate"] for chunk in loaded) <= 200

api_load_result, api_loaded = api(
    {
        "op": "load",
        "terms": "LOAD_BUDGET_SHARED",
        "source": "live",
        "mode": "like",
        "limit": 4,
        "max_tokens": 200,
    }
)
assert api_load_result.returncode == 0, api_loaded
assert api_loaded["ok"] is True
assert [chunk["path"] for chunk in api_loaded["chunks"]] == [
    ".github/instructions/z-budget-small.instructions.md"
]
assert api_loaded["token_estimate"] <= api_loaded["max_tokens"] == 200

only_oversize_result = run_cli(
    "load",
    "LOAD_ONLY_OVERSIZE",
    "--source",
    "live",
    "--mode",
    "like",
    "--limit",
    "4",
    "--max-tokens",
    "200",
    "--json",
)
assert only_oversize_result.returncode != 0
assert "exceed max_tokens=200" in only_oversize_result.stderr

api_oversize_result, api_oversize = api(
    {
        "op": "load",
        "terms": "LOAD_ONLY_OVERSIZE",
        "source": "live",
        "mode": "like",
        "limit": 4,
        "max_tokens": 200,
    }
)
assert api_oversize_result.returncode != 0
assert api_oversize["ok"] is False
assert api_oversize["chunks"] == []
assert api_oversize["token_estimate"] == 0
assert api_oversize["max_tokens"] == 200

print(
    "PASS strict brief/load recall contract "
    f"tight_budget={tight_budget} focus_limit_matches={focus_limit_matches}"
)
PY
  then
    printf 'PASS github-index enforces canonical/profile/focus priority and fail-closed budgets\n'
  else
    printf 'FAIL github-index strict brief/load recall contract drifted\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" archive-markdown \
    .github/task-runs/blocked-self \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" archive-markdown \
    .github/task-runs/history-saturation \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  local brief_out brief_api_out
  brief_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" brief BRIEF_PRIORITY_FOCUS \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --profile github-index \
      --max-tokens 1200
  ) || rc=1
  printf '%s\n' "$brief_out"
  brief_api_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" api \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --request '{"op":"brief","terms":"BRIEF_PRIORITY_FOCUS","profile":"github-index","max_tokens":1200}'
  ) || rc=1
  printf '%s\n' "$brief_api_out"
  if grep -Fq -- '# Agent Brief' <<< "$brief_out" &&
     grep -Fq -- '- `recall_status`: complete' <<< "$brief_out" &&
     grep -Fq -- 'updated in stored db' <<< "$brief_out" &&
     grep -Fq -- '"op": "brief"' <<< "$brief_api_out" &&
     grep -Fq -- '"ok": true' <<< "$brief_api_out" &&
     grep -Fq -- '"recall_status": "complete"' <<< "$brief_api_out"; then
    printf 'PASS github-index brief returns live-or-stored startup context for agents\n'
  else
    printf 'FAIL github-index brief did not return expected startup context\n'
    rc=1
  fi
  local suggest_out
  suggest_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" brief ubuntu full \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --max-tokens 700 \
      --json
  ) || rc=1
  printf '%s\n' "$suggest_out"
  if grep -Fq -- '"profile_suggestions":' <<< "$suggest_out" &&
     grep -Fq -- '"profile": "nemu-ubuntu-full-gate"' <<< "$suggest_out"; then
    printf 'PASS github-index brief recommends matching e2e profile\n'
  else
    printf 'FAIL github-index brief did not recommend expected e2e profile\n'
    rc=1
  fi
  local profiles_out profiles_api_out
  profiles_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" profiles ubuntu full \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --include-nodes \
      --json
  ) || rc=1
  printf '%s\n' "$profiles_out"
  profiles_api_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" api \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --request '{"op":"profiles","terms":"ubuntu full","include_nodes":true,"limit":4}'
  ) || rc=1
  printf '%s\n' "$profiles_api_out"
  if grep -Fq -- '"op": "profiles"' <<< "$profiles_out" &&
     grep -Fq -- '"profile": "nemu-ubuntu-full-gate"' <<< "$profiles_out" &&
     grep -Fq -- '"node_count": 1' <<< "$profiles_out" &&
     grep -Fq -- '"nodes":' <<< "$profiles_out" &&
     grep -Fq -- '"op": "profiles"' <<< "$profiles_api_out" &&
     grep -Fq -- '"profile": "nemu-ubuntu-full-gate"' <<< "$profiles_api_out"; then
    printf 'PASS github-index profiles catalog lists matching e2e profile\n'
  else
    printf 'FAIL github-index profiles catalog did not list expected e2e profile\n'
    rc=1
  fi
  local resolved_out resolved_api_out
  resolved_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" resolve-profile nemu-ubuntu-full-gate \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --json
  ) || rc=1
  printf '%s\n' "$resolved_out"
  resolved_api_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" api \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --request '{"op":"resolve-profile","profile":"nemu-ubuntu-full-gate","include_nodes":true}'
  ) || rc=1
  printf '%s\n' "$resolved_api_out"
  if grep -Fq -- '"op": "resolve-profile"' <<< "$resolved_out" &&
     grep -Fq -- '"ok": true' <<< "$resolved_out" &&
     grep -Fq -- '"expanded_node_count": 2' <<< "$resolved_out" &&
     grep -Fq -- '"to": "base-gate"' <<< "$resolved_out" &&
     grep -Fq -- '"source_profile": "base-gate"' <<< "$resolved_out" &&
     grep -Fq -- '"source_profile": "nemu-ubuntu-full-gate"' <<< "$resolved_out" &&
     grep -Fq -- '"op": "resolve-profile"' <<< "$resolved_api_out" &&
     grep -Fq -- '"expanded_node_count": 2' <<< "$resolved_api_out"; then
    printf 'PASS github-index resolve-profile expands e2e include closure\n'
  else
    printf 'FAIL github-index resolve-profile did not expand expected include closure\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" snapshot-stored \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/snapshot \
    --yes || rc=1
  rm -f "$mini_db"
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" rehydrate \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/snapshot \
    --yes || rc=1
  local rehydrate_out
  rehydrate_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --source stored \
      --path .github/memory/project-status.md \
      --limit 1 \
      --max-tokens 200
  ) || rc=1
  printf '%s\n' "$rehydrate_out"
  if grep -Fq -- 'updated in stored db' <<< "$rehydrate_out"; then
    printf 'PASS github-index rehydrate restores current stored content after DB loss\n'
  else
    printf 'FAIL github-index rehydrate did not restore current stored content\n'
    rc=1
  fi
  mkdir -p "$mini_repo/.github/task-runs/demo/evidence"
  cat > "$mini_repo/.github/task-runs/demo/dispatch-log.md" <<'EOF'
# 派发日志

## 基本信息

- `task_id`: demo
- `task_slug`: demo-run
- `graph_template`: modular-agent-e2e
- `profile`: github-index
EOF
  cat > "$mini_repo/.github/task-runs/demo/task-report.md" <<'EOF'
# 任务报告

## 基本信息

- `task_id`: demo
- `task_slug`: demo-run
- `graph_template`: modular-agent-e2e
- `profile`: github-index
- `graph_mode`: static
- `status`: blocked
- `started_at`: 2026-06-12 00:00:00 +0800
- `updated_at`: 2026-06-12 00:00:02 +0800

## 关键产物

- `context_brief`: .github/task-runs/demo/context-brief.md
- `profile_resolve`: .github/task-runs/demo/profile-resolve.md

## 收尾结论

- `final_result`: demo run completed
EOF
  cat > "$mini_repo/.github/task-runs/demo/context-brief.md" <<'EOF'
# Agent Brief

demo context brief source
EOF
  cat > "$mini_repo/.github/task-runs/demo/profile-resolve.md" <<'EOF'
# E2E Resolved Profile

- `source`: stored
- `profile`: github-index
- `ok`: True
- `expanded_node_count`: 1
- `profile_order`: github-index
EOF
  cat > "$mini_repo/.github/task-runs/demo/evidence/note.md" <<'EOF'
# Evidence Note

demo markdown evidence source
__DEMO_MARKDOWN_MARKER__
EOF
  cat > "$mini_repo/.github/task-runs/demo/evidence/demo.log" <<'EOF'
PASS demo raw evidence
__DEMO_MARKER__
WARN demo bounded summary
EOF
  cat > "$mini_repo/.github/task-runs/demo/evidence/demo.cmd" <<'EOF'
echo demo command
EOF
  local evidence_index_out
  evidence_index_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence .github/task-runs/demo \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --write-index \
      --yes \
      --json
  ) || rc=1
  printf '%s\n' "$evidence_index_out"
  if grep -Fq -- '"op": "index-evidence"' <<< "$evidence_index_out" &&
     grep -Fq -- '"assets": 3' <<< "$evidence_index_out" &&
     grep -Fq -- '.github/task-runs/demo/evidence-index.md' <<< "$evidence_index_out" &&
     grep -Fq -- '"stored_index_docs": [' <<< "$evidence_index_out" &&
     e2e_github_index_backup_entry_valid \
       "$mini_repo/.github/db-backup/stored-snapshot" \
       .github/task-runs/demo/evidence-index.md \
       "$mini_repo/.github/task-runs/demo/evidence-index.md" &&
     grep -Fq -- '.github/task-runs/demo/evidence/note.md' "$mini_repo/.github/task-runs/demo/evidence-index.md" &&
     grep -Fq -- '__DEMO_MARKDOWN_MARKER__' "$mini_repo/.github/task-runs/demo/evidence-index.md"; then
    printf 'PASS github-index indexes raw evidence assets and stores generated evidence-index docs\n'
  else
    printf 'FAIL github-index raw evidence asset index did not produce stored evidence-index summary\n'
    rc=1
  fi

  mkdir -p "$mini_repo/.github/task-runs/trace-demo/evidence"
  cat > "$mini_repo/.github/task-runs/trace-demo/task-report.md" <<'EOF'
# 任务报告

- `task_id`: trace-demo
- `task_slug`: trace-demo
- `profile`: github-index
- `status`: completed
EOF
  printf 'PASS trace demo evidence\n' \
    > "$mini_repo/.github/task-runs/trace-demo/evidence/trace.log"
  cat > "$mini_repo/.github/task-runs/trace-demo/run-manifest.json" <<'EOF'
{
  "schema_version": 1,
  "trace_id": "e2e:trace-demo",
  "run_id": "trace-demo",
  "task_slug": "trace-demo",
  "profile": "github-index",
  "status": "completed",
  "git": {},
  "artifacts": {
    "task_report": ".github/task-runs/trace-demo/task-report.md",
    "evidence_dir": ".github/task-runs/trace-demo/evidence",
    "run_manifest": ".github/task-runs/trace-demo/run-manifest.json"
  },
  "node_counts": {
    "total": 1
  },
  "evidence": {
    "asset_count": 1,
    "total_size_bytes": 25
  },
  "db": {
    "markdown_archive": true,
    "raw_evidence_index_only": true
  }
}
EOF
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence \
    .github/task-runs/trace-demo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --write-index \
    --yes >/dev/null || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence \
    .github/task-runs/trace-demo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --write-index \
    --yes >/dev/null || rc=1
  if python3 - "$E2E_ROOT_DIR" "$mini_repo" "$mini_db" <<'PY'
import json
import sys
from pathlib import Path

source_root = Path(sys.argv[1]).resolve()
repo_root = Path(sys.argv[2]).resolve()
db_path = Path(sys.argv[3]).resolve()
sys.path.insert(0, str(source_root))

from scripts.dev_memory.core import open_db
from scripts.dev_memory.maintenance import (
    validate_run_manifest_payload,
    validate_runtime_artifact_run,
)

run_id = "trace-demo"
manifest_path = repo_root / ".github/task-runs/trace-demo/run-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
conn = open_db(db_path, readonly=True)
try:
    rows = conn.execute(
        "SELECT path, kind FROM evidence_assets WHERE run_id = ? ORDER BY path",
        (run_id,),
    ).fetchall()
    _result, trace_errors = validate_run_manifest_payload(
        repo_root,
        conn,
        run_id,
        manifest,
        manifest_path,
    )
    _artifact_result, artifact_errors = validate_runtime_artifact_run(
        repo_root,
        conn,
        run_id,
        manifest,
    )
finally:
    conn.close()

paths = [(row["path"], row["kind"]) for row in rows]
expected_manifest = ".github/task-runs/trace-demo/run-manifest.json"
index_text = (repo_root / ".github/task-runs/trace-demo/evidence-index.md").read_text(
    encoding="utf-8"
)
ok = (
    not trace_errors
    and not artifact_errors
    and len(paths) == 2
    and (expected_manifest, "json") in paths
    and "- `asset_count`: 1" in index_text
    and f"- `total_size_bytes`: {(repo_root / '.github/task-runs/trace-demo/evidence/trace.log').stat().st_size}" in index_text
    and "- `kind`: json" not in index_text
    and expected_manifest not in index_text
)
raise SystemExit(0 if ok else 1)
PY
  then
    printf 'PASS github-index binds run manifest in DB while ordinary evidence index excludes pointers\n'
  else
    printf 'FAIL github-index run-manifest trace binding diverges from ordinary evidence index\n'
    rc=1
  fi

  cp "$mini_repo/.github/task-runs/trace-demo/run-manifest.json" \
    "$tmp_dir/trace-demo-manifest-original.json"
  python3 - "$mini_repo/.github/task-runs/trace-demo/run-manifest.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
payload["revision_probe"] = 1
path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
  cp "$mini_repo/.github/task-runs/trace-demo/run-manifest.json" \
    "$tmp_dir/trace-demo-manifest-updated.json"
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence \
    .github/task-runs/trace-demo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --write-index \
    --yes >/dev/null || rc=1
  if python3 - \
      "$mini_repo" \
      "$mini_db" \
      "$tmp_dir/trace-demo-manifest-original.json" \
      "$tmp_dir/trace-demo-manifest-updated.json" <<'PY'
import hashlib
import sqlite3
import sys
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
db_path = Path(sys.argv[2]).resolve()
original = Path(sys.argv[3]).read_bytes()
updated = Path(sys.argv[4]).read_bytes()
live = (repo_root / ".github/task-runs/trace-demo/run-manifest.json").read_bytes()
conn = sqlite3.connect(db_path)
try:
    row = conn.execute(
        "SELECT sha256, size_bytes FROM evidence_assets WHERE path = ?",
        (".github/task-runs/trace-demo/run-manifest.json",),
    ).fetchone()
finally:
    conn.close()
ok = (
    row is not None
    and original != updated == live
    and row[0] == hashlib.sha256(live).hexdigest()
    and row[1] == len(live)
)
raise SystemExit(0 if ok else 1)
PY
  then
    printf 'PASS github-index refreshes final run-manifest metadata without duplicate rows\n'
  else
    printf 'FAIL github-index retained stale or duplicate run-manifest metadata\n'
    rc=1
  fi

  python3 - "$mini_repo" <<'PY'
import json
import sys
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
run_id = "trace-peer"
run_root = repo_root / ".github/task-runs" / run_id
(run_root / "evidence").mkdir(parents=True)
(run_root / "task-report.md").write_text(
    "# 任务报告\n\n"
    "- `task_id`: trace-peer\n"
    "- `task_slug`: trace-peer\n"
    "- `profile`: github-index\n"
    "- `status`: completed\n",
    encoding="utf-8",
)
(run_root / "evidence/trace.log").write_text("PASS trace peer evidence\n", encoding="utf-8")
manifest = {
    "schema_version": 1,
    "trace_id": "e2e:trace-peer",
    "run_id": "trace-peer",
    "task_slug": "trace-peer",
    "profile": "github-index",
    "status": "completed",
    "git": {},
    "artifacts": {
        "task_report": ".github/task-runs/trace-peer/task-report.md",
        "evidence_dir": ".github/task-runs/trace-peer/evidence",
        "run_manifest": ".github/task-runs/trace-peer/run-manifest.json",
    },
    "node_counts": {"total": 1},
    "evidence": {"asset_count": 1, "total_size_bytes": 25},
    "db": {"markdown_archive": True, "raw_evidence_index_only": True},
}
(run_root / "run-manifest.json").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence \
    .github/task-runs/trace-peer \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --write-index \
    --yes >/dev/null || rc=1
  rm -f "$mini_repo/.github/task-runs/trace-demo/run-manifest.json"
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence \
    .github/task-runs/trace-demo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --write-index \
    --yes >/dev/null || rc=1
  if python3 - "$mini_db" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
try:
    demo = conn.execute(
        "SELECT path FROM evidence_assets WHERE run_id = ? ORDER BY path",
        ("trace-demo",),
    ).fetchall()
    peer = conn.execute(
        "SELECT path FROM evidence_assets WHERE run_id = ? ORDER BY path",
        ("trace-peer",),
    ).fetchall()
finally:
    conn.close()
demo_paths = [row[0] for row in demo]
peer_paths = [row[0] for row in peer]
ok = (
    demo_paths == [".github/task-runs/trace-demo/evidence/trace.log"]
    and len(peer_paths) == 2
    and ".github/task-runs/trace-peer/run-manifest.json" in peer_paths
)
raise SystemExit(0 if ok else 1)
PY
  then
    printf 'PASS github-index removes stale manifest rows without crossing run boundaries\n'
  else
    printf 'FAIL github-index manifest cleanup leaked stale or cross-run rows\n'
    rc=1
  fi
  cp "$tmp_dir/trace-demo-manifest-original.json" \
    "$mini_repo/.github/task-runs/trace-demo/run-manifest.json"
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence \
    .github/task-runs/trace-demo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --write-index \
    --yes >/dev/null || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" archive-markdown \
    .github/task-runs/trace-demo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --yes >/dev/null || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" archive-markdown \
    .github/task-runs/trace-peer \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --yes >/dev/null || rc=1

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" rebuild \
    --repo-root "$mini_repo" \
    --db "$mini_db" || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" archive-markdown .github/task-runs/demo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  if grep -Fq -- 'demo run completed' "$mini_repo/.github/task-runs/demo/task-report.md" &&
     ! grep -Fq -- 'DB-backed .github/task-runs/demo/task-report.md' "$mini_repo/.github/task-runs/demo/task-report.md" &&
     e2e_github_index_backup_entry_valid \
       "$mini_repo/.github/db-backup/test" \
       .github/task-runs/demo/task-report.md \
       "$mini_repo/.github/task-runs/demo/task-report.md"; then
    printf 'PASS github-index archives task-run Markdown to DB while keeping live file and backup\n'
  else
    printf 'FAIL github-index archive-markdown did not preserve live task-run Markdown\n'
    rc=1
  fi
  if python3 - "$mini_db" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
pattern = ".github/task-runs/%/evidence/%"
asset = conn.execute(
    "SELECT COUNT(*) FROM evidence_assets WHERE path = ?",
    (".github/task-runs/demo/evidence/note.md",),
).fetchone()[0]
file_text = conn.execute(
    "SELECT COUNT(*) FROM file_text WHERE path LIKE ?",
    (pattern,),
).fetchone()[0]
documents = conn.execute(
    "SELECT COUNT(*) FROM db_documents WHERE path LIKE ?",
    (pattern,),
).fetchone()[0]
conn.close()
raise SystemExit(0 if (asset, file_text, documents) == (1, 0, 0) else 1)
PY
  then
    printf 'PASS github-index keeps raw Markdown evidence in evidence_assets only\n'
  else
    printf 'FAIL github-index leaked raw Markdown evidence into a full-text document table\n'
    rc=1
  fi
  local runtime_neighbor runtime_run runtime_index_out runtime_updated_at
  runtime_run="$mini_repo/.github/runtime-artifacts/runtime_demo"
  runtime_neighbor="$mini_repo/.github/runtime-artifacts/runtimeXdemo"
  runtime_updated_at='2026-06-12 00:00:04 +0800'
  mkdir -p "$runtime_run/evidence"
  cat > "$runtime_run/nodes.tsv" <<'EOF'
runtime-node	agent-system	github-index	PASS	input	output	evidence
EOF
  cat > "$runtime_run/task-report.md" <<'EOF'
# Runtime Task Report

- `task_slug`: runtime_demo
- `profile`: github-index
- `status`: completed
- `updated_at`: 2026-06-12 00:00:04 +0800
EOF
  cat > "$runtime_run/evidence/note.md" <<'EOF'
# Runtime Markdown Evidence

__RUNTIME_MD_MARKER__
EOF
  cat > "$runtime_run/evidence/runtime.log" <<'EOF'
PASS runtime bounded evidence
EOF
  (
    E2E_ROOT_DIR="$mini_repo"
    E2E_RUN_DIR="$runtime_run"
    E2E_PROFILE=github-index
    E2E_TASK_SLUG=runtime_demo
    E2E_STARTED_AT='2026-06-12 00:00:03 +0800'
    e2e_render_run_manifest completed PASS "$runtime_updated_at"
  )
  if python3 - "$runtime_run/run-manifest.json" <<'PY'
import json
import sys

manifest = json.load(open(sys.argv[1], encoding="utf-8"))
evidence = manifest["evidence"]
expected_kinds = {"log": 1, "md": 1}
raise SystemExit(
    0
    if evidence["asset_count"] == 2
    and evidence["by_kind"] == expected_kinds
    else 1
)
PY
  then
    printf 'PASS github-index run manifest counts only raw evidence subtree assets\n'
  else
    printf 'FAIL github-index run manifest mixed task-run pointers with raw evidence assets\n'
    rc=1
  fi
  mkdir -p "$runtime_neighbor/evidence"
  cat > "$runtime_neighbor/evidence/neighbor.log" <<'EOF'
PASS adjacent runtime evidence must survive
EOF
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence \
    .github/runtime-artifacts/runtimeXdemo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --yes >/dev/null || rc=1
  runtime_index_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" index-evidence \
      .github/runtime-artifacts/runtime_demo \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --write-index \
      --yes \
      --json
  ) || rc=1
  printf '%s\n' "$runtime_index_out"
  if grep -Fq -- '"assets": 2' <<< "$runtime_index_out" &&
     grep -Fq -- '"runtime_demo"' <<< "$runtime_index_out" &&
     grep -Fq -- '.github/runtime-artifacts/runtime_demo/evidence-index.md' <<< "$runtime_index_out" &&
     grep -Fq -- '__RUNTIME_MD_MARKER__' "$runtime_run/evidence-index.md" &&
     python3 - "$mini_db" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
current_paths = {
    row[0]
    for row in conn.execute(
        "SELECT path FROM evidence_assets WHERE run_id = ?",
        ("runtime_demo",),
    )
}
neighbor_paths = {
    row[0]
    for row in conn.execute(
        "SELECT path FROM evidence_assets WHERE run_id = ?",
        ("runtimeXdemo",),
    )
}
conn.close()
expected = {
    ".github/runtime-artifacts/runtime_demo/evidence/note.md",
    ".github/runtime-artifacts/runtime_demo/evidence/runtime.log",
}
expected_neighbor = {
    ".github/runtime-artifacts/runtimeXdemo/evidence/neighbor.log",
}
raise SystemExit(
    0
    if current_paths == expected and neighbor_paths == expected_neighbor
    else 1
)
PY
  then
    printf 'PASS github-index isolates adjacent runtime roots during bounded asset cleanup\n'
  else
    printf 'FAIL github-index crossed runtime-root boundaries during asset cleanup\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --source stored \
    --path .github/task-runs/demo/task-report.md \
    --limit 1 \
    --max-tokens 200 || rc=1
  local runs_out runs_api_out
  runs_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" runs \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --profile github-index \
      --json
  ) || rc=1
  printf '%s\n' "$runs_out"
  runs_api_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" api \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --request '{"op":"runs","profile":"github-index","limit":4}'
  ) || rc=1
  printf '%s\n' "$runs_api_out"
  if grep -Fq -- '"op": "runs"' <<< "$runs_out" &&
     grep -Fq -- '"run_id": "demo"' <<< "$runs_out" &&
     grep -Fq -- '"profile": "github-index"' <<< "$runs_out" &&
     grep -Fq -- '"status": "blocked"' <<< "$runs_out" &&
     grep -Fq -- '"profile_resolve_path": ".github/task-runs/demo/profile-resolve.md"' <<< "$runs_out" &&
     grep -Fq -- '"evidence_index_path": ".github/task-runs/demo/evidence-index.md"' <<< "$runs_out" &&
     grep -Fq -- '"evidence_asset_count": 3' <<< "$runs_out" &&
     grep -Fq -- '"expanded_node_count": 1' <<< "$runs_out" &&
     grep -Fq -- '"op": "runs"' <<< "$runs_api_out" &&
     grep -Fq -- '"run_id": "demo"' <<< "$runs_api_out"; then
    printf 'PASS github-index runs catalog lists archived task-run evidence\n'
  else
    printf 'FAIL github-index runs catalog did not list expected archived task-run\n'
    rc=1
  fi
  local evidence_out evidence_api_out
  evidence_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" evidence DEMO_MARKER \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --run-id demo \
      --json
  ) || rc=1
  printf '%s\n' "$evidence_out"
  evidence_api_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" api \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --request '{"op":"evidence","run_id":"demo","terms":"DEMO_MARKER","limit":4}'
  ) || rc=1
  printf '%s\n' "$evidence_api_out"
  if grep -Fq -- '"op": "evidence"' <<< "$evidence_out" &&
     grep -Fq -- '"path": ".github/task-runs/demo/evidence/demo.log"' <<< "$evidence_out" &&
     grep -Fq -- '"DEMO_MARKER"' <<< "$evidence_out" &&
     grep -Fq -- '"op": "evidence"' <<< "$evidence_api_out" &&
     grep -Fq -- '"size_bytes":' <<< "$evidence_api_out"; then
    printf 'PASS github-index evidence query returns structured raw log summaries\n'
  else
    printf 'FAIL github-index evidence query did not return expected raw log summary\n'
    rc=1
  fi
  rm -f "$mini_repo/.github/task-runs/demo/task-report.md"
  printf '\nlocal historical task-run drift\n' >> "$mini_repo/.github/task-runs/demo/context-brief.md"
  local doctor_archived_out
  if doctor_archived_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" doctor \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --fail-on-drift
  ); then
    printf '%s\n' "$doctor_archived_out"
    if grep -Fq -- 'blocking_drift=0' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'diagnostic_only=' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'historical_archive_diagnostics=' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'live_index_cache_diagnostics=' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'hidden_historical_drift=' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'historical_drift_details=hidden' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'historical_archive_missing=' <<< "$doctor_archived_out" &&
       ! grep -Fq -- '.github/task-runs/demo/task-report.md' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'historical_archive_stale=' <<< "$doctor_archived_out" &&
       ! grep -Fq -- '.github/task-runs/demo/context-brief.md' <<< "$doctor_archived_out"; then
      printf 'PASS github-index doctor hides historical task-run drift in default output\n'
    else
      printf 'FAIL github-index doctor default output leaked historical task-run drift details\n'
      rc=1
    fi
  else
    printf '%s\n' "$doctor_archived_out"
    printf 'FAIL github-index doctor rejected historical task-run missing/stale drift\n'
    rc=1
  fi
  local doctor_archived_verbose_out
  if doctor_archived_verbose_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" doctor \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --fail-on-drift \
      --show-nonblocking-drift
  ); then
    printf '%s\n' "$doctor_archived_verbose_out"
    if grep -Fq -- 'blocking_drift=0' <<< "$doctor_archived_verbose_out" &&
       grep -Fq -- 'historical_archive_diagnostics=2' <<< "$doctor_archived_verbose_out" &&
       grep -Fq -- 'live_index_cache_diagnostics=0' <<< "$doctor_archived_verbose_out" &&
       grep -Fq -- 'diagnostic_only=2' <<< "$doctor_archived_verbose_out" &&
       grep -Fq -- 'diagnostic_only_note=ignored_by_fail_on_drift' <<< "$doctor_archived_verbose_out" &&
       ! grep -Fq -- 'historical_archive_missing=' <<< "$doctor_archived_verbose_out" &&
       ! grep -Fq -- '.github/task-runs/demo/task-report.md' <<< "$doctor_archived_verbose_out" &&
       ! grep -Fq -- 'historical_archive_stale=' <<< "$doctor_archived_verbose_out" &&
       ! grep -Fq -- '.github/task-runs/demo/context-brief.md' <<< "$doctor_archived_verbose_out"; then
      printf 'PASS github-index doctor summarizes historical task-run diagnostics without path noise\n'
    else
      printf 'FAIL github-index doctor verbose non-blocking summary leaked path noise\n'
      rc=1
    fi
  else
    printf '%s\n' "$doctor_archived_verbose_out"
    printf 'FAIL github-index doctor verbose rejected historical task-run missing/stale drift\n'
    rc=1
  fi
  local doctor_archived_details_out
  if doctor_archived_details_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" doctor \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --fail-on-drift \
      --show-diagnostic-details
  ); then
    printf '%s\n' "$doctor_archived_details_out"
    if grep -Fq -- 'blocking_drift=0' <<< "$doctor_archived_details_out" &&
       grep -Fq -- 'historical_archive_diagnostics=2' <<< "$doctor_archived_details_out" &&
       grep -Fq -- 'live_index_cache_diagnostics=0' <<< "$doctor_archived_details_out" &&
       grep -Fq -- 'diagnostic_only=2' <<< "$doctor_archived_details_out" &&
       grep -Fq -- 'diagnostic_only_note=ignored_by_fail_on_drift' <<< "$doctor_archived_details_out" &&
       grep -Fq -- 'historical_archive_missing=' <<< "$doctor_archived_details_out" &&
       grep -Fq -- '.github/task-runs/demo/task-report.md' <<< "$doctor_archived_details_out" &&
       grep -Fq -- 'historical_archive_stale=' <<< "$doctor_archived_details_out" &&
       grep -Fq -- '.github/task-runs/demo/context-brief.md' <<< "$doctor_archived_details_out"; then
      printf 'PASS github-index doctor diagnostic details explicitly show historical task-run drift paths\n'
    else
      printf 'FAIL github-index doctor diagnostic details did not show actionable historical paths\n'
      rc=1
    fi
  else
    printf '%s\n' "$doctor_archived_details_out"
    printf 'FAIL github-index doctor diagnostic details rejected historical task-run missing/stale drift\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" refresh AGENTS.md \
    --repo-root "$mini_repo" \
    --db "$mini_db" || rc=1
  python3 -c 'import os, sys, time; ts = time.time() + 5; os.utime(sys.argv[1], (ts, ts))' "$mini_repo/AGENTS.md" || rc=1
  local doctor_shim_mtime_out
  if doctor_shim_mtime_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" doctor \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --fail-on-drift \
      --show-nonblocking-drift
  ); then
    printf '%s\n' "$doctor_shim_mtime_out"
    if grep -Fq -- 'blocking_drift=0' <<< "$doctor_shim_mtime_out" &&
       grep -Fq -- 'historical_archive_diagnostics=2' <<< "$doctor_shim_mtime_out" &&
       grep -Fq -- 'live_index_cache_diagnostics=0' <<< "$doctor_shim_mtime_out" &&
       grep -Fq -- 'diagnostic_only=2' <<< "$doctor_shim_mtime_out" &&
       ! grep -Fq -- 'live_index_cache_stale=' <<< "$doctor_shim_mtime_out" &&
       ! grep -Fq -- 'AGENTS.md' <<< "$doctor_shim_mtime_out"; then
      printf 'PASS github-index doctor ignores indexed shim mtime-only cache drift\n'
    else
      printf 'FAIL github-index doctor reported indexed shim mtime-only cache drift\n'
      rc=1
    fi
  else
    printf '%s\n' "$doctor_shim_mtime_out"
    printf 'FAIL github-index doctor rejected indexed shim mtime-only cache drift\n'
    rc=1
  fi
  printf '\nlocal old agent shim stale drift\n' >> "$mini_repo/AGENTS.md"
  local doctor_shim_default_out
  if doctor_shim_default_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" doctor \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --fail-on-drift
  ); then
    printf '%s\n' "$doctor_shim_default_out"
    if grep -Fq -- 'blocking_drift=0' <<< "$doctor_shim_default_out" &&
       ! grep -Fq -- 'diagnostic_drift=' <<< "$doctor_shim_default_out" &&
       ! grep -Fq -- 'diagnostic_only=' <<< "$doctor_shim_default_out" &&
       ! grep -Fq -- 'historical_archive_diagnostics=' <<< "$doctor_shim_default_out" &&
       ! grep -Fq -- 'live_index_cache_diagnostics=' <<< "$doctor_shim_default_out" &&
       ! grep -Fq -- 'live_index_cache_stale=' <<< "$doctor_shim_default_out" &&
       ! grep -Fq -- 'AGENTS.md' <<< "$doctor_shim_default_out"; then
      printf 'PASS github-index doctor hides old agent shim stale drift in default output\n'
    else
      printf 'FAIL github-index doctor default output leaked old agent shim stale drift\n'
      rc=1
    fi
  else
    printf '%s\n' "$doctor_shim_default_out"
    printf 'FAIL github-index doctor rejected old agent shim stale drift\n'
    rc=1
  fi
  local doctor_shim_verbose_out
  if doctor_shim_verbose_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" doctor \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --fail-on-drift \
      --show-nonblocking-drift
  ); then
    printf '%s\n' "$doctor_shim_verbose_out"
    if grep -Fq -- 'blocking_drift=0' <<< "$doctor_shim_verbose_out" &&
       grep -Fq -- 'historical_archive_diagnostics=2' <<< "$doctor_shim_verbose_out" &&
       grep -Fq -- 'live_index_cache_diagnostics=1' <<< "$doctor_shim_verbose_out" &&
       grep -Fq -- 'diagnostic_only=3' <<< "$doctor_shim_verbose_out" &&
       grep -Fq -- 'diagnostic_only_note=ignored_by_fail_on_drift' <<< "$doctor_shim_verbose_out" &&
       ! grep -Fq -- 'live_index_cache_stale=' <<< "$doctor_shim_verbose_out" &&
       ! grep -Fq -- 'AGENTS.md' <<< "$doctor_shim_verbose_out"; then
      printf 'PASS github-index doctor summarizes old agent shim stale diagnostics without path noise\n'
    else
      printf 'FAIL github-index doctor verbose old agent shim summary leaked path noise\n'
      rc=1
    fi
  else
    printf '%s\n' "$doctor_shim_verbose_out"
    printf 'FAIL github-index doctor verbose rejected old agent shim stale drift\n'
    rc=1
  fi
  local doctor_shim_details_out
  if doctor_shim_details_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" doctor \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --fail-on-drift \
      --show-diagnostic-details
  ); then
    printf '%s\n' "$doctor_shim_details_out"
    if grep -Fq -- 'blocking_drift=0' <<< "$doctor_shim_details_out" &&
       grep -Fq -- 'historical_archive_diagnostics=2' <<< "$doctor_shim_details_out" &&
       grep -Fq -- 'live_index_cache_diagnostics=1' <<< "$doctor_shim_details_out" &&
       grep -Fq -- 'diagnostic_only=3' <<< "$doctor_shim_details_out" &&
       grep -Fq -- 'diagnostic_only_note=ignored_by_fail_on_drift' <<< "$doctor_shim_details_out" &&
       grep -Fq -- 'live_index_cache_stale=' <<< "$doctor_shim_details_out" &&
       grep -Fq -- 'AGENTS.md' <<< "$doctor_shim_details_out"; then
      printf 'PASS github-index doctor diagnostic details explicitly show old agent shim stale path\n'
    else
      printf 'FAIL github-index doctor diagnostic details old agent shim output was not actionable\n'
      rc=1
    fi
  else
    printf '%s\n' "$doctor_shim_details_out"
    printf 'FAIL github-index doctor diagnostic details rejected old agent shim stale drift\n'
    rc=1
  fi
  local doctor_readonly_lock_out
  doctor_readonly_lock_out=$(
    python3 - "$E2E_ROOT_DIR" "$mini_repo" "$mini_db" <<'PY'
import sqlite3
import subprocess
import sys
from pathlib import Path

e2e_root = Path(sys.argv[1])
mini_repo = Path(sys.argv[2])
mini_db = Path(sys.argv[3])

conn = sqlite3.connect(str(mini_db), timeout=30)
conn.execute("BEGIN IMMEDIATE")
try:
    result = subprocess.run(
        [
            sys.executable,
            str(e2e_root / "scripts/github_index_db.py"),
            "doctor",
            "--repo-root",
            str(mini_repo),
            "--db",
            str(mini_db),
            "--fail-on-drift",
        ],
        cwd=mini_repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=10,
    )
    print(f"rc={result.returncode}")
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print("stderr=" + result.stderr.strip())
    raise SystemExit(result.returncode)
finally:
    conn.rollback()
    conn.close()
PY
  ) || rc=1
  printf '%s\n' "$doctor_readonly_lock_out"
  if grep -Fq -- 'rc=0' <<< "$doctor_readonly_lock_out" &&
     grep -Fq -- 'blocking_drift=0' <<< "$doctor_readonly_lock_out" &&
     ! grep -Fq -- 'db_status=locked' <<< "$doctor_readonly_lock_out" &&
     ! grep -Fq -- 'db_error=database is locked' <<< "$doctor_readonly_lock_out"; then
    printf 'PASS github-index doctor default read path avoids WAL write lock\n'
  else
    printf 'FAIL github-index doctor default path was blocked by DB write lock\n'
    rc=1
  fi
  local audit_archived_out
  audit_archived_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" audit-db-first \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --backup-dir .github/db-backup/test \
      --json
  ) || rc=1
  printf '%s\n' "$audit_archived_out"
  if grep -Fq -- '"ok": true' <<< "$audit_archived_out" &&
     grep -Fq -- '"archived_stored_only": [' <<< "$audit_archived_out" &&
     grep -Fq -- '.github/task-runs/demo/task-report.md' <<< "$audit_archived_out"; then
    printf 'PASS github-index audit treats stored-only historical task-run logs as archived evidence\n'
  else
    printf 'FAIL github-index audit rejected stored-only historical task-run logs\n'
    rc=1
  fi
  local audit_archived_default_out
  if audit_archived_default_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" audit-db-first \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --backup-dir .github/db-backup/test
  ); then
    printf '%s\n' "$audit_archived_default_out"
    if ! grep -Fq -- 'nonblocking_archived_stored_only=' <<< "$audit_archived_default_out" &&
       ! grep -Fq -- 'nonblocking_live_drift=' <<< "$audit_archived_default_out" &&
       ! grep -Fq -- 'hidden_nonblocking_db_first_drift=' <<< "$audit_archived_default_out" &&
       ! grep -Fq -- 'nonblocking_db_first_drift_details=hidden' <<< "$audit_archived_default_out" &&
       ! grep -Fq -- 'nonblocking_db_first_drift=' <<< "$audit_archived_default_out" &&
       ! grep -Fq -- ' live_drift=' <<< "$audit_archived_default_out" &&
       ! grep -Fq -- '.github/task-runs/demo/task-report.md' <<< "$audit_archived_default_out" &&
       ! grep -Fq -- '.github/task-runs/demo/context-brief.md' <<< "$audit_archived_default_out"; then
      printf 'PASS github-index audit default hides non-blocking DB-first drift details\n'
    else
      printf 'FAIL github-index audit default leaked or mislabeled non-blocking drift\n'
      rc=1
    fi
  else
    printf '%s\n' "$audit_archived_default_out"
    printf 'FAIL github-index audit default rejected non-blocking historical drift\n'
    rc=1
  fi
  local audit_archived_verbose_out
  if audit_archived_verbose_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" audit-db-first \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --backup-dir .github/db-backup/test \
      --show-nonblocking-drift
  ); then
    printf '%s\n' "$audit_archived_verbose_out"
    if grep -Fq -- 'nonblocking_db_first_drift=2' <<< "$audit_archived_verbose_out" &&
       grep -Fq -- 'nonblocking_archived_stored_only=1' <<< "$audit_archived_verbose_out" &&
       grep -Fq -- 'nonblocking_live_drift=1' <<< "$audit_archived_verbose_out" &&
       grep -Fq -- '[nonblocking_archived_stored_only]' <<< "$audit_archived_verbose_out" &&
       grep -Fq -- '[nonblocking_live_drift]' <<< "$audit_archived_verbose_out" &&
       grep -Fq -- '.github/task-runs/demo/task-report.md' <<< "$audit_archived_verbose_out" &&
       grep -Fq -- '.github/task-runs/demo/context-brief.md' <<< "$audit_archived_verbose_out"; then
      printf 'PASS github-index audit verbose can show non-blocking DB-first drift details\n'
    else
      printf 'FAIL github-index audit verbose did not show non-blocking drift details\n'
      rc=1
    fi
  else
    printf '%s\n' "$audit_archived_verbose_out"
    printf 'FAIL github-index audit verbose rejected non-blocking historical drift\n'
    rc=1
  fi
  printf '\nlocal strict live drift\n' >> "$mini_repo/.github/memory/project-status.md"
  local doctor_strict_out
  if doctor_strict_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" doctor \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --fail-on-drift
  ); then
    printf '%s\n' "$doctor_strict_out"
    printf 'FAIL github-index doctor allowed strict memory live drift\n'
    rc=1
  else
    printf '%s\n' "$doctor_strict_out"
    if grep -Fq -- 'stale=' <<< "$doctor_strict_out" &&
       grep -Fq -- 'blocking_drift=1' <<< "$doctor_strict_out" &&
       ! grep -Fq -- 'diagnostic_drift=' <<< "$doctor_strict_out" &&
       ! grep -Fq -- 'historical_archive_diagnostics=' <<< "$doctor_strict_out" &&
       ! grep -Fq -- 'live_index_cache_diagnostics=' <<< "$doctor_strict_out" &&
       ! grep -Fq -- 'hidden_historical_drift=' <<< "$doctor_strict_out" &&
       ! grep -Fq -- 'historical_drift_details=hidden' <<< "$doctor_strict_out" &&
       grep -Fq -- '.github/memory/project-status.md' <<< "$doctor_strict_out"; then
      printf 'PASS github-index doctor still rejects strict memory live drift\n'
    else
      printf 'FAIL github-index doctor strict memory drift output was not actionable\n'
      rc=1
    fi
  fi
  local audit_strict_out
  if audit_strict_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" audit-db-first \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --backup-dir .github/db-backup/test \
      --json
  ); then
    printf '%s\n' "$audit_strict_out"
    printf 'FAIL github-index audit allowed strict memory live drift\n'
    rc=1
  else
    printf '%s\n' "$audit_strict_out"
    if grep -Fq -- '"ok": false' <<< "$audit_strict_out" &&
       grep -Fq -- '"content_mismatch": [' <<< "$audit_strict_out" &&
       grep -Fq -- '.github/memory/project-status.md' <<< "$audit_strict_out"; then
      printf 'PASS github-index audit still rejects strict memory live drift\n'
    else
      printf 'FAIL github-index audit strict memory drift output was not actionable\n'
      rc=1
    fi
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" update-stored .github/memory/project-status.md \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --from-file .github/memory/project-status.md || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" snapshot-stored \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --path .github/memory/project-status.md \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  if e2e_github_index_backup_entry_valid \
       "$mini_repo/.github/db-backup/test" \
       .github/memory/project-status.md \
       "$mini_repo/.github/memory/project-status.md"; then
    printf 'PASS github-index snapshots repaired strict live truth before final audit\n'
  else
    printf 'FAIL github-index strict live repair did not refresh the authoritative backup\n'
    rc=1
  fi
  local usage_out usage_api_out
  usage_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" usage \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --surface api \
      --json
  ) || rc=1
  printf '%s\n' "$usage_out"
  usage_api_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" api \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --request '{"op":"usage","surface":"cli","limit":20}'
  ) || rc=1
  printf '%s\n' "$usage_api_out"
  if grep -Fq -- '"op": "usage"' <<< "$usage_out" &&
     grep -Fq -- '"last_used_at": "20' <<< "$usage_out" &&
     grep -Fq -- '"surface": "api"' <<< "$usage_out" &&
     grep -Fq -- '"op": "runs"' <<< "$usage_out" &&
     grep -Fq -- '"op": "usage"' <<< "$usage_api_out" &&
     grep -Fq -- '"surface": "cli"' <<< "$usage_api_out" &&
     grep -Fq -- '"op": "runs"' <<< "$usage_api_out"; then
    printf 'PASS github-index usage log records CLI/API database access time\n'
  else
    printf 'FAIL github-index usage log did not record expected database access time\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" audit-db-first \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" audit-markdown-coverage \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --fail-on-live-evidence || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" materialize \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --path .github/memory/project-status.md \
    --output-root materialized || rc=1
  if grep -Fq -- 'updated in stored db' "$mini_repo/materialized/.github/memory/project-status.md"; then
    printf 'PASS github-index materialize restores stored document content\n'
  else
    printf 'FAIL github-index materialize did not restore stored content\n'
    rc=1
  fi
  printf '# temporary live corruption before restore\n' \
    > "$mini_repo/.github/memory/project-status.md"
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" restore \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --path .github/memory/project-status.md \
    --yes || rc=1
  if grep -Fq -- 'updated in stored db' "$mini_repo/.github/memory/project-status.md" &&
     grep -Fq -- 'local strict live drift' "$mini_repo/.github/memory/project-status.md"; then
    printf 'PASS github-index restore recovers current retained memory truth from backup\n'
  else
    printf 'FAIL github-index restore did not recover current retained memory truth\n'
    rc=1
  fi

  rm -rf "$tmp_dir"
  return "$rc"
}
