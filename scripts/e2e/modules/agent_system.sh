#!/usr/bin/env bash

e2e_agent_system_discovery() {
  echo "[agent-system] discovery files"
  local rc=0
  e2e_print_required_files \
    AGENTS.md \
    .github/AGENTS.md \
    .github/copilot-instructions.md \
    .github/agentic-hardware-blueprint.md \
    .github/instructions/memory-protocol.instructions.md \
    .github/instructions/agent-e2e-workflow.instructions.md \
    .github/e2e/README.md \
    .github/e2e/profiles/discovery.tsv \
    .github/e2e/profiles/nemu-dev.tsv \
    .github/e2e/profiles/nemu-dev-gate.tsv \
    .github/e2e/profiles/nemu-dev-full-gate.tsv \
    .github/e2e/profiles/nemu-dev-full-soak.tsv \
    .github/e2e/profiles/npc-dev.tsv \
    .github/e2e/profiles/nemu-ubuntu-focused.tsv \
    .github/e2e/profiles/nemu-ubuntu-gate.tsv \
    .github/e2e/profiles/nemu-ubuntu-full-gate.tsv \
    .github/e2e/profiles/nemu-ubuntu-full-soak.tsv \
    .github/e2e/modules/agent-system.md \
    .github/e2e/modules/toolchain.md \
    .github/memory/project-status.md \
    .github/memory/known-issues.md \
    .github/memory/modules/agent-system.md \
    .github/task-runs/templates/task-report.template.md \
    .github/task-runs/templates/dispatch-log.template.md \
    scripts/agent-env.sh \
    scripts/agent-run.sh \
    scripts/agent-e2e.sh \
    scripts/e2e/lib/common.sh \
    scripts/e2e/lib/report.sh || rc=1

  echo "[agent-system] non-interactive soft environment hook"
  local runner_sh="$E2E_ROOT_DIR/scripts/agent-e2e.sh"
  local agent_env_sh="$E2E_ROOT_DIR/scripts/agent-env.sh"
  local agent_run_sh="$E2E_ROOT_DIR/scripts/agent-run.sh"
  if grep -Fq 'source "$E2E_ROOT_DIR/scripts/agent-env.sh"' "$runner_sh"; then
    printf 'PASS agent-e2e sources scripts/agent-env.sh\n'
  else
    printf 'FAIL agent-e2e sources scripts/agent-env.sh\n'
    rc=1
  fi
  if grep -Fq 'YSYX_AGENT_ENV_SOURCED=1' "$agent_env_sh"; then
    printf 'PASS agent-env exports sourced marker\n'
  else
    printf 'FAIL agent-env exports sourced marker\n'
    rc=1
  fi
  if grep -Fq 'source "$REPO_ROOT/scripts/agent-env.sh"' "$agent_run_sh" &&
     grep -Fq 'exec "$@"' "$agent_run_sh"; then
    printf 'PASS agent-run sources scripts/agent-env.sh before exec\n'
  else
    printf 'FAIL agent-run sources scripts/agent-env.sh before exec\n'
    rc=1
  fi
  if grep -Fq '看似 source、实际为空' "$agent_env_sh" &&
     grep -Fq 'unset YSYX_AGENT_ENV_SOURCED YSYX_AGENT_ENV_SOURCE' "$agent_env_sh" &&
     grep -Fq 'unset YSYX_HOME NEMU_HOME AM_HOME NPC_HOME NVBOARD_HOME YOSYSSTA_HOME' "$agent_env_sh"; then
    printf 'PASS agent-env repairs incomplete inherited marker\n'
  else
    printf 'FAIL agent-env repairs incomplete inherited marker\n'
    rc=1
  fi

  echo "[agent-system] outer command-control hygiene"
  local workflow_doc=".github/instructions/agent-e2e-workflow.instructions.md"
  local e2e_readme=".github/e2e/README.md"
  local agent_contract=".github/e2e/modules/agent-system.md"
  local control_hygiene_ok=1
  for doc in "$workflow_doc" "$e2e_readme" "$agent_contract"; do
    if e2e_file_contains "$doc" '外层工具控制符' &&
       e2e_file_contains "$doc" 'rg -e'; then
      printf 'PASS command-control hygiene documented in %s\n' "$doc"
    else
      printf 'FAIL command-control hygiene documented in %s\n' "$doc"
      control_hygiene_ok=0
    fi
  done
  if [[ $control_hygiene_ok -ne 1 ]]; then
    rc=1
  fi

  echo "[agent-system] WSL single-flight hygiene"
  local wsl_hygiene_ok=1
  for doc in "$workflow_doc" "$e2e_readme" "$agent_contract"; do
    if e2e_file_contains "$doc" '并发启动多个 `wsl.exe`' &&
       e2e_file_contains "$doc" 'Wsl/Service/E_UNEXPECTED' &&
       e2e_file_contains "$doc" 'scripts/agent-run.sh'; then
      printf 'PASS WSL single-flight hygiene documented in %s\n' "$doc"
    else
      printf 'FAIL WSL single-flight hygiene documented in %s\n' "$doc"
      wsl_hygiene_ok=0
    fi
  done
  if [[ $wsl_hygiene_ok -ne 1 ]]; then
    rc=1
  fi

  echo "[agent-system] scenario profile isolation"
  local profile_isolation_ok=1
  for doc in "$workflow_doc" "$e2e_readme"; do
    if e2e_file_contains "$doc" 'nemu-dev' &&
       e2e_file_contains "$doc" 'npc-dev' &&
       e2e_file_contains "$doc" '场景隔离'; then
      printf 'PASS scenario profile isolation documented in %s\n' "$doc"
    else
      printf 'FAIL scenario profile isolation documented in %s\n' "$doc"
      profile_isolation_ok=0
    fi
  done
  if e2e_file_contains .github/e2e/profiles/nemu-dev.tsv '@include|nemu-ubuntu-focused' &&
     e2e_file_contains .github/e2e/profiles/nemu-dev-full-gate.tsv '@include|nemu-dev' &&
     e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'npc-sim-contract|npc|e2e_npc_sim_contract' &&
     ! e2e_file_contains .github/e2e/profiles/nemu-dev.tsv 'npc-' &&
     ! e2e_file_contains .github/e2e/profiles/npc-dev.tsv 'nemu-ubuntu'; then
    printf 'PASS scenario dev profiles are split\n'
  else
    printf 'FAIL scenario dev profiles are split\n'
    profile_isolation_ok=0
  fi
  if e2e_file_contains .github/e2e/profiles/nemu-ubuntu-gate.tsv '@include|nemu-ubuntu' &&
     e2e_file_contains .github/e2e/profiles/nemu-ubuntu-full-gate.tsv '@include|nemu-ubuntu' &&
     e2e_file_contains .github/e2e/profiles/nemu-ubuntu-full-soak.tsv '@include|nemu-ubuntu'; then
    printf 'PASS existing NEMU Ubuntu integration profiles are preserved\n'
  else
    printf 'FAIL existing NEMU Ubuntu integration profiles are preserved\n'
    profile_isolation_ok=0
  fi
  if [[ $profile_isolation_ok -ne 1 ]]; then
    rc=1
  fi

  echo "[agent-system] tracked persistent agent/e2e sources"
  local untracked_agent_sources
  untracked_agent_sources=$(
    git -C "$E2E_ROOT_DIR" ls-files --others --exclude-standard -- \
      AGENTS.md \
      .github/AGENTS.md \
      .github/agents \
      .github/e2e/README.md \
      .github/e2e/modules \
      .github/e2e/profiles \
      .github/instructions \
      .github/memory/modules \
      scripts/agent-env.sh \
      scripts/agent-run.sh \
      scripts/agent-e2e.sh \
      scripts/e2e/modules 2>/dev/null || true
  )
  if [[ -z $untracked_agent_sources ]]; then
    printf 'PASS persistent agent/e2e source files are tracked\n'
  else
    printf 'FAIL persistent agent/e2e source files are untracked\n%s\n' "$untracked_agent_sources"
    rc=1
  fi

  echo "[agent-system] task-run text artifact sanitizer"
  local report_sh="$E2E_ROOT_DIR/scripts/e2e/lib/report.sh"
  if [[ $(grep -Fc 'e2e_sanitize_task_run_text_artifacts' "$report_sh") -ge 2 ]]; then
    printf 'PASS report.sh sanitizer defined and called\n'
  else
    printf 'FAIL report.sh sanitizer defined and called\n'
    rc=1
  fi
  if grep -Fq "LC_ALL=C sed -i 's/[ \\t\\r]*$//'" "$report_sh"; then
    printf 'PASS report.sh strips trailing blanks and CR\n'
  else
    printf 'FAIL report.sh strips trailing blanks and CR\n'
    rc=1
  fi
  if grep -Fq "find \"\$E2E_RUN_DIR\" -type f" "$report_sh"; then
    printf 'PASS report.sh limits sanitizer to current task-run\n'
  else
    printf 'FAIL report.sh limits sanitizer to current task-run\n'
    rc=1
  fi
  if grep -Fq 'e2e_archive_task_run_markdown_to_db' "$report_sh" &&
     grep -Fq 'archive-markdown "$run_rel"' "$report_sh" &&
     grep -Fq 'E2E_TASK_RUN_DB_BACKUP_DIR' "$report_sh"; then
    printf 'PASS report.sh archives task-run Markdown into database-backed shims\n'
  else
    printf 'FAIL report.sh task-run Markdown DB archive hook missing\n'
    rc=1
  fi
  if grep -Fq 'e2e_generate_context_brief' "$report_sh" &&
     grep -Fq 'E2E_CONTEXT_BRIEF_FILE' "$report_sh" &&
     grep -Fq 'github_index_db.py" brief' "$report_sh"; then
    printf 'PASS report.sh generates DB-backed context brief before dispatch\n'
  else
    printf 'FAIL report.sh context brief hook missing\n'
    rc=1
  fi
  if grep -Fq 'e2e_generate_profile_resolve' "$report_sh" &&
     grep -Fq 'E2E_PROFILE_RESOLVE_FILE' "$report_sh" &&
     grep -Fq 'github_index_db.py" resolve-profile' "$report_sh"; then
    printf 'PASS report.sh generates DB-backed resolved profile before dispatch\n'
  else
    printf 'FAIL report.sh resolved profile hook missing\n'
    rc=1
  fi
  return "$rc"
}

e2e_agent_system_profile_index() {
  echo "[agent-system] e2e profiles"
  find "$E2E_ROOT_DIR/.github/e2e/profiles" -maxdepth 1 -type f -name '*.tsv' -printf '%f\n' | sort
}
