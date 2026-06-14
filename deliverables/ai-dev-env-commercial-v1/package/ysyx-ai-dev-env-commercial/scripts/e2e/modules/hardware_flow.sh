#!/usr/bin/env bash

e2e_hardware_flow_contract() {
  echo "[hardware-flow] contract"
  e2e_print_required_files \
    .github/agents/hardware-flow.agent.md \
    .github/e2e/modules/hardware-flow.md \
    .github/e2e/profiles/discovery.tsv \
    .github/e2e/profiles/quick.tsv \
    .github/e2e/profiles/reference.tsv \
    .github/e2e/profiles/full.tsv \
    scripts/am-regression.sh \
    scripts/e2e/modules/hardware_flow.sh
}

e2e_hardware_flow_npc_sim_status() {
  echo "[hardware-flow] command: make -C npc/sim status"
  make -C "$E2E_ROOT_DIR/npc/sim" status
}

e2e_hardware_flow_reference_regression() {
  echo "[hardware-flow] command: scripts/am-regression.sh --no-bench --skip-devscan"
  timeout "${AGENT_E2E_REFERENCE_TIMEOUT:-1800}s" \
    bash "$E2E_ROOT_DIR/scripts/am-regression.sh" \
      --no-bench --skip-devscan --log-base "$E2E_EVIDENCE_DIR/am-regression"
}

e2e_hardware_flow_full_regression() {
  echo "[hardware-flow] command: scripts/am-regression.sh"
  timeout "${AGENT_E2E_REFERENCE_TIMEOUT:-1800}s" \
    bash "$E2E_ROOT_DIR/scripts/am-regression.sh" \
      --log-base "$E2E_EVIDENCE_DIR/am-regression"
}
