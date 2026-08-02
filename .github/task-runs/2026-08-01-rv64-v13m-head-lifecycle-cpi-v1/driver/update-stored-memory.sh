#!/usr/bin/env bash

set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
db_path="${repo_root}/.github/cache/github-index.sqlite"
run_dir="${repo_root}/.github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1"

prepend_section() {
  local document_path="${1:?document path is required}"
  local section_path="${2:?section path is required}"

  python3 -B - "${db_path}" "${document_path}" "${section_path}" <<'PY' |
import pathlib
import sqlite3
import sys

database, document_path, section_path = sys.argv[1:4]
connection = sqlite3.connect(database)
row = connection.execute(
    "SELECT content FROM db_documents WHERE path = ?", (document_path,)
).fetchone()
if row is None:
    raise SystemExit(f"stored document is missing: {document_path}")
content = row[0]
section = pathlib.Path(section_path).read_text(encoding="utf-8").strip()
first_line_end = content.find("\n")
if first_line_end < 0 or not content.startswith("# "):
    raise SystemExit(f"stored document has no title heading: {document_path}")
sys.stdout.write(
    content[:first_line_end + 1] + "\n" + section + "\n\n" +
    content[first_line_end + 1:].lstrip("\n")
)
PY
  python3 "${repo_root}/scripts/github_index_db.py" update-stored \
    "${document_path}" --stdin --refresh-shim \
    --backup-dir "${repo_root}/.github/db-backup"
}

prepend_section \
  .github/memory/project-status.md \
  "${run_dir}/evidence/memory/project-status-section.md"
prepend_section \
  .github/memory/modules/npc.md \
  "${run_dir}/evidence/memory/npc-section.md"
