#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MODE=quick
PYTHON_BIN=${PYTHON:-python3}

usage() {
  cat <<'EOF'
用法:
  scripts/agent-maintain.sh [--mode quick|final|release|full|check]

说明:
  quick  : C 调度器、shell 语法和轻量自测；不调用 Python/DB/profile。
  final  : 一轮 AI 环境目标结束后运行 quick 和非发布类确定性审计。
  release: 在 final 后追加商业包、DB/branch-health 与交付审计。
  full   : 在 release 后追加 agent-system profile，生成完整 task-run。
  check  : final 的兼容别名；新流程请显式使用 final。
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
    quick|final|release|full) ;;
    check) MODE=final ;;
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

run_quick() {
  local rc=0
  run_step "shell syntax" bash -n \
    scripts/agent-flow.sh \
    scripts/agent-maintain.sh \
    scripts/agent-e2e.sh \
    scripts/task-run-status.sh \
    scripts/tests/test-agent-flow.sh \
    scripts/tests/test-task-run-status.sh || rc=1
  run_step "C workflow controller self-test" scripts/tests/test-agent-flow.sh || rc=1
  return "$rc"
}

run_final() {
  local rc=0
  run_quick || rc=1
  run_step "report traceability audit" "$PYTHON_BIN" scripts/github_index_db.py report-audit || rc=1
  run_step "schema contract audit" "$PYTHON_BIN" scripts/github_index_db.py schema-audit || rc=1
  run_step "runtime artifact boundary audit" "$PYTHON_BIN" scripts/github_index_db.py artifact-audit || rc=1
  run_step "policy audit" "$PYTHON_BIN" scripts/github_index_db.py policy-audit || rc=1
  run_step "skill audit" "$PYTHON_BIN" scripts/github_index_db.py skill-audit || rc=1
  run_step "RTL task contract audit" "$PYTHON_BIN" .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py audit || rc=1
  run_step "RTL task contract self-test" "$PYTHON_BIN" .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py self-test || rc=1
  run_step "RTL task contract CLI self-test" "$PYTHON_BIN" .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py cli-self-test || rc=1
  run_step "task-run status fail-closed self-test" scripts/tests/test-task-run-status.sh || rc=1
  run_step "trace audit" "$PYTHON_BIN" scripts/github_index_db.py trace-audit || rc=1
  run_step "state machine audit" "$PYTHON_BIN" scripts/github_index_db.py state-audit || rc=1
  run_step "profile binding validation" scripts/agent-e2e.sh --validate-all-profiles || rc=1
  return "$rc"
}

run_release() {
  local rc=0
  run_final || rc=1
  run_step "commercial package build" scripts/package-ai-dev-env.sh || rc=1
  run_step "commercial delivery audit" "$PYTHON_BIN" scripts/github_index_db.py delivery-audit || rc=1
  run_step "branch health report" "$PYTHON_BIN" scripts/github_index_db.py branch-health-report || rc=1
  run_step "branch health audit" "$PYTHON_BIN" scripts/github_index_db.py branch-health-audit || rc=1
  run_step "db-first audit" "$PYTHON_BIN" scripts/github_index_db.py audit-db-first || rc=1
  run_step "markdown coverage" "$PYTHON_BIN" scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence || rc=1
  return "$rc"
}

main() {
  parse_args "$@"
  cd "$REPO_ROOT" || exit 2

  local rc=0
  case "$MODE" in
    quick)
      run_quick || rc=1
      ;;
    final)
      run_final || rc=1
      ;;
    release)
      run_release || rc=1
      ;;
    full)
      run_release || rc=1
    run_step "agent-system profile" scripts/agent-e2e.sh --profile agent-system --task-slug agent-env-maintenance-full || rc=1
      ;;
  esac

  if [[ $rc -eq 0 ]]; then
    printf '\n[agent-maintain] PASS mode=%s\n' "$MODE"
  else
    printf '\n[agent-maintain] FAIL mode=%s\n' "$MODE"
  fi
  return "$rc"
}

main "$@"
