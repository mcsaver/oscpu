#!/usr/bin/env bash

e2e_agent_system_discovery() {
  # Discovery is intentionally shallow. Business profiles do not include it,
  # and this explicit AI profile does not expand into DB/publication audits.
  echo "[agent-system] minimal discovery surface"
  local rc=0
  e2e_print_required_files \
    AGENTS.md \
    .github/AGENTS.md \
    .github/copilot-instructions.md \
    .github/instructions/agent-e2e-workflow.instructions.md \
    .github/e2e/profiles/discovery.tsv \
    scripts/agent-env.sh \
    scripts/agent-run.sh \
    scripts/agent-e2e.sh || rc=1
  return "$rc"
}

e2e_agent_system_operating_contract() {
  echo "[agent-system] objective-first operating contract"
  local rc=0
  local agents_doc=".github/AGENTS.md"
  local nav_doc="AI_ENVIRONMENT.md"
  local workflow_doc=".github/instructions/agent-lightweight-workflow.instructions.md"
  local layer_doc=".github/instructions/agent-env-layer-contract.instructions.md"
  local policy_doc=".github/ai-env/contracts/agent-env-policy.json"
  local flow_c="scripts/agent-flow.c"
  local flow_test="scripts/tests/test-agent-flow.sh"
  local contract_test="scripts/tests/test-agent-operating-contract.py"
  local maintain_sh="scripts/agent-maintain.sh"
  local workflow_yml=".github/workflows/agent-maintain.yml"

  e2e_print_required_files \
    "$agents_doc" "$nav_doc" "$workflow_doc" "$layer_doc" "$policy_doc" \
    "$flow_c" "$flow_test" "$contract_test" "$maintain_sh" "$workflow_yml" || rc=1

  if e2e_file_contains "$agents_doc" 'Primary objective' &&
     e2e_file_contains "$agents_doc" 'Safe local work is one authorization scope' &&
     e2e_file_contains "$agents_doc" 'Minimum sufficient validation' &&
     e2e_file_contains "$agents_doc" 'Compaction recovery and reporting'; then
    printf 'PASS canonical contract is objective-first and recovers from compaction\n'
  else
    printf 'FAIL canonical contract is missing objective, validation, batching, or recovery rules\n'
    rc=1
  fi

  if e2e_file_contains "$workflow_doc" '最小验证三问' &&
     e2e_file_contains "$workflow_doc" 'Failure-driven escalation' &&
     e2e_file_contains "$workflow_doc" '以上全部默认 opt-in' &&
     e2e_file_contains "$nav_doc" '普通任务不需要 DB brief' &&
     e2e_file_contains "$layer_doc" '下游不得把推荐升级为新的权限要求'; then
    printf 'PASS daily workflow keeps optional infrastructure out of ordinary work\n'
  else
    printf 'FAIL daily workflow still lacks minimum-validation or opt-in boundaries\n'
    rc=1
  fi

  if e2e_file_contains "$policy_doc" '"gate_selection": "explicit-only"' &&
     e2e_file_contains "$policy_doc" '"changed_paths_create_gates": false' &&
     e2e_file_contains "$policy_doc" '"default_archive_mode": "none"' &&
     e2e_file_contains "$policy_doc" '"zero_gate_finish_is_engineering_pass": false' &&
     grep -Fq 'Gate 只来自调用者显式选择' "$E2E_ROOT_DIR/$flow_c" &&
     grep -Fq 'FINISHED_NO_GATES' "$E2E_ROOT_DIR/$flow_c" &&
     grep -Fq 'RESULT=FINISHED_NO_GATES' "$E2E_ROOT_DIR/$flow_test"; then
    printf 'PASS controller uses explicit gates and zero-gate non-PASS completion\n'
  else
    printf 'FAIL controller or policy still exposes implicit gate/PASS defaults\n'
    rc=1
  fi

  if grep -Fq 'quick  : 只检查维护入口与定向 shell 测试的语法' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'final  : AI 环境 PR 的代表性测试集' "$E2E_ROOT_DIR/$maintain_sh" &&
     grep -Fq 'if: github.event_name != '\''pull_request'\''' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'scripts/agent-maintain.sh --mode final' "$E2E_ROOT_DIR/$workflow_yml" &&
     grep -Fq 'scripts/agent-maintain.sh --mode release' "$E2E_ROOT_DIR/$workflow_yml"; then
    printf 'PASS PR and explicit release maintenance boundaries are separated\n'
  else
    printf 'FAIL maintenance script or CI does not separate PR and release assurance\n'
    rc=1
  fi

  python3 -B "$E2E_ROOT_DIR/$contract_test" --positive-only || rc=1
  return "$rc"
}

# The functions below validate explicitly selected AI-environment components.
# Ordinary tasks do not invoke this profile; commercial delivery remains release-only.

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
     grep -Fq 'scripts/agent-e2e.sh --profile agent-system --publish' "$E2E_ROOT_DIR/$maintain_sh"; then
    printf 'PASS release owns one published agent-system profile with artifact audit\n'
  else
    printf 'FAIL release is not wired to the published agent-system artifact audit\n'
    rc=1
  fi

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" artifact-audit || rc=1
  return "$rc"
}


e2e_agent_system_rtl_task_contract() {
  echo "[agent-system] optional RV64 handoff compatibility"
  local handoff_rc=0
  local handoff_instruction=".github/instructions/rtl-agent-task-contract.instructions.md"
  local handoff_skill=".github/skills/prepare-rtl-task-contract/SKILL.md"
  local handoff_json=".github/ai-env/contracts/agent-env-rtl-task-contract.json"
  local handoff_tool=".github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
  e2e_print_required_files \
    "$handoff_instruction" "$handoff_skill" "$handoff_json" "$handoff_tool" || handoff_rc=1
  if e2e_file_contains "$handoff_instruction" '可选结构化 handoff' &&
     e2e_file_contains "$handoff_instruction" '不是 permission gate' &&
     e2e_file_contains "$handoff_skill" '不作为普通派发的权限、身份或审计门' &&
     e2e_file_contains "$handoff_skill" 'Optional legacy JSON'; then
    printf 'PASS RV64 handoff is advisory and legacy JSON is explicitly scoped\n'
  else
    printf 'FAIL RV64 handoff docs still expose a mandatory permission contract\n'
    handoff_rc=1
  fi
  python3 "$E2E_ROOT_DIR/$handoff_tool" cli-self-test || handoff_rc=1
  return "$handoff_rc"
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
     grep -Fq 'scripts/github_index_db.py' "$E2E_ROOT_DIR/$package_filelist"; then
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

  python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" delivery-audit || rc=1
  return "$rc"
}

e2e_agent_system_task_run_status_fail_closed() {
  echo "[agent-system] explicit persistent long-run status boundary"
  local rc=0
  local status_helper="scripts/task-run-status.sh"
  local status_test="scripts/tests/test-task-run-status.sh"

  e2e_print_required_files \
    "$status_helper" \
    "$status_test" \
    ".github/AGENTS.md" \
    "AI_ENVIRONMENT.md" || rc=1

  if grep -Fq '显式 persistent/published' "$E2E_ROOT_DIR/.github/AGENTS.md" &&
     grep -Fq '普通任务不需要' "$E2E_ROOT_DIR/AI_ENVIRONMENT.md"; then
    printf 'PASS fail-closed status is scoped to explicit persistent/published runs\n'
  else
    printf 'FAIL task-run status scope leaks into ordinary task completion\n'
    rc=1
  fi

  # This profile explicitly validates the helper itself; business profiles do not rerun this self-test.
  "$E2E_ROOT_DIR/$status_test" || rc=1
  return "$rc"
}

e2e_agent_system_profile_index() {
  echo "[agent-system] e2e profiles"
  find "$E2E_ROOT_DIR/.github/e2e/profiles" -maxdepth 1 -type f -name '*.tsv' -printf '%f\n' | sort
}
