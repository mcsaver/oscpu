#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT

mkdir -p \
  "$TEST_ROOT/.github/agents" \
  "$TEST_ROOT/.github/instructions"

review_boundary_valid() {
  local root=$1

  grep -Fq 'candidate / 独立 reviewer' "$root/.github/AGENTS.md" &&
    grep -Fq '高风险、难恢复操作' "$root/.github/AGENTS.md" &&
    grep -Fq '.github/AGENTS.md' "$root/.github/copilot-instructions.md" &&
    grep -Fq '不能自动触发' "$root/.github/agents/agent-system.agent.md" &&
    grep -Fq 'reviewer' "$root/.github/agents/agent-system.agent.md" &&
    grep -Fq '普通失败不要求' "$root/.github/instructions/agent-env-state-machine.instructions.md" &&
    grep -Fq 'Reviewer/Inspector 只在高风险' "$root/.github/instructions/agent-env-state-machine.instructions.md" &&
    grep -Fq '不机械重跑同一' "$root/.github/instructions/agent-env-state-machine.instructions.md"
}

review_boundary_valid "$REPO_ROOT"
printf 'PASS active policy keeps review risk-triggered and non-mechanical\n'

printf '%s\n' '| candidate / 独立 reviewer | 高风险、难恢复操作、正式 promotion、对外发布或用户明确要求 |' \
  >"$TEST_ROOT/.github/AGENTS.md"
printf '%s\n' '跨 agent operating contract 统一见 .github/AGENTS.md。' \
  >"$TEST_ROOT/.github/copilot-instructions.md"
printf '%s\n' '“非平凡”不能自动触发 gate、task-run、reviewer 或 full profile。' \
  >"$TEST_ROOT/.github/agents/agent-system.agent.md"
printf '%s\n' '普通失败不要求独立 reviewer。Reviewer/Inspector 只在高风险时使用，且不机械重跑同一命令。' \
  >"$TEST_ROOT/.github/instructions/agent-env-state-machine.instructions.md"

review_boundary_valid "$TEST_ROOT"
printf 'PASS risk-triggered review anchors are accepted\n'

printf '%s\n' '普通失败一律要求独立 reviewer，并机械重跑全部命令。' \
  >"$TEST_ROOT/.github/instructions/agent-env-state-machine.instructions.md"
if review_boundary_valid "$TEST_ROOT"; then
  printf 'FAIL unconditional review policy was accepted\n' >&2
  exit 1
fi
printf 'PASS unconditional review policy is rejected\n'
