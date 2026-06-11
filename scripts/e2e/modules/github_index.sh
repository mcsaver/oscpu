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

  echo "[github-index] DB-first migration interface"
  if grep -Fq -- 'CREATE TABLE IF NOT EXISTS db_documents' "$E2E_ROOT_DIR/scripts/dev_memory/core.py" &&
     grep -Fq -- 'def promote_documents' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def update_stored_document' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def migrate_to_db' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def restore_backup' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def snapshot_stored_documents' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def rehydrate_stored_documents' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def audit_db_first' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def audit_markdown_coverage' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'def archive_markdown_files' "$E2E_ROOT_DIR/scripts/dev_memory/maintenance.py" &&
     grep -Fq -- 'archive-markdown' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'snapshot-stored' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'rehydrate' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'choices=["auto", "live", "stored"]' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py"; then
    printf 'PASS github-index exposes DB-first promote/update/migrate/restore/audit interface\n'
  else
    printf 'FAIL github-index DB-first migration interface drifted\n'
    rc=1
  fi

  echo "[github-index] e2e task-run archive hook"
  if grep -Fq -- 'e2e_archive_task_run_markdown_to_db' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'archive-markdown "$run_rel"' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'E2E_TASK_RUN_DB_BACKUP_DIR' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh"; then
    printf 'PASS e2e report layer archives task-run Markdown into DB\n'
  else
    printf 'FAIL e2e report layer does not archive task-run Markdown into DB\n'
    rc=1
  fi

  echo "[github-index] e2e context brief hook"
  if grep -Fq -- 'e2e_generate_context_brief' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'E2E_CONTEXT_BRIEF_FILE' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'github_index_db.py" brief' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'e2e_generate_context_brief' "$E2E_ROOT_DIR/scripts/agent-e2e.sh"; then
    printf 'PASS e2e runner generates DB-backed context brief before dispatch\n'
  else
    printf 'FAIL e2e runner context brief hook missing\n'
    rc=1
  fi

  echo "[github-index] e2e resolved profile hook"
  if grep -Fq -- 'e2e_generate_profile_resolve' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'E2E_PROFILE_RESOLVE_FILE' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'github_index_db.py" resolve-profile' "$E2E_ROOT_DIR/scripts/e2e/lib/report.sh" &&
     grep -Fq -- 'e2e_generate_profile_resolve' "$E2E_ROOT_DIR/scripts/agent-e2e.sh"; then
    printf 'PASS e2e runner generates DB-backed resolved profile before dispatch\n'
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
     grep -Fq -- 'def agent_brief' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def agent_profiles' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def agent_resolve_profile' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- 'def agent_runs' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- '--profile-limit' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'profile-catalog' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'resolve-profile' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- 'run-catalog' "$E2E_ROOT_DIR/scripts/dev_memory/cli.py" &&
     grep -Fq -- '"profiles": {"fields"' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- '"resolve-profile": {"fields"' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
     grep -Fq -- '"runs": {"fields"' "$E2E_ROOT_DIR/scripts/dev_memory/api.py" &&
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
    --root .github \
    --db "$tmp_db" \
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

  echo "[github-index] DB-first migrate/restore mini smoke"
  cat > "$mini_repo/AGENTS.md" <<'EOF'
# Mini AGENTS

mini db first source
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
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" migrate \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  if grep -Fq -- 'DB-backed AGENTS.md' "$mini_repo/AGENTS.md" &&
     [[ -f "$mini_repo/.github/db-backup/test/files/AGENTS.md" ]]; then
    printf 'PASS github-index migrate leaves shim and backup\n'
  else
    printf 'FAIL github-index migrate did not leave shim and backup\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --source stored \
    --path AGENTS.md \
    --limit 1 \
    --max-tokens 200 || rc=1
  cat > "$mini_repo/updated-agents.md" <<'EOF'
# Mini AGENTS

mini db first source updated in stored db
EOF
  local stored_update_out
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" update-stored AGENTS.md \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --from-file updated-agents.md || rc=1
  stored_update_out=$(
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load \
      --repo-root "$mini_repo" \
      --db "$mini_db" \
      --source stored \
      --path AGENTS.md \
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
  local api_out
  api_out=$(
    printf '%s\n' \
      '{"op":"stat"}' \
      '{"op":"search","terms":"updated","source":"stored","limit":2}' \
      '{"op":"summary","path":"AGENTS.md","source":"stored","limit":1}' \
      '{"op":"load","path":"AGENTS.md","source":"stored","limit":1,"max_tokens":200}' \
      '{"op":"show","path":"AGENTS.md","source":"stored"}' |
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
    printf 'PASS github-index brief returns DB-backed startup context for agents\n'
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
      --path AGENTS.md \
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
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" archive-markdown .github/task-runs/demo \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --yes || rc=1
  if grep -Fq -- 'DB-backed .github/task-runs/demo/task-report.md' "$mini_repo/.github/task-runs/demo/task-report.md" &&
     [[ -f "$mini_repo/.github/db-backup/test/files/.github/task-runs/demo/task-report.md" ]]; then
    printf 'PASS github-index archives task-run Markdown with shim and backup\n'
  else
    printf 'FAIL github-index archive-markdown did not preserve task-run Markdown\n'
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
     grep -Fq -- '"expanded_node_count": 1' <<< "$runs_out" &&
     grep -Fq -- '"op": "runs"' <<< "$runs_api_out" &&
     grep -Fq -- '"run_id": "demo"' <<< "$runs_api_out"; then
    printf 'PASS github-index runs catalog lists archived task-run evidence\n'
  else
    printf 'FAIL github-index runs catalog did not list expected archived task-run\n'
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
    --path AGENTS.md \
    --output-root materialized || rc=1
  if grep -Fq -- 'updated in stored db' "$mini_repo/materialized/AGENTS.md"; then
    printf 'PASS github-index materialize restores stored document content\n'
  else
    printf 'FAIL github-index materialize did not restore stored content\n'
    rc=1
  fi
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" restore \
    --repo-root "$mini_repo" \
    --db "$mini_db" \
    --backup-dir .github/db-backup/test \
    --path AGENTS.md \
    --yes || rc=1
  if grep -Fq -- '# Mini AGENTS' "$mini_repo/AGENTS.md"; then
    printf 'PASS github-index restore recovers original AGENTS file from backup\n'
  else
    printf 'FAIL github-index restore did not recover original AGENTS file\n'
    rc=1
  fi

  rm -rf "$tmp_dir"
  return "$rc"
}
