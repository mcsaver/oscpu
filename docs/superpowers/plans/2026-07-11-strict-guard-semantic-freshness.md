# Strict Guard Semantic Freshness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Make strict guard evidence freshness depend on recorded run completion time instead of mutable task-report.md mtime.

**Architecture:** Add one timestamp parser at the guard boundary and make the
candidate selector compare semantic epochs. Keep the existing changed-path
profile mapping and DB-recall checks unchanged.

**Tech Stack:** Bash, Python 3 standard library, agent-e2e shell self-tests.

## Global Constraints

- Do not modify RV64 production RTL.
- Use run-manifest.json updated_at as the canonical timestamp when present.
- Use task-report.md updated_at only for manifest-less legacy evidence.
- A manifest/profile/status contradiction must fail closed.
- Use a single WSL command at a time.

---

### Task 1: Add failing semantic-freshness regressions

**Files:**
- Modify: scripts/e2e/modules/agent_system.sh
- Test: scripts/e2e/modules/agent_system.sh

**Interfaces:**
- Consumes: scripts/agent-e2e.sh --guard, --paths-file, and --evidence-dir.
- Produces: shell regression cases that distinguish semantic time from mtime.

- [x] **Step 1: Extend the positive legacy fixture**

Record guard_updated_at from e2e_now and include it in the existing completed
agent-system task report:

~~~bash
local guard_updated_at
guard_updated_at=$(e2e_now)
cat > "$guard_evidence/task-report.md" <<'EOF'
# 任务报告

- `profile`: agent-system
- `status`: completed
- `updated_at`: __GUARD_UPDATED_AT__
EOF
sed -i "s/__GUARD_UPDATED_AT__/$guard_updated_at/" \
  "$guard_evidence/task-report.md"
~~~

- [x] **Step 2: Add stale-semantic and fresh-semantic fixtures**

Create complete DB-recall artifact sets. Give the stale fixture a manifest
updated_at of 2000-01-01 00:00:00 +0000 and touch only its report. Give the
fresh fixture a manifest updated_at one second newer than the changed path and
set its report mtime to 2000:

~~~bash
guard_change_epoch=$(stat -c '%Y' "$E2E_ROOT_DIR/.github/AGENTS.md")
guard_fresh_updated_at=$(date -d "@$((guard_change_epoch + 1))" '+%Y-%m-%d %H:%M:%S %z')
~~~

The stale invocation must return non-zero; the fresh invocation must return
zero. Also add a fixture whose report says agent-system but whose manifest
says npc-dev, and require rejection.

- [x] **Step 3: Add newest-candidate selection coverage**

Pass two otherwise valid agent-system evidence directories, older first and
newer second. Cover both distinct seconds and .100000/.900000 within one
second. Capture guard output and require evidence= to name the newer directory.

- [x] **Step 4: Add fail-closed parsing cases**

Reject non-completed/missing/timezone-less manifest fields, malformed and
non-object/non-finite JSON without traceback, duplicate JSON keys, dangling
manifest symlinks, legacy profile/status prefix collisions, and duplicate
conflicting report fields.

- [x] **Step 5: Run the isolated RED profile**

Run:

~~~bash
E2E_ARCHIVE_TASK_RUN_MARKDOWN_TO_DB=0 \
E2E_INDEX_TASK_RUN_EVIDENCE_ASSETS=0 \
scripts/agent-e2e.sh \
  --profile agent-system \
  --task-slug strict-guard-semantic-red \
  --run-dir .github/runtime-artifacts/strict-guard-semantic-red \
  --stop-on-fail
~~~

Expected: non-zero, with at least the stale-semantic acceptance or old-report
mtime rejection case reported as FAIL.

### Task 2: Implement semantic timestamp selection

**Files:**
- Modify: scripts/agent-e2e.sh
- Test: scripts/e2e/modules/agent_system.sh

**Interfaces:**
- Produces: e2e_guard_evidence_updated_epoch evidence_root profile.
- Consumes: an evidence directory containing run-manifest.json or a legacy
  task-report.md.

- [x] **Step 1: Add the timestamp helper**

Implement a Bash wrapper around Python 3. The Python body must:

~~~python
def parse_epoch_us(raw):
    parsed = datetime.fromisoformat(raw.strip())
    if parsed.tzinfo is None:
        raise ValueError("timezone is required")
    parsed_utc = parsed.astimezone(timezone.utc)
    delta = parsed_utc - datetime(1970, 1, 1, tzinfo=timezone.utc)
    return (delta.days * 86400 + delta.seconds) * 1_000_000 + delta.microseconds
~~~

When a manifest exists, parse JSON and require profile/status/updated_at.
Otherwise find this report form:

~~~text
- `updated_at`: 2026-07-11 22:03:18 +0800
~~~

Parse report profile/status/updated_at as unique exact fields. Parse manifest
with duplicate-key/non-finite-constant rejection, require an object, and reject
manifest symlinks. Print only the integer UTC microsecond epoch and return
non-zero without traceback for malformed input.

- [x] **Step 2: Scan all candidates and choose the newest**

Replace report_mtime qualification in
e2e_guard_find_evidence_for_profile with:

~~~bash
if e2e_guard_evidence_has_db_recall "$evidence_root" &&
   evidence_epoch_us=$(e2e_guard_evidence_updated_epoch "$evidence_root" "$profile") &&
   [[ $evidence_epoch_us =~ ^[0-9]+$ ]] &&
   (( evidence_epoch_us >= min_change_us )) &&
   (( evidence_epoch_us > best_epoch_us )); then
  best_epoch_us=$evidence_epoch_us
  best_dir=${dir#./}
fi
~~~

After the loop, print best_dir only when non-empty.

- [x] **Step 3: Run syntax and GREEN tests**

Run:

~~~bash
bash -n scripts/agent-e2e.sh scripts/e2e/modules/agent_system.sh
E2E_ARCHIVE_TASK_RUN_MARKDOWN_TO_DB=0 \
E2E_INDEX_TASK_RUN_EVIDENCE_ASSETS=0 \
scripts/agent-e2e.sh \
  --profile agent-system \
  --task-slug strict-guard-semantic-green \
  --run-dir .github/runtime-artifacts/strict-guard-semantic-green \
  --stop-on-fail
~~~

Expected: syntax exit 0 and agent-system profile completed.

- [x] **Step 4: Commit the code and regression**

~~~bash
git add scripts/agent-e2e.sh scripts/e2e/modules/agent_system.sh
git diff --cached --check
git commit -m "agent e2e: use semantic guard freshness"
~~~

### Task 3: Persist evidence and verify integration

**Files:**
- Create: .github/task-runs/2026-07-12-strict-guard-semantic-freshness-agent-system-3/
- Create: .github/task-runs/2026-07-12-strict-guard-semantic-freshness-agent-system-3/strict-guard-verification.md
- Modify: retained agent-system/project memory through github_index_db.py
- Modify: .github/db-backup/stored-snapshot/
- Modify: .github/db-backup/task-runs/manifest.json

**Interfaces:**
- Consumes: the GREEN implementation from Task 2.
- Produces: current agent-system evidence, strict-guard proof, and DB snapshots.

- [x] **Step 1: Generate a repository evidence run**

~~~bash
scripts/agent-e2e.sh \
  --profile agent-system \
  --task-slug strict-guard-semantic-freshness-agent-system \
  --stop-on-fail
~~~

Expected: completed task report and run-manifest.json with final_result PASS.

- [x] **Step 2: Run strict guard with explicit current evidence**

~~~bash
scripts/agent-e2e.sh \
  --guard \
  --guard-mode strict \
  --evidence-dir .github/task-runs/2026-07-12-strict-guard-semantic-freshness-agent-system-3 \
  --evidence-dir .github/task-runs/2026-07-11-rv64-authority-evidence-final-npc-dev
~~~

Expected: agent-system PASS. Any unrelated profile requirement must be backed
by a current matching run rather than bypassed.

- [x] **Step 3: Refresh and audit retained state**

~~~bash
python3 scripts/github_index_db.py snapshot-stored \
  --backup-dir .github/db-backup/stored-snapshot --yes
python3 scripts/github_index_db.py audit-db-first
git diff --check
~~~

Expected: DB-first audit PASS and no whitespace errors.

- [ ] **Step 4: Commit exact evidence and snapshot paths**

Stage only the new semantic-freshness task-run and intended DB snapshot paths.
Confirm that build/linux-logs/npc-linux.log, the three pre-existing dirty RV64
RTL files, and .superpowers are absent from the index before committing.
