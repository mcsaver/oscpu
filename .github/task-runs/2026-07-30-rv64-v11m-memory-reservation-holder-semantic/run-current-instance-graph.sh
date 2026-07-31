#!/usr/bin/env bash
set -uo pipefail

run_root=".github/task-runs/2026-07-30-rv64-v11m-memory-reservation-holder-semantic"
evidence_dir="${run_root}/evidence/current-instance-graph"
driver_log="${run_root}/current-instance-graph.driver.log"
driver_status="${run_root}/current-instance-graph.status"

mkdir -p "${evidence_dir}"
printf 'RUNNING stage=yosys-elaboration\n' > "${driver_status}"
python3 npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  --elaborate \
  --timeout-seconds 180 \
  --json-out "${evidence_dir}/holder-instance-graph.json" \
  --receipt-out "${evidence_dir}/yosys-instance-graph-receipt.json" \
  --full-json-out "${evidence_dir}/yosys-instance-graph.full.json.gz" \
  --script-out "${evidence_dir}/yosys-instance-graph.ys" \
  --log-out "${evidence_dir}/yosys-instance-graph.log" \
  > "${driver_log}" 2>&1
rc=$?
if [[ "${rc}" -eq 0 ]]; then
  printf 'PASS stage=yosys-elaboration rc=0\n' > "${driver_status}"
else
  printf 'FAIL stage=yosys-elaboration rc=%s\n' "${rc}" > "${driver_status}"
fi
exit "${rc}"
