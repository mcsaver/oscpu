#!/usr/bin/env bash
set -euo pipefail

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$run_dir/../../.." && pwd)
receipt="$run_dir/evidence/naming-migration.json"
crossbar="$repo_root/npc/rv64/vsrc/bus/AxiCrossbar.v"

hash_file() {
  sha256sum "$1" | sed 's/[[:space:]].*$//'
}

require_hash() {
  local path="$1"
  local expected="$2"
  local actual
  actual=$(hash_file "$repo_root/$path")
  [[ "$actual" == "$expected" ]] || {
    printf '[AXI-CROSSBAR-NAMING][FAIL] hash path=%s expected=%s actual=%s\n' \
      "$path" "$expected" "$actual" >&2
    exit 1
  }
}

new_expected=$(jq -r '.new_identity.source_sha256' "$receipt")
old_expected=$(jq -r '.old_identity.source_sha256' "$receipt")
[[ "$(hash_file "$crossbar")" == "$new_expected" ]]

old_replay=$(
  sed 's/^module AxiCrossbar/module AxiXbar/' "$crossbar" |
    sha256sum |
    sed 's/[[:space:]].*$//'
)
[[ "$old_replay" == "$old_expected" ]] || {
  printf '[AXI-CROSSBAR-NAMING][FAIL] reverse replay expected=%s actual=%s\n' \
    "$old_expected" "$old_replay" >&2
  exit 1
}

if rg -n 'AxiXbar|u_xbar' \
    "$repo_root/npc/rv64/vsrc" \
    "$repo_root/npc/rv64/testbench/tests"; then
  printf '%s\n' \
    '[AXI-CROSSBAR-NAMING][FAIL] retired production identifier remains' >&2
  exit 1
fi

while IFS=$'\t' read -r path expected
do
  require_hash "$path" "$expected"
done < <(
  jq -r '
    .current_design.focused_test_summary,
    .current_design.focused_test_logs[]
    | [.path, .sha256]
    | @tsv
  ' "$receipt"
)

rg -q '\[IFU-AXI-G1-XBAR-BACKPRESSURE\].* PASS' \
  "$run_dir/evidence/focused-axi-crossbar/logs/tb_axi_xbar.log"
rg -q '\[ACCESS-G1-FIREWALL\].* PASS' \
  "$run_dir/evidence/focused-axi-crossbar/logs/tb_axi_exec_firewall.log"
rg -q '\[IFU-AXI-G1-XBAR\].* PASS' \
  "$run_dir/evidence/focused-axi-crossbar/logs/tb_ooo_fetch_axi_bridge_xbar.log"

for current in \
  "$repo_root/npc/rv64/eval/ppa/evidence/ifu-access-current.json" \
  "$repo_root/npc/rv64/eval/ppa/evidence/ifu-axi-flush-drain-current.json"
do
  [[ "$(jq -r '.status' "$current")" == "GAP" ]]
  [[ "$(jq -r '.gap.required_current_source' "$current")" == \
      "npc/rv64/vsrc/bus/AxiCrossbar.v" ]]
  historical_path=$(jq -r '.gap.historical_artifact.path' "$current")
  historical_hash=$(jq -r '.gap.historical_artifact.sha256' "$current")
  require_hash "$historical_path" "$historical_hash"
  [[ "$(jq -r '.status' "$repo_root/$historical_path")" == "PASS" ]]
done

printf '%s\n' \
  '[AXI-CROSSBAR-NAMING][PASS] reverse_hash=old_source current_hash=new_source focused_tb=3/3 retired_production_identifier=0 current_evidence=GAP historical_pass=retained'
