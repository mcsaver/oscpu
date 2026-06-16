#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MODE=check
PYTHON_BIN=${PYTHON:-python3}

usage() {
  cat <<'EOF'
用法:
  scripts/agent-maintain.sh [--mode check|full]

说明:
  check: 只跑轻量维护 gate，验证 Database/Skill/Agent 三层入口。
  full : 在 check 后追加 agent-system profile，生成 task-run 证据包。
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        [[ $# -ge 2 ]] || { echo "--mode 需要参数" >&2; exit 2; }
        MODE=$2
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "未知参数: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  case "$MODE" in
    check|full) ;;
    *)
      echo "未知 mode: $MODE" >&2
      exit 2
      ;;
  esac
}

run_step() {
  local name=$1
  shift
  printf '\n[agent-maintain] %s\n' "$name"
  "$@"
}

main() {
  parse_args "$@"
  cd "$REPO_ROOT" || exit 2

  local rc=0
  run_step "shell syntax" bash -n scripts/agent-maintain.sh scripts/agent-e2e.sh || rc=1
  run_step "report traceability audit" "$PYTHON_BIN" scripts/github_index_db.py report-audit || rc=1
  run_step "schema contract audit" "$PYTHON_BIN" scripts/github_index_db.py schema-audit || rc=1
  run_step "runtime artifact boundary audit" "$PYTHON_BIN" scripts/github_index_db.py artifact-audit || rc=1
  run_step "commercial package build" scripts/package-ai-dev-env.sh || rc=1
  run_step "commercial delivery audit" "$PYTHON_BIN" scripts/github_index_db.py delivery-audit || rc=1
  run_step "policy audit" "$PYTHON_BIN" scripts/github_index_db.py policy-audit || rc=1
  run_step "skill audit" "$PYTHON_BIN" scripts/github_index_db.py skill-audit || rc=1
  run_step "trace audit" "$PYTHON_BIN" scripts/github_index_db.py trace-audit || rc=1
  run_step "state machine audit" "$PYTHON_BIN" scripts/github_index_db.py state-audit || rc=1
  run_step "branch health report" "$PYTHON_BIN" scripts/github_index_db.py branch-health-report || rc=1
  run_step "branch health audit" "$PYTHON_BIN" scripts/github_index_db.py branch-health-audit || rc=1
  run_step "db-first audit" "$PYTHON_BIN" scripts/github_index_db.py audit-db-first || rc=1
  run_step "markdown coverage" "$PYTHON_BIN" scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence || rc=1
  run_step "profile list" scripts/agent-e2e.sh --list-profiles || rc=1
  run_step "profile binding validation" scripts/agent-e2e.sh --validate-all-profiles || rc=1

  if [[ $MODE = full ]]; then
    run_step "agent-system profile" scripts/agent-e2e.sh --profile agent-system --task-slug agent-env-maintenance-full || rc=1
  fi

  if [[ $rc -eq 0 ]]; then
    printf '\n[agent-maintain] PASS mode=%s\n' "$MODE"
  else
    printf '\n[agent-maintain] FAIL mode=%s\n' "$MODE"
  fi
  return "$rc"
}

main "$@"
