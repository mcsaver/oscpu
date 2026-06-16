#!/usr/bin/env bash

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
     grep -Fq -- 'def archive_markdown_files' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py"; then
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
    printf 'PASS github-index persistent sources are tracked\n'
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
     grep -Fq -- 'show_nonblocking_drift' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'show_status_samples' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'blocking_drift=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'nonblocking_drift=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'nonblocking_db_first_drift=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'nonblocking_live_drift=' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- '--show-nonblocking-drift' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- '--show-status-samples' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'archived_stored_only' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def audit_markdown_coverage' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def archive_markdown_files' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def index_evidence_assets' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'stored_index_docs' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'store-evidence-index-documents' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'archive-markdown' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
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
  python3 -m py_compile "$E2E_ROOT_DIR/scripts/github_index_db.py" "$E2E_ROOT_DIR"/scripts/dev_memory/*.py || rc=1

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
      --max-tokens 400
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
  mkdir -p "$mini_repo/.github/memory"
  cat > "$mini_repo/.github/memory/project-status.md" <<'EOF'
# Mini Project Status

mini retained memory source
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
  cat > "$mini_repo/.github/e2e/profiles/nemu-ubuntu-full-gate.tsv" <<'EOF'
# node_id|module|function|owner_agent|inputs|outputs
@include|base-gate||||
nemu-ubuntu-full-focused-gate|nemu|e2e_nemu_ubuntu_full_focused_gate|nemu|optional full Ubuntu rootfs/systemd guest gate|full Ubuntu rootfs guest gate
EOF
  cat > "$mini_repo/.github/e2e/modules/nemu-ubuntu-full-gate.md" <<'EOF'
# NEMU Ubuntu Full Gate

full Ubuntu rootfs systemd guest gate profile
EOF
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" rebuild \
    --repo-root "$mini_repo" \
    --db "$mini_db" || rc=1
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
     [[ -f "$mini_repo/.github/db-backup/test/files/.github/memory/project-status.md" ]]; then
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
  local brief_out brief_api_out
  brief_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" brief updated \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --profile github-index \
      --max-tokens 700
  ) || rc=1
  printf '%s\n' "$brief_out"
  brief_api_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" api \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --request '{"op":"brief","terms":"updated","profile":"github-index","max_tokens":700}'
  ) || rc=1
  printf '%s\n' "$brief_api_out"
  if grep -Fq -- '# Agent Brief' <<< "$brief_out" &&
     grep -Fq -- 'updated in stored db' <<< "$brief_out" &&
     grep -Fq -- '"op": "brief"' <<< "$brief_api_out" &&
     grep -Fq -- '"ok": true' <<< "$brief_api_out"; then
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
# Dispatch Log

## 基本信息

- `task_id`: demo
- `task_slug`: demo-run
- `graph_template`: modular-agent-e2e
- `profile`: github-index
EOF
  cat > "$mini_repo/.github/task-runs/demo/task-report.md" <<'EOF'
# Task Report

## 基本信息

- `task_id`: demo
- `task_slug`: demo-run
- `graph_template`: modular-agent-e2e
- `profile`: github-index
- `graph_mode`: static
- `status`: completed
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
     grep -Fq -- '"assets": 2' <<< "$evidence_index_out" &&
     grep -Fq -- '.github/task-runs/demo/evidence-index.md' <<< "$evidence_index_out" &&
     grep -Fq -- '"stored_index_docs": [' <<< "$evidence_index_out" &&
     [[ -f "$mini_repo/.github/db-backup/stored-snapshot/files/.github/task-runs/demo/evidence-index.md" ]] &&
     grep -Fq -- '__DEMO_MARKER__' "$mini_repo/.github/task-runs/demo/evidence-index.md"; then
    printf 'PASS github-index indexes raw evidence assets and stores generated evidence-index docs\n'
  else
    printf 'FAIL github-index raw evidence asset index did not produce stored evidence-index summary\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" archive-markdown .github/task-runs/demo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  if grep -Fq -- 'demo run completed' "$mini_repo/.github/task-runs/demo/task-report.md" &&
     ! grep -Fq -- 'DB-backed .github/task-runs/demo/task-report.md' "$mini_repo/.github/task-runs/demo/task-report.md" &&
     [[ -f "$mini_repo/.github/db-backup/test/files/.github/task-runs/demo/task-report.md" ]]; then
    printf 'PASS github-index archives task-run Markdown to DB while keeping live file and backup\n'
  else
    printf 'FAIL github-index archive-markdown did not preserve live task-run Markdown\n'
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
     grep -Fq -- '"status": "completed"' <<< "$runs_out" &&
     grep -Fq -- '"profile_resolve_path": ".github/task-runs/demo/profile-resolve.md"' <<< "$runs_out" &&
     grep -Fq -- '"evidence_index_path": ".github/task-runs/demo/evidence-index.md"' <<< "$runs_out" &&
     grep -Fq -- '"evidence_asset_count": 2' <<< "$runs_out" &&
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
       ! grep -Fq -- 'nonblocking_drift=' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'hidden_historical_drift=' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'historical_drift_details=hidden' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'archived_missing=' <<< "$doctor_archived_out" &&
       ! grep -Fq -- '.github/task-runs/demo/task-report.md' <<< "$doctor_archived_out" &&
       ! grep -Fq -- 'archived_stale=' <<< "$doctor_archived_out" &&
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
       grep -Fq -- 'nonblocking_drift=2' <<< "$doctor_archived_verbose_out" &&
       grep -Fq -- 'archived_missing=' <<< "$doctor_archived_verbose_out" &&
       grep -Fq -- '.github/task-runs/demo/task-report.md' <<< "$doctor_archived_verbose_out" &&
       grep -Fq -- 'archived_stale=' <<< "$doctor_archived_verbose_out" &&
       grep -Fq -- '.github/task-runs/demo/context-brief.md' <<< "$doctor_archived_verbose_out"; then
      printf 'PASS github-index doctor can explicitly show historical task-run drift details\n'
    else
      printf 'FAIL github-index doctor verbose non-blocking drift output was not actionable\n'
      rc=1
    fi
  else
    printf '%s\n' "$doctor_archived_verbose_out"
    printf 'FAIL github-index doctor verbose rejected historical task-run missing/stale drift\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" refresh AGENTS.md \
    --repo-root "$mini_repo" \
    --db "$mini_db" || rc=1
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
       ! grep -Fq -- 'nonblocking_drift=' <<< "$doctor_shim_default_out" &&
       ! grep -Fq -- 'live_index_stale=' <<< "$doctor_shim_default_out" &&
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
       grep -Fq -- 'nonblocking_drift=3' <<< "$doctor_shim_verbose_out" &&
       grep -Fq -- 'live_index_stale=' <<< "$doctor_shim_verbose_out" &&
       grep -Fq -- 'AGENTS.md' <<< "$doctor_shim_verbose_out"; then
      printf 'PASS github-index doctor can explicitly show old agent shim stale drift details\n'
    else
      printf 'FAIL github-index doctor verbose old agent shim stale output was not actionable\n'
      rc=1
    fi
  else
    printf '%s\n' "$doctor_shim_verbose_out"
    printf 'FAIL github-index doctor verbose rejected old agent shim stale drift\n'
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
       ! grep -Fq -- 'nonblocking_drift=' <<< "$doctor_strict_out" &&
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
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" restore \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --path .github/memory/project-status.md \
    --yes || rc=1
  if grep -Fq -- 'mini retained memory source' "$mini_repo/.github/memory/project-status.md"; then
    printf 'PASS github-index restore recovers original retained memory file from backup\n'
  else
    printf 'FAIL github-index restore did not recover original retained memory file\n'
    rc=1
  fi

  rm -rf "$tmp_dir"
  return "$rc"
}
