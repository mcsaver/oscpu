#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
out_dir="${1:-$repo_root/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r3p4-alu-terminal/light-yosys}"
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"

source "$repo_root/scripts/agent-env.sh"
rtl_files="$(make -s -C "$repo_root/npc/rv64" print-synth-rtl)"
log="$out_dir/yosys.log"
json="$out_dir/ooo-int-backend.json"

yosys -q -l "$log" -p "
  read_verilog -I$repo_root/npc/rv64/vsrc -I$repo_root/npc/rv64/vsrc/include $rtl_files;
  hierarchy -check -top OooIntBackend;
  prep -top OooIntBackend;
  check;
  stat -top OooIntBackend;
  write_json $json
"

if grep -Eq '(^|[[:space:]])(ERROR|Error):' "$log"; then
  echo "[R3P4-LIGHT-YOSYS] FAIL: Yosys reported an error" >&2
  exit 1
fi

bitmanip_count="$(jq '[.modules.OooIntBackend.cells[] | select(.type == "OooBitmanipGate")] | length' "$json")"
wbu_count="$(jq '[.modules.OooIntBackend.cells[] | select(.type == "WBU")] | length' "$json")"
alu_count="$(jq '[.modules.OooIntBackend.cells[] | select(.type == "ALU")] | length' "$json")"

if [[ "$bitmanip_count" -ne 1 || "$wbu_count" -ne 1 || "$alu_count" -ne 2 ]]; then
  echo "[R3P4-LIGHT-YOSYS] FAIL: bitmanip=$bitmanip_count wbu=$wbu_count alu=$alu_count" >&2
  exit 1
fi

sha256sum "$repo_root/npc/rv64/vsrc/execute/OooIntBackend.v" \
  "$repo_root/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v" \
  "$json" >"$out_dir/input-output.sha256"

{
  echo "[R3P4-LIGHT-YOSYS] PASS"
  echo "OooIntBackend.OooBitmanipGate=$bitmanip_count"
  echo "OooIntBackend.WBU=$wbu_count"
  echo "OooIntBackend.ALU=$alu_count"
  echo "json=$json"
  echo "log=$log"
} | tee "$out_dir/result.txt"
