#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task="$root/.github/task-runs/2026-07-31-rv64-v11w-ifu-dispatch-rebind"
evidence="$task/evidence"
archive="$evidence/pre-rebind-current"
logs="$evidence/logs"
status="$task/runner.status"

# shellcheck source=../../../../scripts/task-run-status.sh
source "$root/scripts/task-run-status.sh"
task_run_status_init "$status"
task_run_status_install_signal_traps

finish() {
  local rc=$?
  trap - EXIT
  task_run_status_finalize "$rc" 0
  exit $?
}
trap finish EXIT

mkdir -p "$archive" "$logs"

task_run_status_stage pre-rebind-identity
if [[ -f "$archive/ifu-axi-flush-drain-current.json" ]]; then
  printf '%s  %s\n' \
    '3916f821132c7dd6601ad95eeac005f7e7f41bd670fe9794d3ca9572e4433866' \
    'ifu-axi-flush-drain-current.json' \
    '5077f1f791d60609c28d4e912f3003f4f7405a9a96fa3cc3cd90d765066dedb2' \
    'ifu-axi-flush-drain.log' \
    'de0beef6ea12ff7a75520a11c58b66886eb9b2a1481c91026fb8f0994f01fe0e' \
    'ifu-access-current.json' \
    '352011b625b7e81eb2bf45f46c0b264325363424da8457166cf42239c9e38849' \
    'ifu-access.log' \
    | (cd "$archive" && sha256sum -c -) \
    >"$logs/pre-rebind-identity.log" 2>&1
else
  printf '%s  %s\n' \
    '3916f821132c7dd6601ad95eeac005f7e7f41bd670fe9794d3ca9572e4433866' \
    'npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain-current.json' \
    '5077f1f791d60609c28d4e912f3003f4f7405a9a96fa3cc3cd90d765066dedb2' \
    'npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain.log' \
    'de0beef6ea12ff7a75520a11c58b66886eb9b2a1481c91026fb8f0994f01fe0e' \
    'npc/rv64/eval/ppa/evidence/ifu-access-current.json' \
    '352011b625b7e81eb2bf45f46c0b264325363424da8457166cf42239c9e38849' \
    'npc/rv64/eval/ppa/evidence/ifu-access.log' \
    | (cd "$root" && sha256sum -c -) \
    >"$logs/pre-rebind-identity.log" 2>&1
  install -m 0644 \
    "$root/npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain-current.json" \
    "$archive/ifu-axi-flush-drain-current.json"
  install -m 0644 \
    "$root/npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain.log" \
    "$archive/ifu-axi-flush-drain.log"
  install -m 0644 \
    "$root/npc/rv64/eval/ppa/evidence/ifu-access-current.json" \
    "$archive/ifu-access-current.json"
  install -m 0644 \
    "$root/npc/rv64/eval/ppa/evidence/ifu-access.log" \
    "$archive/ifu-access.log"
fi
(cd "$archive" && sha256sum ./*) >"$evidence/pre-rebind-current.sha256"

frozen_inputs=(
  '.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/evidence/focused/logs/tb_ooo_fetch_axi_bridge.log'
  '.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/evidence/focused/logs/tb_ooo_fetch_axi_bridge_xbar.log'
  '.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/evidence/focused/logs/tb_axi_xbar.log'
  '.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/evidence/module-aggregate/summary.txt'
  '.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/evidence/mutations/summary.json'
  '.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/evidence/focused/logs/tb_ooo_fetch_access_footprint.log'
  '.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/evidence/focused/logs/tb_ooo_fetch_axi_access_attrs.log'
  '.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/evidence/focused/logs/tb_axi_exec_firewall.log'
  '.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/evidence/focused/logs/tb_ooo_ifu_lane1_fault_owner.log'
  '.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/evidence/sized-dpi/run.log'
  '.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/evidence/module-aggregate/summary.txt'
  '.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/evidence/mutations/summary.json'
)
(cd "$root" && sha256sum "${frozen_inputs[@]}") \
  >"$evidence/frozen-inputs.before.sha256"

task_run_status_stage ifu-axi-frozen-rebuild
python3 -B "$root/npc/rv64/eval/ppa/tools/ifu_axi_flush_drain_evidence.py" \
  --root "$root" \
  --bridge-log "$root/${frozen_inputs[0]}" \
  --xbar-log "$root/${frozen_inputs[1]}" \
  --generic-xbar-log "$root/${frozen_inputs[2]}" \
  --module-summary "$root/${frozen_inputs[3]}" \
  --variant-summary "$root/${frozen_inputs[4]}" \
  --output "$root/npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain-current.json" \
  --raw-log "$root/npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain.log" \
  >"$logs/ifu-axi-frozen-rebuild.log" 2>&1

task_run_status_stage ifu-access-frozen-rebuild
python3 -B "$root/npc/rv64/eval/ppa/tools/ifu_access_evidence.py" \
  --root "$root" \
  --footprint-log "$root/${frozen_inputs[5]}" \
  --attrs-log "$root/${frozen_inputs[6]}" \
  --firewall-log "$root/${frozen_inputs[7]}" \
  --lane-log "$root/${frozen_inputs[8]}" \
  --dpi-log "$root/${frozen_inputs[9]}" \
  --module-summary "$root/${frozen_inputs[10]}" \
  --variant-summary "$root/${frozen_inputs[11]}" \
  --output "$root/npc/rv64/eval/ppa/evidence/ifu-access-current.json" \
  --raw-log "$root/npc/rv64/eval/ppa/evidence/ifu-access.log" \
  >"$logs/ifu-access-frozen-rebuild.log" 2>&1

task_run_status_stage frozen-input-postcheck
(cd "$root" && sha256sum "${frozen_inputs[@]}") \
  >"$evidence/frozen-inputs.after.sha256"
cmp "$evidence/frozen-inputs.before.sha256" \
  "$evidence/frozen-inputs.after.sha256"

task_run_status_stage focused-evidence-unit-tests
(cd "$root" && python3 -B -m unittest -v \
  npc.rv64.eval.ppa.tests.test_ifu_axi_flush_drain_evidence \
  npc.rv64.eval.ppa.tests.test_ifu_access_evidence) \
  >"$logs/focused-evidence-unit-tests.log" 2>&1

task_run_status_stage post-rebind-identity
(cd "$root" && sha256sum \
  npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain-current.json \
  npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain.log \
  npc/rv64/eval/ppa/evidence/ifu-access-current.json \
  npc/rv64/eval/ppa/evidence/ifu-access.log) \
  >"$evidence/post-rebind-current.sha256"

task_run_status_stage complete
task_run_status_mark_evidence_complete
