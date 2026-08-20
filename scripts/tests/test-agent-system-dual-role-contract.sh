#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT

mkdir -p \
  "$TEST_ROOT/.github/agents" \
  "$TEST_ROOT/.github/instructions"

printf '%s\n' '高风险任务执行实现者 / 审查者风险触发双角色复核。' \
  >"$TEST_ROOT/.github/AGENTS.md"
printf '%s\n' '高风险任务执行实现者人格 / 审查者人格风险触发复核。' \
  >"$TEST_ROOT/.github/copilot-instructions.md"
printf '%s\n' '实现者人格负责证据；审查者人格负责反例；普通确定性环境修改直接交付。' \
  >"$TEST_ROOT/.github/agents/agent-system.agent.md"
printf '%s\n' '高风险执行实现者/审查者风险触发双角色复核；落盘、跨模块或长跑本身不触发。' \
  >"$TEST_ROOT/.github/instructions/agent-env-state-machine.instructions.md"

E2E_ROOT_DIR=$TEST_ROOT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/e2e/lib/common.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/e2e/modules/agent_system.sh"

e2e_agent_system_dual_role_docs_valid
printf 'PASS risk-triggered dual-role semantic anchors are accepted\n'

printf '%s\n' '实现者与审查者分别工作。' \
  >"$TEST_ROOT/.github/copilot-instructions.md"
if e2e_agent_system_dual_role_docs_valid; then
  printf 'FAIL missing risk-triggered review anchor was accepted\n' >&2
  exit 1
fi
printf 'PASS missing risk-triggered review anchor is rejected\n'
