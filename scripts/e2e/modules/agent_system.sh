#!/usr/bin/env bash

e2e_agent_system_discovery() {
  echo "[agent-system] discovery files"
  local rc=0
  e2e_print_required_files \
    AGENTS.md \
    AI_ENVIRONMENT.md \
    .github/AGENTS.md \
    .github/copilot-instructions.md \
    .github/ai-env/README.md \
    .github/ai-env/contracts/agent-env-policy.json \
    .github/ai-env/contracts/agent-env-rebuild-matrix.json \
    .github/ai-env/contracts/agent-env-schema-contract.json \
    .github/ai-env/contracts/agent-env-observability.json \
    .github/ai-env/contracts/agent-env-state-traceability.json \
    .github/ai-env/contracts/agent-env-runtime-artifacts.json \
    .github/ai-env/contracts/agent-env-review-routing.json \
    .github/ai-env/contracts/agent-env-branch-health.json \
    .github/ai-env/contracts/agent-env-delivery.json \
    .github/agentic-hardware-blueprint.md \
    .github/instructions/agent-env-layer-contract.instructions.md \
    .github/instructions/agent-env-state-machine.instructions.md \
    .github/instructions/memory-protocol.instructions.md \
    .github/instructions/agent-e2e-workflow.instructions.md \
    .github/skills/agent-env-maintenance/SKILL.md \
    .github/agents/AGENT_INDEX.md \
    .github/workflows/agent-maintain.yml \
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
    deliverables/ai-dev-env-commercial-v1/README.md \
    deliverables/ai-dev-env-commercial-v1/PACKAGING_MANIFEST.md \
    deliverables/ai-dev-env-commercial-v1/COMMERCIAL_READINESS.md \
    scripts/package-ai-dev-env.sh \
    scripts/README.md \
    scripts/agent-env.sh \
    scripts/agent-run.sh \
    scripts/agent-maintain.sh \
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
  if grep -Fq 'validate_profile_boundary' "$runner_sh" &&
     grep -Fq 'mode=NEMU-only' "$runner_sh" &&
     grep -Fq 'mode=NPC-only' "$runner_sh" &&
     grep -Fq 'NEMU-only dev profile pulled NPC work' "$runner_sh" &&
     grep -Fq 'NPC-only dev profile pulled NEMU work' "$runner_sh"; then
    printf 'PASS agent-e2e enforces runtime scenario profile boundary\n'
  else
    printf 'FAIL agent-e2e enforces runtime scenario profile boundary\n'
    profile_isolation_ok=0
  fi
  local scenario_runtime_sh="$E2E_ROOT_DIR/scripts/e2e/lib/common.sh"
  if grep -Fq 'e2e_validate_scenario_runtime_isolation' "$runner_sh" &&
     grep -Fq 'e2e_profile_runtime_scenario' "$scenario_runtime_sh" &&
     grep -Fq 'AGENT_E2E_SCENARIO_RUNTIME_ISOLATION' "$scenario_runtime_sh" &&
     grep -Fq 'E2E_SCENARIO_RUNTIME_PS_FILE' "$scenario_runtime_sh" &&
     grep -Fq 'run-guest-uart-ping' "$scenario_runtime_sh" &&
     grep -Fq 'nemu-python-int' "$scenario_runtime_sh"; then
    printf 'PASS agent-e2e exposes configurable active scenario runtime isolation\n'
  else
    printf 'FAIL agent-e2e active scenario runtime isolation hook missing\n'
    profile_isolation_ok=0
  fi
  local scenario_ps_file
  scenario_ps_file=$(mktemp)
  printf '%s\n' \
    '123 bash .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest-uart-ping-slow.sh' \
    '456 bash .github/task-runs/2026-06-16-nemu-python-int-full-lite-wide-ifetch-off/run.sh' \
    > "$scenario_ps_file"
  if AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=warn E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation nemu-dev >/dev/null 2>&1 &&
     AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=warn E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation npc-dev >/dev/null 2>&1; then
    printf 'PASS scenario runtime guard warns but allows conflicting fake processes by default\n'
  else
    printf 'FAIL scenario runtime guard blocks default parallel fake processes\n'
    profile_isolation_ok=0
  fi
  if AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=strict E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation nemu-dev >/dev/null 2>&1 ||
     AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=strict E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation npc-dev >/dev/null 2>&1; then
    printf 'FAIL scenario runtime strict guard accepts conflicting fake processes\n'
    profile_isolation_ok=0
  else
    printf 'PASS scenario runtime strict guard rejects conflicting fake processes\n'
  fi
  printf '%s\n' \
    '789 bash .github/task-runs/2026-06-16-nemu-python-int-full-lite-wide-ifetch-off/run.sh' \
    > "$scenario_ps_file"
  if AGENT_E2E_SCENARIO_RUNTIME_ISOLATION=strict E2E_SCENARIO_RUNTIME_PS_FILE="$scenario_ps_file" e2e_validate_scenario_runtime_isolation nemu-dev >/dev/null 2>&1; then
    printf 'PASS scenario runtime strict guard accepts same-scenario fake process\n'
  else
    printf 'FAIL scenario runtime strict guard rejects same-scenario fake process\n'
    profile_isolation_ok=0
  fi
  rm -f "$scenario_ps_file"
  if [[ $profile_isolation_ok -ne 1 ]]; then
    rc=1
  fi

  echo "[agent-system] tracked persistent agent/e2e sources"
  local untracked_agent_sources
  untracked_agent_sources=$(
    git -C "$E2E_ROOT_DIR" ls-files --others --exclude-standard -- \
      AGENTS.md \
      AI_ENVIRONMENT.md \
      .github/AGENTS.md \
      .github/ai-env \
      .github/agents \
      .github/e2e/README.md \
      .github/e2e/modules \
      .github/e2e/profiles \
      .github/instructions \
      .github/skills \
      .github/workflows \
      .github/ai-env/contracts/agent-env-policy.json \
      .github/ai-env/contracts/agent-env-rebuild-matrix.json \
      .github/ai-env/contracts/agent-env-schema-contract.json \
      .github/ai-env/contracts/agent-env-observability.json \
      .github/ai-env/contracts/agent-env-state-traceability.json \
      .github/ai-env/contracts/agent-env-runtime-artifacts.json \
      .github/ai-env/contracts/agent-env-review-routing.json \
      .github/ai-env/contracts/agent-env-branch-health.json \
      .github/ai-env/contracts/agent-env-delivery.json \
      .github/memory/modules \
      deliverables/ai-dev-env-commercial-v1 \
      scripts/README.md \
      scripts/agent-env.sh \
      scripts/agent-run.sh \
      scripts/agent-maintain.sh \
      scripts/package-ai-dev-env.sh \
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
    printf 'PASS report.sh archives task-run Markdown into retained database\n'
  else
    printf 'FAIL report.sh task-run Markdown DB archive hook missing\n'
    rc=1
  fi
  if grep -Fq 'e2e_generate_context_brief' "$report_sh" &&
     grep -Fq 'E2E_CONTEXT_BRIEF_FILE' "$report_sh" &&
     grep -Fq 'github_index_db.py" brief' "$report_sh"; then
    printf 'PASS report.sh generates DB-indexed context brief before dispatch\n'
  else
    printf 'FAIL report.sh context brief hook missing\n'
    rc=1
  fi
  if grep -Fq 'e2e_generate_profile_resolve' "$report_sh" &&
     grep -Fq 'E2E_PROFILE_RESOLVE_FILE' "$report_sh" &&
     grep -Fq 'github_index_db.py" resolve-profile' "$report_sh"; then
    printf 'PASS report.sh generates live/indexed resolved profile before dispatch\n'
  else
    printf 'FAIL report.sh resolved profile hook missing\n'
    rc=1
  fi
  return "$rc"
}

e2e_agent_system_three_layer_contract() {
  echo "[agent-system] three-layer AI environment contract"
  local rc=0
  local layer_doc=".github/instructions/agent-env-layer-contract.instructions.md"
  local policy_doc=".github/ai-env/contracts/agent-env-policy.json"
  local matrix_doc=".github/ai-env/contracts/agent-env-rebuild-matrix.json"
  local schema_doc=".github/ai-env/contracts/agent-env-schema-contract.json"
  local observability_doc=".github/ai-env/contracts/agent-env-observability.json"
  local state_trace_doc=".github/ai-env/contracts/agent-env-state-traceability.json"
  local artifact_doc=".github/ai-env/contracts/agent-env-runtime-artifacts.json"
  local review_doc=".github/ai-env/contracts/agent-env-review-routing.json"
  local branch_doc=".github/ai-env/contracts/agent-env-branch-health.json"
  local delivery_doc=".github/ai-env/contracts/agent-env-delivery.json"
  local state_doc=".github/instructions/agent-env-state-machine.instructions.md"
  local skill_doc=".github/skills/agent-env-maintenance/SKILL.md"
  local workflow_yml=".github/workflows/agent-maintain.yml"
  local maintain_sh="scripts/agent-maintain.sh"

  e2e_print_required_files \
    "$layer_doc" \
    "$policy_doc" \
    "$matrix_doc" \
    "$schema_doc" \
    "$observability_doc" \
    "$state_trace_doc" \
    "$artifact_doc" \
    "$review_doc" \
    "$branch_doc" \
    "$delivery_doc" \
    "$state_doc" \
    "$skill_doc" \
    "$workflow_yml" \
    "$maintain_sh" || rc=1

  if e2e_file_contains "$layer_doc" 'Database = 长期记忆层' &&
     e2e_file_contains "$layer_doc" 'Skill = 标准化处理规则层' &&
     e2e_file_contains "$layer_doc" 'Agent = 自动维护流程层' &&
     e2e_file_contains "$layer_doc" 'scripts/agent-maintain.sh --mode check'; then
    printf 'PASS layer contract documents Database/Skill/Agent boundaries\n'
  else
    printf 'FAIL layer contract missing Database/Skill/Agent boundaries\n'
    rc=1
  fi

  if e2e_file_contains "$policy_doc" '"agent_tools"' &&
     e2e_file_contains "$policy_doc" '"allowed_tools"' &&
     e2e_file_contains "$policy_doc" '"retention"' &&
     e2e_file_contains "$policy_doc" '"raw_evidence_policy": "index-only"' &&
     e2e_file_contains "$policy_doc" '"traceability"' &&
     e2e_file_contains "$policy_doc" '"schema_contract": ".github/ai-env/contracts/agent-env-schema-contract.json"' &&
     e2e_file_contains "$policy_doc" '"observability_contract": ".github/ai-env/contracts/agent-env-observability.json"' &&
     e2e_file_contains "$policy_doc" '"state_traceability_contract": ".github/ai-env/contracts/agent-env-state-traceability.json"' &&
     e2e_file_contains "$policy_doc" '"runtime_artifact_contract": ".github/ai-env/contracts/agent-env-runtime-artifacts.json"' &&
     e2e_file_contains "$policy_doc" '"delivery_contract": ".github/ai-env/contracts/agent-env-delivery.json"' &&
     e2e_file_contains "$policy_doc" '"trace_id_required": true' &&
     e2e_file_contains "$policy_doc" '"run_manifest_required": true' &&
     e2e_file_contains "$policy_doc" '"traceback_required": true' &&
     e2e_file_contains "$policy_doc" '"runtime_artifacts"' &&
     e2e_file_contains "$policy_doc" '"artifact_store_root": ".github/runtime-artifacts"' &&
     e2e_file_contains "$policy_doc" '"review_routing": ".github/ai-env/contracts/agent-env-review-routing.json"' &&
     e2e_file_contains "$policy_doc" '"branch_health_dashboard": ".github/ai-env/contracts/agent-env-branch-health.json"' &&
     e2e_file_contains "$policy_doc" '"state_machine"' &&
     e2e_file_contains "$policy_doc" '"branch_health"' &&
     e2e_file_contains "$policy_doc" '"delivery"' &&
     e2e_file_contains "$policy_doc" '"package_script": "scripts/package-ai-dev-env.sh"' &&
     e2e_file_contains "$policy_doc" '"required_workflow": ".github/workflows/agent-maintain.yml"' &&
     e2e_file_contains "$policy_doc" '"nightly_required": true'; then
    printf 'PASS agent environment policy captures tools, retention, delivery, branch health, and CI contract\n'
  else
    printf 'FAIL agent environment policy missing tools, retention, delivery, branch health, or CI contract\n'
    rc=1
  fi

  if e2e_file_contains "$state_trace_doc" '"audit_command": "python3 scripts/github_index_db.py state-audit"' &&
     e2e_file_contains "$state_trace_doc" '"required_traceback_fields"' &&
     e2e_file_contains "$state_trace_doc" '"state-machine-traceback"' &&
     e2e_file_contains "$state_trace_doc" '"reviewer-inspector-gate"' &&
     e2e_file_contains "$state_trace_doc" '"required_run_manifest_field": "state_traceback"'; then
    printf 'PASS state traceability contract defines traceback fields and reviewer/inspector nodes\n'
  else
    printf 'FAIL state traceability contract missing traceback fields or reviewer/inspector nodes\n'
    rc=1
  fi

  if e2e_file_contains "$observability_doc" '"trace_id_format": "e2e:<run_id>"' &&
     e2e_file_contains "$observability_doc" '"run_manifest_path": ".github/task-runs/<run_id>/run-manifest.json"' &&
     e2e_file_contains "$observability_doc" '"required_manifest_fields"' &&
     e2e_file_contains "$observability_doc" '"database_mapping"' &&
     e2e_file_contains "$observability_doc" '"runtime_artifact_contract": ".github/ai-env/contracts/agent-env-runtime-artifacts.json"' &&
     e2e_file_contains "$observability_doc" '"run_manifest_index"'; then
    printf 'PASS observability contract defines trace id, run manifest, and DB mapping\n'
  else
    printf 'FAIL observability contract missing trace id, run manifest, or DB mapping\n'
    rc=1
  fi

  if e2e_file_contains "$schema_doc" '"runtime_schema_version": "4"' &&
     e2e_file_contains "$schema_doc" '"tables"' &&
     e2e_file_contains "$schema_doc" '"db_documents"' &&
     e2e_file_contains "$schema_doc" '"evidence_assets"' &&
     e2e_file_contains "$schema_doc" '"runtime_artifacts"' &&
     e2e_file_contains "$schema_doc" '"runtime_artifact_contract": ".github/ai-env/contracts/agent-env-runtime-artifacts.json"' &&
     e2e_file_contains "$schema_doc" '"required_operations"' &&
     e2e_file_contains "$schema_doc" '"resolve-profile"'; then
    printf 'PASS explicit schema/API contract covers DB tables and read-only API operations\n'
  else
    printf 'FAIL explicit schema/API contract missing DB tables or API operations\n'
    rc=1
  fi

  if e2e_file_contains "$matrix_doc" '"source_report"' &&
     e2e_file_contains "$matrix_doc" '"requirements"' &&
     e2e_file_contains "$matrix_doc" '"R1"' &&
     e2e_file_contains "$matrix_doc" '"R9"' &&
     e2e_file_contains "$matrix_doc" 'branch-health-report' &&
     e2e_file_contains "$matrix_doc" 'artifact-audit' &&
     e2e_file_contains "$matrix_doc" '"implemented"' &&
     ! e2e_file_contains "$matrix_doc" '"partial"' &&
     ! e2e_file_contains "$matrix_doc" '"planned"'; then
    printf 'PASS report-derived rebuild matrix tracks all implemented requirements\n'
  else
    printf 'FAIL report-derived rebuild matrix missing required tracking fields\n'
    rc=1
  fi

  if e2e_file_contains "$artifact_doc" '"audit_command": "python3 scripts/github_index_db.py artifact-audit"' &&
     e2e_file_contains "$artifact_doc" '"local_root": ".github/runtime-artifacts"' &&
     e2e_file_contains "$artifact_doc" '"raw_evidence_index_table": "evidence_assets"' &&
     e2e_file_contains "$artifact_doc" '"large_artifacts_externalized": true' &&
     e2e_file_contains "$artifact_doc" '"waveform_artifacts_externalized": true' &&
     e2e_file_contains "$artifact_doc" '"runtime-artifact-boundary"'; then
    printf 'PASS runtime artifact contract defines source/runtime retention boundary\n'
  else
    printf 'FAIL runtime artifact contract missing source/runtime boundary fields\n'
    rc=1
  fi

  if e2e_file_contains "$review_doc" '"review_routes"' &&
     e2e_file_contains "$review_doc" '"database-layer"' &&
     e2e_file_contains "$review_doc" '"skill-layer"' &&
     e2e_file_contains "$review_doc" '"agent-layer"' &&
     e2e_file_contains "$review_doc" '"requirement_routes"' &&
     e2e_file_contains "$review_doc" '"R9": "agent-layer"' &&
     e2e_file_contains "$review_doc" '"state-audit"'; then
    printf 'PASS review routing contract covers Database/Skill/Agent and R1-R9 routes\n'
  else
    printf 'FAIL review routing contract missing layer or requirement routes\n'
    rc=1
  fi

  if e2e_file_contains "$branch_doc" '"report_command": "python3 scripts/github_index_db.py branch-health-report"' &&
     e2e_file_contains "$branch_doc" '"audit_command": "python3 scripts/github_index_db.py branch-health-audit"' &&
     e2e_file_contains "$branch_doc" '"current_branch"' &&
     e2e_file_contains "$branch_doc" '"git_status_counts"' &&
     e2e_file_contains "$branch_doc" '"maintenance_gates"' &&
     e2e_file_contains "$branch_doc" '"delivery-audit"'; then
    printf 'PASS branch health dashboard contract exposes required signals and commands\n'
  else
    printf 'FAIL branch health dashboard contract missing signals or commands\n'
    rc=1
  fi

  if e2e_file_contains "$delivery_doc" '"audit_command": "python3 scripts/github_index_db.py delivery-audit"' &&
     e2e_file_contains "$delivery_doc" '"delivery_root": "deliverables/ai-dev-env-commercial-v1"' &&
     e2e_file_contains "$delivery_doc" '"package_root": "dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial"' &&
     e2e_file_contains "$delivery_doc" '"archive_root": ".github/archive/legacy-ai-dev-env-2026-06-13"' &&
     e2e_file_contains "$delivery_doc" '"active_legacy_roots_must_be_absent"' &&
     e2e_file_contains "$delivery_doc" '"required_package_paths"'; then
    printf 'PASS delivery contract defines archive, package, and active legacy boundaries\n'
  else
    printf 'FAIL delivery contract missing archive, package, or legacy boundaries\n'
    rc=1
  fi

  if e2e_file_contains "$state_doc" 'recall_context' &&
     e2e_file_contains "$state_doc" 'state traceback' &&
     e2e_file_contains "$state_doc" 'state_traceback' &&
     e2e_file_contains "$state_doc" 'state-machine-traceback' &&
     e2e_file_contains "$state_doc" 'reviewer-inspector-gate' &&
     e2e_file_contains "$state_doc" 'Reviewer / Inspector' &&
     e2e_file_contains "$state_doc" 'agent-system' &&
     e2e_file_contains "$state_doc" '不能把弱证据写成完成'; then
    printf 'PASS state machine instruction captures rollback and inspector rules\n'
  else
    printf 'FAIL state machine instruction missing rollback or inspector rules\n'
    rc=1
  fi

  if e2e_file_contains "$skill_doc" 'name: agent-env-maintenance' &&
     e2e_file_contains "$skill_doc" '数据库层' &&
     e2e_file_contains "$skill_doc" 'Skill 层' &&
     e2e_file_contains "$skill_doc" 'Agent 层'; then
    printf 'PASS agent-env-maintenance skill exposes three-layer workflow\n'
  else
    printf 'FAIL agent-env-maintenance skill missing three-layer workflow\n'
    rc=1
  fi

  if grep -Fq 'report-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'schema-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'artifact-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'package-ai-dev-env.sh' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'delivery-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'trace-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'state-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'policy-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'skill-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'branch-health-report' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'branch-health-audit' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'audit-db-first' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'audit-markdown-coverage --fail-on-live-evidence' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq -- '--validate-all-profiles' "$E2E_ROOT_DIR/$maintain_sh"; then
    printf 'PASS agent-maintain check covers policy, DB, Skill, markdown, and Agent profile gates\n'
  else
    printf 'FAIL agent-maintain check missing required gates\n'
    rc=1
  fi

  if grep -Fq 'rehydrate --backup-dir .github/db-backup/stored-snapshot --yes' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'rehydrate --backup-dir .github/db-backup/task-runs --yes' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'scripts/agent-maintain.sh --mode check' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'scripts/agent-e2e.sh --validate-all-profiles' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'python3 scripts/github_index_db.py delivery-audit' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'schedule:' "$E2E_ROOT_DIR/$workflow_yml"; then
    printf 'PASS agent-maintain workflow rehydrates DB memory and runs nightly gate\n'
  else
    printf 'FAIL agent-maintain workflow missing DB rehydrate or nightly gate\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" report-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" schema-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" artifact-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" delivery-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" trace-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" state-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" policy-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" skill-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" branch-health-report || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" branch-health-audit || rc=1
  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" audit-markdown-coverage --fail-on-live-evidence || rc=1
  return "$rc"
}

e2e_agent_system_runtime_artifact_boundary() {
  echo "[agent-system] runtime artifact boundary"
  local rc=0
  local artifact_doc=".github/ai-env/contracts/agent-env-runtime-artifacts.json"
  local policy_doc=".github/ai-env/contracts/agent-env-policy.json"
  local schema_doc=".github/ai-env/contracts/agent-env-schema-contract.json"
  local observability_doc=".github/ai-env/contracts/agent-env-observability.json"
  local report_sh="scripts/e2e/lib/report.sh"
  local maintain_sh="scripts/agent-maintain.sh"
  local profile_doc=".github/e2e/profiles/agent-system.tsv"

  e2e_print_required_files \
    "$artifact_doc" \
    "$policy_doc" \
    "$schema_doc" \
    "$observability_doc" \
    "$report_sh" \
    "$maintain_sh" \
    "$profile_doc" || rc=1

  if e2e_file_contains "$artifact_doc" '"runtime_payload_roots"' &&
     e2e_file_contains "$artifact_doc" '".github/task-runs/*/evidence"' &&
     e2e_file_contains "$artifact_doc" '".github/runtime-artifacts"' &&
     e2e_file_contains "$artifact_doc" '"raw_evidence_fulltext_in_db": false' &&
     e2e_file_contains "$artifact_doc" '"raw_evidence_index_required": true' &&
     e2e_file_contains "$artifact_doc" '"max_tracked_evidence_bytes": 1048576'; then
    printf 'PASS runtime artifact contract declares payload roots and retention limits\n'
  else
    printf 'FAIL runtime artifact contract missing payload roots or retention limits\n'
    rc=1
  fi

  if grep -Fq '.github/runtime-artifacts/**' "$E2E_ROOT_DIR/.gitignore" &&
     grep -Fq '!.github/runtime-artifacts/.gitkeep' "$E2E_ROOT_DIR/.gitignore" &&
     grep -Fq '.github/task-runs/**/evidence/*.vcd' "$E2E_ROOT_DIR/.gitignore" &&
     grep -Fq '.github/task-runs/**/evidence/*.raw' "$E2E_ROOT_DIR/.gitignore"; then
    printf 'PASS .gitignore keeps runtime artifact store and heavy evidence out of source\n'
  else
    printf 'FAIL .gitignore missing runtime artifact store or heavy evidence patterns\n'
    rc=1
  fi

  if grep -Fq 'e2e_index_task_run_evidence_assets' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'raw_evidence_index_only' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'run-manifest.json' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'archive-markdown' "$E2E_ROOT_DIR/$report_sh"; then
    printf 'PASS report.sh emits manifest pointers and DB evidence asset indexes\n'
  else
    printf 'FAIL report.sh missing runtime artifact indexing hooks\n'
    rc=1
  fi

  if e2e_file_contains "$profile_doc" 'runtime-artifact-boundary|agent-system|e2e_agent_system_runtime_artifact_boundary|agent-system|' &&
     grep -Fq 'artifact-audit' "$E2E_ROOT_DIR/$maintain_sh"; then
    printf 'PASS agent-system profile and maintenance gate execute artifact-audit\n'
  else
    printf 'FAIL agent-system profile or maintenance gate missing runtime artifact audit\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" artifact-audit || rc=1
  return "$rc"
}

e2e_agent_system_state_traceback() {
  echo "[agent-system] state machine traceback"
  local rc=0
  local state_doc=".github/instructions/agent-env-state-machine.instructions.md"
  local state_trace_doc=".github/ai-env/contracts/agent-env-state-traceability.json"
  local report_sh="scripts/e2e/lib/report.sh"

  e2e_print_required_files \
    "$state_doc" \
    "$state_trace_doc" \
    "$report_sh" || rc=1

  if e2e_file_contains "$state_doc" 'recall_context' &&
     e2e_file_contains "$state_doc" 'classify_layer' &&
     e2e_file_contains "$state_doc" 'plan_graph' &&
     e2e_file_contains "$state_doc" 'implement' &&
     e2e_file_contains "$state_doc" 'verify' &&
     e2e_file_contains "$state_doc" 'inspect' &&
     e2e_file_contains "$state_doc" 'persist' &&
     e2e_file_contains "$state_doc" 'state_traceback'; then
    printf 'PASS state machine instruction covers executable states and state_traceback\n'
  else
    printf 'FAIL state machine instruction missing executable states or state_traceback\n'
    rc=1
  fi

  if grep -Fq '"state_traceback"' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'state_sequence' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'failure_state' "$E2E_ROOT_DIR/$report_sh" &&
     grep -Fq 'rollback_target' "$E2E_ROOT_DIR/$report_sh"; then
    printf 'PASS report.sh emits state_traceback fields into task-run artifacts\n'
  else
    printf 'FAIL report.sh missing state_traceback artifact fields\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" state-audit || rc=1
  return "$rc"
}

e2e_agent_system_reviewer_inspector_gate() {
  echo "[agent-system] reviewer/inspector execution gate"
  local rc=0
  local profile_doc=".github/e2e/profiles/agent-system.tsv"
  local review_doc=".github/ai-env/contracts/agent-env-review-routing.json"
  local policy_doc=".github/ai-env/contracts/agent-env-policy.json"
  local state_trace_doc=".github/ai-env/contracts/agent-env-state-traceability.json"

  e2e_print_required_files \
    "$profile_doc" \
    "$review_doc" \
    "$policy_doc" \
    "$state_trace_doc" || rc=1

  if e2e_file_contains "$profile_doc" 'state-machine-traceback|agent-system|e2e_agent_system_state_traceback|agent-system|' &&
     e2e_file_contains "$profile_doc" 'reviewer-inspector-gate|agent-system|e2e_agent_system_reviewer_inspector_gate|agent-system|'; then
    printf 'PASS agent-system profile executes state traceback and reviewer/inspector nodes\n'
  else
    printf 'FAIL agent-system profile missing R7 execution nodes\n'
    rc=1
  fi

  if e2e_file_contains "$review_doc" '"R7": "agent-layer"' &&
     e2e_file_contains "$review_doc" '"primary_agent": "ysyx-coordinator"' &&
     e2e_file_contains "$review_doc" '"inspector": "agent-system"' &&
     e2e_file_contains "$review_doc" '"state-audit"'; then
    printf 'PASS review routing maps R7 to reviewer/inspector gate\n'
  else
    printf 'FAIL review routing missing R7 reviewer/inspector gate\n'
    rc=1
  fi

  if e2e_file_contains "$policy_doc" '"reviewer_profile_nodes"' &&
     e2e_file_contains "$policy_doc" '"state-machine-traceback"' &&
     e2e_file_contains "$policy_doc" '"reviewer-inspector-gate"'; then
    printf 'PASS policy requires reviewer/inspector profile nodes\n'
  else
    printf 'FAIL policy missing reviewer/inspector profile node requirements\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" state-audit || rc=1
  return "$rc"
}

e2e_agent_system_commercial_delivery_readiness() {
  echo "[agent-system] commercial delivery readiness"
  local rc=0
  local delivery_doc=".github/ai-env/contracts/agent-env-delivery.json"
  local package_script="scripts/package-ai-dev-env.sh"
  local delivery_root="deliverables/ai-dev-env-commercial-v1"
  local package_root="dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial"
  local archive_manifest=".github/archive/legacy-ai-dev-env-2026-06-13/ARCHIVE_MANIFEST.md"
  local archive_checksums=".github/archive/legacy-ai-dev-env-2026-06-13/CHECKSUMS.txt"
  local archive_pointers=".github/archive/legacy-ai-dev-env-2026-06-13/POINTERS.md"
  local package_filelist="$package_root/PACKAGE_FILELIST.txt"
  local sensitive_log
  local marker_home="/home/""lyg"
  local marker_windows="C:/Users/""17279"
  local marker_id="260""10035"
  local marker_tag="ysyx_""260""10035"

  sensitive_log=$(mktemp)

  e2e_print_required_files \
    "$delivery_doc" \
    "$package_script" \
    "$delivery_root/README.md" \
    "$delivery_root/PACKAGING_MANIFEST.md" \
    "$delivery_root/COMMERCIAL_READINESS.md" \
    "$delivery_root/docs/ARCHITECTURE.md" \
    "$delivery_root/docs/OPERATIONS.md" \
    "$delivery_root/docs/QUALITY_GATES.md" \
    "$archive_manifest" \
    "$archive_checksums" \
    "$archive_pointers" || rc=1

  bash "$E2E_ROOT_DIR/$package_script" || rc=1

  e2e_print_required_files \
    "$package_root/README.md" \
    "$package_root/AI_ENVIRONMENT.md" \
    "$package_root/PACKAGING_MANIFEST.md" \
    "$package_root/.github/AGENTS.md" \
    "$package_root/.github/ai-env/README.md" \
    "$package_root/.github/ai-env/contracts/agent-env-delivery.json" \
    "$package_root/.github/ai-env/contracts/agent-env-policy.json" \
    "$package_root/.github/agents/AGENT_INDEX.md" \
    "$package_root/.github/skills/agent-env-maintenance/SKILL.md" \
    "$package_root/scripts/README.md" \
    "$package_root/scripts/agent-maintain.sh" \
    "$package_root/scripts/github_index_db.py" \
    "$package_filelist" || rc=1

  if [[ ! -e "$E2E_ROOT_DIR/outputs" && ! -e "$E2E_ROOT_DIR/.github/e2e/_manual" ]]; then
    printf 'PASS legacy active outputs are absent from the live workspace\n'
  else
    printf 'FAIL legacy active outputs still exist in live workspace\n'
    rc=1
  fi

  if e2e_file_contains "$archive_manifest" 'outputs/' &&
     e2e_file_contains "$archive_manifest" '.github/e2e/_manual'; then
    printf 'PASS archive manifest records moved legacy output roots\n'
  else
    printf 'FAIL archive manifest missing moved legacy output roots\n'
    rc=1
  fi

  if grep -Fq 'README.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq 'AI_ENVIRONMENT.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq '.github/ai-env/README.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq '.github/ai-env/contracts/agent-env-delivery.json' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq '.github/agents/AGENT_INDEX.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq 'scripts/README.md' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq 'scripts/agent-maintain.sh' "$E2E_ROOT_DIR/$package_filelist" &&
     grep -Fq 'scripts/github_index_db.py' "$E2E_ROOT_DIR/$package_filelist" &&
     ! grep -Fq "$marker_home" "$E2E_ROOT_DIR/$package_filelist"; then
    printf 'PASS package filelist is relative and contains required delivery entries\n'
  else
    printf 'FAIL package filelist missing required entries or contains absolute paths\n'
    rc=1
  fi

  if [[ ! -d "$E2E_ROOT_DIR/$package_root/.github/e2e/modules/modules" &&
        ! -d "$E2E_ROOT_DIR/$package_root/.github/e2e/profiles/profiles" ]]; then
    printf 'PASS package e2e directories are not nested twice\n'
  else
    printf 'FAIL package contains duplicated e2e module/profile directories\n'
    rc=1
  fi

  if rg -n -e "$marker_home" -e "$marker_windows" -e "$marker_id" -e "$marker_tag" "$E2E_ROOT_DIR/$package_root" >"$sensitive_log" 2>/dev/null; then
    printf 'FAIL package contains local/private markers\n'
    sed -n '1,10p' "$sensitive_log"
    rc=1
  else
    printf 'PASS package contains no local/private marker scan hits\n'
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" delivery-audit || rc=1
  rm -f "$sensitive_log"
  return "$rc"
}

e2e_agent_system_profile_index() {
  echo "[agent-system] e2e profiles"
  find "$E2E_ROOT_DIR/.github/e2e/profiles" -maxdepth 1 -type f -name '*.tsv' -printf '%f\n' | sort
}
