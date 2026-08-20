#!/usr/bin/env bash

e2e_cpu_architect_contract() {
  echo "[cpu-architect] semantic routing and custom agent contract"
  local rc=0
  local policy="$E2E_ROOT_DIR/.github/ai-env/contracts/cpu-architect-routing-v1.json"
  local instruction="$E2E_ROOT_DIR/.github/instructions/cpu-architect-routing.instructions.md"
  local canonical_agent="$E2E_ROOT_DIR/.github/agents/cpu-architect.agent.md"
  local codex_agent="$E2E_ROOT_DIR/.codex/agents/cpu-architect.toml"
  local classifier="$E2E_ROOT_DIR/scripts/cpu_architect_route.py"
  local tests="$E2E_ROOT_DIR/scripts/tests/test_cpu_architect_route.py"
  local learning_policy="$E2E_ROOT_DIR/.github/ai-env/contracts/cpu-architect-learning-v1.json"
  local capability_schema="$E2E_ROOT_DIR/.github/ai-env/contracts/cpu-architect-capability-graph-v1.schema.json"
  local experience_schema="$E2E_ROOT_DIR/.github/ai-env/contracts/cpu-architect-experience-record-v1.schema.json"
  local gap_schema="$E2E_ROOT_DIR/.github/ai-env/contracts/cpu-architect-knowledge-gap-v1.schema.json"
  local learning_validator="$E2E_ROOT_DIR/scripts/cpu_architect_learning.py"
  local learning_tests="$E2E_ROOT_DIR/scripts/tests/test_cpu_architect_learning.py"
  local architecture_entry="$E2E_ROOT_DIR/npc/rv64/ARCHITECTURE.md"
  local architecture_catalog="$E2E_ROOT_DIR/npc/rv64/design/arch/rv64-architecture-registry-v1.json"
  local architecture_schema="$E2E_ROOT_DIR/npc/rv64/eval/ppa/schemas/rv64-architecture-registry-v1.schema.json"
  local architecture_tool="$E2E_ROOT_DIR/npc/rv64/eval/ppa/tools/architecture_registry.py"
  local architecture_tests="$E2E_ROOT_DIR/npc/rv64/eval/ppa/tests/test_architecture_registry.py"

  e2e_print_required_files \
    "$policy" "$instruction" "$canonical_agent" "$codex_agent" \
    "$classifier" "$tests" "$learning_policy" "$capability_schema" \
    "$experience_schema" "$gap_schema" "$learning_validator" \
    "$learning_tests" "$architecture_entry" "$architecture_catalog" \
    "$architecture_schema" "$architecture_tool" "$architecture_tests" || rc=1

  if e2e_file_contains "$codex_agent" 'name = "cpu_architect"' &&
     e2e_file_contains "$codex_agent" 'description = ' &&
     e2e_file_contains "$codex_agent" 'developer_instructions = """' &&
     e2e_file_contains "$instruction" 'ARCHITECT' &&
     e2e_file_contains "$instruction" 'EXPLORER' &&
     e2e_file_contains "$instruction" 'WORKER' &&
     e2e_file_contains "$instruction" 'REVIEWER' &&
     e2e_file_contains "$instruction" 'CLARIFY' &&
     e2e_file_contains "$instruction" 'NON_ARCH' &&
     e2e_file_contains "$canonical_agent" 'Grounded Experience Loop' &&
     e2e_file_contains "$canonical_agent" 'CapabilityGraph' &&
     e2e_file_contains "$canonical_agent" 'KnowledgeGap' &&
     e2e_file_contains "$canonical_agent" '不能' &&
     e2e_file_contains "$canonical_agent" 'ARCHITECTURE.md' &&
     e2e_file_contains "$architecture_catalog" '"single_entry": "npc/rv64/ARCHITECTURE.md"' &&
     e2e_file_contains "$architecture_catalog" '"bpu"' &&
     e2e_file_contains "$architecture_catalog" '"fp"' &&
     e2e_file_contains "$learning_policy" '"autonomous_weight_update": false'; then
    printf 'PASS custom agent, six-way route and grounded learning boundary are discoverable\n'
  else
    printf 'FAIL custom agent, route taxonomy or grounded learning boundary is incomplete\n'
    rc=1
  fi

  python3 -B "$classifier" validate-policy || rc=1
  python3 -B "$classifier" self-test || rc=1
  python3 -B "$tests" || rc=1
  python3 -B "$learning_validator" validate-contracts || rc=1
  python3 -B "$learning_validator" self-test || rc=1
  python3 -B "$learning_tests" || rc=1
  python3 -B "$architecture_tests" || rc=1
  return "$rc"
}
