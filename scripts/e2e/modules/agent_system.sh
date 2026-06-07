#!/usr/bin/env bash

e2e_agent_system_discovery() {
  echo "[agent-system] discovery files"
  e2e_print_required_files \
    AGENTS.md \
    .github/AGENTS.md \
    .github/copilot-instructions.md \
    .github/agentic-hardware-blueprint.md \
    .github/instructions/memory-protocol.instructions.md \
    .github/instructions/agent-e2e-workflow.instructions.md \
    .github/e2e/README.md \
    .github/e2e/profiles/discovery.tsv \
    .github/e2e/modules/agent-system.md \
    .github/memory/project-status.md \
    .github/memory/known-issues.md \
    .github/memory/modules/agent-system.md \
    .github/task-runs/templates/task-report.template.md \
    .github/task-runs/templates/dispatch-log.template.md \
    scripts/agent-e2e.sh \
    scripts/e2e/lib/common.sh \
    scripts/e2e/lib/report.sh
}

e2e_agent_system_profile_index() {
  echo "[agent-system] e2e profiles"
  find "$E2E_ROOT_DIR/.github/e2e/profiles" -maxdepth 1 -type f -name '*.tsv' -printf '%f\n' | sort
}
