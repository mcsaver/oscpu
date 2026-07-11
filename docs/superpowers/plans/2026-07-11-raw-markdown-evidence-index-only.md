# Raw Markdown Evidence Index-only Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Keep Markdown runtime evidence in evidence_assets only, never in DB
full-text document tables.

**Architecture:** Route retention by runtime path before extension-based
classification. The general document index skips raw roots, while
index-evidence owns bounded metadata, hashes, markers, and excerpts.

**Tech Stack:** Python 3, SQLite, Bash e2e profiles.

## Global Constraints

- Preserve raw files locally until their evidence indexes are refreshed.
- Do not modify RV64 production RTL.
- Do not weaken artifact-audit or markdown-coverage.
- Use exact-path staging and one WSL command at a time.

---

### Task 1: Write the failing github-index contract

**Files:**
- Modify: scripts/e2e/modules/github_index.sh

**Interfaces:**
- Consumes: index-evidence, rebuild, archive-markdown, and the mini SQLite DB.
- Produces: a regression that requires evidence/note.md to be asset-only.

- [ ] **Step 1: Require Markdown evidence indexing**

Change the mini-repository expectation from assets 2 to assets 3 and require
the JSON output to name .github/task-runs/demo/evidence/note.md.

- [ ] **Step 2: Require absence from full-text tables**

After rebuilding and archiving the mini repository, query SQLite with Python:

~~~python
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
pattern = ".github/task-runs/%/evidence/%"
asset = conn.execute(
    "SELECT COUNT(*) FROM evidence_assets WHERE path = ?",
    (".github/task-runs/demo/evidence/note.md",),
).fetchone()[0]
file_text = conn.execute(
    "SELECT COUNT(*) FROM file_text WHERE path LIKE ?", (pattern,)
).fetchone()[0]
documents = conn.execute(
    "SELECT COUNT(*) FROM db_documents WHERE path LIKE ?", (pattern,)
).fetchone()[0]
raise SystemExit(0 if (asset, file_text, documents) == (1, 0, 0) else 1)
~~~

- [ ] **Step 3: Run RED**

~~~bash
E2E_ARCHIVE_TASK_RUN_MARKDOWN_TO_DB=0 \
E2E_INDEX_TASK_RUN_EVIDENCE_ASSETS=0 \
scripts/agent-e2e.sh \
  --profile github-index \
  --task-slug raw-markdown-evidence-red \
  --run-dir .github/runtime-artifacts/raw-markdown-evidence-red \
  --stop-on-fail
~~~

Expected: non-zero because current index-evidence reports two assets and
archive-markdown stores note.md as a document.

### Task 2: Separate raw evidence from document retention

**Files:**
- Modify: scripts/dev_memory/core.py
- Modify: scripts/dev_memory/maintenance.py
- Modify: scripts/e2e/lib/report.sh
- Modify: .github/ai-env/contracts/agent-env-schema-contract.json
- Test: scripts/e2e/modules/github_index.sh

**Interfaces:**
- Produces: is_raw_evidence_path(rel_path), returning true for either runtime
  evidence root.
- Consumes: normalized repository-relative POSIX paths.

- [ ] **Step 1: Add the shared path predicate**

~~~python
def is_raw_evidence_path(rel_path: str) -> bool:
    normalized = rel_path.replace("\\", "/")
    if normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized.startswith(".github/runtime-artifacts/") or (
        normalized.startswith(".github/task-runs/")
        and "/evidence/" in normalized
    )
~~~

Call it from should_skip_path. Extend prune_ignored_index_rows to delete
files/file_text/chunks/FTS rows matching both raw roots.

- [ ] **Step 2: Remove raw evidence from DB-retained kinds**

Delete task-evidence from DB_RETAINED_KINDS and from retention.db_owned_kinds
in the schema contract. In archive_markdown_candidates, explicitly skip every
path for which is_raw_evidence_path returns true.

- [ ] **Step 3: Index Markdown as a bounded evidence asset**

Add ".md" to EVIDENCE_TEXT_SUFFIXES. Keep full content out of evidence_assets;
only the existing hash, line count, summary, head/tail excerpts, and markers
are stored.

- [ ] **Step 4: Count evidence Markdown in run manifests**

In e2e_render_run_manifest, skip Markdown only when it is outside
run_dir/evidence. Top-level task-run documents remain excluded from asset
counts.

- [ ] **Step 5: Enforce both full-text boundaries**

Extend artifact-audit to report raw runtime paths found in file_text as well
as db_documents. Exclude raw runtime roots from audit-markdown-coverage because
artifact-audit is their authoritative retention gate.

- [ ] **Step 6: Run GREEN**

~~~bash
python3 -m py_compile scripts/dev_memory/core.py scripts/dev_memory/maintenance.py
bash -n scripts/e2e/lib/report.sh scripts/e2e/modules/github_index.sh
E2E_ARCHIVE_TASK_RUN_MARKDOWN_TO_DB=0 \
E2E_INDEX_TASK_RUN_EVIDENCE_ASSETS=0 \
scripts/agent-e2e.sh \
  --profile github-index \
  --task-slug raw-markdown-evidence-green \
  --run-dir .github/runtime-artifacts/raw-markdown-evidence-green \
  --stop-on-fail
~~~

Expected: all commands exit zero.

### Task 3: Migrate repository evidence and restore the baseline

**Files:**
- Untrack: the nine reported .github/task-runs/*/evidence/*.md payloads.
- Modify: generated evidence-index.md files for their three task runs.
- Modify: .github/db-backup/stored-snapshot/

**Interfaces:**
- Consumes: Task 2's index-only retention implementation.
- Produces: no raw runtime path in db_documents/file_text and current indexes.

- [ ] **Step 1: Re-index the three affected runs**

Run index-evidence --write-index --yes for:

- 2026-07-11-rv64-doc-authority-refresh
- 2026-07-11-rv64-ooo-code-first-architecture-audit
- 2026-07-11-strict-guard-artifact-lifecycle-fix

- [ ] **Step 2: Prune historical document rows**

Materialize only the nine raw document paths to an ignored quarantine output
and use --prune-non-retained. Rebuild the main DB to prune general full-text
rows for both runtime roots.

- [ ] **Step 3: Remove payloads from Git tracking**

Use git rm --cached with the exact nine paths. Confirm the files still exist
locally and are ignored, and that each appears in evidence_assets.

- [ ] **Step 4: Verify the restored baseline**

~~~bash
python3 scripts/github_index_db.py artifact-audit
python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence
python3 scripts/github_index_db.py audit-db-first
scripts/agent-e2e.sh \
  --profile agent-system \
  --task-slug raw-markdown-evidence-agent-system \
  --stop-on-fail
~~~

Expected: all gates PASS. Then stage only the lifecycle implementation,
contract, regression, affected indexes/task-run metadata, and deliberate
tracked-payload deletions.
