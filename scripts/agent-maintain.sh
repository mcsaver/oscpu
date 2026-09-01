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
  quick  : 只检查维护入口与定向 shell 测试的语法；不执行测试、DB 或 profile。
  final  : AI 环境 PR 的代表性测试集；覆盖 operating contract 场景、controller、真实严格例外、
           专家路由、可选 RTL handoff、JSON 和 profile 绑定，不运行 DB/publication/commercial 审计。
  release: 显式 release/商业交付边界，运行专项合同、持久化、发布与交付审计。
  full   : release 的兼容别名。
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
    scripts/package-ai-dev-env.sh \
    scripts/task-run-status.sh \
    scripts/tests/test-agent-flow.sh \
    scripts/tests/test-agent-system-dual-role-contract.sh \
    scripts/tests/test-rv64-soc-delivery-gates.sh \
    scripts/tests/test-source-tree-artifact-hygiene.sh \
    scripts/tests/test-task-run-status.sh || rc=1
  return "$rc"
}

run_final() {
  local rc=0
  local json_rc=0
  local json_file
  local contract_dir=.github/ai-env/contracts
  local -a json_files=("$contract_dir"/*.json)
  run_quick || rc=1
  run_step "operating contract scenarios and mutations" \
    "$PYTHON_BIN" -B scripts/tests/test-agent-operating-contract.py || rc=1
  run_step "C workflow controller self-test" scripts/tests/test-agent-flow.sh || rc=1
  run_step "risk-triggered reviewer boundary" \
    bash scripts/tests/test-agent-system-dual-role-contract.sh || rc=1
  run_step "persistent longrun terminal status" \
    scripts/tests/test-task-run-status.sh || rc=1
  run_step "runtime artifact source boundary" \
    scripts/tests/test-source-tree-artifact-hygiene.sh || rc=1
  run_step "RV64 delivery hard-invariant preservation" \
    scripts/tests/test-rv64-soc-delivery-gates.sh || rc=1
  run_step "CPU Architect advisory routing" \
    "$PYTHON_BIN" -B scripts/tests/test_cpu_architect_route.py || rc=1
  run_step "CPU Architect grounded-learning boundary" \
    "$PYTHON_BIN" -B scripts/tests/test_cpu_architect_learning.py || rc=1
  run_step "optional RTL handoff compatibility" \
    "$PYTHON_BIN" -B \
      .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py \
      cli-self-test || rc=1
  if [[ ! -d $contract_dir ]]; then
    printf '[agent-maintain] FAIL contract JSON directory is missing: %s\n' "$contract_dir" >&2
    json_rc=1
  elif [[ ! -f ${json_files[0]} ]]; then
    printf '[agent-maintain] FAIL no live contract JSON found in %s\n' "$contract_dir" >&2
    json_rc=1
  else
    for json_file in "${json_files[@]}"; do
      "$PYTHON_BIN" -m json.tool "$json_file" >/dev/null || json_rc=1
    done
  fi
  if [[ $json_rc -eq 0 ]]; then
    printf '[agent-maintain] PASS contract JSON syntax\n'
  else
    printf '[agent-maintain] FAIL contract JSON syntax\n' >&2
    rc=1
  fi
  run_step "profile binding validation" scripts/agent-e2e.sh --validate-all-profiles || rc=1
  return "$rc"
}

run_release() {
  local rc=0
  run_final || rc=1
  run_step "report traceability audit" "$PYTHON_BIN" scripts/github_index_db.py report-audit || rc=1
  run_step "schema contract audit" "$PYTHON_BIN" scripts/github_index_db.py schema-audit || rc=1
  run_step "skill audit" "$PYTHON_BIN" scripts/github_index_db.py skill-audit || rc=1
  run_step "trace audit" "$PYTHON_BIN" scripts/github_index_db.py trace-audit || rc=1
  run_step "published agent-system profile" scripts/agent-e2e.sh --profile agent-system --publish || rc=1
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
      ;;
  esac

  if [[ $rc -eq 0 ]]; then
    case "$MODE" in
      quick)
        printf '\n[agent-maintain] COMPLETE mode=quick scope=shell-syntax\n'
        ;;
      final)
        printf '\n[agent-maintain] COMPLETE mode=final scope=representative-agent-contract-suite\n'
        ;;
      release|full)
        printf '\n[agent-maintain] PASS mode=%s scope=explicit-release-suite\n' "$MODE"
        ;;
    esac
  else
    printf '\n[agent-maintain] FAIL mode=%s\n' "$MODE"
  fi
  return "$rc"
}

main "$@"
