#!/usr/bin/env bash

e2e_github_index_contract() {
  echo "[github-index] contract"
  local rc=0

  e2e_print_required_files \
    scripts/github_index_db.py \
    .github/e2e/modules/github-index.md \
    .github/e2e/profiles/github-index.tsv || rc=1

  echo "[github-index] tracked persistent sources"
  if git -C "$E2E_ROOT_DIR" ls-files --error-unmatch \
      scripts/github_index_db.py \
      scripts/e2e/modules/github_index.sh \
      .github/e2e/modules/github-index.md \
      .github/e2e/profiles/github-index.tsv >/dev/null 2>&1; then
    printf 'PASS github-index persistent sources are tracked\n'
  else
    printf 'FAIL github-index persistent sources are not tracked\n'
    rc=1
  fi

  echo "[github-index] filesystem source and database boundary"
  if grep -Fq 'DEFAULT_ROOT = ".github"' "$E2E_ROOT_DIR/scripts/github_index_db.py" &&
     grep -Fq 'DEFAULT_DB = ".github/cache/github-index.sqlite"' "$E2E_ROOT_DIR/scripts/github_index_db.py" &&
     grep -Fq 'sqlite3' "$E2E_ROOT_DIR/scripts/github_index_db.py"; then
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

  echo "[github-index] python syntax"
  python3 -m py_compile "$E2E_ROOT_DIR/scripts/github_index_db.py" || rc=1

  echo "[github-index] temporary rebuild/stat/query/doctor smoke"
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

  local query_out
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

  rm -rf "$tmp_dir"
  return "$rc"
}
